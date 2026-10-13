begin;
create extension if not exists pgtap with schema extensions;
select plan(84);

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

-- A sync_push request that creates one root deck, under a given or a fresh op id.
create function public.t_root_push_as(p_id uuid, p_op uuid) returns jsonb language sql as $$
  select jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(jsonb_build_object('opId', p_op, 'entityType', 'deck',
      'entityId', p_id, 'op', 'upsert', 'row', jsonb_build_object(
        'id', p_id, 'name', 'Back', 'parentId', null, 'rootId', p_id, 'depth', 1, 'contentType', 'deck',
        'schedulerType', 'eight_box', 'schedulerVersion', 1, 'schedulerConfig', '{}',
        'studyConfig', '{}', 'generation', 1, 'firstAnsweredAt', null, 'sourceTemplateId', null,
        'sourceTemplateVersion', null, 'deleteBatchId', null, 'siblingPosition', 0,
        'createdAt', '2026-09-30T00:00:00.000Z', 'updatedAt', '2026-09-30T00:00:00.000Z')))) $$;
create function public.t_root_push(p_id uuid) returns jsonb language sql as $$
  select public.t_root_push_as(p_id, gen_random_uuid()) $$;

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

-- An access token outlives its user (spec §10): sync_push refuses the whole call for want of
-- a profile (DEV-192, 14_sync_requires_profile.sql), and nothing is stored.
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000004',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.sync_push(public.t_root_push('12000000-0000-0000-0000-0000000000f1')) $$,
  'P0001', 'UNAUTHORIZED', 'a deleted user''s push is refused');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000005',
  'role', 'authenticated')::text, true);
select is(public.sync_push(public.t_root_push('12000000-0000-0000-0000-0000000000f2'))->'results'->0->>'status',
  'applied', 'the same push from a live user is applied');
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

-- Claim, merge, acknowledge (spec §2.3, O4, O5).
-- S anonymous (source), T account (target), X another account. S and T both have a live tag
-- "verb"; S also has a tombstoned tag "noun" while T has a live "noun".
select public.t_user('12000000-0000-0000-0000-000000000011', null, true);                -- S
select public.t_user('12000000-0000-0000-0000-000000000012', 't@example.com', false);    -- T
select public.t_user('12000000-0000-0000-0000-000000000013', 'x@example.com', false);    -- X
select public.t_seed('12000000-0000-0000-0000-000000000011', 'Verb', true);
select public.t_seed('12000000-0000-0000-0000-000000000012', 'verb', true);
insert into public.tags (id, user_id, name, name_folded, created_at, server_version, last_device_id, deleted_at)
values ('12000000-0000-0000-0000-0000000000a1', '12000000-0000-0000-0000-000000000011', 'noun', 'noun',
  now(), private.allocate_versions('12000000-0000-0000-0000-000000000011', 1),
  '00000000-0000-0000-0000-0000000000d1', now()),
  ('12000000-0000-0000-0000-0000000000a2', '12000000-0000-0000-0000-000000000012', 'noun', 'noun',
  now(), private.allocate_versions('12000000-0000-0000-0000-000000000012', 1),
  '00000000-0000-0000-0000-0000000000d1', null);
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000011';
update public.account_settings set theme_mode = 'light' where user_id = '12000000-0000-0000-0000-000000000012';
select set_config('t.top', private.current_version('12000000-0000-0000-0000-000000000012')::text, true);

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_claim_begin() $$, 'P0001', 'NOT_ANONYMOUS',
  'an account cannot hand out a claim');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000011',
  'role', 'authenticated')::text, true);
select set_config('t.token', public.account_claim_begin()::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c1') $$, 'P0001', 'NOT_PERMANENT', 'an anonymous user cannot merge');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(gen_random_uuid(), '12000000-0000-0000-0000-0000000000c1') $$,
  'P0001', 'CLAIM_INVALID', 'a wrong token is refused');
