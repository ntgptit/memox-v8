# Migration verification

What was run on the final tree of branch `claude/ecstatic-lovelace-s80gci`,
what it showed, and what could not be verified here. Environment: the Linux
container, Flutter 3.47.5, Dart 3.13.4, forui 0.27.6, Android only (iOS is
out of scope).

## The gate

`bash .claude/skills/flutter-workflow/scripts/dod_check.sh` on the final tree:
every step passed.

| Step | Result |
|---|---|
| dart format | pass |
| flutter analyze | pass |
| generated code | pass |
| architecture boundaries | pass |
| document integrity | pass |
| Flutter SDK matches `.fvmrc` | pass |
| CI tooling unit tests | pass |
| hook tests | pass |
| theme structure and palette, removed names gone (`tools/design/check.py`) | pass |
| design tooling tests | pass |
| ForUI boundary rules (`tools/ui_lint`) | pass |
| guard self-tests (probes) | pass |
| code verification guard (`memox-v8` ruleset) | pass |
| host tests (full suite, no goldens, `TZ=UTC`) | pass: 4673 tests |

The baseline at `a4f56ce2` (before the migration) passed with 4745 tests. The
difference comes from the tests of the Material 3 component themes and their
helpers, which were deleted with the code they tested (`LEGACY_REMOVAL.md`):
`m3_overlay_barrier_test`, `m3_production_theme_test`,
`app_component_themes_test`, `app_surface_themes_test`,
`app_theme_ambient_test`, `focus_ring_border_test`,
`input_decoration_theme_test`, `theme_slot_fixes_test`, `token_values_test`,
plus four support files. Their contracts that still apply are asserted against
ForUI in the new tests (`test/app/production_theme_test.dart`,
`test/app/app_theme_host_test.dart`, the `Mx*` widget tests). Fourteen test
files were added.

## Goldens

- `run_goldens.sh --update` rewrote the goldens on the final tree. Before that
  run, the golden tests, which sit outside the gate's suite, were moved onto the
  ForUI finders the widget tests use (`byControlLabel`, `EditableText`). One
  golden test was fixed for ForUI's press timer.
- `run_goldens.sh`, with no flag, on the final tree: 615 tests passed.
- Compared with `a4f56ce2`: 328 goldens changed (656 PNG files, light and
  dark), none added or deleted.
- The before, after and diff review is on four private pages, built with the
  `golden-compare` skill. The owner reviews them before any merge.

## Gallery

The debug gallery (`lib/app/gallery/`) renders every `Mx*` widget. It is
covered by `test/app/gallery_test.dart` in the gate's suite, which passed, and
by the "Gallery, light" and "Gallery, dark" goldens, which passed. No APK was
built: the owner dropped that requirement. The Android build was in any case
blocked by the network policy (`dl.google.com` answers 403).

## Accessibility and contracts

- Targets of 48dp, labelled targets and contrast are checked in widget tests:
  the Android tap-target and labelled-tap-target guidelines on every tab
  (`production_theme_test.dart`) and per screen (`test/visual_audit/`), and
  `token_contrast_test.dart` (4.5:1 for text, 3:1 for non-text, with no
  exception list).
- Keyboard focus on the choice surfaces, which are new on this branch: ForUI's
  outline was checked whole and unclipped on screens 17, 18 and 37
  (`study_choice_focus_ring_test.dart`, `topik_attempt_focus_ring_test.dart`).
- Light, Dark and System switch without rebuilding the router
  (`production_theme_test.dart`: "switching the theme keeps the route and its
  stack"), and dialogs, sheets and toasts inherit the theme.

## Not verified here

| Item | Why |
|---|---|
| A run on a device or an emulator, and with TalkBack | No device or emulator in this environment. Every semantics claim comes from a widget test, never a run. |
| An Android build | Blocked by the network policy (`dl.google.com`); the owner dropped the requirement. |
| iOS | Out of scope. |
| `run_auth_it.sh` (auth on a real Supabase stack) | The branch changes no file under `lib/core/auth/` or `supabase/migrations/`. Only presentation files changed under `lib/features/account/`, and their widget tests passed. |
| Linear | The workspace refused new issues (free plan limit), so progress is not recorded there. |

## Known flake

`test/features/deck/presentation/library_root_state_test.dart` failed once in
an early bundled run. The file is unchanged from the baseline, and it passes on
its own and in the same bundle. It passed in every later full run.
