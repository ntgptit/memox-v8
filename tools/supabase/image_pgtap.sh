#!/usr/bin/env bash
# Stand-in for `supabase db reset && supabase test db` when the Supabase CLI
# cannot pull its service images (Docker Hub rate limit, Amazon ECR refused by a
# proxy) but Docker itself runs: starts the `supabase/postgres` image alone, adds
# the Storage tables the storage-api service would create (`storage.buckets`,
# `storage.objects`, their helpers and grants), applies `supabase/migrations/`
# as `postgres` and runs every file in `supabase/tests/database/` as pgTAP.
# `supabase test db` on the full stack stays the reference.
# Usage: tools/supabase/image_pgtap.sh [test-file…]   (default: every test)
# Env:   PGTAP_IMAGE (default supabase/postgres:17.11.0.004), PGTAP_PORT (54329)
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd)
IMAGE=${PGTAP_IMAGE:-supabase/postgres:17.11.0.004}
PORT=${PGTAP_PORT:-54329}
NAME=memox-pgtap-$PORT
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -e POSTGRES_PASSWORD=postgres -p "$PORT":5432 "$IMAGE" >/dev/null
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT
for _ in $(seq 1 60); do
  docker exec "$NAME" pg_isready -U postgres -h localhost >/dev/null 2>&1 && break
  sleep 2
done
P=(docker exec -i "$NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -q)
# Storage schema as storage-api creates it, reduced to what policies and
# migrations read. On Supabase the tables belong to supabase_storage_admin and
# `postgres` manages their policies; here they belong to `postgres` outright, so
# the stub proves the policies' logic, not the ownership path.
docker exec -i "$NAME" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -q <<'SQL'
create type storage.buckettype as enum ('STANDARD', 'ANALYTICS');
create table storage.buckets (
  id text primary key,
  name text not null unique,
  owner uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  public boolean default false,
  avif_autodetection boolean default false,
  file_size_limit bigint,
  allowed_mime_types text[],
  owner_id text,
  type storage.buckettype not null default 'STANDARD'
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text,
  owner uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_accessed_at timestamptz default now(),
  metadata jsonb,
  path_tokens text[] generated always as (string_to_array(name, '/')) stored,
  version text,
  owner_id text,
  user_metadata jsonb,
  level integer,
  unique (bucket_id, name)
);
alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language plpgsql immutable as
  $$ declare _parts text[]; begin select string_to_array(name, '/') into _parts; return _parts[1:array_length(_parts, 1) - 1]; end $$;
create function storage.filename(name text) returns text language plpgsql immutable as
  $$ declare _parts text[]; begin select string_to_array(name, '/') into _parts; return _parts[array_length(_parts, 1)]; end $$;
create function storage.extension(name text) returns text language plpgsql immutable as
  $$ declare _parts text[]; _filename text; begin select string_to_array(name, '/') into _parts; select _parts[array_length(_parts, 1)] into _filename; return reverse(split_part(reverse(_filename), '.', 1)); end $$;
-- GoTrue's own migrations, on first start, add columns to auth.users and
-- redefine auth.uid()/auth.role() to read request.jwt.claims, and add
-- auth.jwt(); the image alone has the initial schema. Reduced to what the
-- migrations and tests read.
alter table auth.users
  add column if not exists is_anonymous boolean not null default false,
  add column if not exists is_sso_user boolean not null default false,
  add column if not exists deleted_at timestamptz,
  add column if not exists phone text,
  add column if not exists email_confirmed_at timestamptz,
  add column if not exists banned_until timestamptz;
create or replace function auth.uid() returns uuid language sql stable as
  $$ select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid $$;
create or replace function auth.role() returns text language sql stable as
  $$ select coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text $$;
create or replace function auth.jwt() returns jsonb language sql stable as
  $$ select coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb $$;
grant execute on function auth.uid(), auth.role(), auth.jwt() to postgres, anon, authenticated, service_role;
alter type storage.buckettype owner to postgres;
alter table storage.buckets owner to postgres;
alter table storage.objects owner to postgres;
alter function storage.foldername(text) owner to postgres;
alter function storage.filename(text) owner to postgres;
alter function storage.extension(text) owner to postgres;
grant usage on schema storage to postgres, anon, authenticated, service_role;
grant all on all tables in schema storage to anon, authenticated, service_role;
grant all on all functions in schema storage to anon, authenticated, service_role;
SQL
for f in "$REPO"/supabase/migrations/*.sql; do
  "${P[@]}" -f - < "$f" || { echo "MIGRATION FAILED $(basename "$f")"; exit 1; }
done
tests=("$@")
[ ${#tests[@]} -eq 0 ] && tests=("$REPO"/supabase/tests/database/*.sql)
fail=0
for t in "${tests[@]}"; do
  if ! out=$("${P[@]}" -t -A -f - < "$t" 2>&1); then
    echo "ERROR $(basename "$t")"; echo "$out" | tail -5; fail=1; continue
  fi
  if echo "$out" | grep -q '^not ok\|Looks like'; then
    echo "FAIL  $(basename "$t")"; echo "$out" | grep -A3 '^not ok\|Looks like'; fail=1
  else
    echo "ok    $(basename "$t") ($(echo "$out" | grep -c '^ok'))"
  fi
done
exit $fail
