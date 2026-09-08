-- Retain the existing enum names so historic reports/older clients still work.
alter table public.user_reports drop constraint user_reports_reason_check;
alter table public.user_reports add constraint user_reports_reason_check check (reason in (
  'harassment', 'hateSpeech', 'threatsSafetyConcerns', 'spamUnwantedMessages',
  'impersonation', 'scam', 'inappropriateContent', 'safetyFeatureMisuse',
  'suspiciousDangerousBehaviour', 'other'
));

-- Historical Other reports may lack details; do not invent descriptions or stop
-- admins reviewing them. Enforce this on new submissions/changes to their content.
create function public.validate_user_report_description() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.reason = 'other' and (new.description is null or
    new.description !~ '[^[:space:]]') then
    raise exception 'A description is required for Other reports';
  end if;
  return new;
end;
$$;
revoke all on function public.validate_user_report_description() from public, anon, authenticated;
create trigger validate_user_report_description before insert or update of reason, description
  on public.user_reports for each row execute function public.validate_user_report_description();
