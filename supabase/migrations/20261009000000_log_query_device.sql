-- ADR-018 §8 (monitoring spec §3.2): the admin's device filter. The body of log_query is
-- 20261008000000's (itself 20261007000000's with a safer limit and cursor), plus one
-- filter: deviceIds, a list of device ids, applied only when it is a JSON array (a null
-- or a scalar restricts nothing, as the other lists; an empty array matches no device).

create or replace function public.log_query(filter jsonb) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit int;
  v_before_at timestamptz;
  v_before_id uuid;
  v_from timestamptz;
  v_to timestamptz;
  v_user uuid;
  v_search text;
  v_items jsonb;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  -- A limit that is not a number is absent; a fraction is cut to a whole number.
  v_limit := case when jsonb_typeof(filter->'limit') = 'number'
    then least(greatest(floor((filter->>'limit')::numeric), 1), 100)::int else 100 end;
  -- A cursor counts only with a valid time and id; otherwise it is absent.
  v_before_at := private.try_timestamptz(filter->'before'->>'occurredAt');
  v_before_id := private.try_uuid(filter->'before'->>'id');
  -- A time range or user that does not parse is absent too.
  v_from := private.try_timestamptz(filter->>'from');
  v_to := private.try_timestamptz(filter->>'to');
  v_user := private.try_uuid(filter->>'userId');
  v_search := replace(replace(replace(filter->>'search', '\', '\\'), '%', '\%'), '_', '\_');
  select coalesce(jsonb_agg(to_jsonb(l) order by l.occurred_at desc, l.id desc), '[]') into v_items
  from (
    select a.id, a.occurred_at, a.level, a.source, a.category, a.event,
      left(a.message, 300) as message, a.error_type, left(a.error_message, 300) as error_message,
      a.status, a.user_id, a.device_id,
      a.app_version, a.platform
    from public.app_log a
    where (jsonb_typeof(filter->'levels') is distinct from 'array'
        or a.level in (select jsonb_array_elements_text(filter->'levels')))
      and (jsonb_typeof(filter->'sources') is distinct from 'array'
        or a.source in (select jsonb_array_elements_text(filter->'sources')))
      and (jsonb_typeof(filter->'categories') is distinct from 'array'
        or a.category in (select jsonb_array_elements_text(filter->'categories')))
      and (jsonb_typeof(filter->'statuses') is distinct from 'array'
        or a.status in (select jsonb_array_elements_text(filter->'statuses')))
      and (v_search is null
        or a.event ilike '%' || v_search || '%' escape '\'
        or a.message ilike '%' || v_search || '%' escape '\')
      and (v_from is null or a.occurred_at >= v_from)
      and (v_to is null or a.occurred_at < v_to)
      and (v_user is null or a.user_id = v_user)
      and (jsonb_typeof(filter->'deviceIds') is distinct from 'array'
        or a.device_id in (select jsonb_array_elements_text(filter->'deviceIds')))
      and (v_before_at is null or v_before_id is null or (a.occurred_at, a.id) < (v_before_at, v_before_id))
    order by a.occurred_at desc, a.id desc
    limit v_limit
  ) l;
  return jsonb_build_object('items', v_items);
end
$$;

revoke all on function public.log_query(jsonb) from public, anon, authenticated;
grant execute on function public.log_query(jsonb) to authenticated;
