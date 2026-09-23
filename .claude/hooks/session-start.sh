#!/bin/bash
# SessionStart:
# 1. Fetch the Impeccable engine once per machine (the launcher downloads it
#    into ~/.impeccable/bin/ on first run), so its 5-second Edit/Write hook does
#    not spend its budget downloading. Failure only delays that to first use.
# 2. Load the vendored Superpowers `using-superpowers` skill into the session
#    context, as the Superpowers plugin's own SessionStart hook does.
# Both are vendored in .claude/skills/ (see .claude/superpowers/, .claude/impeccable/).
set -euo pipefail

IMPECCABLE="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/impeccable/scripts/impeccable"
if [ -x "$IMPECCABLE" ]; then
  "$IMPECCABLE" --version >/dev/null 2>&1 </dev/null || true
fi

SKILL="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/using-superpowers/SKILL.md"
[ -f "$SKILL" ] || exit 0

python3 - "$SKILL" <<'PY'
import json, sys
body = open(sys.argv[1], encoding="utf-8").read()
context = (
    "<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n"
    "**Below is the full content of your 'using-superpowers' skill - your "
    "introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n"
    + body + "\n</EXTREMELY_IMPORTANT>"
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                          "additionalContext": context}}))
PY
