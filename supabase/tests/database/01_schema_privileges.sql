begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select has_table('public', 'deck', 'deck exists');
select has_table('public', 'delete_batch', 'delete_batch exists');
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relname in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')
     and c.relrowsecurity),
  4, 'RLS is on for every sync table');
select is(
  (select count(*)::int from pg_policies where schemaname = 'public'
     and tablename in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')),
  0, 'no policy opens a table to clients');
select is(
  (select count(*)::int from information_schema.role_table_grants
   where table_schema = 'public'
     and table_name in ('deck', 'delete_batch', 'user_sync_version', 'sync_applied_op')
     and grantee in ('anon', 'authenticated', 'PUBLIC')),
  0, 'client roles hold no table privilege');
select ok(not has_schema_privilege('authenticated', 'private', 'usage'),
  'clients cannot use the private schema');

select * from finish();
rollback;
