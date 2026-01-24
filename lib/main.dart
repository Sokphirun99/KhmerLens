// main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/document/document_bloc.dart';
import 'bloc/document/document_event.dart';
import 'bloc/ocr/ocr_bloc.dart';
import 'bloc/search/search_bloc.dart';
import 'bloc/theme/theme_cubit.dart';
import 'repositories/document_repository.dart';
import 'router/app_router.dart';
import 'services/ocr_service.dart';
import 'services/ad_service.dart';
import 'utils/error_handler.dart';
import 'utils/theme.dart';

void main() async {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      ErrorHandler.logError(details.exception, stackTrace: details.stack);
    }
  };

  // Catch async errors not handled by Flutter framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

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
      if (kDebugMode) {
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
  late final OCRService _ocrService;

  @override
  void initState() {
    super.initState();
    _documentRepository = DocumentRepository();
    _ocrService = OCRService();
  }

  @override
  void dispose() {
    // Dispose OCR service to release resources
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _documentRepository),
        RepositoryProvider.value(value: _ocrService),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme cubit
          BlocProvider(
            create: (context) => ThemeCubit(),
          ),
          // Document bloc
          BlocProvider(
            create: (context) => DocumentBloc(
              repository: _documentRepository,
            )..add(const LoadDocuments()),
          ),
          // OCR bloc
          BlocProvider(
            create: (context) => OCRBloc(
              ocrService: _ocrService,
              documentRepository: _documentRepository,
            ),
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
            return MaterialApp.router(
              title: 'KhmerScan',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: context.read<ThemeCubit>().themeMode,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
