# MemoX V8 — Host test suite bundling — design

Status: approved 2026-10-02 (design in conversation, then this spec) ·
Path: architectural (changes how the gate runs the host suite) ·
Owner rulings 2026-10-02 (§2): R1–R3

## 1. Intent

The host suite has grown faster than its runtime can bear. Between 2026-09-29 and 2026-10-01
the number of `test/**/*_test.dart` files went from 437 to 519, and the full non-golden run
now takes **13 min 31 s** in the cloud container (4 cores, Flutter 3.47.5). The header of
`dod_check.sh` still records 266 s for the whole gate on 2026-09-26.

The goal is a gate that is fast again and stays fast as files are added. Nobody should have to
change how they write a test to get there.

### 1.1 What was measured (2026-10-02, cloud container)

The measurements came from `--file-reporter json`, analysed per suite. Each probe was
throwaway and none of it was committed.

| Run | Wall clock | Load (compile) summed | Test bodies summed | Result |
|---|---|---|---|---|
| Today: 483 files, default `-j` (2 on 4 cores) | 13 m 31 s | 772 s | 804 s | 3411 passed |
| 4 bundles, `-j 2` | 2 m 53 s | 29 s | 295 s | 3411 passed |
| **4 bundles, `-j 4`** | **2 m 12 s** | — | — | **3411 passed** |
| 8 bundles, `-j 4` | 2 m 30 s | — | — | 3411 passed |
| `test/features/card` only: 41 files vs 1 bundle | 90 s → 51 s | — | — | 288 passed both |

**Root cause.** Wall clock (801 s) is roughly the sum of the per-file load times (772 s).
`flutter test` compiles each test file separately, through one frontend server, and starts a
fresh `flutter_tester` process for each file. That process reloads the fonts in
`flutter_test_config.dart` and runs on a cold JIT. So the suite pays about 1.4 s (median) per
**file**, however small the file is, and running the test bodies only overlaps the compiles.
Bundling many files into a few entrypoints pays that cost once per bundle. It also lets the
bodies run on a warm JIT, which is why their summed time fell from 804 s to 295 s.

Bundling exposed no state leaking between files. Every one of the 3411 tests passed in every
bundled configuration.

## 2. Owner rulings

- **R1.** Approach A: the gate generates bundled entrypoints at run time. Test files stay as
  they are, and each one still runs alone with `flutter test <file>`. Physical consolidation of
  test files (approach C) and flag tuning alone (approach B) are rejected: B leaves the serial
  compile in place, and C is a large diff that would grow back.
- **R2.** Phase 2 adds a report after each run (slowest tests, failing files and how to re-run
  them). It is report-only.
- **R3.** No `slow` tag. After bundling only 8 tests take more than 2 s, 28 s of CPU in total,
  so a tag would save under 10 s of wall clock. Revisit if the report shows the slow tail
  growing.

## 3. Design

### 3.1 `bundle_tests.py`

A new script, `.claude/skills/flutter-workflow/scripts/bundle_tests.py`, sits beside
`build_verification_plan.py`. It belongs to the gate machinery, not to `tools/`.

- **Input.** A list of test files, either as arguments or from a NUL-separated file, plus the
  bundle count.
  - The full mode passes every tracked or untracked-but-not-ignored `test/**/*_test.dart`.
  - `--changed` passes the plan's `test_files`. This is the expanded list, not the compressed
    `local_test_targets`.
  - `--fast` passes the files under `test/app` and `test/features/deck`.
- **Exclusion.** A file with the library-level annotation `@Tags(['golden'])` is left out. The
  gate never runs goldens on the host. A bundle could not run them anyway, because
  `matchesGoldenFile` resolves the PNG relative to the test file's own location.
- **Refusal.** A file with any other library-level annotation (`@Tags` with another tag,
  `@TestOn`, `@Timeout`, `@Skip`, `@OnPlatform`) makes the script exit non-zero and name the
  file. Those annotations are read from the file that `flutter test` is given, so a bundle
  would drop them silently. The fix is to move the annotation onto the `group` or `test`.
  No file has one today.
- **Async `main`.** `group` refuses an async body, so a file whose `main` is `async` is
  refused the same way, with the fix in the message: make `main` synchronous and move the
  awaits into `setUpAll`. No file has one today.
- **Partition.** The script sorts the files by repo-relative POSIX path and deals them out in
  turn: file *i* goes to bundle *i mod n*. The result is deterministic and measured balanced
  (60–87 s per bundle). Bundles that would be empty are not written, so *n* larger than the
  file count is fine.
- **Bundle count.** `MEMOX_TEST_BUNDLES=<n>` sets it. The default is `os.cpu_count()`, which
  measured best (§1.1). `MEMOX_TEST_BUNDLES=0` means do not bundle (§3.2).
