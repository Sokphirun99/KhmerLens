import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../utils/exceptions.dart';

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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'khmerscan.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to initialize database',
        code: 'DATABASE_INIT_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE documents (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          imagePaths TEXT NOT NULL,
          extractedText TEXT,
          createdAt TEXT NOT NULL,
          expiryDate TEXT,
          metadata TEXT
        )
      ''');

      // Create indexes for faster queries
      await db.execute('CREATE INDEX idx_category ON documents(category)');
      await db.execute(
          'CREATE INDEX idx_created_at ON documents(createdAt DESC)');
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to create database tables',
        code: 'DATABASE_CREATE_TABLES_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Migrate from imagePath (String) to imagePaths (JSON array)
        // First, get all existing documents
        final existingDocs = await db.query('documents');

        // Create new table with updated schema
        await db.execute('''
          CREATE TABLE documents_new (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            imagePaths TEXT NOT NULL,
            extractedText TEXT,
            createdAt TEXT NOT NULL,
            expiryDate TEXT,
            metadata TEXT
          )
        ''');

        // Migrate data: convert single imagePath to array [imagePath]
        for (var doc in existingDocs) {
          final imagePath = doc['imagePath'] as String?;
          final imagePaths = imagePath != null ? '["$imagePath"]' : '[]';

          await db.insert('documents_new', {
            'id': doc['id'],
            'title': doc['title'],
            'category': doc['category'],
            'imagePaths': imagePaths,
            'extractedText': doc['extractedText'],
            'createdAt': doc['createdAt'],
            'expiryDate': doc['expiryDate'],
            'metadata': doc['metadata'],
          });
        }

        // Drop old table and rename new table
        await db.execute('DROP TABLE documents');
        await db.execute('ALTER TABLE documents_new RENAME TO documents');

        // Recreate indexes
        await db.execute('CREATE INDEX idx_category ON documents(category)');
        await db.execute('CREATE INDEX idx_created_at ON documents(createdAt DESC)');
      }
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to upgrade database',
        code: 'DATABASE_UPGRADE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // CRUD Operations

  Future<String> insertDocument(Document document) async {
    try {
      final db = await database;
      await db.insert(
        'documents',
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return document.id;
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to insert document',
        code: 'DATABASE_INSERT_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Document>> getAllDocuments({
    DocumentCategory? category,
    int? limit,
  }) async {
    try {
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
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to query documents',
        code: 'DATABASE_QUERY_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Document?> getDocument(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return Document.fromMap(maps.first);
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to get document',
        code: 'DATABASE_QUERY_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> updateDocument(Document document) async {
    try {
      final db = await database;
      return await db.update(
        'documents',
        document.toMap(),
        where: 'id = ?',
        whereArgs: [document.id],
      );
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to update document',
        code: 'DATABASE_UPDATE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> deleteDocument(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to delete document',
        code: 'DATABASE_DELETE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Document>> searchDocuments(String query) async {
    try {
      final db = await database;
      final maps = await db.query(
        'documents',
        where: 'title LIKE ? OR extractedText LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to search documents',
        code: 'DATABASE_QUERY_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<int> getDocumentCount({DocumentCategory? category}) async {
    try {
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
    } catch (e, stackTrace) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to get document count',
        code: 'DATABASE_QUERY_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to close database connection',
        code: 'DATABASE_CONNECTION_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
