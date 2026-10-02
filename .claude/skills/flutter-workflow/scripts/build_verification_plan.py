#!/usr/bin/env python3
"""Build one immutable, fail-safe verification plan for a change set.

The plan grows monotonically: every rule may add checks, tests or downstream
features, but no rule can remove work selected by an earlier rule. Unknown and
high-risk paths promote the plan to the complete non-golden host suite.

`dod_check.sh --changed` is its only caller; V8's CI runs the full gate.
"""

from __future__ import annotations

import argparse
import json
import posixpath
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath
from typing import Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_IMPACT_MAP = SCRIPT_DIR / "verification_impact_map.json"
FEATURE_SOURCE_PREFIX = "lib/features/"
FEATURE_TEST_PREFIX = "test/features/"
LAYER_ORDER = ("domain", "data", "presentation")
PUBLIC_DOMAIN_BUCKETS = {
    "entities",
    "failures",
    "models",
    "repositories",
    "schedulers",
    "modes",
}


def normalize_path(raw: str) -> str:
    """Normalize separators without stripping a leading dot from `.github`."""
    value = raw.lstrip("\ufeff").rstrip("\r\n").replace("\\", "/")
    while value.startswith("./"):
        value = value[2:]
    return str(PurePosixPath(value)) if value else ""


@dataclass(frozen=True)
class VerificationPlan:
    """What `dod_check.sh --changed` runs, and why.

    The gate acts on `needs_static`, `needs_host_tests` and
    `local_test_targets`, and prints `risk`, `test_files` and `reasons`; the
    other fields explain the selection.
    """

    changed_paths: tuple[str, ...]
    affected_features: tuple[str, ...]
    affected_layers: tuple[str, ...]
    reasons: tuple[str, ...]
    unmatched_paths: tuple[str, ...]
    test_files: tuple[str, ...]
    local_test_targets: tuple[str, ...]
    risk: str
    needs_static: bool
    needs_host_tests: bool
    full_suite: bool

    def to_json_dict(self) -> dict[str, object]:
        payload = asdict(self)
        payload["changed_paths"] = list(self.changed_paths)
        payload["affected_features"] = list(self.affected_features)
        payload["affected_layers"] = list(self.affected_layers)
        payload["reasons"] = list(self.reasons)
        payload["unmatched_paths"] = list(self.unmatched_paths)
        payload["test_files"] = list(self.test_files)
        payload["local_test_targets"] = list(self.local_test_targets)
        return payload


@dataclass(frozen=True)
class ImpactMap:
    feature_dependencies: dict[str, tuple[str, ...]]
    database_query_features: dict[str, tuple[str, ...]]
    full_scope_prefixes: tuple[str, ...]
    full_scope_files: frozenset[str]
    # Paths that provably cannot change what Dart compiles, what tests run, or
    # what CI does. The bar is deliberately that high: everything else keeps
    # falling through to the full suite, which is the right default for a path
    # nobody has classified.
    inert_prefixes: tuple[str, ...]
    inert_files: frozenset[str]

    @classmethod
    def load(cls, path: Path = DEFAULT_IMPACT_MAP) -> "ImpactMap":
        raw = json.loads(path.read_text(encoding="utf-8"))
        if raw.get("version") != 1:
            raise ValueError("unsupported verification impact-map version")
        return cls(
            feature_dependencies={
                key: tuple(value)
                for key, value in raw["feature_dependencies"].items()
            },
            database_query_features={
                key: tuple(value)
                for key, value in raw["database_query_features"].items()
            },
            full_scope_prefixes=tuple(raw["full_scope_prefixes"]),
            full_scope_files=frozenset(raw["full_scope_files"]),
            inert_prefixes=tuple(raw.get("inert_prefixes", ())),
            inert_files=frozenset(raw.get("inert_files", ())),
        )


