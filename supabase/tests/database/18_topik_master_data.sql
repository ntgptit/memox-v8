-- supabase/tests/database/18_topik_master_data.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(139);
-- ADR-024, spec 2026-10-16 §5: Master Data tables behind RLS with no policy; a
-- published version and the audit log are immutable.

-- ============================================================================
-- Tables, privileges and immutability (Task 1)
-- ============================================================================
select has_table('public', 'topik_test_draft', 'draft table exists');
select has_table('public', 'topik_test_version', 'version table exists');
select has_table('public', 'topik_publication', 'publication table exists');
select has_table('public', 'topik_master_audit', 'audit table exists');
select ok(not has_table_privilege('authenticated', 'public.topik_test_draft', 'select'),
  'clients cannot read drafts directly');
select ok(not has_table_privilege('authenticated', 'public.topik_test_version', 'select'),
  'clients cannot read versions directly');
select ok(not has_table_privilege('authenticated', 'public.topik_publication', 'select'),
  'clients cannot read publications directly');
select ok(not has_table_privilege('authenticated', 'public.topik_master_audit', 'select'),
  'clients cannot read the audit log directly');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_test_draft'::regclass),
  'draft has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_test_version'::regclass),
  'version has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_publication'::regclass),
  'publication has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_master_audit'::regclass),
  'audit has RLS');

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

select throws_like($$truncate public.topik_test_version cascade$$, '%immutable%',
  'a published version cannot be truncated');
select throws_like($$truncate public.topik_master_audit$$, '%append-only%',
  'the audit log cannot be truncated');

-- Deleting an account nulls published_by and actor (on delete set null, an
-- internal UPDATE); that is the one change the triggers allow.
insert into auth.users (id, email, is_anonymous)
values ('18000000-0000-0000-0000-000000000001', 'publisher@example.com', false);
insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_by, note)
values ('topik2-97-reading', 1, '{"testId":"topik2-97-reading","contentVersion":1}'::jsonb, '[]'::jsonb,
  'def', '18000000-0000-0000-0000-000000000001', 'by publisher');
insert into public.topik_master_audit (id, actor, action, test_id, content_version)
values ('18000000-0000-0000-0000-0000000000a1', '18000000-0000-0000-0000-000000000001',
  'publish', 'topik2-97-reading', 1);
select lives_ok($$delete from auth.users where id = '18000000-0000-0000-0000-000000000001'$$,
  'deleting a publisher nulls published_by and actor');
select is((select published_by from public.topik_test_version where test_id = 'topik2-97-reading'), null,
  'published_by is null after the publisher is deleted');
select is((select actor from public.topik_master_audit where id = '18000000-0000-0000-0000-0000000000a1'), null,
  'actor is null after the actor is deleted');
select throws_like(
  $$update public.topik_master_audit set test_id = 'x' where id = '18000000-0000-0000-0000-0000000000a1'$$,
  '%append-only%', 'an audit row with a null actor still cannot be edited');

-- ============================================================================
-- The SQL shape check (Task 2)
-- ============================================================================
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
        'questionType', 'X',
        -- the first (100 - (p_points - 1) * p_count) questions score p_points, the rest one less:
        -- every section built with a legal (count, points) pair sums to 100
        'points', case when n - p_first < 100 - (p_points - 1) * p_count then p_points else p_points - 1 end,
        'stemKo', 'q',
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
select is(private.topik_master_shape_issues(public.t_test('topik1', 'reading', 1, 40, 3)), '{numbering}'::text[],
  'TOPIK I reading numbered from 1 instead of 31');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,points}', '3')),
  '{points}'::text[], 'TOPIK II points other than 2, total other than 100');
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
  true, 'TOPIK I listening: one question lowered from 4 to 3, the total is 99, not 100');

-- valid TOPIK I sections: 10 × 4 + 20 × 3 and 20 × 3 + 20 × 2, both 100
select is(private.topik_master_shape_issues(public.t_test('topik1', 'listening', 1, 30, 4)), '{}'::text[],
  'TOPIK I listening, 30 questions totalling 100, passes');
