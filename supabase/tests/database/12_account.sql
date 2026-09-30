begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

-- Auth spec 2026-09-30 §2 (20261010000000_accounts.sql).
create function public.t_user(p_id uuid, p_email text, p_anonymous boolean) returns uuid
  language sql as $$
  insert into auth.users (id, email, is_anonymous) values (p_id, p_email, p_anonymous) returning id $$;

-- One user's whole library, written as postgres: root and child deck, a card tagged p_tag,
-- a review, a schedule, a trash batch, settings when asked, a log. Versions come from the
-- user's counter, as sync_push would take them.
create function public.t_seed(p_user uuid, p_tag text, p_settings boolean) returns void
  language plpgsql as $$
declare
  v_top bigint := private.allocate_versions(p_user, 8);
  v_base bigint := v_top - 8;
  v_root uuid := md5(p_user::text || 'root')::uuid;
  v_child uuid := md5(p_user::text || 'child')::uuid;
  v_card uuid := md5(p_user::text || 'card')::uuid;
  v_tag uuid := md5(p_user::text || 'tag')::uuid;
  v_dev uuid := '00000000-0000-0000-0000-0000000000d1';
begin
  insert into public.deck (id, user_id, name, parent_id, root_id, depth, content_type, scheduler_type,
    scheduler_version, scheduler_config, study_config, generation, sibling_position, created_at,
    updated_at, server_version, last_device_id)
  values (v_root, p_user, 'Root', null, v_root, 1, 'deck', 'eight_box', 1, '{}', '{}', 1, 0, now(),
      now(), v_base + 1, v_dev),
    (v_child, p_user, 'Child', v_root, v_root, 2, 'card', null, null, null, null, null, 0, now(),
      now(), v_base + 2, v_dev);
  insert into public.card (id, user_id, deck_id, front, back, is_flagged, created_at, updated_at,
    server_version, last_device_id)
  values (v_card, p_user, v_child, 'front', 'back', false, now(), now(), v_base + 3, v_dev);
  insert into public.tags (id, user_id, name, name_folded, created_at, server_version, last_device_id)
  values (v_tag, p_user, p_tag, lower(p_tag), now(), v_base + 4, v_dev);
  insert into public.card_tags (card_id, tag_id) values (v_card, v_tag);
  insert into public.review_log (id, user_id, card_id, session_id, scheduler_type, generation, kind,
    mode, action, answered_at, server_version, last_device_id)
  values (md5(p_user::text || 'review')::uuid, p_user, v_card, 's1', 'eight_box', 1, 'learning',
    'browse', 'remembered', now(), v_base + 5, v_dev);
  insert into public.card_schedule (card_id, user_id, scheduler_type, scheduler_version, generation,
    answer_count, lapse_count, current_box, server_version, last_device_id)
  values (v_card, p_user, 'eight_box', 1, 1, 1, 0, 1, v_base + 6, v_dev);
  insert into public.delete_batch (id, user_id, item_type, root_item_id, deleted_at, server_version,
    last_device_id)
  values (md5(p_user::text || 'batch')::uuid, p_user, 'deck', v_root, now(), v_base + 7, v_dev);
  if p_settings then
    insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language,
      updated_at, server_version, last_device_id)
    values (p_user, 20, 'created', 'dark', 'en', now(), v_base + 8, v_dev);
  end if;
  insert into public.app_log (id, occurred_at, level, category, event, user_id)
  values (md5(p_user::text || 'log')::uuid, now(), 'info', 'sync', 't12.seed', p_user);
end
$$;

-- Rows a user owns, across every owned table.
create function public.t_owned(p_user uuid) returns int language sql as $$
  select ((select count(*) from public.deck where user_id = p_user)
    + (select count(*) from public.card where user_id = p_user)
    + (select count(*) from public.tags where user_id = p_user)
    + (select count(*) from public.review_log where user_id = p_user)
    + (select count(*) from public.card_schedule where user_id = p_user)
    + (select count(*) from public.delete_batch where user_id = p_user)
    + (select count(*) from public.account_settings where user_id = p_user)
    + (select count(*) from public.user_sync_version where user_id = p_user)
    + (select count(*) from public.app_log where user_id = p_user))::int $$;

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

-- Deleting a user removes everything it owns, in one statement (spec §2.2).
select public.t_user('12000000-0000-0000-0000-000000000004', 'd@example.com', false);
select public.t_user('12000000-0000-0000-0000-000000000005', 'o@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000004', 'Verb', true);
select public.t_seed('12000000-0000-0000-0000-000000000005', 'Noun', true);
select lives_ok($$ delete from auth.users where id = '12000000-0000-0000-0000-000000000004' $$,
  'a user who owns a whole library can be deleted');
select is(public.t_owned('12000000-0000-0000-0000-000000000004'), 0, 'nothing of it is left');
select is(public.t_owned('12000000-0000-0000-0000-000000000005'), 10, 'another user keeps all of theirs');