- **Output.** The script deletes the old `.dart_tool/memox_test_bundles/*.dart` files, then
  writes `bundle_<k>_test.dart` there and prints their paths. `.dart_tool/` is ignored by git,
  by the analyzer and by the guard, and regenerating on every run means a bundle is never
  stale. Each bundle:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import '../../test/flutter_test_config.dart' as config;
  import '../../test/core/text/folded_text_test.dart' as t0;
  // …
  Future<void> main() => config.testExecutable(() {
    group('test/core/text/folded_text_test.dart', t0.main);
    // …
  });
  ```

  `flutter test` applies a `flutter_test_config.dart` only to files under that config's
  directory, and a bundle under `.dart_tool/` is not, so the bundle calls `testExecutable`
  itself. A probe on 2026-10-02 confirmed that fonts load and a visual audit passes this way.
  The group name is the original path, so every reported test still names its file.

### 3.2 `dod_check.sh`

The host test step in all three modes becomes:

```
bundle_tests.py <files> → TZ=UTC flutter test -j <n> --exclude-tags golden \
                          --file-reporter json:$WORK/test-report.jsonl <bundles>
```

- `-j` equals the bundle count.
- `MEMOX_TEST_BUNDLES=0` runs the same targets file by file, as before; the only addition
  is the JSON report that feeds §3.3. It is the rollback, and the way to check whether a
  failure only happens bundled.
- Nothing else moves: the pass stamp, the static steps, their parallel schedule, the labels,
  and the rule that goldens never run on the host. `ci.yml` calls `dod_check.sh`, so CI gets
  the change with no edit, and its golden job is untouched.
- The comment in the header that says 266 s is replaced with the new measurement.

### 3.3 `test_report.py` (phase 2)

A new script beside the others reads `test-report.jsonl` after the test step and prints the
following below the test step's output:

- the wall clock, the test count, and the time of each bundle;
- the ten slowest tests, each with its original file (taken from the group name);
- when tests failed: each failing test grouped under its original file, and a ready
  `TZ=UTC flutter test <file>` line for each file. If a file passes alone but fails bundled,
  that is a leak between files, and it is still a failure.

The report never changes the gate's verdict. The exit code of `flutter test` alone decides
pass or fail.

### 3.4 Conventions and documents

- `docs/shared/testing/README.md` and the `flutter-testing` skill each get one short paragraph.
  It says that the gate runs test files bundled in one process per bundle, so a test file must
  restore any global state it changes (statics, `debug*` overrides, `HttpOverrides.global`,
  `tester.view`) through `addTearDown`. It also gives the `MEMOX_TEST_BUNDLES=0` way to
  diagnose a failure.
- `CLAUDE.md` does not change: the gate is still the same command.

## 4. Verification

- **Unit tests** (`scripts/tests/`, which the gate already runs as "CI tooling unit tests"):
  - the bundled set equals the input set minus golden files: none lost, none doubled;
  - a non-golden library-level annotation is refused, with the file named;
  - the partition is the same on every run, whatever order the input comes in;
  - *n* larger than the file count writes no empty bundle;
  - Windows `\` separators in the input become POSIX imports;
  - an empty input writes nothing and says so;
  - `test_report.py` reads a recorded JSON fixture and prints the slowest tests and, for a
    failure, its original file.
- **End to end.** One full gate run before and one after. The non-golden test count must match
  (3411 at the time of this spec), every test must pass, and both wall clocks are recorded in
  the PR. A third run uses `--changed` with a small diff and a fourth uses
  `MEMOX_TEST_BUNDLES=0`, to show the fallback.
- **Gate.** `dod_check.sh` must pass in full.

## 5. Risks and rollback

| Risk | Mitigation |
|---|---|
| A file leaks global state into the next one in its bundle | The probe found none in 3411 tests. `flutter_test` already fails a `testWidgets` that leaves a `debug*` variable set. `test_report.py` prints the standalone re-run, and `MEMOX_TEST_BUNDLES=0` gives the old isolation back. |
| A library-level annotation is dropped silently | `bundle_tests.py` refuses it (§3.1). |
| One file fails to compile: its bundle, and possibly the next bundle the frontend server compiles, report nothing | The compile error names the file, and `test_report.py` names each bundle that failed to load. The per-file fallback isolates the file. `flutter analyze`, which runs in the same gate, catches the same error. |
| A machine with a different core count | `os.cpu_count()` adapts, and `MEMOX_TEST_BUNDLES` overrides. |

**Rollback.** Set `MEMOX_TEST_BUNDLES=0`, or revert the one commit that touches
`dod_check.sh`. The two new scripts are inert without it.

## 6. Out of scope

- Bundling the golden suite: it cannot be bundled (§3.1).
- A `slow` tag (R3).
- Rewriting, merging or deleting test files, and coverage decisions. The scenario catalog and
  the testing pyramid audit stay as they are.
- A fail-on-budget rule for test time. Report-only for now (R2); a budget can follow if the
  report shows drift.
