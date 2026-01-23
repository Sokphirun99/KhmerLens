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
    return await _dbService.getAllDocuments(category: category);
  }

  Future<Document?> getDocument(String id) async {
    return _dbService.getDocument(id);
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
    } catch (e) {
      throw DocumentException.createFailed(e);
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      await _dbService.updateDocument(document);
    } catch (e) {
      throw DocumentException.updateFailed(e);
    }
  }

  Future<void> deleteDocument(Document document) async {
    try {
      await _storageService.deleteImage(document.imagePath);
      await _dbService.deleteDocument(document.id);
    } catch (e) {
      throw DocumentException.deleteFailed(e);
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    return _dbService.searchDocuments(query);
  }

  Future<int> getDocumentCount({DocumentCategory? category}) async {
    return await _dbService.getDocumentCount(category: category);
  }

  Future<int> getTotalStorageUsed() async {
    return _storageService.getStorageSize();
  }

  Future<void> clearAllDocuments() async {
    final docs = await _dbService.getAllDocuments();
    for (var doc in docs) {
      await deleteDocument(doc);
    }
  }
}
