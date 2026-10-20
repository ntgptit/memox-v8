# Term line and Study entry hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No dot at a line break anywhere in the app, a breadcrumb that
never ends on "›", and a screen 14 that says what a second start does.

**Architecture:**
- One shared render widget, `MxTermLine`, lays out terms and draws a dot
  only between two terms on the same line.
- Every wrapping term line, and the two shared string slots that carry term
  lines, render through it.
- Screen 14 gains a section and a note while a session is open.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6, Riverpod.

**Spec:** `docs/superpowers/specs/2026-10-20-term-line-and-entry-hierarchy-design.md`

Execution: native (owner, 2026-10-20: "Duyệt, viết spec, plan và làm luôn").

## Global Constraints

- Session and SRS rules do not change (BR-STUDY-004, BR-STUDY-072,
  BR-STUDY-075).
- Spacing comes from `context.dimens` and text from the text roles, with
  `copyWith(color:)` only (the guard).
- `metaDots` phrase lines keep their rule (W2).
- The exact copy:
  - en "Or start another session" / vi "Hoặc bắt đầu phiên khác";
  - en "Starting one ends today's session. Its answers are kept." /
    vi "Bắt đầu phiên mới sẽ kết thúc phiên hôm nay. Câu trả lời được giữ lại.";
  - en "Continue where you stopped." / vi "Tiếp tục từ chỗ bạn đã dừng.";
  - en "Ends today's session" / vi "Kết thúc phiên hôm nay".

## Review Focus

1. A term wider than the whole line, such as a long deck name in a TOPIK
   meta line: it wraps at its own spaces and overflows nothing. Pinned in
   Task 1.
2. Text scale 1.3 at 360 dp on the deck rows: the dot never sits at an
   edge. Pinned in Task 2.
3. A list row that merges semantics (`MxListRow` with an `MxTermLine` meta):
   TalkBack reads the line once. Pinned in Task 1 (one node) and by the
   existing row tests.
4. RTL: the alignment follows `Directionality`. Pinned in Task 1.
5. A start refused while the session section shows: the banner sits above
   the section, under the Resume card. Pinned in Task 4.

---

### Task 1: `MxTermLine` and `breadcrumbLine`

- `lib/shared/widgets/mx_term_line.dart`:
  - `MxTerm`, `MxTermLine`, `MxTermLine.text`;
  - a `MultiChildRenderObjectWidget` laying out terms and dots. Each dot's
    `parentData` tells it whether it is shown; a hidden dot is laid out at
    zero size and not painted.
- `lib/l10n/meta_line.dart`: `breadcrumbLine`.
- Tests in `test/shared/widgets/mx_term_line_test.dart`:
  - a table of widths: at each break no dot is painted at a line start or
    end, read from the render's child offsets;
  - an over-long term;
  - lead and gap;
  - centre alignment;
  - RTL;
  - one semantics node with the joined line;
  - a line with no " · ".

### Task 2: `MxWorkloadBreakdownLine` on `MxTermLine`

- When `canWrap` is true, the spans path and the glyph statement build an
  `MxTermLine`. When it is false, the single line keeps its `Text` with an
  ellipsis.
- The existing tests hold, plus no edge dot at 360 dp and 1.3.

### Task 3: Every other wrapping term line

Each moves to `MxTermLine` or `MxTermLine.text`, by the classification:

- **Plain lines:** starter, import source, import mapping (through
  `MxSettingsRow`), deck tile meta and structure line, card history, card
  schedule, card tag editor, study home resume, study entry resume, study
  entry learn (the inner count), progress deck row, the TOPIK rows, hero,
  progress card and review question, and the settings rows.
- **Lead lines:** card add details and progress card-days.
- **Shared slots:** `MxSettingsRow.subtitle` and `MxFooterBar.caption`
  render with `MxTermLine.text`.
- Then remove `metaLine`, `metaTerms`, `wholeTerm`, `metaTermSeparator` and
  `metaTermDot`, and add them to `tools/design/removed_symbols.json` if that
  list covers `lib/l10n`.
- Use `breadcrumbLine` on the 13 Resume title. Test: the title never ends a
  line on "›".

### Task 4: Study entry with an open session (E1)

- `study_entry_body_widget.dart`:
  - after the Resume card and the banner, while `resumable` shows, add
    `MxListSectionHeader` "Or start another session" and an `MxNote`;
  - the Resume body becomes "Continue where you stopped.".
- `study_entry_footer_widget.dart`: the caption leads with "Ends today's
  session" while `resumable` shows.
- ARB keys in en and vi; run gen-l10n.
- Tests:
  - the section and the note only with a session;
  - the caption prefix for SM-2, Eight boxes and Learn;
  - Continue is the one primary;
  - the banner sits above the section (Review Focus 5).

### Task 5: Checks, docs, verification

- **Tests:**
  - 13 with a sync notice scrolled to the end: the last row ends above the
    notice, at scale 1 and 1.3;
  - the caught-up body follows `nextDueAt` (name the existing test, or add
    one).
- **Docs:**
  - `DESIGN.md`, The Wrap Rule;
  - the Q-P6-4 lines in the detail files (01, 03, 06, 13, 14, 22);
  - 14's Layout, States, Rulings and Copy;
  - `SHARED_WIDGET_INVENTORY`;
  - regenerate `docs/_generated` and the `DESIGN.md` frontmatter if it
    changed.
- **Gate and review:**
  - `run_goldens.sh --update`, then the full gate and goldens;
  - one Impeccable audit of 13 and 14;
  - the final Opus review, its fixes in one batch;
  - the golden-compare page; then the PR after the owner's approval.
