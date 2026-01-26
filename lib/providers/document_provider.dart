import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/database_service.dart';

class DocumentProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _databaseService.getAllDocuments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDocument(Document document) async {
    try {
      await _databaseService.insertDocument(document);
      await loadDocuments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      await _databaseService.updateDocument(document);
      await loadDocuments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _databaseService.deleteDocument(id);
      await loadDocuments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    try {
      return await _databaseService.searchDocuments(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<int> getDocumentCount() async {
    try {
      return await _databaseService.getDocumentCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }
}
