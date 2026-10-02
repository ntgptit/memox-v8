# Critique 2026-10-02 (P1s and single-screen P2s) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the three P1s of the 2026-10-02 critique (21 untrue summary copy, 30/32 sign-out trap, 11 silent import skips) and its single-screen P2s (16a–19 hint glyphs, 22 bar contrast, 01 due strip, 07 flag colour, 32 action rows, 27 offline tone, 11 source picker).

**Architecture:** Presentation changes in each feature, plus four non-UI changes: a `cancelSignOut()` on the account coordinator (`lib/core/auth`), the card import repository naming the drafts it skipped, `ImportSummary` carrying the skipped rows, and `MxStackedDayBars` dropping its fades (`lib/shared`, owner-approved F10). ARB keys are edited in both files, then `flutter gen-l10n`.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, Drift, ARB l10n (`flutter gen-l10n`), flutter_test with `libraryTest` / `accountTest` / `pumpLibraryScreen` / `pumpMx`.

**Spec:** `docs/superpowers/specs/2026-10-02-critique2-fixes-design.md` (approved 2026-10-02, rulings F1–F10).

## Plan rulings (where the plan settles what the spec left open)

The owner sees these when approving the plan; the executor treats them as binding.

- **R1 (§3.1).** The facts card shows only where the hero draws no stats (reset, contentDeleted, saveError; never a finished session), so `summaryFactLearnedSub`, `summaryFactReviewedSub` and `summaryFactWrongCameBack` lose their last reader and are removed from both ARBs, not kept "for later" (CLAUDE.md: no speculative structure).
- **R2 (§3.4).** One "Skipped rows" list under the counts, in source order, each row drawn by the preview's own `ImportPreviewRowWidget` (number, term, meaning, the reason, the mark), instead of two lists under the two count rows. The row already says why it was skipped, so two headed lists would repeat the count labels. Rows the commit's re-check dropped (a card added since the preview) are listed too, as "Already in this deck". The list shows for any result with skipped rows, `none` included.
- **R3 (§3.7).** The learning series uses `derivedColors.statusLearningInk` in both themes. The token test already holds it at 4.5:1 on every ground in light and dark, so one colour path replaces "ink in light, amber in dark".
- **R4 (§3.2).** The layer offers Cancel on a sign-out only once it has stopped (an error, or stuck), not while it runs: a cancel queued behind a running push would land after the sign-out moved on.
- **R5 (§3.11).** `importPickAction` loses its only reader (the empty state's button) and is removed; tests that tapped it tap the "Choose a file" card.
- **R6 (§3.8).** "Plain ink" is `colors.onSurface`, the ink the editor's flag button uses.

## Global Constraints

- Shared and core code change only as the spec says: `MxStackedDayBars` loses its past-day fades (F10); `AccountCoordinator` gains `cancelSignOut()`. No other change to `lib/core` or `lib/shared`.
- BR-STUDY-068: the due strip states its total and the overdue and today halves; New is not in it.
- BR-TRANSFER-002: a blank row is ignored, not skipped; it is never listed.
- BR-TRANSFER-003: the duplicate rule is unchanged; only what the result says changes.
- Auth #8/#9/#22: a cancelled sign-out validates the session like a cancelled switch: online it goes Ready and sync resumes, offline it stays Validating until the reconnect.
- Copy, verbatim:
  - `summaryFactKeptSub`: en "Kept in the history", vi "Đã lưu trong lịch sử";
  - `accountSignOutStoppedOffline`: en "No connection. Nothing has been removed yet.", vi "Không có mạng. Chưa có gì bị xoá.";
  - `accountSignOutHint`: en "Removes this phone's data · sign in again to get it back", vi "Xoá dữ liệu trên máy này · đăng nhập lại để lấy lại";
  - `importSkippedHeader`: en "Skipped rows", vi "Dòng bị bỏ qua";
  - `importSkippedShowAll`: en "Show all {count}", vi "Xem tất cả {count}";
  - `importSkipNote`: en "Duplicates are skipped by the case-insensitive term + meaning.", vi "Dòng trùng được xác định theo thuật ngữ + nghĩa, không phân biệt hoa thường.";
  - removed from both ARBs: `summaryFactLearnedSub`, `summaryFactReviewedSub`, `summaryFactWrongCameBack`, `importPickAction`.
- Every new or edited en ARB key keeps an `@key` with a `description` (`test/app/l10n_test.dart`); a placeholder key declares its placeholder.
- After any ARB edit: `flutter gen-l10n`.
- The guard counts logical lines: a file over 400 warns and fails the gate; `build()` over 100 lines fails. New tests go in new files where the target file is near 400.
- Goldens regenerate only in the Linux container with `TZ=UTC`.
- Ledger and logs live in `.superpowers/sdd/2026-10-02-critique2-fixes/`.
- Every commit message ends with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01WHcLQhgp72txzYGsDLm7JX`.

## Review Focus

1. 30/32 a sign-out stopped offline, then the network comes back before Cancel is tapped: the reconnect resumes the sign-out (existing #39 behaviour); a Cancel tapped after it moved past `started` is refused and the layer follows the state, no crash. Pinned in Task 2 (refusal) and by the existing `#39 offline … waits` test.
2. 30/32 the SDK lost the session while the sign-out waited (`currentUserId` null at `started`): Cancel ends in REAUTH_REQUIRED with the data kept, as `cancelSwitch` does. Pinned in Task 2.
3. 11 a commit-time duplicate (a card added between preview and commit): it is listed as "Already in this deck", and the counts match the list. Pinned in Task 5.
4. 11 the "Choose a file" card tapped while Paste is selected with text typed: it switches to file and opens the picker; a cancelled picker leaves the file option chosen with no source. Pinned in Task 7.
5. 27 a network failure with changes waiting: the note shows and Sync now is outline, not primary. Pinned in Task 12.

---

### Task 1: Session summary per outcome (21, F1, R1)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_hero_widget.dart:79-89,191-256`
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_facts_widget.dart:13-96`
- Modify: `lib/l10n/app_en.arb` (`summaryFactLearnedSub`, `summaryFactReviewedSub`, `summaryFactWrongCameBack` removed; `summaryFactKeptSub` added), `lib/l10n/app_vi.arb` (same)
- Test: `test/features/study/presentation/session_summary_truth_test.dart` (new)

**Interfaces:** none shared.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/presentation/session_summary_truth_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 21 says only what the session did (critique 2026-10-02, F1): no
// "came back in later rounds" for a session that had none, and no
// "Schedules updated" success under an ended or failed hero.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome,
) => pumpLibraryScreen(
  tester,
  env,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: () {},
    onStudyDeck: () {},
  ),
);

void main() {
  for (final (outcome, reason) in [
    (SummaryOutcome.leftEarly, SessionEndReason.userExit),
    (SummaryOutcome.interrupted, SessionEndReason.interrupted),
  ]) {
    libraryTest('${outcome.name} with wrong turns: no came-back note', (
      tester,
      env,
    ) async {
      await _pump(
        tester,
        env,
        summaryView(status: SessionStatus.abandoned, reason: reason),
        outcome,
      );

      expect(find.text(_en.summaryWrongExplained), findsNothing);
    });
  }

  libraryTest('a failed save: the facts say the answers are kept, on a '
      'neutral tile, and the turns line says nothing came back', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.failed,
        reason: SessionEndReason.persistenceError,
      ),
      SummaryOutcome.saveError,
    );

    final finished = find.widgetWithText(MxListRow, _en.summaryFactReviewed);
    expect(
      find.descendant(of: finished, matching: find.text(_en.summaryFactKeptSub)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<MxIconTile>(
            find.descendant(of: finished, matching: find.byType(MxIconTile)),
          )
          .tone,
      MxIconTileTone.tinted,
    );
    expect(find.text(_en.summaryFactWrongSub(23)), findsOneWidget);
    expect(find.text(_en.summaryWrongExplained), findsNothing);
  });

  libraryTest('a reset learning session says the same', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        kind: SessionKind.learning,
        status: SessionStatus.invalidated,
        reason: SessionEndReason.schedulerReset,
        summary: const SessionSummary(
          cardCount: 12,
          learnedCardCount: 4,
          wrongTurnCount: 2,
          answeredCardCount: 9,
          turnCount: 14,
          cardLimit: 20,
        ),
      ),
      SummaryOutcome.reset,
    );

    expect(
      find.descendant(
        of: find.widgetWithText(MxListRow, _en.summaryFactLearned),
        matching: find.text(_en.summaryFactKeptSub),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.summaryFactWrongSub(14)), findsOneWidget);
  });
}
```

Add the `SessionKind` import (`package:memox/features/study_mode/domain/models/session_kind_model.dart`). The existing test `'a finished review: … wrong turns, explained'` (session_summary_test.dart:47) stays and pins that a finished session keeps the note.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/session_summary_truth_test.dart`
Expected: compile error, `summaryFactKeptSub` isn't defined.

- [ ] **Step 3: ARB keys**

`lib/l10n/app_en.arb`: delete the `summaryFactLearnedSub`, `summaryFactReviewedSub` and `summaryFactWrongCameBack` entries with their `@` blocks; after `@summaryFactWrongSub` add:

```json
  "summaryFactKeptSub": "Kept in the history",
  "@summaryFactKeptSub": {
    "description": "Screen handoff 21 (critique 2026-10-02, F1): the finished-cards fact's sub-line after an ended or failed session; its answers are kept, nothing is scheduled by it."
  },
```

`lib/l10n/app_vi.arb`: delete the three keys; after `summaryFactWrongSub` add `"summaryFactKeptSub": "Đã lưu trong lịch sử",`.

Run: `flutter gen-l10n`
Expected: exit 0.

- [ ] **Step 4: The hero's note only after a finished session**

In `session_summary_hero_widget.dart`, pass the tone to `_Stats`:

```dart
            _Stats(
              view: view,
              summary: summary,
              // Every body with stats states the finished count (bold, or
              // "The {n} cards you finished…" when left early) but an
              // interrupted one.
              isFinishedStated: outcome != SummaryOutcome.interrupted,
              // Only a finished session had later rounds (critique
              // 2026-10-02, F1).
              isWrongExplained: tone == SummaryTone.success,
            ),
```

In `_Stats`, add the field after `isFinishedStated`:

```dart
  /// Wrong cards came back in later rounds only in a finished session.
  final bool isWrongExplained;
```

add `required this.isWrongExplained,` to its constructor, and change the note's condition:

```dart
        if (isWrongExplained && summary.wrongTurnCount > 0)
```

- [ ] **Step 5: The facts say what was kept**

In `session_summary_facts_widget.dart`, replace the class doc comment with:

```dart
/// Screen 21's facts (kit Facts), shown only where the hero draws no stats:
/// an ended or failed session. What it finished is kept in the history, what
/// was answered, and the wrong turns out of all (critique 2026-10-02, F1).
```

and the first and last rows with:

```dart
              MxListRow(
                title: isLearning
                    ? l10n.summaryFactLearned
                    : l10n.summaryFactReviewed,
                subtitle: l10n.summaryFactKeptSub,
                leading: const MxIconTile(icon: AppIcons.learned),
                trailing: Text(
                  l10n.studyCount(summaryFinishedCount(view, summary)),
                  style: styles.factValue(colors.onSurface),
                ),
              ),
```

```dart
              MxListRow(
                title: l10n.summaryFactWrong,
                // The kit wraps this line; the row's own subtitle is one.
                meta: Text(
                  l10n.summaryFactWrongSub(turns),
                  style: styles.noteText,
                ),
```

(the rest of the wrong row is unchanged).

- [ ] **Step 6: Run the summary tests**

Run: `flutter test test/features/study/presentation/session_summary_truth_test.dart test/features/study/presentation/session_summary_test.dart test/features/study/presentation/session_ending_state_test.dart`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n lib/features/study test/features/study
git commit -m "fix(study): screen 21 says only what the session did (critique 2026-10-02, F1)"
```

---

### Task 2: The coordinator cancels a stopped sign-out (30/32, F2)

**Files:**
- Modify: `lib/core/auth/account_coordinator_leave.dart` (after `signOut`, line ~33)
- Test: `test/core/auth/account_coordinator_signout_cancel_test.dart` (new)

**Interfaces:**
- Produces: `Future<void> AccountCoordinator.cancelSignOut()` (extension `AccountLeaving`); throws `StateError` unless the pending transition is a sign-out at `TransitionStage.started`.

- [ ] **Step 1: Write the failing tests**

Create `test/core/auth/account_coordinator_signout_cancel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../support/auth_fakes.dart';

// Critique 2026-10-02 (F2): a sign-out stopped before anything on the
// device was removed goes back to the account as it was (auth spec #39a).
void main() {
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// Account X with two unsent changes, its sign-out stopped offline.
  Future<String> stoppedOffline() async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 5
      ..pending = 2;
    world.network.goOffline();
    await world.coordinator.signOut();
    expect(world.state, isA<Transitioning>());
    return x;
  }

  test('offline: X keeps everything, waits for the network, then is ready '
      'and syncing', () async {
    final x = await stoppedOffline();

    await world.coordinator.cancelSignOut();

    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
    expect(world.state, isA<Validating>());

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.sync.paused, isFalse);
    expect(world.device.resets, 0);
  });

  test('back online before the cancel: X is ready at once', () async {
    final x = await stoppedOffline();
    // The server answers again; no reconnect event has resumed the sign-out.
    world.server.offline = false;

    await world.coordinator.cancelSignOut();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.sync.paused, isFalse);
  });

  test("with the SDK's session gone meanwhile, X waits for a sign-in with "
      'its data kept', () async {
    await stoppedOffline();
    world.gateway.dropSession();

    await world.coordinator.cancelSignOut();

    expect(world.state, isA<ReauthRequired>());
    expect(world.device.resets, 0);
  });

  test('nothing to cancel is refused', () async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();

    await expectLater(world.coordinator.cancelSignOut(), throwsStateError);
  });
}
```

If `world.gateway.dropSession()` emits a `userIds` event that the coordinator acts on while a transition is pending, it is ignored (`_onUserId` returns when a transition exists, account_coordinator.dart:285), so the cancel sees `currentUserId == null`.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/auth/account_coordinator_signout_cancel_test.dart`
Expected: compile error, `cancelSignOut` isn't defined.

- [ ] **Step 3: Implement**

In `account_coordinator_leave.dart`, after `signOut`:

```dart
  /// A sign-out stopped before anything on this device was removed (stage
  /// `started`: the SDK still holds X, nothing reset) goes back to X as it
  /// was: the record goes, the gate opens, and the session is checked again,
  /// which resumes sync (#9) or, offline, waits for the network (#8). With
  /// X's session gone meanwhile, X is lost as a cancelled switch's source is
  /// (#22; critique 2026-10-02, F2).
  Future<void> cancelSignOut() => _serial(() async {
    final t = await _store.transition();
    if (t == null ||
        t.kind != TransitionKind.signOut ||
        t.stage != TransitionStage.started) {
      throw StateError('No sign-out to cancel before it signs out');
    }
    final userId = _gateway.currentUserId;
    await _drop(t);
    if (userId == t.sourceUserId) return _validate();
    return _lost(sessionInvalid: true);
  });
```

- [ ] **Step 4: Run the auth tests**

Run: `flutter test test/core/auth`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth test/core/auth
git commit -m "feat(auth): cancel a sign-out stopped before anything is removed (critique 2026-10-02, F2)"
```

---

### Task 3: The layer offers Cancel on a stopped sign-out (30/32, F2, R4)

**Files:**
- Modify: `lib/features/account/presentation/states/account_step_state.dart:72-76`
- Modify: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart:56-95,165-200`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`accountSignOutStoppedOffline`)
- Test: `test/features/account/presentation/account_step_state_test.dart`, `test/features/account/presentation/account_transition_layer_test.dart`

**Interfaces:**
- Consumes: `AccountCoordinator.cancelSignOut()` (Task 2).
- Produces: `bool canCancelSignOut(AccountTransition t)` in `account_step_state.dart`.

- [ ] **Step 1: Write the failing tests**

In `account_step_state_test.dart`, after `'a switch can be cancelled only before the target signs in'`:

```dart
  test('a sign-out can be cancelled only before it signs out (critique '
      '2026-10-02, F2)', () {
    expect(
      canCancelSignOut(
        transitionOf(TransitionKind.signOut, TransitionStage.started),
      ),
      isTrue,
    );
    expect(
      canCancelSignOut(
        transitionOf(TransitionKind.signOut, TransitionStage.signedOut),
      ),
      isFalse,
    );
    expect(
      canCancelSignOut(
        transitionOf(TransitionKind.delete, TransitionStage.started),
      ),
      isFalse,
    );
  });
```

In `account_transition_layer_test.dart`, change the test `'a sign-out stopped offline offers to go on and lose the changes'` to:

```dart
  libraryTest('a sign-out stopped offline says nothing is removed yet, and '
      'offers to lose the changes or cancel (critique 2026-10-02, F2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(TransitionKind.signOut, TransitionStage.started),
            error: const OfflineFailure(cause: 'test'),
          ),
        ),
        unsentCountProvider.overrideWith((ref) async => 2),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountSignOutStoppedOffline), findsOneWidget);
    expect(find.text(_en.accountLayerOffline), findsNothing);
    expect(find.text(_en.accountSignOutLosing(2)), findsOneWidget);
    expect(find.text(_en.commonCancel), findsOneWidget);
  });

  libraryTest('a sign-out still sending offers no Cancel (R4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(TransitionKind.signOut, TransitionStage.started),
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.commonCancel), findsNothing);
  });