class VerificationPlanBuilder:
    """Mutable accumulator whose only public operations widen verification."""

    def __init__(self, root: Path, impact_map: ImpactMap) -> None:
        self.root = root.resolve()
        self.impact_map = impact_map
        self.changed_paths: set[str] = set()
        self.features: set[str] = set()
        self.layers: set[str] = set()
        self.reasons: set[str] = set()
        self.unmatched_paths: set[str] = set()
        self.test_prefixes: set[str] = set()
        self.exact_test_files: set[str] = set()
        self.has_code_changes = False
        self.requires_host_coverage = False
        self.has_golden_image_changes = False
        self.full_suite = False

    def add_reason(self, reason: str) -> None:
        self.reasons.add(reason)

    def require_full(self, reason: str, *, unmatched_path: str | None = None) -> None:
        self.full_suite = True
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.add_reason(reason)
        if unmatched_path:
            self.unmatched_paths.add(unmatched_path)

    def require_feature_layers(
        self, feature: str, layers: Iterable[str], reason: str
    ) -> None:
        normalized_layers = set(layers)
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.features.add(feature)
        self.layers.update(normalized_layers)
        self.add_reason(reason)
        for layer in normalized_layers:
            self.test_prefixes.add(f"test/features/{feature}/{layer}/")

    def require_downstream(self, feature: str, reason: str) -> None:
        pending = [feature]
        visited: set[str] = set()
        while pending:
            current = pending.pop()
            if current in visited:
                continue
            visited.add(current)
            for dependent in self.impact_map.feature_dependencies.get(current, ()):
                if dependent not in visited:
                    pending.append(dependent)
        for affected in visited:
            self.require_feature_layers(affected, LAYER_ORDER, reason)

    def require_all_presentation(self, reason: str) -> None:
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.layers.add("presentation")
        self.test_prefixes.update(
            {"test/features/", "test/app/", "test/shared/"}
        )
        self.add_reason(reason)

    def require_test_path(self, path: str, reason: str) -> None:
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.add_reason(reason)
        if path.endswith("_test.dart") and (self.root / path).is_file():
            if is_golden_only_test(self.root / path):
                self.require_all_presentation(
                    "golden-only change requires non-golden presentation surrogates"
                )
                return
            self.exact_test_files.add(path)
            return
        parts = path.split("/")
        if len(parts) >= 4 and parts[:2] == ["test", "features"]:
            feature = parts[2]
            layer = parts[3] if parts[3] in LAYER_ORDER else ""
            if layer:
                self.require_feature_layers(feature, (layer,), reason)
                return
        if path.startswith("test/app/"):
            self.test_prefixes.add("test/app/")
            return
        if path.startswith("test/core/"):
            segment = parts[2] if len(parts) > 2 else ""
            self.test_prefixes.add(f"test/core/{segment}/" if segment else "test/core/")
            return
        if path.startswith("test/shared/"):
            self.test_prefixes.add("test/shared/")
            return
        self.require_full("unrecognised test support path", unmatched_path=path)

    def classify_path(self, path: str) -> None:
        self.changed_paths.add(path)

        if path.startswith("docs/") or path in {"AGENTS.md", "CLAUDE.md", "README.md"}:
            self.add_reason("documentation contract changed")
            return

        if path.startswith(".claude/") and path.endswith(".md"):
            self.add_reason("agent workflow documentation changed")
            return

        # **Before the full-scope check, because `.github/` is a prefix there
        # and an issue template is not a pipeline.**
        #
        # These are not "low risk" paths, they are paths that cannot reach the
        # build at all: git plumbing, editor settings, repository furniture.
        # Anything that could change what Dart compiles, what tests run, or
        # what CI does stays out of this list and keeps its full run.
        if path in self.impact_map.inert_files or any(
            path.startswith(prefix) for prefix in self.impact_map.inert_prefixes
        ):
            self.add_reason("repository furniture changed; no build input touched")
            return

        if path in self.impact_map.full_scope_files or any(
            path.startswith(prefix) for prefix in self.impact_map.full_scope_prefixes
        ):
            self.require_full("high-risk or verification-infrastructure path changed")
            return

        # **A picture is not code.** Nothing the gate runs can fail on a
        # committed golden image; CI's `goldens` job is what compares it
        # against a fresh render. Returning here without claiming a code
        # change keeps a plan of pictures alone at no static check and no host
        # test, with the risk `pixels`. A picture beside a code change does not
        # narrow the plan: the code's own rule selects its checks.
        if "/goldens/" in path and not path.endswith(".dart"):
            self.has_golden_image_changes = True
            self.add_reason("committed golden image changed")
            return

        if path.startswith("test/"):
            self.require_test_path(path, "test or test support changed")
            return

        if path.startswith(FEATURE_SOURCE_PREFIX):
            self._classify_feature_source(path)
            return

        if path.startswith("lib/core/database/queries/") and path.endswith(".drift"):
            query_name = Path(path).stem
            features = self.impact_map.database_query_features.get(query_name)
            if not features:
                self.require_full("database query has no declared feature owner", unmatched_path=path)
                return
            for feature in features:
                self.require_downstream(feature, "database query contract changed")
            # Drift generation is gitignored, so a source-level Dart import
            # closure cannot see tests consuming the generated DAO methods.
            # These are the repository's cross-feature database contract
            # surfaces and must be added declaratively for every query change.
            self.test_prefixes.update({"test/database/", "test/integration/"})
            self.add_reason("database query cross-surface contracts selected")
            return

        if path.startswith("lib/core/database/"):
            self.require_full("database schema, migration or shared database path changed")
            return

        if path.startswith("lib/core/") or path.startswith("lib/main"):
            self.require_full("shared core or application entrypoint changed")
            return

        if path.startswith("lib/"):
            self.require_full("unrecognised production source path", unmatched_path=path)
            return

        if path.endswith(".md"):
            self.add_reason("markdown documentation changed")
            return

        self.require_full("unrecognised changed path", unmatched_path=path)

    def _classify_feature_source(self, path: str) -> None:
        parts = path.split("/")
        if len(parts) < 5:
            self.require_full("feature source path has no recognised layer", unmatched_path=path)
            return
        feature, layer = parts[2], parts[3]
        if layer == "domain":
            bucket = parts[4] if len(parts) > 4 else ""
            if bucket in PUBLIC_DOMAIN_BUCKETS:
                self.require_downstream(feature, "public domain contract changed")
                return
            if bucket == "usecases":
                self.require_feature_layers(
                    feature,
                    ("domain", "presentation"),
                    "feature use case changed",
                )
                return
            self.require_feature_layers(
                feature, LAYER_ORDER, "domain implementation changed"
            )
            return
        if layer == "data":
            self.require_feature_layers(feature, ("data",), "feature data layer changed")
            return
        if layer == "presentation":
            self.require_feature_layers(
                feature, ("presentation",), "feature presentation changed"
            )
            return
        if layer == "di":
            self.require_feature_layers(
                feature, ("presentation",), "feature dependency wiring changed"
            )
            self.test_prefixes.add("test/app/")
            return
        self.require_full("feature source path has unknown layer", unmatched_path=path)

    def seal(self) -> VerificationPlan:
        runnable_tests = discover_tests(self.root)
        consumer_tests = discover_test_consumers(
            self.root,
            {path for path in self.changed_paths if path.endswith(".dart")},
            runnable_tests,
        )
        if consumer_tests:
            self.exact_test_files.update(consumer_tests)
            self.add_reason("import-derived transitive test consumers selected")
        if self.full_suite:
            selected = runnable_tests
        else:
            selected = {
                path
                for path in runnable_tests
                if path in self.exact_test_files
                or any(path.startswith(prefix) for prefix in self.test_prefixes)
            }

        code_required = self.has_code_changes or self.full_suite
        needs_host_tests = code_required and bool(selected)
        if self.requires_host_coverage and not needs_host_tests:
            self.require_full("code change selected no executable verification")
            selected = runnable_tests
            needs_host_tests = bool(selected)

        # `pixels` rather than `docs` for a picture-only change: both require no
        # Dart verification, but calling a regenerated golden "docs" in the one
        # field a human reads at a glance is a small untruth in exactly the
        # place it would be believed.
        risk = (
            "full"
            if self.full_suite
            else "targeted"
            if code_required
            else "pixels"
            if self.has_golden_image_changes
            else "docs"
        )
        return VerificationPlan(
            changed_paths=tuple(sorted(self.changed_paths)),
            affected_features=tuple(sorted(self.features)),
            affected_layers=tuple(sorted(self.layers)),
            reasons=tuple(sorted(self.reasons)),
            unmatched_paths=tuple(sorted(self.unmatched_paths)),
            test_files=tuple(sorted(selected)),
            local_test_targets=compress_test_targets(selected, runnable_tests),
            risk=risk,
            needs_static=code_required,
            needs_host_tests=needs_host_tests,
            full_suite=self.full_suite,
        )


