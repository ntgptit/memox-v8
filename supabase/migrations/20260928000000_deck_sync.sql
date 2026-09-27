-- ADR-015 / Supabase backend spec §3. Ported from memox-api-services Flyway V1–V4 (deck and delete_batch only).
-- Ids are client-generated UUIDs (ADR-007); times are UTC (ADR-008).

create schema private;
revoke all on schema private from public, anon, authenticated;

create table public.user_sync_version (
  user_id uuid primary key,
  version bigint not null
);

create table public.sync_applied_op (
  user_id uuid not null,
  op_id uuid not null,
  server_version bigint not null,
  applied_at timestamptz not null default now(),
  primary key (user_id, op_id)
);

-- A trash batch; tombstoned_at is the sync tombstone, deleted_at the batch's own time.
create table public.delete_batch (
  id uuid primary key,
  user_id uuid not null,
  item_type text not null check (item_type in ('card', 'deck')),
  root_item_id uuid not null,
  deleted_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  tombstoned_at timestamptz null
);
create unique index uq_delete_batch_user_version on public.delete_batch (user_id, server_version);

create table public.deck (
  id uuid primary key,
  user_id uuid not null,
  name text not null,
  parent_id uuid null references public.deck (id),
  root_id uuid not null,
  depth integer not null check (depth between 1 and 10),
  content_type text not null check (content_type in ('unset', 'card', 'deck')),
  scheduler_type text null check (scheduler_type in ('eight_box', 'sm2')),
  scheduler_version integer null,
  scheduler_config text null,
  study_config text null,
  generation integer null,
  first_answered_at timestamptz null,
  source_template_id text null,
  source_template_version integer null,
  delete_batch_id uuid null references public.delete_batch (id),
  sibling_position integer not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null,
  -- The app's deck CHECKs (deck.drift): a row the app would refuse must be refused here, or it jams every pull.
  constraint deck_root_shape check (
    (parent_id is null and content_type = 'deck' and scheduler_type is not null)
    or (parent_id is not null and scheduler_type is null)),
  constraint deck_root_generation check ((parent_id is null) = (generation is not null)),
  constraint deck_root_scheduler_version check ((parent_id is null) = (scheduler_version is not null)),
  constraint deck_child_configs check (parent_id is null or (scheduler_config is null and study_config is null))
);
-- One version per changed row (sync spec §4.2): a duplicate is a loud error, not a silently skipped change.
create unique index uq_deck_user_version on public.deck (user_id, server_version);
create index idx_deck_parent on public.deck (parent_id);

-- The only path to data is the functions below (spec §2): RLS on, no policy, no client privilege.
alter table public.user_sync_version enable row level security;
alter table public.sync_applied_op enable row level security;
alter table public.delete_batch enable row level security;
alter table public.deck enable row level security;
revoke all on table public.user_sync_version, public.sync_applied_op, public.delete_batch, public.deck
  from public, anon, authenticated;

-- Supabase backend spec §4. Business codes are raised as the exception message (SQLSTATE P0001).

create function private.allocate_versions(p_user uuid, p_count integer) returns bigint
language sql set search_path = '' as $$
  insert into public.user_sync_version as v (user_id, version) values (p_user, p_count)
  on conflict (user_id) do update set version = v.version + excluded.version
  returning version
$$;

create function private.current_version(p_user uuid) returns bigint
language sql stable set search_path = '' as $$
  select coalesce((select version from public.user_sync_version where user_id = p_user), 0)
$$;

