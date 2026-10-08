# Library empty state: The Content Gate — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Library root's chrome (search trigger, Tags, FAB) exists only while the Library holds a deck, driven by one derived `LibraryRootState`; Starter decks and the Trash stay; the rule is named in `DESIGN.md`; the empty-state copy reads as an action.

**Architecture:** A sealed `LibraryRootState` is derived by one Riverpod provider from the root level stream (`deckLevelProvider`) the body already reads, so chrome and body change in the same frame. `DeckLibraryRootWidget` builds its app bar, search trigger and FAB from that state; `DeckLevelBodyWidget` is unchanged. `DeckLevel.hasDecks` is the one definition of "empty" (ruling L4). The rule is written once in `DESIGN.md` (The Content Gate Rule) and cited by the screens that already follow it.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 codegen (`dart run build_runner build --delete-conflicting-outputs`), `flutter gen-l10n` (ARB en/vi), goldens through `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update` (Linux container only), tests through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <files>`.

**Spec:** `docs/superpowers/specs/2026-10-08-library-empty-state-content-gate-design.md` (owner rulings R1–R4, 2026-10-08). Linear: epic DEV-309; each task below becomes one `FE` sub-issue of it (template `.claude/skills/flutter-workflow/references/linear-templates.md`), set In Progress at its Step 1.

## Global Constraints

- Branch: the session branch `ccr-e1b4f874-uftugm` (restarted from `origin/master` at `18ca8150`); one PR for epic DEV-309. Commits end with the two attribution lines of this session.
- "Empty" is `DeckLevel.deckCount == 0` (ruling L4), never `tiles.isEmpty`: "Due only" with decks and nothing due is not empty.
- A content-dependent control is absent, never dimmed (R3). Starter decks and the Trash are present in every state (R2).
- Loading and failure count as no content: the search trigger, Tags and the FAB appear with the first `LibraryRootDecks`.
- Copy (R4): en `libraryEmptyBody` = "Organize your cards into decks. Create your own or start with a ready-made collection."; vi = "Sắp xếp thẻ thành bộ thẻ. Tạo bộ của riêng bạn hoặc bắt đầu với một bộ mẫu có sẵn." Title, both actions and the footnote keep their strings.
- Tokens only; no new shared widget; the deck feature imports nothing new (`bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` stays clean).
- Every golden change goes through a `golden-compare` page before the owner approves.

## Review Focus

1. The last deck goes to the Trash from its row's ⋮ while the Library is sorted "Due only": the chrome must fall to the empty table and the body must show the first-run empty state, not "Nothing due right now" over nothing (Task 1's `hasDecks` + Task 3 scenario B).
2. A reload of the stream that still carries decks (a midnight tick, a sync pull): the search trigger must not blink out and in (Task 1 test "a refresh with data stays Decks").
3. The stream fails after it once had decks: the chrome falls to the failed table (no search, no Tags, no FAB) and the body shows Retry (Task 1 test "a failure is Failed, even after data"; Task 2 table).
4. Reorder mode on a Library that has decks: Done still replaces the actions and the search trigger and the FAB are still absent, as critique 2026-09-30 part 3d-2 rules (Task 2 test "reorder keeps its chrome").
5. The tablet rail (≥600dp) with decks: nothing moves; the existing `app_tablet_landscape_library` golden must not change (Task 4 verifies the mover list).

---

### Task 1: `DeckLevel.hasDecks` and `LibraryRootState` (DEV-309 sub-issue 1)

**Files:**
- Modify: `lib/features/deck/domain/models/deck_level_model.dart` (after `masteryFraction`)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart:95`
- Create: `lib/features/deck/presentation/states/library_root_state.dart` (+ generated `library_root_state.g.dart`)
- Test: `test/features/deck/domain/deck_level_model_test.dart` (create if absent, else append), `test/features/deck/presentation/library_root_state_test.dart` (create)

**Interfaces:**
- Produces: `bool DeckLevel.hasDecks`; `sealed class LibraryRootState { bool get hasDecks }` with `LibraryRootLoading()`, `LibraryRootFailed()`, `LibraryRootEmpty()`, `LibraryRootDecks(DeckLevel level)`; `libraryRootStateProvider` (`Provider<LibraryRootState>`, auto-dispose, no family).

