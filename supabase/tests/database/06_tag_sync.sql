begin;
create extension if not exists pgtap with schema extensions;
select plan(15);
-- The users these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-00000000000a'), ('cccccccc-0000-0000-0000-000000000001')
on conflict (id) do nothing;

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_tag(p_id uuid, p_name text) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', p_name, 'nameFolded', lower(trim(p_name)),
    'createdAt', '2026-09-28T00:00:00Z') $$;
create function public.t_card(p_id uuid, p_deck uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'deckId', p_deck, 'front', 'f', 'back', 'b',
    'isFlagged', false, 'example', null, 'hint', null, 'pronunciation', null, 'deleteBatchId', null,
    'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
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
create function public.t_links(p_card uuid) returns bigint language sql security definer as $$
  select count(*) from public.card_tags where card_id = p_card $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- User A: root R(1); tags T1(20) 'Verb', T2(21) 'Noun'; card K(10) naming T1 and an unknown id.
select is(public.t_push(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'tag', public.t_uuid(20), 'upsert', public.t_tag(public.t_uuid(20), 'Verb')),
    public.t_op(3, 'tag', public.t_uuid(21), 'upsert', public.t_tag(public.t_uuid(21), 'Noun')),
    public.t_op(4, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(1))
      || jsonb_build_object('tagIds', jsonb_build_array(public.t_uuid(20), public.t_uuid(404))))))
  @? '$[*] ? (@.status != "applied")', false, 'a deck, two tags and a tagged card are applied');
select is(public.t_change(public.t_uuid(20)),
  jsonb_build_object('entityType', 'tag', 'entityId', public.t_uuid(20), 'serverVersion', 2, 'deleted', false,
    'row', jsonb_build_object('id', public.t_uuid(20), 'name', 'Verb', 'nameFolded', 'verb',
      'createdAt', '2026-09-28T00:00:00.000000Z')),
  'a tag reads back in the wire shape');
select is(public.t_change(public.t_uuid(10))->'row'->'tagIds', jsonb_build_array(public.t_uuid(20)),
  'a card links its live tags and ignores unknown ids');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'card', public.t_uuid(10), 'upsert',
    public.t_card(public.t_uuid(10), public.t_uuid(1)))))->0->>'status', 'applied', 'a card without tagIds is applied');
select is(public.t_change(public.t_uuid(10))->'row'->'tagIds', jsonb_build_array(public.t_uuid(20)),
  'a card without tagIds keeps its links');
select is(public.t_push(jsonb_build_array(public.t_op(6, 'card', public.t_uuid(10), 'upsert',
    public.t_card(public.t_uuid(10), public.t_uuid(1))
      || jsonb_build_object('tagIds', jsonb_build_array(public.t_uuid(21), public.t_uuid(20))))))->0->>'status',
  'applied', 'a card with two tags is applied');
select is(public.t_change(public.t_uuid(10))->'row'->'tagIds',
  jsonb_build_array(public.t_uuid(20), public.t_uuid(21)), 'links follow tagIds, sorted');

-- One live name per user.
select is(public.t_push(jsonb_build_array(public.t_op(7, 'tag', public.t_uuid(22), 'upsert',
    public.t_tag(public.t_uuid(22), ' VERB '))))->0,
  jsonb_build_object('opId', public.t_uuid(100007), 'status', 'rejected', 'serverVersion', null,
    'code', 'TAG_NAME_TAKEN', 'current', null),
  'a second live tag with a taken name is refused');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'tag', public.t_uuid(20), 'delete', null)))->0->>'status',
  'applied', 'a tag delete is applied');
select is(public.t_change(public.t_uuid(10))->'row'->'tagIds', jsonb_build_array(public.t_uuid(21)),
  'a deleted tag leaves its cards');
select is(public.t_push(jsonb_build_array(public.t_op(9, 'tag', public.t_uuid(22), 'upsert',
    public.t_tag(public.t_uuid(22), 'verb'))))->0->>'status', 'applied', 'a tombstoned name is free again');

-- Deletes remove links.
select is(public.t_push(jsonb_build_array(public.t_op(10, 'card', public.t_uuid(10), 'delete', null)))->0->>'status',
  'applied', 'a tagged card is deleted');
select is(public.t_links(public.t_uuid(10)), 0::bigint, 'a card delete removes its links');
select is((select public.t_push(jsonb_build_array(
    public.t_op(11, 'card', public.t_uuid(11), 'upsert', public.t_card(public.t_uuid(11), public.t_uuid(1))
      || jsonb_build_object('tagIds', jsonb_build_array(public.t_uuid(21)))),
    public.t_op(12, 'deck', public.t_uuid(1), 'delete', null)))->1->>'status'), 'applied', 'the deck of a tagged card is deleted');
select is(public.t_links(public.t_uuid(11)), 0::bigint, 'a deck delete removes the links of its cards');

select * from finish();
rollback;
