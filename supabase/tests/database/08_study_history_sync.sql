begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_card(p_id uuid, p_deck uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'deckId', p_deck, 'front', 'f', 'back', 'b',
    'isFlagged', false, 'example', null, 'hint', null, 'pronunciation', null, 'deleteBatchId', null,
    'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_review(p_id uuid, p_card uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'cardId', p_card, 'sessionId', 's1', 'schedulerType', 'eight_box',
    'generation', 1, 'kind', 'scheduled', 'mode', 'self_assess', 'outcomeReason', null,
    'comparisonVersion', null, 'usedHint', null, 'direction', null, 'action', 'remembered',
    'answeredAt', '2026-09-28T10:00:00Z', 'nextDueAt', '2026-09-30T00:00:00Z', 'previousBox', 1, 'nextBox', 2,
    'previousEaseFactor', null, 'nextEaseFactor', null, 'previousIntervalDays', null, 'nextIntervalDays', null) $$;
create function public.t_schedule(p_card uuid, p_answered text) returns jsonb language sql as $$
  select jsonb_build_object('cardId', p_card, 'schedulerType', 'eight_box', 'schedulerVersion', 1, 'generation', 1,
    'learnedAt', '2026-09-27T00:00:00Z', 'dueAt', '2026-09-30T00:00:00Z', 'lastAnsweredAt', p_answered,
    'answerCount', 3, 'lapseCount', 0, 'currentBox', 2, 'easeFactor', null, 'intervalDays', null,
    'repetitions', null) $$;
create function public.t_op(p_op int, p_type text, p_id uuid, p_kind text, p_row jsonb) returns jsonb
  language sql as $$
  select jsonb_build_object('opId', public.t_uuid(100000 + p_op), 'entityType', p_type,
    'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_change(p_type text, p_id uuid) returns jsonb language sql as $$
  select c from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = p_type and c->>'entityId' = p_id::text $$;
create function public.t_count(p_table text, p_card uuid) returns bigint language plpgsql security definer as $$
declare n bigint;
begin
  execute format('select count(*) from public.%I where card_id = $1', p_table) into n using p_card;
  return n;
end $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- User A: root R(1), card K(10), its schedule and a review V(50).
select is(public.t_push(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(1))),
    public.t_op(3, 'card_schedule', public.t_uuid(10), 'upsert', public.t_schedule(public.t_uuid(10), '2026-09-28T10:00:00Z')),
    public.t_op(4, 'review_log', public.t_uuid(50), 'upsert', public.t_review(public.t_uuid(50), public.t_uuid(10)))))
  @? '$[*] ? (@.status != "applied")', false, 'a card, its schedule and a review are applied');
select is(public.t_change('review_log', public.t_uuid(50))->'row',
  public.t_review(public.t_uuid(50), public.t_uuid(10)) || jsonb_build_object(
    'answeredAt', '2026-09-28T10:00:00.000000Z', 'nextDueAt', '2026-09-30T00:00:00.000000Z'),
  'a review reads back in the wire shape');
select is(public.t_change('card_schedule', public.t_uuid(10))->'row'->>'lastAnsweredAt',
  '2026-09-28T10:00:00.000000Z', 'a schedule reads back under its card id');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'review_log', public.t_uuid(50), 'upsert',
    public.t_review(public.t_uuid(50), public.t_uuid(10)))))->0->>'serverVersion',
  public.t_change('review_log', public.t_uuid(50))->>'serverVersion',
  'a review sent again under a new op id keeps its version');
select is(public.t_count('review_log', public.t_uuid(10)), 1::bigint, 'and is not stored twice');
select is(public.t_push(jsonb_build_array(public.t_op(6, 'card_schedule', public.t_uuid(10), 'upsert',
    public.t_schedule(public.t_uuid(10), '2026-09-28T11:00:00Z')))) is not null
  and public.t_change('card_schedule', public.t_uuid(10))->'row'->>'lastAnsweredAt' = '2026-09-28T11:00:00.000000Z',
  true, 'a schedule is a whole-row upsert; the server does not compare');
