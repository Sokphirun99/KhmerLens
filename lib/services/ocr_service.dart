import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  TextRecognizer? _textRecognizer;
  final bool _useTesseractForKhmer = true;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  /// Extract text from an image file (simple version)
  /// Uses Tesseract for Khmer, ML Kit for other languages
  Future<String> extractText(String imagePath) async {
    try {
      // Try Tesseract first for Khmer support
      if (_useTesseractForKhmer) {
        try {
          final text = await FlutterTesseractOcr.extractText(
            imagePath,
            language: 'khm', // Khmer language code
            args: {
              'preserve_interword_spaces': '1',
            },
          );

          if (text.isNotEmpty) {
            debugPrint(
                'OCR: Extracted text using Tesseract (${text.length} chars)');
            // Check if it contains Khmer or any meaningful text
            if (containsKhmerText(text) || text.trim().length > 3) {
              return text;
            }
          }
        } catch (e) {
          debugPrint('Tesseract OCR Error: $e - Falling back to ML Kit');
        }
      }

      // Fallback to ML Kit (for non-Khmer or if Tesseract fails)
      final inputImage = InputImage.fromFile(File(imagePath));
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR Error: $e');
      return '';
    }
  }

  /// Extract text with detailed information (blocks, confidence, etc.)
  /// Uses Tesseract for Khmer, ML Kit for other languages
  Future<OCRResult> extractTextWithDetails(String imagePath) async {
    try {
      // Try Tesseract first for Khmer support
      if (_useTesseractForKhmer) {
        try {
          final text = await FlutterTesseractOcr.extractText(
            imagePath,
            language: 'khm', // Khmer language code
            args: {
              'preserve_interword_spaces': '1',
            },
          );

          if (text.isNotEmpty) {
            debugPrint(
                'OCR: Extracted text using Tesseract (${text.length} chars)');

            // Convert Tesseract result to OCRResult format
            final lines = text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
            final blocks = <OCRTextBlock>[];

            // Create blocks from lines
            for (var i = 0; i < lines.length; i++) {
              blocks.add(OCRTextBlock(
                text: lines[i],
                confidence: 0.8, // Default confidence for Tesseract
                linesCount: 1,
                boundingBox:
                    null, // Tesseract doesn't provide bounding boxes easily
              ));
            }

            return OCRResult(
              fullText: text,
              blocks: blocks,
              totalBlocks: blocks.length,
              totalLines: lines.length,
              success: true,
            );
          }
        } catch (e) {
          debugPrint('Tesseract OCR Error: $e - Falling back to ML Kit');
        }
      }

      // Fallback to ML Kit (for non-Khmer or if Tesseract fails)
      final inputImage = InputImage.fromFile(File(imagePath));
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final blocks = <OCRTextBlock>[];
      int totalLines = 0;

      for (var block in recognizedText.blocks) {
        blocks.add(OCRTextBlock(
          text: block.text,
          confidence: _calculateBlockConfidence(block),
          linesCount: block.lines.length,
          boundingBox: block.boundingBox,
        ));
        totalLines += block.lines.length;
      }

      return OCRResult(
        fullText: recognizedText.text,
        blocks: blocks,
        totalBlocks: recognizedText.blocks.length,
        totalLines: totalLines,
        success: recognizedText.text.isNotEmpty,
      );
    } catch (e) {
      debugPrint('OCR Error: $e');
      return OCRResult(
        fullText: '',
        blocks: [],
        totalBlocks: 0,
        totalLines: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Calculate average confidence for a text block
  double _calculateBlockConfidence(TextBlock block) {
    if (block.lines.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int elementCount = 0;

    for (var line in block.lines) {
      for (var element in line.elements) {
        if (element.confidence != null) {
          totalConfidence += element.confidence!;
          elementCount++;
        }
      }
    }

    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }

  /// Extract keywords from text (simple implementation)
  List<String> extractKeywords(String text) {
    if (text.isEmpty) return [];

    // Split text into words and filter
    final words = text
        .split(RegExp(r'[\s\n\r]+'))
        .where((word) => word.length > 2)
        .map((word) => word.replaceAll(RegExp(r'[^\w\u1780-\u17FF]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();

    // Count word frequency
    final wordCount = <String, int>{};
    for (var word in words) {
      final lowerWord = word.toLowerCase();
      wordCount[lowerWord] = (wordCount[lowerWord] ?? 0) + 1;
    }

    // Sort by frequency and return top keywords
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(10).map((e) => e.key).toList();
  }

  /// Detect if text contains Khmer characters
  bool containsKhmerText(String text) {
    // Khmer Unicode range: U+1780 to U+17FF
    return RegExp(r'[\u1780-\u17FF]').hasMatch(text);
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

/// Result of OCR processing
class OCRResult {
  final String fullText;
  final List<OCRTextBlock> blocks;
  final int totalBlocks;
  final int totalLines;
  final bool success;
  final String? error;

  OCRResult({
    required this.fullText,
    required this.blocks,
    required this.totalBlocks,
    required this.totalLines,
    required this.success,
    this.error,
  });

  /// Get average confidence across all blocks
  double get averageConfidence {
    if (blocks.isEmpty) return 0.0;
    final total =
        blocks.fold<double>(0, (sum, block) => sum + block.confidence);
    return total / blocks.length;
  }

  /// Check if the result contains Khmer text
  bool get hasKhmerText {
    return RegExp(r'[\u1780-\u17FF]').hasMatch(fullText);
  }
}

/// Represents a block of text from OCR
class OCRTextBlock {
  final String text;
  final double confidence;
  final int linesCount;
  final Rect? boundingBox;

  OCRTextBlock({
    required this.text,
    required this.confidence,
    required this.linesCount,
    this.boundingBox,
  });
}
