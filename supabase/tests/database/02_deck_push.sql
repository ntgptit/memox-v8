begin;
create extension if not exists pgtap with schema extensions;
select plan(32);
-- The users these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-00000000000a'), ('cccccccc-0000-0000-0000-000000000001')
on conflict (id) do nothing;

-- Test helpers, created inside the rolled-back transaction.
create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00.000Z', 'updatedAt', '2026-09-28T00:00:00.000Z') $$;
create function public.t_child(p_id uuid, p_parent uuid) returns jsonb language sql as $$
  select public.t_root(p_id) || jsonb_build_object('name', 'Child', 'parentId', p_parent,
    'rootId', public.t_uuid(999), 'depth', 7, 'contentType', 'card', 'schedulerType', null,
    'schedulerVersion', null, 'schedulerConfig', null, 'studyConfig', null, 'generation', null) $$;
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

-- User A.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- R (root) → C → G; R2 a second root.
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0,
  jsonb_build_object('opId', public.t_uuid(100001), 'status', 'applied', 'serverVersion', 1, 'code', null, 'current', null),
  'a new root is applied with version 1');
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0->>'serverVersion',
  '1', 'a resent opId is acknowledged with its first version');
select is(public.t_change(public.t_uuid(1))->>'serverVersion', '1', 'a resent opId is not applied again');
select is(public.t_push(jsonb_build_array(public.t_op(2, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1)))))->0->>'status',
  'applied', 'a child is applied');
select is(public.t_change(public.t_uuid(2))->'row'->>'rootId', public.t_uuid(1)::text, 'root_id is derived, not read from the row');
select is(public.t_change(public.t_uuid(2))->'row'->>'depth', '2', 'depth is derived, not read from the row');
select is(public.t_push(jsonb_build_array(public.t_op(3, 'deck', public.t_uuid(3), 'upsert', public.t_child(public.t_uuid(3), public.t_uuid(2)))))->0->>'status',
  'applied', 'a grandchild is applied');

-- Tree rules.
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(1), 'upsert', public.t_child(public.t_uuid(1), public.t_uuid(3)))))->0->>'code',
  'DECK_TREE_CYCLE', 'a deck cannot move under its own descendant');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(2)))))->0->>'code',
  'DECK_TREE_CYCLE', 'a deck cannot be its own parent');
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(1), 'upsert', public.t_child(public.t_uuid(1), public.t_uuid(3)))))->0->'current'->>'entityId',
  public.t_uuid(1)::text, 'a rejection carries the server copy');
select is(public.t_push(jsonb_build_array(public.t_op(6, 'deck', public.t_uuid(4), 'upsert', public.t_child(public.t_uuid(4), public.t_uuid(404)))))->0,
  jsonb_build_object('opId', public.t_uuid(100006), 'status', 'rejected', 'serverVersion', null, 'code', 'DECK_PARENT_MISSING', 'current', null),
  'a missing parent is rejected, with no server copy of a new deck');

-- A move rewrites the subtree, one version per row.
select is(public.t_push(jsonb_build_array(public.t_op(7, 'deck', public.t_uuid(10), 'upsert', public.t_root(public.t_uuid(10)))))->0->>'status',
  'applied', 'a second root is applied');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(10)))))->0->>'status',
  'applied', 'a subtree moves to another root');
select is(public.t_change(public.t_uuid(3))->'row'->>'rootId', public.t_uuid(10)::text, 'the moved subtree takes the new root');
select is(public.t_change(public.t_uuid(3))->'row'->>'depth', '3', 'the moved subtree keeps its relative depth');
select is((public.t_change(public.t_uuid(3))->>'serverVersion')::bigint,
  (public.t_change(public.t_uuid(2))->>'serverVersion')::bigint + 1, 'each moved row has its own version');

-- Depth: D1 … D10 fits, D11 does not; a subtree of height 1 under D9 does not.
select is(public.t_push((select jsonb_agg(public.t_op(200 + i, 'deck', public.t_uuid(20 + i), 'upsert',
    case when i = 1 then public.t_root(public.t_uuid(21)) else public.t_child(public.t_uuid(20 + i), public.t_uuid(19 + i)) end) order by i)
  from generate_series(1, 11) i))->10->>'code', 'DECK_TREE_TOO_DEEP', 'depth 11 is rejected');
