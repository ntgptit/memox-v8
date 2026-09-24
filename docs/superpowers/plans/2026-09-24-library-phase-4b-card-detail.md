# Library Phase 4b: Card Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A card row opens the card's read-only detail, following the V3 kit's screen 10:
- the content;
- the current schedule;
- the review history, grouped by cycle and paged 50 at a time.

Its Edit action opens the phase 4a editor on its own route.

**Architecture:**
- **Detail screen.** The card feature gains `CardDetailScreen`, which watches `cardDetailProvider` (phase 4a). Its three sections are content, schedule and history.
- **History.** It comes from `CardHistoryController`, a family `AsyncNotifier` over `LoadCardHistoryPageUseCase`:
  - the first page loads on open, and older pages load on request;
  - a failed page keeps the rows shown, and a late or repeated answer is dropped.
- **Routes (D8).** `app/` adds `/decks/card/:cardId` and `/decks/card/:cardId/edit`, and passes the deck path header and the navigation callbacks.
- **Card list.** A row tap opens the detail unless cards are being selected.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18, Drift 2.35, gen-l10n (en/vi), intl.

**Spec:** `docs/superpowers/specs/2026-09-24-library-screens-design.md` (§4, §5, §6.6, §9, §10 row 4) and the use case `docs/features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md`.
- **Visual authority:** the MemoX Mobile UI Kit v3 (artifact `UCesgHkzYHKsZwhwVshKRE`), screen 10, `CardDetailScreenV3`, with its states loaded, loadMore, loadMoreFailed, empty, error, loading and notFound.
- **Owner decision (2026-09-24):** the kit wins over spec §6.6 where they differ, as in phase 4a (rulings P4b-L1…L9).

## Global Constraints

- **UI only.** No file under `lib/features/*/domain`, `data`, `di` or `lib/core/database` changes (spec §12).
- **Import map:** `card → {deck, srs, tags}` (domain models, entities, failures and di), `deck → {srs}`. `app/` composes; `deck` never imports `card`, and `card` never imports `deck/presentation`.
- **One use case per interaction** (AD-12):
  - the detail reads `cardDetailProvider(cardId)`;
  - the history reads `LoadCardHistoryPageUseCase`.
- **Guard memox-v8 at 0/0:**
  - no raw `IconButton`, `TextButton`, `ListTile`, `Card`, `Checkbox`, `BorderSide`, `RoundedRectangleBorder`, and no `Icon(color:)`;
  - no per-site `textStyles.x.copyWith(`: add a named role to `MxTextStyles` instead;
  - no user-visible string literal;
  - no `ref.read` lexically in `build()`;
  - `build()` within `flutter.max_build_lines`: split into widgets, and build lists in data methods;
  - no defaulted provider or notifier parameter;
  - in the ARB, `placeholders` comes before `description`.
- **Copy:** `app_en.arb` (with `@key`) and `app_vi.arb`. Run `flutter gen-l10n` after ARB edits, and `build_runner` after `@riverpod` edits.
- **Tests** run through the real backend (`libraryTest`, `pumpLibraryScreen`, `pumpMemoxApp`). Goldens are 3x light and dark, generated on Windows, with Latin or romanized text (the golden font has no Hangul).
- Python scripts that write files open them with `newline='\n'`.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings (phase 4b)

| # | Ruling |
|---|---|
| P4b-L1 | **Kit layout wins over spec §6.6.** The detail has:<br>• an app bar with Back, "Card" and an Edit pill;<br>• the deck path;<br>• a content card: front, back, flag, status badge, then only the optional fields that have a value, with their icons, then tags;<br>• a "Current schedule" card: the eight-box ramp or the SM-2 title, and the facts;<br>• "History · newest first", with cycle groups, the events, Load older history, and an end-of-history line. |
| P4b-L2 | **Content and schedule are live; history is read once per visit.** The card's stream updates the content and the schedule, for example after an edit. History pages are read on open and on request. Only studying adds answers, and nothing on this screen studies (BR-CARD-005, BR-CARD-018). |
| P4b-L3 | **Event anatomy.** An event is an `MxCard` holding:<br>• an `MxBadge` "kind · action" in a tone: warning for a lapse (Forgot, Again), neutral for Repeat, primary otherwise;<br>• the absolute date and time;<br>• a meta row with the mode, box / ease / interval before → after, Hint used, Time ran out and Next due.<br><br>Dropped from the kit:<br>• the relative time ("12 days ago"), which needs a live clock and plural copy;<br>• the timeline rail and dots, whose tone the badge already carries;<br>• the "Finished learning" note, because it is derived and BR-CARD-016 shows stored values only. |
| P4b-L4 | **Cycle headers** read "Cycle n · scheduler". The kit's "since reset on 19 Aug" is dropped, because the backend stores no reset date. |
| P4b-L5 | **Gone.** A card deleted while its detail is open, or an id that does not exist, replaces the page with `CardGoneWidget` and Back to deck. The kit's Open Trash is out of scope, because Trash is deferred. |
| P4b-L6 | **History failures.**<br>• If the first page fails, the history section shows `MxErrorState` with Retry, and the content stays.<br>• If an older page fails, the rows stay and a danger `MxInlineBanner` offers Retry from the same cursor (E4).<br>• A late or repeated answer is dropped (E5). |
| P4b-L7 | **Navigation.**<br>• A row tap opens the detail; while cards are selected, it only toggles (BR-CARD-020).<br>• The routes `/decks/card/:cardId` and `/decks/card/:cardId/edit` stay in the Library branch.<br>• The editor's Details link goes back, to the detail. |
| P4b-L8 | **The deck path** over the detail is `DeckContextHeaderWidget(deckId, "Card")`, including its destination line. The kit shows the breadcrumb only; reusing the widget beats a second variant. |
| P4b-L9 | **Mode labels.** The card feature maps the stored mode codes to labels, and an unknown code shows as stored. The study feature, which owns the modes, does not exist yet. |

## Review Focus

1. **A card with more than 50 answers.**
   - Expected: Load older history appends the rest exactly once, even on a double tap (E5), and then the end-of-history line shows (A5).
   - Pinned in Tasks 1 and 3.
2. **An older page that fails to load.**
   - Expected: the rows stay, and Retry goes on from the same cursor rather than from the start (E4).
   - Pinned in Tasks 1 and 3.
3. **A card deleted while its detail is open, or a stale link to a missing card.**
   - Expected: the gone state appears, with no crash and no id shown (E1, E2).
   - Pinned in Task 4.
4. **Back from the detail.**
   - Expected: the card list is exactly as it was left, search term included (UC-CARD-002 step 7).
   - Pinned in Task 4.
5. **Edit from the detail, then save.**
   - Expected: the page returns to the detail, which shows the new content (A1).
   - Pinned in Task 4.

---

### Task 1: History plumbing: page provider, history controller, labels, icons, copy, fixture

**Files:**
- Create:
  - `lib/features/card/presentation/providers/load_card_history_page_use_case_provider.dart`
  - `lib/features/card/presentation/controllers/card_history_controller.dart`
  - `lib/features/card/presentation/widgets/support/card_history_labels_widget.dart`
- Modify:
  - `lib/core/theme/foundations/app_icons.dart`
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
  - `test/support/card_fixtures.dart`
- Test: `test/features/card/presentation/card_history_controller_test.dart`

**Interfaces:**
- Produces:
  - `CardHistoryView({required List<ReviewHistoryEntry> entries, required ReviewHistoryCursor? next, bool isLoadingMore, bool hasMoreFailed})`.
  - `cardHistoryControllerProvider(String cardId)` → `AsyncValue<CardHistoryView>`, and the notifier's `Future<void> loadMore()`.
  - `loadCardHistoryPageUseCaseProvider`.
  - `extension CardHistoryLabels on AppLocalizations`: `cardScheduler(SchedulerType)`, `cardHistoryKind(ReviewKind)`, `cardHistoryAction(Enum)`, `cardHistoryMode(String)`.
  - Icons: `AppIcons.history`, `learned`, `repeat`, `lapses`, `scheduler`, `timeout`, `calendar`.
  - Test fixture: `logReview(AppDatabase db, {required String id, required String cardId, required DateTime at, ...})`.

