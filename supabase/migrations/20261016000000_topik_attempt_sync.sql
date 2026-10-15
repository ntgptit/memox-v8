-- TOPIK spec 2026-10-15 §7.2, §13.3 (ADR-023 #6, BR-TOPIK-026, BR-TOPIK-028):
-- submitted TOPIK attempts sync as insert-only records with a final
-- tombstone. The server checks integrity only; scoring stays in the app
-- (ADR-015). One entity type, topik_attempt; its answers ride in the row.

create table public.topik_attempt (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  test_id text not null,
  level text not null check (level in ('topik1', 'topik2')),
  section text not null check (section in ('listening', 'reading')),
  round integer not null check (round > 0),
  mode text not null check (mode in ('practice')),
  status text not null check (status = 'completed'),
  started_at timestamptz not null,
  completed_at timestamptz not null,
  updated_at timestamptz not null,
  total_time_ms integer not null check (total_time_ms >= 0),
  current_question_no integer not null,
  question_count integer not null check (question_count > 0),
  max_score integer not null check (max_score > 0),
  score integer not null,
  correct_count integer not null,
  answered_count integer not null,
  content_version integer not null check (content_version > 0),
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null,
  check (score between 0 and max_score),
  check (answered_count between 0 and question_count),
  check (correct_count between 0 and answered_count)
);
create unique index uq_topik_attempt_user_version on public.topik_attempt (user_id, server_version);

-- Part of the attempt's row; not a sync entity, so no version (as card_tags).
create table public.topik_attempt_answer (
  attempt_id uuid not null references public.topik_attempt (id) on delete cascade,
  question_no integer not null check (question_no > 0),
  selected_idx integer check (selected_idx between 1 and 4),
  time_spent_ms integer not null check (time_spent_ms >= 0),
  answered_at timestamptz,
  correct_idx integer not null check (correct_idx between 1 and 4),
  points integer not null check (points > 0),
  points_earned integer not null,
  question_type text not null,
  check ((selected_idx is null) = (answered_at is null)),
  check (points_earned = case when selected_idx = correct_idx then points else 0 end),
  primary key (attempt_id, question_no)
);

alter table public.topik_attempt enable row level security;
alter table public.topik_attempt_answer enable row level security;
revoke all on table public.topik_attempt, public.topik_attempt_answer from public, anon, authenticated;

create function private.topik_attempt_change(a public.topik_attempt) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'topik_attempt', 'entityId', a.id, 'serverVersion', a.server_version,
    'deleted', a.deleted_at is not null,
    'row', case when a.deleted_at is not null then null else jsonb_build_object(
      'id', a.id, 'testId', a.test_id, 'level', a.level, 'section', a.section, 'round', a.round,
      'mode', a.mode, 'status', a.status, 'startedAt', private.wire_time(a.started_at),
      'completedAt', private.wire_time(a.completed_at), 'updatedAt', private.wire_time(a.updated_at),
      'totalTimeMs', a.total_time_ms, 'currentQuestionNo', a.current_question_no,
      'questionCount', a.question_count, 'maxScore', a.max_score, 'score', a.score,
      'correctCount', a.correct_count, 'answeredCount', a.answered_count,
      'contentVersion', a.content_version,
      'answers', (select coalesce(jsonb_agg(jsonb_build_object(
          'questionNo', x.question_no, 'selectedIdx', x.selected_idx,
          'timeSpentMs', x.time_spent_ms, 'answeredAt', private.wire_time(x.answered_at),
          'correctIdx', x.correct_idx, 'points', x.points, 'pointsEarned', x.points_earned,
          'questionType', x.question_type) order by x.question_no), '[]'::jsonb)
        from public.topik_attempt_answer x where x.attempt_id = a.id)) end)
$$;

-- BR-TOPIK-028: the stored snapshot adds up over the stored answers.
create function private.topik_attempt_consistent(p_id uuid) returns boolean
language sql stable set search_path = '' as $$
  select a.question_count = s.n and a.max_score = s.points and a.score = s.earned
     and a.correct_count = s.correct and a.answered_count = s.answered
     and a.total_time_ms = s.time_ms
  from public.topik_attempt a,
  lateral (select count(*) as n, coalesce(sum(x.points), 0) as points,
             coalesce(sum(x.points_earned), 0) as earned,
             count(*) filter (where x.selected_idx = x.correct_idx) as correct,
             count(*) filter (where x.selected_idx is not null) as answered,
             coalesce(sum(x.time_spent_ms), 0) as time_ms
           from public.topik_attempt_answer x where x.attempt_id = a.id) s
  where a.id = p_id
