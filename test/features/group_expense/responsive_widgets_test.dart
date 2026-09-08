import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/settlement.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/traveller_balance.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/trip_budget.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/state/budget_state.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/balance_card.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/budget_summary_panel.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/expense_card.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/settlement_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('core cards do not overflow on a narrow Android screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ExpenseCard(
                title: 'An extremely long international restaurant expense',
                subtitle: 'December 31, 2025',
                amount: 'RM 123,456.78',
                onTap: () {},
              ),
              const BalanceCard(
                balance: TravellerBalance(
                  userId: '1',
                  name: 'A traveller with a very long full legal name',
                  initials: 'TL',
                  netBalance: -123456.78,
                  status: TravellerBalanceStatus.needsPayment,
                ),
                formattedBalance: '-RM 123,456.78',
              ),
              SettlementCard(
                description: 'A very long payer name → A very long payee name',
                amount: 'RM 123,456.78',
                paymentMethod: 'Very Long Payment Method',
                date: 'December 31, 2025',
                status: SettlementStatus.pending,
                hasReceipt: true,
                onConfirm: () {},
                onReject: () {},
              ),
              BudgetSummaryPanel(state: _budgetState()),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

BudgetState _budgetState() => BudgetState(
      tripId: '1',
      budget: TripBudget(
        budgetId: '1',
        tripId: '1',
        budgetName: 'A very long international group travel budget',
        budgetAmount: 200000,
        baseCurrency: 'MYR',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
      totalSpent: 123456.78,
    );