```

and add, after `'no connection says the data is safe, and Retry carries on'`:

```dart
  accountTest('Cancel on a sign-out stopped offline keeps the account and '
      'everything on the phone (critique 2026-10-02, F2)', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    world.device.pending = 2;
    await _onThemePage(tester, env, world);
    world.network.goOffline();
    await world.coordinator.signOut();
    await _settle(tester);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(world.state, isA<Validating>());
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/account/presentation/account_step_state_test.dart test/features/account/presentation/account_transition_layer_test.dart`
Expected: compile errors, `canCancelSignOut` and `accountSignOutStoppedOffline` aren't defined.

- [ ] **Step 3: ARB key**

`lib/l10n/app_en.arb`, after the `@accountLayerOffline` block:

```json
  "accountSignOutStoppedOffline": "No connection. Nothing has been removed yet.",
  "@accountSignOutStoppedOffline": {
    "description": "Transition layer (critique 2026-10-02, F2): a sign-out stopped offline before anything on the phone was removed; it can be cancelled or finished with the loss."
  },
```

`lib/l10n/app_vi.arb`, after `accountLayerOffline`: `"accountSignOutStoppedOffline": "Không có mạng. Chưa có gì bị xoá.",`

Run: `flutter gen-l10n`
Expected: exit 0.

- [ ] **Step 4: The predicate**

In `account_step_state.dart`, after `canCancelSwitch`:

```dart
/// Critique 2026-10-02 (F2): a sign-out goes back to where it started only
/// before the SDK signs out, while nothing on this device is gone.
bool canCancelSignOut(AccountTransition t) =>
    t.kind == TransitionKind.signOut && t.stage == TransitionStage.started;
```

- [ ] **Step 5: The layer**

In `_LayerPage.build`, replace the `canCancel` line with:

```dart
    final transition = view.transition;
    final isStopped = view.error != null || view.isStuck;
    // A sign-out cancels only once it has stopped: one queued behind a
    // running push would land after it moved on (critique 2026-10-02, R4).
    final canCancel =
        (canCancelSwitch(transition) && !view.isStuck) ||
        (canCancelSignOut(transition) && isStopped);
```

change the Cancel button's `onPressed` to `() => unawaited(_cancel(context, ref, transition.kind))`, and `_cancel` to:

```dart
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    TransitionKind kind,
  ) async {
    final coordinator = ref.read(accountCoordinatorProvider);
    try {
      await (kind == TransitionKind.signOut
          ? coordinator?.cancelSignOut()
          : coordinator?.cancelSwitch());
    } on Failure catch (error) {
      if (context.mounted) {
        showMxSnackbar(context, message: context.l10n.failure(error));
      }
    } on StateError {
      // The transition moved past where it can go back meanwhile; the layer
      // follows.
      return;
    }
  }
