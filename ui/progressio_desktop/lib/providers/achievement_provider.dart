import 'package:progressio_desktop/model/achievement.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class AchievementProvider extends BaseProvider<Achievement> {
  AchievementProvider() : super('achievements');

  @override
  Achievement fromJson(dynamic json) => Achievement.fromJson(json);
}