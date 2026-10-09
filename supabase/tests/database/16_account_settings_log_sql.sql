begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
-- The user these tests act as (the owned tables reference auth.users, 20261010000000).
insert into auth.users (id) values ('aaaaaaaa-0000-0000-0000-000000000001') on conflict (id) do nothing;

create function public.t_nil() returns uuid language sql immutable as $$
  select '00000000-0000-0000-0000-000000000000'::uuid $$;
create function public.t_settings(p_extra jsonb) returns jsonb language sql as $$
  select jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random', 'themeMode', 'dark',
    'language', 'vi', 'updatedAt', '2026-10-07T00:00:00Z') || p_extra $$;
create function public.t_op(p_op int, p_row jsonb) returns jsonb language sql as $$
  select jsonb_build_object('opId', format('00000000-0000-0000-0000-%s', lpad((200000 + p_op)::text, 12, '0')),
    'entityType', 'account_settings', 'entityId', public.t_nil(), 'op', 'upsert', 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_row() returns jsonb language sql as $$
  select c->'row' from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'account_settings' $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- SQL log switch spec §3.3: the fifth synced column.
select is(public.t_push(jsonb_build_array(public.t_op(1, public.t_settings('{"logSqlStatements": false}'))))->0->>'status',
  'applied', 'a push with the switch is applied');
select is(public.t_row()->>'logSqlStatements', 'false', 'the switch reads back as a boolean');
select is(public.t_push(jsonb_build_array(public.t_op(2, public.t_settings('{}'))))->0->>'status',
  'applied', 'a push without the key is applied');
select is(public.t_row()->>'logSqlStatements', 'true', 'a push without the key stores true (an older app)');

select * from finish();
rollback;