select is(public.account_merge(current_setting('t.token')::uuid, '12000000-0000-0000-0000-0000000000c1'),
  '{"status": "MERGED"}'::jsonb, 'the account merges the anonymous data');
select is(public.account_merge(current_setting('t.token')::uuid, '12000000-0000-0000-0000-0000000000c1'),
  '{"status": "MERGED"}'::jsonb, 'a retry with the same operation says MERGED again');
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c2') $$, 'P0001', 'CLAIM_INVALID',
  'a used token with another operation is refused');
-- Moved: the batch, two decks, the tombstoned tag, the card, its schedule and its review (the
-- live "Verb" merged into the account's tag and the settings gave way to the account's).
select is(jsonb_array_length(public.sync_changes(current_setting('t.top')::bigint, 500)->'changes'), 7,
  'the moved rows reach the account''s other devices as new changes');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000013',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token')::uuid,
  '12000000-0000-0000-0000-0000000000c1') $$, 'P0001', 'CLAIM_INVALID',
  'another user learns nothing from the operation id');
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'another user''s acknowledgement is a no-op');
reset role;

select ok(not exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000011'),
  'the anonymous user is gone');
select is(public.t_owned('12000000-0000-0000-0000-000000000011'), 0, 'it owns nothing any more');
select is((select count(*)::int from public.deck where user_id = '12000000-0000-0000-0000-000000000012'), 4,
  'the account has both libraries');
select is((select count(*)::int from public.tags where user_id = '12000000-0000-0000-0000-000000000012'
  and deleted_at is null and name_folded = 'verb'), 1, 'live tags with the same name become one');
select is((select tag_id from public.card_tags
  where card_id = md5('12000000-0000-0000-0000-000000000011' || 'card')::uuid),
  md5('12000000-0000-0000-0000-000000000012' || 'tag')::uuid, 'the moved card points at the account''s tag');
select ok(exists (select 1 from public.tags where id = '12000000-0000-0000-0000-0000000000a1'
  and user_id = '12000000-0000-0000-0000-000000000012' and deleted_at is not null),
  'a tombstoned tag moves as it is, beside a live one of the same name');
select is((select theme_mode from public.account_settings
  where user_id = '12000000-0000-0000-0000-000000000012'), 'light', 'the account keeps its own settings');
select ok((select min(server_version) from public.card where id = md5('12000000-0000-0000-0000-000000000011' || 'card')::uuid)
  > current_setting('t.top')::bigint, 'moved rows get versions above the account''s last one');
select is((select role from public.profiles where id = '12000000-0000-0000-0000-000000000012'), 'user',
  'the anonymous user''s role is not carried over');
select ok(exists (select 1 from public.account_merge_receipt where operation_id = '12000000-0000-0000-0000-0000000000c1'
  and acknowledged_at is null), 'a receipt records the merge, not yet acknowledged');
select is((select count(*)::int from public.app_log where user_id = '12000000-0000-0000-0000-000000000012'), 2,
  'the logs moved with the data');
select is((select count(*)::int from pg_class c where c.oid in ('public.account_claim'::regclass,
  'public.account_merge_receipt'::regclass) and c.relrowsecurity), 2, 'RLS is on for claims and receipts');

set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000012',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'the account acknowledges its merge');
select lives_ok($$ select public.account_merge_ack('12000000-0000-0000-0000-0000000000c1') $$,
  'acknowledging twice is fine');
reset role;
select ok((select acknowledged_at is not null from public.account_merge_receipt
  where operation_id = '12000000-0000-0000-0000-0000000000c1'), 'the receipt is acknowledged');

-- A target without settings takes the source's; an expired claim is refused.
select public.t_user('12000000-0000-0000-0000-000000000014', null, true);
select public.t_user('12000000-0000-0000-0000-000000000015', 'u@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000014', 'solo', true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000014',
  'role', 'authenticated')::text, true);
select set_config('t.token2', public.account_claim_begin()::text, true);
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select is(public.account_merge(current_setting('t.token2')::uuid, '12000000-0000-0000-0000-0000000000c3')->>'status',
  'MERGED', 'a merge into an empty account');