- [ ] **Step 1: Write the failing tests**

Append to `test/support/card_fixtures.dart`. It already imports `Variable` and `AppDatabase`:

```dart
/// A review_log row as the study flow writes it (BR-CARD-016). The history
/// shows it by [at], newest first. `usedHint` goes with `fill` only and
/// `isTimedOut` with `recall` only (schema invariants 22, 23).
Future<void> logReview(
  AppDatabase db, {
  required String id,
  required String cardId,
  required DateTime at,
  int generation = 1,
  String schedulerType = 'eight_box',
  String kind = 'scheduled',
  String mode = 'recall',
  String action = 'remembered',
  DateTime? nextDueAt,
  int? previousBox,
  int? nextBox,
  double? previousEase,
  double? nextEase,
  int? previousInterval,
  int? nextInterval,
  bool? usedHint,
  bool isTimedOut = false,
}) => db.customInsert(
  'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
  'generation, kind, mode, outcome_reason, used_hint, "action", answered_at, '
  'next_due_at, previous_box, next_box, previous_ease_factor, '
  'next_ease_factor, previous_interval_days, next_interval_days) '
  "VALUES (?, ?, 's', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
  variables: [
    Variable<String>(id),
    Variable<String>(cardId),
    Variable<String>(schedulerType),
    Variable<int>(generation),
    Variable<String>(kind),
    Variable<String>(mode),
    Variable<String>(isTimedOut ? 'timeout' : null),
    Variable<bool>(usedHint),
    Variable<String>(action),
    Variable<DateTime>(at),
    Variable<DateTime>(nextDueAt),
    Variable<int>(previousBox),
    Variable<int>(nextBox),
    Variable<double>(previousEase),
    Variable<double>(nextEase),
    Variable<int>(previousInterval),
    Variable<int>(nextInterval),
  ],
  updates: {db.reviewLog},
);
```

(If the Drift table getter is not `reviewLog`, use the name `app_database.g.dart` gives the `ReviewLog` table.)

`test/features/card/presentation/card_history_controller_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

/// Fails the first request for an older page, then answers as [_cards]
/// does; records every cursor it was asked from.
final class _FlakyHistory implements CardRepository {
  _FlakyHistory(this._cards);

  final CardRepository _cards;
  final afters = <ReviewHistoryCursor?>[];
  var _hasFailed = false;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    afters.add(after);
    if (after != null && !_hasFailed) {
      _hasFailed = true;
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ProviderContainer container([List<Override> overrides = const []]) {
    final created = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
        ...overrides,
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  /// Korean › Words holding card `c`, with [answers] logged a minute apart.
  Future<void> seed(int answers) async {
    final decks = DeckRepositoryImpl(db);
    final words = await decks.sub((await decks.root('Korean')).id, 'Words');
    await insertCard(db, id: 'c', deckId: words.id);
    for (var i = 0; i < answers; i++) {
      await logReview(
        db,
        id: 'r$i',
        cardId: 'c',
        at: DateTime(2026, 9, 1, 8).add(Duration(minutes: i)),
      );
    }
  }

  Future<CardHistoryView> open(ProviderContainer c) {
    c.listen(cardHistoryControllerProvider('c'), (_, _) {});
    return c.read(cardHistoryControllerProvider('c').future);
  }

  CardHistoryController history(ProviderContainer c) =>
      c.read(cardHistoryControllerProvider('c').notifier);

  CardHistoryView shown(ProviderContainer c) =>
      c.read(cardHistoryControllerProvider('c')).requireValue;

  test('the newest 50 first; older answers append once (BR-CARD-015)', () async {
    await seed(ReviewHistoryPage.size + 1);
    final c = container();
    final first = await open(c);

    expect(first.entries, hasLength(ReviewHistoryPage.size));
    expect(first.entries.first.id, 'r50');
    expect(first.next, isNotNull);

    // A double tap asks once (E5).
    await Future.wait([history(c).loadMore(), history(c).loadMore()]);
    expect(shown(c).entries, hasLength(ReviewHistoryPage.size + 1));
    expect(shown(c).entries.last.id, 'r0');
    expect(shown(c).next, isNull);
  });

  test('a failed older page keeps the rows; Retry resumes at the cursor (E4)', () async {
    await seed(ReviewHistoryPage.size + 1);
    final flaky = _FlakyHistory(
      CardRepositoryImpl(db, ScheduleRepositoryImpl(db), TagRepositoryImpl(db)),
    );
    final c = container([
      loadCardHistoryPageUseCaseProvider.overrideWithValue(
        LoadCardHistoryPageUseCase(flaky),
      ),
    ]);
    await open(c);
    await history(c).loadMore();

    expect(shown(c).hasMoreFailed, isTrue);
    expect(shown(c).isLoadingMore, isFalse);
    expect(shown(c).entries, hasLength(ReviewHistoryPage.size));

    await history(c).loadMore();
    expect(shown(c).hasMoreFailed, isFalse);
    expect(shown(c).entries, hasLength(ReviewHistoryPage.size + 1));
    expect(flaky.afters[2], same(flaky.afters[1]));
  });

  test('a card never studied has an empty history (BR-CARD-018)', () async {
    await seed(0);
    final view = await open(container());

    expect(view.entries, isEmpty);
    expect(view.next, isNull);
  });

  test('a card that is gone has an empty history; its detail says why', () async {
    final view = await open(container());

    expect(view.entries, isEmpty);
    expect(view.next, isNull);
  });

  test('the labels name each kind, action and mode; an unknown mode as stored', () {
    final en = lookupAppLocalizations(const Locale('en'));

    expect(en.cardHistoryKind(ReviewKind.relearning), en.cardHistoryKindRelearning);
    expect(en.cardHistoryAction(EightBoxAction.forgotten), en.cardActionForgotten);
    expect(en.cardHistoryAction(Sm2Action.easy), en.cardActionEasy);
    expect(en.cardHistoryMode('self_assess'), en.cardModeSelfAssess);
    expect(en.cardHistoryMode('dictation'), 'dictation');
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_history_controller_test.dart`
Expected: FAIL to compile, because `card_history_controller.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/providers/load_card_history_page_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'load_card_history_page_use_case_provider.g.dart';

@riverpod
LoadCardHistoryPageUseCase loadCardHistoryPageUseCase(Ref ref) =>
    LoadCardHistoryPageUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/card/presentation/controllers/card_history_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_history_controller.g.dart';

/// A card's review history as its detail shows it (UC-CARD-002): the newest
/// page, then older pages on request.
final class CardHistoryView {
  const CardHistoryView({
    required this.entries,
    required this.next,
    this.isLoadingMore = false,
    this.hasMoreFailed = false,
  });

  /// Newest first (BR-CARD-015).
  final List<ReviewHistoryEntry> entries;

  /// Null once the oldest answer is shown (A5).
  final ReviewHistoryCursor? next;
  final bool isLoadingMore;

  /// The last older page failed; what is shown stays (E4).
  final bool hasMoreFailed;

  CardHistoryView copyWith({bool? isLoadingMore, bool? hasMoreFailed}) =>
      CardHistoryView(
        entries: entries,
        next: next,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMoreFailed: hasMoreFailed ?? this.hasMoreFailed,
      );
}

/// Read once per visit (ruling P4b-L2): only studying adds answers, and
/// nothing on the detail studies.
@riverpod
class CardHistoryController extends _$CardHistoryController {
  @override
  Future<CardHistoryView> build(String cardId) async {
    final page = await _page(null);
    return CardHistoryView(
      entries: page?.entries ?? const [],
      next: page?.next,
    );
  }

  /// Null once the card is gone; the detail's own stream says so.
  Future<ReviewHistoryPage?> _page(ReviewHistoryCursor? cursor) async =>
      switch (await ref.read(loadCardHistoryPageUseCaseProvider)(
        cardId: cardId,
        cursor: cursor,
      )) {
        Ok(:final value) => value,
        Rejected() => null,
      };

  /// The page after the last answer shown (UC-CARD-002 step 6). A failure
  /// keeps the rows and a retry resumes at the same cursor (E4); an answer
  /// that arrives late or twice is dropped (E5).
  Future<void> loadMore() async {
    final view = state.value;
    final cursor = view?.next;
    if (view == null || cursor == null || view.isLoadingMore) return;
    state = AsyncData(view.copyWith(isLoadingMore: true, hasMoreFailed: false));
    try {
      final page = await _page(cursor);
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null || !identical(current.next, cursor)) return;
      state = AsyncData(
        CardHistoryView(
          entries: [...current.entries, ...?page?.entries],
          next: page?.next,
        ),
      );
    } on Failure {
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, hasMoreFailed: true),
      );
    }
  }
}
```

