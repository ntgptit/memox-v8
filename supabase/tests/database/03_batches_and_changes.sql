begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function public.t_root(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'Root', 'parentId', null, 'rootId', p_id, 'depth', 1,
    'contentType', 'deck', 'schedulerType', 'eight_box', 'schedulerVersion', 1,
    'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null,
    'sourceTemplateId', null, 'sourceTemplateVersion', null, 'deleteBatchId', null,
    'siblingPosition', 0, 'createdAt', '2026-09-28T00:00:00.000Z', 'updatedAt', '2026-09-28T00:00:00.000Z') $$;
create function public.t_batch(p_id uuid, p_root uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'itemType', 'deck', 'rootItemId', p_root,
    'deletedAt', '2026-09-28T01:00:00Z') $$;
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

-- User A: root R (v1), batch B (v2), R trashed into B (v3).
select is(public.t_push(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'delete_batch', public.t_uuid(2), 'upsert', public.t_batch(public.t_uuid(2), public.t_uuid(1))),
    public.t_op(3, 'deck', public.t_uuid(1), 'upsert',
      public.t_root(public.t_uuid(1)) || jsonb_build_object('deleteBatchId', public.t_uuid(2)))))
  @? '$[*] ? (@.status != "applied")', false, 'a batch and a deck trashed into it are applied');
select is(public.t_change(public.t_uuid(2))->'row',
  jsonb_build_object('id', public.t_uuid(2), 'itemType', 'deck', 'rootItemId', public.t_uuid(1),
    'deletedAt', '2026-09-28T01:00:00.000000Z'), 'a batch reads back in the wire shape');
select is(public.t_push(jsonb_build_array(public.t_op(4, 'deck', public.t_uuid(5), 'upsert',
    public.t_root(public.t_uuid(5)) || jsonb_build_object('deleteBatchId', public.t_uuid(404)))))->0->>'code',
  'VALIDATION_FAILED', 'a deck cannot name an unknown batch');
select is(public.t_push(jsonb_build_array(public.t_op(5, 'delete_batch', public.t_uuid(6), 'upsert',
    public.t_batch(public.t_uuid(6), public.t_uuid(1)) || '{"itemType":"folder"}')))->0->>'code',
  'VALIDATION_FAILED', 'a batch holds cards or decks only');

-- Wire shape of a deck row.
select is((select array_agg(k order by k) from jsonb_object_keys(public.t_change(public.t_uuid(1))->'row') k),
  array['contentType','createdAt','deleteBatchId','depth','firstAnsweredAt','generation','id','name','parentId',
        'rootId','schedulerConfig','schedulerType','schedulerVersion','siblingPosition','sourceTemplateId',
        'sourceTemplateVersion','studyConfig','updatedAt'], 'a deck row carries the adapter keys');
select is(public.t_change(public.t_uuid(1))->'row'->>'createdAt', '2026-09-28T00:00:00.000000Z',
  'times are UTC with microseconds and Z');

-- Paging across both types: versions 1, 2, 3 are R, B, R again → changes hold B (2) and R (3).
select is(public.sync_changes(0, 1)->'changes'->0->>'entityId', public.t_uuid(2)::text, 'the first page holds the lowest version');
select is(public.sync_changes(0, 1)->>'hasMore', 'true', 'a full page says there is more');
select is(public.sync_changes(2, 1)->'changes'->0->>'entityId', public.t_uuid(1)::text, 'the next page continues after nextSince');
select is(public.sync_changes(3, 500), '{"changes": [], "nextSince": 3, "hasMore": false}'::jsonb, 'an empty page keeps since');
select is(jsonb_array_length(public.sync_changes(0, 0)->'changes'), 1, 'max_rows is clamped to at least 1');

-- Batch tombstone.
select is(public.t_push(jsonb_build_array(public.t_op(6, 'delete_batch', public.t_uuid(2), 'delete', null)))->0->>'status',
  'applied', 'a batch delete is applied');
select is(public.t_change(public.t_uuid(2)) - 'serverVersion',
  jsonb_build_object('entityType', 'delete_batch', 'entityId', public.t_uuid(2), 'deleted', true, 'row', null),
  'a deleted batch is a tombstone');

-- User B cannot see or touch A's rows.
select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.sync_changes(0, 500)->'changes', '[]'::jsonb, 'another user sees nothing');
select is(public.t_push(jsonb_build_array(public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1)))))->0,
  jsonb_build_object('opId', public.t_uuid(100001), 'status', 'rejected', 'serverVersion', null,
    'code', 'SYNC_ENTITY_CONFLICT', 'current', null), 'another user cannot take an id, even with the same opId');
select is(public.t_push(jsonb_build_array(public.t_op(7, 'delete_batch', public.t_uuid(2), 'delete', null)))->0->>'code',
  'SYNC_ENTITY_CONFLICT', 'another user cannot delete a batch');
select is(public.t_push(jsonb_build_array(public.t_op(8, 'deck', public.t_uuid(7), 'upsert', public.t_root(public.t_uuid(7)))))->0->>'serverVersion',
  '1', 'versions are counted per user');

-- No identity, too many operations.
select set_config('request.jwt.claims', '', true);
select throws_ok($$ select public.sync_changes(0, 10) $$, 'P0001', 'NOT_AUTHENTICATED', 'a call needs a user');
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);
select throws_ok($$ select public.t_push((select jsonb_agg(public.t_op(300 + i, 'deck', public.t_uuid(300 + i), 'delete', null))
  from generate_series(1, 101) i)) $$, 'P0001', 'VALIDATION_FAILED', 'a batch holds at most 100 operations');

select * from finish();
rollback;
