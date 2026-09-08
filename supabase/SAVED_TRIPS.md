# Saved trips

The heart on a discovery card toggles a persisted bookmark in
`matchmaking_saved_trips`. It does not submit a join request. The profile's
**Saved Trips** entry opens `/user_account/saved-trips`.

Saved cards retain full, started, ended, and closed trips in light grey. Details
and removal remain available; joining requires an active upcoming trip with
capacity and no existing membership or open request. The join dialog sends an
introduction through the existing host-approval flow. Joining does not unsave.

The screen refreshes on entry, app resume, every 30 seconds while active, and
on pull-to-refresh. Submission fetches the latest trip and request state first.
Deleted or inaccessible bookmarks are shown as unavailable with a remove action.

Apply `migrations/20260905130000_saved_trip_availability.sql` after the existing
matchmaking migrations. It permits savers to read closed published trips while
preserving restrictive block policies, enables bookmark realtime updates, and
checks start time and capacity at the database write boundary. This migration
has been tested locally; it has not been applied to the live project.

Checks:

```powershell
flutter test --no-pub test/saved_trips_test.dart test/matchmaking_view_model_test.dart test/matchmaking_trip_details_widget_test.dart
npm.cmd install --prefix .dart_tool/verification-tools --no-save @electric-sql/pglite
node --test supabase/tests/saved_trips_database.test.mjs
```