```

In `_Progress.build`, replace the banner's `message:` expression with `message: _stoppedMessage(l10n, error),` and add to `_Progress`:

```dart
  /// What stopped it. A sign-out stopped offline has removed nothing yet,
  /// beside its loss button (critique 2026-10-02, F2).
  String _stoppedMessage(AppLocalizations l10n, Failure? error) {
    if (view.isStuck) return l10n.accountLayerStuck;
    if (error is! OfflineFailure) return l10n.accountLayerFailed;
    return view.transition.kind == TransitionKind.signOut
        ? l10n.accountSignOutStoppedOffline
        : l10n.accountLayerOffline;
  }
```

with `import 'package:memox/l10n/generated/app_localizations.dart';`.

- [ ] **Step 6: Run the account tests**

Run: `flutter test test/features/account test/core/auth`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n lib/features/account test/features/account
git commit -m "feat(account): Cancel on a sign-out stopped before anything is removed (critique 2026-10-02, F2)"
```

---

### Task 4: Account rows and the Sign out confirm (32, F3)

**Files:**
- Modify: `lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart:11-33,72-110`
- Modify: `lib/features/account/presentation/screens/account_screen.dart:59-70,152-170`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`accountSignOutHint`)
- Test: `test/features/account/presentation/account_screen_test.dart`

**Interfaces:** `confirmAccountStep` and `AccountConfirmDialogWidget` gain `bool isWarning = false`.

- [ ] **Step 1: Write the failing tests**

In `account_screen_test.dart` (import `package:memox/shared/widgets/mx_sheet_actions.dart`), extend the first test's loop:

```dart
    for (final label in [
      _en.accountSwitch,
      _en.accountSignOut,
      _en.accountDelete,
    ]) {
      expect(_row(tester, label).isEnabled, isTrue);
      // Each opens a dialog: no chevron (critique 2026-10-02).
      expect(_row(tester, label).isAction, isTrue);
    }
    expect(
      _en.accountSignOutHint,
      "Removes this phone's data · sign in again to get it back",
    );
    expect(find.text(_en.accountSignOutHint), findsOneWidget);
```

add to `'Sign out offline with unsent changes names the loss'`:

```dart
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).isDestructive,
      isTrue,
    );
```

and a new test:

```dart
  accountTest('Sign out online confirms in warning: nothing is lost, but '
      'the phone is cleared (critique 2026-10-02, F3)', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountSignOutTitle), findsOneWidget);
    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect((actions.isWarning, actions.isDestructive), (true, false));
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/account/presentation/account_screen_test.dart`
Expected: FAIL: `isAction` false, the hint text differs, `isWarning` false.

