import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class ContentProvider extends BaseProvider<Content> {
  ContentProvider() : super('contents');

  @override
  Content fromJson(dynamic json) => Content.fromJson(json);
}