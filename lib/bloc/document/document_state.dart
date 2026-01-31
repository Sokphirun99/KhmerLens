// bloc/document/document_state.dart
import 'package:equatable/equatable.dart';
import '../../models/document.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;
  final bool hasMore;
  final bool isLoadingMore;

  const DocumentLoaded({
    required this.documents,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [documents, hasMore, isLoadingMore];

  DocumentLoaded copyWith({
    List<Document>? documents,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return DocumentLoaded(
      documents: documents ?? this.documents,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
  final dynamic error;

  const DocumentError(this.error);

  @override
  List<Object?> get props => [error];
}
