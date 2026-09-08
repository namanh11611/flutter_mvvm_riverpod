import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/model/matchmaking_page.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_shell_screen.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Matchmaking route starts on Discover after My Trips was selected', () {
    final parent = ProviderContainer();
    addTearDown(parent.dispose);
    parent
        .read(matchmakingViewModelProvider.notifier)
        .goTo(MatchmakingPage.myTrips);

    final routeScope = ProviderContainer(
      parent: parent,
      overrides: [
        matchmakingInitialPageProvider.overrideWithValue(
          MatchmakingPage.discover,
        ),
        matchmakingViewModelProvider.overrideWith(MatchmakingViewModel.new),
      ],
    );
    addTearDown(routeScope.dispose);

    expect(
      parent.read(matchmakingViewModelProvider).page,
      MatchmakingPage.myTrips,
    );
    expect(
      routeScope.read(matchmakingViewModelProvider).page,
      MatchmakingPage.discover,
    );
  });

  testWidgets('My Trips route opens the My Trips page', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchmakingInitialPageProvider.overrideWithValue(
            MatchmakingPage.myTrips,
          ),
        ],
        child: const MaterialApp(home: MatchmakingShellScreen()),
      ),
    );

    expect(find.text('My trips'), findsOneWidget);
    expect(find.text('+ Create a new trip'), findsOneWidget);
  });

  testWidgets('discovery does not render local fixture trips', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MatchmakingShellScreen())),
    );
    await tester.pump();
    expect(find.text('Tokyo, Japan'), findsNothing);
    expect(find.text('Kyoto, Japan'), findsNothing);
    expect(find.text('Sign in to discover trips'), findsOneWidget);
  });

  testWidgets('bottom navigation opens My Trips', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MatchmakingShellScreen())),
    );
    await tester.tap(find.byIcon(Icons.luggage_outlined));
    await tester.pump();

    expect(find.text('My trips'), findsOneWidget);
    expect(find.text('+ Create a new trip'), findsOneWidget);
  });

  testWidgets('signed-out discovery hides trip creation', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MatchmakingShellScreen())),
    );
    expect(find.text('GoBuddy'), findsOneWidget);
    expect(find.text('Sign in to discover trips'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