select is(public.t_change(public.t_uuid(30))->'row'->>'depth', '10', 'depth 10 is applied');
select is(public.t_push(jsonb_build_array(public.t_op(9, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(29)))))->0->>'code',
  'DECK_TREE_TOO_DEEP', 'a subtree cannot move where its leaves pass depth 10');

-- Validation.
select is(public.t_push(jsonb_build_array(public.t_op(10, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"contentType":"card"}')))->0->>'code', 'VALIDATION_FAILED', 'a root must hold decks');
select is(public.t_push(jsonb_build_array(public.t_op(11, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"schedulerConfig":"not json"}')))->0->>'code', 'VALIDATION_FAILED', 'config must be JSON');
select is(public.t_push(jsonb_build_array(public.t_op(12, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(41)))))->0->>'code', 'VALIDATION_FAILED', 'row.id must match entityId');
select is(public.t_push(jsonb_build_array(public.t_op(13, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"siblingPosition":"abc"}')))->0->>'code', 'VALIDATION_FAILED', 'a bad number is a validation failure');
select is(public.t_push(jsonb_build_array(public.t_op(14, 'deck', public.t_uuid(40), 'upsert',
  public.t_root(public.t_uuid(40)) || '{"createdAt":"2026-13-40"}')))->0->>'code', 'VALIDATION_FAILED', 'a bad time is a validation failure');
select is(public.t_push(jsonb_build_array(public.t_op(15, 'deck', public.t_uuid(40), 'upsert', null)))->0->>'code',
  'VALIDATION_FAILED', 'an upsert needs a row');
select is(public.t_push(jsonb_build_array(public.t_op(16, 'no_such_type', public.t_uuid(40), 'upsert', '{}')))->0->>'code',
  'SYNC_ENTITY_UNSUPPORTED', 'an unknown entity type is rejected');
select is((select (r->0->>'status') || '/' || (r->1->>'code') || '/' || (public.t_change(public.t_uuid(50)) is not null)::text
  from public.t_push(jsonb_build_array(
    public.t_op(17, 'deck', public.t_uuid(50), 'upsert', public.t_root(public.t_uuid(50))),
    public.t_op(18, 'deck', public.t_uuid(51), 'upsert', public.t_root(public.t_uuid(52))))) r),
  'applied/VALIDATION_FAILED/true', 'a rejected operation does not undo the one before it');

select is((select (r->0->>'status') || '/' || (r->1->>'code') || '/' || (public.t_change(public.t_uuid(60)) is not null)::text
  from public.t_push(jsonb_build_array(
    public.t_op(21, 'deck', public.t_uuid(60), 'upsert', public.t_root(public.t_uuid(60))),
    public.t_op(22, 'deck', public.t_uuid(61), 'upsert', public.t_root(public.t_uuid(61))) || '{"opId":"not-a-uuid"}')) r),
  'applied/VALIDATION_FAILED/true', 'a malformed opId is rejected alone, not the whole batch');

-- Delete tombstones the live subtree, one version per row; the tombstone is final (DEV-184, policy A).
select is(public.t_push(jsonb_build_array(public.t_op(19, 'deck', public.t_uuid(10), 'delete', null)))->0->>'status',
  'applied', 'a subtree delete is applied');
select is(public.t_change(public.t_uuid(3)) - 'serverVersion',
  jsonb_build_object('entityType', 'deck', 'entityId', public.t_uuid(3), 'deleted', true, 'row', null),
  'a descendant is a tombstone with no row');
select is(public.t_push(jsonb_build_array(public.t_op(20, 'deck', public.t_uuid(10), 'upsert', public.t_root(public.t_uuid(10)))))->0->>'code',
  'ENTITY_TOMBSTONED', 'an upsert on a tombstoned deck is refused');
select is(public.t_change(public.t_uuid(10))->>'deleted', 'true', 'the tombstone stays');

select * from finish();
rollback;
