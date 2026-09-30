begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

-- Auth spec 2026-09-30 §2 (20261010000000_accounts.sql).
create function public.t_user(p_id uuid, p_email text, p_anonymous boolean) returns uuid
  language sql as $$
  insert into auth.users (id, email, is_anonymous) values (p_id, p_email, p_anonymous) returning id $$;

select has_table('public', 'profiles', 'profiles exists');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'RLS is on for profiles');
select is((select count(*)::int from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'profiles'
    and grantee in ('anon', 'authenticated', 'PUBLIC')), 0, 'no client privilege on profiles');

select public.t_user('12000000-0000-0000-0000-000000000001', 'p@example.com', false);
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000001'),
  'user', 'a new permanent user gets a profile with the user role');
select public.t_user('12000000-0000-0000-0000-000000000002', null, true);
select ok(exists (select 1 from public.profiles where id = '12000000-0000-0000-0000-000000000002'),
  'a new anonymous user gets a profile');

-- The backfill: a user without a profile gets one, with the admin role from app_metadata.
update auth.users set raw_app_meta_data = '{"role": "admin"}'
  where id = '12000000-0000-0000-0000-000000000001';
delete from public.profiles where id = '12000000-0000-0000-0000-000000000001';
select private.backfill_profiles();
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000001'),
  'admin', 'the backfill recreates a missing profile and copies the admin role');
select lives_ok($$ select private.backfill_profiles() $$, 'the backfill runs twice without error');
update public.profiles set role = 'user' where id = '12000000-0000-0000-0000-000000000001';

-- is_admin reads profiles, not the JWT (spec §2.3).
select public.t_user('12000000-0000-0000-0000-000000000003', 'a@example.com', false);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000003';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000002',
  'role', 'authenticated', 'app_metadata', jsonb_build_object('role', 'admin'))::text, true);
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'an admin claim in the JWT alone is not an admin');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000003',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.log_query('{}'::jsonb) $$, 'a profile with the admin role is an admin');
reset role;
update public.profiles set role = 'user' where id = '12000000-0000-0000-0000-000000000003';
set local role authenticated;
select throws_ok($$ select public.log_query('{}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a role change counts at once, without a new token');
reset role;

select * from finish();
rollback;
