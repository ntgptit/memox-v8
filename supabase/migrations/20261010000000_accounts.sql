-- SB-A1 / auth spec 2026-09-30 §2: profiles with a role, owned rows keyed to auth.users,
-- and the account RPCs. Our tables live in public, internal functions in private.

-- A function created from here on is closed to clients until granted (spec §2.1).
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

-- The business user, one per auth user (spec §2.2).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'user' check (role in ('user', 'admin')),
  role_changed_by uuid null references auth.users (id) on delete set null,
  role_changed_at timestamptz null,
  last_active_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
revoke all on table public.profiles from public, anon, authenticated;

-- Idempotent, and deliberately without an exception handler: a broken trigger must fail
-- the sign-up loudly, not leave a user without a profile.
create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

-- Existing users get a profile; an admin set by hand in app_metadata (ADR-018 §7) keeps it.
create function private.backfill_profiles() returns void
language sql set search_path = '' as $$
  insert into public.profiles (id, role)
  select u.id, case when u.raw_app_meta_data->>'role' = 'admin' then 'admin' else 'user' end
  from auth.users u
  on conflict (id) do nothing
$$;
select private.backfill_profiles();

revoke all on all functions in schema private from public, anon, authenticated;

-- The admin role lives in profiles (spec O8); the log RPCs keep calling this.
create or replace function private.is_admin() returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
$$;
revoke all on function private.is_admin() from public, anon, authenticated;
