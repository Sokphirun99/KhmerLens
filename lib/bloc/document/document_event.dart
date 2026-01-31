// bloc/document/document_event.dart
import 'package:equatable/equatable.dart';
import '../../models/document.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  /// Optional page size for pagination (default: 20)
  final int pageSize;

  const LoadDocuments({this.pageSize = 20});

  @override
  List<Object?> get props => [pageSize];
}

/// Load more documents for infinite scroll pagination
class LoadMoreDocuments extends DocumentEvent {
  final int pageSize;

  const LoadMoreDocuments({this.pageSize = 20});

  @override
  List<Object?> get props => [pageSize];
}

class CreateDocument extends DocumentEvent {
  final Document document;
  final List<String> imagePaths;

  const CreateDocument({
    required this.document,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [document, imagePaths];
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

class RefreshDocuments extends DocumentEvent {
  const RefreshDocuments();
}

class AddImagesToDocument extends DocumentEvent {
  final String documentId;
  final List<String> imagePaths;

  const AddImagesToDocument({
    required this.documentId,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [documentId, imagePaths];
}

class RemoveImageFromDocument extends DocumentEvent {
  final String documentId;
  final String imagePath;

  const RemoveImageFromDocument({
    required this.documentId,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [documentId, imagePath];
}
