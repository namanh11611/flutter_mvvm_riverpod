alter table public.matchmaking_trips
  add column if not exists gallery_image_urls text[] not null default '{}';

comment on column public.matchmaking_trips.gallery_image_urls is
  'User-uploaded trip gallery photos; cover_image_url remains the destination cover.';
