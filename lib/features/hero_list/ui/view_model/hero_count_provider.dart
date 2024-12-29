import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hero_count_provider.g.dart';

@riverpod
class HeroCount extends _$HeroCount {
  @override
  int build() => 0;

  void increment() => state++;
}
