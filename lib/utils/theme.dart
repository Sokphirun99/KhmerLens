import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE (The "Cozy Paper" Look) ---

  // Backgrounds
  static const Color _paperWhite = Color(0xFFF9F7F2); // Warm, like old paper
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _darkPaper = Color(0xFF1E1E1E); // Soft black for dark mode

  // Primary Accents (Sage Green & Sunset)
  static const Color _sageGreen = Color(0xFF7FA087); // Calming primary
  static const Color _sageDark = Color(0xFF5D7A63); // For dark mode
  static const Color _sunsetOrange = Color(0xFFE09F7D); // Secondary accents

  // Text Colors (Ink) - Maximum Contrast
  static const Color _inkBlack = Color(0xFF1A1C1E); // Almost Pure Black
  static const Color _inkGrey = Color(0xFF444746); // Deep Grey
  static const Color _inkLight = Color(0xFF747775);

  // Status Colors
  static const Color _errorRed = Color(0xFFBA1A1A); // Darker Error Red
  static const Color _successGreen = Color(0xFF146C2E);

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _sageGreen,
      scaffoldBackgroundColor: _paperWhite,

      // Typography
      // Primary: Roboto (English/Latin)
      // Fallback: Siemreap (Khmer) - User requested specific combo
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: _inkBlack,
        displayColor: _inkBlack,
        fontFamilyFallback: [GoogleFonts.siemreap().fontFamily ?? 'Siemreap'],
      ),

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: _sageGreen,
        onPrimary: Colors.white,
        secondary: _sunsetOrange,
        onSecondary: Colors.white,
        surface: _pureWhite,
        onSurface: _inkBlack,
        onSurfaceVariant: _inkGrey,
        error: _errorRed,
        outline: _inkLight,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: _paperWhite,
        foregroundColor: _inkBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          color: _inkBlack,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          // Fallback for Khmer title text
          textStyle: TextStyle(
            fontFamilyFallback: [
              GoogleFonts.siemreap().fontFamily ?? 'Siemreap'
            ],
          ),
        ),
      ),

      // Cards (The "Physical" feel)
      cardTheme: CardThemeData(
        color: _pureWhite,
        elevation: 2,
        shadowColor: _inkBlack.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Softer corners
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _sageGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _sageGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _sageGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _sageDark,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark

      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(
        fontFamilyFallback: [GoogleFonts.siemreap().fontFamily ?? 'Siemreap'],
      ),

      colorScheme: const ColorScheme.dark(
        primary: _sageDark,
        onPrimary: Colors.white,
        secondary: _sunsetOrange,
        surface: _darkPaper,
        onSurface: Color(0xFFE3E3E3), // Brighter white for dark mode
        onSurfaceVariant: Color(0xFFC4C7C5), // Lighter grey for subtitles
        outline: _inkGrey,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: _darkPaper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: _inkGrey.withValues(
                  alpha: 0.2)), // Subtle border in dark mode
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _sageDark,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// RESTORED HELPERS
class AppSpacing {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingMd = EdgeInsets.all(md);
}

class AppRadius {
  static final BorderRadius borderRadiusXs = BorderRadius.circular(4.0);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(8.0);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(12.0);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(16.0);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(24.0);
}
