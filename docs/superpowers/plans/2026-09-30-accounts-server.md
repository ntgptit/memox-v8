# Accounts — Server (P1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One Supabase migration that gives every user a `public.profiles` row with a role, links every owned row to `auth.users`, and adds the account RPCs (`me`, roles, claim/merge/ack, delete) and the daily cleanup, all proven by pgTAP.

**Architecture:** A single new migration `supabase/migrations/20261010000000_accounts.sql`, built section by section (one section per task), plus `supabase/tests/database/12_account.sql` built the same way. Every public RPC is `security definer` with `set search_path = ''` and checks the caller first; helpers live in `private`. Nothing in the app calls the new RPCs yet; Monitoring's admin check moves to `profiles` with the role backfilled, so production behaves as today.

**Tech Stack:** Postgres 16 (Supabase), PL/pgSQL, pgTAP, pg_cron; local runner `tools/supabase/local_pgtap.sh`.

**Spec:** `docs/superpowers/specs/2026-09-30-auth-design.md` (§2 server, §9 server row, §10 risks, §11 P1).

## Global Constraints

- Migration file: `supabase/migrations/20261010000000_accounts.sql` (sorts after `20261009000000`); applied migrations are never edited.
- Schema rule (spec O10): our tables in `public`, internal functions in `private`, `auth` belongs to Supabase.
- Every table: `enable row level security`, no policy, `revoke all … from public, anon, authenticated`.
- Every public RPC: `security definer`, `set search_path = ''`, schema-qualified names, authorization first; `revoke all … from public, anon, authenticated` then `grant execute … to authenticated`.
- Every private function: `revoke all … from public, anon, authenticated` (test `04_function_privileges.sql` enforces it for the whole schema).
- `alter default privileges in schema public revoke execute on functions from public, anon, authenticated` (spec §2.1).
- Business errors are the exception message (SQLSTATE `P0001`), as in the existing RPCs: `NOT_AUTHENTICATED`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `INVALID_ROLE`, `ANONYMOUS_USER`, `LAST_ADMIN`, `NOT_ANONYMOUS`, `NOT_PERMANENT`, `CLAIM_INVALID`.
- Local gate: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh` (every file must print `ok`); CI's `supabase` job is the real gate.
- Commit trailers: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2`.

## Preconditions

1. **Orphan check on production (owner-approved, read-only).** Adding the foreign keys fails if any owned row points at a user that no longer exists (for example a test user deleted from the dashboard). Before the PR merges, run on the project (Supabase MCP `execute_sql`, read-only):
   ```sql
   select 'deck' t, count(*) from public.deck where user_id not in (select id from auth.users)
   union all select 'card', count(*) from public.card where user_id not in (select id from auth.users)
   union all select 'tags', count(*) from public.tags where user_id not in (select id from auth.users)
   union all select 'delete_batch', count(*) from public.delete_batch where user_id not in (select id from auth.users)
   union all select 'review_log', count(*) from public.review_log where user_id not in (select id from auth.users)
   union all select 'card_schedule', count(*) from public.card_schedule where user_id not in (select id from auth.users)
   union all select 'account_settings', count(*) from public.account_settings where user_id not in (select id from auth.users)
   union all select 'user_sync_version', count(*) from public.user_sync_version where user_id not in (select id from auth.users)
   union all select 'sync_applied_op', count(*) from public.sync_applied_op where user_id not in (select id from auth.users)
   union all select 'app_log', count(*) from public.app_log where user_id is not null and user_id not in (select id from auth.users);
   ```
   All zero → merge. Any non-zero → stop and ask the owner (the rows are unreachable by any user; the choice is to delete them in a pre-step or keep them and drop that key).

## Rulings made while planning

1. The profile backfill is a function, `private.backfill_profiles()`, called once by the migration, so pgTAP can prove it is idempotent and copies the admin role.
2. Orphans are **not** deleted by the migration: the foreign-key `alter` fails loudly, and the precondition above checks production first.
3. `account_merge` moves the source's `app_log` rows to the target (spec §2.3 "every source row"); a log keeps its history under the account.
4. Two codes beyond the spec: `INVALID_ROLE` (a role other than `user`/`admin`) and `NOT_PERMANENT` (an anonymous caller of `account_merge`).
5. `role_list(p_query text, p_after text)` pages 50 users ordered by email, keyset `email > p_after`, and returns `{items, next}` (`next` = last email when more exist).
6. Tests seed rows directly as `postgres` through a helper, not through `sync_push` (the sync RPCs are covered by files 02–08).
7. The local runner shims `auth.users` with the columns the migration reads (`id`, `email`, `is_anonymous`, `raw_app_meta_data`, `created_at`, `updated_at`, `last_sign_in_at`), as Supabase names them.
8. The cleanup job is `account-cleanup` at `17 4 * * *`, registered like `app-log-retention` (only where pg_cron exists).
9. The cleanup also deletes receipts once acknowledged or expired, and expired claims.
10. `private.is_admin()` stays `language sql stable` without `security definer`: every caller is a definer RPC, as today.
11. The claim token is `gen_random_uuid()`; the table stores `encode(sha256(convert_to(token::text, 'UTF8')), 'hex')` (built-ins, no extension).

## Review Focus

1. **Tags with the same name on both sides of a merge**, one live and one tombstoned: only live tags merge; the source card's link points at the target's tag; the source tombstone moves unchanged.
2. **A target with no `account_settings`**: the source's row moves, with a new version; a target with a row keeps its own and the source's is dropped.
3. **A retry after a lost answer** (same `operation_id`) returns `MERGED` even though the token is consumed; a different op with the consumed token is `CLAIM_INVALID`; another user reusing the op learns nothing.
4. **Deleting a user who owns a whole tree** (root and child decks, a card with a tag link, a review, a schedule, a trash batch, settings, a log): no foreign-key error, nothing left, other users untouched.
5. **The last admin**: demoting it or deleting its account is refused with `LAST_ADMIN`; with two admins, one may demote the other.

