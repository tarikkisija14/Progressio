import 'package:progressio_desktop/model/platform.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class PlatformProvider extends BaseProvider<Platform> {
  PlatformProvider() : super('platforms');

  @override
  Platform fromJson(dynamic json) => Platform.fromJson(json);
}