select is(public.t_push(jsonb_build_array(public.t_op(7, 'card_schedule', public.t_uuid(10), 'upsert',
    public.t_schedule(public.t_uuid(10), '2026-09-28T11:00:00Z') || '{"currentBox": null}')))->0->>'code',
  'VALIDATION_FAILED', 'a schedule outside the CHECKs is refused');
select is(public.t_push(jsonb_build_array(public.t_op(17, 'card_schedule', public.t_uuid(10), 'upsert',
    public.t_schedule(public.t_uuid(99), '2026-09-28T11:00:00Z'))))->0->>'code',
  'VALIDATION_FAILED', 'a schedule row names its own card');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'review_log', public.t_uuid(51), 'upsert',
    public.t_review(public.t_uuid(51), public.t_uuid(404)))))->0,
  jsonb_build_object('opId', public.t_uuid(100008), 'status', 'rejected', 'serverVersion', null,
    'code', 'CARD_MISSING', 'current', null),
  'a review of a card the server never saw is refused');
select is(public.t_push(jsonb_build_array(
    public.t_op(9, 'review_log', public.t_uuid(50), 'delete', null),
    public.t_op(10, 'card_schedule', public.t_uuid(10), 'delete', null)))
  @? '$[*] ? (@.status != "applied")', false, 'a review or schedule delete is acknowledged (R13)');
select is(public.t_count('review_log', public.t_uuid(10)) + public.t_count('card_schedule', public.t_uuid(10)),
  2::bigint, 'and changes nothing');

-- Deletes take the history with the card.
select is(public.t_push(jsonb_build_array(
    public.t_op(11, 'card', public.t_uuid(11), 'upsert', public.t_card(public.t_uuid(11), public.t_uuid(1))),
    public.t_op(12, 'card_schedule', public.t_uuid(11), 'upsert', public.t_schedule(public.t_uuid(11), '2026-09-28T10:00:00Z')),
    public.t_op(13, 'review_log', public.t_uuid(52), 'upsert', public.t_review(public.t_uuid(52), public.t_uuid(11))),
    public.t_op(14, 'card', public.t_uuid(11), 'delete', null)))->3->>'status', 'applied', 'a card with history is deleted');
select is(public.t_count('review_log', public.t_uuid(11)) + public.t_count('card_schedule', public.t_uuid(11)),
  0::bigint, 'a card delete removes its reviews and schedule');
select is(public.t_push(jsonb_build_array(public.t_op(15, 'review_log', public.t_uuid(53), 'upsert',
    public.t_review(public.t_uuid(53), public.t_uuid(11)))))->0->>'status', 'applied',
  'a review of a tombstoned card is acknowledged and dropped (R14)');

select is((select public.t_push(jsonb_build_array(
    public.t_op(20, 'deck', public.t_uuid(2), 'upsert', public.t_root(public.t_uuid(2))),
    public.t_op(21, 'card', public.t_uuid(12), 'upsert', public.t_card(public.t_uuid(12), public.t_uuid(2))),
    public.t_op(22, 'review_log', public.t_uuid(54), 'upsert', public.t_review(public.t_uuid(54), public.t_uuid(12))),
    public.t_op(23, 'deck', public.t_uuid(2), 'delete', null))) is not null)
  and public.t_count('review_log', public.t_uuid(12)) = 0, true,
  'a deck delete removes the reviews of its cards');

select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.t_push(jsonb_build_array(public.t_op(16, 'review_log', public.t_uuid(50), 'upsert',
    public.t_review(public.t_uuid(50), public.t_uuid(10)))))->0->>'code',
  'SYNC_ENTITY_CONFLICT', 'another user''s review id is refused');

select * from finish();
rollback;
