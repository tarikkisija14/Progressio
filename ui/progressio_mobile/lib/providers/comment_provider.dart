import 'package:progressio_mobile/model/comment.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class CommentProvider extends BaseProvider<Comment> {
  CommentProvider() : super('comments');

  @override
  Comment fromJson(dynamic json) => Comment.fromJson(json);

  /// GET /api/episodes/{id}/comments
  Future<List<Comment>> getEpisodeComments(int episodeId,
      {bool hideSpoilers = false, int page = 1, int pageSize = 20}) async {
    final data = await getRaw(
      'episodes/$episodeId/comments',
      query: {
        'page': page,
        'pageSize': pageSize,
        'hideSpoilers': hideSpoilers,
      },
    );
    final items = data is Map
        ? (data['items'] as List? ?? [])
        : (data as List? ?? []);
    return items.map((e) => Comment.fromJson(e)).toList();
  }

  /// GET /api/chapters/{id}/comments
  Future<List<Comment>> getChapterComments(int chapterId,
      {bool hideSpoilers = false, int page = 1, int pageSize = 20}) async {
    final data = await getRaw(
      'chapters/$chapterId/comments',
      query: {
        'page': page,
        'pageSize': pageSize,
        'hideSpoilers': hideSpoilers,
      },
    );
    final items = data is Map
        ? (data['items'] as List? ?? [])
        : (data as List? ?? []);
    return items.map((e) => Comment.fromJson(e)).toList();
  }

  /// GET /api/content/{id}/comments
  Future<List<Comment>> getByContent(int contentId,
      {int page = 1, int pageSize = 20}) async {
    final data = await getRaw(
      'content/$contentId/comments',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = data is Map
        ? (data['items'] as List? ?? [])
        : (data as List? ?? []);
    return items.map((e) => Comment.fromJson(e)).toList();
  }

  /// POST /api/episodes/{id}/comments
  /// Body šalje samo contentId, text, hasSpoiler — episodeId backend uzima iz URL-a
  Future<Comment> addEpisodeComment(
    int episodeId, {
    required int contentId,
    required String text,
    bool hasSpoiler = false,
  }) async {
    final data = await postRaw('episodes/$episodeId/comments', {
       'contentId': contentId,
  'episodeId': episodeId,
  'text': text,
  'hasSpoiler': hasSpoiler,
    });
    return Comment.fromJson(data);
  }

  /// POST /api/chapters/{id}/comments
  /// Body šalje samo contentId, text, hasSpoiler — chapterId backend uzima iz URL-a
  Future<Comment> addChapterComment(
    int chapterId, {
    required int contentId,
    required String text,
    bool hasSpoiler = false,
  }) async {
    final data = await postRaw('chapters/$chapterId/comments', {
      'contentId': contentId,
  'chapterId': chapterId,
  'text': text,
  'hasSpoiler': hasSpoiler,
    });
    return Comment.fromJson(data);
  }

  /// POST /api/comments/{id}/like — toggle
  Future<void> toggleLike(int commentId) async {
    await postRaw('comments/$commentId/like', {});
  }

  /// DELETE /api/comments/{id}
  Future<void> removeComment(int commentId) async {
    await delete(commentId);
  }
}