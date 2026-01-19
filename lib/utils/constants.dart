import 'package:flutter/material.dart';

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

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'birthCertificate': Color(0xFFE91E63), // Pink
    'nationalID': Color(0xFF2196F3), // Blue
    'familyBook': Color(0xFF4CAF50), // Green
    'marriageCertificate': Color(0xFFF44336), // Red
    'other': Color(0xFFFF9800), // Orange
  };

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'id': '1', 'name': 'All', 'icon': '📄', 'color': 0xFF2196F3},
    {'id': '2', 'name': 'Receipts', 'icon': '🧾', 'color': 0xFF4CAF50},
    {'id': '3', 'name': 'Invoices', 'icon': '📋', 'color': 0xFFFF9800},
    {'id': '4', 'name': 'ID Cards', 'icon': '🪪', 'color': 0xFF9C27B0},
    {'id': '5', 'name': 'Contracts', 'icon': '📝', 'color': 0xFFF44336},
    {'id': '6', 'name': 'Notes', 'icon': '📓', 'color': 0xFF00BCD4},
  ];
}