Each line has its test in the task that owns the code (Tasks 4, 6, 7, 8).

---

## File map

| File | Change |
|---|---|
| `tools/supabase/local_pgtap.sh` | shim `auth.users` (Task 1) |
| `supabase/tests/database/02…11_*.sql` | insert the users they act as (Task 1); admin fixtures read `profiles` (Task 3) |
| `supabase/migrations/20261010000000_accounts.sql` | new; one section per task (Tasks 2–8) |
| `supabase/tests/database/12_account.sql` | new; grows per task (Tasks 2–8) |
| `CLAUDE.md`, `supabase/README.md`, ADR-015, ADR-018, `docs/wbs_supabase.md`, the spec | Task 9 |

---

### Task 1: `auth.users` in the local runner and in the existing tests

**Files:**
- Modify: `tools/supabase/local_pgtap.sh` (the shim heredoc)
- Modify: `supabase/tests/database/02_deck_push.sql` … `11_log_query_device.sql` (one fixture line each)

**Interfaces:**
- Produces: a table `auth.users (id uuid primary key, email text, is_anonymous boolean not null default false, raw_app_meta_data jsonb default '{}', created_at timestamptz default now(), updated_at timestamptz default now(), last_sign_in_at timestamptz)` locally; every existing test file inserts the users it acts as.

- [ ] **Step 1: Add the shim.** In `tools/supabase/local_pgtap.sh`, inside the first heredoc, after `create schema extensions; create schema auth;`, add:

```sql
-- Supabase's auth.users, reduced to the columns our migrations read.
create table auth.users (
  id uuid primary key,
  email text,
  is_anonymous boolean not null default false,
  raw_app_meta_data jsonb default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_sign_in_at timestamptz
);
```

- [ ] **Step 2: Insert the test users.** In each of `02_deck_push.sql`, `03_batches_and_changes.sql`, `05_card_sync.sql`, `06_tag_sync.sql`, `07_account_settings_sync.sql`, `08_study_history_sync.sql`, `09_app_log.sql`, `10_log_admin_reads.sql`, `11_log_query_device.sql`, add right after the `select plan(…);` line:

```sql
-- The users these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-00000000000a'), ('cccccccc-0000-0000-0000-000000000001')
on conflict (id) do nothing;
```

- [ ] **Step 3: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok` for `01` … `11`, same counts as before (01: 12, 02: 32, 03: 19, 04: 7, 05: 15, 06: 15, 07: 9, 08: 16, 09: 33, 10: 28, 11: 9).

- [ ] **Step 4: Commit**

```bash
git add tools/supabase/local_pgtap.sh supabase/tests/database
git commit -m "test(supabase): auth.users in the local runner and the users each test acts as"
```

---

### Task 2: `public.profiles`, the trigger and the backfill

**Files:**
- Create: `supabase/migrations/20261010000000_accounts.sql`
- Create: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Consumes: `auth.users` (Task 1).
- Produces: `public.profiles(id, role, role_changed_by, role_changed_at, last_active_at, created_at, updated_at)`; `private.handle_new_user()`; trigger `on_auth_user_created`; `private.backfill_profiles() returns void`.

- [ ] **Step 1: Write the failing test.** Create `supabase/tests/database/12_account.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

-- Auth spec 2026-09-30 §2 (20261010000000_accounts.sql).
create function public.t_user(p_id uuid, p_email text, p_anonymous boolean) returns uuid
  language sql as $$
  insert into auth.users (id, email, is_anonymous) values (p_id, p_email, p_anonymous) returning id $$;

select has_table('public', 'profiles', 'profiles exists');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'RLS is on for profiles');
select is((select count(*)::int from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'profiles'
    and grantee in ('anon', 'authenticated', 'PUBLIC')), 0, 'no client privilege on profiles');

select public.t_user('12000000-0000-0000-0000-000000000001', 'p@example.com', false);
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000001'),
  'user', 'a new permanent user gets a profile with the user role');
select public.t_user('12000000-0000-0000-0000-000000000002', null, true);
select ok(exists (select 1 from public.profiles where id = '12000000-0000-0000-0000-000000000002'),
  'a new anonymous user gets a profile');

-- The backfill: a user without a profile gets one, with the admin role from app_metadata.
update auth.users set raw_app_meta_data = '{"role": "admin"}'
  where id = '12000000-0000-0000-0000-000000000001';
delete from public.profiles where id = '12000000-0000-0000-0000-000000000001';
select private.backfill_profiles();
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000001'),
  'admin', 'the backfill recreates a missing profile and copies the admin role');
select lives_ok($$ select private.backfill_profiles() $$, 'the backfill runs twice without error');
update public.profiles set role = 'user' where id = '12000000-0000-0000-0000-000000000001';

select * from finish();
rollback;
```

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `FAIL 12_account.sql` or `ERROR 12_account.sql` (profiles does not exist).

- [ ] **Step 3: Write the migration's first section.** Create `supabase/migrations/20261010000000_accounts.sql`:

```sql
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
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (7)`; `01`–`11` still `ok`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): profiles with a role, created for every auth user"
```

---