- [ ] **Step 1: Set the sub-issue In Progress on Linear** (`save_issue`, `state: "In Progress"`), after creating it under DEV-309 with the `FE` and `Improvement` labels, milestone V8.0, title "Dẫn xuất LibraryRootState từ stream cấp gốc".

- [ ] **Step 2: Write the failing domain test**

Create or append to `test/features/deck/domain/deck_level_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

DeckTile _tile(String id, {int dueTodayCount = 0}) => DeckTile(
  id: id,
  name: id,
  siblingPosition: 0,
  createdAt: DateTime(2026, 9, 1),
  schedulerType: SchedulerType.eightBox,
  subDeckCount: 0,
  cardCount: 1,
  newCount: 0,
  overdueCount: 0,
  dueTodayCount: dueTodayCount,
  masteredCount: 0,
  oldestDueAt: null,
  startOfToday: DateTime(2026, 9, 24),
);

void main() {
  test('hasDecks counts the level, whatever the filter shows (ruling L4)', () {
    expect(DeckLevel.of(const []).hasDecks, isFalse);
    expect(DeckLevel.of([_tile('a')]).hasDecks, isTrue);
    // "Due only" hides every tile of a level that still holds a deck.
    final dueOnly = DeckLevel.of([_tile('a')], filter: DeckLevelFilter.due);
    expect(dueOnly.tiles, isEmpty);
    expect(dueOnly.hasDecks, isTrue);
  });
}
```

If the file exists, keep its imports and add the test and the `_tile` helper (rename the helper if one exists; read the file first).

- [ ] **Step 3: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/domain/deck_level_model_test.dart`
Expected: compile failure, `The getter 'hasDecks' isn't defined for the type 'DeckLevel'`.

- [ ] **Step 4: Add `hasDecks` and use it in the list widget**

In `deck_level_model.dart`, after `masteryFraction`:

```dart
  /// The level holds at least one deck, whatever the filter shows: the one
  /// definition of an empty level (ruling L4; The Content Gate, DESIGN.md).
  bool get hasDecks => deckCount > 0;
```

In `deck_level_list_widget.dart`, replace line 95's condition:

```dart
    // Ruling L4: an empty level is the first run; an empty filter is not.
    if (!level.hasDecks) {
```

(the `filter == DeckLevelFilter.all` clause goes: a level with no deck is the first run under any filter, and `filter` is still read below for the header).

- [ ] **Step 5: Run the domain test and the deck presentation suite**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/domain/deck_level_model_test.dart test/features/deck/presentation/deck_level_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Write the failing state test**

Create `test/features/deck/presentation/library_root_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/states/library_root_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late LibraryEnv env;
  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() => env.db.close());

  /// The states seen so far, with the provider kept alive.
  List<LibraryRootState> watch(ProviderContainer container) {
    final seen = <LibraryRootState>[];
    container.listen(
      libraryRootStateProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    return seen;
  }

  test('loading, then Empty with no deck', () async {
    final container = libraryContainer(env);
    final seen = watch(container);
    expect(seen.single, isA<LibraryRootLoading>());
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootEmpty>());
    expect(seen.last.hasDecks, isFalse);
  });

  test('a deck makes Decks; losing the last one makes Empty; a new one '
      'makes Decks again (scenarios B and C)', () async {
    final korean = await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());
    expect((seen.last as LibraryRootDecks).level.deckCount, 1);

    await container.read(deleteDeckUseCaseProvider)(deckId: korean.id);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootEmpty>());

    await env.decks.root('Kanji');
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());
  });

  test('"Due only" over decks with nothing due is still Decks (ruling L4)',
      () async {
    await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    container.read(deckLevelQueryProvider(null).notifier).show(DeckLevelFilter.due);
    await pumpEventQueue();

    final last = seen.last;
    expect(last, isA<LibraryRootDecks>());
    expect((last as LibraryRootDecks).level.tiles, isEmpty);
  });

  test('a refresh with data stays Decks: the chrome never blinks (Review '
      'Focus 2)', () async {
    await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());

    container.invalidate(
      deckLevelProvider(
        parentId: null,
        sort: DeckLevelSort.manual,
        filter: DeckLevelFilter.all,
      ),
    );
    await pumpEventQueue();

    expect(seen.last, isA<LibraryRootDecks>());
    expect(seen.skip(1).whereType<LibraryRootLoading>(), isEmpty);
  });

  test('a failure is Failed, even after data', () async {
    await env.decks.root('Korean');
    final container = libraryContainer(env);
    final seen = watch(container);
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootDecks>());

    await env.db.close();
    container.invalidate(
      deckLevelProvider(
        parentId: null,
        sort: DeckLevelSort.manual,
        filter: DeckLevelFilter.all,
      ),
    );
    await pumpEventQueue();
    expect(seen.last, isA<LibraryRootFailed>());
  });
}
```

