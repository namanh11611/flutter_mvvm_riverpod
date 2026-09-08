import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/model/traveller.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/record_settlement_screen.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/state/settlement_state.dart';
import 'package:flutter_mvvm_riverpod/features/group_expense/ui/view_model/settlement_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currentUserId = 'a6d921c9-f698-4e2f-810f-b99d00740a6e';
  const otherUserId = 'member-b';

  testWidgets('member selectors build exactly one item for each user id', (
    tester,
  ) async {
    final state = SettlementState(
      tripId: 'trip',
      currency: 'MYR',
      currentUserId: currentUserId,
      travellers: const [
        Traveller(
          userId: currentUserId,
          displayName: 'Member A',
          initials: 'MA',
        ),
        Traveller(userId: otherUserId, displayName: 'Member B', initials: 'MB'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementViewModelProvider(
            'trip',
          ).overrideWith(() => _StubSettlementViewModel(state)),
        ],
        child: const MaterialApp(
          home: RecordSettlementScreen(
            tripId: 'trip',
            initialPayerId: currentUserId,
            initialPayeeId: otherUserId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    expect(find.text('Member A'), findsOneWidget);
    expect(find.text('Member B'), findsOneWidget);
  });

  testWidgets(
    'invalid current-user roster shows an error instead of dropdown assertion',
    (tester) async {
      final state = SettlementState(
        tripId: 'trip',
        currency: 'MYR',
        currentUserId: currentUserId,
        travellers: const [
          Traveller(
            userId: otherUserId,
            displayName: 'Member B',
            initials: 'MB',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementViewModelProvider(
              'trip',
            ).overrideWith(() => _StubSettlementViewModel(state)),
          ],
          child: const MaterialApp(
            home: RecordSettlementScreen(tripId: 'trip'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('You must be a trip member to record a settlement.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'duplicate member ids are rejected instead of becoming dropdown items',
    (tester) async {
      final state = SettlementState(
        tripId: 'trip',
        currency: 'MYR',
        currentUserId: currentUserId,
        travellers: const [
          Traveller(
            userId: currentUserId,
            displayName: 'Member A',
            initials: 'MA',
          ),
          Traveller(
            userId: currentUserId,
            displayName: 'Member A duplicate',
            initials: 'MA',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementViewModelProvider(
              'trip',
            ).overrideWith(() => _StubSettlementViewModel(state)),
          ],
          child: const MaterialApp(
            home: RecordSettlementScreen(tripId: 'trip'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Unable to load a valid trip member roster.'),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    },
  );
}

class _StubSettlementViewModel extends SettlementViewModel {
  _StubSettlementViewModel(this.value);

  final SettlementState value;

  @override
  Future<SettlementState> build(String tripId) async => value;
}
