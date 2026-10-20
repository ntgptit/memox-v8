# Type scale A and one hierarchy across the app

Status: approved by the owner on 2026-10-20 (decisions T1–T3 below).
Tier 1 at least: it changes `lib/core/theme/` and `lib/shared/`; it reaches
every screen through the scale, so every golden moves.

## 1. Problem

The owner: "Cần kiểm soát lại font size toàn app, tránh cùng 1 cấp bậc mà chỗ
chữ to, chữ bé, chỗ thì chữ đậm chữ nhạt", then "đừng để quá to so với app".

An audit of every `context.texts.<role>` and every ForUI text slot found:

- No raw size or weight anywhere: The Twelve Roles Rule holds. The drift is
  in which role a level picks, and in ForUI's own slots.
- The scale reads large on a 360dp phone: body 14, row titles 16, card
  headings 18, screen titles 20, figures 30.
- One level, several looks:
  - a row's title is `itemTitle` (16/500) in the shared rows and
    `sectionTitle` (18/600) in seven feature rows;
  - a row's metadata line is `body` (14/400) in deck and TOPIK rows and `meta`
    (12/500) in progress, starter and import rows;
  - a card's heading is `sectionTitle` in most cards and `itemTitle` in six;
  - a sheet's title is `itemTitle` (16/500); a dialog's is ForUI's 18/600 at
    line height 1.25, under the 1.4 the scale keeps for Vietnamese marks;
  - "N selected" is `sectionTitle` on Trash and `itemTitle` on a deck;
  - an error state's title is `itemTitle`, an empty state's `sectionTitle`;
  - a field's supporting text and counter are ForUI's 14/400 while its error
    is `caption` 12/400;
  - the tab bar's labels are ForUI's 10/400, bold when selected: no role;
  - a state change moves the weight as well as the colour: card history's
    moves and cycle marks (`body` ↔ `label`), the import preview's note
    (`body` ↔ `meta`), TOPIK's metadata lines in `label` where every other
    metadata line is `body`.

## 2. Decisions (owner, 2026-10-20)

| # | Decision |
|---|---|
| T1 | Scale A: `xs` 13, `sm` 15, `md` 16, `lg` 18, `xl` 20, `xl2` 26. `xs2` 12 and `xs3` 10 stay, and so does every line height. |
| T2 | One role per level (below). |
| T3 | The fixes in §4, in one pull request with a golden-compare page before the merge. |

The roles after T1:

| Role | Step | Size/weight | Level |
|---|---|---|---|
| figure | xl2 | 26/600 | a stat's value |
| term | xl | 20/500 | the word on a study face |
| termCompact | lg | 18/400 | a word on a match tile |
| screenTitle | lg | 18/600 | an app bar's title, "N selected" |
| sectionTitle | md | 16/600 | a card's or a frame's heading, a dialog's and a sheet's title, an empty or error state's title |
| itemTitle | sm | 15/500 | a row's title, a fact's value |
| content | sm | 15/400 | reading text, a field's value and hint |
| button | sm | 15/500 | a button's label |
| body | xs | 13/400 | running text, a note, a row's subtitle and metadata line, a fact's label |
| label | xs | 13/500 | a field's label, a chip, a banner, a toast |
| caption | xs2 | 12/400 | a field's supporting text, error and counter |
| meta | xs2 | 12/500 | an overline, a badge and its peers, a chart's labels, a count, a footer, a tab's label |

## 3. Conventions (T2)

1. **Metadata in a row is `body`.** `meta` is for an overline, a badge and
   what stands beside one (a time over a status badge), a chart's labels, a
   trailing count, a list's footer and a tab's label.
2. **A card's or a frame's heading is `sectionTitle`; a row's title is
   `itemTitle`.** A choice or source tile in a list is a row.
3. **A dialog's and a sheet's title are both `sectionTitle`**, at the
   scale's line height.
4. **A banner and a toast keep `label`; a bare note is `body`.**
5. **A state changes the colour, never the role.** A muted line and its
   warning form share a role.

## 4. Fixes (T3)

| # | Where | From → to |
|---|---|---|
| F1 | `app_typography.dart` | scale A; the roles' doc comments |
| F2 | theme: `dialogStyle` | title `sectionTitle` (16/600, 1.5) |
| F3 | theme: tab bar item | `meta` at rest and when selected (colour only) |
| F4 | theme: form field description and the text field counter | `caption` |
| F5 | `MxBottomSheet` and the three sheets that draw their own text heading (starter algorithm, export, merge choice); the tag-actions sheet's heading is its tag chip, on purpose | `sectionTitle` |
| F6 | `MxErrorState` | `sectionTitle`, as the regular empty state |
| F7 | seven feature rows (import mapping, import deck, import preview, import source option, the chosen source, card row front, starter template) | `sectionTitle` → `itemTitle` |
| F8 | six card headings (deck summary, due strip, lock strip, start over, card trash, study resume) and the importing card | `itemTitle` → `sectionTitle` |
| F9 | Trash's and a deck's "N selected" | `screenTitle` |
| F10 | row metadata: progress deck row, starter template facts and suggestion, the starter sheet's note | `meta` → `body` |
| F11 | card detail's fields | none: on reading, they are read-only fields (an example, a note: long text), not facts, so `label` over `body` stays; the schedule's short facts keep `body` muted over `itemTitle` |
| F12 | colour-only states: card history's moves and cycle marks, the import preview's note, TOPIK's attempt and answer metadata | one role, the colour changes |
| F13 | `DESIGN.md` Hierarchy prose; its frontmatter regenerated | conventions 1–5 |
| F14 | final review S1 (owner 2026-10-20): `MxEmptyState`'s compact title | `itemTitle` → `sectionTitle`, as the error state's |
| F15 | final review S2: Study entry's app bar title (`deck_study_header_widget.dart`) | `sectionTitle` → `screenTitle` |
| F16 | final review S3 (owner 2026-10-20): `MxWorkloadBreakdownLine`, a row's and a hero's metadata line | `meta` → `body` (the 2026-10-17 ruling set `meta`) |
| F17 | final review S4: Card list's deck hero line, as Library's | `body` → `sectionTitle` |
| F18 | final review N1: TOPIK type stats' trailing count | `label` → `meta` |

Left as they are: the breadcrumb's current crumb (`itemTitle` over `label` ancestors), read as a level of its own, not a state. Each classed by convention 1: overlines (uppercase), badges
and their peers (trash's time left, a log row's time, a history entry's time),
chart labels (the box ramp's ends, the score donut), counts (tags, the tag
filter, the import result), footers (no more users or servers, the level
list), timers (recall countdown, the audio bar, a resend timer), the sign-in
eyebrow and the session context line.

## 5. Verification

- `test/core/theme/app_typography_test.dart` (or the theme test that owns the
  scale) pins every role's size and weight; it fails before F1.
- A widget test per shared fix (F2–F6) pins the role the slot draws.
- Every golden moves (F1). Each screen's detail file that states a size is
  updated; the shared widget inventory's rows for the changed slots too.
- The golden-compare page goes to the owner before the merge.