$$;

-- Insert-only: the same id of the same user is acknowledged with its own
-- version; a tombstone is final (server sync spec §5).
create function private.topik_attempt_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.topik_attempt;
  v_answers jsonb := r->'answers';
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id or jsonb_typeof(v_answers) is distinct from 'array' then
    raise exception 'VALIDATION_FAILED';
  end if;
  select * into v_existing from public.topik_attempt where id = p_id for update;
  if found then
    if v_existing.user_id <> p_user then
      raise exception 'SYNC_ENTITY_CONFLICT';
    end if;
    if v_existing.deleted_at is not null then
      raise exception 'ENTITY_TOMBSTONED';
    end if;
    return v_existing.server_version;
  end if;
  if (select count(distinct a->>'questionNo') from jsonb_array_elements(v_answers) a)
      <> jsonb_array_length(v_answers) then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.topik_attempt (id, user_id, test_id, level, section, round, mode, status,
    started_at, completed_at, updated_at, total_time_ms, current_question_no, question_count,
    max_score, score, correct_count, answered_count, content_version, server_version, last_device_id)
  values (p_id, p_user, r->>'testId', r->>'level', r->>'section', (r->>'round')::integer,
    r->>'mode', r->>'status', (r->>'startedAt')::timestamptz, (r->>'completedAt')::timestamptz,
    (r->>'updatedAt')::timestamptz, (r->>'totalTimeMs')::integer,
    (r->>'currentQuestionNo')::integer, (r->>'questionCount')::integer, (r->>'maxScore')::integer,
    (r->>'score')::integer, (r->>'correctCount')::integer, (r->>'answeredCount')::integer,
    (r->>'contentVersion')::integer, v_version, p_device);
  insert into public.topik_attempt_answer (attempt_id, question_no, selected_idx, time_spent_ms,
    answered_at, correct_idx, points, points_earned, question_type)
  select p_id, (a->>'questionNo')::integer, (a->>'selectedIdx')::integer,
    (a->>'timeSpentMs')::integer, (a->>'answeredAt')::timestamptz, (a->>'correctIdx')::integer,
    (a->>'points')::integer, (a->>'pointsEarned')::integer, a->>'questionType'
  from jsonb_array_elements(v_answers) a;
  if not private.topik_attempt_consistent(p_id) then
    raise exception 'VALIDATION_FAILED';
  end if;
  return v_version;
end
$$;

-- A final tombstone, as tag_delete; the answers go physically.
create function private.topik_attempt_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.topik_attempt;
  v_version bigint;
begin
  select * into v_existing from public.topik_attempt where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  delete from public.topik_attempt_answer where attempt_id = p_id;
  v_version := private.allocate_versions(p_user, 1);
  update public.topik_attempt set deleted_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;

