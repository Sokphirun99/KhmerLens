import 'dart:io';

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

          // Add header only on first image of each document
          final isFirstImage = i == 0;
          final pageNumber = i + 1;
          final totalImages = doc.imagePaths.length;

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(0),
              build: (context) {
                return pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    // Full-page image (centered)
                    pw.Container(
                      width: PdfPageFormat.a4.width,
                      height: PdfPageFormat.a4.height,
                      child: pw.Image(
                        pdfImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                    // Optional: Page number badge in corner (for multi-image docs)
                    if (totalImages > 1)
                      pw.Positioned(
                        top: 8,
                        right: 8,
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

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = documentIds.length == 1
          ? '${docs.first.title}.pdf'
          : 'khmerscan_documents.pdf';
      final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:"*?<>|]+'), '_');
      final outputPath = p.join(tempDir.path, sanitizedName);
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile(outputPath)],
          text: 'Exported from KhmerScan',
        );
      } else {
        // On web, just trigger the print/save dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }
    } catch (e) {
      debugPrint('ExportService.exportToPdf error: $e');
      rethrow;
    }
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
