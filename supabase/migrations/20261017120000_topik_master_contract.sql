-- supabase/migrations/20261017120000_topik_master_contract.sql
-- ADR-025 (owner 2026-10-17), decision package 2026-10-17 §11 PR-02: additions to the
-- TOPIK Master Data contract of 20261016120000_topik_master_data.sql. That migration is
-- pushed and never edited; this one replaces its functions and adds constraints.

-- ============================================================================
-- Who reads published content (ADR-025 #5, DR-14): admins only, for now
-- ============================================================================

-- The one gate for every read of published Master Data: the catalog, the content and
-- the media read policy. Admins only until the owner rules otherwise (redistribution of
-- NIIED papers is not established). Lifting it is a migration that replaces this body;
-- devices then pull everything from cursor 0, which a closed gate kept them at.
create function private.topik_can_read_content() returns boolean
language sql stable set search_path = '' as $$
  select private.is_admin()
$$;

-- ============================================================================
-- Integrity and compatibility of what is served (ADR-025 #4; DR-05, DR-06)
-- ============================================================================

-- The SHA-256 of a version's JSON exactly as served (jsonb's text form, UTF-8 bytes),
-- in lowercase hex. A client hashes the `document` string it receives and compares.
create function private.topik_document_sha256(p_json jsonb) returns text
language sql stable set search_path = '' as $$
  select encode(pg_catalog.sha256(convert_to(p_json::text, 'UTF8')), 'hex')
$$;

-- The catalog of 20261016120000, behind the gate and with three more keys per published
-- entry: schemaVersion (an older app skips what it cannot read), sha256 (of the document
-- served by topik_test_content) and bytes (the document plus the media sizes Storage
-- recorded; a size it did not record counts 0).
create or replace function public.topik_catalog(since bigint) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_since bigint := coalesce(since, 0);
  v_limit constant integer := 500;
  v_entries jsonb;
  v_next bigint;
  v_more boolean;
begin
  perform private.require_current_profile();
  -- Not a reader yet (ADR-025 #5): an empty page that keeps the cursor, so the device
  -- stores nothing, logs nothing and pulls everything once the gate opens.
  if not private.topik_can_read_content() then
    return jsonb_build_object('entries', '[]'::jsonb, 'next', v_since, 'more', false);
  end if;
  with page as (
    select p.test_id, p.status, p.current_version, p.catalog_version, v.json, v.checksum, v.media,
      row_number() over (order by p.catalog_version) as n
    from public.topik_publication p
    join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
    where p.catalog_version > v_since
    order by p.catalog_version
    limit v_limit + 1)
  select coalesce(jsonb_agg(case when page.status = 'retired'
      then jsonb_build_object('testId', page.test_id, 'status', page.status, 'catalogVersion', page.catalog_version)
      else jsonb_build_object('testId', page.test_id, 'status', page.status, 'catalogVersion', page.catalog_version,
        'contentVersion', page.current_version, 'checksum', page.checksum, 'media', page.media,
        'level', page.json->>'level', 'round', (page.json->>'round')::integer, 'section', page.json->>'section',
        'titleKo', page.json->>'titleKo', 'tags', private.topik_tags(page.json),
        'schemaVersion', (page.json->>'schemaVersion')::integer,
        'sha256', private.topik_document_sha256(page.json),
        'bytes', octet_length(page.json::text)::bigint
          + coalesce((select sum((m->>'size')::bigint) from jsonb_array_elements(page.media) m), 0)) end
      order by page.catalog_version) filter (where page.n <= v_limit), '[]'::jsonb),
    max(page.catalog_version) filter (where page.n <= v_limit),
    count(*) > v_limit
  into v_entries, v_next, v_more from page;
  return jsonb_build_object('entries', v_entries, 'next', coalesce(v_next, v_since), 'more', v_more);
end
$$;

-- The content of 20261016120000 behind the gate, as an envelope: the document is the
-- stored JSON as text, the exact bytes `sha256` hashes, so a client verifies it before
-- it parses it. NOT_FOUND for anything not current or not readable, as before.
create or replace function public.topik_test_content(p_test_id text, p_content_version integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_json jsonb;
begin
  perform private.require_current_profile();
  if not private.topik_can_read_content() then
    raise exception 'NOT_FOUND';
  end if;
  select v.json into v_json
  from public.topik_publication p
  join public.topik_test_version v on v.test_id = p.test_id and v.content_version = p.current_version
  where p.test_id = p_test_id and p.status = 'published' and p.current_version = p_content_version;
  if v_json is null then
    raise exception 'NOT_FOUND';
  end if;
  return jsonb_build_object('testId', p_test_id, 'contentVersion', p_content_version,
    'schemaVersion', (v_json->>'schemaVersion')::integer,
    'sha256', private.topik_document_sha256(v_json), 'document', v_json::text);
end
$$;

revoke all on function public.topik_catalog(bigint), public.topik_test_content(text, integer)
  from public, anon, authenticated;
grant execute on function public.topik_catalog(bigint), public.topik_test_content(text, integer) to authenticated;

-- The read policy's helper of 20261016120000, behind the gate for everyone but an admin.
create or replace function public.topik_media_can_read(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles pr where pr.id = auth.uid())
    and (private.is_admin() or (private.topik_can_read_content() and exists (
      select 1 from public.topik_publication p
      join public.topik_test_version v on v.test_id = p.test_id
      where p.status = 'published'
        and p.test_id = split_part(p_name, '/', 1)
        and v.content_version::text = split_part(p_name, '/', 2))))
$$;
revoke all on function public.topik_media_can_read(text) from public, anon, authenticated;
grant execute on function public.topik_media_can_read(text) to authenticated;

-- ============================================================================
-- Media named by their SHA-256 (ADR-025 #4, DR-21) and the publish dry run (DR-10)
-- ============================================================================

-- The media a content names: the section audio and every image, distinct, sorted
-- (the order publish reports the first missing one in, and the media array's order).
create function private.topik_media_paths(p_json jsonb) returns text[]
language sql stable set search_path = '' as $$
  select coalesce(array_agg(distinct x.path order by x.path), '{}'::text[])
  from (
    select p_json->'assets'->>'audio' as path
    union all
    select g->'passage'->>'image'
    from jsonb_array_elements(case when jsonb_typeof(p_json->'groups') = 'array' then p_json->'groups' else '[]'::jsonb end) g
    union all
    select o->>'image'
    from jsonb_array_elements(case when jsonb_typeof(p_json->'questions') = 'array' then p_json->'questions' else '[]'::jsonb end) q,
      jsonb_array_elements(case when jsonb_typeof(q->'options') = 'array' then q->'options' else '[]'::jsonb end) o) x
  where x.path is not null and x.path <> ''
$$;

-- The path contract {test_id}/{version}/{sha256}.{ext}: the first segment is the test,
-- the version segment is the version being published or (a rollback carries an old one)
-- an existing version of the test, and the file is named by the SHA-256 of its bytes in
-- lowercase hex with an extension content uses, and nothing follows it. A content-
-- addressed name makes a media file immutable by construction (ADR-025 #4).
create function private.topik_media_path_ok(p_test_id text, p_next integer, p_path text) returns boolean
language sql stable set search_path = '' as $$
  select split_part(p_path, '/', 1) = p_test_id
    and split_part(p_path, '/', 3) ~ '^[0-9a-f]{64}\.(mp3|jpg|jpeg|png|webp)$'
    and array_length(string_to_array(p_path, '/'), 1) = 3
    and (split_part(p_path, '/', 2) = p_next::text
         or exists (select 1 from public.topik_test_version tv
                    where tv.test_id = p_test_id and tv.content_version::text = split_part(p_path, '/', 2)))
$$;

-- The one body of publish and rollback of 20261016120000, with its media steps read
-- from the two helpers above (the publish dry run uses the same ones). Raises, all
-- before it writes anything, exactly as before: VALIDATION_FAILED (detail = the shape
-- issues), INVALID_STATE (retired), VALIDATION_FAILED (detail = 'media'), MEDIA_MISSING
-- (detail = the first missing path, in sorted order).
create or replace function private.topik_publish_version(p_user uuid, p_test_id text, p_json jsonb, p_note text,
  p_action text, p_detail jsonb) returns integer
language plpgsql set search_path = '' as $$
declare
  v_next integer := private.topik_next_version(p_test_id);
  v_json jsonb := jsonb_set(p_json, '{contentVersion}', to_jsonb(v_next));
  v_paths text[] := private.topik_media_paths(v_json);
  v_media jsonb;
  v_catalog bigint;
  v_status text;
  v_issues text[] := private.topik_master_shape_issues(v_json);
  v_missing text;
begin
  if cardinality(v_issues) > 0 then
    raise exception 'VALIDATION_FAILED' using detail = array_to_string(v_issues, ',');
  end if;
  select p.status into v_status from public.topik_publication p where p.test_id = p_test_id for update;
  if v_status = 'retired' then
    raise exception 'INVALID_STATE';
  end if;
  if exists (select 1 from unnest(v_paths) as u(m) where not private.topik_media_path_ok(p_test_id, v_next, u.m)) then
    raise exception 'VALIDATION_FAILED' using detail = 'media';
  end if;
  select u.m into v_missing from unnest(v_paths) with ordinality as u(m, n)
  where not private.topik_media_exists(u.m) order by u.n limit 1;
  if v_missing is not null then
    raise exception 'MEDIA_MISSING' using detail = v_missing;
  end if;
  -- Every path exists now: record the size and eTag Storage holds for it.
  select coalesce(jsonb_agg(jsonb_build_object('path', u.m,
      'size', case when (o.metadata->>'size') ~ '^[0-9]{1,18}$' then (o.metadata->>'size')::bigint end,
      'eTag', o.metadata->>'eTag') order by u.m), '[]'::jsonb) into v_media
  from unnest(v_paths) as u(m)
  left join storage.objects o on o.bucket_id = 'topik-media' and o.name = u.m;
  insert into public.topik_test_version (test_id, content_version, json, media, checksum, published_at, published_by, note)
  values (p_test_id, v_next, v_json, v_media, md5(v_json::text), now(), p_user, p_note);
  v_catalog := private.topik_next_catalog_version();
  insert into public.topik_publication (test_id, status, current_version, catalog_version, updated_at, updated_by)
  values (p_test_id, 'published', v_next, v_catalog, now(), p_user)
  on conflict (test_id) do update
    set status = 'published', current_version = excluded.current_version, catalog_version = excluded.catalog_version,
        updated_at = excluded.updated_at, updated_by = excluded.updated_by;
  perform private.topik_audit(p_action, p_test_id, v_next,
    coalesce(p_detail, '{}'::jsonb) || jsonb_build_object('note', p_note, 'catalogVersion', v_catalog));
  return v_next;
end
$$;

-- A dry run of publish for the admin's tools: every check publish makes on the draft,
-- reported instead of raised, and nothing written. It takes no lock, so a publish that
-- follows can still meet VERSION_MISMATCH when another admin published in between.
create function public.topik_admin_check(p_test_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_draft public.topik_test_draft;
  v_next integer;
  v_json jsonb;
  v_paths text[];
  v_status text;
  v_issues text[];
  v_invalid text[];
  v_missing text[];
begin
  perform private.require_topik_admin();
  select * into v_draft from public.topik_test_draft where test_id = p_test_id;
  if not found then
    raise exception 'NOT_FOUND';
  end if;
  v_next := (select coalesce(max(v.content_version), 0) + 1 from public.topik_test_version v where v.test_id = p_test_id);
  v_json := jsonb_set(v_draft.json, '{contentVersion}', to_jsonb(v_next));
  v_paths := private.topik_media_paths(v_json);
  v_issues := private.topik_master_shape_issues(v_json);
  select p.status into v_status from public.topik_publication p where p.test_id = p_test_id;
  select coalesce(array_agg(u.m order by u.m), '{}'::text[]) into v_invalid
  from unnest(v_paths) as u(m) where not private.topik_media_path_ok(p_test_id, v_next, u.m);
  select coalesce(array_agg(u.m order by u.m), '{}'::text[]) into v_missing
  from unnest(v_paths) as u(m)
  where private.topik_media_path_ok(p_test_id, v_next, u.m) and not private.topik_media_exists(u.m);
  return jsonb_build_object('testId', p_test_id, 'nextContentVersion', v_next,
    'draftContentVersion', v_draft.json->'contentVersion', 'status', v_status,
    'issues', to_jsonb(v_issues), 'mediaInvalid', to_jsonb(v_invalid), 'mediaMissing', to_jsonb(v_missing),
    'ready', cardinality(v_issues) = 0 and cardinality(v_invalid) = 0 and cardinality(v_missing) = 0
      and v_status is distinct from 'retired'
      and v_draft.json->>'contentVersion' is not distinct from v_next::text);
end
$$;
revoke all on function public.topik_admin_check(text) from public, anon, authenticated;
grant execute on function public.topik_admin_check(text) to authenticated;

-- ============================================================================
-- Function privileges (keep last)
-- ============================================================================

revoke all on all functions in schema private from public, anon, authenticated;
