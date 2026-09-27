# Supabase Backend for Deck Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move deck and trash-batch sync from the frozen Spring Boot server to a Supabase project, with the same wire format, an anonymous Supabase identity in the app, and pgTAP proof of the protocol rules.

**Architecture:** One SQL migration in `supabase/migrations/` holds the tables (RLS on, no client privileges) and PL/pgSQL functions: `public.sync_push`, `public.sync_changes` and `public.ping` are the only callable surface; helpers live in schema `private`. The app keeps its coordinator, outbox, triggers and adapters; a new `SupabaseSyncApi implements SyncApi` calls the RPCs through injected functions.

**Tech Stack:** Supabase CLI 2.118 (`npx supabase`), Postgres 17 (Supabase image), PL/pgSQL, pgTAP; Flutter with `supabase_flutter` 2.17.x, Riverpod 3, json_serializable.

**Spec:** [docs/superpowers/specs/2026-09-28-supabase-backend-design.md](../specs/2026-09-28-supabase-backend-design.md) · ADR: [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md)

## Global Constraints

- Wire format unchanged: `PushRequestModel`, `PushResponseModel`, `ChangesResponseModel` in `lib/core/sync/sync_models.dart`; row keys are the camelCase keys of `DeckSyncAdapter` and `DeleteBatchSyncAdapter`.
- Times on the wire: `to_char(t AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')`.
- Every function: `SET search_path = ''`, every name schema-qualified. `sync_push`/`sync_changes` are `SECURITY DEFINER`, `EXECUTE` only for `authenticated`; `ping` for `anon` and `authenticated`; nothing in `private` is executable by client roles.
- Every table: RLS enabled, no policy, `REVOKE ALL … FROM public, anon, authenticated`.
- Batch limit 100 operations; `max_rows` clamped to 1..500; deck depth ≤ 10.
- Business codes: `VALIDATION_FAILED`, `SYNC_ENTITY_CONFLICT`, `SYNC_ENTITY_UNSUPPORTED`, `DECK_PARENT_MISSING`, `DECK_TREE_CYCLE`, `DECK_TREE_TOO_DEEP`, `CONFLICT`, `NOT_AUTHENTICATED`.
- Sync runs only when both `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are defined; `API_BASE_URL` no longer enables it.
- Windows gate: `flutter test --exclude-tags golden`, never `--update-goldens`. Docker must be running for `npx supabase db start`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Code, comments and commit messages in English; `docs/` prose follows the file's language (Vietnamese in ADRs and WBS).

## Review Focus

1. A push whose operation raises an unexpected SQL error (not in the mapped list) fails the whole call — the reviewer checks no *expected* client input reaches that path (bad numbers, bad dates, wrong JSON types). Pinned by the validation block in Task 2 (`"abc"` as `siblingPosition`, `"2026-13-40"` as `createdAt`).
2. Moving a subtree whose height pushes it past depth 10 must be refused, not just an 11th leaf. Pinned in Task 2 (move C with child under D9).
3. A second user reusing a first user's id must never see or overwrite it, on upsert **and** delete. Pinned in Task 3.
4. Paging across mixed `deck`/`delete_batch` rows must neither skip nor repeat a change. Pinned in Task 3 (`sync_changes(0,1)` walk).
5. A reinstalled app (no session) must get a session before the first RPC; an offline sign-in failure must surface as an error so the scheduler backs off. Pinned in Task 4 (`ensureSession` ordering and error propagation tests).

---

### Task 1: Supabase scaffold and schema

**Files:**
- Create: `supabase/config.toml` (via `npx supabase init`), `supabase/.gitignore` (generated)
- Create: `supabase/migrations/20260928000000_deck_sync.sql`
- Test: `supabase/tests/database/01_schema_privileges.sql`

**Interfaces:**
- Produces: tables `public.user_sync_version`, `public.sync_applied_op`, `public.delete_batch`, `public.deck`; schema `private`.

- [ ] **Step 1: Init the Supabase project**

Run from the repo root: `npx supabase init` (answer "N" to IDE settings). Then in `supabase/config.toml` set under `[auth]`:

```toml
enable_anonymous_sign_ins = true
```

Leave `[api] schemas = ["public", "graphql_public"]` as generated (it must not list `private`).

- [ ] **Step 2: Write the failing schema test**

`supabase/tests/database/01_schema_privileges.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select has_table('public', 'deck', 'deck exists');
select has_table('public', 'delete_batch', 'delete_batch exists');
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relname in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')
     and c.relrowsecurity),
  4, 'RLS is on for every sync table');
