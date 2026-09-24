# Library Phase 4: Card Editor and Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cards can be added one after another, edited, and inspected with their review history (M2), and "Add card" is reachable from every deck that can hold cards.

**Architecture:**
- **Card feature.** Two new screens:
  - `CardEditorScreen`, in create mode (continuous) and edit mode;
  - `CardDetailScreen`, with content, tags, status and paged history.

  They sit over the use cases through new providers and a `CardHistory` async notifier. `CardActionsController` gains `createCard` and `editCard`.
- **Deck screen.** It takes `onAddCard`. It opens a two-option create sheet when a deck can hold both decks and cards, and hides its FAB while the card list is selecting. The card list reports that through the `cardContent` builder, since `deck` never imports `card` (D8).
- **Routing.** `app/router` adds `/decks/deck/:deckId/cards/new`, `/decks/card/:cardId` and `/decks/card/:cardId/edit`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18, Drift 2.35 (in-memory for tests), gen-l10n (en/vi), intl `DateFormat`.

**Spec:** `docs/superpowers/specs/2026-09-24-library-screens-design.md` (§4 routes, §5 data flow, §6.1 FAB and unset state, §6.5 card editor, §6.6 card detail, §9, §10 row 4). Card rules: `docs/features/card/ui.md`, `lib/features/card/domain/models/card_draft_model.dart`. Phase 3 plan: `docs/superpowers/plans/2026-09-24-library-phase-3-card-list.md`.

## Global Constraints

- **UI only.** No file under `lib/features/*/domain`, `lib/features/*/data`, `lib/features/*/di` or `lib/core/database` changes (spec §12).
- **Import map:** `card → {deck, srs, tags}` (domain models, entities, failures and di only), `deck → {srs}`. `app/` composes; `deck` never imports `card`.
- **One use case per interaction** through one provider (AD-12). Writes go through `CardActionsController`. The detail and the editor read through `cardDetailProvider(cardId)`, and the history through `cardHistoryProvider(cardId)`.
- **Editor** (spec §6.5, UC-CARD-001):
  - Five fields with character counts (front 60, back 240, example / hint / pronunciation 240), counted in grapheme clusters. Front and back are marked required.
  - Errors are inline, one per field, all at once.
  - Tags come through a feature-local chip input (at most 10, folded duplicates ignored). The flag is an `MxSettingsRow` with an `MxToggle`. Save sits in an `MxFooterBar`.
  - In create mode, `Ok` clears the form, refocuses the front field and shows a snackbar. In edit mode, `Ok` pops.
- **Detail** (spec §6.6, UC-CARD-002, BR-CARD-013…020):
  - Content, tags, status (pill), scheduler and due date.
  - Review history grouped by generation, newest first, with "Load more" while a cursor exists.
  - Edit is an app bar action, never the tap. A card that is gone pops with a snackbar (BR-CARD-019).
- **Feedback** follows spec §5: field reasons stay under their field; any other reason shows in a snackbar; a `Failure` shows `l10n.failure`.
- **Guard memox-v8 at 0/0:**
  - no raw `IconButton`, `ListTile` or `Card`, and no `Icon(color:)`;
  - no `ref.read` lexically in `build()`;
  - `build()` short enough for `flutter.max_build_lines`: split into widgets, and build lists in data methods;
  - no defaulted provider or notifier parameter;
  - in the ARB, `placeholders` comes before `description`.
- **Copy:** `app_en.arb` (with `@key`) and `app_vi.arb`. Run `flutter gen-l10n` after ARB edits, and `dart run build_runner build --delete-conflicting-outputs` after `@riverpod` edits.
- **Tests** run through the real backend (`libraryTest`, `pumpLibraryScreen`, `pumpMemoxApp`).
- **Goldens** are 3x light and dark. Their text uses Latin or romanized content, because the golden font has no Hangul (phase 3 ruling).
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings (phase 4)

| # | Ruling |
|---|---|
| P4-L1 | The deck screen hides its FAB while the card list selects, so the FAB never covers the bulk bar. The card section reports selecting through the `cardContent` builder's second argument. The deck keeps it in `deckCardSelectingProvider(deckId)`, since it may not import `card` (D8). |
| P4-L2 | `MxEmptyState` carries one action. So the unset state's action opens the same create choice as the FAB ("Add to this deck"), and at the deepest level it adds a card directly. |
| P4-L3 | Before saving, the editor checks every field with `CardDraft`'s static rules, so all field errors show at once. The use case checks again, and its refusals go to their field or to a snackbar. |
| P4-L4 | Only submitted tag chips are saved. Text left in the tag input when Save is pressed is not a tag. |
| P4-L5 | A history row shows the answer and its date and time. The study mode code is left out, because the study feature owns mode labels. Rows group under "Round N", one round per generation. |
| P4-L6 | An edit that lands, and a detail or editor whose card is gone, leave with `maybePop`, so a screen that is the only route stays put. |
| P4-L7 | The due date reads `DateFormat.yMMMd` in the current locale. A history row adds the time (`Hm`). |
| P4-L8 | A field's count turns to the error colour past its limit. The error message itself waits for Save. |

## Review Focus

1. **Adding several cards in a row.**
   - Expected: each Save clears the form (tags and flag included), focus returns to the front field, and a double tap on Save adds one card.
   - Pinned in Task 2.
2. **Editing a card that is deleted meanwhile.**
   - Expected: a snackbar says it is gone, the editor leaves, and nothing is written.
   - Pinned in Task 2.
3. **The keyboard open over the editor.**
   - Expected: Save stays visible above it.
   - Pinned in Task 2.
4. **Hangul or Vietnamese text.**
   - Expected: counters count characters as people see them ("한국어" is 3), and nothing overflows at 2x.
   - Pinned in Tasks 2 and 3.
5. **History over more than one page and two generations.**
   - Expected: grouped by round, newest first. Load more appends the rest once, then disappears.
   - Pinned in Task 3.

## File Map

```
lib/l10n/app_en.arb, app_vi.arb                              card editor, detail and deck copy
lib/features/card/presentation/
  providers/  create_card, edit_card, watch_card_detail, load_card_history_page use-case providers;
              card_detail_provider.dart
  states/     card_history_state.dart
  controllers/card_actions_controller.dart                    + createCard, editCard
  screens/    card_editor_screen.dart, card_detail_screen.dart
  widgets/sections/ card_field_widget.dart, card_tag_field_widget.dart,
                    card_detail_content_widget.dart, card_detail_status_widget.dart,
                    card_history_section_widget.dart, card_list_section_widget.dart (callbacks)
  widgets/items/    card_tag_input_chip_widget.dart, card_row_widget.dart (unchanged API)
  widgets/support/  card_detail_labels_widget.dart, card_history_groups_widget.dart
lib/features/deck/presentation/
  screens/deck_level_screen.dart                              onAddCard, create choice, FAB rules
  states/deck_card_selecting_state.dart
  widgets/overlays/deck_create_sheet_widget.dart
  widgets/sections/deck_unset_state_widget.dart               one action, label from caller
lib/app/router/app_routes.dart, app_router.dart               three card routes
test/support/library_harness.dart, card_fixtures.dart         LibraryEnv.cards, logAnswer
test/...                                                      tests and goldens
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md   §9 rows 79–81
```

---

### Task 1: Editor and detail plumbing: providers, history pages, create and edit commands, copy

**Files:**
- Create in `lib/features/card/presentation/`:
  - `providers/`: 4 use-case providers and `card_detail_provider.dart`
  - `states/card_history_state.dart`
  - `widgets/support/card_detail_labels_widget.dart`, `card_history_groups_widget.dart`
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `test/support/library_harness.dart`, `test/support/card_fixtures.dart`
- Test: `test/features/card/presentation/card_actions_controller_test.dart` (extend), `card_history_state_test.dart`, `card_detail_labels_test.dart`

**Interfaces:**
- Produces:
  - `cardDetailProvider(String cardId)`: `Stream<Outcome<CardDetail, CardRejection>>`.
  - `cardHistoryProvider(String cardId)`: `AsyncValue<CardHistoryState>`. The state has `entries`, `next`, `isLoadingMore` and `hasMore`; the notifier's `loadMore()` → `Future<void>` and rethrows a `Failure`.
  - `CardActionsController`:
    - `createCard({required String deckId, required CardDraft draft})` → `Future<Outcome<CardEntity, CardRejection>>`;
    - `editCard({required String cardId, required CardDraft draft})` → `Future<Outcome<void, CardRejection>>`.
  - Labels, as extensions on `AppLocalizations`: `cardScheduler(SchedulerType)` and `cardReviewAction(Enum action)`.
  - `typedef CardHistoryGroup = ({int generation, List<ReviewHistoryEntry> entries})` and `cardHistoryGroups(List<ReviewHistoryEntry>)`.
  - Test support: `LibraryEnv.cards` (a real `CardRepository`) and `logAnswer(AppDatabase, {cardId, id, at, generation, action})` in `card_fixtures.dart`.

- [ ] **Step 1: Write the failing tests**

Add to `test/support/card_fixtures.dart`:

```dart
/// One answer in a card's review history, as the study flow writes it;
/// [at] orders the history.
Future<void> logAnswer(
  AppDatabase db, {
  required String cardId,
  required String id,
  required DateTime at,
  int generation = 1,
  String action = 'remembered',
}) => db.customStatement(
  'INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, '
  'kind, mode, "action", answered_at, next_due_at, previous_box, next_box) '
  "VALUES (?, ?, 's', 'eight_box', ?, 'scheduled', 'recall', ?, ?, ?, 2, 3)",
  [
    id,
    cardId,
    generation,
    action,
    at.millisecondsSinceEpoch ~/ 1000,
    at.millisecondsSinceEpoch ~/ 1000 + 86400,
  ],
);
```

In `test/support/library_harness.dart`, give `LibraryEnv` a real card repository. Add the imports for `CardRepositoryImpl`, `CardRepository`, `ScheduleRepositoryImpl` and `TagRepositoryImpl`:

```dart
final class LibraryEnv {
  LibraryEnv(this.db, this.clock)
    : decks = DeckRepositoryImpl(db),
      cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db),
        TagRepositoryImpl(db),
      );

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
  final CardRepository cards;
}
```

Append inside `main()` of `test/features/card/presentation/card_actions_controller_test.dart`. Add the imports `package:memox/features/card/domain/models/card_draft_model.dart`, `package:memox/features/card/domain/failures/card_failure.dart` and `package:memox/core/database/app_database.dart` if missing:

```dart
  test('createCard saves the content, the flag and the tags', () async {
    final ids = await seed();
    final outcome = await actions().createCard(
      deckId: ids.words,
      draft: const CardDraft(
        front: 'bap',
        back: 'rice',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );

    expect(outcome, isA<Ok<Object?, CardRejection>>());
    expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 2);
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 1);
  });

  test('editCard replaces the content and the tags', () async {
    await seed();
    await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back', tagNames: ['x', 'y']),
    );

    expect(
      await count("SELECT COUNT(*) AS n FROM card WHERE front = 'new'"),
      1,
    );
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 2);
  });

  test('editCard is refused for a card that is gone', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a'});
    final outcome = await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back'),
    );

    expect(
      outcome,
      isA<Rejected<Object?, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.notFound,
      ),
    );
  });
```

`test/features/card/presentation/card_history_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/states/card_history_state.dart';

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

  test('pages come newest first; Load more appends the rest once', () async {
    final env = LibraryEnv(db, FakeDayClock(libraryToday));
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(db, id: 'card', deckId: words.id);
    // Two answers of round 1, then a full page of round 2.
    for (var i = 0; i < 2; i++) {
      await logAnswer(db, cardId: 'card', id: 'old$i', at: DateTime(2026, 8, 1 + i));
    }
    for (var i = 0; i < ReviewHistoryPage.size; i++) {
      await logAnswer(
        db,
        cardId: 'card',
        id: 'new$i',
        at: DateTime(2026, 9, 1).add(Duration(hours: i)),
        generation: 2,
      );
    }
    final provider = cardHistoryProvider('card');
    final keep = container.listen(provider, (_, _) {});
    addTearDown(keep.close);

    final first = await container.read(provider.future);
    expect(first.entries, hasLength(ReviewHistoryPage.size));
    expect(first.entries.first.generation, 2);
    expect(first.hasMore, isTrue);

    await container.read(provider.notifier).loadMore();
    final all = container.read(provider).value!;
    expect(all.entries, hasLength(ReviewHistoryPage.size + 2));
    expect(all.entries.last.generation, 1);
    expect(all.hasMore, isFalse);
    expect({for (final entry in all.entries) entry.id}, hasLength(52));
  });
}
```

`test/features/card/presentation/card_detail_labels_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_detail_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_groups_widget.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

ReviewHistoryEntry _entry(String id, int generation) => ReviewHistoryEntry(
  id: id,
  generation: generation,
  schedulerType: SchedulerType.eightBox,
  kind: ReviewKind.scheduled,
  mode: 'recall',
  action: EightBoxAction.remembered,
  answeredAt: DateTime(2026, 9, 1),
  isTimedOut: false,
  usedHint: null,
  nextDueAt: null,
  previousBox: 1,
  nextBox: 2,
  previousEaseFactor: null,
  nextEaseFactor: null,
  previousIntervalDays: null,
  nextIntervalDays: null,
);

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);

    test('every answer and scheduler has ${locale.languageCode} copy', () {
      for (final action in [...EightBoxAction.values, ...Sm2Action.values]) {
        expect(l10n.cardReviewAction(action).trim(), isNotEmpty);
      }
      for (final type in SchedulerType.values) {
        expect(l10n.cardScheduler(type).trim(), isNotEmpty);
      }
    });
  }

  test('history groups runs of one generation, in order (BR-CARD-017)', () {
    final groups = cardHistoryGroups([
      _entry('a', 2),
      _entry('b', 2),
      _entry('c', 1),
    ]);

    expect([for (final group in groups) group.generation], [2, 1]);
    expect(
      [for (final entry in groups.first.entries) entry.id],
      ['a', 'b'],
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation`
Expected: FAIL to compile. `card_history_state.dart`, `createCard` and the label extension do not exist.

- [ ] **Step 3: Implement**

**Use-case providers**, one file each in `lib/features/card/presentation/providers/`, shaped like the phase 3 ones. Each has `import 'package:memox/features/card/di/card_repository_provider.dart';`, the use case import and `riverpod_annotation`:

| Provider file | Function | Body |
|---|---|---|
| `create_card_use_case_provider.dart` | `createCardUseCase` | `CreateCardUseCase(ref.watch(cardRepositoryProvider))` |
| `edit_card_use_case_provider.dart` | `editCardUseCase` | `EditCardUseCase(ref.watch(cardRepositoryProvider))` |
| `watch_card_detail_use_case_provider.dart` | `watchCardDetailUseCase` | `WatchCardDetailUseCase(ref.watch(cardRepositoryProvider))` |
| `load_card_history_page_use_case_provider.dart` | `loadCardHistoryPageUseCase` | `LoadCardHistoryPageUseCase(ref.watch(cardRepositoryProvider))` |

`lib/features/card/presentation/providers/card_detail_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_detail_provider.g.dart';

/// A card as its detail and its editor read it, again on every change;
/// `Rejected(notFound)` once it is gone (BR-CARD-019).
@riverpod
Stream<Outcome<CardDetail, CardRejection>> cardDetail(Ref ref, String cardId) =>
    ref.watch(watchCardDetailUseCaseProvider)(cardId: cardId);
```

`lib/features/card/presentation/states/card_history_state.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_history_state.g.dart';

/// The history pages a card's detail has loaded, newest first, and where the
/// next one starts (BR-CARD-015). Paged, not streamed (spec §5).
final class CardHistoryState {
  const CardHistoryState({
    required this.entries,
    required this.next,
    this.isLoadingMore = false,
  });

  final List<ReviewHistoryEntry> entries;
  final ReviewHistoryCursor? next;
  final bool isLoadingMore;

  bool get hasMore => next != null;
}

/// A card's history, one page at a time.
@riverpod
class CardHistory extends _$CardHistory {
  @override
  Future<CardHistoryState> build(String cardId) =>
      _page(ref.watch(loadCardHistoryPageUseCaseProvider), const [], null);

  /// The page after the loaded ones, one request at a time. A `Failure`
  /// keeps what loaded and is thrown on for the widget to show.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      CardHistoryState(
        entries: current.entries,
        next: current.next,
        isLoadingMore: true,
      ),
    );
    try {
      state = AsyncData(
        await _page(
          ref.read(loadCardHistoryPageUseCaseProvider),
          current.entries,
          current.next,
        ),
      );
    } on Failure {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<CardHistoryState> _page(
    LoadCardHistoryPageUseCase load,
    List<ReviewHistoryEntry> loaded,
    ReviewHistoryCursor? after,
  ) async {
    final outcome = await load(cardId: cardId, cursor: after);
    return switch (outcome) {
      Ok(:final value) => CardHistoryState(
        entries: [...loaded, ...value.entries],
        next: value.next,
      ),
      // The card is gone: its detail leaves (BR-CARD-019), nothing loads on.
      Rejected() => CardHistoryState(entries: loaded, next: null),
    };
  }
}
```

**Controller.** In `card_actions_controller.dart`, add these after `deleteCards`, with the two provider imports, `card_entity.dart` and `card_draft_model.dart`:

```dart
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
  }) => ref.read(createCardUseCaseProvider)(deckId: deckId, draft: draft);

  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
  }) => ref.read(editCardUseCaseProvider)(cardId: cardId, draft: draft);
```

`lib/features/card/presentation/widgets/support/card_detail_labels_widget.dart`:

```dart
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Names on the card detail: the scheduler and each recorded answer.
extension CardDetailLabel on AppLocalizations {
  String cardScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };

  /// An `EightBoxAction` or a `Sm2Action`, as the history stored it.
  String cardReviewAction(Enum action) => switch (action) {
    EightBoxAction.forgotten => cardActionForgotten,
    EightBoxAction.remembered => cardActionRemembered,
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
    // Only those two enums reach the history; the name is a safe fallback.
    _ => action.name,
  };
}
```

`lib/features/card/presentation/widgets/support/card_history_groups_widget.dart`:

```dart
import 'package:memox/features/card/domain/models/review_history_model.dart';

/// The answers of one generation, newest first (BR-CARD-017).
typedef CardHistoryGroup = ({int generation, List<ReviewHistoryEntry> entries});

/// [entries] (newest first) cut into runs of one generation.
List<CardHistoryGroup> cardHistoryGroups(List<ReviewHistoryEntry> entries) {
  final groups = <CardHistoryGroup>[];
  for (final entry in entries) {
    if (groups.lastOrNull?.generation == entry.generation) {
      groups.last.entries.add(entry);
      continue;
    }
    groups.add((generation: entry.generation, entries: [entry]));
  }
  return groups;
}
```

**Copy.** Run this script as before, then `flutter gen-l10n`. `UPDATE` rewrites two existing deck strings for the new create choice (ruling P4-L2):

```python
import json
from pathlib import Path

INT = {"type": "int"}
STRING = {"type": "String"}

KEYS = {
    "cardAddTitle": ("New card", "Thẻ mới", "Title of the card editor in create mode.", None),
    "cardEditTitle": ("Edit card", "Sửa thẻ", "Title of the card editor in edit mode.", None),
    "cardFieldFront": ("Front", "Mặt trước", "Card field label.", None),
    "cardFieldBack": ("Back", "Mặt sau", "Card field label.", None),
    "cardFieldExample": ("Example", "Ví dụ", "Card field label.", None),
    "cardFieldHint": ("Hint", "Gợi ý", "Card field label.", None),
    "cardFieldPronunciation": ("Pronunciation", "Phát âm", "Card field label.", None),
    "cardFieldRequired": ("Required", "Bắt buộc", "Marks a required card field.", None),
    "cardFieldCount": ("{count}/{limit}", "{count}/{limit}", "A field's character count against its limit.", {"count": INT, "limit": INT}),
    "cardFieldTags": ("Tags", "Nhãn", "Tag input label in the card editor.", None),
    "cardTagAddHint": ("Add a tag", "Thêm nhãn", "Hint in the tag input; Done adds the tag.", None),
    "cardTagRemove": ("Remove {tag}", "Bỏ nhãn {tag}", "Accessible name of a tag chip's remove button.", {"tag": STRING}),
    "cardFlagLabel": ("Flag this card", "Gắn cờ thẻ này", "Flag toggle row in the card editor.", None),
    "cardSave": ("Save", "Lưu", "Card editor save button.", None),
    "cardAddedToast": ("Card added", "Đã thêm thẻ", "Snackbar after a card is created.", None),
    "cardFrontBlank": ("Enter the front.", "Hãy nhập mặt trước.", "Error under a blank front field.", None),
    "cardBackBlank": ("Enter the back.", "Hãy nhập mặt sau.", "Error under a blank back field.", None),
    "cardEdit": ("Edit", "Sửa", "Card detail app bar action.", None),
    "cardDetailContent": ("Content", "Nội dung", "Card detail section title.", None),
    "cardDetailTags": ("Tags", "Nhãn", "Card detail section title.", None),
    "cardDetailNoTags": ("No tags", "Chưa có nhãn", "Card detail when the card has no tag.", None),
    "cardDetailStatus": ("Status", "Trạng thái", "Card detail section title and row label.", None),
    "cardDetailScheduler": ("Scheduler", "Bộ lập lịch", "Card detail row label.", None),
    "cardDetailDue": ("Due", "Đến hạn", "Card detail row label.", None),
    "cardDetailNotLearned": ("Not learned yet", "Chưa học", "Due row value for a new card.", None),
    "cardDetailHistory": ("Review history", "Lịch sử ôn", "Card detail section title.", None),
    "cardHistoryEmpty": ("No reviews yet", "Chưa có lượt ôn nào", "History section with no answer.", None),
    "cardHistoryRound": ("Round {generation}", "Vòng {generation}", "History group header; one round per schedule generation.", {"generation": INT}),
    "cardHistoryLoadMore": ("Load more", "Tải thêm", "Loads the next history page.", None),
    "cardActionForgotten": ("Forgotten", "Quên", "Recorded answer: eight box, forgotten.", None),
    "cardActionRemembered": ("Remembered", "Nhớ", "Recorded answer: eight box, remembered.", None),
    "cardActionAgain": ("Again", "Lại", "Recorded answer: SM-2, again.", None),
    "cardActionHard": ("Hard", "Khó", "Recorded answer: SM-2, hard.", None),
    "cardActionGood": ("Good", "Tốt", "Recorded answer: SM-2, good.", None),
    "cardActionEasy": ("Easy", "Dễ", "Recorded answer: SM-2, easy.", None),
    "cardLoadDetailErrorTitle": ("Couldn't open this card", "Không mở được thẻ này", "Error state title of the card detail and editor.", None),
    "cardEmptyAction": ("Add card", "Thêm thẻ", "Empty card list action that opens the editor.", None),
    "deckAddCard": ("Add card", "Thêm thẻ", "Adds a card to the open deck.", None),
    "deckCreateAny": ("Add to this deck", "Thêm vào bộ thẻ này", "Opens the choice between a sub-deck and a card.", None),
}

UPDATE = {
    "deckUnsetBody": ("Add a sub-deck or your first card.", "Thêm một bộ thẻ con hoặc thẻ đầu tiên."),
    "deckUnsetDeepestBody": ("This deck is at the deepest level, so it holds cards but no more decks.", "Bộ thẻ này đã ở cấp sâu nhất nên chỉ chứa thẻ, không chứa thêm bộ thẻ."),
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
    for key, (en, vi) in UPDATE.items():
        assert key in data, key
        data[key] = en if is_template else vi
    file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation test/features/deck/presentation
```

Expected: PASS: 3 new controller tests, 1 history test and 3 label tests. The deck tests read the updated unset copy through `_en`, so they still pass.

- If `review_log` refuses the `'s'` session id because of a foreign key, insert a session row first with `insertStudyTree`-style SQL from `test/support/srs_fixtures.dart`, and record a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): editor and detail plumbing: create and edit commands, detail stream, history pages, copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The card editor

**Files:**
- Create in `lib/features/card/presentation/`:
  - `screens/card_editor_screen.dart`
  - `widgets/sections/card_field_widget.dart`, `widgets/sections/card_tag_field_widget.dart`
  - `widgets/items/card_tag_input_chip_widget.dart`
- Test: `test/features/card/presentation/card_editor_screen_test.dart`

**Interfaces:**
- Consumes (Task 1): `CardActionsController.createCard` / `editCard`, `cardDetailProvider`, `cardRejection` (phase 3), copy keys.
- Produces:
  - `CardEditorScreen.create({required String deckId})` and `CardEditorScreen.edit({required String cardId})`.
  - `CardFieldWidget({required String label, required int limit, required TextEditingController controller, bool isRequired, bool isMultiline, FocusNode? focusNode, String? errorText})`.
  - `CardTagFieldWidget({required List<String> tags, required ValueChanged<List<String>> onChanged, String? errorText})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_editor_screen_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The editor's text fields, in form order: front, back, example, hint,
/// pronunciation, then the tag input.
Finder _field(int index) => find.byType(EditableText).at(index);

Future<String> _cardDeck(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  return words.id;
}

Future<int> _count(LibraryEnv env, String sql, [List<String> args = const []]) async =>
    (await env.db
            .customSelect(
              sql,
              variables: [for (final arg in args) Variable<String>(arg)],
            )
            .getSingle())
        .read<int>('n');

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(MxButton, _en.cardSave));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('Save adds the card, clears the form and refocuses (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.enterText(_field(5), 'food');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byType(MxToggle));
    await _save(tester);

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 1);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 1);
    expect(find.text(_en.cardAddedToast), findsOneWidget);
    expect(find.text('bap'), findsNothing);
    expect(find.text('food'), findsNothing);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(tester.widget<EditableText>(_field(0)).focusNode.hasFocus, isTrue);
  });

  libraryTest('a double tap on Save adds one card', (tester, env) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.tap(find.widgetWithText(MxButton, _en.cardSave));
    await tester.tap(
      find.widgetWithText(MxButton, _en.cardSave),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
  });

  libraryTest('every field error shows at once and nothing is written', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));
    await tester.enterText(_field(1), 'a' * (CardDraft.maxBackLength + 1));
    await _save(tester);

    expect(find.text(_en.cardFrontBlank), findsOneWidget);
    expect(find.text(_en.cardRejectionBackTooLong), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('counters count characters as people see them (RF4)', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));
    await tester.enterText(_field(0), '한국어');
    await tester.enterText(_field(1), 'Việt');
    await tester.pump();

    expect(find.text(_en.cardFieldCount(3, CardDraft.maxFrontLength)), findsOneWidget);
    expect(find.text(_en.cardFieldCount(4, CardDraft.maxBackLength)), findsOneWidget);
  });

  libraryTest('tags ignore a folded duplicate and stop at ten', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));
    Future<void> addTag(String name) async {
      await tester.enterText(_field(5), name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    await addTag('Verb');
    await addTag('verb');
    expect(find.byTooltip(_en.cardTagRemove('Verb')), findsOneWidget);
    expect(find.byTooltip(_en.cardTagRemove('verb')), findsNothing);

    for (var i = 0; i < 9; i++) {
      await addTag('tag $i');
    }
    await addTag('one too many');
    expect(find.text(_en.cardRejectionTooManyTags), findsOneWidget);

    await tester.tap(find.byTooltip(_en.cardTagRemove('Verb')));
    await tester.pump();
    expect(find.byTooltip(_en.cardTagRemove('Verb')), findsNothing);
  });

  libraryTest('Save stays above the keyboard (RF3)', (tester, env) async {
    final deckId = await _cardDeck(env);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await pumpLibraryScreen(tester, env, CardEditorScreen.create(deckId: deckId));

    expect(
      tester.getBottomLeft(find.widgetWithText(MxButton, _en.cardSave)).dy,
      lessThanOrEqualTo(800 - 300),
    );
  });

  libraryTest('edit starts from the card and saves the change', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, CardEditorScreen.edit(cardId: card.id));
    await tester.pumpAndSettle();

    expect(find.text('bap'), findsOneWidget);
    expect(find.byTooltip(_en.cardTagRemove('food')), findsOneWidget);
    await tester.enterText(_field(1), 'cooked rice');
    await _save(tester);

    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE back = ?',
        ['cooked rice'],
      ),
      1,
    );
  });

  libraryTest('editing a card deleted meanwhile says so, writes nothing (RF2)', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, CardEditorScreen.edit(cardId: card.id));
    await tester.pumpAndSettle();
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardRejectionNotFound), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('the editor meets the target guidelines at 2x (RF4)', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.create(deckId: deckId),
      textScale: 2,
    );
    await tester.enterText(_field(0), List.filled(4, '한국어 단어').join(' '));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_editor_screen_test.dart`
