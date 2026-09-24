# Library Phase 2: Deck Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The whole deck tree can be managed from the Library tab: open any deck level by level, see its path, create sub-decks, rename, move, delete with its summary, change a root's scheduler, reorder decks by drag, and search decks by name (M1).

**Architecture:** `DeckLevelScreen` becomes recursive: `deckId: null` is the Library root, any other id is an open deck with an `MxBreadcrumb` under a content app bar. Both render one shared `DeckLevelBodyWidget` over `deckLevelProvider(parentId, …)`. Every write goes through `DeckActionsController`, one use case per command (AD-12). Overlays live in `widgets/overlays/`, and `app/router` composes the routes `/decks/deck/:deckId` and `/decks/search` and passes navigation to the screens as callbacks.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18, Drift 2.35 (in-memory for tests), gen-l10n (en/vi).

**Spec:** `docs/superpowers/specs/2026-09-24-library-screens-design.md` (§4 navigation, §5 data flow, §6.1–6.3 screens, §9 verification, §10 row 2). Phase 1 plan: `docs/superpowers/plans/2026-09-24-library-phase-1-root.md`.

## Global Constraints

- UI only. No file under `lib/features/*/domain`, `lib/features/*/data`, `lib/features/*/di` or `lib/core/database` changes (spec §12). A backend gap is a finding, not a patch.
- Paths are constants in `lib/app/router/app_routes.dart`. Features receive navigation as callbacks (`onOpenDeck`, `onOpenAncestor`, `onSearch`) and never build a path (spec §4).
- Every interaction calls exactly one use case through one provider in `presentation/providers/` (AD-12). A controller method returns the use case's `Outcome`; the widget chooses the feedback (spec §5).
- Feedback (spec §5):
  - A rejection about the name field shows under the field.
  - Any other rejection shows in a snackbar.
  - `Ok` closes the dialog or sheet.
  - A database `Failure` shows `l10n.failure(failure)` in a snackbar and never an id, path or SQL (BR-CORE-005).
- ADR-011 layout: `presentation/{screens,controllers,states,providers}` and `widgets/{sections,items,overlays,support}`. Suffixes are `_screen`, `_controller`, `_state`, `_provider` and `_widget`, and a file named with "copy" is refused by the guard.
- Import map unchanged: `deck → {srs}`. `deck/presentation` may import `srs/di` and `srs/domain/{models,failures}`.
- Guard memox-v8 must stay 0 errors / 0 warnings:
  - No raw `AppBar`, `TextButton`, `CircularProgressIndicator`, `showModalBottomSheet`, `Icon(color:)`, `ButtonStyle`, `BorderSide`, `RoundedRectangleBorder`, `Card`, `ListTile`, `IconButton` or `Checkbox`.
  - No `ref.read` lexically inside `build()`: put it in a method.
  - No defaulted parameter in a provider or notifier signature.
  - In the ARB, `placeholders` comes before `description`.
- Copy lives in `lib/l10n/app_en.arb` (with `@key` metadata) and `lib/l10n/app_vi.arb` (flat). Run `flutter gen-l10n` after every ARB edit.
- Run `dart run build_runner build --delete-conflicting-outputs` after every `@riverpod` edit (`*.g.dart` is git-ignored).
- Tests run through the real backend: `libraryTest`, `pumpLibraryScreen` and `openTestDatabase()` from `test/support/`. Use cases are not mocked; a fake `DeckRepository` wrapped in the real use case is allowed for failure paths.
- Phones only. Each screen passes `expectAccessibleTargets` and renders at text scale 2 without an exception (spec §9). Goldens are light and dark at 1080×2400, 3x, generated on Windows.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings (phase 2)

| # | Ruling |
|---|---|
| P2-L1 | Cards arrive in phases 3–4, so a `card`-typed deck shows an empty body (the `cardContent` slot comes with phase 3). The `unset` state and the FAB offer only "Create sub-deck"; "Add card" joins them with the editor in phase 4. |
| P2-L2 | The Library root's app bar holds Search and, when the level can be reordered, a Reorder action. The spec puts Reorder only in an open deck's overflow, but the roots need it too, and the root has no overflow. |
| P2-L3 | Reorder mode is offered when the level's sort is manual, its filter is all, and it has at least 2 decks. The mode shows only the decks, in a `ReorderableListView` whose rows carry drag handles; Flutter supplies the TalkBack move actions. The app bar shows Done, and the FAB and chips hide. |
| P2-L4 | The breadcrumb sits under the app bar, outside the scroll, as Library › ancestors › current deck. The app bar shows the deck name. |
| P2-L5 | A breadcrumb tap pops the Library stack back to that deck, or to the root for "Library". A deck that is not on the stack (opened from search) is pushed over the root instead. |
| P2-L6 | Each level keeps its own sort, filter and reorder mode (`deckLevelQueryProvider(parentId)`, `deckReorderModeProvider(parentId)`). |
| P2-L7 | When the open deck stops existing, its screen shows "Deck deleted" once and pops. The same listener serves a delete from its own sheet and any other removal. |
| P2-L8 | Move is offered for sub-decks only (a root cannot move, `rootCannotMove`), and Change scheduler for roots only. A move target is labelled with its full path, "Korean › Words". |
| P2-L9 | Search covers every deck (`scopeDeckId: null`) and is opened from the root only. A blank term shows nothing; a term with no hit shows the neutral empty state naming the term. |
| P2-L10 | The name dialog shows a blank or too-long name under the field. Any other refusal (the deck is gone, too deep, holds cards) shows in a snackbar and closes the dialog. |

## Review Focus

1. **Deleting a deck opened three levels deep.**
   - Expected: exactly one pop, landing on its parent (not the grandparent), and one "Deck deleted" snackbar.
   - Pinned in Task 6 (`deleting the open deck returns to its parent once`).
2. **A double tap on a move target.**
   - Expected: one move and one snackbar; no "already there" refusal from a second call.
   - Pinned in Task 4.
3. **A reorder drop the backend refuses (a stale anchor).**
   - Expected: the rows snap back to the stored order and a snackbar says why.
   - Pinned in Task 3.
4. **A 10-level path with long names at text scale 2.**
   - Expected: no overflow, and the current level stays in view at the end of the breadcrumb.
   - Pinned in Task 2.
5. **Moving the open deck, then Back.**
   - Expected: the breadcrumb shows the new path at once. Back returns to the level below in the stack, which no longer lists the deck.
   - Pinned in Task 6.

## File Map

```
lib/core/theme/foundations/app_icons.dart                    modify: reorder, dragHandle, scheduler
lib/l10n/app_en.arb, app_vi.arb                              modify: phase 2 copy
lib/features/deck/presentation/
  providers/  create_sub_deck_use_case_provider.dart         create (and 9 more use-case providers, Task 1)
              deck_view_provider.dart                        create
              deck_move_targets_provider.dart                create
              deck_search_provider.dart                      create
              deck_deletion_summary_provider.dart            create
  controllers/deck_actions_controller.dart                   modify: six commands
  states/     deck_level_query_state.dart                    modify: family by parentId, allowsReorder
              deck_reorder_mode_state.dart                   create: mode + deckLevelCanReorder
  screens/    deck_level_screen.dart                         rewrite: root + open deck
              deck_search_screen.dart                        create
  widgets/sections/ deck_level_body_widget.dart              create
                    deck_level_list_widget.dart              modify
                    deck_level_header_widget.dart            modify
                    deck_unset_state_widget.dart             create
                    deck_reorder_list_widget.dart            create
                    deck_search_results_widget.dart          create
  widgets/items/    deck_row_widget.dart                     modify: tap + chevron
                    deck_reorder_row_widget.dart             create
  widgets/overlays/ deck_name_dialog_widget.dart             create
                    deck_action_sheet_widget.dart            create
                    deck_delete_dialog_widget.dart           create
                    deck_move_sheet_widget.dart              create
                    deck_scheduler_sheet_widget.dart         create
  widgets/support/  srs_rejection_message_widget.dart        create
                    scheduler_type_label_widget.dart         create
                    deck_path_label_widget.dart              create
                    deck_reorder_anchor_widget.dart          create
lib/app/router/app_routes.dart, app_router.dart              modify
test/support/library_harness.dart, deck_fixtures.dart        modify
test/features/deck/presentation/*                            tests and goldens
test/app/library_routes_test.dart                            create
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md  §9 rows 71–74
```

---

### Task 1: Plumbing: providers, commands, level state, labels and copy

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/features/deck/presentation/controllers/deck_actions_controller.dart`, `lib/features/deck/presentation/states/deck_level_query_state.dart`, `test/support/deck_fixtures.dart`
- Create:
  - `lib/features/deck/presentation/providers/`: 10 use-case providers and 4 read providers (Step 3)
  - `lib/features/deck/presentation/states/deck_reorder_mode_state.dart`
  - `lib/features/deck/presentation/widgets/support/{srs_rejection_message_widget,scheduler_type_label_widget,deck_path_label_widget,deck_reorder_anchor_widget}.dart`
- Test: `test/features/deck/presentation/deck_actions_controller_test.dart` (extend), `test/features/deck/presentation/deck_messages_test.dart` (extend), `test/features/deck/presentation/deck_reorder_anchor_test.dart` (create)

**Interfaces:**
- Consumes: phase 1's `DeckActionsController`, `deckLevelProvider`, `DeckLevelQueryState`, `libraryToday`, `openTestDatabase`, `totalChanges`.
- Produces (later tasks rely on these exact names):
  - `DeckActionsController`:
    - `createSubDeck({required String parentId, required String name})` → `Future<Outcome<DeckEntity, DeckRejection>>`
    - `renameDeck({required String deckId, required String name})` → `Future<Outcome<void, DeckRejection>>`
    - `deleteDeck({required String deckId})` → `Future<Outcome<void, DeckRejection>>`
    - `moveDeck({required String deckId, required String newParentId})` → `Future<Outcome<void, DeckRejection>>`
    - `reorderDeck({required String deckId, required String anchorId, required DeckPlacement placement})` → `Future<Outcome<void, DeckRejection>>`
    - `changeScheduler({required String rootDeckId, required SchedulerType schedulerType})` → `Future<Outcome<void, SrsRejection>>`
  - Read providers:
    - `deckViewProvider(String deckId)`: `Stream<Outcome<DeckView, DeckRejection>>`
    - `deckMoveTargetsProvider(String deckId)`: `Stream<List<DeckMoveTarget>>`
    - `deckSearchProvider(String term)`: `Stream<List<DeckSearchHit>>`
    - `deckDeletionSummaryProvider(String deckId)`: `Future<Outcome<DeckDeletionSummary, DeckRejection>>`
  - Level state:
    - `deckLevelQueryProvider(String? parentId)`: `DeckLevelQueryState` (notifier methods `sortBy`, `show`); `DeckLevelQueryState.allowsReorder`
    - `deckReorderModeProvider(String? parentId)`: `bool` (notifier methods `start`, `finish`)
    - `deckLevelCanReorderProvider(String? parentId)`: `bool`
  - Labels and helpers:
    - `AppLocalizations.srsRejection(SrsRejection)` and `AppLocalizations.schedulerType(SchedulerType)`
    - `deckPathLabel(Iterable<String> names)` and the constant `deckPathSeparator`
    - `deckReorderAnchor(List<String> ids, int oldIndex, int newIndex)` → `({String anchorId, DeckPlacement placement})?`
  - Icons: `AppIcons.reorder`, `AppIcons.dragHandle`, `AppIcons.scheduler`.
  - Test fixture: `lockScheduler(AppDatabase db, String rootId)` in `test/support/deck_fixtures.dart`.

- [ ] **Step 1: Write the failing tests**

Append to `test/features/deck/presentation/deck_actions_controller_test.dart`, inside `main()` after the last test (add the imports listed after the block):

```dart
  DeckActionsController actions() =>
      container.read(deckActionsControllerProvider.notifier);
  DeckRepository decks() => DeckRepositoryImpl(db);

  Future<List<String>> rootOrder() async => [
    for (final row
        in await db
            .customSelect(
              'SELECT name FROM deck WHERE parent_id IS NULL '
              'ORDER BY sibling_position',
            )
            .get())
      row.read<String>('name'),
  ];

  Future<String?> parentOf(String id) async => (await db
          .customSelect(
            'SELECT parent_id FROM deck WHERE id = ?',
            variables: [Variable<String>(id)],
          )
          .getSingle())
      .read<String?>('parent_id');

  test('createSubDeck adds a deck under its parent', () async {
    final korean = await decks().root('Korean');
    final outcome = await actions().createSubDeck(
      parentId: korean.id,
      name: 'Words',
    );

    expect(outcome, isA<Ok<Object?, DeckRejection>>());
    expect(await deckCount(), 2);
  });

  test('renameDeck gives the deck its new name', () async {
    final korean = await decks().root('Korean');
    await actions().renameDeck(deckId: korean.id, name: 'Hàn Quốc');

    expect((await decks().findById(korean.id))!.name, 'Hàn Quốc');
  });

  test('deleteDeck takes the subtree with it', () async {
    final korean = await decks().root('Korean');
    await decks().sub(korean.id, 'Words');
    await actions().deleteDeck(deckId: korean.id);

    expect(await deckCount(), 0);
  });

  test('moveDeck puts the deck under its new parent', () async {
    final korean = await decks().root('Korean');
    final words = await decks().sub(korean.id, 'Words');
    final grammar = await decks().sub(korean.id, 'Grammar');
    await actions().moveDeck(deckId: grammar.id, newParentId: words.id);

    expect(await parentOf(grammar.id), words.id);
  });

  test('reorderDeck places the deck next to its anchor', () async {
    final a = await decks().root('A');
    await decks().root('B');
    final c = await decks().root('C');
    await actions().reorderDeck(
      deckId: c.id,
      anchorId: a.id,
      placement: DeckPlacement.before,
    );

    expect(await rootOrder(), ['C', 'A', 'B']);
  });

  test('changeScheduler switches an unlocked root', () async {
    final korean = await decks().root('Korean');
    final outcome = await actions().changeScheduler(
      rootDeckId: korean.id,
      schedulerType: SchedulerType.sm2,
    );

    expect(outcome, isA<Ok<Object?, SrsRejection>>());
    expect(
      (await decks().findById(korean.id))!.schedulerType,
      SchedulerType.sm2,
    );
  });

  test('changeScheduler is refused once the root is locked', () async {
    final korean = await decks().root('Korean');
    await lockScheduler(db, korean.id);
    final outcome = await actions().changeScheduler(
      rootDeckId: korean.id,
      schedulerType: SchedulerType.sm2,
    );

    expect(
      outcome,
      isA<Rejected<Object?, SrsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SrsRejection.schedulerLocked,
      ),
    );
  });