reset role;
select is((select theme_mode from public.account_settings
  where user_id = '12000000-0000-0000-0000-000000000015'), 'dark', 'an account without settings takes the source''s');
select public.t_user('12000000-0000-0000-0000-000000000016', null, true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000016',
  'role', 'authenticated')::text, true);
select set_config('t.token3', public.account_claim_begin()::text, true);
reset role;
update public.account_claim set expires_at = now() - interval '1 second'
  where source_user_id = '12000000-0000-0000-0000-000000000016';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token3')::uuid,
  '12000000-0000-0000-0000-0000000000c4') $$, 'P0001', 'CLAIM_INVALID', 'an expired claim is refused');
reset role;
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000016'),
  'a refused merge leaves the anonymous user in place');

-- Deletion (spec §2.3, O7).
select public.t_user('12000000-0000-0000-0000-000000000021', 'del@example.com', false);
select public.t_seed('12000000-0000-0000-0000-000000000021', 'gone', true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000021',
  'role', 'authenticated')::text, true);
select lives_ok($$ select public.account_delete() $$, 'a user deletes their account');
select throws_ok($$ select public.me() $$, 'P0001', 'UNAUTHORIZED', 'the old token finds no account');
select throws_ok($$ select public.account_delete() $$, 'P0001', 'UNAUTHORIZED',
  'a retry after the deletion is told the account is gone');
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000007',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_delete() $$, 'P0001', 'LAST_ADMIN',
  'the last admin cannot delete their account');
reset role;
select is(public.t_owned('12000000-0000-0000-0000-000000000021'), 0, 'the deleted account owns nothing');
select ok(has_function_privilege('authenticated', 'public.account_delete()', 'execute')
  and not has_function_privilege('anon', 'public.account_delete()', 'execute'),
  'only a signed-in user can delete an account');

-- Cleanup: anonymous users away 90 days go; others stay; acknowledged receipts and spent claims go.
-- An unacknowledged receipt stays whatever its age (DEV-188): the device that merged may come
-- back months later and retry; a committed merge never returns to the source.
select public.t_user('12000000-0000-0000-0000-000000000022', null, true);
select public.t_user('12000000-0000-0000-0000-000000000023', null, true);
select public.t_user('12000000-0000-0000-0000-000000000024', 'old@example.com', false);
update public.profiles set last_active_at = now() - interval '91 days'
  where id in ('12000000-0000-0000-0000-000000000022', '12000000-0000-0000-0000-000000000024');
insert into public.account_merge_receipt (operation_id, source_user_id, target_user_id, expires_at,
  acknowledged_at)
values ('12000000-0000-0000-0000-0000000000e1', gen_random_uuid(), '12000000-0000-0000-0000-000000000024',
  now() - interval '100 days', null),
  ('12000000-0000-0000-0000-0000000000e2', gen_random_uuid(), '12000000-0000-0000-0000-000000000024',
  now() + interval '7 days', null),
  ('12000000-0000-0000-0000-0000000000e3', gen_random_uuid(), '12000000-0000-0000-0000-000000000024',
  now() + interval '7 days', now());
-- DEV-200: applied op ids older than 90 days go; a resent one is simply applied again.
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000024',
  'role', 'authenticated')::text, true);
select is(public.sync_push(public.t_root_push_as('12000000-0000-0000-0000-0000000000f3',
    '12000000-0000-0000-0000-0000000000a1'))->'results'->0->>'status', 'applied',
  'an op applied before the cleanup');
reset role;
update public.sync_applied_op set applied_at = now() - interval '91 days'
  where op_id = '12000000-0000-0000-0000-0000000000a1';
insert into public.sync_applied_op (user_id, op_id, server_version)
values ('12000000-0000-0000-0000-000000000024', '12000000-0000-0000-0000-0000000000a2', 1);
select private.cleanup_accounts();
select ok(not exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000022'),
  'an anonymous user away 90 days is deleted');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000023'),
  'an active anonymous user stays');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000024'),
  'an account is never cleaned up');