Expected: FAIL to compile, because `card_editor_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_field_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One card field (spec §6.5): its label, a required mark, and a live count
/// against its limit above the input. The count turns to the error colour
/// past the limit; the message waits for Save (ruling P4-L8).
class CardFieldWidget extends StatelessWidget {
  const CardFieldWidget({
    super.key,
    required this.label,
    required this.limit,
    required this.controller,
    this.isRequired = false,
    this.isMultiline = false,
    this.focusNode,
    this.errorText,
  });

  final String label;

  /// In characters as a person sees them (BR-CARD-002, BR-CARD-003).
  final int limit;
  final TextEditingController controller;
  final bool isRequired;
  final bool isMultiline;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Row(
            spacing: AppSpacing.control,
            children: [
              Flexible(child: Text(label, style: styles.settingsLabel)),
              if (isRequired)
                Text(l10n.cardFieldRequired, style: styles.rowDescription),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final count = value.text.characters.length;
                  return Text(
                    l10n.cardFieldCount(count, limit),
                    style: count > limit
                        ? styles.counter.copyWith(color: colors.error)
                        : styles.counter,
                  );
                },
              ),
            ],
          ),
          MxTextField(
            controller: controller,
            focusNode: focusNode,
            hintText: label,
            errorText: errorText,
            isMultiline: isMultiline,
            textInputAction: isMultiline
                ? TextInputAction.newline
                : TextInputAction.next,
          ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/items/card_tag_input_chip_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// A tag on the card being edited, with its own remove control (spec §6.5).
class CardTagInputChipWidget extends StatelessWidget {
  const CardTagInputChipWidget({
    super.key,
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: MxTagChip(label: name)),
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: context.l10n.cardTagRemove(name),
        onPressed: onRemove,
      ),
    ],
  );
}
```

`lib/features/card/presentation/widgets/sections/card_tag_field_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tag_input_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The card's tags as removable chips, and an input whose Done adds one
/// (spec §6.5). A name already there, however spelled, adds nothing
/// (BR-TAG-001). Ruling P4-L4: only chips are saved.
class CardTagFieldWidget extends StatefulWidget {
  const CardTagFieldWidget({
    super.key,
    required this.tags,
    required this.onChanged,
    this.errorText,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;

  @override
  State<CardTagFieldWidget> createState() => _CardTagFieldWidgetState();
}

class _CardTagFieldWidgetState extends State<CardTagFieldWidget> {
  final _input = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final folded = TagEntity.fold(trimmed);
    if (widget.tags.any((tag) => TagEntity.fold(tag) == folded)) {
      _input.clear();
      return;
    }
    final next = [...widget.tags, trimmed];
    if (CardDraft.checkTagNames(next) case Rejected(:final reason)) {
      setState(() => _inputError = context.l10n.cardRejection(reason));
      return;
    }
    setState(() => _inputError = null);
    _input.clear();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Text(l10n.cardFieldTags, style: context.textStyles.settingsLabel),
          if (widget.tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.control,
              children: [
                for (final tag in widget.tags)
                  CardTagInputChipWidget(
                    name: tag,
                    onRemove: () =>
                        widget.onChanged([...widget.tags]..remove(tag)),
                  ),
              ],
            ),
          MxTextField(
            controller: _input,
            hintText: l10n.cardTagAddHint,
            errorText: _inputError ?? widget.errorText,
            textInputAction: TextInputAction.done,
            onSubmitted: _add,
          ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/screens/card_editor_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Adds cards one after another into a deck, or edits one (spec §6.5).
class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen.create({super.key, required String this.deckId})
    : cardId = null;

  const CardEditorScreen.edit({super.key, required String this.cardId})
    : deckId = null;

  final String? deckId;
  final String? cardId;

  @override
  Widget build(BuildContext context) => switch ((deckId, cardId)) {
    (final String deckId, _) => _CardEditorForm(deckId: deckId),
    (_, final String cardId) => _EditLoader(cardId: cardId),
    _ => const SizedBox.shrink(),
  };
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

/// The card to edit, while it loads, fails or is gone.
class _EditLoader extends ConsumerWidget {
  const _EditLoader({required this.cardId});

  final String cardId;

  static const int _skeletonRows = 4;

  /// BR-CARD-019: the card is gone. Say so once and leave (ruling P4-L6).
  void _leaveWhenGone(
    BuildContext context,
    AsyncValue<Outcome<CardDetail, CardRejection>>? previous,
    AsyncValue<Outcome<CardDetail, CardRejection>> next,
  ) {
    if (previous?.value case Rejected()) return;
    if (next.value case Rejected(reason: CardRejection.notFound)) {
      showMxSnackbar(context, message: context.l10n.cardRejectionNotFound);
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(cardId);
    ref.listen(
      provider,
      (previous, next) => _leaveWhenGone(context, previous, next),
    );
    final bar = MxAppBar(
      title: l10n.cardEditTitle,
      density: MxAppBarDensity.content,
      leading: const _BackButton(),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => _CardEditorForm(
        key: ValueKey(cardId),
        card: value.card,
        initialTags: [for (final tag in value.tags) tag.name],
      ),
      AsyncError() => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadDetailErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
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

enum _Field { front, back, example, hint, pronunciation, tags }

/// The form itself: [deckId] to create into, or [card] to edit.
class _CardEditorForm extends ConsumerStatefulWidget {
  const _CardEditorForm({
    super.key,
    this.deckId,
    this.card,
    this.initialTags = const [],
  });

  final String? deckId;
  final CardEntity? card;
  final List<String> initialTags;

  @override
  ConsumerState<_CardEditorForm> createState() => _CardEditorFormState();
}

class _CardEditorFormState extends ConsumerState<_CardEditorForm> {
  late final _front = TextEditingController(text: widget.card?.front);
  late final _back = TextEditingController(text: widget.card?.back);
  late final _example = TextEditingController(text: widget.card?.example);
  late final _hint = TextEditingController(text: widget.card?.hint);
  late final _pronunciation = TextEditingController(
    text: widget.card?.pronunciation,
  );
  final _frontFocus = FocusNode();
  late var _tags = [...widget.initialTags];
  late var _isFlagged = widget.card?.isFlagged ?? false;
  var _errors = const <_Field, String>{};

  /// One save at a time: a second tap while the first runs does nothing.
  var _isSaving = false;

  bool get _isCreating => widget.card == null;

  @override
  void dispose() {
    for (final controller in [_front, _back, _example, _hint, _pronunciation]) {
      controller.dispose();
    }
    _frontFocus.dispose();
    super.dispose();
  }

  static String? _optional(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text;

  CardDraft _draft() => CardDraft(
    front: _front.text,
    back: _back.text,
    example: _optional(_example),
    hint: _optional(_hint),
    pronunciation: _optional(_pronunciation),
    isFlagged: _isFlagged,
    tagNames: _tags,
  );

  /// Ruling P4-L3: each field's own rule, so every error shows at once.
  Map<_Field, String> _fieldErrors(AppLocalizations l10n) {
    String? message(Outcome<void, CardRejection> rule, [String? blank]) =>
        switch (rule) {
          Ok() => null,
          Rejected(reason: CardRejection.blankContent) when blank != null =>
            blank,
          Rejected(:final reason) => l10n.cardRejection(reason),
        };
    final errors = {
      _Field.front: message(
        CardDraft.checkFront(_front.text),
        l10n.cardFrontBlank,
      ),
      _Field.back: message(CardDraft.checkBack(_back.text), l10n.cardBackBlank),
      _Field.example: message(CardDraft.checkOptional(_example.text)),
      _Field.hint: message(CardDraft.checkOptional(_hint.text)),
      _Field.pronunciation: message(
        CardDraft.checkOptional(_pronunciation.text),
      ),
      _Field.tags: message(CardDraft.checkTagNames(_tags)),
    };
    return {
      for (final MapEntry(:key, :value) in errors.entries)
        if (value != null) key: value,
    };
  }

  /// UC-CARD-001 A4: the next card starts from an empty form.
  void _clearForNext() {
    for (final controller in [_front, _back, _example, _hint, _pronunciation]) {
      controller.clear();
    }
    setState(() {
      _tags = [];
      _isFlagged = false;
      _errors = const {};
      _isSaving = false;
    });
    _frontFocus.requestFocus();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = context.l10n;
    final errors = _fieldErrors(l10n);
    setState(() {
      _errors = errors;
      _isSaving = errors.isEmpty;
    });
    if (errors.isNotEmpty) return;
    final actions = ref.read(cardActionsControllerProvider.notifier);
    try {
      final Outcome<Object?, CardRejection> outcome = _isCreating
          ? await actions.createCard(deckId: widget.deckId!, draft: _draft())
          : await actions.editCard(cardId: widget.card!.id, draft: _draft());
      if (!mounted) return;
      switch (outcome) {
        case Ok() when _isCreating:
          _clearForNext();
          showMxSnackbar(context, message: l10n.cardAddedToast);
        case Ok():
          unawaited(Navigator.of(context).maybePop());
        case Rejected(:final reason):
          setState(() => _isSaving = false);
          showMxSnackbar(context, message: l10n.cardRejection(reason));
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: _isCreating ? l10n.cardAddTitle : l10n.cardEditTitle,
        density: MxAppBarDensity.content,
        leading: const _BackButton(),
      ),
      // In-flow, so it stays above the keyboard (spec §6.5).
      footer: MxFooterBar(
        child: MxButton(
          label: l10n.cardSave,
          isBlock: true,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : () => unawaited(_save()),
        ),
      ),
      body: MxScreenScroll(children: _fields(l10n)),
    );
  }

  List<Widget> _fields(AppLocalizations l10n) => [
    const SizedBox(height: AppSpacing.gutter),
    CardFieldWidget(
      label: l10n.cardFieldFront,
      limit: CardDraft.maxFrontLength,
      controller: _front,
      focusNode: _frontFocus,
      isRequired: true,
      errorText: _errors[_Field.front],
    ),
    CardFieldWidget(
      label: l10n.cardFieldBack,
      limit: CardDraft.maxBackLength,
      controller: _back,
      isRequired: true,
      isMultiline: true,
      errorText: _errors[_Field.back],
    ),
    for (final (field, label, controller) in [
      (_Field.example, l10n.cardFieldExample, _example),
      (_Field.hint, l10n.cardFieldHint, _hint),
      (_Field.pronunciation, l10n.cardFieldPronunciation, _pronunciation),
    ])
      CardFieldWidget(
        label: label,
        limit: CardDraft.maxOptionalLength,
        controller: controller,
        isMultiline: true,
        errorText: _errors[field],
      ),
    CardTagFieldWidget(
      tags: _tags,
      errorText: _errors[_Field.tags],
      onChanged: (tags) => setState(() => _tags = tags),
    ),
    MxSection(
      children: [
        MxSettingsRow(
          label: l10n.cardFlagLabel,
          trailing: MxToggle(
            isOn: _isFlagged,
            semanticLabel: l10n.cardFlagLabel,
            onChanged: (isOn) => setState(() => _isFlagged = isOn),
          ),
        ),
      ],
    ),
  ];
}
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation/card_editor_screen_test.dart
```

