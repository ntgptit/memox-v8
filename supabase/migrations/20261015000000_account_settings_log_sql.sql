-- SQL log switch (spec 2026-10-07-sql-log-switch-design.md §3.3): the fifth
-- synced settings column. An admin turns the tracer's per-statement rows on
-- or off for the account; on by default while the app is under test. The two
-- functions are those of 20261001000000_account_settings_sync.sql with the
-- column added; a push without the key (an older app) stores true.

alter table public.account_settings
  add column log_sql_statements boolean not null default true;

create or replace function private.account_settings_change(s public.account_settings) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'account_settings', 'entityId', '00000000-0000-0000-0000-000000000000'::uuid,
    'serverVersion', s.server_version, 'deleted', false,
    'row', jsonb_build_object('cardLimit', s.card_limit, 'newCardOrder', s.new_card_order,
      'themeMode', s.theme_mode, 'language', s.language, 'logSqlStatements', s.log_sql_statements,
      'updatedAt', private.wire_time(s.updated_at)))
$$;

create or replace function private.account_settings_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_version bigint;
begin
  if p_id is distinct from '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language,
    log_sql_statements, updated_at, server_version, last_device_id)
  values (p_user, (r->>'cardLimit')::integer, r->>'newCardOrder', r->>'themeMode', r->>'language',
    coalesce((r->>'logSqlStatements')::boolean, true),
    (r->>'updatedAt')::timestamptz, v_version, p_device)
  on conflict (user_id) do update set
    card_limit = excluded.card_limit, new_card_order = excluded.new_card_order,
    theme_mode = excluded.theme_mode, language = excluded.language,
    log_sql_statements = excluded.log_sql_statements, updated_at = excluded.updated_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id;
  return v_version;
end
$$;
