class AppConstants {
  // App info
  static const String appName = 'KhmerScan';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFirstLaunch = 'first_launch';

  // Database
  static const String databaseName = 'khmerscan.db';
  static const int databaseVersion = 1;

  // Storage limits (free tier)
  static const int maxDocuments = 999999; // Unlimited
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 2560;
  static const int jpegQuality = 85;

  // OCR Settings
  static const String defaultLanguage = 'km';
  static const double minConfidence = 0.5;

  // Ad settings
  static const int scansBeforeInterstitial = 3;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