select is(
  (select count(*)::int from pg_policies where schemaname = 'public'
     and tablename in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')),
  0, 'no policy opens a table to clients');
select is(
  (select count(*)::int from information_schema.role_table_grants
   where table_schema = 'public'
     and table_name in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')
     and grantee in ('anon', 'authenticated', 'PUBLIC')),
  0, 'client roles hold no table privilege');
select ok(not has_schema_privilege('authenticated', 'private', 'usage'),
  'clients cannot use the private schema');

select * from finish();
rollback;
```

- [ ] **Step 3: Run it to verify it fails**

Run: `npx supabase db start` then `npx supabase test db`
Expected: FAIL — `has_table` not ok / `schema "private" does not exist`.

- [ ] **Step 4: Write the schema migration**

`supabase/migrations/20260928000000_deck_sync.sql`:

```sql
-- ADR-015 / Supabase backend spec §3. Ported from memox-api-services Flyway V1–V4 (deck and delete_batch only).
-- Ids are client-generated UUIDs (ADR-007); times are UTC (ADR-008).

create schema private;
revoke all on schema private from public, anon, authenticated;

create table public.user_sync_version (
  user_id uuid primary key,
  version bigint not null
);

create table public.sync_applied_op (
  user_id uuid not null,
  op_id uuid not null,
  server_version bigint not null,
  applied_at timestamptz not null default now(),
  primary key (user_id, op_id)
);

-- A trash batch; tombstoned_at is the sync tombstone, deleted_at the batch's own time.
create table public.delete_batch (
  id uuid primary key,
  user_id uuid not null,
  item_type text not null check (item_type in ('card', 'deck')),
  root_item_id uuid not null,
  deleted_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  tombstoned_at timestamptz null
);
create unique index uq_delete_batch_user_version on public.delete_batch (user_id, server_version);

create table public.deck (
  id uuid primary key,
  user_id uuid not null,
  name text not null,
  parent_id uuid null references public.deck (id),
  root_id uuid not null,
  depth integer not null check (depth between 1 and 10),
  content_type text not null check (content_type in ('unset', 'card', 'deck')),
  scheduler_type text null check (scheduler_type in ('eight_box', 'sm2')),
  scheduler_version integer null,
  scheduler_config text null,
  study_config text null,
  generation integer null,
  first_answered_at timestamptz null,
  source_template_id text null,
  source_template_version integer null,
  delete_batch_id uuid null references public.delete_batch (id),
  sibling_position integer not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null,
  -- The app's deck CHECKs (deck.drift): a row the app would refuse must be refused here, or it jams every pull.
  constraint deck_root_shape check (
    (parent_id is null and content_type = 'deck' and scheduler_type is not null)
    or (parent_id is not null and scheduler_type is null)),
  constraint deck_root_generation check ((parent_id is null) = (generation is not null)),
  constraint deck_root_scheduler_version check ((parent_id is null) = (scheduler_version is not null)),
  constraint deck_child_configs check (parent_id is null or (scheduler_config is null and study_config is null))
);
-- One version per changed row (sync spec §4.2): a duplicate is a loud error, not a silently skipped change.
create unique index uq_deck_user_version on public.deck (user_id, server_version);
create index idx_deck_parent on public.deck (parent_id);

-- The only path to data is the functions below (spec §2): RLS on, no policy, no client privilege.
alter table public.user_sync_version enable row level security;
alter table public.sync_applied_op enable row level security;
alter table public.delete_batch enable row level security;
alter table public.deck enable row level security;
revoke all on table public.user_sync_version, public.sync_applied_op, public.delete_batch, public.deck
  from public, anon, authenticated;
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `npx supabase db reset` then `npx supabase test db`
Expected: `01_schema_privileges.sql .. ok`, `All tests successful.`

- [ ] **Step 6: Commit**

```bash
git add supabase/
git commit -m "feat(supabase): project scaffold and the deck sync schema, closed to clients (ADR-015)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `sync_push` for decks

**Files:**
- Modify: `supabase/migrations/20260928000000_deck_sync.sql` (append)
- Test: `supabase/tests/database/02_deck_push.sql`

**Interfaces:**
- Consumes: the Task 1 tables.
- Produces: `public.sync_push(request jsonb) returns jsonb`; `private.allocate_versions(uuid, integer) returns bigint`; `private.current_version(uuid) returns bigint`; `private.wire_time(timestamptz) returns text`; `private.try_uuid(text) returns uuid`; `private.deck_change(public.deck) returns jsonb`; `private.current_change(uuid, text, uuid) returns jsonb`; `private.apply_operation(uuid, uuid, text, text, uuid, jsonb) returns bigint` (Task 3 adds the `delete_batch` branches); `private.push_one(uuid, uuid, jsonb) returns jsonb`.

- [ ] **Step 1: Write the failing test**

`supabase/tests/database/02_deck_push.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

-- Test helpers, created inside the rolled-back transaction.
create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00.000Z', 'updatedAt', '2026-09-28T00:00:00.000Z') $$;
create function public.t_child(p_id uuid, p_parent uuid) returns jsonb language sql as $$
  select public.t_root(p_id) || jsonb_build_object('name', 'Child', 'parentId', p_parent,
    'rootId', public.t_uuid(999), 'depth', 7, 'contentType', 'card', 'schedulerType', null,
    'schedulerVersion', null, 'schedulerConfig', null, 'studyConfig', null, 'generation', null) $$;
create function public.t_op(p_op int, p_type text, p_id uuid, p_kind text, p_row jsonb) returns jsonb
  language sql as $$
  select jsonb_build_object('opId', public.t_uuid(100000 + p_op), 'entityType', p_type,
    'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_change(p_id uuid) returns jsonb language sql as $$
  select c from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityId' = p_id::text $$;

-- User A.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- R (root) → C → G; R2 a second root.
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0,
  jsonb_build_object('opId', public.t_uuid(100001), 'status', 'applied', 'serverVersion', 1, 'code', null, 'current', null),
  'a new root is applied with version 1');
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0->>'serverVersion',
  '1', 'a resent opId is acknowledged with its first version');
select is(public.t_change(public.t_uuid(1))->>'serverVersion', '1', 'a resent opId is not applied again');
select is(public.t_push(jsonb_build_array(public.t_op(2, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1)))))->0->>'status',
  'applied', 'a child is applied');
select is(public.t_change(public.t_uuid(2))->'row'->>'rootId', public.t_uuid(1)::text, 'root_id is derived, not read from the row');
select is(public.t_change(public.t_uuid(2))->'row'->>'depth', '2', 'depth is derived, not read from the row');
select is(public.t_push(jsonb_build_array(public.t_op(3, 'deck', public.t_uuid(3), 'upsert', public.t_child(public.t_uuid(3), public.t_uuid(2)))))->0->>'status',
  'applied', 'a grandchild is applied');

-- Tree rules.
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(1), 'upsert', public.t_child(public.t_uuid(1), public.t_uuid(3)))))->0->>'code',
  'DECK_TREE_CYCLE', 'a deck cannot move under its own descendant');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(2)))))->0->>'code',
  'DECK_TREE_CYCLE', 'a deck cannot be its own parent');
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(1), 'upsert', public.t_child(public.t_uuid(1), public.t_uuid(3)))))->0->'current'->>'entityId',
  public.t_uuid(1)::text, 'a rejection carries the server copy');
select is(public.t_push(jsonb_build_array(public.t_op(6, 'deck', public.t_uuid(4), 'upsert', public.t_child(public.t_uuid(4), public.t_uuid(404)))))->0,
  jsonb_build_object('opId', public.t_uuid(100006), 'status', 'rejected', 'serverVersion', null, 'code', 'DECK_PARENT_MISSING', 'current', null),
  'a missing parent is rejected, with no server copy of a new deck');

-- A move rewrites the subtree, one version per row.
select is(public.t_push(jsonb_build_array(public.t_op(7, 'deck', public.t_uuid(10), 'upsert', public.t_root(public.t_uuid(10)))))->0->>'status',
  'applied', 'a second root is applied');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(10)))))->0->>'status',
  'applied', 'a subtree moves to another root');
select is(public.t_change(public.t_uuid(3))->'row'->>'rootId', public.t_uuid(10)::text, 'the moved subtree takes the new root');
select is(public.t_change(public.t_uuid(3))->'row'->>'depth', '3', 'the moved subtree keeps its relative depth');
select is((public.t_change(public.t_uuid(3))->>'serverVersion')::bigint,
  (public.t_change(public.t_uuid(2))->>'serverVersion')::bigint + 1, 'each moved row has its own version');

-- Depth: D1 … D10 fits, D11 does not; a subtree of height 1 under D9 does not.
select is(public.t_push((select jsonb_agg(public.t_op(200 + i, 'deck', public.t_uuid(20 + i), 'upsert',
    case when i = 1 then public.t_root(public.t_uuid(21)) else public.t_child(public.t_uuid(20 + i), public.t_uuid(19 + i)) end) order by i)
  from generate_series(1, 11) i))->10->>'code', 'DECK_TREE_TOO_DEEP', 'depth 11 is rejected');
select is(public.t_change(public.t_uuid(30))->'row'->>'depth', '10', 'depth 10 is applied');
select is(public.t_push(jsonb_build_array(public.t_op(9, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(29)))))->0->>'code',
  'DECK_TREE_TOO_DEEP', 'a subtree cannot move where its leaves pass depth 10');

