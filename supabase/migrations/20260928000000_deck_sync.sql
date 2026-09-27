-- ADR-015 / Supabase backend spec §3. Ported from memox-api-services Flyway V1–V4 (deck and delete_batch only).
-- Ids are client-generated UUIDs (ADR-007); times are UTC (ADR-008).

create schema private;
revoke all on schema private from public, anon, authenticated;

create table public.user_sync_version (
  user_id uuid primary key,
  version bigint not null
);

create table public.sync_applied_op (
  user_id uuid not null,
  op_id uuid not null,
  server_version bigint not null,
  applied_at timestamptz not null default now(),
  primary key (user_id, op_id)
);

-- A trash batch; tombstoned_at is the sync tombstone, deleted_at the batch's own time.
create table public.delete_batch (
  id uuid primary key,
  user_id uuid not null,
  item_type text not null check (item_type in ('card', 'deck')),
  root_item_id uuid not null,
  deleted_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  tombstoned_at timestamptz null
);
create unique index uq_delete_batch_user_version on public.delete_batch (user_id, server_version);

create table public.deck (
  id uuid primary key,
  user_id uuid not null,
  name text not null,
  parent_id uuid null references public.deck (id),
  root_id uuid not null,
  depth integer not null check (depth between 1 and 10),
  content_type text not null check (content_type in ('unset', 'card', 'deck')),
  scheduler_type text null check (scheduler_type in ('eight_box', 'sm2')),
  scheduler_version integer null,
  scheduler_config text null,
  study_config text null,
  generation integer null,
  first_answered_at timestamptz null,
  source_template_id text null,
  source_template_version integer null,
  delete_batch_id uuid null references public.delete_batch (id),
  sibling_position integer not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null,
  -- The app's deck CHECKs (deck.drift): a row the app would refuse must be refused here, or it jams every pull.
  constraint deck_root_shape check (
    (parent_id is null and content_type = 'deck' and scheduler_type is not null)
    or (parent_id is not null and scheduler_type is null)),
  constraint deck_root_generation check ((parent_id is null) = (generation is not null)),
  constraint deck_root_scheduler_version check ((parent_id is null) = (scheduler_version is not null)),
  constraint deck_child_configs check (parent_id is null or (scheduler_config is null and study_config is null))
);
-- One version per changed row (sync spec §4.2): a duplicate is a loud error, not a silently skipped change.
create unique index uq_deck_user_version on public.deck (user_id, server_version);
create index idx_deck_parent on public.deck (parent_id);

-- The only path to data is the functions below (spec §2): RLS on, no policy, no client privilege.
alter table public.user_sync_version enable row level security;
alter table public.sync_applied_op enable row level security;
alter table public.delete_batch enable row level security;
alter table public.deck enable row level security;
revoke all on table public.user_sync_version, public.sync_applied_op, public.delete_batch, public.deck
  from public, anon, authenticated;
