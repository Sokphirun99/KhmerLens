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
        final imageFile = await _storageService.getImageFile(doc.imagePath);
        if (imageFile == null) continue;

        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    doc.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Category: ${doc.category.name}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Created: ${doc.createdAt}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(
                        pdfImage,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
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

  /// Export a single document's image (share the original image file).
  Future<void> exportToImage(String documentId) async {
    try {
      final doc = await _databaseService.getDocument(documentId);
      if (doc == null) return;

      final imageFile = await _storageService.getImageFile(doc.imagePath);
      if (imageFile == null) return;

      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile(imageFile.path)],
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
