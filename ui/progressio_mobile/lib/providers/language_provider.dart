import 'package:progressio_mobile/model/language.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class LanguageProvider extends BaseProvider<Language> {
  LanguageProvider() : super('languages');

  @override
  Language fromJson(dynamic json) => Language.fromJson(json);
}