#!/usr/bin/env bash
# SessionStart hook: install the Flutter SDK `.fvmrc` pins so `flutter analyze`
# / `flutter test` work in Claude Code on the web (cloud) sessions, before the
# Flutter project itself exists (no `flutter create` here — that is a separate
# step, done once there is a pubspec.yaml to create).
#
# Only runs in the remote (cloud) environment. Installs to a stable location
# outside the repo ($HOME/.flutter-sdk/<version>/flutter) and persists PATH
# via $CLAUDE_ENV_FILE for the rest of the session. Idempotent: a second run
# with the same .fvmrc version is a fast no-op (no re-download).
#
# Failure here is loud (clear message, non-zero exit) but does not block the
# other SessionStart hook (session-start.sh) — they are separate settings
# entries.
set -uo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
  exit 0
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${CLAUDE_PROJECT_DIR:-$(git -C "$here" rev-parse --show-toplevel 2>/dev/null || pwd)}"
fvmrc="$repo_root/.fvmrc"

fail() {
  echo "✗ install-flutter.sh: $*" >&2
  exit 1
}

[[ -f "$fvmrc" ]] || fail "no .fvmrc at $fvmrc — nothing to install"

version="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$fvmrc" | head -1)"
[[ -n "$version" ]] || fail ".fvmrc exists but names no flutter version"

sdk_root="$HOME/.flutter-sdk/$version"
flutter_dir="$sdk_root/flutter"
flutter_bin="$flutter_dir/bin"

echo "install-flutter.sh: target Flutter $version"

already_installed=false
if [[ -x "$flutter_bin/flutter" ]]; then
  have="$("$flutter_bin/flutter" --version 2>/dev/null | sed -n 's/^Flutter \([0-9][^ ]*\).*/\1/p' | head -1)"
  if [[ "$have" == "$version" ]]; then
    already_installed=true
    echo "install-flutter.sh: Flutter $version already installed at $flutter_dir — skipping download"
  else
    echo "install-flutter.sh: found $flutter_dir but it reports '${have:-unknown}', reinstalling"
    rm -rf "$sdk_root"
  fi
fi

if [[ "$already_installed" == false ]]; then
  manifest_url="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "install-flutter.sh: fetching release manifest"
  curl -fsSL --cacert /root/.ccr/ca-bundle.crt "$manifest_url" -o "$tmp_dir/releases_linux.json" \
    || fail "could not download release manifest from $manifest_url (check HTTPS_PROXY / see /root/.ccr/README.md)"

  release_info="$(python3 - "$tmp_dir/releases_linux.json" "$version" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
version = sys.argv[2]
base_url = data.get("base_url", "")
match = None
for r in data.get("releases", []):
    if r.get("version") == version and r.get("channel") == "stable" and r.get("dart_sdk_arch", "x64") == "x64":
        match = r
        break
if match is None:
    print("", "", "")
else:
    print(base_url, match["archive"], match["sha256"])
PY
)"
  read -r base_url archive sha256 <<<"$release_info"

  [[ -n "$archive" ]] || fail "no stable linux x64 release for Flutter $version in the manifest"

  archive_url="$base_url/$archive"
  archive_path="$tmp_dir/$(basename "$archive")"

  echo "install-flutter.sh: downloading $archive_url"
  curl -fsSL --cacert /root/.ccr/ca-bundle.crt "$archive_url" -o "$archive_path" \
    || fail "could not download $archive_url (check HTTPS_PROXY / see /root/.ccr/README.md)"

  actual_sha256="$(sha256sum "$archive_path" | awk '{print $1}')"
  [[ "$actual_sha256" == "$sha256" ]] \
    || fail "sha256 mismatch for $archive: expected $sha256, got $actual_sha256"

  echo "install-flutter.sh: sha256 verified, extracting"
  mkdir -p "$sdk_root"
  tar -xJf "$archive_path" -C "$sdk_root" \
    || fail "could not extract $archive_path into $sdk_root"

  rm -rf "$tmp_dir"
  trap - EXIT
fi

git config --global --add safe.directory "$flutter_dir" >/dev/null 2>&1 || true

if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  if ! grep -qF "$flutter_bin" "$CLAUDE_ENV_FILE" 2>/dev/null; then
    echo "export PATH=\"$flutter_bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  fi
fi

export PATH="$flutter_bin:$PATH"

"$flutter_bin/flutter" --disable-analytics >/dev/null 2>&1 || true
"$flutter_bin/dart" --disable-analytics >/dev/null 2>&1 || true

echo "install-flutter.sh: warming Dart SDK"
"$flutter_bin/flutter" --version || fail "'flutter --version' failed after install"

echo "install-flutter.sh: Flutter $version ready at $flutter_bin"
