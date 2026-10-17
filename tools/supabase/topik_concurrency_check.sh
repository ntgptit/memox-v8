#!/usr/bin/env bash
# Two-connection check of the TOPIK master-data admin RPCs (ADR-025, decision
# package 2026-10-17 §13.1 and §13.2). pgTAP runs one transaction on one
# connection, so it cannot show two admins racing; this script opens two psql
# sessions as role `authenticated`, both carrying the same admin's JWT claims, and
# proves, on the local stack:
#   1. concurrent publish: session A publishes content version 1 and holds its
#      transaction open; session B publishes the same version, blocks on the
#      per-test lock (the draft row, `for update`), and fails with
#      VERSION_MISMATCH once A commits. Exactly one version exists afterwards and
#      the publication points at it.
#   2. concurrent draft compare-and-set: both sessions save the draft naming the
#      same `updatedAt`; B blocks on the row lock, then fails with VERSION_MISMATCH.
#      The draft's `updatedAt` afterwards is A's.
# It is run by hand, never by the gate or CI: it COMMITS rows (an admin user, a
# Storage object row, a draft and one published version per run), and a published
# version is immutable, so the rows are left behind. Each run uses fresh test ids
# (`topik2-<1000-9999>-listening`), so reruns never collide.
# Usage: tools/supabase/topik_concurrency_check.sh   (prints PASS/FAIL per case;
#        exit 0 only when both pass, 1 on a FAIL, 2 when it refuses to run)
# Env:   DB_URL (default postgresql://postgres:postgres@127.0.0.1:54322/postgres,
#        the Supabase CLI local stack, `npx supabase db start`). The host must be
#        127.0.0.1 or localhost; anything else exits 2 before any connection.
set -euo pipefail

DB_URL=${DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}
# Host of the URL: after "@" (or "://" without credentials), up to ":" "/" or "?".
HOST=${DB_URL#*://}
HOST=${HOST##*@}
HOST=${HOST%%[:/?]*}
case "$HOST" in
  127.0.0.1 | localhost) ;;
  *)
    echo "REFUSED: DB_URL host '$HOST' is not 127.0.0.1 or localhost; this script commits rows and published versions are immutable." >&2
    exit 2
    ;;
esac
command -v psql >/dev/null || { echo "psql is required" >&2; exit 2; }

ADMIN=cccccccc-1111-4111-8111-000000000001
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PSQL=(psql "$DB_URL" -X -q -A -t -v ON_ERROR_STOP=1)
fail=0

# A TOPIK II listening section the way public.t_listening builds it in
# supabase/tests/database/20_topik_master_contract.sql: 50 questions of 2 points,
# one group each, audio named by a SHA-256 under version 1.
doc_for() {
  "${PSQL[@]}" -v t="$1" <<'SQL'
select jsonb_build_object(
    'schemaVersion', 1, 'contentVersion', 1,
    'testId', :'t'::text, 'level', 'topik2', 'round', split_part(:'t'::text, '-', 2)::integer, 'section', 'listening',
    'format', 'pbt', 'form', 'B-홀수형', 'titleKo', '제96회', 'officialTimeLimitSec', 3600,
    'source', jsonb_build_object('publishedBy', 'NIIED', 'url', 'https://www.topik.go.kr/x'),
    'assets', jsonb_build_object('audio', :'t'::text || '/1/' || repeat('a', 64) || '.mp3'),
    'groups', (select jsonb_agg(jsonb_build_object('groupId', 'g' || n, 'instructionKo', '※',
        'questionNos', jsonb_build_array(n),
        'audio', jsonb_build_object('startMs', 0, 'endMs', 1000, 'playCount', 2)))
      from generate_series(1, 50) n),
    'questions', (select jsonb_agg(jsonb_build_object('no', n, 'groupId', 'g' || n, 'questionType', 'X',
        'points', 2, 'stemKo', 'q',
        'options', jsonb_build_array(jsonb_build_object('idx', 1, 'textKo', 'a'),
          jsonb_build_object('idx', 2, 'textKo', 'b'), jsonb_build_object('idx', 3, 'textKo', 'c'),
          jsonb_build_object('idx', 4, 'textKo', 'd')),
        'answerIdx', 1))
      from generate_series(1, 50) n))
SQL
}

# A test id no earlier run used (draft table is the registry; versions only exist with a draft).
new_test_id() {
  local id
  while :; do
    id="topik2-$((RANDOM % 9000 + 1000))-listening"
    [ "$(sql_scalar -v t="$id" <<<"select count(*) from public.topik_test_draft where test_id = :'t'")" = 0 ] && break
  done
  echo "$id"
}

sql_scalar() { "${PSQL[@]}" "$@"; }

# Setup, as postgres, committed: the admin (fixed uuid, idempotent), the audio
# object row, then the first draft saved as that admin.
prepare_test() {
  local t=$1 doc
  doc=$(doc_for "$t")
  "${PSQL[@]}" -v t="$t" -v admin="$ADMIN" -v doc="$doc" >/dev/null <<'SQL'
insert into auth.users (id, email, is_anonymous) values (:'admin', 'concurrency-admin@example.com', false)
on conflict (id) do nothing;
update public.profiles set role = 'admin' where id = :'admin';
insert into storage.objects (bucket_id, name)
values ('topik-media', :'t' || '/1/' || repeat('a', 64) || '.mp3');
begin;
set local role authenticated;
select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', :'admin'), true);
select public.topik_admin_draft_save(:'t', :'doc'::jsonb, '{}'::jsonb, true);
commit;
SQL
}

# Session preamble: role authenticated with the admin's claims, for the whole session.
AS_ADMIN="set role authenticated; select set_config('request.jwt.claims', format('{\"sub\":\"%s\",\"role\":\"authenticated\"}', :'admin'), false);"