create function private.wire_time(p_time timestamptz) returns text
language sql immutable set search_path = '' as $$
  select to_char(p_time at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
$$;

create function private.try_uuid(p_text text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return p_text::uuid;
exception when invalid_text_representation then
  return null;
end
$$;

create function private.deck_change(d public.deck) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'deck', 'entityId', d.id, 'serverVersion', d.server_version,
    'deleted', d.deleted_at is not null,
    'row', case when d.deleted_at is not null then null else jsonb_build_object(
      'id', d.id, 'name', d.name, 'parentId', d.parent_id, 'rootId', d.root_id, 'depth', d.depth,
      'contentType', d.content_type, 'schedulerType', d.scheduler_type,
      'schedulerVersion', d.scheduler_version, 'schedulerConfig', d.scheduler_config,
      'studyConfig', d.study_config, 'generation', d.generation,
      'firstAnsweredAt', private.wire_time(d.first_answered_at),
      'sourceTemplateId', d.source_template_id, 'sourceTemplateVersion', d.source_template_version,
      'deleteBatchId', d.delete_batch_id, 'siblingPosition', d.sibling_position,
      'createdAt', private.wire_time(d.created_at), 'updatedAt', private.wire_time(d.updated_at)) end)
$$;

create function private.delete_batch_change(b public.delete_batch) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'delete_batch', 'entityId', b.id, 'serverVersion', b.server_version,
    'deleted', b.tombstoned_at is not null,
    'row', case when b.tombstoned_at is not null then null else jsonb_build_object(
      'id', b.id, 'itemType', b.item_type, 'rootItemId', b.root_item_id,
      'deletedAt', private.wire_time(b.deleted_at)) end)
$$;

-- The server copy of an entity for this user, or null when the server has never seen it (spec §4.1).
create function private.current_change(p_user uuid, p_type text, p_id uuid) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_deck public.deck;
  v_batch public.delete_batch;
begin
  if p_type = 'deck' then
    select * into v_deck from public.deck where id = p_id and user_id = p_user;
    if found then
      return private.deck_change(v_deck);
    end if;
  end if;
  if p_type = 'delete_batch' then
    select * into v_batch from public.delete_batch where id = p_id and user_id = p_user;
    if found then
      return private.delete_batch_change(v_batch);
    end if;
  end if;
  return null;
end
$$;

-- The live subtree of a deck: its id and each row's distance from it. Empty when the deck is unknown or tombstoned.
create function private.live_subtree(p_user uuid, p_id uuid) returns table (id uuid, rel integer)
language sql stable set search_path = '' as $$
  with recursive sub (id, rel) as (
    select d.id, 0 from public.deck d where d.id = p_id and d.user_id = p_user and d.deleted_at is null
    union all
    select c.id, s.rel + 1 from public.deck c join sub s on c.parent_id = s.id
    where c.user_id = p_user and c.deleted_at is null
  )
  select id, rel from sub
$$;

