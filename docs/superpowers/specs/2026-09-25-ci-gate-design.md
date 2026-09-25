# MemoX V8 — CI gate design (package 6)

Status: design approved in three sections on 2026-09-25 · written spec awaiting review ·
Path: architectural

## 1. Intent

Build BE-D2 of [`docs/wbs_BE.md`](../../wbs_BE.md): a GitHub Actions workflow that runs
the verification gate on Linux for every pull request, together with the golden job
that FE-D1 of [`docs/wbs_FE.md`](../../wbs_FE.md) waits for. One stable check, `CI gate`,
must be green before a pull request is merged.

Success means:

- every pull request runs, on `ubuntu-latest`, exactly the local gate
  (`dod_check.sh`, full), a from-scratch check that generated code reproduces, and the
  golden comparison;
- `CI gate` is green only when every other job of the workflow succeeded, and it is the
  one check a repository ruleset requires;
- the workflow's contract is pinned by the CI tooling tests, which run inside the gate:
  a job that `CI gate` does not cover, a golden run that is not counted, or an
  `--update-goldens` in the workflow fails a test;
- this package's own pull request shows the gate going red on a broken host test and a
  broken golden, then green again;
- the documents describe V8's pipeline, not V7's.

## 2. Context (2026-09-25)

- `master` is at `fe5f32a`: package 5 (#62) merged.
- **The gate** is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` since #61
  (FE-D2; root `README.md`, "Commands"). A full run covers these steps, in parallel:
  - format, `flutter analyze --no-fatal-infos`, and generated code with
    `--skip-rebuild`;
  - the architecture boundaries, the docs check, and the Flutter version against
    `.fvmrc`;
  - the CI tooling unit tests, and the prompt contract when prompts change;
  - the guard's self-tests (pytest) and the guard with the `memox-v8` ruleset;
  - the host tests with `TZ=UTC` and `--exclude-tags golden`.

  A comment in the script says the rebuild half of the generated-code check "belongs in
  CI".
- **Goldens** are Linux renders:
  - They are written in `.claude/skills/flutter-testing/scripts/golden.Dockerfile`:
    Ubuntu 24.04, the official Flutter tarball, and lowercase links to the material
    fonts.
  - `dart_test.yaml` declares the `golden` tag, and 87 tests carry it.
  - They pass in this repository's Linux cloud container: `TZ=UTC flutter test --tags
    golden` gives `+87: All tests passed!` (2026-09-25).
  - The Dockerfile's header already describes the CI job it mirrors: `ubuntu-latest`
    with `subosito/flutter-action` reading `.fvmrc`.
- **Workflows.**
  - The only workflow is `build-apk.yml`, run by hand. It uses `actions/checkout@v7`,
    `actions/setup-java@v6`, and `subosito/flutter-action@v2` with
    `flutter-version-file: .fvmrc` and `cache: true`.
  - The repository is public, so standard runners cost no minutes.
- **Inherited V7 CI tooling** in `.claude/skills/flutter-workflow/scripts/`:
  - `build_verification_plan.py` serves `dod_check.sh --changed`. It also carries
    CI-only output: shards, `--github-output`, and Widgetbook and memox-api flags.
  - `select_test_shard.py` and `check_ci_gate.py` are used only by their own tests.
    They have V7's shape: host shards, and Maven, memox-api and Widgetbook jobs.
  - `count_golden_tests.py` and `prepare_test_fonts.sh` are used nowhere and have no
    test.
- **`test_ci_tooling.py`.**
  - Three tests skip until `.github/workflows/ci.yml` exists, and they assert V7's
    pipeline: a `classify` job, a shard matrix, Widgetbook, and the `check_ci_gate.py`
    wiring.
  - Eight other tests skip without PowerShell 7 (`OK (skipped=11)`).
- **The guard's profiles.**
  - `registries/projects/memox-v8/config/profiles.yaml` makes `local` and `ci`
    identical, and says why.
  - The profile comes from the manifest or an override, never from the environment.
  - The `flutter-ship` skill's note that the guard switches to a stricter profile on CI
    describes V7.
- **Stale documents.** `flutter-ship/references/ci.md` and `SKILL.md` §19 describe V7's
  pipeline:
  - the `ci.yml`/`ci-full.yml` pair;
  - Windows goldens;
  - the `memox-v7` ruleset.
- **The plans that waited on this.**
  - The UI base spec §10 put "a Linux CI test workflow" out of its scope.
  - FE-D1's next step is "Thêm job golden vào CI khi có BE-D2".

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | `.github/workflows/ci.yml`; the CI tooling it needs; removal of the V7 CI tooling that nothing in V8 uses; the documents. Not in scope: the planner's CI-only surface (D11), release builds, deployment | Owner, 2026-09-25 |
| D2 | Approach | CI runs the local gate, `dod_check.sh` in full: one definition of the gate. Not a planner-driven sharded pipeline, and not `--changed`, whose selection would become the merge gate | Owner, 2026-09-25 (approach A of three) |
| D3 | Merge policy | CI green is required before a pull request is merged. The executor waits for `CI gate` before squash-merging. The owner may make `CI gate` a required check in a ruleset and require branches to be up to date (§8) | Owner, 2026-09-25 |
| D4 | Triggers | `pull_request` (opened, synchronize, reopened) and `workflow_dispatch`. No path filter, which would leave a required check pending forever. No `push` to `master`: a pull request verified its head, and "up to date" (§8) makes that head the merged tree. One concurrency group per pull request, cancelling the run in progress. `permissions: contents: read` | Owner, 2026-09-25 (design section 1) |
| D5 | Job `gate` | `ubuntu-latest`, 30 minutes: checkout; `actions/setup-python` 3.13 with the guard's `requirements-dev.txt`; `subosito/flutter-action@v2` with `flutter-version-file: .fvmrc` and `cache: true`; `flutter pub get`; `flutter gen-l10n`; `dart run build_runner build --delete-conflicting-outputs`; `check_generated.py` without `--skip-rebuild`; `dod_check.sh` | Design section 1 |
| D6 | Job `goldens` | In parallel, 20 minutes, with the same setup and no Python dependencies. `prepare_test_fonts.sh`; `TZ=UTC flutter test --tags golden --reporter json` into a report; `count_golden_tests.py` on that report with a floor of 60 (87 today). On failure it uploads the `failures/` images. The workflow never contains `--update-goldens` | Design section 1 |
| D7 | Job `CI gate` | `if: always()`, `needs` every other job. Green only when all of them succeeded; otherwise red, naming each job's result. The one check to require | Design section 1 |
| D8 | V7 tooling | Delete `select_test_shard.py`, `check_ci_gate.py`, their tests (`FileShardSelectionTest`, `AggregateGateTest`) and `PlanOutputsAreWiredIntoTheWorkflowTest`. Keep `build_verification_plan.py`, `check_generated.py`, `check_prompt_contract.py`, `prepare_test_fonts.sh`, `count_golden_tests.py` | Design section 2 |
| D9 | Workflow contract | The test that waited for `ci.yml` is replaced by V8's contract (§5.2), read from the workflow as text, as the old tests did | Design section 2 |
| D10 | Golden count | `count_golden_tests.py` gets its first tests (§5.3) | Design section 2 |
| D11 | Follow-up | The planner's CI-only surface becomes BE-D5 in `wbs_BE.md`, its own item: a refactor of 780 lines with their tests | Design section 2 |
| D12 | Documents | See §6 | Design section 2 |
| D13 | Verification | See §7: local checks before the pull request; on GitHub, the package's pull request is the first run, and a probe commit shows the red path | Design section 3 |
| D14 | Branch and PR | Branch `claude/be-ci` from `master`. The pull request is squash-merged after a clean final review, once `CI gate` is green | Owner's standing choice; D3 |

## 4. The workflow

A sketch; the plan pins the file.

```yaml
name: CI
on:
  pull_request:
  workflow_dispatch:
concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
permissions:
  contents: read
jobs:
  gate:
    name: gate
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - checkout
      - setup-python 3.13; pip install -r code-verification-guard-v2/requirements-dev.txt
      - flutter-action (flutter-version-file: .fvmrc, cache: true)
      - flutter pub get; flutter gen-l10n
      - dart run build_runner build --delete-conflicting-outputs
      - python3 .claude/skills/flutter-workflow/scripts/check_generated.py
      - bash .claude/skills/flutter-workflow/scripts/dod_check.sh
  goldens:
    name: goldens
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - checkout; flutter-action (.fvmrc, cache); pub get; gen-l10n; build_runner
      - bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh
      - TZ=UTC flutter test --tags golden --reporter json > golden-report.jsonl
      - python3 .claude/skills/flutter-workflow/scripts/count_golden_tests.py golden-report.jsonl 60
      - on failure: upload test/**/failures/**
  ci-gate:
    name: CI gate
    if: always()
    needs: [gate, goldens]
    runs-on: ubuntu-latest
    steps:
      - fail unless needs.gate.result and needs.goldens.result are both "success"
```

`dod_check.sh` runs in a fresh checkout, so its pass stamp never applies. It finds the
guard's interpreter by importing `typer` and `pytest`, which step 2 installs. The golden
step writes the JSON report whether or not tests fail, and `count_golden_tests.py`
decides the job's result: a failed test, fewer than the floor, or no report fails it.

## 5. The CI tooling

### 5.1 What goes and what stays

| File | Fate | Why |
|---|---|---|
| `select_test_shard.py`, `FileShardSelectionTest` | deleted | V7's host shards; V8's CI does not shard (D2) |
| `check_ci_gate.py`, `AggregateGateTest` | deleted | V7's aggregate of classify, contract, static, shard, Widgetbook, golden and memox-api jobs; V8's `CI gate` is two conditions in YAML, pinned by §5.2 |
| `PlanOutputsAreWiredIntoTheWorkflowTest` | deleted | It checked the `classify` job's outputs, which V8 has none of; §5.2's third check guards the same failure in V8's shape |
| `WorkflowContractTest.test_ci_consumes_the_sealed_dynamic_plan` | replaced | By §5.2 |
| `build_verification_plan.py` | kept | `dod_check.sh --changed` uses it; its CI-only surface is BE-D5 (D11) |
| `count_golden_tests.py`, `prepare_test_fonts.sh` | kept, now used | The `goldens` job |

### 5.2 The workflow contract

The tests read `.github/workflows/ci.yml` as text, without PyYAML, as the tests they
replace did: the CI tooling tests run in `dod_check.sh`, which installs nothing.

1. The `gate` job runs `dod_check.sh` without `--fast` or `--changed`, and
   `check_generated.py` without `--skip-rebuild`.
2. The `goldens` job runs `flutter test --tags golden` and `count_golden_tests.py`, and
   the workflow never contains `--update-goldens`.
3. The `CI gate` job has `if: always()`, and its `needs` names every other job of the
   workflow. This is the failure V7's wiring test caught: a job that the required check
   does not cover can fail without blocking a merge.
4. The triggers are `pull_request` and `workflow_dispatch`, with no path filter.
5. Every job that installs Flutter reads `.fvmrc`.

### 5.3 The golden count

`count_golden_tests.py <report> <floor>` gets its first tests, from reports in the JSON
reporter's format:

- a report that meets the floor, with every test passing, passes;
- a failed test fails, whatever the count;
- a count under the floor fails;
- a report with no test fails.

## 6. Documents

- **Root `README.md`**, "Commands":
  - CI runs the same gate on every pull request, plus the goldens.
  - `CI gate` must be green before a merge.
  - The owner's ruleset steps (§8).
- **`.claude/skills/flutter-ship/references/ci.md`**: the V8 pipeline replaces the
  description of V7's:
  - the three jobs;
  - no `ci-full.yml`;
  - goldens on `ubuntu-latest`;
  - the guard's profiles being identical.
- **`.claude/skills/flutter-ship/SKILL.md` §19**: the gates in the order V8 runs them,
  and the `memox-v8` ruleset. It also drops the claim that CI switches the guard to a
  stricter profile.
- **`code-verification-guard-v2/AGENTS.md`**: its one line on the MemoX CI says pull
  requests, not "every push".
- **`docs/wbs_BE.md`**:
  - BE-D2 is done.
  - BE-D5 is added: trim the planner's CI-only surface.
  - The next step moves to BE-B1.
  - The update log records the change.
- **`docs/wbs_FE.md`**: FE-D1's next step, the golden job in CI, is done.
- `docs/_generated/` is regenerated if a document it reads changes.

## 7. Verification

**Before the pull request**, in a scratch copy, each task test first:

- the contract tests (§5.2) and the golden count tests (§5.3), each seen failing before
  the change that passes it;
- `ci.yml` parses as YAML (PyYAML, which the guard installs), and `actionlint` if it can
  be installed; otherwise the plan says it did not run;
- `CI=true bash .claude/skills/flutter-workflow/scripts/dod_check.sh`: the full gate
  with the environment variable every CI runner sets;
- the `goldens` job's commands, as the workflow writes them, with the floor.

**On GitHub**, the package's pull request is the first run of the workflow, since a
`pull_request` event runs the workflow of the pull request's own branch.

- The plan records how long each job takes.
- **The red path:** a probe commit on the package branch breaks one host test and one
  golden. The run must show `gate`, `goldens` and `CI gate` red, each naming its cause.
  A revert commit then brings them back to green.
- The squash merge folds the probe and its revert away, so no force-push and no extra
  branch are needed.

## 8. The owner's settings

The executor cannot change repository settings. To make D3 a rule on GitHub rather than
the executor's habit:

1. Go to Settings → Rules → Rulesets → New ruleset → New branch ruleset.
2. Set the target to the default branch (`master`) and the enforcement to Active.
3. Under "Require status checks to pass", add `CI gate`, and turn on "Require branches
   to be up to date before merging".

Until the owner does this, the executor keeps D3 by waiting for `CI gate` before every
merge.

## 9. Out of scope

- BE-D5: the planner's CI-only surface.
- Release builds, signing, the web build, and deployment. `build-apk.yml` stays as it
  is.
- A post-merge run on `master` (D4).
- Coverage reports, and caching beyond `subosito/flutter-action`'s.
- BE-D3's stale documents that this package does not touch.

## 10. Risks and rollback

- **The runner renders differently from the container.** The first run shows it: the
  `goldens` job goes red on unchanged pictures.
  - The uploaded diff says why.
  - The fix is to run that job in a container built from `golden.Dockerfile`, not to
    regenerate the goldens from the runner. The plan records which one held.
  - The local run in this repository's Linux container makes this unlikely.
- **Action versions.** The workflow uses the same majors as `build-apk.yml`
  (`checkout@v7`, `flutter-action@v2`), plus `setup-python` and `upload-artifact`. A
  version that does not exist fails the first run, before any merge.
- **Time.**
  - `gate` is bound by the host suite (about 3 minutes on 4 cores) plus setup.
  - `goldens` runs beside it.
  - The plan estimates 7–10 minutes per push; §7 measures it.
- **A flaky test** now blocks merges. It is fixed, never retried or skipped (the
  repository's drive-to-green rules).
- **Rollback:** delete `ci.yml` and the owner's ruleset, and the gate is local only
  again. The tooling deletions come back with a revert of their commit.
