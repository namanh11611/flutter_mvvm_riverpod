import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../model/budget_validation.dart';
import '../model/expense_date_utils.dart';
import '../model/expense_constants.dart';
import 'view_model/budget_view_model.dart';
import 'widgets/app_text_field.dart';
import 'widgets/budget_feedback_panel.dart';
import 'widgets/currency_chip.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class CreateBudgetScreen extends ConsumerStatefulWidget {
  const CreateBudgetScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _currency = 'MYR';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetViewModelProvider(widget.tripId));
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Create Trip Budget',
        fallbackRoute: '${Routes.groupExpense}/${widget.tripId}',
      ),
      body: SafeArea(
        child: budget.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load budget information.',
            onRetry: () =>
                ref.invalidate(budgetViewModelProvider(widget.tripId)),
          ),
          data: (state) => Form(
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
                  Text(
                    ExpenseDateUtils.formatRange(
                      state.trip!.startDate,
                      state.trip!.endDate,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (state.errorMessage != null) ...[
                  BudgetFeedbackPanel(
                    message: state.errorMessage!,
                    isError: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.successMessage != null) ...[
                  const BudgetFeedbackPanel(
                    message:
                        'Budget Created! Your trip budget has been created successfully.',
                    isError: false,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(text: 'Done', onPressed: () => context.pop()),
                ] else if (state.budget != null)
                  const BudgetFeedbackPanel(
                    message:
                        'This trip already has a budget. Open Edit Budget to change it.',
                    isError: true,
                  )
                else ...[
                  AppTextField(
                    label: 'Budget Name *',
                    controller: _nameController,
                    validator: (value) => BudgetValidation.name(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Budget Amount *',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => BudgetValidation.amount(value ?? ''),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Base Currency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: ExpenseConstants.supportedCurrencies
                        .map(
                          (currency) => CurrencyChip(
                            currency: currency,
                            selected: _currency == currency,
                            onSelected: (_) =>
                                setState(() => _currency = currency),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Notes',
                    controller: _notesController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: state.isSaving ? 'Creating...' : 'Create Budget',
                    backgroundColor: const Color(0xFF7C3AED),
                    isEnable: !state.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(budgetViewModelProvider(widget.tripId).notifier)
        .createBudget(
          name: _nameController.text,
          amount: _amountController.text,
          currency: _currency,
          notes: _notesController.text,
        );
  }
}