select is((select array_agg(operation_id::text order by operation_id) from public.account_merge_receipt
  where target_user_id = '12000000-0000-0000-0000-000000000024'),
  array['12000000-0000-0000-0000-0000000000e1', '12000000-0000-0000-0000-0000000000e2'],
  'an acknowledged receipt goes; an unacknowledged one stays however old');
select ok(not exists (select 1 from public.sync_applied_op where op_id = '12000000-0000-0000-0000-0000000000a1'),
  'an op id applied over 90 days ago is forgotten');
select ok(exists (select 1 from public.sync_applied_op where op_id = '12000000-0000-0000-0000-0000000000a2'),
  'a recent op id is kept');
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000024',
  'role', 'authenticated')::text, true);
select is(public.sync_push(public.t_root_push_as('12000000-0000-0000-0000-0000000000f3',
    '12000000-0000-0000-0000-0000000000a1'))->'results'->0->>'status', 'applied',
  'a forgotten op id resent is applied again, as the same upsert');
reset role;


-- Final review I1/I2: sync or log activity keeps an anonymous user even before the app calls
-- me(); an admin is never cleaned up.
select public.t_user('12000000-0000-0000-0000-000000000031', null, true);
select public.t_user('12000000-0000-0000-0000-000000000032', null, true);
select public.t_user('12000000-0000-0000-0000-000000000033', null, true);
update public.profiles set last_active_at = now() - interval '120 days'
  where id in ('12000000-0000-0000-0000-000000000031', '12000000-0000-0000-0000-000000000032',
    '12000000-0000-0000-0000-000000000033');
update public.profiles set role = 'admin' where id = '12000000-0000-0000-0000-000000000033';
insert into public.sync_applied_op (user_id, op_id, server_version)
values ('12000000-0000-0000-0000-000000000031', gen_random_uuid(), 1);
insert into public.app_log (id, occurred_at, level, category, event, user_id)
values (gen_random_uuid(), now(), 'info', 'sync', 't12.active', '12000000-0000-0000-0000-000000000032');
select private.cleanup_accounts();
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000031'),
  'a push in the last 90 days keeps an anonymous user');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000032'),
  'a log in the last 90 days keeps an anonymous user');
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000033'),
  'an admin is never cleaned up');

-- Final review I2: a merge never deletes the last admin.
select public.t_user('12000000-0000-0000-0000-000000000034', null, true);
update public.profiles set role = case when id = '12000000-0000-0000-0000-000000000034' then 'admin' else 'user' end
  where role = 'admin' or id = '12000000-0000-0000-0000-000000000034';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000034',
  'role', 'authenticated')::text, true);
select set_config('t.token4', public.account_claim_begin()::text, true);
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token4')::uuid,
  '12000000-0000-0000-0000-0000000000c5') $$, 'P0001', 'LAST_ADMIN', 'the last admin is not merged away');
reset role;
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000034'),
  'the last admin keeps their user');

-- Final review: a source that became an account after its claim is not merged away.
select public.t_user('12000000-0000-0000-0000-000000000035', null, true);
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000035',
  'role', 'authenticated')::text, true);
select set_config('t.token5', public.account_claim_begin()::text, true);
reset role;
update auth.users set is_anonymous = false, email = 'linked@example.com'
  where id = '12000000-0000-0000-0000-000000000035';
set local role authenticated;
select set_config('request.jwt.claims', jsonb_build_object('sub', '12000000-0000-0000-0000-000000000015',
  'role', 'authenticated')::text, true);
select throws_ok($$ select public.account_merge(current_setting('t.token5')::uuid,
  '12000000-0000-0000-0000-0000000000c6') $$, 'P0001', 'CLAIM_INVALID',
  'a claim of a user who has since linked an account is refused');
reset role;
select ok(exists (select 1 from auth.users where id = '12000000-0000-0000-0000-000000000035'),
  'the linked account is untouched');

select * from finish();
rollback;
