# Critique 2026-09-30 part 3b: a number stated once — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every number on screens 01, 06, 07, 11, 14, 22 and 28 has one home, per a sharpened DESIGN.md rule.

**Architecture:** Copy and presentation changes only: ARB strings (en, vi), the widgets that render the repeated numbers, one shared label helper in Monitoring, and one derived row count in Import. No domain, data or schema change.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, ARB l10n (`flutter gen-l10n`), widget and golden tests (`libraryTest`, `pumpLibraryScreen`).

**Spec:** `docs/superpowers/specs/2026-09-30-critique-fixes-part3b-design.md`

## Global Constraints

- Authority: BR/UC > DESIGN.md > the screen's detail file (ADR-019). Kept numbers (spec §3): 07 chip counts, 14 NEW/DUE tiles and per-mode counts, the selected count, 11 preview chips and "Import {n} card(s)", 22 ranges, 06 "Restore ({n})" / "Delete ({n})", "Study this deck · {n} due", 14 "Review {n} due cards".
- No layout change beyond what an item names.
- Every user-facing string in both `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`; run `flutter gen-l10n` after ARB edits.
- ARB `@key` metadata lists `placeholders` before `description` (guard rule). A key no widget reads after the change is deleted from both ARBs.
- Straight apostrophes in en strings.
- Section headers render upper-cased (`MxListSectionHeader`); tests find `label.toUpperCase()`.
- Goldens are regenerated only in Task 9.

## Review Focus

