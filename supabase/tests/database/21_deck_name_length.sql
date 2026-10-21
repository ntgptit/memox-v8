begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
-- Deck name 32 spec 2026-10-21 §6 (BR-DECK-020): the server holds a
-- ceiling of 128 code points; the app counts 32 characters within it, so
-- the server never refuses a name the app wrote.
insert into auth.users (id) values ('aaaaaaaa-0000-0000-0000-000000000001')
on conflict (id) do nothing;
create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid, p_name text) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', p_name, 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-10-21T00:00:00.000Z', 'updatedAt', '2026-10-21T00:00:00.000Z') $$;
create function public.t_push1(p_op int, p_id uuid, p_name text) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(jsonb_build_object('opId', public.t_uuid(100000 + p_op),
      'entityType', 'deck', 'entityId', p_id, 'op', 'upsert',
      'row', public.t_root(p_id, p_name)))))->'results'->0 $$;
create function public.t_name(p_id uuid) returns text language sql as $$
  select c->'row'->>'name' from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityId' = p_id::text $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(public.t_push1(1, public.t_uuid(1), repeat('a', 128))->>'status', 'applied',
  'a name of 128 code points is applied');
select is(public.t_push1(2, public.t_uuid(1), repeat('a', 129))->>'code', 'VALIDATION_FAILED',
  'a name of 129 code points is refused');
select is(public.t_name(public.t_uuid(1)), repeat('a', 128),
  'the refused push leaves the name the server holds');
-- 20 families of five code points: 20 characters, 100 code points.
select is(public.t_push1(3, public.t_uuid(2), repeat('👨‍👩‍👧', 20))->>'status', 'applied',
  'a name the app takes, more code points than characters, is applied');

select * from finish();
rollback;
