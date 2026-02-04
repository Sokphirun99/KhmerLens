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
  final isMounted = useIsMounted();

  useEffect(() {
    debugPrint('useBannerAd: Initializing Banner Ad');
    final ad = AdService().createBannerAd()
      ..load().then((_) {
        if (isMounted()) {
          debugPrint('useBannerAd: Ad loaded successfully');
          isBannerAdReady.value = true;
        }
      }).catchError((e) {
        if (isMounted()) {
          debugPrint('useBannerAd: Failed to load ad: $e');
        }
      });

    bannerAd.value = ad;

    return () {
      debugPrint('useBannerAd: Disposing Banner Ad');
      ad.dispose();
    };
  }, []);

  return (bannerAd.value, isBannerAdReady.value);
}