def compress_test_targets(
    selected_files: set[str], all_test_files: set[str]
) -> tuple[str, ...]:
    """Compress an exact selection to the fewest command-line targets.

    `dod_check.sh` hands the targets to `flutter test` on one command line,
    which on Windows cannot carry hundreds of files. A complete selected
    subtree becomes its directory, and only when no unselected test lives
    below it.
    """
    if not selected_files:
        return ()
    candidates: set[str] = set()
    for path in selected_files:
        for parent in PurePosixPath(path).parents:
            value = parent.as_posix()
            if value == "." or not value.startswith("test"):
                continue
            candidates.add(value)

    uncovered = set(selected_files)
    targets: list[str] = []
    for candidate in sorted(candidates, key=lambda value: (value.count("/"), value)):
        prefix = candidate + "/"
        tracked_below = {path for path in all_test_files if path.startswith(prefix)}
        if not tracked_below or not tracked_below <= selected_files:
            continue
        if any(
            candidate == chosen or candidate.startswith(chosen + "/")
            for chosen in targets
        ):
            continue
        targets.append(candidate)
        uncovered.difference_update(tracked_below)
    targets.extend(sorted(uncovered))
    return tuple(sorted(targets))


# **The worktree scan is memoized per process, and that is a scheduling fix
# rather than a correctness one.** Sealing a plan reads each test file to find
# the runnable ones, and every tracked Dart file to build the reverse import
# graph. The CLI builds one plan per process and pays that once;
# `test_ci_tooling.py` builds many plans against unchanging trees and would
# otherwise pay it for every one.
#
# **Keyed by resolved root, and only valid within one process.** The CLI builds
# one plan and exits, so nothing here can observe a tree that changed underneath
# it; the test that builds its own temporary git repo gets its own key rather
# than the repo's answer. A caller that edits files and re-plans in the same
# process would read the first scan — no such caller exists, and one would be
# asking for a plan against a tree that no longer exists anyway.
#
# There is deliberately no `clear()` here. Nothing needs one — a process that
# wanted a second answer would be a process that changed the tree between two
# plans, and the plan is a statement about one tree. Adding the escape hatch
# before a caller exists is the speculative structure `CLAUDE.md` refuses.
_WORKTREE_SCAN_CACHE: dict[str, frozenset[str]] = {}
_RUNNABLE_TEST_CACHE: dict[str, frozenset[str]] = {}
_REVERSE_IMPORT_CACHE: dict[str, dict[str, set[str]]] = {}


