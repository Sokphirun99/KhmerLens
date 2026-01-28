import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();

  factory RatingService() {
    return _instance;
  }

  RatingService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Keys for SharedPreferences
  static const String _kLastReviewRequestDate = 'last_review_request_date';
  static const String _kTotalScans = 'total_scans_count';

  // Configuration
  static const int _minScansBeforeRating = 3;
  static const int _daysBetweenRequests = 14;

  /// Open the store listing for manual rating/review
  Future<void> openStoreListing() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.openStoreListing();
      } else {
        debugPrint('RatingService: Store listing not available');
      }
    } catch (e) {
      debugPrint('RatingService: Error opening store listing: $e');
    }
  }

  /// Check conditions and request review if appropriate
  Future<void> trackEvent({bool isScan = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (isScan) {
        int currentScans = prefs.getInt(_kTotalScans) ?? 0;
        currentScans++;
        await prefs.setInt(_kTotalScans, currentScans);

        if (currentScans < _minScansBeforeRating) {
          debugPrint(
              'RatingService: Not enough scans ($currentScans/$_minScansBeforeRating)');
          return;
        }
      }

      // Check time since last request
      final lastRequestMs = prefs.getInt(_kLastReviewRequestDate);
      if (lastRequestMs != null) {
        final lastRequestDate =
            DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
        final difference = DateTime.now().difference(lastRequestDate).inDays;

        if (difference < _daysBetweenRequests) {
          debugPrint(
              'RatingService: Too soon to request again (Last: $difference days ago)');
          return;
        }
      }

      // If we got here, we can try to request a review
      // Note: isAvailable() returns false on Android if the Play Store is not installed,
      // or if the device is incompatible. On iOS it returns false if < iOS 10.3.
      if (await _inAppReview.isAvailable()) {
        debugPrint('RatingService: Requesting review...');
        await _inAppReview.requestReview();

        // Update last request date
        await prefs.setInt(
            _kLastReviewRequestDate, DateTime.now().millisecondsSinceEpoch);
      } else {
        debugPrint('RatingService: InAppReview not available');
      }
    } catch (e) {
      debugPrint('RatingService: Error tracking event: $e');
    }
  }
}
