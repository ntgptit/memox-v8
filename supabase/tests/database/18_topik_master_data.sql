-- supabase/tests/database/18_topik_master_data.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);
-- ADR-024, spec 2026-10-16 §5: Master Data tables behind RLS with no policy; a
-- published version and the audit log are immutable.

-- ============================================================================
-- Tables, privileges and immutability (Task 1)
-- ============================================================================
select has_table('public', 'topik_test_draft', 'draft table exists');
select has_table('public', 'topik_test_version', 'version table exists');
select has_table('public', 'topik_publication', 'publication table exists');
select has_table('public', 'topik_master_audit', 'audit table exists');
select ok(not has_table_privilege('authenticated', 'public.topik_test_draft', 'select'),
  'clients cannot read drafts directly');
select ok(not has_table_privilege('authenticated', 'public.topik_test_version', 'select'),
  'clients cannot read versions directly');
select ok(not has_table_privilege('authenticated', 'public.topik_publication', 'select'),
  'clients cannot read publications directly');
select ok(not has_table_privilege('authenticated', 'public.topik_master_audit', 'select'),
  'clients cannot read the audit log directly');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_test_draft'::regclass),
  'draft has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_test_version'::regclass),
  'version has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_publication'::regclass),
  'publication has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.topik_master_audit'::regclass),
  'audit has RLS');

-- As postgres (the test role), a version cannot be changed or removed.
insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_at, published_by, note)
values ('topik2-96-reading', 1, '{"testId":"topik2-96-reading","contentVersion":1}'::jsonb, '[]'::jsonb,
  'abc', now(), null, 'first');
select throws_like(
  $$update public.topik_test_version set note = 'edited' where test_id = 'topik2-96-reading'$$,
  '%immutable%', 'a published version cannot be updated');
select throws_like(
  $$delete from public.topik_test_version where test_id = 'topik2-96-reading'$$,
  '%immutable%', 'a published version cannot be deleted');
insert into public.topik_master_audit (id, at, actor, action, test_id, content_version, detail)
values (gen_random_uuid(), now(), null, 'publish', 'topik2-96-reading', 1, '{}'::jsonb);
select throws_like(
  $$delete from public.topik_master_audit where test_id = 'topik2-96-reading'$$,
  '%append-only%', 'the audit log cannot be deleted from');

select throws_like($$truncate public.topik_test_version cascade$$, '%immutable%',
  'a published version cannot be truncated');
select throws_like($$truncate public.topik_master_audit$$, '%append-only%',
  'the audit log cannot be truncated');

-- Deleting an account nulls published_by and actor (on delete set null, an
-- internal UPDATE); that is the one change the triggers allow.
insert into auth.users (id, email, is_anonymous)
values ('18000000-0000-0000-0000-000000000001', 'publisher@example.com', false);
insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_by, note)
values ('topik2-97-reading', 1, '{"testId":"topik2-97-reading","contentVersion":1}'::jsonb, '[]'::jsonb,
  'def', '18000000-0000-0000-0000-000000000001', 'by publisher');
insert into public.topik_master_audit (id, actor, action, test_id, content_version)
values ('18000000-0000-0000-0000-0000000000a1', '18000000-0000-0000-0000-000000000001',
  'publish', 'topik2-97-reading', 1);
select lives_ok($$delete from auth.users where id = '18000000-0000-0000-0000-000000000001'$$,
  'deleting a publisher nulls published_by and actor');
select is((select published_by from public.topik_test_version where test_id = 'topik2-97-reading'), null,
  'published_by is null after the publisher is deleted');
select is((select actor from public.topik_master_audit where id = '18000000-0000-0000-0000-0000000000a1'), null,
  'actor is null after the actor is deleted');
select throws_like(
  $$update public.topik_master_audit set test_id = 'x' where id = '18000000-0000-0000-0000-0000000000a1'$$,
  '%append-only%', 'an audit row with a null actor still cannot be edited');

select * from finish();
rollback;