select is(private.topik_master_shape_issues(public.t_test('topik1', 'reading', 31, 40, 3)), '{}'::text[],
  'TOPIK I reading, numbered 31 to 70 totalling 100, passes');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik1', 'listening', 1, 30, 4), '{questions,0,points}', '5')),
  '{points}'::text[], 'TOPIK I listening: a 5-point question, the total is 101');
-- The testId matches its fields, so identity evaluates (round)::integer on "abc": SQLSTATE 22P02,
-- a data_exception, which the function turns into identity and metadata.
select is(private.topik_master_shape_issues(public.t_test('topik2', 'reading', 1, 50, 2) || '{"round": "abc", "testId": "topik2-abc-reading"}'::jsonb),
  '{identity,metadata}'::text[], 'a wrongly typed field is an identity and metadata failure, not an error');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,options}', '"x"')),
  '{options}'::text[], 'a scalar options reports options and not the fallback');
select is(private.topik_master_shape_issues(
    (select jsonb_set(t, '{groups}', t->'groups' || '[{"groupId": "g1", "questionNos": []}]'::jsonb)
     from (select public.t_test('topik2', 'reading', 1, 50, 2) t) s)),
  '{groups}'::text[], 'two groups with the same groupId');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,options,0,textKo}', '""')),
  '{options}'::text[], 'an option with no text and no image');
select is(private.topik_master_shape_issues(jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,words}', '[{"vi": "x"}]')),
  '{languages}'::text[], 'a words entry without en');

-- ============================================================================
-- Admin RPCs for drafts and the audit log (Task 3)
-- ============================================================================
-- The trigger on_auth_user_created (migration 20261010000000) creates each
-- profile; the role is then set as 12_account.sql does.
insert into auth.users (id, email, is_anonymous) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@example.com', false),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'user@example.com', false)
on conflict (id) do nothing;
update public.profiles set role = 'admin' where id = 'aaaaaaaa-0000-0000-0000-000000000001';

create function public.t_as(p_user text) returns void language sql as $$
  select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', p_user), true) $$;

-- t_test(…, 50, 2) is a valid section; one question raised to 3 points breaks the total.
set local role authenticated;
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select throws_like($$select public.topik_admin_list()$$, 'FORBIDDEN', 'a user is not an admin: list');
select throws_like($$select public.topik_admin_draft_get('topik2-96-reading')$$, 'FORBIDDEN',
  'a user is not an admin: get');
select throws_like($$select public.topik_admin_draft_save('topik2-96-reading', '{}'::jsonb, '{}'::jsonb, false)$$,
  'FORBIDDEN', 'a user is not an admin: save');
select throws_like($$select public.topik_admin_audit(null, 50, null)$$, 'FORBIDDEN', 'a user is not an admin: audit');

select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_list()->'items', '[]'::jsonb, 'an admin sees an empty list');
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2), '{"ok": true}'::jsonb, true)->'issues',
  '[]'::jsonb, 'a valid draft saves with no issue');
select is(public.topik_admin_draft_save('topik2-96-reading', jsonb_set(public.t_test('topik2', 'reading', 1, 50, 2), '{questions,0,points}', '3'), '{}'::jsonb, false)->'issues',
  '["points"]'::jsonb, 'an invalid draft saves and reports its issues');
select throws_like($$select public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2) || '{"testId": "other"}'::jsonb, '{}'::jsonb, false)$$,
  'VALIDATION_FAILED', 'a draft whose testId is not the key is refused');
select throws_like($$select public.topik_admin_draft_save(null, '{}'::jsonb, '{}'::jsonb, false)$$,
  'VALIDATION_FAILED', 'a null test id is refused, not a raw not-null error');
