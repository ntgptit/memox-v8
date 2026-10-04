#!/usr/bin/env bash
# The auth integration tests on a local Supabase stack (spec
# docs/superpowers/specs/2026-10-05-auth-local-integration-tests-design.md):
# real GoTrue, PostgREST and Postgres, OTP codes read from the stack's Mailpit.
# A PR that changes lib/core/auth/, lib/features/account/ or
# supabase/migrations/ runs it, as it runs `npx supabase test db`.
# The suite lives in test_supabase/, outside the default suite, so
# run_tests.sh and dod_check.sh never need Docker.
# Usage: tools/supabase/run_auth_it.sh [flutter test targets…]
#   default target: test_supabase/auth
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO"

# Only what auth needs: GoTrue, PostgREST, Kong, Mailpit and Postgres. The
# rest is slower to start and has nothing the suite reads.
EXCLUDED=realtime,storage-api,imgproxy,postgres-meta,studio,edge-runtime,logflare,vector,supavisor
echo "run_auth_it: starting the local stack (Docker; the first start pulls images)"
npx --yes supabase start -x "$EXCLUDED" >/dev/null

status=$(npx --yes supabase status -o env 2>/dev/null)
value() { printf '%s\n' "$status" | sed -n "s/^$1=\"\{0,1\}\([^\"]*\)\"\{0,1\}\r\{0,1\}$/\1/p" | head -n 1; }
first() { for name in "$@"; do v=$(value "$name"); [ -n "$v" ] && { printf '%s' "$v"; return; }; done; }

export MEMOX_IT_API_URL MEMOX_IT_PUBLISHABLE_KEY MEMOX_IT_SERVICE_ROLE_KEY MEMOX_IT_MAILPIT_URL
MEMOX_IT_API_URL=$(first API_URL)
MEMOX_IT_PUBLISHABLE_KEY=$(first PUBLISHABLE_KEY ANON_KEY)
MEMOX_IT_SERVICE_ROLE_KEY=$(first SECRET_KEY SERVICE_ROLE_KEY)
MEMOX_IT_MAILPIT_URL=$(first MAILPIT_URL INBUCKET_URL)
for name in MEMOX_IT_API_URL MEMOX_IT_PUBLISHABLE_KEY MEMOX_IT_SERVICE_ROLE_KEY MEMOX_IT_MAILPIT_URL; do
  if [ -z "${!name}" ]; then
    echo "run_auth_it: $name is empty: \`npx supabase status -o env\` did not name it" >&2
    exit 1
  fi
done

[ $# -gt 0 ] || set -- test_supabase/auth
echo "run_auth_it: flutter test $*"
TZ=UTC flutter test -r failures-only "$@"
