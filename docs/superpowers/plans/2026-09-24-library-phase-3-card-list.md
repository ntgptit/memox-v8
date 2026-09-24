# Library Phase 3: Card List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A deck that holds cards shows them, and they can be browsed and managed in bulk (M2, M4):
- browse by searching, by four filters with counts and by two sorts, in a list that grows as it scrolls;
- in selection mode, select all, flag or unflag, add a tag, move and delete.

**Architecture:** The `card` feature gains its first presentation layer:
- use-case providers, a `cardListProvider` stream family keyed by primitives, per-deck request and selection state, and a `CardActionsController`;
- a `CardListSectionWidget(deckId)`. `DeckLevelScreen` takes a `cardContent` builder, and `app/router` passes the card section into it (spec D8: `deck` never imports `card`).

Selection chrome lives inside the section. Bulk writes go through one overlay each. Each overlay shows its own snackbars and reports success back, and the section then clears the selection.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18, Drift 2.35 (in-memory for tests), gen-l10n (en/vi).

**Spec:** `docs/superpowers/specs/2026-09-24-library-screens-design.md`: §3 structure, §4 composition, §5 data flow, §6.4 card list section, §9 verification, §10 row 3. Scenarios IT-ORG-013 and IT-ORG-014 are in `docs/features/card/it-scenarios.md`. The phase 2 plan is `docs/superpowers/plans/2026-09-24-library-phase-2-deck-tree.md`.

## Global Constraints

- **UI only.** No file under `lib/features/*/domain`, `lib/features/*/data`, `lib/features/*/di` or `lib/core/database` changes (spec §12). A backend gap is a finding, not a patch.
- **Import map** (`test/architecture/boundary_rules.dart`): `card → {deck, srs, tags}`, `deck → {srs}`.
  - `card/presentation` may import `deck/domain/{entities,models,repositories,failures}`, `tags/domain/…` and `tags/di`, and never `deck/presentation`.
  - `deck` never imports `card`. `app/` composes them.
- **One use case per interaction** through one provider in `presentation/providers/` (AD-12). A controller method returns the use case's result, and the widget chooses the feedback (spec §5).
- **Feedback** (spec §5, IT-ORG-014):
  - A rejection about a form field shows under the field; any other rejection shows in a snackbar.
  - `Ok` closes the overlay.
  - A database `Failure` shows `l10n.failure(failure)` in a snackbar.
  - A refused bulk action writes nothing and **keeps the selection**.
  - A successful one clears it, and its snackbar names the count.
- **Selection** (BR-CARD-020, IT-ORG-013):
  - A long-press enters selection mode with that card. While selecting, a tap only toggles.
  - Deselecting the last card leaves selection mode.
  - Select all takes the whole filtered set, not just the loaded window (BR-CARD-012).
  - Changing the filter or the search clears the selection.
  - System Back while selecting leaves selection first.
- **Flag** sets or clears explicitly, never toggles (BR-CARD-011).
- **Riverpod family keys:** `CardListQuery` has no `==`, so a provider family never takes it as an argument. Pass `filter`, `sort`, `searchTerm` and `windowSize` as primitives.
- **ADR-011 layout and suffixes.** Guard memox-v8 must stay 0 errors / 0 warnings:
  - no raw `IconButton`, `ListTile`, `Checkbox` or `Card`, and no `Icon(color:)`;
  - no `ref.read` lexically inside `build()`;
  - no defaulted provider or notifier parameter;
  - in the ARB, `placeholders` comes before `description`.
- **Copy** lives in `app_en.arb` (with `@key` metadata) and `app_vi.arb` (flat). Run `flutter gen-l10n` after ARB edits, and `dart run build_runner build --delete-conflicting-outputs` after `@riverpod` edits.
- **Tests** run through the real backend (`libraryTest`, `pumpLibraryScreen`, `openTestDatabase`, `insertCard`). A fake repository wrapped in the real use case is allowed only for failure paths.
- **Phones only.** Each surface passes `expectAccessibleTargets` and renders at text scale 2. Goldens are light and dark at 3x.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings (phase 3)

| # | Ruling |
|---|---|
| P3-L1 | The spec puts the selected count and the close action in the app bar. The app bar belongs to `DeckLevelScreen` (deck feature), which may not import `card` (D8), so the section pins its own selection header (close and "N selected") above its scroll. The deck app bar stays. |
| P3-L2 | The backend has no read for the tags a set of cards carries, and `RemoveTagFromCardsUseCase` needs a tag id. So the bulk Tag action adds one tag by name. Removing a tag waits for a backend read (finding, debt row). |
| P3-L3 | A tap on a card row opens the card detail in phase 4. Until then a tap outside selection does nothing and the rows carry no chevron. The empty deck state carries no "Add card" until the editor exists (phase 4). |
| P3-L4 | Flag opens a two-command sheet, "Flag cards" and "Remove flag", so the choice is explicit (BR-CARD-011). |
| P3-L5 | The list keeps its last rows while a new window, filter or term loads, so growth and typing never flash skeletons. The window starts at 50 cards and grows by 50 when the scroll comes within 600 px of its end while `hasMore`. |
| P3-L6 | The rows sit in one `MxCard` built from the current window, not a lazy sliver list. The window caps the row count; a sliver list waits until windows reach thousands. |
| P3-L7 | The bulk bar is the handoff's "5-up icon grid" in an `MxFooterBar`: Select all, Flag, Tag, Move and Delete in equal columns. |
| P3-L8 | Card move targets are labelled by their path. The card feature has its own path join (`cardDeckPathLabel`), since it may not import `deck/presentation`. |
| P3-L9 | The bulk tag input is a dialog, not a sheet, because `MxBottomSheet` does not pad for the keyboard yet (UI-base §9 row 64). |

## Review Focus

1. **Select all with a filter and a search active, over more cards than the window.**
   - Expected: the count equals the whole filtered set, not the loaded rows.
   - Pinned in Task 3.
2. **A bulk tag refused for one card of the selection (it already has 10 tags).**
   - Expected: nothing is written, the reason shows, and the selection stays.
   - Pinned in Task 4.
3. **Midnight while the list is open.**
   - Expected: the Due count and the Due filter take in the cards that fell due, with no write.
   - Pinned in Task 2.
4. **Scrolling to the end of a long deck.**
   - Expected: the window grows, the loaded rows stay on screen (no skeleton), and the new rows follow.
   - Pinned in Task 2.
5. **System Back while selecting.**
   - Expected: it leaves selection and stays on the deck; a second Back leaves the deck.
   - Pinned in Tasks 3 and 5.

## File Map

```
lib/core/theme/foundations/app_icons.dart                 modify: flag, flagged, selectAll
lib/l10n/app_en.arb, app_vi.arb                           modify: card copy
lib/features/card/presentation/
  providers/  7 use-case providers, card_list_provider.dart, card_move_targets_provider.dart
  states/     card_list_request_state.dart, card_selection_state.dart
  controllers/card_actions_controller.dart
  widgets/sections/ card_list_section_widget.dart, card_list_toolbar_widget.dart,
                    card_selection_header_widget.dart, card_bulk_bar_widget.dart
  widgets/items/    card_row_widget.dart
  widgets/overlays/ card_sort_sheet_widget.dart, card_flag_sheet_widget.dart,
                    card_tag_sheet_widget.dart, card_move_sheet_widget.dart,
                    card_delete_dialog_widget.dart
  widgets/support/  card_rejection_message_widget.dart, tag_rejection_message_widget.dart,
                    card_list_labels_widget.dart, card_deck_path_label_widget.dart
lib/features/deck/presentation/screens/deck_level_screen.dart   modify: cardContent slot
lib/app/router/app_router.dart                            modify: pass the card section
test/support/library_harness.dart                         modify: deckScreen(cardContent)
test/features/card/presentation/*                         tests and goldens
test/app/library_routes_test.dart                         extend
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md  §9 rows 75–78
```

---
### Task 1: Card plumbing: providers, controller, request and selection state, labels and copy

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create in `lib/features/card/presentation/`:
  - `providers/`: 7 use-case providers, `card_list_provider.dart`, `card_move_targets_provider.dart`
  - `states/card_list_request_state.dart`, `states/card_selection_state.dart`
  - `controllers/card_actions_controller.dart`
  - `widgets/support/card_rejection_message_widget.dart`, `tag_rejection_message_widget.dart`, `card_list_labels_widget.dart`, `card_deck_path_label_widget.dart`
- Test: `test/features/card/presentation/card_actions_controller_test.dart`, `card_messages_test.dart`, `card_list_state_test.dart`

