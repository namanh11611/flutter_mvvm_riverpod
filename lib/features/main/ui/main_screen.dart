import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/material_ink_well.dart';
import '../../hero_list/ui/hero_list_screen.dart';
import '../../hero_list/ui/view_model/hero_count_provider.dart';
import '../../hero_list/ui/view_model/hero_list_view_model.dart';
import '../../profile/ui/profile_screen.dart';
import '../model/main_tab.dart';

const List<Widget> _screens = [
  HeroListScreen(),
  ProfileScreen(),
];

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(heroCountProvider);
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: _screens,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: context.secondaryWidgetColor,
                      borderRadius: const BorderRadius.all(Radius.circular(48)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: MainTab.values
                          .map((tab) => _buildNavItem(tab))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.secondaryWidgetColor,
                    borderRadius: const BorderRadius.all(Radius.circular(48)),
                  ),
                  child: MaterialInkWell(
                    radius: 48,
                    onTap: () async {
                      final randomHero =
                          sampleHeroes[count % sampleHeroes.length];
                      await ref
                          .read(heroListViewModelProvider.notifier)
                          .addHero(
                            name: randomHero.name,
                            description: randomHero.description,
                            imageUrl: randomHero.imageUrl,
                            power: randomHero.power,
                          );
                      ref.read(heroCountProvider.notifier).increment();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: AppColors.mono100,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(MainTab tab) {
    final isSelected = _currentTabIndex == tab.index;
    return MaterialInkWell(
      radius: 24,
      onTap: () {
        setState(() {
          _currentTabIndex = tab.index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.secondaryBackgroundColor : null,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          children: [
            Icon(
              tab.iconData,
              color: isSelected ? AppColors.blueberry100 : null,
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(tab.labelKey),
              style: AppTheme.body12.copyWith(
                color: isSelected ? AppColors.blueberry100 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
