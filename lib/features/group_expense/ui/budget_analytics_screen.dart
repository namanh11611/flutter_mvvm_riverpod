import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';

import '../model/category_spending.dart';
import '../model/money_utils.dart';
import 'state/analytics_state.dart';
import 'view_model/analytics_view_model.dart';
import 'widgets/app_section_header.dart';
import 'widgets/budget_progress_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/summary_metric_card.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class BudgetAnalyticsScreen extends ConsumerWidget {
  const BudgetAnalyticsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = analyticsViewModelProvider(tripId);
    final analytics = ref.watch(provider);
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Budget Analytics',
        fallbackRoute: '${Routes.groupExpense}/$tripId',
      ),
      body: SafeArea(
        child: analytics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load budget analytics.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (state) => RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _AnalyticsHeader(state: state),
                const SizedBox(height: 18),
                _Metrics(state: state),
                const SizedBox(height: 18),
                BudgetProgressBar(progress: state.usagePercentage / 100),
                const SizedBox(height: 6),
                Text(
                    '${state.usagePercentage.toStringAsFixed(1)}% budget used'),
                const SizedBox(height: 28),
                if (state.isEmpty)
                  const EmptyState(
                    icon: Icons.analytics_outlined,
                    message: 'Add an expense to see spending analytics.',
                  )
                else ...[
                  _HighestCategory(category: state.highestSpendingCategory!),
                  const SizedBox(height: 28),
                  const AppSectionHeader(title: 'Category Breakdown'),
                  const SizedBox(height: 10),
                  ...state.categories.map(
                    (category) => _CategoryRow(
                      category: category,
                      currency: state.currency,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const AppSectionHeader(title: 'Spending Trend'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SpendingTrendChart(points: state.trend),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.state});
  final AnalyticsState state;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF281958), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPENDING OVERVIEW',
              style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              MoneyUtils.formatCurrency(
                state.totalExpenses,
                currency: state.currency,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text('Total trip expenses',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.state});
  final AnalyticsState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: width,
                child: SummaryMetricCard(
                  label: 'Total Budget',
                  value: _money(state.totalBudget),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              SizedBox(
                width: width,
                child: SummaryMetricCard(
                  label: 'Total Expenses',
                  value: _money(state.totalExpenses),
                  icon: Icons.payments_outlined,
                ),
              ),
              SizedBox(
                width: width,
                child: SummaryMetricCard(
                  label: 'Remaining',
                  value: _money(state.remaining),
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          );
        },
      );

  String _money(double value) => MoneyUtils.formatCurrency(
        value,
        currency: state.currency,
      );
}

class _HighestCategory extends StatelessWidget {
  const _HighestCategory({required this.category});
  final CategorySpending category;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9DDFE)),
        ),
        child: Row(children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE9DDFE),
            child: Icon(Icons.emoji_events_outlined, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Highest Spending Category'),
                Text(
                  category.categoryName,
                  style: const TextStyle(
                    color: Color(0xFF281958),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${category.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ]),
      );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.currency});
  final CategorySpending category;
  final String currency;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              CircleAvatar(child: Icon(_categoryIcon(category.iconName))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MoneyUtils.formatCurrency(category.amount,
                        currency: currency),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text('${category.percentage.toStringAsFixed(1)}%'),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (category.percentage / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: const Color(0xFFE9DDFE),
                color: const Color(0xFF7C3AED),
              ),
            ),
          ]),
        ),
      );

  IconData _categoryIcon(String name) => switch (name) {
        'hotel' => Icons.hotel_outlined,
        'flight' => Icons.flight_outlined,
        'food' || 'restaurant' => Icons.restaurant_outlined,
        'transportation' => Icons.directions_car_outlined,
        'fuel' => Icons.local_gas_station_outlined,
        'parking' => Icons.local_parking_outlined,
        'shopping' => Icons.shopping_bag_outlined,
        'entertainment' => Icons.movie_outlined,
        'attraction' => Icons.attractions_outlined,
        _ => Icons.receipt_long_outlined,
      };
}
