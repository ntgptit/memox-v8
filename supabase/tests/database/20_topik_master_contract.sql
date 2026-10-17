-- supabase/tests/database/20_topik_master_contract.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(68);
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
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}',
    to_jsonb('topik2-97-listening/1/' || repeat('a', 64) || '.mp3/')), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'a trailing slash is refused');
select public.topik_admin_draft_save('topik2-97-listening',
  jsonb_set(public.t_listening('topik2-97-listening'), '{assets,audio}',
    to_jsonb('topik2-97-listening/1/' || repeat('a', 64) || '.mp3//x')), '{}'::jsonb, false);
select is(public.t_detail($$select public.topik_admin_publish('topik2-97-listening', 1, 'x')$$), 'media',
  'an empty fourth segment is refused');

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

reset role;
select ok(not has_function_privilege('authenticated', 'private.topik_can_read_content()', 'execute'),
  'the gate is not callable by clients');

select * from finish();
rollback;
