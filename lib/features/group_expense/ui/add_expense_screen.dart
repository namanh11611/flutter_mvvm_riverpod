import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'expense_form.dart';
import 'widgets/group_expense_app_bar.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: GroupExpenseAppBar(
          title: 'Add Expense',
          fallbackRoute: '${Routes.groupExpense}/$tripId',
        ),
        body: SafeArea(
          child: ExpenseForm(
            tripId: tripId,
            onSaved: (expenseId) => context.pushReplacement(
              Uri(
                path:
                    '${Routes.groupExpense}/$tripId/${Routes.expenseDetails}/$expenseId',
                queryParameters: const {
                  'message': 'Expense added successfully',
                },
              ).toString(),
            ),
          ),
        ),
      );
}
