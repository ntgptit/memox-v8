-- SB-S4 / library and study sync spec §3.3–3.4, ADR-017: reviews sync as append-only history and schedules
-- as rows; the server never computes a schedule. Both go with their card.

create table public.review_log (
  id uuid primary key,
  user_id uuid not null,
  card_id uuid not null references public.card (id),
  session_id text not null,
  scheduler_type text not null check (scheduler_type in ('eight_box', 'sm2')),
  generation integer not null,
  kind text not null check (kind in ('learning', 'scheduled', 'relearning')),
  mode text not null check (mode in ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
  outcome_reason text check (outcome_reason is null or outcome_reason = 'timeout'),
  comparison_version integer,
  used_hint integer check (used_hint is null or used_hint in (0, 1)),
  direction text check (direction is null or direction in ('korean_to_meaning', 'meaning_to_korean')),
  action text not null check (action in ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')),
  answered_at timestamptz not null,
  next_due_at timestamptz,
  previous_box integer,
  next_box integer,
  previous_ease_factor double precision,
  next_ease_factor double precision,
  previous_interval_days integer,
  next_interval_days integer,
  server_version bigint not null,
  last_device_id uuid not null,
  check (mode = 'fill' or (comparison_version is null and used_hint is null)),
  check (outcome_reason is null or mode = 'recall')
);
create unique index uq_review_log_user_version on public.review_log (user_id, server_version);
create index idx_review_log_card on public.review_log (card_id);

create table public.card_schedule (
  card_id uuid primary key references public.card (id),
  user_id uuid not null,
  scheduler_type text not null check (scheduler_type in ('eight_box', 'sm2')),
  scheduler_version integer not null,
  generation integer not null,
  learned_at timestamptz,
  due_at timestamptz,
  last_answered_at timestamptz,
  answer_count integer not null,
  lapse_count integer not null,
  current_box integer check (current_box between 1 and 8),
  ease_factor double precision,
  interval_days integer,
  repetitions integer,
  server_version bigint not null,
  last_device_id uuid not null,
  check ((scheduler_type = 'eight_box') = (current_box is not null)),
  check ((scheduler_type = 'sm2') = (ease_factor is not null)),
  check ((ease_factor is null) = (interval_days is null)),
  check ((ease_factor is null) = (repetitions is null)),
  check (learned_at is not null or due_at is null)
);
create unique index uq_card_schedule_user_version on public.card_schedule (user_id, server_version);

alter table public.review_log enable row level security;
alter table public.card_schedule enable row level security;
revoke all on table public.review_log, public.card_schedule from public, anon, authenticated;

create function private.review_log_change(r public.review_log) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'review_log', 'entityId', r.id, 'serverVersion', r.server_version, 'deleted', false,
    'row', jsonb_build_object(
      'id', r.id, 'cardId', r.card_id, 'sessionId', r.session_id, 'schedulerType', r.scheduler_type,
      'generation', r.generation, 'kind', r.kind, 'mode', r.mode, 'outcomeReason', r.outcome_reason,
      'comparisonVersion', r.comparison_version, 'usedHint', r.used_hint, 'direction', r.direction,
      'action', r.action, 'answeredAt', private.wire_time(r.answered_at),
      'nextDueAt', private.wire_time(r.next_due_at), 'previousBox', r.previous_box, 'nextBox', r.next_box,
      'previousEaseFactor', r.previous_ease_factor, 'nextEaseFactor', r.next_ease_factor,
      'previousIntervalDays', r.previous_interval_days, 'nextIntervalDays', r.next_interval_days))
$$;

create function private.card_schedule_change(s public.card_schedule) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'card_schedule', 'entityId', s.card_id, 'serverVersion', s.server_version, 'deleted', false,
    'row', jsonb_build_object(
      'schedulerType', s.scheduler_type, 'schedulerVersion', s.scheduler_version, 'generation', s.generation,
      'learnedAt', private.wire_time(s.learned_at), 'dueAt', private.wire_time(s.due_at),
      'lastAnsweredAt', private.wire_time(s.last_answered_at), 'answerCount', s.answer_count,
      'lapseCount', s.lapse_count, 'currentBox', s.current_box, 'easeFactor', s.ease_factor,
      'intervalDays', s.interval_days, 'repetitions', s.repetitions))
$$;

-- 'live' or 'tombstoned' for the user's card; another user's card or an unknown one is refused.
create function private.card_of(p_user uuid, p_card uuid) returns text
language plpgsql stable set search_path = '' as $$
declare
  v_card public.card;
begin
  select * into v_card from public.card where id = p_card;
  if not found then
    raise exception 'CARD_MISSING';
  end if;
  if v_card.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  return case when v_card.deleted_at is null then 'live' else 'tombstoned' end;
end
$$;

