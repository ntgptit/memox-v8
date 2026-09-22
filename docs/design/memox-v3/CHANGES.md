# Changes after the split

These Markdown files started as a verbatim split of `memox-v3-flutter-handoff_3.json`
(`tools/split_handoff.py`). They are now the working source for V8: `spec.js`, the
generator behind the JSON, is not available, so the JSON is no longer regenerated.

- **Do not re-run the split script into this directory.** It would overwrite the edits below.
- `99-traceability.md` (SHA-256, character counts) describes the original split, not the edited files.
- `00-index.md` is unchanged and still lists the widgets, sections and actions of the original.

## 1. Contrast tokens (P0)

Every ratio was computed from the values in `01-foundations.md`, on the page, card and
input-fill surfaces of both themes, and on the 12–18% tints where a tint is used.

| Token | Light | Dark | Change | Worst case |
|---|---|---|---|---|
| `warning-text` | `#8F5800` | `#FFC658` | **new**; replaces `on-warning` as the ink for warning text | 5.35:1 light, 7.26:1 dark |
| `on-warning` | `#3A2A00` | `#2A1E00` | unchanged value; now the ink on a warning **fill** only, no text consumer | — (was 1.04:1 as dark text) |
| `inversePrimary` | `#A6B2FF` | `#A6B2FF` | now invariant, like `inverseSurface` (dark was `#5265F5`, 2.40:1) | 5.52:1 on `#34395D` |
| `status-learning-text` | `#8F5800` | `#FFC658` | **new**; learning label text | 5.35:1 light, 8.43:1 dark |
| `status-new-text` | `#5F688F` | `#909AC8` | **new**; new label text | 4.86:1 light, 5.42:1 dark |
| `outline` | `#7C85AB` | `#5A6BAE` | unchanged value; now also the input border and the Toggle off track | 3.29:1 light, 3.02:1 dark (on the input fill) |

`status-learning`, `status-new` and `warning` keep their values; they remain the fill, dot and glyph colours.

## 2. Bindings changed

| Component slot | Was | Now |
|---|---|---|
| `FieldMessage` warning text | `on-warning` | `warning-text` |
| `WorkloadBreakdownLine` overdue term | `on-warning` | `warning-text` |
| `WorkloadBreakdownLine` new term | `status-new` | `status-new-text` |
| `StatusBadge` new label | `status-new` | `status-new-text` |
| `StatusBadge` learning label | `status-learning` (shared with the dot) | `status-learning-text` (dot stays `status-learning`) |
| `MasteryDonut` `< 34%` label | `status-learning` (shared with the arc) | `status-learning-text` (arc stays `status-learning`) |
| `TextField` and `SearchField` resting border | `border-ghost` | `outline` |
| `Toggle` off track | `surfaceContainerHighest` | `outline` |
| `Toggle` thumb | `surfaceBright` | `surfaceBright` (light) / `onSurface` (dark) |
| `Snackbar` action label | `inversePrimary` | unchanged binding, new invariant value |

Registry views in `02-theme-binding.md` (value list, per-token usage, consumers by token) and the
token lists at the end of each affected widget were updated to match.

## 3. Decisions to know about

- **`MasteryDonut` no longer paints arc and label in the identical colour.** The old rule
  ("arc and label always share one colour") cannot hold with a text-grade label: the amber fill is
  2.15:1 as text on light. Number and ring now share the hue family.
- **Dark `Toggle` thumb is `onSurface`.** `surfaceBright` on the dark outline track is 2.65:1;
  `onSurface` is 4.15:1.
- **Progress tracks were not recoloured.** A 4px track (`StudyTopBar`) or 5px bar (`MasteryRamp`)
  cannot carry a legible 1px edge, and a solid `outline` track would overpower the fill.
  `01-foundations.md` now states the rule instead: progress is carried by the fill plus a text or
  semantic value, never by track colour alone.

