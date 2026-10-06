-- DEV-192: a deleted user's JWT is live for up to an hour. Until now the sync
-- RPCs only checked auth.uid(), so such a token pushed rows the user_id
-- foreign keys then rejected one by one (VALIDATION_FAILED, kept as
-- sync_rejection on the device) and read an empty change feed. Both now
-- start with private.require_current_profile(), as me() and the account
-- RPCs do: no user raises NOT_AUTHENTICATED as before, a user without a
-- profile raises UNAUTHORIZED, which the app treats as a sign-in failure and
-- validates the account again (auth spec #13). The bodies are those of
-- 20261003000000_app_log.sql (sync_push) and 20261002000000_study_history_sync.sql
-- (sync_changes), unchanged past the first line.

create or replace function public.sync_push(request jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
  v_device uuid := private.try_uuid(request->>'deviceId');
  v_ops jsonb := request->'operations';
  v_op jsonb;
  v_result jsonb;
  v_results jsonb := '[]';
begin
  if v_device is null or jsonb_typeof(v_ops) is distinct from 'array' or jsonb_array_length(v_ops) > 100 then
    raise exception 'VALIDATION_FAILED';
  end if;
  -- One user's pushes are serialized for the whole call (sync spec §4.1).
  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  for v_op in select value from jsonb_array_elements(v_ops) loop
    v_result := private.push_one(v_user, v_device, v_op);
    if v_result->>'status' = 'rejected' then
      perform private.log_server('warning', 'sync', 'sync.rejected',
        format('%s %s refused: %s', v_op->>'entityType', v_op->>'entityId', v_result->>'code'),
        jsonb_build_object('op', v_op, 'result', v_result, 'deviceId', v_device));
    end if;
    v_results := v_results || jsonb_build_array(v_result);
  end loop;
  return jsonb_build_object('results', v_results);
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
