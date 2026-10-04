---
id: SCR-SETTINGS-003
name: Theme
domain: settings
status: ready
route: [/settings/theme]
---

# Theme

## Purpose

The app's theme: follow the phone, always light or always dark. A tap applies it at once, and the
page stays open. On the root navigator with no bottom bar; opened from the Theme row of Settings
(SCR-SETTINGS-002).

## Related Use Cases

- UC-SETTINGS-001

## Layout

- **App bar** — back and "Theme"; no overline.
- **Cards** — three cards, each with a preview, then "System" / "Match phone", "Light" / "Always
  light", "Dark" / "Always dark", and a check and a selected ring on the chosen card. The preview
  paints the light and dark themes' own colours; System is split in half. The three cards go one per
  line when a word of a name or hint would not fit its third (large text, Vietnamese).
- **Note** — a hint note: "Applies at once — no restart, and you stay where you are."
- **Toast** — "Couldn't change the theme." · Retry; the stored choice stays selected.

## States

### `system` · System

Golden: light, dark

### `light` · Always light

Golden: light, dark

### `dark` · Always dark

Golden: light, dark

### `read_error` · Read error

"Couldn't open Settings" with Retry.

Golden: none — no golden in V8 (record 25)

## Controls

### Current theme

- Type: read
- Invokes: FN-SETTINGS-001

### System, Light, Dark cards

- Type: selectable cards
- Invokes: FN-SETTINGS-003

#### On success

- The theme applies at once; the page stays open.

#### On failure

- The toast with Retry; the stored choice stays selected.

### Retry (toast, `read_error`)

- Type: toast action / button
- Invokes: FN-SETTINGS-003, FN-SETTINGS-001

## Responsive Behavior

The three cards go one per line when a word would not fit its third. Otherwise follows the shared
floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Each card is one TalkBack node, "selected" when chosen.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A choice applies at once, with no restart and no lost place. | — |
| A failed change keeps the stored choice selected. | — |

## Copy

"Theme" · "System" · "Match phone" · "Light" · "Always light" · "Dark" · "Always dark" · "Applies at
once — no restart, and you stay where you are." · "Couldn't change the theme." · "Retry" ·
"Couldn't open Settings".

## Rulings

- **D7 (owner):** the screen is titled "Theme" with no overline; the choices are "System", "Always
  light", "Always dark".
- **Build audit 2026-09-26, UI-base row 127:** the three cards go one per line when a word of a name
  or hint would not fit its third (large text, Vietnamese).
- **Critique 2026-09-30 part 3a:** the note is the footnote form Language and Settings use.
