import 'package:progressio_mobile/model/genre.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class GenreProvider extends BaseProvider<Genre> {
  GenreProvider() : super('genres');

  @override
  Genre fromJson(dynamic json) => Genre.fromJson(json);
}