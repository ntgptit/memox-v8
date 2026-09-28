-- SB-S5 / library and study sync spec §3.5: the study and display settings, one row per user.
-- On the wire the entity id is the nil UUID (D2); reminders stay on the device.

create table public.account_settings (
  user_id uuid primary key,
  card_limit integer not null,
  new_card_order text not null check (new_card_order in ('created', 'random')),
  theme_mode text not null check (theme_mode in ('system', 'light', 'dark')),
  language text not null check (language in ('system', 'en', 'vi')),
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null
);
create unique index uq_account_settings_user_version on public.account_settings (user_id, server_version);

alter table public.account_settings enable row level security;
revoke all on table public.account_settings from public, anon, authenticated;

create function private.account_settings_change(s public.account_settings) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'account_settings', 'entityId', '00000000-0000-0000-0000-000000000000'::uuid,
    'serverVersion', s.server_version, 'deleted', false,
    'row', jsonb_build_object('cardLimit', s.card_limit, 'newCardOrder', s.new_card_order,
      'themeMode', s.theme_mode, 'language', s.language, 'updatedAt', private.wire_time(s.updated_at)))
$$;

create function private.account_settings_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_version bigint;
begin
  if p_id is distinct from '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language, updated_at,
    server_version, last_device_id)
  values (p_user, (r->>'cardLimit')::integer, r->>'newCardOrder', r->>'themeMode', r->>'language',
    (r->>'updatedAt')::timestamptz, v_version, p_device)
  on conflict (user_id) do update set
    card_limit = excluded.card_limit, new_card_order = excluded.new_card_order,
    theme_mode = excluded.theme_mode, language = excluded.language, updated_at = excluded.updated_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id;
  return v_version;
end
$$;

-- As in SB-S3, plus the account settings.
create or replace function private.current_change(p_user uuid, p_type text, p_id uuid) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_deck public.deck;
  v_batch public.delete_batch;
  v_card public.card;
  v_tag public.tags;
  v_settings public.account_settings;
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
  if p_type = 'tag' then
    select * into v_tag from public.tags where id = p_id and user_id = p_user;
    if found then
      return private.tag_change(v_tag);
    end if;
  end if;
  -- One row per user; p_id is always the nil id (D2).
  if p_type = 'account_settings' then
    select * into v_settings from public.account_settings where user_id = p_user;
    if found then
      return private.account_settings_change(v_settings);
    end if;
  end if;
  return null;
end
$$;

-- As in SB-S3, plus the settings upsert; settings have no delete, so a delete is VALIDATION_FAILED.
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
    if p_type = 'tag' then
      return private.tag_delete(p_user, p_device, p_id);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

-- As in SB-S3, plus account_settings.
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
  if v_type is null or v_type not in ('deck', 'delete_batch', 'card', 'tag', 'account_settings') then
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

-- As in SB-S3, plus the settings in the feed.
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
      union all
      (select 'tag', t.id, t.server_version from public.tags t
       where t.user_id = v_user and t.server_version > v_since
       order by t.server_version limit v_limit + 1)
      union all
      (select 'account_settings', '00000000-0000-0000-0000-000000000000'::uuid, s.server_version
       from public.account_settings s
       where s.user_id = v_user and s.server_version > v_since
       order by s.server_version limit v_limit + 1)
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

revoke all on all functions in schema private from public, anon, authenticated;
