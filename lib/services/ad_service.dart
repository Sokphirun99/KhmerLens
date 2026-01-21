import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;

  /// Initialize the Google Mobile Ads SDK.
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Legacy alias used in older code.
  Future<void> init() => initialize();

  /// Create a simple banner ad instance.
  BannerAd createBannerAd() {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: '<YOUR-BANNER-AD-UNIT-ID>',
      listener: const BannerAdListener(),
      request: const AdRequest(),
    );
  }

  /// Load an interstitial ad for later showing.
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: '<YOUR-INTERSTITIAL-AD-UNIT-ID>',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show the interstitial ad if loaded.
  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      await loadInterstitialAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
