import 'package:progressio_mobile/model/comment.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class CommentProvider extends BaseProvider<Comment> {
  CommentProvider() : super('comments');

  @override
  Comment fromJson(dynamic json) => Comment.fromJson(json);

  // GET /api/content/{id}/comments
  Future<List<Comment>> getByContent(int contentId, {int page = 1, int pageSize = 20}) async {
    final data = await getRaw(
      'content/$contentId/comments',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = data['items'] as List? ?? [];
    return items.map((e) => Comment.fromJson(e)).toList();
  }

  // GET /api/episodes/{id}/comments
  Future<List<Comment>> getByEpisode(int episodeId, {int page = 1, int pageSize = 20}) async {
    final data = await getRaw(
      'episodes/$episodeId/comments',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = data['items'] as List? ?? [];
    return items.map((e) => Comment.fromJson(e)).toList();
  }

  // DELETE /api/comments/{id}
  // (koristimo naslijeđeni delete() iz BaseProvider)

  // Toggle visibility — backend endpoint nije dostupan kao PATCH/PUT visibility,
  // koristimo soft delete (DELETE) kao jedinu moderacijsku akciju.
}