Expected: PASS, 9 tests.

- If the tag input is not `EditableText.at(5)` (for example, a multiline field adds more than one `EditableText`), find it with `find.widgetWithText(MxTextField, _en.cardTagAddHint)` and record a test-only ruling.
- If `tester.view.viewInsets` does not shrink the Scaffold body in the test binding, assert that `MxFooterBar` sits in the `Scaffold`'s body column above `viewInsets` instead, and record a test-only ruling.
- If the `switch` on a record with `final String` patterns is refused, use `if (deckId case final deckId?) return _CardEditorForm(deckId: deckId);`, and record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card editor: continuous create, edit, tags, flag, inline checks

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The card detail and its review history

**Files:**
- Create in `lib/features/card/presentation/`:
  - `screens/card_detail_screen.dart`
  - `widgets/sections/card_detail_content_widget.dart`, `card_detail_status_widget.dart`, `card_history_section_widget.dart`
- Test: `test/features/card/presentation/card_detail_screen_test.dart`

**Interfaces:**
- Consumes (Task 1): `cardDetailProvider`, `cardHistoryProvider`, `cardHistoryGroups`, `cardReviewAction`, `cardScheduler`, `mxCardStatus` / `cardStatus` (phase 3), `logAnswer`, `LibraryEnv.cards`.
- Produces: `CardDetailScreen({required String cardId, required VoidCallback onEdit})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<String> _card(LibraryEnv env, [CardDraft? draft]) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final card = await env.cards.card(
    words.id,
    draft ??
        const CardDraft(
          front: 'sagwa',
          back: 'apple',
          example: 'An apple a day',
          tagNames: ['fruit', 'food'],
        ),
  );
  return card.id;
}

CardDetailScreen _screen(String cardId, {VoidCallback? onEdit}) =>
    CardDetailScreen(cardId: cardId, onEdit: onEdit ?? () {});

void main() {
  libraryTest('the detail shows content, tags, status and scheduler', (
    tester,
    env,
  ) async {
    final cardId = await _card(env);
    await pumpLibraryScreen(tester, env, _screen(cardId));
    await tester.pumpAndSettle();

    for (final text in ['sagwa', 'apple', 'An apple a day']) {
      expect(find.text(text), findsWidgets);
    }
    expect(find.byType(MxTagChip), findsNWidgets(2));
    expect(find.byType(MxStatusBadge), findsOneWidget);
    expect(find.text(_en.deckSchedulerEightBox), findsOneWidget);
    expect(find.text(_en.cardDetailNotLearned), findsOneWidget);
    expect(find.text(_en.cardHistoryEmpty), findsOneWidget);
  });

  libraryTest('Edit is an app bar action (BR-CARD-020)', (tester, env) async {
    final cardId = await _card(env);
    var edits = 0;
    await pumpLibraryScreen(tester, env, _screen(cardId, onEdit: () => edits++));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(_en.cardEdit));

    expect(edits, 1);
  });

  libraryTest('history groups by round; Load more appends the rest once (RF5)', (
    tester,
    env,
  ) async {
    final cardId = await _card(env);
    for (var i = 0; i < 2; i++) {
      await logAnswer(
        env.db,
        cardId: cardId,
        id: 'old$i',
        at: DateTime(2026, 8, 1 + i),
        action: 'forgotten',
      );
    }
    for (var i = 0; i < ReviewHistoryPage.size; i++) {
      await logAnswer(
        env.db,
        cardId: cardId,
        id: 'new$i',
        at: DateTime(2026, 9, 1).add(Duration(hours: i)),
        generation: 2,
      );
    }
    await pumpLibraryScreen(tester, env, _screen(cardId));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistoryRound(2)), findsOneWidget);
    expect(find.text(_en.cardHistoryRound(1)), findsNothing);
    await tester.scrollUntilVisible(
      find.text(_en.cardHistoryLoadMore),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(_en.cardHistoryLoadMore));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistoryRound(1)), findsOneWidget);
    expect(find.text(_en.cardActionForgotten), findsNWidgets(2));
    expect(find.text(_en.cardHistoryLoadMore), findsNothing);
  });

  libraryTest('a card deleted while open says so (BR-CARD-019)', (
    tester,
    env,
  ) async {
    final cardId = await _card(env);
    await pumpLibraryScreen(tester, env, _screen(cardId));
    await tester.pumpAndSettle();
    await env.cards.deleteCards(cardIds: {cardId});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardRejectionNotFound), findsOneWidget);
  });

  libraryTest('long Hangul and Vietnamese at 2x meet the guidelines (RF4)', (
    tester,
    env,
  ) async {
    final cardId = await _card(
      env,
      CardDraft(
        front: List.filled(3, '한국어').join(' '),
        back: List.filled(15, 'nghĩa tiếng Việt').join(' '),
        tagNames: const ['từ vựng', 'ngữ pháp'],
      ),
    );
    await pumpLibraryScreen(tester, env, _screen(cardId), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_detail_screen_test.dart`
