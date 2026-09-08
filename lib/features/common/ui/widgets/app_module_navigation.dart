import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';

class AppModuleNavigation extends StatelessWidget {
  const AppModuleNavigation({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      if (onDestinationSelected != null) {
        onDestinationSelected!(index);
        return;
      }
      final route = switch (index) {
        0 => Routes.main,
        1 => Routes.myTrips,
        2 => Routes.messages,
        3 => Routes.expenseTripPicker,
        _ => Routes.userAccount,
      };
      if (index != selectedIndex) context.go(route);
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Matchmaking',
      ),
      NavigationDestination(
        icon: Icon(Icons.luggage_outlined),
        selectedIcon: Icon(Icons.luggage),
        label: 'My Trips',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Messages',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Expenses',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ],
  );
}
