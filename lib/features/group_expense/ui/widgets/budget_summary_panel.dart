import 'package:flutter/material.dart';

import '../../model/budget_calculator.dart';
import '../../model/money_utils.dart';
import '../state/budget_state.dart';
import 'budget_progress_bar.dart';
import 'status_chip.dart';

class BudgetSummaryPanel extends StatelessWidget {
  const BudgetSummaryPanel({super.key, required this.state});

  final BudgetState state;

  @override
  Widget build(BuildContext context) {
    final budget = state.budget;
    if (budget == null) return const SizedBox.shrink();
    final (label, color) = switch (state.status) {
      BudgetStatus.normal => ('Normal', const Color(0xFF10B981)),
      BudgetStatus.nearBudget => ('Near Budget', const Color(0xFFF59E0B)),
      BudgetStatus.exceeded => ('Exceeded', const Color(0xFFEF4444)),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E1F4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budget.budgetName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF281958),
                      ),
                ),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 14),
          BudgetProgressBar(progress: state.usagePercentage / 100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _Metric(
                  label: 'Spent',
                  value: MoneyUtils.formatCurrency(
                    state.totalSpent,
                    currency: budget.baseCurrency,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: 'Remaining',
                  value: MoneyUtils.formatCurrency(
                    state.remaining,
                    currency: budget.baseCurrency,
                  ),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
}