`lib/features/card/presentation/widgets/support/card_history_labels_widget.dart`:

```dart
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The stored codes of a card's schedule and history, in the person's words.
extension CardHistoryLabels on AppLocalizations {
  String cardScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => cardSchedulerEightBox,
    SchedulerType.sm2 => cardSchedulerSm2,
  };

  /// BR-CARD-016: the kind as stored, never inferred.
  String cardHistoryKind(ReviewKind kind) => switch (kind) {
    ReviewKind.learning => cardHistoryKindLearning,
    ReviewKind.scheduled => cardHistoryKindScheduled,
    ReviewKind.relearning => cardHistoryKindRelearning,
  };

  /// An `EightBoxAction` or a `Sm2Action`, after the entry's scheduler.
  String cardHistoryAction(Enum action) => switch (action) {
    EightBoxAction.forgotten => cardActionForgotten,
    EightBoxAction.remembered => cardActionRemembered,
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
    _ => action.name,
  };

  /// Ruling P4b-L9: the study feature owns the modes; a code this list does
  /// not know shows as stored.
  String cardHistoryMode(String mode) => switch (mode) {
    'browse' => cardModeBrowse,
    'self_assess' => cardModeSelfAssess,
    'match' => cardModeMatch,
    'guess' => cardModeGuess,
    'recall' => cardModeRecall,
    'fill' => cardModeFill,
    _ => mode,
  };
}
```

**Icons.** In `app_icons.dart`, add after `searchOff`:

```dart
  static const IconData history = Icons.history; // history
  static const IconData learned = Icons.check_circle_outline; // check-circle-2
  static const IconData repeat = Icons.repeat; // repeat
  static const IconData lapses = Icons.replay; // rotate-ccw
  static const IconData scheduler = Icons.autorenew; // refresh-ccw
  static const IconData timeout = Icons.timer_off_outlined; // timer-off
  static const IconData calendar = Icons.event; // calendar
```

**Copy.** Run this script with `python`, then `flutter gen-l10n`:

```python
import json
from pathlib import Path

INT = {"type": "int"}
STRING = {"type": "String"}

KEYS = {
    "cardDetailTitle": ("Card", "Thẻ", "Card detail title, and its breadcrumb segment.", None),
    "cardEditAction": ("Edit", "Sửa", "Card detail app bar action that opens the editor.", None),
    "cardFlaggedLabel": ("Flagged", "Đã gắn cờ", "Accessible name of the flag glyph on a flagged card.", None),
    "cardDetailGoneBody": ("It was deleted while this page was open.", "Thẻ đã bị xoá trong lúc trang này đang mở.", "Body of the card detail's gone state.", None),
    "cardScheduleBox": ("Current schedule · Box {box} of {count}", "Lịch hiện tại · Hộp {box}/{count}", "Overline of the schedule card of an eight-box card.", {"box": INT, "count": INT}),
    "cardScheduleSm2": ("Current schedule · SM-2", "Lịch hiện tại · SM-2", "Overline of the schedule card of an SM-2 card.", None),
    "cardBoxRampStart": ("Box 1 · 1 day", "Hộp 1 · 1 ngày", "Under the box ramp, its first box and interval (BR-SRS-009).", None),
    "cardBoxRampEnd": ("Box 8 · 128 days", "Hộp 8 · 128 ngày", "Under the box ramp, its last box and interval (BR-SRS-009).", None),
    "cardFactDue": ("Due", "Đến hạn", "Schedule fact: the due date.", None),
    "cardFactLearned": ("Learned", "Học xong", "Schedule fact: when learning finished.", None),
    "cardFactLastAnswered": ("Last answered", "Trả lời gần nhất", "Schedule fact: the last answer.", None),
    "cardFactAnswers": ("Answers", "Lượt trả lời", "Schedule fact: answers so far.", None),
    "cardFactLapses": ("Lapses", "Lần quên", "Schedule fact: lapses so far.", None),
    "cardFactScheduler": ("Algorithm", "Thuật toán", "Schedule fact: the scheduler.", None),
    "cardFactSchedulerValue": ("{scheduler} · cycle {generation}", "{scheduler} · chu kỳ {generation}", "The scheduler and its generation.", {"scheduler": STRING, "generation": INT}),
    "cardFactEase": ("Ease", "Độ dễ", "Schedule fact (SM-2): the ease factor.", None),
    "cardFactInterval": ("Interval", "Khoảng cách", "Schedule fact (SM-2): the interval.", None),
    "cardFactIntervalValue": ("{count, plural, =1{1 day} other{{count} days}}", "{count} ngày", "An interval in days.", {"count": INT}),
    "cardFactRepetitions": ("Repetitions", "Số lần lặp", "Schedule fact (SM-2): the repetitions.", None),
    "cardFactNotYet": ("Not yet", "Chưa có", "Schedule fact that has not happened yet.", None),
    "cardSchedulerEightBox": ("Eight boxes", "Tám hộp", "The eight-box scheduler's name.", None),
    "cardSchedulerSm2": ("SM-2", "SM-2", "The SM-2 scheduler's name.", None),
    "cardHistory": ("History", "Lịch sử", "Header of an empty card history.", None),
    "cardHistoryNewestFirst": ("History · newest first", "Lịch sử · mới nhất trước", "Header of a card history with answers.", None),
    "cardHistoryCycle": ("Cycle {generation} · {scheduler}", "Chu kỳ {generation} · {scheduler}", "Header of one scheduler generation in the history (BR-CARD-017).", {"generation": INT, "scheduler": STRING}),
    "cardHistoryEmptyTitle": ("Not studied yet", "Chưa học lần nào", "Empty history title (BR-CARD-018).", None),
    "cardHistoryEmptyBody": ("Every answer in a learning or review session will appear here, newest first.", "Mỗi câu trả lời trong phiên học hoặc ôn sẽ hiện ở đây, mới nhất trước.", "Empty history body.", None),
    "cardHistoryLoadMore": ("Load older history", "Tải lịch sử cũ hơn", "Loads the next page of history.", None),
    "cardHistoryLoadMoreFailedTitle": ("Couldn't load older history.", "Không tải được lịch sử cũ hơn.", "Banner title when an older page fails.", None),
    "cardHistoryLoadMoreFailedBody": ("What is shown is complete up to here.", "Phần đang hiện vẫn đầy đủ tới đây.", "Banner body when an older page fails.", None),
    "cardHistoryEnd": ("Beginning of history · card added {date}", "Đầu lịch sử · thẻ được thêm {date}", "Line after the oldest answer (A5).", {"date": STRING}),
    "cardHistoryLoadErrorTitle": ("Couldn't load the history", "Không tải được lịch sử", "Error state title when the first history page fails.", None),
    "cardHistoryKindLearning": ("Learning", "Đang học", "History kind: learning.", None),
    "cardHistoryKindScheduled": ("Review", "Ôn tập", "History kind: scheduled review.", None),
    "cardHistoryKindRelearning": ("Repeat", "Học lại", "History kind: relearning.", None),
    "cardHistoryEvent": ("{kind} · {action}", "{kind} · {action}", "History badge: the kind, then the action.", {"kind": STRING, "action": STRING}),
    "cardActionForgotten": ("Forgot", "Quên", "History action: forgotten.", None),
    "cardActionRemembered": ("Remembered", "Nhớ", "History action: remembered.", None),
    "cardActionAgain": ("Again", "Lại", "History action (SM-2): again.", None),
    "cardActionHard": ("Hard", "Khó", "History action (SM-2): hard.", None),
    "cardActionGood": ("Good", "Tốt", "History action (SM-2): good.", None),
    "cardActionEasy": ("Easy", "Dễ", "History action (SM-2): easy.", None),
    "cardModeBrowse": ("Browse", "Xem", "Study mode: browse.", None),
    "cardModeSelfAssess": ("Self-assess", "Tự đánh giá", "Study mode: self-assess.", None),
    "cardModeMatch": ("Match", "Ghép", "Study mode: match.", None),
    "cardModeGuess": ("Guess", "Đoán", "Study mode: guess.", None),
    "cardModeRecall": ("Recall", "Nhớ lại", "Study mode: recall.", None),
    "cardModeFill": ("Fill", "Điền", "Study mode: fill.", None),
    "cardHistoryBoxMove": ("Box {from} → {to}", "Hộp {from} → {to}", "History: the box before and after.", {"from": INT, "to": INT}),
    "cardHistoryEaseMove": ("Ease {from} → {to}", "Độ dễ {from} → {to}", "History: the ease before and after, formatted.", {"from": STRING, "to": STRING}),
    "cardHistoryIntervalMove": ("Interval {from}d → {to}d", "Khoảng {from} → {to} ngày", "History: the interval in days before and after.", {"from": INT, "to": INT}),
    "cardHistoryHintUsed": ("Hint used", "Đã dùng gợi ý", "History: a fill answer that used the hint.", None),
    "cardHistoryTimedOut": ("Time ran out", "Hết giờ", "History: a recall answer that timed out.", None),
    "cardHistoryNextDue": ("Next due {date}", "Đến hạn tiếp {date}", "History: the due date the answer set.", {"date": STRING}),
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
    with open(file, "w", encoding="utf-8", newline="\n") as out:
        out.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation/card_history_controller_test.dart
```

