#!/usr/bin/env python3
"""Bundle host test files into a few entrypoints for one `flutter test` run.

`flutter test` compiles every test file on its own and starts a fresh
`flutter_tester` for it, so the suite pays about 1.4 s per file however small
the file is (spec 2026-10-02-test-suite-bundling-design.md §1.1). A bundle
imports many files and runs each one's `main` inside a `group` named by its
path, so that cost is paid once per bundle and every reported test still names
its file.

`dod_check.sh` is the only caller. It takes the targets `flutter test` would
take (files or directories under `test/`), writes the bundles under
`.dart_tool/memox_test_bundles/` (or the `--out` directory below it the gate
gives each run) and prints their paths, one per line.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

from build_verification_plan import discover_tests, is_golden_only_test, normalize_path


BUNDLE_DIR = ".dart_tool/memox_test_bundles"
BUNDLES_ENV = "MEMOX_TEST_BUNDLES"
# **At most eight by default.** Each bundle is a `flutter_tester` of ~300 MB
# beside the analyzer and the guard, and 8 bundles already measured slower
# than 4 on 4 cores (spec §1.1); `os.cpu_count()` also ignores container
# quotas. `MEMOX_TEST_BUNDLES` may still ask for more.
DEFAULT_MAX_BUNDLES = 8
TEST_CONFIG = "test/flutter_test_config.dart"

# **What a bundle cannot carry.** `flutter test` reads a library-level
# annotation (`@Tags`, `@Timeout`, `@TestOn`, `@Skip`, `@OnPlatform`) from the
# file it is handed, so inside a bundle it would be dropped without a word; and
# `group` refuses an async body, so an async `main` cannot be wrapped. Both are
# refused by name rather than run differently from how they read.
_LEADING_ANNOTATION = re.compile(r"\A(?:\s|//[^\n]*\n|/\*[\s\S]*?\*/)*@(\w+)")
_ASYNC_MAIN = re.compile(
    r"(?m)^[ \t]*(?:"
    r"(?:void|dynamic|Future(?:Or)?(?:<[^>\n]*>)?)?\s*main\s*\([^)]*\)\s*async\b"
    r"|Future(?:Or)?(?:<[^>\n]*>)?\s*main\s*\("
    r")"
)


class BundleError(Exception):
    """A selection that cannot be bundled; the message names why."""


def bundle_count(env_value: str | None, cpu_count: int | None) -> int:
    """`MEMOX_TEST_BUNDLES` when set, else one bundle per core, at most
    [DEFAULT_MAX_BUNDLES].

    `0` means "do not bundle"; `dod_check.sh` decides that before calling, so
    reaching here with it is a caller error.
    """
    if env_value is None or not env_value.strip():
        return max(1, min(cpu_count or 1, DEFAULT_MAX_BUNDLES))
    try:
        count = int(env_value)
    except ValueError:
        raise BundleError(
            f"{BUNDLES_ENV} must be a whole number, got {env_value!r}"
        ) from None
    if count < 1:
        raise BundleError(
            f"{BUNDLES_ENV}={count} disables bundling; dod_check.sh runs the "
            "files one by one then, so this script should not have been called"
        )
    return count


def expand_targets(root: Path, targets: list[str]) -> list[str]:
    """Every runnable test file a target names, sorted and without repeats.

    A `.dart` target is that file; anything else is a directory and stands for
    every runnable test below it, the way `flutter test <dir>` reads it.
    """
    runnable = discover_tests(root)
    selected: set[str] = set()
    for raw in targets:
        target = normalize_path(raw).rstrip("/")
        if not target:
            continue
        if target.endswith(".dart"):
            if not (root / target).is_file():
                raise BundleError(f"no such test file: {target}")
            selected.add(target)
            continue
        if not (root / target).is_dir():
            raise BundleError(f"no such test directory: {target}")
        prefix = target + "/"
        selected.update(path for path in runnable if path.startswith(prefix))
    return sorted(selected)


def select_files(root: Path, files: list[str]) -> list[str]:
    """[files] without the golden-only ones, refusing what cannot be bundled."""
    kept: list[str] = []
    refused: list[str] = []
    for path in files:
        if is_golden_only_test(root / path):
            continue
        text = (root / path).read_text(encoding="utf-8")
        annotation = _LEADING_ANNOTATION.match(text)
        if annotation:
            refused.append(
                f"{path}: library-level @{annotation.group(1)} would be dropped "
                "in a bundle; put it on the group or test instead"
            )
        elif _ASYNC_MAIN.search(text):
            refused.append(
                f"{path}: an async main cannot run inside a group; make main "
                "synchronous and move the awaits into setUpAll"
            )
        else:
            kept.append(path)
    if refused:
        raise BundleError("cannot bundle:\n  " + "\n  ".join(refused))
    return kept


def partition(files: list[str], count: int) -> list[list[str]]:
    """Deal [files] out in turn over [count] bundles; empty bundles are dropped.

    Sorted input gives the same bundles on every run, and dealing in turn
    measured balanced (60–87 s per bundle over the whole suite, spec §3.1).
    """
    buckets = [files[index::count] for index in range(count)]
    return [bucket for bucket in buckets if bucket]


def _dart_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    return f"'{escaped}'"


def render_bundle(files: list[str], *, with_config: bool, up: str = "../../") -> str:
    """The Dart source of one bundle importing [files] through [up], the way
    back from the bundle's directory to the repository root."""
    lines = [
        "// Generated by bundle_tests.py for one `flutter test` run. Do not edit.",
        "import 'package:flutter_test/flutter_test.dart';",
        "",
    ]
    if with_config:
        lines.append(f"import {_dart_string(up + TEST_CONFIG)} as config;")
    for index, path in enumerate(files):
        lines.append(f"import {_dart_string(up + path)} as t{index};")
    lines.append("")
    groups = [
        f"  group({_dart_string(path)}, t{index}.main);"
        for index, path in enumerate(files)
    ]
    # A bundle under `.dart_tool/` is outside `test/`, so `flutter test` does
    # not apply `test/flutter_test_config.dart` to it; the bundle calls it.
    if with_config:
        lines.append("Future<void> main() => config.testExecutable(() {")
        lines.extend(groups)
        lines.append("});")
    else:
        lines.append("void main() {")
        lines.extend(groups)
        lines.append("}")
    return "\n".join(lines) + "\n"