Expected: FAIL to compile, because `card_detail_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_detail_content_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// What the card says, and its tags (BR-CARD-014). Read-only.
class CardDetailContentWidget extends StatelessWidget {
  const CardDetailContentWidget({super.key, required this.detail});

  final CardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = detail.card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.cardDetailContent,
          children: [
            _Field(label: l10n.cardFieldFront, value: card.front),
            _Field(label: l10n.cardFieldBack, value: card.back),
            if (card.example case final example?)
              _Field(label: l10n.cardFieldExample, value: example),
            if (card.hint case final hint?)
              _Field(label: l10n.cardFieldHint, value: hint),
            if (card.pronunciation case final pronunciation?)
              _Field(label: l10n.cardFieldPronunciation, value: pronunciation),
          ],
        ),
        MxSection(
          title: l10n.cardDetailTags,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: detail.tags.isEmpty
                  ? Text(
                      l10n.cardDetailNoTags,
                      style: context.textStyles.rowDescription,
                    )
                  : Wrap(
                      spacing: AppSpacing.control,
                      runSpacing: AppSpacing.micro,
                      children: [
                        for (final tag in detail.tags)
                          MxTagChip(label: tag.name),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A label over its value; the value wraps and never truncates.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(label, style: styles.rowDescription),
            Text(value, style: styles.settingsLabel),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_detail_status_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_detail_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// Where the card stands: its status, its scheduler and when it is due
/// (BR-CARD-014). Ruling P4-L7: the date in the current locale.
class CardDetailStatusWidget extends StatelessWidget {
  const CardDetailStatusWidget({super.key, required this.detail});

  final CardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = detail.displayStatus;
    final dueAt = detail.schedule.dueAt;
    return MxSection(
      title: l10n.cardDetailStatus,
      children: [
        MxSettingsRow(
          label: l10n.cardDetailStatus,
          trailing: MxStatusBadge(
            status: mxCardStatus(status),
            label: l10n.cardStatus(status),
          ),
        ),
        MxSettingsRow(
          label: l10n.cardDetailScheduler,
          trailing: Text(l10n.cardScheduler(detail.schedulerType)),
        ),
        MxSettingsRow(
          label: l10n.cardDetailDue,
          trailing: Text(
            dueAt == null
                ? l10n.cardDetailNotLearned
                : DateFormat.yMMMd(locale).format(dueAt.toLocal()),
          ),
        ),
      ],
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_history_section_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/states/card_history_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_detail_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_groups_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The card's answers, newest first, one round per generation, with "Load
/// more" while more follow (BR-CARD-015…018, ruling P4-L5).
class CardHistorySectionWidget extends ConsumerWidget {
  const CardHistorySectionWidget({super.key, required this.cardId});

  final String cardId;

  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cardHistoryProvider(cardId).notifier).loadMore();
    } on Failure catch (failure) {
      if (!context.mounted) return;
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardHistoryProvider(cardId);
    return MxSection(
      title: l10n.cardDetailHistory,
      children: switch (ref.watch(provider)) {
        AsyncData(:final value) when value.entries.isEmpty => [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Text(
              l10n.cardHistoryEmpty,
              style: context.textStyles.rowDescription,
            ),
          ),
        ],
        AsyncData(:final value) => [
          ..._rows(context, l10n, value),
          if (value.hasMore)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.grouped),
              child: MxButton(
                label: l10n.cardHistoryLoadMore,
                tone: MxButtonTone.secondary,
                isBlock: true,
                isLoading: value.isLoadingMore,
                onPressed: value.isLoadingMore
                    ? null
                    : () => unawaited(_loadMore(context, ref)),
              ),
            ),
        ],
        AsyncError() => [
          MxErrorState(
            title: l10n.cardLoadDetailErrorTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(provider),
          ),
        ],
        _ => [const MxSkeletonRow()],
      },
    );
  }

  /// One round header, then its answers.
  List<Widget> _rows(
    BuildContext context,
    AppLocalizations l10n,
    CardHistoryState history,
  ) {
    final when = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();
    return [
      for (final group in cardHistoryGroups(history.entries)) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.grouped,
            AppSpacing.gutter,
            AppSpacing.micro,
          ),
          child: Text(
            l10n.cardHistoryRound(group.generation),
            style: context.textStyles.rowDescription,
          ),
        ),
        for (final entry in group.entries)
          MxListRow(
            title: l10n.cardReviewAction(entry.action),
            subtitle: when.format(entry.answeredAt.toLocal()),
            hasDivider: false,
          ),
      ],
    ];
  }
}
```

`lib/features/card/presentation/screens/card_detail_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_content_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_status_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A card, read-only (spec §6.6, UC-CARD-002): content, tags, status and
/// history. Editing is the app bar's Edit, never the tap (BR-CARD-020).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.cardId,
    required this.onEdit,
  });

  final String cardId;
  final VoidCallback onEdit;

  static const int _skeletonRows = 4;

  /// BR-CARD-019: the card is gone. Say so once and leave (ruling P4-L6).
  void _leaveWhenGone(
    BuildContext context,
    AsyncValue<Outcome<CardDetail, CardRejection>>? previous,
    AsyncValue<Outcome<CardDetail, CardRejection>> next,
  ) {
    if (previous?.value case Rejected()) return;
    if (next.value case Rejected(reason: CardRejection.notFound)) {
      showMxSnackbar(context, message: context.l10n.cardRejectionNotFound);
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(cardId);
    ref.listen(
      provider,
      (previous, next) => _leaveWhenGone(context, previous, next),
    );
    final back = MxIconButton(
      icon: AppIcons.back,
      semanticLabel: l10n.commonBack,
      onPressed: () => unawaited(Navigator.of(context).maybePop()),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => MxAppShell(
        appBar: MxAppBar(
          title: value.card.front,
          density: MxAppBarDensity.content,
          leading: back,
          actions: [
            MxIconButton(
              icon: AppIcons.edit,
              semanticLabel: l10n.cardEdit,
              onPressed: onEdit,
            ),
          ],
        ),
        body: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.gutter),
            CardDetailContentWidget(detail: value),
            CardDetailStatusWidget(detail: value),
            CardHistorySectionWidget(cardId: cardId),
          ],
        ),
      ),
      AsyncError() => MxAppShell(
        appBar: MxAppBar(
          title: l10n.cardLoadDetailErrorTitle,
          density: MxAppBarDensity.content,
          leading: back,
        ),
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadDetailErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      // Loading, or gone and about to leave.
      _ => MxAppShell(
        appBar: MxAppBar(
          title: l10n.cardDetailContent,
          density: MxAppBarDensity.content,
          leading: back,
        ),
        body: MxScreenScroll(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation/card_detail_screen_test.dart
```

Expected: PASS, 5 tests.

- If `MxSection`'s dividers between the history's header and rows look wrong, keep them. The golden in Task 5 is the check. Record any change as a ruling.
- If `flutter.max_build_lines` flags a `build()`, split the `switch` arms into private widgets and record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card detail with its paged review history

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Wire "Add card" and the card routes

**Files:**
- Create: `lib/features/deck/presentation/states/deck_card_selecting_state.dart`, `lib/features/deck/presentation/widgets/overlays/deck_create_sheet_widget.dart`
- Rewrite: `lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`
- Modify:
  - `lib/features/deck/presentation/screens/deck_level_screen.dart`
  - `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
  - `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
  - `test/support/library_harness.dart`
  - `test/features/deck/presentation/open_deck_screen_test.dart`
  - `test/features/card/presentation/card_list_golden_test.dart`
  - `test/features/card/presentation/card_list_section_test.dart`
  - `test/app/library_routes_test.dart`

**Interfaces:**
- Consumes: `CardEditorScreen` (Task 2), `CardDetailScreen` (Task 3), the phase 3 section.
- Produces:
  - `DeckLevelScreen` gains `required ValueChanged<String> onAddCard`, and its `cardContent` becomes `Widget Function(String deckId, ValueChanged<bool> onSelecting)`.
  - `CardListSectionWidget` gains `ValueChanged<bool>? onSelectingChanged`, `VoidCallback? onAddCard` and `ValueChanged<String>? onOpenCard`.
  - `showDeckCreateSheet(BuildContext)` → `Future<DeckCreateOption?>`.
  - `DeckUnsetStateWidget({required bool canNest, required String actionLabel, required VoidCallback? onAction})`.
  - Routes: `AppRoutes.cardIdParam`, `cardNewChild`, `cardChild`, `cardEditChild`, `newCard(deckId)`, `card(cardId)` and `cardEdit(cardId)`.

- [ ] **Step 1: Update the tests**

`test/support/library_harness.dart`: `deckScreen` becomes

```dart
DeckLevelScreen deckScreen({
  String? deckId,
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String?>? onOpenAncestor,
  ValueChanged<String>? onAddCard,
  Widget Function(String deckId, ValueChanged<bool> onSelecting)? cardContent,
}) => DeckLevelScreen(
  deckId: deckId,
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onSearch: () {},
  onAddCard: onAddCard ?? (_) {},
  cardContent: cardContent ?? (_, _) => const SizedBox.shrink(),
);
```

`test/features/card/presentation/card_list_golden_test.dart`: both `cardContent:` arguments become

```dart
            cardContent: (id, onSelecting) => CardListSectionWidget(
              deckId: id,
              onSelectingChanged: onSelecting,
            ),
```

`test/features/deck/presentation/open_deck_screen_test.dart`: the create choice now comes first (ruling P4-L2).

- In `'an empty deck offers a sub-deck; creating one lists it'`, replace the tap on `_en.deckCreateSub` inside `MxEmptyState` with:

  ```dart
      await tester.tap(
        find.descendant(
          of: find.byType(MxEmptyState),
          matching: find.text(_en.deckCreateAny),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.deckCreateSub));
  ```

- In `'the FAB opens the new sub-deck dialog'`, after the FAB tap's `pumpAndSettle()`, add `await tester.tap(find.text(_en.deckCreateSub)); await tester.pumpAndSettle();`.
- Replace `'the deepest deck offers no sub-deck'` with:

  ```dart
    libraryTest('the deepest deck adds cards but no sub-deck', (
      tester,
      env,
    ) async {
      final chain = await _chain(
        env,
        DeckEntity.maxDepth,
        (level) => 'Level $level',
      );
      final added = <String>[];
      await pumpLibraryScreen(
        tester,
        env,
        deckScreen(deckId: chain.last.id, onAddCard: added.add),
      );

      expect(find.text(_en.deckUnsetDeepestBody), findsOneWidget);
      expect(find.text(_en.deckCreateSub), findsNothing);
      await tester.tap(find.byType(MxFab));
      await tester.pump();
      expect(added, [chain.last.id]);
    });
  ```

