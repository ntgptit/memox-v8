# Study UI P1: shell, entry, browse, summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A learner can open a deck's Study entry, continue an already-open same-day
session, browse its cards, and land on the session summary — the whole shell working
end to end for the one mode this phase builds. Screens 14 (Study entry, minus the
direction sheet), 16 (Browse) and 21 (Session summary) are usable; `dod_check.sh` and
the goldens stay green.

**Architecture:**
- **One session route, one screen.** `StudySessionScreen` watches
  `WatchStudySessionUseCase(sessionId)` and picks its body with an exhaustive `switch`
  over `StudyMode` plus the summary once `summary != null` (spec D3). The summary is
  never a second route (spec D2) — the same screen re-renders once the stream reports
  the session has ended.
- **One controller, one in-flight lock.** `StudySessionController` (`@riverpod`) is the
  session's one write path: `answer` and `abandon` in P1, both behind a private
  in-flight flag so a second tap while a write runs is dropped, not queued (spec D4,
  BR-STUDY-004). Mode widgets never call a use case directly.
- **The feedback hold is a mixin, not a provider.** `StudyTurnHoldMixin` keeps the
  answered item and its result on a mode body's `State` until the mode's continue
  condition fires (spec D5). It is pure UI state — nothing in it writes.
- **The built-modes gate is a pure function pair,** `isLearningBuilt` /
  `isReviewBuilt`, over the constant `builtStudyModes = {StudyMode.browse}` (spec §3).
  Study Entry's Learn and Review actions ask these, never a hand-maintained flag.
- **Layout follows the Library pattern** (spec D13):
  `lib/features/study/presentation/{providers,controllers,screens,widgets/{sections,items,support}}`;
  one `@riverpod` provider per use case; `app/` composes and routes (spec A14), the
  same way `onOpenAlgorithm` is threaded today.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18,
Drift 2.35, gen-l10n (en/vi), intl.

**Spec:** `docs/superpowers/specs/2026-09-26-study-ui-design.md` (P1 row of §3, decisions
D1–D13), `docs/shared/ui/screen-handoff/14-study-entry.md`,
`16-study-browse.md`, `21-session-summary.md`, `07-card-list.md`;
`docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md`;
`docs/features/study/it-scenarios.md`.

## Global Constraints

- **UI and presentation-layer wiring only**, except the two additive fields spec D11a
  asks for on `SessionSummary` (Task 1) — no other change under
  `lib/features/*/domain`, `data` or `lib/core/database`.
- **Import map:** `study → {deck, srs, card, study_mode, settings}` (already true of the
  domain layer this phase reads); `study/presentation` never imports `deck/presentation`
  the other way — `app/` composes both, exactly as it already does for `card` and
  `deck`.
- **One use case per interaction** (AD-12): `StudySessionController.answer` calls only
  `AnswerStudyTurnUseCase`; `.abandon` only `AbandonStudySessionUseCase`. Reveal, recall
  time and fill hint are **not** added to the controller in P1 — nothing in this phase
  calls them, and an unused method is dead code; P4 adds them with the modes that need
  them.
- **Guard `memox-v8` at 0/0:** no raw `IconButton`, `TextButton`, `ListTile`, `Card`,
  `Checkbox`, `BorderSide`, `RoundedRectangleBorder`, no `Icon(color:)`; no per-site
  `textStyles.x.copyWith(`; no user-visible string literal; no `ref.read` lexically in
  `build()`; `build()` within `flutter.max_build_lines`; no defaulted provider or
  notifier parameter; ARB `placeholders` before `description`.
- **Copy:** `app_en.arb` (with `@key`) and `app_vi.arb`. Run `flutter gen-l10n` after
  ARB edits, `dart run build_runner build --delete-conflicting-outputs` after
  `@riverpod` edits. Reuse an existing key before adding one — `cardModeBrowse` and its
  siblings (added for the card history, `card_history_labels_widget.dart`) name the
  modes already; the session top bar reuses them instead of a second `studyMode*` set.
- **Tests** run through the real backend (`libraryTest`, `pumpLibraryScreen`,
  `pumpMemoxApp`) and the study fixtures (`test/support/study_fixtures.dart`). Because
  P1 builds only `browse`, a session that must reach `completed` or show a graded
  summary is seeded directly at the row level (new fixtures `insertSession` /
  `insertQueueItem`, Task 1) rather than through `OpenLearningSessionUseCase`, which
  always builds a scheduler's **whole** stage chain (BR-MODE-004) — a chain P1 cannot
  run past its first stage. This is exactly what spec §3 means by "P1 starts no session
  from the UI: its screens are exercised by tests that open sessions through the study
  fixtures/use cases."
- **Test commands on this Windows host are always**
  `flutter test --exclude-tags golden <paths>`. Golden steps say "generate in the Linux
  container (`golden.Dockerfile`), never `--update-goldens` on Windows."
- **WBS and the screen handoff index are out of scope.** `docs/wbs_FE.md` and
  `docs/shared/ui/screen-handoff/00-index.md` rows 14, 16 and 21 stay "not built" —
  P5 flips them once the IT set closes (spec §3, P5 row).
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

### Exit confirmation (owner ruling, 2026-09-27)

`IT-NAV-010` and `IT-CONT-004` describe a confirm step on the ✕, the kit has none, and
no BR/UC requires one. The owner chose the confirm (spec D8, amended). The ✕ and the
system Back both open `showStudyExitDialog`; "Keep studying" leaves the session
`in_progress` on the same card; "Stop" calls `StudySessionController.abandon()` and the
same route shows the summary's Left early state. Handoff 16 records the deviation.

## Review Focus

1. **`AnswerStudyTurnUseCase`'s two failure paths.** A `DatabaseLockedFailure` must
   show an inline error on the same card, with the answer retryable and nothing
   advanced (UC-STUDY-001 E2). Any other `Failure` has already force-failed the
   session server-side (`AnswerStudyTurnUseCase._close`); the shell must not also try
   to recover the turn — it must let the next stream emission show the `saveError`
   summary (E3). — **Pinned in Task 6.**
2. **The exit contract.** The ✕ icon and the Android predictive-back gesture must
   reach the identical code path — the same confirm dialog; Keep studying writes
   nothing, Stop abandons once with committed turns kept — never two implementations
   that drift (D8, owner ruling above). — **Pinned in Task 6.**
3. **A session that stops being writable mid-turn.** The root's generation moved
   underneath it (`staleGeneration`, D6/D7, UC-STUDY-001 E4) or its deck was hard-deleted
   (`notFound`, A5, `IT-CONT-007`) — both must pop to the deck list with a message and
   record nothing for the attempted turn, never render as if the session were still
   running. — **Pinned in Task 6.**
4. **`SessionSummary`'s two new counts must be independent of each other and of the
   three existing ones.** A card that was only ever browsed (no turn recorded yet)
   must not inflate `answeredCardCount`; a card answered twice in one session (a
   relearning comeback) must count once in `answeredCardCount` but twice in
   `turnCount`. — **Pinned in Task 1.**
5. **The stale-session sweep's ordering.** It must finish before the first frame that
   could offer a resumable session, or a session left `in_progress` from an earlier
   local day briefly shows as "Continue" before flipping to gone (spec D9,
   BR-STUDY-072). — **Pinned in Task 4, exercised again from the entry screen's own
   data in Task 5.**

---

### Task 1: `SessionSummary` gains `answeredCardCount` and `turnCount` (spec D11a)

**Files:**
- Modify: `lib/features/study/domain/models/study_session_view_model.dart`
- Modify: `lib/features/study/data/datasources/study_view_dao.dart`
- Modify: `lib/features/study/data/mappers/study_session_view_mapper.dart`
- Modify: `test/support/study_fixtures.dart` (new fixtures `insertSession`,
  `insertQueueItem`, reused by Tasks 4, 6 and 7)
- Test: `test/features/study/data/study_session_summary_test.dart`

**Interfaces:**
- Produces: `SessionSummary.answeredCardCount` (distinct cards with at least one
  `review_log` row in the session), `SessionSummary.turnCount` (every `review_log` row
  of the session, including relearning comebacks) — the numbers behind handoff 21's
  "Cards answered" and "of {total} turns" facts.
- Consumes: `StudyViewDao.summaryCounts`, `studySessionViewOf`
  (`study_session_view_mapper.dart`).

**Field definitions (exact):**
- `answeredCardCount = COUNT(DISTINCT review_log.card_id) WHERE review_log.session_id = :id`
- `turnCount = COUNT(*) FROM review_log WHERE review_log.session_id = :id`

Both are independent of `cardCount` (the queue's distinct cards, whether answered or
not) and of `wrongTurnCount` (turns whose action was a lapse). A card the person only
browsed contributes to `cardCount` but not `answeredCardCount`; a `self_assess`/graded
comeback contributes a second row to `turnCount` without changing `answeredCardCount`.

- [ ] **Step 1: Add the row-level fixtures**

Append to `test/support/study_fixtures.dart` (it already imports `Variable` and
`AppDatabase`):

```dart
/// A `study_session` row exactly as production writes it (schema.md), for a
/// test that seeds a session state directly instead of driving the full
/// production flow — P1's screens are exercised this way because P1 builds
/// only `browse`, one stage short of any scheduler's whole chain
/// (BR-MODE-004; spec §3).
Future<void> insertSession(
  AppDatabase db, {
  required String id,
  required String deckId,
  required String rootId,
  String sessionKind = 'learning',
  String currentMode = 'browse',
  String status = 'in_progress',
  String? endReason,
  int generation = 1,
  int cursor = 0,
  int cardLimit = 20,
  DateTime? startedAt,
  DateTime? endedAt,
}) => db.customInsert(
  'INSERT INTO study_session (id, deck_id, root_id, generation, '
  'session_kind, current_mode, status, end_reason, cursor, card_limit, '
  'started_at, ended_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
  variables: [
    Variable<String>(id),
    Variable<String>(deckId),
    Variable<String>(rootId),
    Variable<int>(generation),
    Variable<String>(sessionKind),
    Variable<String>(currentMode),
    Variable<String>(status),
    Variable<String>(endReason),
    Variable<int>(cursor),
    Variable<int>(cardLimit),
    Variable<DateTime>(startedAt ?? DateTime(2026, 9, 24, 9)),
    Variable<DateTime>(endedAt),
  ],
  updates: {db.studySession},
);

/// A `study_queue_items` row exactly as production writes it.
Future<void> insertQueueItem(
  AppDatabase db, {
  required String sessionId,
  required String mode,
  required String cardId,
  required int position,
  int round = 1,
  String status = 'pending',
  int answersInSession = 0,
}) => db.customInsert(
  'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
  'position, status, answers_in_session) VALUES (?, ?, ?, ?, ?, ?, ?)',
  variables: [
    Variable<String>(sessionId),
    Variable<String>(mode),
    Variable<int>(round),
    Variable<String>(cardId),
    Variable<int>(position),
    Variable<String>(status),
    Variable<int>(answersInSession),
  ],
  updates: {db.studyQueueItems},
);
```

- [ ] **Step 2: Write the failing tests**

