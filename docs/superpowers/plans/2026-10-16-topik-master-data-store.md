# TOPIK Master Data Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Supabase side of ADR-024: the Master Data tables, the admin and client RPCs, the Storage bucket and its policies, and the pgTAP that pins them, with the shared fixtures exported from Dart so the SQL shape checks are proven on the same cases as `checkTopikTest`.

**Architecture:** One migration `supabase/migrations/20261017000000_topik_master_data.sql`, written task by task (it is unpushed until merge, so editing it between tasks is allowed; after merge it is frozen, `supabase/README.md` rule). Four tables behind RLS with no policy and no grant; `SECURITY DEFINER` RPCs with `set search_path = ''`; admin RPCs start with `private.is_admin()` → `FORBIDDEN`; every write audits in its own transaction. Media sits in a private bucket `topik-media` whose `storage.objects` policies call two `SECURITY DEFINER` helpers in `public`. No Flutter and no Admin Web code in this plan (plans 2 and 3 of the spec §10).

**Tech Stack:** Supabase Postgres 15 (PL/pgSQL, jsonb), Supabase Storage, pgTAP through `npx supabase test db` (Docker; in this container prefix `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io`), Dart (`dart run`) for the fixture export, `flutter test` for the freshness gate.

**Spec:** `docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md` (§5 model, §6 RPCs, §6.3 shape checks, §6.4 media, §7 fixtures), ADR-024.

## Global Constraints

- Every table: `enable row level security` and `revoke all on table … from public, anon, authenticated` (ADR-015 #5).
- Every function in `public` that clients call: `security definer set search_path = ''`, then `revoke all on function … from public, anon, authenticated; grant execute on function … to authenticated;` and the migration ends with `revoke all on all functions in schema private from public, anon, authenticated;` (test `04_function_privileges.sql`).
- Every new `public` RPC name is added to the allowed list in `supabase/tests/database/04_function_privileges.sql` (otherwise that test fails).
- Errors are codes raised with `raise exception '<CODE>'`: `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_FAILED`, `VERSION_MISMATCH`, `MEDIA_MISSING`, `INVALID_STATE`, `NOT_AUTHENTICATED` (from `private.require_current_profile()`), never SQL text (BR-CORE-005).
- Admin RPCs call `private.require_current_profile()` first, then `private.is_admin()`; a non-admin gets `FORBIDDEN` (pattern of `role_set`, migration `20261010000000`).
- Timestamps go to clients through `private.wire_time(...)`.
- A new migration never edits one already pushed; this plan's migration is the only file under `supabase/migrations/` it touches.
- Master Data is not a sync entity type: `private.push_one`, `private.apply_operation`, `private.current_change`, `public.sync_changes` and test `15_sync_entity_dispatch.sql` are not touched.
- The owner runs the project push through the `supabase migrations` workflow after merge; nothing in this plan pushes.
- Commit messages: `feat(supabase): DEV-394 …` / `test(supabase): DEV-394 …`, with the attribution lines of the session.

## Review Focus

1. A draft whose `contentVersion` is stale (the admin edited while another admin published): `topik_admin_publish` must refuse with `VERSION_MISMATCH`, not publish a duplicate version. Pinned in Task 4.
2. `topik_catalog(since)` when more than 500 publications changed: the page must end with `more = true` and a `next` the client can pass back, and no entry may be skipped between pages. Pinned in Task 5.
3. `topik_test_content` for a version that is no longer current (a superseded or retired one): `NOT_FOUND`, so a client never caches content the catalog no longer names. Pinned in Task 5.
4. An object in `topik-media` whose path names a test and version that is published but whose file is not listed in the version's `media`: readable by clients? The read policy keys on the prefix only; a stray file under a published prefix is readable. Acceptable (an admin put it there) and pinned as such in Task 6 so the behaviour is deliberate.
5. A publish whose JSON passes the SQL shape check but would fail `checkTopikTest` (a question type of another level, a translation missing `en` deep in a word): the app still rejects it on download (BR-TOPIK-008). The fixtures of Task 7 pin that the SQL check is a subset: every fixture the SQL rejects, Dart rejects; not the reverse.

---

### Task 1: Tables, sequence and immutability triggers

**Files:**
- Create: `supabase/migrations/20261017000000_topik_master_data.sql`
- Create: `supabase/tests/database/18_topik_master_data.sql`

**Interfaces:**
- Produces: tables `public.topik_test_draft`, `public.topik_test_version`, `public.topik_publication`, `public.topik_master_audit`; sequence `public.topik_catalog_version_seq`; trigger functions `private.topik_version_immutable()`, `private.topik_audit_append_only()`. `checksum` is `md5(json::text)` (set by Task 4; Task 1's test inserts a literal).

- [ ] **Step 1: Write the failing pgTAP test**

```sql
-- supabase/tests/database/18_topik_master_data.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);
-- ADR-024, spec 2026-10-16 §5: Master Data tables behind RLS with no policy; a
-- published version and the audit log are immutable.

select has_table('public', 'topik_test_draft', 'draft table exists');
select has_table('public', 'topik_test_version', 'version table exists');
select has_table('public', 'topik_publication', 'publication table exists');
select has_table('public', 'topik_master_audit', 'audit table exists');
select ok(not has_table_privilege('authenticated', 'public.topik_test_version', 'select'),
  'clients cannot read versions directly');

-- As postgres (the test role), a version cannot be changed or removed.
insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_at, published_by, note)
values ('topik2-96-reading', 1, '{"testId":"topik2-96-reading","contentVersion":1}'::jsonb, '[]'::jsonb,
  'abc', now(), null, 'first');
select throws_like(
  $$update public.topik_test_version set note = 'edited' where test_id = 'topik2-96-reading'$$,
  '%immutable%', 'a published version cannot be updated');
select throws_like(
  $$delete from public.topik_test_version where test_id = 'topik2-96-reading'$$,
  '%immutable%', 'a published version cannot be deleted');
insert into public.topik_master_audit (id, at, actor, action, test_id, content_version, detail)
values (gen_random_uuid(), now(), null, 'publish', 'topik2-96-reading', 1, '{}'::jsonb);
select throws_like(
  $$delete from public.topik_master_audit where test_id = 'topik2-96-reading'$$,
  '%append-only%', 'the audit log cannot be deleted from');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it to see it fail**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | tail -20`
Expected: `18_topik_master_data.sql` fails (`has_table` false).

- [ ] **Step 3: Write the migration's first part**

```sql
-- supabase/migrations/20261017000000_topik_master_data.sql
-- ADR-024, spec 2026-10-16 §5–§6: TOPIK Master Data (the tests themselves)
-- live here, managed by the Admin Web through topik_admin_* and read by the
-- app through topik_catalog and topik_test_content. Not a sync entity type:
-- not personal, no user_id, no tombstone per user (spec §4).

-- The working copy of one test; may be invalid while drafting.
create table public.topik_test_draft (
  test_id text primary key,
  json jsonb not null,
  last_check jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  check (json->>'testId' = test_id)
);

-- One published, immutable version of one test (BR-TOPIK-007).
create table public.topik_test_version (
  test_id text not null,
  content_version integer not null check (content_version > 0),
  json jsonb not null,
  media jsonb not null default '[]'::jsonb,
  checksum text not null,
  published_at timestamptz not null default now(),
  published_by uuid references auth.users (id) on delete set null,
  note text,
  primary key (test_id, content_version),
  check (json->>'testId' = test_id),
  check ((json->>'contentVersion')::integer = content_version),
  check (jsonb_typeof(media) = 'array')
);

-- What clients see of each test: published at one version, or retired.
-- catalog_version is one global, monotonic counter: a client pulls
-- "everything after N" (spec §6.2).
create sequence public.topik_catalog_version_seq;
create table public.topik_publication (
  test_id text primary key,
  status text not null check (status in ('published', 'retired')),
  current_version integer not null,
  catalog_version bigint not null unique,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  foreign key (test_id, current_version) references public.topik_test_version (test_id, content_version)
);
create index idx_topik_publication_catalog on public.topik_publication (catalog_version);

-- Every change, in the transaction that made it; append-only.
create table public.topik_master_audit (
  id uuid primary key,
  at timestamptz not null default now(),
  actor uuid references auth.users (id) on delete set null,
  action text not null check (action in
    ('draft_save', 'draft_import', 'draft_delete', 'publish', 'retire', 'unretire', 'rollback')),
  test_id text not null,
  content_version integer,
  detail jsonb not null default '{}'::jsonb
);
create index idx_topik_master_audit_at on public.topik_master_audit (at desc, id desc);
create index idx_topik_master_audit_test on public.topik_master_audit (test_id, at desc);

alter table public.topik_test_draft enable row level security;
alter table public.topik_test_version enable row level security;
alter table public.topik_publication enable row level security;
alter table public.topik_master_audit enable row level security;
revoke all on table public.topik_test_draft, public.topik_test_version,
  public.topik_publication, public.topik_master_audit from public, anon, authenticated;
revoke all on sequence public.topik_catalog_version_seq from public, anon, authenticated;

create function private.topik_version_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'topik_test_version is immutable once published';
end
$$;
create trigger topik_test_version_immutable
before update or delete on public.topik_test_version
for each row execute function private.topik_version_immutable();

create function private.topik_audit_append_only() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'topik_master_audit is append-only';
end
$$;
create trigger topik_master_audit_append_only
before update or delete on public.topik_master_audit
for each row execute function private.topik_audit_append_only();

revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | tail -20`
Expected: every file passes, `18_topik_master_data.sql` 8/8.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql
git commit -m "feat(supabase): DEV-394 TOPIK Master Data tables, immutable versions, append-only audit (ADR-024)"
```

---

### Task 2: The shape check

**Files:**
- Modify: `supabase/migrations/20261017000000_topik_master_data.sql` (append)
- Modify: `supabase/tests/database/18_topik_master_data.sql` (raise `plan`, append tests)

**Interfaces:**
- Produces: `private.topik_master_shape_issues(p_json jsonb) returns text[]`: the names of the broken rules, in the Dart enum's spelling (`identity`, `metadata`, `numbering`, `points`, `options`, `groups`, `languages`), empty when the shape is right. A subset of `checkTopikTest` (spec §6.3): no question-type map, no audio range, no asset existence.

- [ ] **Step 1: Write the failing tests** (append before `select * from finish();`; set `plan(20)`)

```sql
-- §6.3: the SQL shape check, a subset of checkTopikTest, in the Dart rules' names.
create function public.t_test(p_level text, p_section text, p_first int, p_count int, p_points int)
returns jsonb language sql as $$
  select jsonb_build_object(
    'schemaVersion', 1, 'contentVersion', 1,
    'testId', p_level || '-96-' || p_section, 'level', p_level, 'round', 96, 'section', p_section,
    'format', 'pbt', 'form', 'B-홀수형', 'titleKo', '제96회', 'officialTimeLimitSec', 3600,
    'source', jsonb_build_object('publishedBy', 'NIIED', 'url', 'https://www.topik.go.kr/x'),
    'assets', case when p_section = 'listening' then jsonb_build_object('audio', 'a.mp3') else '{}'::jsonb end,
    'groups', (select jsonb_agg(jsonb_build_object('groupId', 'g' || n, 'instructionKo', '※',
        'questionNos', jsonb_build_array(n),
        'audio', case when p_section = 'listening'
          then jsonb_build_object('startMs', 0, 'endMs', 1000, 'playCount', 2) end))
      from generate_series(p_first, p_first + p_count - 1) n),
    'questions', (select jsonb_agg(jsonb_build_object('no', n, 'groupId', 'g' || n,
        'questionType', 'X', 'points', p_points, 'stemKo', 'q',
        'options', jsonb_build_array(jsonb_build_object('idx', 1, 'textKo', 'a'),
          jsonb_build_object('idx', 2, 'textKo', 'b'), jsonb_build_object('idx', 3, 'textKo', 'c'),
          jsonb_build_object('idx', 4, 'textKo', 'd')),
        'answerIdx', 1))
      from generate_series(p_first, p_first + p_count - 1) n)) $$;

select is(private.topik_master_shape_issues(public.t_test('topik2', 'reading', 1, 50, 2)), '{}'::text[],
  'TOPIK II reading, 50 × 2 points, passes');
select is(private.topik_master_shape_issues(public.t_test('topik1', 'listening', 1, 30, 4) || '{"questions": []}'::jsonb),
  '{numbering,points,groups}'::text[], 'no questions: numbering, points and groups');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{testId}', '"topik2-95-reading"')),
  '{identity}'::text[], 'a test id that does not match its fields');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{source,publishedBy}', '"ETS"')),
  '{metadata}'::text[], 'a publisher other than NIIED');