def discover_worktree_dart_files(root: Path) -> set[str]:
    """Return tracked plus existing untracked Dart files used by local gates."""
    key = str(root.resolve())
    cached = _WORKTREE_SCAN_CACHE.get(key)
    if cached is not None:
        # A copy, because callers own what they receive — `seal` builds sets from
        # this and a shared mutable would make one plan able to corrupt the next.
        return set(cached)
    paths: set[str] = set()
    for arguments in (
        ["ls-files", "-z", "--", "lib", "test"],
        ["ls-files", "--others", "--exclude-standard", "-z", "--", "lib", "test"],
    ):
        completed = subprocess.run(
            ["git", "-C", str(root), *arguments],
            check=True,
            capture_output=True,
        )
        paths.update(
            normalize_path(raw.decode("utf-8"))
            for raw in completed.stdout.split(b"\0")
            if raw and raw.decode("utf-8").endswith(".dart")
        )
    present = {path for path in paths if (root / path).is_file()}
    _WORKTREE_SCAN_CACHE[key] = frozenset(present)
    return present


# What may precede a library-level annotation in a Dart file: a byte-order
# mark, whitespace, and comments. `bundle_tests.py` reads annotations through
# the same prefix, so "golden-only" and "refused" agree on where a file starts.
LEADING_TRIVIA = r"(?:\ufeff|\s|//[^\n]*\n|/\*[\s\S]*?\*/)*"
GOLDEN_TAGS = re.compile(
    r"\A" + LEADING_TRIVIA + r"@Tags\s*\([^)]*?['\"]golden['\"][^)]*\)"
)


def is_golden_only_test(path: Path) -> bool:
    """Whether CI's `--exclude-tags golden` excludes the whole test file."""
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    return bool(path.name.endswith("_golden_test.dart") or GOLDEN_TAGS.match(text))


