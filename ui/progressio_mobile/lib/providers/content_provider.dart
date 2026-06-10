import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class ContentProvider extends BaseProvider<Content> {
  ContentProvider() : super('contents');

  @override
  Content fromJson(dynamic json) => Content.fromJson(json);
}