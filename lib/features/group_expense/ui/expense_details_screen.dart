import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../model/expense_date_utils.dart';
import '../model/money_utils.dart';
import 'view_model/expense_view_model.dart';
import 'widgets/budget_feedback_panel.dart';
import 'widgets/load_error_state.dart';
import 'widgets/receipt_image.dart';
import 'widgets/group_expense_app_bar.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.tripId,
    required this.expenseId,
    this.initialSuccessMessage,
  });

  final String tripId;
  final String expenseId;
  final String? initialSuccessMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = expenseViewModelProvider(
      tripId: tripId,
      expenseId: expenseId,
    );
    final details = ref.watch(provider);
    ref.listen(provider, (previous, next) {
      if (next.value?.isDeleted ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully.')),
        );
        context.go('${Routes.groupExpense}/$tripId');
      }
    });
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Expense Details',
        fallbackRoute: '${Routes.groupExpense}/$tripId',
        actions: [
          IconButton(
            tooltip: 'Edit expense',
            onPressed: () => context.push(
              '${Routes.groupExpense}/$tripId/${Routes.expenseDetails}/$expenseId/${Routes.editExpense}',
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: details.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load expense details.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (state) {
            final expense = state.expense;
            if (expense == null) {
              return const Center(child: Text('Expense not found.'));
            }
            final category = state.categories
                .where((item) => item.categoryId == expense.categoryId)
                .firstOrNull;
            final payer = state.travellers
                .where((item) => item.userId == expense.paidByUserId)
                .firstOrNull;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (state.errorMessage != null) ...[
                  BudgetFeedbackPanel(
                    message: state.errorMessage!,
                    isError: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if ((state.successMessage ?? initialSuccessMessage) != null &&
                    !state.isDeleted) ...[
                  BudgetFeedbackPanel(
                    message: state.successMessage ?? initialSuccessMessage!,
                    isError: false,
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF281958), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category?.name ?? 'Expense',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(
                        expense.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        MoneyUtils.formatCurrency(
                          expense.originalAmount,
                          currency: expense.currencyCode,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (expense.currencyCode != state.baseCurrency)
                        Text(
                          '${MoneyUtils.formatCurrency(expense.baseAmount, currency: state.baseCurrency)} at ${expense.exchangeRate.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Paid by',
                  value: payer?.displayName ?? 'Unknown',
                ),
                _DetailRow(
                  label: 'Date',
                  value: ExpenseDateUtils.formatDate(expense.expenseDate),
                ),
                if (expense.notes != null)
                  _DetailRow(label: 'Notes', value: expense.notes!),
                const SizedBox(height: 18),
                Text('Split', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...state.participants.map((participant) {
                  final traveller = state.travellers
                      .where((item) => item.userId == participant.userId)
                      .firstOrNull;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(traveller?.displayName ?? 'Traveller'),
                    subtitle: participant.sharePercentage == null
                        ? null
                        : Text(
                            '${participant.sharePercentage!.toStringAsFixed(2)}%'),
                    trailing: Text(
                      MoneyUtils.formatCurrency(
                        participant.shareAmount,
                        currency: state.baseCurrency,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                }),
                if (state.receipt != null) ...[
                  const SizedBox(height: 18),
                  Text('Receipt',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ReceiptImage(path: state.receipt!.imagePath),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This removes the expense, its split information, and receipt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      final provider = expenseViewModelProvider(
        tripId: tripId,
        expenseId: expenseId,
      );
      await ref.read(provider.notifier).deleteExpense();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child:
                  Text(label, style: const TextStyle(color: Color(0xFF786B91))),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
