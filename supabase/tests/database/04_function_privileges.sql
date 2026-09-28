begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

select ok(not has_function_privilege('anon', 'public.sync_push(jsonb)', 'execute'), 'anon cannot push');
select ok(not has_function_privilege('anon', 'public.sync_changes(bigint, integer)', 'execute'), 'anon cannot pull');
select ok(has_function_privilege('authenticated', 'public.sync_push(jsonb)', 'execute'), 'a user can push');
select ok(has_function_privilege('authenticated', 'public.sync_changes(bigint, integer)', 'execute'), 'a user can pull');
select ok(not has_function_privilege('authenticated', 'private.deck_upsert(uuid, uuid, uuid, jsonb)', 'execute'),
  'private helpers are not callable');
-- Every private function, those later migrations add included: a new function gets
-- EXECUTE for PUBLIC by default, so each migration must revoke it.
select is(
  (select array_agg(p.oid::regprocedure::text order by 1) from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'private'
     and (has_function_privilege('anon', p.oid, 'execute')
       or has_function_privilege('authenticated', p.oid, 'execute'))),
  null, 'no private function is executable by a client role');
set local role anon;
select is(public.ping(), 'ok', 'anon can ping');

select * from finish();
rollback;
