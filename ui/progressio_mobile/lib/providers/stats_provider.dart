import 'package:progressio_mobile/model/stats.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class StatsProvider extends BaseProvider<BasicStats> {
  StatsProvider() : super('stats');

  @override
  BasicStats fromJson(dynamic json) => BasicStats.fromJson(json);

  Future<BasicStats> getBasicStats() async {
    final data = await getRaw('stats/me');
    return BasicStats.fromJson(data);
  }

  Future<PremiumStats> getPremiumStats() async {
    final data = await getRaw('stats/me/premium');
    return PremiumStats.fromJson(data);
  }
}