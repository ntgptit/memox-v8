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

create function private.topik_version_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'topik_test_version is immutable once published';
end
$$;
create trigger topik_test_version_immutable
before update or delete on public.topik_test_version
for each row execute function private.topik_version_immutable();

create function private.topik_audit_append_only() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'topik_master_audit is append-only';
end
$$;
create trigger topik_master_audit_append_only
before update or delete on public.topik_master_audit
for each row execute function private.topik_audit_append_only();

-- ============================================================================
-- Function privileges (keep last)
-- ============================================================================

revoke all on all functions in schema private from public, anon, authenticated;
