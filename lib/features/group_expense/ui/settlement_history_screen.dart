import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../model/expense_date_utils.dart';
import '../model/money_utils.dart';
import '../model/settlement.dart';
import '../model/settlement_filter.dart';
import 'view_model/settlement_view_model.dart';
import 'widgets/empty_state.dart';
import 'widgets/budget_feedback_panel.dart';
import 'widgets/settlement_card.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class SettlementHistoryScreen extends ConsumerWidget {
  const SettlementHistoryScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = settlementViewModelProvider(tripId);
    final history = ref.watch(provider);
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Settlement History',
        fallbackRoute: '${Routes.groupExpense}/$tripId',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '${Routes.groupExpense}/$tripId/${Routes.recordSettlement}',
        ),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load settlement history.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (state) => RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search traveller',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: ref.read(provider.notifier).search,
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SettlementFilter.values
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_filterLabel(filter)),
                                selected: state.filter == filter,
                                onSelected: (_) => ref
                                    .read(provider.notifier)
                                    .setFilter(filter),
                              ),
                            ))
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 14),
                if (state.successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      state.successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BudgetFeedbackPanel(
                      message: state.errorMessage!,
                      isError: true,
                    ),
                  ),
                if (state.filteredSettlements.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No settlements match this view.',
                  )
                else
                  ...state.filteredSettlements.map((settlement) {
                    final id = settlement.settlementId!;
                    final hasReceipt = state.receipts.containsKey(id);
                    final isPayer = settlement.payerId == state.currentUserId;
                    final isPayee = settlement.payeeId == state.currentUserId;
                    final isPending =
                        settlement.status == SettlementStatus.pending;
                    return SettlementCard(
                      description:
                          '${state.travellerName(settlement.payerId)} → ${state.travellerName(settlement.payeeId)}',
                      amount: MoneyUtils.formatCurrency(
                        settlement.amount,
                        currency: state.currency,
                      ),
                      paymentMethod: settlement.paymentMethod,
                      date: ExpenseDateUtils.formatDate(
                        settlement.settlementDate,
                      ),
                      status: settlement.status,
                      hasReceipt: hasReceipt,
                      onReceipt: isPayer && isPending
                          ? () => _replaceReceipt(context, ref, id)
                          : null,
                      onRemoveReceipt: hasReceipt && isPayer && isPending
                          ? () => ref.read(provider.notifier).removeReceipt(id)
                          : null,
                      onDelete: isPayer && isPending
                          ? () => _delete(context, ref, id)
                          : null,
                      onConfirm: isPayee && isPending
                          ? () => ref
                              .read(provider.notifier)
                              .confirmPaymentReceived(id)
                          : null,
                      onReject: isPayee && isPending
                          ? () => ref.read(provider.notifier).rejectPayment(id)
                          : null,
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _replaceReceipt(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final image =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (image != null) {
      await ref
          .read(settlementViewModelProvider(tripId).notifier)
          .replaceReceipt(settlementId, image.path);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete settlement?'),
        content: const Text(
          'This removes the settlement and its receipt. Completed balances will be recalculated.',
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
      final deleted = await ref
          .read(settlementViewModelProvider(tripId).notifier)
          .deleteSettlement(settlementId);
      if (!deleted && context.mounted) {
        context.showErrorSnackBar('Unable to delete the settlement.');
      }
    }
  }

  String _filterLabel(SettlementFilter filter) => switch (filter) {
        SettlementFilter.all => 'All',
        SettlementFilter.pending => 'Pending',
        SettlementFilter.completed => 'Completed',
        SettlementFilter.rejected => 'Rejected',
      };
}