Read `deck_level_query_state.dart` first: the notifier's method that sets the filter is `show(DeckLevelFilter)` (as `DeckLevelListWidget._showAll` calls it); if its name differs, use the real one. If closing the database does not make the stream fail (Drift may complete it instead), replace the last test's trigger by overriding `watchDeckLevelUseCaseProvider` with a use case whose stream is `Stream.error(StateError('read failed'))`, following `test/features/progress/presentation/progress_providers_test.dart` ("a failed read is an error").

- [ ] **Step 7: Run it and see it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/library_root_state_test.dart`
Expected: compile failure, `library_root_state.dart` not found.

- [ ] **Step 8: Implement the state and regenerate**

Create `lib/features/deck/presentation/states/library_root_state.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_root_state.g.dart';

/// The Library root as one state for its chrome and its body (screen 01):
/// the search trigger, Tags and the FAB exist only with decks (The Content
/// Gate Rule, DESIGN.md); Starter decks and the Trash always do. Loading
/// and failure count as no content.
sealed class LibraryRootState {
  const LibraryRootState();

  bool get hasDecks => this is LibraryRootDecks;
}

final class LibraryRootLoading extends LibraryRootState {
  const LibraryRootLoading();
}

final class LibraryRootFailed extends LibraryRootState {
  const LibraryRootFailed();
}

/// The level holds no deck: the first run (ruling L4).
final class LibraryRootEmpty extends LibraryRootState {
  const LibraryRootEmpty();
}

final class LibraryRootDecks extends LibraryRootState {
  const LibraryRootDecks(this.level);

  final DeckLevel level;
}

/// Derived from the same level stream the body reads, so both change in
/// one frame. A refresh that still has data keeps its state; a failure is
/// Failed even over a stale value, as the body's error state is.
@riverpod
LibraryRootState libraryRootState(Ref ref) {
  final query = ref.watch(deckLevelQueryProvider(null));
  final level = ref.watch(
    deckLevelProvider(parentId: null, sort: query.sort, filter: query.filter),
  );
  // Object patterns on the getters: a refresh keeps its previous value
  // (hasValue), a failure over a stale value is still an error.
  return switch (level) {
    AsyncValue(hasError: true) => const LibraryRootFailed(),
    AsyncValue(hasValue: true, :final value?) =>
      value.hasDecks ? LibraryRootDecks(value) : const LibraryRootEmpty(),
    _ => const LibraryRootLoading(),
  };
}
```

Run `dart run build_runner build --delete-conflicting-outputs` (writes `library_root_state.g.dart`, git-ignored). If the analyzer rejects `:final value?` inside the object pattern, read `value` after the match: `AsyncValue(hasValue: true) => switch (level.value) { final v? when v.hasDecks => LibraryRootDecks(v), _ => const LibraryRootEmpty() }`.

- [ ] **Step 9: Run the tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/library_root_state_test.dart test/features/deck/domain/deck_level_model_test.dart`
Expected: PASS (4 + 1 tests). `flutter analyze lib test` reports no error in the touched files.

- [ ] **Step 10: Commit**

```bash
git add lib/features/deck test/features/deck
git commit -m "feat(deck): DEV-309 LibraryRootState derives the Library root's one state from its level stream"
```

---

### Task 2: The root chrome follows the state (DEV-309 sub-issue 2)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`
- Test: `test/features/deck/presentation/deck_level_screen_test.dart` (scenarios A and C; the app bar test; a reorder test)

**Interfaces:**
- Consumes: `libraryRootStateProvider`, `LibraryRootState.hasDecks` (Task 1).
- Produces: nothing new; `DeckLibraryRootWidget` keeps its constructor.

- [ ] **Step 1: Set the sub-issue In Progress on Linear** (create it under DEV-309: `FE`, `Improvement`, V8.0, title "Chrome của Library root theo LibraryRootState").

