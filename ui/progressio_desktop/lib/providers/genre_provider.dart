import 'package:progressio_desktop/model/genre.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class GenreProvider extends BaseProvider<Genre> {
  GenreProvider() : super('genres');

  @override
  Genre fromJson(dynamic json) => Genre.fromJson(json);
}