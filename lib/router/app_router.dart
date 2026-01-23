// router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document.dart';
import '../screens/camera_screen.dart';
import '../screens/document_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';

/// App route paths
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String documentDetail = '/document/:id';
  static const String search = '/search';
  static const String settings = '/settings';
}

/// GoRouter configuration for the app
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Home screen
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Camera screen
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
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

  /// Navigate to camera
  void goToCamera() => go(AppRoutes.camera);

  /// Push to camera (preserves back stack)
  Future<T?> pushCamera<T>() => push<T>(AppRoutes.camera);

  /// Navigate to search
  void goToSearch() => go(AppRoutes.search);

  /// Push to search (preserves back stack)
  void pushSearch() => push(AppRoutes.search);

  /// Navigate to settings
  void goToSettings() => go(AppRoutes.settings);

  /// Push to settings (preserves back stack)
  void pushSettings() => push(AppRoutes.settings);

  /// Navigate to home
  void goToHome() => go(AppRoutes.home);
}
