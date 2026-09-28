-- SB-S2 / library and study sync spec §3.1: cards sync as rows. The deck delete tombstones the
-- cards of its subtree; the dispatch, the server copy and the change feed learn `card`.

create table public.card (
  id uuid primary key,
  user_id uuid not null,
  deck_id uuid not null references public.deck (id),
  front text not null,
  back text not null,
  is_flagged boolean not null,
  example text null,
  hint text null,
  pronunciation text null,
  delete_batch_id uuid null references public.delete_batch (id),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null
);
create unique index uq_card_user_version on public.card (user_id, server_version);
create index idx_card_deck on public.card (deck_id);

alter table public.card enable row level security;
revoke all on table public.card from public, anon, authenticated;

create function private.card_change(c public.card) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'card', 'entityId', c.id, 'serverVersion', c.server_version,
    'deleted', c.deleted_at is not null,
    'row', case when c.deleted_at is not null then null else jsonb_build_object(
      'id', c.id, 'deckId', c.deck_id, 'front', c.front, 'back', c.back, 'isFlagged', c.is_flagged,
      'example', c.example, 'hint', c.hint, 'pronunciation', c.pronunciation,
      'deleteBatchId', c.delete_batch_id,
      'createdAt', private.wire_time(c.created_at), 'updatedAt', private.wire_time(c.updated_at)) end)
$$;

create or replace function private.current_change(p_user uuid, p_type text, p_id uuid) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_deck public.deck;
  v_batch public.delete_batch;
  v_card public.card;
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
  if p_type = 'card' then
    select * into v_card from public.card where id = p_id and user_id = p_user;
    if found then
      return private.card_change(v_card);
    end if;
  end if;
  return null;
end
$$;

create function private.card_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_owner uuid;
  v_deck public.deck;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  select user_id into v_owner from public.card where id = p_id for update;
  if found and v_owner <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
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
  return v_version;
end
$$;

create function private.card_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
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
  v_version := private.allocate_versions(p_user, 1);
  update public.card set deleted_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;

-- As before, plus the live cards of the tombstoned decks, one version each after the decks'.
create or replace function private.deck_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
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
  select array_agg(s.id) into v_deck_ids from private.live_subtree(p_user, p_id) s;
  v_rows := cardinality(v_deck_ids);
  select count(*) into v_cards from public.card c
  where c.user_id = p_user and c.deck_id = any (v_deck_ids) and c.deleted_at is null;
  v_first := private.allocate_versions(p_user, v_rows + v_cards) - v_rows - v_cards + 1;
  update public.deck d
  set deleted_at = now(), server_version = v_first + s.n - 1, last_device_id = p_device
  from (select t.id, row_number() over (order by t.rel, t.id) as n from private.live_subtree(p_user, p_id) t) s
  where d.id = s.id;
  update public.card c
  set deleted_at = now(), server_version = v_first + v_rows + s.n - 1, last_device_id = p_device
  from (select k.id, row_number() over (order by k.id) as n from public.card k
        where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null) s
  where c.id = s.id;
  return v_first;
end
$$;

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
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'card' then
      return private.card_delete(p_user, p_device, p_id);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

-- As in the first migration; only the supported types grow.
create or replace function private.push_one(p_user uuid, p_device uuid, p_op jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  -- Parsed safely: a failure here would escape this block's handler and fail the whole batch.
  v_op_id uuid := private.try_uuid(p_op->>'opId');
  v_type text := p_op->>'entityType';
  v_version bigint;
  v_code text;
begin
  if v_op_id is null then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null,
      'code', 'VALIDATION_FAILED', 'current', null);
  end if;
  select server_version into v_version from public.sync_applied_op where user_id = p_user and op_id = v_op_id;
  if found then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  end if;
  if v_type is null or v_type not in ('deck', 'delete_batch', 'card') then
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

-- As in the first migration, with cards in the feed.
create or replace function public.sync_changes(since bigint, max_rows integer) returns jsonb
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
      union all
      (select 'card', c.id, c.server_version from public.card c
       where c.user_id = v_user and c.server_version > v_since
       order by c.server_version limit v_limit + 1)
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
