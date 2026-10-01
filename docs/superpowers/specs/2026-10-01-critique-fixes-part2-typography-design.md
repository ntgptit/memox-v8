# Whole-app critique 2026-09-30, part 2: label roles — design

Status: draft 2026-10-01 ·
Path: architectural (text styles in `lib/core/theme`, two shared widgets, about twenty call sites) ·
Owner rulings 2026-10-01 (§2): P1–P4

## 1. Intent

DESIGN.md allows the all-caps section label (13/700, 0.6 tracking, onSurface) only "to introduce a
list or settings group and nowhere else". The app uses that one style for three jobs: a group
title, the label of an input, and the context line above a big title or number (an eyebrow). The
critique of 2026-09-30 found:

- stacked caps with no hierarchy (card edit: "OPTIONAL DETAILS" › "EXAMPLE SENTENCE" › field);
- the Study home "WAITING FOR YOU" borrowing `requiredMarker` (the card field's "Required" style);
- user data upper-cased: "REVIEW SESSION · NHÀ HÀNG", the session context line's deck name, and
  "RESULTS FOR “HỌC”" on search.

Part 1 (R2) deferred this split to its own spec. This is that spec.

Success means:

- every call site in §3 uses the role §3 names, pinned by a widget test or a golden;
- no user-entered text is upper-cased anywhere;
- no layout change beyond the line heights the new sizes bring;
- goldens regenerated in the Linux container and reviewed by the owner on a golden review page;
  the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a screen's detail file. No BR or UC
fixes a label style. The proposal page of 2026-10-01 showed the current goldens beside the
options.

## 2. Owner rulings (2026-10-01)

- **P1.** Three roles. **Section label** stays as it is and only introduces a list or settings
  group. **Eyebrow** is the context line above a big title or number. **Field label** names an
  input or a read-only field.
- **P2.** Eyebrow, option A: 12/600, 0.8 tracking, onSurfaceVariant. The app's own words are
  upper-cased; user data keeps the case it was typed in.
- **P3.** Field label: 14/600 onSurface, sentence case. "Required" is a caption in primary ink,
  sized like the "· optional" caption, not an all-caps overline.
- **P4.** Never upper-case user data. Search drops its "Results for “…”" header: the search field
  already shows the term.

## 3. Items

### 3.1 Text styles (`MxTextStyles`)

- `overline` stays (13/700, 0.6, tabular, onSurface). Its doc names one job: the section label.
- New `eyebrow`: the label-small role at 600, 12, 0.8 tracking, tabular, onSurfaceVariant. The
  caller upper-cases the app's own words; never user data.
- New `fieldLabel`: 14/600, onSurface, sentence case.
- `requiredMarker` becomes `rowDescription` in primary ink: the same size as the "· optional"
  caption it pairs with.
- `statLabel` becomes the eyebrow.
- `compactOverline` is removed; its callers become eyebrows (already 12).
- `statusLabel` (a card row's status, the Recall and Fill tags) and the study top bar's mode pill
  keep their own styles: they are status chips, not labels.

### 3.2 Section labels (unchanged)

`MxListSectionHeader`, `MxSection`'s title, the card history's cycle headers (10), "Optional
details" on the card editor (08/09), and the tags list's sort label (05).

### 3.3 Eyebrows

App words upper-cased, muted, 12/600:

- `MxDotOverline` ("CONTINUE STUDYING", 13);
- Study home's workload block ("WAITING FOR YOU", 13): eyebrow instead of `requiredMarker`; its
  glyph follows the eyebrow's colour;
- Study entry's hero overline (the algorithm, 14);
- Session summary's hero overline (21): "REVIEW SESSION · Nhà hàng";
- the session context line (16–20): "Nhà hàng · REVIEW · ROUND 1";
- the study face card's labels ("TERM", "MEANING") and Browse's label (16–20);
- the card schedule card's title (10);
- Progress: the Today card's label and the streak labels (22);
- the deck summary card (01) and the card list's deck summary (07);
- `MxStatTile`'s label.

### 3.4 Field labels

Sentence case, 14/600, no upper-casing:

- the card editor's field headers (08/09): "Front · Term" with the Required caption, "Example
  sentence" with "· optional";
- the card editor's Tags header (08/09);
- the tag rename dialog's "New name" (05);
- the starter algorithm sheet's label (03): "Review algorithm" with the Required caption. The
  copy "Review algorithm · required" splits into the label and the caption;
- the card detail's read-only field labels (10).

### 3.5 User data keeps its case

- Session summary and the session context line upper-case the app's words around the deck
  name and leave the name as typed. A study-feature helper builds the string with a placeholder
  for the name, upper-cases the template, then puts the name back. Screen readers keep reading
  the plain sentence.
- Search drops `MxListSectionHeader(label: searchResultsFor(term))`; the "Decks" and "Cards"
  section labels stay. The `searchResultsFor` key goes from both ARBs.

## 4. Verification

- A test written first for each behaviour:
  - the three styles' values and `requiredMarker` matching the optional caption's size;
  - each role at its call sites, by the style the widget draws;
  - the summary and the context line showing "Nhà hàng" as typed beside upper-cased app words,
    in English and Vietnamese;
  - search with no results header;
  - the starter sheet's split label.
- Goldens regenerated in the Linux container; the owner reviews them on a `golden-compare` page
  before merge.
- The gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `TZ=UTC flutter test --tags golden`.

## 5. Records

- DESIGN.md Typography: the Section Label, Eyebrow and Field Label roles with their values, and
  the rule that user data is never upper-cased. The Don't on all-caps overlines names the eyebrow
  as the one allowed context line above a title or number.
- Detail files of the changed screens (01, 03, 04, 05, 07, 08, 09, 10, 13, 14, 16–21, 22): one
  ruling line each.
- `docs/wbs_FE.md`: a row FE-D13 for part 2.

## 6. Out of scope

3c-2 (the session screens' other findings, including the context line's length), 3d, and any
change to body, title or number styles.
