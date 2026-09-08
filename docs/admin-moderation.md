# Admin module

The admin module follows the suggested layouts and core workflow in
`admin_module_codex_spec.md`, supplied by the project owner. Safety/emergency
administration is excluded. Image removal remains deferred for placement elsewhere;
the existing server operation is retained, with no removal control in this UI.

## Navigation and layouts

- `/admin`: two-column attention cards (pending, under review, suspended, banned),
  reports received today, resolved reports, recent report table and recent activities.
- `/admin/reports`: search by report/user ID or name, status/category/date filters,
  newest/oldest sorting, paginated report table; cards on narrow screens.
- `/admin/reports/:reportId`: reporter and reported-user sections, current account
  status and previous reports, description, internal note, decision form and case history.
- `/admin/users`: search by display name, email or user ID, account-status filter,
  report/warning counts and links to user details.
- `/admin/users/:userId`: basic account information, moderation summary, most recent
  50 activities and reports, and actions appropriate to the account's current status.
- `/admin/activity`: paginated, read-only audit records filtered by admin, action and date.

Wide screens use a sidebar; narrow screens use a navigation drawer. All pages reuse
the application's Material theme. Loading, empty, error/retry and action-busy states
are included. Dashboard cards open the corresponding filtered reports/users page.

The existing report schema has no attachment or priority fields. The case page shows
that no attachments were submitted; it does not fabricate evidence or priority data.
Notifications, custom suspension durations and optional priority are not added.

## Official user-to-user report reasons

The user report form and admin category filter share `UserReportReason`. Existing
stored enum values are retained, including `hateSpeech`, now presented under the
broader Inappropriate or Offensive Behaviour category. Historical cases keep their
original descriptions and IDs; no report table is duplicated.

| Stored value | Official label | Description | Review attention |
| --- | --- | --- | --- |
| `harassment` | Harassment or Bullying | Repeated targeting, insults, intimidation, bullying, pressure, or persistent unwanted interaction. | Higher |
| `hateSpeech` | Inappropriate or Offensive Behaviour | Obscene, abusive, discriminatory, sexually inappropriate, or seriously offensive behaviour. | Higher |
| `threatsSafetyConcerns` | Threats or Safety Concerns | Threats, intimidation, possible physical harm, or behaviour that creates a direct personal safety concern, including meetup-related concerns. | Safety concern - review first |
| `spamUnwantedMessages` | Spam or Unwanted Messages | Repeated unwanted messages, promotional messages, irrelevant messages, or similar spam behaviour. | Normal |
| `impersonation` | Fake Account / Impersonation | Pretending to be another person or deliberately misrepresenting identity. | Normal |
| `scam` | Scam or Fraud | Deceiving another user for money, personal information, account access, or another benefit. | Higher |
| `inappropriateContent` | Inappropriate Content | Explicit, disturbing, inappropriate, or seriously offensive images, text, links, or other shared content. | Normal |
| `safetyFeatureMisuse` | Misuse of Safety / Emergency Features | Deliberate abuse of GoBuddy safety/emergency functions, such as prank activation, repeated false activation, or using safety features to harass someone. Accidental activation must not automatically be treated as misuse. | Higher |
| `suspiciousDangerousBehaviour` | Suspicious or Dangerous Behaviour | Potentially dangerous real-world behaviour, especially behaviour related to meeting another GoBuddy user. | Safety concern - review first |
| `other` | Other | Used when the issue does not reasonably fit the predefined categories. Please provide a description. | Normal |

User flow: select a reason, describe what happened, confirm, submit, then receive a
success message. A reason is required. Other requires a trimmed, non-whitespace
description; all descriptions are limited to 1,000 characters. Submission controls
are disabled during confirmation/network work. Errors use safe messages, never raw
database details. Reporting creates a Pending moderation case and does not block
the user. Blocking remains a separate action.

Attention labels highlight safety concerns and higher-attention categories in the
admin report queue/details. They are review guidance only; chronological sorting
remains available. Categories and report counts never automatically warn, suspend
or ban anyone. Accidental emergency activation is not automatically misuse.
These reasons belong to ordinary Reports, not a separate emergency-management page.
The existing admin review/confirmation/audit workflow remains unchanged.

The authenticated session supplies reporter_id. Existing RLS restricts users to
their own reports and rejects forged reviewer/status fields. Internal admin notes
remain in the protected audit table. Evidence uploads are not added because the
existing report system has no attachment support.

Migration `20260906000100_official_report_reasons.sql` expands the existing reason
constraint and adds content validation for new/edited Other reports. Historical
Other cases without descriptions remain reviewable; no description is invented.
This migration was applied to the linked Supabase project on 6 September 2026.
The existing Edge Function already supports these values; no redeployment is needed.

