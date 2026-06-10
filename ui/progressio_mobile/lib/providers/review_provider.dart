import 'package:progressio_mobile/model/review.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super('reviews');

  @override
  Review fromJson(dynamic json) => Review.fromJson(json);

  /// GET /api/reviews/{contentId}?hideSpoilers=false&page=1&pageSize=20
  Future<List<Review>> getForContent(int contentId,
      {bool hideSpoilers = false}) async {
    final data = await getRaw(
      'reviews/$contentId',
      query: {
        'hideSpoilers': hideSpoilers,
        'page': 1,
        'pageSize': 20,
      },
    );
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => Review.fromJson(e)).toList();
    }
    if (data is List) {
      return data.map((e) => Review.fromJson(e)).toList();
    }
    return [];
  }

  /// GET /api/reviews/my/{contentId}
  Future<Review?> getMyReview(int contentId) async {
    try {
      final data = await getRaw('reviews/my/$contentId');
      return Review.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/reviews
  Future<Review> createReview({
    required int contentId,
    required int rating,
    String? title,
    String? body,
    bool hasSpoiler = false,
  }) async {
    final data = await postRaw('reviews', {
      'contentId': contentId,
      'rating': rating,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'hasSpoiler': hasSpoiler,
    });
    return Review.fromJson(data);
  }

  /// PUT /api/reviews/{reviewId}
  Future<Review> updateReview(
    int reviewId, {
    required int rating,
    String? title,
    String? body,
    bool hasSpoiler = false,
  }) async {
    final data = await update(reviewId, {
      'rating': rating,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      'hasSpoiler': hasSpoiler,
    });
    return data;
  }

  /// DELETE /api/reviews/{reviewId}  (Admin only)
  Future<void> adminDelete(int reviewId) async {
    await delete(reviewId);
  }
}