-- Validation.
select is(public.t_push(jsonb_build_array(public.t_op(10, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"contentType":"card"}')))->0->>'code', 'VALIDATION_FAILED', 'a root must hold decks');
select is(public.t_push(jsonb_build_array(public.t_op(11, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"schedulerConfig":"not json"}')))->0->>'code', 'VALIDATION_FAILED', 'config must be JSON');
select is(public.t_push(jsonb_build_array(public.t_op(12, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(41)))))->0->>'code', 'VALIDATION_FAILED', 'row.id must match entityId');
select is(public.t_push(jsonb_build_array(public.t_op(13, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"siblingPosition":"abc"}')))->0->>'code', 'VALIDATION_FAILED', 'a bad number is a validation failure');
select is(public.t_push(jsonb_build_array(public.t_op(14, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"createdAt":"2026-13-40"}')))->0->>'code', 'VALIDATION_FAILED', 'a bad time is a validation failure');
select is(public.t_push(jsonb_build_array(public.t_op(15, 'deck', public.t_uuid(40), 'upsert', null)))->0->>'code',
  'VALIDATION_FAILED', 'an upsert needs a row');
select is(public.t_push(jsonb_build_array(public.t_op(16, 'card', public.t_uuid(40), 'upsert', '{}')))->0->>'code',
  'SYNC_ENTITY_UNSUPPORTED', 'an unknown entity type is rejected');
select is((select (r->0->>'status') || '/' || (r->1->>'code') || '/' || (public.t_change(public.t_uuid(50)) is not null)::text
  from public.t_push(jsonb_build_array(
    public.t_op(17, 'deck', public.t_uuid(50), 'upsert', public.t_root(public.t_uuid(50))),
    public.t_op(18, 'deck', public.t_uuid(51), 'upsert', public.t_root(public.t_uuid(52))))) r),
  'applied/VALIDATION_FAILED/true', 'a rejected operation does not undo the one before it');

-- Delete tombstones the live subtree, one version per row; resurrection clears it.
select is(public.t_push(jsonb_build_array(public.t_op(19, 'deck', public.t_uuid(10), 'delete', null)))->0->>'status',
  'applied', 'a subtree delete is applied');
select is(public.t_change(public.t_uuid(3)) - 'serverVersion',
  jsonb_build_object('entityType', 'deck', 'entityId', public.t_uuid(3), 'deleted', true, 'row', null),
  'a descendant is a tombstone with no row');
select is(public.t_push(jsonb_build_array(public.t_op(20, 'deck', public.t_uuid(10), 'upsert', public.t_root(public.t_uuid(10)))))->0->>'status',
  'applied', 'a tombstoned deck can be upserted again');
select is(public.t_change(public.t_uuid(10))->>'deleted', 'false', 'the upsert resurrects it');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx supabase test db`
Expected: FAIL — `function public.sync_push(jsonb) does not exist`.

- [ ] **Step 3: Append the functions to the migration**

Append to `supabase/migrations/20260928000000_deck_sync.sql`:

```sql
-- Supabase backend spec §4. Business codes are raised as the exception message (SQLSTATE P0001).

create function private.allocate_versions(p_user uuid, p_count integer) returns bigint
language sql set search_path = '' as $$
  insert into public.user_sync_version as v (user_id, version) values (p_user, p_count)
  on conflict (user_id) do update set version = v.version + excluded.version
  returning version
$$;

create function private.current_version(p_user uuid) returns bigint
language sql stable set search_path = '' as $$
  select coalesce((select version from public.user_sync_version where user_id = p_user), 0)
$$;

create function private.wire_time(p_time timestamptz) returns text
language sql immutable set search_path = '' as $$
  select to_char(p_time at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
$$;

create function private.try_uuid(p_text text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return p_text::uuid;
exception when invalid_text_representation then
  return null;
end
$$;

create function private.deck_change(d public.deck) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'deck', 'entityId', d.id, 'serverVersion', d.server_version,
    'deleted', d.deleted_at is not null,
    'row', case when d.deleted_at is not null then null else jsonb_build_object(
      'id', d.id, 'name', d.name, 'parentId', d.parent_id, 'rootId', d.root_id, 'depth', d.depth,
      'contentType', d.content_type, 'schedulerType', d.scheduler_type,
      'schedulerVersion', d.scheduler_version, 'schedulerConfig', d.scheduler_config,
      'studyConfig', d.study_config, 'generation', d.generation,
      'firstAnsweredAt', private.wire_time(d.first_answered_at),
      'sourceTemplateId', d.source_template_id, 'sourceTemplateVersion', d.source_template_version,
      'deleteBatchId', d.delete_batch_id, 'siblingPosition', d.sibling_position,
      'createdAt', private.wire_time(d.created_at), 'updatedAt', private.wire_time(d.updated_at)) end)
$$;

-- The server copy of an entity for this user, or null when the server has never seen it (spec §4.1).
create function private.current_change(p_user uuid, p_type text, p_id uuid) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_deck public.deck;
begin
  if p_type = 'deck' then
    select * into v_deck from public.deck where id = p_id and user_id = p_user;
    if found then
      return private.deck_change(v_deck);
    end if;
  end if;
  return null;
end
$$;

-- The live subtree of a deck: its id and each row's distance from it. Empty when the deck is unknown or tombstoned.
create function private.live_subtree(p_user uuid, p_id uuid) returns table (id uuid, rel integer)
language sql stable set search_path = '' as $$
  with recursive sub (id, rel) as (
    select d.id, 0 from public.deck d where d.id = p_id and d.user_id = p_user and d.deleted_at is null
    union all
    select c.id, s.rel + 1 from public.deck c join sub s on c.parent_id = s.id
    where c.user_id = p_user and c.deleted_at is null
  )
  select id, rel from sub
$$;

create function private.deck_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_parent_id uuid := (r->>'parentId')::uuid;
  v_existing public.deck;
  v_exists boolean;
  v_parent public.deck;
  v_root uuid;
  v_depth integer;
  v_height integer;
  v_subtree_ids uuid[];
  v_descendants integer := 0;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- A root holds decks and owns the scheduler; a child has neither (schema.md: deck).
  if v_parent_id is null then
    if r->>'contentType' is distinct from 'deck' or r->>'schedulerType' is null
        or r->>'schedulerVersion' is null or r->>'generation' is null then
      raise exception 'VALIDATION_FAILED';
    end if;
  elsif r->>'schedulerType' is not null or r->>'schedulerVersion' is not null or r->>'generation' is not null
      or r->>'schedulerConfig' is not null or r->>'studyConfig' is not null then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- Config columns hold JSON that other devices parse; a non-JSON value fails the cast (22P02).
  perform (r->>'schedulerConfig')::jsonb, (r->>'studyConfig')::jsonb;

  select * into v_existing from public.deck where id = p_id for update;
  v_exists := found;
  if v_exists and v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;

  select coalesce(array_agg(s.id), '{}'), coalesce(max(s.rel), 0) into v_subtree_ids, v_height
  from private.live_subtree(p_user, p_id) s;

  if v_parent_id is null then
    v_root := p_id;
    v_depth := 1;
  else
    select * into v_parent from public.deck where id = v_parent_id;
    if not found or v_parent.user_id <> p_user or v_parent.deleted_at is not null then
      raise exception 'DECK_PARENT_MISSING';
    end if;
    if v_parent_id = p_id or v_parent_id = any (v_subtree_ids) then
      raise exception 'DECK_TREE_CYCLE';
    end if;
    v_root := v_parent.root_id;
    v_depth := v_parent.depth + 1;
  end if;
  if v_depth + v_height > 10 then
    raise exception 'DECK_TREE_TOO_DEEP';
  end if;

  -- A tombstoned deck has no live subtree, so resurrecting it moves no descendant.
  if v_exists and (v_existing.root_id <> v_root or v_existing.depth <> v_depth) then
    v_descendants := greatest(0, cardinality(v_subtree_ids) - 1);
  end if;
  v_version := private.allocate_versions(p_user, 1 + v_descendants) - v_descendants;

  insert into public.deck (id, user_id, name, parent_id, root_id, depth, content_type, scheduler_type,
    scheduler_version, scheduler_config, study_config, generation, first_answered_at, source_template_id,
    source_template_version, delete_batch_id, sibling_position, created_at, updated_at, server_version,
    last_device_id, deleted_at)
  values (p_id, p_user, r->>'name', v_parent_id, v_root, v_depth, r->>'contentType', r->>'schedulerType',
    (r->>'schedulerVersion')::integer, r->>'schedulerConfig', r->>'studyConfig', (r->>'generation')::integer,
    (r->>'firstAnsweredAt')::timestamptz, r->>'sourceTemplateId', (r->>'sourceTemplateVersion')::integer,
    (r->>'deleteBatchId')::uuid, (r->>'siblingPosition')::integer, (r->>'createdAt')::timestamptz,
    (r->>'updatedAt')::timestamptz, v_version, p_device, null)
  on conflict (id) do update set
    name = excluded.name, parent_id = excluded.parent_id, root_id = excluded.root_id, depth = excluded.depth,
    content_type = excluded.content_type, scheduler_type = excluded.scheduler_type,
    scheduler_version = excluded.scheduler_version, scheduler_config = excluded.scheduler_config,
    study_config = excluded.study_config, generation = excluded.generation,
    first_answered_at = excluded.first_answered_at, source_template_id = excluded.source_template_id,
    source_template_version = excluded.source_template_version, delete_batch_id = excluded.delete_batch_id,
    sibling_position = excluded.sibling_position, created_at = excluded.created_at,
    updated_at = excluded.updated_at, server_version = excluded.server_version,
    last_device_id = excluded.last_device_id, deleted_at = null;

  if v_descendants > 0 then
    update public.deck d
    set root_id = v_root, depth = v_depth + s.rel, server_version = v_version + s.n, last_device_id = p_device
    from (select t.id, t.rel, row_number() over (order by t.rel, t.id) as n
          from private.live_subtree(p_user, p_id) t where t.rel > 0) s
    where d.id = s.id;
  end if;
  return v_version;
end
$$;

create function private.deck_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.deck;
  v_rows integer;
  v_first bigint;
begin
  select * into v_existing from public.deck where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  select count(*) into v_rows from private.live_subtree(p_user, p_id);
  v_first := private.allocate_versions(p_user, v_rows) - v_rows + 1;
  update public.deck d
  set deleted_at = now(), server_version = v_first + s.n - 1, last_device_id = p_device
  from (select t.id, row_number() over (order by t.rel, t.id) as n from private.live_subtree(p_user, p_id) t) s
  where d.id = s.id;
  return v_first;
end
$$;

create function private.apply_operation(
  p_user uuid, p_device uuid, p_type text, p_kind text, p_id uuid, p_row jsonb) returns bigint
language plpgsql set search_path = '' as $$
begin
  if p_kind = 'upsert' then
    if p_row is null or jsonb_typeof(p_row) <> 'object' then
      raise exception 'VALIDATION_FAILED';
    end if;
    if p_type = 'deck' then
      return private.deck_upsert(p_user, p_device, p_id, p_row);
    end if;
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

create function private.push_one(p_user uuid, p_device uuid, p_op jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_op_id uuid := (p_op->>'opId')::uuid;
  v_type text := p_op->>'entityType';
  v_version bigint;
  v_code text;
begin
  select server_version into v_version from public.sync_applied_op where user_id = p_user and op_id = v_op_id;
  if found then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  end if;
  if v_type is null or v_type not in ('deck', 'delete_batch') then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null,
      'code', 'SYNC_ENTITY_UNSUPPORTED', 'current', null);
  end if;
  -- A subtransaction: a rejection rolls back only this operation (spec §4.1).
  begin
    v_version := private.apply_operation(p_user, p_device, v_type, p_op->>'op', (p_op->>'entityId')::uuid, p_op->'row');
    insert into public.sync_applied_op (user_id, op_id, server_version) values (p_user, v_op_id, v_version);
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  exception
    when raise_exception then
      v_code := sqlerrm;
    when check_violation or not_null_violation or foreign_key_violation or invalid_text_representation
        or invalid_datetime_format or datetime_field_overflow or numeric_value_out_of_range then
      v_code := 'VALIDATION_FAILED';
    when unique_violation then
      v_code := 'CONFLICT';
  end;
  return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null, 'code', v_code,
    'current', private.current_change(p_user, v_type, private.try_uuid(p_op->>'entityId')));
end
$$;

create function public.sync_push(request jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_device uuid := private.try_uuid(request->>'deviceId');
  v_ops jsonb := request->'operations';
  v_op jsonb;
  v_results jsonb := '[]';
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if v_device is null or jsonb_typeof(v_ops) is distinct from 'array' or jsonb_array_length(v_ops) > 100 then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- One user's pushes are serialized for the whole call (sync spec §4.1).
  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  for v_op in select value from jsonb_array_elements(v_ops) loop
    v_results := v_results || jsonb_build_array(private.push_one(v_user, v_device, v_op));
  end loop;
  return jsonb_build_object('results', v_results);
end
$$;
```

Also add a temporary `public.sync_changes` so the test's `t_change` helper works — **no**: Task 2's test uses `sync_changes`, so write the real one now (Task 3 extends it for `delete_batch`). Append:

```sql
create function public.sync_changes(since bigint, max_rows integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_since bigint := coalesce(since, 0);
  v_limit integer := least(greatest(coalesce(max_rows, 500), 1), 500);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  with page as (
    select u.entity_type, u.id, u.server_version, row_number() over (order by u.server_version) as n
    from (
      select 'deck' as entity_type, d.id, d.server_version from public.deck d
      where d.user_id = v_user and d.server_version > v_since
      order by d.server_version limit v_limit + 1
    ) u
    order by u.server_version limit v_limit + 1
  )
  select coalesce(jsonb_agg(private.current_change(v_user, p.entity_type, p.id) order by p.server_version)
           filter (where p.n <= v_limit), '[]'),
         max(p.server_version) filter (where p.n <= v_limit),
         count(*) > v_limit
  into v_changes, v_next, v_more
  from page p;
  return jsonb_build_object('changes', v_changes, 'nextSince', coalesce(v_next, v_since), 'hasMore', v_more);
end
$$;

-- Clients reach data only through these functions (spec §2).
revoke all on all functions in schema private from public, anon, authenticated;
revoke all on function public.sync_push(jsonb), public.sync_changes(bigint, integer) from public, anon, authenticated;
grant execute on function public.sync_push(jsonb), public.sync_changes(bigint, integer) to authenticated;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `npx supabase db reset` then `npx supabase test db`
Expected: `01_… ok`, `02_deck_push.sql .. ok`, `All tests successful.`

- [ ] **Step 5: Commit**

```bash
git add supabase/
git commit -m "feat(supabase): sync_push and sync_changes for decks, with the tree rules (ADR-015)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Trash batches, isolation, paging, wire, `ping`

**Files:**
- Modify: `supabase/migrations/20260928000000_deck_sync.sql`
- Test: `supabase/tests/database/03_batches_and_changes.sql`, `supabase/tests/database/04_function_privileges.sql`

**Interfaces:**
- Consumes: Task 2's functions.
- Produces: `private.delete_batch_change(public.delete_batch) returns jsonb`, `private.delete_batch_upsert(uuid, uuid, uuid, jsonb) returns bigint`, `private.delete_batch_delete(uuid, uuid, uuid) returns bigint`, `public.ping() returns text`; `sync_changes` covers both entity types.

- [ ] **Step 1: Write the failing tests**

`supabase/tests/database/03_batches_and_changes.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00.000Z', 'updatedAt', '2026-09-28T00:00:00.000Z') $$;
create function public.t_batch(p_id uuid, p_root uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'itemType', 'deck', 'rootItemId', p_root,
    'deletedAt', '2026-09-28T01:00:00Z') $$;
create function public.t_op(p_op int, p_type text, p_id uuid, p_kind text, p_row jsonb) returns jsonb
  language sql as $$
  select jsonb_build_object('opId', public.t_uuid(100000 + p_op), 'entityType', p_type,
    'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_change(p_id uuid) returns jsonb language sql as $$
  select c from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityId' = p_id::text $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- User A: root R (v1), batch B (v2), R trashed into B (v3).
select is(public.t_push(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'delete_batch', public.t_uuid(2), 'upsert', public.t_batch(public.t_uuid(2), public.t_uuid(1))),
    public.t_op(3, 'deck', public.t_uuid(1), 'upsert',
      public.t_root(public.t_uuid(1)) || jsonb_build_object('deleteBatchId', public.t_uuid(2)))))
  @? '$[*] ? (@.status != "applied")', false, 'a batch and a deck trashed into it are applied');
select is(public.t_change(public.t_uuid(2))->'row',
  jsonb_build_object('id', public.t_uuid(2), 'itemType', 'deck', 'rootItemId', public.t_uuid(1),
    'deletedAt', '2026-09-28T01:00:00.000000Z'), 'a batch reads back in the wire shape');
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(5), 'upsert',
    public.t_root(public.t_uuid(5)) || jsonb_build_object('deleteBatchId', public.t_uuid(404)))))->0->>'code',
  'VALIDATION_FAILED', 'a deck cannot name an unknown batch');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'delete_batch', public.t_uuid(6), 'upsert',
    public.t_batch(public.t_uuid(6), public.t_uuid(1)) || '{"itemType":"folder"}')))->0->>'code',
  'VALIDATION_FAILED', 'a batch holds cards or decks only');

-- Wire shape of a deck row.
select is((select array_agg(k order by k) from jsonb_object_keys(public.t_change(public.t_uuid(1))->'row') k),
  array['contentType','createdAt','deleteBatchId','depth','firstAnsweredAt','generation','id','name','parentId',
        'rootId','schedulerConfig','schedulerType','schedulerVersion','siblingPosition','sourceTemplateId',
        'sourceTemplateVersion','studyConfig','updatedAt'], 'a deck row carries the adapter keys');
select is(public.t_change(public.t_uuid(1))->'row'->>'createdAt', '2026-09-28T00:00:00.000000Z',
  'times are UTC with microseconds and Z');

-- Paging across both types: versions 1, 2, 3 are R, B, R again → changes hold B (2) and R (3).
select is(public.sync_changes(0, 1)->'changes'->0->>'entityId', public.t_uuid(2)::text, 'the first page holds the lowest version');
select is(public.sync_changes(0, 1)->>'hasMore', 'true', 'a full page says there is more');
select is(public.sync_changes(2, 1)->'changes'->0->>'entityId', public.t_uuid(1)::text, 'the next page continues after nextSince');
select is(public.sync_changes(3, 500), '{"changes": [], "nextSince": 3, "hasMore": false}'::jsonb, 'an empty page keeps since');
select is(jsonb_array_length(public.sync_changes(0, 0)->'changes'), 1, 'max_rows is clamped to at least 1');

-- Batch tombstone.
select is(public.t_push(jsonb_build_array(public.t_op(6, 'delete_batch', public.t_uuid(2), 'delete', null)))->0->>'status',
  'applied', 'a batch delete is applied');
select is(public.t_change(public.t_uuid(2)) - 'serverVersion',
  jsonb_build_object('entityType', 'delete_batch', 'entityId', public.t_uuid(2), 'deleted', true, 'row', null),
  'a deleted batch is a tombstone');

-- User B cannot see or touch A's rows.
select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.sync_changes(0, 500)->'changes', '[]'::jsonb, 'another user sees nothing');
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0,
  jsonb_build_object('opId', public.t_uuid(100001), 'status', 'rejected', 'serverVersion', null,
    'code', 'SYNC_ENTITY_CONFLICT', 'current', null), 'another user cannot take an id, even with the same opId');
select is(public.t_push(jsonb_build_array(public.t_op(7, 'delete_batch', public.t_uuid(2), 'delete', null)))->0->>'code',
  'SYNC_ENTITY_CONFLICT', 'another user cannot delete a batch');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'deck', public.t_uuid(7), 'upsert', public.t_root(public.t_uuid(7)))))->0->>'serverVersion',
  '1', 'versions are counted per user');

