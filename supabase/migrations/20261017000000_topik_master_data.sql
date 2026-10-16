-- supabase/migrations/20261017000000_topik_master_data.sql
-- ADR-024, spec 2026-10-16 §5–§6: TOPIK Master Data (the tests themselves)
-- live here, managed by the Admin Web through topik_admin_* and read by the
-- app through topik_catalog and topik_test_content. Not a sync entity type:
-- not personal, no user_id, no tombstone per user (spec §4).

-- ============================================================================
-- Tables
-- ============================================================================

-- The working copy of one test; may be invalid while drafting.
create table public.topik_test_draft (
  test_id text primary key,
  json jsonb not null,
  last_check jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  check (json->>'testId' = test_id)
);

-- One published, immutable version of one test (BR-TOPIK-007).
create table public.topik_test_version (
  test_id text not null,
  content_version integer not null check (content_version > 0),
  json jsonb not null,
  media jsonb not null default '[]'::jsonb,
  checksum text not null,
  published_at timestamptz not null default now(),
  published_by uuid references auth.users (id) on delete set null,
  note text,
  primary key (test_id, content_version),
  check (json->>'testId' = test_id),
  check ((json->>'contentVersion')::integer = content_version),
  check (jsonb_typeof(media) = 'array')
);

-- What clients see of each test: published at one version, or retired.
-- catalog_version is one global, monotonic counter: a client pulls
-- "everything after N" (spec §6.2).
create sequence public.topik_catalog_version_seq;
create table public.topik_publication (
  test_id text primary key,
  status text not null check (status in ('published', 'retired')),
  current_version integer not null,
  catalog_version bigint not null unique,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  foreign key (test_id, current_version) references public.topik_test_version (test_id, content_version)
);
create index idx_topik_publication_catalog on public.topik_publication (catalog_version);

-- Every change, in the transaction that made it; append-only.
create table public.topik_master_audit (
  id uuid primary key,
  at timestamptz not null default now(),
  actor uuid references auth.users (id) on delete set null,
  action text not null check (action in
    ('draft_save', 'draft_import', 'draft_delete', 'publish', 'retire', 'unretire', 'rollback')),
  test_id text not null,
  content_version integer,
  detail jsonb not null default '{}'::jsonb
);
create index idx_topik_master_audit_at on public.topik_master_audit (at desc, id desc);
create index idx_topik_master_audit_test on public.topik_master_audit (test_id, at desc);

