# UI hardening SP2a — study and cards: data safety and dead ends — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix backlog items 2.01–2.25 and 2.49–2.51 of the UI hardening spec. That means typed content no longer goes missing, no study or card flow strands the person, no screen shows a false state, and no bulk action lands on the wrong cards.

**Architecture:** Each fix lands where its logic lives, keeping ADR-010/011 layers and ADR-020 (queries in `.drift`):
- controllers and repositories for behaviour;
- screens and widgets for holds, guards and banners;
- one device-local Drift table (`card_draft`, schema 13) for the card draft (ruling R9).

New copy follows DESIGN.md's local-first voice and the SP1 rules.

**Tech Stack:** Flutter 3.47.5, Dart, Riverpod (riverpod_annotation), Drift (`.drift` files, schema snapshots), flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-03-ui-hardening-sp2a-design.md`. The parent spec is `docs/superpowers/specs/2026-10-03-ui-hardening-design.md` (rulings R3, R8, R9, and §6.1 with each finding's evidence).

**Task numbering:** tasks 1–11 are the study cluster (A1–A11), 12–21 the card editor cluster (B1–B10), and 22–30 the card list and import cluster (C1–C9). Task 31 closes the branch. A reference such as "A4" in a task means Task 4, "B5" means Task 16, and "C6" means Task 27.

## Global Constraints

- **Tokens and copy.** Use tokens only. Never write `Color(0x…)`, `Colors.*`, literal sizes, radii, durations or opacities in `lib/shared`, `lib/features` or `lib/app`; the `check_design_tokens.py` hook checks every edited Dart file. Components hold no copy: every new string goes in `lib/l10n/app_en.arb` with a `description`, and in `lib/l10n/app_vi.arb` in Vietnamese with diacritics. Use ICU plurals for counts. `test/app/l10n_test.dart` enforces both.
- **Copy voice** (DESIGN.md):
  - A failure says first that nothing was lost, then offers the retry.
  - A destructive confirm names the loss.
  - A note says something the screen does not already show.
  - Offline is neutral.
  - Warning amber means a refusal or a limit where nothing was lost; danger means a loss.
- **Queries and schema.** Every SQL query lives in a `.drift` file (ADR-020; the guard checks it). A schema change bumps `schemaVersion` and ships with a migration step plus schema-snapshot and upgrade tests (`flutter-drift` skill).
- **Layers** (ADR-010/011, `check_architecture.sh`):
  - `presentation/` never imports `data/`;
  - no pass-through use cases;
  - no single-implementation interface without an architectural reason (the draft repository's contract has one: the presentation→data boundary).
- **Running tests.** A single file: `flutter test <file>`. A folder: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh <dir>`. Never `flutter test <dir>`, never `--update-goldens`. After a `.drift` or annotation change, run `dart run build_runner build --delete-conflicting-outputs` first.
- **Commits.** Conventional and scoped, in English, ending with the Co-Authored-By trailer from the session's attribution reminder.
- **Rulings.**
  - **R3:** starting while another deck's session is open asks first.
  - **R9:** the card draft lives in `card_draft` (device-local; never synced, never logged).
  - **R7:** toast replacement is unchanged.
- **Pre-existing on this Windows host:** 2 failures in `monitoring_detail_screen_test.dart` (timezone) when run file by file. They pass bundled in the gate.

## Controller rulings on the drafting decisions

- **Study (A):** the drafters' recommendations stand:
  - A6: a new `StudySettleGuardWidget.isGuardedAtStart`, wrapping only the summary's action pair;
  - A7: new reveal copy and no Retry button;
  - A9: Done or Back over a lost deck goes to the Library;
  - A1: the confirm covers Learn and Review only;
  - A4: the deferred leave runs after the dialog closes;
  - A5: the overlay flag is released on close;
  - A3: `Navigator.pop()` after a confirmed discard, falling back to the card editor's `_isLeaving` pattern;
  - the copy is a proposal the owner may reword.
- **Editor (B):**
  - D1: `CardDraftRepository` is a domain contract plus `CardDraftRepositoryImpl`, because of the presentation→data boundary.
  - D2: no use cases.
  - D3: drafts expire after 30 days.
  - D4: `MxInlineBanner` gets a `neutral` tone. This depends on the owner approving the change to `lib/shared`.
  - D5–D9 and D11–D12 are accepted.
  - D10: `cardDeckGoneBody` gains "Your text is kept on this phone." (and its VI equivalent).
- **Cards (C):**
  - C1 `BulkOutcome` in `lib/core/error/`, C7 `MxBottomSheet.builder` and C5's amendment of BR-TRASH-008 and UC-CARD-001 depend on the owner's answer.
  - C7: the size check comes after the picker has read the bytes.
  - C9: undo is one operation over per-card batches, and Cancel only gets a pin test.

## Review Focus

- **A stale session from an earlier day.** It must never trigger the cross-deck confirm (Task 1).
- **A kill inside the 500 ms autosave window.** It loses at most that window's typing, because dispose flushes (Task 15).
- **A bulk action where every selected card is gone.** It writes nothing, does not throw, and says so (Task 22).
- **Import limits are inclusive.** Exactly 20,000 rows and exactly 5 MB are accepted; one over is refused (Task 28).
- **Undo import after some imported cards changed.** It still moves every imported card to the Trash, and they stay restorable (Task 30).


---

### Task 1 (A1): Starting while another deck's session is open asks first (2.01, R3)

**Also pin (Review Focus):** a session of another deck left open on an earlier day is closed as stale before entry and never triggers the confirm — add a test that seeds yesterday's open session of deck B, starts deck A, and expects no dialog.

**Files:**
- Modify: `lib/core/database/queries/study_session_queries.drift` (insert after `closeSessionsStartedBefore`, lines 83-89)
- Modify: `lib/features/study/data/datasources/study_session_dao.dart` (insert after `closeStaleSessions`, lines 99-110)
- Modify: `lib/features/study/domain/repositories/study_entry_repository.dart` (append before the closing brace, after line 45)
- Modify: `lib/features/study/data/repositories/study_entry_repository_impl.dart` (insert after `watchEntry`, lines 112-119)
- Create: `lib/features/study/domain/usecases/find_other_deck_session_use_case.dart`
- Create: `lib/features/study/presentation/providers/find_other_deck_session_use_case_provider.dart`
- Create: `lib/features/study/presentation/widgets/overlays/study_end_other_session_dialog_widget.dart`
- Modify: `lib/features/study/presentation/controllers/study_entry_controller.dart` (class doc lines 12-20, `start` lines 38-74)
- Modify: `lib/features/study/presentation/screens/study_entry_screen.dart` (imports lines 1-21, `_start` lines 98-102)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (after `studyExitStop`)
- Test (create): `test/features/study/data/other_deck_session_test.dart`
- Test (modify): `test/features/study/presentation/study_entry_controller_test.dart`, `test/features/study/presentation/study_entry_actions_test.dart`, `test/features/study/presentation/study_entry_actions_golden_test.dart`, `test/support/study_entry_fixtures.dart`
- Goldens: adds `study_entry_end_other_session_{light,dark}.png` (new, Linux run); moves none.

**Interfaces:**
- Produces (domain): `Future<String?> StudyEntryRepository.otherDeckSessionName({required String deckId, DateTime? now})`: the name of the deck whose open, resumable session of today is not `deckId`'s; null when none.
- Produces (use case): `FindOtherDeckSessionUseCase.call({required String deckId}) → Future<String?>`, provider `findOtherDeckSessionUseCaseProvider`.
- Produces (controller): `StudyEntryController.start(StudyStart start, {Future<bool> Function(String deckName)? confirmEnd}) → Future<String?>`. With `confirmEnd` given, a `LearnStart` or `ReviewStart` asks it first when another deck's session is open; `false` starts nothing. `ContinueStart` and `retry()` never ask.
- Produces (overlay): `Future<bool> showStudyEndOtherSessionDialog(BuildContext context, {required String deckName})`.
- Produces (test support): `openOtherDeckSession(AppDatabase db, DeckRepository decks, StudyEntryRepository entries) → Future<String>` in `study_entry_fixtures.dart` (a learning session left open on root `Spanish` › leaf `Unit`); `FailingEntries.otherDeckSessionName` delegating to the inner repository.
- Consumes: `closeAllOpenSessions` is unchanged; the confirmed start still ends the other session inside `_open` (`study_entry_repository_impl.dart:197-198`).

Rulings applied: R3 (spec §3). Only a Learn or a Review ends another session (`resumeSession` closes nothing). A session of the same deck keeps the current silent behaviour (spec §3.1, 2.01: "another deck"). Try again does not ask a second time.

- [ ] **Step 1: Write the failing tests**

Test support first, in `test/support/study_entry_fixtures.dart`. Append this function:

```dart
/// A learning session left open on another deck: a sm2 root `Spanish` with a
/// leaf `Unit` holding one new card `x0`, opened through [entries]. Returns
/// the session's id.
Future<String> openOtherDeckSession(
  AppDatabase db,
  DeckRepository decks,
  StudyEntryRepository entries,
) async {
  final root = await decks.root('Spanish', SchedulerType.sm2);
  final unit = await decks.sub(root.id, 'Unit');
  await insertCard(db, id: 'x0', deckId: unit.id, back: 'new x');
  final opened = await entries.openLearningSession(deckId: unit.id);
  return (opened as Ok<String, StudyRejection>).value;
}
```

and, inside `FailingEntries` (after `watchEntry`), the delegate every `StudyEntryRepository` implementation now needs:

```dart
  @override
  Future<String?> otherDeckSessionName({
    required String deckId,
    DateTime? now,
  }) => _inner.otherDeckSessionName(deckId: deckId, now: now);
```

Create `test/features/study/data/other_deck_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// R3 (SP2a 2.01): the open session of another deck that a start would end.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// Korean › Lesson and Spanish › Unit with one new card each; returns the
  /// two leaves' ids.
  Future<(String, String)> twoLeaves() async {
    final korean = await decks.root('Korean', SchedulerType.sm2);
    final lesson = await decks.sub(korean.id, 'Lesson');
    final spanish = await decks.root('Spanish', SchedulerType.sm2);
    final unit = await decks.sub(spanish.id, 'Unit');
    await insertCard(db, id: 'a1', deckId: lesson.id);
    await insertCard(db, id: 'b1', deckId: unit.id);
    return (lesson.id, unit.id);
  }

  Future<String> openOn(String deckId, {DateTime? at}) async {
    final opened = await entries.openLearningSession(deckId: deckId, now: at);
    return (opened as Ok<String, StudyRejection>).value;
  }

  test("names the deck of another deck's open session", () async {
    final (lesson, unit) = await twoLeaves();
    await openOn(lesson);

    expect(
      await entries.otherDeckSessionName(deckId: unit, now: now),
      'Lesson',
    );
  });

  test('the deck that holds the session is not asked about itself', () async {
    final (lesson, _) = await twoLeaves();
    await openOn(lesson);

    expect(await entries.otherDeckSessionName(deckId: lesson, now: now), isNull);
  });

  test('no session, an ended one and one of an earlier day ask nothing', () async {
    final (lesson, unit) = await twoLeaves();
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);

    final ended = await openOn(lesson);
    await studySessionRepository(db, () => now).abandonSession(sessionId: ended);
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);

    await openOn(lesson, at: DateTime(2026, 9, 23, 9));
    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);
    // Close the stale one, so the teardown's one-open-session invariant holds.
    await studySessionRepository(db, () => now).abandonStaleSessions(now: now);
  });

  test("a session whose deck went to the Trash is not offered", () async {
    final (lesson, unit) = await twoLeaves();
    await openOn(lesson);

    await decks.deleteDeck(deckId: lesson);

    expect(await entries.otherDeckSessionName(deckId: unit, now: now), isNull);
  });
}
```

Append to `test/features/study/presentation/study_entry_controller_test.dart`, inside `main()` after the last test (`study_entry_fixtures.dart` and `study_fixtures.dart` are already imported):

```dart
  test("another deck's open session asks first; Keep it starts nothing and "
      'writes nothing (R3, 2.01)', () async {
    final other = await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);
    final asked = <String>[];

    final id = await controllerOf(leaf).start(
      const LearnStart(),
      confirmEnd: (deckName) async {
        asked.add(deckName);
        return false;
      },
    );

    expect(id, isNull);
    expect(asked, ['Unit']);
    expect(stateOf(leaf).status, StudyStartStatus.idle);
    expect(
      (await sessionOf(env.db, other)).read<String>('status'),
      'in_progress',
    );
    // Only the other deck's opening reached the store.
    expect(env.entries.opened, 1);
  });

  test("End it and start closes the other deck's session and opens the new "
      'one (R3, 2.01)', () async {
    final other = await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1);

    final id = await controllerOf(
      leaf,
    ).start(const LearnStart(), confirmEnd: (_) async => true);

    expect(id, isNotNull);
    final ended = await sessionOf(env.db, other);
    expect(
      (ended.read<String>('status'), ended.read<String>('end_reason')),
      ('abandoned', 'user_exit'),
    );
  });

  test('a start on the deck that holds the open session asks nothing '
      '(spec §3.1, 2.01)', () async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    await env.entries.openLearningSession(deckId: leaf);

    final id = await controllerOf(leaf).start(
      const LearnStart(),
      confirmEnd: (_) async => fail('asked about the deck\'s own session'),
    );

    expect(id, isNotNull);
  });
```

Append to `test/features/study/presentation/study_entry_actions_test.dart`, inside `main()` (its imports already cover `Ok`, `StudyRejection`, `sessionOf`, `sm2Leaf`):

```dart
  libraryTest("starting while another deck's session is open asks first: "
      'Keep it starts nothing, End it and start closes that session '
      '(R3, 2.01)', (tester, env) async {
    final other = await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 1);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );

    await tester.tap(_button(_en.studyEntryLearn));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyEndOtherTitle('Unit')), findsOneWidget);
    expect(find.text(_en.studyEndOtherBody), findsOneWidget);

    await tester.tap(find.text(_en.studyEndOtherKeep));
    await tester.pumpAndSettle();
    expect(opened, isNull);
    expect(
      (await sessionOf(env.db, other)).read<String>('status'),
      'in_progress',
    );

    await tester.tap(_button(_en.studyEntryLearn));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studyEndOtherConfirm));
    await tester.pumpAndSettle();
    expect(opened, isNotNull);
    expect(
      (await sessionOf(env.db, other)).read<String>('status'),
      'abandoned',
    );
  });

  libraryTest('a review asks the same way, after the direction sheet '
      '(R3, 2.01)', (tester, env) async {
    await openOtherDeckSession(env.db, env.decks, env.entries);
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 2);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf, onOpen: (id) => opened = id),
    );

    await tester.tap(_button(_en.studyEntryReviewCta(2)));
    await tester.pumpAndSettle();
    await tester.tap(_button(_en.studyDirectionStart));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyEndOtherTitle('Unit')), findsOneWidget);
    expect(opened, isNull);
  });
```

Append to `test/features/study/presentation/study_entry_actions_golden_test.dart`: add `import '../../../support/study_entry_fixtures.dart';` to the imports, and inside the `for (final brightness …)` loop, after the `direction sheet` test:

```dart
    libraryTest('study entry, end the other session, $theme', (
      tester,
      env,
    ) async {
      final leaf = await _sm2(env);
      await openOtherDeckSession(env.db, env.decks, env.entries);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(leaf), brightness);
        await tester.tap(find.text(_en.studyEntryLearn));
        await tester.pumpAndSettle();
        await _golden(tester, 'end_other_session', theme);
      });
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/data/other_deck_session_test.dart test/features/study/presentation/study_entry_controller_test.dart test/features/study/presentation/study_entry_actions_test.dart`
Expected: FAIL to compile: `otherDeckSessionName` is not defined on `StudyEntryRepositoryImpl` or `StudyEntryRepository`, `confirmEnd` is not a parameter of `start`, `studyEndOtherTitle` is not defined on `AppLocalizations`.

- [ ] **Step 3: Implement**

`lib/core/database/queries/study_session_queries.drift` — insert after `closeSessionsStartedBefore` (before `createSession`):

```sql
-- R3 (SP2a 2.01): the deck name of the open session of the current day that
-- Continue could still take up (BR-STUDY-075: at its root's generation, out
-- of the Trash, with a queue row left) and that is not :deck_id's: the
-- session a start on :deck_id would end (BR-STUDY-072). The newest, of two
-- started at once the higher id.
openSessionDeckNameOutside(:deck_id AS TEXT, :start_of_today AS DATETIME):
SELECT d.name FROM study_session s
JOIN deck d ON d.id = s.deck_id
JOIN deck r ON r.id = s.root_id
WHERE s.status = 'in_progress' AND s.started_at >= :start_of_today
  AND s.generation = r.generation
  AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)
  AND s.deck_id <> :deck_id
ORDER BY s.started_at DESC, s.id DESC
LIMIT 1;
```

`study_session_dao.dart` — after `closeStaleSessions`:

```dart
  /// The name of the deck whose open session of today Continue could still
  /// take up and that is not [deckId]'s: what a start on [deckId] would end
  /// (R3, BR-STUDY-072, BR-STUDY-075); null when none.
  Future<String?> otherDeckSessionName(
    String deckId, {
    required DateTime startOfToday,
  }) => openSessionDeckNameOutside(deckId, startOfToday).getSingleOrNull();
```

`study_entry_repository.dart` — append inside the interface, after `watchEntry`:

```dart

  /// R3 (UI hardening SP2a 2.01): the name of the deck whose open session a
  /// start on [deckId] would end: an open session of today, at its root's
  /// generation, out of the Trash and with a queue row left, that is not
  /// [deckId]'s own (BR-STUDY-072, BR-STUDY-075). Null when there is none.
  /// It writes nothing.
  Future<String?> otherDeckSessionName({
    required String deckId,
    DateTime? now,
  });
```

`study_entry_repository_impl.dart` — after `watchEntry`:

```dart

  @override
  Future<String?> otherDeckSessionName({
    required String deckId,
    DateTime? now,
  }) => _dao.otherDeckSessionName(
    deckId,
    startOfToday: startOfLocalDay(now ?? _now()),
  );
```

`find_other_deck_session_use_case.dart`:

```dart
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// R3 (UI hardening SP2a 2.01): before a Learn or a Review, the deck whose
/// open session the start would end, so the person is asked first. Null when
/// none. It writes nothing.
final class FindOtherDeckSessionUseCase {
  const FindOtherDeckSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<String?> call({required String deckId}) =>
      _entries.otherDeckSessionName(deckId: deckId);
}
```

`find_other_deck_session_use_case_provider.dart`:

```dart
import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/find_other_deck_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'find_other_deck_session_use_case_provider.g.dart';

@riverpod
FindOtherDeckSessionUseCase findOtherDeckSessionUseCase(Ref ref) =>
    FindOtherDeckSessionUseCase(ref.watch(studyEntryRepositoryProvider));
```

`study_end_other_session_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// R3: starting here ends the open session of another deck. Completes true to
/// end it and start; false (Keep it, or dismissed) starts nothing. The
/// confirm is the warning tone: nothing is lost, a round is dropped.
Future<bool> showStudyEndOtherSessionDialog(
  BuildContext context, {
  required String deckName,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => StudyEndOtherSessionDialogWidget(deckName: deckName),
    ) ??
    false;

class StudyEndOtherSessionDialogWidget extends StatelessWidget {
  const StudyEndOtherSessionDialogWidget({super.key, required this.deckName});

  /// The deck whose session the start would end.
  final String deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.studyEndOtherTitle(deckName),
      body: l10n.studyEndOtherBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyEndOtherKeep,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyEndOtherConfirm,
        onConfirm: () => Navigator.of(context).pop(true),
        isWarning: true,
      ),
    );
  }
}
```

`study_entry_controller.dart` — imports add `import 'package:memox/features/study/presentation/providers/find_other_deck_session_use_case_provider.dart';`; add the field and replace the head of `start`. Before:

```dart
  @override
  StudyStartState build(String deckId) => const StudyStartState();

  /// Runs [start]; answers the session to open, or null when it was dropped,
  /// refused or failed.
  Future<String?> start(StudyStart start) async {
    if (state.isStarting) return null;
    state = StudyStartState(
```

After:

```dart
  /// The check of another deck's session is running: a second start waits
  /// (BR-STUDY-004) so two dialogs never stack.
  bool _isConfirming = false;

  @override
  StudyStartState build(String deckId) => const StudyStartState();

  /// Runs [start]; answers the session to open, or null when it was dropped,
  /// refused, failed or not confirmed. A Learn or a Review ends the open
  /// session of another deck (BR-STUDY-072); with [confirmEnd] given it asks
  /// first, with that deck's name, and starts nothing on false (R3). Continue
  /// and Try again never ask.
  Future<String?> start(
    StudyStart start, {
    Future<bool> Function(String deckName)? confirmEnd,
  }) async {
    if (state.isStarting || _isConfirming) return null;
    if (confirmEnd != null &&
        start is! ContinueStart &&
        !await _isEndConfirmed(confirmEnd)) {
      return null;
    }
    if (!ref.mounted) return null;
    state = StudyStartState(
```

and add, after `retry()`:

```dart
  /// True when no other deck's session would end, or the person confirmed it.
  Future<bool> _isEndConfirmed(
    Future<bool> Function(String deckName) confirmEnd,
  ) async {
    _isConfirming = true;
    try {
      final other = await ref.read(findOtherDeckSessionUseCaseProvider)(
        deckId: deckId,
      );
      return other == null || await confirmEnd(other);
    } on Failure {
      // The read failed: the start itself meets the same store and reports a
      // failed write, so it is not held back here.
      return true;
    } finally {
      _isConfirming = false;
    }
  }
```

`study_entry_screen.dart` — add `import 'package:memox/features/study/presentation/widgets/overlays/study_end_other_session_dialog_widget.dart';` (alphabetical among the overlays imports) and replace `_start`. Before:

```dart
  Future<void> _start(BuildContext context, WidgetRef ref, StudyStart start) =>
      _open(
        context,
        ref.read(studyEntryControllerProvider(deckId).notifier).start(start),
      );
```

After:

```dart
  Future<void> _start(BuildContext context, WidgetRef ref, StudyStart start) =>
      _open(
        context,
        ref
            .read(studyEntryControllerProvider(deckId).notifier)
            .start(
              start,
              // R3: a Learn or a Review ends another deck's open session.
              confirmEnd: (deckName) async =>
                  context.mounted &&
                  await showStudyEndOtherSessionDialog(
                    context,
                    deckName: deckName,
                  ),
            ),
      );
```

ARB, `app_en.arb` after `studyExitStop`:

```json
  "studyEndOtherTitle": "End your session in {deck}?",
  "@studyEndOtherTitle": {
    "placeholders": {
      "deck": {
        "type": "String"
      }
    },
    "description": "Screen 14 (SP2a 2.01, R3): the confirm title when a start would end the open session of another deck."
  },
  "studyEndOtherBody": "Its answers are kept; the rest of that round is dropped.",
  "@studyEndOtherBody": {
    "description": "Screen 14 (SP2a 2.01): the confirm body; names what is kept and what is dropped."
  },
  "studyEndOtherKeep": "Keep it",
  "@studyEndOtherKeep": {
    "description": "Screen 14 (SP2a 2.01): leaves the other deck's session open and starts nothing."
  },
  "studyEndOtherConfirm": "End it and start",
  "@studyEndOtherConfirm": {
    "description": "Screen 14 (SP2a 2.01): ends the other deck's session and starts this one."
  },
```

`app_vi.arb` after `studyExitStop`:

```json
  "studyEndOtherTitle": "Kết thúc phiên đang học ở {deck}?",
  "studyEndOtherBody": "Các câu đã trả lời được giữ lại; phần còn lại của vòng đó sẽ bị bỏ.",
  "studyEndOtherKeep": "Giữ phiên đó",
  "studyEndOtherConfirm": "Kết thúc và bắt đầu",
```

Then run `flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/data/other_deck_session_test.dart test/features/study/presentation/study_entry_controller_test.dart test/features/study/presentation/study_entry_actions_test.dart test/app/l10n_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/study test/app/study_routes_test.dart`; expected PASS (no existing test starts a session while another deck's is open).

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/queries/study_session_queries.drift \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/domain/repositories/study_entry_repository.dart \
  lib/features/study/data/repositories/study_entry_repository_impl.dart \
  lib/features/study/domain/usecases/find_other_deck_session_use_case.dart \
  lib/features/study/presentation/providers/find_other_deck_session_use_case_provider.dart \
  lib/features/study/presentation/widgets/overlays/study_end_other_session_dialog_widget.dart \
  lib/features/study/presentation/controllers/study_entry_controller.dart \
  lib/features/study/presentation/screens/study_entry_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/features/study/data/other_deck_session_test.dart \
  test/features/study/presentation/study_entry_controller_test.dart \
  test/features/study/presentation/study_entry_actions_test.dart \
  test/features/study/presentation/study_entry_actions_golden_test.dart \
  test/support/study_entry_fixtures.dart
git commit -m "feat(study): ask before a start ends another deck's open session (SP2a 2.01, R3)"
```

---

### Task 2 (A2): The entry's pick, gone state and start hold (2.02, 2.03, 2.04)

**Files:**
- Modify: `lib/features/study/presentation/controllers/study_entry_controller.dart` (add `dismissFailure` after `retry`)
- Modify: `lib/features/study/presentation/controllers/review_mode_pick_controller.dart` (lines 1-16)
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart` (imports lines 1-22; the `AsyncData() =>` arm, lines 62-63; new `_gone` method after `_pick`, lines 52-54)
- Modify: `lib/features/study/presentation/screens/study_entry_screen.dart` (`build`, lines 53-96)
- Modify: `test/support/library_harness.dart` (imports lines 1-37; append a helper after `pumpLibraryScreen`, line 154)
- Test: `test/features/study/presentation/study_entry_controller_test.dart`, `study_entry_actions_test.dart`, `study_entry_screen_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `StudyEntryController.dismissFailure() → void` (a refused or failed start goes back to idle, `lastStart` cleared; a start that is running or an idle state is left alone). `ReviewModePickController.pick` calls it.
- Produces (test support): `pumpLibraryScreenPushed(WidgetTester tester, LibraryEnv env, Widget screen, {List<Override> overrides = const []}) → Future<void>`: pumps a host page with an `open` button, taps it and settles, so `screen` sits on a real stack over a page (Back, covering routes). A3 reuses it.
- Consumes: A1's `start(..., confirmEnd:)` is untouched.

- [ ] **Step 1: Write the failing tests**

`test/support/library_harness.dart` — add `import 'package:memox/shared/widgets/mx_app_shell.dart';` with the other `shared/widgets` imports and append after `pumpLibraryScreen`:

```dart
/// [screen] pushed over a host page, as the router pushes it: Back and a
/// covering route act on a real stack. Pumps the host, taps its `open`
/// button and settles.
Future<void> pumpLibraryScreenPushed(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  await pumpLibraryScreen(
    tester,
    env,
    MxAppShell(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: overrides,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
```

`study_entry_controller_test.dart` — add `import 'package:memox/features/study/presentation/controllers/review_mode_pick_controller.dart';`; append inside `main()`:

```dart
  test('picking a review mode drops a failed start, so Try again cannot '
      'replay the mode picked before (2.02)', () async {
    final leaf = (await insertFiveDue(env.db, env.decks)).id;
    final controller = controllerOf(leaf);
    container.listen(reviewModePickControllerProvider(leaf), (_, _) {});
    env.entries.isFailing = true;

    await controller.start(const ReviewStart(mode: StudyMode.match));
    expect(stateOf(leaf).status, StudyStartStatus.failed);

    container
        .read(reviewModePickControllerProvider(leaf).notifier)
        .pick(StudyMode.guess);

    expect(stateOf(leaf).status, StudyStartStatus.idle);
    expect(stateOf(leaf).lastStart, isNull);
    expect(await controller.retry(), isNull);
    expect(env.entries.opened, 1);
  });

  test('a pick does not drop a start that is running (2.02, BR-STUDY-004)', () async {
    final leaf = (await insertFiveDue(env.db, env.decks)).id;
    final controller = controllerOf(leaf);
    container.listen(reviewModePickControllerProvider(leaf), (_, _) {});
    final gate = Completer<void>();
    env.entries.gate = gate.future;

    final running = controller.start(const ReviewStart(mode: StudyMode.match));
    controller.dismissFailure();
    expect(stateOf(leaf).status, StudyStartStatus.starting);

    gate.complete();
    await running;
  });
```
(add `import 'dart:async';` at the top of that file.)

`study_entry_actions_test.dart` — append inside `main()` (add `import '../../../support/study_fixtures.dart';` is present; add `import 'package:memox/shared/widgets/mx_icon_button.dart';`):

```dart
  libraryTest('picking another review mode after a failed start drops Try '
      'again and the old mode (2.02)', (tester, env) async {
    final leaf = await insertFiveDue(env.db, env.decks);
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(leaf.id, onOpen: (id) => opened = id),
    );
    env.entries.isFailing = true;
    await tester.tap(_button(_en.studyEntryReviewCta(5)));
    await tester.pumpAndSettle();
    expect(_button(_en.studyEntryTryAgain), findsOneWidget);

    await tester.tap(find.text(_en.cardModeGuess));
    await tester.pump();

    expect(_button(_en.studyEntryTryAgain), findsNothing);
    expect(find.text(_en.studyEntryStartFailedTitle), findsNothing);
    env.entries.isFailing = false;
    await tester.tap(_button(_en.studyEntryReviewCta(5)));
    await tester.pumpAndSettle();
    expect(
      (await sessionOf(env.db, opened!)).read<String>('current_mode'),
      'guess',
    );
  });

  libraryTest('while a session opens Back and Study options do nothing '
      '(2.04)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 1, dueCards: 1);
    final gate = Completer<void>();
    env.entries.gate = gate.future;
    var optionsOpened = 0;
    await pumpLibraryScreenPushed(
      tester,
      env,
      StudyEntryScreen(
        deckId: leaf,
        title: const Text('Deck'),
        breadcrumb: const SizedBox.shrink(),
        onOpenSession: (_) {},
        onOpenStudyOptions: () => optionsOpened++,
      ),
    );

    await tester.tap(_button(_en.studyEntryLearn));
    await tester.pump();

    await tester.tap(find.byTooltip(_en.commonBack), warnIfMissed: false);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tap(find.byTooltip(_en.deckStudyOptions), warnIfMissed: false);
    await tester.pump();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(optionsOpened, 0);
    expect(
      tester
          .widget<MxIconButton>(find.widgetWithIcon(MxIconButton, AppIcons.back))
          .onPressed,
      isNull,
    );

    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(_en.commonBack));
    await tester.pumpAndSettle();
    expect(find.byType(StudyEntryScreen), findsNothing);
  });
```
(add `import 'package:memox/core/theme/foundations/app_icons.dart';`.)

`study_entry_screen_test.dart` — append inside `main()`:

```dart
  libraryTest('a deck lost while another route covers its entry shows the gone '
      'state with Back once uncovered (2.03)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await pumpLibraryScreenPushed(tester, env, _screen(root.id));
    final entry = tester.element(find.byType(StudyEntryScreen));
    unawaited(
      Navigator.of(entry).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await env.decks.deleteDeck(deckId: root.id);
    await tester.pumpAndSettle();
    // The one-shot listener holds back under a cover: no toast, no pop.
    expect(find.text(_en.studyEntryDeckGone), findsNothing);

    Navigator.of(entry).pop();
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    await tester.tap(find.text(_en.commonBack));
    await tester.pumpAndSettle();
    expect(find.byType(StudyEntryScreen), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_entry_controller_test.dart test/features/study/presentation/study_entry_actions_test.dart test/features/study/presentation/study_entry_screen_test.dart`
Expected: FAIL. `dismissFailure` is not defined (compile); once stubbed, the 2.02 tests fail (`status` stays `failed`, Try again stays), the 2.03 test finds no `deckGoneTitle` (blank body), the 2.04 test finds the screen popped by the system Back.

- [ ] **Step 3: Implement**

`study_entry_controller.dart` — after `retry()`:

```dart
  /// A new pick drops a refusal or a failure the last start left, so Try
  /// again and the banner do not outlive the mode they were about (2.02). A
  /// start that runs is left alone (BR-STUDY-004).
  void dismissFailure() {
    if (state.status == StudyStartStatus.idle || state.isStarting) return;
    state = const StudyStartState();
  }
```

`review_mode_pick_controller.dart`:

```dart
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_mode_pick_controller.g.dart';

/// The review mode picked on a deck's Study Entry (FE-A6 P3, E1): null
/// until the person picks one, then the offer falls back from it to the
/// first available mode. Not persisted: default review modes belong to
/// Study options (FE-A3). A pick also drops the refusal or failure the last
/// start left, so Try again never replays the mode picked before (2.02).
@riverpod
class ReviewModePickController extends _$ReviewModePickController {
  @override
  StudyMode? build(String deckId) => null;

  void pick(StudyMode mode) {
    state = mode;
    ref.read(studyEntryControllerProvider(deckId).notifier).dismissFailure();
  }
}
```

`study_entry_body_widget.dart` — add `import 'dart:async';` at the top; replace the arm

```dart
      // The screen leaves on notFound (UC-STUDY-001 E1).
      AsyncData() => const <Widget>[],
```

by

```dart
      // The one-shot listener leaves with a toast while the route is
      // current; under another route this is what stays (2.03).
      AsyncData() => [_gone(context)],
```

and add after `_pick`:

```dart
  /// The deck went to the Trash or no longer exists (UC-STUDY-001 E1): the
  /// not-found form with the way back.
  Widget _gone(BuildContext context) {
    final l10n = context.l10n;
    return MxErrorState(
      icon: AppIcons.searchOff,
      title: l10n.deckGoneTitle,
      body: l10n.deckGoneBody,
      retryLabel: l10n.commonBack,
      onRetry: () => unawaited(Navigator.of(context).maybePop()),
      actionIcon: AppIcons.back,
    );
  }
```

`study_entry_screen.dart` — in `build`, after `final l10n = context.l10n;` add `final isStarting = ref.watch(studyEntryControllerProvider(deckId)).isStarting;` and wrap the shell. Before (lines 59-96):

```dart
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        titleWidget: title,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (onOpenStudyOptions case final open?)
            MxIconButton(
              icon: AppIcons.studyOptions,
              semanticLabel: l10n.deckStudyOptions,
              onPressed: open,
            ),
        ],
      ),
```

After:

```dart
    final l10n = context.l10n;
    final isStarting = ref
        .watch(studyEntryControllerProvider(deckId))
        .isStarting;
    // A session is being written: Back or Study options would leave it
    // orphaned (2.04).
    return PopScope(
      canPop: !isStarting,
      child: MxAppShell(
        appBar: MxAppBar(
          titleWidget: title,
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: l10n.commonBack,
            onPressed: isStarting
                ? null
                : () => unawaited(Navigator.of(context).maybePop()),
          ),
          actions: [
            if (onOpenStudyOptions case final open?)
              MxIconButton(
                icon: AppIcons.studyOptions,
                semanticLabel: l10n.deckStudyOptions,
                onPressed: isStarting ? null : open,
              ),
          ],
        ),
```

The tail of `build` (lines 80-96) keeps its arguments and gains one indent level, closing the `MxAppShell` and then the `PopScope`:

```dart
        body: StudyEntryBodyWidget(
          deckId: deckId,
          breadcrumb: breadcrumb,
          onLearn: () => unawaited(_start(context, ref, const LearnStart())),
          onContinue: (sessionId) =>
              unawaited(_start(context, ref, ContinueStart(sessionId))),
        ),
        footer: switch (ref.watch(studyEntryProvider(deckId))) {
          AsyncData(value: Ok(:final value)) => StudyEntryFooterWidget(
            deckId: deckId,
            entry: value,
            onReview: () => unawaited(_review(context, ref, value)),
            onLearn: () => unawaited(_start(context, ref, const LearnStart())),
            onRetry: () => unawaited(_retry(context, ref)),
          ),
          _ => null,
        },
      ),
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_entry_controller_test.dart test/features/study/presentation/study_entry_actions_test.dart test/features/study/presentation/study_entry_screen_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/study test/app/study_routes_test.dart`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/controllers/study_entry_controller.dart \
  lib/features/study/presentation/controllers/review_mode_pick_controller.dart \
  lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart \
  lib/features/study/presentation/screens/study_entry_screen.dart \
  test/support/library_harness.dart \
  test/features/study/presentation/study_entry_controller_test.dart \
  test/features/study/presentation/study_entry_actions_test.dart \
  test/features/study/presentation/study_entry_screen_test.dart
git commit -m "fix(study): a pick drops a failed start, a lost deck shows its state, a running start holds Back (SP2a 2.02-2.04)"
```

---

### Task 3 (A3): Study options — a failed read shows the error, Back with edits asks (2.05, 2.06)

**Files:**
- Modify: `lib/features/settings/presentation/screens/study_options_screen.dart` (imports lines 1-21; `build` lines 41-116)
- Modify: `lib/features/settings/presentation/states/study_options_state.dart` (after `isSaving`, line 33)
- Create: `lib/features/settings/presentation/widgets/overlays/study_options_discard_dialog_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (after `studyOptionsSaved`)
- Test: `test/features/settings/presentation/study_options_screen_test.dart`
- Goldens: none (the new dialog is not golden-tested; the screen's existing goldens do not move).

**Interfaces:**
- Produces: `StudyOptionsState.hasEdits → bool` (a toggle, a limit, an invalid typed limit or an order was changed and not saved).
- Produces: `Future<bool> showStudyOptionsDiscardDialog(BuildContext context)` (true = discard).
- Consumes: A2's `pumpLibraryScreenPushed`; `FlakySettingsRepository.failure` (`test/support/settings_fakes.dart:28`).

Decision notes: the settings feature may not import the card feature's presentation, so the card editor's discard-dialog pattern (`card_discard_dialog_widget.dart`: `showMxDialog<bool>` + `MxSheetActions` with a Keep-editing cancel and a named confirm) is copied with its own strings. The screen stays a `ConsumerWidget`: after the confirm it leaves with `Navigator.pop()`, which a `PopScope(canPop: false)` does not hold back (only `maybePop` and system Back are held).

- [ ] **Step 1: Write the failing tests**

In `study_options_screen_test.dart` add imports `package:memox/features/settings/domain/entities/app_settings_entity.dart`, `package:memox/features/settings/presentation/providers/app_settings_provider.dart`, `package:memox/features/settings/presentation/providers/watch_study_options_use_case_provider.dart`; append inside `main()`:

```dart
  libraryTest('a failed read of the app defaults shows the error instead of '
      'an endless skeleton; Retry reads both again (2.05)', (tester, env) async {
    final ids = await _seed(env);
    var settingsReads = 0;
    var optionsReads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(ids.subId),
      overrides: [
        appSettingsProvider.overrideWith((ref) {
          settingsReads++;
          return Stream<AppSettingsEntity>.error(
            FlakySettingsRepository.failure,
          );
        }),
        studyOptionsProvider(ids.subId).overrideWith((ref) {
          optionsReads++;
          return ref.watch(watchStudyOptionsUseCaseProvider)(
            deckId: ids.subId,
          );
        }),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byType(MxSkeletonList), findsNothing);
    expect(find.text(_en.cardSave), findsNothing);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();
    await tester.pump();

    expect((settingsReads, optionsReads), (2, 2));
  });

  libraryTest('Back with an edited draft asks first: Keep editing stays with '
      'the draft, Discard changes leaves (2.06)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreenPushed(tester, env, _screen(ids.subId));
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();

    await tester.tap(find.byTooltip(_en.commonBack));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyOptionsDiscardTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyOptionsKeepEditing));
    await tester.pumpAndSettle();
    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    expect(tester.widget<MxStepper>(find.byType(MxStepper)).value, 21);

    await tester.tap(find.byTooltip(_en.commonBack));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studyOptionsDiscard));
    await tester.pumpAndSettle();
    expect(find.byType(StudyOptionsScreen), findsNothing);
  });

  libraryTest('Back with nothing edited leaves at once (2.06)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreenPushed(tester, env, _screen(ids.subId));

    await tester.tap(find.byTooltip(_en.commonBack));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyOptionsDiscardTitle), findsNothing);
    expect(find.byType(StudyOptionsScreen), findsNothing);
  });

  libraryTest('Back after a save that landed leaves at once (2.06)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreenPushed(tester, env, _screen(ids.subId));
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(_en.commonBack));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyOptionsDiscardTitle), findsNothing);
    expect(find.byType(StudyOptionsScreen), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/settings/presentation/study_options_screen_test.dart`
Expected: FAIL. Compile error first (`studyOptionsDiscardTitle`, `studyOptionsKeepEditing`, `studyOptionsDiscard` are not defined). With the strings stubbed: the 2.05 test finds a `MxSkeletonList` and no `MxErrorState`; the 2.06 test pops the screen without a dialog.

- [ ] **Step 3: Implement**

`study_options_state.dart` — after `bool get isSaving => …;`:

```dart

  /// Something was changed and not saved: a toggle, a limit (a typed one
  /// outside 1–200 included) or an order. Leaving drops it (2.06).
  bool get hasEdits =>
      isUsingAppDefaults != null ||
      cardLimit != null ||
      isCardLimitInvalid ||
      newCardOrder != null;
```

`study_options_discard_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before Study options is left with changes that Save has not written
/// (2.06), as the card editor asks before a changed form is left. Completes
/// true to discard, false to keep editing.
Future<bool> showStudyOptionsDiscardDialog(BuildContext context) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => const StudyOptionsDiscardDialogWidget(),
    ) ??
    false;