### Task 3: `private.is_admin()` reads `profiles`

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`, `09_app_log.sql`, `10_log_admin_reads.sql`, `11_log_query_device.sql`

**Interfaces:**
- Consumes: `public.profiles` (Task 2).
- Produces: `private.is_admin()` true iff `profiles.role = 'admin'` for `auth.uid()`; the JWT claim no longer counts.

- [ ] **Step 1: Write the failing tests.** In `12_account.sql` change `select plan(7);` to `select plan(10);` and add before `select * from finish();`:

```sql
-- is_admin reads profiles, not the JWT (spec §2.3).
select public.t_user('12000000-0000-0000-0000-000000000003', 'a@example.com', false);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000003';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000002',
  'role', 'authenticated', 'app_metadata', jsonb_build_object('role', 'admin'))::text, true);
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'an admin claim in the JWT alone is not an admin');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000003',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.log_query('{}'::jsonb) $$, 'a profile with the admin role is an admin');
reset role;
update public.profiles set role = 'user' where id = '12000000-0000-0000-0000-000000000003';
set local role authenticated;
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a role change counts at once, without a new token');
reset role;
```

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `FAIL 12_account.sql` (the first new test passes the JWT admin through the old `is_admin`).

- [ ] **Step 3: Append to the migration.**

```sql
-- The admin role lives in profiles (spec O8); the log RPCs keep calling this.
create or replace function private.is_admin() returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
$$;
revoke all on function private.is_admin() from public, anon, authenticated;
```

- [ ] **Step 4: Move the admin fixtures of 09–11 to `profiles`.** In `09_app_log.sql`, `10_log_admin_reads.sql` and `11_log_query_device.sql`, after the `insert into auth.users …` line of Task 1, add:

```sql
update public.profiles set role = 'admin' where id = 'bbbbbbbb-0000-0000-0000-00000000000a';
```

(Their `t_as(sub, true)` helper still sets the claim; it no longer matters, and the profile now carries the role.)

- [ ] **Step 5: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (10)`; `09 (33)`, `10 (28)`, `11 (9)` still `ok`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database
git commit -m "feat(supabase): the admin check reads profiles.role"
```

---

### Task 4: Owned rows reference `auth.users`

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Consumes: existing tables of `20260928`…`20261003`.
- Produces: `user_id → auth.users(id) on delete cascade` on `deck`, `card`, `tags`, `delete_batch`, `review_log`, `card_schedule`, `account_settings`, `user_sync_version`, `sync_applied_op`, `app_log`; `card_tags` keys `on delete cascade`; test helper `public.t_seed(p_user uuid, p_tag text, p_settings boolean)` used by Tasks 7–8.

- [ ] **Step 1: Write the failing tests.** In `12_account.sql` change the plan to `select plan(14);`, add this helper after `t_user`:

```sql
-- One user's whole library, written as postgres: root and child deck, a card tagged p_tag,
-- a review, a schedule, a trash batch, settings when asked, a log. Versions come from the
-- user's counter, as sync_push would take them.
create function public.t_seed(p_user uuid, p_tag text, p_settings boolean) returns void
  language plpgsql as $$
declare
  v_top bigint := private.allocate_versions(p_user, 8);
  v_base bigint := v_top - 8;
  v_root uuid := md5(p_user::text || 'root')::uuid;
  v_child uuid := md5(p_user::text || 'child')::uuid;
  v_card uuid := md5(p_user::text || 'card')::uuid;
  v_tag uuid := md5(p_user::text || 'tag')::uuid;
  v_dev uuid := '00000000-0000-0000-0000-0000000000d1';
begin
  insert into public.deck (id, user_id, name, parent_id, root_id, depth, content_type, scheduler_type,
    scheduler_version, scheduler_config, study_config, generation, sibling_position, created_at,
    updated_at, server_version, last_device_id)
  values (v_root, p_user, 'Root', null, v_root, 1, 'deck', 'eight_box', 1, '{}', '{}', 1, 0, now(),
      now(), v_base + 1, v_dev),
    (v_child, p_user, 'Child', v_root, v_root, 2, 'card', null, null, null, null, null, 0, now(),
      now(), v_base + 2, v_dev);
  insert into public.card (id, user_id, deck_id, front, back, is_flagged, created_at, updated_at,
    server_version, last_device_id)
  values (v_card, p_user, v_child, 'front', 'back', false, now(), now(), v_base + 3, v_dev);
  insert into public.tags (id, user_id, name, name_folded, created_at, server_version, last_device_id)
  values (v_tag, p_user, p_tag, lower(p_tag), now(), v_base + 4, v_dev);
  insert into public.card_tags (card_id, tag_id) values (v_card, v_tag);
  insert into public.review_log (id, user_id, card_id, session_id, scheduler_type, generation, kind,
    mode, action, answered_at, server_version, last_device_id)
  values (md5(p_user::text || 'review')::uuid, p_user, v_card, 's1', 'eight_box', 1, 'learning',
    'browse', 'remembered', now(), v_base + 5, v_dev);
  insert into public.card_schedule (card_id, user_id, scheduler_type, scheduler_version, generation,
    answer_count, lapse_count, current_box, server_version, last_device_id)
  values (v_card, p_user, 'eight_box', 1, 1, 1, 0, 1, v_base + 6, v_dev);
  insert into public.delete_batch (id, user_id, item_type, root_item_id, deleted_at, server_version,
    last_device_id)
  values (md5(p_user::text || 'batch')::uuid, p_user, 'deck', v_root, now(), v_base + 7, v_dev);
  if p_settings then
    insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language,
      updated_at, server_version, last_device_id)
    values (p_user, 20, 'created', 'dark', 'en', now(), v_base + 8, v_dev);
  end if;
  insert into public.app_log (id, occurred_at, level, category, event, user_id)
  values (md5(p_user::text || 'log')::uuid, now(), 'info', 'sync', 't12.seed', p_user);
end
$$;

-- Rows a user owns, across every owned table.
create function public.t_owned(p_user uuid) returns int language sql as $$
  select ((select count(*) from public.deck where user_id = p_user)
    + (select count(*) from public.card where user_id = p_user)
    + (select count(*) from public.tags where user_id = p_user)
    + (select count(*) from public.review_log where user_id = p_user)
    + (select count(*) from public.card_schedule where user_id = p_user)
    + (select count(*) from public.delete_batch where user_id = p_user)
    + (select count(*) from public.account_settings where user_id = p_user)
    + (select count(*) from public.user_sync_version where user_id = p_user)
    + (select count(*) from public.app_log where user_id = p_user))::int $$;
