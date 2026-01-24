// repositories/document_repository.dart
import 'dart:io';

import '../models/document.dart';
import '../models/document_category.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/exceptions.dart';

class DocumentRepository {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  Future<List<Document>> getAllDocuments({
    DocumentCategory? category,
  }) async {
    try {
      return await _dbService.getAllDocuments(category: category);
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

  Future<String> createDocument(Document document, String imagePath) async {
    try {
      // Save image to storage
      final savedPath = await _storageService.saveImage(File(imagePath));

      // Create document with saved path
      final docToSave = Document(
        id: document.id,
        title: document.title,
        category: document.category,
        imagePath: savedPath,
        extractedText: document.extractedText,
        createdAt: document.createdAt,
        expiryDate: document.expiryDate,
        metadata: document.metadata,
      );

      await _dbService.insertDocument(docToSave);
      return docToSave.id;
    } catch (e, stackTrace) {
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

  Future<void> deleteDocument(Document document) async {
    try {
      await _storageService.deleteImage(document.imagePath);
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

  Future<int> getDocumentCount({DocumentCategory? category}) async {
    try {
      return await _dbService.getDocumentCount(category: category);
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
