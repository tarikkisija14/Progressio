import 'package:progressio_mobile/model/feed_item.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class FeedProvider extends BaseProvider<FeedItem> {
  FeedProvider() : super('feed');

  @override
  FeedItem fromJson(dynamic json) => FeedItem.fromJson(json);

  Future<List<FeedItem>> getFeed({int page = 1}) async {
    final result = await get(filter: {'page': page, 'pageSize': 20});
    return result.items;
  }
}