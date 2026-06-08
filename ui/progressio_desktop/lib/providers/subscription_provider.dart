import 'package:progressio_desktop/model/subscription.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

// NOTE: Backend exposes only GET /api/subscriptions/me (current user).
// A GET /api/admin/subscriptions endpoint is required for full admin listing.
class SubscriptionProvider extends BaseProvider<Subscription> {
  SubscriptionProvider() : super('subscriptions');

  @override
  Subscription fromJson(dynamic json) => Subscription.fromJson(json);

  Future<Subscription?> getMySubscription() async {
    try {
      final data = await getRaw('subscriptions/me');
      if (data == null) return null;
      return Subscription.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}