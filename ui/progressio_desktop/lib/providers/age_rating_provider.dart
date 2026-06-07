import 'package:progressio_desktop/model/age_rating.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class AgeRatingProvider extends BaseProvider<AgeRating> {
  AgeRatingProvider() : super('age-ratings');

  @override
  AgeRating fromJson(dynamic json) => AgeRating.fromJson(json);
}