select is(public.topik_admin_list()->'items'->0->>'testId', 'topik2-96-reading', 'the list names the draft');
select is(public.topik_admin_list()->'items'->0->'publication', 'null'::jsonb, 'not published yet');
select is(public.topik_admin_draft_get('topik2-96-reading')->'json'->'questions'->0->>'points', '3', 'the draft reads back');
select throws_like($$select public.topik_admin_draft_get('nope')$$, 'NOT_FOUND', 'an unknown draft');
-- topik2-96-reading also holds the 'publish' row inserted above as postgres.
select is((select count(*) from jsonb_array_elements(public.topik_admin_audit('topik2-96-reading', 50, null)->'items') i
    where i->>'action' like 'draft%'), 2::bigint,
  'two draft audit rows: import, then save');
select is(public.topik_admin_audit('topik2-96-reading', 50, null)->'items'->0->>'action', 'draft_save', 'newest first');
select isnt(public.topik_admin_audit('topik2-96-reading', 1, null)->>'next', null,
  'a full page names the cursor of the next one');
select is(public.topik_admin_audit('topik2-96-reading', 1,
    (public.topik_admin_audit('topik2-96-reading', 1, null)->>'next')::timestamptz)->'items'->0->>'action', 'draft_import',
  'following the cursor gives the second-newest row, with no overlap');
select is(public.topik_admin_audit('topik2-96-reading', 50, null)->>'next', null, 'the last page has no cursor');
select is(public.topik_admin_draft_delete('topik2-96-reading')->>'testId', 'topik2-96-reading', 'delete returns the id');
select throws_like($$select public.topik_admin_draft_delete('topik2-96-reading')$$, 'NOT_FOUND',
  'deleting a missing draft');
select is(public.topik_admin_list()->'items', '[]'::jsonb, 'the draft is gone');
select is(public.topik_admin_audit('topik2-96-reading', 50, null)->'items'->0->>'action', 'draft_delete',
  'the delete is in the audit log');

-- ============================================================================
-- Publish, retire, unretire, rollback, versions (Task 4)
-- ============================================================================
-- topik2-96-reading already holds a version row inserted as postgres above, so the
-- publication flow uses topik1-96-reading (t_pub: a valid 40 × 3/2-point section,
-- contentVersion p_cv) and topik1-96-listening / topik2-96-listening for media.
reset role;
create function public.t_pub(p_cv integer) returns jsonb language sql as $$
  select jsonb_set(public.t_test('topik1', 'reading', 31, 40, 3), '{contentVersion}', to_jsonb(p_cv)) $$;
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
-- The audit rows of one test as a compact list, newest first, draft rows left out.
create function public.t_audit(p_test_id text) returns text[] language sql as $$
  select coalesce(array_agg(i->>'action' order by n), '{}') from public.topik_admin_audit(p_test_id, 200, null) a,
    jsonb_array_elements(a->'items') with ordinality t(i, n) where i->>'action' not like 'draft%' $$;

set local role authenticated;
-- A user is not an admin.
select public.t_as('bbbbbbbb-0000-0000-0000-000000000002');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 1, 'x')$$, 'FORBIDDEN', 'a user cannot publish');
select throws_like($$select public.topik_admin_retire('topik1-96-reading', 'x')$$, 'FORBIDDEN', 'a user cannot retire');
select throws_like($$select public.topik_admin_unretire('topik1-96-reading', 'x')$$, 'FORBIDDEN', 'a user cannot unretire');
select throws_like($$select public.topik_admin_rollback('topik1-96-reading', 1, 'x')$$, 'FORBIDDEN', 'a user cannot roll back');
select throws_like($$select public.topik_admin_versions('topik1-96-reading')$$, 'FORBIDDEN', 'a user cannot list versions');
select throws_like($$select public.topik_admin_version_get('topik1-96-reading', 1)$$, 'FORBIDDEN', 'a user cannot read a version');
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');

-- Publish.
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 1, 'x')$$, 'NOT_FOUND', 'publishing without a draft');
select is(public.topik_admin_draft_save('topik1-96-reading', jsonb_set(public.t_pub(1), '{questions,0,points}', '4'), '{}'::jsonb, true)->'issues',
  '["points"]'::jsonb, 'an invalid draft to publish');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 1, 'try')$$, 'VALIDATION_FAILED',
  'an invalid draft cannot be published');