Expected: PASS, 5 tests.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): history plumbing: paged history controller, labels, icons, copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The content card and the schedule card

**Files:**
- Create:
  - `lib/features/card/presentation/widgets/sections/card_detail_content_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_schedule_widget.dart`
- Test: `test/features/card/presentation/card_detail_blocks_test.dart`

**Interfaces:**
- Consumes (Task 1): copy keys, icons, `CardHistoryLabels.cardScheduler`.
- Produces:
  - `CardDetailContentWidget({required CardDetail detail})`.
  - `CardScheduleWidget({required CardDetail detail})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_detail_blocks_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_content_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_schedule_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(List<Widget> children) =>
    Scaffold(body: ListView(children: children));

Future<String> _words(
  LibraryEnv env, [
  SchedulerType type = SchedulerType.eightBox,
]) async {
  final korean = await env.decks.root('Korean', type);
  return (await env.decks.sub(korean.id, 'Words')).id;
}

Future<CardDetail> _detail(LibraryEnv env, String cardId) async =>
    (await env.cards.watchDetail(cardId).first)!;

void main() {
  libraryTest('the content shows only the fields that have a value (BR-CARD-014)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(
        front: 'bap',
        back: 'rice',
        example: 'Bap meogeosseoyo?',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );
    final detail = await _detail(env, card.id);
    await pumpLibraryScreen(
      tester,
      env,
      _host([CardDetailContentWidget(detail: detail)]),
    );

    expect(find.text('bap'), findsOneWidget);
    expect(find.text('rice'), findsOneWidget);
    expect(find.text('Bap meogeosseoyo?'), findsOneWidget);
    expect(find.text(_en.cardFieldExample.toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardFieldHint.toUpperCase()), findsNothing);
    expect(find.text('food'), findsOneWidget);
    expect(find.bySemanticsLabel(_en.cardFlaggedLabel), findsOneWidget);
    expect(find.text(_en.cardStatusNew), findsOneWidget);
  });

  libraryTest('an eight-box card shows its box on the ramp and its facts', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await insertCard(
      env.db,
      id: 'c',
      deckId: deckId,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 28),
      box: 3,
    );
    final detail = await _detail(env, 'c');
    await pumpLibraryScreen(tester, env, _host([CardScheduleWidget(detail: detail)]));

    expect(find.text(_en.cardScheduleBox(3, 8).toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardBoxRampStart), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMd('en').format(DateTime(2026, 9, 28))),
      findsOneWidget,
    );
    expect(
      find.text(
        _en.cardFactSchedulerValue(
          _en.cardSchedulerEightBox,
          detail.schedule.generation,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.cardFactEase), findsNothing);
  });

  libraryTest('an SM-2 card shows ease, interval and repetitions, no ramp', (
    tester,
    env,
  ) async {
    final deckId = await _words(env, SchedulerType.sm2);
    await insertCard(
      env.db,
      id: 'c',
      deckId: deckId,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 28),
      intervalDays: 6,
    );
    final detail = await _detail(env, 'c');
    await pumpLibraryScreen(tester, env, _host([CardScheduleWidget(detail: detail)]));

    expect(find.text(_en.cardScheduleSm2.toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardBoxRampStart), findsNothing);
    expect(find.text('2.50'), findsOneWidget);
    expect(find.text(_en.cardFactIntervalValue(6)), findsOneWidget);
    expect(find.text(_en.cardFactRepetitions), findsOneWidget);
  });

  libraryTest('a new card says what has not happened yet', (tester, env) async {
    final deckId = await _words(env);
    await insertCard(env.db, id: 'c', deckId: deckId);
    final detail = await _detail(env, 'c');
    await pumpLibraryScreen(tester, env, _host([CardScheduleWidget(detail: detail)]));

    // Due, learned and last answered.
    expect(find.text(_en.cardFactNotYet), findsNWidgets(3));
  });

  libraryTest('content and schedule hold at 2x and meet the guidelines', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(
        front: 'Tiếng Việt có dấu, một thuật ngữ khá dài',
        back: 'a long meaning that wraps over several lines at 2x',
        pronunciation: 'tiếng việt',
        tagNames: ['từ vựng', 'topik 1'],
      ),
    );
    final detail = await _detail(env, card.id);
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardDetailContentWidget(detail: detail),
        CardScheduleWidget(detail: detail),
      ]),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

If `watchDetail(...).first` does not complete inside the fake async zone, wrap `_detail` in `tester.runAsync`. Record a test-only ruling.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_detail_blocks_test.dart`
Expected: FAIL to compile, because the two widget files do not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_detail_content_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// The card's content (kit 10): front and back, the flag and status, then
/// only the optional fields that have a value (BR-CARD-014), then tags.
class CardDetailContentWidget extends StatelessWidget {
  const CardDetailContentWidget({super.key, required this.detail});

  final CardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final card = detail.card;
    final status = detail.displayStatus;
    final optional = [
      (AppIcons.example, l10n.cardFieldExample, card.example),
      (AppIcons.hint, l10n.cardFieldHint, card.hint),
      (AppIcons.pronunciation, l10n.cardFieldPronunciation, card.pronunciation),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.micro,
                    children: [
                      Text(card.front, style: styles.screenTitle),
                      Text(card.back, style: styles.dialogBody),
                    ],
                  ),
                ),
                if (card.isFlagged)
                  Icon(
                    AppIcons.flagged,
                    size: AppIconSize.inline,
                    semanticLabel: l10n.cardFlaggedLabel,
                  ),
                MxStatusBadge(
                  status: mxCardStatus(status),
                  label: l10n.cardStatus(status),
                ),
              ],
            ),
            for (final (icon, label, value) in optional)
              if (value != null && value.trim().isNotEmpty)
                _OptionalField(icon: icon, label: label, value: value),
            if (detail.tags.isNotEmpty)
              Wrap(
                spacing: AppSpacing.micro,
                runSpacing: AppSpacing.micro,
                children: [
                  for (final tag in detail.tags) MxTagChip(label: tag.name),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.control,
      children: [
        Icon(icon, size: AppIconSize.inline),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.micro,
            children: [
              Text(
                label.toUpperCase(),
                semanticsLabel: label,
                style: styles.overline,
              ),
              Text(value, style: styles.dialogBody),
            ],
          ),
        ),
      ],
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_schedule_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Where the card stands now (kit 10, BR-CARD-014): the eight-box ramp or
/// the SM-2 title, then the facts of the scheduler the card is under.
class CardScheduleWidget extends StatelessWidget {
  const CardScheduleWidget({super.key, required this.detail});

