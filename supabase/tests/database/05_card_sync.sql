begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_child(p_id uuid, p_parent uuid) returns jsonb language sql as $$
  select public.t_root(p_id) || jsonb_build_object('name', 'Child', 'parentId', p_parent,
    'contentType', 'card', 'schedulerType', null, 'schedulerVersion', null, 'schedulerConfig', null,
    'studyConfig', null, 'generation', null) $$;
create function public.t_card(p_id uuid, p_deck uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'deckId', p_deck, 'front', '사과', 'back', 'apple',
    'isFlagged', false, 'example', null, 'hint', 'fruit', 'pronunciation', null, 'deleteBatchId', null,
    'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:01Z') $$;
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

-- User A: root R(1) → child D(2); card K(10) in D.
select is(public.t_push(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1))),
    public.t_op(3, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(2)))))
  @? '$[*] ? (@.status != "applied")', false, 'a deck and a card in it are applied');
select is(public.t_change(public.t_uuid(10))->'row',
  jsonb_build_object('id', public.t_uuid(10), 'deckId', public.t_uuid(2), 'front', '사과', 'back', 'apple',
    'isFlagged', false, 'example', null, 'hint', 'fruit', 'pronunciation', null, 'deleteBatchId', null,
    'createdAt', '2026-09-28T00:00:00.000000Z', 'updatedAt', '2026-09-28T00:00:01.000000Z',
    'tagIds', '[]'::jsonb),
  'a card reads back in the wire shape');
select is(public.t_change(public.t_uuid(10))->>'entityType', 'card', 'sync_changes lists cards');
select is(public.t_push(jsonb_build_array(public.t_op(4, 'card', public.t_uuid(11), 'upsert',
    public.t_card(public.t_uuid(11), public.t_uuid(404)))))->0,
  jsonb_build_object('opId', public.t_uuid(100004), 'status', 'rejected', 'serverVersion', null,
    'code', 'CARD_DECK_MISSING', 'current', null),
  'a card in a missing deck is refused, with no server copy of a new card');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'card', public.t_uuid(12), 'upsert',
    public.t_card(public.t_uuid(12), public.t_uuid(2)) || '{"isFlagged":null}')))->0->>'code',
  'VALIDATION_FAILED', 'isFlagged is required');
select is(public.t_push(jsonb_build_array(public.t_op(6, 'card', public.t_uuid(12), 'upsert',
    public.t_card(public.t_uuid(12), public.t_uuid(2)) || jsonb_build_object('deleteBatchId', public.t_uuid(77)))))->0->>'code',
  'VALIDATION_FAILED', 'a card cannot name an unknown trash batch');

-- Deleting D tombstones its card, each row with its own version.
select is(public.t_push(jsonb_build_array(public.t_op(7, 'deck', public.t_uuid(2), 'delete', null)))->0->>'status',
  'applied', 'the deck delete is applied');
select is(public.t_change(public.t_uuid(10))->>'deleted', 'true', 'a deck delete tombstones its cards');
select ok((public.t_change(public.t_uuid(10))->>'serverVersion')::bigint
  <> (public.t_change(public.t_uuid(2))->>'serverVersion')::bigint, 'the card tombstone has its own version');
-- An offline edit of that card is refused with the tombstone, so the device deletes it.
select is(public.t_push(jsonb_build_array(public.t_op(8, 'card', public.t_uuid(10), 'upsert',
    public.t_card(public.t_uuid(10), public.t_uuid(2)))))->0->'current'->>'deleted',
  'true', 'an edit of a card in a deleted deck is refused with the tombstone');

-- Card delete and resurrection.
select is(public.t_push(jsonb_build_array(
    public.t_op(9, 'card', public.t_uuid(13), 'upsert', public.t_card(public.t_uuid(13), public.t_uuid(1))),
    public.t_op(10, 'card', public.t_uuid(13), 'delete', null)))->1->>'status',
  'applied', 'a card delete is applied');
select is(public.t_change(public.t_uuid(13))->>'deleted', 'true', 'a deleted card is a tombstone');
select is(public.t_push(jsonb_build_array(public.t_op(11, 'card', public.t_uuid(13), 'upsert',
    public.t_card(public.t_uuid(13), public.t_uuid(1)))))->0->>'status', 'applied', 'an upsert resurrects a card');

-- User B.
select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.t_push(jsonb_build_array(public.t_op(12, 'card', public.t_uuid(13), 'upsert',
    public.t_card(public.t_uuid(13), public.t_uuid(1)))))->0->>'code',
  'SYNC_ENTITY_CONFLICT', 'another user''s card id is refused');
select is(public.t_push(jsonb_build_array(public.t_op(13, 'card', public.t_uuid(14), 'upsert',
    public.t_card(public.t_uuid(14), public.t_uuid(1)))))->0->>'code',
  'CARD_DECK_MISSING', 'a card cannot go into another user''s deck');

select * from finish();
rollback;