```

Imports to add to that test file:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';

import '../../../support/deck_fixtures.dart';
```

(`test/` may import `data/`; the boundary rules cover `lib/` only. If `check_architecture.py` disagrees, use `LibraryEnv(db, FakeDayClock(libraryToday)).decks` instead and record a ruling.)

Append to `test/features/deck/presentation/deck_messages_test.dart`, inside the `for (final locale …)` loop:

```dart
    test('every srs rejection has plain ${locale.languageCode} copy', () {
      for (final reason in SrsRejection.values) {
        final copy = l10n.srsRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
    });

    test('every scheduler has a ${locale.languageCode} name', () {
      for (final type in SchedulerType.values) {
        expect(l10n.schedulerType(type).trim(), isNotEmpty);
      }
    });
```

and its imports:

```dart
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Create `test/features/deck/presentation/deck_reorder_anchor_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_anchor_widget.dart';

const _ids = ['a', 'b', 'c'];

void main() {
  test('moving down lands after the deck it passed', () {
    // ReorderableListView reports 2 for "a" dropped between "b" and "c".
    expect(deckReorderAnchor(_ids, 0, 2), (
      anchorId: 'b',
      placement: DeckPlacement.after,
    ));
  });

  test('moving to the top lands before the first deck', () {
    expect(deckReorderAnchor(_ids, 2, 0), (
      anchorId: 'a',
      placement: DeckPlacement.before,
    ));
  });

  test('moving to the end lands after the last deck', () {
    expect(deckReorderAnchor(_ids, 0, 3), (
      anchorId: 'c',
      placement: DeckPlacement.after,
    ));
  });

  test('a drop where it started moves nothing', () {
    expect(deckReorderAnchor(_ids, 1, 1), isNull);
    expect(deckReorderAnchor(_ids, 1, 2), isNull);
  });

  test('a path reads root first', () {
    expect(deckPathLabel(['Korean', 'Words']), 'Korean › Words');
  });
}
```

Add to `test/support/deck_fixtures.dart` (with `import 'package:drift/drift.dart' show Variable;` and `import 'package:memox/core/database/app_database.dart';`):

```dart
/// Records a first answer on [rootId], which locks its scheduler
/// (BR-SRS-003).
Future<void> lockScheduler(AppDatabase db, String rootId) => db.customUpdate(
  'UPDATE deck SET first_answered_at = ? WHERE id = ?',
  variables: [
    Variable<DateTime>(DateTime(2026, 9, 20)),
    Variable<String>(rootId),
  ],
  updates: {db.deck},
);
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_actions_controller_test.dart test/features/deck/presentation/deck_messages_test.dart test/features/deck/presentation/deck_reorder_anchor_test.dart`
Expected: FAIL to compile. `createSubDeck`, `srsRejection`, `schedulerType` and `deckReorderAnchor` are not defined.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_icons.dart`: add after `offline`:

```dart
  static const IconData reorder = Icons.reorder; // list-ordered
  static const IconData dragHandle = Icons.drag_handle; // grip-horizontal
  static const IconData scheduler = Icons.event_repeat_outlined; // calendar-clock
```

**Use-case providers.** Create one file per use case in `lib/features/deck/presentation/providers/`, each shaped exactly like phase 1's `create_root_deck_use_case_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/<use_case_file>.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '<provider_file>.g.dart';

@riverpod
<UseCase> <useCaseName>(Ref ref) => <UseCase>(<repository>);
```

| Provider file | Function | Body |
|---|---|---|
| `create_sub_deck_use_case_provider.dart` | `createSubDeckUseCase` | `CreateSubDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `rename_deck_use_case_provider.dart` | `renameDeckUseCase` | `RenameDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `delete_deck_use_case_provider.dart` | `deleteDeckUseCase` | `DeleteDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `get_deck_deletion_summary_use_case_provider.dart` | `getDeckDeletionSummaryUseCase` | `GetDeckDeletionSummaryUseCase(ref.watch(deckRepositoryProvider))` |
| `move_deck_use_case_provider.dart` | `moveDeckUseCase` | `MoveDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `reorder_deck_use_case_provider.dart` | `reorderDeckUseCase` | `ReorderDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `search_decks_use_case_provider.dart` | `searchDecksUseCase` | `SearchDecksUseCase(ref.watch(deckRepositoryProvider))` |
| `watch_deck_use_case_provider.dart` | `watchDeckUseCase` | `WatchDeckUseCase(ref.watch(deckRepositoryProvider))` |
| `watch_deck_move_targets_use_case_provider.dart` | `watchDeckMoveTargetsUseCase` | `WatchDeckMoveTargetsUseCase(ref.watch(deckRepositoryProvider))` |
| `change_deck_scheduler_use_case_provider.dart` | `changeDeckSchedulerUseCase` | `ChangeDeckSchedulerUseCase(ref.watch(scheduleRepositoryProvider))`, importing `package:memox/features/srs/di/schedule_repository_provider.dart` instead of the deck repository provider |

The use case files are `lib/features/deck/domain/usecases/<snake name>_use_case.dart`, for example `create_sub_deck_use_case.dart`.

**Read providers:**

`lib/features/deck/presentation/providers/deck_view_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_view_provider.g.dart';

/// An open deck with its breadcrumb and Create options, again on every
/// change; `Rejected(notFound)` once it is deleted.
@riverpod
Stream<Outcome<DeckView, DeckRejection>> deckView(Ref ref, String deckId) =>
    ref.watch(watchDeckUseCaseProvider)(deckId: deckId);
```

`lib/features/deck/presentation/providers/deck_move_targets_provider.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_move_targets_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_move_targets_provider.g.dart';

/// The decks [deckId] may move under, each with its path (UC-DECK-005).
@riverpod
Stream<List<DeckMoveTarget>> deckMoveTargets(Ref ref, String deckId) =>
    ref.watch(watchDeckMoveTargetsUseCaseProvider)(deckId: deckId);
```

`lib/features/deck/presentation/providers/deck_search_provider.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/presentation/providers/search_decks_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_search_provider.g.dart';

/// Every deck whose name holds [term] (ruling P2-L9: the whole library).
@riverpod
Stream<List<DeckSearchHit>> deckSearch(Ref ref, String term) =>
    ref.watch(searchDecksUseCaseProvider)(scopeDeckId: null, term: term);
```

`lib/features/deck/presentation/providers/deck_deletion_summary_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/presentation/providers/get_deck_deletion_summary_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_deletion_summary_provider.g.dart';

/// What deleting [deckId] would take with it (BR-DECK-023).
@riverpod
Future<Outcome<DeckDeletionSummary, DeckRejection>> deckDeletionSummary(
  Ref ref,
  String deckId,
) => ref.watch(getDeckDeletionSummaryUseCaseProvider)(deckId: deckId);
```

**Controller.** In `lib/features/deck/presentation/controllers/deck_actions_controller.dart`, add these methods after `createRootDeck`, with the imports of the six new use-case providers, `deck_placement_model.dart` and `srs/domain/failures/srs_failure.dart`:

```dart
  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
  }) => ref.read(createSubDeckUseCaseProvider)(parentId: parentId, name: name);

  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) => ref.read(renameDeckUseCaseProvider)(deckId: deckId, name: name);

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) =>
      ref.read(deleteDeckUseCaseProvider)(deckId: deckId);

  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
  }) => ref.read(moveDeckUseCaseProvider)(
    deckId: deckId,
    newParentId: newParentId,
  );

  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
  }) => ref.read(reorderDeckUseCaseProvider)(
    deckId: deckId,
    anchorId: anchorId,
    placement: placement,
  );

  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => ref.read(changeDeckSchedulerUseCaseProvider)(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
```

**Level state.** Replace the notifier and add the getter in `lib/features/deck/presentation/states/deck_level_query_state.dart`:

```dart
/// What the person asked a level for: its order and which decks show
/// (UC-DECK-003, UC-DECK-006).
final class DeckLevelQueryState {
  const DeckLevelQueryState({
    this.sort = DeckLevelSort.manual,
    this.filter = DeckLevelFilter.all,
  });

  final DeckLevelSort sort;
  final DeckLevelFilter filter;

  /// Ruling P2-L3: dragging edits the manual order, so it needs that order
  /// with every deck showing.
  bool get allowsReorder =>
      sort == DeckLevelSort.manual && filter == DeckLevelFilter.all;
}

/// One level's query, kept while its screen lives (ruling P2-L6). The roots
/// are [parentId] null.
@riverpod
class DeckLevelQuery extends _$DeckLevelQuery {
  @override
  DeckLevelQueryState build(String? parentId) => const DeckLevelQueryState();

  void sortBy(DeckLevelSort sort) =>
      state = DeckLevelQueryState(sort: sort, filter: state.filter);

  void show(DeckLevelFilter filter) =>
      state = DeckLevelQueryState(sort: state.sort, filter: filter);
}
```

Phase 1's two readers now name the level. In `widgets/sections/deck_level_header_widget.dart` and `widgets/sections/deck_level_list_widget.dart`, change every `deckLevelQueryProvider` to `deckLevelQueryProvider(null)`, and in `screens/deck_level_screen.dart` change `ref.watch(deckLevelQueryProvider)` to `ref.watch(deckLevelQueryProvider(null))`. Task 2 replaces those files; this edit only keeps Task 1 compiling.

`lib/features/deck/presentation/states/deck_reorder_mode_state.dart`:

