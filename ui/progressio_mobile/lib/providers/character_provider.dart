import 'package:progressio_mobile/model/character.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class CharacterProvider extends BaseProvider<Character> {
  CharacterProvider() : super('characters');

  @override
  Character fromJson(dynamic json) => Character.fromJson(json);
}