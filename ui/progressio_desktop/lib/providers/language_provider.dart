import 'package:progressio_desktop/model/language.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class LanguageProvider extends BaseProvider<Language> {
  LanguageProvider() : super('languages');

  @override
  Language fromJson(dynamic json) => Language.fromJson(json);
}