select is(private.topik_master_shape_issues(public.t_test('topik1', 'reading', 1, 40, 2) || '{"questions": null}'::jsonb)
  @> '{numbering}'::text[], true, 'TOPIK I reading must start at 31');
select is(private.topik_master_shape_issues(public.t_test('topik2', 'reading', 1, 50, 3)), '{points}'::text[],
  'TOPIK II points other than 2, total other than 100');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,answerIdx}', '5')),
  '{options}'::text[], 'an answer index of 5');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,groupId}', '"nope"')),
  '{groups}'::text[], 'a question whose group does not exist');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,explanation}', '{"vi": "x"}')),
  '{languages}'::text[], 'an explanation without en');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,explanation}', '{"vi": "x", "en": "y"}')),
  '{}'::text[], 'an explanation with both languages passes');
select is(private.topik_master_shape_issues('{"testId": "x"}'::jsonb) @> '{identity,metadata}'::text[], true,
  'a bare object fails identity and metadata and does not throw');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik1', 'listening', 1, 30, 4), '{questions,0,points}', '3')) @> '{points}'::text[],
  true, 'TOPIK I listening: 29 × 4 + 3 is not 100');
```

The expected order of the names is the order the function appends them: `identity`, `metadata`, `numbering`, `points`, `options`, `groups`, `languages`.

- [ ] **Step 2: Run to see them fail**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | grep -A3 "18_topik"`
Expected: `function private.topik_master_shape_issues(jsonb) does not exist`.

- [ ] **Step 3: Append the function to the migration**

