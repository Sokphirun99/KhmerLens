// bloc/document/document_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/document.dart';
import '../../repositories/document_repository.dart';
import '../../utils/error_handler.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository repository;

  DocumentBloc({required this.repository}) : super(DocumentInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadMoreDocuments>(_onLoadMoreDocuments);
    on<CreateDocument>(_onCreateDocument);
    on<UpdateDocument>(_onUpdateDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<RefreshDocuments>(_onRefreshDocuments);
    on<AddImagesToDocument>(_onAddImagesToDocument);
    on<RemoveImageFromDocument>(_onRemoveImageFromDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());

    try {
      final documents = await repository.getDocumentsPaginated(
        limit: event.pageSize,
      );

      // Check if there are more documents
      bool hasMore = false;
      if (documents.isNotEmpty) {
        hasMore = await repository.hasMoreDocuments(documents.last.createdAt);
      }

      emit(DocumentLoaded(
        documents: documents,
        hasMore: hasMore,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onLoadMoreDocuments(
    LoadMoreDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DocumentLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    // Emit loading more state while preserving current documents
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // Use the last document's createdAt as cursor
      final cursor = currentState.documents.isNotEmpty
          ? currentState.documents.last.createdAt
          : null;

      final newDocuments = await repository.getDocumentsPaginated(
        cursorCreatedAt: cursor,
        limit: event.pageSize,
      );

      // Check if there are more documents after this batch
      bool hasMore = false;
      if (newDocuments.isNotEmpty) {
        hasMore = await repository.hasMoreDocuments(newDocuments.last.createdAt);
      }

      emit(DocumentLoaded(
        documents: [...currentState.documents, ...newDocuments],
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      // On error, revert to previous state without loading indicator
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onCreateDocument(
    CreateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentCreating());

    try {
      debugPrint(
          'DocumentBloc: Creating document with ${event.imagePaths.length} images');

      await repository.createDocument(event.document, event.imagePaths);

      // Fetch the created document from repository to get the correct saved image paths
      final createdDocument = await repository.getDocument(event.document.id);

      debugPrint(
          'DocumentBloc: Document created with ID: ${event.document.id}');

      // Emit creation success
      if (createdDocument != null) {
        emit(DocumentCreated(createdDocument));
      } else {
        emit(DocumentCreated(event.document));
      }

      // OPTIMIZATION: Manually update the list instead of reloading from DB
      // Check if we have the previous list in memory
      if (state is DocumentLoaded && createdDocument != null) {
        final currentState = state as DocumentLoaded;
        final updatedDocuments = List<Document>.from(currentState.documents)
          ..insert(0, createdDocument); // Insert new doc at the top

        emit(DocumentLoaded(
          documents: updatedDocuments,
          hasMore: currentState.hasMore,
        ));
      } else {
        // Fallback: reload everything if we weren't in a loaded state
        add(const RefreshDocuments());
      }
    } catch (e, stackTrace) {
      debugPrint('DocumentBloc: Error creating document: $e');
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onUpdateDocument(
    UpdateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentUpdating());

    try {
      await repository.updateDocument(event.document);
      emit(DocumentUpdated(event.document));

      // Reload documents after updating
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentDeleting());

    try {
      await repository.deleteDocument(event.document);
      emit(DocumentDeleted(event.document.id));

      // Reload documents after deleting
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onRefreshDocuments(
    RefreshDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      // Preserve current page size if we have loaded documents
      int pageSize = 20;
      if (state is DocumentLoaded) {
        final loadedCount = (state as DocumentLoaded).documents.length;
        // Keep at least the same number of documents loaded, or minimum 20
        pageSize = loadedCount > 20 ? loadedCount : 20;
      }

      final documents = await repository.getDocumentsPaginated(limit: pageSize);

      bool hasMore = false;
      if (documents.isNotEmpty) {
        hasMore = await repository.hasMoreDocuments(documents.last.createdAt);
      }

      emit(DocumentLoaded(
        documents: documents,
        hasMore: hasMore,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onAddImagesToDocument(
    AddImagesToDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentUpdating());

    try {
      await repository.addImagesToDocument(event.documentId, event.imagePaths);

      // Reload documents after adding images
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onRemoveImageFromDocument(
    RemoveImageFromDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentUpdating());

    try {
      await repository.removeImageFromDocument(
          event.documentId, event.imagePath);

      // Reload documents after removing image
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }
}
