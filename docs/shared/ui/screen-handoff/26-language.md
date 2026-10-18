<!-- Hand-written screen record. -->

# 26 · Language

The app's language: follow the phone, English or Tiếng Việt. A tap applies it at once,
and the page stays open. UC-SETTINGS-001 step 5, BR-SETTINGS-006; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.3.

## Entry points

- **Screen 23's Language row**, `/settings/language`, on the root navigator with no bottom
  bar (D2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back and "Language". |
| Rows | `MxSection` + `MxOptionRow` × 3, the note as its `MxNote` | "Follow the system" with what it resolves to now: "Phone is set to English", "Phone is set to Tiếng Việt", or "Your phone's language isn't available · English" (D8). "English", and "Tiếng Việt" with its name in the current language ("Vietnamese"); a sub-line that repeats the title is left out. |
| Note | Text | "Applies at once — no restart, and you stay where you are. Your cards stay in their own language." |
| Toasts | `MxSnackbar` | After a switch, in the new language: "Switched to English" or "Đã chuyển sang Tiếng Việt". "Couldn't change the language. Nothing changed." · Retry; the stored choice stays selected. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| english | `settings_language_english_light.png` | `settings_language_english_dark.png` | Radio rows; English has no sub-line. |
| vietnamese | `settings_language_switched_light.png` | `settings_language_switched_dark.png` | The toast reads in Vietnamese. |
| system | `settings_language_system_light.png` | `settings_language_system_dark.png` | The line names what `system` resolves to (D8). |
| loading | — | — | Before the `app_settings` stream emits: `MxSkeletonList`, three rows (`language_screen.dart:130`, `_skeletonRows = 3`). `UNVERIFIED (code read)`: no test or golden pins it. |
| read error | — | — | (UC E3) `MxErrorState` "Couldn't open Settings" with Retry. |

Goldens: `test/features/settings/presentation/goldens/settings_language_{english,switched,system}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | the `app_settings` stream has not emitted | loading: `MxSkeletonList`, three rows | `UNVERIFIED (code read)`: `language_screen.dart`; no test or golden pins it |
| loading | the stream emits | system / english / vietnamese, the stored one selected | UC-SETTINGS-001 step 5. VERIFIED `language_screen_test.dart::Follow the system names the phone language, or says the app lacks it (FE-A3 D8)` |
| loading | the read fails | read error | UC E3. `UNVERIFIED (code read)`: the `AsyncError` branch; the Theme and Study options pages pin the same branch (`theme_screen_test.dart::a failed read shows the error with Retry and no invented choice (E3)`) |
| read error | Retry | error with Retry spinning, then the state the read gives | `UNVERIFIED (code read)` |
| any | tap another row | the whole app switches at once; toast in the new language ("Switched to English" / "Đã chuyển sang Tiếng Việt"); the page stays | BR-SETTINGS-006. VERIFIED `::a tap switches the language and the toast reads in it (UC-SETTINGS-001 step 5)` |
| any | tap Follow the system | the app follows the phone; the toast reads in the phone's language, English if the app lacks it | `UNVERIFIED (code read)`: `_say` resolves `_phoneLocale()`; the row's line is VERIFIED in `::Follow the system names the phone language, or says the app lacks it (FE-A3 D8)` |
| any | tap the selected row | nothing written, no toast | `UNVERIFIED (code read)`: `_choose` returns on the stored choice; the controller side is VERIFIED `settings_controller_test.dart::theme and language are each one write; choosing the persisted value writes nothing` |
| any | a second tap while a switch runs | ignored: neither the store nor the language the toast names changes | UC A4. VERIFIED `::a second tap while a switch runs changes neither the store nor the language the toast names (A4)` |
| any | the write fails | the stored row stays selected, toast "Couldn't change the language." with Retry | UC E2. VERIFIED `::a failed save keeps the stored language and offers Retry (E2)` |
| any | the write meets a bug (not a `Failure`) | as the write failing: the stored row stays selected, the same toast with Retry; the page is no longer busy; the bug is reported | VERIFIED for the shared `SettingsController._submit` through the reset kind, `settings_held_bug_test.dart::a submit that dies on a bug is no longer busy and says the save failed, with Retry (_submit)`; the other kinds differ only in the write they pass in, `UNVERIFIED (code read)` |
| any | Retry on the toast | the write runs again, then the toast reads in that language | UC E2. VERIFIED same test |
| any | Back | screen 23, whose Language row reads the new choice | `UNVERIFIED (code read)` |

## Rulings

- **Owner 2026-10-18 (closing acceptance NEW-1):** a failed-save toast's Retry acts on this screen's controller, so the toast leaves when the screen does (`showMxSnackbar` closes a toast with an action when its route goes). Before, a Retry tapped after leaving threw "Using ref when a widget is unmounted" and wrote nothing. `settings_toast_leave_test.dart`, `mx_snackbar_route_test.dart`.
- **D8, BR-SETTINGS-006:** the system row says "Phone is set to {language}"; the fallback line shows only for a language the app lacks.
- The choices are `MxOptionRow` radios, the app's single-choice list; the note is the `MxSection` note (M3 review 2026-09-28 D4).
- **Critique 2026-09-26:** a row has no sub-line when it would repeat the title.
- **Q-C-1 (owner, 2026-10-16):** "Your phone's language isn't available · English" keeps each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

"Language" · "Follow the system" · "Phone is set to {language}" · "Your phone's language
isn't available · English" · "English" · "Tiếng Việt" · "Vietnamese" · "Applies at once —
no restart, and you stay where you are. Your cards stay in their own language." ·
"Switched to English" · "Đã chuyển sang Tiếng Việt" · "Couldn't change the language. Nothing changed." ·
"Retry".
