-- ADR-018; spec 2026-09-29-app-logging-design.md §4: every log of the app and the
-- server in one table, read and triaged by an admin only. Nothing is redacted.

create table public.app_log (
  id uuid primary key,
  occurred_at timestamptz not null,
  level text not null check (level in ('debug', 'info', 'warning', 'error')),
  source text not null default 'app' check (source in ('app', 'server')),
  category text not null check (category in
    ('ui', 'navigation', 'state', 'db', 'sync', 'reminder', 'lifecycle', 'server')),
  event text not null,
  message text,
  error_type text,
  error_message text,
  stack_trace text,
  context jsonb not null default '{}',
  user_id uuid,
  device_id text,
  app_version text,
  build_number text,
  platform text,
  os_version text,
  status text check (status in ('open', 'fixed')),
  status_changed_at timestamptz,
  status_changed_by uuid,
  status_note text,
  received_at timestamptz not null default now()
);

create index app_log_occurred_at on public.app_log (occurred_at desc, id desc);
create index app_log_level_status on public.app_log (level, status, occurred_at desc);
create index app_log_user on public.app_log (user_id, occurred_at desc);

alter table public.app_log enable row level security;
revoke all on table public.app_log from public, anon, authenticated;

-- The admin role lives in the user's app_metadata, which only the service role
-- and the dashboard can set (ADR-018 §7).
create function private.is_admin() returns boolean
language sql stable set search_path = '' as $$
  select coalesce(auth.jwt()->'app_metadata'->>'role', '') = 'admin'
$$;

create function private.log_server(p_level text, p_category text, p_event text, p_message text,
  p_context jsonb default '{}') returns void
language sql security definer set search_path = '' as $$
  insert into public.app_log (id, occurred_at, level, source, category, event, message, context,
    user_id, status)
  values (gen_random_uuid(), now(), p_level, 'server', p_category, p_event, p_message,
    coalesce(p_context, '{}'), auth.uid(),
    case when p_level in ('warning', 'error') then 'open' end)
$$;

