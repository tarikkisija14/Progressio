import 'package:progressio_mobile/model/subscription.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class SubscriptionProvider extends BaseProvider<Subscription> {
  SubscriptionProvider() : super('subscriptions');

  @override
  Subscription fromJson(dynamic json) => Subscription.fromJson(json);

  Future<Subscription?> getMine() async {
    try {
      final data = await getRaw('subscriptions/me');
      return Subscription.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}