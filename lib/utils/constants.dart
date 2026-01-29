import '../config/app_config.dart';

/// Legacy constants class - now uses AppConfig
///
/// This class is maintained for backward compatibility.
/// Consider migrating to AppConfig directly in new code.
class AppConstants {
  // App info
  static const String appName = AppConfig.appName;
  static const String appVersion = AppConfig.appVersion;

  // Storage Keys
  static const String keyThemeMode = AppConfig.keyThemeMode;
  static const String keyLanguage = AppConfig.keyLanguage;
  static const String keyFirstLaunch = AppConfig.keyFirstLaunch;

  // Database
  static const String databaseName = AppConfig.databaseName;
  static const int databaseVersion = AppConfig.databaseVersion;

  // Storage limits (free tier)
  static const int maxDocuments = AppConfig.maxDocuments;
  static const int maxImageWidth = AppConfig.maxImageWidth;
  static const int maxImageHeight = AppConfig.maxImageHeight;
  static const int jpegQuality = AppConfig.jpegQuality;

  // OCR Settings
  static const String defaultLanguage = AppConfig.defaultLanguage;
  static const double minConfidence = AppConfig.minConfidence;

  // Ad settings
  static const int scansBeforeInterstitial = AppConfig.scansBeforeInterstitial;

  // Animation durations
  static const Duration shortAnimation = AppConfig.shortAnimation;
  static const Duration mediumAnimation = AppConfig.mediumAnimation;
  static const Duration longAnimation = AppConfig.longAnimation;
}