**Interfaces:**
- Produces:
  - `cardListProvider({required String deckId, required CardListFilter filter, required CardListSort sort, required String searchTerm, required int windowSize})`: `Stream<CardListView>`.
  - `cardMoveTargetsProvider(String sourceDeckId)`: `Stream<List<CardMoveTarget>>`.
  - `cardListRequestProvider(String deckId)`: `CardListRequestState` with fields `filter`, `sort`, `searchTerm`, `windowSize` and the getter `query`. Notifier methods: `show(CardListFilter)`, `sortBy(CardListSort)`, `search(String)`, `grow()`. The constant is `cardListWindowStep = 50`.
  - `cardSelectionProvider(String deckId)`: `Set<String>`. Notifier methods: `toggle(String)`, `selectAll(Set<String>)`, `clear()`.
  - `CardActionsController`:
    - `selectAll({required String deckId, required CardListQuery query})` → `Future<Set<String>>`;
    - `setFlagged({required Set<String> cardIds, required bool isFlagged})` → `Future<Outcome<void, CardRejection>>`;
    - `addTag({required Set<String> cardIds, required String tagName})` → `Future<Outcome<void, TagRejection>>`;
    - `moveCards({required Set<String> cardIds, required String targetDeckId})` → `Future<Outcome<void, CardRejection>>`;
    - `deleteCards({required Set<String> cardIds})` → `Future<Outcome<void, CardRejection>>`.
  - Labels, as extensions on `AppLocalizations`: `cardRejection(CardRejection)`, `tagRejection(TagRejection)`, `cardFilter(CardListFilter)`, `cardSort(CardListSort)`, `cardStatus(CardDisplayStatus)`.
  - Helpers: `MxCardStatus mxCardStatus(CardDisplayStatus)`, the extension `CardListCounts.of(CardListFilter)`, and `cardDeckPathLabel(Iterable<String>)`.
  - Icons: `AppIcons.flag`, `AppIcons.flagged`, `AppIcons.selectAll`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_actions_controller_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CardActionsController actions() =>
      container.read(cardActionsControllerProvider.notifier);

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('n');

  /// Korean › Words with cards a, b (flagged) and c; Korean › Verbs with d.
  Future<({String words, String verbs})> seed() async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final verbs = await decks.sub(korean.id, 'Verbs');
    await insertCard(db, id: 'a', deckId: words.id);
    await insertCard(db, id: 'b', deckId: words.id, isFlagged: true);
    await insertCard(db, id: 'c', deckId: words.id);
    await insertCard(db, id: 'd', deckId: verbs.id);
    return (words: words.id, verbs: verbs.id);
  }

  test('selectAll takes every card the query lets through', () async {
    final ids = await seed();

    expect(
      await actions().selectAll(
        deckId: ids.words,
        query: const CardListQuery(filter: CardListFilter.flagged),
      ),
      {'b'},
    );
    expect(
      await actions().selectAll(
        deckId: ids.words,
        query: const CardListQuery(),
      ),
      {'a', 'b', 'c'},
    );
  });

  test('setFlagged sets the flag on every card given', () async {
    await seed();
    await actions().setFlagged(cardIds: {'a', 'c'}, isFlagged: true);

    expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 3);
  });

  test('addTag tags every card given', () async {
    await seed();
    final outcome = await actions().addTag(
      cardIds: {'a', 'b'},
      tagName: 'verbs',
    );

    expect(outcome, isA<Ok<Object?, TagRejection>>());
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 2);
  });

  test('moveCards puts the cards in the target deck', () async {
    final ids = await seed();
    await actions().moveCards(cardIds: {'a', 'b'}, targetDeckId: ids.verbs);

    expect(
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?',
                variables: [Variable<String>(ids.verbs)],
              )
              .getSingle())
          .read<int>('n'),
      3,
    );
  });

  test('deleteCards deletes every card given', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a', 'c'});

    expect(await count('SELECT COUNT(*) AS n FROM card'), 2);
  });
}
```

`test/features/card/presentation/card_messages_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_deck_path_label_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/tag_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

final _technical = RegExp(
  r'sql|sqlite|exception|/|\\|null|[0-9a-f]{8}-',
  caseSensitive: false,
);

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);
    final code = locale.languageCode;

    test('every card and tag rejection has plain $code copy', () {
      for (final reason in CardRejection.values) {
        final copy = l10n.cardRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
      for (final reason in TagRejection.values) {
        final copy = l10n.tagRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
    });

    test('every filter, sort and status has $code copy', () {
      for (final filter in CardListFilter.values) {
        expect(l10n.cardFilter(filter).trim(), isNotEmpty);
      }
      for (final sort in CardListSort.values) {
        expect(l10n.cardSort(sort).trim(), isNotEmpty);
      }
      for (final status in CardDisplayStatus.values) {
        expect(l10n.cardStatus(status).trim(), isNotEmpty);
      }
    });
  }

  test('each display status has its badge colour', () {
    expect(CardDisplayStatus.values.map(mxCardStatus), [
      MxCardStatus.newCard,
      MxCardStatus.learning,
      MxCardStatus.reviewing,
      MxCardStatus.mastered,
    ]);
  });

  test('a card target reads root first', () {
    expect(cardDeckPathLabel(['Korean', 'Verbs']), 'Korean › Verbs');
  });
}
```

`test/features/card/presentation/card_list_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';

void main() {
  test('a request starts with every card, newest first, one window', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = container.read(cardListRequestProvider('d'));

    expect(
      (request.filter, request.sort, request.searchTerm, request.windowSize),
      (CardListFilter.all, CardListSort.newest, '', cardListWindowStep),
    );
  });

  test('growing adds a window; a new filter or term starts again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = cardListRequestProvider('d');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);
    final notifier = container.read(provider.notifier);

    notifier.grow();
    expect(container.read(provider).windowSize, 2 * cardListWindowStep);
    notifier.show(CardListFilter.due);
    expect(container.read(provider).windowSize, cardListWindowStep);
    notifier
      ..grow()
      ..search('kor');
    expect(container.read(provider).windowSize, cardListWindowStep);
    expect(container.read(provider).query.searchTerm, 'kor');
    expect(container.read(provider).query.filter, CardListFilter.due);
  });

  test('a selection toggles, takes a whole set, and clears', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = cardSelectionProvider('d');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);
    final notifier = container.read(provider.notifier);

    notifier
      ..toggle('a')
      ..toggle('b')
      ..toggle('a');
    expect(container.read(provider), {'b'});
    notifier.selectAll({'a', 'b', 'c'});
    expect(container.read(provider), {'a', 'b', 'c'});
    notifier.clear();
    expect(container.read(provider), isEmpty);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation`
Expected: FAIL to compile. `card_actions_controller.dart` and the state files do not exist.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_icons.dart`: add after `scheduler`:

```dart
  static const IconData flag = Icons.outlined_flag; // flag
  static const IconData flagged = Icons.flag; // flag (filled)
  static const IconData selectAll = Icons.select_all; // check-square
```

**Use-case providers** go in `lib/features/card/presentation/providers/`, one file each, shaped like `lib/features/deck/presentation/providers/create_root_deck_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/<use_case_file>.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '<provider_file>.g.dart';

@riverpod
<UseCase> <useCaseName>(Ref ref) => <UseCase>(<dependencies>);
```

| Provider file | Function | Body |
|---|---|---|
| `watch_card_list_use_case_provider.dart` | `watchCardListUseCase` | `WatchCardListUseCase(ref.watch(cardRepositoryProvider), ref.watch(dayClockProvider))` |
| `select_all_card_ids_use_case_provider.dart` | `selectAllCardIdsUseCase` | `SelectAllCardIdsUseCase(ref.watch(cardRepositoryProvider), ref.watch(dayClockProvider))` |
| `set_cards_flagged_use_case_provider.dart` | `setCardsFlaggedUseCase` | `SetCardsFlaggedUseCase(ref.watch(cardRepositoryProvider))` |
| `move_cards_use_case_provider.dart` | `moveCardsUseCase` | `MoveCardsUseCase(ref.watch(cardRepositoryProvider))` |
| `delete_cards_use_case_provider.dart` | `deleteCardsUseCase` | `DeleteCardsUseCase(ref.watch(cardRepositoryProvider))` |
| `watch_card_move_targets_use_case_provider.dart` | `watchCardMoveTargetsUseCase` | `WatchCardMoveTargetsUseCase(ref.watch(cardRepositoryProvider))` |
| `add_tag_to_cards_use_case_provider.dart` | `addTagToCardsUseCase` | `AddTagToCardsUseCase(ref.watch(tagRepositoryProvider))` |

Import notes:
- `dayClockProvider` comes from `package:memox/core/clock/di/day_clock_provider.dart`.
- `tagRepositoryProvider` comes from `package:memox/features/tags/di/tag_repository_provider.dart`; the tag provider imports that instead of the card repository provider.
- The use case files are `lib/features/card/domain/usecases/<snake>_use_case.dart`.

`lib/features/card/presentation/providers/card_list_provider.dart`:

```dart
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_list_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_provider.g.dart';

/// A window of [deckId]'s cards and the filter counts (UC-CARD-001), again
/// on every change and at each local midnight. The query arrives as
/// primitives: `CardListQuery` has no `==`, and a family key needs one.
@riverpod
Stream<CardListView> cardList(
  Ref ref, {
  required String deckId,
  required CardListFilter filter,
  required CardListSort sort,
  required String searchTerm,
  required int windowSize,
}) => ref.watch(watchCardListUseCaseProvider)(
  deckId: deckId,
  query: CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm),
  windowSize: windowSize,
);
```

`lib/features/card/presentation/providers/card_move_targets_provider.dart`:

```dart
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_move_targets_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_move_targets_provider.g.dart';

/// The decks cards of [sourceDeckId] may move to (UC-CARD-001 A5).
@riverpod
Stream<List<CardMoveTarget>> cardMoveTargets(Ref ref, String sourceDeckId) =>
    ref.watch(watchCardMoveTargetsUseCaseProvider)(sourceDeckId: sourceDeckId);
```

`lib/features/card/presentation/states/card_list_request_state.dart`:

```dart
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_request_state.g.dart';

/// The cards the list asks for first, and how many more each growth adds
/// (ruling P3-L5).
const int cardListWindowStep = 50;

/// What the person asked a deck's card list for, and how far it has grown.
final class CardListRequestState {
  const CardListRequestState({
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm = '',
    this.windowSize = cardListWindowStep,
  });

  final CardListFilter filter;
  final CardListSort sort;
  final String searchTerm;
  final int windowSize;

  /// The query the list, its counts and Select all share (BR-CARD-012).
  CardListQuery get query =>
      CardListQuery(filter: filter, sort: sort, searchTerm: searchTerm);
}

/// A deck's card list request, kept while its screen lives. A new filter,
/// sort or term starts again from the first window.
@riverpod
class CardListRequest extends _$CardListRequest {
  @override
  CardListRequestState build(String deckId) => const CardListRequestState();

  void show(CardListFilter filter) => state = CardListRequestState(
    filter: filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
  );

  void sortBy(CardListSort sort) => state = CardListRequestState(
    filter: state.filter,
    sort: sort,
    searchTerm: state.searchTerm,
  );

  void search(String term) => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: term,
  );

  /// The list neared its end while more cards follow.
  void grow() => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    windowSize: state.windowSize + cardListWindowStep,
  );
}
```

`lib/features/card/presentation/states/card_selection_state.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_selection_state.g.dart';

/// The cards picked in a deck's selection mode (BR-CARD-020). Empty means
/// the list is not selecting.
@riverpod
class CardSelection extends _$CardSelection {
  @override
  Set<String> build(String deckId) => const {};

  void toggle(String cardId) => state = state.contains(cardId)
      ? ({...state}..remove(cardId))
      : {...state, cardId};

  void selectAll(Set<String> cardIds) => state = {...cardIds};

  void clear() => state = const {};
}
```

`lib/features/card/presentation/controllers/card_actions_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/providers/add_tag_to_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/delete_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/select_all_card_ids_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_actions_controller.g.dart';

/// The card list's bulk commands (UC-CARD-001 A5–A8).
///
/// Each command calls exactly one use case (AD-12) and hands back its result;
/// the widget chooses the feedback. A database `Failure` is thrown through.
@riverpod
class CardActionsController extends _$CardActionsController {
  @override
  void build() {}

  /// Every card [query] lets through, not only the loaded rows (BR-CARD-012).
  Future<Set<String>> selectAll({
    required String deckId,
    required CardListQuery query,
  }) => ref.read(selectAllCardIdsUseCaseProvider)(deckId: deckId, query: query);

  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
  }) => ref.read(setCardsFlaggedUseCaseProvider)(
    cardIds: cardIds,
    isFlagged: isFlagged,
  );

  Future<Outcome<void, TagRejection>> addTag({
    required Set<String> cardIds,
    required String tagName,
  }) => ref.read(addTagToCardsUseCaseProvider)(
    cardIds: cardIds,
    tagName: tagName,
  );

  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
  }) => ref.read(moveCardsUseCaseProvider)(
    cardIds: cardIds,
    targetDeckId: targetDeckId,
  );

  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) => ref.read(deleteCardsUseCaseProvider)(cardIds: cardIds);
}
```

`lib/features/card/presentation/widgets/support/card_rejection_message_widget.dart`:

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason the card feature refuses a write (spec §5).
extension CardRejectionMessage on AppLocalizations {
  String cardRejection(CardRejection reason) => switch (reason) {
    CardRejection.blankContent => cardRejectionBlankContent,
    CardRejection.notACardContainer => cardRejectionNotACardContainer,
    CardRejection.notFound => cardRejectionNotFound,
    CardRejection.frontTooLong => cardRejectionFrontTooLong,
    CardRejection.backTooLong => cardRejectionBackTooLong,
    CardRejection.optionalFieldTooLong => cardRejectionOptionalFieldTooLong,
    CardRejection.invalidTagName => cardRejectionInvalidTagName,
    CardRejection.tooManyTags => cardRejectionTooManyTags,
    CardRejection.targetNotFound => cardRejectionTargetNotFound,
    CardRejection.targetIsRoot => cardRejectionTargetIsRoot,
    CardRejection.targetHoldsDecks => cardRejectionTargetHoldsDecks,
    CardRejection.sameDeck => cardRejectionSameDeck,
    CardRejection.crossRootMove => cardRejectionCrossRootMove,
  };
}
```

`lib/features/card/presentation/widgets/support/tag_rejection_message_widget.dart`:

```dart
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason a tag write is refused (spec §5).
extension TagRejectionMessage on AppLocalizations {
  String tagRejection(TagRejection reason) => switch (reason) {
    TagRejection.blankName => tagRejectionBlankName,
    TagRejection.nameTooLong => tagRejectionNameTooLong,
    TagRejection.controlCharacter => tagRejectionControlCharacter,
    TagRejection.tooManyTags => tagRejectionTooManyTags,
    TagRejection.notFound => tagRejectionNotFound,
  };
}
```

`lib/features/card/presentation/widgets/support/card_list_labels_widget.dart`:

```dart
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// Names of the card list's filters, sorts and statuses.
extension CardListLabel on AppLocalizations {
  String cardFilter(CardListFilter filter) => switch (filter) {
    CardListFilter.all => cardFilterAll,
    CardListFilter.due => cardFilterDue,
    CardListFilter.newCards => cardFilterNew,
    CardListFilter.flagged => cardFilterFlagged,
  };

  String cardSort(CardListSort sort) => switch (sort) {
    CardListSort.newest => cardSortNewest,
    CardListSort.dueFirst => cardSortDueFirst,
  };

  String cardStatus(CardDisplayStatus status) => switch (status) {
    CardDisplayStatus.newCard => cardStatusNew,
    CardDisplayStatus.beginning => cardStatusBeginning,
    CardDisplayStatus.reviewing => cardStatusReviewing,
    CardDisplayStatus.mastered => cardStatusMastered,
  };
}

/// The badge colour of each display status (BR-CARD-006).
MxCardStatus mxCardStatus(CardDisplayStatus status) => switch (status) {
  CardDisplayStatus.newCard => MxCardStatus.newCard,
  CardDisplayStatus.beginning => MxCardStatus.learning,
  CardDisplayStatus.reviewing => MxCardStatus.reviewing,
  CardDisplayStatus.mastered => MxCardStatus.mastered,
};

/// The count a filter chip shows (IT-ORG-005).
extension CardListCountOf on CardListCounts {
  int of(CardListFilter filter) => switch (filter) {
    CardListFilter.all => all,
    CardListFilter.due => due,
    CardListFilter.newCards => newCards,
    CardListFilter.flagged => flagged,
  };
}
```

`lib/features/card/presentation/widgets/support/card_deck_path_label_widget.dart`:

```dart
/// Between two decks of a path. The deck feature has its own join; the card
/// feature may not import `deck/presentation` (ruling P3-L8).
const String cardDeckPathSeparator = ' › ';

/// A deck path read root first.
String cardDeckPathLabel(Iterable<String> names) =>
    names.join(cardDeckPathSeparator);
```

**Copy.** Save and run this script as in phase 2 (`python <workspace>/add_arb.py`), then run `flutter gen-l10n`:

```python
import json
from pathlib import Path

INT = {"type": "int"}
STRING = {"type": "String"}