```dart
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_reorder_mode_state.g.dart';

/// Whether a level is in drag-to-reorder mode (spec §6.1, ruling P2-L3).
@riverpod
class DeckReorderMode extends _$DeckReorderMode {
  @override
  bool build(String? parentId) => false;

  void start() => state = true;

  void finish() => state = false;
}

/// Fewer decks than this have no order to change.
const int _minReorderableDecks = 2;

/// Whether a level may enter reorder mode now (ruling P2-L3).
@riverpod
bool deckLevelCanReorder(Ref ref, String? parentId) {
  final query = ref.watch(deckLevelQueryProvider(parentId));
  if (!query.allowsReorder) return false;
  final level = ref
      .watch(
        deckLevelProvider(
          parentId: parentId,
          sort: query.sort,
          filter: query.filter,
        ),
      )
      .value;
  return (level?.tiles.length ?? 0) >= _minReorderableDecks;
}
```

**Labels.** `lib/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart`:

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason the scheduler refuses a write (spec §5).
extension SrsRejectionMessage on AppLocalizations {
  String srsRejection(SrsRejection reason) => switch (reason) {
    SrsRejection.unsupportedAction => srsRejectionUnsupportedAction,
    SrsRejection.schedulerLocked => srsRejectionSchedulerLocked,
    SrsRejection.staleGeneration => srsRejectionStaleGeneration,
    SrsRejection.notFound => srsRejectionNotFound,
    SrsRejection.notARootDeck => srsRejectionNotARootDeck,
  };
}
```

`lib/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The name a person reads for each scheduler.
extension SchedulerTypeLabel on AppLocalizations {
  String schedulerType(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };
}
```

`lib/features/deck/presentation/widgets/support/deck_path_label_widget.dart`:

```dart
/// Between two decks of a path, as in "Korean › Words".
const String deckPathSeparator = ' › ';

/// A deck path read root first.
String deckPathLabel(Iterable<String> names) => names.join(deckPathSeparator);
```

`lib/features/deck/presentation/widgets/support/deck_reorder_anchor_widget.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

/// The sibling a dragged deck lands next to (UC-DECK-006), from a
/// `ReorderableListView` drop of the deck at [oldIndex] to [newIndex] over
/// [ids]. Null when the drop leaves it where it was.
({String anchorId, DeckPlacement placement})? deckReorderAnchor(
  List<String> ids,
  int oldIndex,
  int newIndex,
) {
  // The list reports [newIndex] as if the dragged deck were still in place.
  final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
  if (target == oldIndex) return null;
  final rest = [...ids]..removeAt(oldIndex);
  if (target == 0) {
    return (anchorId: rest.first, placement: DeckPlacement.before);
  }
  return (anchorId: rest[target - 1], placement: DeckPlacement.after);
}
```

**Copy.** Save this script as `.superpowers/sdd/2026-09-24-library-phase-2-deck-tree/add_arb.py` (the plan workspace is git-ignored) and run `python` on it from the repo root:

```python
import json
from pathlib import Path

INT = {"type": "int"}
STRING = {"type": "String"}

# key: (English, Vietnamese, description, placeholders or None)
KEYS = {
    "commonBack": ("Back", "Quay lại", "Accessible name of the back control.", None),
    "commonOk": ("OK", "OK", "Closes a sheet that offers no choice.", None),
    "libraryOpenSearch": ("Search decks", "Tìm bộ thẻ", "Library app bar action that opens deck search.", None),
    "libraryReorder": ("Reorder decks", "Sắp xếp lại bộ thẻ", "App bar action that starts drag-to-reorder.", None),
    "libraryReorderDone": ("Done", "Xong", "Ends drag-to-reorder mode.", None),
    "deckActions": ("Deck actions", "Thao tác với bộ thẻ", "Accessible name of an open deck's overflow action.", None),
    "deckLoadErrorTitle": ("Couldn't open this deck", "Không mở được bộ thẻ này", "Error state title when an open deck fails to load.", None),
    "deckDeletedToast": ("Deck deleted", "Đã xoá bộ thẻ", "Snackbar after the open deck is deleted.", None),
    "deckCreateSub": ("Create sub-deck", "Tạo bộ thẻ con", "Action that creates a deck inside the open deck.", None),
    "deckCreateSubTitle": ("New sub-deck", "Bộ thẻ con mới", "Title of the create sub-deck dialog.", None),
    "deckUnsetTitle": ("This deck is empty", "Bộ thẻ này đang trống", "Title shown in a deck that holds nothing yet.", None),
    "deckUnsetBody": ("Add a sub-deck to start organising it.", "Thêm một bộ thẻ con để bắt đầu sắp xếp.", "Body of the empty deck state.", None),
    "deckUnsetDeepestBody": ("This deck is at the deepest level, so it can't hold more decks.", "Bộ thẻ này đã ở cấp sâu nhất nên không chứa thêm bộ thẻ nào.", "Empty deck body at the maximum depth.", None),
    "deckRename": ("Rename", "Đổi tên", "Deck action sheet command.", None),
    "deckRenameTitle": ("Rename deck", "Đổi tên bộ thẻ", "Title of the rename dialog.", None),
    "deckRenameConfirm": ("Save", "Lưu", "Confirm of the rename dialog.", None),
    "deckMove": ("Move", "Di chuyển", "Deck action sheet command.", None),
    "deckMoveTitle": ("Move to deck", "Chuyển vào bộ thẻ", "Title of the deck move picker.", None),
    "deckMoveRule": ("The deck moves with everything in it. Decks that can't hold it aren't offered.", "Bộ thẻ được chuyển cùng mọi thứ bên trong. Những bộ thẻ không chứa được sẽ không hiện ra.", "One sentence under the move picker title.", None),
    "deckMoveEmptyTitle": ("Nowhere to move", "Không có nơi để chuyển", "Move picker title when no deck can take the deck.", None),
    "deckMoveEmptyBody": ("No other deck can hold this one.", "Không bộ thẻ nào khác chứa được bộ thẻ này.", "Move picker body when no deck can take the deck.", None),
    "deckMovedToast": ("Moved to {deck}", "Đã chuyển vào {deck}", "Snackbar after a move; deck is the new parent's name.", {"deck": STRING}),
    "deckChangeScheduler": ("Change scheduler", "Đổi bộ lập lịch", "Deck action sheet command, root decks only.", None),
    "deckSchedulerTitle": ("Scheduler", "Bộ lập lịch", "Title of the scheduler sheet.", None),
    "deckSchedulerChangeWarning": ("Changing the scheduler restarts the schedule of every card in this deck and ends study sessions in progress.", "Đổi bộ lập lịch sẽ bắt đầu lại lịch của mọi thẻ trong bộ này và kết thúc các phiên học đang dở.", "Warning in the scheduler sheet while a change is possible.", None),
    "deckSchedulerLockedNote": ("The scheduler is locked because cards in this deck have been reviewed.", "Bộ lập lịch đã khoá vì thẻ trong bộ này đã được ôn.", "Note in the scheduler sheet once it is locked.", None),
    "deckSchedulerChangedToast": ("Scheduler changed", "Đã đổi bộ lập lịch", "Snackbar after the scheduler changes.", None),
    "deckReorder": ("Reorder", "Sắp xếp lại", "Deck action sheet command that starts drag-to-reorder.", None),
    "deckDelete": ("Delete", "Xoá", "Deck action sheet command and delete confirm.", None),
    "deckDeleteTitle": ("Delete “{deck}”?", "Xoá “{deck}”?", "Delete dialog title; deck is the deck's name.", {"deck": STRING}),
    "deckDeleteSummary": ("This permanently deletes {subDeckCount, plural, =0{no sub-decks} =1{1 sub-deck} other{{subDeckCount} sub-decks}} and {cardCount, plural, =0{no cards} =1{1 card} other{{cardCount} cards}}. This can't be undone.", "Thao tác này xoá vĩnh viễn {subDeckCount} bộ thẻ con và {cardCount} thẻ. Không thể hoàn tác.", "Delete dialog body: what the delete takes with it.", {"subDeckCount": INT, "cardCount": INT}),
    "deckSearchTitle": ("Search decks", "Tìm bộ thẻ", "Title of the deck search screen.", None),
    "deckSearchHint": ("Deck name", "Tên bộ thẻ", "Hint in the deck search field.", None),
    "deckSearchClear": ("Clear search", "Xoá nội dung tìm", "Accessible name of the search clear button.", None),
    "deckSearchEmptyTitle": ("No deck matches “{term}”", "Không có bộ thẻ nào khớp “{term}”", "Search empty state; term is what the person typed.", {"term": STRING}),
    "deckSearchEmptyBody": ("Check the spelling, or try part of the name.", "Kiểm tra chính tả, hoặc thử một phần của tên.", "Search empty state body.", None),
    "srsRejectionUnsupportedAction": ("This answer doesn't fit the deck's scheduler.", "Câu trả lời này không hợp với bộ lập lịch của bộ thẻ.", "Scheduler refusal: unsupported answer.", None),
    "srsRejectionSchedulerLocked": ("The scheduler is locked because cards in this deck have been reviewed.", "Bộ lập lịch đã khoá vì thẻ trong bộ này đã được ôn.", "Scheduler refusal: locked after the first review.", None),
    "srsRejectionStaleGeneration": ("The deck's schedule changed. Start again.", "Lịch của bộ thẻ đã thay đổi. Hãy bắt đầu lại.", "Scheduler refusal: the schedule was reset meanwhile.", None),
    "srsRejectionNotFound": ("This deck no longer exists.", "Bộ thẻ này không còn nữa.", "Scheduler refusal: the deck is gone.", None),
    "srsRejectionNotARootDeck": ("Only a top-level deck has a scheduler.", "Chỉ bộ thẻ cấp cao nhất mới có bộ lập lịch.", "Scheduler refusal: not a root deck.", None),
}

for path, is_template in (("lib/l10n/app_en.arb", True), ("lib/l10n/app_vi.arb", False)):
    file = Path(path)
    data = json.loads(file.read_text(encoding="utf-8"))
    for key, (en, vi, description, placeholders) in KEYS.items():
        assert key not in data, key
        data[key] = en if is_template else vi
        if is_template:
            meta = {}
            if placeholders:
                meta["placeholders"] = placeholders
            meta["description"] = description
            data["@" + key] = meta
    file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
```

Then run `flutter gen-l10n`.

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation
```

Expected: PASS, including 7 new controller tests, 4 new message tests (2 per locale) and 5 anchor and path tests. The phase 1 screen tests still pass, since the root reads `deckLevelQueryProvider(null)`.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): phase 2 plumbing: providers, commands, level state and copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 2: The recursive deck screen

**Files:**
- Rewrite: `lib/features/deck/presentation/screens/deck_level_screen.dart`, `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_header_widget.dart`, `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`, `lib/app/router/app_router.dart` (a stub builder), `test/support/library_harness.dart`, `test/features/deck/presentation/deck_level_screen_test.dart`, `test/features/deck/presentation/deck_level_screen_golden_test.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`, `lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart`
- Test: `test/features/deck/presentation/open_deck_screen_test.dart`, `test/features/deck/presentation/deck_name_dialog_widget_test.dart`

**Interfaces:**
- Consumes (Task 1): `deckViewProvider`, `deckLevelQueryProvider(parentId)`, `DeckActionsController.createSubDeck` / `renameDeck`, `deckLevelProvider`.
- Produces:
  - `DeckLevelScreen({String? deckId, required ValueChanged<String> onOpenDeck, required ValueChanged<String?> onOpenAncestor, required VoidCallback onSearch})`.
  - `DeckLevelBodyWidget({required String? parentId, required ValueChanged<String> onOpenDeck, required Widget emptyState})`.
  - `showCreateSubDeckDialog(BuildContext, {required String parentId})` and `showRenameDeckDialog(BuildContext, {required DeckEntity deck})`, both `Future<void>`.
  - In the harness: `deckScreen({String? deckId, ValueChanged<String>? onOpenDeck, ValueChanged<String?>? onOpenAncestor})`.
  - In the screen file, two private widgets later tasks edit:
    - `_LibraryRoot` (`ConsumerWidget`, fields `onOpenDeck`, `onSearch`);
    - `_OpenDeckContent` (`ConsumerWidget`, fields `view`, `onOpenDeck`, `onOpenAncestor`).

