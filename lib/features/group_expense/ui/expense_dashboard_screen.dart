import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../../common/ui/widgets/app_module_navigation.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../model/expense_date_utils.dart';
import '../model/money_utils.dart';
import 'state/expense_dashboard_state.dart';
import 'view_model/expense_dashboard_view_model.dart';
import 'widgets/app_section_header.dart';
import 'widgets/budget_progress_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/expense_card.dart';
import 'widgets/group_expense_app_bar.dart';
import 'widgets/summary_metric_card.dart';

class ExpenseDashboardScreen extends ConsumerWidget {
  const ExpenseDashboardScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(expenseDashboardViewModelProvider(tripId));
    return Scaffold(
      appBar: const GroupExpenseAppBar(title: 'Group Expenses'),
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _DashboardError(
            onRetry: () =>
                ref.invalidate(expenseDashboardViewModelProvider(tripId)),
          ),
          data: (state) => RefreshIndicator(
            onRefresh: () => ref
                .read(expenseDashboardViewModelProvider(tripId).notifier)
                .refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _TripHeader(state: state),
                const SizedBox(height: 20),
                _Summary(state: state),
                const SizedBox(height: 18),
                BudgetProgressBar(progress: state.usagePercentage / 100),
                const SizedBox(height: 6),
                Text(
                    '${state.usagePercentage.toStringAsFixed(1)}% of budget used'),
                const SizedBox(height: 28),
                const AppSectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActions(state: state),
                const SizedBox(height: 28),
                const AppSectionHeader(title: 'Outstanding Balance'),
                const SizedBox(height: 10),
                _BalancePreview(state: state),
                const SizedBox(height: 28),
                AppSectionHeader(
                  title: 'Recent Expenses (${state.expenses.length})',
                ),
                const SizedBox(height: 10),
                if (state.expenses.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No expenses have been added yet.',
                  )
                else
                  ...state.expenses.map(
                    (expense) => ExpenseCard(
                      title: expense.title,
                      subtitle:
                          ExpenseDateUtils.formatDate(expense.expenseDate),
                      amount: MoneyUtils.formatCurrency(
                        expense.originalAmount,
                        currency: expense.currencyCode,
                      ),
                      onTap: () => context.push(
                        '${Routes.groupExpense}/${state.tripId}/${Routes.expenseDetails}/${expense.expenseId}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: dashboard.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(
                '${Routes.groupExpense}/${dashboard.value!.tripId}/${Routes.addExpense}',
              ),
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
      bottomNavigationBar: const AppModuleNavigation(selectedIndex: 3),
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({required this.state});

  final ExpenseDashboardState state;

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final dates = trip == null
        ? 'Trip dates unavailable'
        : '${DateFormat('MMM d').format(trip.startDate)}–${DateFormat('d, y').format(trip.endDate)}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF281958), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'CURRENT TRIP',
          style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          trip?.destination ?? 'Current Trip',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trip != null) ...[
          const SizedBox(height: 3),
          Text(trip.destination, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 8),
        Text(
          '$dates  •  ${state.travellerCount} travellers',
          style: const TextStyle(color: Colors.white70),
        ),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});
  final ExpenseDashboardState state;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: SummaryMetricCard(
            label: 'Budget',
            value: _compact(state.budgetAmount, state.currency),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryMetricCard(
            label: 'Spent',
            value: _compact(state.totalSpent, state.currency),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SummaryMetricCard(
            label: 'Left',
            value: _compact(state.remaining, state.currency),
            icon: Icons.savings_outlined,
          ),
        ),
      ]);

  String _compact(double amount, String currency) {
    final symbol = currency == 'MYR' ? 'RM' : currency;
    return '$symbol${NumberFormat('#,##0').format(amount)}';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.state});
  final ExpenseDashboardState state;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, String)>[
      (
        Icons.add_card,
        'Expense',
        '${Routes.groupExpense}/${state.tripId}/${Routes.addExpense}'
      ),
      (
        Icons.swap_horiz,
        'Settle',
        '${Routes.groupExpense}/${state.tripId}/${Routes.recordSettlement}'
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Budget',
        '${Routes.groupExpense}/${state.tripId}/${state.hasBudget ? Routes.editBudget : Routes.createBudget}'
      ),
      (
        Icons.balance_outlined,
        'Balance',
        '${Routes.groupExpense}/${state.tripId}/${Routes.outstandingBalance}'
      ),
      (
        Icons.history,
        'History',
        '${Routes.groupExpense}/${state.tripId}/${Routes.settlementHistory}'
      ),
      (
        Icons.insights_outlined,
        'Analytics',
        '${Routes.groupExpense}/${state.tripId}/${Routes.budgetAnalytics}'
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (action) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 60) / 2,
              child: OutlinedButton.icon(
                onPressed: () => context.push(action.$3),
                icon: Icon(action.$1),
                label: Text(action.$2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({required this.state});
  final ExpenseDashboardState state;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF281958),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOU OWE', style: TextStyle(color: Colors.white60)),
                Text(
                  MoneyUtils.formatCurrency(state.youOwe,
                      currency: state.currency),
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OWED TO YOU',
                  style: TextStyle(color: Colors.white60),
                ),
                Text(
                  MoneyUtils.formatCurrency(
                    state.owedToYou,
                    currency: state.currency,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: PrimaryButton(
              text: 'View',
              backgroundColor: const Color(0xFF7C3AED),
              onPressed: () => context.push(
                '${Routes.groupExpense}/${state.tripId}/${Routes.outstandingBalance}',
              ),
            ),
          ),
        ]),
      );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load the expense dashboard.'),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