```sql
-- §6.3: the structural half of BR-TOPIK-001…004, 006, 007, in the Dart rules'
-- names; a subset of checkTopikTest, which the app still runs on download.
create function private.topik_master_shape_issues(p_json jsonb) returns text[]
language plpgsql immutable set search_path = '' as $$
declare
  v_issues text[] := '{}';
  v_level text := p_json->>'level';
  v_section text := p_json->>'section';
  v_first integer;
  v_count integer;
  v_questions jsonb := case when jsonb_typeof(p_json->'questions') = 'array' then p_json->'questions' else '[]'::jsonb end;
  v_groups jsonb := case when jsonb_typeof(p_json->'groups') = 'array' then p_json->'groups' else '[]'::jsonb end;
  v_points_ok boolean;
begin
  -- identity: testId = {level}-{round}-{section}
  if p_json->>'testId' is distinct from format('%s-%s-%s', v_level, p_json->>'round', v_section)
     or v_level not in ('topik1', 'topik2') or v_section not in ('listening', 'reading')
     or coalesce((p_json->>'round')::integer, 0) <= 0 then
    v_issues := v_issues || 'identity';
  end if;
  -- metadata: BR-TOPIK-007 and the fixed format
  if coalesce((p_json->>'schemaVersion')::integer, 0) <> 1
     or coalesce((p_json->>'contentVersion')::integer, 0) < 1
     or p_json->>'format' is distinct from 'pbt'
     or coalesce(p_json->>'form', '') = ''
     or p_json->'source'->>'publishedBy' is distinct from 'NIIED'
     or coalesce(p_json->'source'->>'url', '') = '' then
    v_issues := v_issues || 'metadata';
  end if;
  -- numbering: BR-TOPIK-001
  select case when v_level = 'topik1' and v_section = 'listening' then 1
              when v_level = 'topik1' and v_section = 'reading' then 31
              else 1 end,
         case when v_level = 'topik1' and v_section = 'listening' then 30
              when v_level = 'topik1' and v_section = 'reading' then 40
              else 50 end
  into v_first, v_count;
  if (select coalesce(array_agg((q->>'no')::integer order by (q->>'no')::integer), '{}')
      from jsonb_array_elements(v_questions) q)
     is distinct from (select array_agg(n) from generate_series(v_first, v_first + v_count - 1) n) then
    v_issues := v_issues || 'numbering';
  end if;
  -- points: BR-TOPIK-002
  select coalesce(sum((q->>'points')::integer), 0) = 100
     and bool_and(case when v_level = 'topik2' then (q->>'points')::integer = 2
                       when v_section = 'listening' then (q->>'points')::integer in (3, 4)
                       else (q->>'points')::integer in (2, 3) end)
  into v_points_ok from jsonb_array_elements(v_questions) q;
  if not coalesce(v_points_ok, false) then
    v_issues := v_issues || 'points';
  end if;
  -- options: BR-TOPIK-003
  if exists (select 1 from jsonb_array_elements(v_questions) q
             where jsonb_typeof(q->'options') is distinct from 'array'
                or (select coalesce(array_agg((o->>'idx')::integer order by (o->>'idx')::integer), '{}')
                    from jsonb_array_elements(q->'options') o) <> '{1,2,3,4}'::integer[]
                or exists (select 1 from jsonb_array_elements(q->'options') o
                           where coalesce(o->>'textKo', '') = '' and coalesce(o->>'image', '') = '')
                or coalesce((q->>'answerIdx')::integer, 0) not between 1 and 4) then
    v_issues := v_issues || 'options';
  end if;
  -- groups: BR-TOPIK-004 (membership; the audio range is Dart's)
  if jsonb_array_length(v_groups) = 0
     or exists (select 1 from jsonb_array_elements(v_questions) q
                where not exists (select 1 from jsonb_array_elements(v_groups) g
                                  where g->>'groupId' = q->>'groupId'
                                    and g->'questionNos' @> to_jsonb(array[(q->>'no')::integer])))
     or (select count(*) from jsonb_array_elements(v_groups) g)
        <> (select count(distinct g->>'groupId') from jsonb_array_elements(v_groups) g)
     or exists (select 1 from jsonb_array_elements(v_groups) g, jsonb_array_elements(g->'questionNos') n
                where not exists (select 1 from jsonb_array_elements(v_questions) q where q->'no' = n))
     or (select count(*) from jsonb_array_elements(v_groups) g, jsonb_array_elements(g->'questionNos') n)
        <> jsonb_array_length(v_questions) then
    v_issues := v_issues || 'groups';
  end if;
  -- languages: BR-TOPIK-006, every multilingual object has non-empty vi and en
  if exists (
    select 1 from (
      select q->'explanation' as t from jsonb_array_elements(v_questions) q
      union all select q->'translation' from jsonb_array_elements(v_questions) q
      union all select g->'scriptTranslation' from jsonb_array_elements(v_groups) g
      union all select w from jsonb_array_elements(v_questions) q,
        jsonb_array_elements(case when jsonb_typeof(q->'words') = 'array' then q->'words' else '[]'::jsonb end) w
      union all select gr from jsonb_array_elements(v_questions) q,
        jsonb_array_elements(case when jsonb_typeof(q->'grammars') = 'array' then q->'grammars' else '[]'::jsonb end) gr
    ) x
    where x.t is not null and jsonb_typeof(x.t) <> 'null'
      and (coalesce(btrim(x.t->>'vi'), '') = '' or coalesce(btrim(x.t->>'en'), '') = '')) then
    v_issues := v_issues || 'languages';
  end if;
  return v_issues;
exception when others then
  -- A JSON that is not the shape at all (a wrong type in a field) is an identity
  -- and metadata failure, never an error to the caller.
  return array['identity', 'metadata'];
end
$$;
revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | grep -A3 "18_topik"`
Expected: 20/20. If a `select is(...)` on the array order fails, the function appends in a different order than the test lists: fix the test's expected array to the function's order (`identity, metadata, numbering, points, options, groups, languages`), never the other way round.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql
git commit -m "feat(supabase): DEV-394 the SQL shape check of a TOPIK test, in the Dart rules' names"
```

---

### Task 3: Admin RPCs for drafts and the audit log

**Files:**
- Modify: `supabase/migrations/20261017000000_topik_master_data.sql` (append)
- Modify: `supabase/tests/database/18_topik_master_data.sql` (append; `plan(32)`)
- Modify: `supabase/tests/database/04_function_privileges.sql` (the allowed list)

**Interfaces:**
- Produces:
  - `private.topik_audit(p_action text, p_test_id text, p_content_version integer, p_detail jsonb) returns void`
  - `private.require_topik_admin() returns uuid` (profile check, then `is_admin`, else `FORBIDDEN`)
  - `public.topik_admin_list() returns jsonb` → `{"items": [{"testId", "draft": {"updatedAt", "lastCheck"} | null, "publication": {"status", "currentVersion", "catalogVersion"} | null, "latestVersion": int | null}]}`
  - `public.topik_admin_draft_get(p_test_id text) returns jsonb` → `{"testId", "json", "lastCheck", "updatedAt", "updatedBy"}` or `NOT_FOUND`
  - `public.topik_admin_draft_save(p_test_id text, p_json jsonb, p_last_check jsonb, p_imported boolean) returns jsonb` → `{"testId", "updatedAt", "issues": text[]}` (the SQL shape issues, informational)
  - `public.topik_admin_draft_delete(p_test_id text) returns jsonb` → `{"testId"}`
  - `public.topik_admin_audit(p_test_id text, p_limit integer, p_before timestamptz) returns jsonb` → `{"items": [...], "next": timestamptz | null}`

- [ ] **Step 1: Write the failing tests** (append; the admin user `aaaaaaaa-…01` and the plain user `bbbbbbbb-…02` are inserted into `auth.users` as postgres before `set local role authenticated`; the profile trigger creates their profiles and the admin role is set with an `update`, as `12_account.sql` does)

```sql
-- The trigger on_auth_user_created (migration 20261010000000) creates each
-- profile; the role is then set as 12_account.sql does.
insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@example.com', false),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'user@example.com', false)
on conflict (id) do nothing;
update public.profiles set role = 'admin' where id = 'aaaaaaaa-0000-0000-0000-000000000001';

create function public.t_as(p_user text) returns void language sql as $$
  select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', p_user), true) $$;

set local role authenticated;
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select throws_like($$select public.topik_admin_list()$$, 'FORBIDDEN', 'a user is not an admin: list');
select throws_like($$select public.topik_admin_draft_save('topik2-96-reading', '{}'::jsonb, '{}'::jsonb, false)$$,
  'FORBIDDEN', 'a user is not an admin: save');

select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_list()->'items', '[]'::jsonb, 'an admin sees an empty list');
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2), '{"ok": true}'::jsonb, true)->'issues',
  '[]'::jsonb, 'a valid draft saves with no issue');
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 3), '{}'::jsonb, false)->'issues',
  '["points"]'::jsonb, 'an invalid draft saves and reports its issues');
select throws_like($$select public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2) || '{"testId": "other"}'::jsonb, '{}'::jsonb, false)$$,
  'VALIDATION_FAILED', 'a draft whose testId is not the key is refused');
select is(public.topik_admin_list()->'items'->0->>'testId', 'topik2-96-reading', 'the list names the draft');
select is(public.topik_admin_list()->'items'->0->'publication', 'null'::jsonb, 'not published yet');
select is(public.topik_admin_draft_get('topik2-96-reading')->'json'->'questions'->0->>'points', '3', 'the draft reads back');
select throws_like($$select public.topik_admin_draft_get('nope')$$, 'NOT_FOUND', 'an unknown draft');
select is((select count(*) from jsonb_array_elements(public.topik_admin_audit(null, 50, null)->'items')), 2::bigint,
  'two audit rows: import, then save');
select is(public.topik_admin_audit('topik2-96-reading', 50, null)->'items'->0->>'action', 'draft_save', 'newest first');
select is(public.topik_admin_draft_delete('topik2-96-reading')->>'testId', 'topik2-96-reading', 'delete returns the id');
select is(public.topik_admin_list()->'items', '[]'::jsonb, 'the draft is gone');
```

- [ ] **Step 2: Run to see them fail**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | grep -A3 "18_topik"`
Expected: `function public.topik_admin_list() does not exist`.

- [ ] **Step 3: Append the functions**