```

and before `select * from finish();`:

```sql
-- Deleting a user removes everything it owns, in one statement (spec §2.2).
select public.t_user('12000000-0000-0000-0000-000000000004', 'd@example.com', false);
select public.t_user('12000000-0000-0000-0000-000000000005', 'o@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000004', 'Verb', true);
select public.t_seed('12000000-0000-0000-0000-000000000005', 'Noun', true);
select lives_ok($$ delete from auth.users where id = '12000000-0000-0000-0000-000000000004' $$,
  'a user who owns a whole library can be deleted');
select is(public.t_owned('12000000-0000-0000-0000-000000000004'), 0, 'nothing of it is left');
select is(public.t_owned('12000000-0000-0000-0000-000000000005'), 10, 'another user keeps all of theirs');

-- An access token outlives its user; the keys stop it from writing (spec §10).
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000004',
  'role', 'authenticated')::text, true);
do $$
begin
  perform public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(jsonb_build_object('opId', gen_random_uuid(), 'entityType', 'deck',
      'entityId', '12000000-0000-0000-0000-0000000000f1', 'op', 'upsert', 'row', jsonb_build_object(
        'id', '12000000-0000-0000-0000-0000000000f1', 'name', 'Back', 'parentId', null,
        'rootId', '12000000-0000-0000-0000-0000000000f1', 'depth', 1, 'contentType', 'deck',
        'schedulerType', 'eight_box', 'schedulerVersion', 1, 'schedulerConfig', '{}',
        'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null, 'sourceTemplateId', null,
        'sourceTemplateVersion', null, 'deleteBatchId', null, 'siblingPosition', 0,
        'createdAt', '2026-09-30T00:00:00.000Z', 'updatedAt', '2026-09-30T00:00:00.000Z')))));
exception when others then null;
end
$$;
reset role;
select is(public.t_owned('12000000-0000-0000-0000-000000000004'), 0,
  'deleted user cannot recreate persisted data through sync_push');
```

(`t_owned` of the other user: 2 decks + 1 card + 1 tag + 1 review + 1 schedule + 1 batch + 1 settings + 1 counter + 1 log = 10.)

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `FAIL 12_account.sql`: the deleted user's rows remain (`t_owned` = 10, not 0).

- [ ] **Step 3: Append to the migration.**

```sql
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
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (14)`; every other file `ok`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): owned rows reference auth.users and go with their user"
```

---

### Task 5: `me()`, activity and the profile guard

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Produces: `private.require_current_profile() returns uuid` (raises `NOT_AUTHENTICATED` without a caller, `UNAUTHORIZED` without a profile); `private.touch_user_activity(p_user uuid) returns void`; `public.me() returns jsonb` = `{"id", "email", "isAnonymous", "role"}`.

- [ ] **Step 1: Write the failing tests.** Plan → `select plan(21);`; add:

```sql
-- me() (spec §2.3).
select ok(has_function_privilege('authenticated', 'public.me()', 'execute'), 'a user can call me');
select ok(not has_function_privilege('anon', 'public.me()', 'execute'), 'anon cannot call me');
update public.profiles set last_active_at = now() - interval '3 days'
  where id = '12000000-0000-0000-0000-000000000002';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000002',
  'role', 'authenticated')::text, true);
select is(public.me(), jsonb_build_object('id', '12000000-0000-0000-0000-000000000002', 'email', null,
  'isAnonymous', true, 'role', 'user'), 'me() describes an anonymous user');
reset role;
select ok((select last_active_at > now() - interval '1 minute' from public.profiles
  where id = '12000000-0000-0000-0000-000000000002'), 'me() marks a user active after a day away');
update public.profiles set last_active_at = now() - interval '1 hour'
  where id = '12000000-0000-0000-0000-000000000005';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000005',
  'role', 'authenticated')::text, true);
select is(public.me()->>'email', 'o@example.com', 'me() gives the email of an account');
reset role;
select ok((select last_active_at < now() - interval '50 minutes' from public.profiles
  where id = '12000000-0000-0000-0000-000000000005'), 'activity is written at most once a day');
delete from public.profiles where id = '12000000-0000-0000-0000-000000000005';
set local role authenticated;
select throws_ok($$ select public.me() $$, 'P0001', 'UNAUTHORIZED', 'a caller without a profile is refused');
reset role;
```

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ERROR 12_account.sql` (`public.me()` does not exist).

- [ ] **Step 3: Append to the migration.**

```sql
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
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (21)`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): me() returns the caller's account and marks it active"
```

---

### Task 6: Roles — `role_list` and `role_set`

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Consumes: `private.is_admin()` (Task 3), `private.wire_time(timestamptz)` (20260928).
- Produces: `public.role_list(p_query text, p_after text) returns jsonb` = `{"items": [{"id","email","role","createdAt","lastSignInAt"}], "next": text|null}`; `public.role_set(p_user uuid, p_role text) returns jsonb` = `{"id","role"}`.

- [ ] **Step 1: Write the failing tests.** Plan → `select plan(33);`; add:

```sql
-- Roles (spec §2.3, O9).
select public.t_user('12000000-0000-0000-0000-000000000006', 'admin1@example.com', false);
select public.t_user('12000000-0000-0000-0000-000000000007', 'admin2@example.com', false);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000006';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000001',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.role_list(null, null) $$, 'P0001', 'FORBIDDEN', 'a user cannot list roles');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'admin') $$, 'P0001',
  'FORBIDDEN', 'a user cannot grant a role');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000006',
  'role', 'authenticated')::text, true);
select is(public.role_list('admin', null)->'items'->0->>'email', 'admin1@example.com',
  'an admin finds users by email');
select ok(not (public.role_list('', null)->'items' @> jsonb_build_array(jsonb_build_object(
  'id', '12000000-0000-0000-0000-000000000002'))), 'anonymous users are not listed');
select is(public.role_set('12000000-0000-0000-0000-000000000007', 'admin')->>'role', 'admin',
  'an admin grants the admin role');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000002', 'admin') $$, 'P0001',
  'ANONYMOUS_USER', 'an anonymous user cannot be an admin');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-0000000000ff', 'admin') $$, 'P0001',
  'NOT_FOUND', 'an unknown user is not found');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'owner') $$, 'P0001',
  'INVALID_ROLE', 'only user and admin exist');
-- Two admins: one may demote the other; the last one may not demote itself.
select is(public.role_set('12000000-0000-0000-0000-000000000006', 'user')->>'role', 'user',
  'with two admins, one may be demoted');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000007',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'user') $$, 'P0001',
  'LAST_ADMIN', 'the last admin cannot be demoted');
reset role;
select is((select role_changed_by from public.profiles where id = '12000000-0000-0000-0000-000000000006'),
  '12000000-0000-0000-0000-000000000006'::uuid, 'who changed a role is recorded');
delete from auth.users where id = '12000000-0000-0000-0000-000000000006';
select is((select role_changed_by from public.profiles where id = '12000000-0000-0000-0000-000000000007'),
  null, 'deleting the admin who granted a role clears the record, not the profile');
```