-- No identity, too many operations.
select set_config('request.jwt.claims', '', true);
select throws_ok($$ select public.sync_changes(0, 10) $$, 'P0001', 'NOT_AUTHENTICATED', 'a call needs a user');
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);
select throws_ok($$ select public.t_push((select jsonb_agg(public.t_op(300 + i, 'deck', public.t_uuid(300 + i), 'delete', null))
  from generate_series(1, 101) i)) $$, 'P0001', 'VALIDATION_FAILED', 'a batch holds at most 100 operations');

select * from finish();
rollback;
```

`supabase/tests/database/04_function_privileges.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select ok(not has_function_privilege('anon', 'public.sync_push(jsonb)', 'execute'), 'anon cannot push');
select ok(not has_function_privilege('anon', 'public.sync_changes(bigint, integer)', 'execute'), 'anon cannot pull');
select ok(has_function_privilege('authenticated', 'public.sync_push(jsonb)', 'execute'), 'a user can push');
select ok(has_function_privilege('authenticated', 'public.sync_changes(bigint, integer)', 'execute'), 'a user can pull');
select ok(not has_function_privilege('authenticated', 'private.deck_upsert(uuid, uuid, uuid, jsonb)', 'execute'),
  'private helpers are not callable');
set local role anon;
select is(public.ping(), 'ok', 'anon can ping');

