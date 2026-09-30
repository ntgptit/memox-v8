begin;
create extension if not exists pgtap with schema extensions;
select plan(9);
-- The users these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-00000000000a'), ('cccccccc-0000-0000-0000-000000000001')
on conflict (id) do nothing;

-- ADR-018 §8; monitoring spec §3.2: the admin filters the logs by device.
create function public.t_as(p_sub text, p_admin boolean) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', p_sub, 'role', 'authenticated',
    'app_metadata', case when p_admin then jsonb_build_object('role', 'admin') else '{}'::jsonb end)::text, true) $$;

insert into public.app_log (id, occurred_at, level, category, event, device_id, error_message) values
  ('33333333-0000-0000-0000-000000000001', now() - interval '3 minutes', 'error', 'db', 'a.one', 'dev-a',
    repeat('e', 400)),
  ('33333333-0000-0000-0000-000000000002', now() - interval '2 minutes', 'warning', 'db', 'b.one', 'dev-b', null),
  ('33333333-0000-0000-0000-000000000003', now() - interval '1 minute', 'error', 'db', 'c.one', 'dev-c', null),
  ('33333333-0000-0000-0000-000000000004', now(), 'info', 'db', 'none.one', null, null);

set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001', false);
select throws_ok($$ select public.log_query('{"deviceIds": ["dev-a"]}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a user still cannot read logs');

select public.t_as('bbbbbbbb-0000-0000-0000-00000000000a', true);
select is((select array_agg(i->>'event') from jsonb_array_elements(
    public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items') i),
  array['a.one'], 'one device');
select is((select array_agg(i->>'event' order by i->>'event') from jsonb_array_elements(
    public.log_query('{"deviceIds": ["dev-a", "dev-c"]}'::jsonb)->'items') i),
  array['a.one', 'c.one'], 'several devices');
-- As the other lists: an empty array names no device, so nothing matches. The app omits
-- the key when no device is chosen.
select is(jsonb_array_length(public.log_query('{"deviceIds": []}'::jsonb)->'items'), 0,
  'an empty list matches no device');
select is(jsonb_array_length(public.log_query('{"deviceIds": null}'::jsonb)->'items'), 4,
  'a null restricts nothing');
select is(jsonb_array_length(public.log_query('{"deviceIds": "dev-a"}'::jsonb)->'items'), 4,
  'a scalar restricts nothing');
select is((select array_agg(i->>'event') from jsonb_array_elements(public.log_query(
    '{"deviceIds": ["dev-a", "dev-b", "dev-c"], "levels": ["error"]}'::jsonb)->'items') i),
  array['c.one', 'a.one'], 'the device filter combines with the others, newest first');
select is(public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items'->0->>'device_id', 'dev-a',
  'a compact row carries its device');
select is(length(public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items'->0->>'error_message'), 300,
  'a compact row carries the first 300 characters of its error message');

select * from finish();
rollback;
