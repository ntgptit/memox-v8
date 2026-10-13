<!-- Hand-written screen record. -->

# 25 · Theme

The app's theme: follow the phone, always light or always dark. A tap applies it at
once, and the page stays open. UC-SETTINGS-001 step 4, BR-SETTINGS-005; spec
[2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.3.

## Entry points

- **Screen 23's Theme row**, `/settings/theme`, on the root navigator with no bottom bar
  (D2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back and "Theme" (D7). |
| Cards | `MxCard` (selected ring) + `MxRowInk` × 3 | A preview, then "System" / "Match phone", "Light" / "Always light", "Dark" / "Always dark", and a check on the chosen card. The preview paints the light and dark themes' own colours; System is split in half. Each card is one TalkBack node, "selected" when chosen. |
| Note | `MxNote.hint` | "Applies at once — no restart, and you stay where you are.", the footnote form Language and Settings use (critique 2026-09-30 part 3a). |
| Toast | `MxSnackbar` | "Couldn't change the theme." · Retry. The stored choice stays selected. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| system | `settings_theme_system_light.png` | `settings_theme_system_dark.png` | Titled "Theme", with plain descriptors (D7); no "THEME" overline. |
| light | `settings_theme_light_light.png` | `settings_theme_light_dark.png` | As system. |
| dark | `settings_theme_dark_light.png` | `settings_theme_dark_dark.png` | As system. |
| read error | — | — | (UC E3) `MxErrorState` "Couldn't open Settings" with Retry. |

Goldens: `test/features/settings/presentation/goldens/settings_theme_{system,light,dark}_{light,dark}.png`.

## Rulings

- **D7 (owner):** the screen is titled "Theme" with no overline; the choices are "System", "Always light", "Always dark".
- **Build audit 2026-09-26, UI-base row 127:** the three cards go one per line when a word of a name or hint would not fit its third (large text, Vietnamese).

## Copy

"Theme" · "System" · "Match phone" · "Light" · "Always light" · "Dark" · "Always dark" ·
"Applies at once — no restart, and you stay where you are." · "Couldn't change the
theme." · "Retry".
