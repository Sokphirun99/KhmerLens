import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';
import '../models/document_category.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'khmerscan.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        extractedText TEXT,
        createdAt TEXT NOT NULL,
        expiryDate TEXT,
        metadata TEXT
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_category ON documents(category)');
    await db.execute('CREATE INDEX idx_created_at ON documents(createdAt DESC)');
  }

  // CRUD Operations

  Future<String> insertDocument(Document document) async {
    final db = await database;
    await db.insert(
      'documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return document.id;
  }

  Future<List<Document>> getAllDocuments({
    DocumentCategory? category,
    int? limit,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (category != null) {
      maps = await db.query(
        'documents',
        where: 'category = ?',
        whereArgs: [category.name],
        orderBy: 'createdAt DESC',
        limit: limit,
      );
    } else {
      maps = await db.query(
        'documents',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
    }

    return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
  }

  Future<Document?> getDocument(String id) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Document.fromMap(maps.first);
  }

  Future<int> updateDocument(Document document) async {
    final db = await database;
    return await db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> deleteDocument(String id) async {
    final db = await database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'title LIKE ? OR extractedText LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
  }

  Future<int> getDocumentCount({DocumentCategory? category}) async {
    final db = await database;

    if (category != null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM documents WHERE category = ?',
        [category.name],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } else {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM documents',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