class StudyOptionsDiscardDialogWidget extends StatelessWidget {
  const StudyOptionsDiscardDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.studyOptionsDiscardTitle,
      body: l10n.studyOptionsDiscardBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyOptionsKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyOptionsDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
```

`study_options_screen.dart` — add import `package:memox/features/settings/presentation/widgets/overlays/study_options_discard_dialog_widget.dart`. Replace the whole `build` method (lines 41-116) with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      studyOptionsControllerProvider(deckId).select((s) => s.timesSaved),
      (before, after) {
        if (after > (before ?? 0)) {
          showMxSnackbar(context, message: l10n.studyOptionsSaved);
        }
      },
    );
    final draft = ref.watch(studyOptionsControllerProvider(deckId));
    final settings = ref.watch(appSettingsProvider);
    final appDefaults = settings.value?.studyDefaults;
    final options = ref.watch(studyOptionsProvider(deckId));
    final loaded = switch ((options, appDefaults)) {
      (AsyncData(value: Ok(:final value)), final defaults?) => (
        value,
        StudyOptionsForm.of(value, draft, appDefaults: defaults),
      ),
      _ => null,
    };
    // What Save has not written: Back asks before it drops it (2.06).
    final isDirty = switch (loaded) {
      (_, final StudyOptionsForm form) =>
        draft.hasEdits && (form.isChanged || form.isCardLimitInvalid),
      null => false,
    };
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard(context));
      },
      child: MxAppShell(
        appBar: MxAppBar(
          title: l10n.deckStudyOptions,
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
            breadcrumb,
            Expanded(
              child: switch (options) {
                _ when loaded != null => StudyOptionsFormWidget(
                  deckId: deckId,
                  stored: loaded.$1,
                  form: loaded.$2,
                  rootName: loaded.$1.rootDeckName,
                ),
                AsyncData(value: Rejected()) => _gone(context),
                // Either read failing leaves no form to draw: one error with
                // one Retry for both (2.05).
                _ when options is AsyncError || settings is AsyncError =>
                  MxScreenScroll(
                    children: [
                      MxErrorState(
                        title: l10n.settingsLoadErrorTitle,
                        body: l10n.libraryLoadErrorBody,
                        retryLabel: l10n.commonRetry,
                        onRetry: () {
                          ref.invalidate(studyOptionsProvider(deckId));
                          ref.invalidate(appSettingsProvider);
                        },
                        isRetrying: options.isLoading || settings.isLoading,
                      ),
                    ],
                  ),
                _ => MxScreenScroll(
                  children: [
                    MxSkeletonList(
                      semanticLabel: l10n.commonLoading,
                      rows: _skeletonRows,
                    ),
                  ],
                ),
              },
            ),
          ],
        ),
        footer: switch (loaded) {
          (_, final StudyOptionsForm form) => StudyOptionsFooterWidget(
            deckId: deckId,
            form: form,
          ),
          null => null,
        },
      ),
    );
  }

  /// Back with edits: discard or keep editing (2.06). A confirmed discard
  /// pops the route directly; the guard holds only `maybePop` and system
  /// Back.
  Future<void> _confirmDiscard(BuildContext context) async {
    if (!await showStudyOptionsDiscardDialog(context)) return;
    if (context.mounted) Navigator.of(context).pop();
  }
```

ARB `app_en.arb` after `studyOptionsSaved`:

```json
  "studyOptionsDiscardTitle": "Discard your changes?",
  "@studyOptionsDiscardTitle": {
    "description": "Screen 15 (SP2a 2.06): the confirm title when Back is pressed with unsaved edits."
  },
  "studyOptionsDiscardBody": "Leaving now keeps the options as they were saved.",
  "@studyOptionsDiscardBody": {
    "description": "Screen 15 (SP2a 2.06): the confirm body; names what Back keeps."
  },
  "studyOptionsKeepEditing": "Keep editing",
  "@studyOptionsKeepEditing": {
    "description": "Screen 15 (SP2a 2.06): stays on the screen with the draft."
  },
  "studyOptionsDiscard": "Discard changes",
  "@studyOptionsDiscard": {
    "description": "Screen 15 (SP2a 2.06): drops the draft and leaves; names the loss."
  },
```

`app_vi.arb` after `studyOptionsSaved`:

```json
  "studyOptionsDiscardTitle": "Bỏ các thay đổi?",
  "studyOptionsDiscardBody": "Rời đi bây giờ thì tuỳ chọn giữ nguyên như lần lưu trước.",
  "studyOptionsKeepEditing": "Tiếp tục sửa",
  "studyOptionsDiscard": "Bỏ thay đổi",
```

Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/settings/presentation/study_options_screen_test.dart test/features/settings/presentation/study_options_controller_test.dart test/app/l10n_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings test/app`; expected PASS (the route tests reach Study options without edits).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/screens/study_options_screen.dart \
  lib/features/settings/presentation/states/study_options_state.dart \
  lib/features/settings/presentation/widgets/overlays/study_options_discard_dialog_widget.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/features/settings/presentation/study_options_screen_test.dart
git commit -m "fix(settings): Study options shows a failed read and asks before dropping edits (SP2a 2.05-2.06)"
```

---

### Task 4 (A4): The session screen — a leave during the exit dialog, and a Stop that fails (2.07, 2.08)

**Files:**
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart` (fields lines 66-77; `_abandon`/`_confirmAbandon` lines 87-94; `_leave` lines 202-207; `_onPop` lines 209-219)
- Modify: `lib/features/study/presentation/controllers/study_session_controller.dart` (`abandon`, lines 142-150)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (after `studyExitStop`, after A1's keys)
- Modify: `test/support/study_fixtures.dart` (`LockableSessions`, lines 370-450)
- Test: `test/features/study/presentation/study_session_screen_test.dart`, `study_session_controller_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `Future<bool> StudySessionController.abandon()`: true once the abandon write ran (the session ended, or was already over); false when the write failed and the session stays open.
- Produces (test support): `LockableSessions.isAbandonFailing` (bool): `abandonSession` throws `UnknownDatabaseFailure`.
- Consumes: the exit dialog `showStudyExitDialog` (unchanged).

Semantics: the exit dialog is itself a route, so while it is up the session route is not current and `_leave` cannot run. The leave is remembered and runs when the dialog's future completes; a pending leave wins over Stop (the session is gone, there is nothing to stop). While a confirm is open ✕ does nothing.

- [ ] **Step 1: Write the failing tests**

`test/support/study_fixtures.dart` — in `LockableSessions` add after `var isLocked = false;`:

```dart
  /// While set, [abandonSession] fails as a broken write does (SP2a 2.08).
  var isAbandonFailing = false;
```

and replace the `abandonSession` override:

```dart
  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) async {
    if (isAbandonFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.abandonSession(sessionId: sessionId, now: now);
  }
```

`study_session_controller_test.dart` — append inside `main()`:

```dart
  test('abandon answers true once the session ended, false when the write '
      'failed and the session stays open (2.08)', () async {
    final id = await browsing(['a', 'b']);
    final controller = await controllerOf(id);

    sessions.isAbandonFailing = true;
    expect(await controller.abandon(), isFalse);
    expect(
      (await sessionOf(db, id)).read<String>('status'),
      'in_progress',
    );

    sessions.isAbandonFailing = false;
    expect(await controller.abandon(), isTrue);
    expect((await sessionOf(db, id)).read<String>('status'), 'abandoned');
  });
```

`study_session_screen_test.dart` — append inside `main()`:

```dart
  libraryTest('a deck lost while the exit dialog is open leaves when the '
      'dialog closes, once, with a message (2.07)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    final left = <String?>[];
    await _pumpScreen(tester, env, id, onLeave: left.add);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();
    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();
    // The dialog is a route over this one: the leave waits for it.
    expect(find.text(_en.studyExitTitle), findsOneWidget);
    expect(left, isEmpty);

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(_en.studyEntryDeckGone), findsOneWidget);
  });

  libraryTest('a Stop confirmed after the deck was lost leaves and writes no '
      'abandon (2.07)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    // An abandon that was written would fail and show the Stop toast.
    env.sessions.isAbandonFailing = true;
    final left = <String?>[];
    await _pumpScreen(tester, env, id, onLeave: left.add);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();
    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.studyExitStop));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(_en.studyStopFailed), findsNothing);
  });

  libraryTest('a Stop that fails says so in a toast and the session stays '
      'open (2.08)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    env.sessions.isAbandonFailing = true;
    await _pumpScreen(tester, env, id);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studyExitStop));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyStopFailed), findsOneWidget);
    expect(
      (await sessionOf(env.db, id)).read<String>('status'),
      'in_progress',
    );
    expect(find.byType(MxStudyTopBar), findsOneWidget);
  });

  libraryTest('✕ twice opens one exit dialog, never two (2.08)', (
    tester,
    env,
  ) async {
    final id = await _session(env, ['a', 'b']);
    await _pumpScreen(tester, env, id);
    final close = find.byTooltip(_en.studySessionClose);

    await tester.tap(close);
    await tester.tap(close, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pumpAndSettle();
    // A second dialog would still be there under the first.
    expect(find.text(_en.studyExitTitle), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_session_controller_test.dart test/features/study/presentation/study_session_screen_test.dart`
Expected: FAIL. Compile errors first (`studyStopFailed` undefined; `abandon()` returns `Future<void>`, so `expect(await controller.abandon(), isFalse)` fails to type-check). After stubbing: the 2.07 tests leave `left` empty; the double ✕ finds two dialogs.

- [ ] **Step 3: Implement**

`study_session_controller.dart` — replace `abandon` (lines 142-150):

```dart
  /// ✕ and system Back: the session ends as `user_exit`; its turns stay
  /// (A3, BR-STUDY-014, BR-STUDY-019). The stream then shows the summary.
  /// Answers false when the write failed and the session stays open, so the
  /// screen can say so (2.08); a refusal (the session already ended, or is
  /// gone) is the stream's to show and answers true.
  Future<bool> abandon() async {
    try {
      await ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId);
      return true;
    } on Failure {
      // The session stays open; the next start closes it (BR-STUDY-072).
      return false;
    }
  }
```

`study_session_screen.dart` — fields, after `var _hasLeft = false;` (line 68):

```dart

  /// A leave that arrived while this route was covered (the exit dialog is a
  /// route): remembered, and run when the dialog's future completes (2.07).
  (String, String?)? _pendingLeave;

  /// The exit dialog is open: ✕ and Back do nothing meanwhile (2.08).
  var _isConfirming = false;
```

Replace `_abandon`/`_confirmAbandon` (lines 87-94):

```dart
  /// The ✕ and system Back ask first (spec D8, owner ruling 2026-09-27);
  /// Stop abandons, Keep studying changes nothing. One dialog at a time
  /// (2.08).
  void _abandon() => unawaited(_confirmAbandon());

  Future<void> _confirmAbandon() async {
    if (_isConfirming) return;
    _isConfirming = true;
    final bool shouldStop;
    try {
      shouldStop = await showStudyExitDialog(context);
    } finally {
      _isConfirming = false;
    }
    if (!mounted) return;
    // The deck went, or the session was reset, while the dialog was up: the
    // leave the listener could not run runs now, and there is nothing to
    // stop (2.07).
    final pending = _pendingLeave;
    if (pending != null) {
      _pendingLeave = null;
      _leave(pending.$1, pending.$2);
      return;
    }
    if (!shouldStop) return;
    final didStop = await _controller.abandon();
    if (!didStop && mounted) {
      showMxSnackbar(context, message: context.l10n.studyStopFailed);
    }
  }
```

Replace `_leave` (lines 202-207):

```dart
  void _leave(String message, String? deckId) {
    if (_hasLeft) return;
    // Under the exit dialog the route is not current: keep the leave for
    // when it closes (2.07).
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      _pendingLeave = (message, deckId);
      return;
    }
    _hasLeft = true;
    showMxSnackbar(context, message: message);
    widget.onLeave(deckId);
  }
```

`_onPop` is unchanged (it ends in `_abandon()`, now guarded).

ARB `app_en.arb` after `studyEndOtherConfirm` (A1) or `studyExitStop`:

```json
  "studyStopFailed": "Couldn't stop the session. Your answers are kept; try again.",
  "@studyStopFailed": {
    "description": "Session screen (SP2a 2.08): toast when the Stop write failed and the session stays open."
  },
```

`app_vi.arb`:

```json
  "studyStopFailed": "Không dừng được phiên. Các câu đã trả lời vẫn được giữ; hãy thử lại.",
```

Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_session_controller_test.dart test/features/study/presentation/study_session_screen_test.dart test/app/l10n_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/study test/app/study_routes_test.dart`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/screens/study_session_screen.dart \
  lib/features/study/presentation/controllers/study_session_controller.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/support/study_fixtures.dart \
  test/features/study/presentation/study_session_screen_test.dart \
  test/features/study/presentation/study_session_controller_test.dart
git commit -m "fix(study): a leave during the exit dialog runs when it closes; a failed Stop is said (SP2a 2.07-2.08)"
```

---

### Task 5 (A5): Recall's clock stops under the exit dialog (2.11)

**Files:**
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart` (fields; `_confirmAbandon` from A4; `StudyRecallWidget(` call, lines 370-381; `dispose`)
- Modify: `lib/features/study/presentation/widgets/sections/study_recall_widget.dart` (constructor lines 34-44; `initState` 88-104; `didUpdateWidget` 107-120; `dispose` 122-128; `_onLifecycle` 142-150)
- Test: `test/features/study/presentation/study_recall_test.dart`
- Goldens: none.

**Interfaces:**
- Consumes: A4's `_confirmAbandon`/`_isConfirming`.
- Produces: `StudyRecallWidget({…, required ValueListenable<bool> overlayOpen})`: while true the clock stops and its time left is saved; when it turns false a counting turn runs on. `_StudySessionScreenState` owns the `ValueNotifier<bool> _overlayOpen`.

The notifier is released the moment the dialog closes, even when Stop was confirmed: the turn is then replaced by the summary within a frame or two, and the widget saves its time left on dispose as before.

- [ ] **Step 1: Write the failing tests**

Append inside `main()` of `study_recall_test.dart`:

```dart
  libraryTest('the clock stops under the exit dialog and runs on when it '
      'closes: the turn never times out unseen (2.11)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('15s / 20s'), findsOneWidget);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_en.studyExitTitle), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('15s / 20s'), findsOneWidget);
    // The time left was kept when the clock stopped.
    expect(await _rowOf(env.db, id), (15000, false));

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('14s / 20s'), findsOneWidget);
  });

  libraryTest('a resume from the background does not restart the clock '
      'while the exit dialog is open (2.11)', (tester, env) async {
    final id = await _recall(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _lifecycle(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('15s / 20s'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_recall_test.dart`
Expected: FAIL: after 10 s under the dialog the text reads `5s / 20s` (the clock ran), and the second test reads `12s / 20s`.

- [ ] **Step 3: Implement**

`study_recall_widget.dart` — constructor: add `required this.overlayOpen,` after `required this.onContinue,` and the field:

```dart
  /// True while the session screen has an overlay over the turn (the exit
  /// dialog): the clock stops under it and runs on when it turns false
  /// (2.11).
  final ValueListenable<bool> overlayOpen;
```

State, `initState`: right after `_lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);` add `widget.overlayOpen.addListener(_onOverlay);`. A turn opened while an overlay is already up cannot happen (the dialog is modal), so nothing else.

`didUpdateWidget` — add at its top, after `super.didUpdateWidget(oldWidget);`:

```dart
    if (oldWidget.overlayOpen != widget.overlayOpen) {
      oldWidget.overlayOpen.removeListener(_onOverlay);
      widget.overlayOpen.addListener(_onOverlay);
    }
```

`dispose` — before `_lifecycle.dispose();` add `widget.overlayOpen.removeListener(_onOverlay);`.

`_onLifecycle` — replace the resumed branch:

```dart
    if (state == AppLifecycleState.resumed) {
      // An overlay still holds the clock (2.11).
      if (!widget.overlayOpen.value) unawaited(_clock.reverse());
      return;
    }
```

and add after `_onLifecycle`:

```dart
  /// An overlay (the exit dialog) is over the turn: the clock stops and its
  /// time left is kept; it runs on when the overlay goes (2.11,
  /// BR-STUDY-036).
  void _onOverlay() {
    if (!_isRunning) return;
    if (widget.overlayOpen.value) {
      _clock.stop();
      widget.onSaveTime(_remainingMs);
      return;
    }
    unawaited(_clock.reverse());
  }
```

`study_session_screen.dart` — field after `_isConfirming`:

```dart

  /// Set while the exit dialog is up; Recall's clock follows it (2.11).
  final ValueNotifier<bool> _overlayOpen = ValueNotifier(false);
```

add a `dispose`:

```dart
  @override
  void dispose() {
    _overlayOpen.dispose();
    super.dispose();
  }
```

in `_confirmAbandon` (A4), around the dialog:

```dart
    _isConfirming = true;
    _overlayOpen.value = true;
    final bool shouldStop;
    try {
      shouldStop = await showStudyExitDialog(context);
    } finally {
      _isConfirming = false;
      _overlayOpen.value = false;
    }
```

and in `_modeBody`, the Recall arm gains `overlayOpen: _overlayOpen,` (after `isBusy: turn.isBusy,`).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_recall_test.dart test/features/study/presentation/study_session_screen_test.dart`
Expected: PASS (Recall's existing clock, lifecycle and refused-reveal tests are unchanged).

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/screens/study_session_screen.dart \
  lib/features/study/presentation/widgets/sections/study_recall_widget.dart \
  test/features/study/presentation/study_recall_test.dart
git commit -m "fix(study): Recall's clock stops under the exit dialog (SP2a 2.11)"
```

---

### Task 6 (A6): Settle guards on the summary footer and on Browse's Next (2.09, 2.10)

**Files:**
- Modify: `lib/features/study/presentation/widgets/support/study_settle_guard_widget.dart` (doc lines 8-14; constructor lines 25-30; state lines 34-45)
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` (imports lines 1-15; footer lines 71-94)
- Modify: `lib/features/study/presentation/widgets/sections/study_browse_widget.dart` (imports lines 1-14; the CTA row, lines 126-137)
- Modify: `test/app/study_routes_test.dart` (the Resume test, the line `await _tap(tester, find.text(_en.summaryDone));` that follows `await tester.pump(const Duration(milliseconds: 400));`)
- Modify: `integration_test/it_plat_005_system_back_test.dart` (line 32)
- Test: `test/features/study/presentation/study_settle_guard_test.dart`, `session_summary_test.dart`, `study_browse_test.dart`, `study_session_golden_test.dart`
- Goldens: none move. The summary golden tests are made to wait out the guard before capturing so the footer is painted at full opacity, as today.

**Interfaces:**
- Produces: `StudySettleGuardWidget({…, bool isGuardedAtStart = false})`: when true the first build is guarded too (a row that appears under the finger rather than swapping in place). `phase` keeps its meaning for later swaps.
- Produces: the summary footer's action pair and Browse's Next row inside the guard; Browse keyed on `item.cardId`, the summary on `view.sessionId`.

DECISION: spec §3.1 says "keyed on the summary", but `StudySettleGuardWidget` deliberately does not guard its first build (`study_settle_guard_widget.dart:12-13`), and the summary is a new widget that replaces the session page, so it would never be guarded. Recommended: the `isGuardedAtStart` parameter above (smallest change, same fade as Recall's actions). The guard wraps the action pair, not the whole footer bar, so the bar's ground and caption stay solid.

- [ ] **Step 1: Write the failing tests**

`study_settle_guard_test.dart` — append inside `main()`:

```dart
  testWidgets('a row guarded at its start takes no tap until it has settled, '
      'then takes one (2.09)', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      StudySettleGuardWidget(
        phase: 'summary',
        isGuardedAtStart: true,
        child: MxButton(label: 'Go', onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });
```

`session_summary_test.dart` — add `import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';`. In the first test replace

```dart
    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeck));
    expect((done, again), (1, 1));
```

by

```dart
    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeck));
    expect((done, again), (1, 1));
```

and append inside `main()`:

```dart
  libraryTest("the last answer's double tap cannot reach Done: the footer "
      'takes no tap for 400 ms after the summary appears (2.09)', (
    tester,
    env,
  ) async {
    var done = 0;
    var again = 0;
    await _pump(
      tester,
      env,
      summaryView(),
      SummaryOutcome.reviewFinished,
      onDone: () => done++,
      onStudyDeck: () => again++,
    );

    await tester.tap(
      find.widgetWithText(MxButton, _en.summaryDone),
      warnIfMissed: false,
    );
    await tester.tap(
      find.widgetWithText(MxButton, _en.studyThisDeck),
      warnIfMissed: false,
    );
    expect((done, again), (0, 0));

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    expect(done, 1);
  });
```

`study_browse_test.dart` — add imports `package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart`; append at file end:

```dart
StudyItem _item(String id) => StudyItem(
  cardId: id,
  front: 'front $id',
  back: 'back $id',
  example: null,
  hint: null,
  pronunciation: null,
  round: 1,
  answersInSession: 0,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

/// Browse over a card that a test swaps, counting the advances it asks for.
class _SwapHost extends StatefulWidget {
  const _SwapHost({super.key, required this.onAdvance});

  final VoidCallback onAdvance;

  @override
  State<_SwapHost> createState() => _SwapHostState();
}

class _SwapHostState extends State<_SwapHost> {
  var _card = 'a';

  void next() => setState(() => _card = 'b');

  @override
  Widget build(BuildContext context) => Material(
    child: StudyBrowseWidget(
      view: summaryView(),
      item: _item(_card),
      isBusy: false,
      onAdvance: widget.onAdvance,
    ),
  );
}
```

and inside `main()`:

```dart
  libraryTest('a double tap on Next cannot skip the card that just swapped '
      'in: Next takes no tap for 400 ms after a new card (2.10)', (
    tester,
    env,
  ) async {
    var advances = 0;
    final host = GlobalKey<_SwapHostState>();
    await pumpLibraryScreen(
      tester,
      env,
      _SwapHost(key: host, onAdvance: () => advances++),
    );
    final next = find.widgetWithText(MxButton, _en.studyBrowseNext);

    await tester.tap(next);
    expect(advances, 1);

    host.currentState!.next();
    await tester.pump();
    await tester.tap(next, warnIfMissed: false);
    expect(advances, 1);

    await tester.pump(StudySettleGuardWidget.settle);
    await tester.tap(next);
    expect(advances, 2);
  });
```

`study_session_golden_test.dart` — add `import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';` and in the summary test, between `pumpLibraryGolden(...)` and `expectBoundaryGolden(...)` add `await tester.pump(StudySettleGuardWidget.settle);`.

`test/app/study_routes_test.dart` — add the same import; in the Resume test change

```dart
    await tester.pump(const Duration(milliseconds: 400));
    await _tap(tester, find.text(_en.summaryDone));
```

to

```dart
    await tester.pump(const Duration(milliseconds: 400));
    // The summary's footer takes no tap while it settles (2.09).
    await tester.pump(StudySettleGuardWidget.settle);
    await _tap(tester, find.text(_en.summaryDone));
```

`integration_test/it_plat_005_system_back_test.dart` line 32: before `await tapText(tester, l10n.summaryDone);` add `await tester.pump(const Duration(milliseconds: 400));` (device test; not run on Windows).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_settle_guard_test.dart test/features/study/presentation/session_summary_test.dart test/features/study/presentation/study_browse_test.dart`
Expected: FAIL: `isGuardedAtStart` is not a parameter (compile). With it stubbed: the summary test counts `done == 1` after the unguarded tap, the Browse test counts `advances == 2` after the second immediate tap.

- [ ] **Step 3: Implement**

`study_settle_guard_widget.dart` — doc sentence "The first build is not a swap." becomes "The first build is not a swap, unless [isGuardedAtStart]." Constructor and field:

```dart
  const StudySettleGuardWidget({
    super.key,
    required this.phase,
    required this.child,
    this.isGuardedAtStart = false,
  });

  /// What the row shows; a new value is a swap.
  final Object phase;
  final Widget child;

  /// A row that appears under the finger rather than swapping in place (the
  /// summary's footer after the last answer, 2.09): its first build is
  /// guarded too.
  final bool isGuardedAtStart;
```

and in the state, before `didUpdateWidget`:

```dart
  @override
  void initState() {
    super.initState();
    if (widget.isGuardedAtStart) unawaited(_settle.forward(from: 0));
  }
```

`session_summary_widget.dart` — add `import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';`; wrap the footer's `MxActionPair` in the guard. Before (lines 71-94):

```dart
      footer: MxFooterBar(
        caption: l10n.summaryDoneCaption,
        child: MxActionPair(
          leading: outcome.canStudyAgain
              ? MxButton(
                  label: l10n.studyThisDeck,
                  tone: MxButtonTone.outline,
                  icon: AppIcons.play,
                  isBlock: true,
                  isSingleLine: true,
                  onPressed: onStudyDeck,
                )
              : null,
          trailing: MxButton(
            label: l10n.summaryDone,
            icon: AppIcons.check,
            isBlock: true,
            isSingleLine: true,
            onPressed: onDone,
          ),
          leadingFlex: _studyFlex,
          trailingFlex: _doneFlex,
        ),
      ),
```

After:

```dart
      footer: MxFooterBar(
        caption: l10n.summaryDoneCaption,
        // The last answer's double tap must not reach Done (2.09).
        child: StudySettleGuardWidget(
          phase: view.sessionId,
          isGuardedAtStart: true,
          child: MxActionPair(
            leading: outcome.canStudyAgain
                ? MxButton(
                    label: l10n.studyThisDeck,
                    tone: MxButtonTone.outline,
                    icon: AppIcons.play,
                    isBlock: true,
                    isSingleLine: true,
                    onPressed: onStudyDeck,
                  )
                : null,
            trailing: MxButton(
              label: l10n.summaryDone,
              icon: AppIcons.check,
              isBlock: true,
              isSingleLine: true,
              onPressed: onDone,
            ),
            leadingFlex: _studyFlex,
            trailingFlex: _doneFlex,
          ),
        ),
      ),
```

`study_browse_widget.dart` — add the same import; wrap the CTA row. Before:

```dart
        StudyCtaRowWidget(
          children: [
            MxButton(
              label: l10n.studyBrowseNext,
              size: MxButtonSize.study,
              isBlock: true,
              onPressed: _forward,
            ),
          ],
        ),
```

After:

```dart
        // A card that just swapped in takes no tap meant for the one before
        // it (2.10).
        StudySettleGuardWidget(
          phase: widget.item.cardId,
          child: StudyCtaRowWidget(
            children: [
              MxButton(
                label: l10n.studyBrowseNext,
                size: MxButtonSize.study,
                isBlock: true,
                onPressed: _forward,
              ),
            ],
          ),
        ),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_settle_guard_test.dart test/features/study/presentation/session_summary_test.dart test/features/study/presentation/session_summary_truth_test.dart test/features/study/presentation/study_browse_test.dart test/app/study_routes_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/study test/app`; expected PASS. If another test taps Done or Next right after a manual pump and now misses, add `await tester.pump(StudySettleGuardWidget.settle);` before the tap, as above.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/widgets/support/study_settle_guard_widget.dart \
  lib/features/study/presentation/widgets/sections/session_summary_widget.dart \
  lib/features/study/presentation/widgets/sections/study_browse_widget.dart \
  test/features/study/presentation/study_settle_guard_test.dart \
  test/features/study/presentation/session_summary_test.dart \
  test/features/study/presentation/study_browse_test.dart \
  test/features/study/presentation/study_session_golden_test.dart \
  test/app/study_routes_test.dart \
  integration_test/it_plat_005_system_back_test.dart
git commit -m "fix(study): settle guards on the summary footer and Browse's Next (SP2a 2.09-2.10)"
```

---

### Task 7 (A7): A refused or failed reveal shows the write-failed banner (2.12)

**Files:**
- Modify: `lib/features/study/presentation/states/study_turn_state.dart` (class, lines 5-18)
- Modify: `lib/features/study/presentation/controllers/study_session_controller.dart` (imports lines 1-13; `revealRecall` lines 82-92; `showFillHint` 94-101; `_write` 120-132)
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart` (`_sessionPage`, the banner, lines 305-325)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (after `studyAnswerBusyBody`)
- Modify: `test/support/study_fixtures.dart` (`LockableSessions.revealRecallAnswer`, lines 398-409)
- Test: `test/features/study/presentation/study_session_controller_test.dart`, `study_recall_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `StudyTurnState({…, bool hasWriteFailed = false})`: a reveal that was refused (any `Rejected`) or failed (a `Failure`) leaves the turn idle with this flag set; the next write or answer clears it.
- Produces (test support): `LockableSessions.isRevealFailing`.
- Consumes: A4's screen changes (none are touched here).

DECISION: the spec reuses "the existing unsaved banner". Its copy ("Couldn't save that answer … Your answer is kept — try again.") is wrong for a reveal, which has no answer yet. Recommended: the same danger banner component with reveal copy and no Retry button (the Show the meaning button is the retry, and the clock runs on). Strings: `studyRevealFailedTitle`, `studyRevealFailedBody`. If the owner rules to reuse the busy copy, drop the two keys and use `studyAnswerBusyTitle`/`studyAnswerBusyBody` in the record below.

- [ ] **Step 1: Write the failing tests**

`study_fixtures.dart` — in `LockableSessions` add `var isRevealFailing = false;` (doc: "While set, [revealRecallAnswer] fails as a broken write does (SP2a 2.12).") and replace the `revealRecallAnswer` override:

```dart
  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) async {
    if (isRevealFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.revealRecallAnswer(
      sessionId: sessionId,
      cardId: cardId,
      remainingMs: remainingMs,
      now: now,
    );
  }
```

`study_session_controller_test.dart` — append inside `main()`:

```dart
  test('a failed reveal sets the write-failed flag, the next write clears it '
      '(2.12)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    sessions.isRevealFailing = true;
    await controller.revealRecall(item, 12000);
    var state = container.read(studySessionControllerProvider(id));
    expect((state.hasWriteFailed, state.isBusy), (true, false));
    expect((await servedOf(id)).isRevealed, isFalse);

    sessions.isRevealFailing = false;
    await controller.revealRecall(item, 12000);
    state = container.read(studySessionControllerProvider(id));
    expect(state.hasWriteFailed, isFalse);
    expect((await servedOf(id)).isRevealed, isTrue);
  });

  test('a refused reveal sets the flag too (2.12)', () async {
    final id = await graded(StudyMode.recall);
    final controller = await controllerOf(id);
    final item = await servedOf(id);
    await controller.abandon();

    await controller.revealRecall(item, 12000);

    expect(
      container.read(studySessionControllerProvider(id)).hasWriteFailed,
      isTrue,
    );
  });

  test('a refused fill hint is not flagged: the card may simply have no '
      'hint (2.12)', () async {
    final id = await graded(StudyMode.fill);
    final controller = await controllerOf(id);
    final item = await servedOf(id);
    await controller.abandon();

    await controller.showFillHint(item);

    expect(
      container.read(studySessionControllerProvider(id)).hasWriteFailed,
      isFalse,
    );
  });
```

`study_recall_test.dart` — append inside `main()`:

```dart
  libraryTest('a reveal that fails says so in the banner; the next tap '
      'works and clears it (2.12)', (tester, env) async {
    final id = await _recall(env);
    env.sessions.isRevealFailing = true;
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);

    expect(find.text(_en.studyRevealFailedTitle), findsOneWidget);
    expect(find.text(_en.studyRevealFailedBody), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(find.text('apple'), findsNothing);

    env.sessions.isRevealFailing = false;
    await tester.tap(find.text(_en.studyRecallShowMeaning));
    await _settle(tester);

    expect(find.text(_en.studyRevealFailedTitle), findsNothing);
    expect(find.text('apple'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_session_controller_test.dart test/features/study/presentation/study_recall_test.dart`
Expected: FAIL: `hasWriteFailed` is not defined on `StudyTurnState` and `studyRevealFailedTitle` is not defined (compile). Stubbed: the flag stays false and no banner shows.

- [ ] **Step 3: Implement**

`study_turn_state.dart`:

```dart
final class StudyTurnState {
  const StudyTurnState({
    this.isBusy = false,
    this.held,
    this.unsaved,
    this.hasWriteFailed = false,
  });

  /// A write is running; every other command is dropped (BR-STUDY-004).
  final bool isBusy;

  /// A graded turn's item and result, on screen until its mode releases it
  /// (spec D5).
  final HeldTurn? held;

  /// The answer a busy database refused, kept for Retry (UC-STUDY-001 E2).
  final PendingAnswer? unsaved;

  /// A reveal was refused or failed: nothing changed and the person is told
  /// (2.12). The next write or answer clears it.
  final bool hasWriteFailed;
}
```

`study_session_controller.dart` — add `import 'package:memox/features/study/domain/failures/study_failure.dart';`. Replace `revealRecall`, keep `showFillHint`, replace `_write`:

```dart
  /// `recall`: shows [item]'s meaning with [remainingMs] left; records no
  /// outcome (BR-STUDY-065, BR-STUDY-036). The stream shows it revealed. A
  /// refusal or a failure leaves the turn as it was, to be tapped again, and
  /// sets [StudyTurnState.hasWriteFailed] so the screen says so (2.12).
  /// Dropped while a write runs (BR-STUDY-004).
  Future<void> revealRecall(StudyItem item, int remainingMs) => _write(
    () => ref.read(revealRecallAnswerUseCaseProvider)(
      sessionId: sessionId,
      cardId: item.cardId,
      remainingMs: _turnTime(remainingMs),
    ),
    flagsFailure: true,
  );
```

```dart
  /// One write with no outcome to hold: busy while it runs, then back to
  /// idle whatever happened; the stream shows what changed. With
  /// [flagsFailure] a refusal or a failure is said (2.12).
  Future<void> _write(
    Future<Outcome<void, StudyRejection>> Function() command, {
    bool flagsFailure = false,
  }) async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    var hasFailed = false;
    try {
      hasFailed = await command() is Rejected;
    } on Failure {
      hasFailed = true;
    }
    if (!ref.mounted) return;
    state = StudyTurnState(hasWriteFailed: flagsFailure && hasFailed);
  }
```

`study_session_screen.dart` — in `_sessionPage`, after `final mode = l10n.studyMode(view.currentMode);` add:

```dart
    // A busy database refused an answer (Retry saves it), or a reveal was
    // refused or failed (the Show the meaning button is its retry, 2.12).
    final isAnswerUnsaved = turn.unsaved != null;
    final (bannerTitle, bannerBody) = isAnswerUnsaved
        ? (l10n.studyAnswerBusyTitle, l10n.studyAnswerBusyBody)
        : (l10n.studyRevealFailedTitle, l10n.studyRevealFailedBody);
```

and replace the banner block (`if (turn.unsaved != null) Padding(…)`):

```dart
          if (isAnswerUnsaved || turn.hasWriteFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.grouped,
              ),
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                title: bannerTitle,
                message: bannerBody,
                actions: [
                  if (isAnswerUnsaved)
                    MxButton(
                      label: l10n.commonRetry,
                      size: MxButtonSize.compact,
                      onPressed: _retry,
                    ),
                ],
              ),
            ),
```

ARB `app_en.arb` after `studyAnswerBusyBody`:

```json
  "studyRevealFailedTitle": "Couldn't show the meaning",
  "@studyRevealFailedTitle": {
    "description": "Session screen (SP2a 2.12): banner title when the Recall reveal was refused or failed."
  },
  "studyRevealFailedBody": "Nothing was lost. Tap Show the meaning to try again.",
  "@studyRevealFailedBody": {
    "description": "Session screen (SP2a 2.12): banner message for a failed Recall reveal; the button is the retry."
  },
```

`app_vi.arb`:

```json
  "studyRevealFailedTitle": "Chưa hiện được nghĩa",
  "studyRevealFailedBody": "Chưa mất gì. Hãy bấm Hiện nghĩa để thử lại.",
```

Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_session_controller_test.dart test/features/study/presentation/study_recall_test.dart test/features/study/presentation/study_session_screen_test.dart test/app/l10n_test.dart`
Expected: PASS (the E2 busy-answer banner test is unchanged: it still shows Retry).

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/states/study_turn_state.dart \
  lib/features/study/presentation/controllers/study_session_controller.dart \
  lib/features/study/presentation/screens/study_session_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/support/study_fixtures.dart \
  test/features/study/presentation/study_session_controller_test.dart \
  test/features/study/presentation/study_recall_test.dart
git commit -m "fix(study): a refused or failed Recall reveal shows the write banner (SP2a 2.12)"
```

---

### Task 8 (A8): The Fill field turns off autocorrect and suggestions (2.13)

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart` (the `TextField(` call, lines 270-290)
- Test: `test/shared/widgets/mx_text_field_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `MxTextFieldVariant.study` builds its `TextField` with `autocorrect: false` and `enableSuggestions: false`; every other variant keeps the platform defaults (true).

- [ ] **Step 1: Write the failing test**

Append inside `main()` of `mx_text_field_test.dart`:

```dart
  testWidgets('study turns off autocorrect and suggestions, so the keyboard '
      'neither reveals nor changes the answer; every other variant keeps '
      'them (2.13)', (tester) async {
    for (final variant in MxTextFieldVariant.values) {
      await pumpMx(
        tester,
        SizedBox(width: 300, child: MxTextField(variant: variant)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final isStudy = variant == MxTextFieldVariant.study;

      expect(field.autocorrect, !isStudy, reason: variant.name);
      expect(field.enableSuggestions, !isStudy, reason: variant.name);
    }
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/widgets/mx_text_field_test.dart`
Expected: FAIL: `Expected: false, Actual: true` for variant `study` (reason `study`).

- [ ] **Step 3: Implement**

In the `TextField(` call of `_field`, after `textInputAction: textInputAction,` (line 274) add:

```dart
      // A typed study answer is the person's own: the keyboard must not
      // suggest it, nor correct it (2.13).
      autocorrect: !isBare,
      enableSuggestions: !isBare,
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/shared/widgets/mx_text_field_test.dart test/features/study/presentation/study_fill_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_text_field.dart test/shared/widgets/mx_text_field_test.dart
git commit -m "fix(ui): the study field turns off autocorrect and suggestions (SP2a 2.13)"
```

---

### Task 9 (A9): The summary stays when its deck is lost (2.51)

**Files:**
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart` (fields; `_onView` lines 170-188; `_onPop` 209-219; `build` 221-239; `_pageOf` 260-269)
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` (constructor lines 21-27; footer `leading`, lines 74-83)
- Test: `test/features/study/presentation/study_session_screen_test.dart`
- Goldens: none.

**Interfaces:**
- Consumes: A6's guard in the summary footer; A4's `_leave`/`_pendingLeave` (untouched).
- Produces: `SessionSummaryWidget({…, bool canStudyDeck = true})`: false hides "Study this deck". `_StudySessionScreenState._shownSummary`: the summary last drawn, kept when the stream turns `Rejected` (deck lost), drawn with `canStudyDeck: false`; Done and system Back then call `onLeave(null)` (the Library).

DECISION: Done on a lost deck calls `onLeave(null)` rather than `onDone(deckId)`: `onDone` goes to the deck's route, which no longer exists. Recommended as written; `onLeave(null)` shows no toast (the summary already stands there).

- [ ] **Step 1: Write the failing tests**

In `study_session_screen_test.dart` add `import 'package:memox/shared/widgets/mx_button.dart';` and append:

```dart
/// A session stopped to its summary, then its deck sent to the Trash: the
/// summary is on screen when the deck is lost (2.51).
Future<void> _summaryOverLostDeck(
  WidgetTester tester,
  LibraryEnv env,
  String id, {
  required ValueChanged<String> onDone,
  required ValueChanged<String?> onLeave,
}) async {
  await _pumpScreen(tester, env, id, onDone: onDone, onLeave: onLeave);
  await _swipeLeft(tester);
  await tester.tap(find.byTooltip(_en.studySessionClose));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.studyExitStop));
  await tester.pumpAndSettle();
  expect(find.text(_en.summaryLeftEarly), findsOneWidget);
  expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsOneWidget);

  final session = await sessionOf(env.db, id);
  await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
  await tester.pumpAndSettle();
}

void main() {
  // … the file's existing tests, then:

  libraryTest('a summary on screen stays when its deck is lost: Study this '
      'deck goes, Done still leaves for the Library (2.51)', (
    tester,
    env,
  ) async {
    final id = await _session(env, ['a', 'b']);
    final left = <String?>[];
    final done = <String>[];
    await _summaryOverLostDeck(
      tester,
      env,
      id,
      onDone: done.add,
      onLeave: left.add,
    );

    expect(find.text(_en.summaryLeftEarly), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsNothing);
    expect(find.text(_en.studyEntryDeckGone), findsNothing);
    expect(left, isEmpty);

    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.pumpAndSettle();
    expect((left, done), ([null], isEmpty));
  });

  libraryTest('system Back on a summary kept over a lost deck is Done '
      '(2.51)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    final left = <String?>[];
    await _summaryOverLostDeck(
      tester,
      env,
      id,
      onDone: (_) {},
      onLeave: left.add,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.studyExitTitle), findsNothing);
    expect(left, [null]);
  });
}
```

(`_summaryOverLostDeck` goes at file level beside `_session` and `_pumpScreen`; the two tests go inside the file's existing `main()`.)

`session_summary_test.dart` — append inside `main()`:

```dart
  libraryTest('canStudyDeck false drops Study this deck and keeps Done '
      '(2.51)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SessionSummaryWidget(
        view: summaryView(),
        outcome: SummaryOutcome.reviewFinished,
        canStudyDeck: false,
        onDone: () {},
        onStudyDeck: () {},
      ),
    );

    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsNothing);
    expect(find.widgetWithText(MxButton, _en.summaryDone), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_session_screen_test.dart test/features/study/presentation/session_summary_test.dart`
Expected: FAIL: `canStudyDeck` is not a parameter (compile). Stubbed: the screen test leaves with the deck-gone toast (`left == [null]` already, summary replaced by a blank page, `find.text(summaryLeftEarly)` finds nothing).

- [ ] **Step 3: Implement**

`session_summary_widget.dart` — constructor and field:

```dart
  const SessionSummaryWidget({
    super.key,
    required this.view,
    required this.outcome,
    required this.onDone,
    required this.onStudyDeck,
    this.canStudyDeck = true,
  });
  …
  /// The deck's Study Entry (handoff 21 ruling).
  final VoidCallback onStudyDeck;

  /// False once the deck is gone: Study this deck has nowhere to go and is
  /// not drawn (2.51).
  final bool canStudyDeck;
```

and in the footer: `leading: outcome.canStudyAgain ? MxButton(` becomes `leading: outcome.canStudyAgain && canStudyDeck ? MxButton(`.

`study_session_screen.dart` — field after `_lastOpenView`:

```dart

  /// The summary last drawn. When its deck is lost the stream turns
  /// `Rejected`; the summary stays, without Study this deck, and Done leaves
  /// for the Library (2.51).
  ({StudySessionView view, SummaryOutcome outcome})? _shownSummary;
```

`_onView` — replace the first case:

```dart
      // A summary on screen stays (2.51); an open session whose deck is gone
      // leaves with a word (A5).
      case AsyncData(value: Rejected()) when _shownSummary == null:
        _leave(l10n.studyEntryDeckGone, null);
```

`_onPop` — after the `ShowSummary` branch and before `_abandon();` insert:

```dart
    // A summary kept over a lost deck: Back is Done (2.51).
    if (_shownSummary != null) {
      widget.onLeave(null);
      return;
    }
```

`build` — replace the arm `AsyncData() => const MxAppShell(body: SizedBox.shrink()),`:

```dart
      // The deck is gone: the listener leaves, unless a summary is on
      // screen, which stays (2.51).
      AsyncData() => switch (_shownSummary) {
        final shown? => _summaryPage(
          shown.view,
          shown.outcome,
          isDeckLost: true,
        ),
        null => const MxAppShell(body: SizedBox.shrink()),
      },
```

`_pageOf` — replace the `ShowSummary` arm:

```dart
      ShowSummary(:final outcome) => _summaryPage(
        view,
        outcome,
        isDeckLost: false,
      ),
```

and add:

```dart
  Widget _summaryPage(
    StudySessionView view,
    SummaryOutcome outcome, {
    required bool isDeckLost,
  }) {
    _shownSummary = (view: view, outcome: outcome);
    return SessionSummaryWidget(
      view: view,
      outcome: outcome,
      canStudyDeck: !isDeckLost,
      // The deck's route is gone with it: Done leaves for the Library.
      onDone: () => isDeckLost ? widget.onLeave(null) : widget.onDone(view.deckId),
      onStudyDeck: () => widget.onStudyDeck(view.deckId),
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_session_screen_test.dart test/features/study/presentation/session_summary_test.dart test/features/study/presentation/session_summary_truth_test.dart`
Expected: PASS (the A5 test "the deck moved to the Trash leaves once" still passes: no summary is on screen).

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/screens/study_session_screen.dart \
  lib/features/study/presentation/widgets/sections/session_summary_widget.dart \
  test/features/study/presentation/study_session_screen_test.dart \
  test/features/study/presentation/session_summary_test.dart
git commit -m "fix(study): the summary stays when its deck is lost; only Study this deck goes (SP2a 2.51)"
```

---

### Task 10 (A10): Resume's refused and failed toasts keep local-first words (2.49)

**Files:**
- Modify: `lib/features/study/presentation/screens/study_home_screen.dart` (`_resume`, lines 151-154)
- Modify: `lib/l10n/app_en.arb` (`studyHomeResumeRefused`, line 4461), `lib/l10n/app_vi.arb` (line 851)
- Modify: `test/support/study_fixtures.dart` (`LockableSessions.resumeSession`, lines 441-445)
- Test: `test/features/study/presentation/study_home_screen_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `studyHomeResumeRefused` now "This session can't be continued. Your answers are kept."; new `studyHomeResumeFailed` "Couldn't open the session. Nothing was lost; try Resume again." (the failed branch used `studyEntryStartFailedTitle`, which is the entry's banner title).
- Produces (test support): `LockableSessions.isResumeFailing`.

- [ ] **Step 1: Write the failing tests**

`study_fixtures.dart` — in `LockableSessions` add `var isResumeFailing = false;` ("While set, [resumeSession] fails as a broken write does (SP2a 2.49).") and replace the `resumeSession` override:

```dart
  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) async {
    if (isResumeFailing) throw const UnknownDatabaseFailure(cause: 'test');
    return _inner.resumeSession(sessionId: sessionId, now: now);
  }
```

`study_home_screen_test.dart` — in the existing test "a refused Resume says so and opens nothing" add after the existing `expect(find.text(_en.studyHomeResumeRefused), findsOneWidget);`:

```dart
    expect(_en.studyHomeResumeRefused, contains('answers are kept'));
```

and append inside `main()`:

```dart
  libraryTest('a Resume whose write fails says nothing was lost and to try '
      'again, and opens nothing (H3, 2.49)', (tester, env) async {
    final taps = _Taps();
    await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
    await pumpLibraryScreen(tester, env, _screen(taps));
    await _settle(tester);
    env.sessions.isResumeFailing = true;

    await tester.tap(find.text(_en.studyHomeResume));
    await _settle(tester);

    expect(taps.sessions, isEmpty);
    expect(find.text(_en.studyHomeResumeFailed), findsOneWidget);
    expect(find.text(_en.studyEntryStartFailedTitle), findsNothing);
    expect(_en.studyHomeResumeFailed, contains('Nothing was lost'));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/study/presentation/study_home_screen_test.dart`
Expected: FAIL: `studyHomeResumeFailed` is not defined (compile); stubbed, `studyHomeResumeRefused` does not contain "answers are kept".

- [ ] **Step 3: Implement**

`study_home_screen.dart`:

```dart
      case ResumeFailed():
        showMxSnackbar(context, message: l10n.studyHomeResumeFailed);
```

`app_en.arb` — change the value of `studyHomeResumeRefused` to `"This session can't be continued. Your answers are kept."` and add after its `@` block:

```json
  "studyHomeResumeFailed": "Couldn't open the session. Nothing was lost; try Resume again.",
  "@studyHomeResumeFailed": {
    "description": "Screen handoff 13 (SP2a 2.49): toast when the Resume write failed; local-first."
  },
```

`app_vi.arb` — `"studyHomeResumeRefused": "Không thể tiếp tục phiên này. Các câu đã trả lời vẫn được giữ.",` followed by:

```json
  "studyHomeResumeFailed": "Không mở được phiên. Chưa mất gì; hãy thử Học tiếp lại.",
```

Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study/presentation/study_home_screen_test.dart test/app/l10n_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/screens/study_home_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/support/study_fixtures.dart \
  test/features/study/presentation/study_home_screen_test.dart
git commit -m "fix(study): Resume's refused and failed toasts say the answers are kept (SP2a 2.49)"
```

---

### Task 11 (A11): Progress keeps the last figures on a stream error and shows a banner (2.50)

**Files:**
- Create: `lib/features/progress/presentation/widgets/sections/progress_stale_banner_widget.dart`
- Modify: `lib/features/progress/presentation/screens/progress_screen.dart` (imports lines 1-20; `build` lines 36-61)
- Modify: `lib/features/progress/presentation/screens/deck_progress_screen.dart` (imports lines 1-21; `build` lines 43-89)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (after `progressErrorBody`)
- Test: `test/features/progress/presentation/progress_screen_test.dart`, `deck_progress_screen_test.dart`, `progress_golden_test.dart`
- Goldens: adds `progress_stale_{light,dark}.png` (new, Linux run); moves none.

**Interfaces:**
- Produces: `ProgressStaleBannerWidget({required VoidCallback onRetry, required bool isRetrying})`: the warning `MxInlineBanner` (title `progressStaleTitle`, message `progressStaleBody`, compact Retry that spins while `isRetrying`).
- Behaviour: a `progressProvider` / `deckProgressProvider` error that arrives after a value keeps drawing that value and puts the banner above it; with no value yet the full error page stays (and its Retry-spinner test is unchanged). A deck level that was `ProgressDeckMissing` is not a figure, so an error after it still shows the error page.

Assumption checked by the first test below: Riverpod 3 keeps the previous value on an `AsyncError` (`value` stays readable; `hasError` is true; `isLoading` is true while the refresh runs). If the test shows the value is dropped, the screens must read the last value through `ref.listen` instead; the test fails loudly rather than silently.

- [ ] **Step 1: Write the failing tests**

`progress_screen_test.dart` — add imports `package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart`, `package:memox/shared/widgets/mx_error_state.dart`, `package:memox/shared/widgets/mx_inline_banner.dart`; append inside `main()`:

```dart
  libraryTest('a failed refresh keeps the figures last read and shows a '
      'warning banner with Retry; the error page is for no value yet '
      '(2.50)', (tester, env) async {
    await progressLibrary(env);
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      overrides: [
        progressProvider.overrideWith((ref) async* {
          reads++;
          yield await ref.watch(watchProgressUseCaseProvider)().first;
          throw StateError('refresh failed');
        }),
      ],
    );
    await _settle(tester);

    expect(find.text('17'), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
    final banner = find.widgetWithText(MxInlineBanner, _en.progressStaleTitle);
    expect(banner, findsOneWidget);
    expect(tester.widget<MxInlineBanner>(banner).tone, MxBannerTone.warning);
    expect(find.text(_en.progressStaleBody), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(reads, 2);
    expect(find.text('17'), findsOneWidget);
    expect(banner, findsOneWidget);
  });
```

`deck_progress_screen_test.dart` — add imports `package:memox/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart`, `package:memox/shared/widgets/mx_error_state.dart`, `package:memox/shared/widgets/mx_inline_banner.dart`; append inside `main()`:

```dart
  libraryTest('a failed refresh keeps the deck level last read and shows the '
      'warning banner with Retry (2.50)', (tester, env) async {
    final korean = await studiedDeck(
      env,
      'Korean',
      days: [(daysAgo: 0, learning: 1, reviewing: 2)],
    );
    await env.decks.sub(korean, 'Grammar');
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(korean, _Taps()),
      overrides: [
        deckProgressProvider(korean).overrideWith((ref) async* {
          reads++;
          yield await ref.watch(watchDeckProgressUseCaseProvider)(korean).first;
          throw StateError('refresh failed');
        }),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.progressWholeDeck), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
    expect(
      find.widgetWithText(MxInlineBanner, _en.progressStaleTitle),
      findsOneWidget,
    );

    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(reads, 2);
    expect(find.text(_en.progressWholeDeck), findsOneWidget);
  });
```

`progress_golden_test.dart` — add import `package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart`; inside the `for (final brightness …)` loop after the `error` test add:

```dart
    libraryTest('progress, stale after a failed refresh, $theme', (
      tester,
      env,
    ) async {
      await progressLibrary(env);
      await shoot(
        tester,
        env,
        'stale',
        overrides: [
          progressProvider.overrideWith((ref) async* {
            yield await ref.watch(watchProgressUseCaseProvider)().first;
            throw StateError('refresh failed');
          }),
        ],
      );
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/progress/presentation/progress_screen_test.dart test/features/progress/presentation/deck_progress_screen_test.dart`
Expected: FAIL: `progressStaleTitle` is not defined (compile). Stubbed: the screens show `MxErrorState` and no `17`.

- [ ] **Step 3: Implement**

`progress_stale_banner_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// A refresh of Progress failed after figures were read: the figures stay and
/// this says so, local-first (2.50). Warning: nothing was lost.
class ProgressStaleBannerWidget extends StatelessWidget {
  const ProgressStaleBannerWidget({
    super.key,
    required this.onRetry,
    required this.isRetrying,
  });

  final VoidCallback onRetry;

  /// The reload runs: Retry spins.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      title: l10n.progressStaleTitle,
      message: l10n.progressStaleBody,
      actions: [
        MxButton(
          label: l10n.commonRetry,
          size: MxButtonSize.compact,
          isLoading: isRetrying,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
```

`progress_screen.dart` — add `import 'package:memox/features/progress/presentation/widgets/sections/progress_stale_banner_widget.dart';`; replace the head of `build` (lines 38-56):

```dart
    final l10n = context.l10n;
    final read = ref.watch(progressProvider);
    // Once shown, a new snapshot only replaces the numbers (FE-A9 D8); a
    // failed refresh keeps them and says so (2.50).
    final children = switch (read) {
      AsyncValue(:final value?) => [
        if (read.hasError)
          ProgressStaleBannerWidget(
            onRetry: () => ref.invalidate(progressProvider),
            isRetrying: read.isLoading,
          ),
        ..._loaded(context, value),
      ],
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          // A local read failed, not the network (critique 2026-09-30).
          icon: AppIcons.alert,
          title: l10n.progressErrorTitle,
          // The reason by the kind of failure, never its cause
          // (UC-PROGRESS-001 E1, BR-CORE-005).
          body: error is Failure ? l10n.failure(error) : l10n.progressErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(progressProvider),
          isRetrying: isLoading,
        ),
      ],
      _ => [ProgressSkeletonWidget(semanticLabel: l10n.progressLoading)],
    };
```

`deck_progress_screen.dart` — add the same import; replace lines 45-67 (`read`, `level`, and the first two arms) with:

```dart
    final read = ref.watch(deckProgressProvider(deckId));
    // The last level read stays through a failed refresh (2.50).
    final level = switch (read.value) {
      final DeckProgressLevel level => level,
      _ => null,
    };
    final Widget body = switch (read) {
      _ when level != null => MxScreenScroll(
        children: [
          if (read.hasError)
            ProgressStaleBannerWidget(
              onRetry: () => ref.invalidate(deckProgressProvider(deckId)),
              isRetrying: read.isLoading,
            ),
          const ProgressRangeWidget(),
          const SizedBox(height: AppSpacing.gutter),
          ProgressLevelListWidget(
            level: level.level,
            isDeckLevel: true,
            onOpenDeck: onOpenDeck,
          ),
        ],
      ),
      AsyncError(:final error, :final isLoading) => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.progressErrorTitle,
            // The reason by the kind of failure, never its cause
            // (UC-PROGRESS-002 E1, BR-CORE-005).
            body: error is Failure
                ? l10n.failure(error)
                : l10n.progressErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(deckProgressProvider(deckId)),
            isRetrying: isLoading,
          ),
        ],
      ),
```

and delete the old `_ when level != null => MxScreenScroll(…)` arm that followed (its content moved above); `AsyncValue(value: ProgressDeckMissing()) => _gone(context)` and the skeleton arm are unchanged.

ARB `app_en.arb` after `progressErrorBody`:

```json
  "progressStaleTitle": "Couldn't refresh your progress",
  "@progressStaleTitle": {
    "description": "Screen handoff 22 (SP2a 2.50): warning banner title when a refresh failed after figures were read."
  },
  "progressStaleBody": "These are the figures last read. Your study history is safe on this device.",
  "@progressStaleBody": {
    "description": "Screen handoff 22 (SP2a 2.50): the banner's message; local-first."
  },
```

`app_vi.arb` after `progressErrorBody`:

```json
  "progressStaleTitle": "Chưa cập nhật được tiến độ",
  "progressStaleBody": "Đây là số liệu của lần đọc gần nhất. Lịch sử học vẫn an toàn trên thiết bị này.",
```

Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/progress/presentation/progress_screen_test.dart test/features/progress/presentation/deck_progress_screen_test.dart test/app/l10n_test.dart`
Expected: PASS, including the existing "a failed read shows the error; Retry reads again", "says what failed, by the kind of failure" and "while a Retry reloads, the error stays and its Retry spins" tests (no value yet, so the error page is unchanged). Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/progress test/app/progress_routes_test.dart`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/presentation/widgets/sections/progress_stale_banner_widget.dart \
  lib/features/progress/presentation/screens/progress_screen.dart \
  lib/features/progress/presentation/screens/deck_progress_screen.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/features/progress/presentation/progress_screen_test.dart \
  test/features/progress/presentation/deck_progress_screen_test.dart \
  test/features/progress/presentation/progress_golden_test.dart
git commit -m "fix(progress): a failed refresh keeps the last figures and shows a banner (SP2a 2.50)"
```

---

---

### Task 12 (B1): `card_draft` table, schema 12 → 13, upgrade tests, local reset

**Files:**
- Modify: `lib/core/database/tables/ui_state.drift` (append after the `dismissed_note` table, line 8)
- Modify: `lib/core/database/app_database.dart:37` (`schemaVersion`) and after the `from11To12` step (ends at line 185)
- Modify: `lib/core/database/local_data_reset.dart:30` (the table loop)
- Generated and committed: `drift_schemas/drift_schema_v13.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema.dart`, `test/drift/generated/schema_v13.dart`
- Modify: `test/drift/migration_test.dart` (header comment, the "schema of v12" tests, lines 110–190)
- Create: `test/drift/card_draft_migration_test.dart`
- Modify: `test/core/database/local_data_reset_test.dart` (`_seed` and the table list in the first test)
- Modify: `docs/shared/data/schema.md` (new section after `## dismissed_note (schema 11)`, line 630)

**Interfaces:**
- Produces: generated row class `CardDraftRow`, table accessor `AppDatabase.cardDraft`, `schema.cardDraft` in the step-by-step schemas. Task B2 builds its queries on them.
- Goldens: none.

- [ ] **Step 1: Write the failing tests**

Create `test/drift/card_draft_migration_test.dart`:

```dart
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// SP2a R9: v13 adds card_draft, the card being written, kept on this device
// only. Nothing else changes: existing settings keep their values and the
// table starts empty.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v12 upgrades to v13 with its rows intact and no draft', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase.execute(
      "INSERT INTO app_settings (id, card_limit, theme_mode, updated_at) "
      "VALUES (1, 35, 'dark', 0)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 13);

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.cardLimit, 35);
    expect(settings.themeMode, 'dark');
    expect(await db.select(db.cardDraft).get(), isEmpty);
  });

  test('a draft is one row per key and queues nothing for sync', () async {
    final db = AppDatabase(await verifier.startAt(13));
    addTearDown(db.close);
    const insert =
        "INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at) "
        "VALUES ('create:d', 'f', 'b', '{}', '[]', 0)";
    await db.customStatement(insert);

    expect(() => db.customStatement(insert), throwsA(anything));
    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });
}
```

In `test/core/database/local_data_reset_test.dart`:

1. In `_seed`, add one statement after the `account_transition` insert (line 30):

```dart
    "INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at) VALUES ('create:C', 'f', 'b', '{}', '[]', 0)",
```

2. In the first test's table list (lines 49–59), add `'card_draft',` after `'sync_rejection',`.

In `test/drift/migration_test.dart`:

1. Header comment: replace `the account state, the account transition and the welcome flag (auth spec §4).` with `the account state, the account transition and the welcome flag (auth spec §4); v13 keeps the card being written on the device (SP2a R9).`
2. Run `sed -i 's/migrateAndValidate(db, 12)/migrateAndValidate(db, 13)/; s/schema of v12/schema of v13/; s/schema of v10, the one an upgrade ends at/schema of v13, the one an upgrade ends at/' test/drift/migration_test.dart`.
3. After the test `'v11 upgrades to the schema of v13'` (it was `v12` before the sed), add:

```dart
  test('v12 upgrades to the schema of v13', () async {
    final db = AppDatabase(await verifier.startAt(12));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);
  });
```

(`account_migration_test.dart`, `nfc_migration_test.dart` and `sync_seed_migration_test.dart` migrate to 12 on purpose and stay as they are: `migrateAndValidate(db, n)` runs the steps up to `n` only.)

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/drift/card_draft_migration_test.dart test/core/database/local_data_reset_test.dart`
Expected: FAIL. The migration test throws `MissingSchemaException` for version 13; the reset test fails with `no such table: card_draft`.

- [ ] **Step 3: Implement**

3a. Append to `lib/core/database/tables/ui_state.drift`:

```sql

-- The card being written, kept on this device so a killed process, a refused
-- save or a card deleted elsewhere loses no text (SP2a R9). draft_key is
-- `create:<deckId>` or `edit:<cardId>`; extras is JSON (example, hint,
-- pronunciation, isFlagged) and tags a JSON array of names. Never synced:
-- no sync trigger and no server_version.
CREATE TABLE card_draft (
  draft_key TEXT NOT NULL PRIMARY KEY,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  extras TEXT NOT NULL,
  tags TEXT NOT NULL,
  updated_at DATETIME NOT NULL
) AS CardDraftRow;
```

3b. In `lib/core/database/app_database.dart` change `int get schemaVersion => 12;` to `int get schemaVersion => 13;`.

3c. Regenerate the snapshot, the step schemas and the verifier, in this order (`.claude/skills/flutter-drift/references/migrations.md`):

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Expected: `drift_schemas/drift_schema_v13.json` appears; `schema_versions.dart` gains `Schema13` and `from12To13` in `stepByStep`; `test/drift/generated/schema_v13.dart` appears and `schema.dart` lists 13.

3d. Add the step after `from11To12` in `app_database.dart`:

```dart
      from12To13: (m, schema) async {
        // SP2a R9: the card being written, device-local. One new, empty
        // table; no row changes, no sync trigger.
        await m.createTable(schema.cardDraft);
      },
```

3e. In `lib/core/database/local_data_reset.dart`, the loop becomes (a draft of the old account must not offer itself to the next one):

```dart
      for (final table in [
        'card',
        'deck',
        'delete_batches',
        'tags',
        'card_draft',
      ]) {
```

and the class doc's "Kept:" paragraph gains nothing; add `the card drafts` to the list of what goes: change `Cards go first:` sentence's start to `The card drafts go with the cards. Cards go first:`.

3f. Add to `docs/shared/data/schema.md` after the `dismissed_note` section (Vietnamese, as the file is):

```markdown
## `card_draft` (schema 13)

Thẻ đang soạn dở trên máy này (SP2a, R9): `draft_key` (khoá chính: `create:<deckId>`
hoặc `edit:<cardId>`), `front`, `back`, `extras` (JSON: example, hint, pronunciation,
isFlagged), `tags` (JSON: mảng tên tag) và `updated_at` (UTC). Bảng chỉ ở trên thiết bị:
không trigger sync, không `server_version`, không bao giờ ghi vào log. Bản nháp bị xoá
khi thẻ được lưu, khi người dùng bỏ thay đổi, hoặc khi form giống hệt thẻ gốc; bản nào
quá 30 ngày thì bị dọn ở lần ghi sau; `LocalDataReset` xoá hết. Đọc và ghi qua
`CardDraftRepository` (`lib/features/card/`).
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/drift test/database test/core/database`
Expected: PASS (every `vN upgrades to the schema of v13`, the new migration tests, the reset test, `test/database/schema_test.dart` which finds `drift_schema_v13.json`).

Then: `python tools/docs/check.py` — expected `PASS — 0 error(s)`; `bash .claude/skills/flutter-drift/scripts/check_drift.sh --diff` — expected no `ERROR`.

- [ ] **Step 5: Commit**

```bash
dart format lib/core/database/app_database.dart lib/core/database/local_data_reset.dart test/drift/card_draft_migration_test.dart test/drift/migration_test.dart test/core/database/local_data_reset_test.dart
git add lib/core/database/tables/ui_state.drift lib/core/database/app_database.dart lib/core/database/schema_versions.dart lib/core/database/local_data_reset.dart drift_schemas/drift_schema_v13.json test/drift test/core/database/local_data_reset_test.dart docs/shared/data/schema.md
git commit -m "feat(database): v13 — device-local card draft table (SP2a R9)"
```

---

### Task 13 (B2): `CardDraftRepository` (read, save, clear) and `CardDraft.sameContentAs`

**Files:**
- Create: `lib/core/database/queries/card_draft_queries.drift`
- Create: `lib/features/card/data/datasources/card_draft_dao.dart`
- Create: `lib/features/card/domain/models/card_draft_key_model.dart`
- Create: `lib/features/card/domain/repositories/card_draft_repository.dart`
- Create: `lib/features/card/data/repositories/card_draft_repository_impl.dart`
- Create: `lib/features/card/di/card_draft_repository_provider.dart`
- Modify: `lib/features/card/domain/models/card_draft_model.dart` (add `sameContentAs`, after `check()` at line 82)
- Test: `test/features/card/data/card_draft_repository_test.dart` (create), `test/features/card/domain/card_draft_model_test.dart` (append)

**Interfaces:**
- Consumes: `CardDraftRow` and `AppDatabase.cardDraft` (Task B1); `guardDatabase` (`core/error/failure.dart`).
- Produces:
  - `abstract interface class CardDraftRepository { Future<CardDraft?> read(String key); Future<void> save(String key, CardDraft draft); Future<void> clear(String key); }`
  - `final class CardDraftRepositoryImpl implements CardDraftRepository { CardDraftRepositoryImpl(AppDatabase db, {DateTime Function()? now}); static const Duration expiry = Duration(days: 30); }`
  - `cardDraftRepositoryProvider` (`CardDraftRepository`), `abstract final class CardDraftKey { static String create(String deckId); static String edit(String cardId); }`
  - `bool CardDraft.sameContentAs(CardDraft other)`.
- Goldens: none.
- DECISION D1 and D3 (see Cluster notes): a domain contract although the spec says "no interface"; a 30-day expiry pruned on save.

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/data/card_draft_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

import '../../../support/test_database.dart';

// R9: the card being written is kept on this device, per key, never synced
// and never logged.

void main() {
  late AppDatabase db;
  late CardDraftRepositoryImpl drafts;
  var clock = DateTime.utc(2026, 10, 3, 9);

  setUp(() {
    db = openTestDatabase();
    clock = DateTime.utc(2026, 10, 3, 9);
    drafts = CardDraftRepositoryImpl(db, now: () => clock);
  });
  tearDown(() => db.close());

  const hangul = CardDraft(
    front: '밥',
    back: 'Cơm',
    example: 'Tôi ăn cơm.',
    pronunciation: 'bap',
    isFlagged: true,
    tagNames: ['món ăn', 'topik 1'],
  );
  final deckKey = CardDraftKey.create('deck-1');

  Future<int> count() async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM card_draft').getSingle())
          .read<int>('n');

  test('nothing is kept at first', () async {
    expect(await drafts.read(deckKey), isNull);
  });

  test('a draft reads back as it was saved, Hangul, null fields and tags '
      'included', () async {
    await drafts.save(deckKey, hangul);

    final kept = await drafts.read(deckKey);
    expect(kept!.sameContentAs(hangul), isTrue);
    expect(kept.hint, isNull);
    expect(kept.tagNames, ['món ăn', 'topik 1']);
  });

  test('saving again replaces the draft of that key', () async {
    await drafts.save(deckKey, hangul);
    await drafts.save(deckKey, const CardDraft(front: 'a', back: 'b'));

    expect(await count(), 1);
    final kept = await drafts.read(deckKey);
    expect((kept!.front, kept.back, kept.isFlagged), ('a', 'b', false));
  });

  test('each key keeps its own draft', () async {
    final editKey = CardDraftKey.edit('card-1');
    await drafts.save(deckKey, const CardDraft(front: 'new', back: 'n'));
    await drafts.save(editKey, const CardDraft(front: 'edit', back: 'e'));

    expect((await drafts.read(deckKey))!.front, 'new');
    expect((await drafts.read(editKey))!.front, 'edit');
  });

  test('clear drops one key; clearing a missing one changes nothing', () async {
    final editKey = CardDraftKey.edit('card-1');
    await drafts.save(deckKey, hangul);
    await drafts.save(editKey, hangul);

    await drafts.clear(deckKey);
    await drafts.clear(deckKey);

    expect(await drafts.read(deckKey), isNull);
    expect(await drafts.read(editKey), isNotNull);
  });

  test('a draft older than 30 days goes with the next save', () async {
    await drafts.save(CardDraftKey.edit('old'), hangul);
    clock = clock.add(const Duration(days: 29));
    await drafts.save(CardDraftKey.create('a'), hangul);
    expect(await drafts.read(CardDraftKey.edit('old')), isNotNull);

    clock = clock.add(const Duration(days: 2));
    await drafts.save(CardDraftKey.create('b'), hangul);

    expect(await drafts.read(CardDraftKey.edit('old')), isNull);
    expect(await drafts.read(CardDraftKey.create('a')), isNotNull);
    expect(await drafts.read(CardDraftKey.create('b')), isNotNull);
  });

  test('a row nothing in the app wrote reads as no draft', () async {
    await db.customStatement(
      "INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at) "
      "VALUES ('create:x', 'f', 'b', 'not json', '[]', 0)",
    );

    expect(await drafts.read('create:x'), isNull);
  });

  test('drafts never sync: saving queues nothing', () async {
    await drafts.save(deckKey, hangul);

    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });
}
```

Append to `test/features/card/domain/card_draft_model_test.dart`, inside `main()`:

```dart
  group('sameContentAs', () {
    const base = CardDraft(
      front: 'f',
      back: 'b',
      example: 'e',
      isFlagged: true,
      tagNames: ['x', 'y'],
    );

    test('the same text, flag and tags in the same order', () {
      const same = CardDraft(
        front: 'f',
        back: 'b',
        example: 'e',
        isFlagged: true,
        tagNames: ['x', 'y'],
      );
      expect(base.sameContentAs(same), isTrue);
    });

    test('any difference counts', () {
      const others = [
        CardDraft(front: 'F', back: 'b', example: 'e', isFlagged: true, tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'B', example: 'e', isFlagged: true, tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'b', isFlagged: true, tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'b', example: 'e', hint: 'h', isFlagged: true, tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'b', example: 'e', pronunciation: 'p', isFlagged: true, tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'b', example: 'e', tagNames: ['x', 'y']),
        CardDraft(front: 'f', back: 'b', example: 'e', isFlagged: true, tagNames: ['y', 'x']),
        CardDraft(front: 'f', back: 'b', example: 'e', isFlagged: true, tagNames: ['x']),
      ];
      for (final other in others) {
        expect(base.sameContentAs(other), isFalse);
      }
    });
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/data/card_draft_repository_test.dart test/features/card/domain/card_draft_model_test.dart`
Expected: FAIL to compile: the repository, key model and `sameContentAs` do not exist.

- [ ] **Step 3: Implement**

`lib/core/database/queries/card_draft_queries.drift`:

```sql
import '../tables/ui_state.drift';

-- The card being written, kept on this device (never synced; SP2a R9).
-- draft_key is the primary key, so one draft per key.

-- The draft of :draft_key, or no row.
findCardDraft:
SELECT * FROM card_draft WHERE draft_key = :draft_key;

-- Replaces the draft of :draft_key, so a later save never leaves two.
upsertCardDraft(
  :draft_key AS TEXT,
  :front AS TEXT,
  :back AS TEXT,
  :extras AS TEXT,
  :tags AS TEXT,
  :updated_at AS DATETIME
):
INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at)
VALUES (:draft_key, :front, :back, :extras, :tags, :updated_at)
ON CONFLICT (draft_key) DO UPDATE SET
  front = excluded.front,
  back = excluded.back,
  extras = excluded.extras,
  tags = excluded.tags,
  updated_at = excluded.updated_at;

-- Dropping a draft that is not there changes nothing.
deleteCardDraft(:draft_key AS TEXT):
DELETE FROM card_draft WHERE draft_key = :draft_key;

-- Drafts nobody wrote to since :before; their deck or card may be gone.
deleteCardDraftsBefore(:before AS DATETIME):
DELETE FROM card_draft WHERE updated_at < :before;
```

`lib/features/card/data/datasources/card_draft_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'card_draft_dao.g.dart';

/// Row access for `card_draft` (`card_draft_queries.drift`): the card being
/// written, device-local and never synced (SP2a R9). It returns Drift rows,
/// never domain models.
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_draft_queries.drift'},
)
final class CardDraftDao extends DatabaseAccessor<AppDatabase>
    with _$CardDraftDaoMixin {
  CardDraftDao(super.attachedDatabase);

  Future<CardDraftRow?> find(String key) => findCardDraft(key).getSingleOrNull();

  Future<void> upsert({
    required String key,
    required String front,
    required String back,
    required String extras,
    required String tags,
    required DateTime at,
  }) => upsertCardDraft(key, front, back, extras, tags, at);

  Future<void> remove(String key) => deleteCardDraft(key);

  Future<void> removeBefore(DateTime cutoff) => deleteCardDraftsBefore(cutoff);
}
```

`lib/features/card/domain/models/card_draft_key_model.dart`:

```dart
/// The key a card being written is kept under (SP2a R9): one per deck for a
/// new card, one per card for an edit.
abstract final class CardDraftKey {
  static String create(String deckId) => 'create:$deckId';

  static String edit(String cardId) => 'edit:$cardId';
}
```

`lib/features/card/domain/repositories/card_draft_repository.dart`:

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// The card being written, kept on this device (SP2a R9): never synced and
/// never logged. The one implementation is `CardDraftRepositoryImpl`; the
/// contract lets the presentation layer stay off `data/` and tests fail a
/// write on purpose.
abstract interface class CardDraftRepository {
  /// The draft kept under [key], or null when there is none.
  Future<CardDraft?> read(String key);

  /// Keeps [draft] under [key], replacing any earlier draft of that key.
  Future<void> save(String key, CardDraft draft);

  /// Drops the draft under [key]; dropping a missing one changes nothing.
  Future<void> clear(String key);
}
```

`lib/features/card/data/repositories/card_draft_repository_impl.dart`:

```dart
import 'dart:convert';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/datasources/card_draft_dao.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';

/// `card_draft` through [CardDraftDao]. The optional fields and the flag are
/// one JSON object, the tag names a JSON array. The text is card content, so
/// nothing here logs it (ADR-002).
final class CardDraftRepositoryImpl implements CardDraftRepository {
  CardDraftRepositoryImpl(AppDatabase db, {DateTime Function()? now})
    : _dao = CardDraftDao(db),
      _now = now ?? DateTime.now;

  /// A draft not written to for this long goes with the next save: the deck
  /// or the card it names may be gone for good, and its text should not stay
  /// on the phone forever.
  static const Duration expiry = Duration(days: 30);

  static const _example = 'example';
  static const _hint = 'hint';
  static const _pronunciation = 'pronunciation';
  static const _isFlagged = 'isFlagged';

  final CardDraftDao _dao;
  final DateTime Function() _now;

  @override
  Future<CardDraft?> read(String key) => guardDatabase(() async {
    final row = await _dao.find(key);
    return row == null ? null : _draftOf(row);
  });

  @override
  Future<void> save(String key, CardDraft draft) => guardDatabase(() async {
    final at = _now().toUtc();
    await _dao.upsert(
      key: key,
      front: draft.front,
      back: draft.back,
      extras: jsonEncode({
        _example: draft.example,
        _hint: draft.hint,
        _pronunciation: draft.pronunciation,
        _isFlagged: draft.isFlagged,
      }),
      tags: jsonEncode(draft.tagNames),
      at: at,
    );
    await _dao.removeBefore(at.subtract(expiry));
  });

  @override
  Future<void> clear(String key) => guardDatabase(() => _dao.remove(key));

  static CardDraft? _draftOf(CardDraftRow row) {
    try {
      final extras = jsonDecode(row.extras) as Map<String, Object?>;
      final tags = jsonDecode(row.tags) as List<Object?>;
      return CardDraft(
        front: row.front,
        back: row.back,
        example: extras[_example] as String?,
        hint: extras[_hint] as String?,
        pronunciation: extras[_pronunciation] as String?,
        isFlagged: extras[_isFlagged] as bool? ?? false,
        tagNames: [for (final tag in tags) tag as String],
      );
    } on FormatException {
      // A row nothing in this app wrote offers no draft; it never breaks the
      // editor.
      return null;
    } on TypeError {
      return null;
    }
  }
}
```

`lib/features/card/di/card_draft_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_draft_repository_provider.g.dart';

@riverpod
CardDraftRepository cardDraftRepository(Ref ref) =>
    CardDraftRepositoryImpl(ref.watch(databaseProvider));
```

In `card_draft_model.dart` add `import 'package:collection/collection.dart';` after the `characters` import, and after `check()` (line 82):

```dart

  /// Whether [other] is the same card as typed: the same text, flag and tag
  /// names, in the same order. The draft kept on the device is dropped when
  /// it equals the form it would restore.
  bool sameContentAs(CardDraft other) =>
      front == other.front &&
      back == other.back &&
      example == other.example &&
      hint == other.hint &&
      pronunciation == other.pronunciation &&
      isFlagged == other.isFlagged &&
      const ListEquality<String>().equals(tagNames, other.tagNames);
```

Then generate: `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/data/card_draft_repository_test.dart test/features/card/domain/card_draft_model_test.dart`
Expected: PASS.
Then: `flutter analyze lib/features/card` (expected: No issues found), `python .claude/skills/flutter-architecture/scripts/check_architecture.py` (expected: clean) and `bash .claude/skills/flutter-drift/scripts/check_drift.sh --diff` (expected: no `ERROR`).

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card test/features/card/data/card_draft_repository_test.dart test/features/card/domain/card_draft_model_test.dart
git add lib/core/database/queries/card_draft_queries.drift lib/features/card/data/datasources/card_draft_dao.dart lib/features/card/data/repositories/card_draft_repository_impl.dart lib/features/card/domain/models/card_draft_key_model.dart lib/features/card/domain/models/card_draft_model.dart lib/features/card/domain/repositories/card_draft_repository.dart lib/features/card/di/card_draft_repository_provider.dart test/features/card/data/card_draft_repository_test.dart test/features/card/domain/card_draft_model_test.dart
git commit -m "feat(card): device-local card draft repository (SP2a R9)"
```

---

### Task 14 (B3): `MxInlineBanner` gets a neutral tone

**Files:**
- Modify: `lib/shared/widgets/mx_inline_banner.dart` (enum line 13, tone switch lines 47–65, glyph line 134)
- Modify: `DESIGN.md:347` (the **MxInlineBanner** record)
- Test: `test/shared/widgets/mx_inline_banner_test.dart` (append inside `main()`)

**Interfaces:**
- Produces: `enum MxBannerTone { neutral, warning, danger }`. Task B5 shows the kept draft with `MxBannerTone.neutral`. (If another cluster adds the same value first, drop the code steps and keep the test.)
- Goldens: none (no existing screen uses the new value).
- DECISION D4.

- [ ] **Step 1: Write the failing test** (append inside `main()` of `mx_inline_banner_test.dart`)

```dart
  testWidgets('neutral: the note ground and ghost edge, the info glyph, an '
      'onSurface title (SP2a R9)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.neutral,
          title: 'Unsaved text from earlier',
          message: _message,
        ),
      ),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.info));

    expect(_ground(tester).color, scheme.surfaceContainerLow);
    expect(_ground(tester).border, Border.all(color: derived.ghostBorder));
    expect((glyph.size, glyph.color), (16, scheme.onSurfaceVariant));
    expect(
      tester.widget<Text>(find.text('Unsaved text from earlier')).style!.color,
      scheme.onSurface,
    );
    expect(find.byIcon(AppIcons.alert), findsNothing);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_inline_banner_test.dart`
Expected: FAIL to compile (`MxBannerTone.neutral` is undefined).

- [ ] **Step 3: Implement**

In `mx_inline_banner.dart`, replace the enum and its doc:

```dart
/// Neutral offers a choice and nothing is wrong (a draft kept for the person).
/// Warning is a refusal or a limit, and nothing was lost. Danger means an
/// operation failed.
enum MxBannerTone { neutral, warning, danger }
```

Add the case to the `switch (tone)` (before `warning`):

```dart
      // The MxNote's ground, so a calm notice that offers a choice does not
      // read as a problem (SP2a R9).
      MxBannerTone.neutral => (
        colors.surfaceContainerLow,
        derived.ghostBorder,
        colors.onSurfaceVariant,
        colors.onSurface,
      ),
```

Replace the glyph (`Icon(AppIcons.alert, size: AppIconSize.inline, color: ink)`) by:

```dart
                  child: Icon(
                    tone == MxBannerTone.neutral
                        ? AppIcons.info
                        : AppIcons.alert,
                    size: AppIconSize.inline,
                    color: ink,
                  ),
```

In `DESIGN.md` line 347, replace `**MxInlineBanner** (warning or danger; the glyph reads in warning ink or error` with `**MxInlineBanner** (neutral, warning or danger; neutral takes the MxNote's ground and the info glyph, and offers a choice where nothing is wrong, as the card editor's kept draft, SP2a R9; the glyph reads in warning ink or error`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_inline_banner_test.dart`, then `python tools/docs/check.py`.
Expected: PASS; `PASS — 0 error(s)`.

- [ ] **Step 5: Commit**

```bash
dart format lib/shared/widgets/mx_inline_banner.dart test/shared/widgets/mx_inline_banner_test.dart
git add lib/shared/widgets/mx_inline_banner.dart test/shared/widgets/mx_inline_banner_test.dart DESIGN.md
git commit -m "feat(ui): MxInlineBanner neutral tone for a notice that offers a choice (SP2a R9)"
```

---

### Task 15 (B4): `CardDraftController` — the debounced writer

**Also pin (Review Focus):** a process kill inside the 500 ms debounce loses at most the text typed in that window — add a fakeAsync test: type, advance 400 ms, dispose the controller, and expect the flushed draft to hold the typed text (dispose flushes).

**Files:**
- Create: `lib/features/card/presentation/controllers/card_draft_controller.dart`
- Test: `test/features/card/presentation/card_draft_controller_test.dart` (create)

**Interfaces:**
- Consumes: `CardDraftRepository`, `CardDraft.sameContentAs` (Task B2); `Failure` (`core/error/failure.dart`).
- Produces:

```dart
final class CardDraftController {
  CardDraftController({required CardDraftRepository repository, required String key, Duration delay = pause});
  static const Duration pause = Duration(milliseconds: 500);
  Future<CardDraft?> read();
  void schedule(CardDraft draft, {required CardDraft saved});
  Future<void> flush();
  Future<void> clear();
}
```

- It is a plain class owned by the form's state, not a Riverpod notifier: its timer must live and die with the form. The spec's "editor controller" is this class plus the form that owns it.
- Goldens: none.

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/presentation/card_draft_controller_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';
import 'package:memox/features/card/presentation/controllers/card_draft_controller.dart';

// SP2a 2.14 (R9): the draft is written once typing pauses, in order, and an
// unchanged form keeps none. A failed draft write never reaches the form.

final class _FakeDrafts implements CardDraftRepository {
  final stored = <String, CardDraft>{};
  final calls = <String>[];
  Duration saveTime = Duration.zero;
  Failure? failure;

  @override
  Future<CardDraft?> read(String key) async {
    calls.add('read $key');
    if (failure case final failure?) throw failure;
    return stored[key];
  }

  @override
  Future<void> save(String key, CardDraft draft) async {
    calls.add('save $key ${draft.front}');
    if (saveTime > Duration.zero) await Future<void>.delayed(saveTime);
    if (failure case final failure?) throw failure;
    stored[key] = draft;
  }

  @override
  Future<void> clear(String key) async {
    calls.add('clear $key');
    if (failure case final failure?) throw failure;
    stored.remove(key);
  }
}

const _key = 'create:d';
const _empty = CardDraft(front: '', back: '');

void main() {
  late _FakeDrafts drafts;
  late CardDraftController controller;

  setUp(() {
    drafts = _FakeDrafts();
    controller = CardDraftController(repository: drafts, key: _key);
  });

  test('a change is written once typing pauses, not before', () {
    fakeAsync((async) {
      controller.schedule(const CardDraft(front: 'bap', back: ''), saved: _empty);

      async.elapse(const Duration(milliseconds: 499));
      expect(drafts.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap']);
      expect(drafts.stored[_key]!.front, 'bap');
    });
  });

  test('a later change restarts the pause and only the last text is written',
      () {
    fakeAsync((async) {
      controller.schedule(const CardDraft(front: 'b', back: ''), saved: _empty);
      async.elapse(const Duration(milliseconds: 300));
      controller.schedule(const CardDraft(front: 'ba', back: ''), saved: _empty);
      async.elapse(const Duration(milliseconds: 300));
      expect(drafts.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 200));
      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key ba']);
    });
  });

  test('a form equal to the saved one drops the draft instead of keeping it',
      () {
    fakeAsync((async) {
      drafts.stored[_key] = const CardDraft(front: 'x', back: 'y');
      controller.schedule(_empty, saved: _empty);

      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();
      expect(drafts.calls, ['clear $_key']);
      expect(drafts.stored, isEmpty);
    });
  });

  test('clear cancels a write that is still waiting', () {
    fakeAsync((async) {
      controller.schedule(const CardDraft(front: 'bap', back: ''), saved: _empty);
      unawaited(controller.clear());

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(drafts.calls, ['clear $_key']);
    });
  });

  test('flush writes what waits at once', () {
    fakeAsync((async) {
      controller.schedule(const CardDraft(front: 'bap', back: ''), saved: _empty);
      unawaited(controller.flush());

      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap']);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(drafts.calls, hasLength(1));
    });
  });

  test('writes keep their order: a clear after a slow save wins', () {
    fakeAsync((async) {
      drafts.saveTime = const Duration(milliseconds: 100);
      controller.schedule(const CardDraft(front: 'bap', back: ''), saved: _empty);
      async.elapse(CardDraftController.pause);
      unawaited(controller.clear());

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap', 'clear $_key']);
      expect(drafts.stored, isEmpty);
    });
  });

  test('a failed write is swallowed and the next one still runs', () {
    fakeAsync((async) {
      drafts.failure = const UnknownDatabaseFailure(cause: 'disk full');
      controller.schedule(const CardDraft(front: 'a', back: ''), saved: _empty);
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();

      drafts.failure = null;
      controller.schedule(const CardDraft(front: 'ab', back: ''), saved: _empty);
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();
      expect(drafts.stored[_key]!.front, 'ab');
    });
  });

  test('read hands back the kept draft, or nothing when the read fails',
      () async {
    drafts.stored[_key] = const CardDraft(front: 'kept', back: 'k');
    expect((await controller.read())!.front, 'kept');

    drafts.failure = const UnknownDatabaseFailure(cause: 'disk full');
    expect(await controller.read(), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/card/presentation/card_draft_controller_test.dart`
Expected: FAIL to compile (`CardDraftController` does not exist).

- [ ] **Step 3: Implement** — create `lib/features/card/presentation/controllers/card_draft_controller.dart`:

```dart
import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';

/// Keeps the card being written in its device-local draft (SP2a R9, 2.14):
/// each change is written once typing pauses, in order, and a form equal to
/// what it was opened with keeps no draft. The draft is a convenience, so a
/// failed write never reaches the form. A plain class: the form's state owns
/// it and its timer, and flushes it when it goes.
final class CardDraftController {
  CardDraftController({
    required CardDraftRepository repository,
    required this.key,
    this.delay = pause,
  }) : _repository = repository;

  /// How long typing must pause before the draft is written.
  static const Duration pause = Duration(milliseconds: 500);

  final String key;
  final Duration delay;
  final CardDraftRepository _repository;

  Timer? _timer;
  ({CardDraft draft, CardDraft saved})? _pending;
  Future<void> _writes = Future<void>.value();

  /// The draft kept under [key]; null when there is none or the read fails.
  Future<CardDraft?> read() async {
    try {
      return await _repository.read(key);
    } on Failure {
      // An unreadable draft offers nothing; it must not stop the editor.
      return null;
    }
  }

  /// Writes [draft] once typing pauses for [delay]; when it is the same card
  /// as [saved] (what the form was opened with) the draft is dropped instead.
  void schedule(CardDraft draft, {required CardDraft saved}) {
    _pending = (draft: draft, saved: saved);
    _timer?.cancel();
    _timer = Timer(delay, _write);
  }

  /// Writes what waits, now; completes when every queued write is done.
  Future<void> flush() {
    _timer?.cancel();
    _write();
    return _writes;
  }

  /// Drops the draft and whatever still waits to be written.
  Future<void> clear() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _enqueue(() => _repository.clear(key));
    return _writes;
  }

  void _write() {
    _timer = null;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    _enqueue(
      () => pending.draft.sameContentAs(pending.saved)
          ? _repository.clear(key)
          : _repository.save(key, pending.draft),
    );
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) async {
      try {
        await write();
      } on Failure {
        // The draft is a convenience: a failed write never interrupts typing.
      }
    });
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/card/presentation/card_draft_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card/presentation/controllers/card_draft_controller.dart test/features/card/presentation/card_draft_controller_test.dart
git add lib/features/card/presentation/controllers/card_draft_controller.dart test/features/card/presentation/card_draft_controller_test.dart
git commit -m "feat(card): debounced draft writer for the card editor (SP2a 2.14)"
```

---

### Task 16 (B5): Autosave, the restore banner, and clearing on save, discard and an unchanged form (2.14)

**Files:**
- Create: `lib/features/card/presentation/widgets/sections/card_draft_banner_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (imports lines 9–14; fields lines 64–84; dispose 96–103; `_isDirty` 118–128; `_touch` 211; `_afterSave` 240–260; `_clearForNext` 263–276; `_confirmLeave` 289–296; flag toggle 372; `_fields` 379–428)
- Modify: `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb` (insert after `cardDeckRejectsBody`, lines 950 and 205)
- Test: `test/features/card/presentation/card_editor_draft_test.dart` (create; Tasks B6–B8 append)

**Interfaces:**
- Consumes: `cardDraftRepositoryProvider`, `CardDraftKey`, `CardDraft.sameContentAs` (B2); `CardDraftController` (B4); `MxBannerTone.neutral` (B3).
- Produces: `class CardDraftBannerWidget extends StatelessWidget { const CardDraftBannerWidget({super.key, required VoidCallback onRestore, required VoidCallback onDiscard}); }`; in the form, `_drafts` (the controller), `_offer` (the kept draft on offer), `_keepDraft()`. ARB keys `cardDraftTitle`, `cardDraftBody`, `cardDraftRestore`.
- Goldens: none move (a new golden comes in Task B10).
- DECISION D8 (while a kept draft is on offer, new typing is not autosaved).

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/presentation/card_editor_draft_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.

final _en = lookupAppLocalizations(const Locale('en'));

/// Past the 500 ms pause that starts a draft write.
const _pause = Duration(milliseconds: 600);

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

String _text(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_field(index)).controller.text;

CardDraftRepositoryImpl _drafts(LibraryEnv env) =>
    CardDraftRepositoryImpl(env.db);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  libraryTest('typing is kept in a draft once it pauses (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump(const Duration(milliseconds: 300));
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);

    await tester.pump(_pause);
    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));
  });

  libraryTest('a draft kept before the editor was killed is offered back, '
      'and Restore fills the form (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await _drafts(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(
        front: 'bap',
        back: 'rice',
        example: 'Bap meogeoyo.',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsOneWidget);
    expect(_text(tester, 0), isEmpty);

    await tester.tap(find.widgetWithText(MxButton, _en.cardDraftRestore));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(_text(tester, 0), 'bap');
    expect(_text(tester, 1), 'rice');
    expect(find.text('Bap meogeoyo.'), findsOneWidget);
    // The tags sit below the fold of a 360×800 screen.
    await tester.dragUntilVisible(
      find.bySemanticsLabel(_en.cardTagRemove('food')),
      find.byType(ListView),
      const Offset(0, -200),
    );
  });

  libraryTest('Discard on the banner drops the draft and keeps the form '
      'empty (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await _drafts(env).save(
      CardDraftKey.create(deckId),
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.cardDiscard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(_text(tester, 0), isEmpty);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an edit draft is offered on its own card only; a draft equal '
      'to the card is dropped, not offered (2.14)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final other = await env.cards.card(
      deckId,
      const CardDraft(front: 'mul', back: 'water'),
    );
    await _drafts(env).save(
      CardDraftKey.edit(card.id),
      const CardDraft(front: 'bab', back: 'rice'),
    );
    await _drafts(env).save(
      CardDraftKey.edit(other.id),
      const CardDraft(front: 'mul', back: 'water'),
    );

    await pumpLibraryScreen(tester, env, _edit(other.id));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsNothing);
    expect(await _drafts(env).read(CardDraftKey.edit(other.id)), isNull);

    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.cardDraftRestore));
    await tester.pumpAndSettle();
    expect(_text(tester, 0), 'bab');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNotNull,
    );
  });

  libraryTest('Save clears the draft (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('Save changes clears an edit draft (2.14)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNotNull);

    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNull);
  });

  libraryTest('Discard on the discard dialog clears the draft (2.14)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardDiscard));
    await tester.pumpAndSettle();

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });

  libraryTest('an unchanged form keeps no draft: typing then undoing it '
      'drops it (2.14)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump(_pause);
    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNotNull);

    await tester.enterText(_field(0), '');
    await tester.pump(_pause);

    expect(await _drafts(env).read(CardDraftKey.create(deckId)), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart`
Expected: FAIL to compile (`cardDraftTitle`, `cardDraftRestore` are undefined).

- [ ] **Step 3: Implement**

3a. ARB. In `lib/l10n/app_en.arb`, insert after the `@cardDeckRejectsBody` entry (line 953):

```json
  "cardDraftTitle": "Unsaved text from earlier",
  "@cardDraftTitle": {
    "description": "Neutral banner title above the card editor when a draft kept on this device is offered back (SP2a R9)."
  },
  "cardDraftBody": "Kept on this phone only, not synced. Restore it or discard it.",
  "@cardDraftBody": {
    "description": "Neutral banner body offering the kept draft back."
  },
  "cardDraftRestore": "Restore",
  "@cardDraftRestore": {
    "description": "Banner action: puts the kept draft back into the form. Its partner is cardDiscard."
  },
```

In `lib/l10n/app_vi.arb`, insert after the `"cardDeckRejectsBody"` line (205):

```json
  "cardDraftTitle": "Nội dung chưa lưu từ lần trước",
  "cardDraftBody": "Chỉ được giữ trên điện thoại này, không đồng bộ. Hãy khôi phục hoặc bỏ đi.",
  "cardDraftRestore": "Khôi phục",
```

Run `flutter gen-l10n`.

3b. `lib/features/card/presentation/widgets/sections/card_draft_banner_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The draft kept on this device, offered back above the fields (SP2a R9).
/// Neutral: nothing is wrong. Restore is secondary, since the footer's Save
/// is the screen's one primary (the One Indigo Rule); Discard is outline, and
/// the primary-weight action sits last.
class CardDraftBannerWidget extends StatelessWidget {
  const CardDraftBannerWidget({
    super.key,
    required this.onRestore,
    required this.onDiscard,
  });

  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.neutral,
      title: l10n.cardDraftTitle,
      message: l10n.cardDraftBody,
      actions: [
        MxButton(
          label: l10n.cardDiscard,
          size: MxButtonSize.compact,
          tone: MxButtonTone.outline,
          onPressed: onDiscard,
        ),
        MxButton(
          label: l10n.cardDraftRestore,
          size: MxButtonSize.compact,
          tone: MxButtonTone.secondary,
          onPressed: onRestore,
        ),
      ],
    );
  }
}
```

3c. `card_editor_form_widget.dart`, imports. Add (sorted into the existing blocks):

```dart
import 'package:memox/features/card/di/card_draft_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/presentation/controllers/card_draft_controller.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_draft_banner_widget.dart';
```

(`di/` goes before `domain/failures/`; `card_draft_key_model` before `card_draft_model`; the controller after `card_actions_controller`; the banner after `card_discard_dialog_widget` and before `card_edit_summary_widget`.)

3d. Fields. Replace `  late var _saved = _draft();` with `  late CardDraft _saved;` and after `final _tagEditor = GlobalKey<CardTagEditorWidgetState>();` add:

```dart
  late final _drafts = CardDraftController(
    repository: ref.read(cardDraftRepositoryProvider),
    key: _isCreating
        ? CardDraftKey.create(widget.deckId)
        : CardDraftKey.edit(_card!.id),
  );

  /// A draft kept from an earlier session, on offer above the fields (R9).
  CardDraft? _offer;
```

3e. `dispose` becomes (and `initState` is new, right before it):

```dart
  @override
  void initState() {
    super.initState();
    _saved = _draft();
    for (final controller in _controllers) {
      controller.addListener(_keepDraft);
    }
    unawaited(_offerKeptDraft());
  }

  @override
  void dispose() {
    // What waits for the pause is written now: leaving mid-pause loses
    // nothing.
    unawaited(_drafts.flush());
    for (final controller in _controllers) {
      controller.dispose();
    }
    _frontFocus.dispose();
    super.dispose();
  }
```

3f. `_isDirty` becomes:

```dart
  bool get _isDirty => _hasPendingTag || !_draft().sameContentAs(_saved);
```

3g. After `_touch` add:

```dart
  /// The draft kept for this form, offered back when it differs from what the
  /// form shows now; a draft equal to it is dropped (R9).
  Future<void> _offerKeptDraft() async {
    final kept = await _drafts.read();
    if (kept == null) return;
    if (kept.sameContentAs(_saved)) {
      unawaited(_drafts.clear());
      return;
    }
    if (mounted) setState(() => _offer = kept);
  }

  /// Every change goes to the draft once typing pauses. While an earlier
  /// draft is on offer it stays as it is until the person answers it.
  void _keepDraft() {
    if (_offer != null) return;
    _drafts.schedule(_draft(), saved: _saved);
  }

  void _restoreOffer() {
    final draft = _offer;
    if (draft == null) return;
    // _offer is still set while the controllers change, so the listeners
    // write nothing: the kept draft is already what is on screen.
    _front.text = draft.front;
    _back.text = draft.back;
    _example.text = draft.example ?? '';
    _hint.text = draft.hint ?? '';
    _pronunciation.text = draft.pronunciation ?? '';
    setState(() {
      _tags = [...draft.tagNames];
      _isFlagged = draft.isFlagged;
      _isDetailsOpen =
          _isDetailsOpen ||
          draft.example != null ||
          draft.hint != null ||
          draft.pronunciation != null;
      _offer = null;
    });
  }

  void _discardOffer() {
    setState(() => _offer = null);
    unawaited(_drafts.clear());
  }
```

3h. `_afterSave`, the two `Ok` branches:

```dart
      case Ok() when _isCreating:
        _clearForNext();
        showMxSnackbar(context, message: l10n.cardAddedToast);
      case Ok():
        _saved = draft;
        unawaited(_drafts.clear());
        _leave();
```

3i. `_clearForNext`: inside `setState` add `_offer = null;` after `_saved = _draft();`, and after the `setState` call, before `_frontFocus.requestFocus();`, add `unawaited(_drafts.clear());` (the cleared controllers armed a write; clearing cancels it).

3j. `_confirmLeave` ends with:

```dart
    if (!discard || !mounted) return;
    unawaited(_drafts.clear());
    _leave();
```

3k. The flag toggle and the tag editor report to the draft:

```dart
              onPressed: () {
                setState(() => _isFlagged = !_isFlagged);
                _keepDraft();
              },
```

```dart
      onChanged: (tags) {
        setState(() => _tags = tags);
        _keepDraft();
      },
```

3l. `_fields`: after `const SizedBox(height: AppSpacing.control),` add:

```dart
    if (_offer != null)
      CardDraftBannerWidget(
        onRestore: _restoreOffer,
        onDiscard: _discardOffer,
      ),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart test/features/card/presentation/card_editor_screen_test.dart test/features/card/presentation/card_editor_save_test.dart test/features/card/presentation/card_editor_keyboard_test.dart test/features/card/presentation/card_tag_input_test.dart`
Expected: PASS (the old editor tests are unchanged).
Then: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/app test/visual_audit/screens/features/card` — expected PASS (excluding goldens); `flutter analyze lib/features/card` — No issues found.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card test/features/card/presentation/card_editor_draft_test.dart
git add lib/features/card/presentation lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/card/presentation/card_editor_draft_test.dart
git commit -m "feat(card): the editor keeps what is typed and offers it back (SP2a 2.14)"
```

---

### Task 17 (B6): A deck that rejects the card keeps the draft; Cancel, close and Back are held while saving (2.15, 2.16)

**Controller ruling (D10):** this task also extends `cardDeckGoneBody` in `app_en.arb` with the sentence "Your text is kept on this phone." and the VI string with "Nội dung bạn đã nhập vẫn được giữ trên điện thoại này."; update any test that matches the old body text exactly.

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (`_afterSave` `notACardContainer` branch; `_confirmLeave`; `_close`; the `PopScope` in `build`; `_appBar` leading)
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_footer_widget.dart:12-36` (`onCancel` nullable)
- Modify: `lib/l10n/app_en.arb` (`cardDeckRejectsBody`, line 950), `lib/l10n/app_vi.arb` (line 205)
- Test: `test/features/card/presentation/card_editor_draft_test.dart` (append)

**Interfaces:**
- Consumes: `CardDraftController.schedule`/`flush` (B4), `_drafts`, `_offer` (B5).
- Produces: `CardEditorFooterWidget({…, required VoidCallback? onCancel, …})`; the form's `_keepNow()`.
- Goldens: none.
- DECISION D6: once the text is in the draft (deck refuses), leaving asks nothing.

- [ ] **Step 1: Write the failing tests** (append to `card_editor_draft_test.dart`)

Add the imports `dart:async`, `package:memox/core/error/outcome.dart`, `package:memox/core/theme/foundations/app_icons.dart`, `package:memox/features/card/domain/failures/card_failure.dart`, `package:memox/features/card/domain/repositories/card_repository.dart`, `package:memox/features/card/domain/usecases/edit_card_use_case.dart`, `package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart`, `package:memox/shared/widgets/mx_icon_button.dart`, then:

```dart
/// An edit that waits until the test lets it through.
final class _HeldEdits implements CardRepository {
  _HeldEdits(this._cards);

  final CardRepository _cards;
  final release = Completer<void>();

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) async {
    await release.future;
    return _cards.editCard(cardId: cardId, draft: draft, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

and inside `main()`:

```dart
  libraryTest('a deck that rejects the card keeps the draft, says so, and '
      'offers the text back next time (2.15)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    // Save before the pause ends: the refusal itself writes the draft.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDeckRejectsTitle), findsOneWidget);
    expect(find.text(_en.cardDeckRejectsBody), findsOneWidget);
    final kept = await _drafts(env).read(CardDraftKey.create(deckId));
    expect((kept!.front, kept.back), ('bap', 'rice'));

    // Leaving asks nothing: the text is already safe.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsNothing);

    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDraftTitle), findsOneWidget);
  });

  libraryTest('Cancel, close and Back are held while a save is in flight '
      '(2.16)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final held = _HeldEdits(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(held)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pump();

    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<MxIconButton>(find.widgetWithIcon(MxIconButton, AppIcons.back))
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardTitle), findsNothing);

    held.release.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(_en.cardDiscardTitle), findsNothing);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart`
Expected: FAIL. The first test fails on `cardDeckRejectsBody` (the old copy has no "kept" sentence) and on the discard dialog appearing; the second finds Cancel enabled.

- [ ] **Step 3: Implement**

3a. ARB. EN `lib/l10n/app_en.arb`: replace `"cardDeckRejectsBody": "It now holds sub-decks.",` with `"cardDeckRejectsBody": "It now holds sub-decks. Your text is kept on this phone.",`. VI `lib/l10n/app_vi.arb`: replace `"cardDeckRejectsBody": "Giờ nó chứa các bộ thẻ con.",` with `"cardDeckRejectsBody": "Giờ nó chứa các bộ thẻ con. Nội dung bạn nhập được giữ trên điện thoại này.",`. Run `flutter gen-l10n`.

3b. `card_editor_footer_widget.dart`: the field becomes `final VoidCallback? onCancel;` and the constructor `required this.onCancel,` is unchanged (still required, now nullable); document it:

```dart
  /// Null while a save is in flight: Cancel is held (SP2a 2.16).
  final VoidCallback? onCancel;
```

3c. In the form, add next to `_confirmLeave`:

```dart
  /// What is on screen is what a refusal would strand: it goes to the draft
  /// at once, ahead of any earlier draft on offer (SP2a 2.15).
  void _keepNow() {
    _offer = null;
    _drafts.schedule(_draft(), saved: _saved);
    unawaited(_drafts.flush());
  }
```

3d. `_afterSave`, the deck refusal:

```dart
      case Rejected(reason: CardRejection.notACardContainer):
        _keepNow();
        setState(() {
          _isSaving = false;
          _deckRejects = true;
        });
```

3e. Holds. `_confirmLeave` starts with `if (_isSaving) return;`. `_close` becomes:

```dart
  void _close() {
    if (_isSaving) return;
    unawaited(Navigator.of(context).maybePop());
  }
```

The `PopScope`:

```dart
    return PopScope(
      // A refused deck leaves without asking: its text is already in the
      // draft. A save in flight holds Back (SP2a 2.15, 2.16).
      canPop:
          !_isSaving && (_isLeaving || _isGone || _deckRejects || !_isDirty),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSaving) return;
        unawaited(_confirmLeave());
      },
```

The footer's `onCancel: _close,` becomes `onCancel: _isSaving ? null : _close,` and the app bar's leading `onPressed: _close,` becomes `onPressed: _isSaving ? null : _close,`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart test/features/card/presentation/card_editor_screen_test.dart test/features/card/presentation/card_editor_blocks_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card/presentation test/features/card/presentation/card_editor_draft_test.dart
git add lib/features/card/presentation lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/card/presentation/card_editor_draft_test.dart
git commit -m "fix(card): a refused deck keeps the draft; Cancel, close and Back wait for a save (SP2a 2.15, 2.16)"
```

---

### Task 18 (B7): A card that goes away keeps the form, with a banner and its text (2.17)

**Files:**
- Create: `lib/features/card/presentation/states/card_editor_source_state.dart`
- Modify: `lib/features/card/presentation/screens/card_editor_screen.dart` (`_EditLoader`, lines 59–131)
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (constructor and fields lines 39–61; state flags lines 77–86; `_caption` 185; `_onSave` 203; `_afterSave` `notFound` branch; `build` and `_appBar`; `_fields`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (insert after `cardGoneBody`, lines 958 and 207)
- Modify: `test/features/card/presentation/card_editor_screen_test.dart` (the test "a card deleted while editing shows it is gone (RF3)", lines 319–340)
- Test: `test/features/card/presentation/card_editor_draft_test.dart` (append)

**Interfaces:**
- Consumes: `_keepNow()` (B6), `_drafts` (B4/B5).
- Produces: `enum CardEditorSource { present, gone, unreadable }`; `CardEditorFormWidget({…, CardEditorSource source = CardEditorSource.present})`; ARB keys `cardEditorGoneTitle`, `cardEditorGoneBody`, `cardEditorStaleTitle`, `cardEditorStaleBody`, `cardCaptionGone`.
- Goldens: none move (a new one comes in B10).
- DECISION D7 (a read error after opening is a warning "couldn't refresh", never "deleted"); D10 (a new card's deck gone keeps the full page).

- [ ] **Step 1: Write the failing tests**

In `card_editor_screen_test.dart`, replace the whole test `'a card deleted while editing shows it is gone (RF3)'` with:

```dart
  libraryTest('a card deleted while editing keeps the form and tells why '
      '(RF3, SP2a 2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);
    expect(find.text('changed'), findsOneWidget);
    expect(find.text(_en.cardGoneTitle), findsNothing);
    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
      ),
      0,
    );
  });
```

Append to `card_editor_draft_test.dart` (add imports `dart:async`, `package:memox/core/error/failure.dart`, `package:memox/features/card/domain/models/card_detail_model.dart`, `package:memox/features/card/domain/repositories/card_repository.dart` (if not yet added), `package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart`, `package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart`):

```dart
/// A card detail the test feeds by hand.
final class _ScriptedDetail implements CardRepository {
  _ScriptedDetail(this._stream);

  final Stream<CardDetail?> _stream;

  @override
  Stream<CardDetail?> watchDetail(String cardId) => _stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

```dart
  libraryTest('a deleted card: a danger banner, Save off, the draft kept, '
      'leaving asks nothing (2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorGoneTitle), findsOneWidget);
    expect(find.text(_en.cardEditorGoneBody), findsOneWidget);
    expect(_text(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNull,
    );
    // Written at once, not after the pause.
    expect(
      (await _drafts(env).read(CardDraftKey.edit(card.id)))?.back,
      'changed',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardTitle), findsNothing);
  });

  libraryTest('a read error after the form opened keeps it, with a warning '
      'that never says deleted (2.17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final detail = await env.cards.watchDetail(card.id).first;
    final source = StreamController<CardDetail?>();
    addTearDown(source.close);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_ScriptedDetail(source.stream)),
        ),
      ],
    );
    source.add(detail);
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');

    source.addError(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardEditorStaleTitle), findsOneWidget);
    expect(find.text(_en.cardEditorGoneTitle), findsNothing);
    expect(_text(tester, 1), 'changed');
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNotNull,
    );
    expect(find.textContaining('sqlite'), findsNothing);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart test/features/card/presentation/card_editor_screen_test.dart`
Expected: FAIL to compile (`cardEditorGoneTitle`, `cardEditorStaleTitle` are undefined).

- [ ] **Step 3: Implement**

3a. ARB. EN, after the `@cardGoneBody` entry:

```json
  "cardEditorGoneTitle": "This card was deleted.",
  "@cardEditorGoneTitle": {
    "description": "Danger banner above the card editor when the card went away while it was open (SP2a 2.17)."
  },
  "cardEditorGoneBody": "Your text is kept on this phone.",
  "@cardEditorGoneBody": {
    "description": "Danger banner body: the typed text is in the device-local draft."
  },
  "cardEditorStaleTitle": "Couldn't refresh this card.",
  "@cardEditorStaleTitle": {
    "description": "Warning banner above the card editor when reading the card failed after it opened."
  },
  "cardEditorStaleBody": "Your text is kept on this phone, and you can still save.",
  "@cardEditorStaleBody": {
    "description": "Warning banner body: nothing typed was lost."
  },
  "cardCaptionGone": "This card can't be saved now.",
  "@cardCaptionGone": {
    "description": "Card edit footer caption once the card is gone."
  },
```

VI, after the `"cardGoneBody"` line:

```json
  "cardEditorGoneTitle": "Thẻ này đã bị xoá.",
  "cardEditorGoneBody": "Nội dung bạn nhập được giữ trên điện thoại này.",
  "cardEditorStaleTitle": "Không làm mới được thẻ này.",
  "cardEditorStaleBody": "Nội dung bạn nhập được giữ trên điện thoại này, và bạn vẫn có thể lưu.",
  "cardCaptionGone": "Hiện không lưu được thẻ này.",
```

Run `flutter gen-l10n`.

3b. `lib/features/card/presentation/states/card_editor_source_state.dart`:

```dart
/// Where the card under edit stands while the form is open (SP2a 2.17): the
/// form never goes away with it, it only annotates itself.
enum CardEditorSource {
  /// The card is there.
  present,

  /// The card was deleted or trashed after the form opened.
  gone,

  /// Reading the card failed after the form opened; nothing says it is gone.
  unreadable,
}
```

3c. `card_editor_screen.dart`: replace `_EditLoader` (class and its state) with the following. `CardDetail` is imported from `package:memox/features/card/domain/models/card_detail_model.dart`, `CardEditorSource` from `package:memox/features/card/presentation/states/card_editor_source_state.dart`.

```dart
/// The card to edit while it loads, fails or is gone (ruling P4a-L4). Once
/// the form has opened it stays: a card that goes away later is shown on the
/// form, never in place of it, so typed text is not thrown away (SP2a 2.17).
class _EditLoader extends ConsumerStatefulWidget {
  const _EditLoader({
    required this.cardId,
    required this.deckContext,
    this.onOpenTrash,
  });

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<_EditLoader> createState() => _EditLoaderState();
}

class _EditLoaderState extends ConsumerState<_EditLoader> {
  static const int _skeletonRows = 4;

  /// The card as the form opened with it.
  CardDetail? _opened;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(widget.cardId);
    void back() => unawaited(Navigator.of(context).maybePop());
    final bar = MxAppBar(
      title: l10n.cardEditTitle,
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: back,
      ),
    );
    final value = ref.watch(provider);
    if (value case AsyncData(value: Ok(value: final detail))) {
      _opened ??= detail;
    }
    if (_opened case final opened?) {
      return CardEditorFormWidget(
        key: ValueKey(widget.cardId),
        deckId: opened.card.deckId,
        detail: opened,
        source: switch (value) {
          AsyncError() => CardEditorSource.unreadable,
          AsyncData(value: Rejected()) => CardEditorSource.gone,
          _ => CardEditorSource.present,
        },
        deckContext: widget.deckContext,
        onOpenTrash: widget.onOpenTrash,
      );
    }
    return switch (value) {
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: CardGoneWidget(
          title: l10n.cardGoneTitle,
          body: l10n.cardGoneBody,
          onBack: back,
          onOpenTrash: widget.onOpenTrash,
        ),
      ),
      AsyncError(:final isLoading) => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadErrorEditTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
              isRetrying: isLoading,
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }
}
```

The `CardEditorScreen.edit` still builds `_EditLoader(cardId: cardId!, deckContext: deckContext, onOpenTrash: onOpenTrash)`.

3d. `card_editor_form_widget.dart`. Import `package:memox/features/card/presentation/states/card_editor_source_state.dart`.

Constructor and field (after `detail`):

```dart
    this.source = CardEditorSource.present,
```
```dart
  /// Whether the card under edit is still there (SP2a 2.17).
  final CardEditorSource source;
```

State, next to `_isGone`:

```dart
  /// A new card's deck went away on Save: nothing is left to write to, so the
  /// page says so. (An edited card that goes away keeps the form; see
  /// [_isCardGone].)
  bool get _isDeckGone => _isCreating && _isGone;

  /// The card under edit was deleted, from outside or found missing on Save:
  /// the form stays with its text, Save is off and the draft is kept.
  bool get _isCardGone =>
      !_isCreating && (_isGone || widget.source == CardEditorSource.gone);
```

`didUpdateWidget`, next to `dispose`:

```dart
  @override
  void didUpdateWidget(CardEditorFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The card went away while it was open: what is on screen is written now.
    if (oldWidget.source != widget.source &&
        widget.source == CardEditorSource.gone) {
      _keepNow();
    }
  }
```

`_caption`: after the `_isSaving` line add `if (_isCardGone) return l10n.cardCaptionGone;`.

`_onSave`: add `!_isCardGone &&` after `!_deckRejects &&`.

`_afterSave`:

```dart
      case Rejected(reason: CardRejection.notFound):
        _keepNow();
        setState(() {
          _isSaving = false;
          _isGone = true;
        });
```

`build`: the `PopScope` `canPop` expression gains `|| _isCardGone`:

```dart
      canPop:
          !_isSaving &&
          (_isLeaving || _isGone || _deckRejects || _isCardGone || !_isDirty),
```

The footer and body switch on `_isDeckGone`:

```dart
        footer: _isDeckGone
            ? null
            : CardEditorFooterWidget(
                … unchanged …
              ),
        body: _isDeckGone
            ? CardGoneWidget(
                title: l10n.cardDeckGoneTitle,
                body: l10n.cardDeckGoneBody,
                onBack: _leave,
                onOpenTrash: widget.onOpenTrash,
              )
            : Column( … unchanged … ),
```

`_appBar`: `if (!_isCreating && !_isGone)` becomes `if (!_isCreating && !_isCardGone)`.

`_fields`: after the deck-rejects banner add:

```dart
    if (_isCardGone)
      MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.cardEditorGoneTitle,
        message: l10n.cardEditorGoneBody,
      )
    else if (widget.source == CardEditorSource.unreadable)
      MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.cardEditorStaleTitle,
        message: l10n.cardEditorStaleBody,
      ),
```

and the last block becomes `if (_card case final card? when !_isCardGone) CardTrashSectionWidget(card: card, onOpenTrash: widget.onOpenTrash),`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/presentation/card_editor_draft_test.dart test/features/card/presentation/card_editor_screen_test.dart test/features/card/presentation/card_editor_save_test.dart`
Then: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/app test/features/trash` and `flutter analyze lib/features/card`.
Expected: PASS; No issues found.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card test/features/card/presentation
git add lib/features/card/presentation lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/card/presentation
git commit -m "fix(card): a card that goes away keeps the editor form and its text (SP2a 2.17)"
```

---

### Task 19 (B8): Changed on another device — a typed outcome at save, and the choice (2.18)

**Files:**
- Modify: `lib/features/card/domain/failures/card_failure.dart:43` (new reason)
- Modify: `lib/features/card/domain/repositories/card_repository.dart:28-33` (`editCard`)
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart:75-91` (`editCard`)
- Modify: `lib/features/card/domain/usecases/edit_card_use_case.dart:10-15`
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart:77-80` (`editCard`)
- Modify: `lib/features/card/presentation/widgets/support/card_rejection_message_widget.dart:20`, `lib/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart:24` (exhaustive switches)
- Create: `lib/features/card/presentation/widgets/overlays/card_changed_dialog_widget.dart`
- Modify: `lib/features/card/presentation/screens/card_editor_screen.dart` (`_EditLoaderState`: track the latest card)
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (`latest`, `_card`, `_save`, the conflict flow)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (insert `cardRejectionChangedElsewhere` after `cardRejectionTargetInTrash`, lines 728 and 154; the dialog keys after `cardKeepEditing`, find it with `grep -n cardKeepEditing`)
- Modify: `test/features/card/presentation/card_editor_screen_test.dart` (`_CountingEdits`, lines 67–85), `test/features/card/presentation/card_editor_draft_test.dart` (`_HeldEdits`)
- Test: `test/features/card/data/card_batch_writes_test.dart` (group `editCard`, after the test at line 148), `test/features/card/presentation/card_actions_controller_test.dart`, `test/features/card/presentation/card_editor_draft_test.dart`

**Interfaces:**
- Consumes: the form's `_card`, `_adoptTheirs` needs the latest detail from the loader; `showMxDialog`, `MxDialog`, `MxSheetActions`.
- Produces:
  - `CardRejection.changedElsewhere`.
  - `Future<Outcome<void, CardRejection>> CardRepository.editCard({required String cardId, required CardDraft draft, DateTime? expectedUpdatedAt, DateTime? now})`. With an `expectedUpdatedAt` that is not the stored `updated_at`, nothing is written and the outcome is `Rejected(CardRejection.changedElsewhere)`; null skips the check ("Keep mine").
  - `EditCardUseCase.call({required String cardId, required CardDraft draft, DateTime? expectedUpdatedAt})` and `CardActionsController.editCard` with the same parameter.
  - `enum CardConflictChoice { useTheirs, keepMine }` and `Future<CardConflictChoice?> showCardChangedDialog(BuildContext context)`.
  - `CardEditorFormWidget({…, CardDetail? latest})`: the newest present detail, which "Use theirs" loads. ARB keys `cardChangedTitle`, `cardChangedBody`, `cardUseTheirs`, `cardKeepMine`, `cardRejectionChangedElsewhere`.
- Goldens: none move (a new one comes in B10).
- Conflict with cluster C (it edits `card_repository.dart`, `card_repository_impl.dart` and `card_actions_controller.dart` for the bulk outcome): the hunks are in different methods; rebase by hand if needed.
- DECISION D9 (the comparison is at second precision, as `updated_at` is stored).

- [ ] **Step 1: Write the failing tests**

In `card_batch_writes_test.dart`, inside `group('editCard (BR-CARD-005)', …)` add (the group's `cards` is built with `now: _t0`; `_later` is a day after):

```dart
    test('an edit that expects the version it read goes through; one that '
        'expects an older version is refused and writes nothing (2.18)', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b'),
      );
      // Another device saves first.
      await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'theirs'),
        now: _later,
      );

      final stale = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'mine'),
        expectedUpdatedAt: card.updatedAt,
        now: DateTime(2026, 9, 25),
      );

      expect(_reason(stale), CardRejection.changedElsewhere);
      expect((await cardRow(card.id))['back'], 'theirs');

      final current = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'mine'),
        expectedUpdatedAt: _later,
        now: DateTime(2026, 9, 25),
      );
      expect(current, isA<Ok<void, CardRejection>>());
      expect((await cardRow(card.id))['back'], 'mine');
    });

    test('without an expected version the edit overwrites the newer one '
        '("Keep mine", 2.18)', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b'),
      );
      await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'theirs'),
        now: _later,
      );

      final result = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'mine'),
        now: DateTime(2026, 9, 25),
      );

      expect(result, isA<Ok<void, CardRejection>>());
      expect((await cardRow(card.id))['back'], 'mine');
    });