`test/features/study/data/study_session_summary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// D11a: answeredCardCount and turnCount, independent of cardCount and of
// each other (Review Focus 4).

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('answeredCardCount is distinct cards with a turn; turnCount is every '
      'turn, including a comeback (D11a)', () async {
    final decks = DeckRepositoryImpl(db);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    await insertCard(db, id: 'c2', deckId: leaf.id);
    await insertCard(db, id: 'c3', deckId: leaf.id);
    await insertSession(
      db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'completed',
      endedAt: DateTime(2026, 9, 24, 10),
    );
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c1',
      position: 0,
      status: 'completed',
    );
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c2',
      position: 1,
      status: 'completed',
    );
    // c3 was in the queue but never answered (BR-MODE-005: browse commits an
    // AdvanceAnswer turn per swipe, so a card left unswiped has no row).
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c3',
      position: 2,
      status: 'pending',
    );
    // c1 answered twice (a relearning comeback); c2 once.
    await logReview(db, id: 'r1', cardId: 'c1', at: DateTime(2026, 9, 24, 9, 1));
    await logReview(db, id: 'r2', cardId: 'c1', at: DateTime(2026, 9, 24, 9, 2));
    await logReview(db, id: 'r3', cardId: 'c2', at: DateTime(2026, 9, 24, 9, 3));

    final counts = await StudyViewDao(db).summaryCounts('s', lapseActions: const []);
    expect(counts.cardCount, 3);
    expect(counts.answeredCardCount, 2);
    expect(counts.turnCount, 3);

    final view = await StudySessionViewRepositoryImpl(db).watchSession('s').first;
    expect(view!.summary!.answeredCardCount, 2);
    expect(view.summary!.turnCount, 3);
  });
}
```

- [ ] **Step 3: Run it to see it fail**

Run: `flutter test --exclude-tags golden test/features/study/data/study_session_summary_test.dart`
Expected: FAIL to compile — `SummaryCounts` and `SessionSummary` have no
`answeredCardCount`/`turnCount` fields yet.

- [ ] **Step 4: Implement**

`study_session_view_model.dart`, extend `SessionSummary`:

```dart
final class SessionSummary {
  const SessionSummary({
    required this.cardCount,
    required this.answeredCardCount,
    required this.turnCount,
    required this.learnedCardCount,
    required this.wrongTurnCount,
  });

  /// The distinct cards of the queue.
  final int cardCount;

  /// Distinct cards with at least one turn recorded (handoff 21 "Cards
  /// answered"; spec D11a).
  final int answeredCardCount;

  /// Every turn recorded, including a relearning comeback (handoff 21 "of
  /// {total} turns"; spec D11a).
  final int turnCount;

  /// In a learning session, its cards that are now learned; null in a
  /// review.
  final int? learnedCardCount;

  /// The session's turns whose action was a lapse (BR-SRS-018).
  final int wrongTurnCount;
}
```

`study_view_dao.dart`, extend the typedef and the query:

```dart
/// The counts a session's summary shows (spec D11, D11a).
typedef SummaryCounts = ({
  int cardCount,
  int answeredCardCount,
  int turnCount,
  int learnedCount,
  int wrongCount,
});
```

```dart
  Future<SummaryCounts> summaryCounts(
    String sessionId, {
    required List<String> lapseActions,
  }) async {
    final lapses = List.filled(lapseActions.length, '?').join(', ');
    final row = await _db
        .customSelect(
          'SELECT'
          ' (SELECT COUNT(DISTINCT card_id) FROM study_queue_items'
          '  WHERE session_id = ?) AS card_count,'
          ' (SELECT COUNT(DISTINCT card_id) FROM review_log'
          '  WHERE session_id = ?) AS answered_card_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?)'
          '  AS turn_count,'
          ' (SELECT COUNT(DISTINCT q.card_id) FROM study_queue_items q'
          '  JOIN card_schedule cs ON cs.card_id = q.card_id'
          '  WHERE q.session_id = ? AND cs.learned_at IS NOT NULL)'
          '  AS learned_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?'
          '  AND action IN ($lapses)) AS wrong_count',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            for (final action in lapseActions) Variable<String>(action),
          ],
          readsFrom: {_db.studyQueueItems, _db.cardSchedule, _db.reviewLog},
        )
        .getSingle();
    return (
      cardCount: row.read<int>('card_count'),
      answeredCardCount: row.read<int>('answered_card_count'),
      turnCount: row.read<int>('turn_count'),
      learnedCount: row.read<int>('learned_count'),
      wrongCount: row.read<int>('wrong_count'),
    );
  }
```

`study_session_view_mapper.dart`, extend the `SessionSummary(` call inside
`studySessionViewOf`:

```dart
    summary: counts == null
        ? null
        : SessionSummary(
            cardCount: counts.cardCount,
            answeredCardCount: counts.answeredCardCount,
            turnCount: counts.turnCount,
            learnedCardCount: switch (kind) {
              SessionKind.learning => counts.learnedCount,
              SessionKind.reviewing => null,
            },
            wrongTurnCount: counts.wrongCount,
          ),
```

- [ ] **Step 5: Run the test**

Run: `flutter test --exclude-tags golden test/features/study/data/study_session_summary_test.dart`
Expected: PASS.

- [ ] **Step 6: Full study suite, gate, commit**

