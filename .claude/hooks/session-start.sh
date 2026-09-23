#!/bin/bash
# Install the Superpowers plugin declared in .claude/settings.json
# (extraKnownMarketplaces + enabledPlugins) on Claude Code on the web.
# Cloud containers start from a fresh Claude config, and declaring a plugin in
# project settings does not install it there, so this does. Idempotent: a
# plugin that is already installed is left as is.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PLUGIN="superpowers@superpowers-marketplace"
MARKETPLACE="obra/superpowers-marketplace"

cd "${CLAUDE_PROJECT_DIR:-.}"

if claude plugin list 2>/dev/null | grep -q "$PLUGIN"; then
  exit 0
fi

claude plugin marketplace add "$MARKETPLACE" --scope project >/dev/null
claude plugin install "$PLUGIN" --scope project >/dev/null
echo "Installed $PLUGIN" >&2