```sql
-- §6.1: admin RPCs. Every one requires a profile, then the admin role.
create function private.require_topik_admin() returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  return v_user;
end
$$;

create function private.topik_audit(p_action text, p_test_id text, p_content_version integer, p_detail jsonb)
returns void language sql set search_path = '' as $$
  insert into public.topik_master_audit (id, at, actor, action, test_id, content_version, detail)
  values (gen_random_uuid(), now(), auth.uid(), p_action, p_test_id, p_content_version, coalesce(p_detail, '{}'::jsonb))
$$;

create function public.topik_admin_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_topik_admin();
  return jsonb_build_object('items', coalesce((
    select jsonb_agg(jsonb_build_object(
      'testId', t.test_id,
      'draft', case when d.test_id is null then null else jsonb_build_object(
        'updatedAt', private.wire_time(d.updated_at), 'lastCheck', d.last_check) end,
      'publication', case when p.test_id is null then null else jsonb_build_object(
        'status', p.status, 'currentVersion', p.current_version, 'catalogVersion', p.catalog_version) end,
      'latestVersion', (select max(v.content_version) from public.topik_test_version v where v.test_id = t.test_id))
      order by t.test_id)
    from (select test_id from public.topik_test_draft
          union select test_id from public.topik_publication) t
    left join public.topik_test_draft d on d.test_id = t.test_id
    left join public.topik_publication p on p.test_id = t.test_id), '[]'::jsonb));
end
$$;

create function public.topik_admin_draft_get(p_test_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_row public.topik_test_draft;
begin
  perform private.require_topik_admin();
  select * into v_row from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  return jsonb_build_object('testId', v_row.test_id, 'json', v_row.json, 'lastCheck', v_row.last_check,
    'updatedAt', private.wire_time(v_row.updated_at), 'updatedBy', v_row.updated_by);
end
$$;

create function public.topik_admin_draft_save(p_test_id text, p_json jsonb, p_last_check jsonb, p_imported boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_topik_admin();
  v_issues text[];
  v_at timestamptz := now();
begin
  if jsonb_typeof(p_json) is distinct from 'object' or p_json->>'testId' is distinct from p_test_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_issues := private.topik_master_shape_issues(p_json);
  insert into public.topik_test_draft (test_id, json, last_check, updated_at, updated_by)
  values (p_test_id, p_json, coalesce(p_last_check, '{}'::jsonb), v_at, v_user)
  on conflict (test_id) do update
    set json = excluded.json, last_check = excluded.last_check, updated_at = excluded.updated_at,
        updated_by = excluded.updated_by;
  perform private.topik_audit(case when p_imported then 'draft_import' else 'draft_save' end, p_test_id, null,
    jsonb_build_object('issues', to_jsonb(v_issues)));
  return jsonb_build_object('testId', p_test_id, 'updatedAt', private.wire_time(v_at), 'issues', to_jsonb(v_issues));
end
$$;

create function public.topik_admin_draft_delete(p_test_id text) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_topik_admin();
  delete from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  perform private.topik_audit('draft_delete', p_test_id, null, '{}'::jsonb);
  return jsonb_build_object('testId', p_test_id);
end
$$;

create function public.topik_admin_audit(p_test_id text, p_limit integer, p_before timestamptz) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_items jsonb;
  v_next timestamptz;
begin
  perform private.require_topik_admin();
  with page as (
    select a.*, row_number() over (order by a.at desc, a.id desc) as n
    from public.topik_master_audit a
    where (p_test_id is null or a.test_id = p_test_id)
      and (p_before is null or a.at < p_before)
    order by a.at desc, a.id desc
    limit v_limit + 1)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'at', private.wire_time(at), 'actor', actor,
           'action', action, 'testId', test_id, 'contentVersion', content_version, 'detail', detail)
           order by at desc, id desc) filter (where n <= v_limit), '[]'::jsonb),
         case when count(*) > v_limit then min(at) filter (where n <= v_limit) end
  into v_items, v_next from page;
  return jsonb_build_object('items', v_items, 'next', private.wire_time(v_next));
end
$$;

revoke all on function public.topik_admin_list(), public.topik_admin_draft_get(text),
  public.topik_admin_draft_save(text, jsonb, jsonb, boolean), public.topik_admin_draft_delete(text),
  public.topik_admin_audit(text, integer, timestamptz) from public, anon, authenticated;
grant execute on function public.topik_admin_list(), public.topik_admin_draft_get(text),
  public.topik_admin_draft_save(text, jsonb, jsonb, boolean), public.topik_admin_draft_delete(text),
  public.topik_admin_audit(text, integer, timestamptz) to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Add the names to the privileges test**

In `supabase/tests/database/04_function_privileges.sql`, the last `select is(` (a signed-in user can execute only the listed RPCs) extends its `not in (...)` list with `'topik_admin_list', 'topik_admin_draft_get', 'topik_admin_draft_save', 'topik_admin_draft_delete', 'topik_admin_audit'`.

- [ ] **Step 5: Run the tests to see them pass**

Run: `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | tail -25`
Expected: all files pass; `18_topik_master_data.sql` 32/32; `04_function_privileges.sql` 9/9.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql supabase/tests/database/04_function_privileges.sql
git commit -m "feat(supabase): DEV-394 TOPIK admin RPCs for drafts and the audit log"
```

---

### Task 4: Publish, retire, unretire, rollback, versions

**Files:**
- Modify: `supabase/migrations/20261017000000_topik_master_data.sql` (append)
- Modify: `supabase/tests/database/18_topik_master_data.sql` (append; `plan(48)`)
- Modify: `supabase/tests/database/04_function_privileges.sql` (the allowed list)

**Interfaces:**
- Produces:
  - `private.topik_media_exists(p_path text) returns boolean` (a row in `storage.objects` with `bucket_id = 'topik-media'` and `name = p_path`); Task 6 creates the bucket, this task only reads the table, which exists in every Supabase database.
  - `private.topik_publish_version(p_user uuid, p_test_id text, p_json jsonb, p_note text, p_action text, p_detail jsonb) returns integer` (the shared body of publish and rollback: inserts the version at `max + 1`, moves the publication, audits; returns the new `content_version`).
  - `public.topik_admin_publish(p_test_id text, p_expected_content_version integer, p_note text) returns jsonb` → `{"testId", "contentVersion", "catalogVersion"}`; errors `NOT_FOUND` (no draft), `VERSION_MISMATCH`, `VALIDATION_FAILED` (with the issue names in `detail`, see below), `MEDIA_MISSING`.
  - `public.topik_admin_retire(p_test_id text, p_note text)`, `public.topik_admin_unretire(p_test_id text, p_note text)` → `{"testId", "status", "catalogVersion"}`; `NOT_FOUND`, `INVALID_STATE` (already in that state).
  - `public.topik_admin_rollback(p_test_id text, p_to_version integer, p_note text)` → `{"testId", "contentVersion", "rolledBackFrom", "catalogVersion"}`; `NOT_FOUND`.
  - `public.topik_admin_versions(p_test_id text)` → `{"items": [{"contentVersion", "publishedAt", "publishedBy", "note", "checksum", "media"}]}` newest first; `public.topik_admin_version_get(p_test_id text, p_content_version integer)` → `{"contentVersion", "json", "media", "checksum", "publishedAt", "note"}` or `NOT_FOUND`.
- Rule for `VALIDATION_FAILED` detail: Postgres `raise exception` carries only the message, so publish raises `raise exception 'VALIDATION_FAILED' using detail = array_to_string(v_issues, ',')`; the Admin Web reads `details` of the PostgREST error. The test checks the message with `throws_like`.

- [ ] **Step 1: Write the failing tests** (append; still as the admin)

```sql
-- Publish, retire, unretire, rollback (§5).
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 3), '{}'::jsonb, true)->'issues',
  '["points"]'::jsonb, 'an invalid draft to publish');
select throws_like($$select public.topik_admin_publish('topik2-96-reading', 1, 'try')$$, 'VALIDATION_FAILED',
  'an invalid draft cannot be published');
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'fixed');
select throws_like($$select public.topik_admin_publish('topik2-96-reading', 2, 'try')$$, 'VERSION_MISMATCH',
  'the expected version must be max + 1 (here 1)');
select is(public.topik_admin_publish('topik2-96-reading', 1, 'first')->>'contentVersion', '1', 'published as version 1');
select is((select status from public.topik_publication where test_id = 'topik2-96-reading'), 'published', 'the publication is live');
select is(public.topik_admin_list()->'items'->0->'publication'->>'currentVersion', '1', 'the list shows it');
-- The draft is now the next version's working copy: it must say contentVersion 2.
select throws_like($$select public.topik_admin_publish('topik2-96-reading', 2, 'again')$$, 'VERSION_MISMATCH',
  'the draft still says contentVersion 1, so it cannot be published as 2');
select is(public.topik_admin_draft_save('topik2-96-reading', jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{contentVersion}', '2'), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'the draft bumped to 2');
select is(public.topik_admin_publish('topik2-96-reading', 2, 'second')->>'contentVersion', '2', 'published as version 2');
select is((select count(*) from public.topik_test_version where test_id = 'topik2-96-reading'), 2::bigint, 'two versions kept');
select is(public.topik_admin_versions('topik2-96-reading')->'items'->0->>'contentVersion', '2', 'versions newest first');
select is(public.topik_admin_version_get('topik2-96-reading', 1)->'json'->>'contentVersion', '1', 'an old version reads back');
select throws_like($$select public.topik_admin_version_get('topik2-96-reading', 9)$$, 'NOT_FOUND', 'an unknown version');
-- A listening draft whose audio object is not in Storage cannot be published.
select is(public.topik_admin_draft_save('topik2-96-listening', public.t_test('topik2', 'listening', 1, 50, 2), '{}'::jsonb, true)->'issues',
  '[]'::jsonb, 'a listening draft');
select throws_like($$select public.topik_admin_publish('topik2-96-listening', 1, 'no audio yet')$$, 'MEDIA_MISSING',
  'a referenced media object must exist in the bucket');
-- Retire, unretire.
select is(public.topik_admin_retire('topik2-96-reading', 'pulled')->>'status', 'retired', 'retired');
select throws_like($$select public.topik_admin_retire('topik2-96-reading', 'again')$$, 'INVALID_STATE', 'retiring twice');
select is(public.topik_admin_unretire('topik2-96-reading', 'back')->>'status', 'published', 'unretired');
select throws_like($$select public.topik_admin_retire('nope', 'x')$$, 'NOT_FOUND', 'retiring an unknown test');
-- Rollback is a new version with the old content.
select is(public.topik_admin_rollback('topik2-96-reading', 1, 'back to 1')->>'contentVersion', '3', 'rollback publishes version 3');
select is((select v.json->>'contentVersion' from public.topik_test_version v where v.test_id = 'topik2-96-reading' and v.content_version = 3),
  '3', 'the rolled-back content carries the new version number');
select is((select a.detail->>'rolledBackFrom' from public.topik_master_audit a where a.action = 'rollback' order by a.at desc limit 1),
  '1', 'the audit names the source version');
-- catalog_version is monotonic across every change.
select ok((select bool_and(ok) from (select catalog_version > lag(catalog_version) over (order by catalog_version) as ok
  from public.topik_publication) s), 'catalog versions increase');
```

- [ ] **Step 2: Run to see them fail**

Run as in Task 3. Expected: `function public.topik_admin_publish(text, integer, text) does not exist`.

- [ ] **Step 3: Append the functions**

```sql
-- §5: versions. A publish and a rollback share one body: the next
-- content_version, the publication moved, the audit written.
create function private.topik_media_exists(p_path text) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from storage.objects o where o.bucket_id = 'topik-media' and o.name = p_path)
$$;

create function private.topik_publish_version(p_user uuid, p_test_id text, p_json jsonb, p_note text,
  p_action text, p_detail jsonb) returns integer
language plpgsql set search_path = '' as $$
declare
  v_next integer;
  v_media jsonb;
  v_catalog bigint;
begin
  perform pg_advisory_xact_lock(hashtext('public.topik_test_version:' || p_test_id));
  select coalesce(max(content_version), 0) + 1 into v_next
  from public.topik_test_version where test_id = p_test_id;
  if (p_json->>'contentVersion')::integer <> v_next then
    raise exception 'VERSION_MISMATCH';
  end if;
  -- The media the content names: the section audio and every image.
  select coalesce(jsonb_agg(distinct x.path), '[]'::jsonb) into v_media from (
    select p_json->'assets'->>'audio' as path where p_json->'assets'->>'audio' is not null
    union all select g->'passage'->>'image' from jsonb_array_elements(coalesce(p_json->'groups', '[]'::jsonb)) g
      where g->'passage'->>'image' is not null
    union all select o->>'image' from jsonb_array_elements(coalesce(p_json->'questions', '[]'::jsonb)) q,
      jsonb_array_elements(q->'options') o where o->>'image' is not null) x;
  if exists (select 1 from jsonb_array_elements_text(v_media) m where not private.topik_media_exists(m)) then
    raise exception 'MEDIA_MISSING';
  end if;
  insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_at, published_by, note)
  values (p_test_id, v_next, p_json, v_media, md5(p_json::text), now(), p_user, p_note);
  v_catalog := nextval('public.topik_catalog_version_seq');
  insert into public.topik_publication (test_id, status, current_version, catalog_version, updated_at, updated_by)
  values (p_test_id, 'published', v_next, v_catalog, now(), p_user)
  on conflict (test_id) do update
    set status = 'published', current_version = excluded.current_version, catalog_version = excluded.catalog_version,
        updated_at = excluded.updated_at, updated_by = excluded.updated_by;
  perform private.topik_audit(p_action, p_test_id, v_next, p_detail || jsonb_build_object('note', p_note, 'catalogVersion', v_catalog));
  return v_next;
end
$$;

create function public.topik_admin_publish(p_test_id text, p_expected_content_version integer, p_note text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_topik_admin();
  v_draft public.topik_test_draft;
  v_issues text[];
  v_version integer;
begin
  select * into v_draft from public.topik_test_draft where test_id = p_test_id for update;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  if (v_draft.json->>'contentVersion')::integer is distinct from p_expected_content_version then
    raise exception 'VERSION_MISMATCH';
  end if;
  v_issues := private.topik_master_shape_issues(v_draft.json);
  if cardinality(v_issues) > 0 then
    raise exception 'VALIDATION_FAILED' using detail = array_to_string(v_issues, ',');
  end if;
  v_version := private.topik_publish_version(v_user, p_test_id, v_draft.json, p_note, 'publish', '{}'::jsonb);
  return jsonb_build_object('testId', p_test_id, 'contentVersion', v_version,
    'catalogVersion', (select catalog_version from public.topik_publication where test_id = p_test_id));
end
$$;

create function private.topik_set_status(p_user uuid, p_test_id text, p_status text, p_action text, p_note text) returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_pub public.topik_publication;
  v_catalog bigint;
begin
  select * into v_pub from public.topik_publication where test_id = p_test_id for update;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  if v_pub.status = p_status then
    raise exception 'INVALID_STATE';
  end if;
  v_catalog := nextval('public.topik_catalog_version_seq');
  update public.topik_publication set status = p_status, catalog_version = v_catalog, updated_at = now(), updated_by = p_user
  where test_id = p_test_id;
  perform private.topik_audit(p_action, p_test_id, v_pub.current_version,
    jsonb_build_object('note', p_note, 'catalogVersion', v_catalog));
  return jsonb_build_object('testId', p_test_id, 'status', p_status, 'catalogVersion', v_catalog);
end
$$;

create function public.topik_admin_retire(p_test_id text, p_note text) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  return private.topik_set_status(private.require_topik_admin(), p_test_id, 'retired', 'retire', p_note);
end
$$;

create function public.topik_admin_unretire(p_test_id text, p_note text) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  return private.topik_set_status(private.require_topik_admin(), p_test_id, 'published', 'unretire', p_note);
end
$$;

create function public.topik_admin_rollback(p_test_id text, p_to_version integer, p_note text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_topik_admin();
  v_old public.topik_test_version;
  v_next integer;
begin
  select * into v_old from public.topik_test_version where test_id = p_test_id and content_version = p_to_version;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  select coalesce(max(content_version), 0) + 1 into v_next from public.topik_test_version where test_id = p_test_id;
  v_next := private.topik_publish_version(v_user, p_test_id,
    jsonb_set(v_old.json, '{contentVersion}', to_jsonb(v_next)), p_note, 'rollback',
    jsonb_build_object('rolledBackFrom', p_to_version));
  return jsonb_build_object('testId', p_test_id, 'contentVersion', v_next, 'rolledBackFrom', p_to_version,
    'catalogVersion', (select catalog_version from public.topik_publication where test_id = p_test_id));
end
$$;

create function public.topik_admin_versions(p_test_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_topik_admin();
  return jsonb_build_object('items', coalesce((
    select jsonb_agg(jsonb_build_object('contentVersion', v.content_version,
      'publishedAt', private.wire_time(v.published_at), 'publishedBy', v.published_by, 'note', v.note,
      'checksum', v.checksum, 'media', v.media) order by v.content_version desc)
    from public.topik_test_version v where v.test_id = p_test_id), '[]'::jsonb));
end
$$;

create function public.topik_admin_version_get(p_test_id text, p_content_version integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_row public.topik_test_version;
begin
  perform private.require_topik_admin();
  select * into v_row from public.topik_test_version where test_id = p_test_id and content_version = p_content_version;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  return jsonb_build_object('contentVersion', v_row.content_version, 'json', v_row.json, 'media', v_row.media,
    'checksum', v_row.checksum, 'publishedAt', private.wire_time(v_row.published_at), 'note', v_row.note);
end
$$;

revoke all on function public.topik_admin_publish(text, integer, text), public.topik_admin_retire(text, text),
  public.topik_admin_unretire(text, text), public.topik_admin_rollback(text, integer, text),
  public.topik_admin_versions(text), public.topik_admin_version_get(text, integer) from public, anon, authenticated;
grant execute on function public.topik_admin_publish(text, integer, text), public.topik_admin_retire(text, text),
  public.topik_admin_unretire(text, text), public.topik_admin_rollback(text, integer, text),
  public.topik_admin_versions(text), public.topik_admin_version_get(text, integer) to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
```

The checksum is `md5(json::text)`, a built-in: it validates a cache copy (spec §8.3), it is not a security measure, so no extension is needed (no migration of this project uses `pgcrypto`'s `digest`).

- [ ] **Step 4: Add the six names to the privileges test** (`'topik_admin_publish', 'topik_admin_retire', 'topik_admin_unretire', 'topik_admin_rollback', 'topik_admin_versions', 'topik_admin_version_get'`).

- [ ] **Step 5: Run the tests to see them pass**

Run as in Task 3. Expected: `18_topik_master_data.sql` 48/48, `04` 9/9.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql supabase/tests/database/04_function_privileges.sql
git commit -m "feat(supabase): DEV-394 publish, retire, unretire and rollback of TOPIK Master Data, each audited"
```

---

### Task 5: Client RPCs

**Files:**
- Modify: `supabase/migrations/20261017000000_topik_master_data.sql` (append)
- Modify: `supabase/tests/database/18_topik_master_data.sql` (append; `plan(60)`)
- Modify: `supabase/tests/database/04_function_privileges.sql` (the allowed list)

**Interfaces:**
- Produces:
  - `public.topik_catalog(since bigint) returns jsonb` → `{"entries": [{"testId", "status", "catalogVersion", "contentVersion", "checksum", "media", "level", "round", "section", "titleKo", "tags": [...]}], "next": bigint, "more": boolean}`; a `retired` entry carries only `testId`, `status`, `catalogVersion`. Pages of at most 500, ordered by `catalog_version`; `next` is the last `catalog_version` of the page.
  - `public.topik_test_content(p_test_id text, p_content_version integer) returns jsonb` → the published `json`; `NOT_FOUND` unless the publication is `published` at exactly that version.
  - Tags are derived (BR-TOPIK-009), the same five names Dart derives: `explanation`, `translation` (a question's `translation` or a group's `scriptTranslation`), `words`, `grammars`, `script`.

- [ ] **Step 1: Write the failing tests** (append; the catalog is read by the plain user too)

```sql
-- §6.2: what clients read. 'topik2-96-reading' is published at version 3 (after the rollback).
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select is(jsonb_array_length(public.topik_catalog(0)->'entries'), 1, 'one publication in the catalog');
select is(public.topik_catalog(0)->'entries'->0->>'contentVersion', '3', 'at its current version');
select is(public.topik_catalog(0)->'entries'->0->>'level', 'topik2', 'with its identity fields');
select is(public.topik_catalog(0)->'entries'->0->'tags', '[]'::jsonb, 'no supporting content: no tags');
select is(public.topik_catalog(0)->>'more', 'false', 'one page');
select is(public.topik_catalog((public.topik_catalog(0)->>'next')::bigint)->'entries', '[]'::jsonb, 'nothing after the cursor');
select is(public.topik_test_content('topik2-96-reading', 3)->>'contentVersion', '3', 'the current content is served');
select throws_like($$select public.topik_test_content('topik2-96-reading', 2)$$, 'NOT_FOUND', 'a superseded version is not served');
select throws_like($$select public.topik_test_content('nope', 1)$$, 'NOT_FOUND', 'an unknown test');
-- A retirement is a tombstone in the catalog.
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_retire('topik2-96-reading', 'gone')->>'status', 'retired', 'retired again');
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select is(public.topik_catalog(0)->'entries'->0->>'status', 'retired', 'the catalog says retired');
select is(public.topik_catalog(0)->'entries'->0->'contentVersion', 'null'::jsonb, 'a retired entry carries no content');
select throws_like($$select public.topik_test_content('topik2-96-reading', 3)$$, 'NOT_FOUND', 'a retired test is not served');
-- anon cannot read either.
reset role;
set local role anon;
select throws_like($$select public.topik_catalog(0)$$, '%permission denied%', 'anon cannot read the catalog');
```

Add one paging test that publishes 501 tests? Too slow with the shape check; instead pin the page size with a direct insert into the tables as postgres before `set local role authenticated` (at the top of the file, after Task 1's inserts): insert 501 rows into `topik_test_version` and `topik_publication` for ids `topik2-1-reading` … `topik2-501-reading` with minimal JSON (`{"testId": …, "contentVersion": 1, "level": "topik2", "round": n, "section": "reading", "titleKo": "t"}`, which the tables' CHECKs accept), then as the user:

```sql
select is(jsonb_array_length(public.topik_catalog(0)->'entries'), 500, 'a page holds 500');
select is(public.topik_catalog(0)->>'more', 'true', 'and says there is more');
select is(jsonb_array_length(public.topik_catalog((public.topik_catalog(0)->>'next')::bigint)->'entries'), 2,
  'the second page holds the rest (the seeded 501st and the published test)');
```

Adjust the earlier `'one publication in the catalog'` assertions to the seeded count (they become `501`, or filter the seeded rows out by deleting them as postgres before those assertions). Keep the test readable: seed the 501 rows, assert paging, delete them, then run the publish flow of Task 4. Reorder the file accordingly.

- [ ] **Step 2: Run to see them fail**

Expected: `function public.topik_catalog(bigint) does not exist`.

- [ ] **Step 3: Append the functions**

```sql
-- §6.2: client reads. Master Data is not personal, so nothing filters by the
-- user; the grant keeps anon out, and the profile check keeps a deleted
-- user's live JWT out (DEV-192).
create function private.topik_tags(p_json jsonb) returns jsonb
language sql immutable set search_path = '' as $$
  select coalesce(jsonb_agg(t order by t), '[]'::jsonb) from (
    select 'explanation' as t where exists (select 1 from jsonb_array_elements(coalesce(p_json->'questions', '[]'::jsonb)) q where q->'explanation' is not null and jsonb_typeof(q->'explanation') <> 'null')
    union all select 'translation' where exists (select 1 from jsonb_array_elements(coalesce(p_json->'questions', '[]'::jsonb)) q where q->'translation' is not null and jsonb_typeof(q->'translation') <> 'null')
      or exists (select 1 from jsonb_array_elements(coalesce(p_json->'groups', '[]'::jsonb)) g where g->'scriptTranslation' is not null and jsonb_typeof(g->'scriptTranslation') <> 'null')
    union all select 'words' where exists (select 1 from jsonb_array_elements(coalesce(p_json->'questions', '[]'::jsonb)) q where jsonb_typeof(q->'words') = 'array' and jsonb_array_length(q->'words') > 0)
    union all select 'grammars' where exists (select 1 from jsonb_array_elements(coalesce(p_json->'questions', '[]'::jsonb)) q where jsonb_typeof(q->'grammars') = 'array' and jsonb_array_length(q->'grammars') > 0)
    union all select 'script' where exists (select 1 from jsonb_array_elements(coalesce(p_json->'groups', '[]'::jsonb)) g where coalesce(g->>'script', '') <> '')
  ) x
$$;

create function public.topik_catalog(since bigint) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_since bigint := coalesce(since, 0);
  v_limit constant integer := 500;
  v_entries jsonb;
  v_next bigint;
  v_more boolean;
begin
  perform private.require_current_profile();
  with page as (
    select p.*, v.json, v.checksum, v.media, row_number() over (order by p.catalog_version) as n
    from public.topik_publication p
    join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
    where p.catalog_version > v_since
    order by p.catalog_version
    limit v_limit + 1)
  select coalesce(jsonb_agg(case when status = 'retired'
      then jsonb_build_object('testId', test_id, 'status', status, 'catalogVersion', catalog_version)
      else jsonb_build_object('testId', test_id, 'status', status, 'catalogVersion', catalog_version,
        'contentVersion', current_version, 'checksum', checksum, 'media', media,
        'level', json->>'level', 'round', (json->>'round')::integer, 'section', json->>'section',
        'titleKo', json->>'titleKo', 'tags', private.topik_tags(json)) end
      order by catalog_version) filter (where n <= v_limit), '[]'::jsonb),
    max(catalog_version) filter (where n <= v_limit), count(*) > v_limit
  into v_entries, v_next, v_more from page;
  return jsonb_build_object('entries', v_entries, 'next', coalesce(v_next, v_since), 'more', v_more);
end
$$;

create function public.topik_test_content(p_test_id text, p_content_version integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_json jsonb;
begin
  perform private.require_current_profile();
  select v.json into v_json
  from public.topik_publication p
  join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
  where p.test_id = p_test_id and p.status = 'published' and p.current_version = p_content_version;
  if v_json is null then
    raise exception 'NOT_FOUND';
  end if;
  return v_json;
end
$$;

revoke all on function public.topik_catalog(bigint), public.topik_test_content(text, integer)
  from public, anon, authenticated;
grant execute on function public.topik_catalog(bigint), public.topik_test_content(text, integer) to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Add `'topik_catalog', 'topik_test_content'` to the privileges test's list.**

- [ ] **Step 5: Run the tests to see them pass**

Expected: `18_topik_master_data.sql` 60/60 (adjust `plan` to the count the file has after the reordering).

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql supabase/tests/database/04_function_privileges.sql
git commit -m "feat(supabase): DEV-394 topik_catalog and topik_test_content for the app"
```

---

### Task 6: The media bucket and its policies

**Files:**
- Modify: `supabase/migrations/20261017000000_topik_master_data.sql` (append)
- Modify: `supabase/tests/database/18_topik_master_data.sql` (append; `plan(68)`)
- Modify: `supabase/tests/database/04_function_privileges.sql` (the allowed list)
- Modify: `supabase/README.md` (Rules: the Storage exception; Owner setup: nothing to do by hand, the bucket is in the migration)

**Interfaces:**
- Produces: bucket `topik-media` (private); `public.topik_media_can_write(p_name text) returns boolean` (admin), `public.topik_media_can_read(p_name text) returns boolean` (the object's `{test_id}/{content_version}` prefix is a published current version); four policies on `storage.objects` for `authenticated`: select (read helper), insert / update / delete (write helper), all limited to `bucket_id = 'topik-media'`.
- Policies run with the caller's privileges, so the helpers are `security definer` and granted to `authenticated` (and listed in `04_function_privileges.sql`). They are the only `public` functions a client can call that are not RPCs the app or the Admin Web invoke directly; the README says so.

- [ ] **Step 1: Write the failing tests** (append)

```sql
-- §6.4: media. The bucket exists and is private; the helpers decide the policies.
reset role;
select is((select public from storage.buckets where id = 'topik-media'), false, 'the media bucket is private');
select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'topik_media_%'), 4::bigint, 'four policies on the bucket');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select ok(public.topik_media_can_write('topik2-96-listening/1/listening.mp3'), 'an admin may write');
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select ok(not public.topik_media_can_write('topik2-96-listening/1/listening.mp3'), 'a user may not write');
-- 'topik2-96-reading' is retired at this point of the file; unretire it as the admin first.
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_unretire('topik2-96-reading', 'for media')->>'status', 'published', 'published again');
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select ok(public.topik_media_can_read('topik2-96-reading/3/picture.png'), 'a user may read the current version''s objects');
select ok(not public.topik_media_can_read('topik2-96-reading/2/picture.png'), 'not a superseded version''s');
select ok(not public.topik_media_can_read('topik2-96-listening/1/listening.mp3'), 'not an unpublished test''s');
-- Review Focus 4: a stray object under a published prefix is readable; deliberate.
select ok(public.topik_media_can_read('topik2-96-reading/3/anything.bin'), 'any object under a published prefix reads');
```

- [ ] **Step 2: Run to see them fail**

Expected: the bucket row is missing (`is(null, false)` fails) and the helpers do not exist.

- [ ] **Step 3: Append the bucket, helpers and policies**

```sql
-- §6.4: media in a private bucket. Storage authorises through policies on
-- storage.objects, the one place a policy exists (ADR-024 #7, owner O1); the
-- policies call two security-definer helpers so they can read our tables.
insert into storage.buckets (id, name, public)
values ('topik-media', 'topik-media', false)
on conflict (id) do nothing;

create function public.topik_media_can_write(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.is_admin()
$$;

create function public.topik_media_can_read(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and (private.is_admin() or exists (
    select 1 from public.topik_publication p
    where p.status = 'published'
      and p.test_id = split_part(p_name, '/', 1)
      and p.current_version::text = split_part(p_name, '/', 2)))
$$;
revoke all on function public.topik_media_can_write(text), public.topik_media_can_read(text)
  from public, anon, authenticated;
grant execute on function public.topik_media_can_write(text), public.topik_media_can_read(text) to authenticated;

create policy topik_media_read on storage.objects for select to authenticated
  using (bucket_id = 'topik-media' and public.topik_media_can_read(name));
create policy topik_media_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'topik-media' and public.topik_media_can_write(name));
create policy topik_media_update on storage.objects for update to authenticated
  using (bucket_id = 'topik-media' and public.topik_media_can_write(name))
  with check (bucket_id = 'topik-media' and public.topik_media_can_write(name));
create policy topik_media_delete on storage.objects for delete to authenticated
  using (bucket_id = 'topik-media' and public.topik_media_can_write(name));
revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Add `'topik_media_can_write', 'topik_media_can_read'` to the privileges test's list; add to `supabase/README.md` Rules** a bullet:

```markdown
- TOPIK Master Data (ADR-024) is reached through `topik_admin_*` (an admin),
  `topik_catalog` and `topik_test_content` (everyone). Its media sits in the
  private bucket `topik-media`; Storage authorises through four policies on
  `storage.objects`, the one exception to "no policy" (owner, 2026-10-16, O1),
  each calling `topik_media_can_read` / `topik_media_can_write`, which are
  granted to `authenticated` only to serve those policies.
```

- [ ] **Step 5: Run the tests to see them pass**

Expected: `18_topik_master_data.sql` passes with its new count; `04` 9/9. If the local stack refuses `insert into storage.buckets` (a permission error), run it in the migration as is: migrations run as the `postgres` superuser on Supabase; if `supabase db reset` still fails, stop and report, the fallback is `config.toml`'s `[storage.buckets.topik-media]` section, which the owner must mirror in the dashboard.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017000000_topik_master_data.sql supabase/tests/database/18_topik_master_data.sql supabase/tests/database/04_function_privileges.sql supabase/README.md
git commit -m "feat(supabase): DEV-394 the topik-media bucket and its policies"
```

---

### Task 7: The fixture contract: Dart fixtures exported to a generated pgTAP file

**Files:**
- Create: `test/support/topik_contract_fixtures.dart` (the fixture list and the renderer)
- Create: `test/tools/topik_fixtures_export_test.dart` (the freshness gate; regenerates with `MEMOX_UPDATE_FIXTURES=1`)
- Create: `test/fixtures/topik/*.json` (generated: one valid test per level and section, one broken variant per SQL-covered rule)
- Create: `supabase/tests/database/19_topik_master_fixtures.sql` (generated)

No file under `tools/` imports `test/support/` (none does today: `rg "test/support" tools/` is empty), so the generator lives on the test side, the way goldens are updated by a flag: the test compares by default and writes when `MEMOX_UPDATE_FIXTURES=1` is set.

**Interfaces:**
- Consumes: `topikTestJson({TopikLevel level, TopikSection section, int round})` from `test/support/topik_content_fixtures.dart`; `topikContentOf(files, assetExists:)` → `TopikContentLoad` (`accepted`, `issues`) from `lib/features/topik/data/mappers/topik_content_pack_mapper.dart`, the shared pipeline, so a fixture the mapper itself refuses (a missing question) is judged the way the app judges it.
- Produces: `List<ContractFixture> topikContractFixtures()` and `Map<String, String> renderTopikContractFiles()` (path → content) in `test/support/topik_contract_fixtures.dart`. Each fixture carries `name`, `json`, `dartErrorRules` (the rule names of the error issues the pipeline reports) and `sqlRules` (the rules the SQL check must name, a subset of `dartErrorRules`). The SQL file asserts, per fixture, that `private.topik_master_shape_issues(json)` is contained in the Dart error rules (Review Focus 5) and equals `sqlRules`.

- [ ] **Step 1: Write the failing freshness test**

```dart
// test/tools/topik_fixtures_export_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/topik_contract_fixtures.dart';

// ADR-024 §7: the fixtures are the contract between the Dart validator, the
// SQL shape check and the Admin Web's TypeScript port. The committed files
// must be what the renderer writes today; MEMOX_UPDATE_FIXTURES=1 rewrites them.
void main() {
  test('the exported fixtures and the pgTAP file are fresh', () {
    final shouldWrite = Platform.environment['MEMOX_UPDATE_FIXTURES'] == '1';
    for (final MapEntry(key: path, value: content)
        in renderTopikContractFiles().entries) {
      final file = File(path);
      if (shouldWrite) {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(content);
        continue;
      }
      expect(
        file.existsSync(),
        isTrue,
        reason: '$path is missing: MEMOX_UPDATE_FIXTURES=1 flutter test test/tools/topik_fixtures_export_test.dart',
      );
      expect(file.readAsStringSync(), content, reason: '$path is stale');
    }
  });

  test('every broken fixture is an error in Dart, and the SQL rules it names are among them', () {
    for (final fixture in topikContractFixtures()) {
      expect(
        fixture.dartErrorRules,
        fixture.sqlRules.isEmpty ? isEmpty : isNotEmpty,
        reason: fixture.name,
      );
      expect(fixture.dartErrorRules, containsAll(fixture.sqlRules), reason: fixture.name);
    }
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/tools/topik_fixtures_export_test.dart`
Expected: compile error, `topik_contract_fixtures.dart` does not exist.

- [ ] **Step 3: Write the fixtures and the renderer**

```dart
// test/support/topik_contract_fixtures.dart
import 'dart:convert';

import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import 'topik_content_fixtures.dart';

/// One fixture of the contract (ADR-024 §7): a test JSON, the rules the Dart
/// pipeline reports as errors for it, and the rules the SQL shape check must
/// name (a subset of the Dart ones).
final class ContractFixture {
  ContractFixture(this.name, this.json, {required this.sqlRules})
    : dartErrorRules = {
        for (final issue in topikContentOf([
          (origin: '$name.json', json: json),
        ], assetExists: (_) => true).issues)
          if (issue.isError) issue.rule.name,
      };

  final String name;
  final Map<String, Object?> json;
  final Set<String> sqlRules;
  final Set<String> dartErrorRules;
}

Map<String, Object?> _copy(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

Map<String, Object?> _mutated(void Function(Map<String, Object?> json) edit) {
  final json = _copy(topikTestJson());
  edit(json);
  return json;
}

Map<String, Object?> _question(Map<String, Object?> json, int index) =>
    (json['questions'] as List<Object?>)[index] as Map<String, Object?>;

List<ContractFixture> topikContractFixtures() => [
  for (final level in TopikLevel.values)
    for (final section in [TopikSection.listening, TopikSection.reading])
      ContractFixture(
        '${level.code}-${section.name}-valid',
        topikTestJson(level: level, section: section),
        sqlRules: const {},
      ),
  ContractFixture(
    'identity-wrong-test-id',
    _mutated((j) => j['testId'] = 'topik2-95-reading'),
    sqlRules: const {'identity'},
  ),
  ContractFixture(
    'metadata-publisher',
    _mutated((j) => (j['source'] as Map<String, Object?>)['publishedBy'] = 'ETS'),
    sqlRules: const {'metadata'},
  ),
  ContractFixture(
    'numbering-missing-question',
    _mutated((j) => (j['questions'] as List<Object?>).removeLast()),
    sqlRules: const {'numbering', 'points', 'groups'},
  ),
  ContractFixture(
    'points-three',
    _mutated((j) => _question(j, 0)['points'] = 3),
    sqlRules: const {'points'},
  ),
  ContractFixture(
    'options-answer-5',
    _mutated((j) => _question(j, 0)['answerIdx'] = 5),
    sqlRules: const {'options'},
  ),
  ContractFixture(
    'groups-unknown-group',
    _mutated((j) => _question(j, 0)['groupId'] = 'nope'),
    sqlRules: const {'groups'},
  ),
  ContractFixture(
    'languages-missing-en',
    _mutated((j) => _question(j, 0)['explanation'] = {'vi': 'x'}),
    sqlRules: const {'languages'},
  ),
];

/// Every generated file, by its repo-relative path.
Map<String, String> renderTopikContractFiles() {
  final all = topikContractFixtures();
  const encoder = JsonEncoder.withIndent('  ');
  final files = <String, String>{
    for (final f in all) 'test/fixtures/topik/${f.name}.json': '${encoder.convert(f.json)}\n',
  };
  final sql = StringBuffer()
    ..writeln('-- GENERATED by test/tools/topik_fixtures_export_test.dart (MEMOX_UPDATE_FIXTURES=1) — DO NOT EDIT')
    ..writeln('-- ADR-024 §7: the SQL shape check is a subset of checkTopikTest on every fixture.')
    ..writeln('begin;')
    ..writeln('create extension if not exists pgtap with schema extensions;')
    ..writeln('select plan(${all.length * 2});');
  for (final f in all) {
    final json = jsonEncode(f.json).replaceAll("'", "''");
    final dart = (f.dartErrorRules.toList()..sort()).join(',');
    final rules = (f.sqlRules.toList()..sort()).join(',');
    sql
      ..writeln("select ok(private.topik_master_shape_issues('$json'::jsonb) <@ '{$dart}'::text[],")
      ..writeln("  '${f.name}: the SQL rules are among the Dart errors');")
      ..writeln("select is(private.topik_master_shape_issues('$json'::jsonb), '{$rules}'::text[],")
      ..writeln("  '${f.name}: the SQL rules are exactly ${rules.isEmpty ? 'none' : rules}');");
  }
  sql
    ..writeln('select * from finish();')
    ..writeln('rollback;');
  files['supabase/tests/database/19_topik_master_fixtures.sql'] = sql.toString();
  return files;
}
```

If `TopikSection.name` is not the code the test ids use (`listening`, `reading`), use `section.code`, which `topikTestJson` uses for `testId`.

- [ ] **Step 4: Generate, then run both test suites**

Run: `MEMOX_UPDATE_FIXTURES=1 flutter test test/tools/topik_fixtures_export_test.dart && flutter test test/tools/topik_fixtures_export_test.dart && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase db reset && SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx supabase test db 2>&1 | grep -E "19_topik|Result"`
Expected: 11 JSON files and the SQL file written; the Dart tests pass; `19_topik_master_fixtures.sql` passes 22/22. If a fixture's second assertion fails because the SQL names a rule Dart does not, the SQL check of Task 2 is wrong: fix it there. If Dart names more rules than `sqlRules` for a fixture, that is allowed (the first assertion) and expected (`numbering-missing-question`).

- [ ] **Step 5: Run the gate on the change**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed`
Expected: green; the architecture guard accepts a test-support file importing the mapper (the content lint already does).

- [ ] **Step 6: Commit**

```bash
git add test/support/topik_contract_fixtures.dart test/tools/topik_fixtures_export_test.dart test/fixtures/topik supabase/tests/database/19_topik_master_fixtures.sql
git commit -m "test(supabase): DEV-394 the fixture contract between checkTopikTest and the SQL shape check"
```

---

### Task 8: Documents and the ledger

**Files:**
- Modify: `supabase/README.md` (Rules bullet from Task 6 if not yet; the Storage limits line of spec §6.4 under Owner setup)
- Modify: `docs/shared/data/schema.md` (a short "Server: TOPIK Master Data" note pointing at the spec; the Drift tables are unchanged by this plan)
- Modify: `docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md` (§10 row 1: "built, PR n")
- Linear: a comment on DEV-394 (the epic) with the evidence; no new sub-issue (the 250-issue cap)

- [ ] **Step 1: Write the README additions** (Owner setup, after step 6)

```markdown
7. TOPIK Master Data (ADR-024) needs nothing by hand: the migration creates
   the tables, the RPCs and the private bucket `topik-media`. The Free plan
   holds 1 GB of storage and 5 GB of egress a month; one round's media is
   tens of MB. The `supabase usage` workflow reports the storage size too.
```

- [ ] **Step 2: Run the docs guard and the full gate**

Run: `python3 tools/docs/check.py && bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: PASS; every gate green.

- [ ] **Step 3: Commit, push, comment on Linear**

```bash
git add supabase/README.md docs/shared/data/schema.md docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md
git commit -m "docs(supabase): DEV-394 TOPIK Master Data store in the README, schema notes and the spec's ledger"
git push -u origin <branch>
```

The Linear comment follows `linear-templates.md` (Done template once merged: PR, merge commit, `dod_check.sh` count, `supabase test db` count, check degrade: `04_function_privileges`, `15_sync_entity_dispatch` untouched and green; check similar: no other table with policies, no other admin RPC family; state & transition: not applicable, no screen).

---

## Self-review

- **Spec coverage:** §5 tables and rules (Tasks 1, 4), §6.1 admin RPCs (Tasks 3, 4), §6.2 client RPCs (Task 5), §6.3 shape checks (Task 2), §6.4 media (Task 6), §7 fixtures (Task 7), §10 row 1 and §11 O1/O4/O6 (Tasks 4, 6). §8 (app) and §9 (Admin Web) are plans 2 and 3, out of this plan by design.
- **Placeholders:** none; every SQL and Dart body is written. One conditional instruction remains (`TopikSection.name` vs `.code` in Task 7) with the exact alternative.
- **Type consistency:** `topik_master_shape_issues(jsonb) returns text[]` is used in Tasks 2, 3, 4, 7 with that signature; `renderTopikContractFiles()` and `topikContractFixtures()` are named the same in Task 7's two files; `private.topik_audit(text, text, integer, jsonb)` in Tasks 3 and 4; `topik_publish_version(uuid, text, jsonb, text, text, jsonb) returns integer` in Task 4 twice; catalog entry keys in Task 5 match spec §6.2.
- **Review Focus:** 1 → Task 4 (`VERSION_MISMATCH` tests), 2 → Task 5 (501-row paging), 3 → Task 5 (superseded and retired `NOT_FOUND`), 4 → Task 6 (stray object readable, pinned), 5 → Task 7 (subset assertion per fixture).
