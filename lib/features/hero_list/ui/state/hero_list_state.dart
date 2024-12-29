import 'package:freezed_annotation/freezed_annotation.dart';

import '../../model/hero.dart';

part 'hero_list_state.freezed.dart';
part 'hero_list_state.g.dart';

@freezed
class HeroListState with _$HeroListState {
  const factory HeroListState({
    @Default([]) List<Hero> heroes,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HeroListState;

  factory HeroListState.fromJson(Map<String, Object?> json) =>
      _$HeroListStateFromJson(json);
}