- [ ] **Step 3: ARB**

`accountSignOutHint`: en "Removes this phone's data · sign in again to get it back" (description "Screen 32: under Sign out, what it does (Account UI spec §9.1; critique 2026-10-02, F3)."); vi "Xoá dữ liệu trên máy này · đăng nhập lại để lấy lại".

Run: `flutter gen-l10n`
Expected: exit 0.

- [ ] **Step 4: The dialog takes a warning tone**

In `account_confirm_dialog_widget.dart`, add `bool isWarning = false,` to `confirmAccountStep` after `isDestructive`, pass `isWarning: isWarning,` to the widget; in `AccountConfirmDialogWidget` add `this.isWarning = false,` to the constructor, the field

```dart
  /// A confirm that changes a lot but loses nothing (critique 2026-10-02).
  final bool isWarning;
```

and `isWarning: isWarning,` to its `MxSheetActions`.

- [ ] **Step 5: The screen**

In `account_screen.dart`, `command()` gets `isAction: true,` after `icon: icon,` with the comment `// Each opens a dialog: no chevron (critique 2026-10-02).`; in `_signOut` add `isWarning: !isLosing,` after `isDestructive: isLosing,`.

- [ ] **Step 6: Run the account tests**

Run: `flutter test test/features/account`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n lib/features/account test/features/account
git commit -m "fix(account): Sign out names its outcome and confirms in warning; command rows show no chevron (critique 2026-10-02, F3)"
```

---

### Task 5: The import result carries its skipped rows (11, F4, R2)

**Files:**
- Modify: `lib/features/card/domain/models/card_import_result_model.dart`
- Modify: `lib/features/card/data/repositories/card_transfer_repository_impl.dart:56-74`
- Modify: `lib/features/transfer/domain/models/import_preview_model.dart:59-66`
- Modify: `lib/features/transfer/domain/models/import_summary_model.dart`
- Modify: `lib/features/transfer/domain/usecases/commit_import_use_case.dart`
- Test: `test/features/card/data/card_transfer_test.dart`, `test/features/transfer/domain/import_use_cases_test.dart`

**Interfaces:**
- Produces: `CardImportResult({required int written, required List<int> skippedIndexes})` with getter `int skippedDuplicates`; `List<ImportRow> ImportPreview.rowsToWrite({required bool includeDuplicates})`; `ImportSummary({required int written, required int blank, required List<ImportRow> skipped})` with getters `duplicatesSkipped`, `invalid`, `kind` (unchanged meaning).

- [ ] **Step 1: Write the failing tests**

In `card_transfer_test.dart`, after `expect((result.written, result.skippedDuplicates), (1, 2));` (line ~182) add:

```dart
      // The drafts the commit dropped, by their place in the batch
      // (critique 2026-10-02, F4).
      expect(result.skippedIndexes, [0, 2]);
```

In `import_use_cases_test.dart`, at the end of `'pasted rows become cards; …'` add:

```dart
    // Each skipped row, in source order, with why (critique 2026-10-02, F4);
    // the blank row 5 is ignored, not listed.
    expect(
      [for (final row in summary.skipped) (row.rowNumber, row.kind)],
      [
        (3, ImportRowKind.invalid),
        (4, ImportRowKind.duplicateInDeck),
        (6, ImportRowKind.duplicateInSource),
      ],
    );