-- An access token outlives its user; the keys stop it from writing (spec §10).
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000004',
  'role', 'authenticated')::text, true);
do $$
begin
  perform public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(jsonb_build_object('opId', gen_random_uuid(), 'entityType', 'deck',
      'entityId', '12000000-0000-0000-0000-0000000000f1', 'op', 'upsert', 'row', jsonb_build_object(
        'id', '12000000-0000-0000-0000-0000000000f1', 'name', 'Back', 'parentId', null,
        'rootId', '12000000-0000-0000-0000-0000000000f1', 'depth', 1, 'contentType', 'deck',
        'schedulerType', 'eight_box', 'schedulerVersion', 1, 'schedulerConfig', '{}',
        'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null, 'sourceTemplateId', null,
        'sourceTemplateVersion', null, 'deleteBatchId', null, 'siblingPosition', 0,
        'createdAt', '2026-09-30T00:00:00.000Z', 'updatedAt', '2026-09-30T00:00:00.000Z')))));
exception when others then null;
end
$$;
reset role;
select is(public.t_owned('12000000-0000-0000-0000-000000000004'), 0,
  'deleted user cannot recreate persisted data through sync_push');

-- me() (spec §2.3).
select ok(has_function_privilege('authenticated', 'public.me()', 'execute'), 'a user can call me');
select ok(not has_function_privilege('anon', 'public.me()', 'execute'), 'anon cannot call me');
update public.profiles set last_active_at = now() - interval '3 days'
  where id = '12000000-0000-0000-0000-000000000002';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000002',
  'role', 'authenticated')::text, true);
select is(public.me(), jsonb_build_object('id', '12000000-0000-0000-0000-000000000002', 'email', null,
  'isAnonymous', true, 'role', 'user'), 'me() describes an anonymous user');
reset role;
select ok((select last_active_at > now() - interval '1 minute' from public.profiles
  where id = '12000000-0000-0000-0000-000000000002'), 'me() marks a user active after a day away');
update public.profiles set last_active_at = now() - interval '1 hour'
  where id = '12000000-0000-0000-0000-000000000005';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000005',
  'role', 'authenticated')::text, true);
select is(public.me()->>'email', 'o@example.com', 'me() gives the email of an account');
reset role;
select ok((select last_active_at < now() - interval '50 minutes' from public.profiles
  where id = '12000000-0000-0000-0000-000000000005'), 'activity is written at most once a day');
delete from public.profiles where id = '12000000-0000-0000-0000-000000000005';
set local role authenticated;
select throws_ok($$ select public.me() $$, 'P0001', 'UNAUTHORIZED', 'a caller without a profile is refused');
reset role;

-- Roles (spec §2.3, O9).
select public.t_user('12000000-0000-0000-0000-000000000006', 'admin1@example.com', false);
select public.t_user('12000000-0000-0000-0000-000000000007', 'admin2@example.com', false);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000006';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000001',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.role_list(null, null) $$, 'P0001', 'FORBIDDEN', 'a user cannot list roles');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'admin') $$, 'P0001',
  'FORBIDDEN', 'a user cannot grant a role');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000006',
  'role', 'authenticated')::text, true);
select is(public.role_list('admin', null)->'items'->0->>'email', 'admin1@example.com',
  'an admin finds users by email');
select ok(not (public.role_list('', null)->'items' @> jsonb_build_array(jsonb_build_object(
  'id', '12000000-0000-0000-0000-000000000002'))), 'anonymous users are not listed');
select is(public.role_set('12000000-0000-0000-0000-000000000007', 'admin')->>'role', 'admin',
  'an admin grants the admin role');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000002', 'admin') $$, 'P0001',
  'ANONYMOUS_USER', 'an anonymous user cannot be an admin');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-0000000000ff', 'admin') $$, 'P0001',
  'NOT_FOUND', 'an unknown user is not found');
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'owner') $$, 'P0001',
  'INVALID_ROLE', 'only user and admin exist');
-- Two admins: one may demote the other; the last one may not demote itself.
select is(public.role_set('12000000-0000-0000-0000-000000000006', 'user')->>'role', 'user',
  'with two admins, one may be demoted');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000007',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.role_set('12000000-0000-0000-0000-000000000007', 'user') $$, 'P0001',
  'LAST_ADMIN', 'the last admin cannot be demoted');
reset role;
select is((select role_changed_by from public.profiles where id = '12000000-0000-0000-0000-000000000006'),
  '12000000-0000-0000-0000-000000000006'::uuid, 'who changed a role is recorded');
delete from auth.users where id = '12000000-0000-0000-0000-000000000006';
select is((select role_changed_by from public.profiles where id = '12000000-0000-0000-0000-000000000007'),
  null, 'deleting the admin who granted a role clears the record, not the profile');

select * from finish();
rollback;
