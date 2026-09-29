begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

-- ADR-018; spec 2026-09-29-app-logging-design.md §4.
create function public.t_entry(p_id text, p_level text, p_at timestamptz default now()) returns jsonb
language sql as $$
  select jsonb_build_object('id', p_id, 'occurredAt', p_at, 'level', p_level, 'category', 'db',
    'event', 'db.query', 'message', 'SELECT * FROM card WHERE front = ''私''',
    'context', jsonb_build_object('args', jsonb_build_array(1, 'a')),
    'deviceId', 'dev-1', 'appVersion', '8.0.0', 'userId', '00000000-0000-0000-0000-00000000dead') $$;
create function public.t_as(p_sub text, p_admin boolean) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', p_sub, 'role', 'authenticated',
    'app_metadata', case when p_admin then jsonb_build_object('role', 'admin') else '{}'::jsonb end)::text, true) $$;

select has_table('public', 'app_log', 'app_log exists');
select ok((select relrowsecurity from pg_class where oid = 'public.app_log'::regclass), 'RLS is on');
select is((select count(*)::int from pg_policies where tablename = 'app_log'), 0, 'no policy');
select is((select count(*)::int from information_schema.role_table_grants
  where table_name = 'app_log' and grantee in ('anon', 'authenticated', 'PUBLIC')), 0,
  'client roles hold no privilege on app_log');
select ok(not has_function_privilege('anon', 'public.log_push(jsonb)', 'execute'), 'anon cannot push logs');
select ok(has_function_privilege('authenticated', 'public.log_push(jsonb)', 'execute'), 'a user can push logs');

set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001', false);

select is(jsonb_array_length(public.log_push(jsonb_build_array(
    public.t_entry('11111111-0000-0000-0000-000000000001', 'info'),
    public.t_entry('11111111-0000-0000-0000-000000000002', 'warning')))->'accepted'),
  2, 'two entries are accepted');
select is(jsonb_array_length(public.log_push(jsonb_build_array(
    public.t_entry('11111111-0000-0000-0000-000000000001', 'info'),
    public.t_entry('11111111-0000-0000-0000-000000000002', 'warning')))->'accepted'),
  2, 'a repeated push reports the ids accepted again');
select throws_ok($$ select public.log_push((select jsonb_agg(public.t_entry(gen_random_uuid()::text, 'info'))
    from generate_series(1, 501))) $$, 'P0001', 'VALIDATION_FAILED', 'more than 500 entries are refused');
select throws_ok($$ select public.log_push(jsonb_build_array(public.t_entry(gen_random_uuid()::text, 'loud'))) $$,
  'P0001', 'VALIDATION_FAILED', 'an unknown level is refused');
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN', 'a user cannot read logs');
select throws_ok($$ select public.log_set_status('11111111-0000-0000-0000-000000000002', 'fixed', null) $$,
  'P0001', 'FORBIDDEN', 'a user cannot triage logs');

reset role;
select is((select count(*)::int from public.app_log where id in
  ('11111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002')), 2,
  'the repeated push kept one row each');
select is((select array_agg(distinct user_id::text) from public.app_log where source = 'app'),
  array['aaaaaaaa-0000-0000-0000-000000000001'], 'user_id comes from the session, not the payload');
select is((select status from public.app_log where id = '11111111-0000-0000-0000-000000000002'),
  'open', 'a warning arrives open');
select is((select status from public.app_log where id = '11111111-0000-0000-0000-000000000001'),
  null, 'an info has no status');

set local role authenticated;
select public.t_as('bbbbbbbb-0000-0000-0000-00000000000a', true);
select is(jsonb_array_length(public.log_query(jsonb_build_object('levels', jsonb_build_array('warning')))->'items'),
  1, 'an admin filters by level');
select is(public.log_query(jsonb_build_object('limit', 1))->'items'->0->>'message',
  'SELECT * FROM card WHERE front = ''私''', 'content comes back whole (ADR-018 §1)');
select is(public.log_set_status('11111111-0000-0000-0000-000000000002', 'fixed', 'index added')->>'status',
  'fixed', 'an admin marks a warning fixed');

reset role;
select is((select status_changed_by::text || ' / ' || status_note from public.app_log
  where id = '11111111-0000-0000-0000-000000000002'),
  'bbbbbbbb-0000-0000-0000-00000000000a / index added', 'who fixed it, and the note, are kept');

select private.log_server('warning', 'sync', 'sync.rejected', 'op refused', '{"code":"CONFLICT"}'::jsonb);
select is((select count(*)::int from public.app_log where source = 'server' and event = 'sync.rejected'), 1,
  'the server writes its own log row');

insert into public.app_log (id, occurred_at, level, category, event, source) values
  ('22222222-0000-0000-0000-000000000001', now() - interval '8 days', 'info', 'db', 'old.info', 'app'),
  ('22222222-0000-0000-0000-000000000002', now() - interval '6 days', 'info', 'db', 'recent.info', 'app'),
  ('22222222-0000-0000-0000-000000000003', now() - interval '181 days', 'error', 'db', 'old.error', 'app'),
  ('22222222-0000-0000-0000-000000000004', now() - interval '179 days', 'error', 'db', 'recent.error', 'app');
select private.purge_app_log();
select is((select array_agg(event order by event) from public.app_log where id::text like '22222222%'),
  array['recent.error', 'recent.info'], 'purge drops info after 7 days and errors after 6 months');

create function public.t_cron_scheduled() returns boolean language plpgsql as $$
begin
  if to_regclass('cron.job') is null then return true; end if;  -- no pg_cron here
  return exists (select 1 from cron.job where jobname = 'app-log-retention');
end $$;
select ok(public.t_cron_scheduled(), 'the retention job is scheduled where pg_cron exists');

select * from finish();
rollback;