create function private.deck_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_parent_id uuid := (r->>'parentId')::uuid;
  v_existing public.deck;
  v_exists boolean;
  v_parent public.deck;
  v_root uuid;
  v_depth integer;
  v_height integer;
  v_subtree_ids uuid[];
  v_descendants integer := 0;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- A root holds decks and owns the scheduler; a child has neither (schema.md: deck).
  if v_parent_id is null then
    if r->>'contentType' is distinct from 'deck' or r->>'schedulerType' is null
        or r->>'schedulerVersion' is null or r->>'generation' is null then
      raise exception 'VALIDATION_FAILED';
    end if;
  elsif r->>'schedulerType' is not null or r->>'schedulerVersion' is not null or r->>'generation' is not null
      or r->>'schedulerConfig' is not null or r->>'studyConfig' is not null then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- Config columns hold JSON that other devices parse; a non-JSON value fails the cast (22P02).
  perform (r->>'schedulerConfig')::jsonb, (r->>'studyConfig')::jsonb;

  select * into v_existing from public.deck where id = p_id for update;
  v_exists := found;
  if v_exists and v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;

  select coalesce(array_agg(s.id), '{}'), coalesce(max(s.rel), 0) into v_subtree_ids, v_height
  from private.live_subtree(p_user, p_id) s;

  if v_parent_id is null then
    v_root := p_id;
    v_depth := 1;
  else
    select * into v_parent from public.deck where id = v_parent_id;
    if not found or v_parent.user_id <> p_user or v_parent.deleted_at is not null then
      raise exception 'DECK_PARENT_MISSING';
    end if;
    if v_parent_id = p_id or v_parent_id = any (v_subtree_ids) then
      raise exception 'DECK_TREE_CYCLE';
    end if;
    v_root := v_parent.root_id;
    v_depth := v_parent.depth + 1;
  end if;
  if v_depth + v_height > 10 then
    raise exception 'DECK_TREE_TOO_DEEP';
  end if;

  -- A tombstoned deck has no live subtree, so resurrecting it moves no descendant.
  if v_exists and (v_existing.root_id <> v_root or v_existing.depth <> v_depth) then
    v_descendants := greatest(0, cardinality(v_subtree_ids) - 1);
  end if;
  v_version := private.allocate_versions(p_user, 1 + v_descendants) - v_descendants;

  insert into public.deck (id, user_id, name, parent_id, root_id, depth, content_type, scheduler_type,
    scheduler_version, scheduler_config, study_config, generation, first_answered_at, source_template_id,
    source_template_version, delete_batch_id, sibling_position, created_at, updated_at, server_version,
    last_device_id, deleted_at)
  values (p_id, p_user, r->>'name', v_parent_id, v_root, v_depth, r->>'contentType', r->>'schedulerType',
    (r->>'schedulerVersion')::integer, r->>'schedulerConfig', r->>'studyConfig', (r->>'generation')::integer,
    (r->>'firstAnsweredAt')::timestamptz, r->>'sourceTemplateId', (r->>'sourceTemplateVersion')::integer,
    (r->>'deleteBatchId')::uuid, (r->>'siblingPosition')::integer, (r->>'createdAt')::timestamptz,
    (r->>'updatedAt')::timestamptz, v_version, p_device, null)
  on conflict (id) do update set
    name = excluded.name, parent_id = excluded.parent_id, root_id = excluded.root_id, depth = excluded.depth,
    content_type = excluded.content_type, scheduler_type = excluded.scheduler_type,
    scheduler_version = excluded.scheduler_version, scheduler_config = excluded.scheduler_config,
    study_config = excluded.study_config, generation = excluded.generation,
    first_answered_at = excluded.first_answered_at, source_template_id = excluded.source_template_id,
    source_template_version = excluded.source_template_version, delete_batch_id = excluded.delete_batch_id,
    sibling_position = excluded.sibling_position, created_at = excluded.created_at,
    updated_at = excluded.updated_at, server_version = excluded.server_version,
    last_device_id = excluded.last_device_id, deleted_at = null;

  if v_descendants > 0 then
    update public.deck d
    set root_id = v_root, depth = v_depth + s.rel, server_version = v_version + s.n, last_device_id = p_device
    from (select t.id, t.rel, row_number() over (order by t.rel, t.id) as n
          from private.live_subtree(p_user, p_id) t where t.rel > 0) s
    where d.id = s.id;
  end if;
  return v_version;
end
$$;

create function private.deck_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.deck;
  v_rows integer;
  v_first bigint;
begin
  select * into v_existing from public.deck where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  select count(*) into v_rows from private.live_subtree(p_user, p_id);
  v_first := private.allocate_versions(p_user, v_rows) - v_rows + 1;
  update public.deck d
  set deleted_at = now(), server_version = v_first + s.n - 1, last_device_id = p_device
  from (select t.id, row_number() over (order by t.rel, t.id) as n from private.live_subtree(p_user, p_id) t) s
  where d.id = s.id;
  return v_first;
end
$$;

-- Trash batches: whole-row upsert, tombstone on delete, no tree rules (app deck-sync spec §6).
create function private.delete_batch_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_owner uuid;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  select user_id into v_owner from public.delete_batch where id = p_id for update;
  if found and v_owner <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.delete_batch (id, user_id, item_type, root_item_id, deleted_at, server_version,
    last_device_id, tombstoned_at)
  values (p_id, p_user, r->>'itemType', (r->>'rootItemId')::uuid, (r->>'deletedAt')::timestamptz, v_version,
    p_device, null)
  on conflict (id) do update set
    item_type = excluded.item_type, root_item_id = excluded.root_item_id, deleted_at = excluded.deleted_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id, tombstoned_at = null;
  return v_version;
end
$$;

create function private.delete_batch_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.delete_batch;
  v_version bigint;
begin
  select * into v_existing from public.delete_batch where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.tombstoned_at is not null then
    return v_existing.server_version;
  end if;
  v_version := private.allocate_versions(p_user, 1);
  update public.delete_batch set tombstoned_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;

