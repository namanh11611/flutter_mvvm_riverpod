import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/spending_trend_point.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/widgets/spending_trend_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('spending trend renders empty and populated data safely',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpendingTrendChart(points: [])),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendingTrendChart(
            points: [
              SpendingTrendPoint(date: DateTime(2025, 7, 19), amount: 250),
              SpendingTrendPoint(date: DateTime(2025, 7, 20), amount: 580),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Jul 19'), findsOneWidget);
    expect(find.text('Jul 20'), findsOneWidget);
  });
}