- [ ] **Step 1: Write the failing tests**

Add to `test/support/library_harness.dart` (import `package:memox/features/deck/presentation/screens/deck_level_screen.dart`):

```dart
/// A deck level whose navigation goes nowhere, for screen tests: the Library
/// root when [deckId] is null.
DeckLevelScreen deckScreen({
  String? deckId,
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String?>? onOpenAncestor,
}) => DeckLevelScreen(
  deckId: deckId,
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onSearch: () {},
);
```

In `test/features/deck/presentation/deck_level_screen_test.dart` and `deck_level_screen_golden_test.dart`, replace every `const DeckLevelScreen()` with `deckScreen()` and delete the now unused import of `deck_level_screen.dart`.

`test/features/deck/presentation/open_deck_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _path = ['Korean', 'Words', 'Verbs'];

Finder _crumb(String label) =>
    find.descendant(of: find.byType(MxBreadcrumb), matching: find.text(label));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

/// A root and one deck per level below it, down to [depth].
Future<List<DeckEntity>> _chain(
  LibraryEnv env,
  int depth,
  String Function(int level) name,
) async {
  final decks = [await env.decks.root(name(1))];
  for (var level = 2; level <= depth; level++) {
    decks.add(await env.decks.sub(decks.last.id, name(level)));
  }
  return decks;
}

void main() {
  libraryTest('an open deck names itself and shows its path', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, 3, (level) => _path[level - 1]);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));

    expect(_barTitle('Verbs'), findsOneWidget);
    for (final label in [_en.navLibrary, ..._path]) {
      expect(_crumb(label), findsOneWidget);
    }
  });

  libraryTest('a breadcrumb tap reports that level, the root as null', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, 3, (level) => _path[level - 1]);
    final levels = <String?>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id, onOpenAncestor: levels.add),
    );
    await tester.tap(_crumb('Korean'));
    await tester.tap(_crumb(_en.navLibrary));

    expect(levels, [chain.first.id, null]);
  });

  libraryTest('a deck of decks lists its sub-decks; a row opens its deck', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new', deckId: words.id);
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenDeck: opened.add),
    );

    // The level line and the Words row both read "1 new".
    expect(find.text('1 new', findRichText: true), findsNWidgets(2));
    expect(find.byType(MxListSectionHeader), findsOneWidget);
    await tester.tap(find.text('Words'));
    expect(opened, [words.id]);
  });

  libraryTest('an empty deck offers a sub-deck; creating one lists it', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.text(_en.deckCreateSub),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Words');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text('Words'), findsOneWidget);
  });

  libraryTest('the FAB opens the new sub-deck dialog', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckCreateSubTitle), findsOneWidget);
  });

  libraryTest('the deepest deck offers no sub-deck', (tester, env) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Level $level',
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));

    expect(find.byType(MxFab), findsNothing);
    expect(find.text(_en.deckUnsetDeepestBody), findsOneWidget);
    expect(find.text(_en.deckCreateSub), findsNothing);
  });

  libraryTest('a deck of cards shows no deck list yet (ruling P2-L1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new', deckId: words.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));

    expect(_barTitle('Words'), findsOneWidget);
    expect(find.byType(MxListSectionHeader), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });

  libraryTest('a deck deleted while open says so (ruling P2-L7)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await env.decks.deleteDeck(deckId: korean.id);
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.deckDeletedToast), findsOneWidget);
  });

  libraryTest('a 10-level path at 2x keeps the current level in view (RF4)', (
    tester,
    env,
  ) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Từ vựng tiếng Hàn cấp $level',
    );
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final current = _crumb('Từ vựng tiếng Hàn cấp ${DeckEntity.maxDepth}');
    expect(tester.getRect(current).right, lessThanOrEqualTo(360));
  });

  libraryTest('an open deck meets the target guidelines', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    await expectAccessibleTargets(tester);
  });
}
```

`test/features/deck/presentation/deck_name_dialog_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showRenameDeckDialog(context, deck: deck),
    ),
  ),
);

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  libraryTest('rename starts from the current name and saves the new one', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);

    expect(find.text('Korean'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('a blank name stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await tester.enterText(find.byType(EditableText), '   ');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.deckRejectionBlankName), findsOneWidget);
  });

  libraryTest('a deck gone meanwhile closes the dialog and says so (P2-L10)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _host(korean));
    await open(tester);
    await env.decks.deleteDeck(deckId: korean.id);
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.deckRejectionNotFound), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/open_deck_screen_test.dart test/features/deck/presentation/deck_name_dialog_widget_test.dart`
Expected: FAIL to compile. `DeckLevelScreen` has no `deckId`, and `deck_name_dialog_widget.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Sends a dialog's name through one controller command.
typedef DeckNameSubmit =
    Future<Outcome<Object?, DeckRejection>> Function(
      DeckActionsController actions,
      String name,
    );

/// A new deck inside [parentId], at the end of its decks (UC-DECK-004).
Future<void> showCreateSubDeckDialog(
  BuildContext context, {
  required String parentId,
}) => showMxDialog<void>(
  context,
  builder: (dialogContext) => DeckNameDialogWidget(
    title: dialogContext.l10n.deckCreateSubTitle,
    confirmLabel: dialogContext.l10n.deckCreateConfirm,
    submit: (actions, name) =>
        actions.createSubDeck(parentId: parentId, name: name),
  ),
);

/// A new name for [deck] (UC-DECK-002).
Future<void> showRenameDeckDialog(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxDialog<void>(
  context,
  builder: (dialogContext) => DeckNameDialogWidget(
    title: dialogContext.l10n.deckRenameTitle,
    confirmLabel: dialogContext.l10n.deckRenameConfirm,
    initialName: deck.name,
    submit: (actions, name) => actions.renameDeck(deckId: deck.id, name: name),
  ),
);

/// One name field and its confirm. A refusal about the name stays under
/// the field; any other refusal closes the dialog with a snackbar (ruling
/// P2-L10).
class DeckNameDialogWidget extends ConsumerStatefulWidget {
  const DeckNameDialogWidget({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.submit,
    this.initialName = '',
  });

  final String title;
  final String confirmLabel;
  final DeckNameSubmit submit;
  final String initialName;

  @override
  ConsumerState<DeckNameDialogWidget> createState() =>
      _DeckNameDialogWidgetState();
}

class _DeckNameDialogWidgetState extends ConsumerState<DeckNameDialogWidget> {
  static const _nameReasons = {
    DeckRejection.blankName,
    DeckRejection.nameTooLong,
  };

  late final _name = TextEditingController(text: widget.initialName);
  DeckRejection? _rejection;

  /// One submit at a time: a second tap while the first runs does nothing.
  var _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _rejection = null;
    });
    try {
      final outcome = await widget.submit(
        ref.read(deckActionsControllerProvider.notifier),
        _name.text,
      );
      if (!mounted) return;
      switch (outcome) {
        case Ok():
          Navigator.of(context).pop();
        case Rejected(:final reason) when _nameReasons.contains(reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
        case Rejected(:final reason):
          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
          Navigator.of(context).pop();
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          MxTextField(
            controller: _name,
            hintText: l10n.deckNameHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.deckRejection(reason),
            },
            textInputAction: TextInputAction.done,
            onSubmitted: _isSubmitting ? null : (_) => _submit(),
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: widget.confirmLabel,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// A deck that holds nothing yet (UC-DECK-004). Ruling P2-L1: it offers a
/// sub-deck now, and a card once the editor arrives in phase 4.
class DeckUnsetStateWidget extends StatelessWidget {
  const DeckUnsetStateWidget({super.key, required this.onCreateSubDeck});

  /// Null at the deepest level, where no sub-deck fits (BR-DECK-001).
  final VoidCallback? onCreateSubDeck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canNest = onCreateSubDeck != null;
    return MxEmptyState(
      icon: AppIcons.folder,
      title: l10n.deckUnsetTitle,
      body: canNest ? l10n.deckUnsetBody : l10n.deckUnsetDeepestBody,
      actionLabel: canNest ? l10n.deckCreateSub : null,
      onAction: onCreateSubDeck,
    );
  }
}
```

`lib/features/deck/presentation/widgets/items/deck_row_widget.dart`: the class gains a required `onTap` and a chevron. Keep the imports.

```dart
/// One deck of a level: its tile, its name and its workload. A tap opens it.
class DeckRowWidget extends StatelessWidget {
  const DeckRowWidget({
    super.key,
    required this.tile,
    required this.onTap,
    this.hasDivider = true,
  });

  final DeckTile tile;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => MxListRow(
    title: tile.name,
    leading: const MxIconTile(
      icon: AppIcons.library,
      size: MxIconTileSize.large,
    ),
    meta: DeckWorkloadLineWidget(
      overdueCount: tile.overdueCount,
      todayCount: tile.dueTodayCount,
      newCount: tile.newCount,
      cardCount: tile.cardCount,
    ),
    hasChevron: true,
    onTap: onTap,
    hasDivider: hasDivider,
  );
}
```

`lib/features/deck/presentation/widgets/sections/deck_level_header_widget.dart`: add `required this.parentId` with the field `final String? parentId;`. Use `deckLevelQueryProvider(parentId)` in both the `_query` helper and the `ref.watch`.

`lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (whole file):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_header_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// A loaded level: today's work first, then the decks (spec §6.1, D3).
class DeckLevelListWidget extends ConsumerWidget {
  const DeckLevelListWidget({
    super.key,
    required this.level,
    required this.parentId,
    required this.onOpenDeck,
    required this.emptyState,
  });

  final DeckLevel level;
  final String? parentId;
  final ValueChanged<String> onOpenDeck;

  /// Shown when the level holds no deck at all (ruling L4).
  final Widget emptyState;

  void _showAll(WidgetRef ref) => ref
      .read(deckLevelQueryProvider(parentId).notifier)
      .show(DeckLevelFilter.all);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(deckLevelQueryProvider(parentId)).filter;
    final tiles = level.tiles;
    // Ruling L4: an empty level is the first run; an empty filter is not.
    if (tiles.isEmpty && filter == DeckLevelFilter.all) {
      return MxScreenScroll(
        clearance: MxScrollClearance.fabAboveNav,
        children: [const SizedBox(height: AppSpacing.gutter), emptyState],
      );
    }
    return MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        const SizedBox(height: AppSpacing.gutter),
        DeckWorkloadLineWidget(
          overdueCount: level.overdueCount,
          todayCount: level.dueTodayCount,
          newCount: level.newCount,
          cardCount:
              level.overdueCount +
              level.dueTodayCount +
              level.newCount +
              level.scheduledCount,
        ),
        const SizedBox(height: AppSpacing.section),
        DeckLevelHeaderWidget(parentId: parentId),
        if (tiles.isEmpty)
          MxEmptyState(
            icon: AppIcons.library,
            title: l10n.libraryNothingDueTitle,
            body: l10n.libraryNothingDueBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
            actionLabel: l10n.libraryShowAllDecks,
            onAction: () => _showAll(ref),
          )
        else
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, tile) in tiles.indexed)
                  DeckRowWidget(
                    tile: tile,
                    onTap: () => onOpenDeck(tile.id),
                    hasDivider: index < tiles.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
```

`lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A level's decks as its stream delivers them (spec §5): skeleton rows
/// while loading, a plain error with Retry, then the list. The roots are
/// [parentId] null.
class DeckLevelBodyWidget extends ConsumerWidget {
  const DeckLevelBodyWidget({
    super.key,
    required this.parentId,
    required this.onOpenDeck,
    required this.emptyState,
  });

  final String? parentId;
  final ValueChanged<String> onOpenDeck;

  /// Shown when the level holds no deck at all.
  final Widget emptyState;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    final provider = deckLevelProvider(
      parentId: parentId,
      sort: query.sort,
      filter: query.filter,
    );
    return ref
        .watch(provider)
        .when(
          data: (level) => DeckLevelListWidget(
            level: level,
            parentId: parentId,
            onOpenDeck: onOpenDeck,
            emptyState: emptyState,
          ),
          loading: () => MxScreenScroll(
            clearance: MxScrollClearance.fabAboveNav,
            children: [
              for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
            ],
          ),
          error: (_, _) => MxScreenScroll(
            clearance: MxScrollClearance.fabAboveNav,
            children: [
              MxErrorState(
                title: l10n.libraryLoadErrorTitle,
                body: l10n.libraryLoadErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(provider),
              ),
            ],
          ),
        );
  }
}
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (whole file):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_body_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// One level of the deck tree (spec §6.1): the Library root when [deckId] is
/// null, otherwise an open deck under its breadcrumb. Navigation arrives as
/// callbacks; the screen never builds a path (spec §4).
class DeckLevelScreen extends StatelessWidget {
  const DeckLevelScreen({
    super.key,
    this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.onSearch,
  });

  final String? deckId;
  final ValueChanged<String> onOpenDeck;

  /// A breadcrumb tap: a deck above this one, or null for the Library root.
  final ValueChanged<String?> onOpenAncestor;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => switch (deckId) {
    null => _LibraryRoot(onOpenDeck: onOpenDeck, onSearch: onSearch),
    final id => _OpenDeck(
      deckId: id,
      onOpenDeck: onOpenDeck,
      onOpenAncestor: onOpenAncestor,
    ),
  };
}

/// The roots with today's work first (UC-DECK-003).
class _LibraryRoot extends ConsumerWidget {
  const _LibraryRoot({required this.onOpenDeck, required this.onSearch});

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navLibrary,
        actions: [
          MxIconButton(
            icon: AppIcons.search,
            semanticLabel: l10n.libraryOpenSearch,
            onPressed: onSearch,
          ),
        ],
      ),
      fab: MxFab(
        icon: AppIcons.add,
        semanticLabel: l10n.libraryCreateDeck,
        onPressed: createDeck,
      ),
      body: DeckLevelBodyWidget(
        parentId: null,
        onOpenDeck: onOpenDeck,
        emptyState: MxEmptyState(
          icon: AppIcons.library,
          title: l10n.libraryEmptyTitle,
          body: l10n.libraryEmptyBody,
          actionLabel: l10n.libraryCreateDeck,
          onAction: createDeck,
        ),
      ),
    );
  }
}

/// An open deck while its stream loads, fails or is gone.
class _OpenDeck extends ConsumerWidget {
  const _OpenDeck({
    required this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
  });

  final String deckId;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;

  static const int _skeletonRows = 4;

  /// Ruling P2-L7: the deck is gone. Say so once and step back.
  void _leaveWhenGone(
    BuildContext context,
    AsyncValue<Outcome<DeckView, DeckRejection>>? previous,
    AsyncValue<Outcome<DeckView, DeckRejection>> next,
  ) {
    if (previous?.value case Rejected()) return;
    if (next.value case Rejected(reason: DeckRejection.notFound)) {
      showMxSnackbar(context, message: context.l10n.deckDeletedToast);
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = deckViewProvider(deckId);
    ref.listen(
      provider,
      (previous, next) => _leaveWhenGone(context, previous, next),
    );
    final bar = MxAppBar(
      title: l10n.navLibrary,
      density: MxAppBarDensity.content,
      leading: const _BackButton(),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => _OpenDeckContent(
        view: value,
        onOpenDeck: onOpenDeck,
        onOpenAncestor: onOpenAncestor,
      ),
      AsyncError() => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.deckLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      // Loading, or gone and about to pop.
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}

/// An open deck: its name, its path, and what it holds (spec §6.1).
class _OpenDeckContent extends ConsumerWidget {
  const _OpenDeckContent({
    required this.view,
    required this.onOpenDeck,
    required this.onOpenAncestor,
  });

  final DeckView view;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final deck = view.deck;
    final canCreateDeck = view.createOptions.contains(DeckCreateOption.deck);
    void createSubDeck() =>
        unawaited(showCreateSubDeckDialog(context, parentId: deck.id));
    return MxAppShell(
      appBar: MxAppBar(
        title: deck.name,
        density: MxAppBarDensity.content,
        leading: const _BackButton(),
      ),
      fab: canCreateDeck
          ? MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.deckCreateSub,
              onPressed: createSubDeck,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ruling P2-L4: Library › ancestors › this deck.
          MxBreadcrumb(
            segments: [
              MxBreadcrumbSegment(
                label: l10n.navLibrary,
                onTap: () => onOpenAncestor(null),
              ),
              for (final entry in view.breadcrumb)
                MxBreadcrumbSegment(
                  label: entry.name,
                  onTap: () => onOpenAncestor(entry.id),
                ),
              MxBreadcrumbSegment(label: deck.name),
            ],
          ),
          Expanded(
            child: switch (deck.contentType) {
              // Ruling P2-L1: the card list arrives in phase 3.
              DeckContentType.card => const SizedBox.shrink(),
              DeckContentType.deck || DeckContentType.unset =>
                DeckLevelBodyWidget(
                  parentId: deck.id,
                  onOpenDeck: onOpenDeck,
                  emptyState: DeckUnsetStateWidget(
                    onCreateSubDeck: canCreateDeck ? createSubDeck : null,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => MxIconButton(
    icon: AppIcons.back,
    semanticLabel: context.l10n.commonBack,
    onPressed: () => unawaited(Navigator.of(context).maybePop()),
  );
}
```

Routing is Task 6. Until then, in `lib/app/router/app_router.dart` the `/decks` builder becomes the following, so the app compiles:

```dart
              builder: (context, state) => DeckLevelScreen(
                onOpenDeck: (_) {},
                onOpenAncestor: (_) {},
                onSearch: () {},
              ),
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation test/app/app_test.dart
```

Expected: PASS. The new tests (10 open deck, 3 name dialog) pass, and all phase 1 tests pass through `deckScreen()`.

- [ ] **Step 5: Regenerate the root goldens, look, gate, commit**

The root app bar now has the search action, so the phase 1 Library goldens change.

```bash
flutter test --update-goldens --tags golden test/features/deck/presentation/deck_level_screen_golden_test.dart test/app/app_golden_test.dart
flutter test --tags golden test/features/deck/presentation test/app
```

Open `library_decks_light.png` and `test/app/goldens/app_library_light.png`. The search glyph sits at the right of the "Library" bar, and nothing else moved. `app_gallery_*` must not change. Delete any `failures/` folder.

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): open decks level by level with their breadcrumb

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Reorder mode

**Files:**
- Create: `lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart`, `lib/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`, `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Test: `test/features/deck/presentation/deck_reorder_test.dart`

**Interfaces:**
- Consumes:
  - Task 1: `deckReorderModeProvider`, `deckLevelCanReorderProvider`, `deckReorderAnchor`, `DeckActionsController.reorderDeck`, `reorderDeckUseCaseProvider`, `AppIcons.reorder` / `dragHandle`.
  - Task 2: `DeckLevelBodyWidget`, `_LibraryRoot`, `_OpenDeckContent`.
- Produces:
  - `DeckReorderListWidget({required List<DeckTile> tiles})`.
  - `DeckReorderRowWidget({required DeckTile tile, required int index, bool hasDivider})`.
  - `_ReorderDone({required String? parentId})` in the screen file, which Task 4 reuses.

- [ ] **Step 1: Write the failing tests**

`test/features/deck/presentation/deck_reorder_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/reorder_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Decks whose every reorder is refused, as when the anchor moved away.
final class _RefusingDecks implements DeckRepository {
  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  }) async => const Rejected(DeckRejection.notSiblings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<String>> _rootOrder(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT name FROM deck WHERE parent_id IS NULL '
            'ORDER BY sibling_position',
          )
          .get())
    row.read<String>('name'),
];

/// The deck names in reorder mode, top to bottom.
List<String> _shownOrder(WidgetTester tester) => [
  for (final row in tester.widgetList<DeckReorderRowWidget>(
    find.byType(DeckReorderRowWidget),
  ))
    row.tile.name,
];

/// Drags [name]'s handle down one and a half rows, past the next deck.
Future<void> _dragPastNext(WidgetTester tester, String name) async {
  final row = find.widgetWithText(DeckReorderRowWidget, name);
  final handle = find.descendant(
    of: row,
    matching: find.byIcon(AppIcons.dragHandle),
  );
  final step = tester.getSize(row).height * 0.75;
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await tester.pump();
  await gesture.moveBy(Offset(0, step));
  await tester.pump();
  await gesture.moveBy(Offset(0, step));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _startReorder(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.libraryReorder));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('Reorder is offered for a manual level of two decks or more', (
    tester,
    env,
  ) async {
    await env.decks.root('A');
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byTooltip(_en.libraryReorder), findsNothing);

    await env.decks.root('B');
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip(_en.libraryReorder), findsOneWidget);

    await tester.tap(find.text(_en.deckSortTrigger(_en.deckSortManual)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortName));
    await tester.pumpAndSettle();
    expect(find.byTooltip(_en.libraryReorder), findsNothing);
  });

  libraryTest('dragging a deck past the next one saves the new order', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B', 'C']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);

    expect(find.byType(MxFab), findsNothing);
    await _dragPastNext(tester, 'A');

    expect(await _rootOrder(env), ['B', 'A', 'C']);
    expect(_shownOrder(tester), ['B', 'A', 'C']);
  });

  libraryTest('each row offers TalkBack move actions (D7)', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);
    final handle = tester.ensureSemantics();
    final material = MaterialLocalizations.of(
      tester.element(find.byType(DeckReorderRowWidget).first),
    );

    final labels = <String>{};
    for (
      SemanticsNode? node = tester.getSemantics(find.text('A'));
      node != null;
      node = node.parent
    ) {
      for (final id in node.getSemanticsData().customSemanticsActionIds ?? []) {
        labels.add(CustomSemanticsAction.getAction(id)!.label!);
      }
    }
    expect(labels, contains(material.reorderItemDown));
    handle.dispose();
  });

  libraryTest('Done ends the mode and brings back the FAB', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);
    await tester.tap(find.text(_en.libraryReorderDone));
    await tester.pumpAndSettle();

    expect(find.byType(DeckReorderRowWidget), findsNothing);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('a refused drop snaps back and says why (RF3)', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B', 'C']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        reorderDeckUseCaseProvider.overrideWithValue(
          ReorderDeckUseCase(_RefusingDecks()),
        ),
      ],
    );
    await _startReorder(tester);
    await _dragPastNext(tester, 'A');

    expect(_shownOrder(tester), ['A', 'B', 'C']);
    expect(find.text(_en.deckRejectionNotSiblings), findsOneWidget);
  });

  libraryTest('reorder mode meets the target guidelines at 2x', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen(), textScale: 2);
    await _startReorder(tester);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_reorder_test.dart`
Expected: FAIL to compile, because `deck_reorder_row_widget.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A deck in reorder mode: its drag handle takes the chevron's place (spec
/// §6.1). The list around it gives TalkBack its move actions.
class DeckReorderRowWidget extends StatelessWidget {
  const DeckReorderRowWidget({
    super.key,
    required this.tile,
    required this.index,
    this.hasDivider = true,
  });

  final DeckTile tile;

  /// The row's place in the list, which the drag handle reports.
  final int index;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => MxListRow(
    title: tile.name,
    leading: const MxIconTile(
      icon: AppIcons.library,
      size: MxIconTileSize.large,
    ),
    meta: DeckWorkloadLineWidget(
      overdueCount: tile.overdueCount,
      todayCount: tile.dueTodayCount,
      newCount: tile.newCount,
      cardCount: tile.cardCount,
    ),
    trailing: ReorderableDragStartListener(
      index: index,
      child: const SizedBox.square(
        dimension: AppSize.touchTarget,
        child: Icon(AppIcons.dragHandle),
      ),
    ),
    hasDivider: hasDivider,
  );
}
```

`lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_anchor_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A level's decks in drag-to-reorder mode (spec §6.1, ruling P2-L3). Each
/// drop is one `ReorderDeckUseCase` call. The dropped order shows at once,
/// and the stream's next order, or the stored one after a refusal, wins.
class DeckReorderListWidget extends ConsumerStatefulWidget {
  const DeckReorderListWidget({super.key, required this.tiles});

  final List<DeckTile> tiles;

