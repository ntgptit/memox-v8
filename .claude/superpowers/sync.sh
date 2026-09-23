#!/bin/bash
# Vendor the Superpowers skills (https://github.com/obra/superpowers, MIT) into
# .claude/skills/ so every Claude Code session — including a fresh cloud
# container — has them without installing the plugin.
#
#   .claude/superpowers/sync.sh [git-ref]      (default: the ref in UPSTREAM)
#
# Copies upstream skills/<name>/ to .claude/skills/<name>/, replacing any earlier
# copy, and rewrites the plugin-namespaced skill names `superpowers:<name>` to
# `<name>`, the name a project skill is invoked by. Nothing else is changed.
# Records the vendored commit in .claude/superpowers/UPSTREAM.
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
DIR="$ROOT/.claude/superpowers"
REPO="https://github.com/obra/superpowers.git"
REF="${1:-$(sed -n 's/^ref: //p' "$DIR/UPSTREAM" 2>/dev/null || true)}"
REF="${REF:-main}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet "$REPO" "$TMP/sp"
git -C "$TMP/sp" checkout --quiet "$REF"
COMMIT="$(git -C "$TMP/sp" rev-parse HEAD)"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$TMP/sp/.claude-plugin/plugin.json" | head -1)"

# Drop skills vendored last time, then copy the current set.
if [ -f "$DIR/SKILLS" ]; then
  while read -r name; do
    [ -n "$name" ] && rm -rf "$ROOT/.claude/skills/$name"
  done < "$DIR/SKILLS"
fi
: > "$DIR/SKILLS"
for src in "$TMP/sp/skills"/*/; do
  name="$(basename "$src")"
  if [ -e "$ROOT/.claude/skills/$name" ]; then
    echo "refusing to overwrite non-Superpowers skill .claude/skills/$name" >&2
    exit 1
  fi
  cp -R "$src" "$ROOT/.claude/skills/$name"
  echo "$name" >> "$DIR/SKILLS"
done

# `superpowers:<name>` → `<name>` in every vendored text file.
while read -r name; do
  files="$(grep -rlI 'superpowers:[a-z]' "$ROOT/.claude/skills/$name" || true)"
  [ -z "$files" ] || printf '%s\n' "$files" | xargs sed -i -E 's/superpowers:([a-z][a-z0-9-]*)/\1/g'
done < "$DIR/SKILLS"

cp "$TMP/sp/LICENSE" "$DIR/LICENSE"
printf 'repo: %s\nref: %s\ncommit: %s\nversion: %s\n' "$REPO" "$REF" "$COMMIT" "$VERSION" > "$DIR/UPSTREAM"
echo "vendored superpowers $VERSION ($COMMIT): $(wc -l < "$DIR/SKILLS") skills"
