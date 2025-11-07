import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../model/hero.dart';
import '../../repository/hero_list_repository.dart';
import '../state/hero_list_state.dart';

part 'hero_list_view_model.g.dart';

@Riverpod(keepAlive: true)
class HeroListViewModel extends _$HeroListViewModel {
  late HeroListRepository _repository;

  @override
  FutureOr<HeroListState> build() async {
    _repository = await ref.watch(heroListRepositoryProvider.future);
    final heroes = await _repository.getHeroes();
    return HeroListState(heroes: heroes);
  }

  Future<void> addHero({
    required String name,
    required String description,
    required String imageUrl,
    required int power,
  }) async {
    state = const AsyncValue.loading();
    try {
      final hero = Hero(
        id: const Uuid().v4(),
        name: name,
        description: description,
        imageUrl: imageUrl,
        power: power,
        lastUpdated: DateTime.now(),
      );

      await _repository.insertHero(hero);
      await refreshHeroes();
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> updateHero(Hero hero) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateHero(hero);
      await refreshHeroes();
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> deleteHero(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteHero(id);
      await refreshHeroes();
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> toggleFavorite(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleFavorite(id);
      await refreshHeroes();
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> refreshHeroes() async {
    try {
      final heroes = await _repository.getHeroes();
      state = AsyncData(HeroListState(heroes: heroes));
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }
}