Files updated: this document; `safety/model/user_safety.dart` (shared enum,
descriptions, attention and validation); `safety/repository/user_safety_repository.dart`
(validation and safe errors); `safety/ui/widgets/report_user_action.dart` (form and
confirmation); admin screen, detail screen and shared widgets (labels, filters and
attention); existing admin UI test expectations.
Files added: `safety/ui/view_model/report_user_view_model.dart` (busy state and
submission); the migration above; `test/features/safety/report_user_test.dart`;
`supabase/tests/official_report_reasons.sql` (database regression checks).
All Dart feature paths above are under `lib/features/`.

## Decisions and enforcement

Reports progress from Pending to Under Review, then Resolved or Dismissed. Review
notes and confirmations are required. A report alone never punishes the reported user.
Decisions include dismissal, resolution without an account action, warning, 1/3/7/30-day
suspension and permanent ban. Reactivation is available from User Management.
Administrator accounts cannot receive account moderation actions.

`admin_users` remains the role authority; user-editable metadata never grants access.
The Edge Function authenticates every request and checks the protected role and
current restriction. Its service-role key stays on the server.

The existing `account_bans` record is the authority for application restrictions:
null `expires_at` means permanent ban, a future expiry means suspension, and an expired
record no longer restricts access. The RLS active-account policies and PostgREST
pre-request hook enforce this for existing JWTs. The router also handles suspended
accounts, and access can be retried after expiry. New restrictions do not write Auth
ban durations: this lets account state, case resolution and audit history commit in
one database transaction. Reactivation first clears any legacy Auth ban through the
server-only Auth API, then releases the database restriction. If the API fails, the
restriction remains in place. See [Supabase Auth admin updates](https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid).

New service-role Edge Functions must check account restrictions explicitly, as they
bypass RLS. Public resources and previously downloaded data remain public/available.
Expired restrictions stay recorded in audit history. Internal notes are kept in the
protected audit table and are never copied into reporter-visible report fields.

## Deployment

Deployment completed on 6 September 2026 in project `xnkobjlnduowpwwxscvh`.
The following migrations are now applied, after the earlier 001/002 migrations:

1. `supabase/migrations/20260905000300_admin_report_workflow.sql`
2. `supabase/migrations/20260905000400_admin_case_management.sql`

Migration 004 adds the restriction expiry and audit report link, service-only summary
views and search functions, and the atomic moderation decision function. It updates
account-access helpers without renaming or removing existing tables. Existing user
safety/emergency functionality is unchanged.

```sh
supabase functions deploy admin-moderation --project-ref xnkobjlnduowpwwxscvh --no-verify-jwt
```

The updated endpoint was deployed through the authenticated Supabase CLI because
the connector lacked Edge Function deployment scope. Gateway JWT verification is
disabled; the function itself verifies the token with `auth.getUser` and checks the
protected admin role on every request.

Live read-only verification passed for all dashboard queries using the service role
(15 users, 1 pending report at verification time), report/user search functions, and
the admin-only database grants. The deployed endpoint returned HTTP 401 with
`Sign in required` for an unauthenticated dashboard request. An authenticated app
session was not available for an end-to-end UI check; refresh the dashboard in the
signed-in admin session to load the newly deployed backend.

## Validation

```sh
flutter test test/features/admin
node --test supabase/functions/admin-moderation/index.test.mjs
```

`supabase/tests/admin_case_management.sql` validates workflow, failed-action atomicity,
warning history, suspension expiry, ban/reactivation, dismissal, search/filtering and
role/grant protection. Run it against a disposable database with one admin and two
ordinary user profiles. It rolls back its fixture changes. It has passed locally in
PGlite using the existing report schema and migrations 001, 003 and 004. This does
not replace a live Supabase integration check after deployment.

## Files changed for specification alignment

Created:
- `lib/features/admin/ui/admin_detail_screens.dart`
- `lib/features/admin/ui/widgets/admin_widgets.dart`
- `supabase/migrations/20260905000400_admin_case_management.sql`
- `supabase/tests/admin_case_management.sql`
- `supabase/functions/admin-moderation/index.test.mjs`
- `test/features/admin/admin_spec_ui_test.dart`

Updated:
- Admin screen, models, repository and ViewModel under `lib/features/admin/`
- `supabase/functions/admin-moderation/index.ts`
- `lib/core/routing/router.dart` and `account_access_redirect.dart`
- `lib/features/user_account/repository/authentication_repository.dart`
- Existing admin widget/access tests and this document

Existing functions affected: admin listing/profile/report queries, dashboard queries,
moderation submission, access redirection and onboarding access checks. Login screen
and ordinary user safety screens were not changed for this update.
