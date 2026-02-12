import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:share_plus/share_plus.dart';
import 'khmer_ocr_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Auto-start scanning when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanDocument();
    });
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

  Future<void> _processImage(String path) async {
    setState(() => _isScanning = true);
    try {
      final text = await _ocrService.extractText(path);
      setState(() {
        _extractedText = text;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Failed to extract text: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _copyToClipboard() {
    if (_extractedText != null) {
      Clipboard.setData(ClipboardData(text: _extractedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  void _shareText() {
    if (_extractedText != null) {
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
        title: const Text('Save Document'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Document Title',
            hintText: 'Enter a title for this scan',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty && mounted) {
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
          const SnackBar(content: Text('Document saved successfully')),
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
        title: const Text('Khmer OCR'),
        actions: [
          if (_extractedText != null) ...[
            IconButton(
              icon: const Iconify(Mdi.content_save, color: Colors.black),
              onPressed: _saveDocument,
              tooltip: 'Save',
            ),
            IconButton(
              icon: const Iconify(Mdi.content_copy, color: Colors.black),
              onPressed: _copyToClipboard,
              tooltip: 'Copy',
            ),
            IconButton(
              icon: const Iconify(Mdi.share_variant, color: Colors.black),
              onPressed: _shareText,
              tooltip: 'Share',
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
                            label: const Text('Scan Document'),
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
                        'Extracted Text',
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
                                ? 'Processing...'
                                : 'No text extracted yet.'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily:
                                  'GoogleFonts.kantumruyPro().fontFamily', // Assuming Khmer font
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
      floatingActionButton: FloatingActionButton(
        onPressed: _scanDocument,
        tooltip: 'Scan New',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
