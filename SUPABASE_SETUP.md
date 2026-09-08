# GoBuddy Supabase and Database Guide

This folder records database changes so the Supabase schema is reviewed and
shared through Git alongside the Flutter code. Supabase runs the database;
these SQL files are the versioned record of how it was created.

## Current files

| File | Purpose | Run order |
|---|---|---:|
| `001_matchmaking_schema.sql` | Matchmaking types, tables, constraints, and indexes | 1 |
| `002_matchmaking_rls.sql` | Matchmaking Row Level Security and access policies | 2 |
| `003_matchmaking_api_access_and_profiles.sql` | Public profiles and explicit Flutter Data API grants | 3 |

Check with the project owner which scripts have already been applied to the
shared development project. Run only the next unapplied script; do not rerun
older scripts. These files are also used for review and recovery.

## First-time Flutter setup

1. Ask the project owner for the development **Project URL** and
   **publishable key**. Never request or share the `service_role` key.
2. Create a local `.env` file in the repository root:

   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-publishable-key
   ```

3. Keep the project's other required environment variables in the same file.
4. Generate the Envied output:

   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```

5. Install dependencies and run the app:

   ```powershell
   flutter pub get
   flutter run
   ```

`.env` is ignored by Git. Never force-add it or paste credentials into Dart,
SQL, screenshots, issues, commits, or chat messages.

## Temporary development test user

The complete user-account module is still under development. For now, the
existing email/password Login screen authenticates against Supabase so that
developers can obtain a real session and test RLS-protected features.

Create a development user in the shared Supabase project:

1. Open **Supabase Dashboard → Authentication → Users**.
2. Select **Add user → Create new user**.
3. Enter a test email address and a non-production password.
4. Enable **Auto Confirm User** if that option is shown.
5. Create the user.
6. Run the Flutter app and sign in with those exact credentials.

Successful login creates a genuine Supabase session, so `auth.uid()` is
available to RLS policies. The launch screen also recognizes a persisted
session and skips Login on later launches.

To verify authentication, return to **Authentication → Users** and check that
the test user's last sign-in time has updated.

Important rules:

- Never commit or hard-code the test email or password.
- Do not use a personal or production password.
- Each developer should preferably use a separate test user.
- The publishable key is valid in Flutter; secret and `service_role` keys are not.
- This test-user flow does not replace completing registration, password reset,
  profile creation, logout, and production authentication handling.

## Setting up a fresh Supabase project

In the Supabase Dashboard:

1. Create a project.
2. Enable the Data API.
3. Disable **Automatically expose new tables**.
4. Enable automatic RLS.
5. Open **SQL Editor** and run `001_matchmaking_schema.sql`.
6. In a new query, run `002_matchmaking_rls.sql`.
7. In a new query, run `003_matchmaking_api_access_and_profiles.sql`.
8. Verify with:

   ```sql
   select *
   from public.matchmaking_trips
   order by created_at;
   ```

Run selected SQL or use separate query tabs. Running the complete schema twice
will produce errors such as `type "trip_status" already exists`.

## Rules for team members

1. Do not edit an SQL file after it has been applied to the shared database.
2. Put every database change in a new numbered file.
3. Use the next available number and a descriptive name, for example:

   ```text
   003_expense_tables.sql
   004_chat_tables.sql
   005_add_trip_notifications.sql
   ```

4. A module owner should modify only their module's tables unless the team has
   agreed on a shared-table change.
5. Run new SQL on the development project, test it, and commit the SQL file
   with the related Flutter changes.
6. Every table accessible from Flutter must have RLS and explicit policies.
7. Never store user passwords. Supabase Auth owns credentials in `auth.users`.
8. Never use the database password, secret key, or `service_role` key in Flutter.
9. Review `drop`, destructive `alter`, and cascade changes with the team first.

## Adding a database change

Example: a member wants to add an expense module.

1. Pull the latest repository changes.
2. Create `database/003_expense_tables.sql`.
3. Add the expense tables, constraints, indexes, RLS, and policies.
4. Run only that new file in the Supabase SQL Editor.
5. Test the module against the development project.
6. Commit and open a pull request:

   ```powershell
   git add database/003_expense_tables.sql
   git add lib test
   git commit -m "add expense database schema"
   git push
   ```

Pulling from Git does not automatically run SQL. Existing SQL files are history;
only newly approved database changes need to be applied to the shared project.

## Shared schema decisions

Coordinate before changing tables referenced by multiple modules, especially:

- Supabase Auth and user profiles
- Trips and trip membership
- Shared notifications
- Storage buckets
- Foreign-key deletion behavior

Use module-specific prefixes when names could collide. Current matchmaking
tables use the `matchmaking_` prefix.

## Current integration status

The matchmaking trip repository now reads and writes trips, styles, and saved
trips through Supabase for authenticated users. When Supabase is unavailable
or tests do not initialize it, the repository's demo data remains available.

The remaining integration order is:

1. Complete Register/Logout/password recovery and profile creation.
2. Connect join-request and membership actions to Supabase.
3. Add an atomic database function for accepting requests and preventing
   overbooking.
4. Add Storage policies if trip image uploads are implemented.
5. Add loading, error, retry, and integration tests.

## Common errors

### `type "trip_status" already exists`

The schema was run more than once. Open a new query and run only the SQL you
intend to test.

### `new row violates row-level security policy`

The user is not signed in, the inserted owner/applicant ID does not equal
`auth.uid()`, or a required policy is missing.

### Flutter receives an empty list

Confirm the table contains data, the user has a Supabase session, and the
select policy permits that user to see the rows.

### `relation does not exist`

The relevant schema file has not been applied to that Supabase project or the
table name is incorrect.

## Moving to Supabase CLI later

The manual SQL workflow is sufficient for the current team project. If the
database becomes larger, migrate these files into `supabase/migrations/` and
use the Supabase CLI for local resets, schema diffs, and automated deployment.

## Group Communication & Collaboration

Run these files in the following order after the matchmaking schema and RLS
scripts above. Open each file in VS Code, copy its **SQL contents** (not the
file path), and run it in Supabase Dashboard → SQL Editor.

1. `supabase/migrations/20260816_group_collaboration.sql`
2. `supabase/migrations/20260820_group_collaboration_permissions.sql`
3. `supabase/migrations/20260821_accept_request_adds_member.sql`
4. `supabase/migrations/20260824000100_matchmaking_hardening.sql`
5. `supabase/migrations/20260825000100_collaboration_engagement.sql`
6. `supabase/migrations/20260825000200_collaboration_enhancements.sql`
7. `supabase/migrations/20260825000300_collaboration_member_management.sql`
8. `supabase/migrations/20260825000400_collaboration_membership_sync.sql`
9. `supabase/migrations/20260825000500_collaboration_polish.sql`
10. `supabase/migrations/20260825_collaboration_api_grants.sql`
11. `supabase/migrations/20260826100000_collaboration_event_reads.sql`

The collaboration engagement, enhancement, and API-grant migrations are
required for Add Activity, Pin, Lock, Create Poll, Vote, RSVP, activity
history, typing, read receipts, and reversible member controls. If the app
reports that `public.save_matchmaking_trip` is missing, run
`20260824000100_matchmaking_hardening.sql`.

### Flutter web Google sign-in

In Supabase Dashboard → Authentication → URL Configuration, add:

```text
http://localhost:3000/**
```

Keep the local app running while signing in:

```powershell
& 'C:\flutter\bin\flutter.bat' run -d chrome --web-port 3000
```
