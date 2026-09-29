begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

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
-- Bad rows are skipped, not the whole call: one would otherwise block every later
-- log of the device. Their ids come back accepted, so the device drops them.
select is(public.log_push(jsonb_build_array(
    public.t_entry('11111111-0000-0000-0000-000000000003', 'info'),
    public.t_entry('11111111-0000-0000-0000-000000000004', 'loud'),
    public.t_entry('11111111-0000-0000-0000-000000000005', 'info') - 'level',
    public.t_entry('11111111-0000-0000-0000-000000000006', 'info') || '{"occurredAt": "not a time"}',
    '"not an object"'::jsonb)),
  jsonb_build_object('accepted', jsonb_build_array('11111111-0000-0000-0000-000000000003',
    '11111111-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000005',
    '11111111-0000-0000-0000-000000000006'), 'rejected', 4),
  'bad rows are skipped and reported, the good one is kept');
select is((public.log_push(jsonb_build_array(
    public.t_entry('11111111-0000-0000-0000-000000000007', 'debug') || jsonb_build_object('context',
      jsonb_build_object('kind', 'batch', 'sql', 'INSERT',
        'args', (select jsonb_agg(repeat('x', 1000)) from generate_series(1, 300))))))->>'rejected')::int,
  0, 'an oversized context is accepted');
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN', 'a user cannot read logs');
select throws_ok($$ select public.log_set_status('11111111-0000-0000-0000-000000000002', 'fixed', null) $$,
  'P0001', 'FORBIDDEN', 'a user cannot triage logs');

reset role;
select is((select count(*)::int from public.app_log where id in
  ('11111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002')), 2,
  'the repeated push kept one row each');
select is((select array_agg(id::text order by id) from public.app_log where id::text like '11111111-0000-0000-0000-00000000000_'
    and id::text between '11111111-0000-0000-0000-000000000003' and '11111111-0000-0000-0000-000000000006'),
  array['11111111-0000-0000-0000-000000000003'], 'only the valid row of a mixed push is stored');
select is((select count(*)::int from public.app_log where source = 'server' and event = 'server.log_rejected'
    and (context->>'rejected')::int = 4), 1, 'the server logs the rows it skipped');
select is((select context - 'bytes' from public.app_log where id = '11111111-0000-0000-0000-000000000007'),
  '{"sql": "INSERT", "kind": "batch", "truncated": true}'::jsonb,
  'a context over 256 kB keeps its kind and SQL and says it was cut');
select is((select array_agg(distinct user_id::text) from public.app_log where source = 'app'),
  array['aaaaaaaa-0000-0000-0000-000000000001'], 'user_id comes from the session, not the payload');
select is((select status from public.app_log where id = '11111111-0000-0000-0000-000000000002'),
  'open', 'a warning arrives open');
select is((select status from public.app_log where id = '11111111-0000-0000-0000-000000000001'),
  null, 'an info has no status');

set local role authenticated;
select public.t_as('bbbbbbbb-0000-0000-0000-00000000000a', true);
select is(jsonb_array_length(public.log_query(jsonb_build_object('levels', jsonb_build_array('warning'),
    'sources', jsonb_build_array('app')))->'items'),
  1, 'an admin filters by level');
select is(public.log_query(jsonb_build_object('limit', 1, 'sources', jsonb_build_array('app')))->'items'->0->>'message',
  'SELECT * FROM card WHERE front = ''私''', 'content comes back whole (ADR-018 §1)');
select is((select array_agg(i->>'id') from jsonb_array_elements(public.log_query(jsonb_build_object(
    'userId', 'aaaaaaaa-0000-0000-0000-000000000001', 'search', 'db.que',
    'from', now() - interval '1 minute', 'to', now() + interval '1 minute'))->'items') i),
  array['11111111-0000-0000-0000-000000000007', '11111111-0000-0000-0000-000000000003',
    '11111111-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001'],
  'an admin filters by user, text and time, newest first (then by id)');
select is((select array_agg(i->>'id') from jsonb_array_elements(public.log_query(jsonb_build_object(
    'userId', 'aaaaaaaa-0000-0000-0000-000000000001', 'categories', jsonb_build_array('db'),
    'before', jsonb_build_object('occurredAt', now(), 'id', '11111111-0000-0000-0000-000000000002')))->'items') i),
  array['11111111-0000-0000-0000-000000000001'], 'the next page starts after the cursor');
select is(jsonb_array_length(public.log_query(jsonb_build_object('search', 'no such text'))->'items'), 0,
  'a search that matches nothing returns no rows');
select is(public.log_set_status('11111111-0000-0000-0000-000000000002', 'fixed', 'index added')->>'status',
  'fixed', 'an admin marks a warning fixed');

reset role;
select is((select status_changed_by::text || ' / ' || status_note from public.app_log
  where id = '11111111-0000-0000-0000-000000000002'),
  'bbbbbbbb-0000-0000-0000-00000000000a / index added', 'who fixed it, and the note, are kept');

select private.log_server('warning', 'sync', 'sync.rejected', 'op refused', '{"code":"CONFLICT"}'::jsonb);
select is((select count(*)::int from public.app_log where source = 'server' and event = 'sync.rejected'), 1,
  'the server writes its own log row');

select lives_ok($$ select private.log_server('loud', 'sync', 'x', null) $$,
  'a server log that cannot be written never fails its caller (sync_push)');

-- Age counts from arrival: a device clock set years ahead cannot keep a row forever.
insert into public.app_log (id, occurred_at, received_at, level, category, event, source) values
  ('22222222-0000-0000-0000-000000000001', now(), now() - interval '8 days', 'info', 'db', 'old.info', 'app'),
  ('22222222-0000-0000-0000-000000000002', now(), now() - interval '6 days', 'info', 'db', 'recent.info', 'app'),
  ('22222222-0000-0000-0000-000000000003', now(), now() - interval '181 days', 'error', 'db', 'old.error', 'app'),
  ('22222222-0000-0000-0000-000000000004', now(), now() - interval '179 days', 'error', 'db', 'recent.error', 'app'),
  ('22222222-0000-0000-0000-000000000005', now() + interval '9 years', now() - interval '8 days', 'debug', 'db',
    'future.debug', 'app');
select private.purge_app_log();
select is((select array_agg(event order by event) from public.app_log where id::text like '22222222%'),
  array['recent.error', 'recent.info'], 'purge drops info after 7 days and errors after 180, by arrival');

select ok(exists (select 1 from cron.job where jobname = 'app-log-retention'),
  'the retention job is scheduled');

select * from finish();
rollback;