```

and at the end of `'rows that became duplicates after the preview end on none'`:

```dart
    // The commit's re-check names the row it dropped.
    expect(
      [for (final row in summary.skipped) (row.rowNumber, row.kind)],
      [(2, ImportRowKind.duplicateInDeck)],
    );
    expect(summary.duplicatesSkipped, 1);
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/card/data/card_transfer_test.dart test/features/transfer/domain/import_use_cases_test.dart`
Expected: compile errors, `skippedIndexes` and `skipped` aren't defined.

- [ ] **Step 3: The repository names what it skipped**

`card_import_result_model.dart`:

```dart
/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({required this.written, required this.skippedIndexes});

  final int written;

  /// The places, in the drafts handed in, of those the duplicate policy
  /// dropped inside the commit (BR-TRANSFER-003), in order.
  final List<int> skippedIndexes;

  int get skippedDuplicates => skippedIndexes.length;
}
```

In `card_transfer_repository_impl.dart`, replace the write loop and the result:

```dart
      final taken = await _dao.foldedPairs(deckId);
      final skipped = <int>[];
      for (final (index, draft) in drafts.indexed) {
        final pair = (front: foldText(draft.front), back: foldText(draft.back));
        if (!includeDuplicates && taken.contains(pair)) {
          skipped.add(index);
          continue;
        }
        taken.add(pair);
        await _cards.insertCard(deckId, draft, at);
      }
      final written = drafts.length - skipped.length;
      if (written > 0 && contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(CardImportResult(written: written, skippedIndexes: skipped));
```

- [ ] **Step 4: The preview's rows to write**

In `import_preview_model.dart`, replace `draftsToWrite` with:

```dart
  /// The rows a commit writes, in source order (A4).
  List<ImportRow> rowsToWrite({required bool includeDuplicates}) => [
    for (final row in rows)
      if (row.kind == ImportRowKind.ready ||
          (includeDuplicates && row.isDuplicate))
        row,
  ];

  /// The drafts a commit hands to the card feature, in source order.
  List<CardDraft> draftsToWrite({required bool includeDuplicates}) => [
    for (final row in rowsToWrite(includeDuplicates: includeDuplicates))
      row.draft!,
  ];
```

- [ ] **Step 5: The summary holds the rows**

`import_summary_model.dart` (keep `enum ImportSummaryKind` and its doc as they are):

```dart
/// What an import did (UC-TRANSFER-001 step 8): the cards written, the blank
/// rows ignored, and every row skipped, with why.
final class ImportSummary {
  const ImportSummary({
    required this.written,
    required this.blank,
    required this.skipped,
  });

  final int written;
  final int blank;

  /// The rows not written, in source order: the invalid ones, the duplicates
  /// the preview found when they were not included, and those the commit's
  /// own re-check found, marked as already in the deck (BR-TRANSFER-003;
  /// critique 2026-10-02, F4). A blank row is ignored, not skipped
  /// (BR-TRANSFER-002).
  final List<ImportRow> skipped;

  int get duplicatesSkipped => skipped.where((row) => row.isDuplicate).length;

  int get invalid =>
      skipped.where((row) => row.kind == ImportRowKind.invalid).length;

  /// `none`: the commit found nothing left to write (spec §8.1 ruling 1).
  /// A blank row is ignored, not skipped, so it alone keeps `success`.
  ImportSummaryKind get kind {
    if (written == 0) return ImportSummaryKind.none;
    if (skipped.isNotEmpty) return ImportSummaryKind.partial;
    return ImportSummaryKind.success;
  }
}
```

with `import 'package:memox/features/transfer/domain/models/import_preview_model.dart';`.

- [ ] **Step 6: The use case maps the commit back to rows**

In `commit_import_use_case.dart`:

```dart
    final toWrite = preview.rowsToWrite(includeDuplicates: includeDuplicates);
    if (toWrite.isEmpty) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importCards(
      deckId: deckId,
      drafts: [for (final row in toWrite) row.draft!],
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        ImportSummary(
          written: value.written,
          blank: preview.blank,
          skipped: _skipped(
            preview,
            toWrite,
            value.skippedIndexes,
            includeDuplicates: includeDuplicates,
          ),
        ),
      ),
```

(the `Rejected` arms unchanged), and add to the class:

```dart
  /// What the preview left out, and what the commit's re-check dropped as
  /// already in the deck, in source order (critique 2026-10-02, F4).
  static List<ImportRow> _skipped(
    ImportPreview preview,
    List<ImportRow> toWrite,
    List<int> dropped, {
    required bool includeDuplicates,
  }) {
    final droppedRows = {for (final index in dropped) toWrite[index].rowNumber};
    return [
      for (final row in preview.rows)
        if (row.kind == ImportRowKind.invalid ||
            (!includeDuplicates && row.isDuplicate))
          row
        else if (droppedRows.contains(row.rowNumber))
          ImportRow(
            rowNumber: row.rowNumber,
            kind: ImportRowKind.duplicateInDeck,
            draft: row.draft,
          ),
    ];
  }
```

Update the class doc's last line to "…and the result with every row skipped (critique 2026-10-02, F4)."

- [ ] **Step 7: Run the transfer and card data tests**

Run: `flutter test test/features/transfer test/features/card/data`
Expected: all pass (`ImportResultWidget` reads `duplicatesSkipped`/`invalid`/`kind`, which keep their meaning).

- [ ] **Step 8: Commit**

```bash
git add lib/features/card lib/features/transfer test/features/card test/features/transfer
git commit -m "feat(transfer): the import result carries the rows it skipped (critique 2026-10-02, F4)"
```

---

### Task 6: The result lists the skipped rows (11, F4, R2)

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`importSkippedHeader`, `importSkippedShowAll`, `importSkipNote`)
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:41-43`
- Test: `test/features/transfer/presentation/import_result_skipped_test.dart` (new)

**Interfaces:** consumes `ImportSummary.skipped` (Task 5) and `ImportPreviewRowWidget(row:)`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transfer/presentation/import_result_skipped_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Screen 11's result names every row it skipped and why (critique
// 2026-10-02, F4; UC-TRANSFER-001 step 8).

final _en = lookupAppLocalizations(const Locale('en'));

ImportRow _invalid(int row) => ImportRow(
  rowNumber: row,
  kind: ImportRowKind.invalid,
  draft: CardDraft(front: 'term $row', back: ''),
  reason: CardRejection.blankContent,
);

ImportRow _duplicate(int row) => ImportRow(
  rowNumber: row,
  kind: ImportRowKind.duplicateInDeck,
  draft: CardDraft(front: 'dup $row', back: 'meaning $row'),
);

Widget _host(ImportSummary summary) => Scaffold(
  body: SingleChildScrollView(
    child: ImportResultWidget(state: CardImportDone(summary)),
  ),
);

void main() {
  libraryTest('a partial import lists its skipped rows with why, five at '
      'first, all after Show all', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        ImportSummary(
          written: 3,
          blank: 1,
          skipped: [
            for (var row = 2; row <= 5; row++) _invalid(row),
            for (var row = 6; row <= 8; row++) _duplicate(row),
          ],
        ),
      ),
    );

    expect(find.text(_en.importSkippedHeader.toUpperCase()), findsOneWidget);
    expect(find.byType(ImportPreviewRowWidget), findsNWidgets(5));
    expect(find.text('term 2'), findsOneWidget);
    expect(find.text(_en.importRowBackEmpty), findsNWidgets(4));
    expect(find.text('dup 7'), findsNothing);

    final showAll = find.text(_en.importSkippedShowAll(7));
    await tester.ensureVisible(showAll);
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(find.byType(ImportPreviewRowWidget), findsNWidgets(7));
    expect(find.text(_en.importRowDuplicateInDeck), findsNWidgets(3));
    expect(showAll, findsNothing);
  });

  libraryTest('five or fewer skipped rows need no Show all', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(ImportSummary(written: 1, blank: 0, skipped: [_invalid(3)])),
    );

    expect(find.byType(ImportPreviewRowWidget), findsOneWidget);
    expect(find.textContaining('Show all'), findsNothing);
  });

  libraryTest('a clean import lists nothing', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(const ImportSummary(written: 2, blank: 0, skipped: [])),
    );

    expect(find.byType(ImportPreviewRowWidget), findsNothing);
    expect(find.text(_en.importSkippedHeader.toUpperCase()), findsNothing);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/transfer/presentation/import_result_skipped_test.dart`
Expected: compile error, `importSkippedHeader` isn't defined.

- [ ] **Step 3: ARB**

`lib/l10n/app_en.arb`, after the `@importCountInvalid` block:

```json
  "importSkippedHeader": "Skipped rows",
  "@importSkippedHeader": {
    "description": "Import result (critique 2026-10-02, F4): the header over the rows the import skipped, each with its number and why."
  },
  "importSkippedShowAll": "Show all {count}",
  "@importSkippedShowAll": {
    "description": "Import result (critique 2026-10-02, F4): shows every skipped row past the first five.",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
```

`importSkipNote` en: "Duplicates are skipped by the case-insensitive term + meaning." (description unchanged).

`lib/l10n/app_vi.arb`, after `importCountInvalid`: `"importSkippedHeader": "Dòng bị bỏ qua",` and `"importSkippedShowAll": "Xem tất cả {count}",`; `importSkipNote`: "Dòng trùng được xác định theo thuật ngữ + nghĩa, không phân biệt hoa thường."

Run: `flutter gen-l10n`
Expected: exit 0.

- [ ] **Step 4: The list**

In `import_result_widget.dart`, in the `CardImportDone` column, after the counts block and before the note:

```dart
          if (summary.skipped.isNotEmpty)
            _SkippedRows(rows: summary.skipped),
```

and add at the end of the file (imports `import_preview_model.dart`, `import_preview_row_widget.dart`, `mx_button.dart`):

```dart
/// The rows the import skipped, each as the preview drew it: number, term,
/// meaning, why, and its mark (critique 2026-10-02, F4). The first
/// [shownRows] show; "Show all" opens the rest in place.
class _SkippedRows extends StatefulWidget {
  const _SkippedRows({required this.rows});

  final List<ImportRow> rows;

  static const int shownRows = 5;

  @override
  State<_SkippedRows> createState() => _SkippedRowsState();
}

class _SkippedRowsState extends State<_SkippedRows> {
  var _isShowingAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = widget.rows;
    final shown = _isShowingAll
        ? rows
        : rows.take(_SkippedRows.shownRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSkippedHeader,
          children: [for (final row in shown) ImportPreviewRowWidget(row: row)],
        ),
        if (shown.length < rows.length)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxButton(
              label: l10n.importSkippedShowAll(rows.length),
              tone: MxButtonTone.text,
              size: MxButtonSize.compact,
              onPressed: () => setState(() => _isShowingAll = true),
            ),
          ),
      ],
    );
  }
}
```

Update the class doc of `ImportResultWidget`: "…then what was added and skipped, and each skipped row with why (critique 2026-10-02, F4)."

- [ ] **Step 5: UC-TRANSFER-001 step 8**

Replace step 8's first line with: "8. Hệ thống hiện kết quả — số đã ghi, số trùng bỏ qua, số invalid bị loại, và từng dòng bị bỏ qua với số dòng và lý do (critique 2026-10-02) — với" (the rest of the step unchanged).

- [ ] **Step 6: Run the transfer tests**

Run: `flutter test test/features/transfer`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n lib/features/transfer test/features/transfer docs/features/transfer
git commit -m "feat(transfer): the import result lists each skipped row and why (critique 2026-10-02, F4)"
```

---