  @override
  ConsumerState<DeckReorderListWidget> createState() =>
      _DeckReorderListWidgetState();
}

class _DeckReorderListWidgetState extends ConsumerState<DeckReorderListWidget> {
  late List<DeckTile> _order = widget.tiles;

  @override
  void didUpdateWidget(DeckReorderListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _order = widget.tiles;
  }

  Future<void> _drop(int oldIndex, int newIndex) async {
    final anchor = deckReorderAnchor(
      [for (final tile in _order) tile.id],
      oldIndex,
      newIndex,
    );
    if (anchor == null) return;
    final moving = _order[oldIndex];
    setState(() {
      _order = [..._order]
        ..removeAt(oldIndex)
        ..insert(newIndex > oldIndex ? newIndex - 1 : newIndex, moving);
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .reorderDeck(
            deckId: moving.id,
            anchorId: anchor.anchorId,
            placement: anchor.placement,
          );
      if (!mounted) return;
      if (outcome case Rejected(:final reason)) {
        setState(() => _order = widget.tiles);
        showMxSnackbar(context, message: context.l10n.deckRejection(reason));
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _order = widget.tiles);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    buildDefaultDragHandles: false,
    padding: EdgeInsetsDirectional.fromSTEB(
      AppSpacing.gutter,
      AppSpacing.gutter,
      AppSpacing.gutter,
      AppSpacing.section + MediaQuery.paddingOf(context).bottom,
    ),
    itemCount: _order.length,
    onReorder: (oldIndex, newIndex) => unawaited(_drop(oldIndex, newIndex)),
    itemBuilder: (context, index) => DeckReorderRowWidget(
      key: ValueKey(_order[index].id),
      tile: _order[index],
      index: index,
      hasDivider: index < _order.length - 1,
    ),
  );
}
```

`lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`:
- Import `deck_reorder_mode_state.dart` and `deck_reorder_list_widget.dart`.
- Add `final isReordering = ref.watch(deckReorderModeProvider(parentId));` after the `provider` line.
- Replace the `data:` branch with:

```dart
          data: (level) => isReordering
              ? DeckReorderListWidget(tiles: level.tiles)
              : DeckLevelListWidget(
                  level: level,
                  parentId: parentId,
                  onOpenDeck: onOpenDeck,
                  emptyState: emptyState,
                ),
```

`lib/features/deck/presentation/screens/deck_level_screen.dart`: import `deck_reorder_mode_state.dart` and `package:memox/shared/widgets/mx_button.dart`. Then make these edits.

1. Replace the whole `_LibraryRoot` class with:

```dart
/// The roots with today's work first (UC-DECK-003).
class _LibraryRoot extends ConsumerWidget {
  const _LibraryRoot({required this.onOpenDeck, required this.onSearch});

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onSearch;

  void _startReorder(WidgetRef ref) =>
      ref.read(deckReorderModeProvider(null).notifier).start();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReordering = ref.watch(deckReorderModeProvider(null));
    final canReorder = ref.watch(deckLevelCanReorderProvider(null));
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navLibrary,
        actions: isReordering
            ? const [_ReorderDone(parentId: null)]
            : [
                MxIconButton(
                  icon: AppIcons.search,
                  semanticLabel: l10n.libraryOpenSearch,
                  onPressed: onSearch,
                ),
                // Ruling P2-L2: the roots reorder from the app bar.
                if (canReorder)
                  MxIconButton(
                    icon: AppIcons.reorder,
                    semanticLabel: l10n.libraryReorder,
                    onPressed: () => _startReorder(ref),
                  ),
              ],
      ),
      fab: isReordering
          ? null
          : MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.libraryCreateDeck,
              onPressed: createDeck,
            ),
      body: DeckLevelBodyWidget(
        parentId: null,
        onOpenDeck: onOpenDeck,
        emptyState: MxEmptyState(
          icon: AppIcons.library,
          title: l10n.libraryEmptyTitle,
          body: l10n.libraryEmptyBody,
          actionLabel: l10n.libraryCreateDeck,
          onAction: createDeck,
        ),
      ),
    );
  }
}
```

2. In `_OpenDeckContent.build`, add `final isReordering = ref.watch(deckReorderModeProvider(deck.id));` after `final deck = view.deck;`. Give the `MxAppBar` `actions: [if (isReordering) _ReorderDone(parentId: deck.id)],` and change the FAB condition to `canCreateDeck && !isReordering`.

3. Add at the end of the file:

```dart
/// Ends reorder mode for its level (ruling P2-L3).
class _ReorderDone extends ConsumerWidget {
  const _ReorderDone({required this.parentId});

  final String? parentId;

  void _finish(WidgetRef ref) =>
      ref.read(deckReorderModeProvider(parentId).notifier).finish();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MxButton(
    label: context.l10n.libraryReorderDone,
    size: MxButtonSize.compact,
    onPressed: () => _finish(ref),
  );
}
```

- [ ] **Step 4: Run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation
```

Expected: PASS, with 6 new reorder tests.

- If the drag lands one row off, change the two `moveBy` steps to `0.8` of a row and record a test-only ruling.
- If the move-action labels are not found on an ancestor of the "A" text, search the descendants of `find.byType(DeckReorderRowWidget).first` instead and record a test-only ruling. `ReorderableListView` wraps each item in a `Semantics` with these custom actions.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): reorder decks by drag, with TalkBack move actions

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The deck action sheet: rename, move, scheduler, reorder, delete

**Files:**
- Create in `lib/features/deck/presentation/widgets/overlays/`: `deck_action_sheet_widget.dart`, `deck_delete_dialog_widget.dart`, `deck_move_sheet_widget.dart`, `deck_scheduler_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Test: `test/features/deck/presentation/deck_action_sheet_test.dart`

**Interfaces:**
- Consumes:
  - Task 1: `DeckActionsController.deleteDeck` / `moveDeck` / `changeScheduler`, `deckDeletionSummaryProvider`, `deckMoveTargetsProvider`, `deckLevelCanReorderProvider`, `deckReorderModeProvider`, `srsRejection`, `schedulerType`, `deckPathLabel`, `lockScheduler`, `AppIcons.scheduler` / `reorder`.
  - Task 2: `showRenameDeckDialog`, `_OpenDeckContent`.
  - Task 3: `_ReorderDone`.
- Produces:
  - `enum DeckAction { rename, move, changeScheduler, reorder, delete }`.
  - Overlay openers:
    - `showDeckActionSheet(BuildContext, {required DeckView view, required bool canReorder})` → `Future<DeckAction?>`;
    - `showDeleteDeckDialog(BuildContext, {required DeckEntity deck})` → `Future<void>`;
    - `showMoveDeckSheet(BuildContext, {required DeckEntity deck})` → `Future<void>`;
    - `showDeckSchedulerSheet(BuildContext, {required DeckView view})` → `Future<void>`.

- [ ] **Step 1: Write the failing tests**

`test/features/deck/presentation/deck_action_sheet_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.deckActions));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String command) async {
  await _openSheet(tester);
  await tester.tap(find.text(command));
  await tester.pumpAndSettle();
}

Future<int> _deckCount(LibraryEnv env) async => (await env.db
        .customSelect('SELECT COUNT(*) AS n FROM deck')
        .getSingle())
    .read<int>('n');