```

In `card_actions_controller_test.dart`, append inside `main()`:

```dart
  test('editCard carries the version it read: an older one is refused as '
      'changedElsewhere (2.18)', () async {
    await seed();
    final stale = await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back'),
      expectedUpdatedAt: DateTime(2026, 8, 1),
    );
    expect(
      stale,
      isA<Rejected<Object?, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.changedElsewhere,
      ),
    );

    final current = await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back'),
      expectedUpdatedAt: DateTime(2026, 9, 1),
    );
    expect(current, isA<Ok<Object?, CardRejection>>());
  });
```

In the two fakes, add the new parameter so they stay valid overrides — `_CountingEdits` in `card_editor_screen_test.dart` and `_HeldEdits` in `card_editor_draft_test.dart`:

```dart
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  }) {
    edits++;
    return _cards.editCard(
      cardId: cardId,
      draft: draft,
      expectedUpdatedAt: expectedUpdatedAt,
      now: now,
    );
  }
```

(`_HeldEdits` awaits `release.future` and then forwards the same way.)

Append to `card_editor_draft_test.dart` (imports: `package:drift/drift.dart` `show Variable`):

```dart
Future<String> _backOf(LibraryEnv env, String cardId) async =>
    (await env.db
            .customSelect(
              'SELECT back FROM card WHERE id = ?',
              variables: [Variable<String>(cardId)],
            )
            .getSingle())
        .read<String>('back');

