import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter/foundation.dart';

class KhmerOcrService {
  /// Extracts Khmer text from an image path
  Future<String> extractText(String imagePath) async {
    try {
      // "khm" matches the language code for "khm.traineddata"
      // "eng" is usually built-in or can be added for dual-language support like "khm+eng"
      final text = await FlutterTesseractOcr.extractText(imagePath,
          language: 'khm',
          args: {
            "preserve_interword_spaces": "1",
          });

      return text;
    } catch (e) {
      debugPrint('Khmer OCR Error: $e');
      return 'Error extracting text: $e';
    }
  }
}
