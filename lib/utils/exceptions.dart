// utils/exceptions.dart

/// Base exception class for KhmerScan app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// Exception thrown when document operations fail
class DocumentException extends AppException {
  DocumentException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DocumentException.notFound(String documentId) {
    return DocumentException(
      'Document not found',
      code: 'DOCUMENT_NOT_FOUND',
    );
  }

  factory DocumentException.createFailed(dynamic error) {
    return DocumentException(
      'Failed to create document',
      code: 'DOCUMENT_CREATE_FAILED',
      originalError: error,
    );
  }

  factory DocumentException.updateFailed(dynamic error) {
    return DocumentException(
      'Failed to update document',
      code: 'DOCUMENT_UPDATE_FAILED',
      originalError: error,
    );
  }

  factory DocumentException.deleteFailed(dynamic error) {
    return DocumentException(
      'Failed to delete document',
      code: 'DOCUMENT_DELETE_FAILED',
      originalError: error,
    );
  }
}

/// Exception thrown when OCR operations fail
class OCRException extends AppException {
  OCRException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory OCRException.extractionFailed(dynamic error) {
    return OCRException(
      'Failed to extract text from image',
      code: 'OCR_EXTRACTION_FAILED',
      originalError: error,
    );
  }

  factory OCRException.noTextFound() {
    return OCRException(
      'No text found in image',
      code: 'OCR_NO_TEXT_FOUND',
    );
  }

  factory OCRException.invalidImage(String reason) {
    return OCRException(
      'Invalid image: $reason',
      code: 'OCR_INVALID_IMAGE',
    );
  }

  factory OCRException.engineNotAvailable(String engine) {
    return OCRException(
      'OCR engine not available: $engine',
      code: 'OCR_ENGINE_NOT_AVAILABLE',
    );
  }
}

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.saveFailed(dynamic error) {
    return StorageException(
      'Failed to save file',
      code: 'STORAGE_SAVE_FAILED',
      originalError: error,
    );
  }

  factory StorageException.loadFailed(String path, dynamic error) {
    return StorageException(
      'Failed to load file: $path',
      code: 'STORAGE_LOAD_FAILED',
      originalError: error,
    );
  }

  factory StorageException.deleteFailed(dynamic error) {
    return StorageException(
      'Failed to delete file',
      code: 'STORAGE_DELETE_FAILED',
      originalError: error,
    );
  }

  factory StorageException.insufficientSpace(int requiredBytes) {
    return StorageException(
      'Insufficient storage space. Need ${(requiredBytes / 1024 / 1024).toStringAsFixed(1)} MB',
      code: 'STORAGE_INSUFFICIENT_SPACE',
    );
  }

  factory StorageException.permissionDenied() {
    return StorageException(
      'Storage permission denied',
      code: 'STORAGE_PERMISSION_DENIED',
    );
  }
}

/// Exception thrown when database operations fail
class DatabaseException extends AppException {
  DatabaseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseException.queryFailed(String query, dynamic error) {
    return DatabaseException(
      'Database query failed',
      code: 'DATABASE_QUERY_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.insertFailed(dynamic error) {
    return DatabaseException(
      'Failed to insert record',
      code: 'DATABASE_INSERT_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.updateFailed(dynamic error) {
    return DatabaseException(
      'Failed to update record',
      code: 'DATABASE_UPDATE_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.deleteFailed(dynamic error) {
    return DatabaseException(
      'Failed to delete record',
      code: 'DATABASE_DELETE_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.migrationFailed(
      int fromVersion, int toVersion, dynamic error) {
    return DatabaseException(
      'Database migration failed from v$fromVersion to v$toVersion',
      code: 'DATABASE_MIGRATION_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.initializationFailed(dynamic error) {
    return DatabaseException(
      'Failed to initialize database',
      code: 'DATABASE_INIT_FAILED',
      originalError: error,
    );
  }

  factory DatabaseException.connectionFailed(dynamic error) {
    return DatabaseException(
      'Failed to connect to database',
      code: 'DATABASE_CONNECTION_FAILED',
      originalError: error,
    );
  }
}

/// Exception thrown when authentication operations fail
class AuthenticationException extends AppException {
  AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthenticationException.biometricNotAvailable() {
    return AuthenticationException(
      'Biometric authentication is not available on this device',
      code: 'AUTH_BIOMETRIC_NOT_AVAILABLE',
    );
  }

  factory AuthenticationException.biometricNotEnrolled() {
    return AuthenticationException(
      'No biometric credentials enrolled. Please set up fingerprint or face recognition in device settings',
      code: 'AUTH_BIOMETRIC_NOT_ENROLLED',
    );
  }

  factory AuthenticationException.authenticationFailed() {
    return AuthenticationException(
      'Authentication failed. Please try again',
      code: 'AUTH_FAILED',
    );
  }

  factory AuthenticationException.tooManyAttempts() {
    return AuthenticationException(
      'Too many failed attempts. Please try again later',
      code: 'AUTH_TOO_MANY_ATTEMPTS',
    );
  }

  factory AuthenticationException.cancelled() {
    return AuthenticationException(
      'Authentication cancelled by user',
      code: 'AUTH_CANCELLED',
    );
  }
}

/// Exception thrown when export operations fail
class ExportException extends AppException {
  ExportException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ExportException.pdfGenerationFailed(dynamic error) {
    return ExportException(
      'Failed to generate PDF',
      code: 'EXPORT_PDF_FAILED',
      originalError: error,
    );
  }

  factory ExportException.shareFailed(dynamic error) {
    return ExportException(
      'Failed to share document',
      code: 'EXPORT_SHARE_FAILED',
      originalError: error,
    );
  }

  factory ExportException.noDocumentsSelected() {
    return ExportException(
      'No documents selected for export',
      code: 'EXPORT_NO_DOCUMENTS',
    );
  }
}

/// Exception thrown when encryption operations fail
class EncryptionException extends AppException {
  EncryptionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory EncryptionException.encryptionFailed(dynamic error) {
    return EncryptionException(
      'Failed to encrypt data',
      code: 'ENCRYPTION_FAILED',
      originalError: error,
    );
  }

  factory EncryptionException.decryptionFailed(dynamic error) {
    return EncryptionException(
      'Failed to decrypt data',
      code: 'DECRYPTION_FAILED',
      originalError: error,
    );
  }

  factory EncryptionException.keyGenerationFailed(dynamic error) {
    return EncryptionException(
      'Failed to generate encryption key',
      code: 'KEY_GENERATION_FAILED',
      originalError: error,
    );
  }

  factory EncryptionException.keyNotFound() {
    return EncryptionException(
      'Encryption key not found',
      code: 'KEY_NOT_FOUND',
    );
  }
}