  final CardDetail detail;

  /// BR-SRS-009.
  static const int _boxCount = 8;
  static const String _easePattern = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final box = detail.schedule.currentBox;
    final title = box == null
        ? l10n.cardScheduleSm2
        : l10n.cardScheduleBox(box, _boxCount);
    final facts = _facts(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: styles.overline,
            ),
            if (box != null) ...[
              _BoxRamp(box: box, count: _boxCount),
              Row(
                children: [
                  Text(l10n.cardBoxRampStart, style: styles.counter),
                  const Spacer(),
                  Text(l10n.cardBoxRampEnd, style: styles.counter),
                ],
              ),
            ],
            for (var i = 0; i < facts.length; i += 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.gutter,
                children: [
                  Expanded(child: facts[i]),
                  Expanded(
                    child: i + 1 < facts.length
                        ? facts[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _facts(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final schedule = detail.schedule;
    final number = NumberFormat.decimalPattern(locale).format;
    String date(DateTime? at) => at == null
        ? l10n.cardFactNotYet
        : DateFormat.yMMMd(locale).format(at.toLocal());
    String dateTime(DateTime? at) => at == null
        ? l10n.cardFactNotYet
        : DateFormat.yMMMd(locale).add_Hm().format(at.toLocal());
    return [
      _Fact(icon: AppIcons.clock, label: l10n.cardFactDue, value: date(schedule.dueAt)),
      _Fact(
        icon: AppIcons.learned,
        label: l10n.cardFactLearned,
        value: date(schedule.learnedAt),
      ),
      _Fact(
        icon: AppIcons.history,
        label: l10n.cardFactLastAnswered,
        value: dateTime(schedule.lastAnsweredAt),
      ),
      _Fact(
        icon: AppIcons.repeat,
        label: l10n.cardFactAnswers,
        value: number(schedule.answerCount),
      ),
      _Fact(
        icon: AppIcons.lapses,
        label: l10n.cardFactLapses,
        value: number(schedule.lapseCount),
      ),
      _Fact(
        icon: AppIcons.scheduler,
        label: l10n.cardFactScheduler,
        value: l10n.cardFactSchedulerValue(
          l10n.cardScheduler(detail.schedulerType),
          schedule.generation,
        ),
      ),
      if (schedule.easeFactor case final ease?)
        _Fact(
          icon: AppIcons.progress,
          label: l10n.cardFactEase,
          value: NumberFormat(_easePattern, locale).format(ease),
        ),
      if (schedule.intervalDays case final days?)
        _Fact(
          icon: AppIcons.calendar,
          label: l10n.cardFactInterval,
          value: l10n.cardFactIntervalValue(days),
        ),
      if (schedule.repetitions case final repetitions?)
        _Fact(
          icon: AppIcons.repeat,
          label: l10n.cardFactRepetitions,
          value: number(repetitions),
        ),
    ];
  }
}

/// Eight bars: the boxes behind the card tinted, its box full and taller.
/// The overline above says the same in words, so the ramp is not read out.
class _BoxRamp extends StatelessWidget {
  const _BoxRamp({required this.box, required this.count});

  final int box;
  final int count;

  static const double _barHeight = 6;
  static const double _currentBarHeight = 10;
  static const double _pastAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        spacing: AppSpacing.control,
        children: [
          for (var index = 1; index <= count; index++)
            Expanded(
              child: Container(
                height: index == box ? _currentBarHeight : _barHeight,
                decoration: BoxDecoration(
                  color: switch (index.compareTo(box)) {
                    0 => colors.primary,
                    < 0 => colors.primary.withValues(alpha: _pastAlpha),
                    _ => colors.surfaceContainerHigh,
                  },
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      spacing: AppSpacing.control,
      children: [
        MxIconTile(icon: icon, size: MxIconTileSize.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: styles.rowDescription),
              Text(value, style: styles.rowTitle),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation/card_detail_blocks_test.dart
```

Expected: PASS, 5 tests.

- If a switch pattern on `int` (`< 0`) does not compile, use an `if` chain in a local function. Record a ruling.
- If `MxIconTileSize.small` is not the smallest tile, use the tile the settings rows use.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card detail's content card and schedule card

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The history section

**Files:**
- Create:
  - `lib/features/card/presentation/widgets/items/card_history_event_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_history_section_widget.dart`
- Test: `test/features/card/presentation/card_history_section_test.dart`

**Interfaces:**
- Consumes (Task 1): `cardHistoryControllerProvider`, `CardHistoryView`, `CardHistoryLabels`, `logReview`.
- Produces:
  - `CardHistoryEventWidget({required ReviewHistoryEntry entry})`.
  - `CardHistorySectionWidget({required String cardId, required DateTime addedAt})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_history_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _addedAt = DateTime(2026, 8, 1);

Widget _section() => Scaffold(
  body: ListView(
    children: [CardHistorySectionWidget(cardId: 'c', addedAt: _addedAt)],
  ),
);

/// Korean › Words holding card `c`.
Future<void> _card(LibraryEnv env) async {
  final words = await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
  await insertCard(env.db, id: 'c', deckId: words.id);
}

Future<void> _answers(LibraryEnv env, int count) async {
  for (var i = 0; i < count; i++) {
    await logReview(
      env.db,
      id: 'r$i',
      cardId: 'c',
      at: DateTime(2026, 9, 1, 8).add(Duration(minutes: i)),
    );
  }
}

/// Fails the first older page, then answers as [_cards] does.
final class _FlakyHistory implements CardRepository {
  _FlakyHistory(this._cards);

  final CardRepository _cards;
  var _hasFailed = false;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    if (after != null && !_hasFailed) {
      _hasFailed = true;
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _tapLoadMore(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MxButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a card never studied says so (BR-CARD-018)', (tester, env) async {
    await _card(env);
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistory), findsOneWidget);
    expect(find.text(_en.cardHistoryEmptyTitle), findsOneWidget);
  });

  libraryTest('each answer shows the values its row stored (BR-CARD-016)', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'a',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      mode: 'fill',
      usedHint: true,
      previousBox: 2,
      nextBox: 3,
      nextDueAt: DateTime(2026, 9, 6),
    );
    await logReview(
      env.db,
      id: 'b',
      cardId: 'c',
      at: DateTime(2026, 9, 3, 8),
      kind: 'learning',
      action: 'forgotten',
      isTimedOut: true,
    );
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    expect(find.text(_en.cardHistoryNewestFirst), findsOneWidget);
    expect(
      find.text(
        _en.cardHistoryEvent(
          _en.cardHistoryKindScheduled,
          _en.cardActionRemembered,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        _en.cardHistoryEvent(_en.cardHistoryKindLearning, _en.cardActionForgotten),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.cardModeFill), findsOneWidget);
    expect(find.text(_en.cardHistoryBoxMove(2, 3)), findsOneWidget);
    expect(find.text(_en.cardHistoryHintUsed), findsOneWidget);
    expect(find.text(_en.cardHistoryTimedOut), findsOneWidget);
    expect(
      find.text(
        _en.cardHistoryNextDue(DateFormat.MMMd('en').format(DateTime(2026, 9, 6))),
      ),
      findsOneWidget,
    );
  });

  libraryTest('answers group by cycle, the current one first (BR-CARD-017)', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'new',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      generation: 2,
    );
    await logReview(
      env.db,
      id: 'old',
      cardId: 'c',
      at: DateTime(2026, 4, 6, 20),
      schedulerType: 'sm2',
      mode: 'self_assess',
      action: 'hard',
      previousEase: 2.5,
      nextEase: 2.36,
      previousInterval: 1,
      nextInterval: 6,
    );
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();

    final current = find.text(
      _en.cardHistoryCycle(2, _en.cardSchedulerEightBox).toUpperCase(),
    );
    final earlier = find.text(
      _en.cardHistoryCycle(1, _en.cardSchedulerSm2).toUpperCase(),
    );
    expect(current, findsOneWidget);
    expect(earlier, findsOneWidget);
    expect(tester.getTopLeft(current).dy, lessThan(tester.getTopLeft(earlier).dy));
    expect(find.text(_en.cardHistoryEaseMove('2.50', '2.36')), findsOneWidget);
    expect(find.text(_en.cardHistoryIntervalMove(1, 6)), findsOneWidget);
    expect(find.text(_en.cardModeSelfAssess), findsOneWidget);
  });

  libraryTest('Load older history adds the rest, then the history ends (A5)', (
    tester,
    env,
  ) async {
    await _card(env);
    await _answers(env, ReviewHistoryPage.size + 1);
    await pumpLibraryScreen(tester, env, _section());
    await tester.pumpAndSettle();
    expect(find.byType(CardHistoryEventWidget), findsNWidgets(ReviewHistoryPage.size));

    await _tapLoadMore(tester, _en.cardHistoryLoadMore);

    expect(
      find.byType(CardHistoryEventWidget),
      findsNWidgets(ReviewHistoryPage.size + 1),
    );
    expect(find.widgetWithText(MxButton, _en.cardHistoryLoadMore), findsNothing);
    expect(
      find.text(_en.cardHistoryEnd(DateFormat.yMMMd('en').format(_addedAt))),
      findsOneWidget,
    );
  });

  libraryTest('a failed older page keeps the rows and offers Retry (E4)', (
    tester,
    env,
  ) async {
    await _card(env);
    await _answers(env, ReviewHistoryPage.size + 1);
    await pumpLibraryScreen(
      tester,
      env,
      _section(),
      overrides: [
        loadCardHistoryPageUseCaseProvider.overrideWithValue(
          LoadCardHistoryPageUseCase(_FlakyHistory(env.cards)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await _tapLoadMore(tester, _en.cardHistoryLoadMore);

    expect(find.text(_en.cardHistoryLoadMoreFailedTitle), findsOneWidget);
    expect(find.byType(CardHistoryEventWidget), findsNWidgets(ReviewHistoryPage.size));
    expect(find.textContaining('sqlite'), findsNothing);

    await _tapLoadMore(tester, _en.commonRetry);
    expect(
      find.byType(CardHistoryEventWidget),
      findsNWidgets(ReviewHistoryPage.size + 1),
    );
    expect(find.text(_en.cardHistoryLoadMoreFailedTitle), findsNothing);
  });

  libraryTest('the history holds at 2x and meets the guidelines', (
    tester,
    env,
  ) async {
    await _card(env);
    await logReview(
      env.db,
      id: 'a',
      cardId: 'c',
      at: DateTime(2026, 9, 2, 8),
      mode: 'fill',
      usedHint: true,
      previousBox: 2,
      nextBox: 3,
      nextDueAt: DateTime(2026, 9, 6),
    );
    await pumpLibraryScreen(tester, env, _section(), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_history_section_test.dart`
Expected: FAIL to compile, because the two widget files do not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/items/card_history_event_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// One answer in a card's history (kit 10, ruling P4b-L3): kind and action,
/// when, then the values its row stored (BR-CARD-016).
class CardHistoryEventWidget extends StatelessWidget {
  const CardHistoryEventWidget({super.key, required this.entry});

  final ReviewHistoryEntry entry;

  static const String _easePattern = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final action = entry.action;
    final isLapse =
        action == EightBoxAction.forgotten || action == Sm2Action.again;
    final (tone, icon) = switch (entry.kind) {
      _ when isLapse => (MxBadgeTone.warning, AppIcons.lapses),
      ReviewKind.relearning => (MxBadgeTone.neutral, AppIcons.repeat),
      _ => (MxBadgeTone.primary, AppIcons.check),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.control,
              runSpacing: AppSpacing.micro,
              children: [
                MxBadge(
                  label: l10n.cardHistoryEvent(
                    l10n.cardHistoryKind(entry.kind),
                    l10n.cardHistoryAction(action),
                  ),
                  tone: tone,
                  icon: icon,
                ),
                Text(
                  DateFormat.MMMd(locale).add_Hm().format(
                    entry.answeredAt.toLocal(),
                  ),
                  style: context.textStyles.counter,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.grouped,
              runSpacing: AppSpacing.micro,
              children: [
                for (final (icon, text) in _meta(l10n, locale))
                  _Meta(icon: icon, text: text),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Only what the row stored; before → after only when both are stored.
  List<(IconData, String)> _meta(AppLocalizations l10n, String locale) {
    final ease = NumberFormat(_easePattern, locale).format;
    return [
      (AppIcons.library, l10n.cardHistoryMode(entry.mode)),
      if ((entry.previousBox, entry.nextBox) case (final from?, final to?))
        (AppIcons.progress, l10n.cardHistoryBoxMove(from, to)),
      if ((entry.previousEaseFactor, entry.nextEaseFactor)
          case (final from?, final to?))
        (AppIcons.progress, l10n.cardHistoryEaseMove(ease(from), ease(to))),
      if ((entry.previousIntervalDays, entry.nextIntervalDays)
          case (final from?, final to?))
        (AppIcons.calendar, l10n.cardHistoryIntervalMove(from, to)),
      if (entry.usedHint ?? false) (AppIcons.hint, l10n.cardHistoryHintUsed),
      if (entry.isTimedOut) (AppIcons.timeout, l10n.cardHistoryTimedOut),
      if (entry.nextDueAt case final due?)
        (
          AppIcons.calendar,
          l10n.cardHistoryNextDue(DateFormat.MMMd(locale).format(due.toLocal())),
        ),
    ];
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.micro,
    children: [
      Icon(icon, size: AppIconSize.inline),
      Flexible(child: Text(text, style: context.textStyles.rowDescription)),
    ],
  );
}
```

`lib/features/card/presentation/widgets/sections/card_history_section_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A card's review history (UC-CARD-002, kit 10): newest first, grouped by
/// cycle (BR-CARD-017), with older pages on request and a line where it
/// begins (rulings P4b-L3, P4b-L6).
class CardHistorySectionWidget extends ConsumerWidget {
  const CardHistorySectionWidget({
    super.key,
    required this.cardId,
    required this.addedAt,
  });

  final String cardId;

  /// When the card was made: the end-of-history line names it.
  final DateTime addedAt;

  static const int _skeletonRows = 3;

  void _loadMore(WidgetRef ref) => unawaited(
    ref.read(cardHistoryControllerProvider(cardId).notifier).loadMore(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardHistoryControllerProvider(cardId);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _history(context, value, () => _loadMore(ref)),
      ),
      AsyncError() => MxErrorState(
        title: l10n.cardHistoryLoadErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => Column(
        children: [
          for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      ),
    };
  }

  List<Widget> _history(
    BuildContext context,
    CardHistoryView view,
    VoidCallback onLoadMore,
  ) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final entries = view.entries;
    if (entries.isEmpty) {
      return [
        MxListSectionHeader(label: l10n.cardHistory),
        MxEmptyState(
          icon: AppIcons.history,
          title: l10n.cardHistoryEmptyTitle,
          body: l10n.cardHistoryEmptyBody,
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
        ),
      ];
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return [
      MxListSectionHeader(label: l10n.cardHistoryNewestFirst),
      for (final (index, entry) in entries.indexed) ...[
        if (index == 0 || entries[index - 1].generation != entry.generation)
          _CycleHeader(
            label: l10n.cardHistoryCycle(
              entry.generation,
              l10n.cardScheduler(entry.schedulerType),
            ),
          ),
        CardHistoryEventWidget(entry: entry),
      ],
      if (view.hasMoreFailed)
        MxInlineBanner(
          tone: MxBannerTone.danger,
          title: l10n.cardHistoryLoadMoreFailedTitle,
          message: l10n.cardHistoryLoadMoreFailedBody,
          actions: [
            MxButton(
              label: l10n.commonRetry,
              size: MxButtonSize.compact,
              onPressed: onLoadMore,
            ),
          ],
        )
      else if (view.next != null)
        MxButton(
          label: l10n.cardHistoryLoadMore,
          tone: MxButtonTone.secondary,
          isBlock: true,
          isLoading: view.isLoadingMore,
          onPressed: onLoadMore,
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.control),
          child: Text(
            l10n.cardHistoryEnd(DateFormat.yMMMd(locale).format(addedAt.toLocal())),
            textAlign: TextAlign.center,
            style: styles.noteText,
          ),
        ),
    ];
  }
}

/// "Cycle n · scheduler" over one generation's answers (ruling P4b-L4).
class _CycleHeader extends StatelessWidget {
  const _CycleHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.micro,
      AppSpacing.control,
      AppSpacing.micro,
      AppSpacing.control,
    ),
    child: Text(
      label.toUpperCase(),
      semanticsLabel: label,
      style: context.textStyles.overline,
    ),
  );
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation/card_history_section_test.dart
```

Expected: PASS, 6 tests.

- If `MxBadge` has no `icon` parameter of that name, use the name `MxBadge` declares for its 12 glyph.
- If `MxInlineBanner` lays out `actions` differently from the kit's trailing Retry, keep the shared widget's layout (ruling O6).

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card history: cycles, stored values, older pages, failures kept in place

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The detail screen, its routes, and the row tap

**Files:**
- Create: `lib/features/card/presentation/screens/card_detail_screen.dart`
- Modify:
  - `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
  - `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Test:
  - `test/features/card/presentation/card_detail_screen_test.dart` (create)
  - `test/features/card/presentation/card_list_section_test.dart` (extend; update the host)
  - `test/app/library_routes_test.dart` (extend)
  - host updates in `card_bulk_actions_test.dart`, `card_selection_test.dart`, `card_list_golden_test.dart`

**Interfaces:**
- Consumes:
  - Tasks 2–3: `CardDetailContentWidget`, `CardScheduleWidget`, `CardHistorySectionWidget`.
  - Phase 4a: `cardDetailProvider`, `CardGoneWidget`, `CardEditorScreen.edit`, `DeckContextHeaderWidget`.
- Produces:
  - `CardDetailScreen({required String cardId, required Widget Function(String deckId, String currentLabel) deckContext, required ValueChanged<String> onEdit})`.
  - `CardListSectionWidget` gains `required ValueChanged<String> onOpenCard`.
  - `AppRoutes`: `cardIdParam`, `cardChild`, `cardEditChild`, `card(String cardId)`, `editCard(String cardId)`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

CardDetailScreen _screen(String cardId, {ValueChanged<String>? onEdit}) =>
    CardDetailScreen(
      cardId: cardId,
      deckContext: (deckId, label) =>
          DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
      onEdit: onEdit ?? (_) {},
    );

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

/// A read that fails the first way a real database can.
final class _BrokenCards implements CardRepository {
  @override
  Stream<CardDetail?> watchDetail(String cardId) =>
      Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('the detail shows the card under its path; Edit asks for it', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(
      await _words(env),
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final edits = <String>[];
    await pumpLibraryScreen(tester, env, _screen(card.id, onEdit: edits.add));
    await tester.pumpAndSettle();

    expect(_barTitle(_en.cardDetailTitle), findsOneWidget);
    expect(
      find.descendant(of: find.byType(MxBreadcrumb), matching: find.text('Words')),
      findsOneWidget,
    );
    expect(find.text('bap'), findsOneWidget);
    expect(find.text(_en.cardScheduleBox(1, 8).toUpperCase()), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.cardEditAction));
    expect(edits, [card.id]);
  });

  libraryTest('a card deleted while open shows it is gone (E2)', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(await _words(env));
    await pumpLibraryScreen(tester, env, _screen(card.id));
    await tester.pumpAndSettle();
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pumpAndSettle();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.text(_en.cardDetailGoneBody), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.cardEditAction), findsNothing);
  });

  libraryTest('a link to a card that does not exist shows it is gone (E1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen('missing'));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.textContaining('missing'), findsNothing);
  });

  libraryTest('a failed read offers Retry and hides the cause (E3)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen('c'),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_BrokenCards()),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(_en.cardLoadErrorEditTitle), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('the detail holds Vietnamese at 2x and meets the guidelines', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(
      await _words(env),
      const CardDraft(
        front: 'Tiếng Việt có dấu, một thuật ngữ khá dài',
        back: 'nghĩa',
      ),
    );
    await pumpLibraryScreen(tester, env, _screen(card.id), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

In `test/features/card/presentation/card_list_section_test.dart`, the `_section` host becomes `Scaffold(body: CardListSectionWidget(deckId: deckId, onAddCard: () {}, onOpenCard: (_) {}))`. Inside the phase 4a FAB test, the `cardContent` lambda gains `onOpenCard: (_) {}`. Then append inside `main()`:

```dart
  libraryTest('a tap opens the card; while selecting it only toggles (BR-CARD-020)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(
          deckId: deckId,
          onAddCard: () {},
          onOpenCard: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CardRowWidget).first);
    expect(opened, hasLength(1));

    await tester.longPress(find.byType(CardRowWidget).last);
    await tester.pump();
    await tester.tap(find.byType(CardRowWidget).first);
    await tester.pump();
    expect(opened, hasLength(1));
  });
```

In `card_bulk_actions_test.dart` and `card_selection_test.dart`, the host becomes `CardListSectionWidget(deckId: deckId, onAddCard: () {}, onOpenCard: (_) {})`. In `card_list_golden_test.dart`, both `cardContent` lambdas gain `onOpenCard: (_) {}`.

Append inside `main()` of `test/app/library_routes_test.dart`. Import `package:memox/features/card/presentation/widgets/items/card_row_widget.dart`:

```dart
  libraryTest('a row opens its card; Back returns to the list as it was', (
    tester,
    env,
  ) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap', back: 'rice');
    await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul', back: 'water');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await tester.enterText(find.byType(EditableText), 'bap');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(of: find.byType(CardRowWidget), matching: find.text('bap')),
    );
    expect(_barTitle(_en.cardDetailTitle), findsOneWidget);

    await _back(tester);
    expect(_barTitle('Words'), findsOneWidget);
    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'bap',
    );
  });

  libraryTest('Edit from the detail saves and returns to it (UC-CARD-002 A1)', (
    tester,
    env,
  ) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap', back: 'rice');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await _tap(tester, find.text('bap'));
    await _tap(tester, find.widgetWithText(MxButton, _en.cardEditAction));
    expect(_barTitle(_en.cardEditTitle), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    await _tap(tester, find.widgetWithText(MxButton, _en.cardSaveChanges));

    expect(_barTitle(_en.cardDetailTitle), findsOneWidget);
    expect(find.text('cooked rice'), findsOneWidget);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_detail_screen_test.dart test/features/card/presentation/card_list_section_test.dart test/app/library_routes_test.dart`
Expected: FAIL to compile, because `card_detail_screen.dart` does not exist and `CardListSectionWidget` has no `onOpenCard`.

- [ ] **Step 3: Implement**

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
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_section_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_schedule_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A card, read-only (UC-CARD-002, spec §6.6, kit 10): content, schedule and
/// history under the deck path `app/` passes in. Editing is the explicit
/// Edit action, never the tap (BR-CARD-020).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.cardId,
    required this.deckContext,
    required this.onEdit,
  });

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// Edit for [cardId]: the router opens the editor.
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(cardDetailProvider(cardId));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.cardDetailTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (detail case AsyncData(value: Ok()))
            MxButton(
              label: l10n.cardEditAction,
              icon: AppIcons.edit,
              size: MxButtonSize.compact,
              tone: MxButtonTone.secondary,
              onPressed: () => onEdit(cardId),
            ),
        ],
      ),
      body: _DetailBody(
        cardId: cardId,
        detail: detail,
        deckContext: deckContext,
      ),
    );
  }
}

/// The page while the card loads, fails, is gone, or shows (ruling P4b-L5).
class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.cardId,
    required this.detail,
    required this.deckContext,
  });

