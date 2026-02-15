import 'dart:io';
import 'package:flutter/foundation.dart';

/// AdMob configuration for the app.
///
/// IMPORTANT: Replace test IDs with your production AdMob IDs before release.
/// Get your AdMob IDs from: https://apps.admob.com/
class AdConfig {
  // AdMob App IDs (shown in AndroidManifest.xml and Info.plist)
  static const String androidAppId = 'ca-app-pub-9315602388069795~6456220681';
  static const String iosAppId = 'ca-app-pub-9315602388069795~2528244653';

  // Production Banner Ad Unit IDs
  static const String _productionAndroidBannerAdUnitId =
      'ca-app-pub-9315602388069795/3721472056';
  static const String _productionIosBannerAdUnitId =
      'ca-app-pub-9315602388069795/3270480686';

  // Production Interstitial Ad Unit IDs
  static const String _productionAndroidInterstitialAdUnitId =
      'ca-app-pub-9315602388069795/4583562358';
  static const String _productionIosInterstitialAdUnitId =
      'ca-app-pub-9315602388069795/8814016635';

  // Official AdMob Test IDs
  static const String _testAndroidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testAndroidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Get the appropriate banner ad unit ID for the current platform
  /// Returns Test ID in debug mode, Production ID in release mode
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _testAndroidBannerAdUnitId;
      if (Platform.isIOS) return _testIosBannerAdUnitId;
    } else {
      if (Platform.isAndroid) return _productionAndroidBannerAdUnitId;
      if (Platform.isIOS) return _productionIosBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the appropriate interstitial ad unit ID for the current platform
  /// Returns Test ID in debug mode, Production ID in release mode
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _testAndroidInterstitialAdUnitId;
      if (Platform.isIOS) return _testIosInterstitialAdUnitId;
    } else {
      if (Platform.isAndroid) return _productionAndroidInterstitialAdUnitId;
      if (Platform.isIOS) return _productionIosInterstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }
}
