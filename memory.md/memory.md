# Project Memory: KhmerScan

## 1. Core Architecture
- **Framework**: Flutter
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Navigation**: GoRouter (`AppRouter`)
- **Dependency Injection**: `RepositoryProvider` & `MultiBlocProvider` at the root (`App`).

## 2. Data Layer
- **Database**: `sqflite` (SQLite)
    - **Service**: `DatabaseService` (Singleton).
    - **Tables**: 
        - `documents`: Stores user-scanned documents.
        - `scanned_products`: Stores barcode scan history.
- **Models**: Manual serialization (`fromMap`/`toMap`), no code generation observed for models.
    - **Key Entity**: `Document` (id, title, imagePaths, extractedText).

## 3. Key Services & Features
- **Firebase Integrations**:
    - Core, Crashlytics, Messaging (FCM), Analytics, Performance.
    - `NotificationService` handles local & remote notifications.
- **Monetization**:
    - **Ads**: AdMob (`google_mobile_ads`) configured via `lib/config/ad_config.dart`.
- **Scanning**:
    - Document scanning: `cunning_document_scanner`.
    - Barcode/QR: `mobile_scanner`.
    - OCR/Labeling: `google_mlkit_...`
- **Localization**: Supported via `flutter_localizations` & `LocaleCubit`.

## 4. Configuration & Environment
- **Secrets Management**: `lib/config/` folder contains sensitive configurations (e.g., `ad_config.dart`, `app_config.dart`) and is `.gitignore`d.
- **Themes**: `ThemeCubit` manages `AppTheme.lightTheme` and `darkTheme`.
- **Device Support**: Portrait orientation locked.

## 5. Development Conventions
- **Error Handling**: Global error catching with `runZonedGuarded` -> Firebase Crashlytics.
- **Assets**: Managed in `pubspec.yaml`, icons generated via `flutter_launcher_icons`.
- **OCR Implementation**:
    - **Engine**: `flutter_tesseract_ocr` (Tesseract) with custom `khm.traineddata`.
    - **Permissions**: iOS requires manually copying `tessdata` to `ApplicationDocumentsDirectory`.
    - **Optimization**: Input images are preprocessed (Resize > 2000px, Grayscale, Contrast +50%) via `image` package to improve accuracy.
    - **Git Policy**: `assets/` folder (containing large `tessdata` files) is `.gitignore`d to keep repo size small, but files are present locally.

## 6. Project Evolution & Memory Protocol
- **Scaling Protocol**: This document must be updated whenever major architectural changes, new services, or significant refactoring occurs.
- **Context Source**: The AI should always review this file at the start of a session to understand the project's current state and conventions.
