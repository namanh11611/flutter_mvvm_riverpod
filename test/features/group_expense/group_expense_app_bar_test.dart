import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/group_expense_app_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows a fallback back button without a navigator history',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, __) => const Scaffold(
            appBar: GroupExpenseAppBar(
              title: 'Expense Details',
              fallbackRoute: '/group-expense/trip-id',
            ),
          ),
        ),
        GoRoute(
          path: '/group-expense/trip-id',
          builder: (_, __) => const Text('Expense dashboard'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('does not add a back button on a root page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: GroupExpenseAppBar(title: 'Group Expenses'),
        ),
      ),
    );

    expect(find.byTooltip('Back'), findsNothing);
  });
}
