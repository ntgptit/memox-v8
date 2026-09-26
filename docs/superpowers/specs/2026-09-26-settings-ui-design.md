# FE-A3: the Settings UI — design

Status: approved 2026-09-26 · Path: architectural · Owner rulings 2026-09-26 (§3), amended after the pre-plan critique (`.impeccable/critique/2026-09-26T17-00-00Z__settings-kit.md`): D7–D9

## 1. Intent

The Settings tab is still `PlaceholderScreen`, and `MemoxApp` pins `ThemeMode.system`
with no stored language. The backend of package 1 (BE-A1,
[spec](2026-09-24-settings-reset-backend-design.md)) already has the eight use cases of
UC-SETTINGS-001. FE-A3 puts them on screen:

- **Screen 23 "Settings":** the app-wide study defaults, the Theme and Language rows, and
  Reset app options.
- **Screen 25 "Appearance":** the theme picker.
- **Screen 26 "Language":** the language picker.
- **Screen 15 "Study options":** a root deck's own study options, with "Use app
  defaults".

The whole app follows the stored theme and language from its first frame, and follows
any change at once (BR-SETTINGS-005, BR-SETTINGS-006).

Success means three things:

- every state of kits 15, 23, 25 and 26 is built from `Mx*` widgets, or is recorded as
  not built with the reason;
- each UC-SETTINGS-001 flow (main, A1–A4, E1–E4) has a test;
- changing the theme or the language keeps the navigation stack and the scroll position,
  and a restart keeps the choice.

## 2. Context (2026-09-26)

- **Backend.** `lib/features/settings/domain/usecases/` holds eight use cases. Their
  results are:
  - `WatchAppSettingsUseCase() → Stream<AppSettingsEntity>`;
  - `SaveStudyDefaultsUseCase`, `SetThemeUseCase`, `SetLanguageUseCase` and
    `ResetAppSettingsUseCase` return `Outcome<void, SettingsRejection>`;
  - `WatchStudyOptionsUseCase({deckId})` returns
    `Stream<Outcome<EffectiveStudyOptions, SettingsRejection>>`;
  - `SaveRootStudyOptionsUseCase` and `UseAppDefaultsUseCase({rootDeckId})` return
    `Outcome<void, SettingsRejection>`.

  `EffectiveStudyOptions.source` is `appDefaults`, `rootOverride` or
  `unreadableRootOverride`. `SettingsRejection` is `cardLimitOutOfRange`, `deckNotFound`
  or `notARootDeck`. No backend change is needed.