-- Append-only: an existing id is acknowledged with its own version; a tombstoned card's review is dropped (R14).
create function private.review_log_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.review_log;
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  select * into v_existing from public.review_log where id = p_id;
  if found then
    if v_existing.user_id <> p_user then
      raise exception 'SYNC_ENTITY_CONFLICT';
    end if;
    return v_existing.server_version;
  end if;
  if private.card_of(p_user, (r->>'cardId')::uuid) = 'tombstoned' then
    return private.current_version(p_user);
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.review_log (id, user_id, card_id, session_id, scheduler_type, generation, kind, mode,
    outcome_reason, comparison_version, used_hint, direction, action, answered_at, next_due_at, previous_box,
    next_box, previous_ease_factor, next_ease_factor, previous_interval_days, next_interval_days,
    server_version, last_device_id)
  values (p_id, p_user, (r->>'cardId')::uuid, r->>'sessionId', r->>'schedulerType', (r->>'generation')::integer,
    r->>'kind', r->>'mode', r->>'outcomeReason', (r->>'comparisonVersion')::integer, (r->>'usedHint')::integer,
    r->>'direction', r->>'action', (r->>'answeredAt')::timestamptz, (r->>'nextDueAt')::timestamptz,
    (r->>'previousBox')::integer, (r->>'nextBox')::integer, (r->>'previousEaseFactor')::double precision,
    (r->>'nextEaseFactor')::double precision, (r->>'previousIntervalDays')::integer,
    (r->>'nextIntervalDays')::integer, v_version, p_device);
  return v_version;
end
$$;

-- Whole-row upsert keyed by the card; the server never computes or compares a schedule (ADR-017).
create function private.card_schedule_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_version bigint;
begin
  if private.card_of(p_user, p_id) = 'tombstoned' then
    return private.current_version(p_user);
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.card_schedule (card_id, user_id, scheduler_type, scheduler_version, generation, learned_at,
    due_at, last_answered_at, answer_count, lapse_count, current_box, ease_factor, interval_days, repetitions,
    server_version, last_device_id)
  values (p_id, p_user, r->>'schedulerType', (r->>'schedulerVersion')::integer, (r->>'generation')::integer,
    (r->>'learnedAt')::timestamptz, (r->>'dueAt')::timestamptz, (r->>'lastAnsweredAt')::timestamptz,
    (r->>'answerCount')::integer, (r->>'lapseCount')::integer, (r->>'currentBox')::integer,
    (r->>'easeFactor')::double precision, (r->>'intervalDays')::integer, (r->>'repetitions')::integer,
    v_version, p_device)
  on conflict (card_id) do update set
    scheduler_type = excluded.scheduler_type, scheduler_version = excluded.scheduler_version,
    generation = excluded.generation, learned_at = excluded.learned_at, due_at = excluded.due_at,
    last_answered_at = excluded.last_answered_at, answer_count = excluded.answer_count,
    lapse_count = excluded.lapse_count, current_box = excluded.current_box, ease_factor = excluded.ease_factor,
    interval_days = excluded.interval_days, repetitions = excluded.repetitions,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id;
  return v_version;
end
$$;

-- As in SB-S3, plus the card's reviews and schedule.
create or replace function private.card_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.card;
  v_version bigint;
begin
  select * into v_existing from public.card where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  delete from public.card_tags where card_id = p_id;
  delete from public.review_log where card_id = p_id;
  delete from public.card_schedule where card_id = p_id;
  v_version := private.allocate_versions(p_user, 1);
  update public.card set deleted_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;

-- As in SB-S3, plus the reviews and schedules of the tombstoned cards.
create or replace function private.deck_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.deck;
  v_deck_ids uuid[];
  v_rows integer;
  v_cards integer;
  v_first bigint;
begin
  select * into v_existing from public.deck where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  select array_agg(s.id) into v_deck_ids from private.live_subtree(p_user, p_id) s;
  v_rows := cardinality(v_deck_ids);
  select count(*) into v_cards from public.card c
  where c.user_id = p_user and c.deck_id = any (v_deck_ids) and c.deleted_at is null;
  v_first := private.allocate_versions(p_user, v_rows + v_cards) - v_rows - v_cards + 1;
  update public.deck d
  set deleted_at = now(), server_version = v_first + s.n - 1, last_device_id = p_device
  from (select t.id, row_number() over (order by t.rel, t.id) as n from private.live_subtree(p_user, p_id) t) s
  where d.id = s.id;
  delete from public.card_tags where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  delete from public.review_log where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  delete from public.card_schedule where card_id in (select k.id from public.card k
    where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null);
  update public.card c
  set deleted_at = now(), server_version = v_first + v_rows + s.n - 1, last_device_id = p_device
  from (select k.id, row_number() over (order by k.id) as n from public.card k
        where k.user_id = p_user and k.deck_id = any (v_deck_ids) and k.deleted_at is null) s
  where c.id = s.id;
  return v_first;
end
$$;

-- As in SB-S5, plus reviews and schedules.
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
  return null;
end
$$;

-- As in SB-S5, plus reviews and schedules; their deletes are no-ops (R13).
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
  elsif p_kind = 'delete' then
    if p_type = 'deck' then
      return private.deck_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'delete_batch' then
      return private.delete_batch_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'card' then
      return private.card_delete(p_user, p_device, p_id);
    end if;
    if p_type = 'tag' then
      return private.tag_delete(p_user, p_device, p_id);
    end if;
    -- R13: history goes only with its card; a delete is acknowledged and changes nothing.
    if p_type in ('review_log', 'card_schedule') then
      return private.current_version(p_user);
    end if;
  end if;
  raise exception 'VALIDATION_FAILED';
end
$$;

-- As in SB-S5, plus review_log and card_schedule.
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
  if v_type is null or v_type not in ('deck', 'delete_batch', 'card', 'tag', 'account_settings', 'review_log', 'card_schedule') then
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

-- As in SB-S5, plus schedules and reviews in the feed.
create or replace function public.sync_changes(since bigint, max_rows integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_since bigint := coalesce(since, 0);
  v_limit integer := least(greatest(coalesce(max_rows, 500), 1), 500);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
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

revoke all on all functions in schema private from public, anon, authenticated;
