-- Run this once in Supabase: SQL Editor > New query > paste > Run

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  created_by uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.work_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  area text,
  notes text,
  progress int not null default 0 check (progress between 0 and 100),
  before_path text,
  after_path text,
  created_by uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on public.work_items (project_id, created_at desc);

create function public.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

create trigger work_items_touch before update on public.work_items
for each row execute function public.touch_updated_at();

-- Row level security: every signed-in team member can read and write.
alter table public.projects enable row level security;
alter table public.work_items enable row level security;

create policy "projects read"   on public.projects for select to authenticated using (true);
create policy "projects insert" on public.projects for insert to authenticated with check (true);
create policy "projects update" on public.projects for update to authenticated using (true);
create policy "projects delete" on public.projects for delete to authenticated using (true);

create policy "items read"   on public.work_items for select to authenticated using (true);
create policy "items insert" on public.work_items for insert to authenticated with check (true);
create policy "items update" on public.work_items for update to authenticated using (true);
create policy "items delete" on public.work_items for delete to authenticated using (true);

-- Photo storage bucket (public read, signed-in upload)
insert into storage.buckets (id, name, public)
values ('site-photos', 'site-photos', true)
on conflict (id) do nothing;

create policy "photos read"   on storage.objects for select using (bucket_id = 'site-photos');
create policy "photos insert" on storage.objects for insert to authenticated with check (bucket_id = 'site-photos');
create policy "photos update" on storage.objects for update to authenticated using (bucket_id = 'site-photos');
create policy "photos delete" on storage.objects for delete to authenticated using (bucket_id = 'site-photos');
