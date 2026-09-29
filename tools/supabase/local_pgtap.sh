#!/usr/bin/env bash
# Local stand-in for `supabase test db` where Docker is unavailable: a throwaway
# Postgres 16 cluster with pgTAP and a shim for the Supabase roles, auth.uid() and
# auth.jwt(); pg_cron when postgresql-16-cron is installed.
# CI's `supabase` job stays the gate. Needs postgresql-16 and postgresql-16-pgtap.
# Usage: tools/supabase/local_pgtap.sh
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd)
BIN=/usr/lib/postgresql/16/bin
DATA=$(mktemp -d)
PORT=54329
RUN_AS=()
if [ "$(id -u)" = 0 ]; then chown postgres "$DATA"; RUN_AS=(su postgres -c); fi
run() { if [ ${#RUN_AS[@]} -gt 0 ]; then "${RUN_AS[@]}" "$*"; else bash -c "$*"; fi; }
run "$BIN/initdb -D $DATA -A trust >/dev/null"
# pg_cron, when installed (postgresql-16-cron), as Supabase preloads it.
OPTS="-p $PORT -k /tmp"
if [ -f /usr/share/postgresql/16/extension/pg_cron.control ]; then
  OPTS="$OPTS -c shared_preload_libraries=pg_cron -c cron.database_name=postgres"
fi
run "$BIN/pg_ctl -D $DATA -o '$OPTS' -l $DATA/log start -w >/dev/null"
trap 'run "$BIN/pg_ctl -D $DATA stop -m fast >/dev/null"; rm -rf "$DATA"' EXIT
P=(psql -h /tmp -p "$PORT" -U postgres -v ON_ERROR_STOP=1 -q)
"${P[@]}" <<'SQL'
alter database postgres set search_path = "$user", public, extensions;
create role anon nologin; create role authenticated nologin; create role service_role nologin;
create schema extensions; create schema auth;
-- As Supabase defines it: the sub claim, from either setting.
create function auth.uid() returns uuid language sql stable as
  $$ select coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb->>'sub'))::uuid $$;
grant usage on schema auth, extensions, public to anon, authenticated;
-- The whole claims object, as Supabase's auth.jwt() returns it.
create function auth.jwt() returns jsonb language sql stable as
  $$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $$;
grant execute on function auth.uid(), auth.jwt() to anon, authenticated;
SQL
for f in "$REPO"/supabase/migrations/*.sql; do "${P[@]}" -f "$f"; done
fail=0
for t in "$REPO"/supabase/tests/database/*.sql; do
  if ! out=$("${P[@]}" -t -A -f "$t" 2>&1); then
    echo "ERROR $(basename "$t")"; echo "$out" | tail -5; fail=1; continue
  fi
  if echo "$out" | grep -q '^not ok\|Looks like'; then
    echo "FAIL  $(basename "$t")"; echo "$out" | grep -A3 '^not ok\|Looks like'; fail=1
  else
    echo "ok    $(basename "$t") ($(echo "$out" | grep -c '^ok'))"
  fi
done
exit $fail
