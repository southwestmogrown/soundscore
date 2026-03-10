/// Manages AdMob banner and interstitial ads.
/// Ads are suppressed when the user holds a Pro entitlement.
/// Full implementation in Phase 6.
abstract class AdService {
  Future<void> initialize();
  Future<void> showInterstitial();
  void dispose();
}
