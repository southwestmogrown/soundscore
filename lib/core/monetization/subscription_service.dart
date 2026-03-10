/// Wraps RevenueCat to expose Pro entitlement status.
/// Full implementation in Phase 6.
abstract class SubscriptionService {
  /// Stream that emits true when the user has an active Pro entitlement.
  Stream<bool> get isPro;

  Future<void> initialize();
  Future<void> purchasePro();
  Future<void> restorePurchases();
  void dispose();
}