def out_dir(raw: str | None) -> str:
    """The repo-relative directory the bundles go to: [BUNDLE_DIR] or a
    directory below it, so a stale bundle can never land in `test/`."""
    if raw is None:
        return BUNDLE_DIR
    value = normalize_path(raw).rstrip("/")
    if value != BUNDLE_DIR and not value.startswith(BUNDLE_DIR + "/"):
        raise BundleError(f"--out {raw} must be under {BUNDLE_DIR}")
    return value


def write_bundles(
    root: Path, files: list[str], count: int, directory: str = BUNDLE_DIR
) -> list[str]:
    """Replace the bundles in [directory]; return their repo-relative paths.

    **One directory per run.** Two gate runs in one checkout would otherwise
    rewrite each other's bundles while the frontend server is still compiling
    them, and a full run could pass on a `--fast` run's bundles.
    """
    out = root / directory
    out.mkdir(parents=True, exist_ok=True)
    up = "../" * (directory.count("/") + 1)
    for stale in out.glob("*.dart"):
        stale.unlink()
    with_config = (root / TEST_CONFIG).is_file()
    written: list[str] = []
    for index, bucket in enumerate(partition(files, count)):
        relative = f"{directory}/bundle_{index}_test.dart"
        (root / relative).write_text(
            render_bundle(bucket, with_config=with_config, up=up), encoding="utf-8"
        )
        written.append(relative)
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--paths-file", type=Path)
    parser.add_argument("--out")
    parser.add_argument("targets", nargs="*")
    args = parser.parse_args(argv)

    targets = list(args.targets)
    if args.paths_file:
        targets.extend(
            item.decode("utf-8")
            for item in args.paths_file.read_bytes().split(b"\0")
            if item
        )
    root = args.root.resolve()
    try:
        count = bundle_count(os.environ.get(BUNDLES_ENV), os.cpu_count())
        directory = out_dir(args.out)
        files = select_files(root, expand_targets(root, targets))
    except BundleError as error:
        print(f"bundle_tests: {error}", file=sys.stderr)
        return 1
    if not files:
        print("bundle_tests: the targets name no runnable test file", file=sys.stderr)
        return 0
    written = write_bundles(root, files, count, directory)
    print(
        f"bundle_tests: {len(files)} test files in {len(written)} bundles "
        f"under {directory}",
        file=sys.stderr,
    )
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