select * from finish();
rollback;
```

- [ ] **Step 2: Run them to verify they fail**

Run: `npx supabase test db`
Expected: FAIL — `03_…` rejects `delete_batch` operations with `VALIDATION_FAILED`; `04_…` fails on `function public.ping() does not exist`.

- [ ] **Step 3: Extend the migration**

In `supabase/migrations/20260928000000_deck_sync.sql`:

a) After `private.deck_change`, add:

```sql
create function private.delete_batch_change(b public.delete_batch) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'delete_batch', 'entityId', b.id, 'serverVersion', b.server_version,
    'deleted', b.tombstoned_at is not null,
    'row', case when b.tombstoned_at is not null then null else jsonb_build_object(
      'id', b.id, 'itemType', b.item_type, 'rootItemId', b.root_item_id,
      'deletedAt', private.wire_time(b.deleted_at)) end)
$$;
```

b) In `private.current_change`, add a `v_batch public.delete_batch;` declaration and, before `return null;`:

```sql
  if p_type = 'delete_batch' then
    select * into v_batch from public.delete_batch where id = p_id and user_id = p_user;
    if found then
      return private.delete_batch_change(v_batch);
    end if;
  end if;
```

c) After `private.deck_delete`, add:

```sql
-- Trash batches: whole-row upsert, tombstone on delete, no tree rules (app deck-sync spec §6).
create function private.delete_batch_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_owner uuid;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  select user_id into v_owner from public.delete_batch where id = p_id for update;
  if found and v_owner <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.delete_batch (id, user_id, item_type, root_item_id, deleted_at, server_version,
    last_device_id, tombstoned_at)
  values (p_id, p_user, r->>'itemType', (r->>'rootItemId')::uuid, (r->>'deletedAt')::timestamptz, v_version,
    p_device, null)
  on conflict (id) do update set
    item_type = excluded.item_type, root_item_id = excluded.root_item_id, deleted_at = excluded.deleted_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id, tombstoned_at = null;
  return v_version;
