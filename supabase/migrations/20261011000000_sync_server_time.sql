-- SP2b 2.30 (R10): every sync_changes page also carries the server's clock, so the
-- app can bound the Trash purge clock by the last server time it saw (a device clock
-- set far ahead then never purges early). As in 20261002000000, plus 'serverTime'.
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
  return jsonb_build_object('changes', v_changes, 'nextSince', coalesce(v_next, v_since), 'hasMore', v_more,
    'serverTime', (extract(epoch from now()) * 1000)::bigint);
end
$$;
