import 'package:freezed_annotation/freezed_annotation.dart';

part 'language.freezed.dart';

part 'language.g.dart';

@freezed
class Language with _$Language {
  const factory Language({
    required String id,
    required String name,
    required String code,
    required String flag,
  }) = _Language;

  factory Language.fromJson(Map<String, Object?> json) =>
      _$LanguageFromJson(json);

  static Language empty() =>
      const Language(id: '', name: '', code: '', flag: '');
}
