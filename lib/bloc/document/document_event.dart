// bloc/document/document_event.dart
import 'package:equatable/equatable.dart';
import '../../models/document.dart';
import '../../models/document_category.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  final DocumentCategory? category;

  const LoadDocuments({this.category});

  @override
  List<Object?> get props => [category];
}

class CreateDocument extends DocumentEvent {
  final Document document;
  final String imagePath;

  const CreateDocument({
    required this.document,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [document, imagePath];
}

class UpdateDocument extends DocumentEvent {
  final Document document;

  const UpdateDocument(this.document);

  @override
  List<Object?> get props => [document];
}

class DeleteDocument extends DocumentEvent {
  final Document document;

  const DeleteDocument(this.document);

  @override
  List<Object?> get props => [document];
}

class FilterDocumentsByCategory extends DocumentEvent {
  final DocumentCategory? category;

  const FilterDocumentsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class RefreshDocuments extends DocumentEvent {
  const RefreshDocuments();
}
