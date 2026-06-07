import 'package:progressio_desktop/model/content_type.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class ContentTypeProvider extends BaseProvider<ContentType> {
  ContentTypeProvider() : super('content-types');

  @override
  ContentType fromJson(dynamic json) => ContentType.fromJson(json);
}