-- The four dispatch functions, each in full with the new type (DEV-199,
-- supabase/README.md#rules), from 20261002000000 (current_change, push_one),
-- 20261011000000 (apply_operation) and 20261014000000 (sync_changes).

create or replace function private.current_change(p_user uuid, p_type text, p_id uuid) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_deck public.deck;
  v_batch public.delete_batch;
  v_card public.card;
  v_tag public.tags;
  v_settings public.account_settings;
  v_review public.review_log;
  v_schedule public.card_schedule;
  v_topik public.topik_attempt;
begin
  if p_type = 'deck' then
    select * into v_deck from public.deck where id = p_id and user_id = p_user;
    if found then
      return private.deck_change(v_deck);
    end if;
  end if;
  if p_type = 'delete_batch' then
    select * into v_batch from public.delete_batch where id = p_id and user_id = p_user;
    if found then
      return private.delete_batch_change(v_batch);
    end if;
  end if;
  if p_type = 'card' then
    select * into v_card from public.card where id = p_id and user_id = p_user;
    if found then
      return private.card_change(v_card);
    end if;
  end if;
  if p_type = 'tag' then
    select * into v_tag from public.tags where id = p_id and user_id = p_user;
    if found then
      return private.tag_change(v_tag);
    end if;
  end if;
  -- One row per user; p_id is always the nil id (D2).
  if p_type = 'account_settings' then
    select * into v_settings from public.account_settings where user_id = p_user;
    if found then
      return private.account_settings_change(v_settings);
    end if;
  end if;
  if p_type = 'review_log' then
    select * into v_review from public.review_log where id = p_id and user_id = p_user;
    if found then
      return private.review_log_change(v_review);
    end if;
  end if;
  if p_type = 'card_schedule' then
    select * into v_schedule from public.card_schedule where card_id = p_id and user_id = p_user;
    if found then
      return private.card_schedule_change(v_schedule);
    end if;
  end if;
  if p_type = 'topik_attempt' then
    select * into v_topik from public.topik_attempt where id = p_id and user_id = p_user;
    if found then
      return private.topik_attempt_change(v_topik);
    end if;
  end if;
  return null;
end
$$;

create or replace function private.apply_operation(
  p_user uuid, p_device uuid, p_type text, p_kind text, p_id uuid, p_row jsonb) returns bigint
language plpgsql set search_path = '' as $$
begin
  if p_kind = 'upsert' then
    if p_row is null or jsonb_typeof(p_row) <> 'object' then
      raise exception 'VALIDATION_FAILED';
    end if;
    if p_type = 'deck' then
      return private.deck_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'card' then
      return private.card_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'tag' then
      return private.tag_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'account_settings' then
      return private.account_settings_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'review_log' then
      return private.review_log_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'card_schedule' then
      return private.card_schedule_upsert(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'topik_attempt' then
      return private.topik_attempt_upsert(p_user, p_device, p_id, p_row);
    end if;
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'card' then
      return private.card_delete(p_user, p_device, p_id, p_row);
    end if;
    if p_type = 'tag' then
      return private.tag_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'topik_attempt' then
      return private.topik_attempt_delete(p_user, p_device, p_id);
    end if;
    -- R13: history goes only with its card; a delete is acknowledged and changes nothing.
    if p_type in ('review_log', 'card_schedule') then
      return private.current_version(p_user);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

create or replace function private.push_one(p_user uuid, p_device uuid, p_op jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  -- Parsed safely: a failure here would escape this block's handler and fail the whole batch.
  v_op_id uuid := private.try_uuid(p_op->>'opId');
  v_type text := p_op->>'entityType';
  v_version bigint;
  v_code text;
begin
  if v_op_id is null then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null,
      'code', 'VALIDATION_FAILED', 'current', null);
  end if;
  select server_version into v_version from public.sync_applied_op where user_id = p_user and op_id = v_op_id;
  if found then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  end if;
  if v_type is null or v_type not in ('deck', 'delete_batch', 'card', 'tag', 'account_settings', 'review_log', 'card_schedule', 'topik_attempt') then
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null,
      'code', 'SYNC_ENTITY_UNSUPPORTED', 'current', null);
  end if;
  -- A subtransaction: a rejection rolls back only this operation (spec §4.1).
  begin
    v_version := private.apply_operation(p_user, p_device, v_type, p_op->>'op', (p_op->>'entityId')::uuid, p_op->'row');
    insert into public.sync_applied_op (user_id, op_id, server_version) values (p_user, v_op_id, v_version);
    return jsonb_build_object('opId', p_op->>'opId', 'status', 'applied', 'serverVersion', v_version,
      'code', null, 'current', null);
  exception
    when raise_exception then
      v_code := sqlerrm;
    when check_violation or not_null_violation or foreign_key_violation or invalid_text_representation
        or invalid_datetime_format or datetime_field_overflow or numeric_value_out_of_range then
      v_code := 'VALIDATION_FAILED';
    when unique_violation then
      v_code := 'CONFLICT';
  end;
  return jsonb_build_object('opId', p_op->>'opId', 'status', 'rejected', 'serverVersion', null, 'code', v_code,
    'current', private.current_change(p_user, v_type, private.try_uuid(p_op->>'entityId')));
end
$$;

create or replace function public.sync_changes(since bigint, max_rows integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
  v_since bigint := coalesce(since, 0);
  v_limit integer := least(greatest(coalesce(max_rows, 500), 1), 500);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  with page as (
    select u.entity_type, u.id, u.server_version, row_number() over (order by u.server_version) as n
    from (
      (select 'deck' as entity_type, d.id, d.server_version from public.deck d
       where d.user_id = v_user and d.server_version > v_since
       order by d.server_version limit v_limit + 1)
      union all
      (select 'delete_batch', b.id, b.server_version from public.delete_batch b
       where b.user_id = v_user and b.server_version > v_since
       order by b.server_version limit v_limit + 1)
      union all
      (select 'card', c.id, c.server_version from public.card c
       where c.user_id = v_user and c.server_version > v_since
       order by c.server_version limit v_limit + 1)
      union all
      (select 'tag', t.id, t.server_version from public.tags t
       where t.user_id = v_user and t.server_version > v_since
       order by t.server_version limit v_limit + 1)
      union all
      (select 'account_settings', '00000000-0000-0000-0000-000000000000'::uuid, s.server_version
       from public.account_settings s
       where s.user_id = v_user and s.server_version > v_since
       order by s.server_version limit v_limit + 1)
      union all
      (select 'card_schedule', cs.card_id, cs.server_version from public.card_schedule cs
       where cs.user_id = v_user and cs.server_version > v_since
       order by cs.server_version limit v_limit + 1)
      union all
      (select 'review_log', rl.id, rl.server_version from public.review_log rl
       where rl.user_id = v_user and rl.server_version > v_since
       order by rl.server_version limit v_limit + 1)
      union all
      (select 'topik_attempt', ta.id, ta.server_version from public.topik_attempt ta
       where ta.user_id = v_user and ta.server_version > v_since
       order by ta.server_version limit v_limit + 1)
    ) u
    order by u.server_version limit v_limit + 1
  )
  select coalesce(jsonb_agg(private.current_change(v_user, p.entity_type, p.id) order by p.server_version)
           filter (where p.n <= v_limit), '[]'),
         max(p.server_version) filter (where p.n <= v_limit),
         count(*) > v_limit
  into v_changes, v_next, v_more
  from page p;
  return jsonb_build_object('changes', v_changes, 'nextSince', coalesce(v_next, v_since), 'hasMore', v_more);
end
$$;

-- An account merge moves the source's attempts too; their answers follow by
-- the foreign key (from 20261010000000).
create or replace function private.merge_user_data(p_source uuid, p_target uuid) returns void
language plpgsql set search_path = '' as $$
declare
  v_total bigint;
  v_next bigint;
  v_rows bigint;
begin
  -- Live tags with a name the target already has: links move to the target's tag.
  update public.card_tags ct set tag_id = t.id
  from public.tags s join public.tags t
    on t.user_id = p_target and t.deleted_at is null and t.name_folded = s.name_folded
  where s.user_id = p_source and s.deleted_at is null and ct.tag_id = s.id;
  delete from public.tags s using public.tags t
  where s.user_id = p_source and s.deleted_at is null
    and t.user_id = p_target and t.deleted_at is null and t.name_folded = s.name_folded;

  -- The target's own settings win.
  if exists (select 1 from public.account_settings where user_id = p_target) then
    delete from public.account_settings where user_id = p_source;
  end if;

  select (select count(*) from public.delete_batch where user_id = p_source)
       + (select count(*) from public.deck where user_id = p_source)
       + (select count(*) from public.tags where user_id = p_source)
       + (select count(*) from public.card where user_id = p_source)
       + (select count(*) from public.card_schedule where user_id = p_source)
       + (select count(*) from public.review_log where user_id = p_source)
       + (select count(*) from public.account_settings where user_id = p_source)
       + (select count(*) from public.topik_attempt where user_id = p_source)
  into v_total;
  if v_total > 0 then
    v_next := private.allocate_versions(p_target, v_total::integer) - v_total;

    update public.delete_batch x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.delete_batch where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.deck x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by depth, server_version) as n
          from public.deck where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.tags x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.tags where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.card x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.card where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.card_schedule x set user_id = p_target, server_version = v_next + s.n
    from (select card_id, row_number() over (order by server_version) as n
          from public.card_schedule where user_id = p_source) s
    where x.card_id = s.card_id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.review_log x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.review_log where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.topik_attempt x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.topik_attempt where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;

    update public.account_settings set user_id = p_target, server_version = v_next + 1
    where user_id = p_source;
  end if;

  update public.app_log set user_id = p_target where user_id = p_source;
end
$$;

revoke all on all functions in schema private from public, anon, authenticated;
