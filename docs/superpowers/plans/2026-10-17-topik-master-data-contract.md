# TOPIK Master Data Contract Additions Implementation Plan (PR-02)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the server half of ADR-025 on top of the pushed Master Data store:
- the admin-only read gate;
- the catalog's `schemaVersion`, `sha256` and `bytes`;
- the content envelope;
- media named by their SHA-256;
- a publish dry run;
- optimistic locking on drafts;
- a document size ceiling and bucket limits.

All of it is pinned by pgTAP.

**Architecture:** One **new** migration, `supabase/migrations/20261017120000_topik_master_contract.sql`, is written task by task. It stays unpushed until merge, so editing it between tasks is allowed.

The pushed migration `20261016120000_topik_master_data.sql` is never edited (`supabase/README.md` rule). Instead, its functions are replaced with `create or replace`, or with `drop` + `create` when a signature changes.

New behaviour is proven in a new pgTAP file, `supabase/tests/database/20_topik_master_contract.sql`. The existing `18_topik_master_data.sql` keeps its 282 assertions, with three kinds of edit:
- it opens the read gate inside its own transaction, so it keeps proving the read paths as they will be once the owner lifts the gate;
- it uses SHA-256 media names;
- its catalog entry and content assertions follow the new shapes.

No Flutter, no Drift and no Admin Web code is in this plan.

**Tech Stack:** Supabase Postgres (PL/pgSQL, jsonb, `pg_catalog.sha256`), Supabase Storage, and pgTAP. pgTAP runs through `tools/supabase/image_pgtap.sh`, the local runner of this container; the workflow's `supabase test db` on the full CLI stack is the reference.

**Spec:** `docs/superpowers/specs/2026-10-17-topik-master-data-decision-package.md`. The relevant parts:
- §4.7 candidate DDL;
- §5.7 the pipeline;
- §6 security;
- §7.1–§7.2 catalog and manifest;
- §11 PR-02;
- §12: DR-05, DR-06, DR-09, DR-10, DR-14, DR-21, DR-22.

It also argues from `docs/shared/decisions/ADR-025-ghim-luot-dang-lam-vao-phien-ban-noi-dung-topik.md` (rows 4 and 5) and from `docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md` §5–§6 (the shipped contract).

**Linear:** the new epic could not be created: the workspace hit the Free plan's 250-issue cap on 2026-10-17. Progress is recorded on DEV-394, as on 2026-10-15, until the owner frees slots. Commits name `DEV-394`.

## Global Constraints

