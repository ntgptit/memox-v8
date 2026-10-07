begin;
create extension if not exists pgtap with schema extensions;
select plan(5);
-- DEV-199: every synced entity type is handled in four server functions, and
-- each migration slice rewrites all four in full. Forgetting one place gives
-- SYNC_ENTITY_UNSUPPORTED or a type missing from the feed, and each slice's own
-- test only covers its own type. This file reads the four definitions and
-- holds their type sets equal: the types push_one accepts, the ones
-- apply_operation upserts and deletes, the ones sync_changes emits and the
-- ones current_change returns.

-- The distinct, sorted entity types named in p_text by p_pattern. The
-- pattern's one capture group holds either a single type or a quoted list
-- such as 'a', 'b'.
create function pg_temp.types_in(p_text text, p_pattern text) returns text[]
language sql as $$
  select coalesce(array_agg(distinct t order by t), '{}')
  from regexp_matches(p_text, p_pattern, 'g') as m(g),
       regexp_matches(m.g[1], '([a-z_]+)', 'g') as q(v),
       lateral (select q.v[1] as t) as x
$$;

create function pg_temp.def(p_fn text) returns text language sql as $$
  select pg_get_functiondef(p_fn::regproc)
$$;

-- apply_operation's two branches, split at the delete branch.
create function pg_temp.apply_branch(p_kind text) returns text language sql as $$
  select case p_kind
    when 'upsert' then split_part(pg_temp.def('private.apply_operation'), $q$p_kind = 'delete'$q$, 1)
    else split_part(pg_temp.def('private.apply_operation'), $q$p_kind = 'delete'$q$, 2)
  end
$$;

-- The single list of types the wire accepts. Adding an entity changes this
-- line and the four functions together.
select is(
  pg_temp.types_in(pg_temp.def('private.push_one'), $q$v_type not in \(([^)]*)\)$q$),
  array['account_settings', 'card', 'card_schedule', 'deck', 'delete_batch', 'review_log', 'tag'],
  'push_one accepts the seven synced entity types');

select is(
  pg_temp.types_in(pg_temp.def('private.current_change'), $q$p_type = '([a-z_]+)'$q$),
  pg_temp.types_in(pg_temp.def('private.push_one'), $q$v_type not in \(([^)]*)\)$q$),
  'current_change returns the current row of every type push_one accepts');

select is(
  pg_temp.types_in(pg_temp.apply_branch('upsert'), $q$p_type (?:= |in \()('[^)]*?'(?:, '[a-z_]+')*)$q$),
  pg_temp.types_in(pg_temp.def('private.push_one'), $q$v_type not in \(([^)]*)\)$q$),
  'apply_operation upserts every type push_one accepts');

-- account_settings is one row per user and is never deleted (spec account
-- settings sync); every other type has a delete branch.
select is(
  pg_temp.types_in(pg_temp.apply_branch('delete'), $q$p_type (?:= |in \()('[^)]*?'(?:, '[a-z_]+')*)$q$),
  array_remove(pg_temp.types_in(pg_temp.def('private.push_one'), $q$v_type not in \(([^)]*)\)$q$),
    'account_settings'),
  'apply_operation deletes every type push_one accepts but account_settings');

select is(
  pg_temp.types_in(pg_temp.def('public.sync_changes'), $q$\(select '([a-z_]+)'$q$),
  pg_temp.types_in(pg_temp.def('private.push_one'), $q$v_type not in \(([^)]*)\)$q$),
  'sync_changes emits every type push_one accepts');

select * from finish();
rollback;