/// The other device's save, a day after the editor opened.
Future<void> _otherDeviceSaves(LibraryEnv env, String cardId) =>
    env.cards.editCard(
      cardId: cardId,
      draft: const CardDraft(front: 'bap', back: 'theirs'),
      now: DateTime.now().add(const Duration(days: 1)),
    );
```

```dart
  libraryTest('Save over a version another device saved asks first; Keep '
      'mine saves over it (2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();

    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardChangedTitle), findsOneWidget);
    expect(await _backOf(env, card.id), 'theirs');

    await tester.tap(find.text(_en.cardKeepMine));
    await tester.pumpAndSettle();
    expect(await _backOf(env, card.id), 'mine');
  });

  libraryTest('Use theirs reloads the card, drops the edits and the draft '
      '(2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await tester.pump(_pause);
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.cardUseTheirs));
    await tester.pumpAndSettle();

    expect(_text(tester, 1), 'theirs');
    expect(await _backOf(env, card.id), 'theirs');
    expect(await _drafts(env).read(CardDraftKey.edit(card.id)), isNull);
    expect(
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges)).onPressed,
      isNull,
    );
  });

  libraryTest('dismissing the dialog without a choice writes nothing and '
      'keeps the edits (2.18)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'mine');
    await _otherDeviceSaves(env, card.id);
    await tester.pump();
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardChangedTitle), findsNothing);
    expect(_text(tester, 1), 'mine');
    expect(await _backOf(env, card.id), 'theirs');
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/data/card_batch_writes_test.dart test/features/card/presentation/card_actions_controller_test.dart test/features/card/presentation/card_editor_draft_test.dart`
Expected: FAIL to compile (`expectedUpdatedAt`, `changedElsewhere` and the ARB keys do not exist).

- [ ] **Step 3: Implement**

3a. `card_failure.dart`, after `targetInTrash`:

```dart

  /// SP2a 2.18: the card carries another `updated_at` than the one the editor
  /// opened with, so another device saved it since.
  changedElsewhere,
