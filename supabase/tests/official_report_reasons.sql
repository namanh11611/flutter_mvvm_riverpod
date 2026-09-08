begin;
do $$
declare reporter uuid; target uuid; report uuid; value text;
begin
  select id into reporter from public.user_accounts order by id limit 1;
  select id into target from public.user_accounts where id <> reporter order by id limit 1;
  foreach value in array array['harassment','hateSpeech','threatsSafetyConcerns',
    'spamUnwantedMessages','impersonation','scam','inappropriateContent',
    'safetyFeatureMisuse','suspiciousDangerousBehaviour','other'] loop
    insert into public.user_reports(reporter_id,reported_user_id,reason,description)
      values(reporter,target,value,'Test description') returning id into report;
    if (select status from public.user_reports where id = report) <> 'pending' then
      raise exception 'Reports must start Pending'; end if;
  end loop;
  begin
    insert into public.user_reports(reporter_id,reported_user_id,reason,description)
      values(reporter,target,'other',E' \t\n ');
    raise exception 'TEST: whitespace-only Other accepted';
  exception when raise_exception then if sqlerrm like 'TEST:%' then raise; end if;
  end;
  begin
    insert into public.user_reports(reporter_id,reported_user_id,reason)
      values(reporter,target,'unknown');
    raise exception 'TEST: unknown reason accepted';
  exception when check_violation then null;
  end;
end $$;
rollback;
