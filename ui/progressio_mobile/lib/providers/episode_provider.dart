import 'package:progressio_mobile/model/episode.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class EpisodeProvider extends BaseProvider<Episode> {
  EpisodeProvider() : super('episodes');

  @override
  Episode fromJson(dynamic json) => Episode.fromJson(json);
}