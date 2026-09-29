begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

-- ADR-018 §7; spec 2026-09-29-app-logging-design.md §4: the admin's reads of app_log
-- (20261004000000_log_admin_reads.sql).
create function public.t_as(p_sub text, p_admin boolean) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', p_sub, 'role', 'authenticated',
    'app_metadata', case when p_admin then jsonb_build_object('role', 'admin') else '{}'::jsonb end)::text, true) $$;

insert into public.app_log (id, occurred_at, level, source, category, event, message, error_type,
  error_message, stack_trace, context, user_id, device_id, app_version, build_number, platform,
  os_version, status)
values
  ('33333333-0000-0000-0000-000000000001', now() - interval '3 minutes', 'warning', 'app', 'db',
    't10.long', repeat('x', 500), 'StateError', 'boom', 'stack line 1', '{"sql": "SELECT 1"}',
    'aaaaaaaa-0000-0000-0000-000000000001', 'dev-1', '8.0.0', '42', 'android', '16', 'open'),
  ('33333333-0000-0000-0000-000000000002', now() - interval '2 minutes', 'info', 'app', 'sync',
    't10.percent', 'progress 100% done', null, null, null, '{}',
    'aaaaaaaa-0000-0000-0000-000000000001', 'dev-1', '8.0.0', '42', 'android', '16', null),
  ('33333333-0000-0000-0000-000000000003', now() - interval '1 minute', 'info', 'app', 'sync',
    't10.percent', 'progress 1000 done, table aXb', null, null, null, '{}',
    'aaaaaaaa-0000-0000-0000-000000000001', 'dev-1', '8.0.0', '42', 'android', '16', null),
  ('33333333-0000-0000-0000-000000000004', now() - interval '30 seconds', 'debug', 'app', 'db',
    't10.under_score', 'table a_b', null, null, null, '{}',
    'aaaaaaaa-0000-0000-0000-000000000001', 'dev-1', '8.0.0', '42', 'android', '16', null),
  ('33333333-0000-0000-0000-000000000005', now() - interval '10 seconds', 'debug', 'app', 'db',
    't10.slash', 'path C:\dir', null, null, null, '{}',
    'aaaaaaaa-0000-0000-0000-000000000001', 'dev-1', '8.0.0', '42', 'android', '16', null);

select ok(has_function_privilege('authenticated', 'public.log_get(uuid)', 'execute'),
  'a signed-in user can call log_get (the admin check is inside)');
select ok(not has_function_privilege('anon', 'public.log_get(uuid)', 'execute'), 'anon cannot call log_get');
select ok(not has_function_privilege('public', 'public.log_get(uuid)', 'execute'),
  'PUBLIC cannot call log_get');
select ok(not has_function_privilege('anon', 'public.log_query(jsonb)', 'execute'),
  'anon still cannot call log_query');

set local role authenticated;
select public.t_as('cccccccc-0000-0000-0000-000000000001', false);

-- The admin check comes before any cast of the filter: a bad value must not tell a
-- non-admin anything but FORBIDDEN.
select throws_ok($$ select public.log_query('{"limit": "many"}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a non-admin gets FORBIDDEN, not a cast error, for a bad limit');
select throws_ok($$ select public.log_query('{"userId": "not a uuid"}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a non-admin gets FORBIDDEN for a bad userId');
select throws_ok($$ select public.log_query('{"from": "yesterday-ish"}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a non-admin gets FORBIDDEN for a bad time');
select throws_ok($$ select public.log_get('33333333-0000-0000-0000-000000000001') $$, 'P0001', 'FORBIDDEN',
  'a non-admin cannot read a log');
select throws_ok($$ select public.log_get('99999999-9999-9999-9999-999999999999') $$, 'P0001', 'FORBIDDEN',
  'a non-admin gets FORBIDDEN, not NOT_FOUND, for a missing id');

select public.t_as('bbbbbbbb-0000-0000-0000-00000000000a', true);

-- A JSON null, or a value of the wrong type, is an absent filter.
select is(jsonb_array_length(public.log_query('{"levels": null, "sources": null, "categories": null,
    "statuses": null, "search": null, "from": null, "to": null, "userId": null, "before": null,
    "limit": null}'::jsonb)->'items'), 5, 'JSON nulls filter nothing');
select is(jsonb_array_length(public.log_query('{"levels": "warning", "sources": 7, "categories": {},
    "statuses": true, "before": "later"}'::jsonb)->'items'), 5,
  'a list or cursor of the wrong type filters nothing');
select is(jsonb_array_length(public.log_query('null'::jsonb)->'items'), 5, 'a JSON null filter reads everything');
select is(jsonb_array_length(public.log_query('[]'::jsonb)->'items'), 5, 'a non-object filter reads everything');
select is(jsonb_array_length(public.log_query('{"levels": []}'::jsonb)->'items'), 0,
  'an empty list still matches nothing');

-- search is literal.
select is((select array_agg(i->>'id') from jsonb_array_elements(
    public.log_query('{"search": "100%"}'::jsonb)->'items') i),
  array['33333333-0000-0000-0000-000000000002'], 'a % in the search is a percent sign');
select is((select array_agg(i->>'id') from jsonb_array_elements(
    public.log_query('{"search": "a_b"}'::jsonb)->'items') i),
  array['33333333-0000-0000-0000-000000000004'], 'a _ in the search is an underscore');
select is((select array_agg(i->>'id') from jsonb_array_elements(
    public.log_query('{"search": "C:\\dir"}'::jsonb)->'items') i),
  array['33333333-0000-0000-0000-000000000005'], 'a backslash in the search is a backslash');
select is(jsonb_array_length(public.log_query('{"search": "%"}'::jsonb)->'items'), 1,
  'a lone % matches only text that holds a percent sign');

-- A list row is compact.
select is((select array_agg(k order by k) from jsonb_object_keys(
    public.log_query('{"search": "t10.long"}'::jsonb)->'items'->0) k),
  array['app_version', 'category', 'device_id', 'error_type', 'event', 'id', 'level', 'message',
    'occurred_at', 'platform', 'source', 'status', 'user_id'],
  'a list row has no context, stack trace or error message');
select is(length(public.log_query('{"search": "t10.long"}'::jsonb)->'items'->0->>'message'), 300,
  'a list row cuts the message at 300 characters');

-- log_get returns the whole row.
select is(length(public.log_get('33333333-0000-0000-0000-000000000001')->>'message'), 500,
  'log_get returns the whole message');
select is(public.log_get('33333333-0000-0000-0000-000000000001') - 'occurred_at' - 'received_at',
  ('{"id": "33333333-0000-0000-0000-000000000001", "level": "warning", "source": "app",
    "category": "db", "event": "t10.long", "message": "' || repeat('x', 500) || '",
    "error_type": "StateError", "error_message": "boom", "stack_trace": "stack line 1",
    "context": {"sql": "SELECT 1"}, "user_id": "aaaaaaaa-0000-0000-0000-000000000001",
    "device_id": "dev-1", "app_version": "8.0.0", "build_number": "42", "platform": "android",
    "os_version": "16", "status": "open", "status_changed_at": null, "status_changed_by": null,
    "status_note": null}')::jsonb,
  'log_get returns every column, context and stack trace included');
select throws_ok($$ select public.log_get('99999999-9999-9999-9999-999999999999') $$, 'P0001', 'NOT_FOUND',
  'an admin gets NOT_FOUND for a missing id');

select * from finish();
rollback;
