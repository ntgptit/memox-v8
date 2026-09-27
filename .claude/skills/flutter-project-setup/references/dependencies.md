# Dependencies

Add with `flutter pub add <pkg>` / `flutter pub add --dev <pkg>` so version
constraints are written correctly, then commit `pubspec.lock`.

Do not hardcode versions from memory — check pub.dev for the current release
that matches the Flutter version in use. Versions below are the major line this
project targets, not exact pins.

## Runtime

**Not yet for MemoX V8:** `dio`, `retrofit` and `json_annotation` are
deliberately absent until the first feature calls the API (ADR-012). An unused
HTTP client still costs build time, still needs upgrading, and still suggests a
network layer exists.

The table is `pubspec.yaml` as it stands; a package added there gets a row here
in the same commit.

| Package | Line | Why it is here |
|---|---|---|
| `flutter_riverpod` | 3.x | State + DI. Compile-safe, testable without a widget tree. |
| `riverpod_annotation` | 4.x | Annotations for the generator. |
| `go_router` | 18.x | Declarative routing, deep links, redirect guards. |
| `drift` | 2.x | Typed SQLite with migrations and reactive queries. |
| `drift_flutter` | 0.3.x | Opens the database: a background isolate on native, the WASM worker on web (`lib/core/database/connection.dart`). |
| `sqlite3` | 3.x | The native SQLite library, supplied through native assets, and the `SqliteException` codes `mapDatabaseError` reads. |
| `flutter_localizations` | SDK | Material strings for the supported locales; `flutter: generate: true` builds the ARB files. |
| `intl` | — | Locale-aware dates and numbers. |
| `uuid` | 4.x | Client-generated IDs (ADR-007). Needed **from day one**: a row created offline keeps its ID through sync (ADR-013), and changing the primary-key strategy later means rewriting every foreign key. |
| `characters` | — | Counts user text in graphemes, so a length limit counts what the user sees. |
| `csv` | 8.x | Reads and writes CSV/TSV for import and export (`transfer`). |
| `excel` | 4.x | Reads `.xlsx` sources for import (`transfer`). |
| `file_picker` | 13.x | Picks the file to import. |
| `share_plus` | 13.x | Hands an export to the platform share sheet. |
| ~~`sqlite3_flutter_libs`~~ | — | **Do not add it.** The only version compatible with current Drift is `0.6.0+eol` — a tombstone with no native code in it. `sqlite3` 3.x supplies the native library through native assets instead, so Drift on mobile needs no separate package. The row is struck rather than deleted because a session that has seen the old advice will look for it here. |

Add only when the need is real:

| Package | Add when |
|---|---|
| `dio`, `retrofit`, `json_annotation` | The first API call (ADR-012): one shared `Dio` in `core/network/`, a Retrofit interface per endpoint group, `json_serializable` DTOs in `data/models/`. |
| `flutter_secure_storage` | Tokens exist, which needs login (ADR-013: login comes later). Keychain / EncryptedSharedPreferences, never SharedPreferences. |
| `connectivity_plus` | You show an offline state or trigger sync on reconnect. Note it reports link state, not reachability — a captive portal reads as online. |
| `cached_network_image` | You render remote images in lists. |
| `sentry_flutter` / `firebase_crashlytics` | Entering release (`flutter-ship`). Not before. |

## Dev

| Package | Why |
|---|---|
| `build_runner` | Runs all generators. |
| `riverpod_generator` | `@riverpod` → providers. |
| `drift_dev` | Drift table and DAO codegen, and the schema dumps in `drift_schemas/`. |
| `fake_async` | Drives timers and the day clock in tests. |
| `flutter_lints` | Baseline rule set that `analysis_options.yaml` extends. |
| ~~`riverpod_lint`~~ | **Descoped** — it needs `custom_lint` as its host. Its checks moved to code-verification-guard. |
| ~~`custom_lint`~~ | **Descoped.** No published version supports `analyzer >=10`, which `drift_dev` and the Riverpod generator require. Its job is now code-verification-guard's (the `memox-v8` ruleset). |

Not here, on purpose: `freezed` (value classes are written by hand, and DTOs
are `json_serializable`, never Freezed — ADR-012), `retrofit_generator` and
`json_serializable` until the first API call (ADR-012), `mocktail` (tests fake
the domain contracts instead), and a golden package (goldens run through
`test/support/golden_harness.dart`).

## Code generation

```bash
dart run build_runner build --delete-conflicting-outputs   # one-shot
dart run build_runner watch --delete-conflicting-outputs   # while developing
```

`--delete-conflicting-outputs` is nearly always what you want; without it a
renamed file leaves a stale generated file that then fails the build in a way
that points at the wrong place.

Generated output is not committed (`.gitignore`: `*.g.dart`), so CI runs codegen
before analyze, and `check_generated.py` proves that a clean rebuild reproduces
it.

## Traps worth knowing before you hit them

- **Riverpod 3 dropped the generated per-provider `Ref` subclasses.** Write
  `Ref ref`, not `MyThingRef ref`. Examples written for 2.x will not compile.
- **`riverpod_lint` and `custom_lint` are descoped** — do not try to add them.
  Every published `custom_lint` caps at `analyzer ^8`, while the generator stack
  needs `analyzer >=10`; installing them would force the analyzer, and the
  generators built on it, below the versions this project uses. Their checks
  are owned by **code-verification-guard** (the `memox-v8` ruleset).
  Do **not** put `analyzer: plugins: - custom_lint` in `analysis_options.yaml`:
  a plugin declared but not installed is silently ignored, so the rules look
  configured and never run.
- **Drift does NOT need `sqlite3_flutter_libs`** any more, and adding it is the
  mistake this line used to cause. That package is now `0.6.0+eol` — a tombstone
  that ships no native code — and `sqlite3` 3.x supplies the native library
  through native assets. On mobile Drift works with `sqlite3` alone. If a
  runtime failure to open the database sends you looking for a missing native
  lib, check the `sqlite3` version rather than reaching for the dead package.

## Auditing what is already there

```bash
flutter pub outdated
flutter pub deps --style=compact
```

For each direct dependency ask: is it still used, is it still maintained, is
there a second package doing the same job, and is the licence acceptable? Drop
what fails. An unused dependency still costs build time and still breaks on
upgrade.
