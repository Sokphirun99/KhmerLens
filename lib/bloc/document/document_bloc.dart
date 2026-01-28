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
      final documents = await repository.getAllDocuments();

      emit(DocumentLoaded(
        documents: documents,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
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
        final currentDocuments = (state as DocumentLoaded).documents;
        final updatedDocuments = List<Document>.from(currentDocuments)
          ..insert(0, createdDocument); // Insert new doc at the top

        emit(DocumentLoaded(documents: updatedDocuments));
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
      final documents = await repository.getAllDocuments();

      emit(DocumentLoaded(
        documents: documents,
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
