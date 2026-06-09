import 'package:progressio_desktop/model/city.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('cities');

  @override
  City fromJson(dynamic json) => City.fromJson(json);
}