create function private.apply_operation(
  p_user uuid, p_device uuid, p_type text, p_kind text, p_id uuid, p_row jsonb) returns bigint
language plpgsql set search_path = '' as $$
begin
  if p_kind = 'upsert' then
    if p_row is null or jsonb_typeof(p_row) <> 'object' then
      raise exception 'VALIDATION_FAILED';
    end if;
    if p_type = 'deck' then
      return private.deck_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_upsert(p_user, p_device, p_id, p_row);
    end if;
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

create function private.push_one(p_user uuid, p_device uuid, p_op jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_op_id uuid := (p_op->>'opId')::uuid;
  v_type text := p_op->>'entityType';
  v_version bigint;
  v_code text;
begin
  select server_version into v_version from public.sync_applied_op where user_id = p_user and op_id = v_op_id;
  if found then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  end if;
  if v_type is null or v_type not in ('deck', 'delete_batch') then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null,
      'code', 'SYNC_ENTITY_UNSUPPORTED', 'current', null);
  end if;
  -- A subtransaction: a rejection rolls back only this operation (spec §4.1).
  begin
    v_version := private.apply_operation(p_user, p_device, v_type, p_op->>'op', (p_op->>'entityId')::uuid, p_op->'row');
    insert into public.sync_applied_op (user_id, op_id, server_version) values (p_user, v_op_id, v_version);
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  exception
    when raise_exception then
      v_code := sqlerrm;
    when check_violation or not_null_violation or foreign_key_violation or invalid_text_representation
        or invalid_datetime_format or datetime_field_overflow or numeric_value_out_of_range then
      v_code := 'VALIDATION_FAILED';
    when unique_violation then
      v_code := 'CONFLICT';
  end;
  return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null, 'code', v_code,
    'current', private.current_change(p_user, v_type, private.try_uuid(p_op->>'entityId')));
end
$$;

create function public.sync_push(request jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_device uuid := private.try_uuid(request->>'deviceId');
  v_ops jsonb := request->'operations';
  v_op jsonb;
  v_results jsonb := '[]';
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if v_device is null or jsonb_typeof(v_ops) is distinct from 'array' or jsonb_array_length(v_ops) > 100 then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- One user's pushes are serialized for the whole call (sync spec §4.1).
  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  for v_op in select value from jsonb_array_elements(v_ops) loop
    v_results := v_results || jsonb_build_array(private.push_one(v_user, v_device, v_op));
  end loop;
  return jsonb_build_object('results', v_results);
end
$$;

create function public.sync_changes(since bigint, max_rows integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_since bigint := coalesce(since, 0);
  v_limit integer := least(greatest(coalesce(max_rows, 500), 1), 500);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  with page as (
    select u.entity_type, u.id, u.server_version, row_number() over (order by u.server_version) as n
    from (
      (select 'deck' as entity_type, d.id, d.server_version from public.deck d
       where d.user_id = v_user and d.server_version > v_since
       order by d.server_version limit v_limit + 1)
      union all
      (select 'delete_batch', b.id, b.server_version from public.delete_batch b
       where b.user_id = v_user and b.server_version > v_since
       order by b.server_version limit v_limit + 1)
    ) u
    order by u.server_version limit v_limit + 1
  )
  select coalesce(jsonb_agg(private.current_change(v_user, p.entity_type, p.id) order by p.server_version)
           filter (where p.n <= v_limit), '[]'),
         max(p.server_version) filter (where p.n <= v_limit),
         count(*) > v_limit
  into v_changes, v_next, v_more
  from page p;
  return jsonb_build_object('changes', v_changes, 'nextSince', coalesce(v_next, v_since), 'hasMore', v_more);
end
$$;

-- The keep-alive workflow calls this so a Free project is not paused (ADR-015 #9).
create function public.ping() returns text
language sql stable set search_path = '' as $$ select 'ok' $$;

-- Clients reach data only through these functions (spec §2).
revoke all on all functions in schema private from public, anon, authenticated;
revoke all on function public.sync_push(jsonb), public.sync_changes(bigint, integer) from public, anon, authenticated;
grant execute on function public.sync_push(jsonb), public.sync_changes(bigint, integer) to authenticated;
revoke all on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;
