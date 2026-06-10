import 'package:progressio_mobile/model/season.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class SeasonProvider extends BaseProvider<Season> {
  SeasonProvider() : super('seasons');

  @override
  Season fromJson(dynamic json) => Season.fromJson(json);
}