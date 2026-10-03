<!-- Hand-written screen record. -->

# 15 · Study options

A root deck's study options, opened from any deck in its tree: its own cards per session
and new-card order, or the app defaults from Settings. Save writes them for sessions
started afterwards. UC-SETTINGS-001 A1, E4; BR-STUDY-056, BR-SETTINGS-003,
BR-SETTINGS-004; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.5.

## Entry points

- **The deck action sheet (screen 01):** "Study options" / "Cards per session · new-card
  order", below Rename (D3). It left the Coming soon sheet.
- **Screen 14's app bar:** the sliders icon, "Study options" (D3).

Both open `/decks/deck/:deckId/options` on the root navigator, with no bottom bar. On a
sub-deck the screen shows its root's options (BR-STUDY-056).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Study options". |
| Breadcrumb | `MxBreadcrumb` | Library › the deck's path › the deck › "Study options". |
| Note | `MxNote` (layers) | The screen's one note (critique 2026-09-30): "These options belong to {root} and every sub-deck in it. Changes apply to sessions started from now on; a session already open keeps its options." |
| Unreadable override | `MxInlineBanner` (warning) | "This deck's options could not be read. Saving replaces them." |
| Toggle | `MxSection` + `MxSettingsRow` + `MxToggle` | "Use app defaults"; on: "Following Settings · {n} cards, {order}", off: "Off · this deck has its own options". |
| Options | `MxSection` | "App defaults (read-only here)" or "This deck"; "Cards per session" / "1 to 200" with an `MxStepper` (−/+, hold, typed entry); "New-card order" as an `MxSettingsRow` with an `MxSegmentedTray` ("In order" · "Random"; critique 2026-09-30 part 3a, R2), as screen 23 draws it; each row carries its icon, as on screen 23. While the toggle is on, the two rows show their values as plain text at full contrast, with no stepper or tray (critique 2026-09-30); turning it off brings the controls back with the same values. |
| Card limit message | `MxFieldMessage` (error) | "Enter a number from 1 to 200", under the stepper (UC E1). |
| Footer | `MxFooterBar` + `MxButton` | "Save", enabled only for a valid change (D9); spinning while it runs; "Retry save" after a failure. The caption: "Saved to this device only." or "Fix the limit to enable save."; a failed save is the danger banner "Not saved" at the top of the page (critique 2026-09-30 part 3d-1); the banner and "Retry save" stay through edits until a save succeeds (part 3d-2). |
| Toast | `MxSnackbar` | "Saved · applies to the next session". |
| Discard dialog | `StudyOptionsDiscardDialogWidget` (`MxDialog`, `MxSheetActions`) | "Discard your changes?" / "Leaving now keeps the options as they were saved."; Keep editing (outline) and Discard changes. It opens on Back or system Back while a change Save has not written stands, a typed limit outside 1 to 200 included (SP2a 2.06). |

Save runs Use app defaults when the toggle is on and the root had its own options, and
saves the root's options otherwise. A second Save while one runs is ignored (A4).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| override | `study_options_override_light.png` | `study_options_override_dark.png` | Save is disabled until something changes (D9). |
| defaults | `study_options_defaults_light.png` | `study_options_defaults_dark.png` | Save disabled. |
| invalid | `study_options_invalid_light.png` | `study_options_invalid_dark.png` | The message sits under the stepper and the sub-line stays (UC E1). |
| saving | `study_options_saving_light.png` | `study_options_saving_dark.png` | The stepper and the button spin; the button has no "Saving…" text (`MxButton.isLoading`). |
| saved | `study_options_saved_light.png` | `study_options_saved_dark.png` | — |
| saveFailed | `study_options_save_failed_light.png` | `study_options_save_failed_dark.png` | "Not saved" banner and "Retry save"; both stay through edits until a save succeeds. |
| loading | `study_options_loading_light.png` | `study_options_loading_dark.png` | Skeleton rows, no footer (UI-base row 125). |
| gone | — | — | (spec §6) a deck gone to the Trash shows "This deck is no longer here" with Back (UI-base row 129). |
| read error | — | — | `MxErrorState` with Retry and no invented value; either read failing, the deck's options or the app settings, shows it, and Retry reloads both (SP2a 2.05). |
| discard | no golden | no golden | The dialog over the form; Keep editing leaves it as it was, Discard changes leaves the screen (SP2a 2.06). |

Goldens: `test/features/settings/presentation/goldens/study_options_{override,defaults,invalid,saving,saved,save_failed,loading}_{light,dark}.png`.

## Rulings

- `MxNote` carries one plain string, so the root's name is not bold.
- **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper and the sub-line stays.
- **D9:** Save is enabled only for a valid change; while saving the button spins (`MxButton.isLoading`).
- **Spec §6, UI-base row 129:** a gone root shows the Library's gone state with Back.
- **M3 review 2026-09-28 E1, E2:** new-card order is one `MxSettingsRow` + `MxSegmentedTray`, with icons on every row.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** a failed save shows a danger banner, "Not saved", at the top of the page; the footer keeps Retry save and its local-only caption.
- **SP2a 2.05–2.06 (spec `2026-10-03-ui-hardening-sp2a-design.md` §3.1):** the app settings failing to read is an error like the deck's options failing, not an endless skeleton (2.05); Back with unsaved edits asks Discard or Keep editing, as the card editor does (2.06).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** a failed save's "Not saved" banner and the footer's "Retry save" stay through edits until a save succeeds (the banner's values are the deck's stored ones, so they stay true while the person edits).

## Copy

"Study options" · "These options belong to {root} and every sub-deck in it. Changes apply to sessions started from now on; a session already open keeps its options." · "This
deck's options could not be read. Saving replaces them." · "Use app defaults" ·
"Following Settings · {n} cards, {order}" · "in creation order" · "random order" · "Off · this
deck has its own options" · "App defaults (read-only here)" · "This deck" · "Cards per
session" · "1 to {max}" · "Enter a number from {min} to {max}" · "New-card order" ·
"In order" · "Oldest cards first — the order you added or imported them" ·
"Random" · "Shuffled each learning session" · "Changes apply to sessions started from now
on. A session already open keeps the options it started with." · "Save" · "Retry save" ·
"Saved to this device only." · "Fix the limit to enable save." · "Couldn't save. The deck
still uses {n} cards, {order}." · "Saved · applies to the next session" · "Cards per
session · new-card order" · "Discard your changes?" · "Leaving now keeps the options as they were saved." · "Keep editing" · "Discard changes".
