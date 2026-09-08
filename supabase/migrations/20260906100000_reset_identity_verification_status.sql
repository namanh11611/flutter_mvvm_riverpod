-- Development/test reset: treat every account as never verified.
-- Keep identity_verifications rows and provider session history intact so the
-- audit trail is not destroyed. This changes only the current account status.
update public.user_accounts
set verification_status = 'unverified',
    updated_at = now()
where verification_status is distinct from 'unverified';

-- Existing attempts remain available for troubleshooting and webhook replay.
-- Do not delete or rewrite them here: Didit retains its own verification
-- history, and deleting local rows would make late callbacks ambiguous.
