-- DEV-181 and DEV-184 (EG-02): a purge tombstones only what is as the device
-- last saw it, and a tombstone is final (policy A, owner 2026-10-06).
-- Server sync spec §4.1, §4.4 and §5; ADR-013 #5 and #9.
--
-- A purge's `delete` now carries `row: {"deleteBatchId": …, "serverVersion":
-- …}`: the batch the device purged and the version of the row it last
-- acknowledged. When the row has changed on this server since (another
-- device restored or re-trashed it), the delete is refused with
-- ENTITY_NOT_IN_TRASH and the live copy; the device takes the copy back. A
-- delete without the version (an older build, spec §4.4; a row never
-- acknowledged) tombstones as before. An upsert on a tombstoned deck or card
-- is refused with ENTITY_TOMBSTONED and the tombstone; the device deletes its
-- copy.

-- True when r carries the version the device last saw and the row is past
-- it: the row changed on this server since, and left the purged batch.
create function private.changed_since_seen(p_row_version bigint, r jsonb) returns boolean
language sql immutable set search_path = '' as $$
  select r is not null and jsonb_typeof(r) = 'object'
    and jsonb_typeof(r->'serverVersion') = 'number'
    and p_row_version <> (r->>'serverVersion')::bigint
$$;

-- As in SB-S1, plus the tombstone being final.
create or replace function private.deck_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
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
  -- A tombstone is final (DEV-184): the device takes the tombstone back.
  if v_exists and v_existing.deleted_at is not null then
    raise exception 'ENTITY_TOMBSTONED';
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

-- As in SB-S3, plus the tombstone being final.
create or replace function private.card_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.card;
  v_deck public.deck;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  select * into v_existing from public.card where id = p_id for update;
  if found and v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  -- A tombstone is final (DEV-184): the device takes the tombstone back.
  if found and v_existing.deleted_at is not null then
    raise exception 'ENTITY_TOMBSTONED';
  end if;
  -- A card lives in a live deck of its owner; otherwise a new device would pull a card it cannot hold.
  select * into v_deck from public.deck where id = (r->>'deckId')::uuid;
  if not found or v_deck.user_id <> p_user or v_deck.deleted_at is not null then
    raise exception 'CARD_DECK_MISSING';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.card (id, user_id, deck_id, front, back, is_flagged, example, hint, pronunciation,
    delete_batch_id, created_at, updated_at, server_version, last_device_id, deleted_at)
  values (p_id, p_user, v_deck.id, r->>'front', r->>'back', (r->>'isFlagged')::boolean, r->>'example',
    r->>'hint', r->>'pronunciation', (r->>'deleteBatchId')::uuid, (r->>'createdAt')::timestamptz,
    (r->>'updatedAt')::timestamptz, v_version, p_device, null)
  on conflict (id) do update set
    deck_id = excluded.deck_id, front = excluded.front, back = excluded.back, is_flagged = excluded.is_flagged,
    example = excluded.example, hint = excluded.hint, pronunciation = excluded.pronunciation,
    delete_batch_id = excluded.delete_batch_id, created_at = excluded.created_at,
    updated_at = excluded.updated_at, server_version = excluded.server_version,
    last_device_id = excluded.last_device_id, deleted_at = null;
  -- R10: a row without tagIds (an older build) leaves the links as they are.
  if r ? 'tagIds' then
    if jsonb_typeof(r->'tagIds') <> 'array' then
      raise exception 'VALIDATION_FAILED';
    end if;
    delete from public.card_tags where card_id = p_id;
    insert into public.card_tags (card_id, tag_id)
    select p_id, t.id from public.tags t
    where t.user_id = p_user and t.deleted_at is null
      and t.id in (select private.try_uuid(x) from jsonb_array_elements_text(r->'tagIds') x);
  end if;
  return v_version;
end
$$;

-- As in SB-S4, plus the purge rule; r is the delete's row (the purged batch and the seen version), or null.
drop function private.card_delete(uuid, uuid, uuid);
create function private.card_delete(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.card;
  v_version bigint;
begin
  select * into v_existing from public.card where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  if private.changed_since_seen(v_existing.server_version, r) then
    raise exception 'ENTITY_NOT_IN_TRASH';
  end if;
  delete from public.card_tags where card_id = p_id;
  delete from public.review_log where card_id = p_id;
  delete from public.card_schedule where card_id = p_id;
  v_version := private.allocate_versions(p_user, 1);
  update public.card set deleted_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;

-- As in SB-S4, plus the purge rule on the subtree's root.
drop function private.deck_delete(uuid, uuid, uuid);
create function private.deck_delete(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.deck;
  v_deck_ids uuid[];
  v_rows integer;
  v_cards integer;
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
  if private.changed_since_seen(v_existing.server_version, r) then
    raise exception 'ENTITY_NOT_IN_TRASH';
  end if;
  select array_agg(s.id) into v_deck_ids from private.live_subtree(p_user, p_id) s;
  v_rows := cardinality(v_deck_ids);
  select count(*) into v_cards from public.card c
  where c.user_id = p_user and c.deck_id = any (v_deck_ids) and c.deleted_at is null;
  v_first := private.allocate_versions(p_user, v_rows + v_cards) - v_rows - v_cards + 1;
  update public.deck d
  set deleted_at = now(), server_version = v_first + s.n - 1, last_device_id = p_device
  from (select t.id, row_number() over (order by t.rel, t.id) as n from private.live_subtree(p_user, p_id) t) s
  where d.id = s.id;
  delete from public.card_tags where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  delete from public.review_log where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  delete from public.card_schedule where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  update public.card c
  set deleted_at = now(), server_version = v_first + v_rows + s.n - 1, last_device_id = p_device
  from (select k.id, row_number() over (order by k.id) as n from public.card k
        where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null) s
  where c.id = s.id;
  return v_first;
end
$$;

-- As in SB-S4, plus the row handed to deck and card deletes.
create or replace function private.apply_operation(
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
    if p_type = 'card' then
      return private.card_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'tag' then
      return private.tag_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'account_settings' then
      return private.account_settings_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'review_log' then
      return private.review_log_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'card_schedule' then
      return private.card_schedule_upsert(p_user, p_device, p_id, p_row);
    end if;
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'card' then
      return private.card_delete(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'tag' then
      return private.tag_delete(p_user, p_device, p_id);
    end if;
    -- R13: history goes only with its card; a delete is acknowledged and changes nothing.
    if p_type in ('review_log', 'card_schedule') then
      return private.current_version(p_user);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

revoke all on all functions in schema private from public, anon, authenticated;
