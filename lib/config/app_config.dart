/// Application-wide configuration constants.
///
/// This file centralizes all app configuration values for easy management.
/// Update values here instead of searching through multiple files.
class AppConfig {
  // ============================================================================
  // App Information
  // ============================================================================

  static const String appName = 'KhmerLens';
  static const String appVersion = '1.0.1+3';
  static const String packageName =
      'com.krstudio.khmerscan'; // TODO: Update if needed

  // ============================================================================
  // Storage Keys (SharedPreferences)
  // ============================================================================

  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFirstLaunch = 'first_launch';

  // ============================================================================
  // Database Configuration
  // ============================================================================

  static const String databaseName = 'khmerscan.db';
  static const int databaseVersion = 1;

  // ============================================================================
  // Storage Limits
  // ============================================================================

  static const int maxDocuments = 999999; // Unlimited
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 2560;
  static const int jpegQuality = 85;

  // ============================================================================
  // OCR Settings
  // ============================================================================

  static const String defaultLanguage = 'en'; // English
  static const double minConfidence = 0.5;

  // ============================================================================
  // Ad Behavior Settings
  // ============================================================================

  /// Number of scans before showing an interstitial ad
  static const int scansBeforeInterstitial = 1;

  // ============================================================================
  // Animation Durations
  // ============================================================================

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // ============================================================================
  // API Keys & External Services
  // ============================================================================

  // NOTE: Firebase API keys are handled automatically by lib/firebase_options.dart
  // Do not manually add them here to avoid version control leaks.

  static const String usdaApiKey = String.fromEnvironment('USDA_API_KEY');
  static const String spoonacularApiKey =
      String.fromEnvironment('SPOONACULAR_API_KEY');
  static const String openFdaApiKey =
      String.fromEnvironment('OPEN_FDA_API_KEY');
  static const String cloudmersiveApiKey =
      String.fromEnvironment('CLOUDMERSIVE_API_KEY');
}
