begin;
create extension if not exists pgtap with schema extensions;
select plan(25);
-- DEV-181: a purge's delete carries the purged batch and the version the
-- device last saw; a row changed on the server since (restored elsewhere) is
-- refused with its live copy. DEV-184 (policy A, owner 2026-10-06): a
-- tombstone is final; an upsert on it is refused with the tombstone. Server
-- sync spec §4.4: a delete of an older build carries no row and tombstones
-- as before.
insert into auth.users (id) values ('aaaaaaaa-0000-0000-0000-000000000001')
on conflict (id) do nothing;

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
    'rootId', p_parent, 'depth', 2, 'contentType', 'card', 'schedulerType', null,
    'schedulerVersion', null, 'schedulerConfig', null, 'studyConfig', null, 'generation', null) $$;
create function public.t_card(p_id uuid, p_deck uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'deckId', p_deck, 'front', 'f', 'back', 'b',
    'isFlagged', false, 'example', null, 'hint', null, 'pronunciation', null, 'deleteBatchId', null,
    'createdAt', '2026-09-28T00:00:00Z', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_batch(p_id uuid, p_root uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'itemType', 'deck', 'rootItemId', p_root,
    'deletedAt', '2026-09-28T01:00:00Z') $$;
create function public.t_in(p_row jsonb, p_batch uuid) returns jsonb language sql as $$
  select p_row || jsonb_build_object('deleteBatchId', p_batch) $$;
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
-- What a device last saw of a row: recorded when it synced, sent with its purge.
create table public.t_seen (entity_type text, entity_id uuid, v bigint);
grant all on public.t_seen to authenticated;
create function public.t_see(p_type text, p_id uuid) returns void language sql as $$
  insert into public.t_seen select p_type, p_id, (public.t_change(p_type, p_id)->>'serverVersion')::bigint $$;
create function public.t_purge(p_batch uuid, p_type text, p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('deleteBatchId', p_batch, 'serverVersion',
    (select max(v) from public.t_seen where entity_type = p_type and entity_id = p_id)) $$;
create function public.t_all_applied(p_ops jsonb) returns boolean language sql as $$
  select not (public.t_push(p_ops) @? '$[*] ? (@.status != "applied")') $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- R(1) → C(2); cards K(10) and L(11) in C.
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(1, 'deck', public.t_uuid(1), 'upsert', public.t_root(public.t_uuid(1))),
    public.t_op(2, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1))),
    public.t_op(3, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(2))),
    public.t_op(4, 'card', public.t_uuid(11), 'upsert', public.t_card(public.t_uuid(11), public.t_uuid(2))))),
  'the library is applied');

-- Device A puts C in the Trash (batch B 70) and syncs.
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(5, 'delete_batch', public.t_uuid(70), 'upsert', public.t_batch(public.t_uuid(70), public.t_uuid(2))),
    public.t_op(6, 'deck', public.t_uuid(2), 'upsert', public.t_in(public.t_child(public.t_uuid(2), public.t_uuid(1)), public.t_uuid(70))),
    public.t_op(7, 'card', public.t_uuid(10), 'upsert', public.t_in(public.t_card(public.t_uuid(10), public.t_uuid(2)), public.t_uuid(70))),
    public.t_op(8, 'card', public.t_uuid(11), 'upsert', public.t_in(public.t_card(public.t_uuid(11), public.t_uuid(2)), public.t_uuid(70))))),
  'the Trash state is applied');
select public.t_see('deck', public.t_uuid(2)), public.t_see('card', public.t_uuid(10));
-- Device B restores C: the rows leave the batch, the batch goes.
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(9, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1))),
    public.t_op(10, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(2))),
    public.t_op(11, 'card', public.t_uuid(11), 'upsert', public.t_card(public.t_uuid(11), public.t_uuid(2))),
    public.t_op(12, 'delete_batch', public.t_uuid(70), 'delete', null))),
  'the restore is applied');

-- Device A, stale, purges batch B: the server knows B and the rows left it.
select is(public.t_push(jsonb_build_array(public.t_op(13, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(70), 'deck', public.t_uuid(2)))))->0->>'code',
  'ENTITY_NOT_IN_TRASH', 'a purge of a deck another device restored is refused');
select is(public.t_push(jsonb_build_array(public.t_op(13, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(70), 'deck', public.t_uuid(2)))))->0->'current'->>'deleted',
  'false', 'the refusal carries the live deck');