Future<String?> _parentOf(LibraryEnv env, String id) async => (await env.db
        .customSelect(
          'SELECT parent_id FROM deck WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .getSingle())
    .read<String?>('parent_id');

void main() {
  libraryTest('a root offers rename, its scheduler and delete, not move', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _openSheet(tester);

    expect(find.text(_en.deckRename), findsOneWidget);
    expect(find.text(_en.deckChangeScheduler), findsOneWidget);
    expect(find.text(_en.deckSchedulerEightBox), findsOneWidget);
    expect(find.text(_en.deckDelete), findsOneWidget);
    expect(find.text(_en.deckMove), findsNothing);
    expect(find.text(_en.deckReorder), findsNothing);
  });

  libraryTest('a sub-deck offers move, not the scheduler; two decks reorder', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(words.id, 'A');
    await env.decks.sub(words.id, 'B');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _openSheet(tester);

    expect(find.text(_en.deckMove), findsOneWidget);
    expect(find.text(_en.deckReorder), findsOneWidget);
    expect(find.text(_en.deckChangeScheduler), findsNothing);
  });

  libraryTest('Rename renames the open deck', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckRename);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    // The app bar title and the current crumb.
    expect(find.text('Hàn Quốc'), findsNWidgets(2));
  });

  libraryTest('Delete says what goes with the deck, then deletes it', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final verbs = await env.decks.sub(words.id, 'Verbs');
    await insertCard(env.db, id: 'one', deckId: verbs.id);
    await insertCard(env.db, id: 'two', deckId: verbs.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _choose(tester, _en.deckDelete);

    expect(find.text(_en.deckDeleteTitle('Words')), findsOneWidget);
    expect(find.text(_en.deckDeleteSummary(1, 2)), findsOneWidget);
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(await _deckCount(env), 1);
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
  });

  libraryTest('Move lists targets by path and moves there', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final grammar = await env.decks.sub(korean.id, 'Grammar');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: grammar.id));
    await _choose(tester, _en.deckMove);
    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();

    expect(await _parentOf(env, grammar.id), words.id);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
  });

  libraryTest('a double tap on a move target moves once (RF2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    final grammar = await env.decks.sub(korean.id, 'Grammar');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: grammar.id));
    await _choose(tester, _en.deckMove);
    await tester.tap(find.text('Korean › Words'));
    await tester.tap(find.text('Korean › Words'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect(find.text(_en.deckRejectionSameParent), findsNothing);
  });

  libraryTest('with nowhere to go, the picker says so and offers OK', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _choose(tester, _en.deckMove);

    expect(find.text(_en.deckMoveEmptyTitle), findsOneWidget);
    expect(find.text(_en.commonOk), findsOneWidget);
  });

  libraryTest('an unlocked scheduler warns, then changes', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckChangeScheduler);

    expect(find.text(_en.deckSchedulerChangeWarning), findsOneWidget);
    await tester.tap(find.text(_en.deckSchedulerSm2));
    await tester.pumpAndSettle();

    expect(
      (await env.decks.findById(korean.id))!.schedulerType,
      SchedulerType.sm2,
    );
    expect(find.text(_en.deckSchedulerChangedToast), findsOneWidget);
  });

  libraryTest('a locked scheduler explains itself and cannot change', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckChangeScheduler);

    expect(find.text(_en.deckSchedulerLockedNote), findsOneWidget);
    await tester.tap(find.text(_en.deckSchedulerSm2), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      (await env.decks.findById(korean.id))!.schedulerType,
      SchedulerType.eightBox,
    );
  });

  libraryTest('Reorder from the sheet shows the drag handles', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'A');
    await env.decks.sub(korean.id, 'B');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckReorder);

    expect(find.byIcon(AppIcons.dragHandle), findsNWidgets(2));
    expect(find.text(_en.libraryReorderDone), findsOneWidget);
  });

  libraryTest('the action sheet meets the target guidelines', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _openSheet(tester);

    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_action_sheet_test.dart`
Expected: FAIL. No widget carries the "Deck actions" tooltip.

- [ ] **Step 3: Implement**

The four overlays share this sheet header, the same one phase 1's sort and filter sheets use. Each file writes it out itself:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.card,
    AppSpacing.micro,
    AppSpacing.card,
    AppSpacing.grouped,
  ),
  child: Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: context.textStyles.compactTitle,
  ),
)
```

`lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// What the deck action sheet can start (spec §6.2).
enum DeckAction { rename, move, changeScheduler, reorder, delete }

/// The open deck's commands. It completes with the chosen one, which the
/// screen then opens, or with null when dismissed.
Future<DeckAction?> showDeckActionSheet(
  BuildContext context, {
  required DeckView view,
  required bool canReorder,
}) => showMxBottomSheet<DeckAction>(
  context,
  builder: (_) => DeckActionSheetWidget(view: view, canReorder: canReorder),
);

class DeckActionSheetWidget extends StatelessWidget {
  const DeckActionSheetWidget({
    super.key,
    required this.view,
    required this.canReorder,
  });

  final DeckView view;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deck = view.deck;
    void choose(DeckAction action) => Navigator.of(context).pop(action);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          deck.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.compactTitle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: l10n.deckRename,
              onTap: () => choose(DeckAction.rename),
            ),
            // Ruling P2-L8: a root cannot move, and only a root has a
            // scheduler.
            if (!deck.isRoot)
              MxActionSheetCommandRow(
                icon: AppIcons.folder,
                label: l10n.deckMove,
                hasChevron: true,
                onTap: () => choose(DeckAction.move),
              ),
            if (deck.isRoot)
              MxActionSheetCommandRow(
                icon: AppIcons.scheduler,
                label: l10n.deckChangeScheduler,
                subtitle: l10n.schedulerType(view.schedulerType),
                hasChevron: true,
                onTap: () => choose(DeckAction.changeScheduler),
              ),
            if (canReorder)
              MxActionSheetCommandRow(
                icon: AppIcons.reorder,
                label: l10n.deckReorder,
                onTap: () => choose(DeckAction.reorder),
              ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.deckDelete,
              isDestructive: true,
              onTap: () => choose(DeckAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before [deck] and everything below it are deleted for good.
Future<void> showDeleteDeckDialog(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxDialog<void>(
  context,
  builder: (_) => DeckDeleteDialogWidget(deck: deck),
);

/// The body states how many sub-decks and cards go with the deck
/// (BR-DECK-023). The confirm waits for that count and is destructive.
class DeckDeleteDialogWidget extends ConsumerStatefulWidget {
  const DeckDeleteDialogWidget({super.key, required this.deck});

  final DeckEntity deck;

  @override
  ConsumerState<DeckDeleteDialogWidget> createState() =>
      _DeckDeleteDialogWidgetState();
}

class _DeckDeleteDialogWidgetState
    extends ConsumerState<DeckDeleteDialogWidget> {
  var _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .deleteDeck(deckId: widget.deck.id);
      if (!mounted) return;
      if (outcome case Rejected(:final reason)) {
        showMxSnackbar(context, message: context.l10n.deckRejection(reason));
      }
      // On Ok the open deck's screen says "Deck deleted" and steps back
      // (ruling P2-L7).
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(deckDeletionSummaryProvider(widget.deck.id));
    final body = switch (summary) {
      AsyncData(value: Ok(:final value)) => l10n.deckDeleteSummary(
        value.subDeckCount,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.deckRejection(reason),
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    final canDelete = summary.value is Ok && !_isDeleting;
    return MxDialog(
      title: l10n.deckDeleteTitle(widget.deck.name),
      body: body,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckDelete,
        isDestructive: true,
        onConfirm: canDelete ? _delete : null,
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_move_targets_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Picks the deck [deck] moves under (UC-DECK-005).
Future<void> showMoveDeckSheet(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => DeckMoveSheetWidget(deck: deck),
);

/// The backend already leaves out every deck that cannot take this one
/// (spec §6.2), so each candidate is enabled and named by its path (ruling
/// P2-L8).
class DeckMoveSheetWidget extends ConsumerStatefulWidget {
  const DeckMoveSheetWidget({super.key, required this.deck});

  final DeckEntity deck;

  @override
  ConsumerState<DeckMoveSheetWidget> createState() =>
      _DeckMoveSheetWidgetState();
}

class _DeckMoveSheetWidgetState extends ConsumerState<DeckMoveSheetWidget> {
  static const int _skeletonRows = 3;

  /// One move at a time: a second tap before the first lands does nothing.
  var _isMoving = false;

  Future<void> _move(DeckMoveTarget target) async {
    if (_isMoving) return;
    setState(() => _isMoving = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .moveDeck(deckId: widget.deck.id, newParentId: target.id);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.deckMovedToast(target.name),
          Rejected(:final reason) => l10n.deckRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isMoving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = deckMoveTargetsProvider(widget.deck.id);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: l10n.deckMoveTitle,
        rule: l10n.deckMoveRule,
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: deckPathLabel([
                for (final entry in target.path) entry.name,
                target.name,
              ]),
              isEnabled: !_isMoving,
              onTap: () => unawaited(_move(target)),
            ),
        ],
        // Ruling O11: OK, not Cancel, when there is nowhere to go.
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(),
        emptyTitle: l10n.deckMoveEmptyTitle,
        emptyBody: l10n.deckMoveEmptyBody,
      ),
      AsyncError() => MxBottomSheet(
        child: MxErrorState(
          title: l10n.libraryLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
        ),
      ),
      _ => MxBottomSheet(
        child: Column(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}
```

`lib/features/deck/presentation/widgets/overlays/deck_scheduler_sheet_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A root deck's scheduler (UC-DECK-002, spec §6.2).
Future<void> showDeckSchedulerSheet(
  BuildContext context, {
  required DeckView view,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => DeckSchedulerSheetWidget(view: view),
);

/// While unlocked, a warning says what a change resets (BR-STUDY-016). Once
/// locked, a note explains why and no option can be chosen. Reset learning
/// is out of scope.
class DeckSchedulerSheetWidget extends ConsumerStatefulWidget {
  const DeckSchedulerSheetWidget({super.key, required this.view});

  final DeckView view;

  @override
  ConsumerState<DeckSchedulerSheetWidget> createState() =>
      _DeckSchedulerSheetWidgetState();
}

class _DeckSchedulerSheetWidgetState
    extends ConsumerState<DeckSchedulerSheetWidget> {
  var _isSaving = false;

  Future<void> _choose(SchedulerType type) async {
    if (type == widget.view.schedulerType) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .changeScheduler(
            rootDeckId: widget.view.deck.id,
            schedulerType: type,
          );
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.deckSchedulerChangedToast,
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final isLocked = view.isSchedulerLocked;
    const types = SchedulerType.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.deckSchedulerTitle,
          style: context.textStyles.compactTitle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              0,
              AppSpacing.card,
              AppSpacing.grouped,
            ),
            child: isLocked
                ? MxNote(text: l10n.deckSchedulerLockedNote)
                : MxInlineBanner(
                    tone: MxBannerTone.warning,
                    message: l10n.deckSchedulerChangeWarning,
                  ),
          ),
          for (final (index, type) in types.indexed)
            MxOptionRow(
              title: l10n.schedulerType(type),
              isSelected: type == view.schedulerType,
              onSelected: isLocked || _isSaving
                  ? null
                  : () => unawaited(_choose(type)),
              hasDivider: index < types.length - 1,
            ),
        ],
      ),
    );
  }
}
```

In `lib/features/deck/presentation/screens/deck_level_screen.dart`, import the four overlay files and `deck_reorder_mode_state.dart` (already imported), then change `_OpenDeckContent`.

1. Add this method to the class:

```dart
  /// Opens the chosen command's own dialog or sheet (spec §6.2).
  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref, {
    required bool canReorder,
  }) async {
    final action = await showDeckActionSheet(
      context,
      view: view,
      canReorder: canReorder,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case DeckAction.rename:
        await showRenameDeckDialog(context, deck: view.deck);
      case DeckAction.move:
        await showMoveDeckSheet(context, deck: view.deck);
      case DeckAction.changeScheduler:
        await showDeckSchedulerSheet(context, view: view);
      case DeckAction.reorder:
        ref.read(deckReorderModeProvider(view.deck.id).notifier).start();
      case DeckAction.delete:
        await showDeleteDeckDialog(context, deck: view.deck);
    }
  }
```

2. In `build`, add `final canReorder = ref.watch(deckLevelCanReorderProvider(deck.id));` next to `isReordering`, and replace the app bar `actions:` with:

```dart
        actions: isReordering
            ? [_ReorderDone(parentId: deck.id)]
            : [
                MxIconButton(
                  icon: AppIcons.more,
                  semanticLabel: l10n.deckActions,
                  onPressed: () => unawaited(
                    _openActions(context, ref, canReorder: canReorder),
                  ),
                ),
              ],
```

- [ ] **Step 4: Run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation
```

Expected: PASS, with 11 new action sheet tests.

- If `watchMoveTargets` also offers the deck's current parent ("Korean" for Grammar), the Move tests still pass, because they tap "Korean › Words". Leave the offer as the backend gives it, and record the finding for the final review (spec §12: no backend change).
- If `MxErrorState` inside `MxBottomSheet` overflows at 2x, wrap it in `SingleChildScrollView` and record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): the deck action sheet: rename, move, scheduler, reorder, delete

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Deck search

**Files:**
- Create: `lib/features/deck/presentation/screens/deck_search_screen.dart`, `lib/features/deck/presentation/widgets/sections/deck_search_results_widget.dart`
- Test: `test/features/deck/presentation/deck_search_screen_test.dart`

**Interfaces:**
- Consumes (Task 1): `deckSearchProvider(String term)`, `deckPathLabel`.
- Produces: `DeckSearchScreen({required ValueChanged<String> onOpenDeck})`.

- [ ] **Step 1: Write the failing tests**

`test/features/deck/presentation/deck_search_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

DeckSearchScreen _screen({ValueChanged<String>? onOpenDeck}) =>
    DeckSearchScreen(onOpenDeck: onOpenDeck ?? (_) {});

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
  await tester.pump();
}