```

3b. `card_repository.dart`, `editCard`:

```dart
  /// UC-CARD-001 A1: new content, flag and tags; the schedule row and the
  /// review log stay as they are (BR-CARD-005). When [expectedUpdatedAt] is
  /// given and the card carries another `updated_at`, nothing is written and
  /// the answer is `changedElsewhere` (SP2a 2.18); null skips the check.
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  });
```

3c. `card_repository_impl.dart`:

```dart
  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      final row = await _dao.findRow(cardId);
      if (row == null) return const Rejected(CardRejection.notFound);
      // ponytail: `updated_at` is stored in seconds, so a change in the same
      // second as the editor's version goes unseen; a version column would
      // close it.
      if (expectedUpdatedAt != null &&
          !row.updatedAt.isAtSameMomentAs(expectedUpdatedAt)) {
        return const Rejected(CardRejection.changedElsewhere);
      }
      await _dao.updateContent(cardId, draft, at);
      await _replaceTags(cardId, draft, at);
      return const Ok(null);
    });
  }
```

3d. `edit_card_use_case.dart`:

```dart
  Future<Outcome<void, CardRejection>> call({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
  }) => _cards.editCard(
    cardId: cardId,
    draft: draft,
    expectedUpdatedAt: expectedUpdatedAt,
  );
```

3e. `card_actions_controller.dart`:

```dart
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
  }) => ref.read(editCardUseCaseProvider)(
    cardId: cardId,
    draft: draft,
    expectedUpdatedAt: expectedUpdatedAt,
  );
```

3f. Copy. EN `app_en.arb`, after `@cardRejectionTargetInTrash`:

```json
  "cardRejectionChangedElsewhere": "This card changed on another device.",
  "@cardRejectionChangedElsewhere": {
    "description": "Card edit refusal: another device saved the card since the editor opened (SP2a 2.18). The editor asks Use theirs or Keep mine instead of showing this."
  },
```

after `@cardKeepEditing`:

```json
  "cardChangedTitle": "This card changed on another device",
  "@cardChangedTitle": {
    "description": "Dialog title when Save finds the card saved elsewhere since the editor opened (SP2a 2.18)."
  },
  "cardChangedBody": "Use theirs to reload the newer version and drop your edits. Keep mine to save over it.",
  "@cardChangedBody": {
    "description": "Dialog body naming what each choice does to the text."
  },
  "cardUseTheirs": "Use theirs",
  "@cardUseTheirs": {
    "description": "Dialog action (outline): reload the card as the other device left it."
  },
  "cardKeepMine": "Keep mine",
  "@cardKeepMine": {
    "description": "Dialog action (primary): save the typed text over the newer version."
  },
```

VI `app_vi.arb`: after `"cardRejectionTargetInTrash"` add `"cardRejectionChangedElsewhere": "Thẻ này vừa đổi trên thiết bị khác.",`; after `"cardKeepEditing"` add:

```json
  "cardChangedTitle": "Thẻ này đã đổi trên thiết bị khác",
  "cardChangedBody": "Chọn “Dùng bản kia” để tải lại bản mới hơn và bỏ phần bạn sửa. Chọn “Giữ bản của tôi” để lưu đè lên bản đó.",
  "cardUseTheirs": "Dùng bản kia",
  "cardKeepMine": "Giữ bản của tôi",
```

Both exhaustive switches get the case. `card_rejection_message_widget.dart`: `CardRejection.changedElsewhere => cardRejectionChangedElsewhere,`; `trash_rejection_message_widget.dart` (`trashCardRejection`): the same line. Run `flutter gen-l10n`.

3g. `lib/features/card/presentation/widgets/overlays/card_changed_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Which version wins when Save finds the card changed on another device
/// (SP2a 2.18).
enum CardConflictChoice { useTheirs, keepMine }

/// Asks which version to keep. Completes null when it is dismissed without a
/// choice: the form then stays as it is, unsaved.
Future<CardConflictChoice?> showCardChangedDialog(BuildContext context) =>
    showMxDialog<CardConflictChoice>(
      context,
      builder: (_) => const CardChangedDialogWidget(),
    );

class CardChangedDialogWidget extends StatelessWidget {
  const CardChangedDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.cardChangedTitle,
      body: l10n.cardChangedBody,
      actions: MxSheetActions(
        cancelLabel: l10n.cardUseTheirs,
        onCancel: () =>
            Navigator.of(context).pop(CardConflictChoice.useTheirs),
        confirmLabel: l10n.cardKeepMine,
        onConfirm: () => Navigator.of(context).pop(CardConflictChoice.keepMine),
      ),
    );
  }
}
```

3h. `_EditLoaderState` tracks the newest present detail:

```dart
  /// The card as the form opened with it, and as it stands now.
  CardDetail? _opened;
  CardDetail? _latest;
```

and the `if (value case AsyncData(value: Ok(value: final detail)))` block becomes

```dart
    if (value case AsyncData(value: Ok(value: final detail))) {
      _opened ??= detail;
      _latest = detail;
    }
```

with `latest: _latest,` passed to `CardEditorFormWidget` next to `source:`.

3i. The form. Imports: `package:memox/features/card/presentation/widgets/overlays/card_changed_dialog_widget.dart` (before `card_discard_dialog_widget`). Constructor and field:

```dart
    this.latest,
```
```dart
  /// The card as it stands now, which "Use theirs" loads (SP2a 2.18).
  final CardDetail? latest;
```

`late final _card = widget.detail?.card;` becomes `late var _card = widget.detail?.card;`.

`_save`:

```dart
  /// [overwrites] saves over a version another device saved ("Keep mine").
  Future<void> _save({bool overwrites = false}) async {
    if (_isSaving) return;
    if (!(_tagEditor.currentState?.commitPending() ?? true)) return;
    final draft = _draft();
    setState(() {
      _isSaving = true;
      _hasFailed = false;
    });
    final actions = ref.read(cardActionsControllerProvider.notifier);
    try {
      final Outcome<Object?, CardRejection> outcome = _isCreating
          ? await actions.createCard(deckId: widget.deckId, draft: draft)
          : await actions.editCard(
              cardId: _card!.id,
              draft: draft,
              expectedUpdatedAt: overwrites ? null : _card!.updatedAt,
            );
      if (!mounted) return;
      if (outcome case Rejected(reason: CardRejection.changedElsewhere)) {
        setState(() => _isSaving = false);
        await _resolveConflict();
        return;
      }
      _afterSave(outcome, draft);
    } on Failure {
      // Ruling P4a-L3: said in the form, with the typed content kept.
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasFailed = true;
      });
    }
  }

  /// SP2a 2.18: another device saved this card since the editor opened.
  Future<void> _resolveConflict() async {
    final choice = await showCardChangedDialog(context);
    if (!mounted) return;
    switch (choice) {
      case CardConflictChoice.keepMine:
        unawaited(_save(overwrites: true));
      case CardConflictChoice.useTheirs:
        _adoptTheirs();
      case null:
        return;
    }
  }

  /// "Use theirs": the card as the other device left it replaces the form's
  /// text, and the draft goes with the edits it held.
  void _adoptTheirs() {
    final theirs = widget.latest;
    if (theirs == null) return;
    final card = theirs.card;
    _card = card;
    _front.text = card.front;
    _back.text = card.back;
    _example.text = card.example ?? '';
    _hint.text = card.hint ?? '';
    _pronunciation.text = card.pronunciation ?? '';
    _tagEditor.currentState?.clearInput();
    setState(() {
      _tags = [for (final tag in theirs.tags) tag.name];
      _isFlagged = card.isFlagged;
      _touched.clear();
      _hasFailed = false;
      _saved = _draft();
    });
    unawaited(_drafts.clear());
  }
```

(The `_onSave` closure `() => unawaited(_save())` is unchanged.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/data/card_batch_writes_test.dart test/features/card/presentation/card_actions_controller_test.dart test/features/card/presentation/card_editor_draft_test.dart test/features/card/presentation/card_editor_screen_test.dart test/features/card/presentation/card_messages_test.dart test/features/trash/presentation/trash_rejection_message_test.dart`
Then: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/features/trash test/features/transfer test/app` and `flutter analyze lib test/features/card`.
Expected: PASS; No issues found (the two exhaustive `switch`es compile).

- [ ] **Step 5: Commit**

```bash
dart format lib/features/card lib/features/trash test/features/card test/features/trash
git add lib/features/card lib/features/trash lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/card test/features/trash
git commit -m "feat(card): a save over a version another device saved asks Use theirs or Keep mine (SP2a 2.18)"
```

---

### Task 20 (B9): Screen records 08 and 09

**Files:**
- Modify: `docs/shared/ui/screen-handoff/08-card-create.md`
- Modify: `docs/shared/ui/screen-handoff/09-card-edit.md`

**Interfaces:** none. Goldens: none. (`CLAUDE.md`: a PR that changes a screen updates its detail file; `00-index.md` rows 08 and 09 stay `built`.)

- [ ] **Step 1: Edit `08-card-create.md`**

1. In the Layout table, replace the Deck-rejects row's Design cell with `"This deck no longer accepts cards." / "It now holds sub-decks. Your text is kept on this phone."; shown only once the target deck can no longer hold a card. The text goes to the draft at once, and leaving asks nothing (SP2a 2.15).` and insert, right after it:

```markdown
| Draft banner | `CardDraftBannerWidget` (`MxInlineBanner` neutral) | "Unsaved text from earlier" / "Kept on this phone only, not synced. Restore it or discard it."; Discard (outline) and Restore (secondary), above the fields. Shown only when a draft kept on this device differs from the empty form; a draft equal to it is dropped (SP2a R9, 2.14). |
```

2. In the Footer row append `Cancel, the close button and Back are held while a save is in flight (SP2a 2.16).`
3. In States, add after `emptyForm` the row `| draftOffered | `card_editor_draft_light.png` | `card_editor_draft_dark.png` | The neutral banner above Front; Restore fills the form, Discard drops the draft. |` and replace the `deckRejects` row's App cell with `Caption "This deck can't take cards now." and banner "It now holds sub-decks. Your text is kept on this phone."; the draft stays and the next opening on that deck offers it back.`
4. In Rulings add: `- **SP2a R9 (2026-10-03, spec `2026-10-03-ui-hardening-sp2a-design.md` §3.2):** what is typed is kept in `card_draft`, 500 ms after the last change, per `create:<deckId>`. It is device-local: never synced, never logged, dropped after 30 days. A save, Discard on the discard dialog and an unchanged form clear it; a refused deck keeps it.`
5. In Copy replace `- Deck rejects:` line with `- Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks. Your text is kept on this phone."` and add `- Draft: "Unsaved text from earlier" · "Kept on this phone only, not synced. Restore it or discard it." · "Restore" · "Discard".`

- [ ] **Step 2: Edit `09-card-edit.md`**

1. Layout: after the `Deck path` row add the draft banner row (same text as in 08, "for an edit: when a draft kept for this card differs from the saved card") and, replacing the `Gone state` row, add:

```markdown
| Card-gone banner | `MxInlineBanner` (danger) above the form | "This card was deleted." / "Your text is kept on this phone."; Save is off (caption "This card can't be saved now."), the flag and the More card go, the form and its text stay and the draft is kept; leaving asks nothing (SP2a 2.17). |
| Stale banner | `MxInlineBanner` (warning) | "Couldn't refresh this card." / "Your text is kept on this phone, and you can still save."; shown when reading the card fails after the form opened. |
| Changed-elsewhere dialog | `CardChangedDialogWidget` (`MxDialog`, `MxSheetActions`) | "This card changed on another device" / "Use theirs to reload the newer version and drop your edits. Keep mine to save over it."; Use theirs (outline) and Keep mine (primary). Opens when Save finds another `updated_at` than the one the editor opened with (SP2a 2.18). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | Only when the card is gone before the form ever opened: "This card is no longer here" … (FE-B1 D11). |
```

2. States: replace the `notFound` row's App cell with `The full-page `CardGoneWidget` only when the card is already gone as the editor opens; once the form is open it stays with a danger banner.` and add rows `| cardDeleted | `card_editor_gone_light.png` | `card_editor_gone_dark.png` | The banner above the form, Save off. |`, `| changedElsewhere | `card_editor_changed_dialog_light.png` | `card_editor_changed_dialog_dark.png` | The dialog over the form. |`, `| draftOffered | no golden | no golden | As screen 08. |`.
3. Rulings: add `- **SP2a R9 (2026-10-03, §3.2):** as screen 08, per `edit:<cardId>`; the editor remembers the card's `updatedAt` when it opens and `editCard` compares it at save (`CardRejection.changedElsewhere`); "Keep mine" saves without the check, "Use theirs" reloads the card and clears the draft.`
4. Copy: add the new strings under their groups (Draft, Card gone banner, Changed elsewhere).

- [ ] **Step 3: Check and commit**

Run: `python tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

```bash
git add docs/shared/ui/screen-handoff/08-card-create.md docs/shared/ui/screen-handoff/09-card-edit.md
git commit -m "docs(ui): screens 08 and 09 record the card draft, the card-gone banner and the changed-elsewhere dialog (SP2a)"
```

---

### Task 21 (B10): Golden tests for the draft banner, the card-gone banner and the changed-elsewhere dialog

**Files:**
- Modify: `test/features/card/presentation/card_editor_golden_test.dart` (inside the `for (final brightness …)` loop, after the `'card editor, edit'` test)
- New golden PNGs (generated by the plan's golden task, in the Linux container): `test/features/card/presentation/goldens/card_editor_draft_{light,dark}.png`, `card_editor_gone_{light,dark}.png`, `card_editor_changed_dialog_{light,dark}.png`

**Interfaces:** consumes B1–B8. Goldens: adds six, moves none. Never `--update-goldens` on Windows: on Windows run `flutter test --exclude-tags golden`.

- [ ] **Step 1: Add the tests** (imports: `package:memox/features/card/data/repositories/card_draft_repository_impl.dart`, `package:memox/features/card/domain/models/card_draft_key_model.dart`)

```dart
    libraryTest('card editor, a kept draft is offered, $theme', (
      tester,
      env,
    ) async {
      final deckId = await _words(env);
      await CardDraftRepositoryImpl(env.db).save(
        CardDraftKey.create(deckId),
        const CardDraft(front: 'gamsahamnida', back: 'thank you'),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_draft_$theme.png',
        );
      });
    });

    libraryTest('card editor, the card was deleted, $theme', (tester, env) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(front: 'gamsahamnida', back: 'thank you'),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.edit(cardId: card.id, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).at(1), 'thank you!');
        await env.cards.deleteCards(cardIds: {card.id});
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_gone_$theme.png',
        );
      });
    });

    libraryTest('card editor, changed on another device, $theme', (
      tester,
      env,
    ) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(front: 'gamsahamnida', back: 'thank you'),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.edit(cardId: card.id, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).at(1), 'thank you!');
        await env.cards.editCard(
          cardId: card.id,
          draft: const CardDraft(front: 'gamsahamnida', back: 'thanks'),
          now: DateTime.now().add(const Duration(days: 1)),
        );
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text(_en.cardSaveChanges));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_changed_dialog_$theme.png',
        );
      });
    });
```

- [ ] **Step 2: Check they compile and the rest of the suite is untouched**

Run: `flutter analyze test/features/card/presentation/card_editor_golden_test.dart` — expected: No issues found. `flutter test --exclude-tags golden test/features/card` — expected PASS (the golden file is tagged and excluded on Windows).

- [ ] **Step 3: Commit** (the PNGs follow in the plan's golden task: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then without `--update`, then the golden-compare page for the owner)

```bash
dart format test/features/card/presentation/card_editor_golden_test.dart
git add test/features/card/presentation/card_editor_golden_test.dart
git commit -m "test(card): golden tests for the kept draft, the deleted card and the changed-elsewhere dialog (SP2a)"
```

---

---

### Task 22 (C1): Trash, Move and Flag skip gone ids and return `BulkOutcome`

**Also pin (Review Focus):** when every selected id is gone, the bulk action writes nothing, returns `BulkOutcome(done: 0, skipped: n)` and the UI shows the all-gone message without throwing — add the repository test and one widget test.

Finding 2.19 (card repository half). A card the person selected can vanish before the write (sync, another screen). Today `deleteCards`, `moveCards` and `setFlagged` compare `liveRows.length` with `cardIds.length` and refuse the whole batch with `notFound`; a stale id then makes the whole action fail for ever, because the selection still holds it.

**Files:**
- Create: `lib/core/error/bulk_outcome.dart`
- Modify: `lib/features/card/domain/repositories/card_repository.dart` (doc 11-17; `deleteCards` 35-42; `moveCards` 61-66; `setFlagged` 68-73)
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart` (imports 1-24; `deleteCards` 93-119; `moveCards` 155-199; `setFlagged` 201-216)
- Modify: `lib/features/card/domain/usecases/delete_cards_use_case.dart` (7-14), `move_cards_use_case.dart` (8-15), `set_cards_flagged_use_case.dart` (8-15)
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart` (imports 1-15; `setFlagged` 35-41; `moveCards` 52-58; `deleteCards` 60-63)
- Modify: `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart` (76-83, compile only)
- Modify (docs): `docs/features/card/rules/BR-CARD-011-mutation-hang-loat-all-or-nothing.md`, `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md` (53, 68-69), `docs/features/card/it-scenarios.md` (IT-ORG-014, 296-309)
- Test: `test/features/card/data/card_batch_writes_test.dart`, `test/features/card/data/card_trash_test.dart`; compile fixes in `card_restore_test.dart`, `card_restore_targets_test.dart`, `card_write_use_cases_test.dart`, `card_actions_controller_test.dart`, `card_list_flag_retry_test.dart`, `card_list_golden_test.dart`, `card_list_layout_test.dart`
- Goldens: none.

**Interfaces:**
- Produces (new, `lib/core/error/bulk_outcome.dart`):

```dart
final class BulkOutcome {
  const BulkOutcome({
    required this.done,
    this.skipped = const {},
    this.batchIds = const [],
  });
  final Set<String> done;      // ids written
  final Set<String> skipped;   // ids that were gone when the write ran
  final List<String> batchIds; // delete only: the Trash batch of each id of done, in its order
}
```

- Changes:

```dart
Future<Outcome<BulkOutcome, CardRejection>> CardRepository.deleteCards({required Set<String> cardIds, DateTime? now});
Future<Outcome<BulkOutcome, CardRejection>> CardRepository.moveCards({required Set<String> cardIds, required String targetDeckId, DateTime? now});
Future<Outcome<BulkOutcome, CardRejection>> CardRepository.setFlagged({required Set<String> cardIds, required bool isFlagged, DateTime? now});
```

  The use cases (`DeleteCardsUseCase`, `MoveCardsUseCase`, `SetCardsFlaggedUseCase`) and the `CardActionsController` methods of the same names return the same types. Rules: an empty set is `Ok(BulkOutcome(done: {}))`; no id left is `Rejected(CardRejection.notFound)`; a rule refusal (`sameDeck`, `crossRootMove`, …) still refuses the batch and writes nothing.
- Consumed by: C3 (toasts), C4 (export reuses `BulkOutcome`), C5, C9.

**DECISION:** `BulkOutcome` lives in `lib/core/error/` because the tags feature (`tags → ∅` in `test/architecture/boundary_rules.dart`) and the card feature both return it, and `core/` is the only layer both may import. CLAUDE.md asks the owner to rule on code added to `lib/core/`. Recommended: approve (14 lines, one consumer family). The alternative is a duplicate type in `tags`, which has no benefit.

- [ ] **Step 1: Write the failing tests**

In `test/features/card/data/card_batch_writes_test.dart` add imports:

```dart
import 'package:memox/core/error/bulk_outcome.dart';
```

Replace the test `'one missing card refuses the whole batch'` inside `group('deleteCards (BR-CARD-011)'` (lines 193-202) with:

```dart
    test('a card already gone or in the Trash is skipped; the rest go to the '
        'Trash a batch each (SP2a 2.19)', () async {
      final a = await cards.card(nouns.id);
      final b = await cards.card(nouns.id);
      final trashed = await cards.card(nouns.id);
      await trashCardRow(db, trashed.id);

      final result = await cards.deleteCards(
        cardIds: {a.id, 'missing', b.id, trashed.id},
      );

      final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
      expect(outcome.done, {a.id, b.id});
      expect(outcome.skipped, {'missing', trashed.id});
      expect(outcome.batchIds, hasLength(2));
      expect(await count('delete_batches'), 3, reason: 'two new, one fixture');
    });

    test('when no card is left the batch is notFound, writing nothing', () async {
      final before = await totalChanges(db);

      expect(
        _reason(await cards.deleteCards(cardIds: {'missing', 'gone'})),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
```

In `group('moveCards (BR-CARD-010)'`, in the test `'refuses a batch the rules refuse, writing nothing'` delete lines 268-271 (the `refusal({a.id, 'missing'}, verbs.id)` expectation), then add after that test:

```dart
    test('a card already gone is skipped; the others move (SP2a 2.19)', () async {
      final a = await cards.card(nouns.id);

      final result = await cards.moveCards(
        cardIds: {a.id, 'missing'},
        targetDeckId: verbs.id,
        now: _later,
      );

      final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
      expect(outcome.done, {a.id});
      expect(outcome.skipped, {'missing'});
      expect((await cardRow(a.id))['deck_id'], verbs.id);
      final before = await totalChanges(db);
      expect(
        _reason(
          await cards.moveCards(cardIds: {'missing'}, targetDeckId: verbs.id),
        ),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
```

In `group('setFlagged (BR-CARD-011)'` replace the test `'one missing card refuses the whole batch'` (lines 322-333) with:

```dart
    test('a card already gone is skipped; the rest are flagged (SP2a 2.19)', () async {
      final a = await cards.card(nouns.id);

      final result = await cards.setFlagged(
        cardIds: {a.id, 'missing'},
        isFlagged: true,
      );

      final outcome = (result as Ok<BulkOutcome, CardRejection>).value;
      expect(outcome.done, {a.id});
      expect(outcome.skipped, {'missing'});
      expect((await cardRow(a.id))['is_flagged'], 1);
      final before = await totalChanges(db);
      expect(
        _reason(await cards.setFlagged(cardIds: {'missing'}, isFlagged: true)),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
```

In the same file, in the test `'an empty batch writes nothing…'` (336-357) change line 344 `isA<Ok<List<String>, CardRejection>>()` to `isA<Ok<BulkOutcome, CardRejection>>()`, and the test `'deleting its last card leaves the deck row as it was'` (434-442) line 439 likewise.

In `test/features/card/data/card_trash_test.dart` add `import 'package:memox/core/error/bulk_outcome.dart';`, change the helper `delete` (46-49) to read `.value.batchIds`:

```dart
  Future<List<String>> delete(Set<String> cardIds) async =>
      ((await cards.deleteCards(cardIds: cardIds))
              as Ok<BulkOutcome, CardRejection>)
          .value
          .batchIds;
```

and replace the test at lines 124-149 with:

```dart
  test('a card that is gone or already in the Trash is skipped and the rest '
      'go; when none is left the set is notFound; an empty set writes nothing '
      '(UC-CARD-001 A2, SP2a 2.19)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await delete({'c2'});

    final outcome =
        (await cards.deleteCards(cardIds: {'c1', 'c2', 'missing'})
                as Ok<BulkOutcome, CardRejection>)
            .value;
    expect(outcome.done, {'c1'});
    expect(outcome.skipped, {'c2', 'missing'});
    expect(await batchOf('c1'), outcome.batchIds.single);

    final before = await totalChanges(db);
    expect(
      await cards.deleteCards(cardIds: {'c1', 'c2', 'missing'}),
      isA<Rejected<BulkOutcome, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.notFound,
      ),
    );
    expect(await delete({}), isEmpty);
    expect(await totalChanges(db), before);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/data/card_batch_writes_test.dart test/features/card/data/card_trash_test.dart`
Expected: FAIL to compile (`bulk_outcome.dart` does not exist; `BulkOutcome` undefined).

- [ ] **Step 3: Implement**

Create `lib/core/error/bulk_outcome.dart`:

```dart
/// What a bulk action did with the ids it was given (SP2a 2.19): the ones
/// that still existed were written, the ones already gone were skipped, all
/// inside the same transaction. A rule the cards break is not a skip: that
/// refuses the batch as a `Rejected`.
final class BulkOutcome {
  const BulkOutcome({
    required this.done,
    this.skipped = const {},
    this.batchIds = const [],
  });

  /// The ids written.
  final Set<String> done;

  /// The ids that were gone when the write ran (deleted, in the Trash, or,
  /// for an export, in another deck). The caller prunes them from the
  /// selection and says how many there were.
  final Set<String> skipped;

  /// A delete only: the Trash batch written for each id of [done], in its
  /// order. An Undo names them (BR-TRASH-008).
  final List<String> batchIds;
}
```

`card_repository.dart`: add `import 'package:memox/core/error/bulk_outcome.dart';` and replace the doc at 11-17 with

```dart
/// The one implementation is `CardRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
///
/// A batch takes a set of card ids and works in one transaction. The ids that
/// still exist are written and the ones already gone are skipped, answered as
/// a [BulkOutcome]; when none exists the batch is `notFound`. A card the
/// rules refuse (a move target that does not take it) refuses the whole
/// batch, and nothing is written (BR-CARD-011). An empty set writes nothing
/// and answers `Ok`.
```

and the three signatures (keep the doc sentences, change the return type):

```dart
  /// UC-CARD-001 A2: each card goes to the Trash as a batch of its own, all
  /// at one time, and the batch ids come back in `BulkOutcome.batchIds`, in
  /// the order of the cards done (BR-TRASH-001). A deck left with no active
  /// card is unset again (BR-TRASH-005); the sessions they touch end
  /// (BR-TRASH-004).
  Future<Outcome<BulkOutcome, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  });
  …
  /// BR-CARD-010: only `deck_id` and `updated_at` change.
  Future<Outcome<BulkOutcome, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  });

  /// An explicit value for every card, never a toggle (BR-CARD-011).
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  });
```

`card_repository_impl.dart`: add `import 'package:memox/core/error/bulk_outcome.dart';` (keep the imports sorted: after `app_database.dart`/`mapped_transaction.dart` block, before `core/error/failure.dart`). Replace the three methods:

```dart
  @override
  Future<Outcome<BulkOutcome, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (cardIds.isEmpty) return const Ok(BulkOutcome(done: {}));
      final rows = await _dao.liveRows(cardIds);
      if (rows.isEmpty) return const Rejected(CardRejection.notFound);
      final live = {for (final row in rows) row.id};
      // In the order asked; a card already gone is skipped, not refused
      // (SP2a 2.19).
      final done = {
        for (final id in cardIds)
          if (live.contains(id)) id,
      };
      // One batch per card, all at one time: each card is an item the person
      // can restore on its own (BR-TRASH-001).
      final batchIds = <String>[];
      for (final cardId in done) {
        final batchId = newId();
        await _dao.moveToTrash(cardId, batchId, at);
        batchIds.add(batchId);
      }
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      for (final batchId in batchIds) {
        await _dao.closeSessionsTouching(batchId, at);
      }
      return Ok(
        BulkOutcome(
          done: done,
          skipped: cardIds.difference(live),
          batchIds: batchIds,
        ),
      );
    });
  }
```

```dart
  @override
  Future<Outcome<BulkOutcome, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (cardIds.isEmpty) return const Ok(BulkOutcome(done: {}));
      final rows = await _dao.liveRows(cardIds);
      if (rows.isEmpty) return const Rejected(CardRejection.notFound);
      final live = {for (final row in rows) row.id};
      final target = await _dao.deckRow(targetDeckId);
      if (target == null) return const Rejected(CardRejection.targetNotFound);
      final sourceDeckIds = {for (final row in rows) row.deckId};
      final sources = await _dao.deckRows(sourceDeckIds);
      if (sources.length != sourceDeckIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final targetContentType = DeckContentType.values.byName(
        target.contentType,
      );
      final rule = CardEntity.checkMove(
        targetDeckId: target.id,
        targetRootId: target.rootId,
        targetIsRoot: target.parentId == null,
        targetContentType: targetContentType,
        sourceDeckIds: sourceDeckIds,
        sourceRootIds: {for (final source in sources) source.rootId},
      );
      if (rule case Rejected(:final reason)) return Rejected(reason);

      await _dao.moveCards(live, targetDeckId, at);
      await _unsetEmptied(sourceDeckIds, at);
      if (targetContentType == DeckContentType.unset) {
        await _dao.setDeckContentType(
          targetDeckId,
          DeckContentType.card.name,
          at,
        );
      }
      return Ok(BulkOutcome(done: live, skipped: cardIds.difference(live)));
    });
  }
```

```dart
  @override
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (cardIds.isEmpty) return const Ok(BulkOutcome(done: {}));
      final rows = await _dao.liveRows(cardIds);
      if (rows.isEmpty) return const Rejected(CardRejection.notFound);
      final live = {for (final row in rows) row.id};
      await _dao.setFlagged(live, isFlagged, at);
      return Ok(BulkOutcome(done: live, skipped: cardIds.difference(live)));
    });
  }
