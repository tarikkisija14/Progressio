import 'package:progressio_mobile/model/user_progress.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ProgressProvider extends BaseProvider<UserProgress> {
  ProgressProvider() : super('progress');

  @override
  UserProgress fromJson(dynamic data) => UserProgress.fromJson(data);

  Future<List<UserProgress>> getMyProgress({String? status}) async {
    final data = await getRaw('progress/my');

    List<UserProgress> items = [];

    if (data is List) {
      items = data.map((e) => UserProgress.fromJson(e)).toList();
    } else if (data is Map && data['items'] != null) {
      items = (data['items'] as List)
          .map((e) => UserProgress.fromJson(e))
          .toList();
    }

    if (status != null) {
      items = items.where((x) => x.status == status).toList();
    }

    return items;
  }

  Future<UserProgress?> getForContent(int contentId) async {
    try {
      final data = await getRaw('progress/content/$contentId');
      return UserProgress.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(
    int contentId,
    String status, {
    String? reason,
  }) async {
    await postRaw('progress/status', {
      'contentId': contentId,
      'status': status,
      if (reason != null) 'cancelledReason': reason,
    });
  }

  Future<void> markEpisodeWatched(int episodeId) async {
    await postRaw('episodes/$episodeId/watch', {});
  }

  Future<void> markChapterRead(int chapterId) async {
    await postRaw('chapters/$chapterId/read', {});
  }
}