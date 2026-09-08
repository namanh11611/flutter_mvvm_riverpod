import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../common/ui/widgets/secondary_button.dart';
import '../model/budget_validation.dart';
import '../model/expense_date_utils.dart';
import 'state/budget_state.dart';
import 'view_model/budget_view_model.dart';
import 'widgets/app_text_field.dart';
import 'widgets/budget_feedback_panel.dart';
import 'widgets/budget_summary_panel.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class EditBudgetScreen extends ConsumerStatefulWidget {
  const EditBudgetScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends ConsumerState<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _initializedBudgetId;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetViewModelProvider(widget.tripId));
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Edit Trip Budget',
        fallbackRoute: '${Routes.groupExpense}/${widget.tripId}',
      ),
      body: SafeArea(
        child: budget.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load budget information.',
            onRetry: () => ref.invalidate(
              budgetViewModelProvider(widget.tripId),
            ),
          ),
          data: (state) {
            _initializeControllers(state);
            if (state.budget == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No budget exists for this trip.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    state.trip?.destination ?? 'Current Trip',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF281958),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (state.trip != null) ...[
                    const SizedBox(height: 6),
                    Text(ExpenseDateUtils.formatRange(
                      state.trip!.startDate,
                      state.trip!.endDate,
                    )),
                  ],
                  const SizedBox(height: 20),
                  BudgetSummaryPanel(state: state),
                  const SizedBox(height: 18),
                  if (state.errorMessage != null) ...[
                    BudgetFeedbackPanel(
                      message: state.errorMessage!,
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.successMessage != null) ...[
                    BudgetFeedbackPanel(
                      message: state.successMessage!,
                      isError: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    label: 'Budget Amount *',
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => BudgetValidation.amount(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Notes',
                    controller: _notesController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Cancel',
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          text:
                              state.isSaving ? 'Updating...' : 'Update Budget',
                          backgroundColor: const Color(0xFF7C3AED),
                          isEnable: !state.isSaving,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _initializeControllers(BudgetState state) {
    final budget = state.budget;
    if (budget == null || budget.budgetId == _initializedBudgetId) return;
    _initializedBudgetId = budget.budgetId;
    _amountController.text = budget.budgetAmount.toStringAsFixed(2);
    _notesController.text = budget.notes ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(budgetViewModelProvider(widget.tripId).notifier)
        .updateBudget(
          amount: _amountController.text,
          notes: _notesController.text,
        );
  }
}
