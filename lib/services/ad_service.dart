import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  /// Initialize the Google Mobile Ads SDK and preload ads.
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    // Preload interstitial ad
    await loadInterstitialAd();
  }

  /// Legacy alias used in older code.
  Future<void> init() => initialize();

  /// Create a banner ad instance with proper listeners.
  BannerAd createBannerAd({
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: AdConfig.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          onAdFailedToLoad?.call(error);
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
      request: const AdRequest(),
    );
  }

  /// Load an interstitial ad for later showing.
  Future<void> loadInterstitialAd() async {
    // Avoid loading multiple times
    if (_isInterstitialAdLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialAdLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;

          // Set up callbacks for when the ad is shown
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              // Preload next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              // Retry loading
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  /// Show the interstitial ad if loaded.
  /// Returns true if ad was shown, false otherwise.
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      return true;
    } else {
      debugPrint('Interstitial ad not ready, loading for next time');
      loadInterstitialAd();
      return false;
    }
  }

  /// Check if interstitial ad is ready to show.
  bool get isInterstitialAdReady => _interstitialAd != null;

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
