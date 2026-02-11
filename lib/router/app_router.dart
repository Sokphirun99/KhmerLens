// router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document.dart';

import '../screens/dashboard_screen.dart';
import '../screens/document_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_scan_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/web_view_screen.dart';

import '../features/ocr/ocr_scan_screen.dart';

/// App route paths
class AppRoutes {
  static const String dashboard = '/';
  static const String documents = '/documents';
  static const String camera = '/camera';
  static const String documentDetail = '/document/:id';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String productScan = '/product-scan';
  static const String ocrScan = '/ocr-scan';
  static const String webView = '/webview';
}

/// GoRouter configuration for the app
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    routes: [
      // Dashboard (new home)
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Documents list (previous home)
      GoRoute(
        path: AppRoutes.documents,
        name: 'documents',
        builder: (context, state) => const HomeScreen(),
      ),

      // Document detail screen
      GoRoute(
        path: AppRoutes.documentDetail,
        name: 'document-detail',
        builder: (context, state) {
          final document = state.extra as Document;
          return DocumentDetailScreen(document: document);
        },
      ),

      // Search screen
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Settings screen
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Product scan screen
      GoRoute(
        path: AppRoutes.productScan,
        name: 'product-scan',
        builder: (context, state) => const ProductScanScreen(),
      ),

      // OCR Scan screen
      GoRoute(
        path: AppRoutes.ocrScan,
        name: 'ocr-scan',
        builder: (context, state) => const OcrScanScreen(),
      ),

      // WebView Screen
      GoRoute(
        path: AppRoutes.webView,
        name: 'webview',
        builder: (context, state) {
          final args = state.extra as WebViewScreenArgs;
          return WebViewScreen(
            url: args.url,
            title: args.title,
          );
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" does not exist.',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extension for easy navigation
extension AppRouterExtension on BuildContext {
  /// Navigate to dashboard
  void goToDashboard() => go(AppRoutes.dashboard);

  /// Navigate to documents list
  void goToDocuments() => go(AppRoutes.documents);

  /// Push to documents list (preserves back stack)
  void pushDocuments() => push(AppRoutes.documents);

  /// Navigate to document detail
  void goToDocumentDetail(Document document) {
    go(
      AppRoutes.documentDetail.replaceFirst(':id', document.id),
      extra: document,
    );
  }

  /// Push to document detail (preserves back stack)
  void pushDocumentDetail(Document document) {
    push(
      AppRoutes.documentDetail.replaceFirst(':id', document.id),
      extra: document,
    );
  }

  /// Navigate to search
  void goToSearch() => go(AppRoutes.search);

  /// Push to search (preserves back stack)
  void pushSearch() => push(AppRoutes.search);

  /// Navigate to settings
  void goToSettings() => go(AppRoutes.settings);

  /// Push to settings (preserves back stack)
  void pushSettings() => push(AppRoutes.settings);

  /// Navigate to product scan
  void goToProductScan() => go(AppRoutes.productScan);

  /// Push to product scan (preserves back stack)
  void pushProductScan() => push(AppRoutes.productScan);

  /// Navigate to OCR scan
  void goToOcrScan() => go(AppRoutes.ocrScan);

  /// Push to OCR scan
  void pushOcrScan() => push(AppRoutes.ocrScan);

  /// Navigate to home (dashboard)
  void goToHome() => go(AppRoutes.dashboard);

  /// Push to WebView
  void pushWebView({required String url, required String title}) {
    push(
      AppRoutes.webView,
      extra: WebViewScreenArgs(url: url, title: title),
    );
  }
}
