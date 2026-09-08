import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/widgets/activity_proposal_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({
    required Future<bool> Function(String, String?, TimeOfDay) onPropose,
  }) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => ActivityProposalDialog(
              onPropose: onPropose,
              onCreatePoll: (_, _) async {},
              allowPoll: false,
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );

  testWidgets('requires an explicitly selected activity time', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      subject(
        onPropose: (_, _, _) async {
          submitted = true;
          return true;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Museum visit');
    await tester.tap(find.text('Submit proposal'));
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text('Please select a time for this activity'), findsOneWidget);
    expect(find.byType(ActivityProposalDialog), findsOneWidget);
  });

  testWidgets('uses the time picker value when submitting', (tester) async {
    TimeOfDay? submittedTime;
    await tester.pumpWidget(
      subject(
        onPropose: (_, _, time) async {
          submittedTime = time;
          return true;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Museum visit');
    await tester.tap(find.text('Activity time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit proposal'));
    await tester.pumpAndSettle();

    expect(submittedTime, isNotNull);
    expect(find.byType(ActivityProposalDialog), findsNothing);
  });

  testWidgets('keeps missing proposal schema errors non-fatal', (tester) async {
    await tester.pumpWidget(subject(onPropose: (_, _, _) async => false));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Museum visit');
    await tester.tap(find.text('Activity time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit proposal'));
    await tester.pump();

    expect(find.byType(ActivityProposalDialog), findsOneWidget);
    expect(
      find.textContaining('Activity proposals are temporarily unavailable'),
      findsOneWidget,
    );
  });
}