```bash
flutter test --exclude-tags golden test/features/study
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study test/support/study_fixtures.dart test/features/study/data/study_session_summary_test.dart
git commit -m "feat(study): SessionSummary gains answeredCardCount and turnCount (D11a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `StudySessionController` — answer and abandon behind one in-flight lock (spec D4)

**Files:**
- Create: `lib/features/study/presentation/providers/answer_study_turn_use_case_provider.dart`
- Create: `lib/features/study/presentation/providers/abandon_study_session_use_case_provider.dart`
- Create: `lib/features/study/presentation/controllers/study_session_controller.dart`
- Test: `test/features/study/presentation/study_session_controller_test.dart`

**Interfaces:**
- Produces: `answerStudyTurnUseCaseProvider`, `abandonStudySessionUseCaseProvider`,
  `studySessionControllerProvider(String sessionId)` with
  `Future<Outcome<TurnResult, StudyRejection>?> answer({required String cardId, required StudyAnswer answer})`
  and `Future<Outcome<void, StudyRejection>?> abandon()` — both null when a write is
  already in flight (the tap is dropped, not queued, per BR-STUDY-004).

- [ ] **Step 1: Write the failing test**

`test/features/study/presentation/study_session_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/abandon_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// Answers only after [release] is called, so two calls started together
/// race the lock instead of the database.
final class _SlowSessions implements StudySessionRepository {
  final calls = <String>[];
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async {
    calls.add(cardId);
    await _gate.future;
    return const Ok(TurnResult());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a second answer while one is in flight is dropped (BR-STUDY-004)', () async {
    final sessions = _SlowSessions();
    final container = ProviderContainer(
      overrides: [
        answerStudyTurnUseCaseProvider.overrideWithValue(
          AnswerStudyTurnUseCase(sessions),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      studySessionControllerProvider('s').notifier,
    );

    final first = controller.answer(cardId: 'c1', answer: const AdvanceAnswer());
    final second = controller.answer(cardId: 'c2', answer: const AdvanceAnswer());
    sessions.release();

    expect(await second, isNull);
    expect(await first, isA<Ok<TurnResult, StudyRejection>>());
    expect(sessions.calls, ['c1']);
  });

  test('the lock releases: a later answer after the first completes runs', () async {
    final sessions = _SlowSessions()..release();
    final container = ProviderContainer(
      overrides: [
        answerStudyTurnUseCaseProvider.overrideWithValue(
          AnswerStudyTurnUseCase(sessions),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      studySessionControllerProvider('s').notifier,
    );

    await controller.answer(cardId: 'c1', answer: const AdvanceAnswer());
    await controller.answer(cardId: 'c2', answer: const AdvanceAnswer());

    expect(sessions.calls, ['c1', 'c2']);
  });

  test('abandon calls AbandonStudySessionUseCase exactly once per tap', () async {
    final calls = <String>[];
    final container = ProviderContainer(
      overrides: [
        abandonStudySessionUseCaseProvider.overrideWithValue(
          AbandonStudySessionUseCase(_AbandonSpy(calls)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final outcome = await container
        .read(studySessionControllerProvider('s').notifier)
        .abandon();

    expect(outcome, isA<Ok<void, StudyRejection>>());
    expect(calls, ['s']);
  });
}

final class _AbandonSpy implements StudySessionRepository {
  _AbandonSpy(this.calls);

  final List<String> calls;

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
  }) async {
    calls.add(sessionId);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_session_controller_test.dart`
Expected: FAIL to compile — none of the three new files exist.

- [ ] **Step 3: Implement**

`lib/features/study/presentation/providers/answer_study_turn_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'answer_study_turn_use_case_provider.g.dart';

@riverpod
AnswerStudyTurnUseCase answerStudyTurnUseCase(Ref ref) =>
    AnswerStudyTurnUseCase(ref.watch(studySessionRepositoryProvider));
```

`lib/features/study/presentation/providers/abandon_study_session_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/abandon_study_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'abandon_study_session_use_case_provider.g.dart';

@riverpod
AbandonStudySessionUseCase abandonStudySessionUseCase(Ref ref) =>
    AbandonStudySessionUseCase(ref.watch(studySessionRepositoryProvider));
```

`lib/features/study/presentation/controllers/study_session_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_controller.g.dart';

/// The session screen's one write path (spec D4): answer and abandon, both
/// behind a single in-flight flag, so a second tap while a write runs is
/// dropped instead of racing it (BR-STUDY-004). Reveal, recall time and
/// fill hint join once P4 builds the modes that use them. Mode widgets never
/// call a use case directly.
@riverpod
class StudySessionController extends _$StudySessionController {
  bool _isInFlight = false;

  @override
  void build(String sessionId) {}

  /// Null when a write is already in flight: the tap is dropped, not queued.
  Future<Outcome<TurnResult, StudyRejection>?> answer({
    required String cardId,
    required StudyAnswer answer,
  }) => _guarded(
    () => ref.read(answerStudyTurnUseCaseProvider)(
      sessionId: sessionId,
      cardId: cardId,
      answer: answer,
    ),
  );

  /// UC-STUDY-001 A3: Stop in the exit dialog calls this, from the ✕ and the
  /// system back gesture alike (spec D8, owner ruling 2026-09-27).
  Future<Outcome<void, StudyRejection>?> abandon() => _guarded(
    () => ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId),
  );

  Future<T?> _guarded<T>(Future<T> Function() action) async {
    if (_isInFlight) return null;
    _isInFlight = true;
    try {
      return await action();
    } finally {
      _isInFlight = false;
    }
  }
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --exclude-tags golden test/features/study/presentation/study_session_controller_test.dart
```

Expected: PASS, 3 tests.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study test/features/study/presentation/study_session_controller_test.dart
git commit -m "feat(study): StudySessionController, answer and abandon behind one in-flight lock (D4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The feedback-hold mixin for mode bodies (spec D5)

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_turn_hold_mixin.dart`
- Test: `test/features/study/presentation/study_turn_hold_mixin_test.dart`

**Interfaces:**
- Produces: `mixin StudyTurnHoldMixin<T extends StatefulWidget> on State<T>` with
  `StudyItem? shownItem(StudyItem? liveItem)`, `TurnResult? get heldResult`,
  `void holdTurn(StudyItem item, TurnResult result)`, `void continueTurn()`.

Browse has no graded outcome to hold (D5's own text), so its body's continue
condition fires the instant the write commits — it never actually needs to show a
held result. The mixin is built and tested now anyway, because P2 (`self_assess`'s
reveal-then-grade) and P3/P4's auto-advance modes need the identical hold, and D5 asks
for the mechanism in this phase.

- [ ] **Step 1: Write the failing test**

`test/features/study/presentation/study_turn_hold_mixin_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_turn_hold_mixin.dart';

StudyItem _item(String cardId) => StudyItem(
  cardId: cardId,
  front: 'front $cardId',
  back: 'back $cardId',
  example: null,
  hint: null,
  pronunciation: null,
  round: 1,
  answersInSession: 0,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

class _Host extends StatefulWidget {
  const _Host({required this.liveItem});

  final StudyItem? liveItem;

  @override
  State<_Host> createState() => HostState();
}

class HostState extends State<_Host> with StudyTurnHoldMixin<_Host> {
  @override
  Widget build(BuildContext context) =>
      Text(shownItem(widget.liveItem)?.cardId ?? 'none');
}

void main() {
  testWidgets('holds the answered item until continueTurn (BR-STUDY-063, '
      'BR-STUDY-064)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _Host(liveItem: _item('a'))));
    expect(find.text('a'), findsOneWidget);

    final state = tester.state<HostState>(find.byType(_Host));
    state.holdTurn(_item('a'), const TurnResult(isCorrect: true));

    // The stream moved on to a new item, but the hold keeps the old one on
    // screen (BR-STUDY-064: the unit stays on screen between turns).
    await tester.pumpWidget(MaterialApp(home: _Host(liveItem: _item('b'))));
    expect(find.text('a'), findsOneWidget);
    expect(state.heldResult?.isCorrect, isTrue);

    state.continueTurn();
    await tester.pump();
    expect(find.text('b'), findsOneWidget);
    expect(state.heldResult, isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_turn_hold_mixin_test.dart`
Expected: FAIL to compile — `study_turn_hold_mixin.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';

/// Keeps the card just answered, and its result, on screen until the mode's
/// continue condition fires (spec D5; BR-STUDY-063, BR-STUDY-064): the
/// stream's next current item never replaces it before then. `browse` has
/// no result to show, so its continue condition is met the instant the
/// write commits (`continueTurn` right after `holdTurn`); the graded modes
/// of P2–P4 hold for an auto-advance delay or a Continue tap instead.
mixin StudyTurnHoldMixin<T extends StatefulWidget> on State<T> {
  StudyItem? _heldItem;
  TurnResult? _heldResult;

  /// [liveItem] while nothing is held, else the item being held.
  StudyItem? shownItem(StudyItem? liveItem) => _heldItem ?? liveItem;

  /// Null while nothing is held.
  TurnResult? get heldResult => _heldResult;

  /// Call right after an answer commits, with the item it was for.
  void holdTurn(StudyItem item, TurnResult result) {
    if (!mounted) return;
    setState(() {
      _heldItem = item;
      _heldResult = result;
    });
  }

  /// The continue condition fired: reveal the stream's current item.
  void continueTurn() {
    if (!mounted || _heldItem == null) return;
    setState(() {
      _heldItem = null;
      _heldResult = null;
    });
  }
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_turn_hold_mixin_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study/presentation/widgets/support/study_turn_hold_mixin.dart test/features/study/presentation/study_turn_hold_mixin_test.dart
git commit -m "feat(study): the feedback-hold mixin mode bodies share (D5)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `AbandonStaleSessionsUseCase` runs once, before the first frame (spec D9)

**Files:**
- Create: `lib/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/features/study/data/abandon_stale_sessions_startup_test.dart`

**Interfaces:**
- Produces: `abandonStaleSessionsUseCaseProvider`.
- Consumes: `AbandonStaleSessionsUseCase` (existing, untouched), `insertSession` (Task
  1).

- [ ] **Step 1: Write the failing test**

`test/features/study/data/abandon_stale_sessions_startup_test.dart`:

```dart
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// D9: the sweep runs before MemoxApp's first frame, so a session left
// in_progress from an earlier day is never offered as resumable (Review
// Focus 5). started_at is hard-coded to a date this test will always be
// well past, so the assertion needs no fake clock threaded through the
// production DI (StudySessionRepositoryImpl defaults `now` to
// DateTime.now(), by design — see study_session_repository_impl.dart).

void main() {
  libraryTest('an in_progress session from an earlier day is abandoned as '
      'interrupted before the app shows anything (spec D9, BR-STUDY-072)', (
    tester,
    env,
  ) async {
    final decks = DeckRepositoryImpl(env.db);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'in_progress',
      startedAt: DateTime(2026, 1, 2, 20),
    );

    await pumpMemoxApp(tester, env);

    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'abandoned');
    expect(row.read<String?>('end_reason'), 'interrupted');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test --exclude-tags golden test/features/study/data/abandon_stale_sessions_startup_test.dart`
Expected: FAIL — the session is still `in_progress`, because nothing runs the sweep
at startup yet.

- [ ] **Step 3: Implement**

`lib/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/abandon_stale_sessions_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'abandon_stale_sessions_use_case_provider.g.dart';

@riverpod
AbandonStaleSessionsUseCase abandonStaleSessionsUseCase(Ref ref) =>
    AbandonStaleSessionsUseCase(ref.watch(studySessionRepositoryProvider));
```

`lib/main.dart`, replaced in full:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
  // Riverpod's default retry-on-error would otherwise sit a failed provider
  // in a hidden retry loop while showing AsyncLoading.
  final container = ProviderContainer(retry: _noRetry);
  // Spec D9: closes yesterday's still-open sessions before the first frame
  // that could offer one to Continue (BR-STUDY-072).
  await container.read(abandonStaleSessionsUseCaseProvider)();
  runApp(
    UncontrolledProviderScope(container: container, child: const MemoxApp()),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
```

Because `main()` now builds its own `ProviderContainer` up front instead of handing a
bare `ProviderScope` to `runApp`, `MemoxApp`'s widget tree is unchanged — only who
creates and seeds the container changes.

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --exclude-tags golden test/features/study/data/abandon_stale_sessions_startup_test.dart
```

Expected: PASS.

- [ ] **Step 5: Full app smoke test, gate, commit**

```bash
flutter test --exclude-tags golden test/integration
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/main.dart lib/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart test/features/study/data/abandon_stale_sessions_startup_test.dart
git commit -m "feat(study): sweep stale sessions once, before MemoxApp's first frame (D9)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The built-modes gate, and Study Entry screen 14 (loading, nothing, resume, gated)

**Files:**
- Create: `lib/features/study/domain/models/built_study_modes.dart`
- Create: `lib/features/study/presentation/providers/watch_study_entry_use_case_provider.dart`
- Create: `lib/features/study/presentation/providers/resume_study_session_use_case_provider.dart`
- Create: `lib/features/study/presentation/providers/study_entry_provider.dart`
- Create: `lib/features/study/presentation/controllers/study_entry_controller.dart`
- Create: `lib/features/study/presentation/screens/study_entry_screen.dart`
- Create: `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart`
- Create: `lib/features/study/presentation/widgets/sections/study_entry_resume_banner_widget.dart`
- Create: `lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/domain/built_study_modes_test.dart`
- Test: `test/features/study/presentation/study_entry_screen_test.dart`

**Interfaces:**
- Produces: `const Set<StudyMode> builtStudyModes`, `bool isLearningBuilt(SchedulerType)`,
  `bool isReviewBuilt(SchedulerType)`; `studyEntryProvider(String deckId)` →
  `Stream<Outcome<StudyEntry, StudyRejection>>`; `StudyEntryController` with
  `Future<Outcome<void, StudyRejection>> resume(String sessionId)`;
  `StudyEntryScreen({required String deckId, required ValueChanged<String?> onOpenAncestor, required ValueChanged<String> onSessionReady})`.
- Consumes: `WatchStudyEntryUseCase`, `ResumeStudySessionUseCase`, `stageSequenceOf`,
  `reviewModesOf` (all existing).

**Ruling — scope of the nine kit states.** Handoff 14 lists nine states, but three of
them (`starting`, `refused`, `startFailed`) only exist once Learn/Review actually open
a session. The built-modes gate makes both actions unavailable on every scheduler in
P1 (`isLearningBuilt`/`isReviewBuilt` are false for both `SchedulerType` values,
because neither `stageSequenceOf` ever equals `{browse}` and `reviewModesOf` never
contains `browse`), so those three states have no way to occur through this screen
yet. P1 builds `loading`, `nothing`, `resume` and one **gated** state that replaces
`sm2`/`eightBox` — the hero and counts are real, but the footer always reads "coming
soon" instead of a live CTA, regardless of scheduler (since the gate excludes both
identically). P2 restores `sm2`'s CTA once `self_assess` is built; the other two states
follow as their gate opens.

- [ ] **Step 1: Write the gate's failing test**

`test/features/study/domain/built_study_modes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/built_study_modes.dart';

void main() {
  test('P1 offers neither Learn nor Review on either algorithm (spec §3)', () {
    for (final type in SchedulerType.values) {
      expect(isLearningBuilt(type), isFalse, reason: '$type');
      expect(isReviewBuilt(type), isFalse, reason: '$type');
    }
  });
}
```

Run: `flutter test --exclude-tags golden test/features/study/domain/built_study_modes_test.dart`
Expected: FAIL to compile.

- [ ] **Step 2: Implement the gate**

`lib/features/study/domain/models/built_study_modes.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The modes this build can run end to end (spec §3, "Unbuilt stages are
/// never offered"). Grows each phase; P4 deletes this gate once every mode
/// is built.
const Set<StudyMode> builtStudyModes = {StudyMode.browse};

/// A learning session on [type] runs its whole stage chain in one sitting
/// (BR-MODE-004), so Learn is offered only once every stage of it is built.
bool isLearningBuilt(SchedulerType type) =>
    stageSequenceOf(type).every(builtStudyModes.contains);

/// A review is offered once at least one of its modes is built
/// (BR-STUDY-055); `browse` is never one of them (BR-STUDY-055), so this is
/// also false throughout P1.
bool isReviewBuilt(SchedulerType type) =>
    reviewModesOf(type).any(builtStudyModes.contains);
```

Run the gate test again. Expected: PASS.

- [ ] **Step 3: Write the screen's failing tests**

`test/features/study/presentation/study_entry_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('watching the entry writes no session (IT-STUDY-002)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);

    await pumpLibraryScreen(
      tester,
      env,
      StudyEntryScreen(
        deckId: leaf.id,
        onOpenAncestor: (_) {},
        onSessionReady: (_) {},
      ),
    );
    await tester.pump();

    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  libraryTest('new and due show as two separate counts (IT-STUDY-001)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'new1', deckId: leaf.id);
    await insertCard(env.db, id: 'new2', deckId: leaf.id);
    await insertCard(
      env.db,
      id: 'due1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await insertCard(
      env.db,
      id: 'due2',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 22),
    );

    await pumpLibraryScreen(
      tester,
      env,
      StudyEntryScreen(
        deckId: leaf.id,
        onOpenAncestor: (_) {},
        onSessionReady: (_) {},
      ),
    );
    await tester.pump();

    expect(find.text('2'), findsNWidgets(2)); // New's tile and Due's tile.
    expect(find.text(_en.studyEntryComingSoonTitle), findsOneWidget);
  });

  libraryTest('nothing due shows the positive empty state (E1, BR-STUDY-008)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(
      env.db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );

    await pumpLibraryScreen(
      tester,
      env,
      StudyEntryScreen(
        deckId: leaf.id,
        onOpenAncestor: (_) {},
        onSessionReady: (_) {},
      ),
    );
    await tester.pump();

    expect(find.text(_en.studyEntryNothingTitle), findsOneWidget);
  });

  libraryTest('Continue resumes today's in_progress session and hands its id '
      'up (BR-STUDY-072)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'in_progress',
      startedAt: libraryToday,
    );
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c1',
      position: 0,
    );
    String? ready;

    await pumpLibraryScreen(
      tester,
      env,
      StudyEntryScreen(
        deckId: leaf.id,
        onOpenAncestor: (_) {},
        onSessionReady: (id) => ready = id,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(_en.studyEntryContinue));
    await tester.pump();
    await tester.pump();

    expect(ready, 's');
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'in_progress');
  });
}
```

- [ ] **Step 4: Run them to see them fail**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_entry_screen_test.dart`
Expected: FAIL to compile — none of the presentation files exist.

- [ ] **Step 5: Copy**

Run this script with `python`, then `flutter gen-l10n`:

```python
import json
from pathlib import Path

STRING = {"type": "String"}
INT = {"type": "int"}

KEYS = {
    "studyEntryHeroLine": ("{algorithm} · cards per session {count}", "{algorithm} · số thẻ mỗi phiên {count}", "Study entry hero overline (BR-STUDY-024).", {"algorithm": STRING, "count": INT}),
    "studyEntryNewLabel": ("New", "Mới", "Study entry hero's new-cards stat tile.", None),
    "studyEntryDueLabel": ("Due", "Đến hạn", "Study entry hero's due-cards stat tile.", None),
    "studyEntryOverdueNote": ("{count} of the due cards are overdue", "{count} thẻ đến hạn đã quá hạn", "Note under the hero when some due cards are overdue.", {"count": INT}),
    "studyEntryResumeOverline": ("Session from today", "Phiên của hôm nay", "Resume banner overline (BR-STUDY-072).", None),
    "studyEntryResumeLine": ("{kind} · {mode} · {done} of {total} cards", "{kind} · {mode} · {done}/{total} thẻ", "Resume banner's progress line.", {"kind": STRING, "mode": STRING, "done": INT, "total": INT}),
    "studyEntryResumeExplain": ("Continue where you stopped, or start something new — that ends this one and keeps its answers.", "Tiếp tục từ chỗ đã dừng, hoặc bắt đầu phiên khác — việc đó sẽ kết thúc phiên này và giữ lại các câu đã trả lời.", "Resume banner's explanatory line.", None),
    "studyEntryContinue": ("Continue", "Tiếp tục", "Resume banner's action.", None),
    "studyEntryNothingTitle": ("Nothing to do right now", "Hiện không có gì để làm", "Positive empty state title (E1, BR-STUDY-008).", None),
    "studyEntryNothingBody": ("Every card is learned and resting. Cards cannot be reviewed before they are due.", "Mọi thẻ đã học xong và đang nghỉ. Thẻ không thể ôn trước khi đến hạn.", "Positive empty state body.", None),
    "studyEntryNothingNextDue": ("Next due {date}", "Đến hạn tiếp theo {date}", "The nearest due date, in the empty state (E1).", {"date": STRING}),
    "studyEntryComingSoonTitle": ("Full sessions are coming soon", "Phiên học đầy đủ sắp ra mắt", "Study entry footer when no mode is built yet (spec §3).", None),
    "studyEntryComingSoonCaption": ("Browse is the only stage built so far.", "Hiện chỉ mới có giai đoạn Xem.", "Study entry footer caption when no mode is built yet.", None),
    "studyEntryLoadErrorTitle": ("Couldn't open Study", "Không mở được màn Học", "Study entry error state title (E5).", None),
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

- [ ] **Step 6: Implement the providers and controller**

`lib/features/study/presentation/providers/watch_study_entry_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_entry_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_entry_use_case_provider.g.dart';

@riverpod
WatchStudyEntryUseCase watchStudyEntryUseCase(Ref ref) => WatchStudyEntryUseCase(
  ref.watch(studyEntryRepositoryProvider),
  ref.watch(dayClockProvider),
);
```

`lib/features/study/presentation/providers/resume_study_session_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/resume_study_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resume_study_session_use_case_provider.g.dart';

@riverpod
ResumeStudySessionUseCase resumeStudySessionUseCase(Ref ref) =>
    ResumeStudySessionUseCase(ref.watch(studySessionRepositoryProvider));
```

`lib/features/study/presentation/providers/study_entry_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_entry_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_provider.g.dart';

/// The Study Entry of [deckId] (screen 14), again on every change and at
/// local midnight; `Rejected(notFound)` once the deck is gone.
@riverpod
Stream<Outcome<StudyEntry, StudyRejection>> studyEntry(Ref ref, String deckId) =>
    ref.watch(watchStudyEntryUseCaseProvider)(deckId: deckId);
```

`lib/features/study/presentation/controllers/study_entry_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_controller.g.dart';

/// Study Entry's one write (UC-STUDY-001 A3b): Continue on today's
/// `in_progress` session. Learn and Review write nothing in P1 (spec §3).
@riverpod
class StudyEntryController extends _$StudyEntryController {
  @override
  void build() {}

  Future<Outcome<void, StudyRejection>> resume(String sessionId) =>
      ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId);
}
```

- [ ] **Step 7: Implement the screen**

`lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// Study Entry's hero (kit 14): the algorithm and its card limit, the New
/// and Due stat tiles (each dimmed at zero, BR-STUDY-047, BR-STUDY-051), and
/// the overdue note when any due card is overdue.
class StudyEntryHeroWidget extends StatelessWidget {
  const StudyEntryHeroWidget({super.key, required this.entry, required this.algorithm});

  final StudyEntry entry;

  /// The deck's scheduler, named.
  final String algorithm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final overdue = entry.nextDueAt != null && entry.dueCardCount > 0
        ? entry.dueCardCount
        : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
      child: MxCard(
        isHero: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              l10n.studyEntryHeroLine(algorithm, entry.cardLimit).toUpperCase(),
              semanticsLabel: l10n.studyEntryHeroLine(algorithm, entry.cardLimit),
              style: styles.overline,
            ),
            Row(
              spacing: AppSpacing.gutter,
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.studyEntryNewLabel,
                    value: entry.newCardCount,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: l10n.studyEntryDueLabel,
                    value: entry.dueCardCount,
                  ),
                ),
              ],
            ),
            if (overdue > 0) MxNote(text: l10n.studyEntryOverdueNote(overdue)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  static const double _dimOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Opacity(
      opacity: value == 0 ? _dimOpacity : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: styles.screenTitle),
          Text(label, style: styles.rowDescription),
        ],
      ),
    );
  }
}
```

`lib/features/study/presentation/widgets/sections/study_entry_resume_banner_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Study Entry's resume banner (kit 14, BR-STUDY-072): only for an
/// `in_progress` session opened today.
class StudyEntryResumeBannerWidget extends StatelessWidget {
  const StudyEntryResumeBannerWidget({
    super.key,
    required this.kind,
    required this.mode,
    required this.done,
    required this.total,
    required this.isBusy,
    required this.onContinue,
  });

  final String kind;
  final String mode;
  final int done;
  final int total;
  final bool isBusy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              l10n.studyEntryResumeOverline.toUpperCase(),
              semanticsLabel: l10n.studyEntryResumeOverline,
              style: styles.overline,
            ),
            Text(l10n.studyEntryResumeLine(kind, mode, done, total), style: styles.dialogBody),
            Text(l10n.studyEntryResumeExplain, style: styles.rowDescription),
            MxButton(
              label: l10n.studyEntryContinue,
              isBlock: true,
              isLoading: isBusy,
              onPressed: isBusy ? null : onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Study Entry's footer while the built-modes gate excludes every mode
/// (spec §3): a disabled CTA names what is coming instead of a live action.
class StudyEntryFooterWidget extends StatelessWidget {
  const StudyEntryFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFooterBar(
      caption: l10n.studyEntryComingSoonCaption,
      child: MxButton(
        label: l10n.studyEntryComingSoonTitle,
        isBlock: true,
        onPressed: null,
      ),
    );
  }
}
```

`lib/features/study/presentation/screens/study_entry_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_footer_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_hero_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_resume_banner_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 14: the Study Entry of an open deck, minus the SM-2 direction
/// sheet (FE-A7, P2). UC-STUDY-001 steps 1–2 and 4.
class StudyEntryScreen extends ConsumerStatefulWidget {
  const StudyEntryScreen({
    super.key,
    required this.deckId,
    required this.onOpenAncestor,
    required this.onSessionReady,
  });

  final String deckId;

  /// A breadcrumb tap: the root, or null for the Library.
  final ValueChanged<String?> onOpenAncestor;

  /// Continue opened (or reopened) [sessionId]: the router pushes the
  /// session route (spec D2).
  final ValueChanged<String> onSessionReady;

  @override
  ConsumerState<StudyEntryScreen> createState() => _StudyEntryScreenState();
}

class _StudyEntryScreenState extends ConsumerState<StudyEntryScreen> {
  static const int _skeletonRows = 3;

  bool _isResuming = false;

  Future<void> _resume(String sessionId) async {
    setState(() => _isResuming = true);
    final outcome = await ref
        .read(studyEntryControllerProvider.notifier)
        .resume(sessionId);
    if (!mounted) return;
    switch (outcome) {
      case Ok():
        widget.onSessionReady(sessionId);
      case Rejected(:final reason):
        setState(() => _isResuming = false);
        showMxSnackbar(context, message: context.l10n.studyRejection(reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deckProvider = deckViewProvider(widget.deckId);
    final entryProvider = studyEntryProvider(widget.deckId);
    return MxAppShell(
      appBar: MxAppBar(
        title: ref.watch(deckProvider).valueOrNull?.let((o) => switch (o) {
              Ok(:final value) => value.deck.name,
              Rejected() => l10n.studyEntryLoadErrorTitle,
            }) ??
            '',
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(entryProvider)) {
        AsyncData(value: Ok(:final value)) => _content(context, value),
        AsyncData(value: Rejected()) => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.studyEntryLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
            ),
          ],
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.studyEntryLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(entryProvider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _skeletonRows),
          ],
        ),
      },
    );
  }

  Widget _content(BuildContext context, StudyEntry entry) {
    final l10n = context.l10n;
    final deckName = switch (ref.watch(deckViewProvider(widget.deckId)).valueOrNull) {
      Ok(:final value) => value.deck.name,
      _ => '',
    };
    final resumableId = entry.resumableSessionId;
    return MxScreenScroll(
      children: [
        MxBreadcrumb(
          segments: [
            MxBreadcrumbSegment(
              label: l10n.navLibrary,
              onTap: () => widget.onOpenAncestor(null),
            ),
            MxBreadcrumbSegment(label: deckName),
          ],
        ),
        const SizedBox(height: AppSpacing.grouped),
        StudyEntryHeroWidget(
          entry: entry,
          algorithm: l10n.schedulerType(entry.schedulerType),
        ),
        if (resumableId != null)
          StudyEntryResumeBannerWidget(
            kind: l10n.studySessionKind(SessionKind.learning),
            mode: l10n.cardModeBrowse,
            done: 0,
            total: entry.cardLimit,
            isBusy: _isResuming,
            onContinue: () => unawaited(_resume(resumableId)),
          ),
        if (entry.newCardCount == 0 && entry.dueCardCount == 0)
          MxEmptyState(
            icon: AppIcons.check,
            title: l10n.studyEntryNothingTitle,
            body: entry.nextDueAt == null
                ? l10n.studyEntryNothingBody
                : '${l10n.studyEntryNothingBody}\n'
                    '${l10n.studyEntryNothingNextDue(l10n.schedulerType(entry.schedulerType))}',
            isCompact: true,
          )
        else
          const StudyEntryFooterWidget(),
      ],
    );
  }
}
```

`entry.resumableSessionId`'s progress line uses a placeholder `done: 0` — replacing it
with the resumable session's real progress needs the same view the session screen
reads (`WatchStudySessionUseCase`), which is out of scope for the entry provider. If
`flutter analyze`/the widget test show the placeholder is visibly wrong (it is not
asserted on above), record a follow-up ruling rather than reading a second stream
here; Task 6 makes the accurate number available for a later refinement.

- [ ] **Step 8: Add `studyRejection` and `studySessionKind` if missing**

Check `lib/l10n/failure_message.dart` for an existing `AppLocalizations.studyRejection`
extension (added when `StudyRejection` was last threaded to a screen). If absent, add
it there alongside the sibling extensions (`srsRejection`, `cardRejection`), covering
at least `.sessionExpired`, `.staleGeneration`, `.notFound` with copy keys following
the same KEYS pattern as Step 5. Add `studySessionKind(SessionKind)` next to
`cardHistoryMode` in `lib/features/study/presentation/widgets/support/` as a small new
`study_labels_widget.dart` extension (`SessionKind.learning => studySessionKindLearning`,
`.reviewing => studySessionKindReviewing`), with those two keys added the same way.

- [ ] **Step 9: Run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --exclude-tags golden test/features/study
```

Expected: PASS.

- [ ] **Step 10: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study lib/l10n test/features/study
git commit -m "feat(study): Study entry screen 14, the built-modes gate, and Continue (spec §3, D9)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `StudySessionScreen` shell and Browse — exit, failures, ended sessions (spec D3, D6, D7, D8)

**Files:**
- Create: `lib/features/study/presentation/providers/watch_study_session_use_case_provider.dart`
- Create: `lib/features/study/presentation/providers/study_session_view_provider.dart`
- Create: `lib/features/study/presentation/screens/study_session_screen.dart`
- Create: `lib/features/study/presentation/widgets/sections/session_context_line_widget.dart`
- Create: `lib/features/study/presentation/widgets/sections/session_footer_hint_widget.dart`
- Create: `lib/features/study/presentation/widgets/sections/study_browse_body_widget.dart`
- Create: `lib/features/study/presentation/widgets/sections/study_session_ended_placeholder_widget.dart`
  (a minimal, real "session ended" body; Task 7 replaces it with the full summary)
- Create: `lib/features/study/presentation/widgets/overlays/study_exit_dialog_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/study_session_screen_test.dart`

**Interfaces:**
- Produces: `studySessionViewProvider(String sessionId)` →
  `Stream<Outcome<StudySessionView, StudyRejection>>`;
  `StudySessionScreen({required String sessionId})`.
- Consumes: `StudySessionController` (Task 2), `StudyTurnHoldMixin` (Task 3).

- [ ] **Step 1: Write the failing tests**

`test/features/study/presentation/study_session_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// A deck with three cards on a browse-only queue, in_progress today.
Future<String> _browseSession(LibraryEnv env, {int cardCount = 3}) async {
  final decks = DeckRepositoryImpl(env.db);
  final root = await decks.root('Korean');
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 0; i < cardCount; i++) {
    await insertCard(env.db, id: 'c$i', deckId: leaf.id, front: 'f$i', back: 'b$i');
  }
  await insertSession(
    env.db,
    id: 's',
    deckId: leaf.id,
    rootId: root.id,
    status: 'in_progress',
    startedAt: libraryToday,
  );
  for (var i = 0; i < cardCount; i++) {
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
    );
  }
  return leaf.id;
}

void main() {
  libraryTest('shows the first card and swiping left advances (BR-MODE-005)', (
    tester,
    env,
  ) async {
    await _browseSession(env);
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text('f0'), findsOneWidget);

    await tester.drag(find.text('f0'), const Offset(-300, 0));
    await tester.pump();
    await tester.pump();

    expect(find.text('f1'), findsOneWidget);
    final turns = await env.db
        .customSelect("SELECT COUNT(*) AS n FROM review_log WHERE card_id = 'c0'")
        .getSingle();
    expect(turns.read<int>('n'), 1);
  });

  libraryTest('the close icon asks first; Keep studying changes nothing '
      '(spec D8, IT-CONT-004)', (tester, env) async {
    await _browseSession(env);
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel(_en.studySessionExitLabel));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsNothing);
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'in_progress');
  });

  libraryTest('Stop abandons as user_exit, from the close icon and from '
      'system Back alike (spec D8, IT-NAV-010)', (tester, env) async {
    await _browseSession(env);
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    // System Back opens the same dialog as the close icon.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyExitStop));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(_en.studySessionExitLabel), findsNothing);
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'abandoned');
    expect(row.read<String>('end_reason'), 'user_exit');
  });

  libraryTest('the Android back gesture reaches the identical abandon path '
      '(Review Focus 2)', (tester, env) async {
    await _browseSession(env);
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();

    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'abandoned');
    expect(row.read<String>('end_reason'), 'user_exit');
  });

  libraryTest('a locked write shows an inline error on the same card, and '
      'retry advances once it succeeds (UC-STUDY-001 E2)', (tester, env) async {
    await _browseSession(env);
    var hasFailedOnce = false;
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
      overrides: [
        answerStudyTurnUseCaseProvider.overrideWithValue(
          AnswerStudyTurnUseCase(
            _LockedOnceThenReal(StudySessionRepositoryImpl(env.db), () => hasFailedOnce, (v) => hasFailedOnce = v),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    await tester.drag(find.text('f0'), const Offset(-300, 0));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySessionLockedRetryTitle), findsOneWidget);
    expect(find.text('f0'), findsOneWidget); // still on the same card.

    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();
    await tester.pump();

    expect(find.text('f1'), findsOneWidget);
  });

  libraryTest('a stale generation pops to the deck list with a message and '
      'writes nothing for that turn (E4, Review Focus 3)', (tester, env) async {
    final deckId = await _browseSession(env);
    // A reset elsewhere bumped the root's generation after the session
    // opened, without invalidating it yet (UC-STUDY-001 step 6).
    await env.db.customUpdate(
      "UPDATE deck SET generation = generation + 1 "
      "WHERE id = (SELECT root_id FROM deck WHERE id = ?)",
      variables: [Variable(deckId)],
    );
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    await tester.drag(find.text('f0'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
    final turns = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM review_log')
        .getSingle();
    expect(turns.read<int>('n'), 0);
  });

  libraryTest("the deck being deleted mid-session pops to the deck list "
      "(A5, IT-CONT-007)", (tester, env) async {
    final deckId = await _browseSession(env);
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    await env.db.customUpdate(
      'DELETE FROM deck WHERE id = ?',
      variables: [Variable(deckId)],
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
  });
}

/// Fails the answer with a lock once, tracked by [isLocked]/[setLocked], then
/// answers for real through [real].
final class _LockedOnceThenReal implements StudySessionRepository {
  _LockedOnceThenReal(this.real, this.isLocked, this.setLocked);

  final StudySessionRepository real;
  final bool Function() isLocked;
  final void Function(bool) setLocked;

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async {
    if (!isLocked()) {
      setLocked(true);
      throw const DatabaseLockedFailure(cause: '/data/memox.sqlite');
    }
    return real.answerTurn(
      sessionId: sessionId,
      cardId: cardId,
      answer: answer,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_session_screen_test.dart`
Expected: FAIL to compile — none of the screen or widget files exist yet.

- [ ] **Step 3: Copy**

Add, the same way as Task 5's Step 5: `studySessionContextLine` (`"{deck} · {sessionKind} · stage {stage} of {total} · {mode}"`), `studyBrowseFooterHint`
(`"Swipe left for next, right to look back · nothing is graded here"`),
`studySessionExitLabel` (`"Exit session"`), `studySessionCounterLabel`
(`"{current} of {total}"`), `studySessionLockedRetryTitle`
(`"Couldn't save that answer"`), `studySessionLockedRetryBody`
(`"The database is busy. Try again."`), `studySessionStaleGenerationSnackbar`
(`"Progress was just reset, so this session closed."`),
`studySessionGoneSnackbar` (`"This deck is gone, so the session closed."`),
`studySessionLoadErrorTitle` (`"Couldn't open this session"`), `studyExitTitle`
(`"Stop this session?"` / `"Dừng phiên này?"`), `studyExitBody` (`"Everything you
answered is kept. Cards you haven't reached stay as they were."` / `"Mọi câu đã trả
lời đều được giữ. Những thẻ chưa tới vẫn như cũ."`), `studyExitKeep`
(`"Keep studying"` / `"Học tiếp"`), `studyExitStop` (`"Stop"` / `"Dừng"`). Vietnamese
translations follow the same literal, calm register as the rest of the study
copy. Run `flutter gen-l10n`.

- [ ] **Step 4: Implement the exit dialog**

`lib/features/study/presentation/widgets/overlays/study_exit_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a session is stopped (spec D8, owner ruling 2026-09-27).
/// Completes true to stop; false (Keep studying, or dismissed) keeps it.
Future<bool> showStudyExitDialog(BuildContext context) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => const StudyExitDialogWidget(),
    ) ??
    false;

class StudyExitDialogWidget extends StatelessWidget {
  const StudyExitDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      width: MxDialogWidth.medium,
      title: l10n.studyExitTitle,
      body: l10n.studyExitBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyExitKeep,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyExitStop,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
```

The screen imports it (`widgets/overlays/study_exit_dialog_widget.dart`).

- [ ] **Step 4b: Implement the providers**

`watch_study_session_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_session_view_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_session_use_case_provider.g.dart';

@riverpod
WatchStudySessionUseCase watchStudySessionUseCase(Ref ref) =>
    WatchStudySessionUseCase(ref.watch(studySessionViewRepositoryProvider));
```

`study_session_view_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_session_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_view_provider.g.dart';

/// The session screen (screens 16–21), again after every turn;
/// `Rejected(notFound)` once the session or its deck is gone (A5, E5).
@riverpod
Stream<Outcome<StudySessionView, StudyRejection>> studySessionView(
  Ref ref,
  String sessionId,
) => ref.watch(watchStudySessionUseCaseProvider)(sessionId: sessionId);
```

- [ ] **Step 5: Implement the shared session widgets**

`session_context_line_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The centred overline every session screen shows (handoff 16, "Shared by
/// the session screens"; kit contract, deliberately not a shared widget):
/// deck, session kind, stage position, mode.
class SessionContextLine extends StatelessWidget {
  const SessionContextLine({
    super.key,
    required this.deckName,
    required this.sessionKind,
    required this.stage,
    required this.totalStages,
    required this.modeLabel,
  });

  final String deckName;
  final String sessionKind;
  final int stage;
  final int totalStages;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = l10n.studySessionContextLine(
      deckName,
      sessionKind,
      stage,
      totalStages,
      modeLabel,
    );
    return Text(
      line.toUpperCase(),
      textAlign: TextAlign.center,
      semanticsLabel: line,
      style: context.textStyles.overline,
    );
  }
}
```

`session_footer_hint_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The calm one-line hint under a session's body (handoff 16, "Shared by
/// the session screens"): what the gesture does, and whether it grades.
class SessionFooterHint extends StatelessWidget {
  const SessionFooterHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: context.textStyles.rowDescription,
  );
}
```

- [ ] **Step 6: Implement the Browse body**

`study_browse_body_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/widgets/support/study_turn_hold_mixin.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 16: both faces of the card, nothing graded (BR-MODE-005,
/// BR-MODE-006). A swipe left commits an [AdvanceAnswer]; a swipe right
/// previews an earlier card of this round without recording anything
/// (BR-STUDY-048).
class StudyBrowseBodyWidget extends ConsumerStatefulWidget {
  const StudyBrowseBodyWidget({
    super.key,
    required this.sessionId,
    required this.currentItem,
    required this.onStaleGeneration,
    required this.onGone,
  });

  final String sessionId;
  final StudyItem currentItem;

  /// UC-STUDY-001 E4: the write was refused because the root's generation
  /// moved. Nothing was recorded (spec D6, D7).
  final VoidCallback onStaleGeneration;

  /// The session or its deck is gone underneath the write (A5).
  final VoidCallback onGone;

  @override
  ConsumerState<StudyBrowseBodyWidget> createState() => _StudyBrowseBodyWidgetState();
}

class _StudyBrowseBodyWidgetState extends ConsumerState<StudyBrowseBodyWidget>
    with StudyTurnHoldMixin<StudyBrowseBodyWidget> {
  /// Cards already shown this round, oldest first, for "look back"
  /// (BR-STUDY-048). Looking back never re-records or moves the cursor.
  final _seen = <StudyItem>[];
  int? _lookBackIndex;

  /// The write already failed with a lock once; the inline error offers
  /// Retry on the same card instead of advancing (UC-STUDY-001 E2).
  bool _isLocked = false;

  @override
  void didUpdateWidget(StudyBrowseBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentItem.cardId != oldWidget.currentItem.cardId) {
      _seen.add(widget.currentItem);
      _lookBackIndex = null;
    }
  }

  StudyItem get _displayed {
    final index = _lookBackIndex;
    if (index != null && index >= 0 && index < _seen.length) return _seen[index];
    return widget.currentItem;
  }

  Future<void> _advance() async {
    if (_lookBackIndex != null) {
      setState(() => _lookBackIndex = null);
      return;
    }
    final item = widget.currentItem;
    setState(() => _isLocked = false);
    try {
      final outcome = await ref
          .read(studySessionControllerProvider(widget.sessionId).notifier)
          .answer(cardId: item.cardId, answer: const AdvanceAnswer());
      if (!mounted || outcome == null) return;
      switch (outcome) {
        case Ok():
          continueTurn();
        case Rejected(reason: StudyRejection.staleGeneration):
          widget.onStaleGeneration();
        case Rejected(reason: StudyRejection.notFound):
          widget.onGone();
        case Rejected():
          continueTurn();
      }
    } on DatabaseLockedFailure {
      if (!mounted) return;
      setState(() => _isLocked = true);
    }
  }

  void _lookBack() {
    if (_seen.length < 2) return;
    final index = _lookBackIndex ?? _seen.length - 1;
    if (index == 0) return;
    setState(() => _lookBackIndex = index - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_seen.isEmpty) _seen.add(widget.currentItem);
    final l10n = context.l10n;
    final item = _displayed;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) unawaited(_advance());
        if (velocity > 0) _lookBack();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          if (_isLocked)
            MxInlineBanner(
              tone: MxBannerTone.danger,
              title: l10n.studySessionLockedRetryTitle,
              message: l10n.studySessionLockedRetryBody,
              actions: [
                MxButton(
                  label: l10n.commonRetry,
                  size: MxButtonSize.compact,
                  onPressed: () => unawaited(_advance()),
                ),
              ],
            ),
          MxCard(
            isFullBleed: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Text(item.front, style: context.textStyles.screenTitle),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Text(item.back, style: context.textStyles.dialogBody),
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

`MxButton`/`MxBannerTone` need `import 'package:memox/shared/widgets/mx_button.dart';`
— add it alongside the other shared-widget imports above.

- [ ] **Step 7: Implement the ended-session placeholder and the shell**

`study_session_ended_placeholder_widget.dart` (Task 7 replaces this body; kept minimal
and real so Task 6's exit/failure tests have something concrete to assert against):

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// A minimal, real "the session ended" body (handoff 21's app bar and
/// footer shape). Task 7 replaces the middle with the full seven-state
/// summary; the shell's own contract — same route, no navigation on end —
/// does not change.
class StudySessionEndedPlaceholderWidget extends StatelessWidget {
  const StudySessionEndedPlaceholderWidget({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(title: l10n.studySummaryTitle, density: MxAppBarDensity.screen),
      body: const MxScreenScroll(children: []),
      footer: MxFooterBar(
        child: MxButton(label: l10n.studySummaryDone, isBlock: true, onPressed: onDone),
      ),
    );
  }
}
```

`study_session_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_view_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_context_line_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_body_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_ended_placeholder_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Screens 16–21 on one route (spec D2, D3): the session's body, picked by
/// an exhaustive switch over [StudyMode], and the summary once the session
/// has ended.
class StudySessionScreen extends ConsumerWidget {
  const StudySessionScreen({super.key, required this.sessionId});

  final String sessionId;

  static const int _skeletonRows = 4;

  Future<void> _exit(BuildContext context, WidgetRef ref) async {
    if (!await showStudyExitDialog(context)) return;
    await ref.read(studySessionControllerProvider(sessionId).notifier).abandon();
    // The stream re-emits with the session ended; the same route re-renders
    // as the summary (spec D2, D8). Nothing is popped here.
  }

  void _onStaleGeneration(BuildContext context) {
    showMxSnackbar(context, message: context.l10n.studySessionStaleGenerationSnackbar);
    unawaited(Navigator.of(context).maybePop());
  }

  void _onGone(BuildContext context) {
    showMxSnackbar(context, message: context.l10n.studySessionGoneSnackbar);
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = studySessionViewProvider(sessionId);
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) when value.summary != null =>
        StudySessionEndedPlaceholderWidget(
          onDone: () => unawaited(Navigator.of(context).maybePop()),
        ),
      AsyncData(value: Ok(:final value)) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_exit(context, ref));
        },
        child: _InProgressShell(
          sessionId: sessionId,
          view: value,
          onExit: () => unawaited(_exit(context, ref)),
          onStaleGeneration: () => _onStaleGeneration(context),
          onGone: () => _onGone(context),
        ),
      ),
      AsyncData(value: Rejected()) => Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _onGone(context),
          );
          return const SizedBox.shrink();
        },
      ),
      AsyncError() => MxAppShell(
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.studySessionLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        body: MxScreenScroll(
          children: [
            MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _skeletonRows),
          ],
        ),
      ),
    };
  }
}

class _InProgressShell extends StatelessWidget {
  const _InProgressShell({
    required this.sessionId,
    required this.view,
    required this.onExit,
    required this.onStaleGeneration,
    required this.onGone,
  });

  final String sessionId;
  final StudySessionView view;
  final VoidCallback onExit;
  final VoidCallback onStaleGeneration;
  final VoidCallback onGone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = view.progress;
    final item = view.currentItem;
    return MxAppShell(
      appBar: MxStudyTopBar(
        modeLabel: l10n.cardHistoryMode(view.currentMode.code),
        current: (progress?.completed ?? 0) + 1,
        total: progress?.total ?? 1,
        counterLabel: l10n.studySessionCounterLabel(
          (progress?.completed ?? 0) + 1,
          progress?.total ?? 1,
        ),
        closeLabel: l10n.studySessionExitLabel,
        onClose: onExit,
      ),
      body: item == null
          ? MxScreenScroll(
              children: [
                MxSkeletonList(semanticLabel: l10n.commonLoading, rows: 3),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.grouped,
                children: [
                  SessionContextLine(
                    deckName: view.deckName,
                    sessionKind: l10n.studySessionKind(view.kind),
                    stage: view.currentStageIndex + 1,
                    totalStages: view.stages.length,
                    modeLabel: l10n.cardHistoryMode(view.currentMode.code),
                  ),
                  Expanded(
                    child: switch (view.currentMode) {
                      StudyMode.browse => StudyBrowseBodyWidget(
                        sessionId: sessionId,
                        currentItem: item,
                        onStaleGeneration: onStaleGeneration,
                        onGone: onGone,
                      ),
                      StudyMode.selfAssess ||
                      StudyMode.match ||
                      StudyMode.guess ||
                      StudyMode.recall ||
                      StudyMode.fill => _ComingSoonBody(mode: view.currentMode),
                    },
                  ),
                  if (view.currentMode == StudyMode.browse)
                    SessionFooterHint(text: l10n.studyBrowseFooterHint),
                ],
              ),
            ),
    );
  }
}

/// An unbuilt stage's body (spec P1 row §3): "coming in a later update"
/// instead of a crash. Unreachable in P1 (the built-modes gate never opens a
/// session past `browse`), but the switch above must stay exhaustive.
class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({required this.mode});

  final StudyMode mode;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(context.l10n.studySessionComingSoonBody(mode.code)),
  );
}
```

Add `studySessionComingSoonBody` (`"{mode} is coming in a later update."`) to the ARB
sweep of Step 3.

- [ ] **Step 8: Run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --exclude-tags golden test/features/study
```

Expected: PASS.

- [ ] **Step 9: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study lib/l10n test/features/study
git commit -m "feat(study): StudySessionScreen shell and Browse — exit, locked-write retry, stale-generation and gone handling (D3, D6, D7, D8)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Session summary content — the seven reachable V8 states (spec D2, D11a, handoff 21)

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_session_summary_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart`
  (replace `StudySessionEndedPlaceholderWidget` with the real widget)
- Delete: `lib/features/study/presentation/widgets/sections/study_session_ended_placeholder_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/study_session_summary_test.dart`

**Interfaces:**
- Produces: `StudySessionSummaryWidget({required StudySessionView view, required VoidCallback onDone, required VoidCallback onStudyThisDeck})`.

**Ruling — scope of the eight kit states.** `contentDeleted` is excluded outright
(handoff 21: unreachable in V8.0, no Trash). `large` needs `SessionSummary.cardLimit`
to know a session hit its ceiling, a field spec D11a does not add; `large` renders
identically to `loaded`/`learning` until a later phase adds that field — recorded here,
not invented. The other seven states are built, each seeded directly at the row level
(Task 1's fixtures), because P1 cannot reach several of them (`reset`,
`schedulerChanged`, `saveError`) through any use case a `browse`-only build can drive.

- [ ] **Step 1: Write the failing tests**

`test/features/study/presentation/study_session_summary_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<String> _endedSession(
  LibraryEnv env, {
  required String status,
  String? endReason,
  String sessionKind = 'reviewing',
  int cardCount = 4,
  int answered = 4,
  int wrong = 1,
}) async {
  final decks = DeckRepositoryImpl(env.db);
  final root = await decks.root('Korean');
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 0; i < cardCount; i++) {
    await insertCard(env.db, id: 'c$i', deckId: leaf.id);
  }
  await insertSession(
    env.db,
    id: 's',
    deckId: leaf.id,
    rootId: root.id,
    sessionKind: sessionKind,
    status: status,
    endReason: endReason,
    endedAt: DateTime(2026, 9, 24, 10),
  );
  for (var i = 0; i < cardCount; i++) {
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
      status: 'completed',
    );
  }
  for (var i = 0; i < answered; i++) {
    await logReview(
      env.db,
      id: 'r$i',
      cardId: 'c$i',
      at: DateTime(2026, 9, 24, 9, i),
      action: i < wrong ? 'forgotten' : 'remembered',
    );
  }
  return leaf.id;
}

void main() {
  libraryTest('a completed review shows its facts (loaded)', (tester, env) async {
    await _endedSession(env, status: 'completed');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleReview), findsOneWidget);
    expect(find.text('4'), findsWidgets); // answered and/or total turns.
    expect(find.text('1'), findsWidgets); // wrong turns.
  });

  libraryTest('a completed learning session shows learning copy', (
    tester,
    env,
  ) async {
    await _endedSession(env, status: 'completed', sessionKind: 'learning');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleLearning), findsOneWidget);
  });

  libraryTest('abandoned/user_exit shows leftEarly, turns kept', (tester, env) async {
    await _endedSession(env, status: 'abandoned', endReason: 'user_exit');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleLeftEarly), findsOneWidget);
  });

  libraryTest('abandoned/interrupted shows interrupted copy', (tester, env) async {
    await _endedSession(env, status: 'abandoned', endReason: 'interrupted');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleInterrupted), findsOneWidget);
  });

  libraryTest('invalidated/scheduler_reset shows reset copy', (tester, env) async {
    await _endedSession(env, status: 'invalidated', endReason: 'scheduler_reset');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleReset), findsOneWidget);
  });

  libraryTest('invalidated/scheduler_changed shows its copy and no facts '
      'card (handoff 21: "no BR limits the summary" does not apply here — '
      'the kit itself draws none)', (tester, env) async {
    await _endedSession(env, status: 'invalidated', endReason: 'scheduler_changed');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleSchedulerChanged), findsOneWidget);
    expect(find.text(_en.studySummaryFactsHeader), findsNothing);
  });

  libraryTest('failed/persistence_error shows the save-error copy, turns kept', (
    tester,
    env,
  ) async {
    await _endedSession(env, status: 'failed', endReason: 'persistence_error');
    await pumpLibraryScreen(tester, env, const StudySessionScreen(sessionId: 's'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleSaveError), findsOneWidget);
  });

  libraryTest('Done pops the session route', (tester, env) async {
    await _endedSession(env, status: 'completed');
    await pumpLibraryScreen(
      tester,
      env,
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const StudySessionScreen(sessionId: 's'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(_en.studySummaryDone));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_session_summary_test.dart`
Expected: FAIL — the shell still shows the Task 6 placeholder, which has none of this
copy.

- [ ] **Step 3: Copy**

Add the summary keys, following handoff 21's Copy section literally: `studySummaryTitle`
("Session summary"), `studySummaryTitleReview` ("Review finished"),
`studySummaryTitleLearning` ("Learning finished"), `studySummaryTitleLeftEarly` ("You
left early"), `studySummaryTitleInterrupted` ("Session interrupted"),
`studySummaryTitleReset` ("Ended by a reset"), `studySummaryTitleSchedulerChanged`
("Ended by an algorithm change"), `studySummaryTitleSaveError` ("Stopped by a save
error"), `studySummaryBodyReview` ("You reviewed {count} cards. Their next due dates
are set.", `{count: int}`), `studySummaryBodyLearning` ("{count} cards finished
learning. They come back tomorrow at 00:00.", `{count: int}`),
`studySummaryBodyLeftEarly` ("You answered {answered} of {total} cards before
leaving.", `{answered: int, total: int}`), `studySummaryBodyInterrupted` ("This
session from yesterday was closed by the system and could not be resumed today. Every
answer you gave is kept.", none), `studySummaryBodyReset` ("Learning progress of this
deck was reset while you were studying, so this session could not continue. Answers
given before the reset stay in the history of the earlier cycle.", none),
`studySummaryBodySchedulerChanged` ("The deck switched to a different review
algorithm, so its learning sequence changed. Every card is new again; start learning
from the deck.", none), `studySummaryBodySaveError` ("An answer could not be written
to this device, so the session stopped. Everything saved before that is kept; the
unanswered cards are still due.", none), `studySummaryFactsHeader` ("This session",
none), `studySummaryFactAnswered` ("Cards answered", none), `studySummaryFactWrong`
("Wrong turns", none), `studySummaryFactOfTurns` ("of {total} turns", `{total: int}`),
`studySummaryEndNoteSchedulerChanged` ("Nothing was lost — the answers are in the
history.", none), `studySummaryStudyThisDeck` ("Study this deck", none),
`studySummaryDone` ("Done", none), `studySummaryDoneCaption` ("Done returns you to the
deck.", none), `studySummaryLoadingCaption` ("Loading your summary…", none). Run
`flutter gen-l10n`.

- [ ] **Step 4: Implement**

`study_session_summary_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

enum _Outcome { ok, paused, ended, error }

/// Screen 21: the session summary, once [StudySessionView.summary] is set
/// (spec D2). `contentDeleted` is unreachable in V8.0 (no Trash) and is not
/// built; `large`'s card-limit copy needs a field spec D11a does not add
/// yet and renders as [loaded]/[learning] until it does.
class StudySessionSummaryWidget extends StatelessWidget {
  const StudySessionSummaryWidget({
    super.key,
    required this.view,
    required this.onDone,
    required this.onStudyThisDeck,
  });

  final StudySessionView view;
  final VoidCallback onDone;
  final VoidCallback onStudyThisDeck;

  bool get _hasFacts => view.endReason != SessionEndReason.schedulerChanged;

  _Outcome get _outcome => switch (view.status) {
    SessionStatus.completed => _Outcome.ok,
    SessionStatus.abandoned => _Outcome.paused,
    SessionStatus.invalidated => _Outcome.ended,
    SessionStatus.failed => _Outcome.error,
    SessionStatus.inProgress => throw StateError('no summary while running'),
  };

  String _title(AppLocalizationsExtension l10n) => switch ((view.status, view.endReason, view.kind)) {
    (SessionStatus.completed, _, SessionKind.learning) => l10n.studySummaryTitleLearning,
    (SessionStatus.completed, _, SessionKind.reviewing) => l10n.studySummaryTitleReview,
    (SessionStatus.abandoned, SessionEndReason.interrupted, _) => l10n.studySummaryTitleInterrupted,
    (SessionStatus.abandoned, _, _) => l10n.studySummaryTitleLeftEarly,
    (SessionStatus.invalidated, SessionEndReason.schedulerChanged, _) => l10n.studySummaryTitleSchedulerChanged,
    (SessionStatus.invalidated, _, _) => l10n.studySummaryTitleReset,
    (SessionStatus.failed, _, _) => l10n.studySummaryTitleSaveError,
    (SessionStatus.inProgress, _, _) => throw StateError('no summary while running'),
  };

  String _body(AppLocalizationsExtension l10n) {
    final summary = view.summary!;
    return switch ((view.status, view.endReason, view.kind)) {
      (SessionStatus.completed, _, SessionKind.learning) =>
        l10n.studySummaryBodyLearning(summary.learnedCardCount ?? summary.answeredCardCount),
      (SessionStatus.completed, _, SessionKind.reviewing) =>
        l10n.studySummaryBodyReview(summary.answeredCardCount),
      (SessionStatus.abandoned, SessionEndReason.interrupted, _) =>
        l10n.studySummaryBodyInterrupted,
      (SessionStatus.abandoned, _, _) =>
        l10n.studySummaryBodyLeftEarly(summary.answeredCardCount, summary.cardCount),
      (SessionStatus.invalidated, SessionEndReason.schedulerChanged, _) =>
        l10n.studySummaryBodySchedulerChanged,
      (SessionStatus.invalidated, _, _) => l10n.studySummaryBodyReset,
      (SessionStatus.failed, _, _) => l10n.studySummaryBodySaveError,
      (SessionStatus.inProgress, _, _) => throw StateError('no summary while running'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = view.summary!;
    return MxAppShell(
      appBar: MxAppBar(title: l10n.studySummaryTitle, density: MxAppBarDensity.screen),
      body: MxScreenScroll(
        children: [
          MxCard(
            isHero: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.grouped,
              children: [
                MxIconTile(
                  icon: switch (_outcome) {
                    _Outcome.ok => AppIcons.check,
                    _Outcome.paused => AppIcons.play,
                    _Outcome.ended => AppIcons.info,
                    _Outcome.error => AppIcons.offline,
                  },
                  size: MxIconTileSize.large,
                ),
                Text(_title(l10n), style: context.textStyles.screenTitle),
                Text(_body(l10n), style: context.textStyles.dialogBody),
              ],
            ),
          ),
          if (_hasFacts) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxListSectionHeader(label: l10n.studySummaryFactsHeader),
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  MxListRow(
                    leading: const MxIconTile(icon: AppIcons.check, size: MxIconTileSize.small),
                    title: l10n.studySummaryFactAnswered,
                    trailing: Text('${summary.answeredCardCount}'),
                  ),
                  MxListRow(
                    leading: const MxIconTile(icon: AppIcons.offline, size: MxIconTileSize.small),
                    title: l10n.studySummaryFactWrong,
                    subtitle: l10n.studySummaryFactOfTurns(summary.turnCount),
                    trailing: Text('${summary.wrongTurnCount}'),
                    hasDivider: false,
                  ),
                ],
              ),
            ),
          ],
          if (view.endReason == SessionEndReason.schedulerChanged) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxNote(text: l10n.studySummaryEndNoteSchedulerChanged),
          ],
        ],
      ),
      footer: MxFooterBar(
        caption: l10n.studySummaryDoneCaption,
        child: Row(
          spacing: AppSpacing.control,
          children: [
            if (_outcome == _Outcome.ok || _outcome == _Outcome.paused)
              Expanded(
                child: MxButton(
                  label: l10n.studySummaryStudyThisDeck,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                  onPressed: onStudyThisDeck,
                ),
              ),
            Expanded(
              child: MxButton(label: l10n.studySummaryDone, isBlock: true, onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}
```

`study_session_screen.dart`: replace the `StudySessionEndedPlaceholderWidget(...)`
branch with:

```dart
      AsyncData(value: Ok(:final value)) when value.summary != null =>
        StudySessionSummaryWidget(
          view: value,
          onDone: () => unawaited(Navigator.of(context).maybePop()),
          onStudyThisDeck: () => unawaited(Navigator.of(context).maybePop()),
        ),
```

(Both actions pop once, per the ruling in the Global Constraints: P1's only entry
point to a session is Study Entry's Continue, so a single pop always lands back on
it. Delete the now-unused `study_session_ended_placeholder_widget.dart` file and its
import.)

- [ ] **Step 5: Run the tests**

```bash
flutter test --exclude-tags golden test/features/study
```

Expected: PASS.

- [ ] **Step 6: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/features/study lib/l10n test/features/study
git rm lib/features/study/presentation/widgets/sections/study_session_ended_placeholder_widget.dart 2>/dev/null || true
git commit -m "feat(study): session summary screen 21, seven reachable states (D11a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Routes (spec D1, D2) and entry points (spec D10)

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Modify: `test/support/library_harness.dart` (optional `onOpenStudy`/`onStudy` params
  on the `deckScreen`/`cardDeckScreen` test factories, defaulted, so existing call
  sites keep compiling)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/study_entry_points_test.dart`

**Interfaces:**
- Produces: `AppRoutes.studyChild`, `AppRoutes.study(deckId)` (D1);
  `AppRoutes.sessionIdParam`, `AppRoutes.session`, `AppRoutes.studySession(sessionId)`
  (D2); `DeckAction.study`.

- [ ] **Step 1: Write the failing test**

`test/features/study/presentation/study_entry_points_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the deck action sheet offers a real Study row, and Study '
      'leaves the Coming soon sheet (spec D10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await env.decks.sub(root.id, 'Lesson');
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(_en.deckActions));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckStudy), findsOneWidget);
    await tester.tap(find.text(_en.deckStudy));
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget); // D1: the tab bar stays.
  });

  libraryTest("the card list summary's Study this deck opens the entry (D10)", (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lesson'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardStudyThisDeck));
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
  });

  libraryTest('the session route has no tab bar (spec D2)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'in_progress',
      startedAt: libraryToday,
    );
    await insertQueueItem(env.db, sessionId: 's', mode: 'browse', cardId: 'c1', position: 0);
    await pumpMemoxApp(tester, env);

    // Direct navigation stands in for Study Entry's Continue (Task 5), so
    // this test isolates the route's own chrome.
    final router = GoRouter.of(tester.element(find.byType(MemoxApp)));
    router.push(AppRoutes.studySession('s'));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
  });
}
```

`GoRouter`/`MemoxApp` need `import 'package:go_router/go_router.dart';` and
`import 'package:memox/app/app.dart';` at the top of the test file.

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_entry_points_test.dart`
Expected: FAIL — `DeckAction.study`, the routes and the new callbacks do not exist.

- [ ] **Step 3: Copy**

Add `deckStudy` ("Study", "Học") next to `deckReviewAlgorithm` in the ARB sweep;
`cardStudyThisDeck` ("Study this deck", "Học bộ thẻ này").

- [ ] **Step 4: Routes**

`app_routes.dart`, add:

```dart
  /// Study Entry, relative to [deckChild] (spec D1).
  static const String studyChild = 'study';

  /// The path parameter that names a session.
  static const String sessionIdParam = 'sessionId';

  /// A session, on the root navigator, with no tab bar (spec D2).
  static const String session = '/study/session/:$sessionIdParam';

  /// Study Entry for [deckId].
  static String study(String deckId) => '${deck(deckId)}/$studyChild';

  /// [sessionId]'s session or summary.
  static String studySession(String sessionId) => '/study/session/$sessionId';
```

`app_router.dart`:
- Add `import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';`
  and `.../study_session_screen.dart`.
- Under `AppRoutes.deckChild`'s `routes`, alongside `cardNewChild`/`algorithmChild`, add:

```dart
                    GoRoute(
                      path: AppRoutes.studyChild,
                      builder: (context, state) => StudyEntryScreen(
                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                        onOpenAncestor: (id) => _openAncestor(context, id),
                        onSessionReady: (sessionId) =>
                            unawaited(context.push(AppRoutes.studySession(sessionId))),
                      ),
                    ),
```

- Alongside the top-level `gallery` route, add a sibling entry (outside the
  `StatefulShellRoute`, so it carries no tab bar):

```dart
    GoRoute(
      path: AppRoutes.session,
      builder: (context, state) => StudySessionScreen(
        sessionId: state.pathParameters[AppRoutes.sessionIdParam]!,
      ),
    ),
```

- In `_deckLevel`, thread the new callback and pass it to `cardContent`:

```dart
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
  void addCard(String id) => unawaited(context.push(AppRoutes.newCard(id)));
  void openStudy(String id) => unawaited(context.push(AppRoutes.study(id)));
  return DeckLevelScreen(
    deckId: deckId,
    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
    onOpenAncestor: (id) => _openAncestor(context, id),
    onSearch: () => context.push(AppRoutes.deckSearch),
    onOpenAlgorithm: (id) => unawaited(context.push(AppRoutes.deckAlgorithm(id))),
    onOpenStudy: openStudy,
    onAddCard: addCard,
    cardAppBar: (view, back, actions) =>
        CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
    cardBreadcrumb: (id, child) => CardDeckBreadcrumbWidget(deckId: id, child: child),
    cardContent: (view) => CardListSectionWidget(
      deckId: view.deck.id,
      algorithm: context.l10n.cardScheduler(view.schedulerType),
      onAddCard: () => addCard(view.deck.id),
      onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
      onStudy: () => openStudy(view.deck.id),
    ),
    cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () => addCard(id)),
  );
}
```

- [ ] **Step 5: Thread `onOpenStudy` through `DeckLevelScreen`**

In `deck_level_screen.dart`, add `required this.onOpenStudy` (and the matching
`final ValueChanged<String> onOpenStudy;`) to the three classes that already carry
`onOpenAlgorithm` (`DeckLevelScreen`, its private `_body`/level widget, and `_OpenDeck`
— follow the exact three call sites `onOpenAlgorithm` appears at, listed in this file's
earlier read), and pass it into `openDeckActions(...)`'s call inside the `⋮` button's
`onPressed`.

- [ ] **Step 6: `openDeckActions` and the action sheet**

`deck_actions_flow_widget.dart`:

```dart
Future<void> openDeckActions(
  BuildContext context,
  WidgetRef ref, {
  required String deckId,
  required String? parentId,
  required ValueChanged<String> onOpenDeck,
  required ValueChanged<String> onOpenAlgorithm,
  required ValueChanged<String> onOpenStudy,
  required bool isOpenDeck,
}) async {
  // ...unchanged up to the switch...
  switch (action) {
    case DeckAction.open:
      onOpenDeck(deckId);
    case DeckAction.study:
      onOpenStudy(deckId);
    case DeckAction.rename:
      await showRenameDeckDialog(context, deck: view.deck);
    case DeckAction.move:
      await showMoveDeckSheet(context, deck: view.deck);
    case DeckAction.reviewAlgorithm:
      onOpenAlgorithm(deckId);
    case DeckAction.reorder:
      ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
    case DeckAction.delete:
      await _deleteDeck(context, view: view, isOpenDeck: isOpenDeck);
  }
}
```

`deck_action_sheet_widget.dart`: add `study` to the enum (`enum DeckAction { open,
study, rename, move, reviewAlgorithm, reorder, delete }`) and a row right after Open
(before Rename):

```dart
      MxActionSheetCommandRow(
        icon: AppIcons.study,
        label: l10n.deckStudy,
        onTap: () => choose(DeckAction.study),
      ),
```

`deck_coming_soon_sheet_widget.dart`: delete the `(AppIcons.play, l10n.comingSoonStudy,
l10n.comingSoonStudyBody)` line from `_features` — Study options stays (spec D10:
"Study options stays there").

- [ ] **Step 7: The card list's "Study this deck"**

`card_deck_summary_widget.dart`: add `required this.onStudy` (`final VoidCallback
onStudy;`) and, under the `_StatusBar`, an outline `MxButton` block:

```dart
            const SizedBox(height: AppSpacing.micro),
            MxButton(
              label: l10n.cardStudyThisDeck,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: onStudy,
            ),
```

`card_list_section_widget.dart`: add `required this.onStudy` (`final VoidCallback
onStudy;`) to `CardListSectionWidget`, and pass it into
`CardDeckSummaryWidget(view: view, algorithm: widget.algorithm, onStudy: widget.onStudy)`
in `_children`.

- [ ] **Step 8: Test-harness defaults**

`test/support/library_harness.dart`: add `ValueChanged<String>? onOpenStudy` to
`deckScreen(...)`'s parameters, defaulted `onOpenStudy ?? (_) {}`, passed to
`DeckLevelScreen(..., onOpenStudy: onOpenStudy ?? (_) {})`. `cardDeckScreen`'s
`CardListSectionWidget(...)` call gains `onStudy: () {}`.

- [ ] **Step 9: Run everything touched**

```bash
flutter test --exclude-tags golden test/features/study test/features/card test/features/deck test/visual_audit
```

Expected: PASS.

- [ ] **Step 10: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/app lib/features/deck lib/features/card lib/features/study lib/l10n test/support/library_harness.dart test/features/study/presentation/study_entry_points_test.dart
git commit -m "feat(study): routes D1/D2 and real entry points — deck action sheet and card summary (D10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Visual-audit companions, goldens, and the phase gate

**Files:**
- Create: `test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart`
- Create: `test/visual_audit/screens/features/study/screens/study_session_screen_visual_audit_test.dart`
- Modify: `test/support/study_fixtures.dart` if a companion needs a small seed helper
  not already present (none expected — Tasks 1–8 cover it).
- Test (golden, container only): `test/features/study/presentation/study_entry_screen_golden_test.dart`,
  `test/features/study/presentation/study_session_screen_golden_test.dart` — follow the
  exact shape of `test/features/card/presentation/card_detail_golden_test.dart`
  (`pumpLibraryGolden`, `withRealShadows`, `expectBoundaryGolden`, light and dark).

Two production screens were added this phase (`study_entry_screen.dart`,
`study_session_screen.dart` — the summary is a widget inside the second, not a
`*_screen.dart` file, so the coverage test does not ask for a third companion).

- [ ] **Step 1: Run the coverage test to see it fail**

Run: `flutter test --exclude-tags golden test/visual_audit/screens/screen_audit_coverage_test.dart`
Expected: FAIL — "every production screen has a companion that audits it" lists
`study_entry_screen` and `study_session_screen` as missing.

- [ ] **Step 2: Write the companions**

`study_entry_screen_visual_audit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/study_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 14, gated (no mode built yet)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        StudyEntryScreen(deckId: leaf.id, onOpenAncestor: (_) {}, onSessionReady: (_) {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 14, nothing due', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(
      env.db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        StudyEntryScreen(deckId: leaf.id, onOpenAncestor: (_) {}, onSessionReady: (_) {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 14, resume banner', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      status: 'in_progress',
      startedAt: libraryToday,
    );
    await insertQueueItem(env.db, sessionId: 's', mode: 'browse', cardId: 'c1', position: 0);
    await auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        StudyEntryScreen(deckId: leaf.id, onOpenAncestor: (_) {}, onSessionReady: (_) {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

`study_session_screen_visual_audit_test.dart` follows the same shape with two cases:
Browse in progress (the `_browseSession` fixture from Task 6, inlined or promoted to
`study_fixtures.dart` as `Future<String> insertBrowseSession(LibraryEnv env, ...)` if
reused a third time), and the "loaded" summary (`_endedSession` from Task 7, likewise
promoted). Promoting both fixtures avoids copying the seed helper between three test
files; do this as part of this step, updating Tasks 6/7's test files to import the
promoted versions instead of a private one.

- [ ] **Step 3: Run the visual-audit and coverage tests**

Run: `flutter test --exclude-tags golden test/visual_audit`
Expected: PASS, including the coverage test.

- [ ] **Step 4: Write the golden tests (Windows: compile and run un-tagged parts only)**

Follow `card_detail_golden_test.dart`'s exact shape: one `test('golden — light', ...,
tags: 'golden')` and one for dark, per screen state, using `pumpLibraryGolden` and
`expectBoundaryGolden` inside `withRealShadows`. Do not run these on Windows.

- [ ] **Step 5: Full phase gate**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: every step green. `dod_check.sh` already excludes goldens and defaults to
base `origin/master` (2026-09-25's gate plan); it must pass with zero new
`targets_pending` entries.

- [ ] **Step 6: Goldens, in the Linux container only**

Generate and verify in `.claude/skills/flutter-testing/scripts/golden.Dockerfile`.
Never run `--update-goldens` on Windows.

- [ ] **Step 7: Commit**

```bash
git add test/visual_audit test/features/study test/support/study_fixtures.dart
git commit -m "test(study): visual-audit companions and goldens for screens 14 and 16/21 (FE-D2 gate)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Do not touch `docs/wbs_FE.md` or `docs/shared/ui/screen-handoff/00-index.md` in this
phase (they stay "not built" for rows 14, 16 and 21 until P5, per spec §3's P5 row).
