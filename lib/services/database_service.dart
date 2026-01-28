import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import '../models/document.dart';
import '../utils/exceptions.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // CONSTANTS
  static const String tableDocuments = 'documents';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colImagePaths = 'imagePaths';
  static const String colExtractedText = 'extractedText';
  static const String colCreatedAt = 'createdAt';
  static const String colExpiryDate = 'expiryDate';
  static const String colMetadata = 'metadata';

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
      // Using constants in SQL creation string
      await db.execute('''
        CREATE TABLE $tableDocuments (
          $colId TEXT PRIMARY KEY,
          $colTitle TEXT NOT NULL,
          $colImagePaths TEXT NOT NULL,
          $colExtractedText TEXT,
          $colCreatedAt TEXT NOT NULL,
          $colExpiryDate TEXT,
          $colMetadata TEXT
        )
      ''');

      await db.execute(
          'CREATE INDEX idx_created_at ON $tableDocuments($colCreatedAt DESC)');
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
        // Migration logic...
        // Note: Keeping raw strings here for the "old" table is usually safer
        // to avoid accidental changes if constants change in the future.
        final existingDocs = await db.query('documents');

        await db.execute('''
          CREATE TABLE documents_new (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            imagePaths TEXT NOT NULL,
            extractedText TEXT,
            createdAt TEXT NOT NULL,
            expiryDate TEXT,
            metadata TEXT
          )
        ''');

        for (var doc in existingDocs) {
          final imagePath = doc['imagePath'] as String?;
          final imagePaths = imagePath != null ? '["$imagePath"]' : '[]';

          await db.insert('documents_new', {
            'id': doc['id'],
            'title': doc['title'],
            'imagePaths': imagePaths,
            'extractedText': doc['extractedText'],
            'createdAt': doc['createdAt'],
            'expiryDate': doc['expiryDate'],
            'metadata': doc['metadata'],
          });
        }

        await db.execute('DROP TABLE documents');
        await db.execute('ALTER TABLE documents_new RENAME TO $tableDocuments');
        await db.execute(
            'CREATE INDEX idx_created_at ON $tableDocuments($colCreatedAt DESC)');
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
        tableDocuments,
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

  Future<List<Document>> getAllDocuments({int? limit}) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableDocuments,
        orderBy: '$colCreatedAt DESC',
        limit: limit,
      );

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
        tableDocuments,
        where: '$colId = ?',
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
        tableDocuments,
        document.toMap(),
        where: '$colId = ?',
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
        tableDocuments,
        where: '$colId = ?',
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
        tableDocuments,
        where: '$colTitle LIKE ? OR $colExtractedText LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '$colCreatedAt DESC',
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

  Future<int> getDocumentCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableDocuments',
      );
      return Sqflite.firstIntValue(result) ?? 0;
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
