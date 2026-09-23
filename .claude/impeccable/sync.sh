#!/bin/bash
# Vendor Impeccable (https://github.com/pbakaus/impeccable, Apache-2.0) for
# Claude Code into this repo, so every session — including a fresh cloud
# container — has it without `npx impeccable install` (whose signed-bundle
# download is not reachable from every network).
#
#   .claude/impeccable/sync.sh [git-ref]      (default: the ref in UPSTREAM)
#
# Copies upstream's project-scope Claude build unchanged:
#   .claude/skills/impeccable/   → .claude/skills/impeccable/
#   .claude/agents/impeccable-*  → .claude/agents/
# Its hooks (PostToolUse Edit|Write, Stop) are registered in
# .claude/settings.json by hand; re-check them against upstream's
# .claude/settings.json when syncing. The engine binary is not vendored: the
# launcher downloads it once per machine into ~/.impeccable/bin/.
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
DIR="$ROOT/.claude/impeccable"
REPO="https://github.com/pbakaus/impeccable.git"
REF="${1:-$(sed -n 's/^ref: //p' "$DIR/UPSTREAM" 2>/dev/null || true)}"
REF="${REF:-main}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet --filter=blob:none --no-checkout "$REPO" "$TMP/imp"
git -C "$TMP/imp" sparse-checkout set --no-cone \
  '/.claude/skills/impeccable/' '/.claude/agents/' '/.claude/settings.json' \
  '/plugin/.claude-plugin/' '/.claude-plugin/' '/LICENSE' '/NOTICE.md'
git -C "$TMP/imp" checkout --quiet "$REF"
COMMIT="$(git -C "$TMP/imp" rev-parse HEAD)"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$TMP/imp/.claude-plugin/plugin.json" | head -1)"

rm -rf "$ROOT/.claude/skills/impeccable"
cp -R "$TMP/imp/.claude/skills/impeccable" "$ROOT/.claude/skills/impeccable"
mkdir -p "$ROOT/.claude/agents"
rm -f "$ROOT/.claude/agents"/impeccable-*.md
cp "$TMP/imp/.claude/agents"/impeccable-*.md "$ROOT/.claude/agents/"

cp "$TMP/imp/LICENSE" "$DIR/LICENSE"
cp "$TMP/imp/NOTICE.md" "$DIR/NOTICE.md"
cp "$TMP/imp/.claude/settings.json" "$DIR/upstream-settings.json"
printf 'repo: %s\nref: %s\ncommit: %s\nversion: %s\n' "$REPO" "$REF" "$COMMIT" "$VERSION" > "$DIR/UPSTREAM"
echo "vendored impeccable $VERSION ($COMMIT)"