KEYS = {
    "cardSearchHint": ("Search cards", "Tìm thẻ", "Hint in the card list search field.", None),
    "cardSearchClear": ("Clear search", "Xoá nội dung tìm", "Accessible name of the card search clear button.", None),
    "cardFilterAll": ("All", "Tất cả", "Card filter chip: every card.", None),
    "cardFilterDue": ("Due", "Đến hạn", "Card filter chip: learned cards due now.", None),
    "cardFilterNew": ("New", "Mới", "Card filter chip: cards not learned yet.", None),
    "cardFilterFlagged": ("Flagged", "Đã gắn cờ", "Card filter chip: flagged cards.", None),
    "cardSortTitle": ("Sort cards", "Sắp xếp thẻ", "Title of the card sort sheet.", None),
    "cardSortTrigger": ("Sort: {order}", "Sắp xếp: {order}", "Card sort chip; order is the current sort.", {"order": STRING}),
    "cardSortNewest": ("Newest", "Mới thêm", "Card sort: newest first.", None),
    "cardSortDueFirst": ("Due first", "Đến hạn trước", "Card sort: soonest due first.", None),
    "cardStatusNew": ("New", "Mới", "Card status: not learned yet.", None),
    "cardStatusBeginning": ("Learning", "Đang học", "Card status: early in its schedule.", None),
    "cardStatusReviewing": ("Reviewing", "Đang ôn", "Card status: in regular review.", None),
    "cardStatusMastered": ("Mastered", "Đã thuộc", "Card status: mastered.", None),
    "cardFlagged": ("Flagged", "Đã gắn cờ", "Accessible name of a card row's flag glyph.", None),
    "cardEmptyTitle": ("No cards yet", "Chưa có thẻ", "Card list empty state title.", None),
    "cardEmptyBody": ("The cards you add to this deck show here.", "Các thẻ bạn thêm vào bộ này sẽ hiện ở đây.", "Card list empty state body.", None),
    "cardFilterEmptyTitle": ("No cards under “{filter}”", "Không có thẻ nào trong “{filter}”", "Card list empty under a filter; filter is its name.", {"filter": STRING}),
    "cardShowAll": ("Show all cards", "Hiện mọi thẻ", "Action that clears the card filter.", None),
    "cardSearchEmptyTitle": ("No card matches “{term}”", "Không có thẻ nào khớp “{term}”", "Card search with no hit; term is what was typed.", {"term": STRING}),
    "cardLoadErrorTitle": ("Couldn't load the cards", "Không tải được thẻ", "Card list error state title.", None),
    "cardSelectedCount": ("{count, plural, =1{1 selected} other{{count} selected}}", "Đã chọn {count}", "Selection header: how many cards are selected.", {"count": INT}),
    "cardSelectionClose": ("Close selection", "Đóng chế độ chọn", "Accessible name of the selection close action.", None),
    "cardSelectAll": ("Select all", "Chọn tất cả", "Bulk bar action.", None),
    "cardFlag": ("Flag", "Gắn cờ", "Bulk bar action.", None),
    "cardTag": ("Tag", "Nhãn", "Bulk bar action.", None),
    "cardMove": ("Move", "Di chuyển", "Bulk bar action.", None),
    "cardDelete": ("Delete", "Xoá", "Bulk bar action and delete confirm.", None),
    "cardFlagSet": ("Flag cards", "Gắn cờ các thẻ", "Flag sheet command that sets the flag.", None),
    "cardFlagClear": ("Remove flag", "Bỏ cờ", "Flag sheet command that clears the flag.", None),
    "cardFlaggedToast": ("{count, plural, =1{1 card flagged} other{{count} cards flagged}}", "Đã gắn cờ {count} thẻ", "Snackbar after flagging.", {"count": INT}),
    "cardUnflaggedToast": ("{count, plural, =1{Flag removed from 1 card} other{Flag removed from {count} cards}}", "Đã bỏ cờ {count} thẻ", "Snackbar after clearing flags.", {"count": INT}),
    "cardTagTitle": ("Add a tag", "Thêm nhãn", "Title of the bulk tag sheet.", None),
    "cardTagHint": ("Tag name", "Tên nhãn", "Hint in the tag name field.", None),
    "cardTagConfirm": ("Add", "Thêm", "Confirm of the tag sheet.", None),
    "cardTaggedToast": ("{count, plural, =1{1 card tagged “{tag}”} other{{count} cards tagged “{tag}”}}", "Đã gắn nhãn “{tag}” cho {count} thẻ", "Snackbar after tagging.", {"count": INT, "tag": STRING}),
    "cardMoveTitle": ("Move to deck", "Chuyển vào bộ thẻ", "Title of the card move picker.", None),
    "cardMoveRule": ("Cards keep their learning. Only decks that hold cards in this top-level deck are offered.", "Thẻ giữ nguyên tiến độ học. Chỉ những bộ thẻ chứa thẻ trong cùng bộ thẻ cấp cao nhất mới hiện ra.", "One sentence under the card move picker title.", None),
    "cardMoveEmptyTitle": ("Nowhere to move", "Không có nơi để chuyển", "Card move picker title with no target.", None),
    "cardMoveEmptyBody": ("No other deck here can hold cards.", "Không có bộ thẻ nào khác ở đây chứa được thẻ.", "Card move picker body with no target.", None),
    "cardMovedToast": ("{count, plural, =1{1 card moved to {deck}} other{{count} cards moved to {deck}}}", "Đã chuyển {count} thẻ vào {deck}", "Snackbar after a move; deck is the target's name.", {"count": INT, "deck": STRING}),
    "cardDeleteTitle": ("{count, plural, =1{Delete 1 card?} other{Delete {count} cards?}}", "Xoá {count} thẻ?", "Delete dialog title.", {"count": INT}),
    "cardDeleteBody": ("The cards and their learning history are deleted for good. This can't be undone.", "Các thẻ và lịch sử học của chúng sẽ bị xoá vĩnh viễn. Không thể hoàn tác.", "Delete dialog body.", None),
    "cardDeletedToast": ("{count, plural, =1{1 card deleted} other{{count} cards deleted}}", "Đã xoá {count} thẻ", "Snackbar after a delete.", {"count": INT}),
    "cardRejectionBlankContent": ("Enter both the front and the back.", "Hãy nhập cả mặt trước và mặt sau.", "Card refusal: blank content.", None),
    "cardRejectionNotACardContainer": ("This deck holds decks, so it can't hold cards.", "Bộ thẻ này chứa bộ thẻ con nên không chứa thẻ.", "Card refusal: the deck holds decks.", None),
    "cardRejectionNotFound": ("This card no longer exists.", "Thẻ này không còn nữa.", "Card refusal: the card is gone.", None),
    "cardRejectionFrontTooLong": ("Keep the front to 60 characters.", "Mặt trước tối đa 60 ký tự.", "Card refusal: front too long.", None),
    "cardRejectionBackTooLong": ("Keep the back to 240 characters.", "Mặt sau tối đa 240 ký tự.", "Card refusal: back too long.", None),
    "cardRejectionOptionalFieldTooLong": ("Keep it to 240 characters.", "Tối đa 240 ký tự.", "Card refusal: example, hint or pronunciation too long.", None),
    "cardRejectionInvalidTagName": ("That tag name can't be used.", "Không dùng được tên nhãn này.", "Card refusal: invalid tag name.", None),
    "cardRejectionTooManyTags": ("A card holds 10 tags at most.", "Mỗi thẻ có tối đa 10 nhãn.", "Card refusal: too many tags.", None),
    "cardRejectionTargetNotFound": ("That deck no longer exists.", "Bộ thẻ đó không còn nữa.", "Card move refusal: the target is gone.", None),
    "cardRejectionTargetIsRoot": ("A top-level deck can't hold cards.", "Bộ thẻ cấp cao nhất không chứa thẻ.", "Card move refusal: the target is a root.", None),
    "cardRejectionTargetHoldsDecks": ("That deck holds decks, so it can't hold cards.", "Bộ thẻ đó chứa bộ thẻ con nên không chứa thẻ.", "Card move refusal: the target holds decks.", None),
    "cardRejectionSameDeck": ("The cards are already there.", "Các thẻ đã ở đó rồi.", "Card move refusal: same deck.", None),
    "cardRejectionCrossRootMove": ("Cards can only move within the same top-level deck.", "Thẻ chỉ di chuyển được trong cùng một bộ thẻ cấp cao nhất.", "Card move refusal: another root.", None),
    "tagRejectionBlankName": ("Enter a tag name.", "Hãy nhập tên nhãn.", "Tag refusal: blank name.", None),
    "tagRejectionNameTooLong": ("Keep the tag to 50 characters.", "Nhãn tối đa 50 ký tự.", "Tag refusal: name too long.", None),
    "tagRejectionControlCharacter": ("A tag can't hold that character.", "Nhãn không được chứa ký tự đó.", "Tag refusal: control character.", None),
    "tagRejectionTooManyTags": ("A card holds 10 tags at most.", "Mỗi thẻ có tối đa 10 nhãn.", "Tag refusal: a card would pass 10 tags.", None),
    "tagRejectionNotFound": ("A card or tag no longer exists.", "Một thẻ hoặc nhãn không còn nữa.", "Tag refusal: a card or tag is gone.", None),
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

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation
```

Expected: PASS: 5 controller tests, 6 message tests and 3 state tests.

- If `check_architecture.py` or `test/architecture` rejects a `test/` import of `deck/data` or `tags/domain`, use the `LibraryEnv(db, …).decks` fixture instead and record a ruling.
- If the `vi` message of a plural key fails `flutter gen-l10n`, give it the plural form `{count, plural, other{…}}` and record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): card list plumbing: providers, bulk commands, request and selection state, copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The card list section, composed into the deck screen

**Files:**
- Create in `lib/features/card/presentation/widgets/`: `sections/card_list_section_widget.dart`, `sections/card_list_toolbar_widget.dart`, `items/card_row_widget.dart`, `overlays/card_sort_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`, `lib/app/router/app_router.dart`, `test/support/library_harness.dart`, `test/app/library_routes_test.dart`
- Test: `test/features/card/presentation/card_list_section_test.dart`

**Interfaces:**
- Consumes (Task 1): `cardListProvider`, `cardListRequestProvider`, `CardListCountOf.of`, `cardFilter` / `cardSort` / `cardStatus`, `mxCardStatus`, `AppIcons.flagged`.
- Produces:
  - `CardListSectionWidget({required String deckId})`.
  - `CardRowWidget({required CardListItem item, required bool isSelecting, required bool isSelected, VoidCallback? onTap, VoidCallback? onLongPress, bool hasDivider})`.
  - `CardListToolbarWidget(...)`.
  - `showCardSortSheet(BuildContext, {required CardListSort selected, required ValueChanged<CardListSort> onSelected})`.
  - `DeckLevelScreen` gains `required Widget Function(String deckId) cardContent`.
  - The harness function `deckScreen` gains `cardContent` (default: an empty box).

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_list_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) =>
    Scaffold(body: CardListSectionWidget(deckId: deckId));

/// Korean › Words: annyeong (new), gamsa (due today), sarang (due
/// tomorrow) and mul (new, flagged).
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(
    env.db,
    id: 'new1',
    deckId: words.id,
    front: 'annyeong',
    back: 'hello',
  );
  await insertCard(
    env.db,
    id: 'due1',
    deckId: words.id,
    front: 'gamsa',
    back: 'thanks',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(
    env.db,
    id: 'later',
    deckId: words.id,
    front: 'sarang',
    back: 'love',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 25),
  );
  await insertCard(
    env.db,
    id: 'flag1',
    deckId: words.id,
    front: 'mul',
    back: 'water',
    isFlagged: true,
  );
  return words.id;
}

int? _chipCount(WidgetTester tester, String label) =>
    tester.widget<MxFilterChip>(find.widgetWithText(MxFilterChip, label)).count;

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(MxFilterChip, label));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('rows show front, back, a status dot and the flag', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));

    expect(find.text('annyeong'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(CardRowWidget), findsNWidgets(4));
    expect(find.byType(MxStatusBadge), findsNWidgets(4));
    expect(find.byIcon(AppIcons.flagged), findsOneWidget);
  });

  libraryTest('each chip counts its filter; a chip filters the rows', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));

    expect(
      [
        for (final label in [
          _en.cardFilterAll,
          _en.cardFilterDue,
          _en.cardFilterNew,
          _en.cardFilterFlagged,
        ])
          _chipCount(tester, label),
      ],
      [4, 1, 2, 1],
    );
    await _tapChip(tester, _en.cardFilterFlagged);

    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(find.text('mul'), findsOneWidget);
  });

  libraryTest('search matches the front or the back', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'thank');
    await tester.pumpAndSettle();

    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(find.text('gamsa'), findsOneWidget);
  });

  libraryTest('due first puts the soonest due first and new cards last', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.tap(find.text(_en.cardSortTrigger(_en.cardSortNewest)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardSortDueFirst));
    await tester.pumpAndSettle();

    double top(String front) => tester.getTopLeft(find.text(front)).dy;
    expect(top('gamsa'), lessThan(top('sarang')));
    expect(top('sarang'), lessThan(top('annyeong')));
  });

  libraryTest('midnight brings the next day\'s card into Due (RF3)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    env.clock.startDay(DateTime(2026, 9, 25));
    await tester.pump();
    await tester.pump();

    expect(_chipCount(tester, _en.cardFilterDue), 2);
  });

  libraryTest('an empty filter names itself and offers every card', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpLibraryScreen(tester, env, _section(words.id));
    await _tapChip(tester, _en.cardFilterFlagged);

    expect(
      find.text(_en.cardFilterEmptyTitle(_en.cardFilterFlagged)),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.cardShowAll));
    await tester.pumpAndSettle();
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('a search with no hit names the term', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSearchEmptyTitle('zzz')), findsOneWidget);
  });

  libraryTest('the window grows near the end and keeps its rows (RF4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    for (var i = 0; i < 60; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: words.id,
        front: 'card $i',
      );
    }
    await pumpLibraryScreen(tester, env, _section(words.id));
    expect(find.byType(CardRowWidget), findsNWidgets(cardListWindowStep));

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump();
    expect(find.byType(MxSkeletonRow), findsNothing);
    expect(
      find.byType(CardRowWidget),
      findsAtLeastNWidgets(cardListWindowStep),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CardRowWidget), findsNWidgets(60));
  });

  libraryTest('a load error says so plainly and offers Retry', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(deckId),
      overrides: [
        cardListProvider(
          deckId: deckId,
          filter: CardListFilter.all,
          sort: CardListSort.newest,
          searchTerm: '',
          windowSize: cardListWindowStep,
        ).overrideWith(
          (ref) => Stream<CardListView>.error(StateError('disk I/O error')),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('disk'), findsNothing);
  });

  libraryTest('long cards at 2x meet the target guidelines', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'long',
      deckId: words.id,
      front: List.filled(6, '한국어 단어').join(' '),
      back: List.filled(20, 'nghĩa tiếng Việt').join(' '),
      isFlagged: true,
    );
    await pumpLibraryScreen(tester, env, _section(words.id), textScale: 2);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

Append to `test/app/library_routes_test.dart` (add `import '../support/card_fixtures.dart';`):

```dart
  libraryTest('a deck of cards lists its cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));

    expect(find.text('annyeong'), findsOneWidget);
  });
