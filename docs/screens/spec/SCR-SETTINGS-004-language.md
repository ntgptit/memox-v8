---
id: SCR-SETTINGS-004
name: Language
domain: settings
status: ready
route: [/settings/language]
---

# Language

## Purpose

The app's language: follow the phone, English or Tiếng Việt. A tap applies it at once, and the page
stays open. On the root navigator with no bottom bar; opened from the Language row of Settings
(SCR-SETTINGS-002).

## Related Use Cases

- UC-SETTINGS-001

## Layout

- **App bar** — back and "Language".
- **Rows** — a section of three radio option rows, with the note as the section's note: "Follow the
  system" with what it resolves to now — "Phone is set to English", "Phone is set to Tiếng Việt", or
  "Your phone's language isn't available · English"; "English"; and "Tiếng Việt" with its name in the
  current language ("Vietnamese"). A sub-line that repeats the title is left out.
- **Note** — "Applies at once — no restart, and you stay where you are. Your cards stay in their own
  language."
- **Toasts** — after a switch, in the new language: "Switched to English" or "Đã chuyển sang Tiếng
  Việt". "Couldn't change the language." · Retry; the stored choice stays selected.

## States

### `english` · English

English has no sub-line.

Golden: light, dark

### `vietnamese` · Tiếng Việt

The toast reads in Vietnamese.

Golden: light, dark

### `system` · Follow the system

The line names what the system choice resolves to.

Golden: light, dark

### `read_error` · Read error

"Couldn't open Settings" with Retry.

Golden: none — no golden in V8 (record 26)

## Controls

### Current language

- Type: read
- Invokes: FN-SETTINGS-001

### Follow the system, English, Tiếng Việt

- Type: radio option rows
- Invokes: FN-SETTINGS-004

#### On success

- The language applies at once; the toast in the new language; the page stays open.

#### On failure

- The toast with Retry; the stored choice stays selected.

### Retry (toast, `read_error`)

- Type: toast action / button
- Invokes: FN-SETTINGS-004, FN-SETTINGS-001

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A choice applies at once, with no restart and no lost place. | — |
| Changing the language never changes card content. | — |
| The system row says what it resolves to now. | — |

## Copy

"Language" · "Follow the system" · "Phone is set to {language}" · "Your phone's language isn't
available · English" · "English" · "Tiếng Việt" · "Vietnamese" · "Applies at once — no restart, and
you stay where you are. Your cards stay in their own language." · "Switched to English" · "Đã chuyển
sang Tiếng Việt" · "Couldn't change the language." · "Retry" · "Couldn't open Settings".

## Rulings

- **D8:** the system row says "Phone is set to {language}"; the fallback line shows only for a
  language the app lacks.
- The choices are radio option rows, the app's single-choice list; the note is the section note (M3
  review 2026-09-28 D4).
- **Critique 2026-09-26:** a row has no sub-line when it would repeat the title.