- Only one migration file is created, `supabase/migrations/20261017120000_topik_master_contract.sql`. No other file under `supabase/migrations/` is touched.
- Every function in `public` that clients call is `security definer set search_path = ''`, followed by `revoke all on function … from public, anon, authenticated; grant execute on function … to authenticated;`. The migration ends with `revoke all on all functions in schema private from public, anon, authenticated;`.
- Every new `public` RPC name joins the allowed list in `supabase/tests/database/04_function_privileges.sql`. The one name this plan adds is `topik_admin_check`.
- Errors are bare codes, raised with `raise exception '<CODE>'` and context in `using detail = …`. The codes are `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_FAILED`, `VERSION_MISMATCH`, `MEDIA_MISSING`, `INVALID_STATE`, `NOT_AUTHENTICATED` and `UNAUTHORIZED`. Never SQL text (BR-CORE-005).
- The read gate is the function `private.topik_can_read_content()`, and its body is `select private.is_admin()` (ADR-025 #5, owner 2026-10-17). Every read of published content goes through it: `topik_catalog`, `topik_test_content` and `topik_media_can_read`.
- When the gate is closed, the catalog returns exactly `{"entries": [], "next": <since or 0>, "more": false}`.
- The media file name rule is `^[0-9a-f]{64}\.(mp3|jpg|jpeg|png|webp)$` on the third path segment, with no fourth segment (ADR-025 #4).
- The document hash is `encode(pg_catalog.sha256(convert_to(json::text, 'UTF8')), 'hex')`, computed when served. Nothing new is stored on `topik_test_version`, which is immutable.
- The document size ceiling is `4194304` bytes (`octet_length(json::text)`). Bucket limits are `file_size_limit = 52428800` and `allowed_mime_types = {audio/mpeg, image/jpeg, image/png, image/webp}`.
- Master Data is not a sync entity: `private.push_one`, `private.apply_operation`, `private.current_change`, `public.sync_changes` and test `15_sync_entity_dispatch.sql` are not touched.
- `19_topik_master_fixtures.sql` and the Dart fixture contract are not touched (shape rules do not change).
- Nothing pushes to the project. After merge, the `supabase migrations` workflow (push on `supabase/migrations/**`) runs pgTAP on the real stack and then `db push`.
- Commit messages are `feat(supabase): DEV-394 …` or `test(supabase): DEV-394 …` / `docs(supabase): DEV-394 …`, with the session's attribution lines.
- The pgTAP runner is `bash tools/supabase/image_pgtap.sh <file…>`. If the Docker daemon is down, start it with `dockerd > /tmp/dockerd.log 2>&1 &` and wait about 5 s.

## Review Focus

1. **A catalog entry whose media has a `size` Storage never recorded (JSON null).** `bytes` must still be a number; null sizes count 0. Pinned in Task 1 (`topik2-95-listening`).
2. **Korean text in the document** (`titleKo`, `form`). The hash must be over the UTF-8 bytes of the served text, the same bytes a client hashes. Pinned in Task 1: `t_listening` carries `제96회` and `B-홀수형`, and the test recomputes the SHA-256 over `convert_to(document, 'UTF8')`.
3. **A revision published before this migration with a non-hash media name.** Its rollback is refused with `VALIDATION_FAILED` / `media`. This is deliberate: the name rule applies to every publish, and the repository shows no published content yet. Pinned in Task 2 (`topik2-94-listening`).
4. **A learner's device once the owner lifts the gate.** Its cursor stayed at 0, so the next refresh pulls everything. Pinned by `18_topik_master_data.sql`, which runs with the gate open and asserts the full pull from 0. Task 1 also pins that a closed gate keeps any cursor.
5. **Two draft saves in one transaction, or less than a millisecond apart.** Each must get a distinct `updatedAt`, or the compare-and-set cannot tell them apart. `updated_at` therefore takes `clock_timestamp()`. Pinned in Task 3.

---

### Task 1: Read gate, catalog compatibility keys, content envelope (DR-14, DR-05, DR-06)

**Files:**
- Create: `supabase/migrations/20261017120000_topik_master_contract.sql`
- Create: `supabase/tests/database/20_topik_master_contract.sql`
- Modify: `supabase/tests/database/18_topik_master_data.sql`. Three edits: open the gate after `select plan(282);` at line 4; the catalog entry literal at lines 516-519; the checksum line at lines 520-521.

**Interfaces:**
- Produces:
  - `private.topik_can_read_content() returns boolean` (stable);
  - `private.topik_document_sha256(p_json jsonb) returns text` (stable, 64 lowercase hex);
  - `public.topik_catalog(since bigint)`, whose published entries add `schemaVersion` (integer), `sha256` (text) and `bytes` (bigint);
  - `public.topik_test_content(p_test_id text, p_content_version integer)`, which now returns `{testId, contentVersion, schemaVersion, sha256, document}` with `document` the stored JSON as text;
  - `public.topik_media_can_read(p_name text)`, which requires the gate for non-admins.
- Test helpers created in `20_…` and reused by later tasks: `public.t_as(text)`, `public.t_detail(text)`, `public.t_listening(text)`, and the constant path form `<test_id>/<version>/<64 hex>.mp3`.

- [ ] **Step 1: Write the failing pgTAP test**

Create `supabase/tests/database/20_topik_master_contract.sql`:

```sql
-- supabase/tests/database/20_topik_master_contract.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);
-- ADR-025 (owner 2026-10-17), decision package 2026-10-17 §11 PR-02: the read gate
-- (admins only for now, #5), the catalog's compatibility and integrity keys and the
-- content envelope (#4; DR-05, DR-06). 18_topik_master_data.sql runs with the gate open.

insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@example.com', false),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'user@example.com', false),
  ('dddddddd-0000-0000-0000-000000000004', null, true)
on conflict (id) do nothing;
update public.profiles set role = 'admin' where id = 'aaaaaaaa-0000-0000-0000-000000000001';

create function public.t_as(p_user text) returns void language sql as $$
  select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', p_user), true) $$;
-- The DETAIL of the error a statement raises (PostgREST hands it to clients as `details`).
create function public.t_detail(p_sql text) returns text language plpgsql as $$
declare v_detail text;
begin
  execute p_sql;
  return null;
exception when others then
  get stacked diagnostics v_detail = pg_exception_detail;
  return v_detail;
end $$;
-- A valid TOPIK II listening section (50 questions of 2 points, one group each) whose
-- audio is named by a SHA-256 under version 1: {test_id}/1/<64 x 'a'>.mp3.
create function public.t_listening(p_test_id text) returns jsonb language sql as $$
  select jsonb_build_object(
    'schemaVersion', 1, 'contentVersion', 1,
    'testId', p_test_id, 'level', 'topik2', 'round', split_part(p_test_id, '-', 2)::integer, 'section', 'listening',
    'format', 'pbt', 'form', 'B-홀수형', 'titleKo', '제96회', 'officialTimeLimitSec', 3600,
    'source', jsonb_build_object('publishedBy', 'NIIED', 'url', 'https://www.topik.go.kr/x'),
    'assets', jsonb_build_object('audio', p_test_id || '/1/' || repeat('a', 64) || '.mp3'),
    'groups', (select jsonb_agg(jsonb_build_object('groupId', 'g' || n, 'instructionKo', '※',
        'questionNos', jsonb_build_array(n),
        'audio', jsonb_build_object('startMs', 0, 'endMs', 1000, 'playCount', 2)))
      from generate_series(1, 50) n),
    'questions', (select jsonb_agg(jsonb_build_object('no', n, 'groupId', 'g' || n, 'questionType', 'X',
        'points', 2, 'stemKo', 'q',
        'options', jsonb_build_array(jsonb_build_object('idx', 1, 'textKo', 'a'),
          jsonb_build_object('idx', 2, 'textKo', 'b'), jsonb_build_object('idx', 3, 'textKo', 'c'),
          jsonb_build_object('idx', 4, 'textKo', 'd')),
        'answerIdx', 1))
      from generate_series(1, 50) n)) $$;

-- Storage objects are written by the storage service: postgres here. One with size and
-- eTag, one without metadata (the local stub can; hosted Storage always records both).
insert into storage.objects (bucket_id, name, metadata) values
  ('topik-media', 'topik2-96-listening/1/' || repeat('a', 64) || '.mp3', '{"size": 3, "eTag": "\"abc\""}');
insert into storage.objects (bucket_id, name) values
  ('topik-media', 'topik2-95-listening/1/' || repeat('a', 64) || '.mp3');

set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_draft_save('topik2-96-listening', public.t_listening('topik2-96-listening'),
  '{}'::jsonb, true)->'issues', '[]'::jsonb, 'a valid listening draft');
select is(public.topik_admin_publish('topik2-96-listening', 1, 'one')->>'contentVersion', '1', 'published as 1');

-- The gate is closed for a learner: an empty page that keeps the cursor, no content, no media.
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select is(public.topik_catalog(0)->'entries', '[]'::jsonb, 'a learner reads an empty catalog while the gate is closed');
select is(public.topik_catalog(0)->>'next', '0', 'which keeps the cursor');
select is(public.topik_catalog(7)->>'next', '7', 'at any cursor');
select is(public.topik_catalog(0)->>'more', 'false', 'with nothing more to pull');
select throws_like($$select public.topik_test_content('topik2-96-listening', 1)$$, 'NOT_FOUND',
  'a learner is not served the content');
select ok(not public.topik_media_can_read('topik2-96-listening/1/' || repeat('a', 64) || '.mp3'),
  'nor may read its media');
select is((select count(*) from storage.objects where bucket_id = 'topik-media'), 0::bigint,
  'and sees no object through the read policy');
select public.t_as('dddddddd-0000-0000-0000-000000000004');
select is(public.topik_catalog(0)->'entries', '[]'::jsonb, 'an anonymous sign-in reads an empty catalog too');

-- An admin reads the catalog, with the compatibility and integrity keys.
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(jsonb_array_length(public.topik_catalog(0)->'entries'), 1, 'an admin reads the catalog');
select is(public.topik_catalog(0)->'entries'->0->>'schemaVersion', '1', 'an entry names its schemaVersion');
select is(public.topik_catalog(0)->'entries'->0->>'sha256',
  public.topik_test_content('topik2-96-listening', 1)->>'sha256', 'the catalog and the content agree on the hash');
select is(public.topik_test_content('topik2-96-listening', 1)->>'sha256',
  encode(sha256(convert_to(public.topik_test_content('topik2-96-listening', 1)->>'document', 'UTF8')), 'hex'),
  'which is the SHA-256 of the UTF-8 bytes of the document served (Korean text included)');
select is((public.topik_catalog(0)->'entries'->0->>'bytes')::bigint,
  octet_length(public.topik_test_content('topik2-96-listening', 1)->>'document')::bigint + 3,
  'bytes is the document plus the sizes of its media');
select is((select array_agg(k order by k) from jsonb_object_keys(public.topik_test_content('topik2-96-listening', 1)) k),
  '{contentVersion,document,schemaVersion,sha256,testId}'::text[], 'the content is an envelope');
select is((public.topik_test_content('topik2-96-listening', 1)->>'document')::jsonb,
  public.topik_admin_version_get('topik2-96-listening', 1)->'json', 'whose document is the stored version');
select is(md5(public.topik_test_content('topik2-96-listening', 1)->>'document'),
  public.topik_catalog(0)->'entries'->0->>'checksum', 'and the md5 checksum still matches the document');
select ok(public.topik_media_can_read('topik2-96-listening/1/' || repeat('a', 64) || '.mp3'), 'an admin reads the media');

-- Review Focus 1: a media file without a recorded size counts 0 in bytes.
select is(public.topik_admin_draft_save('topik2-95-listening', public.t_listening('topik2-95-listening'),
  '{}'::jsonb, true)->'issues', '[]'::jsonb, 'a second draft whose audio has no recorded size');
select is(public.topik_admin_publish('topik2-95-listening', 1, 'one')->>'contentVersion', '1', 'published');
select is((select (e->>'bytes')::bigint from jsonb_array_elements(public.topik_catalog(0)->'entries') e
           where e->>'testId' = 'topik2-95-listening'),
  octet_length(public.topik_test_content('topik2-95-listening', 1)->>'document')::bigint,
  'a null size adds nothing to bytes');

reset role;
select ok(not has_function_privilege('authenticated', 'private.topik_can_read_content()', 'execute'),
  'the gate is not callable by clients');

select * from finish();
rollback;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/supabase/image_pgtap.sh supabase/tests/database/20_topik_master_contract.sql`

Expected: FAIL. The learner reads the published entry (assertion 3 fails), `schemaVersion` is absent, and `topik_test_content(...)->>'sha256'` is null.

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20261017120000_topik_master_contract.sql`:

```sql
-- supabase/migrations/20261017120000_topik_master_contract.sql
-- ADR-025 (owner 2026-10-17), decision package 2026-10-17 §11 PR-02: additions to the
-- TOPIK Master Data contract of 20261016120000_topik_master_data.sql. That migration is
-- pushed and never edited; this one replaces its functions and adds constraints.

-- ============================================================================
-- Who reads published content (ADR-025 #5, DR-14): admins only, for now
-- ============================================================================

-- The one gate for every read of published Master Data: the catalog, the content and
-- the media read policy. Admins only until the owner rules otherwise (redistribution of
-- NIIED papers is not established). Lifting it is a migration that replaces this body;
-- devices then pull everything from cursor 0, which a closed gate kept them at.
create function private.topik_can_read_content() returns boolean
language sql stable set search_path = '' as $$
  select private.is_admin()
$$;

-- ============================================================================
-- Integrity and compatibility of what is served (ADR-025 #4; DR-05, DR-06)
-- ============================================================================

-- The SHA-256 of a version's JSON exactly as served (jsonb's text form, UTF-8 bytes),
-- in lowercase hex. A client hashes the `document` string it receives and compares.
create function private.topik_document_sha256(p_json jsonb) returns text
language sql stable set search_path = '' as $$
  select encode(pg_catalog.sha256(convert_to(p_json::text, 'UTF8')), 'hex')
$$;

-- The catalog of 20261016120000, behind the gate and with three more keys per published
-- entry: schemaVersion (an older app skips what it cannot read), sha256 (of the document
-- served by topik_test_content) and bytes (the document plus the media sizes Storage
-- recorded; a size it did not record counts 0).
create or replace function public.topik_catalog(since bigint) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_since bigint := coalesce(since, 0);
  v_limit constant integer := 500;
  v_entries jsonb;
  v_next bigint;
  v_more boolean;
begin
  perform private.require_current_profile();
  -- Not a reader yet (ADR-025 #5): an empty page that keeps the cursor, so the device
  -- stores nothing, logs nothing and pulls everything once the gate opens.
  if not private.topik_can_read_content() then
    return jsonb_build_object('entries', '[]'::jsonb, 'next', v_since, 'more', false);
  end if;
  with page as (
    select p.test_id, p.status, p.current_version, p.catalog_version, v.json, v.checksum, v.media,
      row_number() over (order by p.catalog_version) as n
    from public.topik_publication p
    join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
    where p.catalog_version > v_since
    order by p.catalog_version
    limit v_limit + 1)
  select coalesce(jsonb_agg(case when page.status = 'retired'
      then jsonb_build_object('testId', page.test_id, 'status', page.status, 'catalogVersion', page.catalog_version)
      else jsonb_build_object('testId', page.test_id, 'status', page.status, 'catalogVersion', page.catalog_version,
        'contentVersion', page.current_version, 'checksum', page.checksum, 'media', page.media,
        'level', page.json->>'level', 'round', (page.json->>'round')::integer, 'section', page.json->>'section',
        'titleKo', page.json->>'titleKo', 'tags', private.topik_tags(page.json),
        'schemaVersion', (page.json->>'schemaVersion')::integer,
        'sha256', private.topik_document_sha256(page.json),
        'bytes', octet_length(page.json::text)::bigint
          + coalesce((select sum((m->>'size')::bigint) from jsonb_array_elements(page.media) m), 0)) end
      order by page.catalog_version) filter (where page.n <= v_limit), '[]'::jsonb),
    max(page.catalog_version) filter (where page.n <= v_limit),
    count(*) > v_limit
  into v_entries, v_next, v_more from page;
  return jsonb_build_object('entries', v_entries, 'next', coalesce(v_next, v_since), 'more', v_more);
end
$$;

-- The content of 20261016120000 behind the gate, as an envelope: the document is the
-- stored JSON as text, the exact bytes `sha256` hashes, so a client verifies it before
-- it parses it. NOT_FOUND for anything not current or not readable, as before.
create or replace function public.topik_test_content(p_test_id text, p_content_version integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_json jsonb;
begin
  perform private.require_current_profile();
  if not private.topik_can_read_content() then
    raise exception 'NOT_FOUND';
  end if;
  select v.json into v_json
  from public.topik_publication p
  join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
  where p.test_id = p_test_id and p.status = 'published' and p.current_version = p_content_version;
  if v_json is null then
    raise exception 'NOT_FOUND';
  end if;
  return jsonb_build_object('testId', p_test_id, 'contentVersion', p_content_version,
    'schemaVersion', (v_json->>'schemaVersion')::integer,
    'sha256', private.topik_document_sha256(v_json), 'document', v_json::text);
end
$$;

revoke all on function public.topik_catalog(bigint), public.topik_test_content(text, integer)
  from public, anon, authenticated;
grant execute on function public.topik_catalog(bigint), public.topik_test_content(text, integer) to authenticated;

-- The read policy's helper of 20261016120000, behind the gate for everyone but an admin.
create or replace function public.topik_media_can_read(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles pr where pr.id = auth.uid())
    and (private.is_admin() or (private.topik_can_read_content() and exists (
      select 1 from public.topik_publication p
      join public.topik_test_version v on v.test_id = p.test_id
      where p.status = 'published'
        and p.test_id = split_part(p_name, '/', 1)
        and v.content_version::text = split_part(p_name, '/', 2))))
$$;
revoke all on function public.topik_media_can_read(text) from public, anon, authenticated;
grant execute on function public.topik_media_can_read(text) to authenticated;

-- ============================================================================
-- Function privileges (keep last)
-- ============================================================================

revoke all on all functions in schema private from public, anon, authenticated;
```

- [ ] **Step 4: Open the gate in test 18 and follow the new shapes**

Edit `supabase/tests/database/18_topik_master_data.sql` in three places.

(a) Directly after the line `select plan(282);` (line 4), insert:

```sql
-- 18 proves the read paths as they will be once the owner opens the read gate
-- (ADR-025 #5); 20_topik_master_contract.sql proves the gate as it ships (admins only).
create or replace function private.topik_can_read_content() returns boolean
language sql stable set search_path = '' as $$ select true $$;
```

(b) Replace:

```sql
select is((public.topik_catalog(0)->'entries'->0) - 'catalogVersion' - 'checksum',
```

with:

```sql
select is((public.topik_catalog(0)->'entries'->0) - 'catalogVersion' - 'checksum' - 'sha256' - 'bytes',
```

Then, in the literal of the same assertion, replace `"tags": []}'::jsonb,` with `"tags": [], "schemaVersion": 1}'::jsonb,`.

(c) Replace:

```sql
  md5(public.topik_test_content('topik2-96-listening', 1)::text), 'and the checksum of the stored json');
```

with:

```sql
  md5(public.topik_test_content('topik2-96-listening', 1)->>'document'), 'and the checksum of the stored json');
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tools/supabase/image_pgtap.sh supabase/tests/database/18_topik_master_data.sql supabase/tests/database/20_topik_master_contract.sql supabase/tests/database/04_function_privileges.sql`

Expected: `18` ok (282), `20` ok (23), `04` ok (9).

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017120000_topik_master_contract.sql \
  supabase/tests/database/20_topik_master_contract.sql supabase/tests/database/18_topik_master_data.sql
git commit -m "feat(supabase): DEV-394 admin-only read gate, catalog schemaVersion/sha256/bytes, content envelope (ADR-025)"
```

---

### Task 2: Content-addressed media names and the publish dry run (DR-21, DR-10)

**Files:**
- Modify: `supabase/migrations/20261017120000_topik_master_contract.sql`. Insert before the "Function privileges (keep last)" block.
- Modify: `supabase/tests/database/20_topik_master_contract.sql`. Plan 23 → 48; insert before the final `reset role;`.
- Modify: `supabase/tests/database/18_topik_master_data.sql` (media names; the sorted literal near line 737).
- Modify: `supabase/tests/database/04_function_privileges.sql` (allowed list).

**Interfaces:**
- Consumes: the Task 1 helpers `t_as`, `t_detail` and `t_listening`.
- Produces:
  - `private.topik_media_paths(p_json jsonb) returns text[]` (distinct, sorted);
  - `private.topik_media_path_ok(p_test_id text, p_next integer, p_path text) returns boolean`;
  - `private.topik_publish_version(...)`, same signature, now using both;
  - `public.topik_admin_check(p_test_id text) returns jsonb`, shaped `{testId, nextContentVersion, draftContentVersion, status, issues[], mediaInvalid[], mediaMissing[], ready}`.

- [ ] **Step 1: Write the failing tests**

In `20_topik_master_contract.sql`, change `select plan(23);` to `select plan(48);`. Then insert this block directly before the final `reset role;` (the one preceding the `has_function_privilege` assertion):

```sql
-- ============================================================================
-- Media named by their SHA-256 (ADR-025 #4, DR-21)
-- ============================================================================
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}', '"topik2-97-listening/1/x.mp3"'), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'a file not named by its SHA-256 is refused');
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}',
    to_jsonb('topik2-97-listening/1/' || repeat('A', 64) || '.mp3')), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'uppercase hex is refused');
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}',
    to_jsonb('topik2-97-listening/1/' || repeat('a', 64) || '.exe')), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'an extension content does not use is refused');
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}',
    to_jsonb('topik2-97-listening/1/' || repeat('a', 64) || '.mp3/x')), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'a path with a fourth segment is refused');

-- ============================================================================
-- The publish dry run (DR-10)
-- ============================================================================
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select throws_like($$select public.topik_admin_check('topik2-97-listening')$$, 'FORBIDDEN', 'a learner cannot run the check');
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select throws_like($$select public.topik_admin_check('nope')$$, 'NOT_FOUND', 'the check needs a draft');
-- A well-named file Storage does not hold yet.
select public.topik_admin_draft_save('topik2-97-listening', public.t_listening('topik2-97-listening'), '{}'::jsonb, false);
select is(public.topik_admin_check('topik2-97-listening')->'mediaMissing',
  jsonb_build_array('topik2-97-listening/1/' || repeat('a', 64) || '.mp3'), 'the check lists the missing media');
select is(public.topik_admin_check('topik2-97-listening')->'mediaInvalid', '[]'::jsonb, 'and nothing badly named');
select is(public.topik_admin_check('topik2-97-listening')->'issues', '[]'::jsonb, 'and no shape issue');
select is(public.topik_admin_check('topik2-97-listening')->>'ready', 'false', 'so the draft is not ready');
select is(public.topik_admin_check('topik2-97-listening')->>'nextContentVersion', '1', 'and would publish as 1');
select is(public.topik_admin_check('topik2-97-listening')->'status', 'null'::jsonb, 'a test never published has no status');
select is(public.topik_admin_versions('topik2-97-listening')->'items', '[]'::jsonb, 'the check stored no version');
select is((select count(*) from jsonb_array_elements(public.topik_admin_audit('topik2-97-listening', 200, null)->'items') i
           where i->>'action' not like 'draft%'), 0::bigint, 'and wrote no audit row');
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$),
  'topik2-97-listening/1/' || repeat('a', 64) || '.mp3', 'a well-named file Storage lacks is MEDIA_MISSING, as the check said');
-- A badly named file.
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}', '"topik2-97-listening/1/x.mp3"'), '{}'::jsonb, false);
select is(public.topik_admin_check('topik2-97-listening')->'mediaInvalid',
  '["topik2-97-listening/1/x.mp3"]'::jsonb, 'the check lists a badly named file');
select is(public.topik_admin_check('topik2-97-listening')->'mediaMissing', '[]'::jsonb, 'and does not also call it missing');
-- With its media in Storage the draft is ready, and publishes.
select public.topik_admin_draft_save('topik2-97-listening', public.t_listening('topik2-97-listening'), '{}'::jsonb, false);
reset role;
insert into storage.objects (bucket_id, name, metadata) values
  ('topik-media', 'topik2-97-listening/1/' || repeat('a', 64) || '.mp3', '{"size": 4, "eTag": "\"e\""}');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_check('topik2-97-listening')->>'ready', 'true', 'with its media in Storage the draft is ready');
select is(public.topik_admin_publish('topik2-97-listening', 1, 'one')->>'contentVersion', '1', 'and publishes');
select is(public.topik_admin_check('topik2-97-listening')->>'ready', 'false',
  'a draft that still says the published version is not ready');
select is(public.topik_admin_check('topik2-97-listening')->>'nextContentVersion', '2', 'the next version is 2');
select is(public.topik_admin_retire('topik2-97-listening', 'gone')->>'status', 'retired', 'retired');
select is(public.topik_admin_check('topik2-97-listening')->>'status', 'retired', 'the check names a retired test');

-- Review Focus 3: a revision published before the name rule (a direct insert stands in
-- for it) is refused on rollback, like any publish of a badly named file.
reset role;
insert into public.topik_test_version (test_id, content_version, json, media, checksum)
values ('topik2-94-listening', 1,
  jsonb_set(public.t_listening('topik2-94-listening'), '{assets,audio}', '"topik2-94-listening/1/a.mp3"'), '[]'::jsonb, 'x');
insert into public.topik_publication (test_id, status, current_version, catalog_version)
values ('topik2-94-listening', 'published', 1, private.topik_next_catalog_version());
insert into storage.objects (bucket_id, name) values
  ('topik-media', 'topik2-94-listening/1/' || repeat('a', 64) || '.mp3');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select public.topik_admin_draft_save('topik2-94-listening',
  jsonb_set(public.t_listening('topik2-94-listening'), '{contentVersion}', '2'), '{}'::jsonb, false);
select is(public.topik_admin_publish('topik2-94-listening', 2, 'two')->>'contentVersion', '2',
  'a well-named revision publishes over the old one');
select is(public.t_detail($$select public.topik_admin_rollback('topik2-94-listening', 1, 'back')$$), 'media',
  'a rollback to a revision with a non-hash media name is refused');
```

Count: 4 (names) + 19 (check) + 2 (legacy) = 25 new assertions; 23 + 25 = 48.

In `supabase/tests/database/04_function_privileges.sql`, add `'topik_admin_check'` to the allowed list right after `'topik_admin_version_get'`. The line becomes:

```sql
       'topik_admin_unretire', 'topik_admin_rollback', 'topik_admin_versions', 'topik_admin_version_get', 'topik_admin_check',
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tools/supabase/image_pgtap.sh supabase/tests/database/20_topik_master_contract.sql supabase/tests/database/04_function_privileges.sql`

Expected: FAIL. `topik2-97-listening/1/x.mp3` publishes past the old path contract, so the detail is not `media`. `topik_admin_check` does not exist. `04` still passes, because the list only allows names.

- [ ] **Step 3: Add the helpers, the new publish body and the check to the migration**

Insert into `20261017120000_topik_master_contract.sql`, before the "Function privileges (keep last)" block:

```sql
-- ============================================================================
-- Media named by their SHA-256 (ADR-025 #4, DR-21) and the publish dry run (DR-10)
-- ============================================================================

-- The media a content names: the section audio and every image, distinct, sorted
-- (the order publish reports the first missing one in, and the media array's order).
create function private.topik_media_paths(p_json jsonb) returns text[]
language sql stable set search_path = '' as $$
  select coalesce(array_agg(distinct x.path order by x.path), '{}'::text[])
  from (
    select p_json->'assets'->>'audio' as path
    union all
    select g->'passage'->>'image'
    from jsonb_array_elements(case when jsonb_typeof(p_json->'groups') = 'array' then p_json->'groups' else '[]'::jsonb end) g
    union all
    select o->>'image'
    from jsonb_array_elements(case when jsonb_typeof(p_json->'questions') = 'array' then p_json->'questions' else '[]'::jsonb end) q,
      jsonb_array_elements(case when jsonb_typeof(q->'options') = 'array' then q->'options' else '[]'::jsonb end) o) x
  where x.path is not null and x.path <> ''
$$;

-- The path contract {test_id}/{version}/{sha256}.{ext}: the first segment is the test,
-- the version segment is the version being published or (a rollback carries an old one)
-- an existing version of the test, and the file is named by the SHA-256 of its bytes in
-- lowercase hex with an extension content uses, and nothing follows it. A content-
-- addressed name makes a media file immutable by construction (ADR-025 #4).
create function private.topik_media_path_ok(p_test_id text, p_next integer, p_path text) returns boolean
language sql stable set search_path = '' as $$
  select split_part(p_path, '/', 1) = p_test_id
    and split_part(p_path, '/', 3) ~ '^[0-9a-f]{64}\.(mp3|jpg|jpeg|png|webp)$'
    and split_part(p_path, '/', 4) = ''
    and (split_part(p_path, '/', 2) = p_next::text
         or exists (select 1 from public.topik_test_version tv
                    where tv.test_id = p_test_id and tv.content_version::text = split_part(p_path, '/', 2)))
$$;

-- The one body of publish and rollback of 20261016120000, with its media steps read
-- from the two helpers above (the publish dry run uses the same ones). Raises, all
-- before it writes anything, exactly as before: VALIDATION_FAILED (detail = the shape
-- issues), INVALID_STATE (retired), VALIDATION_FAILED (detail = 'media'), MEDIA_MISSING
-- (detail = the first missing path, in sorted order).
create or replace function private.topik_publish_version(p_user uuid, p_test_id text, p_json jsonb, p_note text,
  p_action text, p_detail jsonb) returns integer
language plpgsql set search_path = '' as $$
declare
  v_next integer := private.topik_next_version(p_test_id);
  v_json jsonb := jsonb_set(p_json, '{contentVersion}', to_jsonb(v_next));
  v_paths text[] := private.topik_media_paths(v_json);
  v_media jsonb;
  v_catalog bigint;
  v_status text;
  v_issues text[] := private.topik_master_shape_issues(v_json);
  v_missing text;
begin
  if cardinality(v_issues) > 0 then
    raise exception 'VALIDATION_FAILED' using detail = array_to_string(v_issues, ',');
  end if;
  select p.status into v_status from public.topik_publication p where p.test_id = p_test_id for update;
  if v_status = 'retired' then
    raise exception 'INVALID_STATE';
  end if;
  if exists (select 1 from unnest(v_paths) as u(m) where not private.topik_media_path_ok(p_test_id, v_next, u.m)) then
    raise exception 'VALIDATION_FAILED' using detail = 'media';
  end if;
  select u.m into v_missing from unnest(v_paths) with ordinality as u(m, n)
  where not private.topik_media_exists(u.m) order by u.n limit 1;
  if v_missing is not null then
    raise exception 'MEDIA_MISSING' using detail = v_missing;
  end if;
  -- Every path exists now: record the size and eTag Storage holds for it.
  select coalesce(jsonb_agg(jsonb_build_object('path', u.m,
      'size', case when (o.metadata->>'size') ~ '^[0-9]{1,18}$' then (o.metadata->>'size')::bigint end,
      'eTag', o.metadata->>'eTag') order by u.m), '[]'::jsonb) into v_media
  from unnest(v_paths) as u(m)
  left join storage.objects o on o.bucket_id = 'topik-media' and o.name = u.m;
  insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_at, published_by, note)
  values (p_test_id, v_next, v_json, v_media, md5(v_json::text), now(), p_user, p_note);
  v_catalog := private.topik_next_catalog_version();
  insert into public.topik_publication (test_id, status, current_version, catalog_version, updated_at, updated_by)
  values (p_test_id, 'published', v_next, v_catalog, now(), p_user)
  on conflict (test_id) do update
    set status = 'published', current_version = excluded.current_version, catalog_version = excluded.catalog_version,
        updated_at = excluded.updated_at, updated_by = excluded.updated_by;
  perform private.topik_audit(p_action, p_test_id, v_next,
    coalesce(p_detail, '{}'::jsonb) || jsonb_build_object('note', p_note, 'catalogVersion', v_catalog));
  return v_next;
end
$$;

-- A dry run of publish for the admin's tools: every check publish makes on the draft,
-- reported instead of raised, and nothing written. It takes no lock, so a publish that
-- follows can still meet VERSION_MISMATCH when another admin published in between.
create function public.topik_admin_check(p_test_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_draft public.topik_test_draft;
  v_next integer;
  v_json jsonb;
  v_paths text[];
  v_status text;
  v_issues text[];
  v_invalid text[];
  v_missing text[];
begin
  perform private.require_topik_admin();
  select * into v_draft from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  v_next := (select coalesce(max(v.content_version), 0) + 1 from public.topik_test_version v where v.test_id = p_test_id);
  v_json := jsonb_set(v_draft.json, '{contentVersion}', to_jsonb(v_next));
  v_paths := private.topik_media_paths(v_json);
  v_issues := private.topik_master_shape_issues(v_json);
  select p.status into v_status from public.topik_publication p where p.test_id = p_test_id;
  select coalesce(array_agg(u.m order by u.m), '{}'::text[]) into v_invalid
  from unnest(v_paths) as u(m) where not private.topik_media_path_ok(p_test_id, v_next, u.m);
  select coalesce(array_agg(u.m order by u.m), '{}'::text[]) into v_missing
  from unnest(v_paths) as u(m)
  where private.topik_media_path_ok(p_test_id, v_next, u.m) and not private.topik_media_exists(u.m);
  return jsonb_build_object('testId', p_test_id, 'nextContentVersion', v_next,
    'draftContentVersion', v_draft.json->'contentVersion', 'status', v_status,
    'issues', to_jsonb(v_issues), 'mediaInvalid', to_jsonb(v_invalid), 'mediaMissing', to_jsonb(v_missing),
    'ready', cardinality(v_issues) = 0 and cardinality(v_invalid) = 0 and cardinality(v_missing) = 0
      and v_status is distinct from 'retired'
      and v_draft.json->>'contentVersion' is not distinct from v_next::text);
end
$$;
revoke all on function public.topik_admin_check(text) from public, anon, authenticated;
grant execute on function public.topik_admin_check(text) to authenticated;
```

- [ ] **Step 4: Rename test 18's media to SHA-256 names**

Run from the repository root:

```bash
python3 - <<'EOF'
import pathlib
p = pathlib.Path('supabase/tests/database/18_topik_master_data.sql')
s = p.read_text()
A, B, C = 'a' * 64, 'b' * 64, 'c' * 64
for old, new in (('a.mp3', A + '.mp3'), ('o.png', B + '.png'), ('p.png', C + '.png')):
    assert old in s, old
    s = s.replace(old, new)
# The objects a user sees, sorted by name: the renamed files now sort before listening.mp3.
old = ('topik1-96-listening/1/' + A + '.mp3,topik1-96-listening/1/listening.mp3,'
       'topik1-96-listening/1/' + B + '.png,topik1-96-listening/1/' + C + '.png')
new = ('topik1-96-listening/1/' + A + '.mp3,topik1-96-listening/1/' + B + '.png,'
       'topik1-96-listening/1/' + C + '.png,topik1-96-listening/1/listening.mp3')
assert old in s, 'sorted literal'
s = s.replace(old, new)
p.write_text(s)
print('ok')
EOF
```

Expected: `ok`. Only `a.mp3`, `o.png` and `p.png` are renamed. `listening.mp3`, `picture.png`, `admin.png`, `user.png` and `anything.bin` are never published, so the name rule does not apply to them.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tools/supabase/image_pgtap.sh supabase/tests/database/04_function_privileges.sql supabase/tests/database/18_topik_master_data.sql supabase/tests/database/20_topik_master_contract.sql`

Expected: `04` ok (9), `18` ok (282), `20` ok (48).

If an assertion in 18 fails, the cause is either a name the script missed or an expected-media literal whose order changed. Fix it in the test literal; never by relaxing the rule.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017120000_topik_master_contract.sql supabase/tests/database/20_topik_master_contract.sql \
  supabase/tests/database/18_topik_master_data.sql supabase/tests/database/04_function_privileges.sql
git commit -m "feat(supabase): DEV-394 media named by SHA-256 and topik_admin_check, the publish dry run (ADR-025)"
```

---

### Task 3: Draft compare-and-set, size ceiling, bucket limits, refusals at the edge (DR-22, DR-09, S10)

**Files:**
- Modify: `supabase/migrations/20261017120000_topik_master_contract.sql`. Insert before the "Function privileges (keep last)" block.
- Modify: `supabase/tests/database/20_topik_master_contract.sql`. Plan 48 → 66; insert before the final `reset role;`.

**Interfaces:**
- Consumes: the Task 1 helpers.
- Produces:
  - `public.topik_admin_draft_save(p_test_id text, p_json jsonb, p_last_check jsonb, p_imported boolean, p_expected_updated_at timestamptz default null) returns jsonb`. The 4-argument function is dropped, and 4-argument calls resolve to this one through the default.
  - Constraints `topik_test_draft_json_size` and `topik_test_version_json_size`.
  - The bucket row's `file_size_limit` and `allowed_mime_types`.

- [ ] **Step 1: Write the failing tests**

In `20_topik_master_contract.sql`, change `select plan(48);` to `select plan(66);`. Then insert directly before the final `reset role;`:

```sql
-- ============================================================================
-- A draft save names the updatedAt it read (DR-22); a document over 4 MiB is refused (DR-09)
-- ============================================================================
select set_config('t.a', public.topik_admin_draft_save('topik2-98-listening', public.t_listening('topik2-98-listening'),
  '{}'::jsonb, true)->>'updatedAt', true);
select set_config('t.b', public.topik_admin_draft_save('topik2-98-listening', public.t_listening('topik2-98-listening'),
  '{}'::jsonb, false, current_setting('t.a')::timestamptz)->>'updatedAt', true);
select isnt(current_setting('t.b'), current_setting('t.a'),
  'a save naming the current updatedAt goes through and gets a new one, even in the same transaction');
select throws_like($$select public.topik_admin_draft_save('topik2-98-listening', public.t_listening('topik2-98-listening'),
  '{}'::jsonb, false, current_setting('t.a')::timestamptz)$$, 'VERSION_MISMATCH', 'a save naming a stale updatedAt is refused');
select is(public.topik_admin_draft_get('topik2-98-listening')->>'updatedAt', current_setting('t.b'),
  'and leaves the draft as it was');
select throws_like($$select public.topik_admin_draft_save('topik2-99-listening', public.t_listening('topik2-99-listening'),
  '{}'::jsonb, false, now())$$, 'VERSION_MISMATCH', 'an expected updatedAt for a draft that does not exist is refused');
select is(public.topik_admin_draft_save('topik2-99-listening', public.t_listening('topik2-99-listening'),
  '{}'::jsonb, true, null)->>'testId', 'topik2-99-listening', 'no expected updatedAt saves unconditionally (an import)');
select is(public.t_detail($$select public.topik_admin_draft_save('topik2-98-listening',
    jsonb_set(public.t_listening('topik2-98-listening'), '{pad}', to_jsonb(repeat('x', 4194304))), '{}'::jsonb, false)$$),
  'size', 'a document over 4 MiB is refused with the detail size');
select throws_like($$select public.topik_admin_draft_save('topik2-98-listening',
    jsonb_set(public.t_listening('topik2-98-listening'), '{pad}', to_jsonb(repeat('x', 4194304))), '{}'::jsonb, false)$$,
  'VALIDATION_FAILED', 'as VALIDATION_FAILED');
reset role;
select throws_like($$insert into public.topik_test_draft (test_id, json)
    values ('big', jsonb_build_object('testId', 'big', 'pad', repeat('x', 4194304)))$$,
  '%topik_test_draft_json_size%', 'the draft table refuses it too');
select throws_like($$insert into public.topik_test_version (test_id, content_version, json, checksum)
    values ('big', 1, jsonb_build_object('testId', 'big', 'contentVersion', 1, 'pad', repeat('x', 4194304)), 'x')$$,
  '%topik_test_version_json_size%', 'and so does the version table');

-- ============================================================================
-- Bucket limits (DR-09)
-- ============================================================================
select is((select file_size_limit from storage.buckets where id = 'topik-media'), 52428800::bigint,
  'the bucket caps a file at 50 MiB');
select is((select allowed_mime_types from storage.buckets where id = 'topik-media'),
  '{audio/mpeg,image/jpeg,image/png,image/webp}'::text[], 'and accepts only the media types content uses');

-- ============================================================================
-- Refusals at the edge (S10) and a demoted admin
-- ============================================================================
set local role anon;
select throws_like($$select public.topik_admin_list()$$, '%permission denied%', 'anon cannot call an admin RPC');
select throws_like($$select public.topik_admin_check('topik2-96-listening')$$, '%permission denied%', 'nor the dry run');
set local role authenticated;
select public.t_as('cccccccc-0000-0000-0000-000000000003');
select throws_like($$select public.topik_admin_list()$$, 'UNAUTHORIZED',
  'a live token without a profile is UNAUTHORIZED on an admin RPC');
select set_config('request.jwt.claims', '{"role":"authenticated"}', true);
select throws_like($$select public.topik_admin_list()$$, 'NOT_AUTHENTICATED', 'a request without a user is NOT_AUTHENTICATED');
reset role;
insert into auth.users (id, email, is_anonymous) values ('eeeeeeee-0000-0000-0000-000000000005', 'admin2@example.com', false)
on conflict (id) do nothing;
update public.profiles set role = 'admin' where id = 'eeeeeeee-0000-0000-0000-000000000005';
set local role authenticated;
select public.t_as('eeeeeeee-0000-0000-0000-000000000005');
select is(jsonb_typeof(public.topik_admin_list()->'items'), 'array', 'a second admin lists the tests');
reset role;
update public.profiles set role = 'user' where id = 'eeeeeeee-0000-0000-0000-000000000005';
set local role authenticated;
select public.t_as('eeeeeeee-0000-0000-0000-000000000005');
select throws_like($$select public.topik_admin_list()$$, 'FORBIDDEN', 'demoted, the very next call is FORBIDDEN');
select throws_like($$insert into storage.objects (bucket_id, name)
    values ('topik-media', 'topik2-96-listening/2/' || repeat('e', 64) || '.mp3')$$,
  '%row-level security%', 'and Storage refuses an upload');
```

Count: 9 (drafts and size) + 2 (bucket) + 7 (edge and demotion) = 18 new assertions; 48 + 18 = 66.

The final `reset role;` and the `has_function_privilege` assertion stay last, and they run as postgres.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tools/supabase/image_pgtap.sh supabase/tests/database/20_topik_master_contract.sql`

Expected: FAIL. `topik_admin_draft_save` has no fifth parameter (`function … does not exist`), the size checks and bucket limits are absent, and two saves in one transaction share `now()`.

- [ ] **Step 3: Add the new draft save, the constraints and the bucket limits to the migration**

Insert into `20261017120000_topik_master_contract.sql`, before the "Function privileges (keep last)" block:

```sql
-- ============================================================================
-- Draft compare-and-set (DR-22), document size ceiling and bucket limits (DR-09)
-- ============================================================================

-- The draft save of 20261016120000 with an optional compare-and-set: an editor sends
-- back the updatedAt it read, and a save over a newer one is VERSION_MISMATCH (nothing
-- written). Null means no check (an import). updated_at is clock_timestamp(), so two
-- saves in one transaction still differ. A document over 4 MiB is VALIDATION_FAILED
-- with detail 'size'; the table's CHECK is the backstop.
drop function public.topik_admin_draft_save(text, jsonb, jsonb, boolean);
create function public.topik_admin_draft_save(p_test_id text, p_json jsonb, p_last_check jsonb, p_imported boolean,
  p_expected_updated_at timestamptz default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_topik_admin();
  v_issues text[];
  v_at timestamptz := clock_timestamp();
  v_current timestamptz;
begin
  if p_test_id is null or jsonb_typeof(p_json) is distinct from 'object'
     or p_json->>'testId' is distinct from p_test_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  if octet_length(p_json::text) > 4194304 then
    raise exception 'VALIDATION_FAILED' using detail = 'size';
  end if;
  if p_expected_updated_at is not null then
    select d.updated_at into v_current from public.topik_test_draft d where d.test_id = p_test_id for update;
    if v_current is distinct from p_expected_updated_at then
      raise exception 'VERSION_MISMATCH';
    end if;
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
revoke all on function public.topik_admin_draft_save(text, jsonb, jsonb, boolean, timestamptz) from public, anon, authenticated;
grant execute on function public.topik_admin_draft_save(text, jsonb, jsonb, boolean, timestamptz) to authenticated;

-- NOT VALID: rows already there are not rescanned (the version table is immutable);
-- every new row is checked.
alter table public.topik_test_draft
  add constraint topik_test_draft_json_size check (octet_length(json::text) <= 4194304) not valid;
alter table public.topik_test_version
  add constraint topik_test_version_json_size check (octet_length(json::text) <= 4194304) not valid;

-- Storage enforces these on upload: a file content uses, never over 50 MiB.
update storage.buckets
  set file_size_limit = 52428800,
      allowed_mime_types = array['audio/mpeg', 'image/jpeg', 'image/png', 'image/webp']
  where id = 'topik-media';
```

- [ ] **Step 4: Run every pgTAP file**

Run: `bash tools/supabase/image_pgtap.sh`

Expected: every file passes, including `04` (9), `18` (282), `19` (30) and `20` (66).

`18`'s draft saves call the 4-argument form, which now resolves to the 5-argument function through its default. Its `updatedAt` values are not asserted against `now()`; check that with `rg -n "updatedAt" supabase/tests/database/18_topik_master_data.sql`, which should show no comparison with `now()`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261017120000_topik_master_contract.sql supabase/tests/database/20_topik_master_contract.sql
git commit -m "feat(supabase): DEV-394 draft compare-and-set, 4 MiB document ceiling, bucket MIME and size limits (ADR-025)"
```

---

### Task 4: Documents, then the full verification

**Files:**
- Modify: `docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md`. Add §6.5 after §6.4 and amend the last paragraph of §6.2.
- Modify: `supabase/README.md`, the TOPIK bullet in "Rules" (around lines 200-209).
- Modify: `docs/shared/data/schema.md`, section "Server: TOPIK Master Data" (around lines 760-770).
- Modify: `docs/superpowers/specs/2026-10-17-topik-master-data-decision-package.md` §11, the PR-02 row's status.

**Interfaces:** none (documents).

- [ ] **Step 1: Amend spec 2026-10-16**

Run from the repository root:

```bash
python3 - <<'EOF'
import pathlib
p = pathlib.Path('docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md')
s = p.read_text()
old = "Both are `authenticated`-only (the app is always signed in, anonymously at least, ADR-015 #4)."
assert old in s
s = s.replace(old, old + " Since ADR-025 #5 (owner, 2026-10-17) both serve **admins only** until the owner rules otherwise; §6.5 has the contract as built.")
anchor = "\n## 7. One rule set, three gates"
assert anchor in s
section = """
### 6.5 Contract additions of ADR-025 (migration `20261017120000_topik_master_contract.sql`)

- **Read gate.** `private.topik_can_read_content()` (today `select private.is_admin()`) guards `topik_catalog`, `topik_test_content` and `topik_media_can_read`. A caller it refuses gets `{"entries": [], "next": since, "more": false}` from the catalog, `NOT_FOUND` from the content and no object from Storage. Lifting it is a migration that replaces the function's body; devices then pull from cursor 0.
- **Catalog entry.** A published entry adds `schemaVersion` (integer), `sha256` (hex SHA-256 of the document as `topik_test_content` serves it) and `bytes` (document bytes plus the recorded media sizes; a size Storage did not record counts 0). `checksum` (md5) stays for the admin views.
- **Content.** `topik_test_content` returns `{testId, contentVersion, schemaVersion, sha256, document}`, where `document` is the stored JSON as text: a client hashes those UTF-8 bytes, compares them with `sha256`, then parses.
- **Media names.** The third path segment must match `^[0-9a-f]{64}\\.(mp3|jpg|jpeg|png|webp)$`, the SHA-256 of the file's bytes, and nothing may follow it. Otherwise publish and rollback raise `VALIDATION_FAILED` with detail `media`. The bucket accepts `audio/mpeg`, `image/jpeg`, `image/png`, `image/webp`, up to 50 MiB a file.
- **Drafts.** `topik_admin_draft_save` takes an optional fifth argument, `p_expected_updated_at`: a save over a newer draft is `VERSION_MISMATCH`, and nothing is written. A document over 4 MiB is `VALIDATION_FAILED` with detail `size` (both tables also carry the CHECK). `updated_at` is `clock_timestamp()`.
- **Dry run.** `topik_admin_check(test_id)` (admin) returns `{testId, nextContentVersion, draftContentVersion, status, issues[], mediaInvalid[], mediaMissing[], ready}` from the same checks publish makes, and writes nothing.
"""
s = s.replace(anchor, "\n" + section.strip("\n") + "\n" + anchor, 1)
p.write_text(s)
print('ok')
EOF
```

Expected: `ok`.

- [ ] **Step 2: Amend `supabase/README.md`**

Run:

```bash
python3 - <<'EOF'
import pathlib
p = pathlib.Path('supabase/README.md')
s = p.read_text()
old = "`topik_catalog` and `topik_test_content` (everyone)."
assert old in s
s = s.replace(old, "`topik_catalog` and `topik_test_content` (admins only for now: the read gate\n  `private.topik_can_read_content()`, ADR-025 #5).")
old2 = "being published or an existing one."
assert old2 in s
s = s.replace(old2, old2 + " Its file is named by its SHA-256\n  (`{test_id}/{version}/{sha256}.{ext}`, ADR-025 #4); the bucket accepts audio/mpeg and\n  image/jpeg, png, webp up to 50 MiB. `topik_admin_check` is the publish dry run.", 1)
p.write_text(s)
print('ok')
EOF
```

Expected: `ok`.

- [ ] **Step 3: Amend `docs/shared/data/schema.md`**

Run:

```bash
python3 - <<'EOF'
import pathlib
p = pathlib.Path('docs/shared/data/schema.md')
s = p.read_text()
old = "- `topik_master_audit`: nhật ký chỉ thêm, ghi trong cùng transaction với mỗi thay đổi Master Data."
assert old in s
s = s.replace(old, old + "\n- Migration `20261017120000_topik_master_contract.sql` ([ADR-025](../decisions/ADR-025-ghim-luot-dang-lam-vao-phien-ban-noi-dung-topik.md)) thêm CHECK 4 MiB cho JSON của `topik_test_draft` và `topik_test_version`, và giới hạn MIME và kích thước cho bucket `topik-media`. Nó không thêm cột nào; `sha256` của tài liệu được tính lúc phục vụ.")
p.write_text(s)
print('ok')
EOF
```

Expected: `ok`.

- [ ] **Step 4: Mark PR-02 built in the decision package**

Run:

```bash
python3 - <<'PY'
import pathlib
p = pathlib.Path('docs/superpowers/specs/2026-10-17-topik-master-data-decision-package.md')
lines = p.read_text().split('\n')
hits = [i for i, l in enumerate(lines) if l.startswith('| **PR-02** Master schema additions')]
assert len(hits) == 1 and lines[hits[0]].endswith('| 1 |'), hits
lines[hits[0]] = lines[hits[0]][:-len('| 1 |')] + '| 1 · built on branch, plan `docs/superpowers/plans/2026-10-17-topik-master-data-contract.md` |'
p.write_text('\n'.join(lines))
print('ok')
PY
```

Expected: `ok`.

- [ ] **Step 5: Docs check**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`

Expected: `PASS — 0 error(s)`.

- [ ] **Step 6: The full verification**

Run in this order and record each result:

```bash
bash tools/supabase/image_pgtap.sh                                   # every pgTAP file
bash .claude/skills/flutter-workflow/scripts/dod_check.sh            # the full gate, once, on the final tree
bash tools/supabase/run_auth_it.sh                                    # CLAUDE.md: a PR touching supabase/migrations/
```

Expected:
- every pgTAP file `ok`;
- `dod_check.sh` ends `✓ mechanical gates passed`;
- `run_auth_it.sh` passes.

`run_auth_it.sh` needs the Supabase CLI images. If Docker Hub or ECR refuse them, as on 2026-10-16, record it as `BLOCKED` with the error text. The real-stack proof is then the `supabase migrations` workflow's pgTAP step after merge, before `db push`. Never report it as passed.

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md supabase/README.md \
  docs/shared/data/schema.md docs/superpowers/specs/2026-10-17-topik-master-data-decision-package.md docs/_generated/
git commit -m "docs(supabase): DEV-394 contract additions of ADR-025 in the spec, README and schema.md"
```

---

## Out of scope (rulings for the executor)

- **The workflow's storage drift check (DR-15).** It belongs to PR-08 in the decision package roadmap. Not here.
- **`for share` on the listed `storage.objects` rows during publish** (package §5.9, item 3). Not here. Whether `postgres` may take row locks on hosted `storage.objects` (`supabase_storage_admin`-owned) is unproven, and the run-30 failure shows what an unproven Storage assumption costs. The device's SHA-256 check is the guard.
- **The stale comment at `20261016120000_topik_master_data.sql:382-383`.** It cannot be fixed, because a pushed migration is never edited.
- **The assertion "an admin RPC leaves the learner tables untouched"** (package §6.6). Not written: no `topik_admin_*` body names those tables, so the test could not fail. A reader can verify that with `rg -n "topik_attempt" supabase/migrations/20261016120000_topik_master_data.sql supabase/migrations/20261017120000_topik_master_contract.sql`, which shows no hit.
- **BR, UC and Flutter changes.** These belong to PR-04 and PR-05.
