# Whole-app critique 2026-09-30, part 3b: a number stated once — design

Status: approved 2026-09-30 ·
Path: architectural (a DESIGN.md rule applied across seven screens) · Owner rulings 2026-09-30 (§2): R1–R6

## 1. Intent

The critique of 2026-09-30 scored Aesthetic and Minimalist Design 3 of 4: "the same number
repeated 3–4x on many screens". DESIGN.md already says "Do state a number once per screen"
(the Don'ts list), but gives no way to decide which place keeps the number, so screens
drifted. Part 3a is done; 3b makes the rule decidable and applies it to the seven screens
the critique names outside study: 01, 06, 07, 11, 14, 22 and 28.

Success means:

- DESIGN.md states where a number lives and the exceptions, so a reviewer can apply it;
- every item in §4 is built as written, each pinned by a widget test or a golden;
- nothing changes a layout beyond what the item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review
  page; `dod_check.sh` passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file. The
numbers a BR, UC or IT scenario requires stay (§3, "Kept").

## 2. Owner rulings (2026-09-30)

- **R1.** Scope: 01, 06, 07, 11, 14, 22, 28. Session summary (21) and Study home go to 3c;
  flows (Learn offered twice on 14) to 3d.
- **R2.** Approach: sharpen the DESIGN.md rule, then apply it screen by screen.
- **R3.** 07: a card row drops the status dot and keeps the coloured status label.
- **R4.** 06: the selection bar keeps "Restore ({n})" · "Delete ({n})" (owner 2026-09-26,
  H/06:68): a bulk action names its scope.
- **R5.** 14: the start button keeps its count ("Review 12 due cards"); the caption under it
  drops it.
- **R6.** 28: a Level chip names one or two chosen levels and counts from three; the
  Not sent note drops its number (the tab states it); the Not sent list gets a header
  counting the rows shown.

## 3. The rule (DESIGN.md, replacing the one-line Don't)

A number has one home on a screen: the element that explains it (a hero, a tile, a filter
chip, the app bar title).

- **Buttons** name the action. A button carries a count only when that count is what the
  action acts on and no other element states that total: "Study this deck · 4 due" (the
  hero lists the parts, not the total), "Import 1 card" (what will be written, which can
  differ from Ready), "Review 12 due cards" (the session's size, R5), a bulk action's
  "({n})" (R4).
- **A caption under a button** never repeats the button's number.
- **A list header** counts only when no hero, title or chip above already states the same
  number.
- **While selecting**, the selected count lives in the app bar title only.
- **A row** states a status once: a coloured label, not a dot beside it.
- **Kept, because a rule requires them:** the filter chips' counts on 07 (IT-ORG-005,
  BR-CARD-012), the NEW and DUE tiles and each mode's count on 14 (UC-STUDY-001 step 1,
  BR-STUDY-044), the selected count (UC-CARD-001 A6), the preview counts on 11
  (UC-TRANSFER-001 step 5), the two ranges on 22 (BR-PROGRESS-003).

## 4. Items

### 4.1 Screen 01, Library (open deck)

- The sub-deck list header drops its count when the summary card is shown: "Sub-decks"
  (the card says "2 sub-decks · 6 cards"). The root keeps "{n} decks" (no card counts them);
  level 10 keeps its depth header.
- The summary card's breakdown wraps between whole terms instead of ending in "…", as the
  Wrap Rule says (`canWrap: true`). H/01:72, which says it ellipsizes, is corrected.
- Kept: "Study this deck · {n} due" and a sub-deck row's "{n} due" (its own scope).

### 4.2 Screen 07, Card list

- The list header reads "Cards" when the list shows every card of the deck, and "Showing
  {n} of {total}" only while a filter, a tag or search narrows it.
- While selecting, the header row is gone: the app bar says "{n} selected" and the button
  "Select all {total}".
- A card row drops its status dot (R3); the status label keeps its ink colour, and the text
  column starts at the row's padding.
- Kept: the chips' counts, "Study this deck · {n} due".

### 4.3 Screen 06, Trash

- While selecting, the header states the kind's total, "{total} cards" or "{total} decks",
  not "{n} of {total}": the title says "{n} cards selected".
- Kept: "Restore ({n})" · "Delete ({n})" (R4); the purge dialog's count (BR-TRASH-011).

### 4.4 Screen 11, Import

- The preview header drops "{ready} of {total} rows ready": the chips carry the breakdown.
- The caption under Import is shown only when nothing can be imported ("No row will be
  imported.", which says why the button is locked); otherwise the button says it.
- The file line counts data rows: with "First row is a header" on, the header row is not a
  row ("CSV · 5 rows · 3 columns" for a six-line file with a header), so it agrees with the
  preview.
- Kept: the chips, "Import {n} card(s)".

### 4.5 Screen 14, Study entry

- The review caption drops the count: "{mode} · oldest first" (R5). The sm2 caption "{shown}
  of {due} due · oldest first" stays: it says the session limit cut the queue.
- Kept: the NEW and DUE tiles, each mode's count, the start button's count.

### 4.6 Screen 22, Progress

- The deck list header drops the range the segment above states: "By deck" and
  "Sub-decks".
- The footer drops the once-a-day rule the Today card states: "Read-only · resets change
  nothing here".

### 4.7 Screen 28, Monitoring

- While the Status filter holds a single status, rows drop their status badge (the chip and
  the header say it); with both statuses chosen, rows keep it.
- A chip names its choice when one or two are chosen ("Level · Error, Warning") and counts
  from three ("Level · 3"). The Level and Category chips share this label rule
  (`monitoringChipLabel`), so both follow it. TalkBack already reads every name.
- The Not sent note drops its number: "These logs wait on this device. They are sent when
  MemoX is online." The tab keeps "Not sent ({n})".
- The Not sent list gets a header counting the rows it shows at the chosen levels: "{n} at
  these levels".

## 5. Verification

- A test written first for each behaviour change: the 01 header and the wrapping
  breakdown, the 07 header (unfiltered, filtered, selecting) and the dot-free row, the 06
  selecting header, the 11 header, caption and file line (with and without a header row),
  the 14 caption, the 22 header and footer, the 28 badge, chip, note and header.
- vi strings for every changed key, with a vi test where a plural changes.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare`
  page before merge.
- `dart format`, `flutter analyze`, the architecture check, the guard, the full
  `flutter test` with goldens, and `dod_check.sh`.

## 6. Records

- DESIGN.md: the rule (§3).
- Detail files 01 (header, wrap, H/01:72), 06, 07, 11, 14, 22, 28.
- `docs/wbs_FE.md`: a line FE-D10 for part 3b.

## 7. Out of scope

Part 2 (typography), 3c (Session summary, Study home), 3d (flows, including Learn offered
twice on 14), and every number a rule requires (§3, "Kept").
