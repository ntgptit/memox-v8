begin;
create extension if not exists pgtap with schema extensions;
select plan(21);
-- TOPIK spec 2026-10-15 §7.2, §13.3, BR-TOPIK-026, BR-TOPIK-028: submitted
-- attempts sync insert-only with a final tombstone; the server checks
-- integrity only.
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002')
on conflict (id) do nothing;

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
-- A submitted two-question attempt: question 1 right (2 points), question 2 unanswered.
create function public.t_attempt(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'testId', 'topik2-96-reading', 'level', 'topik2',
    'section', 'reading', 'round', 96, 'mode', 'practice', 'status', 'completed',
    'startedAt', '2026-10-15T09:00:00Z', 'completedAt', '2026-10-15T09:10:00Z',
    'updatedAt', '2026-10-15T09:10:00Z', 'totalTimeMs', 5000, 'currentQuestionNo', 2,
    'questionCount', 2, 'maxScore', 4, 'score', 2, 'correctCount', 1, 'answeredCount', 1,
    'contentVersion', 1,
    'answers', jsonb_build_array(
      jsonb_build_object('questionNo', 1, 'selectedIdx', 3, 'timeSpentMs', 3000,
        'answeredAt', '2026-10-15T09:05:00Z', 'correctIdx', 3, 'points', 2, 'pointsEarned', 2,
        'questionType', 'R2_fill_blank'),
      jsonb_build_object('questionNo', 2, 'selectedIdx', null, 'timeSpentMs', 2000,
        'answeredAt', null, 'correctIdx', 1, 'points', 2, 'pointsEarned', 0,
        'questionType', 'R2_fill_blank'))) $$;
create function public.t_op(p_op int, p_type text, p_id uuid, p_kind text, p_row jsonb) returns jsonb
  language sql as $$
  select jsonb_build_object('opId', public.t_uuid(100000 + p_op), 'entityType', p_type,
    'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push1(p_op jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(p_op)))->'results'->0 $$;
create function public.t_change(p_id uuid) returns jsonb language sql as $$
  select c from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'topik_attempt' and c->>'entityId' = p_id::text $$;

-- The user's version counter; a refused push or an unseen delete leaves it as it was.
create function public.t_version(p_user uuid) returns bigint language sql security definer as $$
  select coalesce((select version from public.user_sync_version where user_id = p_user), 0) $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(public.t_push1(public.t_op(1, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'status', 'applied', 'a submitted attempt is applied');
select is(public.t_change(public.t_uuid(1))->'row'->'answers'->0->>'pointsEarned', '2',
  'it reads back with its answers');
select set_config('t.v1', public.t_change(public.t_uuid(1))->>'serverVersion', true);
select is(public.t_push1(public.t_op(2, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'serverVersion', current_setting('t.v1'),
  'sent again under a new op id it keeps its first version');
select set_config('t.top',
  public.t_version('aaaaaaaa-0000-0000-0000-000000000001')::text, true);

select is(public.t_push1(public.t_op(3, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"score": 3}'))->>'code', 'VALIDATION_FAILED',
  'a score that is not the sum of the points earned is refused');
select is(public.t_push1(public.t_op(4, 'topik_attempt', public.t_uuid(2), 'upsert',
    jsonb_set(public.t_attempt(public.t_uuid(2)), '{answers,1,questionNo}', '1')))->>'code',
  'VALIDATION_FAILED', 'a question number twice is refused');
select is(public.t_push1(public.t_op(5, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"status": "in_progress"}'))->>'code',
  'VALIDATION_FAILED', 'an attempt in progress is refused');
select is(public.t_push1(public.t_op(6, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"totalTimeMs": 1}'))->>'code',
  'VALIDATION_FAILED', 'a total time that is not the sum of the answers is refused');
-- BR-TOPIK-028: each count and sum of the snapshot is checked against the answers.
select is(public.t_push1(public.t_op(12, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"questionCount": 3}'))->>'code',
  'VALIDATION_FAILED', 'a question count that is not the number of answers is refused');
select is(public.t_push1(public.t_op(13, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"maxScore": 6}'))->>'code',
  'VALIDATION_FAILED', 'a maximum that is not the sum of the points is refused');
select is(public.t_push1(public.t_op(14, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"correctCount": 0}'))->>'code',
  'VALIDATION_FAILED', 'a correct count that does not match the answers is refused');
select is(public.t_push1(public.t_op(15, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"answeredCount": 2}'))->>'code',
  'VALIDATION_FAILED', 'an answered count that does not match the answers is refused');
select is(public.t_push1(public.t_op(16, 'topik_attempt', public.t_uuid(2), 'upsert',
    jsonb_set(public.t_attempt(public.t_uuid(2)), '{answers,0,selectedIdx}', '5')))->>'code',
  'VALIDATION_FAILED', 'an option outside 1-4 is refused');
select ok(public.t_change(public.t_uuid(2)) is null, 'nothing of the refused attempt is stored');
select is(public.t_version('aaaaaaaa-0000-0000-0000-000000000001')::text, current_setting('t.top'),
  'the refused pushes take no version');

select is(public.t_push1(public.t_op(7, 'topik_attempt', public.t_uuid(3), 'delete', null))->>'status',
  'applied', 'a delete of an attempt the server never saw is acknowledged');
select ok(public.t_change(public.t_uuid(3)) is null, 'and leaves no tombstone');
select is(public.t_version('aaaaaaaa-0000-0000-0000-000000000001')::text, current_setting('t.top'),
  'nor takes a version');

select is(public.t_push1(public.t_op(8, 'topik_attempt', public.t_uuid(1), 'delete', null))->>'status',
  'applied', 'a delete tombstones the attempt');
select is(public.t_push1(public.t_op(9, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'code', 'ENTITY_TOMBSTONED',
  'an upsert onto the tombstone is refused');

-- The wire of the previous slice still applies (server sync spec §4).
select is(public.t_push1(public.t_op(10, 'deck', public.t_uuid(20), 'upsert',
    jsonb_build_object('id', public.t_uuid(20), 'name', 'Root', 'parentId', null,
      'rootId', public.t_uuid(20), 'depth', 1, 'contentType', 'deck', 'schedulerType', 'eight_box',
      'schedulerVersion', 1, 'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1,
      'firstAnsweredAt', null, 'sourceTemplateId', null, 'sourceTemplateVersion', null,
      'deleteBatchId', null, 'siblingPosition', 0, 'createdAt', '2026-10-15T00:00:00Z',
      'updatedAt', '2026-10-15T00:00:00Z')))->>'status', 'applied',
  'a deck push of the previous wire is still applied');

-- Another user's id is a conflict, never a write onto their attempt.
select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.t_push1(public.t_op(11, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'code', 'SYNC_ENTITY_CONFLICT',
  'another user''s attempt id is refused');

select * from finish();
rollback;
