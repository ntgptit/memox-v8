# Build APK to GitHub Release — Design

Status: draft for review · Date: 2026-09-23 · Path: architectural (no `.github/` exists yet)

## 1. Intent

The project owner wants an installable APK that can be downloaded from the
repository's **Releases** page, including from the GitHub mobile app, and
wants CI-built APKs older than 7 days removed automatically.

Success: pressing **Run workflow** on `build-apk` produces a pre-release
holding one universal APK within one run, and every CI-built release older than
7 days is gone after that run.

Reference only: memox-v7 `.github/workflows/build-apk.yml` (manual, draft
release, no cleanup). V8 diverges where the owner decided differently (§2).

## 2. Decisions (project owner, 2026-09-23)

| Topic | Decision |
|---|---|
| Trigger | Manual only: `workflow_dispatch`, no inputs |
| Release kind | Published **pre-release** (visible and downloadable; never labelled "Latest") |
| Cleanup | Delete the whole release **and its tag** when it is a CI-built release older than 7 days |
| APK shape | One universal release APK (no `--split-per-abi`) |

## 3. Scope

- One new file: `.github/workflows/build-apk.yml`.
- No app code, signing config, flavor, or other workflow changes.
- The APK is **debug-signed**: `android/app/build.gradle.kts` still signs the
  `release` build type with `signingConfigs.getByName("debug")`. A real
  keystore is a separate decision.

## 4. Workflow

**Job-wide settings.** `permissions: contents: write` (creating and deleting
releases). `concurrency: build-apk` with `cancel-in-progress: false`, so two
presses queue rather than kill a run that may be mid-publish.

**Steps, in order:**

1. `actions/checkout`.
2. `actions/setup-java`, Temurin 17 — `android/app/build.gradle.kts` targets
   `JavaVersion.VERSION_17` / `JvmTarget.JVM_17`.
3. `subosito/flutter-action` with `flutter-version-file: .fvmrc` (the version
   lives in one place).
4. `flutter pub get`.
5. `dart run build_runner build --delete-conflicting-outputs` — generated code
   is not committed (`.gitignore: *.g.dart`); from foundation Task 5 on, a
   build without it cannot compile.
6. `flutter build apk --release`, then rename
   `build/app/outputs/flutter-apk/app-release.apk` to
   `memox-<run_number>-<sha8>.apk`.
7. **Publish.** `gh release create build-<run_number>-<sha8> <apk>
   --prerelease --target <sha> --title … --notes-file notes.md`. Notes state
   the commit, the APK size, and the debug-key consequences: allow "Install
   from unknown sources"; it cannot be upgraded over by a production-signed
   build.
8. **Cleanup** — runs only after step 7 succeeds, so a failed build never
   deletes the previous APKs. Select releases whose tag starts with `build-`
   and whose `createdAt` is more than 7 days (604 800 s) before now; for each,
   `gh release delete <tag> --cleanup-tag --yes`. Releases whose tag lacks the
   `build-` prefix are never touched. The deleted tags are written to the job
   summary.

The selection logic of step 8 lives in a shell function reading `gh release
list --json tagName,createdAt` output, so it can be exercised on fixture JSON
without GitHub.

## 5. Errors and limits

- Any failing step fails the run; cleanup does not run after a failed publish.
- Cleanup happens only when a build runs. With no build for more than 7 days,
  old releases stay until the next build. A daily `schedule` trigger would
  remove that limit and is out of scope unless the owner asks for it.
- Deleting a release and its tag is irreversible; the `build-` prefix filter
  is the only thing protecting manual releases.
- `gh release list` returns 30 releases by default; the call passes
  `--limit 1000` so older CI releases are not missed.

## 6. Verification

- `actionlint` on the workflow (syntax, expressions, shellcheck of `run:`).
- The cleanup selection run locally on fixture JSON: a `build-` release 8 days
  old (selected), a `build-` release 6 days old (kept), a manual `v1.0.0`
  release 30 days old (kept).
- The container has no Android SDK, so the APK build itself is verified by
  triggering the workflow on GitHub after merge and checking the run, the new
  pre-release, and its APK asset.