void main() {
  libraryTest('a blank term shows nothing', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, '   ');

    expect(find.byType(MxListRow), findsNothing);
    expect(find.byType(MxEmptyState), findsNothing);
  });

  libraryTest('a term finds decks at any depth, each under its path', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'or');

    expect(find.widgetWithText(MxListRow, 'Korean'), findsNWidgets(2));
    expect(find.widgetWithText(MxListRow, 'Words'), findsOneWidget);
    expect(find.text('Kanji'), findsNothing);
  });

  libraryTest('case folds, Vietnamese diacritics included', (
    tester,
    env,
  ) async {
    await env.decks.root('Tiếng Việt');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'TIẾNG');

    expect(find.text('Tiếng Việt'), findsOneWidget);
  });

  libraryTest('no hit names the term (ruling P2-L9)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _type(tester, 'zzz');

    expect(find.text(_en.deckSearchEmptyTitle('zzz')), findsOneWidget);
  });

  libraryTest('a result opens its deck', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final opened = <String>[];
    await pumpLibraryScreen(tester, env, _screen(onOpenDeck: opened.add));
    await _type(tester, 'words');
    await tester.tap(find.text('Words'));

    expect(opened, [words.id]);
  });

  libraryTest('results meet the target guidelines at 2x', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Từ vựng tiếng Hàn rất dài để thử cỡ chữ');
    await pumpLibraryScreen(tester, env, _screen(), textScale: 2);
    await _type(tester, 'từ');

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

In the second test, "Korean" matches twice: once as the root's title and once as the path under "Words".

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_search_screen_test.dart`
Expected: FAIL to compile, because `deck_search_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/widgets/sections/deck_search_results_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/presentation/providers/deck_search_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The decks whose name holds [term], each under its path so two decks of
/// one name tell apart (IT-DISC-006).
class DeckSearchResultsWidget extends ConsumerWidget {
  const DeckSearchResultsWidget({
    super.key,
    required this.term,
    required this.onOpenDeck,
  });

  final String term;
  final ValueChanged<String> onOpenDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A blank term searches nothing (IT-DISC-007), so nothing shows.
    if (term.trim().isEmpty) return const SizedBox.shrink();
    final provider = deckSearchProvider(term);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) when value.isEmpty => MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.search,
            title: l10n.deckSearchEmptyTitle(term.trim()),
            body: l10n.deckSearchEmptyBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
      AsyncData(:final value) => MxScreenScroll(
        children: [
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in value.indexed)
                  MxListRow(
                    title: hit.name,
                    subtitle: hit.path.isEmpty
                        ? null
                        : deckPathLabel([
                            for (final entry in hit.path) entry.name,
                          ]),
                    leading: const MxIconTile(icon: AppIcons.library),
                    hasChevron: true,
                    onTap: () => onOpenDeck(hit.id),
                    hasDivider: index < value.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
      AsyncError() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.libraryLoadErrorTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(provider),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
```

`lib/features/deck/presentation/screens/deck_search_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_search_results_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Finds a deck anywhere in the library by name (spec §6.3, ruling P2-L9).
/// Navigation arrives as a callback (spec §4).
class DeckSearchScreen extends StatefulWidget {
  const DeckSearchScreen({super.key, required this.onOpenDeck});

  final ValueChanged<String> onOpenDeck;

  @override
  State<DeckSearchScreen> createState() => _DeckSearchScreenState();
}

class _DeckSearchScreenState extends State<DeckSearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  var _term = '';

  @override
  void initState() {
    super.initState();
    // The person came here to type.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.deckSearchTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.control,
              AppSpacing.gutter,
              AppSpacing.grouped,
            ),
            child: MxSearchField(
              controller: _query,
              focusNode: _focus,
              hintText: l10n.deckSearchHint,
              clearLabel: l10n.deckSearchClear,
              onChanged: (term) => setState(() => _term = term),
            ),
          ),
          Expanded(
            child: DeckSearchResultsWidget(
              term: _term,
              onOpenDeck: widget.onOpenDeck,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/deck/presentation
```

Expected: PASS, with 6 new search tests.

- If `enterText` does not reach `MxSearchField.onChanged` (the field listens to its controller), add a `tester.testTextInput.enterText` fallback and record a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): search decks by name

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Library routes, router tests and the phase 2 goldens

**Files:**
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`, `test/support/library_harness.dart`
- Create: `test/app/library_routes_test.dart`, `test/features/deck/presentation/deck_screens_golden_test.dart` and its 12 goldens

**Interfaces:**
- Consumes: `DeckLevelScreen` (Task 2), `DeckSearchScreen` (Task 5), and the overlays (Task 4).
- Produces: `AppRoutes.deckChild`, `searchChild`, `deckIdParam`, `deckSearch` and `deck(String id)`, plus `pumpMemoxApp(WidgetTester, LibraryEnv)` in the harness.

- [ ] **Step 1: Write the failing tests**

Add to `test/support/library_harness.dart` (import `package:memox/app/app.dart`):

```dart
/// The whole app over [env] on a 1080×2400 (3x) phone, settled on the
/// Library root.
Future<void> pumpMemoxApp(WidgetTester tester, LibraryEnv env) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: _backend(env), child: const MemoxApp()),
  );
  await tester.pumpAndSettle();
}
```

`test/app/library_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Finder _crumb(String label) =>
    find.descendant(of: find.byType(MxBreadcrumb), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) =>
    _tap(tester, find.byTooltip(_en.commonBack));

/// Korean › Words › Verbs, with Grammar beside Words.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Grammar');
  await env.decks.sub(words.id, 'Verbs');
}

Future<void> _openVerbs(WidgetTester tester) async {
  await _tap(tester, find.text('Korean'));
  await _tap(tester, find.text('Words'));
  await _tap(tester, find.text('Verbs'));
}

void main() {
  libraryTest('each level is one page; Back climbs one level', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    expect(_barTitle('Verbs'), findsOneWidget);

    for (final level in ['Words', 'Korean', _en.navLibrary]) {
      await _back(tester);
      expect(_barTitle(level), findsOneWidget);
    }
  });

  libraryTest('a crumb pops back to its level (ruling P2-L5)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await _tap(tester, _crumb('Korean'));

    expect(_barTitle('Korean'), findsOneWidget);
    await _back(tester);
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('the Library crumb returns to the root', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await _tap(tester, _crumb(_en.navLibrary));

    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(find.byTooltip(_en.commonBack), findsNothing);
  });

  libraryTest('from search, a crumb off the stack opens over the root', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.byTooltip(_en.libraryOpenSearch));
    await tester.enterText(find.byType(EditableText), 'verb');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Verbs'));
    expect(_barTitle('Verbs'), findsOneWidget);

    await _tap(tester, _crumb('Korean'));
    expect(_barTitle('Korean'), findsOneWidget);
    await _back(tester);
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('deleting the open deck returns to its parent once (RF1)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await _tap(tester, find.byTooltip(_en.deckActions));
    await _tap(tester, find.text(_en.deckDelete));
    await _tap(tester, find.text(_en.deckDelete));

    expect(_barTitle('Words'), findsOneWidget);
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
  });

  libraryTest('moving the open deck updates its path at once (RF5)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Grammar'));
    await _tap(tester, find.byTooltip(_en.deckActions));
    await _tap(tester, find.text(_en.deckMove));
    await _tap(tester, find.text('Korean › Words'));

    expect(_crumb('Words'), findsOneWidget);
    await _back(tester);
    expect(_barTitle('Korean'), findsOneWidget);
    expect(find.text('Grammar'), findsNothing);
  });

  libraryTest('re-tapping the Library tab returns to the root', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navLibrary),
      ),
    );

    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });
}
```

`test/features/deck/presentation/deck_screens_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › {Words (3 overdue, 1 today, 1 new), Grammar}; Words › Verbs.
Future<({String korean, String words})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Grammar');
  final verbs = await env.decks.sub(words.id, 'Verbs');
  for (var i = 0; i < 3; i++) {
    await insertCard(
      env.db,
      id: 'late$i',
      deckId: verbs.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
  }
  await insertCard(
    env.db,
    id: 'today',
    deckId: verbs.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(env.db, id: 'new', deckId: verbs.id);
  return (korean: korean.id, words: words.id);
}

Future<void> _settleOverlay(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('open deck, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.korean),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_open_$theme.png',
        );
      });
    });

    libraryTest('empty deck, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean');
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: korean.id),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_unset_$theme.png',
        );
      });
    });

    libraryTest('reorder mode, $theme', (tester, env) async {
      for (final name in ['Korean', 'Kanji N5', 'Hanja']) {
        await env.decks.root(name);
      }
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        await tester.tap(find.byTooltip(_en.libraryReorder));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_reorder_$theme.png',
        );
      });
    });

    libraryTest('deck actions, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.words),
          brightness,
        );
        await tester.tap(find.byTooltip(_en.deckActions));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_actions_$theme.png',
        );
      });
    });

    libraryTest('delete dialog, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.words),
          brightness,
        );
        await tester.tap(find.byTooltip(_en.deckActions));
        await _settleOverlay(tester);
        await tester.tap(find.text(_en.deckDelete));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_delete_$theme.png',
        );
      });
    });

    libraryTest('search results, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          DeckSearchScreen(onOpenDeck: (_) {}),
          brightness,
        );
        await tester.enterText(find.byType(EditableText), 'or');
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_search_$theme.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Run the router tests to verify they fail**

Run: `flutter test test/app/library_routes_test.dart`
Expected: FAIL, because a row tap does nothing (Task 2's stub builder).

- [ ] **Step 3: Implement**

`lib/app/router/app_routes.dart`: add inside `AppRoutes`:

```dart
  /// The path parameter that names an open deck.
  static const String deckIdParam = 'deckId';

  /// The Library's child routes (library spec §4), relative to [decks].
  static const String deckChild = 'deck/:$deckIdParam';
  static const String searchChild = 'search';

  static const String deckSearch = '$decks/$searchChild';

  /// An open deck's location.
  static String deck(String deckId) => '$decks/deck/$deckId';
```

`lib/app/router/app_router.dart`: import `deck_search_screen.dart`. Replace the Library branch with:

```dart
        // The Library (library spec §4): one page per deck level.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.decks,
              builder: (context, state) => _deckLevel(context),
              routes: [
                GoRoute(
                  path: AppRoutes.deckChild,
                  builder: (context, state) => _deckLevel(
                    context,
                    deckId: state.pathParameters[AppRoutes.deckIdParam],
                  ),
                ),
                GoRoute(
                  path: AppRoutes.searchChild,
                  builder: (context, state) => DeckSearchScreen(
                    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                  ),
                ),
              ],
            ),
          ],
        ),
```

and add below `buildAppRouter`:

```dart
/// A Library level wired to the router: each deck opened is one more page,
/// so Back climbs one level (library spec §4).
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) =>
    DeckLevelScreen(
      deckId: deckId,
      onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
      onOpenAncestor: (id) => _openAncestor(context, id),
      onSearch: () => context.push(AppRoutes.deckSearch),
    );

/// Ruling P2-L5: a breadcrumb tap pops the Library stack back to [deckId],
/// or to the root for null. A deck that is not on the stack (it was opened
/// from search) is pushed over the root instead.
void _openAncestor(BuildContext context, String? deckId) {
  final router = GoRouter.of(context);
  var isOnStack = false;
  Navigator.of(context).popUntil((route) {
    final arguments = route.settings.arguments;
    isOnStack =
        deckId != null &&
        arguments is Map &&
        arguments[AppRoutes.deckIdParam] == deckId;
    return isOnStack || route.isFirst;
  });
  if (deckId == null || isOnStack) return;
  unawaited(router.push(AppRoutes.deck(deckId)));
}
```

Add `import 'dart:async';`. go_router gives each page `arguments: {...pathParameters, ...queryParameters}` (`go_router/lib/src/builder.dart`), and that map is what `_openAncestor` reads.

- If the router test shows that `route.settings.arguments` does not carry the deck id, give the deck `GoRoute` a `pageBuilder` that returns `MaterialPage<void>(key: state.pageKey, arguments: state.pathParameters, child: …)`, and record a ruling.
- If `popUntil` leaves go_router's match list out of step (a later push lands on a wrong stack), pop one page at a time with `router.pop()` while `router.canPop()` and the top page is not the target, and record a ruling.

- [ ] **Step 4: Run the tests and make the goldens**

```bash
flutter test test/app
flutter test --update-goldens --tags golden test/features/deck/presentation/deck_screens_golden_test.dart
flutter test --tags golden test/features/deck/presentation test/app
```

Expected: `test/app` passes with 7 new route tests, and the goldens pass on the second run. Delete any `failures/` folder.

Open the light goldens and check:
- `library_deck_open`: the content bar with Back, "Korean" and the overflow. The breadcrumb reads "Library › Korean". The level line reads "3 overdue · 1 today · 1 new", then DECKS with its chips, and the Words and Grammar rows with chevrons. The FAB is present.
- `library_deck_unset`: the empty card reads "This deck is empty" with "Create sub-deck".
- `library_reorder`: three rows with drag handles and no chevrons. The bar shows Done, and there is no FAB and no chip.
- `library_deck_actions`: a sheet titled "Words" with Rename, Move › and a red Delete. There is no Reorder, since Words has one sub-deck.
- `library_deck_delete`: "Delete “Words”?", with the body counting 1 sub-deck and 5 cards and a destructive Delete.
- `library_search`: the field reads "or". Korean has no path line, and Words reads "Korean".

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(app): Library routes for deck levels and deck search

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Register, full gate, hand back

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9)

- [ ] **Step 1: Record the phase in the debt register**

Append after row 70 of UI-base spec §9:

```markdown
| 71 | A deck that holds cards shows an empty body, and the empty-deck state and the FAB offer no "Add card", until the card list (phase 3) and the editor (phase 4) arrive | library phase 2 P2-L1 |
| 72 | The Library root reorders from an app bar action; the library spec names Reorder only in an open deck's overflow | library phase 2 P2-L2 |
| 73 | After the open deck moves, the back stack keeps its old parents: Back returns to a level that no longer lists it | library phase 2 review focus 5 |
| 74 | Deck search always covers the whole library; a search scoped to one deck is not offered | library phase 2 P2-L9 |
```

- [ ] **Step 2: Full gate**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
GUARD_PY=python bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- Every command exits 0, and the guard reports 0 errors and 0 warnings.
- `GUARD_PY=python` is needed on the dev machine, whose `python3.13` lacks `typer` and `pytest` (phase 1 finding).

- [ ] **Step 3: Scope check and commit**

```bash
git add docs/superpowers
git commit -m "docs(spec): record Library phase 2 in the UI debt register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected: the diff lists only:
- `docs/superpowers/`
- `lib/core/theme/foundations/app_icons.dart`
- `lib/l10n/`
- `lib/features/deck/presentation/`
- `lib/app/router/`
- `test/`

No file under `lib/features/*/domain`, `data` or `di`, and none under `lib/core/database`.

Report to the user in Vietnamese:
- Counts and results.
- Every execution ruling.
- The phase 2 goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR, merge it, and continue to phase 3.