- In `'a deck of cards shows no deck list yet (ruling P2-L1)'`, rename it to `'a deck of cards shows its card content, not a deck list'`, and change `expect(find.byType(MxFab), findsNothing);` to `expect(find.byType(MxFab), findsOneWidget);`.
- Add:

  ```dart
    libraryTest('an empty deck\'s create choice adds a card', (tester, env) async {
      final korean = await env.decks.root('Korean');
      final words = await env.decks.sub(korean.id, 'Words');
      final added = <String>[];
      await pumpLibraryScreen(
        tester,
        env,
        deckScreen(deckId: words.id, onAddCard: added.add),
      );
      await tester.tap(find.byType(MxFab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.deckAddCard));
      await tester.pumpAndSettle();

      expect(added, [words.id]);
    });
  ```

Append to `test/features/card/presentation/card_list_section_test.dart`, inside `main()`:

```dart
  libraryTest('outside selection a tap opens the card', (tester, env) async {
    final deckId = await _seed(env);
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(deckId: deckId, onOpenCard: opened.add),
      ),
    );
    await tester.tap(find.text('gamsa'));

    expect(opened, ['due1']);
  });

  libraryTest('an empty deck offers Add card', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    var adds = 0;
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(deckId: words.id, onAddCard: () => adds++),
      ),
    );
    await tester.tap(find.text(_en.cardEmptyAction));

    expect(adds, 1);
  });
```

Append to `test/app/library_routes_test.dart`, inside `main()`. Import `package:memox/shared/widgets/mx_button.dart` and `package:memox/shared/widgets/mx_fab.dart`:

```dart
  Future<void> openWords(WidgetTester tester) async {
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
  }

  Future<void> saveCard(WidgetTester tester, String front, String back) async {
    await tester.enterText(find.byType(EditableText).at(0), front);
    await tester.enterText(find.byType(EditableText).at(1), back);
    await _tap(tester, find.widgetWithText(MxButton, _en.cardSave));
  }

  libraryTest('Add card adds cards one after another (RF1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await openWords(tester);
    await _tap(tester, find.byType(MxFab));

    expect(_barTitle(_en.cardAddTitle), findsOneWidget);
    await saveCard(tester, 'bap', 'rice');
    await saveCard(tester, 'mul', 'water');
    await _back(tester);

    for (final front in ['annyeong', 'bap', 'mul']) {
      expect(find.text(front), findsOneWidget);
    }
  });

  libraryTest('a card opens its detail; Edit saves and comes back', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'new1',
      deckId: words.id,
      front: 'annyeong',
      back: 'hello',
    );
    await pumpMemoxApp(tester, env);
    await openWords(tester);
    await _tap(tester, find.text('annyeong'));
    expect(_barTitle('annyeong'), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.cardEdit));
    await tester.enterText(find.byType(EditableText).at(1), 'hi there');
    await _tap(tester, find.widgetWithText(MxButton, _en.cardSave));

    expect(_barTitle('annyeong'), findsOneWidget);
    expect(find.text('hi there'), findsOneWidget);
  });

  libraryTest('an empty deck takes its first card through the create choice', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpMemoxApp(tester, env);
    await openWords(tester);
    await _tap(tester, find.byType(MxFab));
    await _tap(tester, find.text(_en.deckAddCard));
    await saveCard(tester, 'bap', 'rice');
    await _back(tester);

    expect(_barTitle('Words'), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
  });

  libraryTest('the FAB hides while cards are selected (P4-L1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await openWords(tester);
    expect(find.byType(MxFab), findsOneWidget);

    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    expect(find.byType(MxFab), findsNothing);

    await _tap(tester, find.byTooltip(_en.cardSelectionClose));
    expect(find.byType(MxFab), findsOneWidget);
  });
```

(The two helpers sit inside `main()`, before these tests.)

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/open_deck_screen_test.dart test/app/library_routes_test.dart`
Expected: FAIL to compile. `deckScreen` passes `onAddCard`, which `DeckLevelScreen` lacks.

- [ ] **Step 3: Implement**

`lib/features/deck/presentation/states/deck_card_selecting_state.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_card_selecting_state.g.dart';

/// Whether an open deck's card list is selecting, so the deck screen keeps
/// its FAB off the bulk bar. The card section reports it through the
/// `cardContent` builder (ruling P4-L1).
@riverpod
class DeckCardSelecting extends _$DeckCardSelecting {
  @override
  bool build(String deckId) => false;

  void report(bool isSelecting) => state = isSelecting;
}
```

`lib/features/deck/presentation/widgets/overlays/deck_create_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// The choice when a deck may take a sub-deck or a card (spec §6.1). It
/// completes with the choice, or with null when dismissed.
Future<DeckCreateOption?> showDeckCreateSheet(BuildContext context) =>
    showMxBottomSheet<DeckCreateOption>(
      context,
      builder: (_) => const DeckCreateSheetWidget(),
    );

