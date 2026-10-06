begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
-- The users these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-00000000000a'), ('cccccccc-0000-0000-0000-000000000001')
on conflict (id) do nothing;

create function public.t_nil() returns uuid language sql immutable as $$
  select '00000000-0000-0000-0000-000000000000'::uuid $$;
create function public.t_settings(p_theme text) returns jsonb language sql as $$
  select jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random', 'themeMode', p_theme,
    'language', 'vi', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_op(p_op int, p_id uuid, p_kind text, p_row jsonb) returns jsonb language sql as $$
  select jsonb_build_object('opId', format('00000000-0000-0000-0000-%s', lpad((100000 + p_op)::text, 12, '0')),
    'entityType', 'account_settings', 'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_changes() returns jsonb language sql as $$
  select coalesce(jsonb_agg(c), '[]') from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'account_settings' $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(public.t_push(jsonb_build_array(public.t_op(1, public.t_nil(), 'upsert', public.t_settings('dark'))))->0->>'status',
  'applied', 'settings are applied');
select is(public.t_changes()->0,
  jsonb_build_object('entityType', 'account_settings', 'entityId', public.t_nil(), 'serverVersion', 1,
    'deleted', false, 'row', jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random',
      'themeMode', 'dark', 'language', 'vi', 'updatedAt', '2026-09-28T00:00:00.000000Z')),
  'settings read back in the wire shape, under the nil id');
select is(public.t_push(jsonb_build_array(public.t_op(2, public.t_nil(), 'upsert', public.t_settings('light'))))->0->>'status',
  'applied', 'a second upsert is applied');
select is(jsonb_array_length(public.t_changes()), 1, 'one row per user');
select is(public.t_changes()->0->'row'->>'themeMode', 'light', 'the later upsert wins');
select is(public.t_push(jsonb_build_array(public.t_op(3, '00000000-0000-0000-0000-000000000001', 'upsert',
    public.t_settings('dark'))))->0->>'code', 'VALIDATION_FAILED', 'only the nil id names the settings');
select is(public.t_push(jsonb_build_array(public.t_op(4, public.t_nil(), 'upsert', public.t_settings('neon'))))->0->>'code',
  'VALIDATION_FAILED', 'a theme outside the CHECK is refused');
select is(public.t_push(jsonb_build_array(public.t_op(5, public.t_nil(), 'delete', null)))->0->>'code',
  'VALIDATION_FAILED', 'settings are never deleted');
-- DEV-214: the server keeps card_limit inside 1..200 (BR-STUDY-003), as the app does; the
-- refusal carries the row the server holds, so the pushing device applies it.
select is(public.t_push(jsonb_build_array(public.t_op(6, public.t_nil(), 'upsert',
    public.t_settings('light') || '{"cardLimit": 0}'::jsonb)))->0->>'code',
  'VALIDATION_FAILED', 'a card limit below 1 is refused');
select is(public.t_push(jsonb_build_array(public.t_op(7, public.t_nil(), 'upsert',
    public.t_settings('light') || '{"cardLimit": 201}'::jsonb)))->0->'current'->'row'->>'cardLimit',
  '30', 'a card limit above 200 is refused with the row the server holds');
select is(public.t_push(jsonb_build_array(public.t_op(8, public.t_nil(), 'upsert',
    public.t_settings('light') || '{"cardLimit": 200}'::jsonb)))->0->>'status',
  'applied', 'the upper bound itself is applied');

select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.t_changes(), '[]'::jsonb, 'another user sees no settings');

select * from finish();
rollback;
