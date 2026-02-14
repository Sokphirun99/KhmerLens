import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

import 'bloc/document/document_bloc.dart';
import 'bloc/document/document_event.dart';
import 'bloc/locale/locale_cubit.dart';
import 'bloc/search/search_bloc.dart';
import 'bloc/theme/theme_cubit.dart';
import 'repositories/document_repository.dart';
import 'router/app_router.dart';
import 'services/ad_service.dart';
import 'services/storage_service.dart';
import 'utils/error_handler.dart';
import 'utils/theme.dart';

void main() async {
  // Catch async errors not handled by Flutter framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        if (kReleaseMode) {
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
        } else {
          FlutterError.onError = (FlutterErrorDetails details) {
            FlutterError.presentError(details);
            ErrorHandler.logError(details.exception, stackTrace: details.stack);
          };
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('Firebase initialization failed: $e');
          ErrorHandler.logError(e, stackTrace: stackTrace);
        }
      }

      // Initialize Anonymous Auth
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint(
            'Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}');
      } catch (e) {
        debugPrint('Anonymous sign-in failed: $e');
        // Non-fatal, app can still function (read-only for products)
      }

      // Initialize Storage Service (Sync support)
      try {
        await StorageService().init();
      } catch (e) {
        debugPrint('StorageService initialization failed: $e');
      }

      // Initialize AdMob (Non-blocking)
      AdService().initialize().catchError((e) {
        if (kDebugMode) {
          debugPrint('AdService initialization failed: $e');
        }
      });

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize Notification Service
      try {
        await NotificationService().initialize();
      } catch (e) {
        debugPrint('NotificationService initialization failed: $e');
      }

      // Set OpenFoodFacts UserAgent
      OpenFoodAPIConfiguration.userAgent =
          UserAgent(name: 'KhmerLens', url: 'https://khmerscan.app');

      runApp(const MyApp());
    },
    (error, stackTrace) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance
            .recordError(error, stackTrace, fatal: true);
      } else {
        debugPrint('Unhandled error: $error');
        ErrorHandler.logError(error, stackTrace: stackTrace);
      }
    },
  );
}

class MyApp extends StatefulWidget {
  final DocumentRepository? documentRepository;

  const MyApp({
    super.key,
    this.documentRepository,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DocumentRepository _documentRepository;

  @override
  void initState() {
    super.initState();
    _documentRepository = widget.documentRepository ?? DocumentRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _documentRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme cubit
          BlocProvider(
            create: (context) => ThemeCubit(),
          ),
          // Locale cubit
          BlocProvider(
            create: (context) => LocaleCubit(),
          ),
          // Document bloc
          BlocProvider(
            create: (context) => DocumentBloc(
              repository: _documentRepository,
            )..add(const LoadDocuments()),
          ),
          // Search bloc
          BlocProvider(
            create: (context) => SearchBloc(
              repository: _documentRepository,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, localeState) {
                return MaterialApp.router(
                  title: 'KhmerLens',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: context.read<ThemeCubit>().themeMode,
                  locale: context.read<LocaleCubit>().locale,
                  routerConfig: AppRouter.router,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler:
                            TextScaler.linear(themeState.textScaleFactor),
                      ),
                      child: child!,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
