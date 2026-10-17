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
-- Function privileges (keep last)
-- ============================================================================

revoke all on all functions in schema private from public, anon, authenticated;