- **Kit** "MemoX — Mobile UI Kit v3", version `1790244159-01e6`:
  - **23 "Settings", 8 states:** loaded, loading, saving, saved, invalidLimit,
    saveFailed, resetConfirm, resetDone.
  - **25 "Theme"** (the module is titled "Appearance"), 3 states: system, light, dark.
  - **26 "Language", 3 states:** default (English), changed (Vietnamese), system.
  - **15 "Study options", 7 states:** override, defaults, invalid, saving, saved,
    saveFailed, loading.
  - Screen 15 opens from the deck action sheet ("Study options", "Cards per session ·
    new-card order") and from an icon on screen 14's app bar.
- **Kit against the rules.**
  - Screen 23 saves each option on change, while UC-SETTINGS-001 step 2 said "press save
    for the Study defaults group".
  - Screen 23 draws Theme as an inline segmented tray, and nothing opens screen 25.
  - The reset copy names four values.
- **Other sessions.**
  - *BE-B5, the reminders backend* (`claude/be-reminders`, spec approved, no code yet):
    `Reset to defaults` also turns the reminder off and moves it to 20:00 (its D3). It
    asks FE-A3 to name the reminder in the reset copy (its D4). It plans to use UI-base
    §9 row 108, which FE-B1 already holds.
  - *The study chain* (FE-A6 P5, then FE-A8) owns screens 13, 14 and 16–21.
  - *Shared UI refinements phase 1* (spec and plan only) changes `MxCard`'s radius, the
    footer button pair, `overline` and selecting rows. Goldens from this work re-render
    when it lands.
- **Shared widgets.** `MxSection`, `MxSettingsRow`, `MxSegmentedTray`, `MxStepper`,
  `MxToggle`, `MxOptionRow`, `MxNote`, `MxDialog`, `MxSnackbar` and `MxFooterBar`
  exist. `MxStepper` has −/+ buttons only: the caller clamps, and nothing can be typed.

## 3. Decisions

| # | Decision | Owner |
|---|---|---|
| D1 | Screen 23 saves on change, as the kit draws it; there is no Save button. Each settled change is one submit and one transaction (BR-SETTINGS-007). UC-SETTINGS-001 step 2 is amended to say so. | Owner, 2026-09-26 (permission to amend the UC given with the choice) |
| D2 | The theme is chosen on screen 25, a page of its own. Screen 23's Theme row opens it, as the Language row opens screen 26. The row shows the current choice instead of the kit's inline tray. | Owner, 2026-09-26 |
| D3 | Screen 15 opens from the deck action sheet (the row leaves Coming soon) and from an icon on screen 14's app bar, both as drawn. | Owner, 2026-09-26 |
| D4 | The reset copy names only what the app shows: theme, language, cards per session and new-card order. FE-B5 adds the reminder to the copy when it shows the reminder row. Until then nobody can turn the reminder on, so a reset that turns it off changes nothing a person sees. | Owner, 2026-09-26 (instead of BE-B5 D4) |
| D5 | `main()` reads the `app_settings` row once before `runApp`, so the first frame already has the stored theme and language. `MemoxApp` then follows the stream. | Owner, 2026-09-26 |
| D6 | Cards per session is set three ways: −/+ by one; holding −/+ repeats; tapping the number opens a numeric field. A typed number outside 1–200 shows "Enter a number from 1 to 200" under the field and is not saved. This is the kit's `invalidLimit` / `invalid` state. `MxStepper` is extended for this (§5.1). | Owner, 2026-09-26 |
| D7 | Screen 25's title is "Theme", matching the row that opens it. The card lines read "Match phone", "Always light" and "Always dark", not the kit's palette names "Tokyo Pure" and "Tokyo Nebula". | Owner, 2026-09-26 (critique P2) |
| D8 | Screen 26's "Follow the system" line names what `system` resolves to now: "Phone is set to English" or "Phone is set to Tiếng Việt", and "{phone language} isn't available · English" otherwise. The kit's "Phone is set to Tiếng Việt · falls back to English" contradicts BR-SETTINGS-006. Each row's sub-line names the language in the current UI language. | Critique P1 (BR beats kit) |
| D9 | Screen 15's Save is enabled only while the draft is valid and differs from the persisted options. Its scroll view pads for the footer, so the last note stays readable. | Critique P1, P3 |

## 4. Structure

- **`lib/features/settings/presentation/`** (new):
  - `providers/`: one provider per use case, and `appSettingsProvider` (the stream);
  - `controllers/settings_controller.dart`: screen 23, the submits and their in-flight
    guard;
  - `controllers/study_options_controller.dart`: screen 15, a family by deck id;
  - `states/`: the draft and submit states of each controller;
  - `screens/`: `settings_screen.dart` (23), `appearance_screen.dart` (25),
    `language_screen.dart` (26) and `study_options_screen.dart` (15);
  - `widgets/`: the theme preview card and screen 23's sections.
- **`app/`:**
  - `app.dart`: `MemoxApp` takes an optional `initialSettings` and watches
    `appSettingsProvider`. The `themeMode` and `locale` of `MaterialApp.router` are the
    only things that change. The router is created once, as now.
  - `main.dart`: the pre-read (D5).
  - `router/`:
    - the Settings branch shows screen 23;
    - `/settings/theme` and `/settings/language` open on the root navigator with no
      bottom bar, as the kit draws them;
    - `/decks/deck/:deckId/options` opens screen 15 on the root navigator.
- **Across features.** `deck` and `study` never import `settings`. `app/` passes an
  `onOpenStudyOptions` callback down, as it passes `onOpenTrash`:
  - to `DeckLevelScreen`, then on to the deck action sheet;
  - to `StudyEntryScreen`, for the app bar icon.
- **Shared.** `MxStepper` gains the hold-to-repeat and the typed entry (§5.1), under the
  flutter-theme-design contract, with its own widget tests and gallery entry.

## 5. Behaviour

### 5.1 `MxStepper`

- **Hold.** Holding − or + repeats the step, first after 400 ms and then every 80 ms. It
  stops at the bound the caller sets, where that button's callback is null.
- **Typed entry.** Tapping the number turns it into a numeric `MxTextField` with the
  current value. Done or a lost focus submits the text through
  `onValueSubmitted(String)`. The caller parses and validates it. `isInvalid` draws the
  kit's ring, and the message below the row is the caller's.
- **TalkBack.** The number is one node: "Cards per session, 20". Its action is "Edit",
  and −/+ keep their labels.

### 5.2 Screen 23 (plan 1)

- **Sections.**
  - *Study defaults:* Cards per session (1–200) and New-card order (a segmented tray,
    Created · Random). Its note says the values apply to sessions started from now on
    (BR-SETTINGS-004).
  - *App:* Theme, whose sub-line is the choice ("Follows the system setting", "Light",
    "Dark"), opens 25. Language, whose sub-line is "System · English" and so on, opens 26.
    The Daily reminder row is hidden until FE-B5 (spec A4, "controls without their
    feature are hidden").
  - *Reset:* "Reset app options" with the kit's note.
- **Saving (D1, D6).** A −/+ tap or a hold updates a draft. The draft is submitted once
  the change settles:
  - when a hold is released;
  - 600 ms after the last tap;
  - when a typed value is submitted.

  A segment tap submits at once. While a submit is in flight:
  - its row shows the busy stepper;
  - a second submit of the same value group is ignored (A4);
  - the other rows stay usable.
- **Results.**
  - *Ok:* the toast "Saved".
  - *Failure:* the toast "Couldn't save cards per session. Still {n}." with Retry. The
    control shows the persisted value again, and Retry resubmits the draft (E2).
- **States.**
  - *loading:* skeleton sub-lines and controls.
  - *read error (E3):* `MxErrorState` with Retry, and no invented value. The kit has no
    such state; it is a V8 addition, recorded in the detail file.
- **Reset (A3).**
  - The row opens the kit's dialog: "Reset app options?", its body, and the shield note
    "…This is not 'Reset learning progress'" (BR-SETTINGS-008).
  - Cancel is the safe choice; the confirm is "Reset options" and spins while it runs.
    Ok gives the toast "App options reset to defaults". A failure gives a toast with
    Retry.
  - The copy follows D4.

### 5.3 Screens 25 and 26 (plan 1)

- **Screen 25** (titled "Theme", D7). Three cards: System ("Match phone"), Light ("Always light") and Dark ("Always dark"). Each card has a
  preview. The previews paint colours read from `buildLightTheme()` and
  `buildDarkTheme()` (System is split in half), with no new token. Tapping a card submits
  `SetThemeUseCase`. The app changes at once, and the page stays open. The footnote reads
  "Applies at once — no restart, and you stay where you are."
- **Screen 26.** Three rows: "Follow the system" (its sub-line follows D8), English and
  Tiếng Việt. Tapping a row
  submits `SetLanguageUseCase`. After a switch, the toast is written in the new language:
  "Switched to English" or "Đã chuyển sang Tiếng Việt".
- **Failures on 25 and 26.** A failed save shows a toast with Retry, and the persisted
  choice stays selected (BR-SETTINGS-007).

### 5.4 App-wide theme and language (plan 1)

- **Before the first frame (D5).** `main()` opens a `ProviderContainer`, awaits the first
  `WatchAppSettingsUseCase` value with a 2-second timeout, and starts
  `UncontrolledProviderScope(MemoxApp(initialSettings: …))`. A failure or a timeout
  starts with `null`, so the app follows the platform, and screen 23 shows E3 if the
  stream still fails.
- **After that.** `themeMode` maps from `ThemeChoice`. `locale` maps from
  `LanguageChoice`: null for `system`, `Locale('en')` or `Locale('vi')` otherwise. With
  null, Flutter resolves the locale on `supportedLocales` and falls back to `en`
  (BR-SETTINGS-006).
- **Tests.** Widget tests pump `MemoxApp` without `initialSettings`, as they do today.

### 5.5 Screen 15 (plan 2)

- **Opening it.** It opens for any deck. A sub-deck shows its root's options, and the
  root is resolved by `EffectiveStudyOptions.rootDeckId`. The note names the root deck
  ("These options belong to {root} and every sub-deck in it"). The breadcrumb reads
  through the deck feature's domain use case.
- **"Use app defaults" toggle (A1).**
  - *On:* the options below read "App defaults (read-only here)" and are disabled.
  - *Off:* they read "This deck" and are editable, seeded from the effective values.
- **Save** (in the bottom bar):
  - it runs `UseAppDefaultsUseCase` when the toggle is on and the deck had an override;
  - it runs `SaveRootStudyOptionsUseCase` otherwise;
  - it is disabled while the draft is invalid or unchanged (D9); the scroll view pads for
    the bar.
- **Save states.**
  - *saving:* "Saving…" with a spinner.
  - *Ok:* the toast "Saved · applies to the next session".
  - *Failure:* the caption "Couldn't save. The deck still uses {n} cards, {order}." and
    "Retry save" (E4).
- **Other states.**
  - `unreadableRootOverride` shows a warning note: the deck's options could not be read,
    and saving replaces them.
  - A deck that goes to the Trash while the screen is open shows the gone state with
    Back. This follows the FE-B1 pattern and uses the existing `…GoneTitle` copy style.
- **Entries (D3).**
  - The deck action sheet row "Study options" ("Cards per session · new-card order")
    leaves the Coming soon sheet, and the Coming soon sheet drops its Study options line.
  - Screen 14's app bar gains the "Study options" icon button.

## 6. Errors

- **Messages.** Every rejection and `Failure` maps to copy through the settings
  feature's own messages. No SQL, path or id reaches the screen (BR-SETTINGS-007,
  BR-CORE-005).
- **Rejections.**
  - `cardLimitOutOfRange` cannot reach a submit, because the draft validates first. If it
    does arrive, it shows the field message.
  - `deckNotFound` on screen 15 shows the gone state.
  - `notARootDeck` cannot happen, because the root is resolved first. If it does, it
    shows a generic failure toast.

## 7. Tests

- **Controllers (plain `test()` over the real store):**
  - saving settles once per gesture;
  - the in-flight guard ignores a second submit;
  - a failure keeps the draft and restores the persisted value;
  - reset;
  - screen 15's toggle and Save paths, and the unreadable override.
- **Widgets:** every kit state of 15, 23, 25 and 26, E3, and the gone state of 15.
- **App:**
  - the pre-read paints the stored theme on the first frame;
  - a theme or language change keeps the pushed route and the scroll offset;
  - `system` follows a platform brightness or locale change;
  - a restart keeps the choice (a new app over the same database).
- **Goldens and audits:** light and dark goldens of each screen state. Visual audits at
  360 dp and text scale 2 for the four new screens (`screen_audit_coverage_test`).
- **`MxStepper`:** hold-to-repeat timing, the typed entry, and the TalkBack node.

## 8. Documents

- **Detail files:** `15-study-options.md`, `23-settings.md`, `25-theme.md` and
  `26-language.md`, with captures (`tools/design/screen_states.json` gains the four
  screens).
- **Tracking:**
  - index rows 15, 23, 25 and 26;
  - the state checklist rows (`docs/shared/ui/screen-state-checklist.md`);
  - WBS FE-A3.
- **UC and feature files:**
  - UC-SETTINGS-001: step 2 as D1, and the E3 wording unchanged;
  - `code:` of the settings README and the UC gains `presentation`;
  - `features/settings/ui.md` gains the screens.
- **UI-base §9:** new rows after the last row in use:
  - D2 (theme on its own page, not the inline tray);
  - the E3 error state;
  - 15's gone state;
  - the extended `MxStepper`.

## 9. Plans

1. **Plan 1: screens 23, 25 and 26**, plus the `MxStepper` extension and the app-wide
   theme and language (§5.1–§5.4).
2. **Plan 2: screen 15** and its two entries (§5.5).

Before plan 1, Impeccable critiques kits 15, 23, 25 and 26 (CLAUDE.md, a screen's
workflow, step 3).

## 10. Out of scope

- **Default review modes.** Kit 15 has none, and `review_mode_pick_controller` stays
  unpersisted.
- **The Daily reminder row and screen 24** belong to FE-B5.
- **The reminder in the reset copy** belongs to FE-B5 (D4).

## 11. Risks and rollback

- **Shared UI refinements.** If they land first, this work's goldens re-render; if they
  land second, theirs do. The logic is not touched.
- **BE-B5.** If it merges before this work, reset also turns the reminder off (its D3),
  with no visible effect until FE-B5 (D4). Its planned UI-base row 108 is taken, so it
  must use the next free row. The owner is told.
- **Screen 14.** Its app bar icon touches the study chain's screen. That is one widget
  and one callback, and it is merged after P5 if P5 is in flight.
- **Rollback.** The work is presentation and `app/` only. Reverting the PRs restores the
  placeholder tab and `ThemeMode.system`, and no data changes.