### Task 7: The file card opens the picker (11, F9, R5)

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart:108-118,177-189`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`importPickAction` removed)
- Modify (taps): `test/features/transfer/presentation/card_import_screen_test.dart`, `card_import_golden_test.dart`, `card_import_layout_test.dart`, `test/visual_audit/screens/features/transfer/screens/card_import_screen_visual_audit_test.dart`
- Test: `test/features/transfer/presentation/card_import_source_pick_test.dart` (new)

**Interfaces:** none.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transfer/presentation/card_import_source_pick_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../../support/library_harness.dart';

// Screen 11's source step picks a file from its "Choose a file" card; the
// empty state below carries no second button (critique 2026-10-02, F9).

final _en = lookupAppLocalizations(const Locale('en'));

Future<int Function()> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  ImportPickedFile? file,
}) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  var picks = 0;
  await pumpLibraryScreen(
    tester,
    env,
    CardImportScreen(
      deckId: deck.id,
      deckContext: (id, label) =>
          DeckContextHeaderWidget(deckId: id, currentLabel: label),
      onClose: () {},
      onViewCards: () {},
    ),
    overrides: [
      importFilePickerProvider.overrideWithValue(() async {
        picks++;
        return file;
      }),
    ],
  );
  return () => picks;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('the empty state has no button; the selected file card opens '
      'the picker', (tester, env) async {
    final picks = await _pump(
      tester,
      env,
      file: (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode('a,b'))),
    );

    expect(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.byType(MxButton),
      ),
      findsNothing,
    );
    await _tap(tester, _en.importSourceFile);

    expect(picks(), 1);
    expect(find.text('vocab.csv'), findsOneWidget);
  });

  libraryTest('from Paste, the file card switches to file and opens the '
      'picker; a cancelled picker leaves file chosen with no source', (
    tester,
    env,
  ) async {
    final picks = await _pump(tester, env);
    await _tap(tester, _en.importSourcePaste);
    await tester.enterText(find.byType(EditableText), 'a,b');
    await tester.pumpAndSettle();

    await _tap(tester, _en.importSourceFile);

    expect(picks(), 1);
    expect(find.text(_en.importPickTitle), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/transfer/presentation/card_import_source_pick_test.dart`
Expected: FAIL: the empty state has a button; the selected card's tap opens no picker (`picks()` 0).

- [ ] **Step 3: Implement**

In `import_source_section_widget.dart`, the file option:

```dart
                child: ImportSourceOptionWidget(
                  icon: AppIcons.fileUp,
                  label: l10n.importSourceFile,
                  hint: l10n.importSourceFileHint,
                  isSelected: !isPaste,
                  // The card picks the file, selected or not (critique
                  // 2026-10-02, F9).
                  onSelected: canChange
                      ? () {
                          widget.onChooseKind(CardImportSourceKind.file);
                          widget.onChooseFile();
                        }
                      : null,
                ),
```

and the empty state loses `actionLabel` and `onAction`:

```dart
        // MxEmptyState draws its own surface (critique 2026-09-30 part 3d-2,
        // E10); the "Choose a file" card above picks (critique 2026-10-02,
        // F9).
        MxEmptyState(
          icon: AppIcons.fileUp,
          title: l10n.importPickTitle,
          body: l10n.importPickBody,
          isCompact: true,
        ),
```

Remove `importPickAction` (and `@importPickAction`) from `app_en.arb` and `importPickAction` from `app_vi.arb`; run `flutter gen-l10n`.

- [ ] **Step 4: The tests that tapped the old button**

