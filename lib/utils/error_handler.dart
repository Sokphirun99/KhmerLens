// utils/error_handler.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'exceptions.dart';

/// Handles errors and provides user-friendly messages
class ErrorHandler {
  /// Get user-friendly error message in Khmer
  static String getKhmerMessage(dynamic error) {
    if (error is AppException) {
      return _getKhmerMessageForException(error);
    }
    return 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀត។'; // Something went wrong. Please try again.
  }

  /// Get user-friendly error message in English
  static String getEnglishMessage(dynamic error) {
    if (error is AppException) {
      return _getEnglishMessageForException(error);
    }
    return 'Something went wrong. Please try again.';
  }

  /// Get error message based on current locale (defaults to English)
  static String getMessage(dynamic error, {String locale = 'en'}) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return getKhmerMessage(error);
    }
    return getEnglishMessage(error);
  }

  /// Get recovery suggestion in Khmer
  static String? getKhmerRecoverySuggestion(dynamic error) {
    if (error is! AppException) return null;

    switch (error.code) {
      case 'DOCUMENT_NOT_FOUND':
        return 'ឯកសារប្រហែលជាត្រូវបានលុប។ សូមពិនិត្យមើលបញ្ជីឯកសាររបស់អ្នក។';
      case 'OCR_NO_TEXT_FOUND':
        return 'សូមធ្វើឱ្យប្រាកដថារូបភាពមានអត្ថបទច្បាស់លាស់។';
      case 'STORAGE_INSUFFICIENT_SPACE':
        return 'សូមលុបឯកសារមួយចំនួន ឬសម្អាតទំហំផ្ទុកឧបករណ៍របស់អ្នក។';
      case 'STORAGE_PERMISSION_DENIED':
        return 'សូមអនុញ្ញាតការចូលប្រើទំហំផ្ទុកក្នុងការកំណត់។';
      case 'AUTH_BIOMETRIC_NOT_ENROLLED':
        return 'សូមបើកការស្កេនម្រាមដៃ ឬមុខក្នុងការកំណត់ឧបករណ៍របស់អ្នក។';
      case 'AUTH_TOO_MANY_ATTEMPTS':
        return 'សូមរង់ចាំពីរបីនាទីមុនពេលព្យាយាមម្តងទៀត។';
      default:
        return null;
    }
  }

  /// Get recovery suggestion in English
  static String? getEnglishRecoverySuggestion(dynamic error) {
    if (error is! AppException) return null;

    switch (error.code) {
      case 'DOCUMENT_NOT_FOUND':
        return 'The document may have been deleted. Please check your document list.';
      case 'OCR_NO_TEXT_FOUND':
        return 'Make sure the image contains clear, readable text.';
      case 'OCR_INVALID_IMAGE':
        return 'Try taking a new photo with better lighting and focus.';
      case 'STORAGE_INSUFFICIENT_SPACE':
        return 'Delete some documents or free up device storage.';
      case 'STORAGE_PERMISSION_DENIED':
        return 'Please grant storage permission in Settings.';
      case 'AUTH_BIOMETRIC_NOT_AVAILABLE':
        return 'Your device does not support biometric authentication.';
      case 'AUTH_BIOMETRIC_NOT_ENROLLED':
        return 'Set up fingerprint or face recognition in your device settings.';
      case 'AUTH_TOO_MANY_ATTEMPTS':
        return 'Wait a few minutes before trying again.';
      case 'DATABASE_MIGRATION_FAILED':
        return 'Try reinstalling the app. Your data may be lost.';
      case 'EXPORT_NO_DOCUMENTS':
        return 'Select at least one document to export.';
      default:
        return null;
    }
  }

  /// Get recovery suggestion based on locale
  static String? getRecoverySuggestion(dynamic error, {String locale = 'en'}) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return getKhmerRecoverySuggestion(error);
    }
    return getEnglishRecoverySuggestion(error);
  }

  /// Check if error is recoverable (user can retry)
  static bool isRecoverable(dynamic error) {
    if (error is! AppException) return true;

    // Non-recoverable errors
    const nonRecoverableCodes = [
      'DATABASE_MIGRATION_FAILED',
      'AUTH_BIOMETRIC_NOT_AVAILABLE',
      'STORAGE_PERMISSION_DENIED',
    ];

    return !nonRecoverableCodes.contains(error.code);
  }

  /// Log error for debugging/analytics
  static void logError(dynamic error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('ERROR: ${error.toString()}');
      if (error is AppException && error.originalError != null) {
        debugPrint('ORIGINAL ERROR: ${error.originalError}');
      }
      if (stackTrace != null) {
        debugPrint('STACK TRACE:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════');
    }

    // Send to Firebase Crashlytics in Release mode
    try {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to report error to Crashlytics: $e');
      }
    }
  }

  // Private helper methods

  static String _getKhmerMessageForException(AppException error) {
    switch (error.code) {
      // Document errors
      case 'DOCUMENT_NOT_FOUND':
        return 'រកមិនឃើញឯកសារ';
      case 'DOCUMENT_CREATE_FAILED':
        return 'មិនអាចបង្កើតឯកសារបានទេ';
      case 'DOCUMENT_UPDATE_FAILED':
        return 'មិនអាចធ្វើបច្ចុប្បន្នភាពឯកសារបានទេ';
      case 'DOCUMENT_DELETE_FAILED':
        return 'មិនអាចលុបឯកសារបានទេ';

      // OCR errors
      case 'OCR_EXTRACTION_FAILED':
        return 'មិនអាចស្កេនអត្ថបទបានទេ';
      case 'OCR_NO_TEXT_FOUND':
        return 'រកមិនឃើញអត្ថបទក្នុងរូបភាព';
      case 'OCR_INVALID_IMAGE':
        return 'រូបភាពមិនត្រឹមត្រូវ';
      case 'OCR_ENGINE_NOT_AVAILABLE':
        return 'ម៉ាស៊ីនស្កេនមិនអាចប្រើបានទេ';

      // Storage errors
      case 'STORAGE_SAVE_FAILED':
        return 'មិនអាចរក្សាទុកឯកសារបានទេ';
      case 'STORAGE_LOAD_FAILED':
        return 'មិនអាចផ្ទុកឯកសារបានទេ';
      case 'STORAGE_DELETE_FAILED':
        return 'មិនអាចលុបឯកសារបានទេ';
      case 'STORAGE_INSUFFICIENT_SPACE':
        return 'ទំហំផ្ទុកមិនគ្រប់គ្រាន់';
      case 'STORAGE_PERMISSION_DENIED':
        return 'ត្រូវការការអនុញ្ញាតចូលប្រើទំហំផ្ទុក';

      // Database errors
      case 'DATABASE_QUERY_FAILED':
        return 'មានបញ្ហាក្នុងការទាញយកទិន្នន័យ';
      case 'DATABASE_INSERT_FAILED':
        return 'មិនអាចរក្សាទុកទិន្នន័យបានទេ';
      case 'DATABASE_UPDATE_FAILED':
        return 'មិនអាចធ្វើបច្ចុប្បន្នភាពទិន្នន័យបានទេ';
      case 'DATABASE_DELETE_FAILED':
        return 'មិនអាចលុបទិន្នន័យបានទេ';
      case 'DATABASE_MIGRATION_FAILED':
        return 'មានបញ្ហាក្នុងការធ្វើបច្ចុប្បន្នភាពមូលដ្ឋានទិន្នន័យ';

      // Authentication errors
      case 'AUTH_BIOMETRIC_NOT_AVAILABLE':
        return 'ឧបករណ៍របស់អ្នកមិនគាំទ្រការស្កេនម្រាមដៃ ឬមុខទេ';
      case 'AUTH_BIOMETRIC_NOT_ENROLLED':
        return 'សូមបើកការស្កេនម្រាមដៃ ឬមុខជាមុនសិន';
      case 'AUTH_FAILED':
        return 'ការផ្ទៀងផ្ទាត់មិនជោគជ័យ';
      case 'AUTH_TOO_MANY_ATTEMPTS':
        return 'ព្យាយាមច្រើនដងពេក';
      case 'AUTH_CANCELLED':
        return 'បានបោះបង់ការផ្ទៀងផ្ទាត់';

      // Export errors
      case 'EXPORT_PDF_FAILED':
        return 'មិនអាចបង្កើត PDF បានទេ';
      case 'EXPORT_SHARE_FAILED':
        return 'មិនអាចចែករំលែកឯកសារបានទេ';
      case 'EXPORT_NO_DOCUMENTS':
        return 'សូមជ្រើសរើសឯកសារយ៉ាងហោចណាស់មួយ';

      // Encryption errors
      case 'ENCRYPTION_FAILED':
        return 'មិនអាចអ៊ិនគ្រីបទិន្នន័យបានទេ';
      case 'DECRYPTION_FAILED':
        return 'មិនអាចឌិគ្រីបទិន្នន័យបានទេ';
      case 'KEY_NOT_FOUND':
        return 'រកមិនឃើញកូនសោអ៊ិនគ្រីប';

      default:
        return error.message;
    }
  }

  static String _getEnglishMessageForException(AppException error) {
    switch (error.code) {
      // Document errors
      case 'DOCUMENT_NOT_FOUND':
        return 'Document not found';
      case 'DOCUMENT_CREATE_FAILED':
        return 'Failed to create document';
      case 'DOCUMENT_UPDATE_FAILED':
        return 'Failed to update document';
      case 'DOCUMENT_DELETE_FAILED':
        return 'Failed to delete document';

      // OCR errors
      case 'OCR_EXTRACTION_FAILED':
        return 'Failed to scan text';
      case 'OCR_NO_TEXT_FOUND':
        return 'No text found in image';
      case 'OCR_INVALID_IMAGE':
        return 'Invalid image';
      case 'OCR_ENGINE_NOT_AVAILABLE':
        return 'OCR engine not available';

      // Storage errors
      case 'STORAGE_SAVE_FAILED':
        return 'Failed to save file';
      case 'STORAGE_LOAD_FAILED':
        return 'Failed to load file';
      case 'STORAGE_DELETE_FAILED':
        return 'Failed to delete file';
      case 'STORAGE_INSUFFICIENT_SPACE':
        return 'Insufficient storage space';
      case 'STORAGE_PERMISSION_DENIED':
        return 'Storage permission required';

      // Database errors
      case 'DATABASE_QUERY_FAILED':
        return 'Failed to retrieve data';
      case 'DATABASE_INSERT_FAILED':
        return 'Failed to save data';
      case 'DATABASE_UPDATE_FAILED':
        return 'Failed to update data';
      case 'DATABASE_DELETE_FAILED':
        return 'Failed to delete data';
      case 'DATABASE_MIGRATION_FAILED':
        return 'Database update failed';

      // Authentication errors
      case 'AUTH_BIOMETRIC_NOT_AVAILABLE':
        return 'Biometric authentication not available';
      case 'AUTH_BIOMETRIC_NOT_ENROLLED':
        return 'Biometric not set up';
      case 'AUTH_FAILED':
        return 'Authentication failed';
      case 'AUTH_TOO_MANY_ATTEMPTS':
        return 'Too many attempts';
      case 'AUTH_CANCELLED':
        return 'Authentication cancelled';

      // Export errors
      case 'EXPORT_PDF_FAILED':
        return 'Failed to generate PDF';
      case 'EXPORT_SHARE_FAILED':
        return 'Failed to share document';
      case 'EXPORT_NO_DOCUMENTS':
        return 'No documents selected';

      // Encryption errors
      case 'ENCRYPTION_FAILED':
        return 'Failed to encrypt data';
      case 'DECRYPTION_FAILED':
        return 'Failed to decrypt data';
      case 'KEY_NOT_FOUND':
        return 'Encryption key not found';

      default:
        return error.message;
    }
  }
}
