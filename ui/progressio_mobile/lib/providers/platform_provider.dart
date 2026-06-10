import 'package:progressio_mobile/model/platform.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class PlatformProvider extends BaseProvider<Platform> {
  PlatformProvider() : super('platforms');

  @override
  Platform fromJson(dynamic json) => Platform.fromJson(json);
}