select is(public.t_push(jsonb_build_array(public.t_op(13, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(70), 'deck', public.t_uuid(2)))))->0->'current'->'row'->>'name',
  'Child', 'with its row');
select is(public.t_push(jsonb_build_array(public.t_op(14, 'card', public.t_uuid(10), 'delete', public.t_purge(public.t_uuid(70), 'card', public.t_uuid(10)))))->0->>'code',
  'ENTITY_NOT_IN_TRASH', 'a purge of a card another device restored is refused');
select is(public.t_push(jsonb_build_array(public.t_op(14, 'card', public.t_uuid(10), 'delete', public.t_purge(public.t_uuid(70), 'card', public.t_uuid(10)))))->0->'current'->>'deleted',
  'false', 'the refusal carries the live card');
select is(public.t_change('deck', public.t_uuid(2))->>'deleted', 'false', 'the deck stays live');
select is(public.t_change('card', public.t_uuid(11))->>'deleted', 'false', 'its cards stay live');

-- A row moved to another batch belongs to that batch now.
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(15, 'delete_batch', public.t_uuid(71), 'upsert', public.t_batch(public.t_uuid(71), public.t_uuid(2))),
    public.t_op(16, 'deck', public.t_uuid(2), 'upsert', public.t_in(public.t_child(public.t_uuid(2), public.t_uuid(1)), public.t_uuid(71))))),
  'the deck is trashed again in another batch');
select is(public.t_push(jsonb_build_array(public.t_op(17, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(70), 'deck', public.t_uuid(2)))))->0->>'code',
  'ENTITY_NOT_IN_TRASH', 'a purge of the old batch leaves it to the new one');
-- The device that trashed it again purges that batch: the row is as it saw it.
select public.t_see('deck', public.t_uuid(2));
select is(public.t_push(jsonb_build_array(public.t_op(18, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(71), 'deck', public.t_uuid(2)))))->0->>'status',
  'applied', 'a purge of the batch the deck is in is applied');
select is(public.t_change('deck', public.t_uuid(2))->>'deleted', 'true', 'the deck is a tombstone');
select is(public.t_change('card', public.t_uuid(10))->>'deleted', 'true', 'and so are its cards');

-- DEV-184: the tombstone is final.
select is(public.t_push(jsonb_build_array(public.t_op(19, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1)))))->0->>'code',
  'ENTITY_TOMBSTONED', 'an upsert on a tombstoned deck is refused');
select is(public.t_push(jsonb_build_array(public.t_op(19, 'deck', public.t_uuid(2), 'upsert', public.t_child(public.t_uuid(2), public.t_uuid(1)))))->0->'current'->>'deleted',
  'true', 'with the tombstone');
select is(public.t_push(jsonb_build_array(public.t_op(20, 'card', public.t_uuid(10), 'upsert', public.t_card(public.t_uuid(10), public.t_uuid(1)))))->0->>'code',
  'ENTITY_TOMBSTONED', 'an upsert on a tombstoned card is refused');
select is(public.t_change('deck', public.t_uuid(2))->>'deleted', 'true', 'the deck stays a tombstone');
select is(public.t_push(jsonb_build_array(public.t_op(21, 'deck', public.t_uuid(2), 'delete', public.t_purge(public.t_uuid(71), 'deck', public.t_uuid(2)))))->0->>'status',
  'applied', 'a second delete of a tombstone is acknowledged');

-- An older build's delete carries no batch and tombstones as before (spec §4.4).
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(22, 'deck', public.t_uuid(3), 'upsert', public.t_root(public.t_uuid(3))))), 'a second root R2 is applied');
select is(public.t_push(jsonb_build_array(public.t_op(23, 'deck', public.t_uuid(3), 'delete', null)))->0->>'status',
  'applied', 'a delete without a batch is applied');
select is(public.t_change('deck', public.t_uuid(3))->>'deleted', 'true', 'and tombstones the deck');

-- A batch the server never saw: the device trashed and purged offline, and the
-- row is as it last saw it.
select ok(public.t_all_applied(jsonb_build_array(
    public.t_op(24, 'deck', public.t_uuid(4), 'upsert', public.t_root(public.t_uuid(4))))), 'a third root R3 is applied');
select public.t_see('deck', public.t_uuid(4));
select is(public.t_push(jsonb_build_array(public.t_op(25, 'deck', public.t_uuid(4), 'delete', public.t_purge(public.t_uuid(72), 'deck', public.t_uuid(4)))))->0->>'status',
  'applied', 'a purge naming a batch the server never saw is applied');

select * from finish();
rollback;
