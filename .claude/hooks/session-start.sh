#!/bin/bash
# SessionStart: load the vendored Superpowers `using-superpowers` skill into the
# session context, as the Superpowers plugin's own SessionStart hook does. The
# skills themselves are vendored in .claude/skills/ (see .claude/superpowers/).
set -euo pipefail

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
