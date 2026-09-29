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
| Toasts | `MxSnackbar` | After a switch, in the new language: "Switched to English" or "Đã chuyển sang Tiếng Việt". "Couldn't change the language." · Retry; the stored choice stays selected. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| english | `settings_language_english_light.png` | `settings_language_english_dark.png` | Radio rows; English has no sub-line. |
| vietnamese | `settings_language_switched_light.png` | `settings_language_switched_dark.png` | The toast reads in Vietnamese. |
| system | `settings_language_system_light.png` | `settings_language_system_dark.png` | The line names what `system` resolves to (D8). |
| read error | — | — | **V8 addition (UC E3):** `MxErrorState` "Couldn't open Settings" with Retry. |

Goldens: `test/features/settings/presentation/goldens/settings_language_{english,switched,system}_{light,dark}.png`.

## Rulings

- **D8, BR-SETTINGS-006:** the system row says "Phone is set to {language}"; the fallback line shows only for a language the app lacks.
- The choices are `MxOptionRow` radios, the app's single-choice list; the note is the `MxSection` note (M3 review 2026-09-28 D4).
- **Critique 2026-09-26:** a row has no sub-line when it would repeat the title.

## Copy

"Language" · "Follow the system" · "Phone is set to {language}" · "Your phone's language
isn't available · English" · "English" · "Tiếng Việt" · "Vietnamese" · "Applies at once —
no restart, and you stay where you are. Your cards stay in their own language." ·
"Switched to English" · "Đã chuyển sang Tiếng Việt" · "Couldn't change the language." ·
"Retry".