- [ ] **Step 2: Write the failing widget tests**

In `test/features/deck/presentation/deck_level_screen_test.dart`, change the existing test `'the root app bar holds Starter decks, Tags and Trash, as kit 01 draws it; nothing waits under Coming soon (spec D2)'` to seed first: add `await _seed(env);` as its first line (the three actions are the chrome of a Library with decks). Then add, after `'the FAB waits for a first deck; the empty state offers it'`:

```dart
  libraryTest('scenario A: a first run shows Starter decks and the Trash, '
      'no Tags, no search, no FAB (The Content Gate)', (tester, env) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(
      [
        for (final button in tester.widgetList<MxIconButton>(
          find.descendant(
            of: find.byType(MxAppBar),
            matching: find.byType(MxIconButton),
          ),
        ))
          button.semanticLabel,
      ],
      [_en.libraryStarterDecks, _en.libraryTrash],
    );
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
  });

  libraryTest('scenario C: the first deck brings the search field, Tags and '
      'the FAB in the same frame as its row', (tester, env) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byTooltip(_en.libraryTags), findsNothing);

    await env.decks.root('Korean');
    await tester.pumpAndSettle();

    expect(find.text('Korean'), findsOneWidget);
    expect(find.text(_en.searchFieldHint), findsOneWidget);
    expect(find.byTooltip(_en.libraryTags), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('reorder keeps its chrome: Done replaces the actions, no search '
      'field, no FAB (critique 2026-09-30 part 3d-2)', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckReorder));
    await tester.pumpAndSettle();

    expect(find.byType(DeckReorderDoneWidget), findsOneWidget);
    expect(find.byTooltip(_en.libraryTags), findsNothing);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });
```

Add the import `package:memox/features/deck/presentation/widgets/support/deck_reorder_done_widget.dart`. If a reorder test already exists in this file, extend it with the three `findsNothing` lines instead of adding a new one.

- [ ] **Step 3: Run them and see them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_level_screen_test.dart`
Expected: scenario A fails on the action list (`[Starter decks, Tags, Trash]` found) and on the search hint (found); scenario C fails on `find.byTooltip(_en.libraryTags)` being found before the deck; the reorder test passes or fails only on its new lines (reorder already hides the search field).

- [ ] **Step 4: Build the chrome from the state**

In `deck_library_root_widget.dart`, replace the `build` method's reads and the three gated elements. Remove the imports of `deck_level_provider.dart` and `deck_level_query_state.dart`; add `package:memox/features/deck/presentation/states/library_root_state.dart`. The method becomes:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReordering = ref.watch(deckReorderModeProvider(null));
    // One state for the chrome and the body (The Content Gate Rule): the
    // search trigger, Tags and the FAB exist only with decks; Starter
    // decks and the Trash, the ways in and back, always do.
    final hasDecks = ref.watch(libraryRootStateProvider).hasDecks;
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navLibrary,
        actions: isReordering
            ? const [DeckReorderDoneWidget(parentId: null)]
            // Kit 01: Starter decks, Tags, Trash (spec D2).
            : [
                MxIconButton(
                  icon: AppIcons.starterDecks,
                  semanticLabel: l10n.libraryStarterDecks,
                  onPressed: onOpenStarterDecks,
                ),
                if (hasDecks)
                  MxIconButton(
                    icon: AppIcons.tag,
                    semanticLabel: l10n.libraryTags,
                    onPressed: onOpenTags,
                  ),
                MxIconButton(
                  icon: AppIcons.delete,
                  semanticLabel: l10n.libraryTrash,
                  onPressed: onOpenTrash,
                ),
              ],
      ),
      fab: isReordering || !hasDecks
          ? null
          : MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.libraryCreateDeck,
              onPressed: createDeck,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reorder mode leaves the deck list alone, as it leaves out the
          // summary and the sort pill (critique 2026-09-30 part 3d-2, E3).
          if (hasDecks && !isReordering)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.micro,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: MxSearchField.trigger(
                hintText: l10n.searchFieldHint,
                onTap: onSearch,
              ),
            ),
          Expanded(
            child: DeckLevelBodyWidget(
              parentId: null,
              onOpenDeck: onOpenDeck,
              onOpenAlgorithm: onOpenAlgorithm,
              onOpenStudy: onOpenStudy,
              onOpenStudyOptions: onOpenStudyOptions,
              onOpenTrash: onOpenTrash,
              onOpenStudyHome: onOpenStudyHome,
              schedulerType: null,
              hasDeepestSubDecks: false,
              emptyState: MxEmptyState(
                icon: AppIcons.library,
                title: l10n.libraryEmptyTitle,
                body: l10n.libraryEmptyBody,
                actionLabel: l10n.libraryCreateDeck,
                onAction: createDeck,
                secondaryActionLabel: l10n.libraryBrowseStarterDecks,
                onSecondaryAction: onOpenStarterDecks,
                footnote: l10n.libraryEmptyFootnote,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

The class doc gains one sentence: "Its chrome follows `libraryRootStateProvider` (The Content Gate Rule)." The `// Kit 01: no FAB while the Library loads…` comment and the inline `hasDecks` computation go.