Note on the last test: admin …06 granted …07 (role_changed_by = …06), then …06 demoted itself (role_changed_by of …06 = …06); deleting …06 sets …07's `role_changed_by` to null and keeps …07. At this point the only admins are …06 and …07 (Task 2 resets …01 to `user`; Task 3 leaves …03 a `user`).

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ERROR 12_account.sql` (`public.role_list` does not exist).

- [ ] **Step 3: Append to the migration.**

```sql
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
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (33)`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): admins list users and grant roles, never leaving no admin"
```

---

### Task 7: Claim, merge and acknowledge

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Consumes: `private.require_current_profile()` (Task 5), `private.allocate_versions(uuid, integer)` (20260928), `public.t_seed`, `public.t_owned` (Task 4 test helpers).
- Produces: `public.account_claim`, `public.account_merge_receipt`; `private.token_hash(uuid) returns text`; `private.merge_user_data(p_source uuid, p_target uuid) returns void`; `public.account_claim_begin() returns uuid`; `public.account_merge(p_token uuid, p_operation_id uuid) returns jsonb` = `{"status": "MERGED"}`; `public.account_merge_ack(p_operation_id uuid) returns void`.

- [ ] **Step 1: Write the failing tests.** Plan → `select plan(61);`; add:

```sql
-- Claim, merge, acknowledge (spec §2.3, O4, O5).
-- S anonymous (source), T account (target), X another account. S and T both have a live tag
-- "verb"; S also has a tombstoned tag "noun" while T has a live "noun".
select public.t_user('12000000-0000-0000-0000-000000000011', null, true);                -- S
select public.t_user('12000000-0000-0000-0000-000000000012', 't@example.com', false);    -- T
select public.t_user('12000000-0000-0000-0000-000000000013', 'x@example.com', false);    -- X
select public.t_seed('12000000-0000-0000-0000-000000000011', 'Verb', true);
select public.t_seed('12000000-0000-0000-0000-000000000012', 'verb', true);
insert into public.tags (id, user_id, name, name_folded, created_at, server_version, last_device_id, deleted_at)
values ('12000000-0000-0000-0000-0000000000a1', '12000000-0000-0000-0000-000000000011', 'noun', 'noun',
  now(), private.allocate_versions('12000000-0000-0000-0000-000000000011', 1),
  '00000000-0000-0000-0000-0000000000d1', now()),
  ('12000000-0000-0000-0000-0000000000a2', '12000000-0000-0000-0000-000000000012', 'noun', 'noun',
  now(), private.allocate_versions('12000000-0000-0000-0000-000000000012', 1),
  '00000000-0000-0000-0000-0000000000d1', null);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000011';
update public.account_settings set theme_mode = 'light' where user_id = '12000000-0000-0000-0000-000000000012';
select set_config('t.top', private.current_version('12000000-0000-0000-0000-000000000012')::text, true);

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_claim_begin() $$, 'P0001', 'NOT_ANONYMOUS',
  'an account cannot hand out a claim');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000011',
  'role', 'authenticated')::text, true);
select set_config('t.token', public.account_claim_begin()::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c1') $$, 'P0001', 'NOT_PERMANENT', 'an anonymous user cannot merge');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(gen_random_uuid(), '12000000-0000-0000-0000-0000000000c1') $$,
  'P0001', 'CLAIM_INVALID', 'a wrong token is refused');
select is(public.account_merge(current_setting('t.token')::uuid, '12000000-0000-0000-0000-0000000000c1'),
  '{"status": "MERGED"}'::jsonb, 'the account merges the anonymous data');
select is(public.account_merge(current_setting('t.token')::uuid, '12000000-0000-0000-0000-0000000000c1'),
  '{"status": "MERGED"}'::jsonb, 'a retry with the same operation says MERGED again');
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c2') $$, 'P0001', 'CLAIM_INVALID',
  'a used token with another operation is refused');
-- Moved: the batch, two decks, the tombstoned tag, the card, its schedule and its review (the
-- live "Verb" merged into the account's tag and the settings gave way to the account's).
select is(jsonb_array_length(public.sync_changes(current_setting('t.top')::bigint, 500)->'changes'), 7,
  'the moved rows reach the account''s other devices as new changes');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000013',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c1') $$, 'P0001', 'CLAIM_INVALID',
  'another user learns nothing from the operation id');
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'another user''s acknowledgement is a no-op');
reset role;

select ok(not exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000011'),
  'the anonymous user is gone');
select is(public.t_owned('12000000-0000-0000-0000-000000000011'), 0, 'it owns nothing any more');
select is((select count(*)::int from public.deck where user_id = '12000000-0000-0000-0000-000000000012'), 4,
  'the account has both libraries');
select is((select count(*)::int from public.tags where user_id = '12000000-0000-0000-0000-000000000012'
  and deleted_at is null and name_folded = 'verb'), 1, 'live tags with the same name become one');
select is((select tag_id from public.card_tags
  where card_id = md5('12000000-0000-0000-0000-000000000011' || 'card')::uuid),
  md5('12000000-0000-0000-0000-000000000012' || 'tag')::uuid, 'the moved card points at the account''s tag');
select ok(exists (select 1 from public.tags where id = '12000000-0000-0000-0000-0000000000a1'
  and user_id = '12000000-0000-0000-0000-000000000012' and deleted_at is not null),
  'a tombstoned tag moves as it is, beside a live one of the same name');
select is((select theme_mode from public.account_settings
  where user_id = '12000000-0000-0000-0000-000000000012'), 'light', 'the account keeps its own settings');
select ok((select min(server_version) from public.card where id = md5('12000000-0000-0000-0000-000000000011' || 'card')::uuid)
  > current_setting('t.top')::bigint, 'moved rows get versions above the account''s last one');
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000012'), 'user',
  'the anonymous user''s role is not carried over');
select ok(exists (select 1 from public.account_merge_receipt where operation_id = '12000000-0000-0000-0000-0000000000c1'
  and acknowledged_at is null), 'a receipt records the merge, not yet acknowledged');
select is((select count(*)::int from public.app_log where user_id = '12000000-0000-0000-0000-000000000012'), 2,
  'the logs moved with the data');
select is((select count(*)::int from pg_class c where c.oid in ('public.account_claim'::regclass,
  'public.account_merge_receipt'::regclass) and c.relrowsecurity), 2, 'RLS is on for claims and receipts');

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'the account acknowledges its merge');
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'acknowledging twice is fine');
reset role;
select ok((select acknowledged_at is not null from public.account_merge_receipt
  where operation_id = '12000000-0000-0000-0000-0000000000c1'), 'the receipt is acknowledged');

-- A target without settings takes the source's; an expired claim is refused.
select public.t_user('12000000-0000-0000-0000-000000000014', null, true);
select public.t_user('12000000-0000-0000-0000-000000000015', 'u@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000014', 'solo', true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000014',
  'role', 'authenticated')::text, true);
select set_config('t.token2', public.account_claim_begin()::text, true);
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select is(public.account_merge(current_setting('t.token2')::uuid, '12000000-0000-0000-0000-0000000000c3')->>'status',
  'MERGED', 'a merge into an empty account');
reset role;
select is((select theme_mode from public.account_settings
  where user_id = '12000000-0000-0000-0000-000000000015'), 'dark', 'an account without settings takes the source''s');
select public.t_user('12000000-0000-0000-0000-000000000016', null, true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000016',
  'role', 'authenticated')::text, true);
select set_config('t.token3', public.account_claim_begin()::text, true);
reset role;
update public.account_claim set expires_at = now() - interval '1 second'
  where source_user_id = '12000000-0000-0000-0000-000000000016';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token3')::uuid,
  '12000000-0000-0000-0000-0000000000c4') $$, 'P0001', 'CLAIM_INVALID', 'an expired claim is refused');
reset role;
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000016'),
  'a refused merge leaves the anonymous user in place');
```