select is(public.t_detail($$select public.topik_admin_publish('topik1-96-reading', 1, 'try')$$), 'points',
  'the issue names travel in the error detail');
select is(public.topik_admin_versions('topik1-96-reading')->'items', '[]'::jsonb, 'a refused publish stored no version');
select is(public.t_audit('topik1-96-reading'), '{}'::text[], 'a refused publish wrote no audit row');
select is(public.topik_admin_draft_save('topik1-96-reading', public.t_pub(1), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'fixed');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 2, 'try')$$, 'VERSION_MISMATCH',
  'the expected version must be max + 1 (here 1)');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', null, 'try')$$, 'VERSION_MISMATCH',
  'no expected version is a mismatch');
select is(public.topik_admin_publish('topik1-96-reading', 1, 'first')->>'contentVersion', '1', 'published as version 1');
select is((select i->'publication'->>'status' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), 'published', 'the publication is live');
select is((select i->'publication'->>'currentVersion' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), '1', 'the list shows it');
-- The draft is now the next version's working copy: it must say contentVersion 2.
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 2, 'again')$$, 'VERSION_MISMATCH',
  'the draft still says contentVersion 1, so it cannot be published as 2');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 1, 'again')$$, 'VERSION_MISMATCH',
  'version 1 exists, so 1 cannot be published again');
select is(public.topik_admin_draft_save('topik1-96-reading', public.t_pub(2), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'the draft bumped to 2');
select is(public.topik_admin_publish('topik1-96-reading', 2, 'second')->>'contentVersion', '2', 'published as version 2');
select is(jsonb_array_length(public.topik_admin_versions('topik1-96-reading')->'items'), 2, 'two versions kept');
select is(public.topik_admin_versions('topik1-96-reading')->'items'->0->>'contentVersion', '2', 'versions newest first');
select is(public.topik_admin_versions('topik1-96-reading')->'items'->0->>'note', 'second', 'a version keeps its note');
select is(public.topik_admin_versions('topik1-96-reading')->'items'->0->>'publishedBy', 'aaaaaaaa-0000-0000-0000-000000000001',
  'and who published it');
select is(public.topik_admin_versions('topik1-96-reading')->'items'->0->>'checksum',
  md5((public.topik_admin_version_get('topik1-96-reading', 2)->'json')::text),
  'the checksum is md5 of the stored json');
select is(public.topik_admin_version_get('topik1-96-reading', 1)->'json'->>'contentVersion', '1', 'an old version reads back');
select throws_like($$select public.topik_admin_version_get('topik1-96-reading', 9)$$, 'NOT_FOUND', 'an unknown version');
-- A draft whose contentVersion is not a number is a mismatch, not a cast error.
select is(public.topik_admin_draft_save('topik1-96-listening', public.t_test('topik1', 'listening', 1, 30, 4) || '{"contentVersion": "abc"}'::jsonb,
  '{}'::jsonb, false)->'issues', '["identity","metadata"]'::jsonb, 'a draft with a non-numeric contentVersion');
select throws_like($$select public.topik_admin_publish('topik1-96-listening', 1, 'x')$$, 'VERSION_MISMATCH',
  'a non-numeric contentVersion is a VERSION_MISMATCH');

-- Media: the audio and every image must exist in the bucket.
select is(public.topik_admin_draft_save('topik2-96-listening', public.t_test('topik2', 'listening', 1, 50, 2), '{}'::jsonb, true)->'issues',
  '[]'::jsonb, 'a listening draft');
select throws_like($$select public.topik_admin_publish('topik2-96-listening', 1, 'no audio yet')$$, 'MEDIA_MISSING',
  'a referenced media object must exist in the bucket');
select is(public.topik_admin_versions('topik2-96-listening')->'items', '[]'::jsonb, 'MEDIA_MISSING stored no version');
select is(public.t_audit('topik2-96-listening'), '{}'::text[], 'MEDIA_MISSING wrote no audit row');
-- Storage objects are written by the storage service, not by an admin: postgres here.
reset role;
insert into storage.buckets (id, name) values ('topik-media', 'topik-media'), ('other', 'other')
  on conflict (id) do nothing;
insert into storage.objects (bucket_id, name) values ('other', 'a.mp3');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select throws_like($$select public.topik_admin_publish('topik2-96-listening', 1, 'wrong bucket')$$, 'MEDIA_MISSING',
  'an object of another bucket does not count');
reset role;
insert into storage.objects (bucket_id, name) values ('topik-media', 'a.mp3');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_publish('topik2-96-listening', 1, 'audio there')->>'contentVersion', '1', 'published once the audio exists');
select is(public.topik_admin_versions('topik2-96-listening')->'items'->0->'media', '["a.mp3"]'::jsonb, 'the version lists its media');
-- Images: an option's image and a group's passage image.
select is(public.topik_admin_draft_save('topik1-96-listening',
    jsonb_set(jsonb_set(public.t_test('topik1', 'listening', 1, 30, 4), '{questions,0,options,0,image}', '"img/o.png"'),
      '{groups,0,passage}', '{"image": "img/p.png"}'), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'a draft with an option image and a passage image');
select throws_like($$select public.topik_admin_publish('topik1-96-listening', 1, 'x')$$, 'MEDIA_MISSING', 'neither image exists yet');
reset role;
insert into storage.objects (bucket_id, name) values ('topik-media', 'img/o.png');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select throws_like($$select public.topik_admin_publish('topik1-96-listening', 1, 'x')$$, 'MEDIA_MISSING',
  'the passage image is still missing');
reset role;
insert into storage.objects (bucket_id, name) values ('topik-media', 'img/p.png');
set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.topik_admin_publish('topik1-96-listening', 1, 'images there')->>'contentVersion', '1', 'published once every image exists');
select is(public.topik_admin_versions('topik1-96-listening')->'items'->0->'media', '["a.mp3", "img/o.png", "img/p.png"]'::jsonb,
  'audio and both images are listed');

