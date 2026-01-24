// bloc/ocr/ocr_state.dart
import 'package:equatable/equatable.dart';

abstract class OCRState extends Equatable {
  const OCRState();

  @override
  List<Object?> get props => [];
}

class OCRInitial extends OCRState {}

class OCRProcessing extends OCRState {}

class OCRSuccess extends OCRState {
  final String extractedText;
  final int blocksCount;
  final int linesCount;

  const OCRSuccess({
    required this.extractedText,
    required this.blocksCount,
    required this.linesCount,
  });

  @override
  List<Object?> get props => [extractedText, blocksCount, linesCount];
}

class OCREmpty extends OCRState {
  const OCREmpty();
}

class OCRError extends OCRState {
  final String message;

  const OCRError(this.message);

  @override
  List<Object?> get props => [message];
}
