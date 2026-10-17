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
| Cards | `MxCard` (selected ring) + `MxRowInk` × 3 | A preview, then "System" / "Match phone", "Light" / "Always light", "Dark" / "Always dark", and a check on the chosen card. The preview paints Indigo Day's and Indigo Night's own colours; System is split in half. Each card is one TalkBack node, "selected" when chosen. |
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

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | the `app_settings` stream has not emitted | loading: `MxSkeletonList`, two rows | `UNVERIFIED (code read)`: `theme_screen.dart`; no test or golden pins it |
| loading | the stream emits | system / light / dark, the stored one selected | UC-SETTINGS-001 step 4. VERIFIED `theme_screen_test.dart::the stored theme is selected; a tap saves another and selects it (UC-SETTINGS-001 step 4)` |
| loading | the read fails | read error | UC E3. VERIFIED `::a failed read shows the error with Retry and no invented choice (E3)` |
| read error | Retry | error with Retry spinning, then the state the read gives | UC E3. The error is VERIFIED in the test above; the tap (`ref.invalidate(appSettingsProvider)`) is `UNVERIFIED (code read)` |
| system / light / dark | tap another card | the other card selected and the whole app, this page included, in the new theme; no toast; the page stays | BR-SETTINGS-005. VERIFIED `::the stored theme is selected; a tap saves another and selects it (UC-SETTINGS-001 step 4)`; `settings_controller_test.dart::theme and language are each one write; choosing the persisted value writes nothing` |
| system / light / dark | tap the selected card | no change, nothing written | VERIFIED `settings_controller_test.dart::theme and language are each one write; choosing the persisted value writes nothing` |
| any | a second tap while the write runs | ignored | UC A4. VERIFIED `settings_controller_test.dart::a second submit of a kind in flight is ignored (A4)` |
| any | the write fails | the stored card stays selected, toast "Couldn't change the theme." with Retry | UC E2. VERIFIED `theme_screen_test.dart::a failed save keeps the stored theme and offers Retry, which saves it (E2)` |
| any | Retry on the toast | the write runs again, then the card is selected | UC E2. VERIFIED same test |
| any | the toast's Retry after leaving the page | the write runs; the page is gone, so no result shows | `UNVERIFIED (code read)`: the snackbar's action closes over the page's `ref` |
| any | TalkBack activates a card | the same as a tap | VERIFIED `::TalkBack can choose a theme: the card keeps its tap` |
| any | large text or a long word | one card per line | UI-base row 127. VERIFIED `::at 1x the three cards sit side by side, as the kit draws them` for the row layout; the stacked layout is `UNVERIFIED (code read)` |
| any | Back | screen 23, whose Theme row reads the new choice | `UNVERIFIED (code read)`: the row is built from the same stream (`settings_app_section_widget.dart`) |

## Rulings

- **D7 (owner):** the screen is titled "Theme" with no overline; the choices are "System", "Always light", "Always dark".
- **Build audit 2026-09-26, UI-base row 127:** the three cards go one per line when a word of a name or hint would not fit its third (large text, Vietnamese).

## Copy

"Theme" · "System" · "Match phone" · "Light" · "Always light" · "Dark" · "Always dark" ·
"Applies at once — no restart, and you stay where you are." · "Couldn't change the
theme." · "Retry".
