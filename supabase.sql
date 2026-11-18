-- 세차관리 앱용 표 (위스키 앱 DRAVÉ와 같은 Supabase 프로젝트, 표 이름은 carwash_ 로 시작)
-- 승인된 멤버(아빠·관리자)만 기록을 읽고 쓸 수 있어요.

create table if not exists public.carwash_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'member' check (role in ('admin','member')),
  created_at timestamptz not null default now()
);

create table if not exists public.carwash_requests (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  email text,
  name text,
  created_at timestamptz not null default now()
);

create table if not exists public.carwash_cars (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

create table if not exists public.carwash_jobs (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

create table if not exists public.carwash_settings (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

create or replace function public.carwash_is_member() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.carwash_members where user_id = auth.uid()) $$;

create or replace function public.carwash_is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.carwash_members where user_id = auth.uid() and role = 'admin') $$;

alter table public.carwash_members  enable row level security;
alter table public.carwash_requests enable row level security;
alter table public.carwash_cars     enable row level security;
alter table public.carwash_jobs     enable row level security;
alter table public.carwash_settings enable row level security;

drop policy if exists "members read" on public.carwash_members;
create policy "members read" on public.carwash_members for select to authenticated
  using (public.carwash_is_member() or user_id = auth.uid());
drop policy if exists "admin manage members" on public.carwash_members;
create policy "admin manage members" on public.carwash_members for all to authenticated
  using (public.carwash_is_admin()) with check (public.carwash_is_admin());

drop policy if exists "request own insert" on public.carwash_requests;
create policy "request own insert" on public.carwash_requests for insert to authenticated
  with check (user_id = auth.uid());
drop policy if exists "request read" on public.carwash_requests;
create policy "request read" on public.carwash_requests for select to authenticated
  using (user_id = auth.uid() or public.carwash_is_admin());
drop policy if exists "request delete" on public.carwash_requests;
create policy "request delete" on public.carwash_requests for delete to authenticated
  using (user_id = auth.uid() or public.carwash_is_admin());

drop policy if exists "member all cars" on public.carwash_cars;
create policy "member all cars" on public.carwash_cars for all to authenticated
  using (public.carwash_is_member()) with check (public.carwash_is_member());
drop policy if exists "member all jobs" on public.carwash_jobs;
create policy "member all jobs" on public.carwash_jobs for all to authenticated
  using (public.carwash_is_member()) with check (public.carwash_is_member());
drop policy if exists "member all settings" on public.carwash_settings;
create policy "member all settings" on public.carwash_settings for all to authenticated
  using (public.carwash_is_member()) with check (public.carwash_is_member());

revoke all on public.carwash_members, public.carwash_requests, public.carwash_cars, public.carwash_jobs, public.carwash_settings from anon;
grant select, insert, update, delete on public.carwash_members, public.carwash_requests, public.carwash_cars, public.carwash_jobs, public.carwash_settings to authenticated;
revoke execute on function public.carwash_is_member(), public.carwash_is_admin() from anon;
