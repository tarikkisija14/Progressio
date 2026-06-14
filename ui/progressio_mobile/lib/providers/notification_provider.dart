import 'package:progressio_mobile/model/notification_item.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class NotificationProvider extends BaseProvider<NotificationItem> {
  NotificationProvider() : super('notifications');

  @override
  NotificationItem fromJson(dynamic json) => NotificationItem.fromJson(json);

  Future<List<NotificationItem>> getMyNotifications() async {
    final result = await get(filter: {'page': 1, 'pageSize': 30});
    return result.items;
  }

  Future<void> markRead(int id) async {
    await putRaw('notifications/$id/read', {});
  }
}