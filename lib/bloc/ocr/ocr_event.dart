// bloc/ocr/ocr_event.dart
import 'package:equatable/equatable.dart';
import '../../models/document.dart';

abstract class OCREvent extends Equatable {
  const OCREvent();

  @override
  List<Object?> get props => [];
}

class ExtractText extends OCREvent {
  final Document document;

  const ExtractText(this.document);

  @override
  List<Object?> get props => [document];
}

class ResetOCR extends OCREvent {
  const ResetOCR();
}
