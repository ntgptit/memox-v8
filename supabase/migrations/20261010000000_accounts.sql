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

-- Every owned row belongs to a live auth user (spec §2.2). Deleting the user deletes the rows;
-- a still-valid token of a deleted user cannot write, since its rows would reference nobody.
alter table public.deck add constraint deck_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.card add constraint card_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.tags add constraint tags_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.delete_batch add constraint delete_batch_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.review_log add constraint review_log_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.card_schedule add constraint card_schedule_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.account_settings add constraint account_settings_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.user_sync_version add constraint user_sync_version_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.sync_applied_op add constraint sync_applied_op_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
alter table public.app_log add constraint app_log_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;

-- card_tags has no user_id: its links go with their card or tag, or deleting a user would
-- fail on them. The other keys between one user's rows stay NO ACTION: the cascade removes
-- both ends in the same statement, and NO ACTION is checked at its end.
alter table public.card_tags
  drop constraint card_tags_card_id_fkey,
  add constraint card_tags_card_id_fkey foreign key (card_id) references public.card (id) on delete cascade,
  drop constraint card_tags_tag_id_fkey,
  add constraint card_tags_tag_id_fkey foreign key (tag_id) references public.tags (id) on delete cascade;

-- The caller, who must still have a profile: a deleted user's live token gets UNAUTHORIZED.
create function private.require_current_profile() returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if not exists (select 1 from public.profiles p where p.id = v_user) then
    raise exception 'UNAUTHORIZED';
  end if;
  return v_user;
end
$$;

-- At most one write a day per user (spec §2.3); the 90-day cleanup reads it.
create function private.touch_user_activity(p_user uuid) returns void
language sql set search_path = '' as $$
  update public.profiles set last_active_at = now()
  where id = p_user and last_active_at < now() - interval '1 day'
$$;

create function public.me() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
  v_me jsonb;
begin
  perform private.touch_user_activity(v_user);
  select jsonb_build_object('id', u.id, 'email', u.email, 'isAnonymous', u.is_anonymous, 'role', p.role)
  into v_me
  from auth.users u join public.profiles p on p.id = u.id
  where u.id = v_user;
  return v_me;
end
$$;
revoke all on function public.me() from public, anon, authenticated;
grant execute on function public.me() to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;

-- Roles are changed one at a time, so two admins demoting each other cannot leave none.
create function private.lock_roles() returns void
language sql set search_path = '' as $$
  select pg_advisory_xact_lock(hashtext('public.profiles.role'))
$$;

create function public.role_list(p_query text, p_after text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit constant integer := 50;
  v_items jsonb;
  v_next text;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  with page as (
    select u.id, u.email, p.role, u.created_at, u.last_sign_in_at,
           row_number() over (order by u.email) as n
    from auth.users u join public.profiles p on p.id = u.id
    where not u.is_anonymous and u.email is not null
      and (coalesce(p_query, '') = '' or strpos(lower(u.email), lower(p_query)) > 0)
      and (p_after is null or u.email > p_after)
    order by u.email
    limit v_limit + 1
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'email', email, 'role', role,
           'createdAt', private.wire_time(created_at), 'lastSignInAt', private.wire_time(last_sign_in_at))
           order by email) filter (where n <= v_limit), '[]'),
         case when count(*) > v_limit then max(email) filter (where n = v_limit) end
  into v_items, v_next
  from page;
  return jsonb_build_object('items', v_items, 'next', v_next);
end
$$;

create function public.role_set(p_user uuid, p_role text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_anonymous boolean;
  v_current text;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  if p_role is null or p_role not in ('user', 'admin') then
    raise exception 'INVALID_ROLE';
  end if;
  perform private.lock_roles();
  if not private.is_admin() then  -- demoted while waiting for the lock
    raise exception 'FORBIDDEN';
  end if;
  select u.is_anonymous, p.role into v_anonymous, v_current
  from auth.users u join public.profiles p on p.id = u.id
  where u.id = p_user;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  if p_role = 'admin' and v_anonymous then
    raise exception 'ANONYMOUS_USER';
  end if;
  if v_current = 'admin' and p_role = 'user'
     and (select count(*) from public.profiles where role = 'admin') <= 1 then
    raise exception 'LAST_ADMIN';
  end if;
  update public.profiles
  set role = p_role, role_changed_by = auth.uid(), role_changed_at = now(), updated_at = now()
  where id = p_user;
  return jsonb_build_object('id', p_user, 'role', p_role);
end
$$;
revoke all on function public.role_list(text, text), public.role_set(uuid, text)
  from public, anon, authenticated;
grant execute on function public.role_list(text, text), public.role_set(uuid, text) to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
