// lib/providers/progress_provider.dart

import 'package:progressio_mobile/model/user_progress.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ProgressProvider extends BaseProvider<UserProgress> {
  ProgressProvider() : super('progress');

  @override
  UserProgress fromJson(dynamic json) => UserProgress.fromJson(json);

  
  Future<List<UserProgress>> getMyProgress({String? status}) async {
    final data = await getRaw('progress/my');
    final List list = data is List ? data : (data['items'] ?? []);
    final all = list.map((e) => UserProgress.fromJson(e)).toList();
    if (status != null) {
      return all.where((p) => p.status == status).toList();
    }
    return all;
  }

  
  Future<UserProgress?> getForContent(int contentId) async {
    try {
      final data = await getRaw('progress/content/$contentId');
      return UserProgress.fromJson(data);
    } catch (_) {
      return null;
    }
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
      'newStatus': newStatus,
      if (cancelledReason != null) 'cancelledReason': cancelledReason,
    });
    return UserProgress.fromJson(data);
  }

 
  Future<void> markEpisode(
      int progressId, int episodeId, bool isWatched) async {
    await postRaw('progress/$progressId/episodes', {
      'episodeId': episodeId,
      'isWatched': isWatched,
    });
  }

  
  Future<List<dynamic>> getEpisodeProgresses(int progressId) async {
    final data = await getRaw('progress/$progressId/episodes');
    if (data is List) return data;
    return [];
  }

  
  Future<void> markChapter(
      int progressId, int chapterId, bool isRead) async {
    await postRaw('progress/$progressId/chapters', {
      'chapterId': chapterId,
      'isRead': isRead,
    });
  }

  
  Future<List<dynamic>> getChapterProgresses(int progressId) async {
    final data = await getRaw('progress/$progressId/chapters');
    if (data is List) return data;
    return [];
  }


  Future<Map<String, dynamic>?> getStreak() async {
    try {
      final data = await getRaw('progress/streak');
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}