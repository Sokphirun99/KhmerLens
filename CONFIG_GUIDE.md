# Configuration Guide

This guide explains how to configure KhmerScan with your own IDs and API keys.

> [!IMPORTANT]
> **Security Notice**: The `lib/config/` folder is gitignored to protect your sensitive IDs and API keys. Template files are provided for team members to set up their own configuration.

## 🔒 First-Time Setup

If you're setting up this project for the first time:

1. Copy the template files:
   ```bash
   cp lib/config/ad_config.dart.template lib/config/ad_config.dart
   cp lib/config/app_config.dart.template lib/config/app_config.dart
   ```

2. Follow the steps below to configure your IDs

## 📁 Configuration Files

All configuration values are centralized in the `lib/config` folder:

- **[lib/config/app_config.dart](file:///Users/phirun/Projects_Personal/KhmerScan/lib/config/app_config.dart)** - App-level settings (database, storage, OCR, etc.)
- **[lib/config/ad_config.dart](file:///Users/phirun/Projects_Personal/KhmerScan/lib/config/ad_config.dart)** - AdMob IDs for ads

## 🎯 Quick Start: Update Your AdMob IDs

### Step 1: Get Your AdMob IDs

1. Go to [AdMob Console](https://apps.admob.com/)
2. Create or select your app
3. Get the following IDs:
   - **App ID** (one for Android, one for iOS)
   - **Banner Ad Unit ID** (one for Android, one for iOS)
   - **Interstitial Ad Unit ID** (one for Android, one for iOS)

### Step 2: Update Configuration Files

#### Update `lib/config/ad_config.dart`

Replace the test IDs with your production IDs:

```dart
class AdConfig {
  // Replace these with your actual AdMob App IDs
  static const String androidAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
  static const String iosAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  // Replace these with your actual Banner Ad Unit IDs
  static const String androidBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String iosBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Replace these with your actual Interstitial Ad Unit IDs
  static const String androidInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
}
```

#### Update `android/app/src/main/AndroidManifest.xml`

Find the AdMob App ID meta-data tag and update it:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

#### Update `ios/Runner/Info.plist`

Find the GADApplicationIdentifier key and update it:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### Step 3: Test Your Configuration

Run the app and verify that ads are loading correctly:

```bash
flutter run
```

## ⚙️ Other Configuration Options

### App Information

Update app name, version, and package name in [lib/config/app_config.dart](file:///Users/phirun/Projects_Personal/KhmerScan/lib/config/app_config.dart):

```dart
static const String appName = 'KhmerScan';
static const String appVersion = '1.0.0';
static const String packageName = 'com.krstudio.khmerscan';
```

### Storage Limits

Adjust image quality and size limits:

```dart
static const int maxImageWidth = 1920;
static const int maxImageHeight = 2560;
static const int jpegQuality = 85;
```

### Ad Behavior

Change how often interstitial ads are shown:

```dart
static const int scansBeforeInterstitial = 3; // Show ad every 3 scans
```

### OCR Settings

Configure OCR language and confidence threshold:

```dart
static const String defaultLanguage = 'km'; // Khmer
static const double minConfidence = 0.5;
```

## 🔑 Adding API Keys

To add API keys for external services (Firebase, cloud storage, etc.):

1. Open [lib/config/app_config.dart](file:///Users/phirun/Projects_Personal/KhmerScan/lib/config/app_config.dart)
2. Add your API keys in the "API Keys & External Services" section:

```dart
// API Keys & External Services
static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
static const String cloudStorageUrl = 'YOUR_CLOUD_STORAGE_URL';
```

## 📝 Notes

- **Test IDs**: The app currently uses AdMob test IDs. These will show test ads but won't generate revenue.
- **Production IDs**: Replace test IDs with your production IDs before releasing to production.
- **Platform-Specific**: AdMob requires separate IDs for Android and iOS.
- **Backward Compatibility**: The old `AppConstants` class still works but now uses `AppConfig` internally.

## 🚀 Next Steps

After updating your configuration:

1. Test the app thoroughly
2. Verify ads are loading correctly
3. Check that all features work as expected
4. Build and release your app

For more information, see the [AdMob documentation](https://developers.google.com/admob).
