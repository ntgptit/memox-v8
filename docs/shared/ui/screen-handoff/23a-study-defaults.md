<!-- Hand-written screen record. -->

# 23a · Settings · Study defaults

The app-wide study defaults, moved from the Settings tab to a page of their own
(settings hub spec 2026-10-07, D3): the card limit, the new-card order, the read-aloud
switch and the speech language, each saved on change (FE-A3 D1). Every value shown is
the stored one, or the card limit being changed (BR-SETTINGS-001). UC-SETTINGS-001
step 2; specs [2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.2 (behaviour), [2026-10-07-study-speech-design.md](../../../superpowers/specs/2026-10-07-study-speech-design.md)
§6 (the speech rows) and [2026-10-07-settings-hub-design.md](../../../superpowers/specs/2026-10-07-settings-hub-design.md)
§5.2 (this page).

## Entry points

- **Screen 23's Study defaults row**, `/settings/study`, on the root navigator with no
  bottom bar. Back returns to the hub.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) + Back | "Study defaults". |
| Session | `MxSection` + `MxSettingsRow` × 2, note | "Session". "Cards per session" / "1 to 200 · default 20" with an `MxStepper` under the label: −/+, a hold repeats, a tap on the number types one (FE-A3 D6). "New-card order" / "How new cards enter a learning session" with an `MxSegmentedTray` In order · Random (critique 2026-09-30 part 3a, R2). The note: "Changes apply to sessions you start from now on. A deck with its own study options keeps them." (BR-SETTINGS-004). |
| Card limit message | `MxFieldMessage` (error) | "Enter a number from 1 to 200", under the stepper, while a typed value is out of range (UC E1). |
| Speech | `MxSection` + `MxSettingsRow` × 2, note | "Speech". "Read the term aloud" / "When a new card comes up while learning" with an `MxToggle` (speak tile); "Speech language" / "{language} · Used by decks that follow the defaults" (voice tile, the value first and a chevron), a tap opening the speech language sheet (study speech spec §6, BR-SETTINGS-009, BR-SETTINGS-010). The note: "Changes apply at once. A deck with its own speech language keeps it." (BR-STUDY-080). |
| Speech language sheet | `MxBottomSheet` + `MxOptionRow` × 10 | As screen 15 records it: one row per `SpeechLanguage`, the current one selected and scrolled into view; a language the engine lacks says "No voice on this device · nothing is read" and stays selectable (spec D5, D12). |
| Toasts | `MxSnackbar` | "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the new-card order." · Retry; "Couldn't save the read-aloud switch." · Retry; "Couldn't save the speech language." · Retry (settings hub spec D9). |

The card limit is saved once a change settles: 600 ms after the last step, a hold
included, or at once for a typed value. A segment tap, the toggle and a sheet pick save
at once (D1). Back within those 600 ms still saves the value, but the page is gone, so
its "Saved" toast or failure toast is not shown; accepted (final review 2026-10-07): the
hub's Study summary names the saved value on return.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `study_defaults_loaded_light.png` | `study_defaults_loaded_dark.png` | Both sections with their notes. |
| loading | `study_defaults_loading_light.png` | `study_defaults_loading_dark.png` | Two section-shaped skeleton cards of 2·2 `MxSkeletonRow`s. |
| saving | `study_defaults_saving_light.png` | `study_defaults_saving_dark.png` | The stepper's spinner; the other rows stay usable. |
| saved | `study_defaults_saved_light.png` | `study_defaults_saved_dark.png` | — |
| invalidLimit | `study_defaults_invalid_limit_light.png` | `study_defaults_invalid_limit_dark.png` | The message sits under the stepper and the sub-line stays (UC E1). |
| saveFailed | `study_defaults_save_failed_light.png` | `study_defaults_save_failed_dark.png` | The stepper shows the stored value again. |
| speech language sheet | `study_defaults_speech_language_sheet_light.png` | `study_defaults_speech_language_sheet_dark.png` | Three voices on the device; the others marked. |
| read error | — | — | (UC E3) `MxErrorState` "Couldn't open Settings" with the local-first body and Retry, retrying the same read as the hub. |

Goldens: `test/features/settings/presentation/goldens/study_defaults_{loaded,loading,saving,saved,invalid_limit,save_failed,speech_language_sheet}_{light,dark}.png`.

## Rulings

- **Settings hub spec D3, D9:** two sections with their own notes, so each names its own timing (the limit and order apply from the next session, speech at once); the page says the study rows' toasts, the hub the reset's.
- **FE-A3 D1, D6 (owner):** save on change, no Save button; the stepper takes −/+, a hold that repeats, and a typed number.
- **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper and the sub-line stays.
- **Study speech spec §6, critique 2026-10-07:** the speech language row carries the value first and a chevron; the sheet is resolved before it opens.

## Copy

- "Study defaults" · "Session" · "Cards per session" · "1 to {max} · default {n}" · "Fewer cards per session" · "More cards per session" · "Enter a number from {min} to {max}" · "New-card order" · "How new cards enter a learning session" · "In order" · "Random" · "Changes apply to sessions you start from now on. A deck with its own study options keeps them." · "Speech" · "Read the term aloud" · "When a new card comes up while learning" · "Speech language" · "{language} · Used by decks that follow the defaults" · "No voice on this device · nothing is read" · "Changes apply at once. A deck with its own speech language keeps it."
- Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't save the new-card order." · "Couldn't save the read-aloud switch." · "Couldn't save the speech language." · "Retry".
- Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".