```

The three use cases: add `import 'package:memox/core/error/bulk_outcome.dart';` and change the `call` return type, e.g. `Future<Outcome<BulkOutcome, CardRejection>> call({required Set<String> cardIds}) => _cards.deleteCards(cardIds: cardIds);`. Update the `DeleteCardsUseCase` doc: "…each as a batch of its own whose ids come back in `BulkOutcome.batchIds` (BR-TRASH-001)".

`card_actions_controller.dart`: add the same import; change the three return types and the doc of `deleteCards` to "Moves the cards that still exist to the Trash; `BulkOutcome.batchIds` holds one batch per card, which an Undo names."

`card_delete_dialog_widget.dart` lines 77-83:

```dart
        case Ok(:final value):
          showCardsTrashedSnackbar(
            context,
            batchIds: value.batchIds,
            front: widget.preview?.front,
            onOpenTrash: widget.onOpenTrash,
          );
```

- [ ] **Step 4: Fix the other consumers of the old types**

Compile-only edits (run `flutter analyze` to find any I missed; the sites known today):

| File | Before | After |
|---|---|---|
| `test/features/card/data/card_restore_test.dart:50-52` | `)) as Ok<List<String>, CardRejection>).value;` | `)) as Ok<BulkOutcome, CardRejection>).value.batchIds;` (+ import `core/error/bulk_outcome.dart`) |
| `test/features/card/data/card_restore_targets_test.dart:35-37` | `)) as Ok<List<String>, CardRejection>).value;` | `)) as Ok<BulkOutcome, CardRejection>).value.batchIds;` (+ import) |
| `test/features/card/domain/card_write_use_cases_test.dart:138` | `final [batchId] = (deleted as Ok<List<String>, CardRejection>).value;` | `final [batchId] = (deleted as Ok<BulkOutcome, CardRejection>).value.batchIds;` (+ import) |
| `test/features/card/presentation/card_actions_controller_test.dart:117` | `expect((outcome as Ok<List<String>, CardRejection>).value, hasLength(2));` | `expect((outcome as Ok<BulkOutcome, CardRejection>).value.batchIds, hasLength(2));` (+ import) |
| `card_list_flag_retry_test.dart:59-65`, `card_list_golden_test.dart:52-56`, `card_list_layout_test.dart:74-78` and `:90-100` | `Future<Outcome<void, CardRejection>> setFlagged({` | `Future<Outcome<BulkOutcome, CardRejection>> setFlagged({` (+ import) |
| `card_list_flag_retry_test.dart:68`, `card_list_layout_test.dart:99` | `return const Ok(null);` / `Future.value(const Ok(null))` | `return const Ok(BulkOutcome(done: {}));` / `Future.value(const Ok(BulkOutcome(done: {})))` |

`isA<Ok<void, CardRejection>>()` matchers elsewhere keep passing (`BulkOutcome` is a `void`); leave them.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `flutter test test/features/card/data/card_batch_writes_test.dart test/features/card/data/card_trash_test.dart test/features/card/data/card_restore_test.dart test/features/card/data/card_restore_targets_test.dart test/features/card/domain/card_write_use_cases_test.dart test/features/card/presentation/card_actions_controller_test.dart test/features/card/data/card_batch_limit_test.dart`
Expected: PASS.
Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/features/study test/features/progress test/features/search test/features/trash`
Expected: PASS (those folders call `deleteCards`, `moveCards` or `setFlagged`).

- [ ] **Step 6: Update the docs (Vietnamese; the docs of this repo are Vietnamese)**

`BR-CARD-011-…md`: replace the front-matter `summary:` with `summary: Mọi mutation hàng loạt trên thẻ chạy trong một transaction, giữ quy tắc của thao tác đơn lẻ; thẻ đã không còn bị bỏ qua.` and replace the first paragraph under `## Rule` with:

```
Mọi mutation hàng loạt trên thẻ — di chuyển, xoá, đặt/bỏ cờ, gắn tag — MUST chạy trong **đúng một transaction** và giữ quy tắc của thao tác đơn lẻ: một thẻ vi phạm luật (đích di chuyển từ chối nó, tag chạm trần 10) làm cả lô rollback, và MUST NOT có partial success không được đặc tả. Một thẻ **không còn tồn tại** lúc ghi (đã bị xoá, đã vào Trash) không phải là vi phạm luật: lô bỏ qua thẻ đó trong cùng transaction, ghi các thẻ còn lại và trả `BulkOutcome(done, skipped)`; UI nêu số thẻ đã bỏ qua và dọn các id đó khỏi selection. Khi không còn thẻ nào tồn tại, lô bị từ chối `notFound` và không ghi gì. Gắn tag hàng loạt MUST giữ nguyên quy tắc đơn lẻ: dùng lại tag theo tên đã fold (BR-TAG-001), trần 10 tag mỗi thẻ (BR-TAG-002), và **idempotent** khi thẻ đã có tag đó. Chỉ cần một thẻ chạm trần là cả lô bị từ chối. Đặt cờ hàng loạt MUST là lệnh tường minh `Set flagged` / `Remove flag`, MUST NOT là toggle suy ra từ thẻ đầu tiên. Xoá hàng loạt MUST cascade study state và history như xoá đơn lẻ, và MUST đưa deck về `unset` nếu đó là những thẻ cuối (BR-DECK-015).
```

`UC-CARD-001-…md`: line 53 `Mỗi thao tác là all-or-nothing (BR-CARD-011).` → `Mỗi thao tác chạy trong một transaction: thẻ vi phạm luật làm cả lô rollback, thẻ đã không còn bị bỏ qua (BR-CARD-011).` Add after the `E7` bullet: `- **E8 — Một thẻ trong lô đã không còn:** thẻ đó bị bỏ qua, các thẻ còn lại được ghi; thông báo nêu số thẻ đã bỏ qua và selection được dọn id đó; không còn thẻ nào thì lỗi `notFound` (BR-CARD-011).`

`it-scenarios.md` IT-ORG-014: replace step 4 with
`| 4 | Chạy một bulk action mà một thẻ vi phạm luật (đích bị từ chối, tag chạm trần) | **Không** thẻ nào được ghi; selection giữ nguyên để thử lại |` and add
`| 5 | Chạy một bulk action khi một thẻ đã bị xoá ở nơi khác | Thẻ đó bị bỏ qua, các thẻ còn lại được ghi; thông báo nêu số thẻ đã bỏ qua |`.

Run: `python tools/docs/generate.py` then `python tools/docs/check.py`. Expected: check exits 0.

- [ ] **Step 7: Commit**

```bash
git add lib/core/error/bulk_outcome.dart lib/features/card lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart test/features/card docs/features/card docs/_generated
git commit -m "fix(card): bulk trash, move and flag skip cards that are already gone (SP2a 2.19)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 23 (C2): Tag skips gone ids; a refused bulk Tag names the cards at the limit

Findings 2.19 (tag half) and 2.21. `TagRepository.attachByName` compares `liveCardCount` with `cardIds.length` (`tag_repository_impl.dart:37`) and answers `tooManyTags` with no payload, so the dialog can only say "A card holds 10 tags at most." (`card_tag_dialog_widget.dart:84-86`) without saying how many cards are full.

**Files:**
- Create: `lib/features/tags/domain/models/tag_attach_model.dart`
- Modify: `lib/core/database/queries/tag_queries.drift` (add after `liveCardCountIn`, line 15-16)
- Modify: `lib/features/tags/data/datasources/tag_dao.dart` (add after `liveCardCount`, 33-40)
- Modify: `lib/features/tags/domain/repositories/tag_repository.dart` (`attachByName` doc and signature 17-24; class doc 8-12)
- Modify: `lib/features/tags/data/repositories/tag_repository_impl.dart` (26-55)
- Modify: `lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart` (7-16)
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart` (`addTag` 43-50)
- Modify: `lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart` (68-87)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify (docs): `docs/features/card/rules/BR-CARD-011-mutation-hang-loat-all-or-nothing.md`
- Test: `test/features/tags/data/tag_repository_impl_test.dart`, `test/features/tags/data/tag_batch_limit_test.dart`, `test/features/card/presentation/card_bulk_actions_test.dart`
- Goldens: none.

**Interfaces:**
- Consumes: `BulkOutcome` (C1).
- Produces (`lib/features/tags/domain/models/tag_attach_model.dart`):

```dart
sealed class TagAttach { const TagAttach(); }
final class TagAttached extends TagAttach {
  const TagAttached(this.outcome);
  final BulkOutcome outcome;
}
final class TagLimitReached extends TagAttach {
  const TagLimitReached(this.fullCardIds);
  final Set<String> fullCardIds; // cards at 10 tags that lack the tag; nothing was written
}
```

- Changes: `Future<Outcome<TagAttach, TagRejection>> TagRepository.attachByName({required Set<String> cardIds, required String name, DateTime? now})`; same type from `AddTagToCardsUseCase.call` and `CardActionsController.addTag`. `Rejected` still carries the name reasons (`blankName`, `nameTooLong`, `controlCharacter`) and `notFound` (no card left). A card over the limit is no longer a `Rejected(tooManyTags)` here: the refusal now carries the ids, so the sealed result is the typed form (precedent: `TagRenamePlan`). `TagRejection.tooManyTags` stays for `replaceForCard`. BR-TAG-002 holds: nothing is written.
- New ARB key `cardTagLimitReached(int count)`.
- `detach` is unchanged: no UI calls it today (only `RemoveTagFromCardsUseCase` and its test); give it the same skip when its UI is wired.

- [ ] **Step 1: Write the failing tests**

`test/features/tags/data/tag_repository_impl_test.dart`: add `import 'package:memox/features/tags/domain/models/tag_attach_model.dart';`. Replace the test `'one card at 10 tags refuses the whole batch, writing nothing (BR-TAG-002)'` (lines 141-155) and the test `'a missing card refuses the batch with notFound'` (168-179) with:

```dart
    test('cards at 10 tags refuse the whole batch and are named, writing '
        'nothing (BR-TAG-002, SP2a 2.21)', () async {
      await _cards(db, ['full', 'free', 'full2']);
      await _tagged(db, 'full', 10);
      await _tagged(db, 'full2', 10);
      final before = await totalChanges(db);

      final result = await tags.attachByName(
        cardIds: {'full', 'free', 'full2'},
        name: 'Noun',
      );

      final limit =
          (result as Ok<TagAttach, TagRejection>).value as TagLimitReached;
      expect(limit.fullCardIds, {'full', 'full2'});
      expect(await totalChanges(db), before);
      expect(await _tagNamesOf(db, 'free'), isEmpty);
    });

    test('a card already gone is skipped; the others are tagged (SP2a 2.19)', () async {
      await _cards(db, ['c1']);

      final result = await tags.attachByName(
        cardIds: {'c1', 'gone'},
        name: 'Noun',
      );

      final attached =
          ((result as Ok<TagAttach, TagRejection>).value as TagAttached)
              .outcome;
      expect(attached.done, {'c1'});
      expect(attached.skipped, {'gone'});
      expect(await _tagNamesOf(db, 'c1'), ['Noun']);
    });

    test('when every card is gone the batch is notFound, writing nothing', () async {
      final before = await totalChanges(db);

      final result = await tags.attachByName(cardIds: {'gone'}, name: 'Noun');

      expect(_reasonOf(result), TagRejection.notFound);
      expect(await totalChanges(db), before);
    });
```

`test/features/tags/data/tag_batch_limit_test.dart`, in the test `'the tag counts and live count of a large selection are read whole'` add after the `liveCardCount` expectation:

```dart
      expect(await dao.liveCardIds({..._ids, 'gone'}), _ids);
```

`test/features/card/presentation/card_bulk_actions_test.dart`: replace the expectation at line 186 with the named count (the seed gives `new1` ten tags and selects `annyeong` and `gamsa`, so one card is full):

```dart
      expect(find.text(_en.cardTagLimitReached(1)), findsOneWidget);
```

and add a test after it:

```dart
  libraryTest('Tag names how many cards are full, not only that one is '
      '(SP2a 2.21)', (tester, env) async {
    final ids = await _seed(env);
    final tags = TagRepositoryImpl(env.db);
    for (final card in ['new1', 'due1']) {
      for (var i = 0; i < 10; i++) {
        await tags.attachByName(cardIds: {card}, name: '$card tag $i');
      }
    }
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa', 'mul']);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'extra');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardTagLimitReached(2)), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 20);
  });
```

(`_seed` is the file's helper: it puts `new1`, `due1`, `flag1` in `Korean › Words`.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/tags/data/tag_repository_impl_test.dart test/features/card/presentation/card_bulk_actions_test.dart`
Expected: FAIL to compile (`tag_attach_model.dart` missing, `cardTagLimitReached` undefined).

- [ ] **Step 3: Implement**

Create `lib/features/tags/domain/models/tag_attach_model.dart`:

```dart
import 'package:memox/core/error/bulk_outcome.dart';

/// What attaching one tag to several cards came to (UC-CARD-001 A8). A card
/// at the limit does not fail the call with a bare reason: the person is told
/// which cards, so the answer carries them.
sealed class TagAttach {
  const TagAttach();
}

/// The tag is on every card of [outcome].done; the ones already gone were
/// skipped (SP2a 2.19).
final class TagAttached extends TagAttach {
  const TagAttached(this.outcome);

  final BulkOutcome outcome;
}

/// BR-TAG-002: these cards already hold 10 tags and lack this one. Nothing
/// was written, for any card.
final class TagLimitReached extends TagAttach {
  const TagLimitReached(this.fullCardIds);

  final Set<String> fullCardIds;
}
```

`tag_queries.drift`, after `liveCardCountIn`:

```sql
-- SP2a 2.19: the live cards among :card_ids, one chunk at a time.
liveCardIdsIn:
SELECT id FROM card WHERE id IN :card_ids AND delete_batch_id IS NULL
ORDER BY id;
```

`tag_dao.dart`, after `liveCardCount`:

```dart
  /// The ids of [cardIds] that exist as live cards, read in chunks (BE-C2).
  Future<Set<String>> liveCardIds(Set<String> cardIds) async => {
    for (final chunk in idChunks(cardIds)) ...await liveCardIdsIn(chunk).get(),
  };
```

`tag_repository.dart`: add `import 'package:memox/features/tags/domain/models/tag_attach_model.dart';` and replace `attachByName`:

```dart
  /// Links the tag named [name] to every card of [cardIds] that still exists:
  /// the tag with the same folded name is reused, or created (BR-TAG-001). A
  /// card that already carries it is left as it is; a card already gone is
  /// skipped (SP2a 2.19), and none left is `notFound`. When any card would
  /// pass 10 tags, nothing is written and the answer is [TagLimitReached],
  /// naming those cards (BR-TAG-002, BR-CARD-011).
  Future<Outcome<TagAttach, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  });
```

`tag_repository_impl.dart` (add imports `core/error/bulk_outcome.dart` and `tag_attach_model.dart`), replace `attachByName`:

```dart
  @override
  Future<Outcome<TagAttach, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (TagEntity.checkName(name) case Rejected(:final reason)) {
        return Rejected(reason);
      }
      if (cardIds.isEmpty) {
        return const Ok(TagAttached(BulkOutcome(done: {})));
      }
      final live = await _dao.liveCardIds(cardIds);
      if (live.isEmpty) return const Rejected(TagRejection.notFound);
      final existing = await _dao.findByFoldedName(TagEntity.fold(name));
      final lacking = existing == null
          ? live
          : live.difference(await _dao.cardsCarrying(live, existing.id));
      final counts = await _dao.tagCounts(lacking);
      final full = {
        for (final MapEntry(key: cardId, value: count) in counts.entries)
          if (count >= TagEntity.maxPerCard) cardId,
      };
      if (full.isNotEmpty) return Ok(TagLimitReached(full));

      final tagId = existing?.id ?? await _createTag(name, at);
      for (final cardId in lacking) {
        await _dao.link(cardId, tagId);
      }
      return Ok(
        TagAttached(
          BulkOutcome(done: live, skipped: cardIds.difference(live)),
        ),
      );
    });
  }
```

`add_tag_to_cards_use_case.dart`: return `Future<Outcome<TagAttach, TagRejection>>` (import the model). `card_actions_controller.dart` `addTag`: same return type (import `tag_attach_model.dart`).

`card_tag_dialog_widget.dart`: import `tag_attach_model.dart`, replace the switch (lines 68-87) with:

```dart
      switch (outcome) {
        case Ok(value: TagAttached(outcome: final bulk)):
          showMxSnackbar(
            context,
            message: l10n.cardTaggedToast(bulk.done.length, _name.text.trim()),
          );
          Navigator.of(context).pop(true);
        // IT-ORG-014, BR-TAG-002: nothing was written; the selection stays.
        case Ok(value: TagLimitReached(:final fullCardIds)):
          showMxSnackbar(
            context,
            message: l10n.cardTagLimitReached(fullCardIds.length),
          );
          Navigator.of(context).pop(false);
        case Rejected(:final reason) when _nameReasons.contains(reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
        case Rejected(:final reason):
          showMxSnackbar(context, message: l10n.tagRejection(reason));
          Navigator.of(context).pop(false);
      }
```

ARB. EN (`app_en.arb`, after the `cardTaggedToast` block):

```json
  "cardTagLimitReached": "{count, plural, =1{1 card already has 10 tags; nothing was tagged.} other{{count} cards already have 10 tags; nothing was tagged.}}",
  "@cardTagLimitReached": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Snackbar when a bulk tag is refused because cards already hold the 10-tag limit (BR-TAG-002); count is how many."
  },
```

VI (`app_vi.arb`, after `cardTaggedToast`):

```json
  "cardTagLimitReached": "{count, plural, other{{count} thẻ đã có 10 nhãn; chưa gắn nhãn nào.}}",
```

Run `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `flutter test test/features/tags/data/tag_repository_impl_test.dart test/features/tags/data/tag_batch_limit_test.dart test/features/card/presentation/card_bulk_actions_test.dart test/features/card/presentation/card_actions_controller_test.dart`
Expected: PASS. (`card_actions_controller_test` `addTag` asserts `isA<Ok<Object?, TagRejection>>()`, still true.)

- [ ] **Step 5: Docs**

`BR-CARD-011-…md`, in the paragraph C1 wrote, replace `Chỉ cần một thẻ chạm trần là cả lô bị từ chối.` with `Chỉ cần một thẻ chạm trần là cả lô bị từ chối và không ghi gì; thông báo nêu số thẻ đã chạm trần.` Run `python tools/docs/generate.py` and `python tools/docs/check.py` (exit 0).

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/queries/tag_queries.drift lib/features/tags lib/features/card lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/tags test/features/card docs/features/card docs/_generated
git commit -m "fix(tags): bulk tag skips gone cards and names the cards at the limit (SP2a 2.19, 2.21)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 24 (C3): Toasts say how many cards were already gone

Finding 2.19 (UI half): "Moved 799 cards. 1 was already gone." for Move, Flag, Tag and Trash. Export is C4. The selection needs no pruning here: every successful path already clears it (`_clearAfter` / `_writeFlag`), which is a superset of pruning.

**Files:**
- Create: `lib/l10n/bulk_message.dart`
- Create: `test/l10n/bulk_message_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart` (64-72)
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (`_writeFlag` 158-171)
- Modify: `lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart` (the `TagAttached` case C2 wrote)
- Modify: `lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart` (14-48)
- Modify: `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart` (76-83)
- Test: `test/features/card/presentation/card_bulk_actions_test.dart`
- Goldens: none (no golden shows a bulk toast with skips).

**Interfaces:**
- Produces: `extension BulkMessage on AppLocalizations { String bulkToast(String message, int skipped); }` in `lib/l10n/bulk_message.dart` (returns `message` when `skipped == 0`).
- Produces: `showCardsTrashedSnackbar(BuildContext context, {required List<String> batchIds, String? front, VoidCallback? onOpenTrash, int skipped = 0})`.
- New ARB key `cardBulkWithSkipped(String message, int count)`.

- [ ] **Step 1: Write the failing tests**

`test/l10n/bulk_message_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('a bulk toast is the message alone when nothing was skipped', () {
    expect(en.bulkToast('2 cards moved to Verbs', 0), '2 cards moved to Verbs');
  });

  test('it adds how many were already gone, as a plural', () {
    expect(
      en.bulkToast('2 cards moved to Verbs', 1),
      '2 cards moved to Verbs. 1 was already gone.',
    );
    expect(
      en.bulkToast('2 cards moved to Verbs', 3),
      '2 cards moved to Verbs. 3 were already gone.',
    );
  });

  test('the Vietnamese copy carries the same count', () {
    expect(
      vi.bulkToast('Đã chuyển 2 thẻ vào Verbs', 3),
      'Đã chuyển 2 thẻ vào Verbs. 3 thẻ đã không còn.',
    );
  });
}
```

In `card_bulk_actions_test.dart` add (before `'the bulk bar meets the target guidelines'`), each deleting one selected card behind the screen's back, which is the stale-id case:

```dart
  libraryTest('Move skips a card that went meanwhile and says so (SP2a 2.19)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardMovedToast(1, 'Verbs'), 1)),
      findsOneWidget,
    );
    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [
        ids.verbs,
      ]),
      2,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Flag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagSet);

    expect(
      find.text(_en.bulkToast(_en.cardFlaggedToast(1), 1)),
      findsOneWidget,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Tag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardTaggedToast(1, 'greetings'), 1)),
      findsOneWidget,
    );
  });

  libraryTest('Trash skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardsTrashedToast(1), 1)),
      findsOneWidget,
    );
    expect(await _activeCount(env), 2);
  });
```

Add `import 'package:memox/l10n/bulk_message.dart';` to the test file.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/l10n/bulk_message_test.dart test/features/card/presentation/card_bulk_actions_test.dart`
Expected: FAIL to compile (`bulk_message.dart`, `cardBulkWithSkipped` missing).

- [ ] **Step 3: Implement**

ARB. EN (after `cardMovedToast`):

```json
  "cardBulkWithSkipped": "{message}. {count, plural, =1{1 was already gone.} other{{count} were already gone.}}",
  "@cardBulkWithSkipped": {
    "placeholders": {
      "message": {
        "type": "String"
      },
      "count": {
        "type": "int"
      }
    },
    "description": "A bulk action's toast plus how many of the selected cards were already gone when it ran (SP2a 2.19); message is the toast without that part."
  },
```

VI (after `cardMovedToast`): `"cardBulkWithSkipped": "{message}. {count, plural, other{{count} thẻ đã không còn.}}",`

`lib/l10n/bulk_message.dart`:

```dart
import 'package:memox/l10n/generated/app_localizations.dart';

/// The one place a bulk action's toast gains "N were already gone" (SP2a
/// 2.19), for every action and both features.
extension BulkMessage on AppLocalizations {
  String bulkToast(String message, int skipped) =>
      skipped == 0 ? message : cardBulkWithSkipped(message, skipped);
}
```

Call sites (each imports `package:memox/l10n/bulk_message.dart`):

- `card_move_sheet_widget.dart` 66-72:

```dart
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok(:final value) => l10n.bulkToast(
            l10n.cardMovedToast(value.done.length, target.name),
            value.skipped.length,
          ),
          Rejected(:final reason) => l10n.cardRejection(reason),
        },
      );
```

- `card_list_section_widget.dart` `_writeFlag`, the `case Ok():` branch becomes:

```dart
        case Ok(:final value):
          _selection().clear();
          showMxSnackbar(
            context,
            message: l10n.bulkToast(
              isFlagged
                  ? l10n.cardFlaggedToast(value.done.length)
                  : l10n.cardUnflaggedToast(value.done.length),
              value.skipped.length,
            ),
          );
```

- `card_tag_dialog_widget.dart`, the `TagAttached` toast:

```dart
          showMxSnackbar(
            context,
            message: l10n.bulkToast(
              l10n.cardTaggedToast(bulk.done.length, _name.text.trim()),
              bulk.skipped.length,
            ),
          );
```

- `card_delete_dialog_widget.dart`: pass `skipped: value.skipped.length` to `showCardsTrashedSnackbar`.
- `card_trashed_snackbar_widget.dart`: add `int skipped = 0` to the signature and the doc ("`skipped` is how many of the selected cards were already gone"), and wrap the two messages:

```dart
      message: front == null
          ? l10n.bulkToast(l10n.cardsTrashedToast(1), skipped)
          : l10n.cardTrashedToast(front),
```
and in the several-cards toast `message: l10n.bulkToast(l10n.cardsTrashedToast(batchIds.length), skipped),`. Add the import.

Run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `flutter test test/l10n/bulk_message_test.dart test/features/card/presentation/card_bulk_actions_test.dart test/features/card/presentation/card_messages_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n lib/features/card test/l10n/bulk_message_test.dart test/features/card
git commit -m "feat(card): bulk toasts say how many selected cards were already gone (SP2a 2.19)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 25 (C4): Export skips gone ids, says so, and prunes the selection

Finding 2.19 (export half). `CardTransferRepositoryImpl.exportSnapshot` refuses the whole request when `rows.length != cardIds.length` (`card_transfer_repository_impl.dart:89-91`), and BR-TRANSFER-007 / UC-TRANSFER-002 E6 say so. The sheet therefore dead-ends on one stale id while the selection keeps it.

**Files:**
- Modify: `lib/features/card/domain/models/card_export_snapshot_model.dart` (`CardExportSnapshot` 26-32)
- Modify: `lib/features/card/domain/repositories/card_transfer_repository.dart` (`exportSnapshot` doc 36-44)
- Modify: `lib/features/card/data/repositories/card_transfer_repository_impl.dart` (80-112)
- Modify: `lib/features/transfer/domain/models/export_artifact_model.dart` (`ExportArtifact` 6-17)
- Modify: `lib/features/transfer/domain/usecases/build_export_use_case.dart` (26-61)
- Modify: `lib/features/transfer/presentation/states/card_export_state.dart` (`CardExportState` 73-95)
- Modify: `lib/features/transfer/presentation/controllers/card_export_controller.dart` (`export` 53-57)
- Modify: `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart` (27-42; 46-72; 87-89; 260)
- Modify: `lib/features/card/presentation/states/card_selection_state.dart` (add `prune`)
- Modify: `lib/app/router/app_router.dart` (393-398; imports)
- Modify (docs): `docs/features/transfer/rules/BR-TRANSFER-007-hai-scope-export.md`, `docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md` (E6 71-74, criterion 99)
- Test: `test/features/card/data/card_transfer_test.dart`, `test/features/transfer/domain/export_use_cases_test.dart`, `test/features/transfer/presentation/card_export_controller_test.dart`, `test/features/transfer/presentation/card_export_sheet_test.dart`, `test/features/card/presentation/card_selection_test.dart`
- Goldens: none (`export_stale_*` shows the all-gone banner, unchanged copy).

**Interfaces:**
- Consumes: nothing from C1-C3 except `bulkToast` (C3).
- Produces: `CardExportSnapshot({required String deckName, required List<CardExportRow> rows, Set<String> skipped = const {}})`; `ExportArtifact({…, Set<String> skipped = const {}})`; `CardExportState({…, Set<String> skipped = const {}})`.
- Changes: `Future<Set<String>> showCardExportSheet(BuildContext context, CardExportScope scope)` returns the skipped ids (empty when the file was not handed over); the sheet route's result is `Set<String>?`.
- Produces: `void CardSelection.prune(Set<String> gone)`.
- Rules: a selection id that is gone, in the Trash or in another deck is skipped; the deck itself missing is still `notFound`; every id gone is `TransferRejection.staleSelection`; no row at all stays `emptyScope`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/data/card_transfer_test.dart`: replace the test `'an id that is gone, in the Trash or in another deck fails the whole request (E6)'` (412-430) with:

```dart
    test('an id that is gone, in the Trash or in another deck is skipped; the '
        'rest are read (SP2a 2.19, BR-TRANSFER-007)', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'x', deckId: other.id);

      for (final id in ['missing', 'z', 'x']) {
        final snapshot = _ok(
          await cards.exportSnapshot(deckId: leaf.id, cardIds: {'a', id}),
        );
        expect(snapshot.rows.map((row) => row.front), ['first'], reason: id);
        expect(snapshot.skipped, {id}, reason: id);
      }
      expect(
        _reason(await cards.exportSnapshot(deckId: 'missing')),
        CardRejection.notFound,
      );
    });
```

`test/features/transfer/domain/export_use_cases_test.dart`: replace the last test (138-172) with:

```dart
    test('an empty deck and an empty selection are refused (E5); a selection '
        'with a card gone exports the rest and names it; one with nothing '
        'left is stale (E6, SP2a 2.19)', () async {
      for (final cardIds in <Set<String>?>[null, const {}]) {
        expect(
          _reason(
            await export(
              deckId: leaf.id,
              format: TransferFormat.csv,
              today: _now(),
              cardIds: cardIds,
            ),
          ),
          TransferRejection.emptyScope,
        );
      }
      await insertCard(db, id: 'a', deckId: leaf.id);
      final artifact = _ok(
        await export(
          deckId: leaf.id,
          format: TransferFormat.csv,
          today: _now(),
          cardIds: const {'a', 'gone'},
        ),
      );
      expect(artifact.skipped, {'gone'});
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
            cardIds: const {'gone'},
          ),
        ),
        TransferRejection.staleSelection,
      );
    });
```

`test/features/transfer/presentation/card_export_controller_test.dart`: replace the test `'a selection with a card gone meanwhile exports nothing (E6)'` (198-208) with:

```dart
  test('a selection whose cards are all gone exports nothing (E6)', () async {
    final (:sheet, :state) = open(
      container(),
      CardExportScope.selection(deckId: leaf.id, ids: {'gone'}),
    );

    await sheet.export();

    expect(state().problem, CardExportProblem.staleSelection);
    expect(share.shared, isEmpty);
  });

  test('a card gone meanwhile is skipped; the file holds the rest and the '
      'state names it (SP2a 2.19)', () async {
    final (:sheet, :state) = open(
      container(),
      CardExportScope.selection(deckId: leaf.id, ids: {'a', 'gone'}),
    );

    await sheet.export();

    expect(state().isHandedOver, isTrue);
    expect(state().skipped, {'gone'});
    expect(share.shared, hasLength(1));
  });
```

