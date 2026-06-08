import 'package:progressio_desktop/model/season.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class SeasonProvider extends BaseProvider<Season> {
  SeasonProvider() : super('seasons');

  @override
  Season fromJson(dynamic json) => Season.fromJson(json);
}