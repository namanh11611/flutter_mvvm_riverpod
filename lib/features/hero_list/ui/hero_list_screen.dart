import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../constants/languages.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/common_empty_data.dart';
import '../../common/ui/widgets/common_error.dart';
import '../model/hero.dart' as hero;
import '../ui/view_model/hero_list_view_model.dart';
import 'widgets/hero_item.dart';
import 'widgets/shimmer_hero_grid.dart';

final sampleHeroes = [
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Iron Man',
    description: 'Genius billionaire playboy philanthropist',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/002irm_ons_crd_03.jpg',
    power: 85,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Captain America',
    description: 'Super-Soldier and leader of the Avengers',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/003cap_ons_crd_03.jpg',
    power: 80,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Thor',
    description: 'God of Thunder',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/004tho_ons_crd_03.jpg',
    power: 95,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Black Widow',
    description: 'Master spy and assassin',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/011blw_ons_crd_04.jpg',
    power: 65,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Hulk',
    description: 'The strongest Avenger',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/006hbb_ons_crd_03.jpg',
    power: 100,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Doctor Strange',
    description: 'Master of the Mystic Arts',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/009drs_ons_crd_02.jpg',
    power: 90,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Black Panther',
    description: 'King of Wakanda and protector of its people',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/007blp_ons_crd_02.jpg',
    power: 90,
  ),
  hero.Hero(
    id: const Uuid().v4(),
    name: 'Ant-Man',
    description: 'Size-changing superhero with a heart of gold',
    imageUrl:
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/010ant_ons_crd_03.jpg',
    power: 75,
  ),
];

class HeroListScreen extends ConsumerWidget {
  const HeroListScreen({super.key});

  String _getGreeting() {
    final currentHour = DateTime.now().hour;
    if (currentHour >= 5 && currentHour < 12) return Languages.goodMorning;
    if (currentHour >= 12 && currentHour < 18) return Languages.goodAfternoon;
    return Languages.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroListState = ref.watch(heroListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(_getGreeting()),
          style: AppTheme.title32,
        ),
        automaticallyImplyLeading: false,
        backgroundColor: context.primaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
      ),
      body: heroListState.when(
        data: (state) {
          if (state.isLoading) {
            return const ShimmerHeroGrid();
          }

          if (state.errorMessage != null) {
            return const CommonError();
          }

          if (state.heroes.isEmpty) {
            return const CommonEmptyData();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8,
            ),
            itemCount: state.heroes.length,
            itemBuilder: (context, index) {
              final hero = state.heroes[index];
              return HeroItem(
                name: hero.name,
                imageUrl: hero.imageUrl,
                isFavorite: hero.isFavorite,
                onFavoritePressed: () {
                  ref
                      .read(heroListViewModelProvider.notifier)
                      .toggleFavorite(hero.id);
                },
              );
            },
          );
        },
        loading: () => const ShimmerHeroGrid(),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