  final String cardId;
  final AsyncValue<Outcome<CardDetail, CardRejection>> detail;
  final Widget Function(String deckId, String currentLabel) deckContext;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (detail) {
      AsyncData(value: Ok(:final value)) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          deckContext(value.card.deckId, l10n.cardDetailTitle),
          Expanded(
            child: MxScreenScroll(
              children: [
                const SizedBox(height: AppSpacing.control),
                CardDetailContentWidget(detail: value),
                CardScheduleWidget(detail: value),
                CardHistorySectionWidget(
                  cardId: cardId,
                  addedAt: value.card.createdAt,
                ),
              ],
            ),
          ),
        ],
      ),
      AsyncData(value: Rejected()) => CardGoneWidget(
        title: l10n.cardGoneTitle,
        body: l10n.cardDetailGoneBody,
        onBack: () => unawaited(Navigator.of(context).maybePop()),
      ),
      AsyncError() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.cardLoadErrorEditTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(cardDetailProvider(cardId)),
          ),
        ],
      ),
      _ => MxScreenScroll(
        children: [
          for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      ),
    };
  }
}
```

**Card list section.** In `card_list_section_widget.dart`:
- `CardListSectionWidget` gains `required this.onOpenCard` and this field:

```dart
  /// A row tap outside selection: the router opens the card's detail.
  final ValueChanged<String> onOpenCard;
