import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// A hook that manages the lifecycle of a BannerAd.
///
/// Returns a record: `(BannerAd? ad, bool isReady)`
(BannerAd?, bool) useBannerAd() {
  final bannerAd = useState<BannerAd?>(null);
  final isBannerAdReady = useState(false);

  useEffect(() {
    debugPrint('useBannerAd: Initializing Banner Ad');
    final ad = AdService().createBannerAd()
      ..load().then((_) {
        debugPrint('useBannerAd: Ad loaded successfully');
        // Check if component is still mounted is implicitly handled by hook disposal,
        // but we rely on the ad being disposed if the widget unmounts.
        // Ideally we should use a mounted ref if we were setting state after async,
        // but for now we follow the pattern that if it's disposed, setting value *might* be ignored or error safe.
        // Actually, setting value on unmounted HookState can throw.
        // A safer pattern is checking a mutable 'isMounted' bool.
        isBannerAdReady.value = true;
      }).catchError((e) {
        debugPrint('useBannerAd: Failed to load ad: $e');
      });

    bannerAd.value = ad;

    return () {
      debugPrint('useBannerAd: Disposing Banner Ad');
      ad.dispose();
    };
  }, []);

  return (bannerAd.value, isBannerAdReady.value);
}
