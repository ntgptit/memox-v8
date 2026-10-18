<!-- Hand-written screen record. -->

# 23a · Settings · Study options

The app-wide study options, the defaults every deck follows unless it has its own,
moved from the Settings tab to a page of their own (settings hub spec 2026-10-07, D3;
named "Study options" by the owner on 2026-10-07, the page and file paths unchanged): the card limit, the new-card order, the read-aloud
switch and the speech language, each saved on change (FE-A3 D1). Every value shown is
the stored one, or the card limit being changed (BR-SETTINGS-001). UC-SETTINGS-001
step 2; specs [2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.2 (behaviour), [2026-10-07-study-speech-design.md](../../../superpowers/specs/2026-10-07-study-speech-design.md)
§6 (the speech rows) and [2026-10-07-settings-hub-design.md](../../../superpowers/specs/2026-10-07-settings-hub-design.md)
§5.2 (this page).

## Entry points

- **Screen 23's Study options row**, `/settings/study`, on the root navigator with no
  bottom bar. Back returns to the hub.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` + Back | "Study options". |
| Session | `MxSection` + `MxSettingsRow` × 2, note | "Session". "Cards" / "Per session" with an `MxStepper` in the trailing slot, beside the label: −/+, a hold repeats, a tap on the number types one (FE-A3 D6); the stepper keeps "Cards per session" as its spoken name, and moves under the label from text scale 1.5. "New-card order" / "In order" or "Random" (shuffle tile, the value and a chevron), a tap opening the new-card order sheet (owner 2026-10-07). The note: "Changes apply to sessions you start from now on. A deck with its own study options keeps them." (BR-SETTINGS-004). |
| Card limit message | `MxFieldMessage` (error) in the row's `message` slot | "Enter a number from 1 to 200", under the label and the stepper, from the label's start to the row's end, while a typed value is out of range (UC E1). |
| New-card order sheet | `MxBottomSheet` + `MxOptionRow` × 2 | "New-card order": "In order", "Random", the current one selected; a pick closes the sheet and saves at once, as the speech language sheet does. |
| Speech | `MxSection` + `MxSettingsRow` × 2, note | "Speech". "Read the term aloud" / "When a new card comes up while learning" with an `MxToggle` (speak tile); "Speech language" / "{language} · Used by decks that follow the defaults" (voice tile, the value first and a chevron), a tap opening the speech language sheet (study speech spec §6, BR-SETTINGS-009, BR-SETTINGS-010). The note: "Changes apply at once. A deck with its own speech language keeps it." (BR-STUDY-080). |
| Speech language sheet | `MxBottomSheet` + `MxOptionRow` × 10 | As screen 15 records it: one row per `SpeechLanguage`, the current one selected and scrolled into view; a language the engine lacks says "No voice on this device · nothing is read" and stays selectable (spec D5, D12). |
| Toasts | `MxSnackbar` | "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the new-card order. Nothing changed." · Retry; "Couldn't save the read-aloud switch. Nothing changed." · Retry; "Couldn't save the speech language. Nothing changed." · Retry (settings hub spec D9). |

The card limit is saved once a change settles: 600 ms after the last step, a hold
included, or at once for a typed value. The toggle and a sheet pick save at once (D1). A new-card order picked while the card limit (or another order) is being written is kept and written once that write ends, as a limit changed meanwhile is; the last pick wins and a pick of the stored order writes nothing (audit 2026-10-17). Back within those 600 ms still saves the value, but the page is gone, so
its "Saved" toast or failure toast is not shown; accepted (final review 2026-10-07): the
hub's Study summary names the saved value on return.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `study_defaults_loaded_light.png` | `study_defaults_loaded_dark.png` | Both sections with their notes; the Session card is two 74 dp rows. |
| loading | `study_defaults_loading_light.png` | `study_defaults_loading_dark.png` | Two section-shaped skeleton cards of 2·2 `MxSkeletonRow`s. |
| saving | `study_defaults_saving_light.png` | `study_defaults_saving_dark.png` | The stepper's spinner; the other rows stay usable. |
| saved | `study_defaults_saved_light.png` | `study_defaults_saved_dark.png` | — |
| invalidLimit | `study_defaults_invalid_limit_light.png` | `study_defaults_invalid_limit_dark.png` | The message runs under the label and the stepper; the sub-line stays (UC E1). |
| saveFailed | `study_defaults_save_failed_light.png` | `study_defaults_save_failed_dark.png` | The stepper shows the stored value again. |
| new-card order sheet | `study_defaults_order_sheet_light.png` | `study_defaults_order_sheet_dark.png` | The two orders, In order selected. |
| speech language sheet | `study_defaults_speech_language_sheet_light.png` | `study_defaults_speech_language_sheet_dark.png` | Three voices on the device; the others marked. |
| read error | — | — | (UC E3) `MxErrorState` "Couldn't open Settings" with the local-first body and Retry, retrying the same read as the hub. |

Goldens: `test/features/settings/presentation/goldens/study_defaults_{loaded,loading,saving,saved,invalid_limit,save_failed,order_sheet,speech_language_sheet}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the `app_settings` stream emits | loaded | UC-SETTINGS-001 step 2. VERIFIED `study_defaults_screen_test.dart::the two sections carry their own notes (settings hub spec D3)`; the skeleton is the golden `study_defaults_loading_*` |
| loading | the read fails | read error | UC E3. VERIFIED `::a failed read on the Study defaults page shows the error with Retry and no value (E3)` |
| read error | Retry | error with Retry spinning, then loaded | UC E3. The error is VERIFIED in the test above; the tap is `UNVERIFIED (code read)`: `study_defaults_screen.dart` invalidates `appSettingsProvider` |
| loaded | tap − or + (or hold) | loaded with the draft shown; the write follows 600 ms after the last step | D1, D6. VERIFIED `settings_controller_test.dart::steps settle into one write of the last value (D1, D6)`, `::a step stops at the bounds` |
| loaded (draft) | the 600 ms settle ends | saving | D1. VERIFIED `::while the limit writes, the stepper spins and the order stays usable (saving)` for the spinner |
| saving | the write lands | saved: the draft goes, toast "Saved" | D1. VERIFIED `::steps settle into one save, then "Saved" (D1)` |
| saving | the write fails | saveFailed: the stepper shows the stored value, toast "Couldn't save cards per session. Still {n}." with Retry | UC E2. VERIFIED `::a failed save names the kept value and Retry saves it (E2)`; `settings_controller_test.dart::a failed write keeps the persisted value, says so, and Retry writes the same change (E2)` |
| saveFailed | Retry | saving, then saved | UC E2. VERIFIED same tests |
| saving | a step or a typed value while the write runs | saving; the new value is written once the first ends | VERIFIED `settings_controller_test.dart::a step while its own write runs is written after it` |
| loaded | type a number in 1 to 200 | saving at once, then saved | D6. VERIFIED `settings_controller_test.dart::a typed limit outside 1–200 is shown as invalid and not written; a valid one is written at once (E1)` |
| loaded | type a number outside 1 to 200 | invalidLimit: nothing is written, the message sits under the label and the stepper | UC E1. VERIFIED `::a typed 250 is refused under the stepper and saves nothing (E1)`, `::a typed 250 is refused across the row, under the label (owner 2026-10-07)` |
| invalidLimit | type a valid number | saving at once, then saved | UC E1. VERIFIED `settings_controller_test.dart` (same test as the row above) |
| invalidLimit | tap − or + | the draft steps from the stored value, the message goes | `UNVERIFIED (code read)`: `SettingsController.stepCardLimit` starts from the persisted value when `isCardLimitInvalid` |
| any | Back within the 600 ms settle | the value is still saved, with no toast | accepted (final review 2026-10-07; see the note under Layout). `UNVERIFIED (code read)`: the hub under the page listens to the same `settingsControllerProvider`, so the settle timer survives the pop |
| loaded | tap New-card order | the order sheet | owner 2026-10-07. VERIFIED `::the new-card order row names the order and opens a sheet; a pick saves it (owner 2026-10-07)` |
| order sheet | pick the other order | the sheet closes; saving, then saved: toast "Saved" | VERIFIED same test for the close, the row and the stored order; the toast is `UNVERIFIED (code read)` |
| order sheet | pick the current order, tap away or Back | the sheet closes, nothing written | `UNVERIFIED (code read)`: `chooseNewCardOrder` returns on the same order; `showNewCardOrderSheet` returns null when dismissed |
| saving (order) | the write fails | saveFailed: toast "Couldn't save the new-card order." with Retry; the row shows the stored order | `UNVERIFIED (code read)`: `SettingsController._submit`; the failure path is tested for the limit and the speech rows, not for this one |
| loaded | pick an order while the limit is saving | the pick is kept and written once that write ends; the last pick wins | audit 2026-10-17 SET-6. VERIFIED `settings_controller_test.dart::an order picked while the limit writes is written once that write ends, not lost (audit 2026-10-17 SET-6)`; the reverse (a limit during an order write) `::a limit changed while its group writes is written once that write ends, not dropped` |
| loaded | flip the read-aloud toggle | saving, then saved: toast "Saved" | BR-SETTINGS-010. VERIFIED `::the read-aloud toggle saves on change (BR-SETTINGS-010)` |
| loaded | tap Speech language | the engine is asked (up to 300 ms), then the speech language sheet | study speech spec D5. VERIFIED `::the speech language row opens the sheet; a pick saves and shows its name (BR-SETTINGS-009)` |
| speech language sheet | a second tap on the row while the engine is asked | no second sheet | VERIFIED `speech_language_sheet_test.dart::a second tap while the engine is still asked opens nothing (audit 2026-10-07)` |
| speech language sheet | pick a language | the sheet closes; saving, then saved: toast "Saved" | VERIFIED `::a saved speech language says "Saved", as the other rows do` |
| speech language sheet | dismiss | nothing written | `UNVERIFIED (code read)`: `showSpeechLanguageSheet` returns null |
| saving (toggle or language) | the write fails | saveFailed: toast "Couldn't save the read-aloud switch." / "Couldn't save the speech language." with Retry | UC E2. VERIFIED `::a failed speech save says so, and Retry writes it (UC-SETTINGS-001 E2)` |
| loaded | the stored value changes elsewhere (a sync pull) | the rows show it; a draft is dropped once the store holds it | `UNVERIFIED (code read)`: `SettingsController._dropSavedDraft` on the `appSettingsProvider` listener |

## Rulings

- **Settings hub spec D3, D9:** two sections with their own notes, so each names its own timing (the limit and order apply from the next session, speech at once); the page says the study rows' toasts, the hub the reset's.
- **FE-A3 D1, D6 (owner):** save on change, no Save button; the stepper takes −/+, a hold that repeats, and a typed number.
- **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the label and the stepper, and the sub-line stays.
- **Owner 2026-10-07, compaction:** the page is "Study options"; the Session card is two rows of the hub's height: the stepper sits beside a short label ("Cards" / "Per session"), whose full name the stepper still speaks, and the new-card order is a value row with its sheet, as the speech language is. The range line "1 to 200 · default 20" is gone; the E1 message still names the range. Screen 15 keeps its form.
- **Study speech spec §6, critique 2026-10-07:** the speech language row carries the value first and a chevron; the sheet is resolved before it opens.
- **Q-C-1 (owner, 2026-10-16):** the speech language value and the voice-missing description keep each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- "Study options" · "Session" · "Cards" · "Per session" · "Cards per session" (spoken) · "Fewer cards per session" · "More cards per session" · "Enter a number from {min} to {max}" · "New-card order" · "In order" · "Random" · "Changes apply to sessions you start from now on. A deck with its own study options keeps them." · "Speech" · "Read the term aloud" · "When a new card comes up while learning" · "Speech language" · "{language} · Used by decks that follow the defaults" · "No voice on this device · nothing is read" · "Changes apply at once. A deck with its own speech language keeps it."
- Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't save the new-card order. Nothing changed." · "Couldn't save the read-aloud switch. Nothing changed." · "Couldn't save the speech language. Nothing changed." · "Retry".
- Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".
