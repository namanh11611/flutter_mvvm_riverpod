import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String shellSource;
  late String migrationSource;

  setUpAll(() {
    shellSource = File(
      'lib/features/matchmaking/ui/matchmaking_shell_screen.dart',
    ).readAsStringSync();
    migrationSource = File(
      'supabase/migrations/20260906170000_matchmaking_styles_realtime.sql',
    ).readAsStringSync();
  });

  test('subscribes to every table used to build matchmaking trip cards', () {
    for (final table in <String>[
      'matchmaking_trips',
      'matchmaking_trip_styles',
      'matchmaking_saved_trips',
      'matchmaking_join_requests',
      'matchmaking_notifications',
      'matchmaking_trip_members',
      'trip_members',
    ]) {
      expect(shellSource, contains("table: '$table'"), reason: table);
    }
  });

  test('publishes matchmaking trip styles to Supabase realtime', () {
    expect(migrationSource, contains("tablename = 'matchmaking_trip_styles'"));
    expect(
      migrationSource,
      contains('add table public.matchmaking_trip_styles'),
    );
  });

  test('guards channel callbacks and coalesces realtime refresh bursts', () {
    expect(
      shellSource,
      contains('subscriptionRevision == _subscriptionRevision'),
    );
    expect(shellSource, contains('userId == _subscribedUserId'));
    expect(shellSource, contains('_realtimeRefreshTimer?.cancel()'));
  });
}
