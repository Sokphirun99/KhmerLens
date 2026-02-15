import 'dart:io';
import 'dart:convert'; // Added for utf8 decoding
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'; // Added
import 'package:image/image.dart' as img; // Added
import 'khmer_ocr_service.dart';
import '../../l10n/arb/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:file_picker/file_picker.dart';
import 'package:pdf_render/pdf_render.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Using simple FABs column or similar for now to avoid extra dependency if not needed, or add it.
// Actually, let's use a simple Column of FABs or a Modal Bottom Sheet for "Scan New"
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/document/document_bloc.dart';
import '../../bloc/document/document_event.dart';
import '../../models/document.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final _ocrService = KhmerOcrService();
  String? _imagePath;
  String? _extractedText;
  bool _isScanning = false;

  // AdMob
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    // Auto-scan removed to allow user to choose between Camera/Gallery/File
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load().then((_) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      }).catchError((e) {
        debugPrint('Failed to load banner ad: $e');
      });
  }

  Future<void> _scanDocument() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          _imagePath = pictures.first;
          _extractedText = null;
        });
        _processImage(pictures.first);
      }
    } catch (e) {
      debugPrint('Error scanning: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _imagePath = result.files.single.path;
          _extractedText = null;
        });
        _processImage(_imagePath!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      // Allow PDF and common Office formats
      // Note: Tesseract can only OCR images, so we need to convert PDFs to images.
      // Office files (doc, docx, etc.) cannot be easily converted to images locally without heavy libraries.
      // For now, we will allow picking them, but might only support OCR on PDFs (via rendering).
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final extension = result.files.single.extension?.toLowerCase();

        if (extension == 'pdf') {
          await _processPdf(filePath);
        } else if (extension == 'docx') {
          await _processDocx(filePath);
        } else if (['doc', 'xls', 'xlsx', 'ppt', 'pptx'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Only .docx is supported for direct text extraction. Other Office formats require conversion to PDF.'),
              ),
            );
          }
        } else {
          // Fallback for other types if any
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unsupported file format.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _processDocx(String path) async {
    setState(() {
      _isScanning = true;
      _extractedText = null;
      _imagePath = null;
    });

    try {
      debugPrint('Processing DOCX: $path');
      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find word/document.xml inside the docx zip
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml == null) {
        debugPrint('word/document.xml not found in zip');
        setState(() {
          _isScanning = false;
          _extractedText = 'Could not find document content in .docx file.';
        });
        return;
      }

      final content = documentXml.content;
      String xmlContent;
      // if (content is List<int>) { // Analyzer says always true
      debugPrint('Decoding content from bytes (length: ${content.length})');
      xmlContent = utf8.decode(content as List<int>);
      // } else {
      //   debugPrint('Content is not List<int>, trying toString()');
      //   xmlContent = content.toString();
      // }

      final document = XmlDocument.parse(xmlContent);

      // Extract all text from <w:t> elements
      final textBuffer = StringBuffer();
      // Use * to find all elements and filter by name 't' regardless of prefix if needed
      // But standard docx uses w:t. Let's try finding 'w:t' which worked in test.
      // Also finding 't' just in case.
      final paragraphs = document.findAllElements('w:p');
      if (paragraphs.isEmpty) {
        debugPrint('No w:p elements found. Trying generic p search.');
      }

      for (final paragraph in paragraphs) {
        final texts = paragraph.findAllElements('w:t');
        for (final t in texts) {
          textBuffer.write(t.innerText);
        }
        textBuffer.writeln(); // New line after each paragraph
      }

      final extractedText = textBuffer.toString().trim();
      debugPrint('Extracted text length: ${extractedText.length}');

      // Check for Khmer characters (Unicode range \u1780-\u17FF)
      final hasKhmer = RegExp(r'[\u1780-\u17FF]').hasMatch(extractedText);
      final isGibberish =
          !hasKhmer && extractedText.isNotEmpty && extractedText.length > 10;

      String finalText = extractedText;
      if (isGibberish) {
        finalText = '$extractedText\n\n'
            '--- WARNING ---\n'
            'This document appears to use a Legacy Khmer Font (non-Unicode). '
            'Direct text extraction cannot read it correctly.\n'
            'Please convert this file to PDF and scan it to use OCR.';
      }

      setState(() {
        _isScanning = false;
        _extractedText =
            finalText.isEmpty ? 'No text found in document.' : finalText;
      });

      // Generate a placeholder image for DOCX so it can be saved/displayed
      _generatePlaceholderImage('DOCX');

      if (isGibberish && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Legacy Font Detected'),
            content: const Text(
                'The extracted text appears to be unreadable because this document uses an old Khmer font (like Limon or Breton) instead of Unicode.\n\nPlease convert this file to PDF and use the "File > PDF" option to scan it with OCR.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing DOCX: $e');
      debugPrint(stackTrace.toString());
      setState(() {
        _isScanning = false;
        _extractedText = 'Failed to extract text from .docx: $e';
      });
    }
  }

  Future<void> _processPdf(String path) async {
    setState(() {
      _isScanning = true;
      _extractedText = null;
      _imagePath =
          null; // Reset image preview as we might be rendering a PDF page
    });

    try {
      // Render the first page of the PDF as an image
      final doc = await PdfDocument.openFile(path);
      final page =
          await doc.getPage(1); // 1-based index usually, wait check lib
      // pdf_render uses 1-based indexing for getPage? No, usually 1. Let's check docs or try 1.
      // Actually pdf_render `getPage` takes pageNumber starting at 1.

      final pageImage = await page.render(
        width: 2000, // High res for OCR
        height: (2000 * page.height / page.width).toInt(),
      );

      await pageImage.createImageIfNotAvailable(); // Ensure image is generated

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/pdf_page_1_${DateTime.now().millisecondsSinceEpoch}.png';

      // Write raw rgba pixels? No, pdf_render provides a handy helper or we need to encode.
      // wait, pageImage.pixels is Uint8List. We need to encode to PNG/JPG for Tesseract.
      // Image package can do this.

      final image = img.Image.fromBytes(
        width: pageImage.width,
        height: pageImage.height,
        bytes: pageImage.pixels.buffer,
        order: img
            .ChannelOrder.rgba, // Check pdf_render output format. Usually RGBA.
        numChannels: 4,
      );

      final pngBytes = img.encodePng(image);
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(pngBytes);

      setState(() {
        _imagePath = tempPath; // Show the rendered page
      });

      // Now OCR the temp image
      _processImage(tempPath);

      // Cleanup happens in _processImage or we can leave temp file for preview
    } catch (e) {
      debugPrint('Error processing PDF: $e');
      setState(() {
        _isScanning = false;
        _extractedText = l10n.failedToExtractText('PDF Error: $e');
      });
    }
  }

  Future<void> _processImage(String path) async {
    setState(() => _isScanning = true);
    try {
      final text = await _ocrService.extractText(path);
      setState(() {
        _extractedText = text;
      });
    } catch (e) {
      setState(() {
        _extractedText = l10n.failedToExtractText(e.toString());
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _generatePlaceholderImage(String label) async {
    try {
      final image = img.Image(width: 600, height: 800);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Draw a border
      img.drawRect(image,
          x1: 10, y1: 10, x2: 590, y2: 790, color: img.ColorRgb8(0, 0, 0));

      // Removed text drawing to avoid font dependency issues

      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/docx_placeholder_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPath);
      await file.writeAsBytes(img.encodePng(image));

      setState(() {
        _imagePath = tempPath;
      });
    } catch (e) {
      debugPrint('Error generating placeholder image: $e');
      // Even if generation fails, we should arguably allow saving without image or just show error.
      // But for now, let's just log it.
    }
  }

  void _copyToClipboard() {
    if (_extractedText != null) {
      Clipboard.setData(ClipboardData(text: _extractedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.copiedToClipboard)),
      );
    }
  }

  void _shareText() {
    if (_extractedText != null) {
      // ignore: deprecated_member_use
      Share.share(_extractedText!);
    }
  }

  Future<void> _saveDocument() async {
    if (_imagePath == null) return;

    final titleController = TextEditingController(
      text: 'OCR Scan ${DateTime.now().toString().split('.')[0]}',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.save),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: l10n.documentTitle,
            hintText: l10n.enterDocumentTitle,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty && mounted) {
      debugPrint('Saving document: $title');
      debugPrint('Extracted text length: ${_extractedText?.length}');

      final document = Document(
        id: const Uuid().v4(),
        title: title,
        imagePaths: [_imagePath!],
        extractedText: _extractedText,
        createdAt: DateTime.now(),
      );

      context.read<DocumentBloc>().add(CreateDocument(
            document: document,
            imagePaths: [_imagePath!],
          ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.documentSaved)),
        );
        // Navigate back to show the new document in the list
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.khmerOCR),
        actions: [
          if (_extractedText != null) ...[
            IconButton(
              icon: const Iconify(Mdi.content_save, color: Colors.black),
              onPressed: _saveDocument,
              tooltip: l10n.save,
            ),
            IconButton(
              icon: const Iconify(Mdi.content_copy, color: Colors.black),
              onPressed: _copyToClipboard,
              tooltip: l10n.copy,
            ),
            IconButton(
              icon: const Iconify(Mdi.share_variant, color: Colors.black),
              onPressed: _shareText,
              tooltip: l10n.share,
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: _imagePath != null
                  ? Image.file(File(_imagePath!), fit: BoxFit.contain)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _scanDocument,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(l10n
                                .scanNew), // Was "Scan Document" but scanNew fits context better or add new key
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // OCR Result
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.extractedText,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (_isScanning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _extractedText ??
                            (_isScanning
                                ? l10n.processing
                                : l10n.noTextExtracted),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.kantumruyPro().fontFamily,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerAdReady && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_file',
            onPressed: _pickFile,
            tooltip: 'Pick File (PDF/Doc)',
            child: const Icon(Icons.attach_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.small(
            heroTag: 'fab_gallery',
            onPressed: _pickImage,
            tooltip: 'Pick Image',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'fab_scan',
            onPressed: _scanDocument,
            tooltip: l10n.scanNew,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
