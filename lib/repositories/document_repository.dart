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
      final documents = await _dbService.getAllDocuments();

      // Convert stored relative paths back to absolute
      return await _resolveAbsolutePathsForDocuments(documents);
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
      final documents = await _dbService.getDocumentsPaginated(
        cursorCreatedAt: cursorCreatedAt,
        limit: limit,
      );

      return await _resolveAbsolutePathsForDocuments(documents);
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
      final document = await _dbService.getDocument(id);
      if (document == null) return null;

      return _resolveAbsolutePathsForDocument(document);
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
      // Save all images to storage and track relative paths for DB
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        debugPrint(
            'DocumentRepository: Saving image ${i + 1}/${imagePaths.length}: $imagePath');

        final savedPath = await _storageService.saveImage(File(imagePath));
        debugPrint('DocumentRepository: Image saved to: $savedPath');

        // Convert to relative path for database storage
        final relativePath = await _storageService.getRelativePath(savedPath);
        savedPaths.add(relativePath);
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
        await Future.wait(savedPaths.map((path) async {
          try {
            // Reconstruct absolute path for deletion during cleanup
            // Use sync path resolution since we optimized it earlier
            final absolutePath = _storageService.getAbsolutePathSync(path);
            await _storageService.deleteImage(absolutePath);
          } catch (cleanupError) {
            debugPrint(
                'DocumentRepository: Failed to delete orphaned image: $path ($cleanupError)');
          }
        }));
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
      // Normalize image paths to relative before saving to DB
      final relativePaths = <String>[];
      for (final path in document.imagePaths) {
        relativePaths.add(await _storageService.getRelativePath(path));
      }

      final docToUpdate = document.copyWith(imagePaths: relativePaths);
      await _dbService.updateDocument(docToUpdate);
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
        // Store relative path in DB
        final relativePath = await _storageService.getRelativePath(savedPath);
        savedPaths.add(relativePath);
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

      // Remove image from storage (resolve to absolute first if needed)
      // Note: imagePath coming from UI model should already be absolute if we mapped it correctly on load.
      // But we should be safe.
      final absolutePath = await _storageService.getAbsolutePath(imagePath);
      await _storageService.deleteImage(absolutePath);

      // Update document by removing the image path
      // We need to check against both potential stored formats to be safe
      final updatedImagePaths = document.imagePaths.where((path) {
        // This logic is tricky because document.imagePaths loaded in memory are ABSOLUTE (mapped).
        // But we need to save what?
        // Actually, if we update the document using its existing imagePaths, we might be saving back absolute paths!
        // CRITICAL: We must re-relativize ALL paths before saving updateDocument.
        return path != imagePath;
      }).toList();

      // Re-construct document with normalized RELATIVE paths for storage
      // Wait, let's fix updateDocument method to normalize paths instead.

      final updatedDocument = document.copyWith(
        imagePaths: updatedImagePaths,
      );

      await updateDocument(
          updatedDocument); // This calls our wrapper which should handle normalization
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
        final absolutePath = await _storageService.getAbsolutePath(imagePath);
        await _storageService.deleteImage(absolutePath);
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
      final documents = await _dbService.searchDocuments(query);
      return await _resolveAbsolutePathsForDocuments(documents);
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

  // --- Helpers ---

  Document _resolveAbsolutePathsForDocument(Document doc) {
    // Optimization: Use synchronous path resolution
    // This assumes StorageService.init() has been called in main.dart
    final absolutePaths = doc.imagePaths
        .map((path) => _storageService.getAbsolutePathSync(path))
        .toList();
    return doc.copyWith(imagePaths: absolutePaths);
  }

  Future<List<Document>> _resolveAbsolutePathsForDocuments(
      List<Document> docs) async {
    // Resolve all documents
    // Optimized: No longer async mapping needed, just linear transformation
    return docs.map((doc) => _resolveAbsolutePathsForDocument(doc)).toList();
  }
}