```

(Place it inside `main()`, after the last test.)

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_list_section_test.dart`
Expected: FAIL to compile, because `card_list_section_widget.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/items/card_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// One card of the list (spec §6.4): its front and back on one line each, a
/// status dot, and the flag when set. A long-press selects it (BR-CARD-020).
class CardRowWidget extends StatelessWidget {
  const CardRowWidget({
    super.key,
    required this.item,
    required this.isSelecting,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.hasDivider = true,
  });

  final CardListItem item;
  final bool isSelecting;
  final bool isSelected;

  /// Toggles the card while selecting. Ruling P3-L3: outside selection the
  /// detail arrives in phase 4.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = MxListRow(
      title: item.front,
      subtitle: item.back,
      leading: isSelecting ? MxSelectionCheckbox(isChecked: isSelected) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          if (item.isFlagged)
            Icon(
              AppIcons.flagged,
              size: AppIconSize.inline,
              semanticLabel: l10n.cardFlagged,
            ),
          MxStatusBadge(
            status: mxCardStatus(item.displayStatus),
            label: l10n.cardStatus(item.displayStatus),
            isDot: true,
          ),
        ],
      ),
      onTap: onTap,
      hasDivider: hasDivider,
    );
    // The row carries the checked state; the box is only painted (ruling I6).
    return Semantics(
      checked: isSelecting ? isSelected : null,
      child: GestureDetector(onLongPress: onLongPress, child: row),
    );
  }
}
```

`lib/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Picks the card list's order (IT-ORG-003). The chosen option closes the
/// sheet.
Future<void> showCardSortSheet(
  BuildContext context, {
  required CardListSort selected,
  required ValueChanged<CardListSort> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => CardSortSheetWidget(
    selected: selected,
    onSelected: (sort) {
      onSelected(sort);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class CardSortSheetWidget extends StatelessWidget {
  const CardSortSheetWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CardListSort selected;
  final ValueChanged<CardListSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const sorts = CardListSort.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(l10n.cardSortTitle, style: context.textStyles.compactTitle),
      ),
      child: Column(
        children: [
          for (final (index, sort) in sorts.indexed)
            MxOptionRow(
              title: l10n.cardSort(sort),
              isSelected: sort == selected,
              onSelected: () => onSelected(sort),
              hasDivider: index < sorts.length - 1,
            ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Search within the deck, the four filters with their counts, and the
/// sort (spec §6.4).
class CardListToolbarWidget extends StatelessWidget {
  const CardListToolbarWidget({
    super.key,
    required this.searchController,
    required this.request,
    required this.counts,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
  });

  final TextEditingController searchController;
  final CardListRequestState request;
  final CardListCounts counts;
  final ValueChanged<String> onSearch;
  final ValueChanged<CardListFilter> onFilter;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.control),
        MxSearchField(
          controller: searchController,
          hintText: l10n.cardSearchHint,
          clearLabel: l10n.cardSearchClear,
          onChanged: onSearch,
        ),
        const SizedBox(height: AppSpacing.grouped),
        // The chips never shrink or wrap, so their row scrolls.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: AppSpacing.control,
            children: [
              for (final filter in CardListFilter.values)
                MxFilterChip(
                  label: l10n.cardFilter(filter),
                  count: counts.of(filter),
                  isSelected: filter == request.filter,
                  onSelected: (_) => onFilter(filter),
                ),
              MxChipTrigger(
                label: l10n.cardSortTrigger(l10n.cardSort(request.sort)),
                icon: AppIcons.sort,
                onPressed: onSort,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
      ],
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A deck's cards (spec §6.4): search, the filters with their counts, a
/// sort, and the rows of a window that grows as the list nears its end.
class CardListSectionWidget extends ConsumerStatefulWidget {
  const CardListSectionWidget({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<CardListSectionWidget> createState() =>
      _CardListSectionWidgetState();
}

class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
  static const int _skeletonRows = 4;

  /// How close to the end of the scroll a larger window is asked for.
  static const double _growWithin = 600;

  final _query = TextEditingController();

  /// Ruling P3-L5: the rows stay while a new window, filter or term loads.
  CardListView? _lastView;

  /// The window a growth was asked from, so one end of list asks once.
  int? _grownFrom;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  CardListRequest _request() =>
      ref.read(cardListRequestProvider(widget.deckId).notifier);

  void _growFrom(int windowSize) {
    if (_grownFrom == windowSize) return;
    _grownFrom = windowSize;
    _request().grow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = ref.watch(cardListRequestProvider(widget.deckId));
    final provider = cardListProvider(
      deckId: widget.deckId,
      filter: request.filter,
      sort: request.sort,
      searchTerm: request.searchTerm,
      windowSize: request.windowSize,
    );
    final async = ref.watch(provider);
    final view = _lastView = async.value ?? _lastView;
    if (view == null) {
      return MxScreenScroll(
        children: [
          if (async.hasError)
            MxErrorState(
              title: l10n.cardLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            )
          else
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      );
    }
    // A larger window is asked for only once the current one has loaded.
    final canGrow = async.hasValue && view.hasMore;
    final items = view.items;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (canGrow &&
            notification.depth == 0 &&
            notification.metrics.extentAfter < _growWithin) {
          _growFrom(request.windowSize);
        }
        return false;
      },
      child: MxScreenScroll(
        children: [
          CardListToolbarWidget(
            searchController: _query,
            request: request,
            counts: view.counts,
            onSearch: (term) => _request().search(term),
            onFilter: (filter) => _request().show(filter),
            onSort: () => unawaited(
              showCardSortSheet(
                context,
                selected: request.sort,
                onSelected: (sort) => _request().sortBy(sort),
              ),
            ),
          ),
          if (items.isEmpty)
            _CardListEmpty(
              request: request,
              onShowAll: () => _request().show(CardListFilter.all),
            )
          else
            // Ruling P3-L6: one card over the current window.
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  for (final (index, item) in items.indexed)
                    CardRowWidget(
                      item: item,
                      isSelecting: false,
                      isSelected: false,
                      hasDivider: index < items.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Why no row shows: a search, a filter, or an empty deck.
class _CardListEmpty extends StatelessWidget {
  const _CardListEmpty({required this.request, required this.onShowAll});

  final CardListRequestState request;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final term = request.searchTerm.trim();
    if (term.isNotEmpty) {
      return MxEmptyState(
        icon: AppIcons.search,
        title: l10n.cardSearchEmptyTitle(term),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      );
    }
    if (request.filter != CardListFilter.all) {
      return MxEmptyState(
        icon: AppIcons.filter,
        title: l10n.cardFilterEmptyTitle(l10n.cardFilter(request.filter)),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
        actionLabel: l10n.cardShowAll,
        onAction: onShowAll,
      );
    }
    // Ruling P3-L3: "Add card" arrives with the editor in phase 4.
    return MxEmptyState(
      icon: AppIcons.inbox,
      title: l10n.cardEmptyTitle,
      body: l10n.cardEmptyBody,
    );
  }
}
```

