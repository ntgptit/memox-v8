begin;
create extension if not exists pgtap with schema extensions;
select plan(5);
-- DEV-192: a deleted user's JWT is live for up to an hour. The sync RPCs
-- refuse it with UNAUTHORIZED at once (private.require_current_profile), as
-- me() does, instead of letting the user_id foreign keys reject every row.

-- P keeps its profile (the auth.users trigger makes it); Q loses it.
insert into auth.users (id, email, is_anonymous) values
  ('14000000-0000-0000-0000-000000000001', 'p@example.com', false),
  ('14000000-0000-0000-0000-000000000002', 'q@example.com', false);
delete from public.profiles where id = '14000000-0000-0000-0000-000000000002';

create function public.t_empty_push() returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d4',
    'operations', '[]'::jsonb)) $$;

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '14000000-0000-0000-0000-000000000001',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.t_empty_push() $$, 'a user with a profile pushes');
select lives_ok($$ select public.sync_changes(0, 10) $$, 'a user with a profile reads changes');

select set_config('request.jwt.claims', jsonb_build_object('sub', '14000000-0000-0000-0000-000000000002',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.t_empty_push() $$, 'P0001', 'UNAUTHORIZED',
  'a push under the JWT of a user without a profile is refused');
select throws_ok($$ select public.sync_changes(0, 10) $$, 'P0001', 'UNAUTHORIZED',
  'a changes read under the JWT of a user without a profile is refused');

select set_config('request.jwt.claims', '', true);
select throws_ok($$ select public.sync_changes(0, 10) $$, 'P0001', 'NOT_AUTHENTICATED',
  'a call with no user is still told so');
reset role;

select * from finish();
rollback;