`test/features/transfer/presentation/card_export_sheet_test.dart`: add (the file's `_seed` creates cards `a` and `b`; add `import 'package:memox/l10n/bulk_message.dart';`):

```dart
  libraryTest('a selection with a card gone says how many were skipped '
      '(SP2a 2.19)', (tester, env) async {
    final (:deckId, :share) = await _seed(
      tester,
      env,
      scope: (deckId) =>
          CardExportScope.selection(deckId: deckId, ids: {'a', 'b', 'gone'}),
    );

    await _tap(tester, _button(_en.exportAction(3)));

    expect(
      find.text(_en.bulkToast(_en.exportHandedOver(2), 1)),
      findsOneWidget,
    );
    expect(share.shared, hasLength(1));
  });
```

`test/features/card/presentation/card_selection_test.dart`: add `import 'package:flutter_riverpod/flutter_riverpod.dart';`, `import 'package:memox/features/card/presentation/states/card_selection_state.dart';` and

```dart
  test('prune drops the ids a bulk action found already gone (SP2a 2.19)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final selection = container.read(cardSelectionProvider('deck').notifier)
      ..selectAll({'a', 'b', 'c'});

    selection.prune({'b', 'unknown'});

    expect(container.read(cardSelectionProvider('deck')), {'a', 'c'});
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/data/card_transfer_test.dart test/features/transfer/domain/export_use_cases_test.dart test/features/transfer/presentation/card_export_controller_test.dart test/features/card/presentation/card_selection_test.dart`
Expected: FAIL to compile (`skipped` on `CardExportSnapshot` / `ExportArtifact` / `CardExportState`, `prune`).

- [ ] **Step 3: Implement**

`card_export_snapshot_model.dart`:

```dart
final class CardExportSnapshot {
  const CardExportSnapshot({
    required this.deckName,
    required this.rows,
    this.skipped = const {},
  });

  final String deckName;
  final List<CardExportRow> rows;

  /// The selected ids that were gone, in the Trash or in another deck when
  /// the snapshot was read (SP2a 2.19); empty for a whole-deck export.
  final Set<String> skipped;
}
```

`card_transfer_repository.dart`, the `exportSnapshot` doc: "…in one read that writes nothing (BR-TRANSFER-010, BR-TRANSFER-011). An id that is gone, in the Trash or in another deck is skipped and named in `skipped` (SP2a 2.19, BR-TRANSFER-007); a missing deck is `notFound`. An empty scope is an empty snapshot; the caller refuses it."

`card_transfer_repository_impl.dart` `exportSnapshot` body:

```dart
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final rows = await _dao.exportRows(deckId, cardIds);
      final skipped = cardIds == null
          ? const <String>{}
          : cardIds.difference({for (final row in rows) row.id});
      final tags = await _listDao.tagsOf([for (final row in rows) row.id]);
      return Ok(
        CardExportSnapshot(
          deckName: deck.name,
          skipped: skipped,
          rows: [ /* the existing CardExportRow list, unchanged */ ],
        ),
      );
```

`export_artifact_model.dart`: `ExportArtifact` gets `this.skipped = const {}` and `/// The selected ids the file leaves out because they were gone (SP2a 2.19). final Set<String> skipped;`.

`build_export_use_case.dart`:

```dart
    if (value.rows.isEmpty) {
      return Rejected(
        value.skipped.isEmpty
            ? TransferRejection.emptyScope
            : TransferRejection.staleSelection,
      );
    }
```
and `ExportArtifact(bytes: bytes, fileName: …, format: format, skipped: value.skipped)`.

`card_export_state.dart` `CardExportState`: add `this.skipped = const {}` and `/// With [isHandedOver]: the selected cards the file left out (SP2a 2.19). final Set<String> skipped;`.

`card_export_controller.dart` line 53-56:

```dart
      Ok(value: ExportShareResult.shared) => CardExportState(
        format: format,
        isHandedOver: true,
        skipped: artifact.skipped,
      ),
```

`card_export_sheet_widget.dart`:

```dart
/// … Completes with the ids the file left out (empty when none), or an empty
/// set when nothing was handed over; the toast says how many were skipped.
Future<Set<String>> showCardExportSheet(
  BuildContext context,
  CardExportScope scope,
) async {
  final skipped = await showMxBottomSheet<Set<String>>(
    context,
    builder: (_) => CardExportSheetWidget(scope: scope),
  );
  if (skipped == null) return const {};
  if (context.mounted) {
    final l10n = context.l10n;
    showMxSnackbar(
      context,
      message: l10n.bulkToast(
        l10n.exportHandedOver(scope.cardCount - skipped.length),
        skipped.length,
      ),
    );
  }
  return skipped;
}
```
`showDeckExportSheet`'s last statement stays `await showCardExportSheet(...)`. Line 88: `if (next.isHandedOver) Navigator.of(context).pop(next.skipped);`. Line 260: `void close() => Navigator.of(context).pop();` (the route type is now `Set<String>`, so `pop(false)` would throw a cast error; every non-handover exit pops with no value). Add `import 'package:memox/l10n/bulk_message.dart';`.

`card_selection_state.dart`:

```dart
  /// Drops ids a bulk action found already gone, so they do not stay
  /// selected (SP2a 2.19).
  void prune(Set<String> gone) {
    if (gone.isEmpty) return;
    state = state.difference(gone);
  }
```

`app_router.dart`: add `import 'package:memox/features/card/presentation/states/card_selection_state.dart';` and replace `onExport` (393-398) with `onExport: (ids) => unawaited(_exportSelection(context, view.deck.id, ids)),` plus, next to `_openTrash`:

```dart
/// Exports the selected cards, then drops the ones the file left out from the
/// selection (SP2a 2.19).
Future<void> _exportSelection(
  BuildContext context,
  String deckId,
  Set<String> ids,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final skipped = await showCardExportSheet(
    context,
    CardExportScope.selection(deckId: deckId, ids: ids),
  );
  container.read(cardSelectionProvider(deckId).notifier).prune(skipped);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer test/features/card/data/card_transfer_test.dart test/features/card/data/card_batch_limit_test.dart test/features/card/presentation/card_selection_test.dart test/features/card/presentation/card_bulk_actions_test.dart`
Expected: PASS.

- [ ] **Step 5: Docs (Vietnamese)**

`BR-TRANSFER-007-…md`: in `## Rule` replace `Một id không còn tồn tại, hoặc không còn thuộc chính deck đó tại thời điểm đọc snapshot, MUST làm **cả request** thất bại bằng lý do có kiểu — MUST NOT export một phần im lặng.` with `Một id không còn tồn tại, hoặc không còn thuộc chính deck đó tại thời điểm đọc snapshot, MUST bị bỏ qua trong cùng lần đọc: file chỉ gồm các card còn lại, và kết quả MUST nêu các id đã bỏ qua để UI báo số lượng và dọn selection — MUST NOT bỏ qua im lặng. Khi mọi id đều không còn, request thất bại bằng lý do có kiểu.` In the edge-case table replace the row `| Một card trong tập chọn bị xoá hoặc chuyển deck trước lúc đọc | Cả request thất bại có kiểu; không sinh file một phần (BR-TRANSFER-007) |` with `| Một card trong tập chọn bị xoá hoặc chuyển deck trước lúc đọc | Card đó bị bỏ qua và được nêu tên; file gồm các card còn lại; mọi card đều không còn thì thất bại có kiểu (BR-TRANSFER-007) |`. Update the front-matter `summary` only if it mentions the whole-request failure (it does not).

`UC-TRANSFER-002-…md`: replace the E6 bullet with `- **E6 — Id đã chọn không còn hợp lệ:** một id trong tập chọn đã bị xoá hoặc đã chuyển sang deck khác → id đó bị bỏ qua, file gồm các card còn lại và thông báo nêu số card đã bỏ qua (BR-TRANSFER-007); không còn card nào thì thất bại có kiểu, không sinh file; thông báo mời người dùng chọn lại.` and the acceptance criterion at line 99 with `- [ ] **Given** một tập chọn có một id đã bị xoá hoặc đã chuyển deck, **when** export, **then** file gồm các card còn lại, thông báo nêu số card đã bỏ qua và selection được dọn id đó; mọi id đều không còn thì không có file (BR-TRANSFER-007, E6).`

Run `python tools/docs/generate.py` and `python tools/docs/check.py` (exit 0).

- [ ] **Step 6: Commit**

```bash
git add lib/features/card lib/features/transfer lib/app/router/app_router.dart test/features docs/features/transfer docs/_generated
git commit -m "fix(transfer): export skips selected cards that are gone and prunes the selection (SP2a 2.19)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 26 (C5): Bulk Trash confirm names the count; the toast for several carries Undo

Finding 2.20. The confirm button reads "Move to Trash" whatever the count (`card_delete_dialog_widget.dart:112`), and the toast for several cards offers "Open Trash" instead of Undo (`card_trashed_snackbar_widget.dart:42-47`, FE-B1 D4), so a slip on 799 cards has no quick way back.

How the Trash restores: `CardRepository.restoreCards(batchIds, deckId)` (called from `trash_controller.dart:47`) moves a set of batches into a chosen deck and stamps `updated_at` like a move. An Undo is not a move (trash spec D9: the card keeps its own `updated_at` and its own deck), so this task reuses the same `_restoreInto` check-and-write, split into a refusal check and a write, and applies it per deck for all the batches a delete wrote. Each card keeps a batch of its own (BR-TRASH-001), so "the whole batch" of the spec is the whole set of batches of that one delete (see DECISION below).

**Files:**
- Modify: `lib/features/card/domain/repositories/card_repository.dart` (`undoCardDeletion` 54-59)
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart` (`undoCardDeletion` 140-153; `_restoreInto` 394-433)
- Modify: `lib/features/card/domain/usecases/undo_card_deletion_use_case.dart` (7-13)
- Modify: `lib/features/card/presentation/controllers/card_actions_controller.dart` (`undoCardDeletion` 65-67)
- Modify: `lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart` (14-74)
- Modify: `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart` (112; class doc 41-42)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify (docs): `docs/features/trash/rules/BR-TRASH-008-undo-mot-batch-vua-tao.md`, `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md` (36-37, 94), `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md` (48-49), `docs/features/card/it-scenarios.md` (IT-ORG-014 step 3)
- Test: `test/features/card/data/card_restore_test.dart`, `test/features/card/domain/card_write_use_cases_test.dart`, `test/features/card/presentation/card_bulk_actions_test.dart`
- Goldens: none (`card_list_trash_dialog_*` and `card_editor_trash_dialog_*` show one card, whose label stays "Move to Trash"; `card_list_trashed_*` is the one-card toast).

**Interfaces:**
- Consumes: `BulkOutcome.batchIds` (C1); `bulkToast` (C3).
- Changes: `Future<Outcome<void, CardRejection>> CardRepository.undoCardDeletion({required Set<String> batchIds, DateTime? now})` (was `String batchId`); the same for `UndoCardDeletionUseCase.call({required Set<String> batchIds})` and `CardActionsController.undoCardDeletion({required Set<String> batchIds})`. All or none in one transaction; a missing batch is `notFound`; each card goes back to its own deck with its own `updated_at`; the first deck that refuses (`targetInTrash`, `targetNotFound`, `targetHoldsDecks`, …) refuses all.
- Changes: `showCardsTrashedSnackbar` always carries Undo (one card or several); `onOpenTrash` now rides only on the refused-Undo toast.
- New ARB key `cardMoveToTrashCount(int count)`.
- **DECISION:** BR-TRASH-008 says "Undo MUST NOT be available for a multi-item delete" and UC-CARD-001 line 94 says "no Undo" for several cards; spec 2.20 (approved) reverses both. This task amends BR-TRASH-008 and the UC lines (Step 5). The toast holds one action, so the success toast of several cards trades "Open Trash" for Undo. Recommended: both as specified. A single shared `delete_batches` row for the whole delete would break BR-TRASH-001 (each card restorable alone from the Trash screen), so each card keeps its batch and Undo takes all of them.

- [ ] **Step 1: Write the failing tests**

`test/features/card/data/card_restore_test.dart`: first the mechanical change at the existing calls (lines 221, 243, 247, 251, 265, 271): `undoCardDeletion(batchId: x)` becomes `undoCardDeletion(batchIds: {x})` (`'missing'` becomes `{'missing'}`). Then append inside `group('undoCardDeletion (BR-TRASH-008)'`:

```dart
    test('several cards go back at once, each into its own deck with its '
        'updated_at kept (SP2a 2.20)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: lesson.id);
      await insertCard(db, id: 'c3', deckId: other.id);
      final updatedAt = (await placeOf('c1')).$3;
      final batchIds = await delete({'c1', 'c2', 'c3'});

      expect(
        await cards.undoCardDeletion(batchIds: batchIds.toSet()),
        isA<Ok<void, CardRejection>>(),
      );

      expect(await placeOf('c1'), (lesson.id, null, updatedAt));
      expect(await placeOf('c2'), (lesson.id, null, updatedAt));
      expect(await placeOf('c3'), (other.id, null, updatedAt));
      expect(
        (await db
                .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
                .getSingle())
            .read<int>('n'),
        0,
      );
      expect(await contentTypeOf(lesson.id), DeckContentType.card);
    });

    test('one card whose deck no longer takes it refuses all of them, '
        'writing nothing (SP2a 2.20)', () async {
      final root = await decks.root('Korean');
      final gone = await decks.sub(root.id, 'Gone');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: gone.id);
      final batchIds = await delete({'c1', 'c2'});
      await deleteDeck(gone.id);
      final before = await totalChanges(db);

      expect(
        await cards.undoCardDeletion(batchIds: batchIds.toSet()),
        _refused(CardRejection.targetInTrash),
      );
      expect(await totalChanges(db), before);
      expect((await placeOf('c1')).$2, isNotNull);
    });
```

`test/features/card/domain/card_write_use_cases_test.dart` line 141: `await UndoCardDeletionUseCase(cards)(batchId: batchId)` becomes `await UndoCardDeletionUseCase(cards)(batchIds: {batchId})`.

`test/features/card/presentation/card_bulk_actions_test.dart`: replace the test `'Trash asks with the count; Cancel keeps the selection; several cards get no Undo (FE-B1 D4)'` (217-241) with the two tests below, and in the C3 test `'Trash skips a card that went meanwhile…'` change the confirm finder to `_inDialog(_en.cardMoveToTrashCount(2))` (its dialog holds both selected ids):

```dart
  libraryTest('Trash asks with the count on its button; Cancel keeps the '
      'selection; Undo of several puts them all back (SP2a 2.20)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardDelete);

    expect(find.text(_en.cardDeleteTitle(2)), findsOneWidget);
    expect(find.text(_en.cardDeleteNote(2)), findsOneWidget);
    expect(_inDialog(_en.cardMoveToTrashCount(2)), findsOneWidget);
    await tester.tap(_inDialog(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsNWidgets(2),
    );

    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();
    expect(await _activeCount(env), 2);
    expect(find.text(_en.cardsTrashedToast(2)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();
    expect(await _activeCount(env), 4);
    expect(find.text('annyeong'), findsOneWidget);
    expect(find.text('gamsa'), findsOneWidget);
  });

  libraryTest('a refused Undo of several leaves them all in the Trash '
      '(UC-TRASH-001 E3, SP2a 2.20)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();
    await env.decks.deleteDeck(deckId: ids.words);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.cardUndoRefused(_en.cardRejectionTargetInTrash)),
      findsOneWidget,
    );
    expect(
      await _count(
        env,
        "SELECT COUNT(*) AS n FROM card WHERE id IN ('new1', 'due1') "
        'AND delete_batch_id IS NULL',
      ),
      0,
    );
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/data/card_restore_test.dart test/features/card/presentation/card_bulk_actions_test.dart`
Expected: FAIL to compile (`batchIds:` is not a parameter; `cardMoveToTrashCount` undefined).

- [ ] **Step 3: Implement**

`card_repository.dart`:

```dart
  /// BR-TRASH-008: the cards of [batchIds], the batches one delete wrote, go
  /// back each into its own deck with its `updated_at` kept; all or none. It
  /// is refused, typed, when any of those decks no longer takes its card, and
  /// `notFound` when a batch is gone (SP2a 2.20).
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required Set<String> batchIds,
    DateTime? now,
  });
```

`card_repository_impl.dart`: replace `undoCardDeletion` and split `_restoreInto`:

```dart
  @override
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required Set<String> batchIds,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (batchIds.isEmpty) return const Ok(null);
      // Back into its own deck with its own updated_at: an Undo is not a
      // move (trash spec D9). Grouped by deck so each target is checked once
      // and a refusal leaves every card where it is.
      final byDeck = <String, Map<String, CardRow>>{};
      for (final batchId in batchIds) {
        final card = await _dao.itemOf(batchId);
        if (card == null) return const Rejected(CardRejection.notFound);
        (byDeck[card.deckId] ??= {})[batchId] = card;
      }
      for (final MapEntry(key: deckId, value: cards) in byDeck.entries) {
        if (await _restoreRefusal(deckId, cards) case final reason?) {
          return Rejected(reason);
        }
      }
      for (final MapEntry(key: deckId, value: cards) in byDeck.entries) {
        await _writeRestore(deckId, cards, at: at);
      }
      return const Ok(null);
    });
  }
```

```dart
  /// [cards], by batch, come back into [deckId] when it takes them
  /// (BR-TRASH-006, BR-TRASH-007); [updatedAt] stamps them as a move does.
  /// An unset deck becomes a deck of cards (BR-DECK-008).
  Future<Outcome<void, CardRejection>> _restoreInto(
    String deckId,
    Map<String, CardRow> cards, {
    DateTime? updatedAt,
    required DateTime at,
  }) async {
    if (await _restoreRefusal(deckId, cards) case final reason?) {
      return Rejected(reason);
    }
    await _writeRestore(deckId, cards, updatedAt: updatedAt, at: at);
    return const Ok(null);
  }

  /// Why [cards] cannot go back into [deckId], or null when it takes them
  /// (BR-TRASH-006). Reads only.
  Future<CardRejection?> _restoreRefusal(
    String deckId,
    Map<String, CardRow> cards,
  ) async {
    final target = await _dao.deckRow(deckId);
    if (target == null) {
      return await _dao.isDeckInTrash(deckId)
          ? CardRejection.targetInTrash
          : CardRejection.targetNotFound;
    }
    final rule = CardEntity.checkTarget(
      targetRootId: target.rootId,
      targetIsRoot: target.parentId == null,
      targetContentType: DeckContentType.values.byName(target.contentType),
      sourceRootIds: await _dao.rootIdsOf({
        for (final card in cards.values) card.deckId,
      }),
    );
    if (rule case Rejected(:final reason)) return reason;
    return null;
  }

  /// The writes of a restore that [_restoreRefusal] accepted.
  Future<void> _writeRestore(
    String deckId,
    Map<String, CardRow> cards, {
    DateTime? updatedAt,
    required DateTime at,
  }) async {
    for (final MapEntry(key: batchId, value: card) in cards.entries) {
      await _dao.restoreFromBatch(
        batchId,
        card.id,
        deckId: deckId,
        updatedAt: updatedAt,
      );
    }
    final target = (await _dao.deckRow(deckId))!;
    if (target.contentType == DeckContentType.unset.name) {
      await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
    }
  }
```

`undo_card_deletion_use_case.dart`:

```dart
/// BR-TRASH-008: the cards deleted a moment ago go back into their decks, or
/// the reason they cannot.
final class UndoCardDeletionUseCase {
  const UndoCardDeletionUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required Set<String> batchIds}) =>
      _cards.undoCardDeletion(batchIds: batchIds);
}
```

`card_actions_controller.dart`:

```dart
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required Set<String> batchIds,
  }) => ref.read(undoCardDeletionUseCaseProvider)(batchIds: batchIds);
```

`card_trashed_snackbar_widget.dart`: replace the function and `_undo` (keep the imports, plus `bulk_message.dart` from C3):

```dart
/// Says cards went to the Trash (FE-B1 D3, D4). One card, named by its
/// [front] when the caller has it, or several: Undo for 8 seconds puts them
/// all back (BR-TRASH-008, SP2a 2.20). [skipped] is how many of the selected
/// cards were already gone (SP2a 2.19). [onOpenTrash] rides on a refused
/// Undo's toast.
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showCardsTrashedSnackbar(
  BuildContext context, {
  required List<String> batchIds,
  String? front,
  VoidCallback? onOpenTrash,
  int skipped = 0,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = context.l10n;
  final container = ProviderScope.containerOf(context, listen: false);
  final message = switch (batchIds) {
    [_] when front != null => l10n.cardTrashedToast(front),
    _ => l10n.bulkToast(l10n.cardsTrashedToast(batchIds.length), skipped),
  };
  showMxSnackbar(
    host,
    message: message,
    actionLabel: l10n.commonUndo,
    duration: AppDurations.undoWindow,
    onAction: () =>
        unawaited(_undo(host, container, batchIds.toSet(), onOpenTrash)),
  );
}

/// The cards go back into their decks; a refusal says why and leaves them in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  Set<String> batchIds,
  VoidCallback? onOpenTrash,
) async {
  try {
    final outcome = await container
        .read(cardActionsControllerProvider.notifier)
        .undoCardDeletion(batchIds: batchIds);
    if (outcome case Rejected(:final reason) when host.mounted) {
      final l10n = host.l10n;
      showMxSnackbar(
        host,
        message: l10n.cardUndoRefused(l10n.cardRejection(reason)),
        actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
        onAction: onOpenTrash,
      );
    }
  } on Failure catch (failure) {
    if (host.mounted) showMxSnackbar(host, message: host.l10n.failure(failure));
  }
}
```

`card_delete_dialog_widget.dart`: line 112 `confirmLabel: l10n.cardMoveToTrashCount(count),` and the class doc becomes "The confirm names how many cards move; it is not destructive, since the Trash keeps the cards for 30 days, and it spins while they move (FE-B1 D15, SP2a 2.20)."

ARB. EN (after `cardMoveToTrash`):

```json
  "cardMoveToTrashCount": "{count, plural, =1{Move to Trash} other{Move {count} cards to Trash}}",
  "@cardMoveToTrashCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "The Move to Trash dialog's confirm when it names how many cards move (SP2a 2.20); one card keeps the short form."
  },
```

VI (after `cardMoveToTrash`): `"cardMoveToTrashCount": "{count, plural, =1{Chuyển vào Thùng rác} other{Chuyển {count} thẻ vào Thùng rác}}",`

Run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/features/trash`
Expected: PASS (the Trash screen and its restore tests exercise `restoreCards`, which still goes through the refactored `_restoreInto`).

- [ ] **Step 5: Docs (Vietnamese)**

`BR-TRASH-008-…md`: front-matter `summary: Undo đảo ngược mọi batch mà một thao tác xoá vừa tạo về đúng vị trí cũ, không hỏi target, all-or-nothing.` and the `## Rule` paragraph becomes:

```
Undo là thao tác đảo ngược **mọi batch** mà một thao tác xoá vừa tạo — một batch cho xoá một item, một batch cho mỗi card khi xoá nhiều card từ card list (BR-TRASH-001) — và MUST đưa mọi hàng của chúng về đúng vị trí cũ, không hỏi target, all-or-nothing trong một transaction. Undo MUST áp dụng lại đầy đủ các điều kiện của BR-TRASH-006 lên vị trí cũ của từng batch và MUST bị từ chối bằng lý do có kiểu khi vị trí cũ của bất kỳ batch nào không còn hợp lệ — MUST NOT im lặng đặt vào chỗ khác và MUST NOT khôi phục một phần. Cửa sổ Undo là snackbar 8 giây; sau đó khôi phục qua màn Trash (BR-TRASH-006).
```

`UC-CARD-001-…md`: line 36-37 `Xoá **một** card thì có Undo ngay tại chỗ (BR-TRASH-008)` becomes `Xoá một hay nhiều card đều có Undo ngay tại chỗ, đảo ngược mọi batch vừa tạo (BR-TRASH-008)`; line 94 becomes `- [ ] **Given** người dùng xoá nhiều card, **when** xác nhận (nút xác nhận nêu số card), **then** tất cả vào Trash cùng lúc, mỗi card một batch, và snackbar có Undo đưa cả nhóm về đúng deck cũ (BR-TRASH-001, BR-TRASH-008, A2).` `UC-TRASH-001-…md` A1: append `Với xoá nhiều card, Undo đảo ngược mọi batch của thao tác đó hoặc không batch nào.` `it-scenarios.md` IT-ORG-014 step 3: `thông báo nêu số lượng` becomes `thông báo nêu số lượng và có Undo`.

Run `python tools/docs/generate.py` and `python tools/docs/check.py` (exit 0).

- [ ] **Step 6: Commit**

```bash
git add lib/features/card lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/card docs/features docs/_generated
git commit -m "feat(card): bulk Trash confirm names the count and its toast carries Undo (SP2a 2.20)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 27 (C6): Import `readSource` and `previewRows` catch every exception

Finding 2.22. `previewRows` awaits `previewImportUseCaseProvider` with no `try` (`card_import_controller.dart:136-156`), so a database failure (`foldedPairs` throws a `Failure`) escapes the unawaited call in the screen, leaves `isBusy` set and the wizard frozen on a spinning button. `readSource` (`:114-135`) has the same shape for a codec or isolate failure. `chooseFile` and `commit` already catch.

**Files:**
- Modify: `lib/features/transfer/domain/failures/transfer_failure.dart` (add a reason)
- Modify: `lib/features/transfer/presentation/controllers/card_import_controller.dart` (`readSource` 105-128; `previewRows` 143-167)
- Modify: `lib/features/transfer/presentation/widgets/support/import_labels_widget.dart` (`importProblem` 51-67)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart` (banner, before 81)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/transfer/presentation/card_import_controller_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart`
- Goldens: none.

**Interfaces:**
- Produces: `TransferRejection.previewFailed` (the deck's cards could not be read to mark duplicates); a `readSource` that throws sets `TransferRejection.unreadableFile`.
- New ARB keys `importProblemPreviewTitle`, `importProblemPreviewBody`.
- `previewRows` and `readSource` always end with `isBusy == false`. The wizard shows the preview failure as a danger `MxInlineBanner` in step 2; "Preview rows" is live again and is the retry; changing the mapping clears the problem (existing `assignColumn` behaviour).

- [ ] **Step 1: Write the failing tests**

`card_import_controller_test.dart`: add imports `package:memox/features/card/domain/models/card_folded_pair_model.dart`, `package:memox/features/transfer/domain/models/source_table_model.dart`, `package:memox/features/transfer/domain/models/transfer_source_model.dart`, `package:memox/features/transfer/domain/repositories/transfer_file_repository.dart`, `package:memox/features/transfer/domain/usecases/preview_import_use_case.dart`, `package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart`, `package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart`, `package:memox/features/transfer/presentation/providers/read_import_source_use_case_provider.dart`. Add the fakes after `_BrokenImport`:

```dart
/// Throws on the duplicate read, the way a locked database does.
final class _BrokenDeckRead implements CardTransferRepository {
  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async =>
      throw const UnknownDatabaseFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws on the read, as a codec or an isolate that died does.
final class _ExplodingFiles implements TransferFileRepository {
  @override
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  }) async => throw StateError('codec exploded');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

and two tests before the final `Import another file` test:

```dart
  test('a preview whose deck read throws sets a typed problem and frees the '
      'wizard (SP2a 2.22)', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(() async => picked),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(_BrokenDeckRead()),
        ),
      ],
    );
    addTearDown(c.dispose);
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    await wizard.previewRows();

    expect(draftOf(c).step, CardImportStep.columns);
    expect(draftOf(c).problem, TransferRejection.previewFailed);
    expect(draftOf(c).isBusy, isFalse);
  });

  test('a read that throws is unreadable, not a stuck spinner (SP2a 2.22)', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(() async => picked),
        readImportSourceUseCaseProvider.overrideWithValue(
          ReadImportSourceUseCase(_ExplodingFiles()),
        ),
      ],
    );
    addTearDown(c.dispose);
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();

    await wizard.readSource();

    expect(draftOf(c).step, CardImportStep.source);
    expect(draftOf(c).problem, TransferRejection.unreadableFile);
    expect(draftOf(c).isBusy, isFalse);
  });
```

`card_import_screen_test.dart`: add imports `package:memox/core/error/failure.dart`, `package:memox/features/card/data/repositories/card_repository_impl.dart`, `package:memox/features/card/data/repositories/card_transfer_repository_impl.dart`, `package:memox/features/card/domain/models/card_folded_pair_model.dart`, `package:memox/features/card/domain/repositories/card_transfer_repository.dart`, `package:memox/features/srs/data/repositories/schedule_repository_impl.dart`, `package:memox/features/tags/data/repositories/tag_repository_impl.dart`, `package:memox/features/transfer/domain/usecases/preview_import_use_case.dart`, `package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart`; add the fake and the test:

```dart
/// Throws on the duplicate read until [isBroken] turns false.
final class _FlakyDeckRead implements CardTransferRepository {
  _FlakyDeckRead(this._inner);

  final CardTransferRepository _inner;
  var isBroken = true;

  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async {
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'locked');
    return _inner.foldedPairs(deckId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

```dart
  libraryTest('a preview that cannot read the deck says so and Preview rows '
      'tries again (SP2a 2.22)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    final flaky = _FlakyDeckRead(
      CardTransferRepositoryImpl(
        env.db,
        CardRepositoryImpl(
          env.db,
          ScheduleRepositoryImpl(env.db),
          TagRepositoryImpl(env.db),
        ),
      ),
    );
    await pumpLibraryScreen(
      tester,
      env,
      CardImportScreen(
        deckId: deck.id,
        deckContext: _context,
        onClose: () {},
        onViewCards: () {},
      ),
      overrides: [
        importFilePickerProvider.overrideWithValue(
          () async => _file('front,back\nmul,water\n'),
        ),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(flaky),
        ),
      ],
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);

    expect(find.text(_en.importProblemPreviewTitle), findsOneWidget);
    final preview = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.importPreviewAction),
    );
    expect(preview.isLoading, isFalse);
    expect(preview.onPressed, isNotNull);

    flaky.isBroken = false;
    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importBadgeReady(1)), findsOneWidget);
    expect(find.text(_en.importProblemPreviewTitle), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/presentation/card_import_controller_test.dart test/features/transfer/presentation/card_import_screen_test.dart`
Expected: FAIL (compile: `TransferRejection.previewFailed`, `importProblemPreviewTitle` undefined).

- [ ] **Step 3: Implement**

`transfer_failure.dart`, after `nothingToImport`:

```dart
  /// UC-TRANSFER-001 step 5 (SP2a 2.22): the deck's cards could not be read
  /// to mark the duplicates. Nothing was written; Preview rows can be tried
  /// again.
  previewFailed,
```

`card_import_controller.dart`. In `readSource` replace the `final result = await …;` statement with:

```dart
    final Outcome<SourceTable, TransferRejection> result;
    try {
      result = await ref.read(readImportSourceUseCaseProvider)(
        source,
        sheetIndex: sheetIndex,
      );
    } on Object {
      // Whatever the codec or the isolate threw, the person sees one typed
      // reason and nothing of the file (BR-TRANSFER-006, SP2a 2.22).
      if (!ref.mounted) return;
      state = draft.copyWith(
        isBusy: false,
        problem: TransferRejection.unreadableFile,
      );
      return;
    }
```
and in `previewRows`:

```dart
    final Outcome<ImportPreview, TransferRejection> result;
    try {
      result = await ref.read(previewImportUseCaseProvider)(
        deckId: deckId,
        table: table,
        mapping: draft.mapping,
        hasHeaderRow: draft.hasHeaderRow,
      );
    } on Object {
      // The deck could not be read: the step stays, and so does its work
      // (SP2a 2.22).
      if (!ref.mounted) return;
      state = draft.copyWith(
        isBusy: false,
        problem: TransferRejection.previewFailed,
      );
      return;
    }
```
(the `if (!ref.mounted) return; state = switch (result) {…}` lines after each stay as they are). Add imports `import_preview_model.dart` and `source_table_model.dart`.

`import_labels_widget.dart` `importProblem`, add before the default `_`:

```dart
        TransferRejection.previewFailed => (
          title: importProblemPreviewTitle,
          body: importProblemPreviewBody,
        ),
```

`import_mapping_section_widget.dart`: add imports `package:memox/features/transfer/domain/failures/transfer_failure.dart` and `package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart`; before the `if (!draft.mapping.isComplete) ...[` block insert:

```dart
        // The deck could not be read for the preview: nothing was lost, and
        // Preview rows is live again (SP2a 2.22).
        if (draft.problem == TransferRejection.previewFailed) ...[
          MxInlineBanner(
            tone: MxBannerTone.danger,
            title: l10n.importProblem(TransferRejection.previewFailed).title,
            message: l10n.importProblem(TransferRejection.previewFailed).body,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
```

ARB. EN (after `importProblemEmptyBody`):

```json
  "importProblemPreviewTitle": "Couldn't check this deck",
  "@importProblemPreviewTitle": {
    "description": "Import step 2: the deck's cards could not be read for the preview (SP2a 2.22)."
  },
  "importProblemPreviewBody": "Nothing was imported and your mapping is kept. Choose Preview rows to try again.",
  "@importProblemPreviewBody": {
    "description": "Import step 2: what to do after a failed preview."
  },
```

VI (after `importProblemEmptyBody`):

```json
  "importProblemPreviewTitle": "Không kiểm tra được bộ thẻ này",
  "importProblemPreviewBody": "Chưa nhập gì và cách ghép cột vẫn được giữ. Hãy chọn Xem trước các dòng để thử lại.",
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues (any exhaustive `switch` over `TransferRejection` must name the new value; the known switches use `_`).
Run: `flutter test test/features/transfer/presentation/card_import_controller_test.dart test/features/transfer/presentation/card_import_screen_test.dart test/features/transfer/domain`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/transfer
git commit -m "fix(transfer): import read and preview catch every exception and free the wizard (SP2a 2.22)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 28 (C7): Too-large source rejected up front; skipped rows open in a lazy sheet

**Also pin (Review Focus):** the limits are inclusive — exactly 20,000 rows and exactly 5 MB are accepted; 20,001 rows or 5 MB + 1 byte are refused — add both boundary tests.

Finding 2.23. Nothing caps an import: `TransferFileRepositoryImpl._read` decodes whatever it is given, and `import_result_widget.dart` expands every skipped row into an eager `Column` (`_SkippedRows`, 115-157 today), so a 20,000-row file with 19,999 skips builds 19,999 widgets.

**Files:**
- Create: `lib/features/transfer/domain/models/transfer_limits_model.dart`
- Create: `lib/features/transfer/presentation/widgets/overlays/import_skipped_sheet_widget.dart`
- Modify: `lib/features/transfer/domain/failures/transfer_failure.dart` (add a reason)
- Modify: `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart` (`_read` 51-66)
- Modify: `lib/features/transfer/presentation/widgets/support/import_labels_widget.dart` (`importProblem`)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart` (`_SkippedRows` 115-157; imports)
- Modify: `lib/shared/widgets/mx_bottom_sheet.dart` (constructor 33-45; body line 125)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify (docs): `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Test: `test/features/transfer/data/transfer_file_repository_impl_test.dart`, `test/features/transfer/presentation/card_import_controller_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart`, `test/features/transfer/presentation/import_result_skipped_test.dart`, `test/shared/widgets/mx_bottom_sheet_test.dart`, `test/features/transfer/presentation/card_import_golden_test.dart`
- Goldens: new `import_too_large_light.png` / `import_too_large_dark.png` (Linux container only).

**Interfaces:**
- Produces: `abstract final class TransferLimits { static const int maxMegabytes = 5; static const int maxBytes = maxMegabytes * 1024 * 1024; static const int maxRows = 20000; }`; `TransferRejection.tooLarge`.
- Produces: `const MxBottomSheet.builder({Key? key, required int itemCount, required IndexedWidgetBuilder itemBuilder, Widget? header, Widget? footer, bool hasGrabber = true, bool isHeld = false})`; the body is a `ListView.builder`, so rows are built only in view. `MxBottomSheet.child` becomes `Widget?` (null only for the builder form).
- Produces: `Future<void> showImportSkippedSheet(BuildContext context, {required List<ImportRow> rows})` and `ImportSkippedSheetWidget`.
- New ARB keys `importProblemTooLargeTitle`, `importProblemTooLargeBody(int rows, int megabytes)`.
- Behaviour: a file (or pasted text) over 5 MB is refused before decoding; a parsed table over 20,000 rows (header included) is refused; both as `Rejected(TransferRejection.tooLarge)` from `TransferFileRepository.read`, shown by the existing step-1 problem banner. The result's skipped list shows five rows inline and "Show all {n}" opens the sheet.
- **DECISION:** `MxBottomSheet` has no lazy body (it wraps `child` in a `SingleChildScrollView`, so a `ListView.builder` inside would be laid out whole). The spec asks for a lazy list in an `MxBottomSheet`, so this task adds a `.builder` constructor to the shared widget. CLAUDE.md asks the owner to rule on additions to `lib/shared`. Recommended: approve; the alternative (a full-screen route) departs from the spec.
- **DECISION:** the 5 MB check runs on bytes already in memory (`file.readAsBytes()` in `import_file_picker_provider.dart` runs first), as the spec places it in `TransferFileRepository`. A file of hundreds of MB is still read before it is refused. Recommended: accept (the picker offers local spreadsheets); if it matters, check `PlatformFile.size` in the picker later.

- [ ] **Step 1: Write the failing tests**

`transfer_file_repository_impl_test.dart` (add import `package:memox/features/transfer/domain/models/transfer_limits_model.dart`), append before the final `}` of `main`:

```dart
  group('size caps (SP2a 2.23)', () {
    test('a file over 5 MB is refused before it is decoded', () async {
      // Not UTF-8: decoding would answer badEncoding, so the cap came first.
      final bytes = Uint8List(TransferLimits.maxBytes + 1)
        ..fillRange(0, 4, 0xFF);

      expect(
        await _refusal(FileSource(bytes: bytes, format: TransferFormat.csv)),
        TransferRejection.tooLarge,
      );
      expect(
        await _refusal(FileSource(bytes: bytes, format: TransferFormat.xlsx)),
        TransferRejection.tooLarge,
      );
    });

    test('a table over 20,000 rows is refused; 20,000 rows are read', () async {
      String rows(int count) => List.filled(count, 'a,b').join('\n');

      expect(
        await _refusal(PastedSource(rows(TransferLimits.maxRows + 1))),
        TransferRejection.tooLarge,
      );
      expect(
        (await _table(PastedSource(rows(TransferLimits.maxRows)))).rows,
        hasLength(TransferLimits.maxRows),
      );
    });
  });
```

`card_import_controller_test.dart` (add the same `transfer_limits_model.dart` import):

```dart
  test('a source over the cap is refused at step 1 with its own reason '
      '(SP2a 2.23)', () async {
    picked = (name: 'big.csv', bytes: Uint8List(TransferLimits.maxBytes + 1));
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();

    await wizard.readSource();

    expect(draftOf(c).step, CardImportStep.source);
    expect(draftOf(c).problem, TransferRejection.tooLarge);
    expect(draftOf(c).isBusy, isFalse);
  });
```

`card_import_screen_test.dart` (add the `transfer_limits_model.dart` import):

```dart
  libraryTest('a file over the cap says how to split it (SP2a 2.23)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: (name: 'big.csv', bytes: Uint8List(TransferLimits.maxBytes + 1)),
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importProblemTooLargeTitle), findsOneWidget);
    expect(
      find.text(
        _en.importProblemTooLargeBody(
          TransferLimits.maxRows,
          TransferLimits.maxMegabytes,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.importChooseAnother), findsOneWidget);
  });
```

`mx_bottom_sheet_test.dart`:

```dart
  testWidgets('a builder sheet builds only the rows in view (SP2a 2.23)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBottomSheet.builder(
        itemCount: 5000,
        itemBuilder: (_, index) => SizedBox(
          key: ValueKey('row-$index'),
          height: 48,
          width: double.infinity,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('row-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('row-4999')), findsNothing);
    expect(tester.takeException(), isNull);
  });
```

`import_result_skipped_test.dart`: add import `package:memox/features/transfer/presentation/widgets/overlays/import_skipped_sheet_widget.dart`. In the first test replace everything after `await tester.tap(showAll); await tester.pumpAndSettle();` with:

```dart
    // The inline list keeps its five; the sheet holds all seven.
    expect(find.byType(ImportSkippedSheetWidget), findsOneWidget);
    expect(find.byType(ImportPreviewRowWidget), findsNWidgets(12));
    expect(find.text('dup 7'), findsOneWidget);
```

and add:

```dart
  libraryTest('Show all builds the sheet lazily, not every skipped row '
      '(SP2a 2.23)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        ImportSummary(
          written: 1,
          blank: 0,
          skipped: [for (var row = 2; row <= 3001; row++) _invalid(row)],
        ),
      ),
    );

    final showAll = find.text(_en.importSkippedShowAll(3000));
    await tester.ensureVisible(showAll);
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(find.byType(ImportSkippedSheetWidget), findsOneWidget);
    expect(
      tester.widgetList(find.byType(ImportPreviewRowWidget)).length,
      lessThan(40),
    );
    expect(find.text('term 3001'), findsNothing);
  });
```

`card_import_golden_test.dart` (add the `transfer_limits_model.dart` import), inside the `for` loop add:

```dart
    libraryTest('import too large, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List(TransferLimits.maxBytes + 1),
              ),
            ),
          ],
        );
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await expectBoundaryGolden(
          tester,
          'goldens/import_too_large_$theme.png',
        );
      });
    });
```
(Goldens run only in the Linux container; on Windows this file is excluded by its `golden` tag.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/data/transfer_file_repository_impl_test.dart test/shared/widgets/mx_bottom_sheet_test.dart test/features/transfer/presentation/import_result_skipped_test.dart`
Expected: FAIL to compile (`transfer_limits_model.dart`, `MxBottomSheet.builder`, `ImportSkippedSheetWidget` do not exist).

- [ ] **Step 3: Implement**

`lib/features/transfer/domain/models/transfer_limits_model.dart`:

```dart
/// The largest source an import reads (SP2a 2.23): the commit is one
/// transaction on the UI isolate and the preview is built in memory, so a
/// source past these is split into files instead.
abstract final class TransferLimits {
  static const int maxMegabytes = 5;
  static const int maxBytes = maxMegabytes * 1024 * 1024;

  /// Rows of the parsed table, a header row included.
  static const int maxRows = 20000;
}
```

`transfer_failure.dart`, after `emptySource`:

```dart
  /// SP2a 2.23: the source is over the size or the row cap
  /// (`TransferLimits`); nothing was read.
  tooLarge,
```

`transfer_file_repository_impl.dart`: add `import 'package:memox/features/transfer/domain/models/transfer_limits_model.dart';` and replace `_read`:

```dart
Outcome<SourceTable, TransferRejection> _read((TransferSource, int?) request) {
  final (source, sheetIndex) = request;
  // Before any decoding: an XLSX unzips to far more than its size.
  if (_size(source) > TransferLimits.maxBytes) {
    return const Rejected(TransferRejection.tooLarge);
  }
  final table = switch (source) {
    PastedSource(:final text) => _pasted(text),
    FileSource(:final bytes, format: TransferFormat.xlsx) => _workbook(
      bytes,
      sheetIndex,
    ),
    FileSource(:final bytes, :final format) => _delimitedFile(bytes, format),
  };
  if (table case Ok(:final value)) {
    if (value.rows.length > TransferLimits.maxRows) {
      return const Rejected(TransferRejection.tooLarge);
    }
    if (value.isBlank) return const Rejected(TransferRejection.emptySource);
  }
  return table;
}

// ponytail: pasted text counts UTF-16 units, which is at most its UTF-8
// bytes, so a non-ASCII paste may pass a little over 5 MB; encode it first
// if that ever matters.
int _size(TransferSource source) => switch (source) {
  FileSource(:final bytes) => bytes.lengthInBytes,
  PastedSource(:final text) => text.length,
};
```

`import_labels_widget.dart` `importProblem` (add import `transfer_limits_model.dart`), before the default `_`:

```dart
        TransferRejection.tooLarge => (
          title: importProblemTooLargeTitle,
          body: importProblemTooLargeBody(
            TransferLimits.maxRows,
            TransferLimits.maxMegabytes,
          ),
        ),
```

`mx_bottom_sheet.dart`. Constructors and fields (replace the existing constructor and `child`):

```dart
  const MxBottomSheet({
    super.key,
    required Widget this.child,
    this.header,
    this.footer,
    this.hasGrabber = true,
    this.isHeld = false,
  }) : itemCount = null,
       itemBuilder = null;

  /// A sheet whose body is a long list: [itemBuilder] builds only the rows in
  /// view, where [child] is laid out whole (SP2a 2.23). The list fills the
  /// sheet's 85% cap.
  const MxBottomSheet.builder({
    super.key,
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.header,
    this.footer,
    this.hasGrabber = true,
    this.isHeld = false,
  }) : child = null;

  final Widget? child;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
```

and the body line `Flexible(child: SingleChildScrollView(child: child)),` becomes:

```dart
                Flexible(
                  child: switch (itemBuilder) {
                    final builder? => ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: itemCount,
                      itemBuilder: builder,
                    ),
                    null => SingleChildScrollView(child: child),
                  },
                ),
```
Update the class doc: "only [child] scrolls" gains "(or the builder's list)".

`import_skipped_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Opens every row the import skipped (SP2a 2.23). The result lists five
/// inline; the rest are here, built only as they scroll into view, so a
/// 20,000-row file with thousands of skips stays light.
Future<void> showImportSkippedSheet(
  BuildContext context, {
  required List<ImportRow> rows,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => ImportSkippedSheetWidget(rows: rows),
);

class ImportSkippedSheetWidget extends StatelessWidget {
  const ImportSkippedSheetWidget({super.key, required this.rows});

  final List<ImportRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet.builder(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.importSkippedHeader,
          style: context.textStyles.compactTitle,
        ),
      ),
      itemCount: rows.length,
      itemBuilder: (_, index) => ImportPreviewRowWidget(row: rows[index]),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.importCloseAction,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
```

`import_result_widget.dart`: add `import 'dart:async';` and the sheet import; replace `_SkippedRows` and its state class (lines 115-157) with:

```dart
/// The rows the import skipped, each as the preview drew it: number, term,
/// meaning, why, and its mark (critique 2026-10-02, F4). The first
/// [shownRows] show here; "Show all" opens every row in a sheet that builds
/// them lazily (SP2a 2.23).
class _SkippedRows extends StatelessWidget {
  const _SkippedRows({required this.rows});

  final List<ImportRow> rows;

  static const int shownRows = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSkippedHeader,
          children: [
            for (final row in rows.take(shownRows))
              ImportPreviewRowWidget(row: row),
          ],
        ),
        if (rows.length > shownRows)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxButton(
              label: l10n.importSkippedShowAll(rows.length),
              tone: MxButtonTone.text,
              size: MxButtonSize.compact,
              onPressed: () =>
                  unawaited(showImportSkippedSheet(context, rows: rows)),
            ),
          ),
      ],
    );
  }
}
```

ARB. EN (after `importProblemEmptyBody`):

```json
  "importProblemTooLargeTitle": "This file is too large to import",
  "@importProblemTooLargeTitle": {
    "description": "Import problem: the source is over the size or row cap (SP2a 2.23)."
  },
  "importProblemTooLargeBody": "Split it into files of up to {rows} rows or {megabytes} MB. Nothing was read.",
  "@importProblemTooLargeBody": {
    "placeholders": {
      "rows": {
        "type": "int",
        "format": "decimalPattern"
      },
      "megabytes": {
        "type": "int"
      }
    },
    "description": "Import problem: how to fit under the cap; rows is the row cap, megabytes the size cap."
  },
