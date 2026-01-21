// bloc/document/document_state.dart
import 'package:equatable/equatable.dart';
import '../../models/document.dart';
import '../../models/document_category.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;
  final DocumentCategory? selectedCategory;

  const DocumentLoaded({
    required this.documents,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [documents, selectedCategory];

  DocumentLoaded copyWith({
    List<Document>? documents,
    DocumentCategory? selectedCategory,
  }) {
    return DocumentLoaded(
      documents: documents ?? this.documents,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class DocumentCreating extends DocumentState {}

class DocumentCreated extends DocumentState {
  final Document document;

  const DocumentCreated(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentUpdating extends DocumentState {}

class DocumentUpdated extends DocumentState {
  final Document document;

  const DocumentUpdated(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentDeleting extends DocumentState {}

class DocumentDeleted extends DocumentState {
  final String documentId;

  const DocumentDeleted(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError(this.message);

  @override
  List<Object?> get props => [message];
}
