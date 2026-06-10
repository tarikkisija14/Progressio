import 'package:progressio_mobile/model/recommendation.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class RecommendationProvider extends BaseProvider<Recommendation> {
  RecommendationProvider() : super('recommendations');

  @override
  Recommendation fromJson(dynamic json) => Recommendation.fromJson(json);

  Future<List<Recommendation>> getRecommendations() async {
    final result = await get(filter: {'page': 1, 'pageSize': 20});
    return result.items;
  }
}