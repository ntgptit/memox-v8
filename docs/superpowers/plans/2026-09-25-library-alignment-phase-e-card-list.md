# Library Alignment Phase E — Card List (Screen 07) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An open deck of cards looks and behaves like screen 07 of the V3 handoff:
- a card-deck app bar with search and the selection header;
- a hero summary with the mastery donut, the workload line and the four-state bar;
- filters, a "Showing n of total" header with the sort pill;
- one card per row with its status, tags and due chip;
- a four-command bulk bar.

**Architecture:**
- **Composition.** `DeckLevelScreen` gains two builders beside `cardContent` and `cardFab`, which `app/` composes from `card/presentation` (spec §7, A14). The first builds the card deck's app bar from the `DeckView` and the deck's `⋮` action. The second wraps the breadcrumb, which hides while cards are selected. `cardContent` now receives the `DeckView`, so the summary can name the scheduler. `deck` still never imports `card` (Library spec D8).
- **Read model.** The card read model gains the deck-wide workload (overdue, today, new), counted in the same pass as the status counts (owner decision E-O1).
- **Card feature.** It gains three pieces:
  - a search-open state per deck;
  - the summary card;
  - a redesigned row.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3 (codegen), Drift, gen-l10n (en, vi), go_router 18.

**Spec:** `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` §4.4, §5, §7 (A4 amended 2026-09-25, A13, A14, A15, A16). Screen handoff: `docs/shared/ui/screen-handoff/07-card-list.md` and `docs/shared/ui/screen-handoff/img/07-card-list/`.

## Owner decisions (popup, 2026-09-25)

| # | Decision |
|---|---|
| E-O1 | **The workload joins the card read model.** `CardListView.workload` (overdue, today, new) is counted over the deck's active schedules in the pass that counts the display states, so the summary's breakdown line comes from a read model (spec §1). No schema change. |
| E-O2 | **Goldens are the Linux render** (spec §8, FE-D1). This phase runs goldens only on Linux: a remote or cloud agent regenerates the goldens of the screens it changes. Windows runs use `--exclude-tags golden`. |
| E-O3 | **Spec A4 as amended:** no disabled Study, Tags filter, Import or Export anywhere on screen 07. The Library root's "Coming soon" sheet names them. |

## Rulings written into this plan

| # | Ruling |
|---|---|
| E-L1 | **Empty deck.** A card deck whose last card goes becomes `unset` (BR-DECK-015, `_unsetEmptied`), so it shows screen 01's unset state (New card, New sub-deck). The handoff's `empty` state becomes that. The card list's own empty branch stays only for a filter or search with no hit. |
| E-L2 | **The flag's streak colour** has no theme token (`MxSemanticColors` keeps streak PRESERVE_ONLY). The flag draws in `warning`, through `IconTheme`, not `Icon(color:)`. |
| E-L3 | **"Select all {n}"** is a compact secondary `MxButton` in the selection app bar. The kit's borderless primary text has no button tone in the design system. |
| E-L4 | **The due chip is an `MxBadge`:** overdue uses the `warning` tone, today `primary`, new and later `neutral`. The kit's DueChip is a 4-radius tag. `MxBadge` is the design system's pill for the same idea, and the kit itself notes that the two should converge (audit F-P3). |
| E-L5 | **Rows are lazy.** Each card row is its own child of the section's `MxScreenScroll`, not a `Column` inside one `MxCard`. This closes the eager-build note of the #41 audit. |
| E-L6 | **A bulk command that fails** keeps the selection and shows a danger `MxInlineBanner` above the bulk bar, which the next command clears (handoff `bulkFailed`). A rejection (`Rejected`) still shows as a snackbar, as today. |

## Global Constraints

- **UI only, except E-O1:** the one domain/data change is `CardWorkload` in `card/domain/models/card_list_view_model.dart` and its count in `card/data/mappers/card_mapper.dart`, test-first. No schema change.
- **Feature import map:** `card → {deck, srs, tags}` (domain + di), `deck → {srs}`. `deck` never imports `card`. `app/` composes.
- **Guard `memox-v8` at 0/0:**
  - no raw Material widgets, no `Icon(color:)` (use `IconTheme.merge`), no per-site `textStyles.x.copyWith(`;
  - no user-visible literal strings;
  - booleans read as predicates;
  - no `ref.read` in `build()`;
  - `flutter.max_build_lines`.
