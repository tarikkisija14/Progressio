import 'package:progressio_mobile/model/country.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('countries');

  @override
  Country fromJson(dynamic json) => Country.fromJson(json);
}