## 4. Still open (not part of this patch)

- The learning-amber fill against the progress track is 1.73:1, so a `< 34%` bar is weak without a text value.
- Dark `outline` on the input fill is 3.02:1, only just above the 3:1 line. `#6C7DC0` would give 3.89:1.
- ~~`reviewing` text `#5265F5` on the 14% active-nav pill is 3.85:1.~~ Resolved in fix-loop item 4 (the finding was mislocated: see below).
- The contradictions between files listed in the critique (AppBar title 16 vs 20, `ListRow`, input 52, track token, tracking values) are untouched.

## 5. Fix loop (see `FIX-QUEUE.md`)

### Item 1 · touch areas (`adapt`)

The audit reported three components failing the 48 floor. Only one was real:

- `SegmentedTray`: had no touch row at all. Added `touch area MINIMUM 48 tall` (a band around each painted option, bands meet at the middle of the 2 gap).
- `Stepper` and `SelectionCheckbox`: already had the row (`tap area MINIMUM 48 per button`, "the whole row is the target") but under the label `tap area`, which the Self-check does not recognise. Renamed to `touch area` and, for the checkbox, added "at least 48 tall".
- All three Self-check `touch geometry` lines now read PASS.

### Item 2 · accessible names and state (`harden`)

Added an `## Accessibility contract` section (before `## Theme consumption`) to seven widgets:

- **Required accessible name:** `IconButton` (plus tooltip), `StudyTopBar` close, `AppBar` leading and trailing actions, `Stepper` buttons. The name is caller-owned copy, never derived from a glyph name; the glyph is excluded from semantics.
- **State or value exposed:** `Toggle` (switch, On/Off), `SelectionCheckbox` (checked/unchecked), `Stepper` (adjustable value, disabled at the bounds, invalid message), `MasteryDonut` (one element whose value is the percentage), `StudyTopBar` progress ("N of M" as the value, not the fill).

### Item 3 · reduced motion (`animate`)

- `01-foundations.md`: new `## Reduced motion` section, one global policy for Android "Remove animations" (translate, scale and size are removed; appear and disappear become an opacity fade; loops stop on a static frame; focus, selection and error never rely on movement).
- `02-theme-binding.md` "Global state semantics": the global layer now owns four things (disabled, pressed, focused, reduced motion); components reference the policy and never read the setting.
- 12 widgets (`bottom-sheet`, `button`, `dialog`, `error-state`, `footer-bar`, `list-row`, `scrim`, `snackbar`, `spinner`, `stepper`, `study-top-bar`, `toggle`): a one-line `## Reduced motion` section each, stating that widget's behaviour. The spinner users follow the `Spinner` rule (static arc, still exposed as busy). `skeleton.md` already had its own row and is unchanged.

### Item 4 · contrast and tokens (`colorize`)

- **BottomNav active state.** The audit said the active label sat on the 14% pill at 3.85:1. It does not: the pill is behind the glyph only (`bottom-nav.md`), and the label sits on the glass bar, where `primary` `#5265F5` is 4.39:1 on the page colour (below 4.5:1 at 12/600). Fix: the pill is now a solid `primaryContainer` (no alpha, so its colour no longer depends on what scrolls under the glass) and glyph and label use `onPrimaryContainer` (12.3:1 light, 14.4:1 dark on the page; glyph 10.4:1 / 8.8:1 on the pill). Registry: `primary` loses those two consumers; `primaryContainer` and `onPrimaryContainer` gain them.
- **One track token.** `StudyTopBar` (was `surfaceContainer` in its dimension row) and `MasteryDonut` (was `surfaceContainer` in its binding) now both use `progress-track`, matching `MasteryRamp`. Registry consumers updated.
- **Amber fill rule.** New `## Fill and track contrast` section in `mastery-ramp.md`: the `< 34%` fill is 1.73:1 against the track, so the percentage or count is always also text or the accessible value.