**Composition (spec D8).** In `lib/features/deck/presentation/screens/deck_level_screen.dart`:

1. `DeckLevelScreen` gains a field, plus `required this.cardContent` in its constructor, and passes `cardContent: cardContent` to `_OpenDeck`:

   ```dart
     /// What a deck of cards shows. The router passes the card feature's list
     /// section; `deck` never imports `card` (spec D8).
     final Widget Function(String deckId) cardContent;
   ```

2. `_OpenDeck` gains `required this.cardContent` (`final Widget Function(String deckId) cardContent;`) and passes it to `_OpenDeckContent`.
3. `_OpenDeckContent` gains the same field, and its card branch becomes `DeckContentType.card => cardContent(deck.id),`. Delete the "Ruling P2-L1" comment above that branch.

In `test/support/library_harness.dart`, give `deckScreen` the parameter `Widget Function(String deckId)? cardContent`, and pass `cardContent: cardContent ?? (_) => const SizedBox.shrink(),`.

In `lib/app/router/app_router.dart`, import `package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart`, and add this line to `_deckLevel`'s `DeckLevelScreen(...)`:

```dart
      cardContent: (deckId) => CardListSectionWidget(deckId: deckId),
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation test/features/deck/presentation test/app
```

Expected: PASS: 10 new section tests and 1 new route test. The deck tests still pass through `deckScreen`.

- If the growth test sees rows still at 50 after the drag, drag with `tester.fling(find.byType(ListView), const Offset(0, -6000), 3000)` and pump once more. Record a test-only ruling.
- If `Semantics(checked: null)` warns in this Flutter version, pass `checked: isSelecting && isSelected` only while selecting, by wrapping the `GestureDetector` in `Semantics` only when `isSelecting`. Record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card list section inside a deck of cards

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Selection mode

**Files:**
- Create in `lib/features/card/presentation/widgets/sections/`: `card_selection_header_widget.dart`, `card_bulk_bar_widget.dart`
- Rewrite: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Test: `test/features/card/presentation/card_selection_test.dart`

**Interfaces:**
- Consumes (Task 1): `cardSelectionProvider`, `CardActionsController.selectAll`, `CardListRequestState.query`, `AppIcons.selectAll`.
- Produces:
  - `CardSelectionHeaderWidget({required int count, required VoidCallback onClose})`.
  - `typedef CardBulkAction = ({IconData icon, String label, VoidCallback onTap})` and `CardBulkBarWidget({required List<CardBulkAction> actions})`.
  - In the section: the methods `_selection()` and `_selectAll(CardListQuery)`, and the `actions:` list Task 4 extends.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_selection_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) =>
    Scaffold(body: CardListSectionWidget(deckId: deckId));

/// A deck of cards whose fronts are [fronts]; the first [flagged] are
/// flagged.
Future<String> _deck(
  LibraryEnv env,
  List<String> fronts, {
  int flagged = 0,
}) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  for (final (index, front) in fronts.indexed) {
    await insertCard(
      env.db,
      id: 'c${index.toString().padLeft(2, '0')}',
      deckId: words.id,
      front: front,
      isFlagged: index < flagged,
    );
  }
  return words.id;
}

Finder _header(int count) => find.text(_en.cardSelectedCount(count));

