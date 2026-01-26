import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  /// Print a single document directly using the system print dialog.
  /// Allows the user to select paper size (Letter, A4, etc.) dynamically.
  Future<void> printDocument(String documentId) async {
    try {
      final doc = await _databaseService.getDocument(documentId);
      if (doc == null) return;

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await _generatePdf(format, [doc]);
        },
        name: '${doc.title}.pdf',
      );
    } catch (e) {
      debugPrint('ExportService.printDocument error: $e');
      rethrow;
    }
  }

  /// Export selected documents to a single PDF file and share it.
  Future<void> exportToPdf(List<String> documentIds) async {
    if (documentIds.isEmpty) return;

    try {
      final docs = <Document>[];
      for (final id in documentIds) {
        final doc = await _databaseService.getDocument(id);
        if (doc != null) {
          docs.add(doc);
        }
      }
      if (docs.isEmpty) return;

      // For file export, default to A4
      final pdfBytes = await _generatePdf(PdfPageFormat.a4, docs);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = documentIds.length == 1
          ? '${docs.first.title}.pdf'
          : 'khmerscan_documents.pdf';
      final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:"*?<>|]+'), '_');
      final outputPath = p.join(tempDir.path, sanitizedName);
      final file = File(outputPath);
      await file.writeAsBytes(pdfBytes);

      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile(outputPath)],
          text: 'Exported from KhmerScan',
        );
      } else {
        // On web, just trigger the print/save dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    } catch (e) {
      debugPrint('ExportService.exportToPdf error: $e');
      rethrow;
    }
  }

  /// Helper to generate PDF bytes given a format and list of documents
  Future<Uint8List> _generatePdf(
      PdfPageFormat baseFormat, List<Document> docs) async {
    final pdf = pw.Document();

    for (final doc in docs) {
      // Handle multiple images per document
      if (doc.imagePaths.isEmpty) continue;

      for (int i = 0; i < doc.imagePaths.length; i++) {
        final imagePath = doc.imagePaths[i];
        final imageFile = await _storageService.getImageFile(imagePath);
        if (imageFile == null) continue;

        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        // Get image dimensions to determine orientation
        final codec = await ui.instantiateImageCodec(imageBytes);
        final frame = await codec.getNextFrame();
        final imageWidth = frame.image.width.toDouble();
        final imageHeight = frame.image.height.toDouble();
        codec.dispose();

        // Determine orientation based on image aspect ratio
        final isLandscape = imageWidth > imageHeight;

        // Use the provided format but adjust orientation
        // If the base format is A4 or Letter, we respect that size but rotate if needed
        final pageFormat =
            isLandscape ? baseFormat.landscape : baseFormat.portrait;

        final pageNumber = i + 1;
        final totalImages = doc.imagePaths.length;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(24),
            build: (context) {
              return pw.Stack(
                children: [
                  // Centered image that fills the page
                  pw.Center(
                    child: pw.Image(
                      pdfImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  // Optional: Page number badge in corner (for multi-image docs)
                  if (totalImages > 1)
                    pw.Positioned(
                      top: 0,
                      right: 0,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xB3000000),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          '$pageNumber/$totalImages',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }
    }
    return await pdf.save();
  }

  /// Export a single document's images (share the original image files).
  Future<void> exportToImage(String documentId) async {
    try {
      final doc = await _databaseService.getDocument(documentId);
      if (doc == null) return;

      if (doc.imagePaths.isEmpty) return;

      // Get all image files for this document
      final imageFiles = <XFile>[];
      for (final imagePath in doc.imagePaths) {
        final imageFile = await _storageService.getImageFile(imagePath);
        if (imageFile != null) {
          imageFiles.add(XFile(imageFile.path));
        }
      }

      if (imageFiles.isEmpty) return;

      if (!kIsWeb) {
        await Share.shareXFiles(
          imageFiles,
          text: doc.title,
        );
      } else {
        // Web: no direct file share; could be enhanced later.
        debugPrint('Export to image is not supported on web.');
      }
    } catch (e) {
      debugPrint('ExportService.exportToImage error: $e');
      rethrow;
    }
  }

  /// Share a document as PDF (single-document helper).
  Future<void> shareDocument(String documentId) async {
    await exportToPdf([documentId]);
  }

  /// Export all documents in the database to a single PDF and share it.
  Future<void> exportAllDocuments() async {
    try {
      final docs = await _databaseService.getAllDocuments();
      if (docs.isEmpty) return;
      final ids = docs.map((d) => d.id).toList();
      await exportToPdf(ids);
    } catch (e) {
      debugPrint('ExportService.exportAllDocuments error: $e');
      rethrow;
    }
  }
}