```

- Thread it into `_CardListScroll` (`required this.onOpenCard`, `final ValueChanged<String> onOpenCard;`, passing `onOpenCard: widget.onOpenCard`).
- In `_CardListScroll.build`, replace the row's `onTap:` and its comment:

```dart
                    // BR-CARD-020: a tap opens the card; while selecting it
                    // only toggles.
                    onTap: isSelecting
                        ? () => onToggle(item.id)
                        : () => onOpenCard(item.id),
```

**Routes.** In `app_routes.dart`, add after `cardNewChild`:

```dart
  /// The path parameter that names a card.
  static const String cardIdParam = 'cardId';

  /// A card's detail, relative to [decks], and its editor, relative to it.
  static const String cardChild = 'card/:$cardIdParam';
  static const String cardEditChild = 'edit';
```

And add after `newCard(...)`:

```dart
  /// A card's detail.
  static String card(String cardId) => '$decks/card/$cardId';

  /// The card editor for [cardId].
  static String editCard(String cardId) => '${card(cardId)}/$cardEditChild';
```

In `app_router.dart`, import `card_detail_screen.dart`. After the search `GoRoute` in the Library routes, add:

```dart
                GoRoute(
                  path: AppRoutes.cardChild,
                  builder: (context, state) => CardDetailScreen(
                    cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                    deckContext: _deckContext,
                    onEdit: (id) =>
                        unawaited(context.push(AppRoutes.editCard(id))),
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.cardEditChild,
                      builder: (context, state) => CardEditorScreen.edit(
                        cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                        deckContext: _deckContext,
                      ),
                    ),
                  ],
                ),
