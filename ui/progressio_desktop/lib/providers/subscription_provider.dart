import 'package:progressio_desktop/model/subscription.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class SubscriptionProvider extends BaseProvider<Subscription> {
  SubscriptionProvider() : super('admin/subscriptions');

  @override
  Subscription fromJson(dynamic json) => Subscription.fromJson(json);
}