Replace every `_en.importPickAction` with `_en.importSourceFile` in `card_import_screen_test.dart` (11 places), `card_import_golden_test.dart` (4), `card_import_layout_test.dart` (1) and the visual audit test (2; its guard `if (find.text(_en.importPickAction).evaluate().isEmpty) return;` becomes `if (find.text(_en.importPickTitle).evaluate().isEmpty) return;`, since the file card's label stays on screen after a pick).

Run: `grep -rn importPickAction lib test`
Expected: no hits (the generated l10n files included, after `flutter gen-l10n`).

- [ ] **Step 5: Run the transfer tests**

Run: `flutter test test/features/transfer test/visual_audit/screens/features/transfer --exclude-tags golden`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/transfer test/features/transfer test/visual_audit
git commit -m "fix(transfer): the Choose a file card opens the picker; the empty state drops its button (critique 2026-10-02, F9)"
```

---

### Task 8: Footer hint glyphs (16a–19, F7)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart:112-117`, `study_match_widget.dart:172-175`, `study_guess_widget.dart:184-189`, `study_recall_widget.dart:226-233`
- Test: `test/features/study/presentation/study_self_assess_test.dart`, `study_match_test.dart`, `study_guess_test.dart`, `study_recall_test.dart`

**Interfaces:** none.

- [ ] **Step 1: Write the failing tests**

In each of the four test files add the helper (imports `package:memox/core/theme/foundations/app_icons.dart` and `package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart` where missing):

```dart
/// The footer hint's glyph (critique 2026-10-02, F7).
IconData _hintIcon(WidgetTester tester) => tester
    .widget<SessionFooterHintWidget>(find.byType(SessionFooterHintWidget))
    .icon;
```

and these assertions:
- `study_self_assess_test.dart`, in `'the prompt shows first, …'`: after the first pump `expect(_hintIcon(tester), AppIcons.info);` and after `_reveal` `expect(_hintIcon(tester), AppIcons.info);`.
- `study_match_test.dart`, in `'terms on the left, meanings on the right, …'` after the pump: `expect(_hintIcon(tester), AppIcons.info);`; in `'a wrong pair flashes wrong …'` beside the `studyMatchHintWrong` text check: `expect(_hintIcon(tester), AppIcons.repeat);` and after the `pumpAndSettle` that returns to idle: `expect(_hintIcon(tester), AppIcons.info);`.
- `study_guess_test.dart`, in `'the term is asked under "What is this?" …'` after the pump: `expect(_hintIcon(tester), AppIcons.info);`; in `'a wrong pick marks it wrong …'` once answered: `expect(_hintIcon(tester), AppIcons.info);`.
- `study_recall_test.dart`, in `'at zero the turn counts as forgot, …'`: before the 20 s pump `expect(_hintIcon(tester), AppIcons.info);`, and beside the `studyRecallHintTimedOut` check `expect(_hintIcon(tester), AppIcons.repeat);`; in `'Forgot records a wrong answer and moves on'` after the reveal settles: `expect(_hintIcon(tester), AppIcons.info);`.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_self_assess_test.dart test/features/study/presentation/study_match_test.dart test/features/study/presentation/study_guess_test.dart test/features/study/presentation/study_recall_test.dart`
Expected: FAIL: the glyph is `Icons.check`.

- [ ] **Step 3: Implement**

- self-assess and guess: `icon: AppIcons.check,` → `icon: AppIcons.info,`.
- match: `icon: _isWrongPair ? AppIcons.repeat : AppIcons.info,`.
- recall: `icon: isTimedOut ? AppIcons.repeat : AppIcons.info,`.

Each with the comment `// What to do is info; a card that comes back is repeat (critique 2026-10-02, F7).` (one line above the `SessionFooterHintWidget` in match and recall; above the `icon:` in self-assess and guess).

- [ ] **Step 4: Run the study tests**

Run: `flutter test test/features/study --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study test/features/study
git commit -m "fix(study): footer hints use info for instructions and repeat for cards that come back (critique 2026-10-02, F7)"
```

---

### Task 9: The due strip leaves New out (01, BR-STUDY-068)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart:13-15,48-53`
- Test: `test/features/deck/presentation/deck_level_screen_test.dart:78-92`

**Interfaces:** none.

- [ ] **Step 1: Write the failing test**

In `'the due strip leads; each deck carries its due badge'`, replace `expect(_rich('1 overdue · 1 today · 1 new'), findsOneWidget);` with:

```dart
    // The strip states its total's two halves; New is not due
    // (BR-STUDY-068; critique 2026-10-02).
    expect(_rich('1 overdue · 1 today'), findsOneWidget);
    expect(_rich('1 overdue · 1 today · 1 new'), findsNothing);
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/deck/presentation/deck_level_screen_test.dart`
Expected: FAIL: `'1 overdue · 1 today'` not found (the line still ends "· 1 new").

- [ ] **Step 3: Implement**

In `deck_due_strip_widget.dart`, the class doc's "overdue · today · new under it" becomes "overdue · today under it (New is not due, BR-STUDY-068)", and:

```dart
                    DeckWorkloadLineWidget(
                      overdueCount: level.overdueCount,
                      todayCount: level.dueTodayCount,
                      // The two halves of the total; New stays on each deck
                      // row (BR-STUDY-068; critique 2026-10-02).
                      newCount: 0,
                      cardCount: due + level.newCount + level.scheduledCount,
                    ),
```

- [ ] **Step 4: Run the deck tests**

Run: `flutter test test/features/deck --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck test/features/deck
git commit -m "fix(deck): the Library due strip leaves New out of its breakdown (BR-STUDY-068)"
```

---

### Task 10: Day bars at full strength (22, F5, F10, R3)

**Files:**
- Modify: `lib/shared/widgets/mx_stacked_day_bars.dart:37-38,44-48,64-67,127-128,150-170`
- Modify: `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart:103-106`
- Test: `test/shared/widgets/mx_stacked_day_bars_test.dart`, `test/core/theme/token_contrast_test.dart`, `test/features/progress/presentation/progress_chart_ink_test.dart` (new)

**Interfaces:** `MxDayBar.isCurrent` keeps its meaning for the label only.

- [ ] **Step 1: Write the failing tests**

In `mx_stacked_day_bars_test.dart`, replace the faded-Monday assertion in the first test with:

```dart
    // Monday is drawn as strongly as Today, half its 20 (critique
    // 2026-10-02, F5).
    final reviewing = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          (widget.decoration as BoxDecoration?)?.color?.toARGB32() ==
              _reviewing.color.toARGB32(),
    );
    expect(reviewing, findsNWidgets(2));
    expect(
      tester.getSize(reviewing.first).height,
      closeTo(10 * 78 / 20, 0.01),
    );
```

and change the first `_height(tester, _reviewing.color)` (Today's) to `tester.getSize(reviewing.last).height` with the same `closeTo(12 * 78 / 20, 0.01)`, defining `reviewing` before both expectations.

In `token_contrast_test.dart`, inside the per-ground list after `masteredInk`:

```dart
      // The Progress day bars (critique 2026-10-02, F5).
      ('reviewing bars on $where', scheme.primary, ground, _nonText),
```

Create `test/features/progress/presentation/progress_chart_ink_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22's bars use colours that hold 3:1 on the card (critique
// 2026-10-02, F5): learning in its ink, reviewing in primary.
void main() {
  libraryTest('the learning series is the learning ink', (tester, env) async {
    await progressLibrary(env);
    await pumpLibraryScreen(
      tester,
      env,
      ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {}),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final chart = tester.widget<MxStackedDayBars>(
      find.byType(MxStackedDayBars),
    );
    final context = tester.element(find.byType(MxStackedDayBars));
    expect(chart.top.color, context.derivedColors.statusLearningInk);
    expect(chart.base.color, context.colors.primary);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/shared/widgets/mx_stacked_day_bars_test.dart test/core/theme/token_contrast_test.dart test/features/progress/presentation/progress_chart_ink_test.dart`
Expected: the bars test FAILS (one reviewing bar at full colour, Monday faded); the ink test FAILS (the top colour is `statusLearning`). The token test may pass at once (primary is not faded at the token level); that is a finding about the token, not the test, and stays as the guard against a palette change.

If a token pair fails on a ground the chart never sits on (`sheet`, `low`), restrict the pair to `page` and `row` (the card's grounds) and ledger the ruling.

- [ ] **Step 3: Implement**

In `mx_stacked_day_bars.dart`:
- `isCurrent`'s doc: `/// Labelled in bold; every day's bars draw at full strength (critique 2026-10-02, F5).`
- the class doc: replace "the labels under the bars" sentence's context with "…every day at full strength, the current day told by its bold label (critique 2026-10-02, F5)".
- delete `_pastBaseOpacity`, `_pastTopOpacity` and their comment, the `topFade`/`baseFade` locals, and use `top.color` / `base.color` directly in the two bar `BoxDecoration`s.

In `progress_today_widget.dart`:

```dart
      top: MxBarSeries(
        label: l10n.progressLearning,
        // The ink holds 3:1 on the card in both themes; the amber fill does
        // not in light (critique 2026-10-02, F5).
        color: context.derivedColors.statusLearningInk,
      ),
```

The legend dots take the series colours already (`_legend` reads `series.color`).

- [ ] **Step 4: Run the tests**

Run: `flutter test test/shared/widgets test/core/theme test/features/progress --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared lib/features/progress test/shared test/core test/features/progress
git commit -m "fix(progress): day bars at full strength in colours that hold 3:1 (critique 2026-10-02, F5)"
```

---

### Task 11: One flag ink (07, F6, R6)

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart:147-173`
- Test: `test/features/card/presentation/card_row_test.dart:43-70`

**Interfaces:** none.

- [ ] **Step 1: Write the failing test**

In `'a row shows front, back, status, two tags and +N, the flag and when it is due'`, after `expect(find.byIcon(Icons.flag), findsOneWidget);` (imports `package:memox/core/theme/theme_context.dart` if missing):

```dart
    // The flag is plain ink, as in the editor and the detail; the filled
    // glyph carries the state (critique 2026-10-02, F6).
    final flag = tester.element(find.byIcon(Icons.flag));
    expect(IconTheme.of(flag).color, flag.colors.onSurface);
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/card/presentation/card_row_test.dart`
Expected: FAIL: the colour is the warning colour.

- [ ] **Step 3: Implement**

In `card_row_widget.dart`, `_Trailing`'s doc becomes `/// The flag in plain ink, the filled glyph carrying the state as in the editor and the detail (critique 2026-10-02, F6; supersedes E-L2), over the due chip.`, and the `IconThemeData` color becomes `context.colors.onSurface`.

- [ ] **Step 4: Run the card tests**

Run: `flutter test test/features/card --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "fix(card): the list's flag in plain ink, as in the editor and detail (critique 2026-10-02, F6)"
```

---

### Task 12: Sync offline note and Keep in warning (27, F8)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sections/sync_notice_widget.dart:12-42`
- Modify: `lib/features/settings/presentation/screens/sync_screen.dart:35-40`
- Modify: `lib/features/settings/presentation/widgets/overlays/sync_keep_dialog_widget.dart:28-34`
- Test: `test/features/settings/presentation/sync_screen_test.dart` (one test's failure kind), `test/features/settings/presentation/sync_offline_note_test.dart` (new)

**Interfaces:** none.

- [ ] **Step 1: Write the failing tests**

Create `test/features/settings/presentation/sync_offline_note_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

// Screen 27 (critique 2026-10-02, F8): no connection is a fact to wait out,
// not a warning; keeping refused changes on the device is warned before.
void main() {
  libraryTest('a network failure is a neutral note, and Sync now steps down '
      'to outline even with changes waiting', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          pendingCount: 2,
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            env.clock.now(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MxNote),
        matching: find.textContaining('No connection.'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.outline,
    );
  });

  libraryTest('a server failure stays a warning and Sync now leads', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          lastFailure: LastSyncFailure(
            SyncFailureKind.server,
            env.clock.now(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.primary,
    );
  });

  libraryTest('the Keep dialog confirms in warning', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 3),
        FakeSyncCommands(),
      ),
    );
    await tester.tap(find.text('Keep on this device'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).isWarning,
      isTrue,
    );
  });
}
```

In `sync_screen_test.dart`, `'a problem sits under the status, above Sync now, …'` switches its failure kind to `SyncFailureKind.server` (the banner it measures is the warning a server failure keeps).

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/settings/presentation/sync_offline_note_test.dart`
Expected: FAIL: a banner shows for the network failure; Sync now is primary; `isWarning` false.

- [ ] **Step 3: Implement**

`sync_notice_widget.dart` (imports `app_icons.dart`, `mx_note.dart`; class doc gains "A failed run for want of a network is a neutral note: there is nothing to fix, only to wait (critique 2026-10-02, F8)."):

```dart
    if (status.rejectedCount == 0 && failure != null) {
      final sentence = syncFailureSentence(l10n, failure.kind);
      if (failure.kind == SyncFailureKind.network) {
        return MxNote(icon: AppIcons.offline, text: sentence);
      }
      return MxInlineBanner(tone: MxBannerTone.warning, message: sentence);
    }
```

(import `package:memox/core/sync/sync_failure.dart`).

`sync_screen.dart`:

```dart
  /// Sync now leads only when something waits or the last run failed, no
  /// row was refused, and the network is not what failed: with refused rows
  /// the banner's Try again is the one primary (DESIGN.md One Indigo;
  /// critique 2026-09-30 part 1), and offline a manual run cannot help
  /// (critique 2026-10-02, F8).
  static bool _leadsSyncNow(SyncStatus status) =>
      status.rejectedCount == 0 &&
      status.lastFailure?.kind != SyncFailureKind.network &&
      (status.pendingCount > 0 || status.lastFailure != null);
```

(import `sync_failure.dart` if missing).

`sync_keep_dialog_widget.dart`: `MxSheetActions(…, confirmLabel: l10n.syncKeepOnDevice, isWarning: true, onConfirm: …)` with the comment `// The changes then never sync: warned, not destroyed (critique 2026-10-02, F8).`

- [ ] **Step 4: Run the settings tests**

Run: `flutter test test/features/settings --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings test/features/settings
git commit -m "fix(sync): no connection is a neutral note with an outline Sync now; Keep confirms in warning (critique 2026-10-02, F8)"
```

---

### Task 13: Records

**Files:**
- Modify: `DESIGN.md` (the `MxStackedDayBars` entry, line ~354)
- Modify: detail files `docs/shared/ui/screen-handoff/{01,07,09,10,11,16a,17,18,19,21,22,27,30,32}-*.md`
- Modify: `docs/superpowers/specs/2026-09-30-auth-design.md` (a row after #39)
- Modify: `docs/wbs_FE.md` (row FE-D17)
- Regenerate: `docs/_generated` with `python3 tools/docs/generate.py`

- [ ] **Step 1: DESIGN.md**

`**MxStackedDayBars**` → `**MxStackedDayBars** (every day at full strength, each series in a colour that holds 3:1 on the card, learning in its ink; the current day is told by its bold label, critique 2026-10-02)`.

- [ ] **Step 2: Detail files**

Each file gets one line in its rulings list, in the form `- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** …`, and any row the change makes stale is corrected:
- 01: the due strip's breakdown is overdue · today; New stays on each deck row (BR-STUDY-068).
- 07: the flag is plain ink; E-L2 is superseded (row line 18 "trailing flag in the warning colour (E-L2)" → "trailing flag in plain ink"; the E-L2 ruling line ~88 gains "Superseded by critique 2026-10-02 (F6): plain ink.").
- 09 and 10: the flag is plain ink everywhere, list included.
- 11: the result lists each skipped row (number, term, meaning, why), five then "Show all"; the skip note keeps only the duplicate rule; the "Choose a file" card opens the picker and the empty state has no button (row line 26 already says the option picks through `file_picker`).
- 16a, 17, 18, 19: the footer hint glyph is info, repeat for "comes back" lines (17 wrong pair, 19 timed out).
- 21: the came-back note follows only a finished session; the facts of an ended or failed session read "Kept in the history" on a neutral tile and "of {n} turns" (fix any row quoting "Schedules updated", "Now scheduled, due tomorrow" or "wrong cards came back").
- 22: every day's bars at full strength; learning in its ink; Today by its bold label.
- 27: a network failure is a neutral `MxNote` and Sync now is outline; Keep confirms in warning.
- 30: a sign-out stopped offline says "No connection. Nothing has been removed yet." and offers Cancel beside Retry and the loss button.
- 32: Switch, Sign out and Delete are action rows (no chevron); Sign out's hint is "Removes this phone's data · sign in again to get it back"; its online confirm is warning, the offline loss confirm destructive.

- [ ] **Step 3: Auth spec**

After row 39 of the transition table add:

```
| 39a | SignOut, stage started (nothing local removed) | "Cancel" (critique 2026-10-02) | drop record; open gate; `me()` (#8/#9) | VALIDATING → READY(X) |
```

- [ ] **Step 4: WBS and generated docs**

Add under FE-D16 in `docs/wbs_FE.md`:

```
| FE-D17 | Critique 2026-10-02: 21 lời tóm tắt đúng theo kết cục, 30/32 huỷ sign-out khi chưa xoá gì và gợi ý Sign out nói rõ hệ quả, 11 liệt kê dòng bị bỏ và thẻ "Chọn tệp" mở picker, 16a–19 icon gợi ý, 22 cột ngày đủ đậm 3:1, 01 dải due bỏ new, 07 cờ màu chữ thường, 32 dòng hành động, 27 mất mạng là ghi chú trung tính | đang làm | FE-D16 | S | [spec](superpowers/specs/2026-10-02-critique2-fixes-design.md) và [plan](superpowers/plans/2026-10-02-critique2-fixes.md) | — |
```

Run: `python3 tools/docs/generate.py`
Expected: exit 0.

- [ ] **Step 5: Run the docs checks**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > .superpowers/sdd/2026-10-02-critique2-fixes/gate.log 2>&1; echo $?` (background, `timeout: 3600000`)
Expected: `0`. On failure read the tail of the log and fix (most likely: an ARB description, a stale doc link, a guard length).

- [ ] **Step 6: Commit**

```bash
git add DESIGN.md docs
git commit -m "docs: critique 2026-10-02 rulings in DESIGN.md, detail files, the auth spec and the WBS"
```

---

### Task 14: Goldens, gate and review

- [ ] **Step 1: Regenerate goldens (Linux container)**

Run: `TZ=UTC flutter test --tags golden --update-goldens > .superpowers/sdd/2026-10-02-critique2-fixes/goldens-update.log 2>&1; echo $?`
Expected: `0`. Then `git status --short test | grep goldens` lists the changed PNGs. Expected changes: session summary (21: interrupted, reset/saveError facts), account screen (32: hint, no chevrons) and any sign-out layer golden (30), import partial result and source (11), study session goldens 16a–19 (glyph), library list with the due strip (01), progress (22), card list with a flag (07), sync with a network failure (27). An unexpected file is a finding: read its diff before keeping it.

- [ ] **Step 2: Run goldens clean**

Run: `TZ=UTC flutter test --tags golden > .superpowers/sdd/2026-10-02-critique2-fixes/goldens.log 2>&1; echo $?`
Expected: `0`.

- [ ] **Step 3: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): regenerate for critique 2026-10-02 fixes"
```

- [ ] **Step 4: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > .superpowers/sdd/2026-10-02-critique2-fixes/gate.log 2>&1; echo $?` (background, `timeout: 3600000`)
Expected: `0`.

- [ ] **Step 5: Impeccable after the build, final review, golden review**

Per CLAUDE.md step 5: critique and audit the changed goldens against DESIGN.md, fix everything found in one batch, one `impeccable audit` of that fix. Then, per executing-plans: review package from the commit before Task 1, a fresh reviewer on Opus, one fix pass. Then build the `golden-compare` page (base = the commit before Task 1, head = HEAD) and give the owner the link before any approval.
