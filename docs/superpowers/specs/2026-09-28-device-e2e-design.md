# Device scenarios (FE-D3) — design

Path: architectural · Owner rulings 2026-09-28 (§3): D1–D4

## 1. Goal

Run the eight `DEVICE-E2E` scenarios of
[host-coverage-map.md](../../shared/testing/host-coverage-map.md) on an Android
emulator or phone, by hand, with one command:

| ID | What only a device proves |
|---|---|
| IT-PLAT-001 | Cold start of the installed build: engine bootstrap, the platform database path, the asset bundle |
| IT-PLAT-002 | Content survives a real process restart |
| IT-PLAT-003 | A session killed by the OS resumes where it stopped |
| IT-PLAT-004 | An OS deep link opens the right screen; a bad one recovers |
| IT-PLAT-005 | The system Back button asks before leaving a session |
| IT-PLAT-006 | A release build installs, starts and shows its first screen |
| IT-CONT-008 | A whole study session runs in airplane mode and survives a restart |
| IT-NAV-007 | Content management runs in airplane mode and survives a restart |

Success: `tools/device/run_device_e2e.sh all` prints PASS for each ID on the
API 36 emulator, and the result is recorded in
`docs/shared/testing/device-e2e.md`.

## 2. Scope

- In: the `integration_test` harness, the adb runner script, the eight
  scenarios, an Android deep link (`memox://`), and a not-found screen for an
  unknown route (IT-NAV-005's host test comes with it).
- Out: CI (the device run is manual; CI is paused anyway), iOS, Firebase Test
  Lab, app links over https, a release signing config.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | `integration_test` (Flutter SDK) for the in-app steps, and `tools/device/run_device_e2e.sh` for what only the OS can do: clear data, kill, airplane mode, system Back, deep links, installing a release build | Owner 2026-09-28. No third-party package; runs by hand, not in CI |
| D2 | Each restart splits a scenario into phases, one test file per phase. The script runs each with `flutter test <file> -d <device> --no-uninstall`. That keeps the app and its data, and the tool ends every run with `am force-stop`, the same process death the OS gives | `flutter test` uninstalls by default. `install -r` of the next phase's APK keeps the data |
| D3 | A phase passes values to a later one through its output: `MEMOX-E2E: value KEY=VALUE`. The script passes them on as `--dart-define=MEMOX_E2E_KEY=VALUE`. `MEMOX-E2E: back` asks the script for a real `KEYCODE_BACK` while the test waits | The app has no file the test could share (no `path_provider` dependency), and a real system Back comes only from the OS |
| D4 | Deep link: custom scheme `memox://app/<route>`. The intent filter is VIEW, DEFAULT and BROWSABLE, and `<route>` is any path of the in-app route table (`AppRoutes`) | Owner 2026-09-28. Flutter hands `/<route>` to go_router. No route writes on open: editors save only on Save, and a missing id shows the screen's own gone state (UC-CARD-002 E1, deck gone). App links need a domain; out of scope. Route review (plan Task 2): every `GoRoute` builder only reads on open. The Trash runs its expired purge (BR-TRASH-009), which every app start and resume already runs; search focuses its field and runs `q`, a read |
| D5 | An unknown route shows a not-found screen: `MxEmptyState` with "Page not found", one line, and "Back to Library". It replaces go_router's default page, which prints the exception | IT-NAV-005: no stack trace or internal id, a way back. The kit has no such screen. The shared empty state keeps it in the system; it is recorded in the UI-base register §9 |
| D6 | IT-PLAT-006 runs on a release APK without `integration_test`. The script builds it, installs it on a cleared device, starts it from the launcher intent and checks two things: the first screen (the Library's empty state) through `uiautomator`, and no `FATAL EXCEPTION` or `E/flutter` in logcat | Owner 2026-09-28. `flutter test` runs integration tests only in debug. Create, study and reopen are proven in debug by IT-PLAT-002 and IT-PLAT-003 |
| D7 | Tests find text through the app's own `AppLocalizations`, read from the running widget tree, never from a literal | Any device language works. The script sets the app locale to `en-US` only for its own `uiautomator` checks (D4, D6) |
| D8 | IT-CONT-008 and IT-NAV-007 turn airplane mode on with `cmd connectivity airplane-mode enable`, and the script's `trap` turns it off again on any exit | The device must not stay offline after a failed run |
| D9 | Fixtures are built through the UI, as the scenario catalog writes them (`SETUP-STUDY-EB-5-FULL`: Korean › Chapter 1, ST-01…ST-05), by shared helpers in `integration_test/support/` | A device test has no database handle. The UI is the thing under test |

## 4. Architecture

```
integration_test/
  support/
    device_app.dart       # binding, launch main(), waitFor, l10nOf, signal
    content_steps.dart    # create root/sub deck, card, edit, flag, delete, open path
    study_steps.dart      # SETUP-STUDY-EB-5-FULL, one correct turn per mode
  it_plat_001_cold_start_test.dart
  it_plat_002_a_build_tree_test.dart   it_plat_002_b_after_restart_test.dart
  it_plat_003_a_start_session_test.dart it_plat_003_b_resume_test.dart
  it_plat_004_a_seed_deck_test.dart
  it_plat_005_system_back_test.dart
  it_cont_008_a_offline_session_test.dart it_cont_008_b_after_restart_test.dart
  it_nav_007_a_offline_content_test.dart  it_nav_007_b_after_restart_test.dart
tools/device/run_device_e2e.sh
lib/app/router/route_not_found_screen.dart   # D5
android/app/src/main/AndroidManifest.xml     # D4 intent filter
```

The runner does four things:

1. It picks the device, from `-d` or the only one attached.
2. It runs the scenarios in order.
3. For each phase, it streams the `flutter test` output and reacts to the
   `MEMOX-E2E:` lines (D3).
4. It prints `PASS <ID>` or `FAIL <ID> (<step>)`, then a summary, and exits
   non-zero if any scenario failed.

Its messages are in English (CLAUDE.md, Language).

## 5. Scenario mapping

- **IT-PLAT-001:**
  1. The script clears the data.
  2. The phase launches `main()`.
  3. The phase asserts the Library tab is selected and shows `libraryEmptyTitle` with `libraryCreateDeck`.
- **IT-PLAT-002, phase a:**
  1. D-EB (Eight Box) › D-BRANCH › D-LEAF.
  2. C-001 in D-LEAF.
  3. Change the meaning to "rời bỏ" and see it in the list.
  4. Back to the root.
- **IT-PLAT-002, phase b:** D-EB is in the root, and D-LEAF holds C-001 with "rời bỏ".
- **IT-PLAT-003, phase a:**
  1. `SETUP-STUDY-EB-5-FULL`.
  2. Learn, and answer two turns.
  3. Signal the mode, the prompt and the progress as values.
- **IT-PLAT-003, phase b:**
  1. Study tab, open Korean's entry.
  2. The resume sheet offers Continue, Learn and Review.
  3. After Continue, the mode, the prompt and the progress equal phase a's values.
- **IT-PLAT-004:**
  1. Phase a creates D-EB and signals its id.
  2. The script force-stops the app and opens `memox://app/decks/deck/<id>`, expecting D-EB's page. Back then expects the Library root.
  3. `memox://app/decks/deck/missing` expects `deckGoneTitle`.
  4. `memox://app/nowhere` expects the not-found title.
- **IT-PLAT-005:** one phase.
  1. `SETUP-STUDY-EB-5-FULL`, Learn, one turn.
  2. `signal back` expects `studyExitTitle`; Keep leaves the prompt and the progress unchanged.
  3. `signal back` again, then Stop, expects `summaryLeftEarly`.
  4. The entry has no Continue.
- **IT-CONT-008, with airplane mode on:**
  - **phase a:** `SETUP-STUDY-EB-5-FULL`, then Learn through all 25 turns to the summary.
  - **phase b:** the entry shows no Continue and 0 new. A Review or Learn session starts without any network prompt.
- **IT-NAV-007, with airplane mode on:**
  - **phase a:** D-EB › D-LEAF. A new sub-deck in D-EB. A card created, edited and flagged in D-LEAF.
  - **phase b:** everything is still there. Delete the card, and it goes to the Trash.
- **IT-PLAT-006:** script only (D6).

## 6. Error handling

- A phase that fails stops its scenario. The script records the failure and
  moves on to the next scenario.
- `waitFor` fails with the finder it waited for, after 30 s (a debug cold
  start takes about 15 s).
- The script checks that `adb` and `flutter` exist and that one device is
  attached, before it changes anything.

## 7. Testing

- The not-found screen (D5) gets a host widget test that carries IT-NAV-005,
  and the router test covers the `errorBuilder`.
- The harness is proven by running it. `bash -n` checks the script's syntax
  in the gate's lane.
- A run on the API 36 emulator is the evidence, recorded in
  `docs/shared/testing/device-e2e.md` with the date, device and result per ID.

## 8. Docs

- `docs/shared/testing/device-e2e.md` (new, Vietnamese): how to run, what each
  phase does, the last run.
- The eight scenario rows point to it.
- `docs/features/progress/it-scenarios.md`: the note that the intent filter is
  missing gives way to D4.
- `flutter-project-setup/references/dependencies.md`: a Dev row for
  `integration_test`.
- `flutter-testing/SKILL.md`, "Integration tests": where device scenarios live
  and how they run.
- `wbs_FE.md`: FE-D3 → xong, and the "không có emulator" blocker closes.
- UI-base register §9: the not-found screen (D5).