(28 new assertions: 33 + 28 = 61.)

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ERROR 12_account.sql` (`public.account_claim_begin` does not exist).

- [ ] **Step 3: Append to the migration.**

```sql
-- A one-time claim handed out by an anonymous user (spec §2.2); the token itself is never stored.
create table public.account_claim (
  token_hash text primary key,
  source_user_id uuid not null unique references auth.users (id) on delete cascade,
  expires_at timestamptz not null
);
-- Proof that a merge ran, so a retry after a lost answer says MERGED; no key on the source,
-- which the merge deletes.
create table public.account_merge_receipt (
  operation_id uuid primary key,
  source_user_id uuid not null,
  target_user_id uuid not null references auth.users (id) on delete cascade,
  merged_at timestamptz not null default now(),
  acknowledged_at timestamptz null,
  expires_at timestamptz not null default now() + interval '7 days'
);
alter table public.account_claim enable row level security;
alter table public.account_merge_receipt enable row level security;
revoke all on table public.account_claim, public.account_merge_receipt from public, anon, authenticated;

create function private.token_hash(p_token uuid) returns text
language sql immutable set search_path = '' as $$
  select encode(pg_catalog.sha256(convert_to(p_token::text, 'UTF8')), 'hex')
$$;

create function public.account_claim_begin() returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
  v_token uuid := gen_random_uuid();
begin
  if not coalesce((select u.is_anonymous from auth.users u where u.id = v_user), false) then
    raise exception 'NOT_ANONYMOUS';
  end if;
  insert into public.account_claim (token_hash, source_user_id, expires_at)
  values (private.token_hash(v_token), v_user, now() + interval '15 minutes')
  on conflict (source_user_id) do update
    set token_hash = excluded.token_hash, expires_at = excluded.expires_at;
  return v_token;
end
$$;

-- Moves every row of p_source to p_target (spec §2.3). Moved rows get new versions from the
-- target's counter, parents first, so the target's other devices pull them.
create function private.merge_user_data(p_source uuid, p_target uuid) returns void
language plpgsql set search_path = '' as $$
declare
  v_total bigint;
  v_next bigint;
  v_rows bigint;
