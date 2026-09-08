# Reset current verification status

To make every GoBuddy account appear as if it has never completed identity
verification, apply:

```powershell
supabase db push
```

The migration `migrations/20260906100000_reset_identity_verification_status.sql`
changes all `user_accounts.verification_status` values to `unverified`. It does
not delete `identity_verifications` rows, Didit session IDs, rejection reasons,
or Didit’s provider-side history.

This is appropriate for a development/test reset. It does not make Didit forget
an approved IC or face. If the same user starts a new session, Didit still sees
the existing identity history. If a new GoBuddy account uses a different
`vendor_data`, duplicate detection may still flag the same IC or face.

Run it only against the intended Supabase project. Check the project link first:

```powershell
supabase projects list
supabase status
```

Then verify the result in SQL:

```sql
select verification_status, count(*)
from public.user_accounts
group by verification_status;
```

Expected result after the migration: one row with `verification_status =
'unverified'` and the total account count.