def discover_tests(root: Path) -> set[str]:
    """The runnable test files: every `_test.dart` under `test/` that is not
    golden-only."""
    key = str(root.resolve())
    cached = _RUNNABLE_TEST_CACHE.get(key)
    if cached is not None:
        return set(cached)
    paths = {
        path
        for path in discover_worktree_dart_files(root)
        if path.startswith("test/")
        and path.endswith("_test.dart")
        and not is_golden_only_test(root / path)
    }
    _RUNNABLE_TEST_CACHE[key] = frozenset(paths)
    return paths


def _package_name(root: Path) -> str:
    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"(?m)^name:\s*([A-Za-z0-9_]+)\s*$", pubspec)
    if not match:
        raise ValueError("pubspec.yaml has no package name")
    return match.group(1)


def _resolve_dart_uri(importer: str, uri: str, package_name: str) -> str | None:
    package_prefix = f"package:{package_name}/"
    if uri.startswith(package_prefix):
        return normalize_path(f"lib/{uri[len(package_prefix):]}")
    if ":" in uri:
        return None
    return normalize_path(posixpath.normpath(posixpath.join(posixpath.dirname(importer), uri)))


def _reverse_import_graph(root: Path) -> dict[str, set[str]]:
    """Map each Dart file to the files that import, export or part it.

    Memoized per root: this is the single most expensive read in the plan, and
    it depends on nothing but the tree. Private, and never handed out — callers
    below read it and do not mutate it, so no defensive copy is made of what is
    the largest structure here.
    """
    key = str(root.resolve())
    cached = _REVERSE_IMPORT_CACHE.get(key)
    if cached is not None:
        return cached

    package_name = _package_name(root)
    directive = re.compile(r"\b(?:import|export|part)\s+['\"]([^'\"]+)['\"]")
    reverse: dict[str, set[str]] = {}
    for importer in discover_worktree_dart_files(root):
        text = (root / importer).read_text(encoding="utf-8")
        for uri in directive.findall(text):
            dependency = _resolve_dart_uri(importer, uri, package_name)
            if dependency:
                reverse.setdefault(dependency, set()).add(importer)
    _REVERSE_IMPORT_CACHE[key] = reverse
    return reverse


def discover_test_consumers(
    root: Path,
    changed_dart_paths: set[str],
    runnable_tests: set[str],
) -> set[str]:
    """Find runnable tests that transitively import a changed Dart source.

    Folder ownership remains the primary fast-path policy. This reverse import
    closure seals its blind spots: app/router tests, integration tests, and
    cross-feature harnesses are included even when they live outside the
    changed feature/layer directory.
    """
    if not changed_dart_paths:
        return set()
    reverse = _reverse_import_graph(root)

    pending = list(changed_dart_paths)
    visited = set(changed_dart_paths)
    consumers: set[str] = set()
    while pending:
        dependency = pending.pop()
        for importer in reverse.get(dependency, set()):
            if importer in visited:
                continue
            visited.add(importer)
            pending.append(importer)
            if importer in runnable_tests:
                consumers.add(importer)
    return consumers


def build_plan(
    paths: Iterable[str],
    *,
    root: Path,
    impact_map: ImpactMap | None = None,
    force_full: bool = False,
) -> VerificationPlan:
    builder = VerificationPlanBuilder(root, impact_map or ImpactMap.load())
    normalized = sorted({normalize_path(path) for path in paths if normalize_path(path)})
    for path in normalized:
        builder.classify_path(path)
    if force_full or not normalized:
        reason = "manual full verification requested" if force_full else "empty change set"
        builder.require_full(reason)
    return builder.seal()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--impact-map", type=Path, default=DEFAULT_IMPACT_MAP)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--paths-file", type=Path)
    parser.add_argument("--force-full", action="store_true")
    parser.add_argument("--nul", action="store_true")
    args = parser.parse_args()

    raw = args.paths_file.read_bytes() if args.paths_file else sys.stdin.buffer.read()
    separator = b"\0" if args.nul else b"\n"
    paths = [item.decode("utf-8") for item in raw.split(separator) if item]
    plan = build_plan(
        paths,
        root=args.root.resolve(),
        impact_map=ImpactMap.load(args.impact_map),
        force_full=args.force_full,
    )
    payload = json.dumps(plan.to_json_dict(), ensure_ascii=False, separators=(",", ":"))
    if args.json_output:
        args.json_output.write_text(payload + "\n", encoding="utf-8")
        return 0
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
