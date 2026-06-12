import 'package:progressio_mobile/providers/base_provider.dart';

class VoteProvider extends BaseProvider<dynamic> {
  VoteProvider() : super('character-votes');

  @override
  dynamic fromJson(dynamic json) => json;

  Future<void> vote({
    required int characterId,
    int? episodeId,
    int? chapterId,
    String voteType = 'Favourite',
  }) async {
    await postRaw('character-votes', {
      'characterId': characterId,
      if (episodeId != null) 'episodeId': episodeId,
      if (chapterId != null) 'chapterId': chapterId,
      'voteType': voteType,
    });
  }
}