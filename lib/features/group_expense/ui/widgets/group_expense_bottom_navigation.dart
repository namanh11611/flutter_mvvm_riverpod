import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';

class GroupExpenseBottomNavigation extends StatelessWidget {
  const GroupExpenseBottomNavigation({
    super.key,
    required this.tripId,
    required this.selectedIndex,
  });

  final String tripId;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final route = switch (index) {
            0 => '${Routes.groupExpense}/$tripId',
            1 => '${Routes.groupExpense}/$tripId/${Routes.outstandingBalance}',
            2 => '${Routes.groupExpense}/$tripId/${Routes.settlementHistory}',
            _ => '${Routes.groupExpense}/$tripId/${Routes.budgetAnalytics}',
          };
          if (index != selectedIndex) context.go(route);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            label: 'Balance',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
        ],
      );
}
