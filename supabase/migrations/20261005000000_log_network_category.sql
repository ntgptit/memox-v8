-- Spec 2026-09-29-network-logging-design.md §4: the app logs its HTTP requests under
-- the category `network`. Widens the check and the push validation; nothing else changes.

alter table public.app_log drop constraint app_log_category_check;
alter table public.app_log add constraint app_log_category_check check (category in
  ('ui', 'navigation', 'state', 'db', 'sync', 'network', 'reminder', 'lifecycle', 'server'));

create or replace function private.log_entry_valid(e jsonb) returns boolean
language sql stable set search_path = '' as $$
  select coalesce(jsonb_typeof(e) = 'object'
    and e->>'level' in ('debug', 'info', 'warning', 'error')
    and e->>'category' in ('ui', 'navigation', 'state', 'db', 'sync', 'network', 'reminder', 'lifecycle',
      'server')
    and private.try_uuid(e->>'id') is not null
    and coalesce(e->>'event', '') <> ''
    and private.try_timestamptz(e->>'occurredAt') is not null
    and coalesce(jsonb_typeof(e->'context'), 'object') = 'object', false)
$$;

revoke all on function private.log_entry_valid(jsonb) from public, anon, authenticated;
