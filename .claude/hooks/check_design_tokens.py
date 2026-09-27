"""PostToolUse hook: the guard's design-token rules, on the file just edited.

The guard (`guard/run.py check --ruleset memox-v8`) runs every rule over the
whole tree and is the real gate — but it runs at the gate, after the code is
written. This hook closes that latency gap: after every Edit or Write of a Dart
file it loads memox-v8 through the guard's own loader, keeps the design-token
rules, and runs them on a copy of that one file, reporting violations back into
the same working turn.

The rules, their scopes and the overrides come from the guard's loader, and the
check is the guard's own rule code, so the hook reports exactly what the guard
would for that file.

Exit codes: 0 = clean or out of scope; 2 = violations (stderr is fed back to
the model). Any environment problem (a missing package, an unreadable registry)
exits 0 — the hook is an accelerant, not the gate. The tests in
`.claude/hooks/tests/`, which the gate runs, are what notice a hook that has
stopped working.
"""

from __future__ import annotations

import json
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD_ROOT = REPO_ROOT / "code-verification-guard-v2"
RULESET = "memox-v8"
RULE_PREFIX = "memox.design_token."


@dataclass(frozen=True)
class Finding:
    rule_id: str
    line: int
    code_line: str
    message: str


def _put_guard_on_path() -> None:
    if str(GUARD_ROOT) not in sys.path:
        sys.path.insert(0, str(GUARD_ROOT))


def repository_path(payload: dict) -> str | None:
    """The edited file's path relative to the repository; None when the payload
    names no file, a file that is gone, or one outside the repository."""
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    raw = tool_input.get("file_path") or tool_response.get("filePath")
    if not raw:
        return None
    path = Path(raw).resolve()
    if not path.is_file():
        return None
    try:
        return path.relative_to(REPO_ROOT.resolve()).as_posix()
    except ValueError:
        return None


def design_token_rules() -> list[dict]:
    """memox-v8's enabled design-token rules, as the guard's loader resolves them."""
    _put_guard_on_path()
    from code_verification_guard.config.config_manager import ConfigManager

    _, rules = ConfigManager().load_ruleset_runtime(REPO_ROOT, RULESET)
    return [
        rule
        for rule in rules
        if rule["id"].startswith(RULE_PREFIX) and rule.get("enabled", True)
    ]


def findings_for(relative_path: str, text: str) -> list[Finding]:
    """What the design-token rules report for [text] at [relative_path]."""
    rules = design_token_rules()
    from code_verification_guard.factory.rule_factory import RuleFactory

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        copy = root / relative_path
        copy.parent.mkdir(parents=True, exist_ok=True)
        copy.write_text(text, encoding="utf-8")
        findings = [
            Finding(
                violation.rule_id,
                violation.line_number or 0,
                violation.code_line or "",
                " ".join(violation.message.split()),
            )
            for rule in rules
            for violation in RuleFactory().create(rule).check(root)
        ]
    return sorted(findings, key=lambda finding: (finding.line, finding.rule_id))


def report(relative_path: str, findings: list[Finding]) -> int:
    if not findings:
        return 0
    blocks = [
        f"[{finding.rule_id}] {relative_path}:{finding.line}\n"
        f"  {finding.code_line}\n"
        f"  {finding.message}"
        for finding in findings
    ]
    print(
        "Design-token check failed for the file just edited "
        "(the guard's memox-v8 rules):\n\n" + "\n\n".join(blocks),
        file=sys.stderr,
    )
    return 2


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if not isinstance(payload, dict):
        return 0
    relative_path = repository_path(payload)
    if relative_path is None or not relative_path.endswith(".dart"):
        return 0

    try:
        text = (REPO_ROOT / relative_path).read_text(encoding="utf-8")
        findings = findings_for(relative_path, text)
    except Exception:  # noqa: BLE001 — the hook must never block on env issues
        return 0
    return report(relative_path, findings)


if __name__ == "__main__":
    sys.exit(main())
