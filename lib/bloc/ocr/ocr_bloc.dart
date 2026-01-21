// bloc/ocr/ocr_bloc.dart
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
      final result = await ocrService.extractTextWithDetails(
        event.document.imagePath,
      );

      if (!result.success) {
        emit(OCRError(result.error ?? 'OCR failed'));
        return;
      }

      if (result.fullText.isEmpty) {
        emit(const OCREmpty());
        return;
      }

      // Update document with extracted text
      final updatedDocument = event.document.copyWith(
        extractedText: result.fullText,
      );

      await documentRepository.updateDocument(updatedDocument);

      emit(OCRSuccess(
        extractedText: result.fullText,
        blocksCount: result.totalBlocks,
        linesCount: result.totalLines,
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
