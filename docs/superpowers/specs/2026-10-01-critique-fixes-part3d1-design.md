# Whole-app critique 2026-09-30, part 3d-1: per-screen flows — design

Status: draft 2026-10-01 ·
Path: architectural (seven screens, no new shared widget) ·
Owner rulings 2026-10-01 (§2): D1–D5

## 1. Intent

Part 3d takes the critique's per-screen findings that parts 1 to 3c-2 left open. An audit of
2026-10-01 checked every per-screen finding against the code at `be53e981`: most were done or
ruled, and about 35 remain. The owner split them (D1): 3d-1 takes the ones that change a flow
or hide something a person needs; 3d-2 takes the low-impact and cosmetic ones.

The 3d-1 findings:

- 14: with only new cards, Learn is offered twice: the Learn row's button and the footer's
  primary "Learn 20 new cards".
- 07: while searching with the keyboard up, the add FAB covers a row's due badge.
- 07: a failed bulk flag says "Couldn't finish that." with no way to try again.
- 09: editing a card, Save is live before anything changed.
- 15: a failed save is told only in the footer's muted caption.
- 22: a deck row opens its own level but shows no chevron; "26 cards" sits beside
  "16 learning · 72 reviewing", which are card-days, so 72 > 26 reads as an error; a person who
  never studied gets a grey "Start studying".
- 06: the purge-blocked and kind-lock notices come after the list, far from the rows they are
  about once the list is long.
- 27 and 23: syncing shows an empty box with a faint spinner and no word; on 23 a failed or
  refused sync is the same grey as a quiet one.

Success means:

- every item in §3 is built as written, each pinned by a widget test or a golden;
- no layout change beyond what an item names;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review page;
  the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file.
BR-PROGRESS-001 fixes the four numbers of a Progress row (unique active cards, active days,
learning and reviewing card-days): §3.6 relabels them and keeps all four. BR-TRASH-011 keeps
the kind lock (§3.7 moves its note only).

## 2. Owner rulings (2026-10-01)

- **D1.** 3d splits into 3d-1 (this spec) and 3d-2 (low-impact and cosmetic findings), each
  with its own spec, plan and golden review.
- **D2.** 14: with only new cards, the footer keeps Learn and the Learn row drops its button.
  When a review leads the footer, the row keeps its button.
- **D3.** 22: a deck row puts its card count in the meta line, labels the card-days, and ends
  in a chevron. The total row "All decks" opens nothing and has no chevron.
- **D4.** 06: the purge-blocked banners and the kind-lock note move above the list.
- **D5.** 27: while syncing, the screen says "Syncing…" beside the spinner. 23: the Sync row's
  icon tile takes the warning tone when the last attempt failed or a change was refused.

## 3. Items

### 3.1 Study entry, Learn once (14, D2)

- `StudyEntryLearnWidget` draws no trailing button when `entryFooterActionOf(offer)` is
  `EntryFooterAction.learn`: the footer already offers it. The row keeps its title and line.
- With a review in the footer (`EntryFooterAction.review`), the row keeps its "Learn" button
  as today.
- `expectOnePrimaryPerDecision` and a new test pin one Learn action on the only-new screen.

### 3.2 Card list, FAB while searching (07)

- `CardAddFabWidget` hides while card search is open (`cardSearchOpenProvider`), as it does
  while selecting. Search is for finding; adding waits until search closes.

### 3.3 Card list, retry a failed bulk flag (07)

- The bulk-failure banner gains a "Retry" action (`commonRetry`) that repeats the same
  write: the same cards and the same flag choice, without reopening the sheet. The banner goes
  while it runs and returns if it fails again.
- The banner's copy stays: "Couldn't finish that." · "Nothing changed. The cards stay
  selected."

### 3.4 Card edit, Save waits for a change (09)

- In edit, Save is enabled only when the draft differs from the saved card (the same
  comparison the discard dialog uses, `_isDirty`). Create is unchanged.
- The caption keeps "cardCaptionEdit" while nothing changed.

### 3.5 Study options, a failed save is visible (15)

- When the save failed, a danger `MxInlineBanner` sits at the top of the body, above the
  fields: title "Not saved", message the existing `studyOptionsSaveFailed` text ("Couldn't
  save. The deck still uses {count} cards, {order}."). The footer button keeps "Retry save",
  and its caption returns to "Saved to this device only."
- vi title: "Chưa lưu".

### 3.6 Progress rows (22, D3, BR-PROGRESS-001)

- A deck row: the deck name; meta line 1 "{n} cards · {d} active days"; meta line 2
  "Card-days: {l} learning · {r} reviewing" (learning in the learning ink, reviewing in the
  primary ink, as today); a trailing chevron. vi: "{n} thẻ · {d} ngày có học" and
  "Lượt theo ngày: {l} học mới · {r} ôn tập".
- The total row "All decks" has the same two lines and no chevron (it opens nothing, FE-A9 D2).
- An idle deck keeps "No activity in this range" and its chevron (it still opens its level).
- The never-studied card's "Start studying" is the primary tone: it is the screen's only action
  (One Indigo).
- The four numbers stay; nothing else is added (BR-PROGRESS-001).

### 3.7 Trash notices above the list (06, D4)

- The kind-lock note (`trashKindLock`, while selecting) and the purge-blocked warning banners
  sit right under the retention note, above the kind chips, in the same order as today.
- Their copy is unchanged.

### 3.8 Sync status (27, 23, D5)

- 27: while the manual sync runs, the button's place shows a row of the spinner and
  "Syncing…" (vi "Đang đồng bộ…"), at the button's height, announced as a live status.
  When it ends, the button comes back.
- 23: the Sync row's icon tile is `MxIconTileTone.warning` when the last attempt failed
  (`lastFailure != null`) or a change was refused (`rejectedCount > 0`); success when settled
  (tone pass T4); tinted otherwise. One predicate, `syncNeedsAttention`, beside
  `syncIsSettled`.

## 4. Verification

- A test written first for each behaviour:
  - 14: only-new shows one Learn action; with a review, the row keeps its button;
  - 07: the FAB is absent while search is open and back when it closes; "Retry" repeats
    the flag write with the same cards and choice;
  - 09: Save is disabled on a pristine edit and enabled after a change; create unchanged;
  - 15: a failed save shows the danger banner with the stored values; the caption is the
    local-only line;
  - 22: a deck row's two meta lines and chevron, the total row without one, the primary
    "Start studying", in English and Vietnamese;
  - 06: the notices come before the first entry row;
  - 27: "Syncing…" shows while running and the button returns after; 23: the tile tone per
    status (settled, failed, refused, pending, never synced).
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare` page
  before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md: none beyond the Progress row line in the 22 detail file, unless the plan finds a
  shared rule touched.
- Detail files 06, 07, 09, 14, 15, 22, 23 and 27: one ruling line each.
- `docs/wbs_FE.md`: a row FE-D15 for part 3d-1.

## 6. Out of scope

3d-2 (the low-impact findings: 01 sort wording and reorder search, 02 inert strip hero and reset
tone, 03 facts line and lock warning, 05 empty state and delete-dialog card, 08 tag commit,
10 history badge and Algorithm tile, 11 duplicates toggle and source card, 12 stale copy,
24 minute "00", 28 repeats, skeletons, `MxEmptyState`'s warning ink), and anything a BR fixes.
