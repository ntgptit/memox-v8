begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
-- SP2b 2.30 (R10): every sync_changes page carries the server clock
-- (20261011000000_sync_server_time.sql).
insert into auth.users (id) values ('dddddddd-0000-0000-0000-000000000001') on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(jsonb_typeof(public.sync_changes(0, 500)->'serverTime'), 'number',
  'a page carries the server time as a number');
select ok(abs((public.sync_changes(0, 500)->>'serverTime')::bigint
    - (extract(epoch from now()) * 1000)::bigint) < 60000,
  'it is the server clock in UTC epoch milliseconds');
select is(jsonb_typeof(public.sync_changes(7, 1)->'serverTime'), 'number',
  'a page past the end carries it too');
select is(public.sync_changes(0, 500) - 'serverTime',
  '{"changes": [], "nextSince": 0, "hasMore": false}'::jsonb,
  'the rest of the page is as before');

select * from finish();
rollback;
