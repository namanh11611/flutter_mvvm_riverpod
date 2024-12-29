import 'package:freezed_annotation/freezed_annotation.dart';

part 'hero.freezed.dart';

part 'hero.g.dart';

@freezed
class Hero with _$Hero {
  const factory Hero({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
    @Default(false)
    @JsonKey(fromJson: _boolFromJson, toJson: _boolToJson)
    bool isFavorite,
    @Default(0) int power,
    @JsonKey(
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    )
    DateTime? lastUpdated,
  }) = _Hero;

  factory Hero.fromJson(Map<String, dynamic> json) => _$HeroFromJson(json);
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  return null;
}

int? _dateTimeToJson(DateTime? date) {
  return date?.millisecondsSinceEpoch;
}

bool _boolFromJson(dynamic value) => value == 1;

int _boolToJson(bool value) => value ? 1 : 0;
