import 'package:progressio_mobile/model/review.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('reviews');

  @override
  Review fromJson(dynamic json) => Review.fromJson(json);

  Future<List<Review>> getForContent(int contentId, {bool hideSpoilers = false}) async {
    final data = await getRaw(
      'reviews/$contentId',
      query: {'hideSpoilers': hideSpoilers, 'page': 1, 'pageSize': 20},
    );
    if (data is List) return data.map((e) => Review.fromJson(e)).toList();
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => Review.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createReview(int contentId, int rating, String? title, String? body, bool hasSpoiler) async {
    await postRaw('reviews', {
      'contentId': contentId,
      'rating': rating,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'hasSpoiler': hasSpoiler,
    });
  }
}