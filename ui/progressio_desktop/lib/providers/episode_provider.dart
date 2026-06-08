import 'package:progressio_desktop/model/episode.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class EpisodeProvider extends BaseProvider<Episode> {
  EpisodeProvider() : super('episodes');

  @override
  Episode fromJson(dynamic json) => Episode.fromJson(json);
}