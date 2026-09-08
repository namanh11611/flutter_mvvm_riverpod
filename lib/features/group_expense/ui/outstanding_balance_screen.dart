import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import '../model/money_utils.dart';
import 'view_model/balance_view_model.dart';
import 'widgets/app_section_header.dart';
import 'widgets/balance_card.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class OutstandingBalanceScreen extends ConsumerWidget {
  const OutstandingBalanceScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balanceViewModelProvider(tripId));
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Outstanding Balance',
        fallbackRoute: '${Routes.groupExpense}/$tripId',
      ),
      body: SafeArea(
        child: balances.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to calculate balances.',
            onRetry: () => ref.invalidate(balanceViewModelProvider(tripId)),
          ),
          data: (state) => RefreshIndicator(
            onRefresh: () =>
                ref.read(balanceViewModelProvider(tripId).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Text(
                  state.tripName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF281958),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'YOU OWE',
                        amount: state.youOwe,
                        currency: state.currency,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'OWED TO YOU',
                        amount: state.owedToYou,
                        currency: state.currency,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _NetCard(net: state.net, currency: state.currency),
                const SizedBox(height: 28),
                const AppSectionHeader(title: 'Traveller Balances'),
                const SizedBox(height: 10),
                ...state.balances.map((balance) => BalanceCard(
                      balance: balance,
                      formattedBalance: _signedMoney(
                        balance.netBalance,
                        state.currency,
                      ),
                    )),
                const SizedBox(height: 28),
                const AppSectionHeader(title: 'Suggested Settlements'),
                const SizedBox(height: 10),
                if (state.suggestions.isEmpty)
                  const _SettledPanel()
                else
                  ...state.suggestions.map((suggestion) {
                    final canRecord = suggestion.payerId == state.currentUserId;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${state.travellerName(suggestion.payerId)} → ${state.travellerName(suggestion.payeeId)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    MoneyUtils.formatCurrency(
                                      suggestion.amount,
                                      currency: state.currency,
                                    ),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF281958),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (canRecord) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => context.push(
                                    '${Routes.groupExpense}/$tripId/${Routes.recordSettlement}?payerId=${suggestion.payerId}&payeeId=${suggestion.payeeId}',
                                  ),
                                  icon: const Icon(Icons.payments_outlined),
                                  label: const Text('Record Settlement'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _signedMoney(double amount, String currency) {
    if (MoneyUtils.toCents(amount) == 0) {
      return MoneyUtils.formatCurrency(0, currency: currency);
    }
    final sign = amount > 0 ? '+' : '-';
    return '$sign${MoneyUtils.formatCurrency(amount.abs(), currency: currency)}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });
  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11)),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                MoneyUtils.formatCurrency(amount, currency: currency),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _NetCard extends StatelessWidget {
  const _NetCard({required this.net, required this.currency});
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF281958), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'NET',
                style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${MoneyUtils.toCents(net) > 0 ? '+' : MoneyUtils.toCents(net) < 0 ? '-' : ''}${MoneyUtils.formatCurrency(net.abs(), currency: currency)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _SettledPanel extends StatelessWidget {
  const _SettledPanel();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Expanded(child: Text('Everyone is settled up.')),
          ],
        ),
      );
}
