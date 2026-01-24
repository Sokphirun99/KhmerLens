// bloc/ocr/ocr_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/ocr_service.dart';
import '../../repositories/document_repository.dart';
import 'ocr_event.dart';
import 'ocr_state.dart';

class OCRBloc extends Bloc<OCREvent, OCRState> {
  final OCRService ocrService;
  final DocumentRepository documentRepository;

  OCRBloc({
    required this.ocrService,
    required this.documentRepository,
  }) : super(OCRInitial()) {
    on<ExtractText>(_onExtractText);
    on<ResetOCR>(_onResetOCR);
  }

  Future<void> _onExtractText(
    ExtractText event,
    Emitter<OCRState> emit,
  ) async {
    emit(OCRProcessing());

    try {
      // Process all images in the document
      if (event.document.imagePaths.isEmpty) {
        emit(const OCRError('No images found in document'));
        return;
      }

      final allTexts = <String>[];
      int totalBlocks = 0;
      int totalLines = 0;

      // Process each image
      for (int i = 0; i < event.document.imagePaths.length; i++) {
        final imagePath = event.document.imagePaths[i];

        try {
          final result = await ocrService.extractTextWithDetails(imagePath);

          if (result.success && result.fullText.isNotEmpty) {
            // Add page separator for multi-image documents
            if (event.document.imagePaths.length > 1) {
              allTexts.add('--- Page ${i + 1} ---\n${result.fullText}');
            } else {
              allTexts.add(result.fullText);
            }
            totalBlocks += result.totalBlocks;
            totalLines += result.totalLines;
          }
        } catch (e) {
          // Continue processing other images even if one fails
          debugPrint('OCR failed for image $i: $e');
        }
      }

      if (allTexts.isEmpty) {
        emit(const OCREmpty());
        return;
      }

      // Combine all extracted text
      final combinedText = allTexts.join('\n\n');

      // Update document with extracted text
      final updatedDocument = event.document.copyWith(
        extractedText: combinedText,
      );

      await documentRepository.updateDocument(updatedDocument);

      emit(OCRSuccess(
        extractedText: combinedText,
        blocksCount: totalBlocks,
        linesCount: totalLines,
      ));
    } catch (e) {
      emit(OCRError('Failed to extract text: $e'));
    }
  }

  Future<void> _onResetOCR(
    ResetOCR event,
    Emitter<OCRState> emit,
  ) async {
    emit(OCRInitial());
  }
}
