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
