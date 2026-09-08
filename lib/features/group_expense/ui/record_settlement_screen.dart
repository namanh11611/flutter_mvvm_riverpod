import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/ui/widgets/primary_button.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import '../model/expense_constants.dart';
import '../model/expense_date_utils.dart';
import '../model/expense_form_validation.dart';
import '../model/money_utils.dart';
import 'state/settlement_state.dart';
import 'view_model/settlement_view_model.dart';
import 'widgets/app_text_field.dart';
import 'widgets/budget_feedback_panel.dart';
import 'widgets/load_error_state.dart';
import 'widgets/group_expense_app_bar.dart';

class RecordSettlementScreen extends ConsumerStatefulWidget {
  const RecordSettlementScreen({
    super.key,
    required this.tripId,
    this.initialPayerId,
    this.initialPayeeId,
  });

  final String tripId;
  final String? initialPayerId;
  final String? initialPayeeId;

  @override
  ConsumerState<RecordSettlementScreen> createState() =>
      _RecordSettlementScreenState();
}

class _RecordSettlementScreenState
    extends ConsumerState<RecordSettlementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _payerId;
  String? _payeeId;
  String _paymentMethod = 'DuitNow';
  DateTime _date = DateTime.now();
  String? _receiptPath;
  bool _initialized = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = settlementViewModelProvider(widget.tripId);
    final settlementState = ref.watch(provider);
    return Scaffold(
      appBar: GroupExpenseAppBar(
        title: 'Record Settlement',
        fallbackRoute: '${Routes.groupExpense}/${widget.tripId}',
      ),
      body: SafeArea(
        child: settlementState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorState(
            message: 'Unable to load settlement information.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (state) {
            final memberIds = state.travellers.map((item) => item.userId);
            if (memberIds.toSet().length != state.travellers.length) {
              return LoadErrorState(
                message: 'Unable to load a valid trip member roster.',
                onRetry: () => ref.invalidate(provider),
              );
            }
            if (!memberIds.contains(state.currentUserId)) {
              return LoadErrorState(
                message: 'You must be a trip member to record a settlement.',
                onRetry: () => ref.invalidate(provider),
              );
            }
            _initialize(state);
            _ensureValidSelections(state);
            final outstanding = _payerId == null || _payeeId == null
                ? 0.0
                : state.outstandingFor(_payerId!, _payeeId!);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payment happens outside GoBuddy. Record it here only after arranging payment.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (state.errorMessage != null) ...[
                    BudgetFeedbackPanel(
                      message: state.errorMessage!,
                      isError: true,
                    ),
                    const SizedBox(height: 14),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _payerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payer *',
                      helperText: 'You are submitting this payment',
                    ),
                    items: state.travellers
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.userId,
                            child: Text(
                              item.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_payeeId),
                    initialValue: _payeeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Payee *'),
                    items: state.travellers
                        .where((item) => item.userId != _payerId)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.userId,
                            child: Text(
                              item.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() {
                      _payeeId = value;
                      _syncAmount(state);
                    }),
                    validator: (value) =>
                        ExpenseFormValidation.requiredSelection(value, 'Payee'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Outstanding Amount')),
                        Text(
                          MoneyUtils.formatCurrency(
                            outstanding,
                            currency: state.currency,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Settlement Amount *',
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        ExpenseFormValidation.amount(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method *',
                    ),
                    items: ExpenseConstants.paymentMethods
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value ?? ''),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Payment method is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Color(0xFFF59E0B)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This submission will remain Pending until the payee confirms receiving it.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Settlement Date *'),
                    subtitle: Text(ExpenseDateUtils.formatDate(_date)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _pickDate,
                  ),
                  AppTextField(label: 'Notes', controller: _notes, maxLines: 3),
                  const SizedBox(height: 18),
                  _receiptPicker(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: state.isSaving ? 'Recording...' : 'Record Settlement',
                    isEnable: !state.isSaving,
                    backgroundColor: const Color(0xFF7C3AED),
                    onPressed: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _initialize(SettlementState state) {
    if (_initialized) return;
    _initialized = true;
    _payerId = state.currentUserId;
    if (widget.initialPayerId == state.currentUserId) {
      final initialPayeeId = widget.initialPayeeId;
      if (initialPayeeId != state.currentUserId &&
          state.travellers.any((item) => item.userId == initialPayeeId)) {
        _payeeId = initialPayeeId;
      }
    }
    if (_payeeId == null) {
      for (final suggestion in state.suggestions) {
        if (suggestion.payerId == state.currentUserId &&
            suggestion.payeeId != state.currentUserId &&
            state.travellers.any((item) => item.userId == suggestion.payeeId)) {
          _payeeId = suggestion.payeeId;
          break;
        }
      }
    }
    _syncAmount(state);
  }

  void _ensureValidSelections(SettlementState state) {
    _payerId = state.currentUserId;
    final payeeId = _payeeId;
    if (payeeId == null) return;
    if (payeeId == state.currentUserId ||
        !state.travellers.any((item) => item.userId == payeeId)) {
      _payeeId = null;
      _amount.clear();
    }
  }

  void _syncAmount(SettlementState state) {
    if (_payerId != null && _payeeId != null) {
      final amount = state.outstandingFor(_payerId!, _payeeId!);
      _amount.text = amount > 0 ? amount.toStringAsFixed(2) : '';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final provider = settlementViewModelProvider(widget.tripId);
    final saved = await ref
        .read(provider.notifier)
        .createSettlement(
          payerId: _payerId,
          payeeId: _payeeId,
          amount: _amount.text,
          paymentMethod: _paymentMethod,
          settlementDate: _date,
          notes: _notes.text,
          selectedReceiptPath: _receiptPath,
        );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted for payee confirmation.'),
        ),
      );
      context.pop();
    }
  }

  Widget _receiptPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Optional Receipt',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (_receiptPath != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(_receiptPath!),
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _receiptPath = null),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove receipt'),
        ),
      ] else
        OutlinedButton.icon(
          onPressed: _chooseReceipt,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add receipt'),
        ),
    ],
  );

  Future<void> _chooseReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
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
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _receiptPath = image.path);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }
}