```

VI (after `importProblemEmptyBody`):

```json
  "importProblemTooLargeTitle": "Tệp này quá lớn để nhập",
  "importProblemTooLargeBody": "Hãy chia thành các tệp tối đa {rows} dòng hoặc {megabytes} MB. Chưa đọc gì.",
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `flutter test test/features/transfer/data/transfer_file_repository_impl_test.dart test/shared/widgets/mx_bottom_sheet_test.dart test/features/transfer/presentation/import_result_skipped_test.dart test/features/transfer/presentation/card_import_controller_test.dart test/features/transfer/presentation/card_import_screen_test.dart`
Expected: PASS. (The golden file is excluded on Windows; the Linux run writes `import_too_large_*`.)

- [ ] **Step 5: Docs (Vietnamese)**

`UC-TRANSFER-001-…md`, add after the `E6` bullet: `- **E7 — Nguồn quá lớn:** file hoặc văn bản dán vượt 5 MB, hoặc bảng sau parse vượt 20.000 hàng (tính cả hàng header) → bị từ chối trước khi giải mã bằng lý do có kiểu, kèm hướng dẫn chia nhỏ; nguồn đã chọn trước đó giữ nguyên và không đọc gì.` And in step 8 replace `từng dòng bị bỏ qua với số dòng và lý do (critique 2026-10-02)` with `từng dòng bị bỏ qua với số dòng và lý do (critique 2026-10-02; năm dòng đầu hiện tại chỗ, "Show all" mở danh sách đầy đủ trong một sheet dựng lười)`. Run `python tools/docs/generate.py` and `python tools/docs/check.py`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transfer lib/shared/widgets/mx_bottom_sheet.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/transfer test/shared/widgets/mx_bottom_sheet_test.dart docs/features/transfer docs/_generated
git commit -m "feat(transfer): cap an import's size and list skipped rows lazily (SP2a 2.23)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 29 (C8): The header toggle defaults from what the mapping recognised

Finding 2.24. After a read `CardImportDraft.hasHeaderRow` is always `true` (`card_import_state.dart:267` in the spec's numbering; the default of the `CardImportDraft` constructor today), so a headerless file silently loses its first row as a "header" (`readSource` builds the draft without setting it, `card_import_controller.dart:116-127`).

**Files:**
- Modify: `lib/features/transfer/presentation/controllers/card_import_controller.dart` (`readSource`, the `Ok` branch; new private helper)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart` (`header` 29-31; subtitle 56-58)
- Modify (docs): `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md` (step 4, A3)
- Test: `test/features/transfer/presentation/card_import_controller_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart`
- Goldens: `import_mapping_no_header_light.png` / `_dark.png` move (the toggle's subtitle now names row 1's cells while the toggle is off). `import_mapping_*` and `import_preview_*` do not (their file has a recognised header).

**Interfaces:**
- Behaviour: after `readSource`, `hasHeaderRow == mapping.fieldByColumn.isNotEmpty`, where the mapping is `ColumnMapping.fromHeader(row 1)`. The toggle's subtitle always names the cells of row 1, on or off. The person can still flip the toggle (`setHasHeaderRow` is unchanged).
- No signature changes.

- [ ] **Step 1: Write the failing tests**

`card_import_controller_test.dart`:

```dart
  test('the header toggle follows what the first row names (SP2a 2.24)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

    picked = _file('vocab.csv', 'front,back\nmenu,thực đơn\n');
    await wizard.chooseFile();
    await wizard.readSource();
    expect(draftOf(c).hasHeaderRow, isTrue);

    picked = _file('vocab.csv', 'menu,thực đơn\nbill,hóa đơn\n');
    await wizard.chooseFile();
    await wizard.readSource();
    expect(draftOf(c).hasHeaderRow, isFalse);
    expect(draftOf(c).table!.rows.first, ['menu', 'thực đơn']);
  });
```

`card_import_screen_test.dart` (add `import 'package:memox/shared/widgets/mx_toggle.dart';`):

```dart
  libraryTest('a headerless file keeps its first row as data and the toggle '
      'still names that row (SP2a 2.24)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('mul,water\nbul,fire\n'));
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);

    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(find.text('mul · water'), findsOneWidget);
    expect(find.text(_en.importFileRead('CSV', 2, 2)), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/presentation/card_import_controller_test.dart test/features/transfer/presentation/card_import_screen_test.dart`
Expected: FAIL: the first test gets `hasHeaderRow` true for the headerless file; the second finds the toggle on and no `mul · water` subtitle.

- [ ] **Step 3: Implement**

`card_import_controller.dart`: the `Ok(:final value)` branch of `readSource` becomes `Ok(:final value) => _read(draft, source, value),` and the helper goes at the end of the class:

```dart
  /// The step-2 draft for a table just read: the first row is a header only
  /// when it named a column (SP2a 2.24); the person can still flip it.
  CardImportDraft _read(
    CardImportDraft draft,
    TransferSource source,
    SourceTable table,
  ) {
    final mapping = ColumnMapping.fromHeader(
      table.rows.isEmpty ? const [] : table.rows.first,
    );
    return CardImportDraft(
      step: CardImportStep.columns,
      sourceKind: draft.sourceKind,
      fileName: draft.fileName,
      source: source,
      table: table,
      mapping: mapping,
      hasHeaderRow: mapping.fieldByColumn.isNotEmpty,
    );
  }
```
(`SourceTable` import comes from C6; add it if C6 is not applied.)

`import_mapping_section_widget.dart`:

```dart
    final table = draft.table!;
    // Row 1's cells, header or not: the toggle's subtitle shows what it
    // governs (SP2a 2.24).
    final firstRow = table.rows.isEmpty ? null : table.rows.first;
    final header = draft.hasHeaderRow ? firstRow : null;
```
and the toggle row's subtitle:

```dart
              subtitle: firstRow
                  ?.where((cell) => cell.trim().isNotEmpty)
                  .join(' · '),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/presentation/card_import_controller_test.dart test/features/transfer/presentation/card_import_screen_test.dart test/features/transfer/domain`
Expected: PASS.

- [ ] **Step 5: Docs (Vietnamese)**

`UC-TRANSFER-001-…md` step 4: replace `Hệ thống mặc định coi hàng đầu là header và tự map` with `Hệ thống coi hàng đầu là header khi nó gọi tên ít nhất một cột, và tự map` (keep the rest of the sentence). A3: replace `người dùng tắt "First row contains headers"` with `hệ thống tự tắt "First row is a header" khi hàng đầu không gọi tên cột nào (người dùng cũng có thể tự bật/tắt); công tắc luôn nêu các ô của hàng 1`. Run `python tools/docs/generate.py` and `python tools/docs/check.py`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transfer test/features/transfer docs/features/transfer docs/_generated
git commit -m "fix(transfer): import treats row 1 as a header only when it names a column (SP2a 2.24)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 30 (C9): "Undo import" moves the imported cards to the Trash

**Also pin (Review Focus):** Undo import still moves every imported card to the Trash after some of them were edited or studied in between — add a test that edits one imported card, undoes the import, and expects all of them in the Trash and restorable.

Finding 2.25. After an import there is no way back short of finding and trashing the cards by hand; the commit does not even return which cards it wrote (`CardImportResult` holds only a count and the skipped indexes).

**Files:**
- Modify: `lib/features/card/domain/models/card_import_result_model.dart` (3-11)
- Modify: `lib/features/card/domain/repositories/card_transfer_repository.dart` (`importCards` doc 17-23)
- Modify: `lib/features/card/data/repositories/card_transfer_repository_impl.dart` (`importCards` 57-72)
- Modify: `lib/features/transfer/domain/models/import_summary_model.dart` (10-26)
- Modify: `lib/features/transfer/domain/usecases/commit_import_use_case.dart` (31-45)
- Create: `lib/features/transfer/domain/usecases/undo_import_use_case.dart`
- Create: `lib/features/transfer/presentation/providers/undo_import_use_case_provider.dart`
- Modify: `lib/features/transfer/presentation/controllers/card_import_controller.dart` (add `undoImport`)
- Create: `lib/features/transfer/presentation/widgets/overlays/import_undo_dialog_widget.dart`
- Modify: `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart` (constructor 21-26; counts 45-48)
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart` (`_resultShell` 169-205)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify (docs): `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Test: `test/features/card/data/card_transfer_test.dart`, `test/features/transfer/presentation/card_import_controller_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart`, `test/features/transfer/presentation/import_result_skipped_test.dart`
- Goldens: `import_partial_light.png` / `import_partial_dark.png` move (the result gains the Undo import button; this is the spec's "Undo import result" golden).

**Interfaces:**
- Consumes: `BulkOutcome` (C1), `CardRepository.deleteCards` (C1), `bulkToast` (C3).
- Changes: `CardImportResult({required int written, required List<int> skippedIndexes, required List<String> writtenIds})` (ids of the cards written, in draft order); `ImportSummary({required int written, required int blank, required List<ImportRow> skipped, List<String> writtenIds = const []})`.
- Produces: `UndoImportUseCase.call({required Set<String> cardIds}) → Future<Outcome<BulkOutcome, CardRejection>>` (a thin call of `CardRepository.deleteCards`, in the transfer domain because a feature may not import another feature's use cases, ADR-011); `CardImportController.undoImport() → Future<Outcome<BulkOutcome, CardRejection>>` over `CardImportDone.summary.writtenIds`; `ImportResultWidget({required CardImportState state, VoidCallback? onUndo})`; `showImportUndoDialog(BuildContext context, {required String deckId, required int count}) → Future<BulkOutcome?>`.
- New ARB keys `importUndoAction`, `importUndoTitle(int count)`, `importUndoneToast(int count)`, `importUndoGone`.
- Behaviour: Undo import is on the result when `written > 0`; it asks "Move the {n} imported cards to Trash?" (the note of the Trash dialog, "Recoverable from Trash for 30 days…", is reused); on confirm the cards still active go to the Trash, a batch each, the toast says how many (and how many were already gone), and the import screen closes. A write failure keeps the dialog open with the failure toast.
- **DECISION:** the spec says the cards move "as one batch". `deleteCards` writes one batch per card at one time (BR-TRASH-001: each card restorable alone from the Trash screen). Recommended: keep it, read "one batch" as "one operation", so the imported cards stay individually restorable for 30 days.
- **DECISION:** "Before the write starts, Cancel stays available. Once the transaction runs, it holds." already holds today: the preview step's Cancel is live, and `ImportCommitBarWidget` disables it from the moment `commit()` sets `CardImportStep.importing` (no awaited work sits between the tap and the transaction). This task pins it with a test and adds no new control. Recommended: accept.

- [ ] **Step 1: Write the failing tests**

`card_transfer_test.dart`, inside `group('importCards …'` add:

```dart
    test('the ids of the cards written come back, and not those a duplicate '
        'dropped (SP2a 2.25)', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'menu',
        back: 'thực đơn',
      );

      final result = _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(front: 'menu', back: 'thực đơn'),
            CardDraft(front: 'bill', back: 'hóa đơn'),
            CardDraft(front: 'tip', back: 'tiền boa'),
          ],
          includeDuplicates: false,
        ),
      );

      expect(result.writtenIds, hasLength(2));
      final rows = await db
          .customSelect("SELECT id FROM card WHERE front IN ('bill', 'tip')")
          .get();
      expect(result.writtenIds.toSet(), {
        for (final row in rows) row.read<String>('id'),
      });
    });
```

`card_import_controller_test.dart` (imports: `package:memox/core/error/bulk_outcome.dart`, `../../../support/trash_fixtures.dart`):

```dart
  test('Undo import moves the imported cards to the Trash, a batch each, '
      'skipping one already gone (SP2a 2.25)', () async {
    picked = _file('vocab.csv', 'front,back\nmenu,thực đơn\nbill,hóa đơn\n');
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();
    await wizard.commit();
    final done =
        c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
    expect(done.summary.writtenIds, hasLength(2));
    final [first, second] = done.summary.writtenIds;
    await trashCardRow(db, first);

    final outcome = await wizard.undoImport() as Ok<BulkOutcome, CardRejection>;

    expect(outcome.value.done, {second});
    expect(outcome.value.skipped, {first});
    expect(outcome.value.batchIds, hasLength(1));
    expect(await _active(db), 0);
  });
```
and at the bottom of the file:

```dart
Future<int> _active(AppDatabase db) async => (await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
        )
        .getSingle())
    .read<int>('n');
```

`card_import_screen_test.dart` (imports: `package:memox/features/card/domain/models/card_draft_model.dart`, `package:memox/features/transfer/domain/models/import_preview_model.dart`, `package:memox/features/transfer/presentation/states/card_import_state.dart`, `package:memox/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart`, `package:memox/shared/widgets/mx_dialog.dart`):

```dart
Future<int> _active(LibraryEnv env) async => (await env.db
        .customSelect(
          'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
        )
        .getSingle())
    .read<int>('n');
```

```dart
  libraryTest('Undo import asks, then moves the imported cards to the Trash '
      'and closes (SP2a 2.25)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var closed = 0;
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back\nmul,water\nbul,fire\n'),
      onClose: () => closed++,
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);
    await _tap(tester, _en.importCommitAction(2));
    expect(await _active(env), 2);

    await _tap(tester, _en.importUndoAction);
    expect(find.text(_en.importUndoTitle(2)), findsOneWidget);
    expect(find.text(_en.cardDeleteNote(2)), findsOneWidget);
    await _tap(tester, _en.commonCancel);
    expect(await _active(env), 2);
    expect(closed, 0);

    await _tap(tester, _en.importUndoAction);
    await tester.tap(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardMoveToTrash),
      ),
    );
    await tester.pumpAndSettle();

    expect(await _active(env), 0);
    expect(closed, 1);
    expect(find.text(_en.importUndoneToast(2)), findsOneWidget);
  });

  libraryTest('Cancel stays live before the write and holds once it runs '
      '(SP2a 2.25, a pin of current behaviour)', (tester, env) async {
    final preview = ImportPreview(const [
      ImportRow(
        rowNumber: 2,
        kind: ImportRowKind.ready,
        draft: CardDraft(front: 'a', back: 'b'),
      ),
    ]);
    Widget bar(CardImportDraft draft) => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ImportCommitBarWidget(
          draft: draft,
          onCancel: () {},
          onRead: () {},
          onPreview: () {},
          onCommit: () {},
        ),
      ),
    );
    VoidCallback? cancel() => tester
        .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
        .onPressed;

    await pumpLibraryScreen(
      tester,
      env,
      bar(CardImportDraft(step: CardImportStep.preview, preview: preview)),
    );
    expect(cancel(), isNotNull);

    await pumpLibraryScreen(
      tester,
      env,
      bar(
        CardImportDraft(
          step: CardImportStep.importing,
          preview: preview,
          isBusy: true,
        ),
      ),
    );
    expect(cancel(), isNull);
  });
```

`import_result_skipped_test.dart`:

```dart
  libraryTest('Undo import shows only when something was written (SP2a 2.25)', (
    tester,
    env,
  ) async {
    Widget host(ImportSummary summary) => Scaffold(
      body: SingleChildScrollView(
        child: ImportResultWidget(state: CardImportDone(summary), onUndo: () {}),
      ),
    );

    await pumpLibraryScreen(
      tester,
      env,
      host(const ImportSummary(written: 2, blank: 0, skipped: [])),
    );
    expect(find.text(_en.importUndoAction), findsOneWidget);

    await pumpLibraryScreen(
      tester,
      env,
      host(ImportSummary(written: 0, blank: 0, skipped: [_duplicate(2)])),
    );
    expect(find.text(_en.importUndoAction), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/data/card_transfer_test.dart test/features/transfer/presentation/import_result_skipped_test.dart test/features/transfer/presentation/card_import_controller_test.dart`
Expected: FAIL (compile: `writtenIds`, `undoImport`, `onUndo`, `importUndoAction` undefined).

- [ ] **Step 3: Implement**

`card_import_result_model.dart`:

```dart
/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({
    required this.written,
    required this.skippedIndexes,
    required this.writtenIds,
  });

  final int written;

  /// The places, in the drafts handed in, of those the duplicate policy
  /// dropped inside the commit (BR-TRANSFER-003), in order.
  final List<int> skippedIndexes;

  /// The ids of the cards written, in the order of the drafts kept; an Undo
  /// import names them (SP2a 2.25).
  final List<String> writtenIds;
}
```

`card_transfer_repository_impl.dart` `importCards` (replace lines 57-72):

```dart
      final taken = await _dao.foldedPairs(deckId);
      final skipped = <int>[];
      final writtenIds = <String>[];
      for (final (index, draft) in drafts.indexed) {
        final pair = (front: foldText(draft.front), back: foldText(draft.back));
        if (!includeDuplicates && taken.contains(pair)) {
          skipped.add(index);
          continue;
        }
        taken.add(pair);
        writtenIds.add(await _cards.insertCard(deckId, draft, at));
      }
      final written = writtenIds.length;
      if (written > 0 && contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(
        CardImportResult(
          written: written,
          skippedIndexes: skipped,
          writtenIds: writtenIds,
        ),
      );
```
`card_transfer_repository.dart` `importCards` doc: append "The result names the ids written, which an Undo import moves to the Trash (SP2a 2.25)."

`import_summary_model.dart`: constructor `const ImportSummary({required this.written, required this.blank, required this.skipped, this.writtenIds = const []});` with field doc `/// The ids of the cards written, which Undo import moves to the Trash (SP2a 2.25). final List<String> writtenIds;`.

`commit_import_use_case.dart`: `ImportSummary(written: value.written, blank: preview.blank, writtenIds: value.writtenIds, skipped: _skipped(…))`.

`undo_import_use_case.dart`:

```dart
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRANSFER-001 step 8 (SP2a 2.25): the cards an import wrote go to the
/// Trash, a batch each, recoverable for 30 days (BR-TRASH-001). A card gone
/// since is skipped (BR-CARD-011). A database failure leaves as the thrown
/// `Failure`.
final class UndoImportUseCase {
  const UndoImportUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<BulkOutcome, CardRejection>> call({
    required Set<String> cardIds,
  }) => _cards.deleteCards(cardIds: cardIds);
}
```

`undo_import_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/undo_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_import_use_case_provider.g.dart';

@riverpod
UndoImportUseCase undoImportUseCase(Ref ref) =>
    UndoImportUseCase(ref.watch(cardRepositoryProvider));
```

`card_import_controller.dart`: add imports (`core/error/bulk_outcome.dart`, `features/card/domain/failures/card_failure.dart`, `…/providers/undo_import_use_case_provider.dart`) and, after `startOver`:

```dart
  /// "Undo import" after a result (SP2a 2.25): the cards the commit wrote go
  /// to the Trash, a batch each. The widget chooses the feedback; a database
  /// `Failure` is thrown through.
  Future<Outcome<BulkOutcome, CardRejection>> undoImport() {
    final cardIds = switch (state) {
      CardImportDone(:final summary) => summary.writtenIds.toSet(),
      _ => const <String>{},
    };
    return ref.read(undoImportUseCaseProvider)(cardIds: cardIds);
  }
```

`import_undo_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before the [count] imported cards move to the Trash (SP2a 2.25).
/// Completes with what moved once they have, and the toast is up; null when
/// the person kept them.
Future<BulkOutcome?> showImportUndoDialog(
  BuildContext context, {
  required String deckId,
  required int count,
}) => showMxDialog<BulkOutcome>(
  context,
  builder: (_) => ImportUndoDialogWidget(deckId: deckId, count: count),
);

/// The confirm is not destructive, since the Trash keeps the cards for 30
/// days, and it spins while they move.
class ImportUndoDialogWidget extends ConsumerStatefulWidget {
  const ImportUndoDialogWidget({
    super.key,
    required this.deckId,
    required this.count,
  });

  final String deckId;
  final int count;

  @override
  ConsumerState<ImportUndoDialogWidget> createState() =>
      _ImportUndoDialogWidgetState();
}

class _ImportUndoDialogWidgetState
    extends ConsumerState<ImportUndoDialogWidget> {
  var _isUndoing = false;

  Future<void> _undo() async {
    if (_isUndoing) return;
    setState(() => _isUndoing = true);
    try {
      final outcome = await ref
          .read(cardImportControllerProvider(widget.deckId).notifier)
          .undoImport();
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok(:final value):
          showMxSnackbar(
            context,
            message: l10n.bulkToast(
              l10n.importUndoneToast(value.done.length),
              value.skipped.length,
            ),
          );
          Navigator.of(context).pop(value);
        // Every imported card is already gone: nothing is left to move, so
        // the result has nothing left to undo either.
        case Rejected():
          showMxSnackbar(context, message: l10n.importUndoGone);
          Navigator.of(context).pop(const BulkOutcome(done: {}));
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isUndoing = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.importUndoTitle(widget.count),
      content: MxNote(
        icon: AppIcons.history,
        text: l10n.cardDeleteNote(widget.count),
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.cardMoveToTrash,
        confirmIcon: AppIcons.delete,
        isConfirmLoading: _isUndoing,
        onConfirm: _isUndoing ? null : _undo,
      ),
    );
  }
}
```

`import_result_widget.dart`: constructor `const ImportResultWidget({super.key, required this.state, this.onUndo});` with field doc `/// Opens the Undo import confirm; null hides the button (SP2a 2.25). final VoidCallback? onUndo;` and inside the `if (summary.kind != ImportSummaryKind.none) ...[` spread, after `_Counts(summary: summary),` add:

```dart
            if (summary.written > 0 && onUndo != null) ...[
              const SizedBox(height: AppSpacing.grouped),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MxButton(
                  label: l10n.importUndoAction,
                  tone: MxButtonTone.outline,
                  size: MxButtonSize.small,
                  onPressed: onUndo,
                ),
              ),
            ],
```

`card_import_screen.dart`: add `import 'package:memox/features/transfer/presentation/widgets/overlays/import_undo_dialog_widget.dart';`, the method

```dart
  /// Undo import (SP2a 2.25): the dialog asks and writes; once the cards are
  /// in the Trash there is nothing left to show, so the import closes.
  Future<void> _undoImport(int count) async {
    final undone = await showImportUndoDialog(
      context,
      deckId: widget.deckId,
      count: count,
    );
    if (undone != null && mounted) widget.onClose();
  }
```
and in `_resultShell` the body becomes:

```dart
      body: MxScreenScroll(
        children: [
          ImportResultWidget(
            state: state,
            onUndo: switch (state) {
              CardImportDone(:final summary) when summary.written > 0 =>
                () => unawaited(_undoImport(summary.writtenIds.length)),
              _ => null,
            },
          ),
        ],
      ),
```

ARB. EN (after `importBackToDeck`):

```json
  "importUndoAction": "Undo import",
  "@importUndoAction": {
    "description": "Import result: moves the cards this import wrote to the Trash (SP2a 2.25)."
  },
  "importUndoTitle": "{count, plural, =1{Move the imported card to Trash?} other{Move the {count} imported cards to Trash?}}",
  "@importUndoTitle": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Undo import confirm title."
  },
  "importUndoneToast": "{count, plural, =1{1 imported card moved to Trash} other{{count} imported cards moved to Trash}}",
  "@importUndoneToast": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Snackbar after Undo import."
  },
  "importUndoGone": "None of the imported cards is left to move.",
  "@importUndoGone": {
    "description": "Snackbar when every imported card was already gone."
  },
```

VI (after `importBackToDeck`):

```json
  "importUndoAction": "Hoàn tác lần nhập",
  "importUndoTitle": "{count, plural, other{Chuyển {count} thẻ vừa nhập vào Thùng rác?}}",
  "importUndoneToast": "{count, plural, other{Đã chuyển {count} thẻ vừa nhập vào Thùng rác}}",
  "importUndoGone": "Không còn thẻ nào vừa nhập để chuyển.",
```

Run `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter analyze` — Expected: no issues.
Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer test/features/card/data/card_transfer_test.dart`
Expected: PASS.

- [ ] **Step 5: Docs (Vietnamese)**

`UC-TRANSFER-001-…md`: in the Alternative flows add after A5: `- **A6 — Undo import:** từ màn kết quả có ghi card, người dùng bấm Undo import và xác nhận ("Move the {n} imported cards to Trash?"); các card vừa ghi mà còn active vào Trash, mỗi card một batch (BR-TRASH-001), khôi phục được 30 ngày; card đã không còn bị bỏ qua và được báo số lượng (BR-CARD-011); màn import đóng. Hủy ở bước xem trước vẫn dùng được; khi transaction commit đã chạy, Hủy bị khoá.` and an acceptance criterion: `- [ ] **Given** một import đã ghi card, **when** người dùng bấm Undo import và xác nhận, **then** các card đó vào Trash, mỗi card một batch, và màn import đóng (BR-TRASH-001, A6).` Run `python tools/docs/generate.py` and `python tools/docs/check.py`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/card lib/features/transfer lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features docs/features/transfer docs/_generated
git commit -m "feat(transfer): Undo import moves the imported cards to the Trash (SP2a 2.25)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

---

### Task 31: Screen records, WBS, gate, goldens, golden review, the one audit

**Files:**
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`, `11-card-import.md`, `12-card-export.md`, `13-study-home.md`, `14-study-entry.md`, `15-study-options.md`, `16-study-browse.md`, `19-study-recall.md`, `20-study-fill.md`, `21-session-summary.md`, `22-progress.md`, and their rows in `00-index.md` if a state count changes. Screens 08 and 09 are done in Task 20.
- Modify: `docs/wbs_FE.md` (new row FE-D28 after FE-D27).
- Modify: `docs/shared/rules/` / `docs/features/**/rules/BR-TRASH-008*`, and `UC-CARD-001`, only if the owner approved C5's amendment.
- Modify: `DESIGN.md`, recording `MxInlineBanner`'s neutral tone (if Task 14 landed) and `MxBottomSheet.builder` (if approved).
- Goldens: the new and moved PNGs listed in the appendix.

- [ ] **Step 1: Update each screen's detail file.** For each item that touches the screen, add a States row or ruling, and add the new copy lines. The appendix "Docs and detail files" lists the exact lines for 07, 11 and 12. For the study screens, cite the SP2a item numbers (2.01–2.13, 2.49–2.51).
- [ ] **Step 2: Add the WBS row:** `| FE-D28 | UI hardening SP2a: study và thẻ — draft thẻ (schema 13), hỏi khi kết thúc phiên deck khác, giữ màn khi deck mất, Recall dừng dưới dialog, Fill tắt gợi ý, thao tác hàng loạt bỏ qua thẻ đã mất + Undo, import giới hạn/Undo | đang làm | FE-D27 | L | [spec](superpowers/specs/2026-10-03-ui-hardening-sp2a-design.md), [plan](superpowers/plans/2026-10-03-ui-hardening-sp2a.md) | SP2b |`
- [ ] **Step 3: Docs check.** Run `python tools/docs/generate.py`, then `python tools/docs/check.py`. Expected: `PASS — 0 error(s)`. Commit `docs: SP2a screen records and FE-D28`.
- [ ] **Step 4: The gate.** Run `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`. Fix anything it reports in the task that owns it.
- [ ] **Step 5: Regenerate goldens in the Linux container** (the memory note `goldens-on-linux` has the Windows details):
  - Remove `build/`, then copy the worktree into the container.
  - In the copy: `rm -rf .git && git init && git add -A && git commit`.
  - Run `flutter pub get`, then `TZ=UTC bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`.
  - Compare with `flutter test --tags golden -j 2` over the golden files. It must pass.
  - Copy back only `test/**/goldens/*.png`, and commit `test(goldens): regenerate for SP2a`.
- [ ] **Step 6: Golden review.** Build the `golden-compare` page against the merge-base, explain every moved and new picture, and hand it to the owner before any merge.
- [ ] **Step 7: Run one `impeccable audit`** of SP2a's changed surface. Fix what it finds in one batch, report it, and run no further audit.
- [ ] **Step 8: Close out.** Flip FE-D28 to `xong` with the evidence (`dod_check.sh` xanh, goldens Linux xanh), run the docs check, and commit.


## Appendix: cluster notes (cross-task interfaces, order, risks)

### Cluster A
**Cross-task interfaces**

- A1 produces `StudyEntryRepository.otherDeckSessionName` (every implementer must add it: today only `StudyEntryRepositoryImpl` and the test fake `FailingEntries`), `StudyEntryController.start(confirmEnd:)`, the fixture `openOtherDeckSession`, and the new use case/provider (the `.g.dart` is generated by `build_runner`).
- A2 produces `test/support/library_harness.dart › pumpLibraryScreenPushed`; A3 reuses it. A1/A2 both edit `study_entry_controller.dart` and `study_entry_screen.dart` (A2 wraps `build` in a `PopScope`; A1 changed `_start` only, so the edits do not overlap).
- A4 changes `StudySessionController.abandon` to `Future<bool>`; its only caller is `_confirmAbandon`. A5 builds on A4's `_confirmAbandon`/`_isConfirming`. A7 and A9 edit different regions of `study_session_screen.dart` (the banner in `_sessionPage`; `build`/`_pageOf`/`_onView`/`_onPop`).
- A6 changes `StudySettleGuardWidget` (new optional parameter) and the summary footer; A9 adds `canStudyDeck` to the same summary widget afterwards.
- Test support edited by this cluster: `test/support/study_fixtures.dart › LockableSessions` gains `isAbandonFailing` (A4), `isRevealFailing` (A7), `isResumeFailing` (A10); `study_entry_fixtures.dart` (A1); `library_harness.dart` (A2). Another cluster editing these files should merge, not replace.
- ARB: all clusters append to `app_en.arb`/`app_vi.arb`; this cluster's anchors are listed at the top. `test/app/l10n_test.dart` requires every EN key to carry a `description` and every EN key to exist in VI.
- Screen docs the docs task of SP2a must update (CLAUDE.md: a PR that changes a screen updates its detail file and screen-index row): `13-study-home.md` (2.49), `14` entry (2.01–2.04), `15` study options (2.05–2.06), `16` browse (2.10), `19` recall (2.11, 2.12), `20` fill (2.13), `21` summary (2.09, 2.51), `22` progress (2.50), and the session shell notes (2.07, 2.08). The new use case may change `docs/_generated/traceability.md`: regenerate it with the gate's docs step.

**Goldens**

- New: `study_entry_end_other_session_{light,dark}.png` (A1) and `progress_stale_{light,dark}.png` (A11). Both tests carry the golden tag and have no PNG until the Linux run of the Gate task.
- None of the existing goldens should move. The only risk is the summary goldens (A6): the guard fades the footer in from muted opacity, so the golden test waits `StudySettleGuardWidget.settle` before capturing; if a summary golden still moves in the Linux run, that wait was lost.
- The study-entry-gone state (A2) and the discard dialog (A3) get widget tests, no golden.

**Risks**

- A6: any test or device flow that taps Done or Next within 400 ms of the swap now misses. Fixed here: `session_summary_test.dart` (first test), `study_routes_test.dart` (the Resume test), `it_plat_005_system_back_test.dart`. The full `test/features/study` and `test/app` runs in A6 step 4 will show any other.
- A11 relies on Riverpod 3 keeping the last value on an `AsyncError`; the new tests are the proof, and a failure there means the screens need a different source for the last value.
- A4: `_leave` runs after the dialog's future completes and re-checks `ModalRoute.isCurrent`; the popped dialog route is no longer present at that point (Navigator lifecycle), which the 2.07 test exercises. A pending leave also supersedes a confirmed Stop (nothing to stop once the deck is gone).
- A3: `Navigator.pop()` after a confirmed discard is not held by `PopScope`; under go_router the route is a page-based route, and the pushed-route test covers `MaterialPageRoute` only. If the owner sees the route not popping in the app, switch to the card editor's `_isLeaving` + post-frame `maybePop`.
- A1: a start that fails to read the other deck's session proceeds without asking (the start meets the same store and reports its own failure). Two taps inside the single read are blocked by `_isConfirming`.
- Drift: the new query in `study_session_queries.drift` needs `build_runner` before any test compiles; no table changes, so no schema snapshot.

**

### Cluster B
**Cross-task interfaces.**
- B1 → B2: `CardDraftRow`, `AppDatabase.cardDraft`. B2 → B4/B5: `CardDraftRepository`, `CardDraftKey`, `CardDraft.sameContentAs`, `cardDraftRepositoryProvider`. B3 → B5: `MxBannerTone.neutral`. B4 → B5/B6/B7/B8: `CardDraftController`. B5 → B6/B7: the form's `_drafts`, `_offer`; B6 → B7/B8: `_keepNow()`, the `PopScope` expression, `onCancel` nullable. B7 → B8: `CardEditorSource`, `_EditLoaderState._opened`. B8 changes `CardRepository.editCard`, so any fake that overrides `editCard` explicitly must add `expectedUpdatedAt` (found in the repo: `_CountingEdits`; the new `_HeldEdits`).
- The new form code assumes the order B5 → B6 → B7 → B8 (later snippets quote earlier ones). B1–B4 and B9–B10 are independent of each other apart from the arrows above.

**Files shared with other clusters (merge by hand).**
- `lib/l10n/app_en.arb` / `app_vi.arb`: my keys are inserted next to `cardDeckRejectsBody`, `cardGoneBody`, `cardRejectionTargetInTrash` and `cardKeepEditing`, never at the end.
- `lib/shared/widgets/mx_inline_banner.dart` and `DESIGN.md:347`: B3 adds the `neutral` tone. Cluster A (2.50, a warning banner) does not need it; if any cluster adds `neutral` first, B3 shrinks to its test.
- `card_repository.dart`, `card_repository_impl.dart`, `card_actions_controller.dart` (cluster C's `BulkOutcome`): B8 touches `editCard` only. `CardRejection` gains one value (`changedElsewhere`) and two exhaustive switches (card, trash) must carry it.
- `lib/core/database/app_database.dart`: B1 bumps `schemaVersion` to 13. If another cluster needs a table it must take 14 after this.

**Risks and ceilings.**
1. `updated_at` is stored in seconds, so a change from another device in the same second as the editor's version is not seen (marked `ponytail:` in `editCard`; a version column would close it). A remote tag-link-only change bumps `card.updated_at` only if sync writes it; the sync adapter applies the remote `updated_at` (`sync_card_queries.drift:32`), which I read but did not run.
2. While a kept draft is on offer, new typing is not autosaved until the person answers the banner (D8); a process kill in that window loses the new typing but keeps the offered draft.
3. The draft is written 500 ms after the last change: a kill inside that window loses at most those 500 ms. `dispose` and every refusal flush at once.
4. Each autosave runs one `DELETE … WHERE updated_at < cutoff` (30-day expiry) after the upsert; the table is tiny and unindexed on purpose (no query could name an index).
5. Autosave listens to `TextEditingController` notifications, which include caret moves; an unchanged form writes a harmless `DELETE` after a pause.
6. The create-mode "deck is gone" page (`cardDeckGoneBody`) still says "This card was not saved." The draft is kept, but the copy does not say so (D10).
7. Existing tests that type in the editor now also write drafts. `libraryTest` disposes the tree before the database closes, and `dispose` flushes through `guardDatabase`, so a late write is swallowed rather than failing a test.

**Review focus.**
- B5: `_saved` is assigned in `initState` (it was a lazy `late var`), so the offer is compared with the form as opened, not as already typed into.
- B5/B6: `_keepDraft` is silent while an offer is pending; `_keepNow` overrides that on a refusal.
- B6: `canPop` is false while saving, so Back neither pops nor asks; once the save lands the existing `_leave()` path pops.
- B7: the loader sets `_opened` inside `build` (idempotent `??=`); the form keeps one `ValueKey(cardId)`, so its state survives every later stream event.
- B8: "Keep mine" passes no expected version; "Use theirs" loads the loader's latest detail, so the dialog should open only after the stream has re-emitted (the tests pump twice after the other device's save).

**

### Cluster C
**Cross-task interfaces**

- `BulkOutcome` (C1, `lib/core/error/bulk_outcome.dart`) is returned by `CardRepository.deleteCards/moveCards/setFlagged` (C1), wrapped by `TagAttached` (C2), read by the UI (C3), and used by `showCardsTrashedSnackbar` via `batchIds` (C1, C3, C5) and by `UndoImportUseCase` / `ImportUndoDialogWidget` (C9). C4 copies the skipped ids into `CardExportSnapshot.skipped` as a plain `Set<String>`.
- `bulkToast` (C3, `lib/l10n/bulk_message.dart`) is used by C3, C4, C5 and C9.
- `CardRepository.undoCardDeletion` changes from `batchId` to `batchIds` (C5): the only callers are `UndoCardDeletionUseCase`, `CardActionsController`, `card_trashed_snackbar_widget.dart` and the tests listed in C5.
- `TransferRejection` gains `previewFailed` (C6) and `tooLarge` (C7); `importProblem()` handles both; any new exhaustive switch over it must too.
- `ImportSummary.writtenIds` / `CardImportResult.writtenIds` (C9) are filled where `written` is; `import_result_skipped_test.dart` builds `ImportSummary` without it (defaults to `const []`).

**Order and conflicts**

- C3 and C5 both rewrite `showCardsTrashedSnackbar`; C5's version replaces C3's body and keeps `skipped`.
- C2, C3, C5, C6, C7 and C9 each add ARB keys; they are distinct keys, so conflicts are textual only. This cluster does not edit the card editor, so it should not collide with the editor cluster.
- `card_import_controller.dart` is touched by C6 (`readSource`, `previewRows`), C8 (the `Ok` branch of `readSource`, new `_read`) and C9 (`undoImport`). Apply in the order C6, C8, C9.
- `import_mapping_section_widget.dart` is touched by C6 (banner) and C8 (subtitle): disjoint lines.
- `card_import_screen_test.dart` and `card_import_controller_test.dart` collect tests from C6-C9; imports are additive.

**Goldens that may move (Linux container only)**

- Moved: `test/features/transfer/presentation/goldens/import_mapping_no_header_{light,dark}.png` (C8); `import_partial_{light,dark}.png` (C9, the Undo import button).
- New: `import_too_large_{light,dark}.png` (C7).
- Not moved: `card_list_trashed_*` (one-card toast), `card_list_trash_dialog_*` and `card_editor_trash_dialog_*` (single-card dialogs keep "Move to Trash"), `export_*`, `import_mapping_*`, `import_preview_*`.
- Spec §5 lists "the too-large import state" and "the Undo import result" as the new goldens: those are `import_too_large_*` (new) and `import_partial_*` (moved).

**Docs and detail files left for the branch-level docs task** (not edited above, to avoid colliding with other clusters)

- `docs/shared/ui/screen-handoff/07-card-list.md`: the `trashed` row (line 44) becomes "One or several cards: Undo for 8 seconds puts them all back (FE-B1 D3, D14; SP2a 2.20)"; the Copy line (101) gains "Move {n} cards to Trash" on the confirm, the "{n} were already gone" suffix and "{n} cards already have 10 tags; nothing was tagged."; add a bullet for SP2a 2.19-2.21.
- `docs/shared/ui/screen-handoff/11-card-import.md`: the too-large state, the Undo import row (on `success` and `partial`), the header default, the "Show all" sheet; and its row in `00-index.md`.
- `docs/shared/ui/screen-handoff/12-card-export.md`: the stale-selection row now means "every selected card is gone"; the toast names skipped cards.
- UI-base register rows for the