- **Copy:** `lib/l10n/app_en.arb` (with `@key`: `placeholders` before `description`) and `app_vi.arb`. Run `flutter gen-l10n` after ARB edits, and `dart run build_runner build --delete-conflicting-outputs` after `@riverpod` edits.
- **Tests:** `libraryTest`, `pumpLibraryScreen`, `pumpMemoxApp`. On Windows, `flutter test --exclude-tags golden`. Goldens are regenerated on Linux only (E-O2).
- **Commit trailer:** `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Selecting, then searching or filtering.**
   - Expected: the selection clears (IT-ORG-013), the app bar returns to the deck bar, and the summary comes back.
   - Pinned in the Task 5 tests.
2. **"Select all" with a search term.**
   - Expected: it selects every card the term and the filter let through, not only the loaded window (BR-CARD-012), and the header says "{n} of {total} selected".
   - Pinned in Task 6.
3. **Closing the search.**
   - Expected: the term clears and the full list comes back.
   - Pinned in Task 5.
4. **Deleting the last card.**
   - Expected: the deck turns into screen 01's unset state (E-L1), with no crash and no empty card list.
   - Pinned in Task 6.
5. **Text scale 2 on a 360-wide phone.**
   - Expected: the summary, the rows with two tags and "+N", the due chip and the bulk bar do not overflow.
   - Pinned in Tasks 3, 4 and 5.

---

### Task 1: The deck-wide workload in the card read model (E-O1)

**Files:**
- Modify:
  - `lib/features/card/domain/models/card_list_view_model.dart`
  - `lib/features/card/data/mappers/card_mapper.dart`
  - `lib/features/card/data/repositories/card_repository_impl.dart`
  - `test/features/card/presentation/card_list_section_test.dart` (its `const CardListView(` fixture)
- Test: `test/features/card/data/card_list_read_test.dart`

**Interfaces:**
- Produces:
  - `CardWorkload({required int overdue, required int today, required int newCards})`;
  - `CardListView.workload`;
  - `CardWorkload workloadOf(Iterable<CardSchedule> schedules, DateTime startOfToday)`.

- [ ] **Step 1: Write the failing tests.** Append to `card_list_read_test.dart`. The fixture at T0 = 2026-09-23 10:00 is: `new` new; `begin` due 9/23 (today); `review` due 9/22 (overdue); `master` due 10/23 (later).

```dart
  test('the workload counts the deck: overdue, due today, new', () async {
    final view = await list();

    expect(
      (view.workload.overdue, view.workload.today, view.workload.newCards),
      (1, 1, 1),
    );
  });

  test('the workload ignores the search and the filter', () async {
    final view = await list(
      query: const CardListQuery(
        filter: CardListFilter.flagged,
        searchTerm: 'benevolent',
      ),
    );

    expect(
      (view.workload.overdue, view.workload.today, view.workload.newCards),
      (1, 1, 1),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail.** Run `flutter test test/features/card/data/card_list_read_test.dart`. Expected: compile error, because `workload` is not defined.

- [ ] **Step 3: Implement.** In `card_list_view_model.dart`, after `CardStatusCounts`:

```dart
/// The deck's work by when it is due (BR-STUDY-067, BR-STUDY-068), whatever
/// the search and the filter: the summary's breakdown line (owner decision
/// E-O1).
final class CardWorkload {
  const CardWorkload({
    required this.overdue,
    required this.today,
    required this.newCards,
  });

  final int overdue;
  final int today;
  final int newCards;
}
```

Also add `required this.workload,` to `CardListView`'s constructor and `final CardWorkload workload;` with a one-line doc.

In `card_mapper.dart`, after `statusCountsOf`:

```dart
/// Every schedule row by when it comes back, counted once each.
CardWorkload workloadOf(
  Iterable<CardSchedule> schedules,
  DateTime startOfToday,
) {
  var overdue = 0;
  var today = 0;
  var newCards = 0;
  for (final schedule in schedules) {
    final due = CardDue.of(
      isLearned: schedule.learnedAt != null,
      dueAt: schedule.dueAt,
      startOfToday: startOfToday,
    );
    switch (due.kind) {
      case CardDueKind.overdue:
        overdue++;
      case CardDueKind.today:
        today++;
      case CardDueKind.newCard:
        newCards++;
      case CardDueKind.later:
        break;
    }
  }
  return CardWorkload(overdue: overdue, today: today, newCards: newCards);
}
```

In `card_repository_impl.dart`, after `statusCounts: statusCountsOf(schedules),`, add `workload: workloadOf(schedules, startOfToday),`. `startOfToday` is already computed above the `return`.

In `card_list_section_test.dart`, the `const CardListView(` fixture gains `workload: CardWorkload(overdue: 0, today: 0, newCards: 0),`.

- [ ] **Step 4: Run the tests.** Run `flutter test test/features/card/data test/features/card/presentation --exclude-tags golden`. Expected: PASS.

- [ ] **Step 5: Record and commit.**
  - Append this row to the spec's §5 table:

```markdown
| `card` domain + data | **Workload:** `CardListView.workload`, the deck's overdue, today and new counts, from the schedules the status counts read, in the same pass (phase E, owner decision E-O1). |
```

  - Commit: `feat(card): the deck-wide workload in the card read model (E-O1)`.

---

### Task 2: Copy, icon, text role and `MxCard.isSelected`

**Files:**
- Modify:
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
  - `lib/core/theme/mx_text_styles.dart`
  - `lib/shared/widgets/mx_card.dart`
  - `lib/app/gallery/gallery_surfaces_section.dart`
- Test:
  - `test/shared/widgets/mx_card_test.dart` (extend; create it if it is absent)
  - `test/core/theme/mx_text_styles_test.dart` (if it exists, extend it)

**Interfaces:**
- Produces:
  - `MxCard(isSelected: bool)`: a primary border at `AppStroke.control` over the card's ground;
  - `MxTextStyles.statusLabel(Color ink)`: 12/700, 0.6 tracking, in `ink`; the caller upper-cases the text;
  - the copy keys listed in the Step 3 table.

- [ ] **Step 1: Write the failing test.** `MxCard(isSelected: true)` paints a `Border` whose colour is `colors.primary`; `false` paints the default edge.

```dart
testWidgets('a selected card edges in primary', (tester) async {
  await tester.pumpWidget(
    wrapWithTheme(const MxCard(isSelected: true, child: Text('x'))),
  );
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(MxCard), matching: find.byType(DecoratedBox)).first,
  );
  final border = (box.decoration as BoxDecoration).border! as Border;
  expect(border.top.color, AppTheme.light().colorScheme.primary);
});
```

Use the test helpers the other `test/shared/widgets/*_test.dart` files use for theming: the harness `pumpComponent` or its equivalent.

- [ ] **Step 2: Run it to verify it fails.** Expected: `isSelected` is not a parameter.

- [ ] **Step 3: Implement.**
  - **`MxCard`:** add `this.isSelected = false`. Where the surface decoration is built, a selected card uses `surface.copyWith(border: Border.all(color: colors.primary, width: AppStroke.control))`. It keeps its ground and radius.
  - **Gallery:** add a selected `MxCard` entry beside the plain one in `gallery_surfaces_section.dart`.
  - **Text role:** in `mx_text_styles.dart`, after `overline`:

```dart
  /// A card row's status label (screen 07): the overline's 12/700 and 0.6
  /// tracking, in its status ink.
  TextStyle statusLabel(Color ink) => overline.copyWith(color: ink);
```

  - **Copy.** Add these keys with the `KEYS` script shape of the earlier plans, writing each file with `newline='\n'`:

| Key | en | vi | Placeholders |
|---|---|---|---|
| `cardDeckProgress` | Deck progress · {algorithm} | Tiến độ bộ thẻ · {algorithm} | algorithm String |
| `cardMasteredOf` | {mastered} of {total} cards mastered | {mastered}/{total} thẻ đã thuộc | mastered, total int |
| `cardShowingOf` | Showing {shown} of {total} | Đang hiện {shown}/{total} | shown, total int |
| `cardSelectedOf` | {selected} of {total} selected | Đã chọn {selected}/{total} | selected, total int |
| `cardSelectAllCount` | Select all {count} | Chọn tất cả {count} | count int |
| `cardSearchOpen` | Search in this deck | Tìm trong bộ thẻ này | — |
| `cardSearchClose` | Close search | Đóng tìm kiếm | — |
| `cardDueNew` | New | Mới | — |
| `cardDueToday` | Due today | Đến hạn hôm nay | — |
| `cardDueIn` | In {days}d | Sau {days} ngày | days int |
| `cardDueOverdue` | Overdue {days}d | Quá hạn {days} ngày | days int |
| `cardMoreTags` | +{count} | +{count} | count int |
| `cardSearchEmptyBody` | Try a different term, or clear the search to see all {count} cards. | Thử từ khác, hoặc xoá tìm kiếm để xem cả {count} thẻ. | count int |
| `cardBulkFailedTitle` | Couldn't finish that. | Chưa làm xong việc đó. | — |
| `cardBulkFailedBody` | Nothing changed. The cards stay selected. | Không có gì thay đổi. Các thẻ vẫn đang được chọn. | — |

  - **Existing keys:** `cardLoadErrorTitle` becomes "Couldn't open this deck" / "Không mở được bộ thẻ này", as the handoff's copy says.

- [ ] **Step 4: Run the tests.** Run `flutter gen-l10n`, then `flutter test test/shared test/core --exclude-tags golden`. Expected: PASS.

- [ ] **Step 5: Commit** as `feat(ui): MxCard.isSelected, the status label role and screen 07 copy`.

---

### Task 3: The card row (handoff CardRow)

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart` (rewrite)
- Create: `lib/features/card/presentation/widgets/items/card_due_chip_widget.dart`
- Modify: `lib/features/card/presentation/widgets/support/card_list_labels_widget.dart` (add `cardDue(CardDue)` and `statusInk`)
- Test: `test/features/card/presentation/card_row_test.dart` (create)

**Interfaces:**
- Produces:
  - `CardRowWidget({required CardListItem item, required bool isSelecting, required bool isSelected, VoidCallback? onTap, VoidCallback? onLongPress})`. The `hasDivider` parameter is removed, since each row is its own card.
  - `CardDueChipWidget({required CardDue due})`.

- [ ] **Step 1: Write the failing tests** in `test/features/card/presentation/card_row_test.dart`. Build `CardListItem`s directly and use `pumpLibraryScreen` with a `Scaffold(body: ListView(children: [...]))` host.
  - **Test 1, "a row shows front, back, status, two tags and +N, the flag and when it is due":**
    - Setup: `tags` has 4 entries, `isFlagged: true`, `due: CardDue.overdue(30)`, status reviewing.
    - Expects: `find.text('Reviewing'.toUpperCase())` (via `_en.cardStatusReviewing.toUpperCase()`); the first two tag names; `find.text(_en.cardMoreTags(2))`; `find.text(_en.cardDueOverdue(30))`; `find.bySemanticsLabel(_en.cardFlagged)`.
  - **Test 2, "selecting shows a checkbox, checked when selected":** `MxSelectionCheckbox` is found; `tester.getSemantics(find.byType(CardRowWidget))` `isSemantics(isChecked: true)` when `isSelected`.
  - **Test 3, "each due kind reads as the handoff says":** covers new, today, `later(17)` → "In 17d", and `overdue(30)`.
  - **Test 4, "a row holds at 2x and meets the target guidelines":** two long tags plus "+8", with a long front and back; no exception; `expectAccessibleTargets`.

- [ ] **Step 2: Run the tests** and confirm they fail.

- [ ] **Step 3: Implement.**
  - **`cardDue(CardDue due)`** in `CardListLabels`:
    - `CardDueKind.newCard` → `cardDueNew`;
    - `today` → `cardDueToday`;
    - `later` → `cardDueIn(due.days)`;
    - `overdue` → `cardDueOverdue(due.days)`.
  - **`Color statusInk(BuildContext context, CardDisplayStatus status)`** in the same file. It maps to `context.derivedColors.statusNewInk`, `statusLearningInk` (beginning), `statusReviewingInk` and `statusMasteredInk`.
  - **`CardDueChipWidget`:** `MxBadge(label: l10n.cardDue(due), tone: switch (due.kind) { overdue → warning, today → primary, _ → neutral })` (E-L4).
  - **`CardRowWidget`:** an `MxCard(isSelected: isSelected)` with padding 12, wrapped in `MergeSemantics(Semantics(checked: isSelecting ? isSelected : null, child: GestureDetector(onLongPress:, child: MxRowInk(onTap:, …))))`. Keep the one-node semantics of ruling I6. Inside, a `Row(crossAxisAlignment: start, spacing: AppSpacing.grouped)` holds:
    - **leading:** while selecting, `MxSelectionCheckbox(isChecked: isSelected)`; otherwise an 8-px status dot, `MxStatusBadge(status: mxCardStatus(s), label: l10n.cardStatus(s), isDot: true)`;
    - **middle:** an `Expanded` `Column(crossAxisAlignment: start)`:
      - `Text(item.front, maxLines: 1, overflow: ellipsis, style: styles.contentTitle)`;
      - `Text(item.back, maxLines: 1, overflow: ellipsis, style: styles.rowDescription)`;
      - `SizedBox(height: AppSpacing.control)`;
      - a `Row(spacing: AppSpacing.micro)` of `Text(l10n.cardStatus(s).toUpperCase(), semanticsLabel: l10n.cardStatus(s), style: styles.statusLabel(statusInk(context, s)))`, the first two tags as `Flexible(child: MxTagChip(label: tag.name, isDense: true))`, and, when there are more than two, `Text(l10n.cardMoreTags(n - 2), style: styles.rowDescription)`;
    - **trailing:** a `Column(crossAxisAlignment: end, spacing: AppSpacing.micro)`:
      - when flagged, `IconTheme.merge(data: IconThemeData(color: context.semanticColors.warning, size: AppIconSize.inline), child: Icon(AppIcons.flagged, semanticLabel: l10n.cardFlagged))` (E-L2);
      - `CardDueChipWidget(due: item.due)`.
  - Each row keeps an `AppSpacing.control` bottom padding, so rows sit 8 apart.

- [ ] **Step 4: Run the tests.** Run `flutter test test/features/card/presentation/card_row_test.dart`. Expected: PASS.

- [ ] **Step 5: Commit** as `feat(card): the screen 07 card row: status, tags, due chip, flag`.

---

### Task 4: The deck summary card

**Files:**
- Create: `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`
- Test: `test/features/card/presentation/card_deck_summary_test.dart`

**Interfaces:**
- Produces: `CardDeckSummaryWidget({required CardListView view, required String algorithm})`.

- [ ] **Step 1: Write the failing tests.** Build a `CardListView` with status counts (new 100, beginning 140, reviewing 100, mastered 80) and a workload of 20 overdue, 20 today, 100 new.
  - **Test 1:** `_en.cardDeckProgress('SM-2').toUpperCase()` and `_en.cardMasteredOf(80, 420)` show. `MxMasteryDonut` shows with `fraction` 80/420. `MxWorkloadBreakdownLine` shows. Each legend label shows (`_en.cardStatusNew` …) with its count.
  - **Test 2:** at 2x there is no overflow, and `expectAccessibleTargets` passes.

- [ ] **Step 2: Run the tests** and confirm they fail.

- [ ] **Step 3: Implement.** Use `MxCard(isHero: true)` with a `Column(stretch, spacing: AppSpacing.grouped)`:
  1. **Header:** `Row(spacing: AppSpacing.gutter)` of:
     - `MxMasteryDonut(fraction: total == 0 ? 0 : mastered / total)`;
     - an `Expanded` `Column(crossAxisAlignment: start, spacing: AppSpacing.micro)` of:
       - `Text(l10n.cardDeckProgress(algorithm).toUpperCase(), semanticsLabel: …, style: styles.overline)`;
       - `Text(l10n.cardMasteredOf(mastered, total), style: styles.dialogBody)`;
       - `MxWorkloadBreakdownLine(overdueCount: w.overdue, todayCount: w.today, newCount: w.newCards, overdueLabel: l10n.workloadOverdue, todayLabel: l10n.workloadToday, newLabel: l10n.workloadNew, fallback: l10n.workloadNothingDue(total))`.
  2. **Distribution bar:** a private `_StatusBar`, an `ExcludeSemantics` `ClipRRect(borderRadius: AppRadius.full)` 6 high over a `surfaceContainer` ground. It holds a `Row` of four `Expanded(flex: count)` fills in `semanticColors.statusNew` / `statusLearning` / `statusReviewing` / `statusMastered`; a status whose count is 0 draws nothing.
  3. **Legend:** a `Wrap(spacing: AppSpacing.control, runSpacing: AppSpacing.micro)` of the four entries. Each is `Row(mainAxisSize: min, spacing: AppSpacing.micro)`[`MxStatusBadge(status:, label:, isDot: true)`, `Text('${label} ${count}')` — the label and the count come from l10n and a `NumberFormat`, not a literal].
  - There is no Study button (A4, amended).
  - Named constants: `_barHeight = 6`.

- [ ] **Step 4: Run the tests.** Expected: PASS.

- [ ] **Step 5: Commit** as `feat(card): the card deck summary: donut, workload, four-state bar`.

---

### Task 5: The card section: search reveal, filters, header, lazy rows, bulk bar

**Files:**
- Create: `lib/features/card/presentation/states/card_search_open_state.dart` (`@riverpod class CardSearchOpen`: `build(String deckId) => false`; `open()`; `close()`)
- Modify:
  - `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart` (doc: four commands)
- Delete: `lib/features/card/presentation/widgets/sections/card_selection_header_widget.dart` (it moves to the app bar in Task 6)
- Test:
  - `test/features/card/presentation/card_list_section_test.dart`
  - `card_selection_test.dart`
  - `card_bulk_actions_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - `CardListSectionWidget({required String deckId, required String algorithm, required VoidCallback onAddCard, required ValueChanged<String> onOpenCard})`;
  - `cardSearchOpenProvider(String deckId)`.

- [ ] **Step 1: Write the failing tests.** Update the section host to `CardListSectionWidget(deckId: deckId, algorithm: 'Eight boxes', onAddCard: () {}, onOpenCard: (_) {})`.

New tests:
  - **"the search field waits for the search action":** no `MxSearchField` at first. `container.read(cardSearchOpenProvider(deckId).notifier).open()` via `ProviderScope.containerOf`, then a pump; the field shows. `close()` clears the term, and every row returns (Review Focus 3).
  - **"the summary leads, then the filters, then Showing n of total":** `CardDeckSummaryWidget` is found above `find.text(_en.cardShowingOf(4, 4).toUpperCase())`. The sort pill `MxChipTrigger` sits in the header row.
  - **"selecting hides the summary; the header counts the selection":** long-press a row; `CardDeckSummaryWidget` is gone and `find.text(_en.cardSelectedOf(1, 4).toUpperCase())` shows.
  - **"a filter or a term clears the selection" (Review Focus 1):** select, then tap the Due chip; the selection is empty and the summary is back.
  - **"a failed bulk command keeps the selection and says so" (E-L6):** override `setCardsFlaggedUseCaseProvider` with a use case whose repository throws `UnknownDatabaseFailure`. Select, tap Flag, choose "Flag". Expect `find.text(_en.cardBulkFailedTitle)`, the selection still 1, and no `sqlite` in the text.
  - **"rows build lazily" (E-L5):** seed 60 cards; `find.byType(CardRowWidget, skipOffstage: false)` counts fewer than 50.
  - **"the bulk bar offers Move, Flag, Tag, Delete":** exactly those four labels; no "Export" and no "Select all" in the bar.
  - **2x:** the section with a selection holds at 2x.

Existing tests change:
  - tests that tapped the in-list `CardSelectionHeaderWidget` close now call `selection.clear()`;
  - tests that read the toolbar's search field first open the search;
  - "Select all" moves to Task 6's app bar tests.

- [ ] **Step 2: Run the tests** and confirm they fail.

- [ ] **Step 3: Implement.**
  - **`CardSearchOpen`:**
    - `build(deckId) => false`;
    - `open() => state = true`;
    - `close()` sets `state = false` and calls `ref.read(cardListRequestProvider(deckId).notifier).search('')`, since closing clears the term (spec §4.4).
  - **Toolbar:** the search field shows only when open, with `autofocus` and `onChanged: onSearch`. The filter chips stay in a horizontal scroll. The sort chip leaves the chip row.
  - **Section (`_CardListScroll`):** its children become:
    1. the search field, when open;
    2. `CardDeckSummaryWidget(view:, algorithm:)`, unless selecting;
    3. the filter chips, unless selecting;
    4. an `MxListSectionHeader` labelled `cardSelectedOf(selected.length, counts.all)` while selecting, otherwise `cardShowingOf(items.length, counts.all)`, with `trailing: MxChipTrigger(label: l10n.cardSort(request.sort), icon: AppIcons.sort, onPressed: onSort)` unless selecting;
    5. either the empty branch (search or filter with no hit; the search-empty body now uses `cardSearchEmptyBody(counts.all)`), or **each `CardRowWidget` as its own child** (E-L5).

    The section's `Column` loses `CardSelectionHeaderWidget`. It keeps the `PopScope` (Back clears the selection first) and the `CardBulkBarWidget`, over which it now shows the bulk-failed banner.
  - **Bulk actions:** Move, Flag, Tag, Delete. "Select all" moves to the app bar (Task 6).
  - **Bulk failure:** each `on Failure catch` in `_selectAll`, `_flag` and `_clearAfter` sets `_hasBulkFailed = true` (`setState`) instead of a snackbar, and every new command sets it false first. `MxInlineBanner(tone: danger, title: cardBulkFailedTitle, message: cardBulkFailedBody)` sits above `CardBulkBarWidget` while `_hasBulkFailed && isSelecting`.
  - **Selection clearing on filter or search:** already there (`_show`, `_search`). Keep it.

- [ ] **Step 4: Run the tests.** Run `dart run build_runner build --delete-conflicting-outputs`, then `flutter test test/features/card --exclude-tags golden`. Expected: PASS.

- [ ] **Step 5: Commit** as `feat(card): screen 07 card section: search reveal, summary, header, lazy rows, four-command bulk bar`.

---

### Task 6: The card deck's app bar and breadcrumb, composed by `app/` (A14)

**Files:**
- Create:
  - `lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart`
- Modify:
  - `lib/features/deck/presentation/screens/deck_level_screen.dart`
  - `lib/app/router/app_router.dart`
  - `test/support/library_harness.dart` (`deckScreen`)
- Test:
  - `test/features/card/presentation/card_deck_app_bar_test.dart` (create)
  - `test/features/deck/presentation/open_deck_screen_test.dart`
  - `test/app/library_routes_test.dart`

**Interfaces:**
- `DeckLevelScreen` changes:
  - `cardContent` becomes `Widget Function(DeckView view)`;
  - new `required Widget Function(DeckView view, Widget deckActions) cardAppBar`;
  - new `required Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb`.
- `CardDeckAppBarWidget({required DeckView view, required Widget deckActions})`: a `ConsumerWidget` returning an `MxAppBar`.
- `CardDeckBreadcrumbWidget({required String deckId, required Widget child})`: `child`, or nothing while selecting.

- [ ] **Step 1: Write the failing tests** in `card_deck_app_bar_test.dart`, hosting through `deckScreen(deckId: words, cardContent: …, cardAppBar: …, cardBreadcrumb: …)` built as `app/` builds it:
  - **"the deck bar: Back, the name, search, the deck actions":** `find.byTooltip(_en.cardSearchOpen)`, `find.byTooltip(_en.deckActions)`. Tapping search opens the field.
  - **"selecting turns the bar into the selection header" (A14):** long-press a row. Expect `find.byTooltip(_en.cardSelectionClose)`, `_en.cardSelectedCount(1)`, `find.widgetWithText(MxButton, _en.cardSelectAllCount(4))`. The breadcrumb is hidden (`find.byType(MxBreadcrumb)` finds nothing).
  - **"Select all takes every card the term lets through" (Review Focus 2):** open search, type `a`, long-press a row, tap Select all. The selected count equals the number of matching cards seeded (all of them, beyond the loaded window when 60 are seeded).
  - **"Close clears the selection; the deck bar returns".**
  - **In `open_deck_screen_test.dart`, "deleting the last card turns the deck into its unset state" (E-L1, Review Focus 4):** a card deck with one card; `env.cards.deleteCards(...)`; `pumpAndSettle`. Expect `find.text(_en.deckUnsetTitle)`.
  - **In `library_routes_test.dart`:** open a card deck in the app. Search, type, and close the search; the list is whole again.

- [ ] **Step 2: Run the tests** and confirm they fail.

- [ ] **Step 3: Implement.**
  - **`CardDeckAppBarWidget`:**
    - It watches `cardSelectionProvider(view.deck.id)`, `cardListRequestProvider`, the list provider (for `counts.all`), and `cardSearchOpenProvider`.
    - **While selecting:** `MxAppBar(density: content, leading: MxIconButton(icon: AppIcons.close, semanticLabel: cardSelectionClose, onPressed: clear), titleWidget: Semantics(liveRegion: true, child: Text(cardSelectedCount(n), style: styles.compactTitle)), actions: [MxButton(label: cardSelectAllCount(counts.all), size: compact, tone: secondary, onPressed: selectAll)])` (E-L3).
      - `selectAll` is a method, not called from `build`. It calls `ref.read(cardActionsControllerProvider.notifier).selectAll(deckId:, query: request.query)`, then `selection.selectAll(ids)`.
      - The failure case shows a snackbar through `context.l10n.failure`, as the section's code did.
    - **Otherwise:** `MxAppBar(title: view.deck.name, density: content, leading: back, actions: [MxIconButton(icon: AppIcons.search, semanticLabel: open ? cardSearchClose : cardSearchOpen, onPressed: toggle), deckActions])`.
    - The back button is the deck screen's: pass it through, or build `MxIconButton(icon: AppIcons.back, semanticLabel: commonBack, onPressed: maybePop)` here.
  - **`CardDeckBreadcrumbWidget`:** a `ConsumerWidget`. It returns `SizedBox.shrink()` while `cardSelectionProvider(deckId)` is not empty, otherwise `child`.
  - **`DeckLevelScreen` / `_OpenDeckContent`:** for `DeckContentType.card`:
    - `appBar: cardAppBar(view, deckActionsButton)`, where `deckActionsButton` is the existing `⋮` `MxIconButton`;
    - the breadcrumb goes through `cardBreadcrumb(deck.id, breadcrumb)`;
    - the body calls `cardContent(view)`.

    Other content types keep today's app bar and breadcrumb.
  - **`app_router.dart` (`_deckLevel`):**
    - `cardContent: (view) => CardListSectionWidget(deckId: view.deck.id, algorithm: context.l10n.cardScheduler(view.schedulerType), onAddCard: …, onOpenCard: …)`;
    - `cardAppBar: (view, actions) => CardDeckAppBarWidget(view: view, deckActions: actions)`;
    - `cardBreadcrumb: (id, child) => CardDeckBreadcrumbWidget(deckId: id, child: child)`.
  - **Harness `deckScreen`:** gains `cardAppBar` and `cardBreadcrumb` defaults, a plain `MxAppBar` and the breadcrumb as is. Its `cardContent` default becomes `(_) => const SizedBox.shrink()`.

- [ ] **Step 4: Run the tests.** Run `flutter test test/features test/app --exclude-tags golden`. Expected: PASS.

- [ ] **Step 5: Commit** as `feat(deck,card): the card deck's app bar and breadcrumb composed by app/ (A14)`.

---

### Task 7: Goldens on Linux, handoff, register, gate

**Files:**
- Modify:
  - `docs/shared/ui/screen-handoff/07-card-list.md`
  - `docs/shared/ui/screen-handoff/00-index.md` (07 → `aligned`)
  - `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9: close row 75; add rows for E-L2, E-L3, E-L4)
  - `docs/wbs_FE.md` (FE-A11 phase E done; FE-A2)
- Test:
  - `test/features/card/presentation/card_list_golden_test.dart` (add `card_list_search`, `card_list_bulk_failed`)
  - the gallery golden

- [ ] **Step 1: Handoff 07.**
  - **States table:**
    - `loaded` → "As drawn, without Study and the Tags chip (Coming soon)";
    - `empty` → "The deck is unset again (E-L1): screen 01's unset state";
    - `selection` → "The app bar carries close, 'n selected' and 'Select all n' (A14)";
    - `bulkFailed` → "An inline banner above the bulk bar (E-L6)".
  - **Deviations:** E-L2 (flag in warning), E-L3 (Select all as a secondary button), E-L4 (due chip as `MxBadge`), E-L1 (empty → unset).
  - The "Not captured" note on `cardActions` is removed: a tap opens the detail since #35.

- [ ] **Step 2: Register and ledgers.**
  - In the UI-base register:
    - close row 75 (`— closed by library alignment phase E`);
    - append rows for E-L2, E-L3 and E-L4 (`library alignment phase E`).
  - In `wbs_FE.md`, FE-A11's last cell reads: phase A (#32), B (#34), C (#38), D (#42) done; phase E (07) in this PR.

- [ ] **Step 3: Run the Windows gate.**

```bash
dart format --set-exit-if-changed lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test --exclude-tags golden
python tools/docs/check.py
```

Expected: all green. Commit as `docs(card): screen 07 aligned — handoff, register, ledgers`.

- [ ] **Step 4: Goldens on Linux (E-O2).**
  - Push the branch.
  - Dispatch a remote (Linux) agent to run `flutter test --update-goldens --tags golden` for `test/features/card/presentation/card_list_golden_test.dart`, `test/shared/widgets` (gallery and `MxCard`) and `test/app/app_golden_test.dart`. It checks the images against the handoff (loaded, selection) and pushes one commit, `test(card): screen 07 goldens (Linux)`.
  - Pull that commit. Review the PNGs once, against the handoff images: one inspection round, one batch of fixes, at most one confirming round.

- [ ] **Step 5: Final review and PR.** Run the whole-branch review (opus), open the PR and squash-merge after the owner's popup.