begin
  -- Live tags with a name the target already has: links move to the target's tag.
  update public.card_tags ct set tag_id = t.id
  from public.tags s join public.tags t
    on t.user_id = p_target and t.deleted_at is null and t.name_folded = s.name_folded
  where s.user_id = p_source and s.deleted_at is null and ct.tag_id = s.id;
  delete from public.tags s using public.tags t
  where s.user_id = p_source and s.deleted_at is null
    and t.user_id = p_target and t.deleted_at is null and t.name_folded = s.name_folded;

  -- The target's own settings win.
  if exists (select 1 from public.account_settings where user_id = p_target) then
    delete from public.account_settings where user_id = p_source;
  end if;

  select (select count(*) from public.delete_batch where user_id = p_source)
       + (select count(*) from public.deck where user_id = p_source)
       + (select count(*) from public.tags where user_id = p_source)
       + (select count(*) from public.card where user_id = p_source)
       + (select count(*) from public.card_schedule where user_id = p_source)
       + (select count(*) from public.review_log where user_id = p_source)
       + (select count(*) from public.account_settings where user_id = p_source)
  into v_total;
  if v_total > 0 then
    v_next := private.allocate_versions(p_target, v_total::integer) - v_total;

    update public.delete_batch x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.delete_batch where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.deck x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by depth, server_version) as n
          from public.deck where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.tags x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.tags where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.card x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.card where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.card_schedule x set user_id = p_target, server_version = v_next + s.n
    from (select card_id, row_number() over (order by server_version) as n
          from public.card_schedule where user_id = p_source) s
    where x.card_id = s.card_id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.review_log x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.review_log where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.account_settings set user_id = p_target, server_version = v_next + 1
    where user_id = p_source;
  end if;

  update public.app_log set user_id = p_target where user_id = p_source;
end
$$;

