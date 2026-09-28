begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select ok(not has_function_privilege('anon', 'public.sync_push(jsonb)', 'execute'), 'anon cannot push');
select ok(not has_function_privilege('anon', 'public.sync_changes(bigint, integer)', 'execute'), 'anon cannot pull');
select ok(has_function_privilege('authenticated', 'public.sync_push(jsonb)', 'execute'), 'a user can push');
select ok(has_function_privilege('authenticated', 'public.sync_changes(bigint, integer)', 'execute'), 'a user can pull');
select ok(not has_function_privilege('authenticated', 'private.deck_upsert(uuid, uuid, uuid, jsonb)', 'execute'),
  'private helpers are not callable');
set local role anon;
select is(public.ping(), 'ok', 'anon can ping');

select * from finish();
rollback;