-- A device's buffered logs. user_id is the session's, never the payload's; a repeated
-- id is ignored, so a push retried after a lost reply keeps one row.
create function public.log_push(entries jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_accepted jsonb;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  if jsonb_typeof(entries) is distinct from 'array' or jsonb_array_length(entries) > 500 then
    raise exception 'VALIDATION_FAILED';
  end if;
  if exists (
    select 1 from jsonb_array_elements(entries) e
    where e->>'level' not in ('debug', 'info', 'warning', 'error')
      or e->>'category' not in ('ui', 'navigation', 'state', 'db', 'sync', 'reminder', 'lifecycle', 'server')
      or private.try_uuid(e->>'id') is null
      or coalesce(e->>'event', '') = ''
      or e->>'occurredAt' is null
  ) then
    raise exception 'VALIDATION_FAILED';
  end if;
  insert into public.app_log (id, occurred_at, level, source, category, event, message, error_type,
    error_message, stack_trace, context, user_id, device_id, app_version, build_number, platform,
    os_version, status)
  select (e->>'id')::uuid, (e->>'occurredAt')::timestamptz, e->>'level', 'app', e->>'category',
    e->>'event', e->>'message', e->>'errorType', e->>'errorMessage', e->>'stackTrace',
    coalesce(e->'context', '{}'), v_user, e->>'deviceId', e->>'appVersion', e->>'buildNumber',
    e->>'platform', e->>'osVersion',
    case when e->>'level' in ('warning', 'error') then 'open' end
  from jsonb_array_elements(entries) e
  on conflict (id) do nothing;
  -- Accepted: every id of the call, new or already here.
  select coalesce(jsonb_agg(e->>'id'), '[]') into v_accepted from jsonb_array_elements(entries) e;
  return jsonb_build_object('accepted', v_accepted);
end
$$;

-- Admin reads, newest first, keyset-paginated on (occurred_at, id).
-- filter: levels[], sources[], categories[], statuses[], search, from, to, userId,
-- before {occurredAt, id}, limit (<= 100).
create function public.log_query(filter jsonb) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit int := least(greatest(coalesce((filter->>'limit')::int, 100), 1), 100);
  v_items jsonb;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  select coalesce(jsonb_agg(to_jsonb(l) order by l.occurred_at desc, l.id desc), '[]') into v_items
  from (
    select * from public.app_log a
    where (filter->'levels' is null or a.level in (select jsonb_array_elements_text(filter->'levels')))
      and (filter->'sources' is null or a.source in (select jsonb_array_elements_text(filter->'sources')))
      and (filter->'categories' is null
        or a.category in (select jsonb_array_elements_text(filter->'categories')))
      and (filter->'statuses' is null or a.status in (select jsonb_array_elements_text(filter->'statuses')))
      and (filter->>'search' is null
        or a.event ilike '%' || (filter->>'search') || '%'
        or a.message ilike '%' || (filter->>'search') || '%')
      and (filter->>'from' is null or a.occurred_at >= (filter->>'from')::timestamptz)
      and (filter->>'to' is null or a.occurred_at < (filter->>'to')::timestamptz)
      and (filter->>'userId' is null or a.user_id = (filter->>'userId')::uuid)
      and (filter->'before' is null or (a.occurred_at, a.id) <
        ((filter->'before'->>'occurredAt')::timestamptz, (filter->'before'->>'id')::uuid))
    order by a.occurred_at desc, a.id desc
    limit v_limit
  ) l;
  return jsonb_build_object('items', v_items);
end
$$;

create function public.log_set_status(log_id uuid, new_status text, note text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_row public.app_log;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  if new_status not in ('open', 'fixed') then
    raise exception 'VALIDATION_FAILED';
  end if;
  update public.app_log
  set status = new_status, status_changed_at = now(), status_changed_by = auth.uid(), status_note = note
  where id = log_id and level in ('warning', 'error')
  returning * into v_row;
  if v_row.id is null then
    raise exception 'NOT_FOUND';
  end if;
  return to_jsonb(v_row);
end
$$;

-- ADR-018 §5: debug and info live 7 days, warning and error 180 days ("6 months",
-- fixed at 180 so the device buffer and the server agree).
create function private.purge_app_log() returns void
language sql security definer set search_path = '' as $$
  delete from public.app_log
  where (level in ('debug', 'info') and occurred_at < now() - interval '7 days')
     or (level in ('warning', 'error') and occurred_at < now() - interval '180 days')
$$;

-- Daily at 03:41 UTC, where pg_cron exists (Supabase preloads it).
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    perform cron.schedule('app-log-retention', '41 3 * * *', 'select private.purge_app_log()');
  end if;
end
$$;

-- The server logs the operations it refuses (ADR-018 §9); otherwise as in 20260928000000.
create or replace function public.sync_push(request jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_device uuid := private.try_uuid(request->>'deviceId');
  v_ops jsonb := request->'operations';
  v_op jsonb;
  v_result jsonb;
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
    v_result := private.push_one(v_user, v_device, v_op);
    if v_result->>'status' = 'rejected' then
      perform private.log_server('warning', 'sync', 'sync.rejected',
        format('%s %s refused: %s', v_op->>'entityType', v_op->>'entityId', v_result->>'code'),
        jsonb_build_object('op', v_op, 'result', v_result, 'deviceId', v_device));
    end if;
    v_results := v_results || jsonb_build_array(v_result);
  end loop;
  return jsonb_build_object('results', v_results);
end
$$;

revoke all on all functions in schema private from public, anon, authenticated;
revoke all on function public.log_push(jsonb), public.log_query(jsonb),
  public.log_set_status(uuid, text, text) from public, anon, authenticated;
grant execute on function public.log_push(jsonb), public.log_query(jsonb),
  public.log_set_status(uuid, text, text) to authenticated;
