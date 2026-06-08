import 'package:progressio_desktop/model/chapter.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class ChapterProvider extends BaseProvider<Chapter> {
  ChapterProvider() : super('chapters');

  @override
  Chapter fromJson(dynamic json) => Chapter.fromJson(json);
}