// lib/providers/recommendation_provider.dart

import 'package:progressio_mobile/model/recommendation.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class RecommendationProvider extends BaseProvider<Recommendation> {
  RecommendationProvider() : super('recommendations');

  @override
  Recommendation fromJson(dynamic json) => Recommendation.fromJson(json);


  Future<List<Recommendation>> getRecommendations({int count = 20}) async {
    final data = await getRaw('recommendations', query: {'count': count});
    if (data is List) {
      return data.map((e) => Recommendation.fromJson(e)).toList();
    }
    // Fallback ako se vrati paginiran odgovor
    if (data is Map && data['items'] != null) {
      return (data['items'] as List)
          .map((e) => Recommendation.fromJson(e))
          .toList();
    }
    return [];
  }
}