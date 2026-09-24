# Library alignment phase C — 01 Deck list and 04 Library search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Library root, an open deck of decks, and the Library search look and behave like screens 01 and 04 of the V3 screen handoff, within the deviations the handoff records.

**Architecture:**
- `DeckLevelScreen` stays one recursive screen with the same routes, providers and controllers. Its widgets change.
- **New feature-local widgets:**
  - a card-shaped deck row with a `⋮` that opens the deck's action sheet;
  - the root due strip;
  - the open deck's summary card;
  - one sort & filter sheet;
  - the "deck is gone" state;
  - a search result row with the match emphasised.
- **Small read-model additions:** `DeckLevel.deckCount`, and `contentType` on search hits.
- **Small shared additions:** a secondary action on `MxEmptyState`, a disabled state on `MxActionSheetCommandRow`, three icons, and one text role for the search match.
- Phases A and B already built the handoff, `MxSearchField.trigger` and `MxAppBar.titleWidget`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3 codegen, Drift 2.35, gen-l10n (en, vi), flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` §4.1, §4.3, §5, §6, §9 row C. **Screen handoff:** `docs/shared/ui/screen-handoff/01-deck-list.md` and `04-library-search.md`, with their images.

## Owner decisions for this phase (popups, 2026-09-24)

| # | Decision |
|---|---|
| C-O1 | The open deck's summary counts come from the read model: `DeckLevel` gains `deckCount`, every deck of the level whatever the filter. |
| C-O2 | Search hits carry `contentType`, from the three queries that share `DeckForestRow`. No migration. |
| C-O3 | `MxEmptyState` gains a secondary action, so the first-run state shows "Browse starter decks" disabled between Create deck and the footnote. |
| C-O4 | Search results emphasise the matched part of a name, found with `foldText`, the search's own normalisation (BR-SEARCH-002). |
| C-O5 | Only the goldens of the screens this phase changes are regenerated, on Linux. The other goldens stay as they are (FE-D1). |
| C-O6 | **"N sub-decks · level 10" heads the sub-decks that sit at level 10**, so it shows on an open deck at level 9. BR-DECK-001 lets no deck at level 10 hold sub-decks, and the artifact draws its level-10 deck the way BR-DECK-001 places a level-9 deck (its banner says the sub-decks below can hold only cards). Asked in the popup during Task 7. |
| C-O7 | **`MxListRow` gains an optional `titleMatch` range** drawn in the `rowTitleMatch` role, one line as before. The plan forbade a new slot and had the search hit row redraw the list row, but that needs `Icon(color:)` for the chevron, which the guard bans. `rowTitleMatch` now builds on `listRowTitle`. Asked in the popup during Task 8. |

## Plan rulings

| # | Ruling |
|---|---|
| C-L1 | **No coloured glyph in feature code.** The guard bans `Icon(color:)` in presentation. The deck row's meta is text only ("4 sub-decks · 1,248 cards"), without the artifact's small layers and copy glyphs. The due strip's tile is an `MxIconTile` (tinted primary), not a solid primary square. |
| C-L2 | **No per-site text styling.** The row name uses `rowTitle` (14/600), not the artifact's 14/700. The search match gets a named role, `rowTitleMatch`, in `MxTextStyles`. |
| C-L3 | **"Review algorithm" opens the scheduler sheet until phase D** replaces it with screen 02. The row's label and subtitle follow the handoff now. |
| C-L4 | **Reorder moves into the action sheet at both levels.** The root app bar loses its reorder action, which closes UI-base debt row 72. Reorder mode itself, with its Done button and drag handles, is unchanged. |
| C-L5 | **A gone deck shows an empty state** instead of the snackbar and pop (spec A8, superseding P2-L7). An operation refused because its deck vanished still shows its snackbar (UC-DECK-002 E1). |
| C-L6 | **Row actions read the deck's `DeckView`** (`deckViewProvider(id).future`) when `⋮` is tapped. The dialogs and sheets that follow take the same inputs as today. |

## Global Constraints

- **Scope:**
  - `lib/features/deck/` (presentation, plus the two read-model additions);
  - `lib/core/database/queries/deck_queries.drift` and `card_queries.drift` (a column added to three SELECTs, no schema change);
  - `lib/shared/widgets/mx_empty_state.dart`, `mx_action_sheet_command_row.dart`;
  - `lib/core/theme/foundations/app_icons.dart`, `lib/core/theme/mx_text_styles.dart`;
  - `lib/l10n/app_en.arb`, `app_vi.arb`;
  - tests, goldens of changed screens, docs.
  - `card/presentation` does not change; screen 07 is phase E.
- **Import map:** `deck → {srs}` only. `deck` never imports `card`, and nothing imports `app/`.
- **Guard at 0/0:**
  - no raw Material widgets and no `Icon(color:)` in presentation;
  - no `.copyWith` on `textStyles`;
  - no `ref.read` lexically in `build()`;
  - `build()` within `flutter.max_build_lines`;
  - no defaulted provider or notifier parameter;
  - ARB `placeholders` before `description`.
- **Copy** in `app_en.arb` (with `@key`) and `app_vi.arb`. Run `flutter gen-l10n` after ARB edits and `dart run build_runner build --delete-conflicting-outputs` after `.drift` or `@riverpod` edits.
- **Tests** run on the real backend (`libraryTest`, `pumpLibraryScreen`, `deckScreen()`). Goldens are 3x, light and dark, in Latin text.
- **Golden hygiene:** a golden run rewrites the 21 tracked `test/**/failures/*.png` and adds untracked ones. After each golden run, restore the tracked ones (`git checkout -- $(git diff --name-only | grep /failures/)`) and delete the untracked ones. Never commit them.
- **Gate:** as in phase B. Every non-golden test passes. Goldens fail only where they fail on `master` in this environment (57 on `cae85e5`), minus the ones this phase regenerates.
- **Commit trailer:**
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PJDjKsfDm9reH3a8cML75G
  ```

## Review Focus

- **The due filter is on at an open deck.** Expected: the summary card still says every sub-deck and every card, and the header reads "Decks with due cards" (Task 7 test "the summary counts every sub-deck under the due filter").
- **A row's `⋮` is tapped while that deck is being deleted elsewhere.** Expected: no sheet opens, and a snackbar says the deck is gone. No crash (Task 5 test "a row's actions on a vanished deck say so").
- **A search term with diacritics and capitals ("ĂN", "hoc").** Expected: "Ăn uống" matches "ĂN" with "Ăn" emphasised; "hoc" does not match "học" (Task 8 tests).
- **At text scale 2 on a 360-wide phone:** row name, due badge and `⋮` do not overflow, and the strip's text wraps (Task 5 and Task 6 golden-free overflow tests).
- **Disabled controls in TalkBack:** the Starter decks, Tags and Trash actions, "Study this deck", "Study options" and "Browse starter decks" are announced as disabled buttons and do nothing (Tasks 3, 5 and 6 tests).

---

### Task 1: Spec and handoff record this phase's decisions

**Files:**
- Modify: `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` (§5 table, §6 table, §8 "Goldens on Linux")
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md` (Deviations table)
- Modify: `docs/shared/ui/screen-handoff/04-library-search.md` (Deviations table)

- [ ] **Step 1: Extend the spec**

Append to the §5 table:

```markdown
| `deck` domain | `DeckLevel.deckCount`: every deck of the level whatever the filter, for the open deck's summary (phase C, owner decision C-O1). |
| `deck` domain + data, `deck_queries.drift`, `card_queries.drift` | `contentType` on `DeckTreeNode` and `DeckSearchHit`, read from `d.content_type` in the three queries that share `DeckForestRow` (C-O2). No schema change. |
```

Append to the §6 table:

```markdown
| `MxEmptyState` | An optional secondary action between the primary action and the footnote; a null callback draws it disabled (C-O3). |
| `MxActionSheetCommandRow` | `isEnabled`: a disabled command is dimmed and announced as disabled. |
| Theme | Icons `starterDecks`, `dueNow`, `cardDeck`; text role `rowTitleMatch` for the emphasised part of a search hit (C-O4). |
```

In §8, replace the "Goldens on Linux (FE-D1)" bullet with:

```markdown
- **Goldens on Linux (FE-D1):** a phase regenerates, on Linux, only the goldens of the screens it changes (owner decision, 2026-09-24). The other goldens stay as the owner's platform produced them, and fail on Linux as before.
```

- [ ] **Step 2: Extend the handoff deviation tables**

In `01-deck-list.md`, append to "Deviations":

```markdown
| Layers and copy glyphs in the row's meta | Text only: "4 sub-decks · 1,248 cards" | Guard: no `Icon(color:)` in feature code |
| Solid primary tile on the due strip | Tinted `MxIconTile` | Guard: no `Icon(color:)` in feature code |
| Row name 14/700 | `rowTitle`, 14/600 | Guard: no per-site text styling |
| "Review algorithm" opens screen 02 | Opens the scheduler sheet until phase D | Spec §9 row D |
```

In `04-library-search.md`, append to "Deviations":

```markdown
| Match emphasised in primary 700 with a tinted mark | `rowTitleMatch` (primary, 700), no background mark | Guard: no per-site decoration of text |
```

- [ ] **Step 3: Docs check and commit**

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), 69 warning(s)`.

```bash
git add docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md docs/shared/ui/screen-handoff
git commit -m "docs(spec): record the phase C decisions" -m "<trailer>"
```

---

### Task 2: `DeckLevel.deckCount` and the search hit's content type

**Files:**
- Modify: `lib/features/deck/domain/models/deck_level_model.dart`
- Modify: `lib/features/deck/domain/models/deck_tree_model.dart` (`DeckTreeNode`)
- Modify: `lib/features/deck/domain/models/deck_search_hit_model.dart`
- Modify: `lib/core/database/queries/deck_queries.drift` (`deckMoveTargets`, `deckSearchScope`)
- Modify: `lib/core/database/queries/card_queries.drift` (`cardMoveTargets`)
- Modify: `lib/features/deck/data/repositories/deck_repository_impl.dart` (`_nodeOf`, `watchSearch`)
- Modify: any other file that builds a `DeckTreeNode` directly (find them with `grep -rn "DeckTreeNode(" lib test`)
- Test: `test/features/deck/domain/deck_level_model_test.dart`, `test/features/deck/data/deck_navigation_read_test.dart`

**Interfaces:**
- Produces:
  - `DeckLevel.deckCount` (`int`);
  - `DeckTreeNode.contentType` (`DeckContentType`), required;
  - `DeckSearchHit.contentType` (`DeckContentType`), required.

- [ ] **Step 1: Write the failing tests**

In `deck_level_model_test.dart`, next to the existing `DeckLevel.of` tests (they build `tiles` with a local helper), add:

```dart
  test('deckCount counts every deck of the level, whatever the filter', () {
    final level = DeckLevel.of(tiles, filter: DeckLevelFilter.due);

    expect(level.deckCount, tiles.length);
    expect(level.tiles.length, lessThan(tiles.length));
  });
```

Use the test group's existing `tiles` fixture. If no tile in it is idle, so that the due filter would keep all of them, build one local list with the file's tile helper: one due tile and one idle tile. Then assert `deckCount == 2` and `tiles.length == 1`.

In `deck_navigation_read_test.dart`, inside `group('watchSearch (IT-DISC-006)', ...)`, add:

```dart
    test('each hit carries what its deck holds', () async {
      final eat = (await repo
              .watchSearch(scopeDeckId: null, foldedTerm: 'ăn uống')
              .first)
          .single;
      await insertCard(db, id: 'meal', deckId: eat.id);

      final hits = {
        for (final hit in await repo
            .watchSearch(scopeDeckId: null, foldedTerm: '')
            .first)
          hit.name: hit.contentType,
      };

      expect(hits['D-EB'], DeckContentType.deck);
      expect(hits['Vocabulary'], DeckContentType.deck);
      expect(hits['Academic words'], DeckContentType.unset);
      expect(hits['Ăn uống'], DeckContentType.card);
    });
```

Add the imports `package:memox/features/deck/domain/models/deck_content_type_model.dart` and `../../../support/card_fixtures.dart` if missing. An empty folded term matches every name (`contains('')`).

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/domain/deck_level_model_test.dart test/features/deck/data/deck_navigation_read_test.dart`
Expected: compile errors: `deckCount` and `contentType` are not defined.

- [ ] **Step 3: Implement**

`deck_level_model.dart`:
- add `required this.deckCount,` to `DeckLevel._`, and `final int deckCount;` with the doc `/// Every deck of the level, whatever the filter (the open deck's summary).`;
- in `DeckLevel.of`, pass `deckCount: tiles.length,`, where `tiles` is the unfiltered input.

`deck_tree_model.dart`: add `required this.contentType,` and `final DeckContentType contentType;` to `DeckTreeNode`, importing `deck_content_type_model.dart`.

`deck_search_hit_model.dart`: add `required this.contentType,` and:

```dart
  /// What the deck holds, so a hit can say it (screen 04).
  final DeckContentType contentType;
```

Queries: in each of `deckMoveTargets`, `deckSearchScope` and `cardMoveTargets`, change the select list from `SELECT d.id, d.name, d.parent_id, d.sibling_position,` to `SELECT d.id, d.name, d.parent_id, d.sibling_position, d.content_type,`. The three queries share `DeckForestRow`, so they must return the same columns.

`deck_repository_impl.dart`:
- `_nodeOf` adds `contentType: DeckContentType.values.byName(row.contentType),`;
- `watchSearch` builds `DeckSearchHit(id: node.id, name: node.name, path: path, contentType: node.contentType)`.

Update every other `DeckTreeNode(` constructor call the grep finds (tests included), passing `contentType: DeckContentType.deck` where the test does not care.

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run the tests to verify they pass**

Run:
```bash
flutter test test/features/deck/domain test/features/deck/data test/features/card/data
```
Expected: PASS. The card data tests cover `cardMoveTargets`.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add lib test
git commit -m "feat(deck): the level's deck count and each search hit's content type" -m "<trailer>"
```

---

### Task 3: Shared additions: the secondary action, disabled commands, icons, the match role

**Files:**
- Modify: `lib/shared/widgets/mx_empty_state.dart`
- Modify: `lib/shared/widgets/mx_action_sheet_command_row.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/core/theme/mx_text_styles.dart`
- Test: `test/shared/widgets/mx_empty_state_test.dart`, `test/shared/widgets/mx_action_sheet_command_row_test.dart`, `test/core/theme/mx_text_styles_test.dart` (use the file names that exist; `ls test/shared/widgets test/core/theme`)

**Interfaces:**
- Produces:
  - `MxEmptyState({..., String? secondaryActionLabel, VoidCallback? onSecondaryAction})`. The label alone draws the button disabled.
  - `MxActionSheetCommandRow({..., bool isEnabled = true})`.
  - `AppIcons.starterDecks`, `AppIcons.dueNow`, `AppIcons.cardDeck`.
  - `MxTextStyles.rowTitleMatch`.

- [ ] **Step 1: Write the failing tests**

`MxEmptyState`:

```dart
  testWidgets('a secondary action sits between the action and the footnote', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.library,
        title: 'Start your library',
        actionLabel: 'Create deck',
        onAction: () {},
        secondaryActionLabel: 'Browse starter decks',
        footnote: 'Everything stays on this device.',
      ),
    );
    final primary = tester.getTopLeft(find.text('Create deck')).dy;
    final secondary = tester.getTopLeft(find.text('Browse starter decks')).dy;
    final note = tester.getTopLeft(find.text('Everything stays on this device.')).dy;

    expect(primary, lessThan(secondary));
    expect(secondary, lessThan(note));
  });

  testWidgets('a secondary action without a callback is disabled', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.library,
        title: 'Start your library',
        secondaryActionLabel: 'Browse starter decks',
      ),
    );
    final button = tester.widget<MxButton>(
      find.widgetWithText(MxButton, 'Browse starter decks'),
    );

    expect(button.onPressed, isNull);
    expect(button.tone, MxButtonTone.secondary);
  });
```

`MxActionSheetCommandRow`:

```dart
  testWidgets('a disabled command is dimmed, announced disabled, and inert', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxActionSheetCommandRow(
        icon: AppIcons.play,
        label: 'Study this deck',
        onTap: () => taps++,
        isEnabled: false,
      ),
    );
    await tester.tap(find.text('Study this deck'));

    expect(taps, 0);
    expect(find.byType(Opacity), findsWidgets);
    expect(
      tester.getSemantics(find.byType(MxActionSheetCommandRow)),
      isSemantics(isButton: true, isEnabled: false),
    );
    semantics.dispose();
  });
```

`MxTextStyles` (in the text styles test, next to the other role tests, with the file's existing `styles` fixture for the light scheme):

```dart
  test('rowTitleMatch is the row title, bold, in primary', () {
    expect(styles.rowTitleMatch.fontSize, styles.rowTitle.fontSize);
    expect(styles.rowTitleMatch.fontWeight, FontWeight.w700);
    expect(styles.rowTitleMatch.color, AppColorSchemes.light.primary);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets test/core/theme`
Expected: compile errors for `secondaryActionLabel`, `isEnabled` and `rowTitleMatch`.

- [ ] **Step 3: Implement**

`MxEmptyState`:
- add the fields `secondaryActionLabel` and `onSecondaryAction` with the doc `/// A second, quieter action; drawn disabled when [onSecondaryAction] is null.`;
- add the assert `onSecondaryAction == null || secondaryActionLabel != null`, message `'onSecondaryAction needs secondaryActionLabel'`;
- in `build`, after the primary action block and before the footnote:

```dart
              if (secondaryActionLabel case final label?) ...[
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: label,
                  tone: MxButtonTone.secondary,
                  onPressed: onSecondaryAction,
                  isBlock: true,
                ),
              ],
```

`MxActionSheetCommandRow`: add `this.isEnabled = true,` and `final bool isEnabled;` with the doc `/// A command that exists but cannot run yet: dimmed, announced disabled.`. Pass `isEnabled: isEnabled` to its `MxRowInk`, which already dims and announces a disabled row.

`AppIcons` (in the file's style, each with the kit's glyph name as the comment):

```dart
  static const IconData starterDecks = Icons.auto_awesome_outlined; // sparkles
  static const IconData dueNow = Icons.bolt_outlined; // zap
  static const IconData cardDeck = Icons.copy_all_outlined; // copy
```

`MxTextStyles`, next to `rowTitle`:

```dart
  /// The matched part of a search hit's name (screen 04): the row title,
  /// bold, in primary.
  TextStyle get rowTitleMatch => AppTypography.withWeight(
    rowTitle,
    FontWeight.w700,
  ).copyWith(color: _scheme.primary);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets test/core/theme --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared lib/core/theme test/shared test/core
git commit -m "feat(ui): empty-state secondary action, disabled commands, three icons, the match role" -m "<trailer>"
```

---

### Task 4: The phase's copy

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/l10n/` (if an ARB parity test exists, it covers this; otherwise `flutter gen-l10n` and `flutter analyze` are the check)

**Interfaces:**
- Produces: the keys below, used by Tasks 5–8.

- [ ] **Step 1: Add the keys**

Add to `app_en.arb`, each with its `@key` (placeholders before description). Add the Vietnamese value to `app_vi.arb`.

| Key | en | vi | Placeholders |
|---|---|---|---|
| `libraryStarterDecks` | Starter decks | Bộ thẻ mẫu | — |
| `libraryTags` | Tags | Tag | — |
| `libraryTrash` | Trash | Thùng rác | — |
| `libraryDueTitle` | `{count, plural, =1{1 card due} other{{count} cards due}}` | `{count} thẻ đến hạn` | count int |
| `libraryDecksCount` | `{count, plural, =1{1 deck} other{{count} decks}}` | `{count} bộ thẻ` | count int |
| `libraryDueDecksHeader` | Decks with due cards | Bộ thẻ có thẻ đến hạn | — |
| `libraryBrowseStarter` | Browse starter decks | Xem bộ thẻ mẫu | — |
| `libraryEmptyFootnote` | Everything stays on this device. Nothing is added until you choose. | Mọi thứ nằm trên máy này. Không gì được thêm cho tới khi bạn chọn. | — |
| `deckSubDeckCount` | `{count, plural, =1{1 sub-deck} other{{count} sub-decks}}` | `{count} bộ thẻ con` | count int |
| `deckCardCount` | `{count, plural, =1{1 card} other{{count} cards}}` | `{count} thẻ` | count int |
| `deckRowMeta` | `{subDecks} · {cards}` | `{subDecks} · {cards}` | subDecks String, cards String |
| `deckRowEmpty` | Empty · add cards or a sub-deck | Trống · thêm thẻ hoặc bộ thẻ con | — |
| `deckDueBadge` | `{count} due` | `{count} đến hạn` | count int |
| `deckMoreActions` | More actions for {name} | Thêm thao tác cho {name} | name String |
| `deckSortPillDueOnly` | `{sort} · Due only` | `{sort} · Chỉ đến hạn` | sort String |
| `deckSortFilterTitle` | Sort & filter | Sắp xếp và lọc | — |
| `deckSortByHeader` | Sort by | Sắp xếp theo | — |
| `deckSortManualHint` | Drag decks to arrange them | Kéo bộ thẻ để xếp | — |
| `deckSortRecentHint` | Newest first | Mới nhất trước | — |
| `deckSortNameHint` | A → Z | A → Z | — |
| `deckSortProgress` | Progress | Tiến độ | — |
| `deckSortProgressHint` | Least mastered first | Ít thuộc nhất trước | — |
| `deckFilterDueOnlyTitle` | Only decks with due cards | Chỉ bộ thẻ có thẻ đến hạn | — |
| `deckFilterDueOnlyBody` | Hides decks where nothing is waiting | Ẩn bộ thẻ không có gì đang chờ | — |
| `commonDone` | Done | Xong | — (skip if it exists) |
| `deckOpen` | Open deck | Mở bộ thẻ | — |
| `deckStudyThis` | Study this deck | Học bộ thẻ này | — |
| `deckStudyThisDue` | `Study this deck · {count} due` | `Học bộ thẻ này · {count} đến hạn` | count int |
| `deckStudyOptions` | Study options | Tuỳ chọn học | — |
| `deckStudyOptionsHint` | Cards per session · new-card order | Số thẻ mỗi phiên · thứ tự thẻ mới | — |
| `deckReviewAlgorithm` | Review algorithm | Thuật toán ôn tập | — |
| `deckReviewAlgorithmLocked` | `{algorithm} · locked · reset to start over` | `{algorithm} · đã khoá · đặt lại để bắt đầu lại` | algorithm String |
| `deckReorderHint` | Move before or after a sibling | Đưa lên trước hoặc sau một bộ thẻ cùng cấp | — |
| `deckScheduledCount` | `{count} scheduled` | `{count} đã lên lịch` | count int |
| `deckDepthHeader` | `{count} sub-decks · level 10` | `{count} bộ thẻ con · cấp 10` | count int |
| `deckGoneTitle` | This deck is no longer here | Bộ thẻ này không còn nữa | — |
| `deckGoneBody` | It was deleted while you were away. | Nó đã bị xoá trong lúc bạn không ở đây. | — |
| `deckBackToLibrary` | Back to Library | Về Thư viện | — |
| `deckOpenTrash` | Open Trash | Mở thùng rác | — |
| `searchFinds` | Search finds | Tìm kiếm tìm được | — |
| `searchHintDeckName` | a deck name | tên một bộ thẻ | — |
| `searchHintDeckExample` | TOPIK, Học qua phim | TOPIK, Học qua phim | — |
| `searchAccentNote` | Case does not matter, accents do: “hoc” will not find “học”. | Chữ hoa hay thường không quan trọng, dấu thì có: “hoc” không tìm ra “học”. | — |
| `searchSearching` | Searching for “{term}”… | Đang tìm “{term}”… | term String |
| `searchResultsFor` | Results for “{term}” | Kết quả cho “{term}” | term String |
| `searchDecksGroup` | Decks | Bộ thẻ | — |
| `searchHoldsCards` | `{path} · holds cards` | `{path} · chứa thẻ` | path String |
| `searchHoldsDecks` | `{path} · holds sub-decks` | `{path} · chứa bộ thẻ con` | path String |
| `searchHoldsNothing` | `{path} · empty` | `{path} · trống` | path String |
| `searchErrorTitle` | Search didn't run | Không tìm được | — |
| `searchErrorBody` | Your library is safe on this device. Try again in a moment. | Thư viện của bạn vẫn an toàn trên máy này. Hãy thử lại sau giây lát. | — |

Change these existing values in both files:

| Key | en | vi |
|---|---|---|
| `libraryEmptyTitle` | Start your library | Bắt đầu thư viện của bạn |
| `libraryEmptyBody` | A deck groups the sub-decks that hold your cards. Create one to begin. | Một bộ thẻ gom các bộ thẻ con chứa thẻ của bạn. Hãy tạo một bộ để bắt đầu. |
| `libraryNothingDueTitle` | Nothing due right now | Hiện không có gì đến hạn |
| `libraryNothingDueBody` | No deck has cards waiting. | Không bộ thẻ nào có thẻ đang chờ. |
| `deckSearchHint` | Search decks | Tìm bộ thẻ |
| `deckSearchEmptyTitle` | No matches for “{term}” | Không có kết quả cho “{term}” |
| `deckSearchEmptyBody` | Accents matter — “hoc” does not find “học”. Search covers deck names. | Dấu có ý nghĩa — “hoc” không tìm ra “học”. Tìm kiếm chỉ xét tên bộ thẻ. |
| `deckChangeScheduler` | Review algorithm | Thuật toán ôn tập |

Leave the other existing keys as they are. Keys only the removed widgets used are deleted in Task 9, after their last use goes.

- [ ] **Step 2: Generate and check**

Run: `flutter gen-l10n && flutter analyze`
Expected: "No issues found!". If the repo has an ARB parity test (`grep -rln "app_vi.arb" test`), run it.

- [ ] **Step 3: Commit**

```bash
git add lib/l10n
git commit -m "feat(l10n): copy for screens 01 and 04 of the screen handoff" -m "<trailer>"
```

---

### Task 5: The deck row and its action sheet

**Files:**
- Modify: `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Create: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (rows become cards, 8 apart)
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart` (`_OpenDeckContent._openActions` moves to the flow)
- Test: `test/features/deck/presentation/deck_action_sheet_test.dart`, `test/features/deck/presentation/deck_row_widget_test.dart` (new)

**Interfaces:**
- Consumes: `DeckTile` (subDeckCount, cardCount, dueCount, name, id); `deckViewProvider(id)`; `deckLevelCanReorderProvider(parentId)`; the existing dialog and sheet helpers; Task 3 `isEnabled`; Task 4 keys.
- Produces:
  - `DeckRowWidget({required DeckTile tile, required VoidCallback onTap, required VoidCallback onMore})`.
  - `Future<void> openDeckActions(BuildContext context, WidgetRef ref, {required String deckId, required String? parentId, required ValueChanged<String> onOpenDeck, required bool isOpenDeck})`.
  - `enum DeckAction { open, rename, move, changeScheduler, reorder, delete }`.

`DeckTile` carries no content type, and its `subDeckCount` and `cardCount` already say what the deck holds. So the row picks its tile glyph from those counts: `subDeckCount > 0` → `AppIcons.library`, `cardCount > 0` → `AppIcons.cardDeck`, neither → `AppIcons.folder`, with the meta "Empty · add cards or a sub-deck". This needs no read-model change.

- [ ] **Step 1: Write the failing row tests**

`test/features/deck/presentation/deck_row_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _today = DateTime(2026, 9, 24);

DeckTile _tile({
  String name = 'Korean',
  int subDecks = 4,
  int cards = 1248,
  int overdue = 41,
  int today = 45,
}) => DeckTile(
  id: 'k',
  name: name,
  siblingPosition: 0,
  createdAt: _today,
  schedulerType: SchedulerType.sm2,
  subDeckCount: subDecks,
  cardCount: cards,
  newCount: 0,
  overdueCount: overdue,
  dueTodayCount: today,
  oldestDueAt: overdue > 0 ? DateTime(2026, 9, 20) : null,
  startOfToday: _today,
);

void main() {
  Future<void> pump(WidgetTester tester, DeckTile tile, {VoidCallback? onMore}) =>
      pumpMx(
        tester,
        DeckRowWidget(tile: tile, onTap: () {}, onMore: onMore ?? () {}),
      );

  testWidgets('a card with the name, the due badge and the structure line', (
    tester,
  ) async {
    await pump(tester, _tile());

    expect(find.byType(MxCard), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.widgetWithText(MxBadge, _en.deckDueBadge(86)), findsOneWidget);
    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(4), _en.deckCardCount(1248))),
      findsOneWidget,
    );
  });

  testWidgets('no badge when nothing is due; an empty deck says so', (
    tester,
  ) async {
    await pump(tester, _tile(subDecks: 0, cards: 0, overdue: 0, today: 0));

    expect(find.byType(MxBadge), findsNothing);
    expect(find.text(_en.deckRowEmpty), findsOneWidget);
  });

  testWidgets('⋮ is its own button, named for the deck', (tester) async {
    var more = 0;
    await pump(tester, _tile(), onMore: () => more++);

    await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
    expect(more, 1);
  });

  testWidgets('a long name at text scale 2 on a 360 phone does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMx(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: DeckRowWidget(
          tile: _tile(name: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi'),
          onTap: () {},
          onMore: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
```

If `pumpMx` sets its own `MediaQuery`, wrap only the row as shown. The inner `MediaQuery` wins.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_row_widget_test.dart`
Expected: compile error, no named parameter `onMore`.

- [ ] **Step 3: Implement the row**

Replace the widget in `deck_row_widget.dart` with:

```dart
/// One deck of a level (screen 01): a card with the deck's tile, its name,
/// "N due" when cards wait, what it holds, and ⋮ for its commands. A tap
/// anywhere else opens it.
class DeckRowWidget extends StatelessWidget {
  const DeckRowWidget({
    super.key,
    required this.tile,
    required this.onTap,
    required this.onMore,
  });

  final DeckTile tile;
  final VoidCallback onTap;
  final VoidCallback onMore;

  IconData get _glyph => switch (tile) {
    DeckTile(subDeckCount: > 0) => AppIcons.library,
    DeckTile(cardCount: > 0) => AppIcons.cardDeck,
    _ => AppIcons.folder,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmpty = tile.subDeckCount == 0 && tile.cardCount == 0;
    return MxCard(
      isFullBleed: true,
      child: MxRowInk(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.micro,
            AppSpacing.gutter,
          ),
          child: Row(
            spacing: AppSpacing.gutter,
            children: [
              MxIconTile(icon: _glyph, size: MxIconTileSize.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Row(
                      spacing: AppSpacing.control,
                      children: [
                        Expanded(
                          child: Text(
                            tile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.rowTitle,
                          ),
                        ),
                        if (tile.dueCount > 0)
                          MxBadge(label: l10n.deckDueBadge(tile.dueCount)),
                      ],
                    ),
                    Text(
                      isEmpty
                          ? l10n.deckRowEmpty
                          : l10n.deckRowMeta(
                              l10n.deckSubDeckCount(tile.subDeckCount),
                              l10n.deckCardCount(tile.cardCount),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.rowSubtitle,
                    ),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.more,
                semanticLabel: l10n.deckMoreActions(tile.name),
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Replace the imports with those the widget uses: `material.dart`, `app_icons.dart`, `app_spacing.dart`, `theme_context.dart`, `deck_level_model.dart`, `l10n_context.dart`, `mx_badge.dart`, `mx_card.dart`, `mx_icon_button.dart`, `mx_icon_tile.dart`, `mx_row_ink.dart`. The ⋮ button's own hit area wins over the row's ink.

- [ ] **Step 4: Rows become separated cards**

In `deck_level_list_widget.dart`, replace the `MxCard(isFullBleed: true, child: Column(... DeckRowWidget ...))` block with:

```dart
          Column(
            spacing: AppSpacing.control,
            children: [
              for (final tile in tiles)
                DeckRowWidget(
                  tile: tile,
                  onTap: () => onOpenDeck(tile.id),
                  onMore: () => unawaited(
                    openDeckActions(
                      context,
                      ref,
                      deckId: tile.id,
                      parentId: parentId,
                      onOpenDeck: onOpenDeck,
                      isOpenDeck: false,
                    ),
                  ),
                ),
            ],
          ),
```

Add `import 'dart:async';` and the flow import.

- [ ] **Step 5: The action sheet and the flow**

`deck_action_sheet_widget.dart`:
- `enum DeckAction { open, rename, move, changeScheduler, reorder, delete }`;
- `showDeckActionSheet(context, {required DeckView view, required bool canReorder, required bool offersOpen})` passes `offersOpen` on.

Replace the sheet's header with a tile, the name, and "N sub-decks · N cards · {algorithm}". The counts are not in `DeckView`, so the header shows the name and, for a root, the algorithm name only: `l10n.schedulerType(view.schedulerType)`. Replace the rows with:

```dart
            if (offersOpen)
              MxActionSheetCommandRow(
                icon: AppIcons.folder,
                label: l10n.deckOpen,
                onTap: () => choose(DeckAction.open),
              ),
            MxActionSheetCommandRow(
              icon: AppIcons.play,
              label: l10n.deckStudyThis,
              onTap: () {},
              isEnabled: false,
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: l10n.deckRename,
              onTap: () => choose(DeckAction.rename),
            ),
            if (deck.isRoot) ...[
              MxActionSheetCommandRow(
                icon: AppIcons.settings,
                label: l10n.deckStudyOptions,
                subtitle: l10n.deckStudyOptionsHint,
                onTap: () {},
                isEnabled: false,
              ),
              MxActionSheetCommandRow(
                icon: AppIcons.scheduler,
                label: l10n.deckReviewAlgorithm,
                subtitle: view.isSchedulerLocked
                    ? l10n.deckReviewAlgorithmLocked(
                        l10n.schedulerType(view.schedulerType),
                      )
                    : l10n.schedulerType(view.schedulerType),
                hasChevron: true,
                onTap: () => choose(DeckAction.changeScheduler),
              ),
            ],
            if (!deck.isRoot)
              MxActionSheetCommandRow(
                icon: AppIcons.folder,
                label: l10n.deckMove,
                hasChevron: true,
                onTap: () => choose(DeckAction.move),
              ),
            if (canReorder)
              MxActionSheetCommandRow(
                icon: AppIcons.reorder,
                label: l10n.deckReorder,
                subtitle: l10n.deckReorderHint,
                onTap: () => choose(DeckAction.reorder),
              ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.deckDelete,
              isDestructive: true,
              onTap: () => choose(DeckAction.delete),
            ),
```

`deck_actions_flow_widget.dart`:

```dart
/// Opens a deck's action sheet and then the chosen command's own dialog or
/// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮. It reads
/// the deck's view first, so a deck gone meanwhile says so instead.
Future<void> openDeckActions(
  BuildContext context,
  WidgetRef ref, {
  required String deckId,
  required String? parentId,
  required ValueChanged<String> onOpenDeck,
  required bool isOpenDeck,
}) async {
  final outcome = await ref.read(deckViewProvider(deckId).future);
  if (!context.mounted) return;
  final view = switch (outcome) {
    Ok(:final value) => value,
    Rejected() => null,
  };
  if (view == null) {
    showMxSnackbar(context, message: context.l10n.deckDeletedToast);
    return;
  }
  // The open deck reorders its children; a row reorders its siblings.
  final reorderLevel = isOpenDeck ? deckId : parentId;
  final canReorder = ref.read(deckLevelCanReorderProvider(reorderLevel));
  final action = await showDeckActionSheet(
    context,
    view: view,
    canReorder: canReorder,
    offersOpen: !isOpenDeck,
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case DeckAction.open:
      onOpenDeck(deckId);
    case DeckAction.rename:
      await showRenameDeckDialog(context, deck: view.deck);
    case DeckAction.move:
      await showMoveDeckSheet(context, deck: view.deck);
    case DeckAction.changeScheduler:
      await showDeckSchedulerSheet(context, view: view);
    case DeckAction.reorder:
      ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
    case DeckAction.delete:
      await showDeleteDeckDialog(context, deck: view.deck);
  }
}
```

A row's `canReorder` is the level's own `deckLevelCanReorderProvider(parentId)`. A root row's is the roots' level, `null`.

In `deck_level_screen.dart`, delete `_OpenDeckContent._openActions` and make the open deck's ⋮ call `openDeckActions(context, ref, deckId: deck.id, parentId: deck.parentId, onOpenDeck: onOpenDeck, isOpenDeck: true)`.

- [ ] **Step 6: Update the action sheet tests**

In `deck_action_sheet_test.dart`:
- keep opening the sheet from the open deck's ⋮ (`find.byTooltip(_en.deckActions)`); its rows are now the lists above;
- replace `find.text(_en.deckChangeScheduler)` with `find.text(_en.deckReviewAlgorithm)`, and `_choose(tester, _en.deckChangeScheduler)` with `_choose(tester, _en.deckReviewAlgorithm)`;
- the root test also expects `find.text(_en.deckStudyOptions)` and `find.text(_en.deckStudyThis)`. Assert the latter is disabled: `tester.widget<MxActionSheetCommandRow>(find.widgetWithText(MxActionSheetCommandRow, _en.deckStudyThis)).isEnabled` is false.

Add:

```dart
  libraryTest('a row’s ⋮ opens that deck’s sheet, with Open first', (
    tester,
    env,
  ) async {
    await env.decks.root('Korean');
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());

    await tester.tap(find.byTooltip(_en.deckMoreActions('Kanji')));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckOpen), findsOneWidget);
    expect(find.text(_en.deckReorder), findsOneWidget);
  });

  libraryTest('a row’s actions on a vanished deck say so', (tester, env) async {
    final kanji = await env.decks.root('Kanji');
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen());
    final more = find.byTooltip(_en.deckMoreActions('Kanji'));

    await env.decks.delete(kanji.id);
    await tester.tap(more, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckOpen), findsNothing);
  });
```

`env.decks.delete` is the fixture helper that deletes a deck. If the fixture names it differently, use its delete (read `test/support/deck_fixtures.dart`). After the delete the row may already be gone before the tap; `warnIfMissed: false` covers both orders. The expectation holds either way.

- [ ] **Step 7: Run to verify they pass**

Run: `flutter test test/features/deck/presentation --exclude-tags golden`
Expected: the new row tests and the updated sheet tests pass. Tests that still expect the old root reorder action or the old header fail here and are migrated in Task 6. Record their names; they must be green by the end of Task 6.

- [ ] **Step 8: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/deck test/features/deck
git commit -m "feat(deck): deck rows as cards with their own action sheet" -m "<trailer>"
```

---

### Task 6: The Library root

**Files:**
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart` (`_LibraryRoot`)
- Create: `lib/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (root context, header, nothing-due state)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_header_widget.dart` (count label, one pill)
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart` (one sort & filter sheet)
- Test: `test/features/deck/presentation/deck_level_screen_test.dart`, `deck_reorder_test.dart`, `test/app/library_routes_test.dart`, `test/app/app_test.dart`

**Interfaces:**
- Consumes: Task 3 (`MxEmptyState` secondary, icons), Task 4 keys, phase B `MxSearchField.trigger`.
- Produces: `DeckDueStripWidget({required DeckLevel level})`; `showDeckSortFilterSheet(BuildContext, {required String? parentId})`.

- [ ] **Step 1: Migrate and write the root tests**

In `deck_level_screen_test.dart`:
- **"first run"**: after the Create deck tap, also expect `find.text(_en.libraryBrowseStarter)`, with its `MxButton.onPressed == null`, and `find.text(_en.libraryEmptyFootnote)`.
- **"the level line leads…"**: rename to `'the due strip leads; each deck carries its due badge'`, and expect `find.text(_en.libraryDueTitle(2))`, the rich line `'1 overdue · 1 today · 1 new'` exactly once (`findsOneWidget`), and `find.widgetWithText(MxBadge, _en.deckDueBadge(2))` for Korean. Keep the "strip above Korean" position check on `find.text(_en.libraryDueTitle(2))`. Remove the `workloadNoCards` expectation: rows no longer carry a workload line.
- **"sort by name…"**: open the pill `find.text(_en.deckSortManual)`, tap `find.text(_en.deckSortName)`, tap `find.text(_en.commonDone)`, then expect `find.text(_en.deckSortName)` as the pill.
- **"the due filter hides idle decks…"**: open the pill, flip the toggle (`find.byType(MxToggle)`), tap Done. Expect `find.text(_en.libraryDueDecksHeader)` and the pill `find.text(_en.deckSortPillDueOnly(_en.deckSortManual))`. Where no deck is due, expect `libraryNothingDueTitle`.
- **"midnight turns Due today into Overdue…"**: replace `_rich('2 overdue · 1 new'), findsNWidgets(2)` with `findsOneWidget`.

Add:

```dart
  libraryTest('the root app bar offers starter decks, tags and trash, disabled', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    for (final label in [_en.libraryStarterDecks, _en.libraryTags, _en.libraryTrash]) {
      final button = tester.widget<MxIconButton>(
        find.ancestor(of: find.byTooltip(label), matching: find.byType(MxIconButton)),
      );
      expect(button.onPressed, isNull, reason: label);
    }
    expect(find.byTooltip(_en.libraryReorder), findsNothing);
  });

  libraryTest('the search field opens the search', (tester, env) async {
    await _seed(env);
    var searches = 0;
    await pumpLibraryScreen(tester, env, deckScreen(onSearch: () => searches++));

    await tester.tap(find.text(_en.deckSearchHint));
    expect(searches, 1);
  });

  libraryTest('the due strip is display only and gone without cards', (
    tester,
    env,
  ) async {
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.byType(DeckDueStripWidget), findsNothing);
  });
```

If `deckScreen()` does not take `onSearch`, add an optional `VoidCallback? onSearch` to it in `test/support/library_harness.dart` that defaults to a no-op, and pass it through.

In `deck_reorder_test.dart`, start reorder from a row: replace the helper's tap on `find.byTooltip(_en.libraryReorder)` with:

```dart
  await tester.tap(find.byTooltip(_en.deckMoreActions(firstDeckName)).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.deckReorder));
  await tester.pumpAndSettle();
```

`firstDeckName` is the first root the test seeds. Replace `expect(find.byTooltip(_en.libraryReorder), findsNothing/One)` with opening a row's sheet and expecting `find.text(_en.deckReorder)`. For the sort check, open the sort pill instead of `deckSortTrigger`.

In `test/app/library_routes_test.dart`, replace `find.byTooltip(_en.libraryOpenSearch)` with `find.text(_en.deckSearchHint)`. In `test/app/app_test.dart`, the `libraryEmptyTitle` expectation keeps working, because only its value changed.

- [ ] **Step 2: Run to verify the new ones fail**

Run: `flutter test test/features/deck/presentation/deck_level_screen_test.dart`
Expected: FAIL: the strip, the disabled actions and the pill are missing.

- [ ] **Step 3: The due strip**

`deck_due_strip_widget.dart`:

```dart
/// The Library root's bridge to study (screen 01): how many cards wait in
/// the whole library, and overdue · today · new under it. Display only until
/// Study home exists (spec A6).
class DeckDueStripWidget extends StatelessWidget {
  const DeckDueStripWidget({super.key, required this.level});

  final DeckLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = level.overdueCount + level.dueTodayCount;
    return MxCard(
      isHero: true,
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          const MxIconTile(icon: AppIcons.dueNow, size: MxIconTileSize.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(l10n.libraryDueTitle(due), style: context.textStyles.rowTitle),
                DeckWorkloadLineWidget(
                  overdueCount: level.overdueCount,
                  todayCount: level.dueTodayCount,
                  newCount: level.newCount,
                  cardCount:
                      due + level.newCount + level.scheduledCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: The header and the one sheet**

`deck_level_header_widget.dart` becomes:

```dart
/// The level's count, or "Decks with due cards" under the filter, and one
/// pill naming the order (screen 01) that opens the sort & filter sheet.
class DeckLevelHeaderWidget extends ConsumerWidget {
  const DeckLevelHeaderWidget({
    super.key,
    required this.parentId,
    required this.label,
  });

  final String? parentId;

  /// "6 decks", "4 sub-decks", or the filter's heading.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    final sort = l10n.deckSort(query.sort);
    return MxListSectionHeader(
      label: label,
      trailing: MxChipTrigger(
        label: query.filter == DeckLevelFilter.due
            ? l10n.deckSortPillDueOnly(sort)
            : sort,
        icon: AppIcons.sort,
        onPressed: () => showDeckSortFilterSheet(context, parentId: parentId),
      ),
    );
  }
}
```

`deck_level_query_sheets_widget.dart`: replace both sheets with `showDeckSortFilterSheet`. It opens an `MxBottomSheet` with:
- the header title `deckSortFilterTitle`;
- an overline row `deckSortByHeader`;
- one `MxOptionRow` per `DeckLevelSort` (manual `deckSortManualHint`, recent `deckSortRecentHint`, name `deckSortNameHint`, due with no description). Each picks its sort at once through `deckLevelQueryProvider(parentId).notifier.sortBy`;
- one disabled `MxOptionRow` "Progress" (`onSelected: null`, description `deckSortProgressHint`);
- a row with `deckFilterDueOnlyTitle` / `deckFilterDueOnlyBody` and an `MxToggle` bound to `filter == DeckLevelFilter.due`, which calls `.show(DeckLevelFilter.due)` or `.show(DeckLevelFilter.all)`;
- a footer `MxButton(label: l10n.commonDone, isBlock: true)` that closes the sheet.

The sheet is a `ConsumerWidget`, so the toggle and the selected sort redraw live. Keep `deckSort` from `deck_level_query_label_widget.dart`. `deckFilter` goes unused; delete it and its keys in Task 9.

- [ ] **Step 5: The root**

In `deck_level_list_widget.dart`, for the root (`parentId == null`) and a non-empty level:
1. `DeckDueStripWidget(level: level)` when `level.overdueCount + level.dueTodayCount + level.newCount + level.scheduledCount > 0`, then `SizedBox(height: AppSpacing.grouped)`;
2. the header, with `label: filter == DeckLevelFilter.due ? l10n.libraryDueDecksHeader : l10n.libraryDecksCount(level.deckCount)`;
3. the rows, or under an empty filter the `MxEmptyState` "Nothing due right now" with "Show all decks", as today.

The `DeckWorkloadLineWidget` at the top of the list goes; the strip replaces it at the root. For an open deck, Task 7's summary card takes its place.

In `_LibraryRoot`:
- **App bar:** the screen density title `navLibrary` with three disabled `MxIconButton`s:

  ```dart
        actions: isReordering
            ? const [_ReorderDone(parentId: null)]
            : [
                MxIconButton(
                  icon: AppIcons.starterDecks,
                  semanticLabel: l10n.libraryStarterDecks,
                  onPressed: null,
                ),
                MxIconButton(
                  icon: AppIcons.tag,
                  semanticLabel: l10n.libraryTags,
                  onPressed: null,
                ),
                MxIconButton(
                  icon: AppIcons.delete,
                  semanticLabel: l10n.libraryTrash,
                  onPressed: null,
                ),
              ],
  ```

- **Body:** a `Column` of the search trigger, `Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.micro, AppSpacing.gutter, AppSpacing.control), child: MxSearchField.trigger(hintText: l10n.deckSearchHint, onTap: onSearch))`, then `Expanded(child: DeckLevelBodyWidget(...))`.
- **Empty state:** `MxEmptyState(icon: AppIcons.library, title: l10n.libraryEmptyTitle, body: l10n.libraryEmptyBody, actionLabel: l10n.libraryCreateDeck, onAction: createDeck, secondaryActionLabel: l10n.libraryBrowseStarter, footnote: l10n.libraryEmptyFootnote)`.
- **Clean-up:** delete `_startReorder` and the `canReorder` watch.

The search field stays above the body in every state, as in the artifact, because its column sits outside the stream's states.

- [ ] **Step 6: Run to verify they pass**

Run: `flutter test test/features/deck test/app --exclude-tags golden`
Expected: PASS, including the tests Task 5 recorded as pending migration.

- [ ] **Step 7: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): the Library root of screen 01: search, due strip, one sort & filter sheet" -m "<trailer>"
```

---

### Task 7: The open deck

**Files:**
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart` (`_OpenDeck`, `_OpenDeckContent`)
- Create: `lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (open-deck context and header label)
- Test: `test/features/deck/presentation/open_deck_screen_test.dart`, `test/app/library_routes_test.dart`

**Interfaces:**
- Consumes: `DeckView.schedulerType`, `DeckLevel` (`deckCount`, counts), Task 4 keys, `onOpenAncestor`.
- Produces: `DeckSummaryCardWidget({required DeckLevel level, required SchedulerType schedulerType})`; `DeckGoneStateWidget({required VoidCallback onBackToLibrary})`.

- [ ] **Step 1: Migrate and write the tests**

In `open_deck_screen_test.dart`, replace "a deck deleted while open says so (ruling P2-L7)" with:

```dart
  libraryTest('a deck deleted while open says it is no longer here (A8)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    String? ancestor = 'unset';
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, onOpenAncestor: (id) => ancestor = id),
    );

    await env.decks.delete(words.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    final trash = tester.widget<MxButton>(find.widgetWithText(MxButton, _en.deckOpenTrash));
    expect(trash.onPressed, isNull);
    await tester.tap(find.text(_en.deckBackToLibrary));
    expect(ancestor, isNull);
  });
```

Match the parameter names to what the existing test and harness use for the deck id and `onOpenAncestor`; read the test's first lines.

Add:

```dart
  libraryTest('a deck of decks leads with its summary; Study is disabled', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(korean.id, 'Grammar');
    await insertCard(env.db, id: 'late', deckId: words.id,
        learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 22));
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(find.byType(DeckSummaryCardWidget), findsOneWidget);
    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(2), _en.deckCardCount(1))),
      findsOneWidget,
    );
    final study = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.deckStudyThisDue(1)),
    );
    expect(study.onPressed, isNull);
    expect(find.text(_en.deckSubDeckCount(2)), findsWidgets);
  });

  libraryTest('the summary counts every sub-deck under the due filter', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(korean.id, 'Grammar');
    await insertCard(env.db, id: 'late', deckId: words.id,
        learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 22));
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxToggle));
    await tester.tap(find.text(_en.commonDone));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(2), _en.deckCardCount(1))),
      findsOneWidget,
    );
    expect(find.text(_en.libraryDueDecksHeader), findsOneWidget);
    expect(find.text('Grammar'), findsNothing);
  });
```

In `test/app/library_routes_test.dart`, the deleted-deck route test (around line 109) deletes from the open deck's own sheet. That delete stays: the delete dialog's success still pops back with `deckDeletedToast`, which is the operation path (C-L5). Keep it, and check that it still passes after Step 3.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/open_deck_screen_test.dart`
Expected: FAIL, no summary card and no gone state.

- [ ] **Step 3: Implement**

`deck_summary_card_widget.dart`:

```dart
/// An open deck of decks at a glance (screen 01): its algorithm, what it
/// holds, today's work with what is scheduled, and Study, disabled until
/// study sessions exist (spec A4). No mastery until BE-A7 (spec A5).
class DeckSummaryCardWidget extends StatelessWidget {
  const DeckSummaryCardWidget({
    super.key,
    required this.level,
    required this.schedulerType,
  });

  final DeckLevel level;
  final SchedulerType schedulerType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final due = level.overdueCount + level.dueTodayCount;
    final cards = due + level.newCount + level.scheduledCount;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Text(l10n.schedulerType(schedulerType).toUpperCase(), style: styles.overline),
          Text(
            l10n.deckRowMeta(
              l10n.deckSubDeckCount(level.deckCount),
              l10n.deckCardCount(cards),
            ),
            style: styles.rowTitle,
          ),
          MxWorkloadBreakdownLine(
            overdueCount: level.overdueCount,
            todayCount: level.dueTodayCount,
            newCount: level.newCount,
            overdueLabel: l10n.workloadOverdue,
            todayLabel: l10n.workloadToday,
            newLabel: l10n.workloadNew,
            fallback: cards == 0
                ? l10n.workloadNoCards
                : l10n.workloadNothingDue(cards),
            suffix: level.scheduledCount > 0
                ? l10n.deckScheduledCount(level.scheduledCount)
                : null,
          ),
          const SizedBox(height: AppSpacing.grouped),
          MxButton(
            label: due > 0 ? l10n.deckStudyThisDue(due) : l10n.deckStudyThis,
            icon: AppIcons.play,
            isBlock: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
```

If `schedulerType(...)` is not an `AppLocalizations` extension reachable here, import the one the action sheet uses. If `MxWorkloadBreakdownLine.suffix` expects the text without the separator, pass it exactly as the widget's doc says; read the widget before using it.

`deck_gone_state_widget.dart`:

```dart
/// The open deck was deleted while it was on screen (spec A8): say so, and
/// go back to the Library. Trash is deferred, so its door is shut.
class DeckGoneStateWidget extends StatelessWidget {
  const DeckGoneStateWidget({super.key, required this.onBackToLibrary});

  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.deckGoneTitle,
          body: l10n.deckGoneBody,
          actionLabel: l10n.deckBackToLibrary,
          onAction: onBackToLibrary,
          secondaryActionLabel: l10n.deckOpenTrash,
        ),
      ],
    );
  }
}
```

In `_OpenDeck`:
- delete `_leaveWhenGone` and its `ref.listen`;
- in the `switch`, add before the loading arm:

  ```dart
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: DeckGoneStateWidget(onBackToLibrary: () => onOpenAncestor(null)),
      ),
  ```

In `deck_level_list_widget.dart`, add `schedulerType` as a constructor parameter (`SchedulerType?`, null at the root) passed by `DeckLevelBodyWidget`. `_OpenDeckContent` passes `view.schedulerType`. For an open deck with tiles:
- `DeckSummaryCardWidget(level: level, schedulerType: schedulerType!)`, then `SizedBox(height: AppSpacing.grouped)`;
- the header, with `label` set to:
  - `filter == DeckLevelFilter.due ? l10n.libraryDueDecksHeader : ...`,
  - or when its sub-decks sit at level 10 (C-O6), `l10n.deckDepthHeader(level.deckCount)` (pass `hasDeepestSubDecks` from `_OpenDeckContent` through the body: `deck.depth == DeckEntity.maxDepth - 1`),
  - or otherwise `l10n.deckSubDeckCount(level.deckCount)`.

`DeckLevelBodyWidget` gains `schedulerType` and `isDeepest` parameters and passes them on. The root passes `null` and `false`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck test/app --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): the open deck of screen 01: summary card, sub-deck header, gone state" -m "<trailer>"
```

---

### Task 8: The Library search of screen 04

**Files:**
- Modify: `lib/features/deck/presentation/screens/deck_search_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_search_results_widget.dart`
- Create: `lib/features/deck/presentation/widgets/items/deck_search_hit_row_widget.dart`
- Create: `lib/features/deck/presentation/widgets/support/deck_search_match_widget.dart` (the match finder, pure)
- Test: `test/features/deck/presentation/deck_search_screen_test.dart`, `test/features/deck/presentation/deck_search_match_test.dart` (new)

**Interfaces:**
- Consumes: `DeckSearchHit.contentType` (Task 2), `rowTitleMatch` (Task 3), Task 4 keys, `foldText` (`lib/core/text/folded_text.dart`), phase B `MxAppBar.titleWidget`.
- Produces: `(int start, int end)? deckSearchMatch(String name, String term)`.

- [ ] **Step 1: Write the failing match tests**

`deck_search_match_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_search_match_widget.dart';

void main() {
  test('finds the term whatever its case, and keeps the name’s letters', () {
    expect(deckSearchMatch('Ăn uống', 'ĂN'), (0, 2));
    expect(deckSearchMatch('Academic words', 'words'), (9, 14));
  });

  test('accents matter: "hoc" does not match "học"', () {
    expect(deckSearchMatch('Học qua phim', 'hoc'), isNull);
  });

  test('a blank term matches nothing', () {
    expect(deckSearchMatch('Korean', '  '), isNull);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_search_match_test.dart`
Expected: compile error, the file does not exist.

- [ ] **Step 3: Implement the match**

```dart
import 'package:memox/core/text/folded_text.dart';

/// Where [term] sits in [name] under the search's own folding
/// (BR-SEARCH-002), as a half-open range in [name]; null when it does not.
/// Folding is lower-casing and keeps each letter, so a range in the folded
/// name is the same range in the name.
(int, int)? deckSearchMatch(String name, String term) {
  final folded = foldText(term);
  if (folded.isEmpty) return null;
  final start = foldText(name).indexOf(folded);
  if (start < 0) return null;
  return (start, start + folded.length);
}
```

Before relying on this, read `lib/core/text/folded_text.dart`. If `foldText` trims or normalises in a way that changes lengths (for example NFC composition), map the range back through the same normalisation, and add a test for that case. The comment above must stay true.

Run: `flutter test test/features/deck/presentation/deck_search_match_test.dart`
Expected: PASS.

- [ ] **Step 4: Migrate and write the screen tests**

In `deck_search_screen_test.dart`:
- replace `find.byType(MxListRow)` with `find.byType(DeckSearchHitRowWidget)` and `find.widgetWithText(MxListRow, 'Korean')` with `find.widgetWithText(DeckSearchHitRowWidget, 'Korean', skipOffstage: false)`. The name is a `Text.rich`, so use `find.textContaining('Korean', findRichText: true)` inside `find.descendant(of: find.byType(DeckSearchHitRowWidget), ...)`;
- "a blank term shows nothing" becomes "a blank term shows what search finds": expect `find.text(_en.searchFinds)`, `find.text(_en.searchHintDeckName)` and `find.text(_en.searchAccentNote)`, and no `DeckSearchHitRowWidget`;
- "no hit names the term" expects `find.text(_en.deckSearchEmptyTitle('zzz'))` (use the test's term).

Add:

```dart
  libraryTest('the field sits in the app bar and takes focus', (tester, env) async {
    await pumpLibraryScreen(tester, env, deckSearchScreen());

    expect(
      find.descendant(of: find.byType(MxAppBar), matching: find.byType(MxSearchField)),
      findsOneWidget,
    );
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  libraryTest('results group under Decks, count and say what each holds', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Korean words');
    await insertCard(env.db, id: 'c', deckId: words.id);
    await pumpLibraryScreen(tester, env, deckSearchScreen());

    await tester.enterText(find.byType(TextField), 'korean');
    await tester.pumpAndSettle();

    expect(find.text(_en.searchResultsFor('korean')), findsOneWidget);
    expect(find.text(_en.searchDecksGroup.toUpperCase()), findsOneWidget);
    expect(find.text(_en.searchHoldsCards('Korean')), findsOneWidget);
    expect(find.text(_en.searchHoldsDecks(_en.navLibrary)), findsOneWidget);
  });
```

Use the harness's name for the search screen builder (`deckSearchScreen()` or what the existing test uses). For a root the subtitle path is `navLibrary`. The group label renders as the header style renders it: check `MxListSectionHeader` for upper-casing, and assert the text as it renders.

- [ ] **Step 5: Implement the screen**

`deck_search_screen.dart`: the app bar becomes:

```dart
      appBar: MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        titleWidget: MxSearchField(
          controller: _query,
          focusNode: _focus,
          hintText: l10n.deckSearchHint,
          clearLabel: l10n.deckSearchClear,
          onChanged: (term) => setState(() => _term = term),
        ),
      ),
      body: DeckSearchResultsWidget(term: _term, onOpenDeck: widget.onOpenDeck),
```

`deck_search_hit_row_widget.dart`:

```dart
/// One deck found by the search (screen 04): its tile, its name with the
/// match emphasised, where it sits and what it holds.
class DeckSearchHitRowWidget extends StatelessWidget {
  const DeckSearchHitRowWidget({
    super.key,
    required this.hit,
    required this.term,
    required this.onTap,
    required this.hasDivider,
  });

  final DeckSearchHit hit;
  final String term;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final path = hit.path.isEmpty
        ? l10n.navLibrary
        : deckPathLabel([for (final entry in hit.path) entry.name]);
    final holds = switch (hit.contentType) {
      DeckContentType.card => l10n.searchHoldsCards(path),
      DeckContentType.deck => l10n.searchHoldsDecks(path),
      DeckContentType.unset => l10n.searchHoldsNothing(path),
    };
    final match = deckSearchMatch(hit.name, term);
    return MxListRow(
      titleWidget: Text.rich(
        TextSpan(
          style: styles.listRowTitle,
          children: switch (match) {
            null => [TextSpan(text: hit.name)],
            (final start, final end) => [
              TextSpan(text: hit.name.substring(0, start)),
              TextSpan(text: hit.name.substring(start, end), style: styles.rowTitleMatch),
              TextSpan(text: hit.name.substring(end)),
            ],
          },
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: holds,
      leading: MxIconTile(
        icon: switch (hit.contentType) {
          DeckContentType.card => AppIcons.cardDeck,
          DeckContentType.deck => AppIcons.library,
          DeckContentType.unset => AppIcons.folder,
        },
      ),
      hasChevron: true,
      onTap: onTap,
      hasDivider: hasDivider,
    );
  }
}
```

`MxListRow` takes a `String title` today. Read it. If it has no `titleWidget` slot, the row builds the same layout itself instead: `MxRowInk` → `Padding` → `Row(MxIconTile, Expanded(Column(Text.rich, Text(holds))), chevron Icon)`, with `MxListRow`'s padding and spacing tokens. Do not add a slot to `MxListRow` in this phase.

`deck_search_results_widget.dart`, by state:
- **blank term:** `MxScreenScroll` with:
  - an overline `searchFinds`;
  - one `MxCard(isFullBleed: true)` holding an `MxListRow` hint row (tile `AppIcons.library`, title `searchHintDeckName`, subtitle `searchHintDeckExample`, no tap);
  - `MxNote(text: l10n.searchAccentNote)`.
- **loading:** `MxScreenScroll` with an overline `searchSearching(term.trim())` and three `MxSkeletonRow`s.
- **data, empty:** as today, with the new copy.
- **data:** `MxScreenScroll` with:
  - an overline `searchResultsFor(term.trim())`;
  - `MxListSectionHeader(label: l10n.searchDecksGroup, trailing: MxBadge(label: '${value.length}', tone: MxBadgeTone.neutral))`;
  - `MxCard(isFullBleed: true, child: Column([DeckSearchHitRowWidget ...]))`.
- **error:** `MxErrorState(title: l10n.searchErrorTitle, body: l10n.searchErrorBody, retryLabel: l10n.commonRetry, onRetry: ...)`.

Overlines use the `overline` text role. If a shared widget already draws a small overline label (check `MxListSectionHeader`), use it for these labels too.

- [ ] **Step 6: Run to verify they pass**

Run: `flutter test test/features/deck test/app --exclude-tags golden`
Expected: PASS.

- [ ] **Step 7: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): the Library search of screen 04" -m "<trailer>"
```

---

### Task 9: Goldens, visual check, clean-up, ledgers, the full gate

**Files:**
- Modify: goldens under `test/features/deck/presentation/goldens/` and `test/app/goldens/` for the changed screens only
- Modify: `test/features/deck/presentation/deck_screens_golden_test.dart`, `deck_level_screen_golden_test.dart` (the reorder golden starts from a row's sheet)
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb` (delete keys no code uses any more)
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (close row 72; record the supersession of P2-L7 and rulings C-L1…C-L6 as new rows)
- Modify: `docs/shared/ui/screen-handoff/00-index.md` (01 and 04 → `aligned`)
- Modify: `docs/wbs_FE.md` (FE-A11 next step)

- [ ] **Step 1: Point the reorder golden at the new entry**

In `deck_screens_golden_test.dart`, the reorder golden taps `find.byTooltip(_en.libraryReorder)`. Replace it with the row-sheet sequence from Task 6 Step 1.

- [ ] **Step 2: Regenerate the changed goldens only**

```bash
flutter test --update-goldens --tags golden \
  test/features/deck/presentation/deck_level_screen_golden_test.dart \
  test/features/deck/presentation/deck_screens_golden_test.dart
flutter test --update-goldens --tags golden --plain-name "Library" test/app/app_golden_test.dart
git status --short -- test | grep -v /failures/
```

Expected: only the PNGs of those tests change: `library_*`, `app_library_*` (`Library tab`, `Library with decks`, `Library first run`), light and dark. Then restore and delete the `failures/` images as the Global Constraints say.

- [ ] **Step 3: Look at them against the handoff**

Open with the Read tool, light and dark:
- `library_decks` against `docs/shared/ui/screen-handoff/img/01-deck-list/rootLoaded-*.png`;
- `library_empty` against `rootEmpty`;
- `library_deck_open` against `deckLoaded`;
- `library_deck_actions` against `deckOverflow`;
- `library_search` against `04-library-search/results`.

List every difference that is not in the handoff's Deviations or Pending tables. Fix them in one batch, re-run Step 2 once, and look once more. Stop there. Record any remaining difference as a new Deviations row, with its reason.

- [ ] **Step 4: Remove unused copy**

Run: `grep -n "deckSortTrigger\|deckFilterTrigger\|deckFilterAll\|deckFilterDue\b\|deckFilterTitle\|deckSortTitle\|libraryOpenSearch\|libraryReorder\b" -r lib test | grep -v generated`

Delete each key that no code or test still uses from both ARB files, run `flutter gen-l10n`, and run `flutter analyze`. Delete `DeckLevelQueryLabel.deckFilter` if unused.

- [ ] **Step 5: Debt register, handoff index, ledger**

UI-base spec §9:
- append ` — closed by library alignment phase C (C-L4)` to row 72's first cell;
- append one row per ruling C-L1, C-L2, C-L3 and C-L5, using the table's columns and marking the source `library alignment phase C`. For example: `| 85 | A deck row's meta and the due strip's tile carry no coloured glyph: the guard bans Icon(color:) in feature code | library alignment phase C (C-L1) |`, then continue the numbering.

`00-index.md`: rows 01 and 04 → `aligned`.

`wbs_FE.md`: in the FE-A11 row's last cell, replace `Phase A xong (#32); phase B (nền) trong PR này; phase C sau khi merge` with `Phase A (#32), B (#34) xong; phase C (01, 04) trong PR này; phase D sau khi merge`.

- [ ] **Step 6: The full gate**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test
python3 tools/docs/generate.py && python3 tools/docs/check.py
GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- every command clean except `flutter test` and DoD;
- they fail only on goldens that also fail on `master` and that this phase did not regenerate;
- every regenerated golden passes;
- no non-golden test fails.

Then restore and delete the `failures/` images.

**Scope check:** `git diff --stat origin/master...HEAD -- lib/features/card` must print nothing.

- [ ] **Step 7: Commit**

```bash
git add lib test docs
git commit -m "test(deck): screen 01 and 04 goldens on Linux; close debt row 72; ledgers" -m "<trailer>"
```
