import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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
        await Firebase.initializeApp();

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

      // Initialize AdMob with error handling
      try {
        await AdService().initialize();
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('AdService initialization failed: $e');
          ErrorHandler.logError(e, stackTrace: stackTrace);
        }
        // Continue running the app even if ads fail to initialize
      }

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
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DocumentRepository _documentRepository;

  @override
  void initState() {
    super.initState();
    _documentRepository = DocumentRepository();
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
                  title: 'KhmerScan',
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
