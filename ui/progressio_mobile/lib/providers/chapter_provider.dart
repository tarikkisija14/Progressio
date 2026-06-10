import 'package:progressio_mobile/model/chapter.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ChapterProvider extends BaseProvider<Chapter> {
  ChapterProvider() : super('chapters');

  @override
  Chapter fromJson(dynamic json) => Chapter.fromJson(json);
}