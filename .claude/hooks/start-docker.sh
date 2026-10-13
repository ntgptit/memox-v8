#!/usr/bin/env bash
# SessionStart hook: start the Docker daemon in Claude Code on the web (cloud)
# sessions, so `npx supabase db start` / `npx supabase test db` and
# tools/supabase/run_auth_it.sh can run there. The cloud image ships the
# docker client and dockerd but starts no daemon.
#
# Remote-only and never loud: without a client, without dockerd, or when the
# daemon does not answer in time, it says so and exits 0. The gate
# (dod_check.sh) never needs Docker; only the Supabase checks do.
#
# Image pulls still depend on the environment's settings, not on this hook:
# the network policy must allow the registries' blob hosts, and Docker Hub
# rate-limits anonymous pulls. .claude/hooks/README.md lists what to change.
set -uo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
  exit 0
fi

say() { echo "start-docker.sh: $*"; }

if ! command -v docker >/dev/null 2>&1; then
  say "no docker client in this image; skipping"
  exit 0
fi

if docker info >/dev/null 2>&1; then
  say "Docker daemon already running"
  exit 0
fi

if ! command -v dockerd >/dev/null 2>&1; then
  say "no dockerd in this image; skipping"
  exit 0
fi

log="${TMPDIR:-/tmp}/dockerd.log"
# Detached from this shell, so the daemon outlives the hook.
(setsid nohup dockerd >"$log" 2>&1 &)

wait_seconds="${START_DOCKER_WAIT:-30}"
for _ in $(seq 1 "$wait_seconds"); do
  if docker info >/dev/null 2>&1; then
    say "Docker daemon started (log: $log)"
    exit 0
  fi
  sleep 1
done

say "Docker daemon did not answer within ${wait_seconds}s; see $log" >&2
exit 0