```

In `_deckLevel`, the `cardContent` lambda becomes:

```dart
    cardContent: (id) => CardListSectionWidget(
      deckId: id,
      onAddCard: () => addCard(id),
      onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
    ),
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card test/features/deck test/app --exclude-tags golden
```

Expected: PASS, including the 5 detail screen tests, the new list test and the 2 new route tests.

- If `max_build_lines` flags `CardDetailScreen.build`, move the app bar into a `_DetailAppBar` widget. Record a ruling.
- If the route test's Back finds two back buttons, keep `_back` (the detail sits over the list). If the tooltip is ambiguous, scope it to the top `MxAppBar`. Record a test-only ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card detail screen, its routes, and the row tap

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Goldens, the deviation register, the full gate

**Files:**
- Create: `test/features/card/presentation/card_detail_golden_test.dart`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 register)

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces:
  - goldens `card_detail_top_*` and `card_detail_history_*`;
  - register rows 85–88, and closing notes on rows 77 and 83.

- [ ] **Step 1: Write the goldens**

`test/features/card/presentation/card_detail_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

/// Korean › Words holding a reviewed, flagged card with a two-cycle history.
/// Romanized text: the golden font has no Hangul.
Future<void> _seed(LibraryEnv env) async {
  final words = await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
  await insertCard(
    env.db,
    id: 'c',
    deckId: words.id,
    front: 'gamsahamnida',
    back: 'thank you',
    isFlagged: true,
    learnedAt: DateTime(2026, 8, 20),
    dueAt: DateTime(2026, 9, 26),
    box: 5,
  );
  final answers = [
    (DateTime(2026, 9, 4, 19), 'recall', 4, 5, DateTime(2026, 9, 20)),
    (DateTime(2026, 8, 27, 20), 'fill', 3, 4, DateTime(2026, 9, 4)),
    (DateTime(2026, 8, 23, 18), 'guess', 2, 3, DateTime(2026, 8, 27)),
  ];
  for (final (index, (at, mode, from, to, due)) in answers.indexed) {
    await logReview(
      env.db,
      id: 'g2-$index',
      cardId: 'c',
      at: at,
      generation: 2,
      mode: mode,
      previousBox: from,
      nextBox: to,
      nextDueAt: due,
      usedHint: mode == 'fill' ? true : null,
    );
  }
  await logReview(
    env.db,
    id: 'g1',
    cardId: 'c',
    at: DateTime(2026, 4, 6, 20),
    schedulerType: 'sm2',
    mode: 'self_assess',
    action: 'again',
    previousEase: 2.5,
    nextEase: 2.3,
    previousInterval: 6,
    nextInterval: 1,
  );
}

CardDetailScreen _screen() => CardDetailScreen(
  cardId: 'c',
  deckContext: (deckId, label) =>
      DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
  onEdit: (_) {},
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card detail, top, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/card_detail_top_$theme.png');
      });
    });

    libraryTest('card detail, history, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_detail_history_$theme.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Generate the goldens (Windows) and look at them**

```bash
flutter test --update-goldens --tags golden test/features/card/presentation/card_detail_golden_test.dart
```

Expected: 4 golden files written. Open each and check it against kit 10:
- **Top:** the app bar with Back, "Card" and the Edit pill; the path ending in "Card"; the content card with the flag glyph and the Reviewing badge; the "CURRENT SCHEDULE · BOX 5 OF 8" ramp with box 5 tall and boxes 1–4 tinted; the facts in two columns.
- **History:** "History · newest first"; "CYCLE 2 · EIGHT BOXES" over three events (badges, times, the mode, the box moves, Hint used on the fill answer, Next due); "CYCLE 1 · SM-2" with an Again event in the warning tone and its ease and interval moves; the end-of-history line.

Fix what the pictures show, then regenerate. One round.

- [ ] **Step 3: Record the deviations**

Append these rows to the §9 register table of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`, after row 84:

```markdown
| 85 | The card detail follows the V3 kit (10) over library spec §6.6: a schedule card with the eight-box ramp or the SM-2 facts, history grouped by cycle, Load older history, and an end-of-history line | library phase 4b P4b-L1 |
| 86 | History events show the absolute date and time only, with no timeline rail or dots and no "Finished learning" note; cycle headers carry no reset date, which the backend does not store | library phase 4b P4b-L3, P4b-L4 |
| 87 | The card detail's gone state offers Back to deck only; Open Trash waits for Trash | library phase 4b P4b-L5 |
| 88 | The card detail's deck path includes the destination line of the editor's header, which the kit's detail does not show | library phase 4b P4b-L8 |
```

Append ` — row tap closed by library phase 4b` to the first cell of row 77, and ` — closed by library phase 4b` to the first cell of row 83.

- [ ] **Step 4: Run the full gate**

```bash
dart format --set-exit-if-changed lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test
python tools/docs/check.py
GUARD_PY=python bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- format clean; analyze "No issues found!";
- guard 0 errors / 0 warnings; architecture OK;
- every test passes, goldens included;
- the docs check passes; DoD passes.

**Scope check.** Run `git diff --stat $(git merge-base origin/master HEAD) -- lib/features/*/domain lib/features/*/data lib/features/*/di lib/core/database`. It must print nothing (UI only).

- [ ] **Step 5: Commit**

```bash
git add test docs
git commit -m "test(card): card detail goldens; register phase 4b deviations

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
