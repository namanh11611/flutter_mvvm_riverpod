import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_theme.dart';
import 'widgets/hero_item.dart';

const List<Map<String, String>> heroes = [
  {
    'name': 'Iron Man',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/002irm_ons_crd_03.jpg'
  },
  {
    'name': 'Captain America',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/003cap_ons_crd_03.jpg'
  },
  {
    'name': 'Thor',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/004tho_ons_crd_03.jpg'
  },
  {
    'name': 'Black Widow',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/011blw_ons_crd_04.jpg'
  },
  {
    'name': 'Hulk',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/006hbb_ons_crd_03.jpg'
  },
  {
    'name': 'Doctor Strange',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/009drs_ons_crd_02.jpg'
  },
  {
    'name': 'Black Panther',
    'image':
        'https://terrigen-cdn-dev.marvel.com/content/prod/1x/007blp_ons_crd_02.jpg'
  },
  {
    'name': 'Ant-Man',
    'image': 'https://terrigen-cdn-dev.marvel.com/content/prod/1x/010ant_ons_crd_03.jpg'
  },
];

class HeroListScreen extends ConsumerWidget {
  const HeroListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marvel Superheroes', style: AppTheme.headLineLarge32),
        automaticallyImplyLeading: false,
        backgroundColor: context.primaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.8,
        ),
        itemCount: heroes.length,
        itemBuilder: (context, index) {
          final hero = heroes[index];
          return HeroItem(
            name: hero['name']!,
            imageUrl: hero['image']!,
          );
        },
      ),
    );
  }
}