-- ============================================================================
-- Row level security and privileges (ADR-015 #5)
-- ============================================================================

alter table public.topik_test_draft enable row level security;
alter table public.topik_test_version enable row level security;
alter table public.topik_publication enable row level security;
alter table public.topik_master_audit enable row level security;
revoke all on table public.topik_test_draft, public.topik_test_version,
  public.topik_publication, public.topik_master_audit from public, anon, authenticated;
revoke all on sequence public.topik_catalog_version_seq from public, anon, authenticated;

-- ============================================================================
-- Immutability triggers
-- ============================================================================

-- The foreign keys to auth.users are `on delete set null`; Postgres carries
-- that out as an UPDATE of the referencing row, so the one UPDATE allowed is
-- the one that only nulls that column (account_delete must keep working).
-- Row triggers do not fire on TRUNCATE, so each table has a statement trigger
-- on the same function.
create function private.topik_version_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.published_by is null
     and (to_jsonb(new) - 'published_by') = (to_jsonb(old) - 'published_by') then
    return new;
  end if;
  raise exception 'topik_test_version is immutable once published';
end
$$;
create trigger topik_test_version_immutable
before update or delete on public.topik_test_version
for each row execute function private.topik_version_immutable();
create trigger topik_test_version_no_truncate
before truncate on public.topik_test_version
for each statement execute function private.topik_version_immutable();

create function private.topik_audit_append_only() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.actor is null
     and (to_jsonb(new) - 'actor') = (to_jsonb(old) - 'actor') then
    return new;
  end if;
  raise exception 'topik_master_audit is append-only';
end
$$;
create trigger topik_master_audit_append_only
before update or delete on public.topik_master_audit
for each row execute function private.topik_audit_append_only();
create trigger topik_master_audit_no_truncate
before truncate on public.topik_master_audit
for each statement execute function private.topik_audit_append_only();

-- ============================================================================
-- The shape check (§6.3)
-- ============================================================================

-- The structural half of BR-TOPIK-001…004, 006, 007, in the Dart rules'
-- names; a subset of checkTopikTest, which the app still runs on download.
create function private.topik_master_shape_issues(p_json jsonb) returns text[]
language plpgsql immutable set search_path = '' as $$
declare
  v_issues text[] := '{}';
  v_level text := p_json->>'level';
  v_section text := p_json->>'section';
  v_first integer;
  v_count integer;
  v_questions jsonb := case when jsonb_typeof(p_json->'questions') = 'array' then p_json->'questions' else '[]'::jsonb end;
  v_groups jsonb := case when jsonb_typeof(p_json->'groups') = 'array' then p_json->'groups' else '[]'::jsonb end;
  v_points_ok boolean;
begin
  -- identity: testId = {level}-{round}-{section}
  if p_json->>'testId' is distinct from format('%s-%s-%s', v_level, p_json->>'round', v_section)
     or v_level not in ('topik1', 'topik2') or v_section not in ('listening', 'reading')
     or coalesce((p_json->>'round')::integer, 0) <= 0 then
    v_issues := array_append(v_issues, 'identity');
  end if;
  -- metadata: BR-TOPIK-007 and the fixed format
  if coalesce((p_json->>'schemaVersion')::integer, 0) <> 1
     or coalesce((p_json->>'contentVersion')::integer, 0) < 1
     or p_json->>'format' is distinct from 'pbt'
     or coalesce(p_json->>'form', '') = ''
     or p_json->'source'->>'publishedBy' is distinct from 'NIIED'
     or coalesce(p_json->'source'->>'url', '') = '' then
    v_issues := array_append(v_issues, 'metadata');
  end if;
  -- numbering: BR-TOPIK-001
  select case when v_level = 'topik1' and v_section = 'listening' then 1
              when v_level = 'topik1' and v_section = 'reading' then 31
              else 1 end,
         case when v_level = 'topik1' and v_section = 'listening' then 30
              when v_level = 'topik1' and v_section = 'reading' then 40
              else 50 end
  into v_first, v_count;
  if (select coalesce(array_agg((q->>'no')::integer order by (q->>'no')::integer), '{}')
      from jsonb_array_elements(v_questions) q)
     is distinct from (select array_agg(n) from generate_series(v_first, v_first + v_count - 1) n) then
    v_issues := array_append(v_issues, 'numbering');
  end if;
  -- points: BR-TOPIK-002
  select coalesce(sum((q->>'points')::integer), 0) = 100
     and bool_and(case when v_level = 'topik2' then (q->>'points')::integer = 2
                       when v_section = 'listening' then (q->>'points')::integer in (3, 4)
                       else (q->>'points')::integer in (2, 3) end)
  into v_points_ok from jsonb_array_elements(v_questions) q;
  if not coalesce(v_points_ok, false) then
    v_issues := array_append(v_issues, 'points');
  end if;
  -- options: BR-TOPIK-003
  -- jsonb_array_elements only runs when options is an array (a scalar raises 22023);
  -- the case is what guarantees it, not the order of the or.
  if exists (select 1 from jsonb_array_elements(v_questions) q
             where case when jsonb_typeof(q->'options') = 'array' then
                          (select coalesce(array_agg((o->>'idx')::integer order by (o->>'idx')::integer), '{}')
                           from jsonb_array_elements(q->'options') o) <> '{1,2,3,4}'::integer[]
                          or exists (select 1 from jsonb_array_elements(q->'options') o
                                     where coalesce(o->>'textKo', '') = '' and coalesce(o->>'image', '') = '')
                        else true end
                or coalesce((q->>'answerIdx')::integer, 0) not between 1 and 4) then
    v_issues := array_append(v_issues, 'options');
  end if;
  -- groups: BR-TOPIK-004 (membership; the audio range is Dart's)
  if jsonb_array_length(v_groups) = 0
     or exists (select 1 from jsonb_array_elements(v_questions) q
                where not exists (select 1 from jsonb_array_elements(v_groups) g
                                  where g->>'groupId' = q->>'groupId'
                                    and g->'questionNos' @> to_jsonb(array[(q->>'no')::integer])))
     or (select count(*) from jsonb_array_elements(v_groups) g)
        <> (select count(distinct g->>'groupId') from jsonb_array_elements(v_groups) g)
     or exists (select 1 from jsonb_array_elements(v_groups) g, jsonb_array_elements(g->'questionNos') n
                where not exists (select 1 from jsonb_array_elements(v_questions) q where q->'no' = n))
     or (select count(*) from jsonb_array_elements(v_groups) g, jsonb_array_elements(g->'questionNos') n)
        <> jsonb_array_length(v_questions) then
    v_issues := array_append(v_issues, 'groups');
  end if;
  -- languages: BR-TOPIK-006, every multilingual object has non-empty vi and en
  if exists (
    select 1 from (
      select q->'explanation' as t from jsonb_array_elements(v_questions) q
      union all select q->'translation' from jsonb_array_elements(v_questions) q
      union all select g->'scriptTranslation' from jsonb_array_elements(v_groups) g
      union all select w from jsonb_array_elements(v_questions) q,
        jsonb_array_elements(case when jsonb_typeof(q->'words') = 'array' then q->'words' else '[]'::jsonb end) w
      union all select gr from jsonb_array_elements(v_questions) q,
        jsonb_array_elements(case when jsonb_typeof(q->'grammars') = 'array' then q->'grammars' else '[]'::jsonb end) gr
    ) x
    where x.t is not null and jsonb_typeof(x.t) <> 'null'
      and (coalesce(btrim(x.t->>'vi'), '') = '' or coalesce(btrim(x.t->>'en'), '') = '')) then
    v_issues := array_append(v_issues, 'languages');
  end if;
  return v_issues;
exception when data_exception then
  -- SQLSTATE class 22 (a bad cast, a scalar where an array was expected): a wrongly
  -- typed field is an identity and metadata failure; anything else is a bug and raises.
  return array['identity', 'metadata'];
end
$$;

-- ============================================================================
-- Admin RPCs: drafts and the audit log (§6.1)
-- ============================================================================

-- Every admin RPC requires a profile, then the admin role (the pattern of role_set).
create function private.require_topik_admin() returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_user uuid := private.require_current_profile();
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  return v_user;
end
$$;

-- One audit row, written by the caller's own transaction. clock_timestamp(), not
-- now(): two changes in one transaction keep their order.
create function private.topik_audit(p_action text, p_test_id text, p_content_version integer, p_detail jsonb)
returns void language sql set search_path = '' as $$
  insert into public.topik_master_audit (id, at, actor, action, test_id, content_version, detail)
  values (gen_random_uuid(), clock_timestamp(), auth.uid(), p_action, p_test_id, p_content_version,
    coalesce(p_detail, '{}'::jsonb))
$$;

-- Every test that has a draft or a publication.
create function public.topik_admin_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_topik_admin();
  return jsonb_build_object('items', coalesce((
    select jsonb_agg(jsonb_build_object(
      'testId', t.test_id,
      'draft', case when d.test_id is null then null else jsonb_build_object(
        'updatedAt', private.wire_time(d.updated_at), 'lastCheck', d.last_check) end,
      'publication', case when p.test_id is null then null else jsonb_build_object(
        'status', p.status, 'currentVersion', p.current_version, 'catalogVersion', p.catalog_version) end,
      'latestVersion', (select max(v.content_version) from public.topik_test_version v where v.test_id = t.test_id))
      order by t.test_id)
    from (select test_id from public.topik_test_draft
          union select test_id from public.topik_publication) t
    left join public.topik_test_draft d on d.test_id = t.test_id
    left join public.topik_publication p on p.test_id = t.test_id), '[]'::jsonb));
end
$$;

create function public.topik_admin_draft_get(p_test_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_row public.topik_test_draft;
begin
  perform private.require_topik_admin();
  select * into v_row from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  return jsonb_build_object('testId', v_row.test_id, 'json', v_row.json, 'lastCheck', v_row.last_check,
    'updatedAt', private.wire_time(v_row.updated_at), 'updatedBy', v_row.updated_by);
end
$$;

-- A draft may be invalid while it is being written; its shape issues are returned
-- and audited, not enforced (publishing enforces them).
create function public.topik_admin_draft_save(p_test_id text, p_json jsonb, p_last_check jsonb, p_imported boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_topik_admin();
  v_issues text[];
  v_at timestamptz := now();
begin
  if jsonb_typeof(p_json) is distinct from 'object' or p_json->>'testId' is distinct from p_test_id then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_issues := private.topik_master_shape_issues(p_json);
  insert into public.topik_test_draft (test_id, json, last_check, updated_at, updated_by)
  values (p_test_id, p_json, coalesce(p_last_check, '{}'::jsonb), v_at, v_user)
  on conflict (test_id) do update
    set json = excluded.json, last_check = excluded.last_check, updated_at = excluded.updated_at,
        updated_by = excluded.updated_by;
  perform private.topik_audit(case when p_imported then 'draft_import' else 'draft_save' end, p_test_id, null,
    jsonb_build_object('issues', to_jsonb(v_issues)));
  return jsonb_build_object('testId', p_test_id, 'updatedAt', private.wire_time(v_at), 'issues', to_jsonb(v_issues));
end
$$;

create function public.topik_admin_draft_delete(p_test_id text) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_topik_admin();
  delete from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  perform private.topik_audit('draft_delete', p_test_id, null, '{}'::jsonb);
  return jsonb_build_object('testId', p_test_id);
end
$$;

-- Newest first; `next` is the p_before of the following page, null on the last.
create function public.topik_admin_audit(p_test_id text, p_limit integer, p_before timestamptz) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_items jsonb;
  v_next timestamptz;
begin
  perform private.require_topik_admin();
  with page as (
    select a.*, row_number() over (order by a.at desc, a.id desc) as n
    from public.topik_master_audit a
    where (p_test_id is null or a.test_id = p_test_id)
      and (p_before is null or a.at < p_before)
    order by a.at desc, a.id desc
    limit v_limit + 1)
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'at', private.wire_time(at), 'actor', actor,
           'action', action, 'testId', test_id, 'contentVersion', content_version, 'detail', detail)
           order by at desc, id desc) filter (where n <= v_limit), '[]'::jsonb),
         case when count(*) > v_limit then min(at) filter (where n <= v_limit) end
  into v_items, v_next from page;
  return jsonb_build_object('items', v_items, 'next', private.wire_time(v_next));
end
$$;

revoke all on function public.topik_admin_list(), public.topik_admin_draft_get(text),
  public.topik_admin_draft_save(text, jsonb, jsonb, boolean), public.topik_admin_draft_delete(text),
  public.topik_admin_audit(text, integer, timestamptz) from public, anon, authenticated;
grant execute on function public.topik_admin_list(), public.topik_admin_draft_get(text),
  public.topik_admin_draft_save(text, jsonb, jsonb, boolean), public.topik_admin_draft_delete(text),
  public.topik_admin_audit(text, integer, timestamptz) to authenticated;

-- ============================================================================
-- Function privileges (keep last)
-- ============================================================================

revoke all on all functions in schema private from public, anon, authenticated;