-- Retire, unretire.
select is(public.topik_admin_retire('topik1-96-reading', 'pulled')->>'status', 'retired', 'retired');
select is((select i->'publication'->>'status' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), 'retired', 'the list shows it retired');
select throws_like($$select public.topik_admin_retire('topik1-96-reading', 'again')$$, 'INVALID_STATE', 'retiring twice');
select is(public.topik_admin_unretire('topik1-96-reading', 'back')->>'status', 'published', 'unretired');
select is((select i->'publication'->>'currentVersion' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), '2', 'unretiring restores the version it had');
select throws_like($$select public.topik_admin_unretire('topik1-96-reading', 'again')$$, 'INVALID_STATE', 'unretiring a live test');
-- A retired test is not republished behind the admin's back: unretire is explicit and audited.
select is(public.topik_admin_retire('topik1-96-reading', 'pulled again')->>'status', 'retired', 'retired again');
-- The draft says 3 and carries an empty image path on an option that has text: no media.
select is(public.topik_admin_draft_save('topik1-96-reading',
    jsonb_set(public.t_pub(3), '{questions,1,options,1,image}', '""'), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'the next draft, with an empty image path');
select throws_like($$select public.topik_admin_publish('topik1-96-reading', 3, 'while retired')$$, 'INVALID_STATE',
  'a retired test cannot be published');
select throws_like($$select public.topik_admin_rollback('topik1-96-reading', 1, 'while retired')$$, 'INVALID_STATE',
  'a retired test cannot be rolled back');
select is(jsonb_array_length(public.topik_admin_versions('topik1-96-reading')->'items'), 2, 'no version was stored meanwhile');
select is(public.t_audit('topik1-96-reading'), '{retire,unretire,retire,publish,publish}'::text[],
  'and no publish or rollback was audited');
select is((select i->'publication'->>'status' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), 'retired', 'it stays retired');
select is(public.topik_admin_unretire('topik1-96-reading', 'back again')->>'status', 'published', 'unretired again');
select is(public.topik_admin_publish('topik1-96-reading', 3, 'third')->>'contentVersion', '3',
  'now it publishes, as 3');
select is(public.topik_admin_versions('topik1-96-reading')->'items'->0->'media', '[]'::jsonb,
  'an empty image path is not a media object');
select throws_like($$select public.topik_admin_retire('nope', 'x')$$, 'NOT_FOUND', 'retiring an unknown test');
select throws_like($$select public.topik_admin_unretire('nope', 'x')$$, 'NOT_FOUND', 'unretiring an unknown test');
-- A draft that was never published has no publication to retire.
select is(public.topik_admin_draft_save('topik2-96-reading', public.t_test('topik2', 'reading', 1, 50, 2), '{}'::jsonb, false)->'issues',
  '[]'::jsonb, 'a draft that is not published');
select throws_like($$select public.topik_admin_retire('topik2-96-reading', 'x')$$, 'NOT_FOUND', 'retiring a test that has only a draft');
select throws_like($$select public.topik_admin_unretire('topik2-96-reading', 'x')$$, 'NOT_FOUND', 'unretiring a test that has only a draft');

-- Rollback is a new version with the old content.
select is(public.topik_admin_rollback('topik1-96-reading', 1, 'back to 1')->>'contentVersion', '4', 'rollback publishes version 4');
select is(public.topik_admin_version_get('topik1-96-reading', 4)->'json'->>'contentVersion', '4',
  'the rolled-back content carries the new version number');
select is((public.topik_admin_version_get('topik1-96-reading', 4)->'json') - 'contentVersion',
  (public.topik_admin_version_get('topik1-96-reading', 1)->'json') - 'contentVersion', 'and is otherwise version 1');
select is(public.topik_admin_rollback('topik1-96-reading', 1, 'again')->>'rolledBackFrom', '1', 'the result names the source version');
select is((select a.i->'detail'->>'rolledBackFrom' from (select i from jsonb_array_elements(
    public.topik_admin_audit('topik1-96-reading', 50, null)->'items') i where i->>'action' = 'rollback' limit 1) a),
  '1', 'the audit names the source version');
select is((select i->'publication'->>'currentVersion' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'), '5', 'the publication points at the newest version');
select throws_like($$select public.topik_admin_rollback('topik1-96-reading', 5, 'x')$$, 'INVALID_STATE',
  'rolling back to the version that is already current');
select throws_like($$select public.topik_admin_rollback('topik1-96-reading', 9, 'x')$$, 'NOT_FOUND', 'rolling back to an unknown version');
select throws_like($$select public.topik_admin_rollback('nope', 1, 'x')$$, 'NOT_FOUND', 'rolling back an unknown test');

-- Every change is audited and takes the next catalog version.
select is(public.t_audit('topik1-96-reading'), '{rollback,rollback,publish,unretire,retire,unretire,retire,publish,publish}'::text[],
  'each publication change has an audit row, newest first');
select ok((select count(*) = 9 and bool_and(c > nxt)
    from (select c, coalesce(lead(c) over (order by n), 0) nxt
          from (select (i->'detail'->>'catalogVersion')::bigint c, n
                from jsonb_array_elements(public.topik_admin_audit('topik1-96-reading', 50, null)->'items') with ordinality t(i, n)
                where i->>'action' not like 'draft%') s) s2),
  'catalog versions increase with every change');
select is((select i->'publication'->>'catalogVersion' from jsonb_array_elements(public.topik_admin_list()->'items') i
    where i->>'testId' = 'topik1-96-reading'),
  (select i->'detail'->>'catalogVersion' from jsonb_array_elements(public.topik_admin_audit('topik1-96-reading', 50, null)->'items') i
    where i->>'action' = 'rollback' limit 1), 'the publication carries the last change''s catalog version');
reset role;

select * from finish();
rollback;
