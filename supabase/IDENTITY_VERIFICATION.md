# Identity verification

GoBuddy exposes only `unverified`, `pending`, and `verified`, in both the account
and verification-attempt status columns. Didit's detailed lifecycle is stored
separately as `provider_status`.

| Didit result | GoBuddy status |
| --- | --- |
| Not Started, In Progress, In Review, Resubmitted, Awaiting User | pending |
| Approved | verified |
| Declined, Expired, Abandoned, Kyc Expired | unverified |

Every account status transition inserts a notification into
`matchmaking_notifications` in the same database transaction. Rejection messages
include the latest manual rejection's status-change comment, or the declined
checks' warning descriptions. Write manual rejection comments for the user to
read. If Didit supplies no reason, the notification explicitly says so rather
than inventing one. The app reads the full message in its existing notification
inbox; tapping it opens verification so the user can retry.

The existing `push-notification` function delivers these inserts to registered
devices. Opening a foreground or background verification notification routes to
the verification screen. Pending status is refreshed while that screen or the
profile is active and when the app resumes. The client does not grant verification.

## Deployment

1. Review and apply
   `migrations/20260905120000_complete_identity_verification.sql` to the linked
   Supabase database. This extends the existing account/notification schema and
   migrates legacy attempt status strings. It assumes the existing attempt `id`
   is UUID and its `status` is text, consistent with the project's SQL conventions.
   Check the deployed schema before applying if it was created outside migrations.
   The local database tests cover a representative legacy schema, not a live dump.
2. Set the function secrets in Supabase: `DIDIT_API_KEY`, `DIDIT_WORKFLOW_ID`, and
   `DIDIT_WEBHOOK_SECRET`. Supabase supplies `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   and `SUPABASE_SERVICE_ROLE_KEY`. Keep all provider and service secrets off the
   Flutter client and out of source control.
3. Deploy the functions:

   ```powershell
   supabase functions deploy create-didit-session
   supabase functions deploy didit-webhook --no-verify-jwt
   ```

   `supabase/config.toml` disables the gateway JWT check only for `didit-webhook`.
   The function requires a valid Didit HMAC signature and signed fresh timestamp.
4. In Didit, create a V3 webhook destination at
   `https://<project-ref>.supabase.co/functions/v1/didit-webhook`, subscribed to
   `status.updated` and `data.updated`. Use that destination's shared secret as
   `DIDIT_WEBHOOK_SECRET`.
5. Confirm the existing database INSERT webhook for
   `public.matchmaking_notifications` calls `push-notification`, that its
   `x-webhook-secret` matches `PUSH_WEBHOOK_SECRET`, and that
   `FIREBASE_SERVICE_ACCOUNT` and device-token registration are configured.
   In-app messages are saved even if push delivery is unavailable.
6. Test on a signed-in phone with Didit's sandbox workflow: start, continue the
   same session, approve, reject with a reason, retry, and expire. Verify the
   inbox, foreground/background push, profile badge, and return from the browser.
   Replay an event and confirm that it does not create another notification.

New sessions use `gobuddy://app/identity-verification` as their callback with
`callback_method: both`. Android registers the `app/identity-verification` deep
link and iOS registers the `gobuddy` URL scheme. The router opens the identity
verification screen, which refreshes the trusted database status when the app
resumes. Sessions created before this callback was added must be replaced to gain
the automatic return behavior.

Duplicate event IDs, earlier event times, and callbacks from superseded attempts
do not overwrite the current result. `created_at` orders provider events;
`timestamp` validates each delivery's freshness. A short database lease prevents
concurrent session-creation calls. Session save, pending status and notification
commit together. Status/notification failures roll back the webhook dedup record
so delivery can be retried. Unknown sessions return 503 to cover the brief race
between provider creation and database save.

If a provider callback is never delivered, local refresh reads the last saved
database status. Inspect Didit's delivery logs and replay that event; polling in
the app does not query Didit directly. Provider sessions created before this
change without a stored URL can be replaced by starting verification again.

## Admin review

Platform admins listed in `public.admin_users` see **Identity reviews** in the
app's admin navigation. The queue is loaded from Didit's sessions API, accepts
both `In Review` and `IN_REVIEW` provider formatting, and joins only matching
review sessions to local verification attempts and user profiles. Opening a case retrieves its decision report and evidence from
Didit through `admin-moderation`; provider credentials and evidence URLs are
never exposed to non-admin database clients.

Approve, reject, and request-resubmission actions call Didit's session status API
and write a moderation audit entry. A rejection requires a user-facing reason.
The signed Didit webhook remains responsible for changing the account to
`verified`, `unverified`, or `pending`. Resubmission also sends the admin's
instructions immediately because it leaves the public status at `pending`.

## Local checks

```powershell
flutter test --no-pub test/features/user_account/user_account_view_model_test.dart test/features/user_account/identity_verification_screen_test.dart
node --test supabase/tests/didit.test.mjs
npm.cmd install --prefix .dart_tool/verification-tools --no-save @electric-sql/pglite
node --test supabase/tests/identity_verification_database.test.mjs
deno check supabase/functions/_shared/didit.ts supabase/functions/create-didit-session/index.ts supabase/functions/didit-webhook/index.ts
```

Node 24+ can run the TypeScript helper imported by the Node tests. Test-only npm
dependencies stay in the ignored `.dart_tool` directory.

Provider references:
[webhook signatures and delivery](https://docs.didit.me/integration/webhooks),
[verification statuses](https://docs.didit.me/integration/verification-statuses),
[decision reports](https://docs.didit.me/sessions-api/retrieve-session), and
[manual status-change comments](https://docs.didit.me/management-api/sessions/list-reviews).
