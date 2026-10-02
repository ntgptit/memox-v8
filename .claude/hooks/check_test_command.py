#!/usr/bin/env python3
"""PreToolUse hook (Bash): note when a command runs `flutter test` the slow way.

`flutter test <dir>` (or no target, or many files) compiles every test file on
its own and starts a process for each; `test/features` took about 4 minutes
that way and 1m33s through `run_tests.sh`, which bundles the same files
(2026-10-02). Agents reach for the direct command out of habit, and often run
it twice to filter the output two ways.

The hook never blocks and never decides a permission: it returns
`additionalContext`, which Claude Code places beside the tool result, so the
next run uses the script. Anything it cannot read, it lets pass in silence.
"""

from __future__ import annotations

import json
import re
import shlex
import sys

RUN_TESTS = "bash .claude/skills/flutter-workflow/scripts/run_tests.sh"
RUN_GOLDENS = "bash .claude/skills/flutter-workflow/scripts/run_goldens.sh"

# More `.dart` targets than this read as a suite, not as the file at hand.
MAX_FILES = 3

# `flutter test` options that take the next word as their value.
_VALUED = {
    "-j", "--concurrency", "-r", "--reporter", "--file-reporter", "-t", "--tags",
    "-x", "--exclude-tags", "-n", "--name", "--plain-name", "--timeout",
    "--total-shards", "--shard-index", "--dart-define", "--dart-define-from-file",
    "--coverage-path", "--test-randomize-ordering-seed", "--flavor", "-d", "--device-id",
}
_SEGMENT_SPLIT = re.compile(r"\|\||&&|[;|\n]")
_HEREDOC = re.compile(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")
_ENV_ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
# Words that may stand before a command without being the command.
_COMMAND_PREFIXES = {"time", "env", "command", "exec", "nice"}


def _strip_heredocs(command: str) -> str:
    """[command] without heredoc bodies: their lines are input, not commands."""
    lines = command.split("\n")
    kept: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        kept.append(line)
        index += 1
        for match in _HEREDOC.finditer(line):
            strip_tabs, delimiter = match.group(1) == "-", match.group(3)
            while index < len(lines):
                body = lines[index].lstrip("\t") if strip_tabs else lines[index]
                index += 1
                if body == delimiter:
                    break
    return "\n".join(kept)


def _segments(command: str) -> list[list[str]]:
    """Each simple command of [command] that runs `flutter test`, as words."""
    found: list[list[str]] = []
    for segment in _SEGMENT_SPLIT.split(_strip_heredocs(command)):
        try:
            words = shlex.split(segment, comments=True)
        except ValueError:
            continue
        # Only a command position counts: before `flutter` may stand nothing
        # but environment assignments and `time`-like prefixes, so `echo
        # flutter test` or a `-c` script that mentions it is not a run.
        index = 0
        while index < len(words) and (
            _ENV_ASSIGNMENT.match(words[index]) or words[index] in _COMMAND_PREFIXES
        ):
            index += 1
        if words[index:index + 2] == ["flutter", "test"]:
            found.append(words)
    return found


def _targets(arguments: list[str]) -> tuple[list[str], list[str]]:
    """The test targets and the flags of one `flutter test` call."""
    targets: list[str] = []
    flags: list[str] = []
    skip = False
    for word in arguments:
        if skip:
            flags.append(word)
            skip = False
        elif word.startswith("-"):
            flags.append(word)
            skip = word in _VALUED
        elif word.startswith(("2>", ">", "<")) or word.isdigit():
            continue
        else:
            targets.append(word)
    return targets, flags


def _judge(words: list[str]) -> str | None:
    at = words.index("flutter")
    prefix, arguments = words[:at], words[at + 2:]
    if any(word.startswith("MEMOX_TEST_BUNDLES=0") for word in prefix):
        return None
    targets, flags = _targets(arguments)
    golden = "golden" in flags and any(f in ("-t", "--tags") or f.startswith("--tags=") for f in flags)
    dart_files = [t for t in targets if t.endswith(".dart")]
    directories = [t for t in targets if not t.endswith(".dart")]
    if golden:
        if not targets or directories or len(dart_files) > MAX_FILES:
            return (
                "`flutter test --tags golden` without a single golden file compiles and "
                "starts every test file in test/ to run the golden ones (7m17s on "
                f"2026-10-02). `{RUN_GOLDENS}` compares them bundled in about a minute; "
                "`--update` rewrites them."
            )
        return None
    if targets and not directories and len(dart_files) <= MAX_FILES:
        return None
    scope = " ".join(targets) if targets else "the whole suite"
    shown = " ".join(targets)
    return (
        f"`flutter test` on {scope} runs file by file: each test file is compiled and "
        "started on its own, about 1.4 s per file before any test runs (test/features "
        f"took about 4 minutes this way, 1m33s bundled). `{RUN_TESTS}{' ' + shown if shown else ''}` "
        "runs the same tests bundled, prints only failures and a summary, and keeps its "
        "JSON report under .dart_tool/memox_test_bundles/ when a test fails, so one run "
        "is enough."
    )


def advise(command: str) -> str | None:
    """The note for [command], or None when it runs tests the fast way."""
    notes: list[str] = []
    runs = _segments(command)
    for words in runs:
        note = _judge(words)
        if note and note not in notes:
            notes.append(note)
    if not notes:
        return None
    if len(runs) > 1 and len({tuple(_targets(w[w.index("flutter") + 2:])[0]) for w in runs}) < len(runs):
        notes.append(
            "This command runs the same tests twice, only to filter the output another "
            "way; the run_tests.sh summary already lists every failure."
        )
    return " ".join(notes)


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
        command = (payload.get("tool_input") or {}).get("command") or ""
        note = advise(command) if isinstance(command, str) else None
    except Exception:  # noqa: BLE001 - a hook must never break the command
        return 0
    if note:
        print(json.dumps({
            "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": note}
        }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
