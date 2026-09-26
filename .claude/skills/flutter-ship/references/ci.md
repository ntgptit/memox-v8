# CI pipeline and release builds

## GitHub Actions

The live pipeline is `.github/workflows/ci.yml`. When this page and the file
disagree, the file wins, and this page is corrected in the same change.
`WorkflowContractTest`, in
`.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`, pins what
the file must keep doing, and it runs inside the gate.

It runs by hand (`workflow_dispatch`) on `ubuntu-latest`, as three jobs. The
`pull_request` trigger is paused during active development; the file's `on:`
block says how to resume it.

| Job | What it runs | Limit |
|---|---|---|
| `gate` | Python 3.13 with the guard's `requirements-dev.txt`; Flutter from `.fvmrc`; `flutter pub get`, `flutter gen-l10n` and `build_runner`; `check_generated.py` without `--skip-rebuild`, the from-scratch rebuild the local gate leaves to CI; then `dod_check.sh` in full | 30 min |
| `goldens` | Flutter from `.fvmrc`; the generated code; `prepare_test_fonts.sh`; `TZ=UTC flutter test --tags golden --file-reporter json:golden-report.jsonl`; `count_golden_tests.py golden-report.jsonl 60`; on failure, the `test/**/failures/**` images as the `golden-failures` artifact | 20 min |
| `CI gate` | `if: always()` and `needs` every other job; prints each job's result, and is green only when every one succeeded | 5 min |

Choices that are easy to get wrong:

- **One definition of the gate.** CI runs the `dod_check.sh` a contributor
  runs, in full: never `--fast` or `--changed`, and no selection by the
  planner. `build_verification_plan.py` still serves `dod_check.sh --changed`
  on a workstation; its CI-only outputs (shards, `--github-output`) are BE-D5
  in `docs/wbs_BE.md`.
- **`CI gate` is the one required check.** It needs every other job and runs
  whatever happened to them, so a job that failed, was cancelled or was
  skipped fails it instead of passing unnoticed. A new job goes into its
  `needs`, and the contract test fails until it does. The owner's ruleset steps
  are in the root `README.md`.
- **No path filter, and no run on a push to `master`.** A path filter leaves a
  required check waiting forever on a pull request that touches none of its
  paths. A pull request has already verified its head, and "Require branches to
  be up to date before merging" makes that head the merged tree.
- **Goldens are Linux renders.** The `goldens` job compares them on
  `ubuntu-latest` against the pictures `golden.Dockerfile` writes; there is no
  Windows golden job and no `ci-full.yml`. The workflow never updates a
  picture: one that changes on purpose is regenerated in the container and
  committed. When a golden fails, the job's log names it and the
  `golden-failures` artifact holds the diff.
- **The count is a tripwire.** `flutter test --tags golden` fails a run of no
  test, but it passes a partial collapse, such as a golden file that lost its
  tag. The floor (60, against 87 goldens today) catches that; raise it
  deliberately.
- **One guard profile.** The guard's `local` and `ci` profiles are identical
  (`code-verification-guard-v2/registries/projects/memox-v8/config/profiles.yaml`),
  and the profile never comes from the environment: a warning fails CI exactly
  as it fails a local run.
- **Pin the Flutter version** through `.fvmrc` (`flutter-version-file`) in
  every job that installs Flutter. `channel: stable` alone lets the pipeline
  change under you.
- **Cache** the SDK and `~/.pub-cache` with `subosito/flutter-action`'s
  `cache: true`; nothing else is cached.

Release builds are not part of this pipeline: `.github/workflows/build-apk.yml`
builds one universal release APK by hand and publishes it as a pre-release.

## Release builds

```bash
# Android App Bundle for the store
flutter build appbundle \
  --release \
  --flavor production \
  -t lib/main_production.dart \
  --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols/android

# iOS archive
flutter build ipa \
  --release \
  --flavor production \
  -t lib/main_production.dart \
  --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols/ios
```

**Keep `build/symbols/`.** Obfuscated crash reports are unreadable without the
matching symbol files, and they must match that exact build — archive them
alongside the artifact, per version.

## Signing

Android: keystore from CI secrets, decoded at build time into a path referenced
by `key.properties`. Never commit the keystore or `key.properties`.

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
```

iOS: certificate and provisioning profile from secrets into a temporary keychain
— `apple-actions/import-codesign-certs` handles the fiddly parts.

Losing the Android upload key means you cannot update the listing without Play's
key-reset process. Back it up somewhere durable and outside the repo.

## Versioning

`version: 1.4.2+87` in `pubspec.yaml` — name plus build number. The build number
must increase on every store upload; both stores reject a repeat. Deriving it
from the CI run number removes the manual step and the duplicate-rejection
round-trip.

## Deployment

`fastlane`, or the store CLIs, from a tag-triggered workflow. Always to internal
testing first, then staged rollout: 10% → 50% → 100%, watching crash-free
percentage between steps. A staged rollout is the rollback plan — a bad release
caught at 10% affects a tenth of the users.
