# No dot at a line break; Study entry's other sessions

Status: approved by the owner (2026-10-20, "Duyệt, viết spec, plan và làm
luôn"). Tier 2: it changes a shared widget used by about 35 sites, The Wrap
Rule in `DESIGN.md`, and screen 14's layout and rulings.

## 1. Problem

The owner's review of the Study home goldens (2026-10-20, 8.4/10) found:

- **P1, wrap.** A line of terms that wraps leaves its dot at the end of the
  line: "3 overdue · 2 today ·" / "4 new". The Wrap Rule glues each dot to
  the term before it (`lib/l10n/meta_line.dart`, ruling Q-P6-4). Every
  wrapping meta line in the app shares the mechanism.
- **P1, breadcrumb.** The Resume title "{root} › {deck}" can end a line on
  "›" ("IELTS Academic Word List ›" / "Words").
- **P1, Study entry.** With an open session, screen 14 offers Continue,
  Learn and "Start a new review instead". That a new start ends the open
  session is said only in the Resume card's body.
- **P2, empty states.** The labels must follow the data, and "…due
  tomorrow" must come from the schedule.
- **P2, notice.** The floating sync notice must never hide the list's last
  row.

## 2. Decisions (owner, 2026-10-20)

| # | Decision |
|---|---|
| W1 | At a line break the dot is not drawn: "3 overdue · 2 today" / "4 new". A dot is drawn only between two terms on the same line. Fixed in one shared widget. |
| W2 | Phrase lines (`metaDots`: hints and descriptions whose phrases wrap as words) keep the current rule; putting them in whole-term units would leave wide gaps. They are named as the exception. |
| B1 | The breadcrumb's "›" is glued to the deck after it, so it never ends a line. The title stays one text of at most two lines. |
| E1 | With an open session, screen 14 groups Learn and the review options under "Or start another session", with a note on what that does. Continue stays the one primary. Session and SRS rules do not change. |

## 3. Design

### 3.1 `MxTermLine` (W1)

A new shared widget, `lib/shared/widgets/mx_term_line.dart`:

- `MxTermLine({required List<MxTerm> terms, InlineSpan? lead, double? leadGap,
  TextStyle? style, MxTermLineAlign align = start, String? semanticsLabel})`.
- `MxTermLine.text(String line, {TextStyle? style, …})`: splits a
  localized line at its plain " · " (the ARB form) into terms. A line with
  no " · " is one term and renders as a plain wrapping `Text`.
- `MxTerm`: the term's text, an optional style over the line's style, and
  an optional leading glyph (`IconData`, its colour).
- **Layout** (a `RenderBox` with term and dot children, like `Wrap`):
  - A term is placed on the current line when it fits at its natural one-line
    width after a dot; otherwise it starts the next line, and the dot
    between them is neither laid out nor painted.
  - A term wider than the whole line takes a line of its own and wraps at its
    own spaces.
  - Lines are as tall as their tallest child; children centre on the line
    (a glyph and its words).
  - `lead` (for example "Card-days:") comes first and is followed by `leadGap`,
    not by a dot.
  - Alignment is start or centre; it follows `Directionality`.
- **Semantics:** one node with the whole line ("3 overdue · 2 today · 4
  new"), or with `semanticsLabel`. The glyphs are decorative.
- `meta_line.dart` keeps `metaDots` (W2) and gains `breadcrumbLine` (B1).
  Once no caller is left, `metaLine`, `metaTerms`, `wholeTerm`,
  `metaTermSeparator` and `metaTermDot` are removed.

### 3.2 Sites

- **Every wrapping term line moves to `MxTermLine`** (the classification is in
  the plan):
  - plain `Text(metaLine(…))`;
  - the multi-colour lines in `MxWorkloadBreakdownLine` (its glyph statement
    and its spans);
  - `progress_deck_row_widget` and `card_add_details_widget` (with a `lead`).
- **Shared string slots that receive a term line** render it with
  `MxTermLine.text`: `MxSettingsRow.subtitle` and `MxFooterBar.caption`. A
  `metaDots` string has no plain " · " left, so it stays one term and wraps
  as before.
- **Single-line lines stay `Text`**: the gallery's `canWrap: false`
  breakdown and the two-line `MxActionSheetCommandRow.subtitle`.
- **`DESIGN.md` The Wrap Rule** reads: a line of terms wraps only between
  whole terms, and no dot stands at either end of a line. Phrase lines wrap
  as words, each dot kept on the word before it.

### 3.3 Breadcrumb (B1)

- `breadcrumbLine(String line)` replaces the space after each " › " with a
  no-break space, so "›" stays with the first word after it.
- The Resume title on 13 uses it. Other "›" strings are sentences (a
  settings path in a hint) and are unchanged.

### 3.4 Study entry with an open session (E1)

The order while the Resume card shows:

1. The hero.
2. The Resume card: the overline, the session line, the track, "Continue
   where you stopped." and Continue (primary block).
3. The refused or failed banner, if any.
4. `MxListSectionHeader` "Or start another session" ("Hoặc bắt đầu phiên
   khác").
5. `MxNote`: "Starting one ends today's session. Its answers are kept."
   ("Bắt đầu phiên mới sẽ kết thúc phiên hôm nay. Câu trả lời được giữ
   lại.").
6. The Learn row and the review options, as today.

The footer:

- Its button stays outline beside Resume.
- Its caption leads with "Ends today's session" ("Kết thúc phiên hôm nay"):
  - SM-2: "Ends today's session · {shown} of {due} due · oldest first".
  - Eight boxes: "Ends today's session · {mode} · oldest first".
  - Learn: "Ends today's session".

What does not change:

- Without an open session, screen 14 is unchanged.
- The nothing-due state is unchanged.
- The starts, the refusals and the lock (BR-STUDY-004) are unchanged.

### 3.5 Checks (no change expected)

- **Notice:** `MxAppShell` pads the body by the notice's measured height
  plus 16 (`mx_app_shell.dart`, `_NoticeLayer`). A screen test on 13 scrolls
  to the end with a sync notice and pins that the last row ends above the
  notice, at text scale 1 and 1.3.
  - The keyboard is N/A: 13 has no field.
  - The slot holds one notice, so notices never stack.
- **Empty states** (semantics, from the data):

| Label | Where | When |
|---|---|---|
| "Nothing due" | a deck row on 13 | the deck has cards; overdue, today and new are 0 |
| "No cards yet" | a deck row on 13 | the deck has no card (no target) |
| "Nothing due right now" | 13's workload card | no card is due: the caught-up card when nothing waits at all, the plain card when new cards wait |
| "Nothing to study yet" | 13, noDecks | the library has no root deck |
| "Nothing to do right now" | 14 | the deck has nothing new and nothing due |

- **Next due date:** the caught-up body ("…tomorrow", "…on {date}") reads
  `nextDueAt` from the study view DAO, the earliest scheduled `due_at`
  (BR-STUDY-074). A test pins it, or the existing one is named.

## 4. States and transitions

- **13:** the loaded, noResume, newOnly, zero and sync frames move only where
  a line wraps; no state or transition changes.
- **14, resume:**
  - The new section and note show under the Resume card.
  - The footer caption leads with "Ends today's session".
  - Transitions are unchanged: Continue, Learn and Review start as before.
- **Every screen with a wrapping term line:** the frames move where a line
  wraps; nothing else moves.

## 5. Verification

- **`MxTermLine` tests:**
  - no dot at a line's start or end, at widths that break between each pair
    of terms;
  - a term wider than the line wraps on its own;
  - lead and gap;
  - centre alignment;
  - one semantics node;
  - text scale 1.3;
  - a line with no " · ".
- **`MxWorkloadBreakdownLine`:** its existing tests hold, plus no edge dot.
- **13:** the Resume title never ends a line on "›", at a 360 dp phone and
  at a 1.3 text scale.
- **14:** the section and the note show only with an open session; the
  caption prefix; Continue stays the one primary.
- **Notice:** the last row clears the notice (§3.5).
- **Goldens:** rerendered and reviewed on the golden-compare page.
- **Review:** an Impeccable audit of 13 and 14, then the final review.