end
$$;

create function private.delete_batch_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.delete_batch;
  v_version bigint;
begin
  select * into v_existing from public.delete_batch where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.tombstoned_at is not null then
    return v_existing.server_version;
  end if;
  v_version := private.allocate_versions(p_user, 1);
  update public.delete_batch set tombstoned_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;
```

d) In `private.apply_operation`, add the branches:

```sql
    if p_type = 'delete_batch' then
      return private.delete_batch_upsert(p_user, p_device, p_id, p_row);
    end if;
```

inside the `upsert` branch after the deck call, and

```sql
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
```

inside the `delete` branch after the deck call.

e) In `public.sync_changes`, replace the inner `u` subquery with the union of both tables:

```sql
    from (
      (select 'deck' as entity_type, d.id, d.server_version from public.deck d
       where d.user_id = v_user and d.server_version > v_since
       order by d.server_version limit v_limit + 1)
      union all
      (select 'delete_batch', b.id, b.server_version from public.delete_batch b
       where b.user_id = v_user and b.server_version > v_since
       order by b.server_version limit v_limit + 1)
    ) u
```

f) Before the grants block, add:

```sql
-- The keep-alive workflow calls this so a Free project is not paused (ADR-015 #9).
create function public.ping() returns text
language sql stable set search_path = '' as $$ select 'ok' $$;
```

and extend the grants:

```sql
revoke all on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `npx supabase db reset` then `npx supabase test db`
Expected: four files ok, `All tests successful.`

- [ ] **Step 5: Commit**

```bash
git add supabase/
git commit -m "feat(supabase): trash batches, pull across both types, per-user isolation and ping (ADR-015)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `SupabaseSyncApi` in the app

**Files:**
- Modify: `pubspec.yaml` (add `supabase_flutter`), `.claude/skills/flutter-project-setup/references/dependencies.md` (row)
- Create: `lib/core/network/supabase_config.dart`, `lib/core/sync/supabase_sync_api.dart`
- Modify: `lib/core/network/di/network_providers.dart` (remove `syncApi`), `lib/core/sync/di/sync_providers.dart`, `lib/main.dart`
- Test: `test/core/sync/supabase_sync_api_test.dart`, `test/core/network/supabase_config_test.dart`

**Interfaces:**
- Consumes: `SyncApi`, `PushRequestModel`, `PushResponseModel`, `ChangesResponseModel` (`lib/core/sync/`); RPC names and params from Tasks 2–3: `sync_push` `{request}`, `sync_changes` `{since, max_rows}`.
- Produces: `SupabaseConfig({required String url, required String publishableKey})`, `SupabaseConfig.environment`, `bool get isEnabled`; `typedef RpcCall = Future<Object?> Function(String function, Map<String, Object?> params)`; `typedef SessionGuard = Future<void> Function()`; `SupabaseSyncApi({required SessionGuard ensureSession, required RpcCall rpc})`; providers `supabaseConfigProvider`, `syncApiProvider` (now in `sync_providers.dart`).

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add supabase_flutter:^2.17.2`
Add to the table in `.claude/skills/flutter-project-setup/references/dependencies.md`, after the `connectivity_plus` row:

```markdown
| `supabase_flutter` | 2.x | The Supabase backend (ADR-015): anonymous auth and the `sync_push`/`sync_changes` RPCs, used only by `lib/core/sync/di/sync_providers.dart` and `main.dart`. |
```

- [ ] **Step 2: Write the failing tests**

`test/core/network/supabase_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/supabase_config.dart';

void main() {
  test('is enabled only when both the URL and the key are set', () {
    expect(const SupabaseConfig(url: 'u', publishableKey: 'k').isEnabled, isTrue);
    expect(const SupabaseConfig(url: '', publishableKey: 'k').isEnabled, isFalse);
    expect(const SupabaseConfig(url: 'u', publishableKey: '').isEnabled, isFalse);
  });

  test('a test build names no project', () {
    expect(SupabaseConfig.environment.isEnabled, isFalse);
  });
}
```

`test/core/sync/supabase_sync_api_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

void main() {
  late List<String> calls;
  late Map<String, Object?> lastParams;

  SupabaseSyncApi apiReturning(Object? response, {Object? sessionError}) =>
      SupabaseSyncApi(
        ensureSession: () async {
          calls.add('session');
          if (sessionError != null) {
            throw sessionError;
          }
        },
        rpc: (function, params) async {
          calls.add(function);
          lastParams = params;
          return response;
        },
      );

  setUp(() {
    calls = [];
    lastParams = {};
  });

  test('push sends the request as sync_push(request) after ensuring a session', () async {
    final api = apiReturning({
      'results': [
        {'opId': 'o', 'status': 'applied', 'serverVersion': 4, 'code': null, 'current': null},
      ],
    });

    final response = await api.push(
      const PushRequestModel(
        deviceId: 'd',
        operations: [
          SyncOperationModel(opId: 'o', entityType: 'deck', entityId: 'x', op: 'delete', row: null),
        ],
      ),
    );

    expect(calls, ['session', 'sync_push']);
    expect(lastParams, {
      'request': {
        'deviceId': 'd',
        'operations': [
          {'opId': 'o', 'entityType': 'deck', 'entityId': 'x', 'op': 'delete', 'row': null},
        ],
      },
    });
    expect(response.results.single.serverVersion, 4);
  });

  test('changes calls sync_changes(since, max_rows) and parses the page', () async {
    final api = apiReturning({
      'changes': [
        {'entityType': 'deck', 'entityId': 'x', 'serverVersion': 7, 'deleted': true, 'row': null},
      ],
      'nextSince': 7,
      'hasMore': false,
    });

    final page = await api.changes(3, 500);

    expect(calls, ['session', 'sync_changes']);
    expect(lastParams, {'since': 3, 'max_rows': 500});
    expect(page.changes.single.isDeleted, isTrue);
    expect(page.nextSince, 7);
  });

  test('a failed sign-in stops the call and reaches the scheduler', () async {
    final api = apiReturning(null, sessionError: StateError('offline'));

    await expectLater(api.changes(0, 500), throwsStateError);
    expect(calls, ['session']);
  });

  test('an RPC error reaches the scheduler', () async {
    final api = SupabaseSyncApi(
      ensureSession: () async {},
      rpc: (_, _) async => throw StateError('P0001 VALIDATION_FAILED'),
    );

    await expectLater(api.changes(0, 500), throwsStateError);
  });
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/core/network/supabase_config_test.dart test/core/sync/supabase_sync_api_test.dart`
Expected: FAIL — `supabase_config.dart` / `supabase_sync_api.dart` not found.

- [ ] **Step 4: Implement**

`lib/core/network/supabase_config.dart`:

```dart
/// Where the Supabase project lives (ADR-015). Sync runs only when a build
/// defines both `--dart-define=SUPABASE_URL=…` and
/// `--dart-define=SUPABASE_PUBLISHABLE_KEY=…`.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  static const environment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String url;
  final String publishableKey;

  bool get isEnabled => url.isNotEmpty && publishableKey.isNotEmpty;
}
```

`lib/core/sync/supabase_sync_api.dart`:

```dart
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_models.dart';

/// Calls a Postgres function through Supabase and returns its decoded JSON.
typedef RpcCall =
    Future<Object?> Function(String function, Map<String, Object?> params);

/// Makes sure the client holds a session before a call (anonymous sign-in).
typedef SessionGuard = Future<void> Function();

/// [SyncApi] over the Supabase RPCs `sync_push` and `sync_changes`
/// (ADR-015). Errors propagate: the scheduler backs off on any failure.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi({required SessionGuard ensureSession, required RpcCall rpc})
    : _ensureSession = ensureSession,
      _rpc = rpc;

  final SessionGuard _ensureSession;
  final RpcCall _rpc;

  @override
  Future<PushResponseModel> push(PushRequestModel request) async {
    await _ensureSession();
    final json = await _rpc('sync_push', {'request': request.toJson()});
    return PushResponseModel.fromJson(json! as Map<String, Object?>);
  }

  @override
  Future<ChangesResponseModel> changes(int since, int limit) async {
    await _ensureSession();
    final json = await _rpc('sync_changes', {
      'since': since,
      'max_rows': limit,
    });
    return ChangesResponseModel.fromJson(json! as Map<String, Object?>);
  }
}
```

In `lib/core/network/di/network_providers.dart`, delete the `syncApi` provider and the `sync_api.dart` import (the Dio stays for a future REST API, ADR-012).

In `lib/core/sync/di/sync_providers.dart`, add imports `package:memox/core/network/supabase_config.dart`, `package:memox/core/sync/supabase_sync_api.dart`, `package:memox/core/sync/sync_api.dart`, `package:supabase_flutter/supabase_flutter.dart`; drop the `network_providers.dart` import; and replace the enabling check and add two providers:

```dart
@Riverpod(keepAlive: true)
SupabaseConfig supabaseConfig(Ref ref) => SupabaseConfig.environment;

/// Sync through the Supabase project; main.dart has initialized the client.
@Riverpod(keepAlive: true)
SyncApi syncApi(Ref ref) {
  final client = Supabase.instance.client;
  return SupabaseSyncApi(
    ensureSession: () async {
      if (client.auth.currentSession != null) {
        return;
      }
      await client.auth.signInAnonymously();
    },
    rpc: (function, params) => client.rpc<Object?>(function, params: params),
  );
}

/// The running sync, or null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
    return null;
  }
  // … unchanged body …
}
```

In `lib/main.dart`, replace the two sync lines with:

```dart
  // ADR-015: sync starts with the app when this build names a Supabase project.
  final supabase = container.read(supabaseConfigProvider);
  if (supabase.isEnabled) {
    await Supabase.initialize(
      url: supabase.url,
      publishableKey: supabase.publishableKey,
    );
  }
  container.read(syncSchedulerProvider);
```

with `import 'package:supabase_flutter/supabase_flutter.dart';`.

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/network test/core/sync`
Expected: all pass.

- [ ] **Step 6: Run the app gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` (stage new files first: `git add -A lib test pubspec.yaml pubspec.lock .claude/skills`)
Expected: green; `flutter test --exclude-tags golden` passes, `test_skill_dependency_table.py` sees the new row.

- [ ] **Step 7: Commit**

Run `git status` first: the new plugin may touch generated platform registrants; stage those with the rest.

```bash
git add -A
git commit -m "feat(sync): SupabaseSyncApi with anonymous sign-in; sync runs when a build names a Supabase project (ADR-015)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: CI job, keep-alive workflow, Supabase README

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `.github/workflows/supabase-keepalive.yml`, `supabase/README.md`

**Interfaces:**
- Consumes: `supabase/` from Tasks 1–3; `public.ping()`.

- [ ] **Step 1: Replace the `api` job in `ci.yml`**

Replace the whole `api:` job with:

```yaml
  supabase:
    name: supabase
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7

      - uses: supabase/setup-cli@v1
        with:
          version: 2.118.0

      # Postgres only (the runner has Docker): migrations, then pgTAP (ADR-015 #6).
      - name: start database
        run: supabase db start

      - name: pgTAP
        run: supabase test db
```

and in `ci-gate`, `needs: [gate, goldens, supabase]`.

- [ ] **Step 2: Create the keep-alive workflow**

`.github/workflows/supabase-keepalive.yml`:

```yaml
# ADR-015 #9: a Free project pauses after a week without activity; one call a day keeps it up.
name: supabase keep-alive

on:
  schedule:
    - cron: '17 3 * * *'
  workflow_dispatch:

permissions: {}

jobs:
  ping:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: ping
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_PUBLISHABLE_KEY: ${{ secrets.SUPABASE_PUBLISHABLE_KEY }}
        run: |
          if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_PUBLISHABLE_KEY" ]; then
            echo "::notice::SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY is not set; nothing to keep alive."
            exit 0
          fi
          curl --fail --silent --show-error -X POST "$SUPABASE_URL/rest/v1/rpc/ping" \
            -H "apikey: $SUPABASE_PUBLISHABLE_KEY" -H "Content-Type: application/json" -d '{}'
```

- [ ] **Step 3: Write `supabase/README.md`**

```markdown
# MemoX on Supabase

The sync backend (ADR-015; design in
`docs/superpowers/specs/2026-09-28-supabase-backend-design.md`). Everything the
server does is in `migrations/`; `tests/database/` proves it with pgTAP.

## Run and test locally

Needs Docker. From the repo root:

    npx supabase db start      # Postgres with the migrations applied
    npx supabase test db       # pgTAP
    npx supabase db reset      # re-apply migrations after editing one

## Owner setup (once)

1. Create a project on supabase.com (Free plan).
2. Authentication → Sign In / Providers: enable **Anonymous sign-ins**, and
   turn on CAPTCHA or keep the default rate limit for anonymous sign-ins.
3. `npx supabase login`, `npx supabase link --project-ref <ref>`,
   `npx supabase db push`.
4. GitHub → Settings → Secrets → Actions: `SUPABASE_URL` and
   `SUPABASE_PUBLISHABLE_KEY` (Project Settings → API Keys), for the
   keep-alive workflow.
5. Build the app with both values:

       flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

## Rules

- Clients reach data only through `sync_push`, `sync_changes` and `ping`.
  Tables have RLS on, no policy and no client privilege; helpers live in the
  unexposed `private` schema.
- A new migration never edits one already pushed to the project.
```

- [ ] **Step 4: Validate the workflows**

Run: `python -c "import yaml,sys;[yaml.safe_load(open(f)) for f in ['.github/workflows/ci.yml','.github/workflows/supabase-keepalive.yml']];print('ok')"`
Expected: `ok`. Then `npx supabase test db` once more. Expected: `All tests successful.`

- [ ] **Step 5: Commit**

```bash
git add .github/workflows supabase/README.md
git commit -m "ci: pgTAP job for Supabase replaces the frozen API job; daily keep-alive ping (ADR-015)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Documents

**Files:**
- Modify: `docs/shared/decisions/ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md`, `docs/shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md`
- Modify: `docs/superpowers/specs/2026-09-27-api-authority-command-sync-design.md`, `docs/superpowers/specs/2026-09-27-api-command-protocol-deck-card-design.md`, `docs/superpowers/plans/2026-09-27-api-command-protocol-deck-card.md`, `docs/superpowers/specs/2026-09-27-server-sync-design.md`, `docs/superpowers/specs/2026-09-27-app-deck-sync-design.md`
- Modify: `docs/wbs_API.md`, `docs/wbs_BE.md`, `CLAUDE.md`, `docs/shared/data/schema.md`, `memox-api-services/README.md`
- Modify: skills citing ADR-014: `.claude/skills/flutter-architecture/SKILL.md`, `.claude/skills/flutter-data-layer/SKILL.md`, `.claude/skills/flutter-data-layer/references/persistence.md`, `.claude/skills/flutter-feature-slice/SKILL.md`, `.claude/skills/flutter-drift/references/dynamic-sql-semantics.md`, `.claude/skills/flutter-drift/references/project-baseline.md`, and `networking.md` if it names `API_BASE_URL` as the sync switch
- Regenerate: `docs/_generated/index.md`

- [ ] **Step 1: Deprecate ADR-014**

Frontmatter: `status: deprecated`, `superseded_by: ADR-015`. Under the title block add:

```markdown
> **Thay bởi [ADR-015](ADR-015-supabase-lam-backend.md) (2026-09-28):** backend là
> Supabase; nghiệp vụ và SRS chỉ ở app. Văn bản dưới đây giữ làm lịch sử.
```

- [ ] **Step 2: ADR-013 note**

Replace the `> Dòng #1 … ADR-014 …` quote with:

```markdown
> [ADR-014](ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md) từng sửa các dòng #1, #2,
> #4, #5 và #8; [ADR-015](ADR-015-supabase-lam-backend.md) (2026-09-28) bỏ ADR-014,
> nên các dòng đó có hiệu lực trở lại như văn bản gốc. Server là Supabase: đọc
> "PostgreSQL của `memox-api-services`" là Postgres của Supabase, và
> `CurrentUserProvider` là `auth.uid()`.
```

- [ ] **Step 3: Superseded specs and plan**

At the top of the API authority spec, the command-protocol spec and its plan, add under the title:

```markdown
> **Superseded 2026-09-28** by [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md)
> and the [Supabase backend design](../specs/2026-09-28-supabase-backend-design.md): the
> backend is Supabase and business rules stay in the app. Kept as history.
```

(use `2026-09-28-supabase-backend-design.md` without `../specs/` inside `specs/`). In the server-sync spec, replace the "Amended 2026-09-27" quote with:

```markdown
> **Amended 2026-09-28** by [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md):
> the 2026-09-27 command-sync amendment (ADR-014) is withdrawn, so this spec holds as
> written; the server side is implemented in Supabase
> ([Supabase backend design](2026-09-28-supabase-backend-design.md)), with `auth.uid()`
> in place of `CurrentUserProvider`.
```

In the app deck-sync spec, add under the status line: `> Since 2026-09-28 the server is Supabase and sync is enabled by SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY ([Supabase backend design](2026-09-28-supabase-backend-design.md) §5).`

- [ ] **Step 4: WBS**

- `docs/wbs_API.md`: under the title add `> **Đóng băng 2026-09-28** cùng `memox-api-services` ([ADR-015](shared/decisions/ADR-015-supabase-lam-backend.md)). Tiến độ sync nằm ở nhóm "Đồng bộ với server" của [`wbs_BE.md`](wbs_BE.md).`
- `docs/wbs_BE.md`: rename the heading to `### Đồng bộ với server (ADR-013, ADR-015)`; replace its intro paragraph with one saying the server is Supabase (`supabase/`), the protocol is the row model of the server-sync spec, and business rules stay in the app; set BE-E7 to `hoãn` with next action `Bị thay bởi ADR-015: không làm mô hình lệnh`; add a row:

```markdown
| BE-E8 | Backend Supabase cho sync deck (ADR-015): bảng và RPC `sync_push`/`sync_changes`/`ping` trong `supabase/migrations/`, RLS không policy, pgTAP; `SupabaseSyncApi` và đăng nhập ẩn danh; job CI `supabase`, workflow keep-alive | đang làm | BE-E1 | L | [spec](superpowers/specs/2026-09-28-supabase-backend-design.md), [plan](superpowers/plans/2026-09-28-supabase-backend.md) | Chủ dự án tạo project và `supabase db push` (README của `supabase/`) |
```

Replace the other `ADR-014` mentions in `wbs_BE.md` prose with `ADR-015` where they state the current rule; leave dated history lines as they are.

- [ ] **Step 5: CLAUDE.md**

Replace the section `## Backend API: memox-api-services` with:

```markdown
## Backend: Supabase

The server is a Supabase project ([ADR-015](docs/shared/decisions/ADR-015-supabase-lam-backend.md)).
Business rules and SRS live only in the app; the server checks integrity.

- **Code:** `supabase/migrations/` (SQL and PL/pgSQL). Clients call only
  `sync_push`, `sync_changes` and `ping`; tables have RLS on, no policy and
  no client privilege; helpers live in the unexposed `private` schema.
- **Gate:** `npx supabase db start` then `npx supabase test db` (pgTAP in
  `supabase/tests/`; needs Docker). CI runs it in the `supabase` job.
- **Owner setup:** [supabase/README.md](supabase/README.md).
- **`memox-api-services/` is frozen:** kept as a reference for server logic
  that may come later (sharing, secrets, heavy batch, AI), out of CI, not
  developed. Its conventions stay in `spring-boot-mybatis-review`.
```

and change the Java/Spring skills bullet's link target from `#backend-api-memox-api-services` to `#backend-supabase`, saying they apply to the frozen `memox-api-services/` only.

- [ ] **Step 6: schema.md, API README, skills**

- `docs/shared/data/schema.md` sync section: add one line — the server copy lives in Supabase (`supabase/migrations/`), reached through `sync_push`/`sync_changes` (ADR-015).
- `memox-api-services/README.md`: first line after the title: `> **Frozen 2026-09-28** ([ADR-015](../docs/shared/decisions/ADR-015-supabase-lam-backend.md)): the backend is Supabase; this project is a reference, out of CI.`
- Each skill line citing ADR-014 (list above, from `grep -rn "ADR-014" .claude/skills`): cite ADR-015 instead, and where the line says the server is canonical for SRS or that push carries commands, say instead that the app owns BR and SRS and push carries rows (ADR-013 with ADR-015). In `flutter-data-layer/SKILL.md`'s description, "Retrofit on the one shared Dio (ADR-012, ADR-014)" becomes "the Supabase RPCs through `SupabaseSyncApi` (ADR-015); Retrofit on the shared Dio stays for a future REST API (ADR-012)". Any `API_BASE_URL` described as the sync switch becomes `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY`.

- [ ] **Step 7: Regenerate and check**

Run: `python tools/docs/generate.py && python tools/docs/check.py && grep -rn "ADR-014" .claude/skills CLAUDE.md`
Expected: generate writes `docs/_generated/index.md` with ADR-014 `deprecated` → ADR-015 and ADR-015 `active`; check prints no error; the grep finds nothing.

- [ ] **Step 8: Full gates**

Run: `git add -A && bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `npx supabase test db`
Expected: both green.

- [ ] **Step 9: Commit**

```bash
git add -A docs CLAUDE.md memox-api-services/README.md .claude/skills
git commit -m "docs: ADR-014 superseded by ADR-015; specs, WBS, CLAUDE.md and skills follow the Supabase backend

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
