-- Storage policies for expense receipts inspect public.expenses. PostgreSQL
-- can evaluate those policies for uploads to other buckets as well, so the
-- authenticated role must be allowed to run the policy's SELECT. Row-level
-- security remains responsible for limiting which expense rows are visible.
do $$
begin
  if to_regclass('public.expenses') is not null then
    grant select on table public.expenses to authenticated;
  end if;
end
$$;

