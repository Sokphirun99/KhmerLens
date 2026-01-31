// repositories/document_repository.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/exceptions.dart';

class DocumentRepository {
  final DatabaseService _dbService;
  final StorageService _storageService;

  DocumentRepository({
    DatabaseService? dbService,
    StorageService? storageService,
  })  : _dbService = dbService ?? DatabaseService(),
        _storageService = storageService ?? StorageService();

  Future<List<Document>> getAllDocuments() async {
    try {
      return await _dbService.getAllDocuments();
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to load documents',
        code: 'DOCUMENT_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gets documents with cursor-based pagination.
  /// Returns documents created before [cursorCreatedAt] (or first page if null).
  /// [limit] controls page size (default 20).
  Future<List<Document>> getDocumentsPaginated({
    DateTime? cursorCreatedAt,
    int limit = 20,
  }) async {
    try {
      return await _dbService.getDocumentsPaginated(
        cursorCreatedAt: cursorCreatedAt,
        limit: limit,
      );
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to load documents',
        code: 'DOCUMENT_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Checks if more documents exist after the given cursor.
  Future<bool> hasMoreDocuments(DateTime cursorCreatedAt) async {
    try {
      return await _dbService.hasMoreDocuments(cursorCreatedAt);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to check for more documents',
        code: 'DOCUMENT_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Document?> getDocument(String id) async {
    try {
      return await _dbService.getDocument(id);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to get document',
        code: 'DOCUMENT_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String> createDocument(
      Document document, List<String> imagePaths) async {
    // List to track saved images for rollback in case of failure
    final savedPaths = <String>[];

    try {
      debugPrint(
          'DocumentRepository: Creating document with ${imagePaths.length} images');

      // Save all images to storage
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        debugPrint(
            'DocumentRepository: Saving image ${i + 1}/${imagePaths.length}: $imagePath');
        final savedPath = await _storageService.saveImage(File(imagePath));
        debugPrint('DocumentRepository: Image saved to: $savedPath');
        savedPaths.add(savedPath);
      }

      debugPrint('DocumentRepository: All ${savedPaths.length} images saved');

      // Create document with saved paths
      final docToSave = Document(
        id: document.id,
        title: document.title,
        imagePaths: savedPaths,
        extractedText: document.extractedText,
        createdAt: document.createdAt,
        expiryDate: document.expiryDate,
        metadata: document.metadata,
      );

      debugPrint('DocumentRepository: Inserting document into database');
      await _dbService.insertDocument(docToSave);
      debugPrint(
          'DocumentRepository: Document created successfully with ID: ${docToSave.id}');

      return docToSave.id;
    } catch (e, stackTrace) {
      debugPrint('DocumentRepository: Error creating document: $e');

      // CLEANUP: If we fail here, delete the images we just saved to avoid storage clutter
      if (savedPaths.isNotEmpty) {
        debugPrint('DocumentRepository: Cleaning up orphaned images...');
        for (final path in savedPaths) {
          try {
            await _storageService.deleteImage(path);
          } catch (cleanupError) {
            debugPrint(
                'DocumentRepository: Failed to delete orphaned image: $path');
          }
        }
      }

      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to create document',
        code: 'DOCUMENT_CREATE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      await _dbService.updateDocument(document);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to update document',
        code: 'DOCUMENT_UPDATE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addImagesToDocument(
      String documentId, List<String> newImagePaths) async {
    try {
      final document = await getDocument(documentId);
      if (document == null) {
        throw DocumentException(
          'Document not found',
          code: 'DOCUMENT_NOT_FOUND',
        );
      }

      // Save new images to storage
      final savedPaths = <String>[];
      for (final imagePath in newImagePaths) {
        final savedPath = await _storageService.saveImage(File(imagePath));
        savedPaths.add(savedPath);
      }

      // Update document with new image paths
      final updatedDocument = document.copyWith(
        imagePaths: [...document.imagePaths, ...savedPaths],
      );

      await _dbService.updateDocument(updatedDocument);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to add images to document',
        code: 'DOCUMENT_ADD_IMAGES_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeImageFromDocument(
      String documentId, String imagePath) async {
    try {
      final document = await getDocument(documentId);
      if (document == null) {
        throw DocumentException(
          'Document not found',
          code: 'DOCUMENT_NOT_FOUND',
        );
      }

      // Remove image from storage
      await _storageService.deleteImage(imagePath);

      // Update document by removing the image path
      final updatedImagePaths =
          document.imagePaths.where((path) => path != imagePath).toList();
      final updatedDocument = document.copyWith(
        imagePaths: updatedImagePaths,
      );

      await _dbService.updateDocument(updatedDocument);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to remove image from document',
        code: 'DOCUMENT_REMOVE_IMAGE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteDocument(Document document) async {
    try {
      // Delete all images associated with the document
      for (final imagePath in document.imagePaths) {
        await _storageService.deleteImage(imagePath);
      }
      await _dbService.deleteDocument(document.id);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to delete document',
        code: 'DOCUMENT_DELETE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    try {
      return await _dbService.searchDocuments(query);
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to search documents',
        code: 'DOCUMENT_SEARCH_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> getDocumentCount() async {
    try {
      return await _dbService.getDocumentCount();
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to get document count',
        code: 'DOCUMENT_COUNT_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> getTotalStorageUsed() async {
    try {
      return await _storageService.getStorageSize();
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw StorageException(
        'Failed to get storage size',
        code: 'STORAGE_SIZE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearAllDocuments() async {
    try {
      final docs = await _dbService.getAllDocuments();
      for (var doc in docs) {
        await deleteDocument(doc);
      }
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      throw DocumentException(
        'Failed to clear all documents',
        code: 'DOCUMENT_CLEAR_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