create function public.account_merge(p_token uuid, p_operation_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_target uuid := private.require_current_profile();
  v_source uuid;
begin
  if coalesce((select u.is_anonymous from auth.users u where u.id = v_target), true) then
    raise exception 'NOT_PERMANENT';
  end if;
  if p_operation_id is null then
    raise exception 'CLAIM_INVALID';
  end if;
  -- A retry after a lost answer.
  if exists (select 1 from public.account_merge_receipt r
             where r.operation_id = p_operation_id and r.target_user_id = v_target) then
    return jsonb_build_object('status', 'MERGED');
  end if;
  -- Consumed atomically: a concurrent call with the same token finds nothing.
  delete from public.account_claim c
  where c.token_hash = private.token_hash(p_token) and c.expires_at > now()
  returning c.source_user_id into v_source;
  if v_source is null then
    -- The concurrent call may have been this very operation; its receipt is committed now.
    if exists (select 1 from public.account_merge_receipt r
               where r.operation_id = p_operation_id and r.target_user_id = v_target) then
      return jsonb_build_object('status', 'MERGED');
    end if;
    raise exception 'CLAIM_INVALID';
  end if;
  if v_source = v_target then
    raise exception 'CLAIM_INVALID';
  end if;
  perform private.merge_user_data(v_source, v_target);
  insert into public.account_merge_receipt (operation_id, source_user_id, target_user_id)
  values (p_operation_id, v_source, v_target);
  delete from auth.users where id = v_source;
  return jsonb_build_object('status', 'MERGED');
end
$$;

create function public.account_merge_ack(p_operation_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
begin
  update public.account_merge_receipt
  set acknowledged_at = coalesce(acknowledged_at, now())
  where operation_id = p_operation_id and target_user_id = v_user;
end
$$;

revoke all on function public.account_claim_begin(), public.account_merge(uuid, uuid),
  public.account_merge_ack(uuid) from public, anon, authenticated;
grant execute on function public.account_claim_begin(), public.account_merge(uuid, uuid),
  public.account_merge_ack(uuid) to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (61)`; every other file `ok`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): an anonymous user's data merges into an account, idempotently"
```

---

### Task 8: Account deletion and the daily cleanup

**Files:**
- Modify: `supabase/migrations/20261010000000_accounts.sql` (append)
- Modify: `supabase/tests/database/12_account.sql`

**Interfaces:**
- Consumes: `private.lock_roles()` (Task 6), `private.require_current_profile()` (Task 5).
- Produces: `private.delete_user_data(p_user uuid) returns void`; `public.account_delete() returns void`; `private.cleanup_accounts() returns void`; cron job `account-cleanup`.

- [ ] **Step 1: Write the failing tests.** Plan → `select plan(71);` (10 new assertions); add:

```sql
-- Deletion (spec §2.3, O7).
select public.t_user('12000000-0000-0000-0000-000000000021', 'del@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000021', 'gone', true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000021',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.account_delete() $$, 'a user deletes their account');
select throws_ok($$ select public.me() $$, 'P0001', 'UNAUTHORIZED', 'the old token finds no account');
select throws_ok($$ select public.account_delete() $$, 'P0001', 'UNAUTHORIZED',
  'a retry after the deletion is told the account is gone');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000007',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_delete() $$, 'P0001', 'LAST_ADMIN',
  'the last admin cannot delete their account');
reset role;
select is(public.t_owned('12000000-0000-0000-0000-000000000021'), 0, 'the deleted account owns nothing');
select ok(has_function_privilege('authenticated', 'public.account_delete()', 'execute')
  and not has_function_privilege('anon', 'public.account_delete()', 'execute'),
  'only a signed-in user can delete an account');

-- Cleanup: anonymous users away 90 days go; others stay; spent receipts and claims go.
select public.t_user('12000000-0000-0000-0000-000000000022', null, true);
select public.t_user('12000000-0000-0000-0000-000000000023', null, true);
select public.t_user('12000000-0000-0000-0000-000000000024', 'old@example.com', false);
update public.profiles set last_active_at = now() - interval '91 days'
  where id in ('12000000-0000-0000-0000-000000000022', '12000000-0000-0000-0000-000000000024');
insert into public.account_merge_receipt (operation_id, source_user_id, target_user_id, expires_at)
values ('12000000-0000-0000-0000-0000000000e1', gen_random_uuid(), '12000000-0000-0000-0000-000000000024',
  now() - interval '1 second'),
  ('12000000-0000-0000-0000-0000000000e2', gen_random_uuid(), '12000000-0000-0000-0000-000000000024',
  now() + interval '7 days');
select private.cleanup_accounts();
select ok(not exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000022'),
  'an anonymous user away 90 days is deleted');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000023'),
  'an active anonymous user stays');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000024'),
  'an account is never cleaned up');
select is((select array_agg(operation_id::text order by operation_id) from public.account_merge_receipt
  where target_user_id = '12000000-0000-0000-0000-000000000024'),
  array['12000000-0000-0000-0000-0000000000e2'], 'expired or acknowledged receipts go, a fresh one stays');
```

- [ ] **Step 2: Run it to verify it fails.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ERROR 12_account.sql` (`public.account_delete` does not exist).

- [ ] **Step 3: Append to the migration.**

```sql
-- Everything a user owns goes with the auth row (the keys of section 4 cascade). Later,
-- Storage objects the user owns would have to be removed first.
create function private.delete_user_data(p_user uuid) returns void
language sql set search_path = '' as $$
  delete from auth.users where id = p_user
$$;

create function public.account_delete() returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
begin
  perform private.lock_roles();
  if (select role from public.profiles where id = v_user) = 'admin'
     and (select count(*) from public.profiles where role = 'admin') <= 1 then
    raise exception 'LAST_ADMIN';
  end if;
  perform private.delete_user_data(v_user);
end
$$;
revoke all on function public.account_delete() from public, anon, authenticated;
grant execute on function public.account_delete() to authenticated;

-- Daily (spec O7): abandoned anonymous users and spent merge records.
create function private.cleanup_accounts() returns void
language plpgsql set search_path = '' as $$
declare
  v_user uuid;
begin
  for v_user in
    select u.id from auth.users u join public.profiles p on p.id = u.id
    where u.is_anonymous and p.last_active_at < now() - interval '90 days'
  loop
    perform private.delete_user_data(v_user);
  end loop;
  delete from public.account_merge_receipt where acknowledged_at is not null or expires_at < now();
  delete from public.account_claim where expires_at < now();
end
$$;
revoke all on all functions in schema private from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    perform cron.schedule('account-cleanup', '17 4 * * *', 'select private.cleanup_accounts()');
  end if;
end
$$;
```

- [ ] **Step 4: Run the suite.**

Run: `PGTAP_PORT=54391 bash tools/supabase/local_pgtap.sh`
Expected: `ok 12_account.sql (71)`; `04_function_privileges.sql (7)` still `ok` (no private function open to clients).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261010000000_accounts.sql supabase/tests/database/12_account.sql
git commit -m "feat(supabase): account deletion and a daily cleanup of abandoned anonymous users"
```

---

### Task 9: Documents

**Files:**
- Modify: `CLAUDE.md` (Backend section, the RPC sentence)
- Modify: `supabase/README.md` (the RPC list and the owner's steps)
- Modify: `docs/shared/decisions/ADR-015-supabase-lam-backend.md` (identity row 4), `docs/shared/decisions/ADR-018-log-tap-trung-va-monitoring.md` (§7 admin source)
- Modify: `docs/wbs_supabase.md` (SB-A1, SB-A5 rows, update log)
- Modify: `docs/superpowers/specs/2026-09-30-auth-design.md` (status line)

- [ ] **Step 1: CLAUDE.md.** Replace the sentence "Clients call only `sync_push`, `sync_changes`, `ping` and the log RPCs (`log_push`; for an admin, `log_query`, `log_get` and `log_set_status`, ADR-018 (`…`))" with: "Clients call only `sync_push`, `sync_changes`, `ping`, the log RPCs (`log_push`; for an admin, `log_query`, `log_get` and `log_set_status`, ADR-018 (`docs/shared/decisions/ADR-018-log-tap-trung-va-monitoring.md`)) and the account RPCs (`me`, `account_claim_begin`, `account_merge`, `account_merge_ack`, `account_delete`; for an admin, `role_list` and `role_set`, auth spec (`docs/superpowers/specs/2026-09-30-auth-design.md`))".
- [ ] **Step 2: supabase/README.md.** Add the account RPCs to its RPC list, and to the owner's steps: "the first admin: `update public.profiles set role = 'admin' where id = '<your user id>';` in the SQL editor (the migration already copies an `app_metadata.role = admin`)".
- [ ] **Step 3: ADR-015 row 4 and ADR-018 §7.** ADR-015 row 4 (Danh tính): add "Login bằng email OTP và Google gắn vào cùng user (auth spec 2026-09-30); role nằm trong `public.profiles`". ADR-018 §7: replace "role admin lấy từ `app_metadata`" with "role admin lấy từ `public.profiles.role` (auth spec 2026-09-30, migration `20261010000000`); `app_metadata` không còn được đọc".
- [ ] **Step 4: WBS.** `docs/wbs_supabase.md`: SB-A1 → `xong`, evidence "Spec (`superpowers/specs/2026-09-30-auth-design.md`)"; SB-A5 → `đang làm`, note "Server (P1): `account_delete`, `private.cleanup_accounts` (cron `account-cleanup`), migration `20261010000000_accounts.sql`, pgTAP `12_account.sql`; app (P3) chờ"; one update-log line for 2026-09-30.
- [ ] **Step 5: Spec status.** First line of the spec: "Status: approved 2026-09-30; P1 (server) implemented by `docs/superpowers/plans/2026-09-30-accounts-server.md`".
- [ ] **Step 6: Check and commit.**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

```bash
git add CLAUDE.md supabase/README.md docs
git commit -m "docs: account RPCs, admin role in profiles, SB-A1 done"
```

---

## Self-review (done while writing)

- Spec §2.1 → Tasks 2 (default privileges, table rules), 5–8 (RPC rules). §2.2 profiles → 2; FKs and `card_tags` → 4; claim, receipt → 7. §2.3 `is_admin` → 3; `require_current_profile`, `touch`, `me` → 5; roles → 6; claim/merge/ack → 7; delete, cron → 8. §2.4 owner setup → not code (spec §11). §9 server row: every listed case has a test in 2–8 (concurrent demotion is serialized by `lock_roles`; pgTAP runs one session, so the test is the sequential two-admin case). §10 FK risk → Precondition 1.
- Names are consistent across tasks: `t_user`, `t_seed`, `t_owned`, `private.lock_roles`, `private.token_hash`, `private.merge_user_data`, `private.delete_user_data`, `private.cleanup_accounts`.
