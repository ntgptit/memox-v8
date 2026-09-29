-- ADR-018 §7; spec 2026-09-29-app-logging-design.md §4: the admin's reads of app_log,
-- tightened after 20261003000000 (already applied; never edited).
--   * log_query checks the admin first: a non-admin never reaches a cast of the filter.
--   * A JSON null, or a value of the wrong type, counts as absent.
--   * search matches literally: `%`, `_` and `\` are text, not wildcards.
--   * A list row is compact (no context, no stack trace, a message cut at 300 characters);
--     log_get returns the whole row of one log.

create or replace function public.log_query(filter jsonb) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit int;
  v_search text;
  v_items jsonb;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  v_limit := least(greatest(coalesce((filter->>'limit')::int, 100), 1), 100);
  v_search := replace(replace(replace(filter->>'search', '\', '\\'), '%', '\%'), '_', '\_');
  select coalesce(jsonb_agg(to_jsonb(l) order by l.occurred_at desc, l.id desc), '[]') into v_items
  from (
    select a.id, a.occurred_at, a.level, a.source, a.category, a.event,
      left(a.message, 300) as message, a.error_type, a.status, a.user_id, a.device_id,
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
      and (filter->>'from' is null or a.occurred_at >= (filter->>'from')::timestamptz)
      and (filter->>'to' is null or a.occurred_at < (filter->>'to')::timestamptz)
      and (filter->>'userId' is null or a.user_id = (filter->>'userId')::uuid)
      and (jsonb_typeof(filter->'before') is distinct from 'object' or (a.occurred_at, a.id) <
        ((filter->'before'->>'occurredAt')::timestamptz, (filter->'before'->>'id')::uuid))
    order by a.occurred_at desc, a.id desc
    limit v_limit
  ) l;
  return jsonb_build_object('items', v_items);
end
$$;

create function public.log_get(log_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_row public.app_log;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  select * into v_row from public.app_log where id = log_id;
  if v_row.id is null then
    raise exception 'NOT_FOUND';
  end if;
  return to_jsonb(v_row);
end
$$;

revoke all on function public.log_query(jsonb), public.log_get(uuid) from public, anon, authenticated;
grant execute on function public.log_query(jsonb), public.log_get(uuid) to authenticated;
