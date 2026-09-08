import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'expense_form.dart';
import 'widgets/group_expense_app_bar.dart';

class EditExpenseScreen extends StatelessWidget {
  const EditExpenseScreen({
    super.key,
    required this.tripId,
    required this.expenseId,
  });
  final String tripId;
  final String expenseId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: GroupExpenseAppBar(
          title: 'Edit Expense',
          fallbackRoute: '${Routes.groupExpense}/$tripId',
        ),
        body: SafeArea(
          child: ExpenseForm(
            tripId: tripId,
            expenseId: expenseId,
            onSaved: (_) => context.pop(),
          ),
        ),
      );
}
