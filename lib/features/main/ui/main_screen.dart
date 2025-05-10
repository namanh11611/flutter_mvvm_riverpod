import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../features/hero_list/ui/hero_list_screen.dart';
import '../../../features/profile/ui/profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../../hero_list/ui/view_model/hero_count_provider.dart';
import '../../hero_list/ui/view_model/hero_list_view_model.dart';

const List<Widget> _screens = [
  HeroListScreen(),
  HeroListScreen(),
  ProfileScreen(),
];

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PersistentBottomNavBarItem> _navBarsItems(
    BuildContext context,
    Color selectedColor,
    Color unselectedColor,
    int count,
  ) {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(MingCuteIcons.mgc_lightning_fill, color: selectedColor),
        inactiveIcon:
            Icon(MingCuteIcons.mgc_lightning_line, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: AppColors.mono0,
          size: 20,
        ),
        inactiveIcon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: AppColors.mono0,
          size: 20,
        ),
        activeColorPrimary: selectedColor,
        inactiveColorPrimary: unselectedColor,
        onPressed: (_) async {
          final randomHero = sampleHeroes[count % sampleHeroes.length];
          await ref.read(heroListViewModelProvider.notifier).addHero(
                name: randomHero.name,
                description: randomHero.description,
                imageUrl: randomHero.imageUrl,
                power: randomHero.power,
              );
          ref.read(heroCountProvider.notifier).increment();
        },
      ),
      PersistentBottomNavBarItem(
        icon: Icon(MingCuteIcons.mgc_user_3_fill, color: selectedColor),
        inactiveIcon:
            Icon(MingCuteIcons.mgc_user_3_line, color: unselectedColor),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        context.isDarkMode ? AppColors.blueberry100 : AppColors.blueberry100;
    final unselectedColor =
        context.isDarkMode ? AppColors.mono40 : AppColors.mono60;
    final count = ref.watch(heroCountProvider);
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _screens,
        items: _navBarsItems(
          context,
          selectedColor,
          unselectedColor,
          count,
        ),
        confineToSafeArea: true,
        backgroundColor: context.secondaryWidgetColor,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          colorBehindNavBar: context.secondaryBackgroundColor,
        ),
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            // Screen transition animation on change of selected tab.
            animateTabTransition: true,
            duration: Duration(milliseconds: 300),
            screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
          ),
          onNavBarHideAnimation: OnHideAnimationSettings(
            duration: Duration(milliseconds: 100),
            curve: Curves.bounceInOut,
          ),
        ),
        navBarStyle: NavBarStyle.style17,
      ),
    );
  }
}
