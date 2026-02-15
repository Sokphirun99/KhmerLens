import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class KhmerOcrService {
  /// Extracts Khmer text from an image path
  Future<String> extractText(String imagePath) async {
    String? processedImagePath;
    try {
      // Ensure tessdata is copied to a writable location
      // FIX: Solves NSCocoaErrorDomain Code=513 on iOS
      final tessDataPath = await _copyTessDataToAppDocuments();

      // Preprocess image for better OCR results
      // FIX: Solves "Image too small to scale" and improves accuracy
      processedImagePath = await _preprocessImage(imagePath);

      // "khm" matches the language code for "khm.traineddata"
      // "eng" is usually built-in or can be added for dual-language support like "khm+eng"
      final text = await FlutterTesseractOcr.extractText(
          processedImagePath ?? imagePath,
          language: 'khm',
          args: {
            "preserve_interword_spaces": "1",
            "tessdata": tessDataPath,
            // Optimization:
            // PSM 6: Assume a single uniform block of text. Great for cropped document blocks.
            // OEM 1: Neural nets LSTM only. Best accuracy.
            "psm": "6",
            "oem": "1",
          });

      return text;
    } catch (e) {
      debugPrint('Khmer OCR Error: $e');
      return 'Error extracting text: $e';
    } finally {
      // Clean up temporary processed image
      if (processedImagePath != null && processedImagePath != imagePath) {
        try {
          final file = File(processedImagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting temp OCR image: $e');
        }
      }
    }
  }

  /// Copies tessdata files from assets to ApplicationDocumentsDirectory
  /// Returns the path to the directory containing tessdata
  Future<String> _copyTessDataToAppDocuments() async {
    // Tesseract expects the PARENT directory of "tessdata", not "tessdata" itself.
    // e.g. if we pass "/path/to/docs", it looks for "/path/to/docs/tessdata/khm.traineddata"
    final appDocDir = await getApplicationDocumentsDirectory();
    final tessDataDir = Directory(path.join(appDocDir.path, 'tessdata'));

    if (!await tessDataDir.exists()) {
      await tessDataDir.create(recursive: true);
    }

    // List of traineddata files to copy
    // Ensure these match files in assets/tessdata/
    const trainedDataFiles = ['khm.traineddata', 'eng.traineddata'];

    for (final fileName in trainedDataFiles) {
      final file = File(path.join(tessDataDir.path, fileName));
      if (!await file.exists()) {
        final data = await rootBundle.load('assets/tessdata/$fileName');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes);
      }
    }

    return appDocDir.path;
  }

  /// Preprocesses image for better OCR accuracy:
  /// 1. Resize if too small
  /// 2. Convert to grayscale
  /// 3. Increase contrast
  Future<String?> _preprocessImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Check for garbage inputs (e.g. tiny crops)
      if (image.width < 50 || image.height < 50) {
        debugPrint(
            'OCR Warning: Image dimensions too small (${image.width}x${image.height}). Skipping.');
        return null;
      }

      // 1. Resize if too small (improves text recognition on low-res images)
      // Tesseract works best with images ~300 DPI. For a full page, width > 2000px is good.
      if (image.width < 2000) {
        image = img.copyResize(image, width: 2000);
      }

      // 2. Convert to grayscale (removes color noise)
      image = img.grayscale(image);

      // 3. Increase contrast (helps separate text from background)
      image = img.adjustColor(image, contrast: 1.5);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/ocr_processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final encoded = img.encodeJpg(image, quality: 90);
      await File(tempPath).writeAsBytes(encoded);

      return tempPath;
    } catch (e) {
      debugPrint('Image preprocessing failed: $e');
      return null; // Fallback to original image
    }
  }
}