class DeckCreateSheetWidget extends StatelessWidget {
  const DeckCreateSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void choose(DeckCreateOption option) => Navigator.of(context).pop(option);
    return MxBottomSheet(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.folder,
              label: l10n.deckCreateSub,
              onTap: () => choose(DeckCreateOption.deck),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.add,
              label: l10n.deckAddCard,
              onTap: () => choose(DeckCreateOption.card),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart` (whole file):

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// A deck that holds nothing yet (UC-DECK-004). Ruling P4-L2: its one
/// action is the same create choice as the FAB.
class DeckUnsetStateWidget extends StatelessWidget {
  const DeckUnsetStateWidget({
    super.key,
    required this.canNest,
    required this.actionLabel,
    required this.onAction,
  });

  /// False at the deepest level, where no sub-deck fits (BR-DECK-001).
  final bool canNest;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxEmptyState(
      icon: AppIcons.folder,
      title: l10n.deckUnsetTitle,
      body: canNest ? l10n.deckUnsetBody : l10n.deckUnsetDeepestBody,
      actionLabel: onAction == null ? null : actionLabel,
      onAction: onAction,
    );
  }
}
```

**`lib/features/deck/presentation/screens/deck_level_screen.dart`:**
- Import `deck_card_selecting_state.dart` and `deck_create_sheet_widget.dart`.
- `DeckLevelScreen`:
  - add `required this.onAddCard` with the field `final ValueChanged<String> onAddCard;` (doc comment: "Adds a card to a deck (the router opens the editor).");
  - change the `cardContent` field type to `Widget Function(String deckId, ValueChanged<bool> onSelecting)`;
  - pass `onAddCard: onAddCard` to `_OpenDeck`.
- `_OpenDeck` gains the same `onAddCard` field and the new `cardContent` type, and passes both to `_OpenDeckContent`.
- Replace the whole `_OpenDeckContent` class with the class below, and add `_DeckBreadcrumb` after it. The `_openActions` body is unchanged from phase 2.

```dart
/// An open deck: its name, its path, and what it holds (spec §6.1).
class _OpenDeckContent extends ConsumerWidget {
  const _OpenDeckContent({
    required this.view,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.onAddCard,
    required this.cardContent,
  });

  final DeckView view;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;
  final ValueChanged<String> onAddCard;
  final Widget Function(String deckId, ValueChanged<bool> onSelecting)
  cardContent;

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

  /// What "Create" adds here (BR-DECK-012): one option acts at once, two
  /// ask first (spec §6.1).
  Future<void> _create(BuildContext context) async {
    final options = view.createOptions;
    final option = options.length == 1
        ? options.first
        : await showDeckCreateSheet(context);
    if (option == null || !context.mounted) return;
    switch (option) {
      case DeckCreateOption.deck:
        await showCreateSubDeckDialog(context, parentId: view.deck.id);
      case DeckCreateOption.card:
        onAddCard(view.deck.id);
    }
  }

  /// Ruling P4-L1: the card list says when it selects.
  void _reportSelecting(WidgetRef ref, bool isSelecting) => ref
      .read(deckCardSelectingProvider(view.deck.id).notifier)
      .report(isSelecting);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final deck = view.deck;
    final options = view.createOptions;
    final isReordering = ref.watch(deckReorderModeProvider(deck.id));
    final canReorder = ref.watch(deckLevelCanReorderProvider(deck.id));
    final isCardSelecting =
        deck.contentType == DeckContentType.card &&
        ref.watch(deckCardSelectingProvider(deck.id));
    final createLabel = options.length > 1
        ? l10n.deckCreateAny
        : options.contains(DeckCreateOption.card)
        ? l10n.deckAddCard
        : l10n.deckCreateSub;
    void create() => unawaited(_create(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: deck.name,
        density: MxAppBarDensity.content,
        leading: const _BackButton(),
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
      ),
      fab: options.isNotEmpty && !isReordering && !isCardSelecting
          ? MxFab(icon: AppIcons.add, semanticLabel: createLabel, onPressed: create)
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeckBreadcrumb(view: view, onOpenAncestor: onOpenAncestor),
          Expanded(
            child: switch (deck.contentType) {
              DeckContentType.card => cardContent(
                deck.id,
                (isSelecting) => _reportSelecting(ref, isSelecting),
              ),
              DeckContentType.deck || DeckContentType.unset =>
                DeckLevelBodyWidget(
                  parentId: deck.id,
                  onOpenDeck: onOpenDeck,
                  emptyState: DeckUnsetStateWidget(
                    canNest: options.contains(DeckCreateOption.deck),
                    actionLabel: createLabel,
                    onAction: options.isEmpty ? null : create,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

/// Ruling P2-L4: Library › ancestors › this deck.
class _DeckBreadcrumb extends StatelessWidget {
  const _DeckBreadcrumb({required this.view, required this.onOpenAncestor});

  final DeckView view;
  final ValueChanged<String?> onOpenAncestor;

  @override
  Widget build(BuildContext context) => MxBreadcrumb(
    segments: [
      MxBreadcrumbSegment(
        label: context.l10n.navLibrary,
        onTap: () => onOpenAncestor(null),
      ),
      for (final entry in view.breadcrumb)
        MxBreadcrumbSegment(
          label: entry.name,
          onTap: () => onOpenAncestor(entry.id),
        ),
      MxBreadcrumbSegment(label: view.deck.name),
    ],
  );
}
```

**`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`:**

1. Give `CardListSectionWidget` three optional callbacks:

   ```dart
     const CardListSectionWidget({
       super.key,
       required this.deckId,
       this.onSelectingChanged,
       this.onAddCard,
       this.onOpenCard,
     });

     final String deckId;

     /// Told when selection mode starts or ends, so the deck screen can keep
     /// its FAB off the bulk bar (ruling P4-L1).
     final ValueChanged<bool>? onSelectingChanged;

     /// The empty deck's "Add card" (UC-CARD-001 A3).
     final VoidCallback? onAddCard;

     /// A tap outside selection opens the card's detail (BR-CARD-020).
     final ValueChanged<String>? onOpenCard;
   ```

2. In the state, add:

   ```dart
     @override
     void initState() {
       super.initState();
       // A new list starts unselected; a stale report must not hide the FAB.
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) widget.onSelectingChanged?.call(false);
       });
     }
   ```

   Add these lines at the top of `build()`, after `final selected = …`:

   ```dart
       ref.listen(cardSelectionProvider(widget.deckId), (previous, next) {
         final wasSelecting = previous?.isNotEmpty ?? false;
         if (wasSelecting != next.isNotEmpty) {
           widget.onSelectingChanged?.call(next.isNotEmpty);
         }
       });
   ```

3. Pass `onOpen: widget.onOpenCard` and `onAddCard: widget.onAddCard` to `_CardListScroll`. It gains the fields `final ValueChanged<String>? onOpen;` and `final VoidCallback? onAddCard;`, forwards `onAddCard` to `_CardListEmpty`, and its row `onTap` becomes:

   ```dart
                       onTap: isSelecting
                           ? () => onToggle(item.id)
                           : switch (onOpen) {
                               null => null,
                               final open => () => open(item.id),
                             },
   ```

4. `_CardListEmpty` gains `final VoidCallback? onAddCard;`. Its final empty-deck state becomes:

   ```dart
       return MxEmptyState(
         icon: AppIcons.inbox,
         title: l10n.cardEmptyTitle,
         body: l10n.cardEmptyBody,
         actionLabel: onAddCard == null ? null : l10n.cardEmptyAction,
         onAction: onAddCard,
       );
   ```

   Delete its "Ruling P3-L3" comment.

**Routes.** In `lib/app/router/app_routes.dart`, add:

```dart
  /// The path parameter that names a card.
  static const String cardIdParam = 'cardId';

  /// The card routes (library spec §4): the editor under a deck, and the
  /// detail and its editor under [decks].
  static const String cardNewChild = 'cards/new';
  static const String cardChild = 'card/:$cardIdParam';
  static const String cardEditChild = 'edit';

  static String newCard(String deckId) => '${deck(deckId)}/$cardNewChild';

  static String card(String cardId) => '$decks/card/$cardId';

  static String cardEdit(String cardId) => '${card(cardId)}/$cardEditChild';
```

In `lib/app/router/app_router.dart`, import `card_editor_screen.dart` and `card_detail_screen.dart`. Then make these changes.

1. The deck child route gains its card editor:

   ```dart
                   GoRoute(
                     path: AppRoutes.deckChild,
                     builder: (context, state) => _deckLevel(
                       context,
                       deckId: state.pathParameters[AppRoutes.deckIdParam],
                     ),
                     routes: [
                       GoRoute(
                         path: AppRoutes.cardNewChild,
                         builder: (context, state) => CardEditorScreen.create(
                           deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                         ),
                       ),
                     ],
                   ),
   ```

2. Add a sibling of the search route:

   ```dart
                   GoRoute(
                     path: AppRoutes.cardChild,
                     builder: (context, state) {
                       final cardId = state.pathParameters[AppRoutes.cardIdParam]!;
                       return CardDetailScreen(
                         cardId: cardId,
                         onEdit: () => context.push(AppRoutes.cardEdit(cardId)),
                       );
                     },
                     routes: [
                       GoRoute(
                         path: AppRoutes.cardEditChild,
                         builder: (context, state) => CardEditorScreen.edit(
                           cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                         ),
                       ),
                     ],
                   ),
   ```

3. In `_deckLevel`, add `onAddCard: (deckId) => context.push(AppRoutes.newCard(deckId)),`, and make `cardContent`:

   ```dart
         cardContent: (deckId, onSelecting) => CardListSectionWidget(
           deckId: deckId,
           onSelectingChanged: onSelecting,
           onAddCard: () => context.push(AppRoutes.newCard(deckId)),
           onOpenCard: (cardId) => context.push(AppRoutes.card(cardId)),
         ),
   ```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features test/app
```

Expected: PASS. That covers the updated deck tests, 2 new section tests and 4 new route tests. Golden differences (the empty deck's action label, the FAB on a deck of cards) are expected here and regenerated in Task 5.

- If `flutter.max_build_lines` flags `_OpenDeckContent.build`, move the `MxAppBar` into a private `_OpenDeckBar` widget and record a ruling.
- If the FAB is still shown in the first frame after a long-press, because the report arrives in a listener, add one `pump()` in the route test and record a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(app): Add card and card routes; the deck's create choice and FAB rules

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Goldens, register, full gate

**Files:**
- Create: `test/features/card/presentation/card_screens_golden_test.dart` and its goldens
- Regenerate: `library_deck_unset_*`, `card_list_*` and `card_selection_*`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9)

- [ ] **Step 1: Write the golden test**

`test/features/card/presentation/card_screens_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card editor with errors, $theme', (tester, env) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId),
          brightness,
        );
        await tester.enterText(find.byType(EditableText).at(1), 'rice');
        await tester.tap(find.widgetWithText(MxButton, _en.cardSave));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_errors_$theme.png',
        );
      });
    });

    libraryTest('card detail with history, $theme', (tester, env) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(
          front: 'sagwa',
          back: 'apple',
          example: 'An apple a day',
          tagNames: ['fruit', 'food'],
        ),
      );
      for (var i = 0; i < 3; i++) {
        await logAnswer(
          env.db,
          cardId: card.id,
          id: 'a$i',
          at: DateTime(2026, 9, 20 + i, 9, 30),
          action: i.isEven ? 'remembered' : 'forgotten',
        );
      }
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardDetailScreen(cardId: card.id, onEdit: () {}),
          brightness,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await expectBoundaryGolden(
          tester,
          'goldens/card_detail_$theme.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Make and check the goldens**

```bash
flutter test --update-goldens --tags golden test/features/card/presentation test/features/deck/presentation/deck_screens_golden_test.dart
flutter test --tags golden test/features test/app
```

Delete any `failures/` folder. Open the light goldens:
- `card_editor_errors`: "New card" with Back; Front marked Required with "Enter the front." under it; Back filled ("4/240"); example, hint and pronunciation; Tags with its input; the flag row with its toggle; Save at the bottom in the footer.
- `card_detail`: "sagwa" with Edit; the Content section (Front, Back, Example); Tags with two chips; Status (New pill, Eight box, Not learned yet); Review history with "Round 1" and three answers, newest first.
- `library_deck_unset`: the empty card's action now reads "Add to this deck".
- `card_list`: the FAB now shows on the deck of cards. `card_selection`: no FAB.

- [ ] **Step 3: Register the phase**

Append after row 78 of UI-base spec §9:

```markdown
| 79 | A tag typed in the editor's tag input but not submitted with Done is not saved; only chips are | library phase 4 P4-L4 |
| 80 | A review history row shows the answer and its time; the study mode is left out until the study feature owns its labels | library phase 4 P4-L5 |
| 81 | The unset deck state has one action, the create choice, because MxEmptyState carries one; the spec names two actions | library phase 4 P4-L2 |
```

- [ ] **Step 4: Full gate**

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

- [ ] **Step 5: Scope check and commit**

```bash
git add test docs/superpowers
git commit -m "test(card): editor and detail goldens; record Library phase 4 in the UI debt register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected: the diff lists only:
- `docs/superpowers/`
- `lib/l10n/`
- `lib/features/card/presentation/`
- `lib/features/deck/presentation/`
- `lib/app/router/`
- `test/`

Report to the user in Vietnamese:
- Counts and results.
- Every ruling.
- The goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR and merge it. This is the last Library phase.
