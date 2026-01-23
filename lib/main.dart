// main.dart
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
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize AdMob
  await AdService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create repository
    final documentRepository = DocumentRepository();
    final ocrService = OCRService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: documentRepository),
        RepositoryProvider.value(value: ocrService),
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
              repository: documentRepository,
            )..add(const LoadDocuments()),
          ),
          // OCR bloc
          BlocProvider(
            create: (context) => OCRBloc(
              ocrService: ocrService,
              documentRepository: documentRepository,
            ),
          ),
          // Search bloc
          BlocProvider(
            create: (context) => SearchBloc(
              repository: documentRepository,
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
