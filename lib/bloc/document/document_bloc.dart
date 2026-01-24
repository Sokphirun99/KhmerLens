// bloc/document/document_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
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
    on<FilterDocumentsByCategory>(_onFilterByCategory);
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
      final documents = await repository.getAllDocuments(
        category: event.category,
      );

      emit(DocumentLoaded(
        documents: documents,
        selectedCategory: event.category,
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
      await repository.createDocument(event.document, event.imagePaths);
      emit(DocumentCreated(event.document));

      // Reload documents after creating
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
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

  Future<void> _onFilterByCategory(
    FilterDocumentsByCategory event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());

    try {
      final documents = await repository.getAllDocuments(
        category: event.category,
      );

      emit(DocumentLoaded(
        documents: documents,
        selectedCategory: event.category,
      ));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }

  Future<void> _onRefreshDocuments(
    RefreshDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    final currentState = state;

    try {
      final category =
          currentState is DocumentLoaded ? currentState.selectedCategory : null;

      final documents = await repository.getAllDocuments(
        category: category,
      );

      emit(DocumentLoaded(
        documents: documents,
        selectedCategory: category,
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
      await repository.removeImageFromDocument(event.documentId, event.imagePath);

      // Reload documents after removing image
      add(const RefreshDocuments());
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      emit(DocumentError(e));
    }
  }
}