void main() {
  libraryTest('a long-press selects that card', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(_header(1), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNWidgets(2));
    expect(
      tester.getSemantics(find.byType(CardRowWidget).last),
      containsSemantics(isChecked: true),
    );
  });

  libraryTest('a tap toggles; the last one off leaves selection', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_header(2), findsOneWidget);

    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_header(1), findsOneWidget);
    await tester.tap(find.text('annyeong'));
    await tester.pump();
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('outside selection a tap does nothing yet (ruling P3-L3)', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.tap(find.text('annyeong'));
    await tester.pump();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Select all takes the whole filtered, searched set (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, [
      for (var i = 0; i < 60; i++) 'card $i',
    ], flagged: 55);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'card');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterFlagged));
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsNWidgets(cardListWindowStep));

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardSelectAll));
    await tester.pumpAndSettle();

    expect(_header(55), findsOneWidget);
  });

  libraryTest('changing the filter clears the selection', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa'], flagged: 1);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterFlagged));
    await tester.pumpAndSettle();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('system Back leaves selection first (RF5)', (tester, env) async {
    final deckId = await _deck(env, ['annyeong']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('selection meets the target guidelines at 2x', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId), textScale: 2);
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_selection_test.dart`
Expected: FAIL. A long-press shows no "1 selected" header.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_selection_header_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Close and the selected count, pinned above the list while selecting
/// (ruling P3-L1).
class CardSelectionHeaderWidget extends StatelessWidget {
  const CardSelectionHeaderWidget({
    super.key,
    required this.count,
    required this.onClose,
  });

  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.micro,
        AppSpacing.micro,
        AppSpacing.gutter,
        AppSpacing.micro,
      ),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxIconButton(
            icon: AppIcons.close,
            semanticLabel: l10n.cardSelectionClose,
            onPressed: onClose,
          ),
          Expanded(
            // TalkBack reads the new count as it changes.
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.cardSelectedCount(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.compactTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One command of the bulk bar.
typedef CardBulkAction = ({IconData icon, String label, VoidCallback onTap});

/// The card list's bulk bar: the handoff's 5-up icon grid, one icon and
/// label per equal column (ruling P3-L7).
class CardBulkBarWidget extends StatelessWidget {
  const CardBulkBarWidget({super.key, required this.actions});

  final List<CardBulkAction> actions;

  @override
  Widget build(BuildContext context) => MxFooterBar(
    child: Row(
      children: [
        for (final action in actions)
          Expanded(child: _BulkCommand(action: action)),
      ],
    ),
  );
}

class _BulkCommand extends StatelessWidget {
  const _BulkCommand({required this.action});

  final CardBulkAction action;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      button: true,
      child: MxRowInk(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.control),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              Icon(action.icon),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textStyles.rowDescription,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (whole file):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_header_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A deck's cards (spec §6.4): search, the filters with their counts, a
/// sort, and the rows of a window that grows as the list nears its end. A
/// long-press starts selection mode, with its header and bulk bar.
class CardListSectionWidget extends ConsumerStatefulWidget {
  const CardListSectionWidget({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<CardListSectionWidget> createState() =>
      _CardListSectionWidgetState();
}

class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
  static const int _skeletonRows = 4;

  /// How close to the end of the scroll a larger window is asked for.
  static const double _growWithin = 600;

  final _query = TextEditingController();

  /// Ruling P3-L5: the rows stay while a new window, filter or term loads.
  CardListView? _lastView;

  /// The window a growth was asked from, so one end of list asks once.
  int? _grownFrom;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  CardListRequest _request() =>
      ref.read(cardListRequestProvider(widget.deckId).notifier);

  CardSelection _selection() =>
      ref.read(cardSelectionProvider(widget.deckId).notifier);

  void _growFrom(int windowSize) {
    if (_grownFrom == windowSize) return;
    _grownFrom = windowSize;
    _request().grow();
  }

  /// Other cards show, so the selection goes (IT-ORG-013).
  void _show(CardListFilter filter) {
    _request().show(filter);
    _selection().clear();
  }

  void _search(String term) {
    _request().search(term);
    _selection().clear();
  }

  /// Every card the query lets through, not only the loaded rows
  /// (BR-CARD-012).
  Future<void> _selectAll(CardListQuery query) async {
    try {
      final ids = await ref
          .read(cardActionsControllerProvider.notifier)
          .selectAll(deckId: widget.deckId, query: query);
      if (!mounted) return;
      _selection().selectAll(ids);
    } on Failure catch (failure) {
      if (!mounted) return;
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = ref.watch(cardListRequestProvider(widget.deckId));
    final selected = ref.watch(cardSelectionProvider(widget.deckId));
    final isSelecting = selected.isNotEmpty;
    final provider = cardListProvider(
      deckId: widget.deckId,
      filter: request.filter,
      sort: request.sort,
      searchTerm: request.searchTerm,
      windowSize: request.windowSize,
    );
    final async = ref.watch(provider);
    final view = _lastView = async.value ?? _lastView;
    if (view == null) {
      return MxScreenScroll(
        children: [
          if (async.hasError)
            MxErrorState(
              title: l10n.cardLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            )
          else
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      );
    }
    // A larger window is asked for only once the current one has loaded.
    final canGrow = async.hasValue && view.hasMore;
    final items = view.items;
    final list = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (canGrow &&
            notification.depth == 0 &&
            notification.metrics.extentAfter < _growWithin) {
          _growFrom(request.windowSize);
        }
        return false;
      },
      child: MxScreenScroll(
        children: [
          CardListToolbarWidget(
            searchController: _query,
            request: request,
            counts: view.counts,
            onSearch: _search,
            onFilter: _show,
            onSort: () => unawaited(
              showCardSortSheet(
                context,
                selected: request.sort,
                onSelected: (sort) => _request().sortBy(sort),
              ),
            ),
          ),
          if (items.isEmpty)
            _CardListEmpty(
              request: request,
              onShowAll: () => _show(CardListFilter.all),
            )
          else
            // Ruling P3-L6: one card over the current window.
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  for (final (index, item) in items.indexed)
                    CardRowWidget(
                      item: item,
                      isSelecting: isSelecting,
                      isSelected: selected.contains(item.id),
                      // BR-CARD-020: while selecting, a tap only toggles.
                      onTap: isSelecting
                          ? () => _selection().toggle(item.id)
                          : null,
                      onLongPress: () => _selection().toggle(item.id),
                      hasDivider: index < items.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    // Back leaves selection before it leaves the deck (IT-ORG-013).
    return PopScope(
      canPop: !isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selection().clear();
      },
      child: Column(
        children: [
          if (isSelecting)
            CardSelectionHeaderWidget(
              count: selected.length,
              onClose: () => _selection().clear(),
            ),
          Expanded(child: list),
          if (isSelecting)
            CardBulkBarWidget(
              actions: [
                (
                  icon: AppIcons.selectAll,
                  label: l10n.cardSelectAll,
                  onTap: () => unawaited(_selectAll(request.query)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Why no row shows: a search, a filter, or an empty deck.
class _CardListEmpty extends StatelessWidget {
  const _CardListEmpty({required this.request, required this.onShowAll});

  final CardListRequestState request;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final term = request.searchTerm.trim();
    if (term.isNotEmpty) {
      return MxEmptyState(
        icon: AppIcons.search,
        title: l10n.cardSearchEmptyTitle(term),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      );
    }
    if (request.filter != CardListFilter.all) {
      return MxEmptyState(
        icon: AppIcons.filter,
        title: l10n.cardFilterEmptyTitle(l10n.cardFilter(request.filter)),
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
        actionLabel: l10n.cardShowAll,
        onAction: onShowAll,
      );
    }
    // Ruling P3-L3: "Add card" arrives with the editor in phase 4.
    return MxEmptyState(
      icon: AppIcons.inbox,
      title: l10n.cardEmptyTitle,
      body: l10n.cardEmptyBody,
    );
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation
```

Expected: PASS: 7 new selection tests, with the Task 2 section tests still green.

- If `containsSemantics(isChecked: true)` does not find the flag on `CardRowWidget`'s node, assert it on `find.text('annyeong')` instead, since `MxListRow` may merge the row. Record a test-only ruling.
- If `handlePopRoute` pops the test's only route instead of reaching `PopScope`, wrap the section in a pushed route inside the test and record a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): selection mode with Select all over the whole filtered set

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Bulk flag, tag, move and delete

**Files:**
- Create in `lib/features/card/presentation/widgets/overlays/`: `card_flag_sheet_widget.dart`, `card_tag_dialog_widget.dart`, `card_move_sheet_widget.dart`, `card_delete_dialog_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Test: `test/features/card/presentation/card_bulk_actions_test.dart`

**Interfaces:**
- Consumes:
  - Task 1: `CardActionsController.setFlagged` / `addTag` / `moveCards` / `deleteCards`, `cardMoveTargetsProvider`, `cardRejection`, `tagRejection`, `cardDeckPathLabel`, `AppIcons.flag` / `flagged`.
  - Task 3: the section's `_selection()` and its `actions:` list.
- Produces:
  - `showCardFlagSheet(BuildContext)` → `Future<bool?>` (true sets the flag, false clears it).
  - `showCardTagDialog(BuildContext, {required Set<String> cardIds})` → `Future<bool>`.
  - `showCardMoveSheet(BuildContext, {required String sourceDeckId, required Set<String> cardIds})` → `Future<bool>`.
  - `showDeleteCardsDialog(BuildContext, {required Set<String> cardIds})` → `Future<bool>`.
  - Each `Future<bool>` completes true only when the write landed; its overlay has already shown the snackbar.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_bulk_actions_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) =>
    Scaffold(body: CardListSectionWidget(deckId: deckId));

/// Korean › Words: annyeong (new1), gamsa (due1), mul (flag1, flagged);
/// Korean › Verbs: gada (verb1).
Future<({String words, String verbs})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final verbs = await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'due1', deckId: words.id, front: 'gamsa');
  await insertCard(
    env.db,
    id: 'flag1',
    deckId: words.id,
    front: 'mul',
    isFlagged: true,
  );
  await insertCard(env.db, id: 'verb1', deckId: verbs.id, front: 'gada');
  return (words: words.id, verbs: verbs.id);
}

Future<int> _count(LibraryEnv env, String sql, [List<String> args = const []]) async =>
    (await env.db
            .customSelect(
              sql,
              variables: [for (final arg in args) Variable<String>(arg)],
            )
            .getSingle())
        .read<int>('n');

Future<void> _select(WidgetTester tester, List<String> fronts) async {
  await tester.longPress(find.text(fronts.first));
  await tester.pumpAndSettle();
  for (final front in fronts.skip(1)) {
    await tester.tap(find.text(front));
    await tester.pump();
  }
}

Future<void> _bulk(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

void main() {
  libraryTest('Flag sets the flag on every selected card', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagSet);

    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      3,
    );
    expect(find.text(_en.cardFlaggedToast(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Remove flag clears it, never toggles (P3-L4)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['mul', 'annyeong']);
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagClear);

    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      0,
    );
  });

  libraryTest('Tag adds one tag to every selected card', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 2);
    expect(find.text(_en.cardTaggedToast(2, 'greetings')), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('a blank tag stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);
    await _bulk(tester, _en.cardTag);
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
  });

  libraryTest('a tag refused for one card writes nothing, keeps selection (RF2)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    final tags = TagRepositoryImpl(env.db);
    for (var i = 0; i < 10; i++) {
      await tags.attachByName(cardIds: {'new1'}, name: 'tag $i');
    }
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'extra');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagRejectionTooManyTags), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 10);
    expect(find.text(_en.cardSelectedCount(2)), findsOneWidget);
  });

  libraryTest('Move sends the cards to another deck of the root', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?',
        [ids.verbs],
      ),
      3,
    );
    expect(find.text(_en.cardMovedToast(2, 'Verbs')), findsOneWidget);
  });

  libraryTest('Delete asks with the count; Cancel keeps the selection', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardDelete);

    expect(find.text(_en.cardDeleteTitle(2)), findsOneWidget);
    await tester.tap(_inDialog(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardSelectedCount(2)), findsOneWidget);

    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardDelete));
    await tester.pumpAndSettle();
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 2);
    expect(find.text(_en.cardDeletedToast(2)), findsOneWidget);
  });

  libraryTest('the bulk bar meets the target guidelines', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);

    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_bulk_actions_test.dart`
Expected: FAIL. The bulk bar has no Flag, Tag, Move or Delete.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// Ruling P3-L4: the flag is set or cleared, never toggled (BR-CARD-011).
/// Completes with true to set it, false to clear it, null when dismissed.
Future<bool?> showCardFlagSheet(BuildContext context) =>
    showMxBottomSheet<bool>(context, builder: (_) => const CardFlagSheetWidget());

class CardFlagSheetWidget extends StatelessWidget {
  const CardFlagSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.flagged,
              label: l10n.cardFlagSet,
              onTap: () => Navigator.of(context).pop(true),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.flag,
              label: l10n.cardFlagClear,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/tag_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Adds one tag, by name, to every card of [cardIds] (UC-CARD-001 A8).
/// Completes true once it landed. Ruling P3-L9: a dialog, since a sheet does
/// not yet pad for the keyboard (UI-base §9 row 64).
Future<bool> showCardTagDialog(
  BuildContext context, {
  required Set<String> cardIds,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardTagDialogWidget(cardIds: cardIds),
    ) ??
    false;

class CardTagDialogWidget extends ConsumerStatefulWidget {
  const CardTagDialogWidget({super.key, required this.cardIds});

  final Set<String> cardIds;

  @override
  ConsumerState<CardTagDialogWidget> createState() =>
      _CardTagDialogWidgetState();
}

class _CardTagDialogWidgetState extends ConsumerState<CardTagDialogWidget> {
  /// Refusals about the name itself stay under the field (spec §5).
  static const _nameReasons = {
    TagRejection.blankName,
    TagRejection.nameTooLong,
    TagRejection.controlCharacter,
  };

  final _name = TextEditingController();
  TagRejection? _rejection;
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
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .addTag(cardIds: widget.cardIds, tagName: _name.text);
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok():
          showMxSnackbar(
            context,
            message: l10n.cardTaggedToast(
              widget.cardIds.length,
              _name.text.trim(),
            ),
          );
          Navigator.of(context).pop(true);
        case Rejected(:final reason) when _nameReasons.contains(reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
        // IT-ORG-014: nothing was written; the selection stays.
        case Rejected(:final reason):
          showMxSnackbar(context, message: l10n.tagRejection(reason));
          Navigator.of(context).pop(false);
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
      title: l10n.cardTagTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          MxTextField(
            controller: _name,
            hintText: l10n.cardTagHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.tagRejection(reason),
            },
            textInputAction: TextInputAction.done,
            onSubmitted: _isSubmitting ? null : (_) => _submit(),
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardTagConfirm,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_move_targets_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_deck_path_label_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Picks the deck the cards of [cardIds] move to (UC-CARD-001 A5).
/// Completes true once the move landed.
Future<bool> showCardMoveSheet(
  BuildContext context, {
  required String sourceDeckId,
  required Set<String> cardIds,
}) async =>
    await showMxBottomSheet<bool>(
      context,
      builder: (_) =>
          CardMoveSheetWidget(sourceDeckId: sourceDeckId, cardIds: cardIds),
    ) ??
    false;

/// The backend offers only eligible decks, each named by its path (ruling
/// P3-L8).
class CardMoveSheetWidget extends ConsumerStatefulWidget {
  const CardMoveSheetWidget({
    super.key,
    required this.sourceDeckId,
    required this.cardIds,
  });

  final String sourceDeckId;
  final Set<String> cardIds;

  @override
  ConsumerState<CardMoveSheetWidget> createState() =>
      _CardMoveSheetWidgetState();
}

class _CardMoveSheetWidgetState extends ConsumerState<CardMoveSheetWidget> {
  static const int _skeletonRows = 3;

  /// One move at a time: a second tap before the first lands does nothing.
  var _isMoving = false;

  Future<void> _move(CardMoveTarget target) async {
    if (_isMoving) return;
    setState(() => _isMoving = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .moveCards(cardIds: widget.cardIds, targetDeckId: target.id);
      if (!mounted) return;
      final l10n = context.l10n;
      final hasMoved = outcome is Ok;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.cardMovedToast(widget.cardIds.length, target.name),
          Rejected(:final reason) => l10n.cardRejection(reason),
        },
      );
      Navigator.of(context).pop(hasMoved);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isMoving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = cardMoveTargetsProvider(widget.sourceDeckId);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: l10n.cardMoveTitle,
        rule: l10n.cardMoveRule,
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: cardDeckPathLabel([
                for (final entry in target.path) entry.name,
                target.name,
              ]),
              isEnabled: !_isMoving,
              onTap: () => unawaited(_move(target)),
            ),
        ],
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(false),
        emptyTitle: l10n.cardMoveEmptyTitle,
        emptyBody: l10n.cardMoveEmptyBody,
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

`lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before the cards of [cardIds] and their history are deleted for
/// good (IT-ORG-014). Completes true once they are gone.
Future<bool> showDeleteCardsDialog(
  BuildContext context, {
  required Set<String> cardIds,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDeleteDialogWidget(cardIds: cardIds),
    ) ??
    false;

class CardDeleteDialogWidget extends ConsumerStatefulWidget {
  const CardDeleteDialogWidget({super.key, required this.cardIds});

  final Set<String> cardIds;

  @override
  ConsumerState<CardDeleteDialogWidget> createState() =>
      _CardDeleteDialogWidgetState();
}

class _CardDeleteDialogWidgetState
    extends ConsumerState<CardDeleteDialogWidget> {
  var _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .deleteCards(cardIds: widget.cardIds);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.cardDeletedToast(widget.cardIds.length),
          Rejected(:final reason) => l10n.cardRejection(reason),
        },
      );
      Navigator.of(context).pop(outcome is Ok);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.cardDeleteTitle(widget.cardIds.length),
      body: l10n.cardDeleteBody,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardDelete,
        isDestructive: true,
        onConfirm: _isDeleting ? null : _delete,
      ),
    );
  }
}
```

**The section** (`card_list_section_widget.dart`):

- Import `package:memox/core/error/outcome.dart`, `package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart`, and the four overlay files.
- Add these methods after `_selectAll`:

```dart
  /// Ruling P3-L4: set or clear, as chosen. The selection goes only once the
  /// write landed (IT-ORG-014).
  Future<void> _flag(Set<String> cardIds) async {
    final isFlagged = await showCardFlagSheet(context);
    if (isFlagged == null || !mounted) return;
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .setFlagged(cardIds: cardIds, isFlagged: isFlagged);
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok():
          _selection().clear();
          showMxSnackbar(
            context,
            message: isFlagged
                ? l10n.cardFlaggedToast(cardIds.length)
                : l10n.cardUnflaggedToast(cardIds.length),
          );
        case Rejected(:final reason):
          showMxSnackbar(context, message: l10n.cardRejection(reason));
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  /// Each overlay shows its own snackbar; the selection goes once the write
  /// landed. The section may be gone by then (the deck emptied), hence the
  /// `mounted` check.
  Future<void> _clearAfter(Future<bool> write) async {
    if (await write && mounted) _selection().clear();
  }
```

- Extend the `actions:` list after the Select all entry:

```dart
                (
                  icon: AppIcons.flag,
                  label: l10n.cardFlag,
                  onTap: () => unawaited(_flag(selected)),
                ),
                (
                  icon: AppIcons.tag,
                  label: l10n.cardTag,
                  onTap: () => unawaited(
                    _clearAfter(showCardTagDialog(context, cardIds: selected)),
                  ),
                ),
                (
                  icon: AppIcons.folder,
                  label: l10n.cardMove,
                  onTap: () => unawaited(
                    _clearAfter(
                      showCardMoveSheet(
                        context,
                        sourceDeckId: widget.deckId,
                        cardIds: selected,
                      ),
                    ),
                  ),
                ),
                (
                  icon: AppIcons.delete,
                  label: l10n.cardDelete,
                  onTap: () => unawaited(
                    _clearAfter(
                      showDeleteCardsDialog(context, cardIds: selected),
                    ),
                  ),
                ),
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation
```

Expected: PASS: 8 new bulk tests.

- If the move picker also offers the source deck ("Korean › Words"), the test still passes, since it taps "Korean › Verbs". Leave the offer as the backend gives it, and record a finding (spec §12).

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): bulk flag, tag, move and delete from selection mode

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Route behaviour and the card list goldens

**Files:**
- Modify: `test/app/library_routes_test.dart`
- Create: `test/features/card/presentation/card_list_golden_test.dart` and its goldens

- [ ] **Step 1: Write the tests**

Append to `test/app/library_routes_test.dart`, inside `main()`:

```dart
  libraryTest('Back leaves selection first, then the deck (RF5)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_barTitle('Words'), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_barTitle('Korean'), findsOneWidget);
  });
```

(Import `package:memox/shared/widgets/mx_selection_checkbox.dart`.)

`test/features/card/presentation/card_list_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

/// A deck of cards in every status, one flagged, shown as its open deck.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final rows = [
    ('안녕하세요', 'hello', null, 1),
    ('감사합니다', 'thank you', DateTime(2026, 9, 24), 2),
    ('사랑', 'love', DateTime(2026, 9, 30), 5),
    ('물', 'water', DateTime(2026, 12, 1), 8),
  ];
  for (final (index, (front, back, due, box)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      learnedAt: due == null ? null : DateTime(2026, 9, 1),
      dueAt: due,
      box: box,
      isFlagged: index == 1,
      createdAt: DateTime(2026, 9, 1 + index),
    );
  }
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card list, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(
            deckId: deckId,
            cardContent: (id) => CardListSectionWidget(deckId: id),
          ),
          brightness,
        );
        await expectBoundaryGolden(tester, 'goldens/card_list_$theme.png');
      });
    });

    libraryTest('card selection, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(
            deckId: deckId,
            cardContent: (id) => CardListSectionWidget(deckId: id),
          ),
          brightness,
        );
        await tester.longPress(find.text('사랑'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/card_selection_$theme.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Run the route test**

Run: `flutter test test/app/library_routes_test.dart`
Expected: PASS. Tasks 2–3 built the behaviour, so a failure here is a finding to debug, not a test to relax.

- [ ] **Step 3: Make and check the goldens**

```bash
flutter test --update-goldens --tags golden test/features/card/presentation/card_list_golden_test.dart
flutter test --tags golden test/features/card/presentation test/features/deck/presentation test/app
```

Delete any `failures/` folder. Open the light goldens:
- `card_list`: the content bar "Words" and the breadcrumb Library › Korean › Words; the search field; the chips All 4 · Due 1 · New 1 · Flagged 1, then Sort; four rows in one card, each with its front, back and status dot; 감사합니다 has a flag glyph.
- `card_selection`: under the breadcrumb, the header "✕ 1 selected"; checkboxes on every row, with 사랑's checked; the bulk bar at the bottom with Select all, Flag, Tag, Move and Delete in equal columns.

- [ ] **Step 4: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add test
git commit -m "test(card): the card list in the app, and its goldens

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Register, full gate, hand back

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9)

- [ ] **Step 1: Record the phase in the debt register**

Append after row 74 of UI-base spec §9:

```markdown
| 75 | The card list's selection header (count and close) sits inside the card section, under the deck app bar, not in it: the deck screen may not import `card` (D8) | library phase 3 P3-L1 |
| 76 | Bulk Tag only adds a tag. Removing one from a selection needs a read of the tags the selection carries, which the backend lacks (finding) | library phase 3 P3-L2 |
| 77 | A card row's tap opens nothing, and the empty deck offers no "Add card", until the detail and the editor arrive in phase 4 | library phase 3 P3-L3 |
| 78 | The bulk tag input is a dialog, not a sheet, because MxBottomSheet does not pad for the keyboard (row 64) | library phase 3 P3-L9 |
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

Expected: every command exits 0, and the guard reports 0 errors and 0 warnings.

- [ ] **Step 3: Scope check and commit**

```bash
git add docs/superpowers
git commit -m "docs(spec): record Library phase 3 in the UI debt register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected: the diff lists only:
- `docs/superpowers/`
- `lib/core/theme/foundations/app_icons.dart`
- `lib/l10n/`
- `lib/features/card/presentation/`
- `lib/features/deck/presentation/screens/deck_level_screen.dart`
- `lib/app/router/`
- `test/`

Report to the user in Vietnamese:
- Counts and results.
- Every ruling.
- The goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR, merge it, and continue to phase 4.