- [ ] **Step 5: Run the screen suite and see it pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation test/app/library_routes_test.dart`
Expected: PASS. `flutter analyze lib test` clean for the file; `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/deck test/features/deck
git commit -m "feat(deck): DEV-309 the Library root's search, Tags and FAB follow LibraryRootState"
```

---

### Task 3: Scenario B, the rule and the copy (DEV-309 sub-issue 3)

**Files:**
- Modify: `lib/l10n/app_en.arb:91-94`, `lib/l10n/app_vi.arb:23`
- Modify: `DESIGN.md:306` (after The Clear Tail Rule)
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md:12-13, 65, 117`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9, after row 172)
- Test: `test/features/deck/presentation/deck_level_screen_test.dart` (scenario B, the copy)

**Interfaces:**
- Consumes: the chrome of Task 2.
- Produces: `l10n.libraryEmptyBody` with the new strings.

- [ ] **Step 1: Set the sub-issue In Progress on Linear** (create it under DEV-309: `FE`, `Improvement`, V8.0, title "Kịch bản xoá bộ thẻ cuối, The Content Gate Rule và copy empty state").

- [ ] **Step 2: Write the failing tests**

In `deck_level_screen_test.dart`, after scenario C:

```dart
  libraryTest('scenario B: the last deck goes to the Trash; the same frame '
      'drops the search field, Tags and the FAB and keeps the Trash and Undo',
      (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byTooltip(_en.libraryTags), findsOneWidget);

    await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.trashMoveConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byTooltip(_en.libraryTags), findsNothing);
    expect(find.byType(MxFab), findsNothing);
    expect(find.byTooltip(_en.libraryTrash), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
  });

  libraryTest('the empty state reads as an action, in both languages (R4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(
      find.text(
        'Organize your cards into decks. Create your own or start with a '
        'ready-made collection.',
      ),
      findsOneWidget,
    );
    expect(
      _vi.libraryEmptyBody,
      'Sắp xếp thẻ thành bộ thẻ. Tạo bộ của riêng bạn hoặc bắt đầu với một '
      'bộ mẫu có sẵn.',
    );
  });
```

If the delete dialog's confirm pump leaves a spinner (FE-B1 D15), replace the last `pumpAndSettle` by `await tester.pump(); await tester.pump(const Duration(milliseconds: 500));` as `deck_action_sheet_test.dart` does.

- [ ] **Step 3: Run them and see them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_level_screen_test.dart`
Expected: scenario B passes already if Task 2 is complete (it is the end-to-end proof; keep it), the copy test fails on the English text not found.

- [ ] **Step 4: Change the copy**

`lib/l10n/app_en.arb` lines 91–94:

```json
  "libraryEmptyBody": "Organize your cards into decks. Create your own or start with a ready-made collection.",
  "@libraryEmptyBody": {
    "description": "First-run empty state body, action-first (spec 2026-10-08 library empty state, R4)."
  },
```

`lib/l10n/app_vi.arb` line 23:

```json
  "libraryEmptyBody": "Sắp xếp thẻ thành bộ thẻ. Tạo bộ của riêng bạn hoặc bắt đầu với một bộ mẫu có sẵn.",
```

Run `flutter gen-l10n`.

- [ ] **Step 5: Run the tests and see them pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_level_screen_test.dart test/l10n`
Expected: PASS.

- [ ] **Step 6: Write the rule and the docs**

`DESIGN.md`, after line 306 (The Clear Tail Rule), one paragraph:

```markdown
**The Content Gate Rule.** A control that acts on a screen's content (search, filter, select, tag, the FAB that adds a sibling to a list) exists only once that content exists, and is absent, not dimmed, until then; loading and failure count as no content. A control that creates the first content or recovers it (Create, Starter decks, Import, the Trash, Back) stays in every state. Trash › Select, Tags › search, the Library's FAB, search field and Tags follow it (DEV-309); the 0.38 dim is for a control that exists but cannot act right now.
```

`docs/shared/ui/screen-handoff/01-deck-list.md`:
- Row 12 (App bar): replace `"Library", then Starter decks (sparkles, screen 03), Tags (tag, screen 05) and Trash (screen 06) (FE-B2 + FE-B4 D2).` with `"Library", then Starter decks (sparkles, screen 03), Tags (tag, screen 05; only with decks, The Content Gate Rule, DEV-309) and Trash (screen 06, always: the way back) (FE-B2 + FE-B4 D2).`
- Row 13 (Search): append ` Only with decks (The Content Gate Rule, DEV-309).` before the closing ` |`.
- Row 65 (rootEmpty): replace with `| rootEmpty | \`library_empty_light.png\` | \`library_empty_dark.png\` | No search field, no Tags, no FAB (The Content Gate Rule, DEV-309); Starter decks and the Trash stay. "Create deck", then "Browse starter decks" (screen 03), and the footnote (FE-B4 §5.4). |`
- Row 117 (First launch copy): replace the body string with `"Organize your cards into decks. Create your own or start with a ready-made collection."`.

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`, §9 after row 172:

```markdown
| 173 | The empty Library kept its search field and Tags, two controls over content that did not exist, while the FAB alone waited for a deck — closed by DEV-309 (spec `2026-10-08-library-empty-state-content-gate-design.md`): one derived `LibraryRootState` gates the search trigger, Tags and the FAB; The Content Gate Rule names the convention Trash and Tags already followed | owner 2026-10-08 |
```

Run `python3 tools/docs/check.py` → PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n test/features/deck DESIGN.md docs/shared/ui/screen-handoff/01-deck-list.md docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
git commit -m "feat(deck): DEV-309 The Content Gate Rule, scenario B, and an action-first empty Library"
```

---

### Task 4: Goldens, audit, gate and the owner's review (DEV-309 sub-issue 4)

**Files:**
- Modify: `test/features/deck/presentation/goldens/library_empty_{light,dark}.png`, `test/app/goldens/app_library_{light,dark}.png`, and any other mover the run reports

- [ ] **Step 1: Set the sub-issue In Progress on Linear** (create it under DEV-309: `FE`, `Improvement`, V8.0, title "Golden, audit và gate cho Library rỗng").

- [ ] **Step 2: Regenerate the goldens in the container**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `git status --short -- 'test/**/goldens/*.png'`.
Expected movers: `library_empty_*`, `app_library_*` only. `app_tablet_landscape_library_*` and every other golden must not move (Review Focus 5); any other mover is explained on the golden page or fixed.

- [ ] **Step 3: Golden review page**

Invoke the `golden-compare` skill (base `git merge-base origin/master HEAD`); one family "Library rỗng (DEV-309)"; the `why` names the two absent controls, the unchanged Starter decks and Trash, the new copy, and the body's rise by the search field's height. Keep the page link for the PR body and the Linear comments.

- [ ] **Step 4: One Impeccable audit**

Invoke `impeccable` with `audit` on the empty Library (light and dark goldens) against `DESIGN.md`: the two CTAs' hierarchy, the app bar with two actions, TalkBack order. Fix what it finds in one batch, commit `fix(deck): DEV-309 impeccable audit batch`; no second audit.

- [ ] **Step 5: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → `✓ mechanical gates passed`. Then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (compare mode) → all pass.

- [ ] **Step 6: Commit and Linear**

```bash
git add test
git commit -m "test(deck): DEV-309 goldens of the empty Library without its gated chrome"
```

Comment on each sub-issue: "Đã cài trên nhánh `ccr-e1b4f874-uftugm`, commit `<sha7>`; golden review: <link>". Then run `finishing-a-development-branch`: the final whole-branch review on Opus, the push, and the PR for epic DEV-309 (the owner approves through `AskUserQuestion`); sub-issues In Review while the PR is open, Done once merged, with the evidence comment.
