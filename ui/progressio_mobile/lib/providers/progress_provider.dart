import 'package:progressio_mobile/model/user_progress.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ProgressProvider extends BaseProvider<UserProgress> {
  ProgressProvider() : super('progress');

  @override
  UserProgress fromJson(dynamic json) => UserProgress.fromJson(json);

  int _statusToInt(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'InProgress':
        return 1;
      case 'Completed':
        return 2;
      case 'OnHold':
        return 3;
      case 'Cancelled':
        return 4;
      default:
        throw Exception('Unknown progress status: $status');
    }
  }

  Future<List<UserProgress>> getMyProgress({String? status}) async {
    final items = await _loadAllPages('progress/my');
    final all = items
        .map((item) => UserProgress.fromJson(item as Map<String, dynamic>))
        .toList();

    if (status == null) return all;
    return all.where((progress) => progress.status == status).toList();
  }

  Future<UserProgress?> getForContent(int contentId) async {
    final data = await getRaw('progress/content/$contentId');
    if (data == null) return null;
    return UserProgress.fromJson(data);
  }

  Future<UserProgress> startProgress(int contentId) async {
    final data = await postRaw('progress/start', {'contentId': contentId});
    return UserProgress.fromJson(data);
  }

  Future<UserProgress> changeStatus(
    int progressId,
    String newStatus, {
    String? cancelledReason,
  }) async {
    final data = await putRaw('progress/$progressId/status', {
      'newStatus': _statusToInt(newStatus),
      if (cancelledReason != null) 'cancelledReason': cancelledReason,
    });
    return UserProgress.fromJson(data);
  }

  Future<void> markEpisode(
    int progressId,
    int episodeId,
    bool isWatched,
  ) async {
    await postRaw('progress/$progressId/episodes', {
      'episodeId': episodeId,
      'isWatched': isWatched,
    });
  }

  Future<List<dynamic>> getEpisodeProgresses(int progressId) =>
      _loadAllPages('progress/$progressId/episodes');

  Future<void> markChapter(
    int progressId,
    int chapterId,
    bool isRead,
  ) async {
    await postRaw('progress/$progressId/chapters', {
      'chapterId': chapterId,
      'isRead': isRead,
    });
  }

  Future<List<dynamic>> getChapterProgresses(int progressId) =>
      _loadAllPages('progress/$progressId/chapters');

  Future<Map<String, dynamic>?> getStreak() async {
    try {
      final data = await getRaw('progress/streak');
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> _loadAllPages(String path) async {
    const pageSize = 100;
    var page = 1;
    var totalCount = 0;
    final items = <dynamic>[];

    do {
      final data = await getRaw(
        path,
        query: {'page': page, 'pageSize': pageSize},
      );

      if (data is List) {
        items.addAll(data);
        break;
      }

      final map = data as Map<String, dynamic>;
      final pageItems = map['items'] as List<dynamic>? ?? const [];
      totalCount = map['totalCount'] as int? ?? pageItems.length;
      items.addAll(pageItems);
      page++;
    } while (items.length < totalCount);

    return items;
  }
}