- **07 with a paged window:** a deck with more cards than the first window, narrowed by a filter — "Showing {n} of {total}" counts matches, not the loaded window (Task 2 test uses `counts`, not `items.length`).
- **11 headerless file:** with "First row is a header" off, the file line counts every line (Task 4 test flips the toggle).
- **11 nothing to import:** the caption "No row will be imported." still explains the locked button (Task 4 keeps the existing `willWrite == 0` test).
- **28 both statuses chosen:** rows keep their badge (Task 7 test).
- **28 three levels chosen:** the chip counts, "Level · 3" (Task 7 keeps the existing test's second half).

---

### Task 1: 01 open deck — header without the count, a breakdown that wraps

**Files:**
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart:75-81`, `lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart:74`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/deck/presentation/open_deck_screen_test.dart:296-303`

**Interfaces:**
- Produces: ARB key `deckSubDecksHeader` (en "Sub-decks", vi "Bộ thẻ con").

- [ ] **Step 1: Failing tests.** In the open-deck test at line 301 replace `expect(find.text(_en.deckSubDeckCount(2).toUpperCase()), findsOneWidget);` with

```dart
    // The summary card states the count; the header names the list
    // (critique 2026-09-30 part 3b).
    expect(find.text(_en.deckSubDecksHeader.toUpperCase()), findsOneWidget);
    expect(find.text(_en.deckSubDeckCount(2).toUpperCase()), findsNothing);
```

and add a test in the same file, seeding as the test at line 296 does plus enough scheduled cards that the breakdown overflows one line at 360 dp (overdue, today, new and scheduled all non-zero):

```dart
  libraryTest('the summary breakdown wraps between whole terms, never "…" '
      '(Wrap Rule; critique 2026-09-30 part 3b)', (tester, env) async {
    // seed: see the test at line 296, with scheduled cards added
    await tester.pumpAndSettle();
    final line = tester.widget<Text>(
      find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(Text),
      ).first,
    );
    expect(line.maxLines, isNull);
    expect(line.overflow, isNot(TextOverflow.ellipsis));
  });
```

- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/deck/presentation/open_deck_screen_test.dart` → FAIL (`deckSubDecksHeader` undefined; maxLines is 1).
- [ ] **Step 3: Implement.** Add to `app_en.arb` after `deckSubDeckCount`:

```json
  "deckSubDecksHeader": "Sub-decks",
  "@deckSubDecksHeader": {
    "description": "Screen 01: the sub-deck list header under an open deck's summary card, which already states the count (critique 2026-09-30 part 3b)."
  },
```

and `"deckSubDecksHeader": "Bộ thẻ con",` to `app_vi.arb`. In `_headerLabel` return `l10n.deckSubDecksHeader` in place of `l10n.deckSubDeckCount(level.deckCount)` (the root and level-10 branches stay). In `deck_summary_card_widget.dart` pass `canWrap: true` to `MxWorkloadBreakdownLine`. Run `flutter gen-l10n`.
- [ ] **Step 4:** Run the file → PASS.
- [ ] **Step 5: Commit** `fix(deck): the open deck's header names the list; its breakdown wraps`.

### Task 2: 07 card list — header, selection, row

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart:343-387`, `lib/features/card/presentation/widgets/items/card_row_widget.dart:44-62`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/card/presentation/card_list_layout_test.dart:101-133`, `test/features/card/presentation/card_row_test.dart`, `test/features/card/presentation/card_selection_test.dart:48`, `test/features/card/presentation/card_bulk_actions_test.dart:188,223`

**Interfaces:**
- Produces: ARB key `cardListHeader` (en "Cards", vi "Thẻ"); `cardSelectedOf` deleted.

- [ ] **Step 1: Failing tests.**
  - `card_list_layout_test.dart:107`: the unfiltered header is `find.text(_en.cardListHeader.toUpperCase())`; add `expect(find.textContaining('SHOWING'), findsNothing);`.
  - New test in the same file: tap the "Due" chip (`find.widgetWithText(MxFilterChip, _en.cardFilterDue)`), `pumpAndSettle`, then `expect(find.text(_en.cardShowingOf(dueCount, 2).toUpperCase()), findsOneWidget);` where `dueCount` is the seed's due cards and 2 its active cards.
  - `card_list_layout_test.dart:132`: replace the `cardSelectedOf` line with `expect(find.byType(MxListSectionHeader), findsNothing); expect(find.text(_en.cardSelectedCount(1)), findsOneWidget);`.
  - `card_selection_test.dart:48` helper and `card_bulk_actions_test.dart:188,223`: find the app bar title `_en.cardSelectedCount(count)` instead of `cardSelectedOf(count, total)` (drop the `total` argument where it becomes unused).
  - `card_row_test.dart`: add

```dart
  libraryTest('a row states its status once: the label, no dot (critique '
      '2026-09-30 part 3b, R3)', (tester, env) async {
    // pump one row as the test at line 43 does
    expect(find.byType(MxStatusBadge), findsNothing);
    expect(find.text(_en.cardStatusMastered.toUpperCase()), findsOneWidget);
  });
```

  and change the test at line 223 ("the status dot and the trailing column are centred…") to centre the content column and the trailing column (the dot is gone); rename it accordingly.
- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/card` → the new and edited tests FAIL.
- [ ] **Step 3: Implement.**
  - ARB en: `"cardListHeader": "Cards"` with `@cardListHeader` description "Screen 07: the list header while every card of the deck shows; 'Showing {n} of {total}' only while a filter, a tag or search narrows it (critique 2026-09-30 part 3b)." vi `"cardListHeader": "Thẻ"`. Delete `cardSelectedOf` and `@cardSelectedOf` from both ARBs.
  - `card_list_section_widget.dart`: the header shows only when not selecting. Label: `request.isNarrowed ? l10n.cardShowingOf(view.counts.of(request.filter), view.statusCounts.total) : l10n.cardListHeader`, where narrowed means `request.filter != CardListFilter.all || request.searchTerm.trim().isNotEmpty || request.tags.isNotEmpty` (add it as a getter `isNarrowed` on the request state class in `card_list_request_state.dart`, documented). Keep the sort chip trailing.
  - `card_row_widget.dart`: remove the `ExcludeSemantics(MxStatusBadge(isDot: true))` branch; keep the checkbox while selecting. Update the comment ("The checkbox, while selecting, and the trailing column centre on the row"). Remove the now-unused imports.
  - `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/card` → PASS.
- [ ] **Step 5: Commit** `fix(card): the card list states each number once; a row states its status once`.

### Task 3: 06 Trash — the selecting header states the total

**Files:**
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart:257-269`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/trash/presentation/trash_selection_test.dart:56-59,183-186`

**Interfaces:**
- Produces: ARB keys `trashCardsHeader` ("{count, plural, =1{1 card} other{{count} cards}}", vi "{count} thẻ"), `trashDecksHeader` ("{count, plural, =1{1 deck} other{{count} decks}}", vi "{count} bộ thẻ"); `trashSelectedOfCards` and `trashSelectedOfDecks` deleted.

- [ ] **Step 1: Failing tests.** Line 57: `find.text(_en.trashCardsHeader(2).toUpperCase())`; line 184: `find.text(_en.trashCardsHeader(1).toUpperCase())`. Add after each: `expect(find.textContaining(' OF '), findsNothing);`.
- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/trash` → FAIL.
- [ ] **Step 3: Implement.** Add the two keys (with `placeholders.count` int, then description "Screen 06: the list header while selecting; the title states how many are selected (critique 2026-09-30 part 3b).") to both ARBs; delete the two old keys. In `_header`: `TrashKind.card => l10n.trashCardsHeader(total(TrashKind.card))`, `TrashKind.deck => l10n.trashDecksHeader(total(TrashKind.deck))`; drop `count` and the `state` parameter if unused. `flutter gen-l10n`.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `fix(trash): the selecting header states the total, the title the selection`.

### Task 4: 11 Import — preview header, caption, file line

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart:38-44`, `lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart:52-57`, `lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart:253-255`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/transfer/presentation/card_import_screen_test.dart:86,210`

**Interfaces:**
- Produces: ARB key `importCaptionNothingToImport` (en "No row will be imported.", vi "Không dòng nào được nhập."); `importPreviewReady` and `importCaptionPreview` deleted.

- [ ] **Step 1: Failing tests.**
  - Line 86: replace with `expect(find.textContaining('rows ready'), findsNothing); expect(find.text('2 rows will become new cards.'), findsNothing);`.
  - Line 210: `find.text(_en.importCaptionNothingToImport)`.
  - New test: the file `'front,back\nmul,water\nbul,fire\n'` read with the header toggle on shows `find.textContaining('2 rows')` and not `'3 rows'`; after tapping `_en.importHeaderToggle` (off) it shows `'3 rows'`. Pump and read as the test at line 62 does.
- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/transfer` → FAIL.
- [ ] **Step 3: Implement.**
  - Preview header: `MxListSectionHeader(label: l10n.importSectionPreview)` with no trailing.
  - Commit bar, preview step caption: `draft.willWrite > 0 ? null : l10n.importCaptionNothingToImport` (the tuple's caption type becomes `String?`; `MxFooterBar.caption` already accepts null — check its signature and rule if not).
  - Source line: `l10n.importFileRead(format, dataRows, table.columnCount)` with `final dataRows = draft.hasHeaderRow ? math.max(0, table.rows.length - 1) : table.rows.length;` and a comment citing `import_preview_model.dart:83` (the preview skips the header row the same way).
  - ARB: add `importCaptionNothingToImport` to both with a description; delete `importPreviewReady` and `importCaptionPreview`. `flutter gen-l10n`.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `fix(transfer): the preview states its counts once; the file line counts data rows`.

### Task 5: 14 Study entry — the caption drops the count

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart:67-71`, `lib/l10n/app_en.arb:3273`, `lib/l10n/app_vi.arb:626`
- Test: `test/features/study/presentation/study_entry_actions_test.dart:288,298`

- [ ] **Step 1: Failing tests.** Lines 288 and 298: `_en.studyEntryModeCaption(_en.cardModeMatch)` and `(_en.cardModeGuess)` (one argument). Add `expect(find.textContaining('5 due cards ·'), findsNothing);` after the first.
- [ ] **Step 2:** Run the file → FAIL (compile: too many arguments in the widget once the ARB changes; before it, the test fails to compile). Change the ARB first, then run: the widget call fails to compile — that is the RED.
- [ ] **Step 3: Implement.** en `"studyEntryModeCaption": "{mode} · oldest first"` (placeholders: `mode` String only; description adds "the start button states the count (R5, critique 2026-09-30 part 3b)"); vi `"{mode} · cũ nhất trước"`. Widget: `l10n.studyEntryModeCaption(l10n.studyMode(target.mode))`. `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/study` → PASS.
- [ ] **Step 5: Commit** `fix(study): the review caption leaves the count to the start button`.

### Task 6: 22 Progress — header without the range, footer without the rule

**Files:**
- Modify: `lib/features/progress/presentation/widgets/sections/progress_level_list_widget.dart:37-42`, `lib/l10n/app_en.arb:4676-4691,4755`, `lib/l10n/app_vi.arb:881-884,897`
- Test: `test/features/progress/presentation/progress_screen_test.dart`, `test/app/progress_routes_test.dart:59`

**Interfaces:**
- Produces: ARB keys `progressByDeck` (en "By deck", vi "Theo deck"), `progressSubDecks` (en "Sub-decks", vi "Deck con"); the four range-suffixed keys deleted.

- [ ] **Step 1: Failing tests.** `progress_routes_test.dart:59`: `find.text(_en.progressSubDecks.toUpperCase())`. In `progress_screen_test.dart`, in the test at line 54 add

```dart
    expect(find.text(_en.progressByDeck.toUpperCase()), findsOneWidget);
    expect(find.textContaining('LAST 7 DAYS'), findsNothing);
    expect(find.text(_en.progressFooter), findsOneWidget);
    expect(find.textContaining('counts once'), findsOneWidget); // Today only
```

- [ ] **Step 2:** Run both files → FAIL.
- [ ] **Step 3: Implement.** ARB en: `progressByDeck`, `progressSubDecks` (descriptions: "Screen 22: the deck list header; the range segment above states the range (critique 2026-09-30 part 3b)."); `progressFooter` → "Read-only · resets change nothing here"; vi `"Chỉ đọc · đặt lại không đổi gì ở đây"`. Delete `progressByDeckWeek`, `progressByDeckMonth`, `progressSubDecksWeek`, `progressSubDecksMonth` from both. Widget: `final header = isDeckLevel ? l10n.progressSubDecks : l10n.progressByDeck;` (the `range` read stays for `total` and `note`). `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/progress test/app/progress_routes_test.dart` → PASS.
- [ ] **Step 5: Commit** `fix(progress): the list header and the footer leave the range and the rule to their homes`.

### Task 7: 28 Monitoring — badge, chip, note, Not sent header

**Files:**
- Modify: `lib/features/monitoring/presentation/widgets/items/log_row_widget.dart`, `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart:180-185`, `lib/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart:58-67`, `lib/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart:43-50,110-126`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/monitoring/presentation/monitoring_filters_test.dart:19`, `test/features/monitoring/presentation/monitoring_screen_test.dart`, `test/features/monitoring/presentation/monitoring_not_sent_test.dart`

**Interfaces:**
- Produces: `LogRowWidget({..., bool isStatusShown = true})`; ARB `monitoringPendingCount` ("{count} at these levels", vi "{count} ở các mức này"); `monitoringPendingNote` loses its placeholder.

- [ ] **Step 1: Failing tests.**
  - `monitoring_filters_test.dart:19`: `find.text('Level · Warning, Error')`. The later `'Level · 3'` stays (three levels count).
  - `monitoring_screen_test.dart`, in the test at line 21 (default filter, open only): `expect(find.widgetWithText(MxBadge, 'Open'), findsNothing);`. New test: set the Status chip to both statuses (open the Status sheet with `tapMonitoringChip(tester, 'Status')`, turn both on, Apply) → `findsWidgets` for the `Open` badge.
  - `monitoring_not_sent_test.dart`, test at line 14: `expect(find.text('12 logs wait on this device. They are sent when MemoX is online.'), findsNothing); expect(find.text('These logs wait on this device. They are sent when MemoX is online.'), findsOneWidget);` and the list header `find.text('${shownRows} AT THESE LEVELS')` where `shownRows` is the rows the test's fake returns at the default levels.
- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/monitoring` → FAIL.
- [ ] **Step 3: Implement.**
  - `monitoringChipLabel`: `0 => label`, `1 || 2 => l10n.monitoringChipValue(label, chosen.join(', '))`, `final count => l10n.monitoringChipValue(label, '$count')`; doc: "names one or two choices, counts from three (critique 2026-09-30 part 3b)".
  - `LogRowWidget`: new `final bool isStatusShown;` (doc: "False while the Status filter holds one status: the chip and the header say it."). The badge branch becomes `if (isStatusShown && status != null && statusLabel != null)`; the `Visibility.maintain` placeholder stays in the else branch so row heights hold. The semantics label keeps the status.
  - Server list: `isStatusShown: loaded.filter.statuses.length != 1` (confirm `MonitoringListLoaded.filter` at `monitoring_list_state.dart:56`).
  - Pending tab: `MxNote(text: l10n.monitoringPendingNote)`; above the rows add `MxListSectionHeader(label: l10n.monitoringPendingCount(logs.items.length))` when `logs.items` is not empty.
  - ARB en `monitoringPendingNote`: "These logs wait on this device. They are sent when MemoX is online." (no placeholders); vi "Các nhật ký này đang chờ trên máy này. Chúng được gửi khi MemoX có mạng."; add `monitoringPendingCount` with `placeholders.count` int. `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/monitoring` → PASS.
- [ ] **Step 5: Commit** `fix(monitoring): Open said once, chips name their levels, Not sent counts what it shows`.

### Task 8: Records

**Files:**
- Modify: `DESIGN.md` (the Don'ts line "Do state a number once per screen…"), `docs/shared/ui/screen-handoff/{01-deck-list,06-trash,07-card-list,11-card-import,14-study-entry,22-progress,28-monitoring}.md`, `docs/wbs_FE.md`

- [ ] **Step 1: DESIGN.md.** Replace the one-line "state a number once" item with the rule of spec §3 (home, buttons, captions, list headers, selecting, rows, kept numbers), in DESIGN.md's voice, citing "critique 2026-09-30 part 3b".
- [ ] **Step 2: Detail files.** 01: header "Sub-decks" under the summary card; the breakdown wraps (fix line 72's "ends in an ellipsis"). 06: the selecting header "{total} cards"/"{total} decks". 07: the header "Cards" / "Showing {n} of {total}" while narrowed, none while selecting, no status dot on a row. 11: no "ready" header text, caption only when nothing can be imported, file line counts data rows. 14: the caption "{mode} · oldest first". 22: headers "By deck"/"Sub-decks", the footer. 28: the badge rule, the chip rule, the note, the Not sent header. Update each file's Copy section.
- [ ] **Step 3: WBS.** Row FE-D10 "Critique 2026-09-30 phần 3b: một con số nói một lần (rule DESIGN.md; 01, 06, 07, 11, 14, 22, 28)" status "đang làm", dependency FE-D9, links to the spec and this plan. `python3 tools/docs/generate.py`, then `python3 tools/docs/check.py` → PASS.
- [ ] **Step 4: Commit** `docs: record critique part 3b`.

### Task 9: Goldens, gates, review

- [ ] **Step 1:** `flutter test --tags golden` (no update); list failing goldens. Expected: 01 open deck (`library_deck_open`, and any golden showing the sub-deck header), 07 card list / selection / search / search results, 06 selection and restore-target states, 11 preview and source-bearing states, 14 entry states with a review caption, 22 week/month/deck progress, 28 list and not-sent. Anything else is a regression: stop and debug.
- [ ] **Step 2:** `flutter test --tags golden --update-goldens`; view four changed goldens (one per family); commit `test(goldens): regenerate for critique part 3b`.
- [ ] **Step 3: Gates.** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`, `FLUTTER_ROOT=/root/.flutter-sdk/3.47.5/flutter bash .claude/skills/flutter-workflow/scripts/dod_check.sh` (run the guard with `python3.13` if the default python lacks typer) → all pass.
- [ ] **Step 4:** Golden review page with `golden-compare` (base = this plan's commit), families per screen, `why` in Vietnamese.
- [ ] **Step 5:** Whole-branch review of this part's range (requesting-code-review, most capable model), one fix pass, then finishing-a-development-branch.