now_ms() { echo $(($(date +%s%N) / 1000000)); }

report() { # report <case> <failures…>
  local name=$1
  shift
  if [ $# -eq 0 ]; then
    echo "PASS $name"
  else
    echo "FAIL $name: $*"
    fail=1
  fi
}

# ---------------------------------------------------------------------------
# Case 1: concurrent publish
# ---------------------------------------------------------------------------
case_publish() {
  local name="concurrent publish" t errs=()
  t=$(new_test_id)
  prepare_test "$t"
  "${PSQL[@]}" -v t="$t" -v admin="$ADMIN" >"$WORK/p_a.out" 2>"$WORK/p_a.err" <<SQL &
begin;
$AS_ADMIN
select public.topik_admin_publish(:'t', 1, 'a');
select pg_sleep(3);
commit;
SQL
  local pid=$! t0 t1 rc_b=0
  sleep 1
  t0=$(now_ms)
  "${PSQL[@]}" -v t="$t" -v admin="$ADMIN" >"$WORK/p_b.out" 2>"$WORK/p_b.err" <<SQL || rc_b=$?
$AS_ADMIN
select public.topik_admin_publish(:'t', 1, 'b');
SQL
  t1=$(now_ms)
  local rc_a=0
  wait "$pid" || rc_a=$?

  [ "$rc_a" -eq 0 ] || errs+=("session A exited $rc_a: $(cat "$WORK/p_a.err")")
  grep -q '"contentVersion": 1' "$WORK/p_a.out" || errs+=("session A did not publish contentVersion 1: $(cat "$WORK/p_a.out")")
  [ "$rc_b" -ne 0 ] || errs+=("session B succeeded: $(cat "$WORK/p_b.out")")
  grep -q 'VERSION_MISMATCH' "$WORK/p_b.err" || errs+=("session B did not fail with VERSION_MISMATCH: $(cat "$WORK/p_b.err")")
  [ $((t1 - t0)) -ge 1500 ] || errs+=("session B returned after $((t1 - t0)) ms; it did not wait for A's lock")
  local versions current
  versions=$(sql_scalar -v t="$t" <<<"select count(*) from public.topik_test_version where test_id = :'t'")
  current=$(sql_scalar -v t="$t" <<<"select coalesce((select current_version::text from public.topik_publication where test_id = :'t'), 'none')")
  [ "$versions" = 1 ] || errs+=("$versions versions exist, expected exactly 1")
  [ "$current" = 1 ] || errs+=("the publication points at '$current', expected 1")
  report "$name ($t)" "${errs[@]}"
}

# ---------------------------------------------------------------------------
# Case 2: concurrent draft compare-and-set
# ---------------------------------------------------------------------------
case_draft_cas() {
  local name="concurrent draft compare-and-set" t errs=() doc updated
  t=$(new_test_id)
  prepare_test "$t"
  doc=$(doc_for "$t")
  # updatedAt exactly as topik_admin_draft_get returns it (a microsecond string).
  updated=$("${PSQL[@]}" -v t="$t" -v admin="$ADMIN" <<SQL | tail -n 1
begin;
set local role authenticated;
select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', :'admin'), true);
select public.topik_admin_draft_get(:'t')->>'updatedAt';
commit;
SQL
  )
  [ -n "$updated" ] || { report "$name ($t)" "could not read the draft's updatedAt"; return; }

  "${PSQL[@]}" -v t="$t" -v admin="$ADMIN" -v doc="$doc" -v at="$updated" >"$WORK/d_a.out" 2>"$WORK/d_a.err" <<SQL &
begin;
$AS_ADMIN
select public.topik_admin_draft_save(:'t', :'doc'::jsonb, '{}'::jsonb, false, :'at'::timestamptz)->>'updatedAt';
select pg_sleep(3);
commit;
SQL
  local pid=$! t0 t1 rc_b=0 rc_a=0
  sleep 1
  t0=$(now_ms)
  "${PSQL[@]}" -v t="$t" -v admin="$ADMIN" -v doc="$doc" -v at="$updated" >"$WORK/d_b.out" 2>"$WORK/d_b.err" <<SQL || rc_b=$?
$AS_ADMIN
select public.topik_admin_draft_save(:'t', :'doc'::jsonb, '{}'::jsonb, false, :'at'::timestamptz)->>'updatedAt';
SQL
  t1=$(now_ms)
  wait "$pid" || rc_a=$?

  local a_at
  a_at=$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$WORK/d_a.out" || true)
  [ "$rc_a" -eq 0 ] || errs+=("session A exited $rc_a: $(cat "$WORK/d_a.err")")
  [ -n "$a_at" ] && [ "$a_at" != "$updated" ] || errs+=("session A returned no new updatedAt: '$a_at'")
  [ "$rc_b" -ne 0 ] || errs+=("session B succeeded: $(cat "$WORK/d_b.out")")
  grep -q 'VERSION_MISMATCH' "$WORK/d_b.err" || errs+=("session B did not fail with VERSION_MISMATCH: $(cat "$WORK/d_b.err")")
  [ $((t1 - t0)) -ge 1500 ] || errs+=("session B returned after $((t1 - t0)) ms; it did not wait for A's lock")
  local final
  final=$("${PSQL[@]}" -v t="$t" -v admin="$ADMIN" <<SQL | tail -n 1
begin;
set local role authenticated;
select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}', :'admin'), true);
select public.topik_admin_draft_get(:'t')->>'updatedAt';
commit;
SQL
  )
  [ "$final" = "$a_at" ] || errs+=("the draft's updatedAt is '$final', expected A's '$a_at'")
  report "$name ($t)" "${errs[@]}"
}

case_publish
case_draft_cas
exit "$fail"
