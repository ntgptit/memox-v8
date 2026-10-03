# UI hardening SP2b — dialogs, settings, sync and account: data safety and dead ends — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix backlog items 2.26–2.48 of the UI hardening spec: no dialog loses its outcome or hides its failure under a scrim, the Trash never purges on a wrong clock (R10), reminders and sync never show a false state, and no account flow strands the person (R11).

**Architecture:** Each fix lands where its logic lives (ADR-010/011 layers, ADR-020 queries in `.drift`). One server change: `sync_changes` returns `serverTime` (migration + pgTAP; ADR-015 RPC list). Shared code (owner-approved): `MxDeckPickerSheet.isHeld`/`banner`, `InvalidEmailFailure`.

**Tech Stack:** Flutter 3.47.5, Dart, Riverpod (riverpod_annotation), Drift, Supabase (pgTAP), flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-03-ui-hardening-sp2b-design.md` (owner decisions in its §9). Parent: `docs/superpowers/specs/2026-10-03-ui-hardening-design.md` (rulings R10, R11; §7).

**Task numbering:** Tasks 1–18 are cluster A (deck dialogs, starter, Trash with R10, Settings reset), 19–25 cluster B (reminder, sync, monitoring), 26–36 cluster C (account). Task 37 closes the branch. A reference such as "A3" means Task 3, "B2" Task 20, "C4" Task 29.

## Global Constraints

- **Tokens and copy.** Tokens only (`check_design_tokens.py` hook). Components hold no copy: every string goes in `lib/l10n/app_en.arb` with a `description` and in `app_vi.arb` in Vietnamese with diacritics; ICU plurals for counts.
- **Copy voice** (DESIGN.md): a failure says first that nothing was lost; destructive confirms name the loss; a note says something new; offline is neutral; warning = refusal or limit with nothing lost; danger = a loss.
- **Queries and schema.** SQL lives in `.drift` files; a new query gets an owner in `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`. Supabase changes ship as a migration plus pgTAP; gate: `npx supabase db start` then `npx supabase test db`.
- **Layers.** `presentation/` never imports `data/`; widgets never `ref.read/watch` a `*RepositoryProvider`; no pass-through use cases.
- **Guard.** `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` exits 0 with 0 warnings: files ≤ 400 logical lines, predicate booleans, fixed clocks in tests, ARB descriptions.
- **Running tests.** One file: `flutter test <file>`. A folder: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh <dir>`. Never `--update-goldens`. Before each commit: `dart format` on touched files and `flutter analyze lib test`.
- **Commits.** Conventional, scoped, English, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Controller rulings on the drafting decisions

- **A (Tasks 1–18):** all recommendations stand (A1 `failureOfThrown` in `lib/l10n/failure_message.dart`; A2 a held picker also disables dismiss; A12/A13 Option A, owner-approved; A18 is done).
- **R10 clock (Tasks 14, 18) — ruling:** the purge clock is `min(deviceNow, lastServerTime)`; a batch is expired when it is expired at that instant. With no recorded server time (never synced), nothing is swept as expired — manual purge of selected items still works. This replaces any "clock agrees within a tolerance" check: a forward-jumped device clock can never purge early, and a stale sync only delays the purge.
- **B (Tasks 19–25):** all recommendations stand (B5 reads `authStateProvider`; `SyncScreen.onSignIn` becomes required; B2 also watches `isEnabled`; B6 empty-list failure stays the failure page and `refresh()` clears the warning; goldens 27/28 state rows with image links land with their PNGs).
- **C (Tasks 26–36):** all recommendations stand (2.45 warning banner with a compact Retry; C10 kept; one last-send record; the layer's own code page is not held; `accountNoticeText`; 2.40 also forgets the pick when the context is gone). Task 36 (C11) folds into Task 37's docs step if convenient.

## Review Focus

- **A forward-jumped device clock** (Task 14/18): nothing is purged that the server's last time does not call expired; a test sets the device 60 days ahead.
- **A dialog dismissed by Back or the scrim mid-write** (Tasks 3–9, 11, 15): the dialog stays; the outcome (toast or banner) still reaches the screen.
- **Permission granted in system settings while screen 24 is open** (Tasks 19–21): on resume the warning goes without a restart.
- **A resend inside the rate-limit window, then leaving and coming back** (Task 27): the wait survives and no second send is made.
- **A role call that never answers** (Task 33): the page ends as offline within the timeout, not a spinner.

---

# SP2b cluster A — deck dialogs and sheets, Starter sheet, Trash, Settings reset (tasks A1–A18)

Spec: `docs/superpowers/specs/2026-10-03-ui-hardening-sp2b-design.md` §3.1 (2.26, 2.27, 2.28), §3.2 (2.29), §3.3 (2.30 R10, 2.31, 2.32), §3.4 (2.33), the shared code of §4 they need (`MxDeckPickerSheet.isHeld` and `banner`) and the BR changes of §5 for Trash and `sync_changes`.

**Task order.**
- A1–A2 are shared code.
- A3–A9 are the writing dialogs and sheets (2.26, 2.27, 2.28).
- A10 is 2.29.
- A11 is 2.33.
- A12–A14 are 2.30 (server time: migration, client, use case).
- A15–A17 are the Trash purge dialog (2.27, 2.31, 2.32).
- A18 is a DECISION that closes a hole in R10.

Every task is one commit. Every implementer runs `dart format` on the touched files and `flutter analyze lib test` before committing.

## Pattern used by A3–A9 (read once)

- **Hold (2.26).** The dialog passes `isHeld: _isBusy` to `MxDialog`; a sheet passes it to `MxDeckPickerSheet`. Cancel is `null` while busy, because `Navigator.pop` ignores `PopScope` and a Cancel that pops mid-write loses the toast.
- **Failure inside the dialog (2.27).** `Failure? _failure` is cleared at the next submit. The catch-all is `on Object catch (error, stack)` and uses `failureOfThrown` (A1). It releases the busy flag and sets `_failure`. The dialog draws `MxInlineBanner(tone: MxBannerTone.warning, message: l10n.failure(failure))` first in its `content`; a sheet passes it as `banner:`. The confirm, or the candidate, stays enabled and is the retry. A typed `Rejected` keeps its toast (ruling P2-L10).
- **Test support (A3 creates it).** `test/support/held_writes.dart` has `WriteHold`, which waits for `open()` and then throws what `failNext()` queued. It also has `HeldDecks`, `HeldCards`, `HeldTags` and `HeldTrash`, which put a `WriteHold` in front of one write of the real repository. A test wires one in through the use-case provider, as `card_bulk_trash_test.dart` does with `GatedCardTrash`.

---

### Task 1 (A1): `failureOfThrown` — the catch-all every holding dialog needs

**Files:**
- Modify: `lib/l10n/failure_message.dart` (add after the `FailureMessage` extension, line 20)
- Test: `test/l10n/failure_message_test.dart`

**Interfaces:**
- Produces: `Failure failureOfThrown(Object error, StackTrace stack, {required String library})`. A `Failure` comes back as it is. Anything else is reported with `FlutterError.reportError` (the way `import_undo_dialog_widget.dart:79` and the card editor do) and comes back as `UnknownDatabaseFailure(cause: error)`.
- DECISION: the helper lives in `lib/l10n/failure_message.dart`, so nine dialogs do not each carry the same eight lines. If the owner would rather not touch this file, inline those eight lines at each site; the only call shape that changes is `failureOfThrown(error, stack, library: 'x')`. Recommended: the helper.

- [ ] **Step 1: Write the failing test** (append inside `main()` of `failure_message_test.dart`; add `import 'package:flutter/foundation.dart';` if the analyzer asks)

```dart
  test('failureOfThrown tells a Failure as it is and reports anything else', () {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    const known = DatabaseLockedFailure(cause: 'locked');

    expect(failureOfThrown(known, StackTrace.empty, library: 'x'), same(known));
    expect(reported, isEmpty);

    final told = failureOfThrown(
      StateError('boom'),
      StackTrace.empty,
      library: 'deck delete',
    );
    expect(told, isA<UnknownDatabaseFailure>());
    expect(reported.single.exception, isA<StateError>());
    expect(reported.single.library, 'deck delete');
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/l10n/failure_message_test.dart`
Expected: FAIL to compile (`failureOfThrown` is undefined).

- [ ] **Step 3: Implement.** In `failure_message.dart` add `import 'package:flutter/foundation.dart';` with the imports, and after the extension:

```dart
/// What a write's catch-all tells the person. A database [Failure] is told as
/// it is; anything else is reported (as the card editor's and the import
/// undo's catch-alls do) and told as an unknown failure. Either way the
/// caller releases its busy flag and keeps its form for another try
/// (SP2b 2.26, 2.27).
Failure failureOfThrown(
  Object error,
  StackTrace stack, {
  required String library,
}) {
  if (error is Failure) return error;
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stack, library: library),
  );
  return UnknownDatabaseFailure(cause: error);
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/l10n/failure_message_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/failure_message.dart test/l10n/failure_message_test.dart
git commit -m "feat(l10n): failureOfThrown reports a non-Failure and tells it as unknown (SP2b 2.26)"
```

Goldens: none.

---

### Task 2 (A2): `MxDeckPickerSheet` can be held and can carry a banner

**Files:**
- Modify: `lib/shared/widgets/mx_deck_picker_sheet.dart` (constructor and fields 40-61, `build` 63-111, `_PickerHead` 143-173)
- Test: `test/shared/widgets/mx_deck_picker_sheet_test.dart` (the `_picker` helper at 12-21; two new tests)

**Interfaces:**
- Produces: `MxDeckPickerSheet({…, bool isHeld = false, Widget? banner})`.
  - `isHeld` goes to `MxBottomSheet.isHeld` (Back, a scrim tap and a drag are refused) and turns the dismiss button off.
  - `banner` is a notice the caller builds, such as an `MxInlineBanner`. The sheet places it in its fixed head, under the rule and above the rows, so a long list never scrolls it away.
- DECISION (spec §4, DECISION 1): both parameters are optional and stay in the shared widget. Recommended: yes. Without them, the failure toast sits under the scrim, which is the defect. The dismiss button turning off while held goes with it: a Cancel that pops mid-write would lose the toast.

- [ ] **Step 1: Write the failing tests.** Replace the `_picker` helper:

```dart
MxDeckPickerSheet _picker(
  List<MxPickerCandidate> candidates, {
  VoidCallback? onDismiss,
  bool isHeld = false,
  Widget? banner,
}) => MxDeckPickerSheet(
  title: 'Move to deck',
  rule: 'Cards keep their progress.',
  candidates: candidates,
  dismissLabel: 'Cancel',
  onDismiss: onDismiss ?? () {},
  emptyTitle: 'Nowhere to move',
  isHeld: isHeld,
  banner: banner,
);
```

Add `import 'package:memox/shared/widgets/mx_inline_banner.dart';` and append inside `main()`:

```dart
  testWidgets('a banner sits in the head, under the rule and above the rows '
      '(SP2b 2.27)', (tester) async {
    await pumpMx(
      tester,
      _picker(
        [MxPickerCandidate(label: 'Kana', onTap: () {})],
        banner: const MxInlineBanner(
          tone: MxBannerTone.warning,
          message: 'Busy. Try again.',
        ),
      ),
    );

    final banner = tester.getRect(find.byType(MxInlineBanner));
    expect(
      banner.top,
      greaterThan(
        tester.getBottomLeft(find.text('Cards keep their progress.')).dy,
      ),
    );
    expect(banner.bottom, lessThan(tester.getTopLeft(find.text('Kana')).dy));
  });

  testWidgets('held: the sheet is held and the dismiss button is off '
      '(SP2b 2.26)', (tester) async {
    await pumpMx(
      tester,
      _picker([MxPickerCandidate(label: 'Kana', onTap: () {})], isHeld: true),
    );

    expect(tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld, isTrue);
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Cancel')).onPressed,
      isNull,
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_deck_picker_sheet_test.dart`
Expected: FAIL to compile (`isHeld` and `banner` are not parameters of `MxDeckPickerSheet`).

- [ ] **Step 3: Implement.** In `mx_deck_picker_sheet.dart`:

Constructor and fields:

```dart
    required this.emptyTitle,
    this.emptyBody,
    this.isHeld = false,
    this.banner,
  });
  …
  final String? emptyBody;

  /// A write behind a candidate is running: Back, a scrim tap and a drag are
  /// refused and the dismiss button is off, so its result reaches the screen
  /// (SP2b 2.26).
  final bool isHeld;

  /// A notice under the rule, such as a failure the person retries by
  /// choosing again (SP2b 2.27). The caller builds it and owns its copy.
  final Widget? banner;
```

In `build`:

```dart
    return MxBottomSheet(
      isHeld: isHeld,
      header: _PickerHead(title: title, rule: rule, banner: banner),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: dismissLabel,
              onPressed: isHeld ? null : onDismiss,
```

`_PickerHead`:

```dart
  const _PickerHead({required this.title, this.rule, this.banner});

  final String title;
  final String? rule;
  final Widget? banner;
  …
          Text(title, style: styles.compactTitle),
          if (rule case final text?) Text(text, style: styles.noteText),
          if (banner case final notice?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.control),
              child: notice,
            ),
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_deck_picker_sheet_test.dart`
Expected: PASS (all, old and new).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_deck_picker_sheet.dart test/shared/widgets/mx_deck_picker_sheet_test.dart
git commit -m "feat(ui): MxDeckPickerSheet can be held and carry a banner (SP2b 2.26, 2.27)"
```

Goldens: none (`mx_deck_picker_*` draws neither).

---

### Task 3 (A3): Deck delete dialog holds and keeps its failure inside (2.26, 2.27)

**Files:**
- Create: `test/support/held_writes.dart`
- Create: `test/features/deck/presentation/deck_delete_dialog_test.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart` (imports 1-17, state 54-125)
- Modify: `test/features/deck/presentation/deck_screens_golden_test.dart` (a new golden after `delete dialog`, line 132-150)

**Interfaces:**
- Consumes: `failureOfThrown` (A1), `MxDialog.isHeld` (SP1), `MxInlineBanner`.
- Produces (test support, used by A4–A9, A15–A18):
  - `final class WriteHold { static const DatabaseLockedFailure failure; int calls; void open(); void failNext([Object error]); Future<void> pass(); }`
  - `HeldDecks(DeckRepository inner, WriteHold hold)`: gates `renameDeck`, `deleteDeck` and `moveDeck`.
  - `HeldCards(CardRepository inner, WriteHold hold)`: gates `moveCards` and `restoreCards`.
  - `HeldTags(TagRepository inner, WriteHold hold)`: gates `attachByName`.
  - `HeldTrash(TrashRepository inner, WriteHold hold)`: gates `purge`.

- [ ] **Step 1: Write the failing tests.** Create `test/support/held_writes.dart`:

```dart
import 'dart:async';

import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_attach_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// A write a test holds in flight, so it can press Back or tap the scrim
/// meanwhile, then lets through ([open]) or fails ([failNext]) (SP2b 2.26).
final class WriteHold {
  /// What a failing write throws unless the test names another error.
  static const failure = DatabaseLockedFailure(cause: 'locked');

  final _gate = Completer<void>();
  final _errors = <Object>[];

  /// Writes that reached the gate.
  int calls = 0;

  void open() {
    if (!_gate.isCompleted) _gate.complete();
  }

  /// The next write that passes the gate throws [error].
  void failNext([Object error = failure]) => _errors.add(error);

  Future<void> pass() async {
    calls++;
    await _gate.future;
    if (_errors.isNotEmpty) throw _errors.removeAt(0);
  }
}

/// The real decks, each write behind [hold].
final class HeldDecks implements DeckRepository {
  HeldDecks(this._inner, this.hold);

  final DeckRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.renameDeck(deckId: deckId, name: name, now: now);
  }

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.deleteDeck(deckId: deckId, now: now);
  }

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.moveDeck(deckId: deckId, newParentId: newParentId, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real cards, a move and a restore behind [hold].
final class HeldCards implements CardRepository {
  HeldCards(this._inner, this.hold);

  final CardRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<BulkOutcome, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.moveCards(
      cardIds: cardIds,
      targetDeckId: targetDeckId,
      now: now,
    );
  }

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.restoreCards(batchIds: batchIds, deckId: deckId, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real tags, attaching by name behind [hold].
final class HeldTags implements TagRepository {
  HeldTags(this._inner, this.hold);

  final TagRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<TagAttach, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.attachByName(cardIds: cardIds, name: name, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real Trash, a purge behind [hold].
final class HeldTrash implements TrashRepository {
  HeldTrash(this._inner, this.hold);

  final TrashRepository _inner;
  final WriteHold hold;

  @override
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  }) async {
    await hold.pass();
    return _inner.purge(batchIds: batchIds, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

Create `test/features/deck/presentation/deck_delete_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// Longer than the dialog's exit, so a pop that was not held would be gone.
const _exit = Duration(milliseconds: 500);

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showDeleteDeckDialog(context, deck: deck),
    ),
  ),
);

/// Opens the dialog over [deck], its delete behind the returned hold.
Future<WriteHold> _open(
  WidgetTester tester,
  LibraryEnv env,
  DeckEntity deck,
) async {
  final hold = WriteHold();
  await pumpLibraryScreen(
    tester,
    env,
    _host(deck),
    overrides: [
      deleteDeckUseCaseProvider.overrideWithValue(
        DeleteDeckUseCase(HeldDecks(env.decks, hold)),
      ),
    ],
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return hold;
}

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

void main() {
  libraryTest('Back, a scrim tap and Cancel wait for the move; its toast with '
      'Undo then arrives (SP2b 2.26)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    await tester.tap(find.text(_en.deckDelete));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(_exit);
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(_exit);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.deckTrashedToast('Korean', 0, 0)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
  });

  libraryTest('a failed move keeps the dialog with a warning banner, and Move '
      'to Trash is the retry (SP2b 2.27)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(hold.calls, 2);
    expect(find.text(_en.deckTrashedToast('Korean', 0, 0)), findsOneWidget);
  });

  libraryTest('a write that throws a non-Failure is reported and releases the '
      'dialog (SP2b 2.26)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await _open(tester, env, korean);
    hold
      ..open()
      ..failNext(StateError('boom'));
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<StateError>());
    expect(_banner(_en.failureUnknown), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });
}
```

Golden test: in `deck_screens_golden_test.dart` add the imports `package:memox/features/deck/domain/usecases/delete_deck_use_case.dart`, `package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart`, `../../../support/held_writes.dart`, and after the `delete dialog` test:

```dart
    libraryTest('delete dialog, failed, $theme', (tester, env) async {
      final ids = await _seed(env);
      final hold = WriteHold()
        ..open()
        ..failNext();
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.words),
          brightness,
          overrides: [
            deleteDeckUseCaseProvider.overrideWithValue(
              DeleteDeckUseCase(HeldDecks(env.decks, hold)),
            ),
          ],
        );
        await tester.tap(find.byTooltip(_en.deckActions));
        await _settleOverlay(tester);
        await tester.tap(find.text(_en.deckDelete));
        await _settleOverlay(tester);
        await tester.tap(find.text(_en.deckDelete));
        await _settleOverlay(tester);
        expect(find.text(_en.failureBusy), findsOneWidget);
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_delete_failed_$theme.png',
        );
      });
    });
```

(`failureBusy` is the copy of `DatabaseLockedFailure`; `FailureMessage.failure` maps it, line 12 of `failure_message.dart`.)

- [ ] **Step 2: Run the unit tests to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_delete_dialog_test.dart`
Expected: FAIL. Test 1 finds the dialog gone after Back/scrim (Cancel is live, the dialog is not held). Test 2 finds a toast and no banner. Test 3 leaves `_isDeleting` stuck and the `StateError` unhandled.

- [ ] **Step 3: Implement.** In `deck_delete_dialog_widget.dart` add imports `package:memox/core/theme/foundations/app_spacing.dart` and `package:memox/shared/widgets/mx_inline_banner.dart`. Replace the state class (lines 54-125):

```dart
class _DeckDeleteDialogWidgetState
    extends ConsumerState<DeckDeleteDialogWidget> {
  var _isDeleting = false;

  /// The last move's failure, shown in the dialog until the next try
  /// (SP2b 2.27).
  Failure? _failure;

  Future<void> _delete(DeckDeletionSummary summary) async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _failure = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .deleteDeck(deckId: widget.deck.id);
      if (!mounted) return;
      switch (outcome) {
        case Ok(value: final batchId):
          showDeckTrashedSnackbar(
            context,
            deckName: widget.deck.name,
            summary: summary,
            batchId: batchId,
            onOpenTrash: widget.onOpenTrash,
          );
        case Rejected(:final reason):
          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
      }
      Navigator.of(context).pop(outcome is Ok);
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck delete');
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(deckDeletionSummaryProvider(widget.deck.id));
    final counted = switch (summary) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final body = switch (summary) {
      AsyncData(value: Ok(:final value)) => l10n.deckDeleteSummary(
        widget.deck.name,
        value.subDeckCount,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.deckRejection(reason),
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    final failure = _failure;
    return MxDialog(
      // The toast with Undo must reach the screen: Back and a scrim tap wait
      // for the move (SP2b 2.26).
      isHeld: _isDeleting,
      title: l10n.deckDeleteTitle,
      body: body,
      content: counted == null && failure == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.grouped,
              children: [
                if (failure != null)
                  MxInlineBanner(
                    tone: MxBannerTone.warning,
                    message: l10n.failure(failure),
                  ),
                if (counted != null)
                  MxNote(icon: AppIcons.history, text: l10n.deckDeleteNote),
              ],
            ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isDeleting ? null : () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckDelete,
        confirmIcon: AppIcons.delete,
        isConfirmLoading: _isDeleting,
        onConfirm: switch (counted) {
          final summary? when !_isDeleting => () => _delete(summary),
          _ => null,
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_delete_dialog_test.dart test/features/deck/presentation/deck_action_sheet_test.dart`
Expected: PASS (the existing delete tests in `deck_action_sheet_test.dart` still hold).

- [ ] **Step 5: Commit**

```bash
git add test/support/held_writes.dart \
  test/features/deck/presentation/deck_delete_dialog_test.dart \
  test/features/deck/presentation/deck_screens_golden_test.dart \
  lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
git commit -m "fix(deck): the delete dialog holds while the move runs and keeps its failure inside (SP2b 2.26, 2.27)"
```

Goldens: none move. One new golden test, `library_deck_delete_failed_{light,dark}`, is generated later in the Linux container (never `--update-goldens` on Windows).

---

### Task 4 (A4): Rename and sub-deck dialog (2.26, 2.27)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart` (imports 1-14, state 83-152)
- Test: `test/features/deck/presentation/deck_name_dialog_widget_test.dart`

**Interfaces:**
- Consumes: A1, A3's `held_writes.dart`.
- One widget serves both rename and create-sub-deck (`DeckNameDialogWidget`), so one set of tests covers both.

- [ ] **Step 1: Write the failing tests.** Add the imports `package:memox/features/deck/domain/usecases/rename_deck_use_case.dart`, `package:memox/features/deck/presentation/providers/rename_deck_use_case_provider.dart`, `package:memox/l10n/failure_message.dart`, `package:memox/shared/widgets/mx_inline_banner.dart`, `package:memox/shared/widgets/mx_sheet_actions.dart`, `../../../support/held_writes.dart`. Append inside `main()`:

```dart
  Future<WriteHold> openHeld(
    WidgetTester tester,
    LibraryEnv env,
    DeckEntity deck,
  ) async {
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      _host(deck),
      overrides: [
        renameDeckUseCaseProvider.overrideWithValue(
          RenameDeckUseCase(HeldDecks(env.decks, hold)),
        ),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    return hold;
  }

  libraryTest('Back, a scrim tap and Cancel wait for the save (SP2b 2.26)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final hold = await openHeld(tester, env, korean);
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });

  libraryTest('a failed save keeps the typed name and shows a banner; the '
      'confirm saves again (SP2b 2.27)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final hold = await openHeld(tester, env, korean);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text('Hàn Quốc'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failure(WriteHold.failure)),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect((await env.decks.findById(korean.id))!.name, 'Hàn Quốc');
  });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_name_dialog_widget_test.dart`
Expected: FAIL. The first new test finds the dialog gone (Cancel and the scrim are live); the second finds a toast and no banner.

- [ ] **Step 3: Implement.** In `deck_name_dialog_widget.dart` add imports `package:memox/shared/widgets/mx_inline_banner.dart`; remove nothing (the snackbar import stays for the typed `Rejected`). In the state class:

```dart
  DeckRejection? _rejection;

  /// The last save's failure, shown above the field until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_submit` (lines 91-119): the opening `setState` and the catch become

```dart
    setState(() {
      _isSubmitting = true;
      _rejection = null;
      _failure = null;
    });
    …
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck name');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _failure = failure;
      });
    }
```

`build`:

```dart
    final failure = _failure;
    return MxDialog(
      // Back and a scrim tap wait for the write (SP2b 2.26).
      isHeld: _isSubmitting,
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          if (failure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.failure(failure),
            ),
          MxTextField(
            …unchanged…
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(),
        confirmLabel: widget.confirmLabel,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
```

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_name_dialog_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart \
  test/features/deck/presentation/deck_name_dialog_widget_test.dart
git commit -m "fix(deck): the rename and sub-deck dialog holds while it saves and keeps its failure inside (SP2b 2.26, 2.27)"
```

Goldens: none.

---

### Task 5 (A5): Create-root dialog (2.26, 2.27)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart` (imports 1-22, state 44-101, `build` 103-157)
- Test: `test/features/deck/presentation/create_root_deck_dialog_widget_test.dart` (one existing test edited, one added)

**Interfaces:**
- Consumes: A1. The file already has `_SlowDecks` (a gated `createRootDeck` with `release()` and `calls`), so it does not use `held_writes.dart`.
- Constraint: the dialog's own `PopScope(canPop: false)` calls `_leave()` on Back and on a scrim tap. A started form asks to discard first (A1 of the screen's flow). `_leave()` must return at once while `_isSubmitting`, or the discard dialog opens over a write.

- [ ] **Step 1: Write the failing tests.** Add imports `package:memox/shared/widgets/mx_inline_banner.dart` and `package:memox/shared/widgets/mx_sheet_actions.dart`. Replace, in the test `a database failure keeps the dialog and says so plainly (RF4)`:

```dart
    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
```
with
```dart
    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failureUnknown),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
```
and append:

```dart
  libraryTest('Back, a scrim tap and Cancel do nothing while the deck is '
      'created, so the discard dialog never opens over a write (SP2b 2.26)', (
    tester,
    env,
  ) async {
    final slow = _SlowDecks(env.decks);
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [
        createRootDeckUseCaseProvider.overrideWithValue(
          CreateRootDeckUseCase(slow),
        ),
      ],
    );
    await open(tester);
    await tester.enterText(find.byType(EditableText), 'Korean');
    await chooseEightBox(tester);
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_en.deckDiscardTitle), findsNothing);
    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );

    slow.release();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(await _decks(env), [('Korean', 'eight_box')]);
  });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`
Expected: FAIL. The edited test finds a toast and no banner. The new test finds the discard dialog open (`_leave()` opens it because a name was typed).

- [ ] **Step 3: Implement.** Add `import 'package:memox/shared/widgets/mx_inline_banner.dart';`. In the state class:

```dart
  DeckRejection? _rejection;

  /// The last create's failure, shown above the field until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_leave`:

```dart
  Future<void> _leave() async {
    // Never over a write: its result must reach the screen (SP2b 2.26).
    if (_isSubmitting) return;
    if (_isStarted && !await showDeckDiscardDialog(context)) return;
    if (mounted) Navigator.of(context).pop();
  }
```

`_submit`:

```dart
    setState(() {
      _isSubmitting = true;
      _rejection = null;
      _failure = null;
    });
    …
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck create');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _failure = failure;
      });
    }
```

`build`: the dialog gets `isHeld: _isSubmitting`, the banner leads the content `Column`, and Cancel is off:

```dart
    final failure = _failure;
    final dialog = MxDialog(
      isHeld: _isSubmitting,
      title: l10n.deckCreateRootTitle,
      content: Column(
        …
        children: [
          if (failure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.failure(failure),
            ),
          MxTextField(…unchanged…),
          …
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isSubmitting ? null : () => unawaited(_leave()),
```

Remove the now-unused `showMxSnackbar` import (`mx_snackbar.dart`) from this file.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart \
  test/features/deck/presentation/create_root_deck_dialog_widget_test.dart
git commit -m "fix(deck): the create-root dialog holds while it writes, never asks to discard over a write, and keeps its failure inside (SP2b 2.26, 2.27)"
```

Goldens: none.

---

### Task 6 (A6): Reset dialog — hold, failure inside, summary Retry (2.26, 2.27, 2.28)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart` (imports 1-26, `_reset` 57-83, `build` 85-150)
- Create: `test/features/deck/presentation/deck_reset_failure_test.dart`
- Modify: `test/features/deck/presentation/deck_algorithm_golden_test.dart` (a new golden after `reset dialog`)

**Interfaces:**
- Consumes: A1, A3's `WriteHold`.
- A new file keeps `deck_reset_dialog_test.dart` (328 lines) under the file-size guard.
- Behaviour:
  - A reset write failure shows the banner and no toast; Reset is the retry.
  - A failed summary read (`AsyncError`) leaves the body empty and leads the content with a warning banner that has a compact Retry (`commonRetry`). Retry calls `ref.invalidate(resetLearningSummaryProvider(id))`.
  - A typed `Rejected` (deck gone) keeps its body message and has no retry.
  - Cancel stays live in the summary-failed state.

- [ ] **Step 1: Write the failing tests.** Create `deck_reset_failure_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The real schedules, except that the first [summaryFailures] summary reads
/// throw, a [summaryRejection] refuses the summary, and a reset waits on
/// [hold] (UC-SRS-001 E1; SP2b 2.26, 2.28).
final class _FlakySchedules implements ScheduleRepository {
  _FlakySchedules(this._real, this.hold);

  final ScheduleRepository _real;
  final WriteHold hold;
  int summaryFailures = 0;
  SrsRejection? summaryRejection;

  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) async {
    if (summaryFailures > 0) {
      summaryFailures--;
      throw WriteHold.failure;
    }
    if (summaryRejection case final reason?) return Rejected(reason);
    return _real.resetSummary(rootDeckId: rootDeckId);
  }

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) async {
    await hold.pass();
    return _real.resetLearning(
      rootDeckId: rootDeckId,
      schedulerType: schedulerType,
    );
  }

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  }) => _real.changeScheduler(rootDeckId: rootDeckId, newType: newType);

  @override
  Future<void> initializeCard({required String cardId}) =>
      _real.initializeCard(cardId: cardId);

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) =>
      _real.recordTurn(turn);

  @override
  Future<(SchedulerType, CardScheduleState)?> scheduleOf({
    required String cardId,
  }) => _real.scheduleOf(cardId: cardId);

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) =>
      _real.completeLearning(cardId: cardId, generation: generation, now: now);
}

Future<void> _openReset(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text(_en.algorithmResetAction),
    200,
    scrollable: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.algorithmResetAction));
  await tester.pumpAndSettle();
}

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

/// A locked sm2 root over [schedules], its reset dialog open.
Future<void> _pumpOpen(
  WidgetTester tester,
  LibraryEnv env,
  _FlakySchedules Function(ScheduleRepository real) make,
) async {
  final korean = await env.decks.root('Korean', SchedulerType.sm2);
  await lockScheduler(env.db, korean.id);
  await pumpLibraryScreen(
    tester,
    env,
    deckAlgorithmScreen(deckId: korean.id),
    overrides: [
      scheduleRepositoryProvider.overrideWithValue(
        make(ScheduleRepositoryImpl(env.db)),
      ),
    ],
  );
  await _openReset(tester);
}

void main() {
  libraryTest('a failed summary read says so with Retry; Cancel stays live; '
      'Retry reads again (SP2b 2.28)', (tester, env) async {
    await _pumpOpen(
      tester,
      env,
      (real) => _FlakySchedules(real, WriteHold()..open())..summaryFailures = 1,
    );

    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    var actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNull);
    expect(actions.onCancel, isNotNull);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.resetNothingToLose), findsOneWidget);
    actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNotNull);
  });

  libraryTest('a deck gone meanwhile keeps its message, has no Retry and '
      'leaves the confirm off (SP2b 2.28)', (tester, env) async {
    await _pumpOpen(
      tester,
      env,
      (real) =>
          _FlakySchedules(real, WriteHold()..open())
            ..summaryRejection = SrsRejection.notFound,
    );

    expect(find.text(_en.srsRejection(SrsRejection.notFound)), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onConfirm,
      isNull,
    );
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(_en.resetDialogTitle), findsNothing);
  });

  libraryTest('Back and a scrim tap wait for the reset; a failure keeps the '
      'dialog with a banner and the confirm retries (SP2b 2.26, 2.27)', (
    tester,
    env,
  ) async {
    final hold = WriteHold();
    await _pumpOpen(tester, env, (real) => _FlakySchedules(real, hold));
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDialog), findsOneWidget);

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();
    expect(find.text(_en.resetDialogTitle), findsNothing);
    expect(find.text(_en.resetDoneToast(2, 0)), findsOneWidget);
  });
}
```

Golden test: in `deck_algorithm_golden_test.dart` add the imports `package:memox/core/error/outcome.dart`, `package:memox/features/deck/presentation/providers/reset_learning_summary_provider.dart`, `package:memox/features/srs/domain/failures/srs_failure.dart`, `package:memox/features/srs/domain/models/reset_learning_summary_model.dart`, `../../../support/held_writes.dart`, and after the `reset dialog` test:

```dart
    libraryTest('reset dialog, summary failed, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await lockScheduler(env.db, korean.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckAlgorithmScreen(deckId: korean.id),
          brightness,
          overrides: [
            resetLearningSummaryProvider(korean.id).overrideWith(
              (ref) => Future<Outcome<ResetLearningSummary, SrsRejection>>.error(
                WriteHold.failure,
              ),
            ),
          ],
        );
        await tester.tap(find.text(_en.algorithmResetAction));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(_en.commonRetry), findsOneWidget);
        await expectBoundaryGolden(
          tester,
          'goldens/library_algorithm_reset_failed_$theme.png',
        );
      });
    });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_reset_failure_test.dart`
Expected: FAIL. Test 1 finds no banner and no Retry (the failure is plain body text). Test 3 finds the dialog closed after Back (it is not held) or a toast in place of the banner. Test 2 already passes: the rejection message, the missing Retry, the off confirm and the live Cancel are today's behaviour, and the test pins them so 2.28's Retry does not leak into the typed case.

- [ ] **Step 3: Implement.** Add imports `package:memox/shared/widgets/mx_button.dart` and `package:memox/shared/widgets/mx_inline_banner.dart`. In the state class add

```dart
  /// The last reset's failure, shown in the dialog until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_reset` (lines 57-83): the opening line and the catch become

```dart
    setState(() {
      _isResetting = true;
      _failure = null;
    });
    …
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck reset');
      if (!mounted) return;
      // E1: rolled back; the dialog stays for another try.
      setState(() {
        _isResetting = false;
        _failure = failure;
      });
    }
```

`build`: replace the `AsyncError` branch of `body` (it moves into the banner) and rewrite the dialog head:

```dart
    final body = switch (value) {
      AsyncData(value: Ok(:final value)) when !value.hasProgressToLose =>
        l10n.resetNothingToLose,
      AsyncData(value: Ok(:final value)) => l10n.resetDialogIntro(
        _nextCycle(view),
        view.deck.name,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.srsRejection(reason),
      _ => null,
    };
    // A failed summary read: Retry reads it again; Cancel stays live, so the
    // dialog is never a dead end (SP2b 2.28).
    final summaryFailure = switch (value) {
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    final failure = _failure;
    return MxDialog(
      isHeld: _isResetting,
      title: l10n.resetDialogTitle,
      body: body,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.failure(failure),
            ),
          if (summaryFailure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: summaryFailure,
              actions: [
                MxButton(
                  label: l10n.commonRetry,
                  size: MxButtonSize.compact,
                  isLoading: value.isLoading,
                  onPressed: () =>
                      ref.invalidate(resetLearningSummaryProvider(view.deck.id)),
                ),
              ],
            ),
          if (value.isLoading && !value.hasError)
            MxSkeletonList(semanticLabel: context.l10n.commonLoading, rows: 1),
          …rest of the children unchanged…
```

Remove the now-unused `showMxSnackbar` call in the catch only; the success path still toasts, so the `mx_snackbar.dart` import stays.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_reset_failure_test.dart test/features/deck/presentation/deck_reset_dialog_test.dart test/features/deck/presentation/deck_reset_wiring_test.dart`
Expected: PASS (the old "a reset that fails keeps the dialog for another try" test still passes: it finds the failure text once, now in the banner).

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart \
  test/features/deck/presentation/deck_reset_failure_test.dart \
  test/features/deck/presentation/deck_algorithm_golden_test.dart
git commit -m "fix(deck): the reset dialog holds, keeps its failure inside and retries a failed summary (SP2b 2.26, 2.27, 2.28)"
```

Goldens: none move. One new golden test, `library_algorithm_reset_failed_{light,dark}`.

---

### Task 7 (A7): Deck move sheet (screen 01) holds and keeps its failure inside (2.26, 2.27)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart` (imports 1-18, `_move` 48-70, picker call 77-96)
- Create: `test/features/deck/presentation/deck_move_sheet_test.dart`

**Interfaces:**
- Consumes: A1, A2 (`MxDeckPickerSheet.isHeld` and `banner`), A3's `HeldDecks`.

- [ ] **Step 1: Write the failing tests.** Create `deck_move_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/usecases/move_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/move_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _exit = Duration(milliseconds: 500);

Widget _host(DeckEntity deck) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showMoveDeckSheet(context, deck: deck),
    ),
  ),
);

/// Korean › {Words, Grammar}, the sheet open over Grammar, its move behind
/// the returned hold.
Future<({WriteHold hold, DeckEntity grammar, DeckEntity words})> _open(
  WidgetTester tester,
  LibraryEnv env,
) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final grammar = await env.decks.sub(korean.id, 'Grammar');
  final hold = WriteHold();
  await pumpLibraryScreen(
    tester,
    env,
    _host(grammar),
    overrides: [
      moveDeckUseCaseProvider.overrideWithValue(
        MoveDeckUseCase(HeldDecks(env.decks, hold)),
      ),
    ],
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (hold: hold, grammar: grammar, words: words);
}

void main() {
  libraryTest('Back, a scrim tap and Cancel wait for the move; its toast then '
      'arrives (SP2b 2.26)', (tester, env) async {
    final (:hold, :grammar, :words) = await _open(tester, env);
    await tester.tap(find.text('Korean › Words'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(_exit);
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(_exit);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect((await env.decks.findById(grammar.id))!.parentId, words.id);
  });

  libraryTest('a failed move keeps the sheet with a banner; choosing again is '
      'the retry (SP2b 2.27)', (tester, env) async {
    final (:hold, :grammar, :words) = await _open(tester, env);
    hold
      ..open()
      ..failNext();
    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failure(WriteHold.failure)),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester
          .widget<MxListRow>(find.widgetWithText(MxListRow, 'Korean › Words'))
          .isEnabled,
      isTrue,
    );

    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(hold.calls, 2);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect((await env.decks.findById(grammar.id))!.parentId, words.id);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_move_sheet_test.dart`
Expected: FAIL. Test 1 finds the sheet gone (the sheet is not held); test 2 finds a toast and no banner.

- [ ] **Step 3: Implement.** Add `import 'package:memox/shared/widgets/mx_inline_banner.dart';`. In the state class add

```dart
  /// The last move's failure, shown in the sheet until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_move`: `setState(() { _isMoving = true; _failure = null; });` and the catch

```dart
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck move');
      if (!mounted) return;
      setState(() {
        _isMoving = false;
        _failure = failure;
      });
    }
```

In `build`, the `MxDeckPickerSheet(` call gets two arguments after `emptyBody`:

```dart
        isHeld: _isMoving,
        banner: switch (_failure) {
          final failure? => MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.failure(failure),
          ),
          null => null,
        },
```

Remove the unused `Failure`-toast path: `showMxSnackbar` stays for the success and `Rejected` toast.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_move_sheet_test.dart test/features/deck/presentation/deck_action_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart \
  test/features/deck/presentation/deck_move_sheet_test.dart
git commit -m "fix(deck): the move sheet holds while it writes and keeps its failure inside (SP2b 2.26, 2.27)"
```

Goldens: none.

---

### Task 8 (A8): Card move sheet and card tag dialog (screen 07) (2.26, 2.27)

**Files:**
- Modify: `lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart` (imports 1-19, `_move` 65-106, picker call 113-131)
- Modify: `lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart` (imports 1-16, state 45-151)
- Create: `test/features/card/presentation/card_bulk_write_hold_test.dart`

**Interfaces:**
- Consumes: A1, A2, A3's `HeldCards` and `HeldTags`, and the harness in `card_bulk_actions_harness.dart` (`seedBulkCards`, `bulkSection`, `selectCards`, `tapBulk`, `inDialog`, `enL10n`).
- The tag dialog (a field dialog) gets `isHeld: _isSubmitting`; the move sheet gets the picker's `isHeld` and `banner`. Both keep the selection on failure, as today.

- [ ] **Step 1: Write the failing tests.** Create `card_bulk_write_hold_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/usecases/add_tag_to_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/move_cards_use_case.dart';
import 'package:memox/features/card/presentation/providers/add_tag_to_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

const _exit = Duration(milliseconds: 500);

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

Future<void> _backAndScrim(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump(_exit);
  await tester.tapAt(const Offset(2, 2));
  await tester.pump(_exit);
}

void main() {
  libraryTest('Move: Back, a scrim tap and Cancel wait for the move; a failure '
      'keeps the sheet with a banner and choosing again retries (SP2b 2.26, '
      '2.27)', (tester, env) async {
    final ids = await seedBulkCards(env);
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      bulkSection(ids.words),
      overrides: [
        moveCardsUseCaseProvider.overrideWithValue(
          MoveCardsUseCase(HeldCards(env.cards, hold)),
        ),
      ],
    );
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pump();

    await _backAndScrim(tester);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
          .onPressed,
      isNull,
    );

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(_banner(enL10n.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(find.text(enL10n.cardMovedToast(2, 'Verbs')), findsOneWidget);
  });

  libraryTest('Tag: Back, a scrim tap and Cancel wait for the write; a failure '
      'keeps the dialog, the name and the selection (SP2b 2.26, 2.27)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      bulkSection(ids.words),
      overrides: [
        addTagToCardsUseCaseProvider.overrideWithValue(
          AddTagToCardsUseCase(HeldTags(TagRepositoryImpl(env.db), hold)),
        ),
      ],
    );
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pump();

    await _backAndScrim(tester);
    expect(find.byType(MxDialog), findsOneWidget);

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text('greetings'), findsOneWidget);
    expect(_banner(enL10n.failure(WriteHold.failure)), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsNWidgets(2),
    );

    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(enL10n.cardTaggedToast(2, 'greetings')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/card/presentation/card_bulk_write_hold_test.dart`
Expected: FAIL. Both tests find the sheet or dialog gone after Back or the scrim, and a toast in place of the banner.

- [ ] **Step 3: Implement.**

`card_move_sheet_widget.dart`: add `import 'package:memox/shared/widgets/mx_inline_banner.dart';`, the field `Failure? _failure;` (doc: "shown in the sheet until the next try (SP2b 2.27)"), `setState(() { _isMoving = true; _failure = null; });` and the catch

```dart
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'card move');
      if (!mounted) return;
      setState(() {
        _isMoving = false;
        _failure = failure;
      });
    }
```

The `MxDeckPickerSheet(` call gets, after `emptyBody:`,

```dart
        isHeld: _isMoving,
        banner: switch (_failure) {
          final failure? => MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.failure(failure),
          ),
          null => null,
        },
```

`card_tag_dialog_widget.dart`: add the `mx_inline_banner.dart` import and the field next to `_isSubmitting`:

```dart
  var _isSubmitting = false;

  /// The last write's failure, shown above the field until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_submit`: the opening `setState` also sets `_failure = null`; the catch becomes

```dart
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'card tag');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _failure = failure;
      });
    }
```

`build`:

```dart
    final failure = _failure;
    return MxDialog(
      // The toast and the cleared selection must reach the screen (SP2b 2.26).
      isHeld: _isSubmitting,
      title: l10n.cardTagTitle,
      content: Column(
        …
        children: [
          if (failure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.failure(failure),
            ),
          MxTextField(…unchanged…),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        …
```

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/card/presentation/card_bulk_write_hold_test.dart test/features/card/presentation/card_bulk_actions_test.dart test/features/card/presentation/card_bulk_gone_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart \
  lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart \
  test/features/card/presentation/card_bulk_write_hold_test.dart
git commit -m "fix(card): the move sheet and the tag dialog hold while they write and keep their failure inside (SP2b 2.26, 2.27)"
```

Goldens: none.

---

### Task 9 (A9): Trash restore sheet (screen 06) (2.26, 2.27)

**Files:**
- Modify: `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart` (imports 1-22, `_restore` 64-113, picker call 145-161)
- Test: `test/features/trash/presentation/trash_restore_test.dart` (130 lines; two tests appended)

**Interfaces:**
- Consumes: A1, A2, A3's `HeldCards`. The restore sheet is the third picker sheet; the same change as A7.

- [ ] **Step 1: Write the failing tests.** Add imports `package:memox/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart`, `package:memox/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart`, `package:memox/l10n/failure_message.dart`, `package:memox/shared/widgets/mx_button.dart`, `package:memox/shared/widgets/mx_inline_banner.dart`, `../../../support/held_writes.dart`. Append inside `main()`:

```dart
  libraryTest('Back, a scrim tap and Cancel wait for the restore; its toast '
      'then arrives (SP2b 2.26)', (tester, env) async {
    await seedTrash(env);
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        restoreCardsFromTrashUseCaseProvider.overrideWithValue(
          RestoreCardsFromTrashUseCase(HeldCards(env.cards, hold)),
        ),
      ],
    );
    await _openRestore(tester, 'meokda · eat');
    await tester.tap(_inSheet('Korean › Words'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonCancel))
          .onPressed,
      isNull,
    );

    hold.open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(
      find.text(_en.trashRestoredOne('meokda · eat', 'Words')),
      findsOneWidget,
    );
    expect(await _isActive(env, 'card', 'meokda'), isTrue);
  });

  libraryTest('a failed restore keeps the sheet with a banner; choosing again '
      'retries (SP2b 2.27)', (tester, env) async {
    await seedTrash(env);
    final hold = WriteHold()
      ..open()
      ..failNext();
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        restoreCardsFromTrashUseCaseProvider.overrideWithValue(
          RestoreCardsFromTrashUseCase(HeldCards(env.cards, hold)),
        ),
      ],
    );
    await _openRestore(tester, 'meokda · eat');
    await tester.tap(_inSheet('Korean › Words'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failure(WriteHold.failure)),
      ),
      findsOneWidget,
    );
    expect(await _isActive(env, 'card', 'meokda'), isFalse);

    await tester.tap(_inSheet('Korean › Words'));
    await tester.pumpAndSettle();
    expect(await _isActive(env, 'card', 'meokda'), isTrue);
    expect(
      find.text(_en.trashRestoredOne('meokda · eat', 'Words')),
      findsOneWidget,
    );
  });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/trash/presentation/trash_restore_test.dart`
Expected: FAIL. The first finds the sheet gone after Back or the scrim; the second finds a toast in place of the banner.

- [ ] **Step 3: Implement.** Add `import 'package:memox/shared/widgets/mx_inline_banner.dart';`. In the state class:

```dart
  var _isRestoring = false;

  /// The last restore's failure, shown in the sheet until the next try
  /// (SP2b 2.27).
  Failure? _failure;
```

`_restore`: `setState(() { _isRestoring = true; _failure = null; });` and the catch

```dart
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'trash restore');
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _failure = failure;
      });
    }
```

The `MxDeckPickerSheet(` call gets, after `emptyBody: _emptyBody(l10n),`:

```dart
        isHeld: _isRestoring,
        banner: switch (_failure) {
          final failure? => MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.failure(failure),
          ),
          null => null,
        },
```

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/trash/presentation/trash_restore_test.dart test/features/trash/presentation/trash_selection_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart \
  test/features/trash/presentation/trash_restore_test.dart
git commit -m "fix(trash): the restore sheet holds while it writes and keeps its failure inside (SP2b 2.26, 2.27)"
```

Goldens: none (`trash_restore_target` draws neither the hold nor the banner).

---

### Task 10 (A10): A non-`Failure` from the starter add no longer holds the sheet forever (2.29)

**Files:**
- Modify: `lib/features/starter_decks/presentation/controllers/starter_add_controller.dart` (imports 1-7, catch 43-46)
- Modify: `test/support/starter_screen_fixtures.dart` (`StarterLibraryFake`, the add at the end of the class)
- Test: `test/features/starter_decks/presentation/starter_add_controller_test.dart`

**Interfaces:**
- Produces (test support): `StarterLibraryFake.addError`, an `Object?`. When set, every add throws it after the hold.
- Behaviour: a non-`Failure` is reported with `FlutterError.reportError` (library `'starter add'`), as the import-undo dialog does. Both kinds set `hasFailed: true` and clear `isAdding`, so the sheet reads "Try again" and Back is released.

- [ ] **Step 1: Write the failing test.** In `starter_screen_fixtures.dart` add the field after `hold` and the throw after `await hold?.future;`:

```dart
  /// When set, every add throws it, a non-`Failure` included (SP2b 2.29).
  Object? addError;
  …
    await hold?.future;
    if (addError case final error?) throw error;
    if (failsAdds) {
```

In `starter_add_controller_test.dart` add `import 'package:flutter/foundation.dart';` and append inside `main()`:

```dart
  test('a non-Failure from the add ends in hasFailed, not isAdding, and is '
      'reported; the next add works (SP2b 2.29)', () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    library.addError = StateError('bad row');

    expect(await add(), isNull);

    final state = container.read(starterAddControllerProvider);
    expect((state.hasFailed, state.isAdding), (true, false));
    expect(reported.single.exception, isA<StateError>());
    expect(reported.single.library, 'starter add');

    library.addError = null;
    expect(await add(), isA<StarterAdded>());
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/starter_decks/presentation/starter_add_controller_test.dart`
Expected: FAIL. The `StateError` escapes `add()` (only `Failure` is caught), so the test throws and `isAdding` stays true.

- [ ] **Step 3: Implement.** In `starter_add_controller.dart` add `import 'package:flutter/foundation.dart';` and replace the catch (lines 43-46):

```dart
    } on Object catch (error, stack) {
      // A database `Failure` reads as a failed add; anything else the add
      // threw is reported as the import undo's catch-all does. Both end in
      // hasFailed, so the sheet reads "Try again" and Back is released
      // (SP2b 2.29).
      if (error is! Failure) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'starter add',
          ),
        );
      }
      if (ref.mounted) state = const StarterAddState(hasFailed: true);
      return null;
    }
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/starter_decks/presentation/starter_add_controller_test.dart`
Expected: PASS. Then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/starter_decks`; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/starter_decks/presentation/controllers/starter_add_controller.dart \
  test/support/starter_screen_fixtures.dart \
  test/features/starter_decks/presentation/starter_add_controller_test.dart
git commit -m "fix(starter): a non-Failure from the add reports and releases the sheet (SP2b 2.29)"
```

Goldens: none (`starter_add_failed_*` is unchanged: same state, a `Failure`).

---

### Task 11 (A11): Settings reset keeps the dialog on a failed write (2.33)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart` (whole class, 31-61)
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart` (line 163, the `(SettingsSaveFailed(), SettingsSubmit.reset)` toast row)
- Modify: `lib/l10n/app_en.arb` (the `@settingsResetFailed` description, line 5363)
- Modify: `test/features/settings/presentation/settings_screen_test.dart` (the test at 83-116)
- Create: `test/features/settings/presentation/settings_reset_dialog_test.dart`
- Modify: `test/features/settings/presentation/settings_screen_golden_test.dart` (a new golden after `reset done`)

**Interfaces:**
- Consumes: `SettingsController.reset()` (`Future<bool>`, `settings_controller.dart:127`), `MxDialog.isHeld`, A1.
- Behaviour:
  - `_reset()` pops on true.
  - On false it releases the dialog and shows the warning banner `settingsResetFailed` inside it; the confirm reads "Retry" (`commonRetry`) and is the retry, so it goes through the dialog again.
  - The screen's toast for `(SettingsSaveFailed, reset)` goes. The success toast stays.
  - The dialog's own `PopScope` is replaced by `MxDialog.isHeld`.

- [ ] **Step 1: Write the failing tests.** Create `settings_reset_dialog_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host() => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () => showSettingsResetDialog(context),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a failed reset keeps the dialog with the banner; the confirm '
      'reads Retry and runs it again (SP2b 2.33)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await _open(tester);
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.settingsResetFailed),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsResetConfirm), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(store.writes, 2);
  });

  libraryTest('Back and a scrim tap wait while the reset runs; released, the '
      'dialog closes (SP2b 2.33)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..hold = Completer<void>();
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await _open(tester);
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDialog), findsOneWidget);

    store.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });
}
```

In `settings_screen_test.dart`, replace the body of the test `reset: onAppOptionsReset runs once on success, never on failure` from `store.isFailing = true;` to its last `expect` with:

```dart
    store.isFailing = true;
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    // M3-B3: the dialog's footer is the stock MxSheetActions pair.
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).confirmLabel,
      _en.settingsResetConfirm,
    );
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 0);
    // The dialog owns the failure (SP2b 2.33): it stays, with no toast.
    expect(find.text(_en.settingsResetFailed), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(resets, 1);
    expect(find.text(_en.settingsResetBody), findsNothing, reason: 'closed');
```

Golden test: in `settings_screen_golden_test.dart` add after the `reset done` test:

```dart
    libraryTest('settings, reset failed, $theme', (tester, env) async {
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.text(_en.settingsResetRow));
        await _settle(tester);
        await tester.tap(find.text(_en.settingsResetConfirm));
        await _settle(tester);
        expect(find.text(_en.settingsResetFailed), findsOneWidget);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_reset_failed_$theme.png',
        );
      });
    });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/settings/presentation/settings_reset_dialog_test.dart test/features/settings/presentation/settings_screen_test.dart`
Expected: FAIL. Today a failed reset pops the dialog and toasts, so `find.byType(MxDialog)` finds nothing and the confirm never reads Retry.

- [ ] **Step 3: Implement.** Replace the state class in `settings_reset_dialog_widget.dart`; add imports `package:memox/core/theme/foundations/app_spacing.dart`, `package:memox/l10n/failure_message.dart` and `package:memox/shared/widgets/mx_inline_banner.dart`:

```dart
class _SettingsResetDialogWidgetState
    extends ConsumerState<SettingsResetDialogWidget> {
  var _isResetting = false;

  /// The last reset wrote nothing: the banner shows and the confirm reads
  /// Retry (SP2b 2.33).
  var _hasFailed = false;

  Future<void> _reset() async {
    if (_isResetting) return;
    setState(() {
      _isResetting = true;
      _hasFailed = false;
    });
    var hasReset = false;
    try {
      hasReset = await ref.read(settingsControllerProvider.notifier).reset();
    } on Object catch (error, stack) {
      // `reset()` answers false for a database Failure; anything else it
      // threw is reported, and the dialog is released all the same.
      failureOfThrown(error, stack, library: 'settings reset');
    }
    if (!mounted) return;
    if (hasReset) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isResetting = false;
      _hasFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      // While it runs, nothing may look like a cancel (BR-SETTINGS-008).
      isHeld: _isResetting,
      title: l10n.settingsResetTitle,
      body: l10n.settingsResetBody,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          if (_hasFailed)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.settingsResetFailed,
            ),
          MxNote(icon: AppIcons.safe, text: l10n.settingsResetSafe),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isResetting ? null : () => Navigator.of(context).pop(),
        confirmLabel: _hasFailed ? l10n.commonRetry : l10n.settingsResetConfirm,
        onConfirm: () => unawaited(_reset()),
        isConfirmLoading: _isResetting,
      ),
    );
  }
}
```

In `settings_screen.dart` delete the row `(SettingsSaveFailed(), SettingsSubmit.reset) => l10n.settingsResetFailed,` (line 163): the `_ => null` that follows ends the notice without a toast. In `app_en.arb` change the description of `@settingsResetFailed` to `"Banner inside the reset dialog when the reset failed (E2, SP2b 2.33); the confirm becomes Retry."`

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/settings/presentation/settings_reset_dialog_test.dart test/features/settings/presentation/settings_screen_test.dart test/features/settings/presentation/settings_controller_test.dart test/app/l10n_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart \
  lib/features/settings/presentation/screens/settings_screen.dart \
  lib/l10n/app_en.arb \
  test/features/settings/presentation/settings_reset_dialog_test.dart \
  test/features/settings/presentation/settings_screen_test.dart \
  test/features/settings/presentation/settings_screen_golden_test.dart
git commit -m "fix(settings): a failed reset keeps its dialog with an inline error and Retry (SP2b 2.33)"
```

Goldens: none move (`settings_reset_confirm` has the same layout: `MxNote` fills the width either way). One new golden test, `settings_reset_failed_{light,dark}`.

---

### Task 12 (A12): `sync_changes` returns the server time (2.30, R10, part 1: Supabase)

**Files:**
- Create: `supabase/migrations/20261011000000_sync_server_time.sql`
- Create: `supabase/tests/database/13_sync_server_time.sql`
- Modify: `supabase/tests/database/03_batches_and_changes.sql` (line 65)
- Modify: `docs/superpowers/specs/2026-09-28-supabase-backend-design.md` (§4.2, lines 135-144)

**Interfaces:**
- Produces: the `sync_changes` JSON gains `"serverTime"`: the server's `now()` as UTC epoch milliseconds (a number), on every page.
- DECISION: server time source = Option A (spec §4, DECISION 3): the server answers with its own clock. Recommended. Option B (the `iat` of the access token) needs no server change but couples trash safety to the auth layer and to token refresh timing. If the owner picks B, skip A12 and A13, and make A14's `ServerTimeReader` read the token's `iat`; A14's use case, wiring test and harness override keep the same shape.
- The RPC list in `supabase/README.md#rules` does not change (same function name and arguments).
- The new migration replaces the function whole: `create or replace` of the body of `20261002000000_study_history_sync.sql:399-448`, plus one key. `create or replace` keeps the grants of the first migration.

- [ ] **Step 1: Write the failing test.** Create `supabase/tests/database/13_sync_server_time.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
-- SP2b 2.30 (R10): every sync_changes page carries the server clock
-- (20261011000000_sync_server_time.sql).
insert into auth.users (id) values ('dddddddd-0000-0000-0000-000000000001') on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(jsonb_typeof(public.sync_changes(0, 500)->'serverTime'), 'number',
  'a page carries the server time as a number');
select ok(abs((public.sync_changes(0, 500)->>'serverTime')::bigint
    - (extract(epoch from now()) * 1000)::bigint) < 60000,
  'it is the server clock in UTC epoch milliseconds');
select is(jsonb_typeof(public.sync_changes(7, 1)->'serverTime'), 'number',
  'a page past the end carries it too');
select is(public.sync_changes(0, 500) - 'serverTime',
  '{"changes": [], "nextSince": 0, "hasMore": false}'::jsonb,
  'the rest of the page is as before');

select * from finish();
rollback;
```

In `03_batches_and_changes.sql` line 65 change the expression to ignore the new key:

```sql
select is(public.sync_changes(3, 500) - 'serverTime', '{"changes": [], "nextSince": 3, "hasMore": false}'::jsonb, 'an empty page keeps since');
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx supabase db start` then `npx supabase test db`
Expected: `13_sync_server_time.sql` FAILS (tests 1-3: `serverTime` is absent, so `jsonb_typeof` is null). Every other file passes, `03` included.

- [ ] **Step 3: Implement.** Create `20261011000000_sync_server_time.sql`:

```sql
-- SP2b 2.30 (R10): every sync_changes page also carries the server's clock, so the
-- app can tell a device clock set far ahead from a trustworthy one before the Trash
-- auto-purge deletes anything for good. As in 20261002000000, plus 'serverTime'.
create or replace function public.sync_changes(since bigint, max_rows integer) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_since bigint := coalesce(since, 0);
  v_limit integer := least(greatest(coalesce(max_rows, 500), 1), 500);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  with page as (
    select u.entity_type, u.id, u.server_version, row_number() over (order by u.server_version) as n
    from (
      (select 'deck' as entity_type, d.id, d.server_version from public.deck d
       where d.user_id = v_user and d.server_version > v_since
       order by d.server_version limit v_limit + 1)
      union all
      (select 'delete_batch', b.id, b.server_version from public.delete_batch b
       where b.user_id = v_user and b.server_version > v_since
       order by b.server_version limit v_limit + 1)
      union all
      (select 'card', c.id, c.server_version from public.card c
       where c.user_id = v_user and c.server_version > v_since
       order by c.server_version limit v_limit + 1)
      union all
      (select 'tag', t.id, t.server_version from public.tags t
       where t.user_id = v_user and t.server_version > v_since
       order by t.server_version limit v_limit + 1)
      union all
      (select 'account_settings', '00000000-0000-0000-0000-000000000000'::uuid, s.server_version
       from public.account_settings s
       where s.user_id = v_user and s.server_version > v_since
       order by s.server_version limit v_limit + 1)
      union all
      (select 'card_schedule', cs.card_id, cs.server_version from public.card_schedule cs
       where cs.user_id = v_user and cs.server_version > v_since
       order by cs.server_version limit v_limit + 1)
      union all
      (select 'review_log', rl.id, rl.server_version from public.review_log rl
       where rl.user_id = v_user and rl.server_version > v_since
       order by rl.server_version limit v_limit + 1)
    ) u
    order by u.server_version limit v_limit + 1
  )
  select coalesce(jsonb_agg(private.current_change(v_user, p.entity_type, p.id) order by p.server_version)
           filter (where p.n <= v_limit), '[]'),
         max(p.server_version) filter (where p.n <= v_limit),
         count(*) > v_limit
  into v_changes, v_next, v_more
  from page p;
  return jsonb_build_object('changes', v_changes, 'nextSince', coalesce(v_next, v_since), 'hasMore', v_more,
    'serverTime', (extract(epoch from now()) * 1000)::bigint);
end
$$;
```

Before committing, diff the body against `20261002000000_study_history_sync.sql:399-448`: the only difference must be the added `'serverTime'` key.

Docs: in the supabase backend spec §4.2 change

```
- `max_rows` is clamped to 1..500. Returns `ChangesResponseModel`:
  `{"changes": [...], "nextSince", "hasMore"}`.
```
to
```
- `max_rows` is clamped to 1..500. Returns `ChangesResponseModel`:
  `{"changes": [...], "nextSince", "hasMore", "serverTime"}`.
- `serverTime` is the server's `now()` as UTC epoch milliseconds (SP2b 2.30,
  R10). The app stores it at each pull and the Trash auto-purge waits unless
  the device clock agrees with it within one day (BR-TRASH-009).
```

- [ ] **Step 4: Run to verify it passes**

Run: `npx supabase db reset` then `npx supabase test db`
Expected: all 13 files pass, `13_sync_server_time.sql` included (4 of 4).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261011000000_sync_server_time.sql \
  supabase/tests/database/13_sync_server_time.sql \
  supabase/tests/database/03_batches_and_changes.sql \
  docs/superpowers/specs/2026-09-28-supabase-backend-design.md
git commit -m "feat(supabase): sync_changes returns the server time (SP2b 2.30, R10)"
```

Goldens: none.

---

### Task 13 (A13): The pull stores the server time (2.30, R10, part 2: client)

**Files:**
- Modify: `lib/core/database/tables/sync_keys.dart` (a new key after `syncPullEntityTypesKey`, line 26)
- Modify: `lib/core/sync/sync_models.dart` (`ChangesResponseModel`, 104-117)
- Modify: `lib/core/sync/sync_store.dart` (after `setPullEntityTypes`, line 38)
- Modify: `lib/core/sync/sync_coordinator.dart` (`_pull`, 176-208)
- Modify: `test/core/sync/fake_sync_server.dart` (`changes`, 73-85)
- Modify: `test/core/sync/sync_models_test.dart` (one test appended)
- Create: `test/core/sync/sync_server_time_test.dart`

**Interfaces:**
- Produces:
  - `ChangesResponseModel({…, int? serverTime})`, nullable, default null.
  - `Future<void> SyncStore.recordServerTime(DateTime at)`, which stores UTC epoch milliseconds under `syncServerTimeKey = 'server_time'`.
  - `Future<DateTime?> SyncStore.serverTime()`, UTC, or null when never stored.
- The pull loop remembers the last non-null `serverTime` of its pages and records it in the same transaction as `setSince`, so a page without it (an old server) keeps the earlier value. `LocalDataReset` deletes every `sync_state` row except the device id, so a sign-out or account switch also clears it, and the purge waits for the next sync.
- Generated `*.g.dart` files are not committed; run `dart run build_runner build --delete-conflicting-outputs` after the model change.

- [ ] **Step 1: Write the failing tests.** In `fake_sync_server.dart` add a field after `failChangesAfter` and pass it:

```dart
  /// The server clock a page reports, UTC epoch milliseconds; null plays an
  /// old server that sends none (SP2b 2.30).
  int? serverTimeMillis;
  …
    return ChangesResponseModel(
      changes: page,
      nextSince: page.isEmpty ? since : page.last.serverVersion,
      hasMore: sorted.length > limit,
      serverTime: serverTimeMillis,
    );
```

Append to `sync_models_test.dart` inside `main()`:

```dart
  test('a changes page carries the server time when the server sends it', () {
    final base = {'changes': <Object?>[], 'nextSince': 0, 'hasMore': false};

    expect(
      ChangesResponseModel.fromJson({
        ...base,
        'serverTime': 1790000000000,
      }).serverTime,
      1790000000000,
    );
    expect(ChangesResponseModel.fromJson(base).serverTime, isNull);
  });
```

Create `sync_server_time_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

// SP2b 2.30 (R10): the server's clock as of the last pull, kept for the Trash
// auto-purge to compare with the device clock.
void main() {
  late AppDatabase db;
  late SyncStore store;
  late FakeSyncServer server;
  late SyncCoordinator coordinator;
  final seen = DateTime.utc(2026, 10, 3, 8);

  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
    server = FakeSyncServer();
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [DeckSyncAdapter(db)],
    );
  });
  tearDown(() => db.close());

  test('no server time is known before the first sync', () async {
    expect(await store.serverTime(), isNull);
  });

  test('the store keeps the time as UTC milliseconds', () async {
    await store.recordServerTime(seen);

    expect(await store.serverTime(), seen);
  });

  test('a pull stores the server time of its page', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;

    await coordinator.runOnce();

    expect(await store.serverTime(), seen);
  });

  test('a page without it keeps the last one (an old server)', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;
    await coordinator.runOnce();
    server.serverTimeMillis = null;

    await coordinator.runOnce();

    expect(await store.serverTime(), seen);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `dart run build_runner build --delete-conflicting-outputs` then `flutter test test/core/sync/sync_models_test.dart test/core/sync/sync_server_time_test.dart`
Expected: FAIL to compile (`serverTime` is not a field of `ChangesResponseModel`; `recordServerTime` and `serverTime()` do not exist).

- [ ] **Step 3: Implement.**

`sync_keys.dart`:

```dart
/// The server's clock as of the last pull: UTC epoch milliseconds (SP2b 2.30,
/// R10). The Trash auto-purge compares the device clock with it.
const syncServerTimeKey = 'server_time';
```

`sync_models.dart`, `ChangesResponseModel`:

```dart
  const ChangesResponseModel({
    required this.changes,
    required this.nextSince,
    required this.hasMore,
    this.serverTime,
  });
  …
  final bool hasMore;

  /// The server's clock when it answered, UTC epoch milliseconds. Null from a
  /// server that does not send it yet (SP2b 2.30, R10).
  final int? serverTime;
```

`sync_store.dart`, after `setPullEntityTypes`:

```dart
  /// The server clock of the last pull (SP2b 2.30, R10); null before the
  /// first sync, or against a server that sends none.
  Future<DateTime?> serverTime() async =>
      _fromMillis(await _value(syncServerTimeKey));

  Future<void> recordServerTime(DateTime at) =>
      _put(syncServerTimeKey, _millis(at));
```

`sync_coordinator.dart`, `_pull`:

```dart
    final changes = <SyncChangeModel>[];
    int? serverTime;
    while (true) {
      final page = await _api.changes(since, _pullLimit);
      changes.addAll(page.changes);
      since = page.nextSince;
      // The last page that carries it is the freshest reading (R10).
      serverTime = page.serverTime ?? serverTime;
      if (!page.hasMore) {
        break;
      }
    }
    final seenAt = serverTime == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(serverTime, isUtc: true);
    await _store.applyingRemote(deferForeignKeys: true, () async {
      …
      await _store.setSince(since);
      await _store.setPullEntityTypes(types);
      if (seenAt != null) await _store.recordServerTime(seenAt);
    });
```

Then run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync`
Expected: PASS (the new tests and every existing sync test).

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/tables/sync_keys.dart lib/core/sync/sync_models.dart \
  lib/core/sync/sync_store.dart lib/core/sync/sync_coordinator.dart \
  test/core/sync/fake_sync_server.dart test/core/sync/sync_models_test.dart \
  test/core/sync/sync_server_time_test.dart
git commit -m "feat(sync): the pull stores the server time for the Trash auto-purge (SP2b 2.30, R10)"
```

Goldens: none.

---

### Task 14 (A14): The Trash auto-purge waits unless the clock agrees with the server (2.30, R10, part 3)

**Files:**
- Modify: `lib/features/trash/domain/entities/trash_entry_entity.dart` (after `trashCutoff`, line 11)
- Modify: `lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart` (whole file)
- Modify: `lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart` (whole file)
- Modify: `test/support/library_harness.dart` (`_backend`, line 98-107, and the imports)
- Modify: `test/features/trash/domain/trash_use_cases_test.dart` (line 107 and new tests)
- Create: `test/features/trash/presentation/purge_expired_wiring_test.dart`
- Modify: `docs/features/trash/rules/BR-TRASH-009-retention-30-ngay.md`, `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`

**Interfaces:**
- Produces:
  - `const purgeClockTolerance = Duration(days: 1)`, beside `trashRetention`.
  - `bool isTrashClockTrusted(DateTime now, DateTime? serverTime)`: false for null, true when `now.difference(serverTime).abs() <= purgeClockTolerance` (the bound is inclusive).
  - `typedef ServerTimeReader = Future<DateTime?> Function()` (trash domain, in `purge_expired_trash_use_case.dart`).
  - `PurgeExpiredTrashUseCase(TrashRepository, DayClock, ServerTimeReader)`. `call()` returns an empty `PurgeReport` when the clock is not trusted, and does not touch the store. Manual `purge(batchIds)` is untouched here (but see A18).
- The provider passes `ref.watch(syncStoreProvider).serverTime`.
- The library test harness overrides `purgeExpiredTrashUseCaseProvider` with a reader that agrees with the fake day, so every existing Trash and app test keeps purging. The real wiring has its own test.
- Consumes: A13's `SyncStore.serverTime()`.

- [ ] **Step 1: Write the failing tests.** In `trash_use_cases_test.dart`, change line 107 to pass a reader that agrees with the clock:

```dart
    expect(
      (await PurgeExpiredTrashUseCase(trash, clock, () async => clock.now())())
          .purged,
      {last},
    );
```

and append inside `main()`:

```dart
  // R10 (BR-TRASH-009): the auto-purge runs only when the device clock agrees
  // with the server time seen at the last sync, within a day, inclusive.
  Future<void> expireOneDeck() async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await decks.deleteDeck(deckId: words.id);
    // Past the retention: the clock alone would purge it.
    clock.current = clock.current.add(trashRetention);
  }

  for (final (label, seenAgo, isPurged) in <(String, Duration?, bool)>[
    ('never synced', null, false),
    ('a server 23 h behind the device', const Duration(hours: 23), true),
    ('a server exactly 24 h behind (inclusive)', purgeClockTolerance, true),
    ('a server 25 h behind', const Duration(hours: 25), false),
    (
      'a server 40 days behind (a clock set forward)',
      const Duration(days: 40),
      false,
    ),
    ('a device 23 h behind the server', const Duration(hours: -23), true),
    (
      'a device 25 h behind the server (a clock set back)',
      const Duration(hours: -25),
      false,
    ),
  ]) {
    test('the auto-purge with $label (R10)', () async {
      await expireOneDeck();
      final seen = seenAgo == null ? null : clock.now().subtract(seenAgo);

      final report = await PurgeExpiredTrashUseCase(
        trash,
        clock,
        () async => seen,
      )();

      expect(report.purged, isPurged ? hasLength(1) : isEmpty);
      expect(
        await WatchTrashUseCase(trash)().first,
        hasLength(isPurged ? 0 : 1),
      );
    });
  }
```

Create `purge_expired_wiring_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// The real wiring of R10: the use case reads the server time the sync stored.
void main() {
  test('the auto-purge waits until a sync stored a server time that agrees '
      'with the clock (SP2b 2.30)', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final clock = FakeDayClock(DateTime(2026, 9, 25, 9));
    final decks = DeckRepositoryImpl(db, now: clock.now);
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await decks.deleteDeck(deckId: words.id);
    clock.current = clock.current.add(trashRetention);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);

    // Never synced: the batch is expired and stays.
    final waited = await container.read(purgeExpiredTrashUseCaseProvider)();
    expect(waited.purged, isEmpty);

    await SyncStore(db).recordServerTime(clock.now());
    final purged = await container.read(purgeExpiredTrashUseCaseProvider)();
    expect(purged.purged, hasLength(1));
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/trash/domain/trash_use_cases_test.dart test/features/trash/presentation/purge_expired_wiring_test.dart`
Expected: FAIL to compile (`PurgeExpiredTrashUseCase` takes two arguments; `purgeClockTolerance` is undefined).

- [ ] **Step 3: Implement.**

`trash_entry_entity.dart`, after `trashCutoff`:

```dart
/// BR-TRASH-009 (R10): how far the device clock may sit from the server time
/// seen at the last sync before the auto-purge waits.
const purgeClockTolerance = Duration(days: 1);

/// Whether [now] agrees with [serverTime], the server's clock at the last
/// sync, within [purgeClockTolerance] (inclusive). A device that never synced
/// has no reading and is not trusted (BR-TRASH-009).
bool isTrashClockTrusted(DateTime now, DateTime? serverTime) =>
    serverTime != null &&
    now.difference(serverTime).abs() <= purgeClockTolerance;
```

`purge_expired_trash_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// The server's time as of the last sync, or null when this device never
/// synced or its server sends none (BR-TRASH-009, R10).
typedef ServerTimeReader = Future<DateTime?> Function();

/// What a purge that waits reports: nothing was touched.
const _waits = PurgeReport(purged: {}, blocked: {}, missing: {});

/// UC-TRASH-001 step 3 and A4: every batch 720 hours old or more goes for
/// good, but only while the device clock agrees with the server time seen at
/// the last sync, within a day. Otherwise it waits, deletes nothing and tries
/// again at the next start, resume, Trash visit or sync (BR-TRASH-009, R10).
/// The UI calls it at start, on resume, when the Trash opens and when it
/// regains focus (trash spec D13).
final class PurgeExpiredTrashUseCase {
  const PurgeExpiredTrashUseCase(this._trash, this._clock, this._serverTime);

  final TrashRepository _trash;
  final DayClock _clock;
  final ServerTimeReader _serverTime;

  Future<PurgeReport> call() async {
    final now = _clock.now();
    if (!isTrashClockTrusted(now, await _serverTime())) return _waits;
    return _trash.purgeExpired(now: now);
  }
}
```

`purge_expired_trash_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purge_expired_trash_use_case_provider.g.dart';

@riverpod
PurgeExpiredTrashUseCase purgeExpiredTrashUseCase(Ref ref) =>
    PurgeExpiredTrashUseCase(
      ref.watch(trashRepositoryProvider),
      ref.watch(dayClockProvider),
      // R10: the server's clock as of the last sync.
      ref.watch(syncStoreProvider).serverTime,
    );
```

`test/support/library_harness.dart`: add imports `package:memox/features/trash/data/repositories/trash_repository_impl.dart`, `package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart` and `package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart`, and add to the list in `_backend`:

```dart
  // R10: the library tests' server agrees with their fake day, so the
  // auto-purge runs as it did; the real wiring has its own test
  // (purge_expired_wiring_test.dart).
  purgeExpiredTrashUseCaseProvider.overrideWithValue(
    PurgeExpiredTrashUseCase(
      TrashRepositoryImpl(env.db),
      env.clock,
      () async => env.clock.now(),
    ),
  ),
```

Docs. `BR-TRASH-009-retention-30-ngay.md`: in the front matter change `summary:` to

```
summary: Retention là 30 × 24 giờ từ `deleted_at`; auto-purge chạy khi khởi động, resume và mở Trash, và chỉ khi giờ máy khớp giờ server (lệch ≤ 1 ngày).
```

Append to the end of the `## Rule` paragraph (before `**Enforced by:** store`):

```
Auto-purge MUST chỉ chạy khi giờ máy lệch không quá 1 ngày so với giờ server thấy ở lần đồng bộ gần nhất; nếu chưa từng đồng bộ hoặc lệch quá 1 ngày, auto-purge MUST chờ (không xoá gì) cho đến lần chạy sau. Purge do người dùng chọn không bị ảnh hưởng.
```

and replace the `## Edge case` body `Không áp dụng` with:

```
- Giờ máy chỉnh tới trước 40 ngày khi offline → không xoá; xoá sau lần đồng bộ kế.
```

`UC-TRASH-001-...md`: in step 3 change "Hệ thống chạy auto-purge trước / khi vẽ, rồi hiển thị các batch còn lại" to "Hệ thống chạy auto-purge trước khi vẽ — khi đồng hồ tin cậy (BR-TRASH-009) — rồi hiển thị các batch còn lại"; in A4 change "auto-purge chạy lại khi màn được / focus lại và bỏ các hàng đã hết hạn" to "auto-purge chạy lại khi màn được focus lại, khi đồng hồ tin cậy (BR-TRASH-009), và bỏ các hàng đã hết hạn".

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/trash/domain/trash_use_cases_test.dart test/features/trash/presentation/purge_expired_wiring_test.dart` then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/trash test/app/trash_auto_purge_test.dart test/app/trash_routes_test.dart`
Expected: PASS. If a test outside these folders fails because it built `PurgeExpiredTrashUseCase` by hand, give it `() async => clock.now()` as in `trash_use_cases_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/domain/entities/trash_entry_entity.dart \
  lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart \
  lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart \
  test/support/library_harness.dart \
  test/features/trash/domain/trash_use_cases_test.dart \
  test/features/trash/presentation/purge_expired_wiring_test.dart \
  docs/features/trash/rules/BR-TRASH-009-retention-30-ngay.md \
  docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
git commit -m "fix(trash): the auto-purge waits unless the device clock agrees with the server (SP2b 2.30, R10)"
```

Goldens: none.

---

### Task 15 (A15): Trash purge dialog keeps a failed purge inside (2.27)

**Files:**
- Modify: `lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart` (imports 1-13, state 41-122)
- Create: `test/features/trash/presentation/trash_purge_dialog_test.dart` (A16 and A17 append to it)

**Interfaces:**
- Consumes: A1, A3's `HeldTrash`.
- The dialog keeps its own `PopScope(canPop: !_isPurging)` (the spec leaves the purge hold as it is). A failed purge keeps the dialog with the warning banner, and Delete is the retry. There is no toast for the failure.

- [ ] **Step 1: Write the failing test.** Create `trash_purge_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/usecases/purge_trash_use_case.dart';
import 'package:memox/features/trash/presentation/providers/purge_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _button(String label) => find.widgetWithText(MxButton, label);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Selects the two cards of [seedTrash].
Future<void> _selectCards(WidgetTester tester) async {
  await _tap(tester, _button(_en.trashSelect));
  await _tap(tester, find.text('meokda · eat'));
  await _tap(tester, find.text('homework · bai tap'));
}

void main() {
  libraryTest('a failed purge keeps the dialog with a banner, and Delete is '
      'the retry (SP2b 2.27)', (tester, env) async {
    await seedTrash(env);
    final hold = WriteHold()
      ..open()
      ..failNext();
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        purgeTrashUseCaseProvider.overrideWithValue(
          PurgeTrashUseCase(
            HeldTrash(TrashRepositoryImpl(env.db), hold),
            env.clock,
          ),
        ),
      ],
    );
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected(2)));
    await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.failure(WriteHold.failure)),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart`
Expected: FAIL. Today the failure is a toast, so the `MxInlineBanner` finder finds nothing.

- [ ] **Step 3: Implement.** Add `import 'package:memox/shared/widgets/mx_inline_banner.dart';`. In the state class add, after `_isPurging`:

```dart
  /// The last purge's failure, shown in the dialog until the next try; Delete
  /// is the retry (SP2b 2.27).
  Failure? _failure;
```

`_purge`: the opening `setState` becomes `setState(() { _isPurging = true; _failure = null; });` and the catch (lines 72-76) becomes

```dart
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'trash purge');
      if (!mounted) return;
      setState(() {
        _isPurging = false;
        _failure = failure;
      });
    }
```

In `build`, after `final count = widget.entries.length;` add `final failure = _failure;` and give the `MxDialog` a `content:` after `body:`:

```dart
        content: failure == null
            ? null
            : MxInlineBanner(
                tone: MxBannerTone.warning,
                message: l10n.failure(failure),
              ),
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart test/features/trash/presentation/trash_selection_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart \
  test/features/trash/presentation/trash_purge_dialog_test.dart
git commit -m "fix(trash): a failed purge keeps its dialog with a banner and Delete retries (SP2b 2.27)"
```

Goldens: none.

---

### Task 16 (A16): A purge that keeps a deck says so in a toast (2.31)

**Files:**
- Modify: `lib/features/trash/presentation/widgets/support/trash_labels_widget.dart` (a new function after `trashEntryName`, line 22)
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart` (`_list` 188-193, and `_blockedNotes` 277-298 removed)
- Modify: `lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart` (`_purge` success branch; a new `_toast`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (two keys after `trashPurgeBlocked`)
- Modify: `test/features/trash/presentation/trash_selection_test.dart` (the test at 134-172; one import)
- Modify: `test/features/trash/presentation/trash_golden_test.dart` (`trash purge blocked`, one `expect`)
- Test: `test/features/trash/presentation/trash_purge_dialog_test.dart` (appended)
- Modify: `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md` (E4)

**Interfaces:**
- Produces: `Iterable<String> trashBlockedNotes(AppLocalizations l10n, Map<String, Set<String>> blocked, List<TrashEntry> entries)`, moved out of `_TrashScreenState._blockedNotes` into `trash_labels_widget.dart`. The screen's banner keeps using it.
- After `purge`, when `report.blocked` is not empty the toast names what was kept: one blocked deck gives its `trashPurgeBlocked(name, blocker)` note, several give `trashPurgeKeptMany(n)`, and when something also purged `trashPurgedWithKept(purged, kept)` joins them. The toast uses `bulkToastDuration(hasNews: true)`. `report.missing` needs no toast: those rows are already gone.
- New ARB keys:
  - `trashPurgeKeptMany` (int `count`): "{count} decks were kept: they still hold entries deleted earlier. The notes above the list say which." / "{count} bộ thẻ được giữ lại vì còn chứa mục đã xoá trước đó. Các ghi chú phía trên danh sách nói rõ từng bộ."
  - `trashPurgedWithKept` (String `purged`, String `kept`): "{purged}. {kept}" in both languages.

- [ ] **Step 1: Write the failing tests.** Append to `trash_purge_dialog_test.dart` (add imports `../../../support/card_fixtures.dart` and `../../../support/deck_fixtures.dart`):

```dart
Finder _toast(String message) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(message));

/// Korean › Food: its card went to the Trash first, then the deck, so the deck
/// holds an older entry and a purge skips it (invariant 36).
Future<void> _seedFood(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final food = await env.decks.sub(korean.id, 'Food');
  await insertCard(
    env.db,
    id: 'rice',
    deckId: food.id,
    front: 'bap',
    back: 'rice',
  );
  await env.cards.deleteCards(
    cardIds: {'rice'},
    now: libraryToday.subtract(const Duration(days: 2)),
  );
  await env.decks.deleteDeck(
    deckId: food.id,
    now: libraryToday.subtract(const Duration(days: 1)),
  );
}
```

and inside `main()`:

```dart
  libraryTest('a purge the store skips says so in a toast that names what the '
      'deck still holds (SP2b 2.31)', (tester, env) async {
    await _seedFood(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await _tap(tester, find.byTooltip(_en.trashEntryActions('Food')));
    await _tap(tester, find.text(_en.trashDeletePermanently));
    await _tap(tester, _inDialog(_en.trashPurgeConfirm(1)));

    expect(find.byType(MxDialog), findsNothing);
    expect(_toast(_en.trashPurgeBlocked('Food', 'bap · rice')), findsOneWidget);
    expect(find.text(_en.trashPurgedDecks(1)), findsNothing);
  });

  libraryTest('a purge that takes one deck and keeps two says both in one '
      'toast (SP2b 2.31)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    for (final (index, name) in ['Food', 'Travel'].indexed) {
      final deck = await env.decks.sub(korean.id, name);
      await insertCard(env.db, id: 'c$index', deckId: deck.id);
      await env.cards.deleteCards(
        cardIds: {'c$index'},
        now: libraryToday.subtract(const Duration(days: 3)),
      );
      await env.decks.deleteDeck(
        deckId: deck.id,
        now: libraryToday.subtract(const Duration(days: 2)),
      );
    }
    final basics = await env.decks.root('Basics');
    await env.decks.deleteDeck(
      deckId: basics.id,
      now: libraryToday.subtract(const Duration(days: 1)),
    );
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await _tap(tester, _button(_en.trashSelect));
    for (final name in ['Food', 'Travel', 'Basics']) {
      await _tap(tester, find.text(name));
    }
    await _tap(tester, _button(_en.trashPurgeSelected(3)));
    await _tap(tester, _inDialog(_en.trashPurgeConfirm(3)));

    expect(
      _toast(
        _en.trashPurgedWithKept(
          _en.trashPurgedDecks(1),
          _en.trashPurgeKeptMany(2),
        ),
      ),
      findsOneWidget,
    );
  });
```

In `trash_selection_test.dart` add `import 'package:memox/shared/widgets/mx_inline_banner.dart';` and replace (lines 163-171)

```dart
    expect(
      find.text(_en.trashPurgeBlocked('Food', 'bap · rice')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(find.text(_en.trashPurgeBlocked('Food', 'bap · rice')))
          .dy,
      lessThan(tester.getTopLeft(find.text('Food')).dy),
    );
```

with

```dart
    // The screen's banner above the rows, and the dialog's toast (SP2b 2.31).
    final note = _en.trashPurgeBlocked('Food', 'bap · rice');
    final banner = find.descendant(
      of: find.byType(MxInlineBanner),
      matching: find.text(note),
    );
    expect(banner, findsOneWidget);
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.text(note)),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(banner).dy,
      lessThan(tester.getTopLeft(find.text('Food')).dy),
    );
```

In `trash_golden_test.dart`, in `trash purge blocked`, after `await tester.pumpAndSettle();` add `expect(find.byType(SnackBar), findsOneWidget);` (the toast now shows; the golden `trash_purge_blocked_{light,dark}` moves).

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart test/features/trash/presentation/trash_selection_test.dart`
Expected: FAIL. `trashPurgedWithKept` and `trashPurgeKeptMany` do not exist yet, so the purge-dialog test file does not compile; once it does, the edited selection test finds no toast.

- [ ] **Step 3: Implement.**

ARB, `app_en.arb` after `trashPurgeBlocked`:

```json
  "trashPurgeKeptMany": "{count} decks were kept: they still hold entries deleted earlier. The notes above the list say which.",
  "@trashPurgeKeptMany": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 06 toast (SP2b 2.31): a purge kept several decks because they still hold entries deleted earlier; the notes above the list name each."
  },
  "trashPurgedWithKept": "{purged}. {kept}",
  "@trashPurgedWithKept": {
    "placeholders": {
      "purged": {
        "type": "String"
      },
      "kept": {
        "type": "String"
      }
    },
    "description": "Screen 06 toast (SP2b 2.31): what a purge deleted for good, then what it kept; both sentences are built by the caller."
  },
```

`app_vi.arb` after `trashPurgeBlocked`:

```json
  "trashPurgeKeptMany": "{count} bộ thẻ được giữ lại vì còn chứa mục đã xoá trước đó. Các ghi chú phía trên danh sách nói rõ từng bộ.",
  "trashPurgedWithKept": "{purged}. {kept}",
```

`trash_labels_widget.dart`, after `trashEntryName` (the screen's logic, moved and its parameters named):

```dart
/// One sentence per batch a purge skipped that is still in [entries], naming
/// what it still holds (spec D6). [blocked] is `PurgeReport.blocked`, or the
/// controller's `TrashState.blocked`.
Iterable<String> trashBlockedNotes(
  AppLocalizations l10n,
  Map<String, Set<String>> blocked,
  List<TrashEntry> entries,
) sync* {
  final byBatch = {for (final entry in entries) entry.batchId: entry};
  for (final MapEntry(key: batchId, value: inner) in blocked.entries) {
    final skipped = byBatch[batchId];
    final names = [
      for (final id in inner)
        if (byBatch[id] case final entry?) trashEntryName(entry),
    ];
    if (skipped == null || names.isEmpty) continue;
    yield l10n.trashPurgeBlocked(
      trashEntryName(skipped),
      names.join(trashNamesSeparator),
    );
  }
}
```

`trash_screen.dart`: in `_list` replace `for (final note in _blockedNotes(l10n, state, entries))` with `for (final note in trashBlockedNotes(l10n, state.blocked, entries))`, and delete `_blockedNotes` with its doc comment (lines 277-298).

`trash_purge_dialog_widget.dart`: add imports `package:memox/features/trash/domain/models/purge_report_model.dart`, `package:memox/features/trash/presentation/providers/trash_entries_provider.dart`, `package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart`, `package:memox/l10n/bulk_message.dart` and `package:memox/l10n/generated/app_localizations.dart`. In `_purge`, replace the success branch (from `final purged = …` to `Navigator.of(context).pop(true);`) with

```dart
      final message = _toast(context.l10n, report);
      if (message != null) {
        showMxSnackbar(
          context,
          message: message,
          // What was kept is news the person reads past a first sentence.
          duration: bulkToastDuration(hasNews: report.blocked.isNotEmpty),
        );
      }
      Navigator.of(context).pop(true);
```

and add the method:

```dart
  /// What the purge did, in one toast: what went and what was kept (SP2b
  /// 2.31). Null when nothing went and nothing was kept: every chosen batch
  /// was already gone, and its row with it.
  String? _toast(AppLocalizations l10n, PurgeReport report) {
    final purged = report.purged.length;
    final went = switch (purged) {
      0 => null,
      _ when _isCards => l10n.trashPurgedCards(purged),
      _ => l10n.trashPurgedDecks(purged),
    };
    // One kept deck is named with what it holds; several are counted, and
    // the notes above the list name each.
    final kept = switch (report.blocked.length) {
      0 => null,
      1 =>
        trashBlockedNotes(
          l10n,
          report.blocked,
          ref.read(trashEntriesProvider).value ?? const <TrashEntry>[],
        ).firstOrNull,
      final many => l10n.trashPurgeKeptMany(many),
    };
    return switch ((went, kept)) {
      (final a?, final b?) => l10n.trashPurgedWithKept(a, b),
      (final one?, null) || (null, final one?) => one,
      (null, null) => null,
    };
  }
```

`UC-TRASH-001-...md`, E4: change "…và người dùng thấy lý do / có kiểu (BR-TRASH-010)." to "…và người dùng thấy lý do có kiểu trong một toast nêu tên deck bị giữ (nhiều deck thì nêu số lượng) cùng banner của màn (BR-TRASH-010)."

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart test/features/trash/presentation/trash_selection_test.dart test/app/l10n_test.dart` then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/trash`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/presentation/widgets/support/trash_labels_widget.dart \
  lib/features/trash/presentation/screens/trash_screen.dart \
  lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/features/trash/presentation/trash_purge_dialog_test.dart \
  test/features/trash/presentation/trash_selection_test.dart \
  test/features/trash/presentation/trash_golden_test.dart \
  docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
git commit -m "fix(trash): a purge that keeps a deck says which in a toast (SP2b 2.31)"
```

Goldens: `trash_purge_blocked_{light,dark}` move (the toast now shows over the list). Regenerate in the Linux container only.

---

### Task 17 (A17): A deck purge confirm names the deck and its scope (2.32)

**Files:**
- Modify: `lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart` (`build`, the `body:` line)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (two keys after `trashPurgeBody`)
- Test: `test/features/trash/presentation/trash_purge_dialog_test.dart` (appended)
- Modify: `test/features/trash/presentation/trash_golden_test.dart` (a new golden after `trash purge confirm`)
- Modify: `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md` (A3)

**Interfaces:**
- One deck: `trashPurgeDeckBody(deck, subDeckCount, cardCount)`, from its `TrashDeckEntry`. Several decks: `trashPurgeDecksTotalBody(count, subDecks, cards)`, with sums. Cards keep `trashPurgeBody(count)`.
- New ARB keys:
  - `trashPurgeDeckBody` (String `deck`, int `subDeckCount`, int `cardCount`): "“{deck}”, with {subDeckCount, plural, =1{1 sub-deck} other{{subDeckCount} sub-decks}} and {cardCount, plural, =1{1 card} other{{cardCount} cards}}, disappears for good, together with its study history. This cannot be undone." / "“{deck}”, cùng {subDeckCount} bộ thẻ con và {cardCount} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác."
  - `trashPurgeDecksTotalBody` (int `count`, int `subDecks`, int `cards`): "{count} decks, with {subDecks, plural, =1{1 sub-deck} other{{subDecks} sub-decks}} and {cards, plural, =1{1 card} other{{cards} cards}}, disappear for good, together with their study history. This cannot be undone." / "{count} bộ thẻ, cùng {subDecks} bộ thẻ con và {cards} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác."
- The spec's copy for the total has no plural for sub-decks and cards, so it would read "1 sub-decks". The plural form is the only change; its `other` text is the spec's.

- [ ] **Step 1: Write the failing tests.** Append inside `main()` of `trash_purge_dialog_test.dart`:

```dart
  libraryTest('a deck confirm names the deck, its sub-decks and its cards '
      '(SP2b 2.32)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await _tap(tester, find.byTooltip(_en.trashEntryActions('Basics')));
    await _tap(tester, find.text(_en.trashDeletePermanently));

    expect(find.text(_en.trashPurgeDeckBody('Basics', 1, 2)), findsOneWidget);
    expect(find.text(_en.trashPurgeBody(1)), findsNothing);
  });

  libraryTest('several decks name the totals of their sub-decks and cards '
      '(SP2b 2.32)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    // Basics (1 sub-deck, 2 cards) and Places (no sub-decks, 3 cards).
    await _tap(tester, _button(_en.trashSelect));
    await _tap(tester, find.text('Basics'));
    await _tap(tester, find.text('Places'));
    await _tap(tester, _button(_en.trashPurgeSelected(2)));

    expect(find.text(_en.trashPurgeDecksTotalBody(2, 1, 5)), findsOneWidget);
  });

  libraryTest('cards keep the count-only confirm (SP2b 2.32)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected(2)));

    expect(find.text(_en.trashPurgeBody(2)), findsOneWidget);
  });
```

Golden test: in `trash_golden_test.dart` after `trash purge confirm`:

```dart
    libraryTest('trash purge confirm deck, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await tester.tap(find.byTooltip(_en.trashEntryActions('Basics')));
        await _settle(tester);
        await tester.tap(find.text(_en.trashDeletePermanently));
        await _settle(tester);
        expect(
          find.text(_en.trashPurgeDeckBody('Basics', 1, 2)),
          findsOneWidget,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/trash_purge_confirm_deck_$theme.png',
        );
      });
    });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart`
Expected: FAIL to compile (`trashPurgeDeckBody` and `trashPurgeDecksTotalBody` do not exist).

- [ ] **Step 3: Implement.** ARB, `app_en.arb` after `trashPurgeBody`:

```json
  "trashPurgeDeckBody": "“{deck}”, with {subDeckCount, plural, =1{1 sub-deck} other{{subDeckCount} sub-decks}} and {cardCount, plural, =1{1 card} other{{cardCount} cards}}, disappears for good, together with its study history. This cannot be undone.",
  "@trashPurgeDeckBody": {
    "placeholders": {
      "deck": {
        "type": "String"
      },
      "subDeckCount": {
        "type": "int"
      },
      "cardCount": {
        "type": "int"
      }
    },
    "description": "Screen 06 purge dialog body for one deck (SP2b 2.32, BR-TRASH-011): names the deck, what goes with it, and that its history goes too."
  },
  "trashPurgeDecksTotalBody": "{count} decks, with {subDecks, plural, =1{1 sub-deck} other{{subDecks} sub-decks}} and {cards, plural, =1{1 card} other{{cards} cards}}, disappear for good, together with their study history. This cannot be undone.",
  "@trashPurgeDecksTotalBody": {
    "placeholders": {
      "count": {
        "type": "int"
      },
      "subDecks": {
        "type": "int"
      },
      "cards": {
        "type": "int"
      }
    },
    "description": "Screen 06 purge dialog body for several decks (SP2b 2.32): the count and the totals of their sub-decks and cards."
  },
```

`app_vi.arb` after `trashPurgeBody`:

```json
  "trashPurgeDeckBody": "“{deck}”, cùng {subDeckCount} bộ thẻ con và {cardCount} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác.",
  "trashPurgeDecksTotalBody": "{count} bộ thẻ, cùng {subDecks} bộ thẻ con và {cards} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác.",
```

`trash_purge_dialog_widget.dart`: replace `body: l10n.trashPurgeBody(count),` with `body: _body(l10n),` and add

```dart
  /// What goes: a deck is named with its sub-decks and cards, several decks
  /// by their totals, cards by the count (SP2b 2.32, BR-TRASH-011).
  String _body(AppLocalizations l10n) {
    final entries = widget.entries;
    int sum(int Function(TrashDeckEntry deck) of) => entries
        .whereType<TrashDeckEntry>()
        .fold(0, (total, deck) => total + of(deck));
    return switch (entries) {
      [TrashDeckEntry(:final name, :final subDeckCount, :final cardCount)] =>
        l10n.trashPurgeDeckBody(name, subDeckCount, cardCount),
      _ when !_isCards => l10n.trashPurgeDecksTotalBody(
        entries.length,
        sum((deck) => deck.subDeckCount),
        sum((deck) => deck.cardCount),
      ),
      _ => l10n.trashPurgeBody(entries.length),
    };
  }
```

`UC-TRASH-001-...md`, A3: change "Hộp thoại nêu / đúng số item, nói lịch sử học không khôi phục được" to "Hộp thoại nêu đúng số item — với một deck thì nêu tên deck cùng số deck con và số card, với nhiều deck thì nêu tổng của chúng — nói lịch sử học không khôi phục được".

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/trash/presentation/trash_purge_dialog_test.dart test/features/trash/presentation/trash_selection_test.dart test/app/l10n_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart \
  lib/l10n/app_en.arb lib/l10n/app_vi.arb \
  test/features/trash/presentation/trash_purge_dialog_test.dart \
  test/features/trash/presentation/trash_golden_test.dart \
  docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
git commit -m "fix(trash): a deck purge confirm names the deck, its sub-decks and its cards (SP2b 2.32)"
```

Goldens: none move (`trash_purge_confirm` is the cards dialog). One new golden test, `trash_purge_confirm_deck_{light,dark}`.

---

### Task 18 (A18): DECISION — a manual purge must not sweep what an untrusted clock calls expired (2.30, R10)

**Why this is a task.** `TrashRepository.purge(batchIds, now)` takes the chosen batches and also every batch past `trashCutoff(now)` (`trash_dao.dart:34-47`, `purgeCandidates`). With a device clock set 40 days forward, one manual purge of a single item would delete everything the clock calls expired and bypass R10. The spec says "manual `purge(batchIds)` is untouched"; this task keeps the chosen batches going as they do and only stops the expired sweep while the clock is untrusted.

DECISION: do this task. Recommended: yes (about eight lines). If the owner rules that a manual purge sweeps as before, skip A18; nothing earlier depends on it.

**Files:**
- Modify: `lib/features/trash/domain/usecases/purge_trash_use_case.dart` (whole file)
- Modify: `lib/features/trash/presentation/providers/purge_trash_use_case_provider.dart`
- Modify: `test/support/library_harness.dart` (`_backend`)
- Modify: `test/features/trash/domain/trash_use_cases_test.dart` (line 99 and a new test)
- Modify: `test/features/trash/presentation/trash_purge_dialog_test.dart` (the `PurgeTrashUseCase(...)` call of A15)
- Modify: `docs/features/trash/rules/BR-TRASH-009-retention-30-ngay.md`

**Interfaces:**
- Consumes: A14's `isTrashClockTrusted` and `ServerTimeReader`.
- Produces: `PurgeTrashUseCase(TrashRepository, DayClock, ServerTimeReader)`. While the clock is untrusted it calls `purge(batchIds, now: <the epoch>)`, whose cutoff is before every batch, so only the chosen batches go.

- [ ] **Step 1: Write the failing test.** In `trash_use_cases_test.dart` change line 99 to `PurgeTrashUseCase(trash, clock, () async => clock.now())(batchIds: {again})`, and append inside `main()`:

```dart
  test('a manual purge takes the chosen batch but sweeps nothing expired '
      'while the clock is untrusted (R10)', () async {
    await expireOneDeck();
    final other = await decks.root('Other');
    final chosen = ((await decks.deleteDeck(
      deckId: other.id,
      now: clock.now(),
    )) as Ok<String, DeckRejection>).value;

    final report = await PurgeTrashUseCase(trash, clock, () async => null)(
      batchIds: {chosen},
    );

    expect(report.purged, {chosen});
    // The expired Words batch is still there: only the chosen one went.
    expect(await WatchTrashUseCase(trash)().first, hasLength(1));

    final trusted = await PurgeTrashUseCase(
      trash,
      clock,
      () async => clock.now(),
    )(batchIds: const {});
    expect(trusted.purged, hasLength(1));
  });
```

(`expireOneDeck` is the helper A14 added to this file.)

In `trash_purge_dialog_test.dart` change the A15 construction to `PurgeTrashUseCase(HeldTrash(TrashRepositoryImpl(env.db), hold), env.clock, () async => env.clock.now())`.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/trash/domain/trash_use_cases_test.dart`
Expected: FAIL to compile (`PurgeTrashUseCase` takes two arguments).

- [ ] **Step 3: Implement.** `purge_trash_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';

/// UC-TRASH-001 A3: the batches the person chose go for good, and so does
/// every expired one, unless the device clock is not trusted (R10): then only
/// the chosen batches go. A batch that still holds another is skipped and
/// reported (BR-TRASH-010, E4, E6).
final class PurgeTrashUseCase {
  const PurgeTrashUseCase(this._trash, this._clock, this._serverTime);

  final TrashRepository _trash;
  final DayClock _clock;
  final ServerTimeReader _serverTime;

  /// A time before every batch: its cutoff takes none of the expired ones.
  static final _beforeEveryBatch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  Future<PurgeReport> call({required Set<String> batchIds}) async {
    final now = _clock.now();
    final isTrusted = isTrashClockTrusted(now, await _serverTime());
    return _trash.purge(
      batchIds: batchIds,
      now: isTrusted ? now : _beforeEveryBatch,
    );
  }
}
```

`purge_trash_use_case_provider.dart`: add `import 'package:memox/core/sync/di/sync_providers.dart';` and pass `ref.watch(syncStoreProvider).serverTime` as the third argument.

`test/support/library_harness.dart`: add in `_backend` beside the expired override (and the imports for `PurgeTrashUseCase` and `purgeTrashUseCaseProvider`):

```dart
  purgeTrashUseCaseProvider.overrideWithValue(
    PurgeTrashUseCase(
      TrashRepositoryImpl(env.db),
      env.clock,
      () async => env.clock.now(),
    ),
  ),
```

`BR-TRASH-009-...md`: after the sentence "Purge do người dùng chọn không bị ảnh hưởng." add "Khi giờ không tin cậy, purge do người dùng chọn chỉ xoá đúng các batch đã chọn và không quét thêm batch hết hạn."

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/trash/domain/trash_use_cases_test.dart test/features/trash/presentation/trash_purge_dialog_test.dart` then `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/trash test/app/trash_auto_purge_test.dart test/features/trash_double_tap_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash/domain/usecases/purge_trash_use_case.dart \
  lib/features/trash/presentation/providers/purge_trash_use_case_provider.dart \
  test/support/library_harness.dart \
  test/features/trash/domain/trash_use_cases_test.dart \
  test/features/trash/presentation/trash_purge_dialog_test.dart \
  docs/features/trash/rules/BR-TRASH-009-retention-30-ngay.md
git commit -m "fix(trash): a manual purge sweeps no expired batch while the clock is untrusted (SP2b 2.30, R10)"
```

Goldens: none.

---

## Cluster notes

**Cross-task interfaces.**
- A1's `failureOfThrown` is used by A3-A9, A11 and A15.
- A2's `MxDeckPickerSheet.isHeld` and `banner` are used by A7-A9.
- A3's `test/support/held_writes.dart` (`WriteHold`, `HeldDecks`, `HeldCards`, `HeldTags`, `HeldTrash`) is used by A4, A6-A9 and A15. A5 reuses the file's own `_SlowDecks`.
- A12 → A13 → A14 form a chain: the server key, then `SyncStore.serverTime()`, then the use case.
  - A14 changes the `PurgeExpiredTrashUseCase` constructor, so every test or code that builds it by hand is updated in A14.
  - A14's harness override keeps every library test purging.
- A15-A17 all edit `trash_purge_dialog_widget.dart` in sequence; A16 and A17 describe only the members they change, relative to the state after the previous task. A18 changes the `PurgeTrashUseCase` constructor that A15's test builds.

**Shared files other clusters may touch (merge order).**
- `test/support/library_harness.dart` (A14, A18).
- `lib/l10n/app_en.arb` and `app_vi.arb`: A11 edits one description; A16 and A17 add four keys after `trashPurgeBlocked` and `trashPurgeBody`.
- `test/features/settings/presentation/settings_screen_test.dart` and `settings_screen_golden_test.dart` (A11).
- `lib/core/sync/sync_models.dart` and `sync_coordinator.dart` (A13).

**Goldens.**
- Existing goldens that move: `trash_purge_blocked_{light,dark}` (A16).
- New golden tests: `library_deck_delete_failed` (A3), `library_algorithm_reset_failed` (A6), `settings_reset_failed` (A11) and `trash_purge_confirm_deck` (A17), each in light and dark.
- No cluster-A task adds a PNG; all are generated in the Linux container with `run_goldens.sh --update`, never on Windows.
- The golden-compare page goes to the owner before the merge.

**Risks.**
- **R10 reads literally.** `now.difference(seen).abs() > 1 day` means a person who has not synced for more than a day also waits, not only one with a skewed clock. The purge resumes at the next sync, and a never-synced install never auto-purges (spec §8). The owner may want a looser rule later; that is one more ruling.
- **Sign-out and account switch.** `LocalDataReset` clears `sync_state` but the device id, so the stored server time goes and the purge waits for the next sync. This is consistent and safe.
- **A18 hole.** Without A18, one manual purge under a forward clock still sweeps every "expired" batch.
- **Banner spacing.** `MxInlineBanner` carries a 16 bottom margin and the dialog columns add 12 between children, so a banner sits 28 above the next control. The impeccable audit of the golden page decides whether to tighten it.
- **`failureOfThrown` reporting.** A widget test that deliberately throws a non-`Failure` must call `tester.takeException()` (A3 does).
- **Generated code.** The `ChangesResponseModel` change needs `dart run build_runner build --delete-conflicting-outputs`.
- **Windows.** `npx supabase db start` needs Docker. Without it, `bash tools/supabase/local_pgtap.sh` runs the same migrations and tests.
- **Commit trailer.** The commit messages here omit the `Co-Authored-By` trailer; the merged plan's Global Constraints add it from the session's attribution reminder, as SP2a does.

**Not in this cluster (the controller closes them).**
- Detail files `docs/shared/ui/screen-handoff/` 01, 02, 03, 06, 23 (States and Copy) and their rows in `00-index.md`.
- The failure-in-dialog pattern in `DESIGN.md` under Components → MxInlineBanner.
- The WBS row `FE-D29` in `docs/wbs_FE.md`.
- `verification_impact_map.json`: no `.drift` query is added here, so nothing to map.
- Whether `check_architecture.sh` accepts `lib/features/trash/presentation/providers/*` importing `core/sync/di/sync_providers.dart` (settings screens already do the same).

**DECISION list.**
1. **A1.** Put `failureOfThrown` in `lib/l10n/failure_message.dart` (recommended), or inline the eight lines in each of nine dialogs.
2. **A2.** (Spec DECISION 1.) `MxDeckPickerSheet` gains `isHeld` and `banner`, and a held sheet turns its dismiss button off (recommended: yes).
3. **A12.** (Spec DECISION 3.) Server time source: Option A, `sync_changes` returns `serverTime` (drafted); Option B, the token's `iat` (skip A12 and A13).
4. **A18.** The manual purge also refuses to sweep expired batches while the clock is untrusted (recommended: yes). The spec says the manual purge is untouched.
5. **A17** (a note, not a ruling). The `trashPurgeDecksTotalBody` copy adds plural forms for sub-decks and cards; the spec's text would read "1 sub-decks".
6. **Spec DECISION 4** (no shared failure widget): followed. Each dialog builds its own `MxInlineBanner`.


## Cluster B: Daily reminder (2.34, 2.35, 2.36) and Sync and Monitoring (2.37, 2.38, 2.39)

Spec: `docs/superpowers/specs/2026-10-03-ui-hardening-sp2b-design.md` §3.5, §3.6, §5 (BR-REMINDER-011, UC-REMINDER-001, sync status spec §5.4), §6, §7 (goldens), §8 (detail files).

Every task ends with the same three checks before its commit. They are written once here and named "the checks" below:

```bash
dart format <the Dart files the task touched>
flutter analyze lib test
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: no format change, `No issues found!`, guard exit code 0 with 0 warnings. Generated code (`*.g.dart`, `lib/l10n/generated`) is not tracked; the steps that add a provider or an ARB key regenerate it (`dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`).

---

### Task 19 (B1): `ReminderPlatformRepository.notificationPermission()` reads the permission and never asks

**Files:**
- Modify: `lib/features/reminders/data/datasources/reminder_plugins_data_source.dart` (interface; add after `requestNotificationPermission`, lines 21-23)
- Modify: `lib/features/reminders/data/datasources/plugin_reminder_plugins_data_source.dart` (add after `requestNotificationPermission`, lines 58-62)
- Modify: `lib/features/reminders/domain/repositories/reminder_platform_repository.dart` (add after `requestPermission`, lines 20-23)
- Modify: `lib/features/reminders/data/repositories/android_reminder_platform_repository_impl.dart` (add after `requestPermission`, lines 30-41)
- Modify: `lib/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart` (add after `requestPermission`, lines 19-21)
- Modify: `test/support/fake_reminder_platform.dart` (enum lines 11-18; `requestPermission` lines 58-63)
- Modify: `test/app/reminder_tap_test.dart` (the `_FakePlugins`, lines 12-52)
- Test: `test/features/reminders/data/android_reminder_platform_repository_test.dart` (the `_FakePlugins`, lines 14-55; new group before `group('openNotificationSettings (FE-B6)'` at line 214)
- Test: `test/features/reminders/data/unsupported_reminder_platform_repository_test.dart` (lines 26-30)

**Interfaces:**
- Consumes: `ReminderPermission` (`reminder_platform_model.dart`: `granted`, `denied`), `AndroidFlutterLocalNotificationsPlugin.areNotificationsEnabled(): Future<bool?>`.
- Produces:
  - `ReminderPluginsDataSource.notificationsEnabled(): Future<bool?>` (`true` allowed, `false` blocked, `null` the platform cannot say).
  - `ReminderPlatformRepository.notificationPermission(): Future<ReminderPermission>`.
  - `FakeReminderPlatform.notifications: ReminderPermission?` and `PlatformCall.notificationPermission` (test support, used by B2 and B3).

Goldens: none.

- [ ] **Step 1: Write the failing tests**

In `android_reminder_platform_repository_test.dart`, extend `_FakePlugins`:

```dart
// after `bool? permission = true;`
  bool? enabled = true;
```

```dart
// after the requestNotificationPermission override (lines 38-40)
  @override
  Future<bool?> notificationsEnabled() => _call('enabled', enabled);
```

Add this group before `group('openNotificationSettings (FE-B6)', () {`:

```dart
  group('notificationPermission (BR-REMINDER-011, SP2b 2.34)', () {
    test('allowed reads granted and asks nothing', () async {
      expect(
        await platform.notificationPermission(),
        ReminderPermission.granted,
      );
      expect(plugins.calls, ['enabled']);
    });

    test('blocked reads denied', () async {
      plugins.enabled = false;
      expect(
        await platform.notificationPermission(),
        ReminderPermission.denied,
      );
    });

    test('a platform that cannot say, and a throw, read granted: an unknown '
        'never shows a false warning', () async {
      plugins.enabled = null;
      expect(
        await platform.notificationPermission(),
        ReminderPermission.granted,
      );
      plugins
        ..enabled = false
        ..fails = true;
      expect(
        await platform.notificationPermission(),
        ReminderPermission.granted,
      );
    });
  });
```

In `unsupported_reminder_platform_repository_test.dart`, add to the first test, after the `requestPermission` expectation:

```dart
    // Nothing is blocked where nothing is delivered: the unavailable row
    // says it all, and a warning here would be false.
    expect(await platform.notificationPermission(), ReminderPermission.granted);
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders/data/android_reminder_platform_repository_test.dart test/features/reminders/data/unsupported_reminder_platform_repository_test.dart`
Expected: FAIL to compile: `'notificationsEnabled' isn't a method in the supertype`, `The method 'notificationPermission' isn't defined`.

- [ ] **Step 3: Implement**

`reminder_plugins_data_source.dart`, after `requestNotificationPermission()`:

```dart
  /// Whether the app's notifications are allowed right now, without asking:
  /// `true` allowed, `false` blocked, `null` where the platform cannot say.
  Future<bool?> notificationsEnabled();
```

`plugin_reminder_plugins_data_source.dart`, after `requestNotificationPermission()`:

```dart
  @override
  Future<bool?> notificationsEnabled() async {
    await initialize();
    return _android?.areNotificationsEnabled();
  }
```

`reminder_platform_repository.dart`, after `requestPermission()`:

```dart
  /// Reads the notification permission and never asks for it (BR-REMINDER-011,
  /// amended by SP2b 2.34): `denied` only when the platform says the app's
  /// notifications are blocked. What it cannot tell, or fails to read, is
  /// `granted`, so an unknown never shows a false warning.
  Future<ReminderPermission> notificationPermission();
```

`android_reminder_platform_repository_impl.dart`, after `requestPermission()`:

```dart
  @override
  Future<ReminderPermission> notificationPermission() async {
    try {
      final enabled = await _plugins.notificationsEnabled();
      // Null: the platform cannot say, which is not a refusal.
      return enabled == false
          ? ReminderPermission.denied
          : ReminderPermission.granted;
    } on Object {
      return ReminderPermission.granted;
    }
  }
```

`unsupported_reminder_platform_repository_impl.dart`, after `requestPermission()`:

```dart
  /// Nothing is delivered here, so nothing is blocked: the unavailable row
  /// says it all (BR-REMINDER-012).
  @override
  Future<ReminderPermission> notificationPermission() async =>
      ReminderPermission.granted;
```

`test/app/reminder_tap_test.dart`, after `requestNotificationPermission()`:

```dart
  @override
  Future<bool?> notificationsEnabled() async => true;
```

`test/support/fake_reminder_platform.dart`:

```dart
enum PlatformCall {
  capability,
  requestPermission,
  notificationPermission,
  schedule,
  cancel,
  show,
  openSettings,
}
```

```dart
  // after `Completer<void>? permissionHold;`

  /// What the system's notification state reads when it differs from
  /// [permission]: a fresh Android 13 install reads blocked until the person
  /// allows. Null follows [permission]; a request settles it.
  ReminderPermission? notifications;
```

```dart
  @override
  Future<ReminderPermission> requestPermission() async {
    if (permissionHold case final gate?) await gate.future;
    calls.add(PlatformCall.requestPermission);
    notifications = null;
    return permission;
  }

  @override
  Future<ReminderPermission> notificationPermission() async {
    calls.add(PlatformCall.notificationPermission);
    return notifications ?? permission;
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders test/app/reminder_tap_test.dart test/app/reminder_reconcile_test.dart`
Expected: PASS (no existing test lists `calls` with a permission read in it).

- [ ] **Step 5: Run the checks, then commit**

```bash
git add lib/features/reminders/data/datasources/reminder_plugins_data_source.dart lib/features/reminders/data/datasources/plugin_reminder_plugins_data_source.dart lib/features/reminders/domain/repositories/reminder_platform_repository.dart lib/features/reminders/data/repositories/android_reminder_platform_repository_impl.dart lib/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart test/support/fake_reminder_platform.dart test/app/reminder_tap_test.dart test/features/reminders/data/android_reminder_platform_repository_test.dart test/features/reminders/data/unsupported_reminder_platform_repository_test.dart
git commit -m "feat(reminders): read the notification permission without asking (SP2b 2.34)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 20 (B2): Screen 24 says when Android blocks a reminder that is on (2.34)

**Files:**
- Create: `lib/features/reminders/presentation/providers/reminder_permission_provider.dart` (`reminder_permission_provider.g.dart` is generated)
- Modify: `lib/features/reminders/presentation/screens/reminder_screen.dart` (state class lines 39-46; `_loaded` lines 99-144)
- Modify: `lib/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart` (fields lines 89-104; subtitle switch lines 120-125)
- Modify: `lib/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart` (fields lines 10-24; `build` lines 26-37)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `test/support/reminder_screen_harness.dart` (append a helper)
- Modify: `test/features/reminders/presentation/reminder_screen_golden_test.dart` (add one state)
- Create: `test/features/reminders/presentation/reminder_permission_test.dart`
- Docs: `docs/features/reminders/rules/BR-REMINDER-011-xin-quyen-sau-khi-bat.md`, `docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md`, `docs/shared/ui/screen-handoff/24-daily-reminder.md`, `docs/shared/ui/screen-handoff/00-index.md`

**Interfaces:**
- Consumes: `ReminderPlatformRepository.notificationPermission()` (B1), `reminderPlatformRepositoryProvider`, `reminderStatusProvider`, `FakeReminderPlatform.notifications` (B1).
- Produces:
  - `@riverpod Future<ReminderPermission> reminderPermission(Ref ref)` → `reminderPermissionProvider` (autoDispose). Used by B3.
  - `ReminderSettingsSectionWidget({…, required bool isPermissionRevoked})`, `ReminderBannersWidget({…, required bool isPermissionRevoked})`.
  - `resumeReminderApp(WidgetTester)` in `test/support/reminder_screen_harness.dart`.
  - ARB keys `reminderRevokedHint`, `reminderRevokedBody`.

Goldens that move: none. New: `reminder_perm_revoked_light.png`, `reminder_perm_revoked_dark.png`.

- [ ] **Step 1: Add the ARB keys (the tests refer to them) and regenerate**

`lib/l10n/app_en.arb`: replace

```json
  "@reminderOpenSystemSettings": {
    "description": "Screen handoff 24 (FE-B6): the E1 banner's first action; opens the app's notification settings."
  },
```

with

```json
  "@reminderOpenSystemSettings": {
    "description": "Screen handoff 24 (FE-B6): the E1 banner's first action; opens the app's notification settings."
  },
  "reminderRevokedHint": "On · notifications are blocked for MemoX",
  "@reminderRevokedHint": {
    "description": "Screen handoff 24 (SP2b 2.34): the toggle row's line while the reminder is on but Android blocks MemoX's notifications."
  },
  "reminderRevokedBody": "The reminder is on, but Android won't show it. Allow notifications in Android Settings › Apps › MemoX › Notifications.",
  "@reminderRevokedBody": {
    "description": "Screen handoff 24 (SP2b 2.34): the warning banner's message while the reminder is on and the permission was revoked; its title is reminderDeniedTitle."
  },
```

`lib/l10n/app_vi.arb`: replace the line `  "reminderOpenSystemSettings": "Mở cài đặt hệ thống",` with

```json
  "reminderOpenSystemSettings": "Mở cài đặt hệ thống",
  "reminderRevokedHint": "Đang bật · thông báo của MemoX đang bị chặn",
  "reminderRevokedBody": "Nhắc nhở đang bật nhưng Android sẽ không hiển thị. Hãy cho phép thông báo trong Cài đặt Android › Ứng dụng › MemoX › Thông báo.",
```

Run: `flutter gen-l10n`
Expected: exits 0; `lib/l10n/generated/app_localizations.dart` has `reminderRevokedHint` and `reminderRevokedBody`.

- [ ] **Step 2: Add the test helper and write the failing tests**

Append to `test/support/reminder_screen_harness.dart`:

```dart
/// The app going to the background and coming back: the person visited
/// system settings (BR-REMINDER-011, SP2b 2.34). The screen reads the
/// notification permission again.
Future<void> resumeReminderApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await settleReminderScreen(tester);
}
```

(add `import 'package:flutter/widgets.dart';` to that file).

Create `test/features/reminders/presentation/reminder_permission_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';

// Screen 24: the notification permission read on open and on resume
// (BR-REMINDER-011 amended; SP2b 2.34, 2.36).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('on, then blocked in system settings: the hint and the warning '
      'say so, and nothing stored changes (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
    final writes = s.store.writes;

    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);

    expect(find.text(_en.reminderRevokedHint), findsOneWidget);
    expect(find.text(_en.reminderOnHint), findsNothing);
    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);
    expect(find.text(_en.reminderOpenSystemSettings), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);
    expect(s.store.writes, writes, reason: 'the stored reminder is not changed');
    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
      reason: 'BR-REMINDER-011: reading never asks',
    );
  });

  libraryTest('allowed again: the warning and the hint go, the reminder was '
      'never touched (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);

    s.platform.permission = ReminderPermission.granted;
    await resumeReminderApp(tester);

    expect(find.text(_en.reminderRevokedBody), findsNothing);
    expect(find.text(_en.reminderRevokedHint), findsNothing);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('off with the permission blocked: no warning, the reminder is '
      'not on (2.34)', (tester, env) async {
    await pumpReminderScreen(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );

    expect(find.text(_en.reminderOffHint), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.reminderRevokedBody), findsNothing);
  });

  libraryTest('turning on from a fresh install reads no false warning: the '
      'read from before the person allowed is not trusted (2.34)', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform()
      ..notifications = ReminderPermission.denied;
    await pumpReminderScreen(tester, env, platform: platform);

    await tapReminderToggle(tester);

    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.text(_en.reminderRevokedHint), findsNothing);
    expect(find.byType(MxInlineBanner), findsNothing);
  });

  libraryTest('Open system settings on the revoked warning opens them and '
      'writes nothing (2.34)', (tester, env) async {
    final s = await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    s.platform.permission = ReminderPermission.denied;
    await resumeReminderApp(tester);
    final writes = s.store.writes;

    await tester.tap(find.text(_en.reminderOpenSystemSettings));
    await settleReminderScreen(tester);

    expect(s.platform.calls.last, PlatformCall.openSettings);
    expect(s.store.writes, writes);
    expect(find.text(_en.reminderRevokedBody), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/reminders/presentation/reminder_permission_test.dart`
Expected: FAIL. The first, second and fifth tests fail on `findsOneWidget` for `reminderRevokedHint` (the screen never reads the permission); the third and fourth pass already and keep guarding the other branches.

- [ ] **Step 4: Implement**

Create `lib/features/reminders/presentation/providers/reminder_permission_provider.dart`:

```dart
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_permission_provider.g.dart';

/// The notification permission as it stands now (BR-REMINDER-011 amended,
/// SP2b 2.34): read when screen 24 opens, again when the app resumes (the
/// screen invalidates it), and never asked for.
@riverpod
Future<ReminderPermission> reminderPermission(Ref ref) {
  // Read again whenever the reminder is turned on or off: a read from before
  // the person allowed notifications would warn about a reminder that was
  // just turned on.
  ref.watch(
    reminderStatusProvider.select((status) => status.value?.reminder.isEnabled),
  );
  return ref.watch(reminderPlatformRepositoryProvider).notificationPermission();
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

`reminder_settings_section_widget.dart`: add the field and use it.

```dart
    required this.isPermissionRevoked,
```
```dart
  /// The reminder is on but the system blocks its notifications (SP2b 2.34).
  final bool isPermissionRevoked;
```
```dart
          subtitle: switch ((isOn, action.problem)) {
            (true, _) =>
              isPermissionRevoked
                  ? l10n.reminderRevokedHint
                  : l10n.reminderOnHint,
            (false, ReminderProblem.permissionDenied) =>
              l10n.reminderDeniedHint,
            (false, _) => l10n.reminderOffHint,
          },
```

`reminder_banners_widget.dart`: add the field after `onOpenSettings`:

```dart
    required this.isPermissionRevoked,
```
```dart
  /// The reminder is on but the system blocks its notifications (SP2b 2.34):
  /// shown only when no operation left a problem of its own.
  final bool isPermissionRevoked;
```

and at the top of `build`, after the `action(...)` helper and before `return switch (problem)`:

```dart
    if (problem == null && isPermissionRevoked) {
      return MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.reminderDeniedTitle,
        message: l10n.reminderRevokedBody,
        actions: [
          MxButton(
            label: l10n.reminderOpenSystemSettings,
            size: MxButtonSize.compact,
            onPressed: onOpenSettings,
          ),
        ],
      );
    }
```

`reminder_screen.dart`:

```dart
import 'package:memox/features/reminders/presentation/providers/reminder_permission_provider.dart';
```

In `_ReminderScreenState`, after the `_controller` getter:

```dart
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The person may allow or block notifications in system settings and come
    // back: read the permission again (BR-REMINDER-011, SP2b 2.34).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(reminderPermissionProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
```

In `_loaded`, before `return MxScreenScroll(` of the supported branch:

```dart
    // A read in flight is not an answer: the screen warns on a settled one.
    final permission = ref.watch(reminderPermissionProvider);
    final isPermissionRevoked =
        status.reminder.isEnabled &&
        !permission.isLoading &&
        permission.value == ReminderPermission.denied;
```

and pass `isPermissionRevoked: isPermissionRevoked,` to `ReminderSettingsSectionWidget(...)` and `ReminderBannersWidget(...)`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders/presentation`
Expected: PASS (the new file, `reminder_screen_test`, `reminder_controller_test`; the golden file is excluded on Windows).

If `handleAppLifecycleStateChanged` rejects the sequence in `resumeReminderApp`, keep the helper's shape and fix the sequence there: it is the only place a lifecycle is driven.

- [ ] **Step 6: Add the golden test**

In `reminder_screen_golden_test.dart`, add `import '../../../support/reminder_screen_harness.dart';` and, after the `permission denied` test:

```dart
    // SP2b 2.34: the reminder is on and Android blocks its notifications.
    libraryTest('reminder, permission revoked, $theme', (tester, env) async {
      final platform = FakeReminderPlatform();
      await shoot(
        tester,
        env,
        'perm_revoked',
        platform: platform,
        act: (_) async {
          await toggle(tester);
          platform.permission = ReminderPermission.denied;
          await resumeReminderApp(tester);
          expect(find.text('Notifications are blocked for MemoX'), findsOneWidget);
        },
      );
    });
```

The PNGs are generated later in the Linux container; do not run `--update-goldens`. On Windows run `flutter analyze test/features/reminders/presentation/reminder_screen_golden_test.dart` only.

- [ ] **Step 7: Docs**

`docs/features/reminders/rules/BR-REMINDER-011-xin-quyen-sau-khi-bat.md`: in the Rule, replace `MUST NOT lưu trạng thái "đã bật" khi bước bật chưa hoàn tất.` with

```
MUST NOT lưu trạng thái "đã bật" khi bước bật chưa hoàn tất. Ứng dụng MAY đọc (không xin) trạng thái quyền khi mở màn và khi resume. Nếu nhắc đang bật mà quyền bị tắt, UI MUST nói và chỉ đường mở cài đặt hệ thống; settings MUST NOT bị đổi. Banner "bị từ chối" tự mất khi quyền đã bật lại.
```

Append two rows to the edge-case table:

```
| Nhắc đang bật, người dùng tắt quyền thông báo trong cài đặt hệ thống rồi quay lại app | UI nói thông báo đang bị chặn và chỉ đường mở cài đặt; settings giữ nguyên bật (BR-REMINDER-011) |
| Bị từ chối, rồi bật lại quyền trong cài đặt hệ thống và quay lại app | Banner "bị từ chối" tự mất; toggle vẫn tắt, người dùng tự chạm bật (BR-REMINDER-011) |
```

`UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md`: in step 1 replace `trên màn khoá (BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-005).` with

```
trên màn khoá (BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-005). Màn chỉ đọc
   (không xin) trạng thái quyền notification khi mở và khi resume; nhắc đang bật
   mà quyền bị tắt thì màn nói rõ và chỉ đường mở cài đặt, settings không đổi
   (BR-REMINDER-011).
```

In E1 replace `hành động thử lại. Hệ thống không tự xin lại quyền (BR-REMINDER-011).` with

```
hành động thử lại. Hệ thống không tự xin lại quyền (BR-REMINDER-011). Khi người
  dùng bật lại quyền ở cài đặt hệ thống và quay về app, lý do tự mất; toggle vẫn
  **tắt**.
```

`docs/shared/ui/screen-handoff/24-daily-reminder.md`:

- Layout, Banner row: replace `Only after an operation left a problem: E1 \`warning\`, E3 \`danger\`, E6 \`warning\`. |` with `Only after an operation left a problem: E1 \`warning\`, E3 \`danger\`, E6 \`warning\`; or, with the reminder on, when Android blocks MemoX's notifications (read on open and on resume, never asked): \`warning\`, titled "Notifications are blocked for MemoX", with "Open system settings" (SP2b 2.34). |`
- States: add after the `permDenied` row `| permRevoked | \`reminder_perm_revoked_light.png\` | \`reminder_perm_revoked_dark.png\` | The reminder is on but Android blocks its notifications: the toggle row reads "On · notifications are blocked for MemoX" and a \`warning\` banner offers "Open system settings". Nothing stored changes; both go when the permission is back on the next resume (SP2b 2.34, 2.36). |`
- Rulings: add `- **SP2b 2.34 (spec \`2026-10-03-ui-hardening-sp2b-design.md\`):** the screen reads the permission without asking (\`ReminderPlatformRepository.notificationPermission\`, \`reminderPermissionProvider\`) on open and on resume. Unknown or unreadable counts as allowed, so a warning is never false.`
- Copy: add `- Revoked: "On · notifications are blocked for MemoX" · title "Notifications are blocked for MemoX" · "The reminder is on, but Android won't show it. Allow notifications in Android Settings › Apps › MemoX › Notifications." · "Open system settings".`

`docs/shared/ui/screen-handoff/00-index.md`: row 24, States `9` → `10`.

- [ ] **Step 8: Run the checks, then commit**

```bash
git add lib/features/reminders/presentation/providers/reminder_permission_provider.dart lib/features/reminders/presentation/screens/reminder_screen.dart lib/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart lib/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/support/reminder_screen_harness.dart test/features/reminders/presentation/reminder_permission_test.dart test/features/reminders/presentation/reminder_screen_golden_test.dart docs/features/reminders/rules/BR-REMINDER-011-xin-quyen-sau-khi-bat.md docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md docs/shared/ui/screen-handoff/24-daily-reminder.md docs/shared/ui/screen-handoff/00-index.md
git commit -m "fix(reminders): say when Android blocks a reminder that is on (SP2b 2.34)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 21 (B3): The "blocked" guidance goes when the permission comes back (2.36, merged into 2.34)

**Files:**
- Modify: `lib/features/reminders/presentation/controllers/reminder_controller.dart` (add a method after `retry`, lines 51-55)
- Modify: `lib/features/reminders/presentation/screens/reminder_screen.dart` (`build`, lines 48-62)
- Test: `test/features/reminders/presentation/reminder_controller_test.dart` (append in `main()`)
- Test: `test/features/reminders/presentation/reminder_permission_test.dart` (append in `main()`)
- Docs: `docs/shared/ui/screen-handoff/24-daily-reminder.md`

**Interfaces:**
- Consumes: `reminderPermissionProvider` (B2), `ReminderProblem.permissionDenied`.
- Produces: `ReminderController.clearPermissionProblem(): void`.

Goldens: none.

- [ ] **Step 1: Write the failing tests**

Append to `reminder_controller_test.dart` inside `main()`:

```dart
  libraryTest('clearPermissionProblem: the refused-permission problem goes, '
      'and Retry has nothing left to repeat (SP2b 2.36)', (tester, env) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();
    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.permissionDenied,
    );
    final writes = s.store.writes;

    _controller(s.container).clearPermissionProblem();
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    await _controller(s.container).retry();

    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
      reason: 'BR-REMINDER-011: nothing asks again by itself',
    );
    expect(s.store.writes, writes);
  });

  libraryTest('clearPermissionProblem leaves every other problem alone', (
    tester,
    env,
  ) async {
    final s = _setUp(
      env,
      platform: FakeReminderPlatform()..refusing.add(PlatformCall.schedule),
    );
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();

    _controller(s.container).clearPermissionProblem();

    expect(
      s.container.read(reminderControllerProvider).problem,
      ReminderProblem.couldNotTurnOn,
    );
  });
```

Append to `reminder_permission_test.dart` inside `main()`:

```dart
  libraryTest('refused, then allowed in system settings: the guidance and the '
      '"refused" hint go on resume, the toggle stays off (2.36)', (
    tester,
    env,
  ) async {
    final s = await pumpReminderScreen(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await tapReminderToggle(tester);
    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderDeniedHint), findsOneWidget);
    final writes = s.store.writes;

    s.platform.permission = ReminderPermission.granted;
    await resumeReminderApp(tester);

    expect(find.text(_en.reminderDeniedTitle), findsNothing);
    expect(find.text(_en.reminderDeniedHint), findsNothing);
    expect(find.text(_en.reminderOffHint), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(s.store.writes, writes);
    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(1),
      reason: 'BR-REMINDER-011: turning it on is the person\'s tap',
    );
  });

  libraryTest('refused and still blocked on resume: the guidance stays (2.36)', (
    tester,
    env,
  ) async {
    await pumpReminderScreen(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await tapReminderToggle(tester);

    await resumeReminderApp(tester);

    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders/presentation/reminder_controller_test.dart test/features/reminders/presentation/reminder_permission_test.dart`
Expected: FAIL. The controller tests do not compile (`clearPermissionProblem` is undefined); the screen test finds `reminderDeniedTitle` still on screen.

- [ ] **Step 3: Implement**

`reminder_controller.dart`, after `retry()`:

```dart
  /// The permission came back (allowed in system settings): the "blocked"
  /// guidance no longer holds. Nothing is asked or stored and the toggle stays
  /// off, since turning it on is the person's tap (BR-REMINDER-011, SP2b
  /// 2.36). Every other problem, and any operation in flight, is left alone.
  void clearPermissionProblem() {
    if (state.isBusy || state.problem != ReminderProblem.permissionDenied) {
      return;
    }
    _again = null;
    state = const ReminderActionState();
  }
```

`reminder_screen.dart`, in `build`, after the `saveFailed` listener:

```dart
    ref.listen(reminderPermissionProvider, (_, next) {
      // A read in flight is not an answer, and its previous value is not new.
      if (next.isLoading || next.value != ReminderPermission.granted) return;
      _controller.clearPermissionProblem();
    });
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders/presentation`
Expected: PASS.

- [ ] **Step 5: Docs**

`24-daily-reminder.md`, Rulings: add `- **SP2b 2.36:** the "refused" guidance and the "Off · notification permission was refused" hint go on the next resume once the permission is allowed. The toggle stays off; turning it on is the person's tap (BR-REMINDER-011).`

- [ ] **Step 6: Run the checks, then commit**

```bash
git add lib/features/reminders/presentation/controllers/reminder_controller.dart lib/features/reminders/presentation/screens/reminder_screen.dart test/features/reminders/presentation/reminder_controller_test.dart test/features/reminders/presentation/reminder_permission_test.dart docs/shared/ui/screen-handoff/24-daily-reminder.md
git commit -m "fix(reminders): the blocked guidance goes when permission is allowed again (SP2b 2.36)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 22 (B4): The time dialog clears an invalid flag on a step and says why Save is off (2.35)

**Files:**
- Modify: `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart` (state class lines 199-302)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `test/features/reminders/presentation/reminder_time_dialog_test.dart`
- Modify: `test/features/reminders/presentation/reminder_screen_golden_test.dart` (add one state)
- Docs: `docs/shared/ui/screen-handoff/24-daily-reminder.md`, `docs/shared/ui/screen-handoff/00-index.md`

**Interfaces:**
- Consumes: `MxStepper({isInvalid, onDecrement, onIncrement, onValueSubmitted})`, `MxFieldMessage({required message, tone = error})` (`lib/shared/widgets/mx_field_message.dart`).
- Produces: ARB keys `reminderHourRange`, `reminderMinuteRange`.

Goldens that move: none (`reminder_changing_time_*` has no invalid flag). New: `reminder_time_invalid_light.png`, `reminder_time_invalid_dark.png`.

- [ ] **Step 1: Add the ARB keys and regenerate**

`app_en.arb`: replace

```json
  "@reminderLaterMinute": {
    "description": "Screen handoff 24 (FE-B5): the time dialog (A1, spec D2): the minute stepper's +."
  },
```

with

```json
  "@reminderLaterMinute": {
    "description": "Screen handoff 24 (FE-B5): the time dialog (A1, spec D2): the minute stepper's +."
  },
  "reminderHourRange": "Enter an hour from 0 to 23.",
  "@reminderHourRange": {
    "description": "Screen handoff 24 (SP2b 2.35): the time dialog's line under the hour stepper after a typed hour out of range."
  },
  "reminderMinuteRange": "Enter a minute from 0 to 59.",
  "@reminderMinuteRange": {
    "description": "Screen handoff 24 (SP2b 2.35): the time dialog's line under the minute stepper after a typed minute out of range."
  },
```

`app_vi.arb`: replace `  "reminderLaterMinute": "Phút muộn hơn",` with

```json
  "reminderLaterMinute": "Phút muộn hơn",
  "reminderHourRange": "Nhập giờ từ 0 đến 23.",
  "reminderMinuteRange": "Nhập phút từ 0 đến 59.",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing tests**

Create `test/features/reminders/presentation/reminder_time_dialog_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

import '../../../support/library_harness.dart';

// Screen 24's time dialog (UC-REMINDER-001 A1; SP2b 2.35).

final _en = lookupAppLocalizations(const Locale('en'));

/// The dialog open on 20:00 over a page with one button.
Future<void> _open(WidgetTester tester, LibraryEnv env) async {
  await pumpLibraryScreen(
    tester,
    env,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => unawaited(
              showReminderTimeDialog(context, minuteOfDay: 20 * 60),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Taps the stepper that shows [shown], types [text] and presses Done.
Future<void> _type(WidgetTester tester, String shown, String text) async {
  await tester.tap(find.text(shown));
  await tester.pump();
  await tester.enterText(find.byType(EditableText), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

MxButton _save(WidgetTester tester) => tester.widget<MxButton>(
  find.widgetWithText(MxButton, _en.reminderTimeSave),
);

void main() {
  libraryTest('a typed hour of 24 says why Save is off, and a step clears it', (
    tester,
    env,
  ) async {
    await _open(tester, env);
    await _type(tester, '20', '24');

    expect(find.text(_en.reminderHourRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.tap(find.byTooltip(_en.reminderEarlierHour));
    await tester.pump();

    expect(find.text(_en.reminderHourRange), findsNothing);
    expect(_save(tester).onPressed, isNotNull);
    expect(find.text('19:00'), findsOneWidget);
  });

  libraryTest('a typed minute of 75 says why Save is off, and a step clears '
      'it', (tester, env) async {
    await _open(tester, env);
    await _type(tester, '00', '75');

    expect(find.text(_en.reminderMinuteRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.tap(find.byTooltip(_en.reminderLaterMinute));
    await tester.pump();

    expect(find.text(_en.reminderMinuteRange), findsNothing);
    expect(_save(tester).onPressed, isNotNull);
    expect(find.text('20:01'), findsOneWidget);
  });

  libraryTest('typing a valid value after a wrong one clears the line', (
    tester,
    env,
  ) async {
    await _open(tester, env);
    await _type(tester, '20', '24');
    expect(find.byType(MxFieldMessage), findsOneWidget);

    await _type(tester, '20', '7');

    expect(find.byType(MxFieldMessage), findsNothing);
    expect(find.text('07:00'), findsOneWidget);
    expect(_save(tester).onPressed, isNotNull);
  });

  libraryTest('both wrong: each stepper has its own line, and one step clears '
      'only its own', (tester, env) async {
    await _open(tester, env);
    await _type(tester, '20', '24');
    await _type(tester, '00', '75');
    expect(find.byType(MxFieldMessage), findsNWidgets(2));

    await tester.tap(find.byTooltip(_en.reminderEarlierHour));
    await tester.pump();

    expect(find.text(_en.reminderHourRange), findsNothing);
    expect(find.text(_en.reminderMinuteRange), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/reminders/presentation/reminder_time_dialog_test.dart`
Expected: FAIL. `find.text(_en.reminderHourRange)` finds nothing (no line is drawn), and after a step Save stays disabled because the flag never clears.

- [ ] **Step 4: Implement**

In `reminder_time_dialog_widget.dart` add `import 'package:memox/shared/widgets/mx_field_message.dart';` and, in the state class after `_typed`:

```dart
  /// A step starts again from the number the stepper shows, so it also clears
  /// a typed value that was out of range (SP2b 2.35).
  void _stepHour(int by) => setState(() {
    _hour += by;
    _isHourInvalid = false;
  });

  void _stepMinute(int by) => setState(() {
    _minute += by;
    _isMinuteInvalid = false;
  });
```

Hour stepper:

```dart
              onDecrement: _hour > 0 ? () => _stepHour(-1) : null,
              onIncrement: _hour < _lastHour ? () => _stepHour(1) : null,
```

Minute stepper:

```dart
              onDecrement: _minute > 0 ? () => _stepMinute(-1) : null,
              onIncrement: _minute < _lastMinute ? () => _stepMinute(1) : null,
```

Give each `_labelled` call its line: after the stepper argument of the hour call add `problem: _isHourInvalid ? l10n.reminderHourRange : null,`, and of the minute call `problem: _isMinuteInvalid ? l10n.reminderMinuteRange : null,`. Replace `_labelled`:

```dart
  Widget _labelled(
    BuildContext context,
    String label,
    Widget stepper, {
    String? problem,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label, style: context.textStyles.settingsLabel),
          ),
          stepper,
        ],
      ),
      if (problem != null) MxFieldMessage(message: problem),
    ],
  );
```

Update the class doc: `…a typed value out of range marks its stepper, says the range under it and keeps Save off until a valid value is typed or a step clears it.`

- [ ] **Step 5: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/reminders/presentation/reminder_time_dialog_test.dart test/features/reminders/presentation/reminder_screen_test.dart`
Expected: PASS (`a typed minute outside 0–59 disables Save` still holds).

- [ ] **Step 6: Add the golden test**

In `reminder_screen_golden_test.dart` add `import 'package:memox/l10n/generated/app_localizations.dart';`, `final _en = lookupAppLocalizations(const Locale('en'));` above `main`, and after the `changing time` test:

```dart
    // SP2b 2.35: a typed minute out of range, with its line.
    libraryTest('reminder, time invalid, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'time_invalid',
        act: (_) async {
          await toggle(tester);
          await tester.tap(find.text('20:00'));
          await _settle(tester);
          await tester.tap(find.text('00'));
          await tester.pump();
          await tester.enterText(find.byType(EditableText), '75');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
          expect(find.text(_en.reminderMinuteRange), findsOneWidget);
        },
      );
    });
```

PNGs come from the Linux container later; never `--update-goldens`.

- [ ] **Step 7: Docs**

`24-daily-reminder.md`:

- States: after `changingTime` add `| timeInvalid | \`reminder_time_invalid_light.png\` | \`reminder_time_invalid_dark.png\` | A typed hour or minute out of range marks its stepper and a line under it names the range; Save stays off until a valid value is typed or a step clears it (SP2b 2.35). |`
- Accessibility: replace `a typed value out of range marks the stepper and keeps Save off.` with `a typed value out of range marks the stepper, says the range in a line under it (announced), and keeps Save off.`
- Copy, Dialog bullet: append `· "Enter an hour from 0 to 23." · "Enter a minute from 0 to 59."`
- Rulings: add `- **SP2b 2.35:** a step clears that stepper's invalid flag; the line under it ("Enter an hour from 0 to 23.") says why Save is off.`

`00-index.md`: row 24, States `10` → `11`.

- [ ] **Step 8: Run the checks, then commit**

```bash
git add lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/reminders/presentation/reminder_time_dialog_test.dart test/features/reminders/presentation/reminder_screen_golden_test.dart docs/shared/ui/screen-handoff/24-daily-reminder.md docs/shared/ui/screen-handoff/00-index.md
git commit -m "fix(reminders): the time dialog clears an invalid flag on a step and says why Save is off (SP2b 2.35)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 23 (B5): A refused session on Sync offers "Sign in" (2.37)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sections/sync_notice_widget.dart` (fields lines 22-35; `build` lines 37-47)
- Modify: `lib/features/settings/presentation/screens/sync_screen.dart` (constructor line 32; `_leadsSyncNow` lines 36-44; `build` lines 47-80)
- Modify: `lib/app/router/app_router.dart` (lines 287-291)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify (mechanical): `test/features/settings/presentation/sync_screen_test.dart`, `sync_offline_note_test.dart`, `sync_screen_golden_test.dart`, `test/visual_audit/screens/features/settings/screens/sync_screen_visual_audit_test.dart` (every `const SyncScreen()`)
- Create: `test/features/settings/presentation/sync_screen_sign_in_test.dart`
- Create: `test/app/sync_routes_test.dart`
- Modify: `test/features/settings/presentation/sync_screen_golden_test.dart` (add one state)
- Docs: `docs/superpowers/specs/2026-09-28-sync-status-design.md` (§5.4), `docs/shared/ui/screen-handoff/27-sync.md`, `docs/shared/ui/screen-handoff/00-index.md`

**Interfaces:**
- Consumes: `authStateProvider` (`lib/core/auth/di/auth_providers.dart`), `ReauthRequired` (`lib/core/auth/auth_state.dart`), `AppRoutes.settingsSignInReauth({required String from})`, `AppRoutes.settingsSync`, `l10n.accountSignIn`.
- Produces:
  - `SyncScreen({super.key, required VoidCallback onSignIn})`.
  - `SyncNoticeWidget({…, required bool canSignIn, required VoidCallback onSignIn})` and `static bool SyncNoticeWidget.asksSignIn(SyncStatus status, {required bool canSignIn})`.
  - ARB key `syncSignInAgain`.

Goldens that move: none (no existing sync golden has a signIn failure). New: `sync_failed_sign_in_light.png`, `sync_failed_sign_in_dark.png`.

DECISION: `canSignInAgainProvider` lives in `features/account/presentation`, and features are islands (flutter-architecture: no import of another feature's `presentation/`). `SyncScreen` therefore reads `authStateProvider` (core) with the same one-line test, `value is ReauthRequired`, as `canSignInAgain`. Recommended: yes.

- [ ] **Step 1: Add the ARB key and regenerate**

`app_en.arb`: replace

```json
  "@syncFailedUnknown": {
    "description": "Screen 27 (SB-U1): the failure banner, unknown."
  },
```

with

```json
  "@syncFailedUnknown": {
    "description": "Screen 27 (SB-U1): the failure banner, unknown."
  },
  "syncSignInAgain": "Your sign-in expired, so sync is paused. Your changes are safe on this device. Sign in again to resume.",
  "@syncSignInAgain": {
    "description": "Screen 27 (SP2b 2.37): the warning banner when the session was refused and the person can sign in again; its action is accountSignIn."
  },
```

`app_vi.arb`: replace the line `  "syncFailedUnknown": "Đồng bộ dừng vì có lỗi. Thay đổi của bạn vẫn an toàn trên máy. MemoX sẽ thử lại.",` with

```json
  "syncFailedUnknown": "Đồng bộ dừng vì có lỗi. Thay đổi của bạn vẫn an toàn trên máy. MemoX sẽ thử lại.",
  "syncSignInAgain": "Phiên đăng nhập đã hết hạn nên đồng bộ đang tạm dừng. Thay đổi vẫn an toàn trên điện thoại này. Đăng nhập lại để tiếp tục.",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing tests**

Create `test/features/settings/presentation/sync_screen_sign_in_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

// Screen 27: a refused session offers Sign in (SP2b 2.37).

final _en = lookupAppLocalizations(const Locale('en'));

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

SyncStatus _signInFailed(LibraryEnv env, {int rejectedCount = 0}) => SyncStatus(
  rejectedCount: rejectedCount,
  lastFailure: LastSyncFailure(SyncFailureKind.signIn, env.clock.now()),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

MxButton _syncNow(WidgetTester tester) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, _en.syncNow));

void main() {
  libraryTest('a refused session says sync is paused and offers Sign in; Sync '
      'now steps back (2.37)', (tester, env) async {
    var signIns = 0;
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () => signIns++),
      overrides: [
        ...syncOverrides(_signInFailed(env)),
        authStateOf(const ReauthRequired(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncSignInAgain), findsOneWidget);
    expect(find.text(_en.syncFailedSignIn), findsNothing);
    expect(
      tester.widget<MxInlineBanner>(find.byType(MxInlineBanner)).tone,
      MxBannerTone.warning,
    );
    expect(_syncNow(tester).tone, MxButtonTone.outline);
    expectOnePrimaryPerDecision(tester);

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    expect(signIns, 1);
  });

  libraryTest('a sign-in failure with no refused session is the plain '
      'sentence: nothing to sign in to (2.37)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: [
        ...syncOverrides(_signInFailed(env)),
        authStateOf(const Ready(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncFailedSignIn), findsOneWidget);
    expect(find.text(_en.syncSignInAgain), findsNothing);
    expect(find.widgetWithText(MxButton, _en.accountSignIn), findsNothing);
    expect(_syncNow(tester).tone, MxButtonTone.primary);
  });

  libraryTest('refused rows keep their own banner over a refused session '
      '(2.37)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: [
        ...syncOverrides(_signInFailed(env, rejectedCount: 2)),
        authStateOf(const ReauthRequired(_account)),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.syncRejectedTitle(2)), findsOneWidget);
    expect(find.text(_en.syncSignInAgain), findsNothing);
  });
}
```

Create `test/app/sync_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';

final _en = lookupAppLocalizations(const Locale('en'));

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

/// Screen 27's route (SP2b 2.37): Sign in opens screen 30 in re-auth mode and
/// a successful sign-in returns to Sync.
void main() {
  accountTest('Sync offers Sign in on a refused session, and signing in '
      'returns to Sync', (tester, env, world) async {
    await refuseSession(world);
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(
            SyncStatus(
              lastFailure: LastSyncFailure(
                SyncFailureKind.signIn,
                env.clock.now(),
              ),
            ),
          ),
        ),
      ],
    );
    _router(tester).go(AppRoutes.settingsSync);
    await tester.pumpAndSettle();
    expect(find.text(_en.syncSignInAgain), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountSendCode)); // the address is filled
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.settingsSync,
    );
    expect(world.state, isA<Ready>());
  });
}
```

(`pumpMemoxApp` and `accountTest` come from `account_harness.dart`'s re-use of `library_harness.dart`; add `import '../support/library_harness.dart';` if the analyzer reports `pumpMemoxApp` undefined.)

- [ ] **Step 3: Update every existing construction, then run to see the real failure**

`onSignIn` is required (as `AccountScreen.onSignInAgain` is), so the 23 existing call sites change mechanically:

```bash
sed -i 's/const SyncScreen()/SyncScreen(onSignIn: () {})/g' test/features/settings/presentation/sync_screen_test.dart test/features/settings/presentation/sync_offline_note_test.dart test/features/settings/presentation/sync_screen_golden_test.dart test/visual_audit/screens/features/settings/screens/sync_screen_visual_audit_test.dart
```

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation/sync_screen_sign_in_test.dart test/app/sync_routes_test.dart`
Expected: FAIL to compile: `No named parameter with the name 'onSignIn'`.

- [ ] **Step 4: Implement**

`sync_notice_widget.dart`:

```dart
  const SyncNoticeWidget({
    super.key,
    required this.status,
    required this.task,
    required this.onRun,
    required this.canSignIn,
    required this.onSignIn,
  });

  final SyncStatus status;
  final SyncTask? task;
  final ValueChanged<SyncTask> onRun;

  /// The session was refused and the person can sign in again.
  final bool canSignIn;

  /// Opens the sign-in flow that returns to this screen (SP2b 2.37).
  final VoidCallback onSignIn;

  static bool shows(SyncStatus status) =>
      status.rejectedCount > 0 || status.lastFailure != null;

  /// A refused session with no refused row: the banner asks to sign in, and
  /// Sync now cannot succeed (SP2b 2.37). A transient refusal, where nothing
  /// can be signed in again, keeps the plain sentence.
  static bool asksSignIn(SyncStatus status, {required bool canSignIn}) =>
      canSignIn &&
      status.rejectedCount == 0 &&
      status.lastFailure?.kind == SyncFailureKind.signIn;
```

At the top of `build`, after `final l10n = context.l10n;`:

```dart
    if (asksSignIn(status, canSignIn: canSignIn)) {
      return MxInlineBanner(
        tone: MxBannerTone.warning,
        message: l10n.syncSignInAgain,
        actions: [
          MxButton(
            label: l10n.accountSignIn,
            size: MxButtonSize.compact,
            onPressed: onSignIn,
          ),
        ],
      );
    }
```

Update the class doc: add `A refused session with no refused row asks to sign in again (SP2b 2.37).`

`sync_screen.dart`: add imports `package:memox/core/auth/auth_state.dart` and `package:memox/core/auth/di/auth_providers.dart`; then

```dart
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key, required this.onSignIn});

  /// Opens the sign-in flow that returns here (SP2b 2.37).
  final VoidCallback onSignIn;
```

```dart
  /// Sync now leads only when something waits or the last run failed, no
  /// row was refused, and neither the network nor a refused session is what
  /// failed: with refused rows the banner's Try again is the one primary
  /// (DESIGN.md One Indigo; critique 2026-09-30 part 1), offline a manual run
  /// cannot help (critique 2026-10-02, F8), and with a refused session the
  /// banner's Sign in leads (SP2b 2.37).
  static bool _leadsSyncNow(SyncStatus status, {required bool canSignIn}) =>
      status.rejectedCount == 0 &&
      status.lastFailure?.kind != SyncFailureKind.network &&
      !SyncNoticeWidget.asksSignIn(status, canSignIn: canSignIn) &&
      (status.pendingCount > 0 || status.lastFailure != null);
```

In `build`, after `final status = ref.watch(syncStatusProvider);`:

```dart
    // The same test as `canSignInAgainProvider`, read from core: a feature
    // does not import another feature's presentation.
    final canSignIn = ref.watch(authStateProvider).value is ReauthRequired;
```

Pass to the notice: `canSignIn: canSignIn, onSignIn: onSignIn,`; and to the button: `tone: _leadsSyncNow(value, canSignIn: canSignIn) ? … : …`.

`app_router.dart` (route at lines 287-291):

```dart
                  GoRoute(
                    path: AppRoutes.settingsSyncChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => SyncScreen(
                      onSignIn: () => unawaited(
                        context.push(
                          AppRoutes.settingsSignInReauth(
                            from: AppRoutes.settingsSync,
                          ),
                        ),
                      ),
                    ),
                  ),
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation test/app/sync_routes_test.dart test/visual_audit/screens/features/settings`
Expected: PASS.

- [ ] **Step 6: Add the golden test**

In `sync_screen_golden_test.dart`: add imports `package:memox/core/auth/account_user.dart`, `package:memox/core/auth/auth_state.dart` and `../../../support/account_harness.dart`; give the `golden` helper `List<Override> overrides = const [],` (import `package:flutter_riverpod/misc.dart` for `Override`) and spread it: `overrides: [...syncOverrides(status, commands), ...overrides],`; then add:

```dart
    // SP2b 2.37: the session was refused; Sign in leads.
    libraryTest('sync, failed sign-in, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'failed_sign_in',
        SyncStatus(
          lastSuccessAt: minutesAgo(env, 90),
          pendingCount: 3,
          oldestPendingAt: minutesAgo(env, 30),
          lastFailure: LastSyncFailure(
            SyncFailureKind.signIn,
            minutesAgo(env, 1),
          ),
        ),
        overrides: [
          authStateOf(
            const ReauthRequired(
              AccountUser(
                id: 'x',
                email: 'a@example.com',
                isAnonymous: false,
                role: AccountRole.user,
              ),
            ),
          ),
        ],
        act: () async {
          await tester.pump();
          expect(find.text('Sign in'), findsOneWidget);
        },
      );
    });
```

PNGs come from the Linux container; never `--update-goldens`.

- [ ] **Step 7: Docs**

`docs/superpowers/specs/2026-09-28-sync-status-design.md` §5.4: after the `- signIn:` bullet (ends `try again."`) add

```
  When the session was refused (`ReauthRequired`) and no row was refused, the banner
  reads "Your sign-in expired, so sync is paused. Your changes are safe on this
  device. Sign in again to resume." with a compact "Sign in" that opens screen 30 in
  re-auth mode and returns to screen 27; Sync now is outline (SP2b 2.37). A
  sign-in failure with no refused session keeps the sentence above.
```

`27-sync.md`: Problem row, append `A refused session with no refused row reads "Your sign-in expired, so sync is paused. Your changes are safe on this device. Sign in again to resume." with a compact primary "Sign in" (opens screen 30 in re-auth mode and returns here); Sync now is outline (SP2b 2.37).`; Rulings: add `- **SP2b 2.37:** a refused session offers Sign in; a transient sign-in failure keeps the plain sentence, since there is nothing to sign in to.`; Copy, Failures bullet: append `· "Your sign-in expired, so sync is paused. Your changes are safe on this device. Sign in again to resume." · "Sign in"`. Do not add a State row with an image link yet: the PNGs do not exist until the Linux run (the golden step adds the `failedSignIn` row with the other new images).

`00-index.md`: row 27, States `7` → `8`.

- [ ] **Step 8: Run the checks, then commit**

```bash
git add lib/features/settings/presentation/widgets/sections/sync_notice_widget.dart lib/features/settings/presentation/screens/sync_screen.dart lib/app/router/app_router.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/settings/presentation/sync_screen_test.dart test/features/settings/presentation/sync_offline_note_test.dart test/features/settings/presentation/sync_screen_golden_test.dart test/features/settings/presentation/sync_screen_sign_in_test.dart test/visual_audit/screens/features/settings/screens/sync_screen_visual_audit_test.dart test/app/sync_routes_test.dart docs/superpowers/specs/2026-09-28-sync-status-design.md docs/shared/ui/screen-handoff/27-sync.md docs/shared/ui/screen-handoff/00-index.md
git commit -m "fix(sync): a refused session offers Sign in instead of a Sync now that cannot succeed (SP2b 2.37)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 24 (B6): A failed refresh keeps the Monitoring rows under a warning with Retry (2.38)

**Files:**
- Modify: `lib/features/monitoring/presentation/states/monitoring_list_state.dart` (lines 184-209)
- Modify: `lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart` (`refresh` lines 80-88; `loadMore` success lines 108-114; `_loadFirst` lines 148-163)
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart` (`_Rows.build` lines 157-196)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `test/features/monitoring/presentation/monitoring_list_refresh_test.dart`
- Test: `test/features/monitoring/presentation/monitoring_screen_test.dart` (append in `main()`, after `pull to refresh asks the first page again`, lines 282-292)
- Modify: `test/features/monitoring/presentation/monitoring_screen_golden_test.dart` (add one state)
- Docs: `docs/shared/ui/screen-handoff/28-monitoring.md`, `docs/shared/ui/screen-handoff/00-index.md`

**Interfaces:**
- Consumes: `MonitoringLoadFailure.of(Object)` (`offline`, `notAdmin`, `other`), `MxInlineBanner`, `MxButton`, `FakeMonitoringRepository` / `QueryCall.answer|fail` / `pageOf` (`test/support/monitoring_fakes.dart`).
- Produces:
  - `MonitoringListLoaded({…, MonitoringLoadFailure? refreshFailure})` and `MonitoringListLoaded.withRefreshFailure(MonitoringLoadFailure?): MonitoringListLoaded`.
  - ARB key `monitoringRefreshFailed`.

Goldens that move: none. New: `monitoring_list_refresh_failed_light.png`, `monitoring_list_refresh_failed_dark.png`.

Rulings made here (spec §3.6 does not cover them):
- DECISION: a refresh that fails while the list is **empty** has no rows to keep, so it stays the full failure page (an empty-state "No open problems" over a failed read would claim all is well). Recommended: yes.
- A refresh already in flight clears the banner at once (`refresh()`), as `retry()` clears a failure, so Retry shows it did something; the banner returns if it fails again.
- A `loadMore` that was in flight when a refresh fails is dropped by the generation guard; `more` goes back to idle so the end of the list is not stuck on a spinner.

- [ ] **Step 1: Add the ARB key and regenerate**

`app_en.arb`: replace

```json
  "@monitoringLoadMoreFailed": {
    "description": "Screen 28: the end of the list when the next page failed."
  },
```

with

```json
  "@monitoringLoadMoreFailed": {
    "description": "Screen 28: the end of the list when the next page failed."
  },
  "monitoringRefreshFailed": "Couldn't refresh the list. The rows below are from the last time it loaded.",
  "@monitoringRefreshFailed": {
    "description": "Screen 28 (SP2b 2.38): the warning banner above the rows when a pull to refresh failed and the rows were kept; its action is Retry."
  },
```

`app_vi.arb`: replace the line `  "monitoringLoadMoreFailed": "Chưa tải thêm được nhật ký.",` with

```json
  "monitoringLoadMoreFailed": "Chưa tải thêm được nhật ký.",
  "monitoringRefreshFailed": "Không làm mới được danh sách. Các dòng bên dưới là lần tải trước.",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing tests**

Create `test/features/monitoring/presentation/monitoring_list_refresh_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2, SP2b 2.38: a refresh that fails keeps the rows.

void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(monitoringListControllerProvider, (_, _) {});
  });

  MonitoringListController controller() =>
      container.read(monitoringListControllerProvider.notifier);
  MonitoringListState state() => container.read(monitoringListControllerProvider);
  MonitoringListLoaded loaded() => state().content as MonitoringListLoaded;
  List<String> ids() => [for (final item in loaded().items) item.id];

  /// The first page, answered with [page].
  Future<void> open(LogPage page) async {
    await pumpEventQueue();
    repository.lastQuery.answer(page);
    await pumpEventQueue();
  }

  /// A refresh asked and answered with a failure.
  Future<void> refreshFailing(Object error) async {
    final refreshing = controller().refresh();
    await pumpEventQueue();
    repository.lastQuery.fail(error);
    await refreshing;
  }

  test('a refresh that fails keeps the rows and says which way it failed', () async {
    await open(pageOf(2));

    await refreshFailing(const OfflineFailure(cause: 'x'));
    expect(ids(), ['r0', 'r1']);
    expect(loaded().refreshFailure, MonitoringLoadFailure.offline);

    await refreshFailing(const ServerFailure(cause: 'x'));
    expect(ids(), ['r0', 'r1']);
    expect(loaded().refreshFailure, MonitoringLoadFailure.other);
  });

  test('a refresh asked again clears the warning at once, and a page that '
      'lands replaces the rows', () async {
    await open(pageOf(2));
    await refreshFailing(const OfflineFailure(cause: 'x'));

    final again = controller().refresh();
    await pumpEventQueue();
    expect(loaded().refreshFailure, isNull);
    expect(ids(), ['r0', 'r1']);
    repository.lastQuery.answer(pageOf(1, prefix: 'n'));
    await again;

    expect(ids(), ['n0']);
    expect(loaded().refreshFailure, isNull);
  });

  test('a lost admin role still replaces the rows', () async {
    await open(pageOf(2));

    await refreshFailing(const NotAdminFailure(cause: 'x'));

    expect(
      (state().content as MonitoringListFailed).failure,
      MonitoringLoadFailure.notAdmin,
    );
  });

  test('an empty list has no rows to keep: the failure page stands', () async {
    await open(pageOf(0));

    await refreshFailing(const OfflineFailure(cause: 'x'));

    expect(
      (state().content as MonitoringListFailed).failure,
      MonitoringLoadFailure.offline,
    );
  });

  test('a new filter clears the rows first, so its failure is the full page', () async {
    await open(pageOf(2));

    controller().setFilter(const LogFilter().withSearch('a'));
    await pumpEventQueue();
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await pumpEventQueue();

    expect(state().content, isA<MonitoringListFailed>());
  });

  test('with a filter set, a failed refresh keeps the rows and the filter', () async {
    await open(pageOf(1));
    final filter = const LogFilter().withSearch('push');
    controller().setFilter(filter);
    await pumpEventQueue();
    repository.lastQuery.answer(pageOf(2, prefix: 'f'));
    await pumpEventQueue();

    await refreshFailing(const OfflineFailure(cause: 'x'));

    expect(ids(), ['f0', 'f1']);
    expect(state().filter, filter);
    expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
  });

  test('a page that was loading when the refresh failed is not left spinning', () async {
    await open(pageOf(LogPage.size));
    final more = controller().loadMore();
    await pumpEventQueue();
    expect(loaded().more, MonitoringMore.loading);

    await refreshFailing(const OfflineFailure(cause: 'x'));
    // The dropped page answers late; nothing changes.
    repository.queries[1].answer(pageOf(3, prefix: 'p'));
    await more;

    expect(loaded().more, MonitoringMore.idle);
    expect(loaded().items, hasLength(LogPage.size));
    expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
  });

  test('a next page that lands keeps the warning: the first rows are still '
      'from the earlier load', () async {
    await open(pageOf(LogPage.size));
    await refreshFailing(const OfflineFailure(cause: 'x'));

    final more = controller().loadMore();
    await pumpEventQueue();
    repository.lastQuery.answer(pageOf(3, prefix: 'p'));
    await more;

    expect(loaded().items, hasLength(LogPage.size + 3));
    expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
  });
}
```

Append to `monitoring_screen_test.dart` inside `main()`, after `pull to refresh asks the first page again`:

```dart
  libraryTest('a pull to refresh that fails keeps the rows under a warning '
      'with Retry, which asks again (SP2b 2.38)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.queries, hasLength(2));
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await tester.pumpAndSettle();

    const warning =
        "Couldn't refresh the list. The rows below are from the last time it loaded.";
    expect(find.text(warning), findsOneWidget);
    expect(find.text('2 LOGS'), findsOneWidget);
    expect(find.text('message of r0'), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.queries, hasLength(3));
    expect(find.text(warning), findsNothing);
    repository.lastQuery.answer(pageOf(1, prefix: 'n'));
    await tester.pumpAndSettle();
    expect(find.text('message of n0'), findsOneWidget);
    expect(find.text(warning), findsNothing);
  });

  libraryTest('a lost admin role on refresh replaces the rows (SP2b 2.38)', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    repository.lastQuery.fail(const NotAdminFailure(cause: 'x'));
    await tester.pumpAndSettle();

    expect(find.text('Only an admin can see this'), findsOneWidget);
    expect(find.text('message of r0'), findsNothing);
  });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/monitoring/presentation/monitoring_list_refresh_test.dart test/features/monitoring/presentation/monitoring_screen_test.dart`
Expected: FAIL to compile (`The getter 'refreshFailure' isn't defined for the type 'MonitoringListLoaded'`); the screen tests then fail on the warning text (the rows are replaced by the error state today).

- [ ] **Step 4: Implement**

`monitoring_list_state.dart`: replace `MonitoringListLoaded` and the `MonitoringListFailed` doc:

```dart
/// The pages read so far. Empty is a state the screen words (default
/// filter, or another); [next] is null at the last page.
final class MonitoringListLoaded extends MonitoringListContent {
  const MonitoringListLoaded({
    required this.items,
    required this.next,
    this.more = MonitoringMore.idle,
    this.refreshFailure,
  });

  final List<LogSummaryEntity> items;
  final LogCursor? next;
  final MonitoringMore more;

  /// The last pull to refresh failed and [items] are from the load before
  /// it (SP2b 2.38); null when the rows are current.
  final MonitoringLoadFailure? refreshFailure;

  MonitoringListLoaded withMore(MonitoringMore value) => MonitoringListLoaded(
    items: items,
    next: next,
    more: value,
    refreshFailure: refreshFailure,
  );

  MonitoringListLoaded withItems(List<LogSummaryEntity> value) =>
      MonitoringListLoaded(
        items: value,
        next: next,
        more: more,
        refreshFailure: refreshFailure,
      );

  MonitoringListLoaded withRefreshFailure(MonitoringLoadFailure? value) =>
      MonitoringListLoaded(
        items: items,
        next: next,
        more: more,
        refreshFailure: value,
      );
}

/// The first page failed, or a refresh found the admin role gone; no stale
/// row is shown.
final class MonitoringListFailed extends MonitoringListContent {
```

`monitoring_list_controller.dart`, `refresh`:

```dart
  Future<void> refresh() {
    final filter = _intended;
    _debounce?.cancel();
    _pendingSearch = null;
    if (filter != state.filter) state = MonitoringListState(filter: filter);
    // The last refresh's warning goes at once, as a retry's failure does; it
    // comes back if this one fails too (SP2b 2.38).
    if (_loaded case final shown? when shown.refreshFailure != null) {
      _show(shown.withRefreshFailure(null));
    }
    return _loadFirst();
  }
```

`loadMore` success:

```dart
      state = MonitoringListState(
        filter: filter,
        content: MonitoringListLoaded(
          items: [...latest.items, ...page.items],
          next: page.next,
          refreshFailure: latest.refreshFailure,
        ),
      );
```

`_loadFirst` catch:

```dart
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      final failure = MonitoringLoadFailure.of(error);
      final shown = _loaded;
      // A pull to refresh that fails keeps the rows (SP2b 2.38). A new filter
      // cleared them first, an empty list has none to keep, and a lost admin
      // role must not leave logs on screen.
      if (shown != null &&
          shown.items.isNotEmpty &&
          failure != MonitoringLoadFailure.notAdmin) {
        // A page that was loading is dropped by the generation guard.
        _show(
          shown.withMore(MonitoringMore.idle).withRefreshFailure(failure),
        );
        return;
      }
      _show(MonitoringListFailed(failure));
    }
```

`monitoring_server_list_widget.dart`, in `_Rows.build`, children after the first `SizedBox`:

```dart
            const SizedBox(height: AppSpacing.control),
            if (loaded.refreshFailure != null)
              MxInlineBanner(
                tone: MxBannerTone.warning,
                message: l10n.monitoringRefreshFailed,
                actions: [
                  MxButton(
                    label: l10n.commonRetry,
                    size: MxButtonSize.compact,
                    onPressed: () => unawaited(controller.refresh()),
                  ),
                ],
              ),
            MxListSectionHeader(label: header),
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/monitoring`
Expected: PASS (the existing `a pull to refresh keeps the rows until the first page lands` and `an old failure never replaces the new rows` still hold).

- [ ] **Step 6: Add the golden test**

In `monitoring_screen_golden_test.dart` add `import 'dart:async';` and, after the `list offline` test:

```dart
    // SP2b 2.38: a pull to refresh failed; the rows stay under a warning.
    libraryTest('monitoring, list refresh failed, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository();
      await golden(
        tester,
        env,
        'list_refresh_failed',
        repository,
        act: () async {
          repository.lastQuery.answer(_openPage());
          await _settle(tester);
          unawaited(
            ProviderScope.containerOf(
                  tester.element(find.byType(MonitoringScreen)),
                )
                .read(monitoringListControllerProvider.notifier)
                .refresh(),
          );
          await tester.pump();
          repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
          await _settle(tester);
          expect(find.textContaining("Couldn't refresh the list"), findsOneWidget);
        },
      );
    });
```

PNGs come from the Linux container; never `--update-goldens`.

- [ ] **Step 7: Docs**

`28-monitoring.md`:

- Layout: the list, `End` row: append to its Design cell ` A pull to refresh that fails keeps the rows under a \`warning\` \`MxInlineBanner\` above the count, "Couldn't refresh the list. The rows below are from the last time it loaded." with Retry, which refreshes again (SP2b 2.38). A lost admin role, a new filter or search, and an empty list show the full failure page instead.`
- Copy, add a bullet: `- Refresh: "Couldn't refresh the list. The rows below are from the last time it loaded." · "Retry".`
- Add a ruling under the Rulings (or Copy-adjacent rulings) section: `- **SP2b 2.38:** a failed refresh keeps the rows; only \`notAdmin\`, a new filter or search, and an empty list replace them.` (If the file has no Rulings heading, add it under the list layout as a paragraph.)

Do not add a State row with an image link yet: the PNGs do not exist until the Linux run.

`00-index.md`: row 28, States `15` → `16`.

- [ ] **Step 8: Run the checks, then commit**

```bash
git add lib/features/monitoring/presentation/states/monitoring_list_state.dart lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/features/monitoring/presentation/monitoring_list_refresh_test.dart test/features/monitoring/presentation/monitoring_screen_test.dart test/features/monitoring/presentation/monitoring_screen_golden_test.dart docs/shared/ui/screen-handoff/28-monitoring.md docs/shared/ui/screen-handoff/00-index.md
git commit -m "fix(monitoring): a failed refresh keeps the rows under a warning with Retry (SP2b 2.38)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 25 (B7): A lost admin role ends Mark fixed as "Only an admin can see this" (2.39)

**Files:**
- Modify: `lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart` (imports lines 3-13; `setStatus` catch, lines 61-66)
- Test: `test/features/monitoring/presentation/monitoring_detail_controller_test.dart` (append in `main()`, after `a change that fails changes nothing…`, line ~190)
- Docs: `docs/shared/ui/screen-handoff/28-monitoring.md`

**Interfaces:**
- Consumes: `NotAdminFailure` (`lib/core/error/failure.dart`, already thrown by `mapMonitoringError` for `FORBIDDEN`), `MonitoringDetailFailed(MonitoringLoadFailure.notAdmin)` (the page already draws it as `monitoringNotAdminTitle` with no footer).
- Produces: none.

Goldens: none.

- [ ] **Step 1: Write the failing test**

Append to `monitoring_detail_controller_test.dart` inside `main()`:

```dart
  // SP2b 2.39: the server answers FORBIDDEN once the role is gone.
  test('a lost admin role ends the page as not-an-admin, with no failed-change '
      'notice to retry (2.39)', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.statusError = const NotAdminFailure(cause: 'FORBIDDEN');

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    final state = container.read(server);
    expect(
      (state.content as MonitoringDetailFailed).failure,
      MonitoringLoadFailure.notAdmin,
    );
    expect(state.notice, isNull);
    expect(state.changing, isNull);
  });
```


- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/monitoring/presentation/monitoring_detail_controller_test.dart`
Expected: FAIL: `state.content` is `MonitoringDetailLoaded` and `state.notice` is a `StatusChangeFailed`, whose Retry would repeat the change for ever.

- [ ] **Step 3: Implement**

`monitoring_detail_controller.dart`: add `import 'package:memox/core/error/failure.dart';` and, before `} on Object {` in `setStatus`:

```dart
    } on NotAdminFailure {
      // The role is gone: a Retry could never succeed, so the page ends as
      // the load does for a user who is not an admin (SP2b 2.39).
      if (!ref.mounted) return;
      state = const MonitoringDetailState(
        content: MonitoringDetailFailed(MonitoringLoadFailure.notAdmin),
      );
    } on Object {
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/monitoring/presentation/monitoring_detail_controller_test.dart test/features/monitoring/presentation/monitoring_detail_screen_test.dart`
Expected: PASS (the offline-failure retry test still holds).

- [ ] **Step 5: Docs**

`28-monitoring.md`, detail layout `Triage` row, append: ` If the server answers FORBIDDEN (the role was lost), the page becomes "Only an admin can see this" with no footer and no Retry toast (SP2b 2.39).`

- [ ] **Step 6: Run the checks, then commit**

```bash
git add lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart test/features/monitoring/presentation/monitoring_detail_controller_test.dart docs/shared/ui/screen-handoff/28-monitoring.md
git commit -m "fix(monitoring): a lost admin role on Mark fixed ends the page instead of offering Retry (SP2b 2.39)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Cluster notes

**Order.** B1 → B2 → B3 is a chain (B2 consumes B1's `notificationPermission()` and the fake; B3 consumes B2's provider). B4, B5, B6 and B7 are independent of each other and of the chain; B4 only shares `reminder_screen_golden_test.dart` and `24-daily-reminder.md` with B2.

**Cross-task interfaces and shared files.**
- `lib/l10n/app_en.arb` and `app_vi.arb` are touched by B2, B4, B5, B6. Each task inserts by anchoring on an existing key (`reminderOpenSystemSettings`, `reminderLaterMinute`, `syncFailedUnknown`, `monitoringLoadMoreFailed`), never by line number, so other clusters' inserts do not collide. VI keys carry no `@description` (the VI file has none); EN keys all have one.
- `docs/shared/ui/screen-handoff/00-index.md` rows 24 (9 → 10 in B2, → 11 in B4), 27 (7 → 8 in B5), 28 (15 → 16 in B6).
- `test/support/fake_reminder_platform.dart` (B1) and `reminder_screen_harness.dart` (B2) are reminder-only support files; no other cluster uses them.
- Generated code: B2 adds one provider (`dart run build_runner build --delete-conflicting-outputs`); B2, B4, B5, B6 add ARB keys (`flutter gen-l10n`). `*.g.dart` and `lib/l10n/generated` are untracked, so nothing generated is committed.
- No `.drift` query, no migration and no `supabase/` change in this cluster, so `verification_impact_map.json` needs no new owner.

**Goldens.** No existing golden moves in this cluster. New states, all light and dark, to be generated in the Linux container after the code lands: `reminder_perm_revoked`, `reminder_time_invalid` (24), `sync_failed_sign_in` (27), `monitoring_list_refresh_failed` (28). 24's State rows are text only and were added in B2 and B4; the State rows with image links for 27 and 28 are deliberately not added in these tasks, because `tools/docs/check.py` fails on a link to a PNG that does not exist yet. Add them in the golden-generation commit, next to the PNGs: `failedSignIn` in `27-sync.md` (`sync_failed_sign_in_*`) and `list, refresh failed` in `28-monitoring.md` (`monitoring_list_refresh_failed_*`).

**Risks.**
- `resumeReminderApp` drives the lifecycle through the full transition chain; if this Flutter version's `AppLifecycleListener` asserts on a transition, only that helper needs changing (B2 Step 5).
- B5 makes `SyncScreen.onSignIn` required and rewrites 23 `const SyncScreen()` sites with one `sed`; if another cluster edits the same test files in parallel, expect a trivial textual merge.
- B6 changes `MonitoringListLoaded`'s constructor with an optional named argument only; no other caller changes.
- Test file size: `monitoring_screen_test.dart` grows from 362 to about 410 physical lines (still under the 500 physical / 400 logical limits); the new controller tests went to their own file for that reason. `reminder_screen_golden_test.dart` grows to about 240 lines.

**DECISION list (for the controller).**
1. **B5 reads `authStateProvider`, not `canSignInAgainProvider`.** The spec names the account provider, but the settings feature may not import another feature's `presentation/` (flutter-architecture, features are islands). `SyncScreen` uses `ref.watch(authStateProvider).value is ReauthRequired`, the provider's own one-line body. Recommended: yes. The alternative is moving `canSignInAgain` to `lib/core/auth/di`, a wider change.
2. **B5 makes `SyncScreen.onSignIn` required**, matching `AccountScreen.onSignInAgain`, and updates 23 test call sites mechanically. Recommended: yes.
3. **B2 adds one line beyond the spec:** `reminderPermission` also watches `reminderStatusProvider`'s `isEnabled`. Without it, a read made before the person allowed notifications (a fresh Android 13 install reads "blocked") would show a false revoked warning right after turning the reminder on. Pinned by the fourth test of `reminder_permission_test.dart`. Recommended: yes.
4. **B6, empty list plus a failed refresh stays the full failure page** instead of an empty-state with a warning, since "No open problems" over a failed read would claim all is well. Recommended: yes.
5. **B6, `refresh()` clears the banner at once** (and a `loadMore` dropped by the refresh goes back to idle), so Retry visibly acts and the end of the list is never stuck on a spinner. Recommended: yes.
6. **State rows with images for 27 and 28** are added with the PNGs after the Linux run, not in these commits (see Goldens).


## Cluster C — Account (screens 29–33), tasks C1–C11

**Scope:** spec §3.7 rows 2.40, 2.41 (with merged 2.44), 2.42, 2.43 (R11), 2.45, 2.46, 2.47, 2.48, the §4 shared-code item `InvalidEmailFailure` (DECISION 2, recommended yes), and the detail-file / spec-doc updates for screens 29–33 (§8). Spec §5 has no BR change for the account cluster; the account-UI spec line it names (`Recovering.isStuck`) is edited in C11.

**Conventions every task in this cluster follows** (SP2a lessons):

- After the edits, run `dart format` on every touched `.dart` file and `flutter analyze lib test` (the whole tree; it must print `No issues found!`), then the guard: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` (exit 0, 0 warnings). Where a task creates a provider, run `dart run build_runner build --delete-conflicting-outputs` first (`*.g.dart` is git-ignored: never `git add` it). Where a task touches an ARB file, run `flutter gen-l10n` first (`lib/l10n/generated/` is git-ignored too).
- Tests run at the default text scale. Instants in tests are fixed (`DateTime(2026, 10, 3, 9)`), never `DateTime.now()`. In widget tests the clock the controllers see is `env.clock` (`FakeDayClock(libraryToday)`, installed by `libraryTest`); in plain `ProviderContainer` tests the test overrides `dayClockProvider` with its own `FakeDayClock`.
- Single test file: `flutter test <file>`. A folder: `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/run_tests.sh <dir>`. Never `flutter test <dir>`; never `--update-goldens` (PNGs come later, from the Linux container).
- Commit trailer on every commit: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Every task states which goldens it may move. Golden tests (`@Tags(['golden'])`) cannot run on Windows: the implementer only checks that they compile (`flutter analyze lib test`).

---

### Task 26 (C1): Declining the merge sheet forgets the Google account that was picked (2.40)

**Files:**
- Modify: `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart` (doc comment at `:19-23`; `startLinkSwitch` body at `:45-60`)
- Test: `test/features/account/presentation/merge_choice_sheet_test.dart` (imports at `:1-18`; append a test after `'Cancel starts nothing'` at `:139-154`)

**Interfaces:**
- Consumes: `AccountCoordinator.forgetPickedGoogle()` (extension `AccountSwitching`, `lib/core/auth/account_coordinator_switch.dart:71`, unchanged); `FakeAuthGateway.google` (`test/support/fake_auth_server.dart:100`).
- Produces: no new API. Behaviour: `startLinkSwitch` returns `false` after calling `accounts.forgetPickedGoogle()` on three paths: the sheet dismissed (or the context gone), `beginSwitch` throwing a `Failure`, and `beginSwitch` throwing a `StateError`. A started switch (`return true`) keeps the credential: the target sign-in needs it.

Why it matters: `continueWithGoogle` keeps `_pendingGoogle` after `IdentityTakenFailure` so the switch can sign in with the same pick. If the person cancels the sheet, the next press of "Continue with Google" silently reuses that old pick, and the picker never shows again.

- [ ] **Step 1: Write the failing test**

Add to the imports of `merge_choice_sheet_test.dart`:

```dart
import 'package:memox/core/auth/auth_gateway.dart' show GoogleCredential;
```

Append inside `main()` after the `'Cancel starts nothing'` test:

```dart
  accountTest('Cancel forgets the Google account picked for the sheet, so '
      'the next press shows the picker again (2.40)', (
    tester,
    env,
    world,
  ) async {
    await env.decks.root('Korean');
    world.server.addUser(email: 'g@example.com');
    // The link meets an existing account: the pick is kept for the switch.
    await expectLater(
      world.coordinator.continueWithGoogle(),
      throwsA(isA<IdentityTakenFailure>()),
    );
    await pumpLibraryScreen(
      tester,
      env,
      _host(email: null),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('go'));
    await _settle(tester);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);

    // The picker answers with another account now. A kept pick would be used
    // instead, and would be refused again as taken.
    world.gateway.google = const GoogleCredential(
      idToken: 'second-pick',
      email: 'h@example.com',
    );
    await world.coordinator.continueWithGoogle();
    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'h@example.com'),
    );
  });
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/features/account/presentation/merge_choice_sheet_test.dart`
Expected: the new test FAILS with an uncaught `IdentityTakenFailure` from the last `continueWithGoogle()` (the kept `g@example.com` pick is reused). The other tests pass.

- [ ] **Step 3: Implement**

In `merge_choice_sheet_widget.dart`, extend the doc comment of `startLinkSwitch` (after "Returns whether the switch started; the transition layer takes over from there."):

```dart
/// A switch that does not start (the sheet declined, or the account refused)
/// forgets the Google account picked for it, so the next press shows the
/// picker again (SP2b 2.40); a started switch keeps it for the target
/// sign-in.
```

Replace `:45-60`:

```dart
  if (choice == null || !context.mounted) {
    accounts.forgetPickedGoogle();
    return false;
  }
  try {
    await accounts.beginSwitch(choice: choice, targetHint: email);
    return true;
  } on Failure catch (error) {
    accounts.forgetPickedGoogle();
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failure(error));
    }
    return false;
  } on StateError {
    // The account moved on meanwhile: it takes a switch only in Ready.
    accounts.forgetPickedGoogle();
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failureAccount);
    }
    return false;
  }
}
```

- [ ] **Step 4: Run the test file again**

Run: `flutter test test/features/account/presentation/merge_choice_sheet_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Format, analyze, guard**

Run: `dart format lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart test/features/account/presentation/merge_choice_sheet_test.dart`, then `flutter analyze lib test`, then `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`.
Expected: no issues; guard exit 0, 0 warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart test/features/account/presentation/merge_choice_sheet_test.dart
git commit -m "fix(account): a declined merge sheet forgets the Google account picked for it (SP2b 2.40)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 27 (C2): A code just sent is not sent again, and its wait survives leaving (2.41, merged 2.44)

**Files:**
- Create: `lib/features/account/presentation/providers/last_code_sent_provider.dart` (+ generated `.g.dart`, not committed)
- Modify: `lib/features/account/presentation/controllers/sign_in_controller.dart` (imports `:1-5`; `sendCode` at `:29-48`)
- Modify: `lib/features/account/presentation/controllers/code_controller.dart` (imports `:1-8`; `build` at `:23-28`; `resend` at `:63-93`)
- Test: `test/features/account/presentation/sign_in_controller_test.dart` (imports `:1-9`; `setUp` at `:17-25`; new group after `'a cancelled Google pick says nothing'` at `:132-136`)
- Test: `test/features/account/presentation/code_controller_test.dart` (imports `:1-9`; `setUp` at `:14-18`; `containerOf` at `:22-27`; new group at the end of `main()`)

**Interfaces:**
- Consumes: `dayClockProvider` / `DayClock.now()` (`lib/core/clock/di/day_clock_provider.dart`); `CodeController.resendWait` (60 s, `code_controller.dart:18`); `SignInPurpose` (`sign_in_state.dart:7`); `FakeDayClock.current` (`test/support/fake_day_clock.dart`).
- Produces (new, feature-local, in-memory):

```dart
typedef CodeSent = ({SignInPurpose purpose, String email, DateTime sentAt});

@Riverpod(keepAlive: true)
class LastCodeSent extends _$LastCodeSent {
  @override
  CodeSent? build() => null;

  /// A code went to [email] for [purpose] at [at].
  void record(SignInPurpose purpose, String email, DateTime at);

  /// What is left of [wait] since the last recorded send, in whole seconds
  /// (rounded up, never above [wait]); null when the last send was to another
  /// address or purpose, or none was recorded.
  Duration? waitLeft(
    SignInPurpose purpose,
    String email,
    DateTime now,
    Duration wait,
  );
}
// provider: lastCodeSentProvider
```

Behaviour:
- `SignInController.sendCode` returns `SignInOutcome.codeSent` without calling the server when `waitLeft(...)` is greater than zero. A successful send records `now`.
- `CodeController.build` starts at `waitLeft(...) ?? resendWait`; a zero start runs no timer. (A send this app run did not record, such as a test calling the coordinator directly, still starts a fresh 60 s.)
- `CodeController.resend` records `now` on success, and also on `RateLimitedFailure` (the server saw a send within the minute) and then waits `resendWait` again with `_startWait()`. Other failures still return `Duration.zero` and record nothing.
- The key is `(purpose, email.trim().toLowerCase())`: `"A@x.com"` and `"a@x.com "` are the same address; a one-letter edit is another address and sends. Only the last send is held (DECISION 3 below).

- [ ] **Step 1: Write the failing tests for the sign-in controller**

In `sign_in_controller_test.dart` add imports:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';

import '../../../support/fake_day_clock.dart';
```

(place the `../../../support/fake_day_clock.dart` import with the other relative imports, sorted.) Change the `setUp` so the container reads a clock the test moves:

```dart
  late FakeDayClock clock;

  setUp(() async {
    clock = FakeDayClock(DateTime(2026, 10, 3, 9));
    world = AuthWorld();
    await readyAnonymous(world);
    container = ProviderContainer(
      overrides: [
        ...accountOverrides(world),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
    container.listen(provider, (_, _) {});
  });
```

Add a group after `'a cancelled Google pick says nothing'`:

```dart
  group('a code already on its way (2.41)', () {
    test('the same address inside the wait reopens the code step without '
        'sending, whatever its case or spaces', () async {
      expect(await controller().sendCode('a@example.com'), SignInOutcome.codeSent);
      world.server.sentCodes.clear();
      clock.current = clock.current.add(const Duration(seconds: 30));

      expect(
        await controller().sendCode('  A@Example.com '),
        SignInOutcome.codeSent,
      );

      expect(world.server.sentCodes, isEmpty);
      expect(state().isRunning, isFalse);
    });

    test('another address sends, and so does the same one once the wait is '
        'over', () async {
      await controller().sendCode('a@example.com');
      world.server.sentCodes.clear();

      expect(
        await controller().sendCode('a@example.org'),
        SignInOutcome.codeSent,
      );
      expect(world.server.sentCodes.keys, ['a@example.org']);

      world.server.sentCodes.clear();
      clock.current = clock.current.add(CodeController.resendWait);
      expect(
        await controller().sendCode('a@example.org'),
        SignInOutcome.codeSent,
      );
      expect(world.server.sentCodes.keys, ['a@example.org']);
    });

    test('a refused send is not recorded: the next press asks the server '
        'again', () async {
      world.gateway.failNextRequest = const RateLimitedFailure();
      expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);

      expect(await controller().sendCode('a@example.com'), SignInOutcome.codeSent);
      expect(world.server.sentCodes.keys, ['a@example.com']);
    });
  });
```

- [ ] **Step 2: Write the failing tests for the code controller**

In `code_controller_test.dart` add imports:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';

import '../../../support/fake_day_clock.dart';
```

(`code_state.dart` brings `ResendOutcome`.) Replace `setUp` and `containerOf`:

```dart
  late FakeDayClock clock;

  setUp(() async {
    clock = FakeDayClock(DateTime(2026, 10, 3, 9));
    world = AuthWorld();
    await readyAnonymous(world);
    await world.coordinator.requestCode('a@example.com');
  });
  tearDown(() => world.close());

  /// A container whose controller is not built yet, so a test can record a
  /// send first.
  ProviderContainer bareContainer() {
    final container = ProviderContainer(
      overrides: [
        ...accountOverrides(world),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ProviderContainer containerOf() {
    final container = bareContainer();
    container.listen(provider, (_, _) {});
    return container;
  }
```

Append at the end of `main()`:

```dart
  group('a code sent a moment ago (2.41, 2.44)', () {
    void sentAgo(
      ProviderContainer container,
      Duration ago, {
      String email = 'A@Example.com',
      SignInPurpose purpose = SignInPurpose.link,
    }) => container
        .read(lastCodeSentProvider.notifier)
        .record(purpose, email, clock.current.subtract(ago));

    test('the wait picks up where the last send left it, in whole seconds', () {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 20, milliseconds: 400));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).resendIn, const Duration(seconds: 40));
      expect(container.read(provider).canResend, isFalse);
    });

    test('a send older than the wait leaves Resend open at once', () {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).canResend, isTrue);
    });

    for (final (email, purpose) in [
      ('b@example.com', SignInPurpose.link),
      ('a@example.com', SignInPurpose.reauth),
    ]) {
      test('a send to $email for ${purpose.name} is not this step\'s', () {
        final container = bareContainer();
        sentAgo(container, const Duration(seconds: 30), email: email, purpose: purpose);
        container.listen(provider, (_, _) {});

        expect(container.read(provider).resendIn, CodeController.resendWait);
      });
    }

    test('a successful resend records the send and waits a minute', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.sent,
      );

      expect(container.read(provider).resendIn, CodeController.resendWait);
      expect(container.read(lastCodeSentProvider)?.sentAt, clock.current);
    });

    test('a rate-limited resend waits a minute too, and leaving the step '
        'keeps what is left of it (2.44)', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});
      world.gateway.failNextRequest = const RateLimitedFailure();

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.refused,
      );

      expect(container.read(provider).problem, SignInProblem.rateLimited);
      expect(container.read(provider).resendIn, CodeController.resendWait);
      // Leave and come back ten seconds later: the controller is built again.
      clock.current = clock.current.add(const Duration(seconds: 10));
      container.invalidate(provider);
      expect(container.read(provider).resendIn, const Duration(seconds: 50));
    });

    test('any other refusal leaves Resend open and records nothing', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});
      world.network.goOffline();

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.refused,
      );

      expect(container.read(provider).problem, SignInProblem.offline);
      expect(container.read(provider).canResend, isTrue);
      expect(
        container.read(lastCodeSentProvider)?.sentAt,
        clock.current.subtract(const Duration(seconds: 61)),
      );
    });
  });
```

(`Failure` is imported for `RateLimitedFailure`; `AccountCoordinator`/`auth_state` imports already in the file stay.)

- [ ] **Step 3: Run both files and watch them fail**

Run: `flutter test test/features/account/presentation/sign_in_controller_test.dart test/features/account/presentation/code_controller_test.dart`
Expected: compile FAILURE (`last_code_sent_provider.dart` does not exist).

- [ ] **Step 4: Implement the provider**

Create `lib/features/account/presentation/providers/last_code_sent_provider.dart`:

```dart
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_code_sent_provider.g.dart';

/// The last sign-in code this app run sent: for which sign-in, to which
/// address, and when.
typedef CodeSent = ({SignInPurpose purpose, String email, DateTime sentAt});

/// Which code is on its way, so leaving the code step and coming back, or
/// pressing "Send code" again for the same address, does not ask the server
/// for another one inside the resend wait (SP2b 2.41, 2.44). In memory and
/// feature-local; only the last send is held.
@Riverpod(keepAlive: true)
class LastCodeSent extends _$LastCodeSent {
  @override
  CodeSent? build() => null;

  void record(SignInPurpose purpose, String email, DateTime at) =>
      state = (purpose: purpose, email: _keyOf(email), sentAt: at);

  /// What is left of [wait] since the last recorded send, in whole seconds
  /// (rounded up, never above [wait], so a clock set back adds nothing). Null
  /// when the last send was to another address or purpose, or none was
  /// recorded: the caller decides what that means.
  Duration? waitLeft(
    SignInPurpose purpose,
    String email,
    DateTime now,
    Duration wait,
  ) {
    final last = state;
    if (last == null || last.purpose != purpose || last.email != _keyOf(email)) {
      return null;
    }
    final left = wait - now.difference(last.sentAt);
    if (left <= Duration.zero) return Duration.zero;
    if (left >= wait) return wait;
    return Duration(
      seconds: (left.inMicroseconds / Duration.microsecondsPerSecond).ceil(),
    );
  }
}

/// "A@x.com" and "a@x.com " are one address.
String _keyOf(String email) => email.trim().toLowerCase();
```

Run: `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 5: Implement `SignInController.sendCode`**

Imports (keep them sorted):

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
```

Replace the tail of `sendCode` (`:43-47`, the `return _run(...)`):

```dart
    final sent = ref.read(lastCodeSentProvider.notifier);
    final clock = ref.read(dayClockProvider);
    // The same address inside the resend wait: the code on its way is still
    // the one to enter, so the code step reopens and nothing is sent (2.41).
    final left = sent.waitLeft(
      purpose,
      address,
      clock.now(),
      CodeController.resendWait,
    );
    if (left != null && left > Duration.zero) return SignInOutcome.codeSent;
    final outcome = await _run(
      SignInTask.email,
      (accounts) => accounts.requestCode(address, confirmedLoss: confirmedLoss),
      done: SignInOutcome.codeSent,
    );
    if (outcome == SignInOutcome.codeSent) {
      sent.record(purpose, address, clock.now());
    }
    return outcome;
  }
```

- [ ] **Step 6: Implement `CodeController`**

Imports:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
```

Replace `build` (`:23-28`):

```dart
  @override
  CodeState build(String email, SignInPurpose purpose) {
    ref.onDispose(() => _timer?.cancel());
    // Read, not watched: a send recorded while this step is open must not
    // rebuild it. A code sent a moment ago keeps its wait across leaving and
    // coming back (2.41); one this run did not record starts a fresh minute.
    final wait =
        ref
            .read(lastCodeSentProvider.notifier)
            .waitLeft(purpose, email, ref.read(dayClockProvider).now(), resendWait) ??
        resendWait;
    if (wait > Duration.zero) _startWait();
    return CodeState(resendIn: wait);
  }
```

Replace the body of `resend` from `final accounts = …` to the final `return outcome;` (`:63-93`):

```dart
  Future<ResendOutcome> resend({bool confirmedLoss = false}) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || !state.canResend) return ResendOutcome.refused;
    // Captured before the await: the step may be left while the code is on
    // its way, and the send still has to be remembered.
    final sent = ref.read(lastCodeSentProvider.notifier);
    final clock = ref.read(dayClockProvider);
    state = const CodeState(isResending: true);
    SignInProblem? problem;
    try {
      await accounts.requestCode(email, confirmedLoss: confirmedLoss);
    } on UnsentChangesFailure catch (error) {
      if (ref.mounted) {
        state = CodeState(
          isVerifying: state.isVerifying,
          unsentCount: error.count,
        );
      }
      return ResendOutcome.unsentChanges;
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    final isSent = problem == null;
    // A rate limit means the server saw a send within the minute: wait that
    // long again instead of offering a Resend that is sure to be refused
    // (2.44).
    final isWaiting = isSent || problem == SignInProblem.rateLimited;
    if (isWaiting) sent.record(purpose, email, clock.now());
    final outcome = isSent ? ResendOutcome.sent : ResendOutcome.refused;
    if (!ref.mounted) return outcome;
    state = CodeState(
      isVerifying: state.isVerifying,
      problem: problem,
      resendIn: isWaiting ? resendWait : Duration.zero,
    );
    if (isWaiting) _startWait();
    return outcome;
  }
```

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/account/presentation/sign_in_controller_test.dart test/features/account/presentation/code_controller_test.dart test/features/account/presentation/code_screen_test.dart test/features/account/presentation/sign_in_screen_test.dart`
Expected: PASS. (The screen tests are included because they drive these controllers: their calls go to the coordinator directly, so no send is recorded and the code step still starts at `1:00`.)

- [ ] **Step 8: Format, analyze, guard**

Run `dart format` on the 5 `.dart` files above, `flutter analyze lib test`, then the guard command (exit 0, 0 warnings).

- [ ] **Step 9: Commit**

```bash
git add lib/features/account/presentation/providers/last_code_sent_provider.dart lib/features/account/presentation/controllers/sign_in_controller.dart lib/features/account/presentation/controllers/code_controller.dart test/features/account/presentation/sign_in_controller_test.dart test/features/account/presentation/code_controller_test.dart
git commit -m "fix(account): a code just sent is not sent again, and its resend wait survives leaving (SP2b 2.41, 2.44)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none (`code_waiting` still shows `1:00`: the golden's code is requested through the coordinator, which records nothing).

---

### Task 28 (C3): An address GoTrue calls invalid is the address problem (2.42, shared `InvalidEmailFailure`)

**Files:**
- Modify: `lib/core/error/failure.dart` (new class after `RateLimitedFailure`, `:97-100`)
- Modify: `lib/core/auth/supabase_auth_errors.dart` (`_fromAuth` at `:28-47`)
- Modify: `lib/features/account/presentation/states/sign_in_state.dart` (`signInProblemOf` at `:61-66`)
- Test: `test/core/auth/supabase_auth_errors_test.dart` (append after `"GoTrue's codes"` at `:21-58`)
- Test: `test/features/account/presentation/sign_in_controller_test.dart` (append after `'a rate limit says so'` at `:71-76`)
- Test: `test/l10n/failure_message_test.dart` (list at `:12-22`)

**Interfaces:**
- Produces: `final class InvalidEmailFailure extends AuthFailure { const InvalidEmailFailure({super.cause}); }` (message `'That email address is not valid.'`). `FailureMessage.failure` needs no change: it falls under its existing `AuthFailure()` branch (`lib/l10n/failure_message.dart:15`).
- `classifyAuthError` maps `email_address_invalid`, and `validation_failed` whose message names the email, to it. `signInProblemOf(InvalidEmailFailure())` is the existing `SignInProblem.invalidEmail`, which the form already shows under the field (`accountEmailInvalid`).

- [ ] **Step 1: Write the failing tests**

Append to `supabase_auth_errors_test.dart` inside `main()`:

```dart
  test('an address GoTrue refuses is the address, not a server error (2.42)', () {
    Failure of(String message, String code) => classifyAuthError(
      AuthApiException(message, statusCode: '422', code: code),
    );

    expect(
      of('Email address "x@" is invalid', 'email_address_invalid'),
      isA<InvalidEmailFailure>(),
    );
    expect(
      of('Unable to validate email address: invalid format', 'validation_failed'),
      isA<InvalidEmailFailure>(),
    );
    expect(
      of('Password should be at least 6 characters', 'validation_failed'),
      isA<ServerFailure>(),
    );
  });
```

Append to `sign_in_controller_test.dart` after `'a rate limit says so'`:

```dart
  test('an address the server refuses reads as the address problem, not '
      '"try again" (2.42)', () async {
    world.gateway.failNextRequest = const InvalidEmailFailure();

    expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);

    expect(state().problem, SignInProblem.invalidEmail);
    expect(state().problemTask, SignInTask.email);
  });
```

In `failure_message_test.dart` add `const InvalidEmailFailure(cause: 'email_address_invalid'),` to the `failures` list (after `InvalidCodeFailure`).

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/core/auth/supabase_auth_errors_test.dart test/features/account/presentation/sign_in_controller_test.dart test/l10n/failure_message_test.dart`
Expected: compile FAILURE (`InvalidEmailFailure` is undefined).

- [ ] **Step 3: Implement**

`failure.dart`, after `RateLimitedFailure`:

```dart
/// An address the server refused as not a valid one (GoTrue
/// `email_address_invalid`, or a `validation_failed` about the email). The
/// field says "check the address", not "try again" (SP2b 2.42).
final class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure({super.cause})
    : super(message: 'That email address is not valid.');
}
```

`supabase_auth_errors.dart`, inside the `switch (error.code)` of `_fromAuth`, before the `_ when error.statusCode == '429'` case:

```dart
    'email_address_invalid' => InvalidEmailFailure(cause: error),
    // GoTrue words a malformed address as a validation failure too.
    'validation_failed' when _namesEmail(error) => InvalidEmailFailure(
      cause: error,
    ),
```

and below `_fromAuth`:

```dart
bool _namesEmail(AuthException error) =>
    error.message.toLowerCase().contains('email');
```

`sign_in_state.dart`, in `signInProblemOf`, before `InvalidCodeFailure()`:

```dart
  InvalidEmailFailure() => SignInProblem.invalidEmail,
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/auth/supabase_auth_errors_test.dart test/features/account/presentation/sign_in_controller_test.dart test/l10n/failure_message_test.dart test/core/auth/supabase_auth_gateway_test.dart`
Expected: PASS.

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 6 files above; `flutter analyze lib test` (a sealed `Failure` switch elsewhere must still be exhaustive: the only switch on it, `FailureMessage.failure`, covers `AuthFailure()`); guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/core/error/failure.dart lib/core/auth/supabase_auth_errors.dart lib/features/account/presentation/states/sign_in_state.dart test/core/auth/supabase_auth_errors_test.dart test/features/account/presentation/sign_in_controller_test.dart test/l10n/failure_message_test.dart
git commit -m "fix(account): an address the server calls invalid reads as the address problem (SP2b 2.42)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none (`sign_in_invalid` is unchanged: its `a@` is refused before anything is sent).

---

### Task 29 (C4): A stuck account layer says the move resumes, and offers "Close MemoX" (2.43, R11)

**Files:**
- Modify: `lib/l10n/app_en.arb` (`accountLayerStuck` block at `:7187-7190`)
- Modify: `lib/l10n/app_vi.arb` (`accountLayerStuck` at `:1388`)
- Modify: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart` (imports `:1-29`; `_Progress.build` stopped branch at `:202-219`)
- Modify: `test/support/account_harness.dart` (new helper after `accountOverrides` at `:42-46`; imports `:1-11`)
- Test: `test/features/account/presentation/account_transition_layer_test.dart` (the stuck test at `:304-328`)
- Test: `test/features/account/presentation/account_golden_test.dart` (layers loop at `:231-242`)

**Interfaces:**
- Consumes: `MxActionPair({MxButton? leading, required MxButton trailing})` (`lib/shared/widgets/mx_action_pair.dart`; both buttons must be `isBlock: true, isSingleLine: true`); `SystemNavigator.pop()`.
- Produces: ARB key `accountCloseApp`; new copy for `accountLayerStuck`; test helper `List<MethodCall> watchAppCloses(WidgetTester tester)` (counts the platform's `SystemNavigator.pop` calls instead of sending them, and clears the mock at teardown).

New copy:

| Key | EN | VI |
|---|---|---|
| `accountLayerStuck` (changed) | Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens. | Đã có lỗi khi chuyển tài khoản. Dữ liệu vẫn an toàn trên điện thoại này. MemoX sẽ tiếp tục việc chuyển ở lần mở sau. |
| `accountCloseApp` (new) | Close MemoX | Đóng MemoX |

- [ ] **Step 1: Write the failing test and the helper**

In `account_harness.dart` add `import 'package:flutter/services.dart';` and, after `accountOverrides`:

```dart
/// The platform's "close the app" calls (`SystemNavigator.pop`), recorded
/// instead of sent. The mock is removed when the test ends.
List<MethodCall> watchAppCloses(WidgetTester tester) {
  final closes = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') closes.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return closes;
}
```

In `account_transition_layer_test.dart` replace the test `'stuck says the data is safe and offers only Retry'` (`:304-328`) with:

```dart
  libraryTest('stuck says the data is safe and the move resumes on the next '
      'launch; Close MemoX leaves the app, Retry stays (R11)', (
    tester,
    env,
  ) async {
    final closes = watchAppCloses(tester);
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Recovering(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.merged,
              choice: TransitionChoice.merge,
            ),
            isStuck: true,
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerStuck), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.text(_en.commonCancel), findsNothing);
    // Close leads, Retry trails: side by side, Close first.
    expect(
      tester.getCenter(find.text(_en.accountCloseApp)).dx,
      lessThan(tester.getCenter(find.text(_en.commonRetry)).dx),
    );

    await tester.tap(find.text(_en.accountCloseApp));
    await tester.pump();
    expect(closes, hasLength(1));
  });

  libraryTest('a non-stuck stop keeps Retry alone', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(TransitionKind.switchAccount, TransitionStage.claimed),
            error: const OfflineFailure(cause: 'test'),
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerOffline), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.text(_en.accountCloseApp), findsNothing);
  });
```

In `account_golden_test.dart`, in the layers loop, assert the new state is on screen before the capture: change the `capture(...)` call at `:234-240` to also pass

```dart
          before: name == 'layer_stuck'
              ? () async {
                  expect(find.text(_en.accountCloseApp), findsOneWidget);
                }
              : null,
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/account/presentation/account_transition_layer_test.dart`
Expected: FAIL: `accountCloseApp` is undefined (compile error).

- [ ] **Step 3: Implement the copy**

`app_en.arb`: replace the `accountLayerStuck` block (`:7187-7190`) and add the new key after it:

```json
  "accountLayerStuck": "Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens.",
  "@accountLayerStuck": {
    "description": "Transition layer: a state the machine says cannot happen; says the data is safe and the move resumes on the next launch (SP2b R11)."
  },
  "accountCloseApp": "Close MemoX",
  "@accountCloseApp": {
    "description": "Transition layer, stuck: closes the app, beside Retry. It changes no data (SP2b R11)."
  },
```

`app_vi.arb`: replace the `accountLayerStuck` line (`:1388`) with these two lines:

```json
  "accountLayerStuck": "Đã có lỗi khi chuyển tài khoản. Dữ liệu vẫn an toàn trên điện thoại này. MemoX sẽ tiếp tục việc chuyển ở lần mở sau.",
  "accountCloseApp": "Đóng MemoX",
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Implement the layer**

In `account_transition_layer_widget.dart` add `import 'package:flutter/services.dart';` (after `flutter/material.dart`) and `import 'package:memox/shared/widgets/mx_action_pair.dart';` (sorted, before `mx_app_bar.dart`). Replace the Retry button inside `if (isStopped) ...[` (`:211-215`) with:

```dart
                  if (view.isStuck)
                    // R11: nothing here can be fixed by retrying alone, and
                    // the move resumes on the next launch, so the way out of
                    // the app sits beside Retry. It changes no data.
                    MxActionPair(
                      leading: MxButton(
                        label: l10n.accountCloseApp,
                        tone: MxButtonTone.outline,
                        isBlock: true,
                        isSingleLine: true,
                        onPressed: () => unawaited(SystemNavigator.pop()),
                      ),
                      trailing: MxButton(
                        label: l10n.commonRetry,
                        isBlock: true,
                        isSingleLine: true,
                        onPressed: () => unawaited(_retry(ref)),
                      ),
                    )
                  else
                    MxButton(
                      label: l10n.commonRetry,
                      isBlock: true,
                      onPressed: () => unawaited(_retry(ref)),
                    ),
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/account/presentation/account_transition_layer_test.dart`
Expected: PASS. Also run `flutter test test/l10n` (ARB parity and descriptions).

- [ ] **Step 6: Format, analyze, guard**

`dart format` on the 5 `.dart` files; `flutter analyze lib test` (this also compiles the golden test); guard exit 0.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart test/support/account_harness.dart test/features/account/presentation/account_transition_layer_test.dart test/features/account/presentation/account_golden_test.dart
git commit -m "feat(account): a stuck account layer says the move resumes and offers Close MemoX (SP2b 2.43, R11)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens that move: `layer_stuck_light.png`, `layer_stuck_dark.png` (copy and the Close button). No other.

---

### Task 30 (C5): A code that could not be checked keeps its digits; the field keeps the keyboard (2.45)

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/code_form_widget.dart` (imports `:1-16`; state class `:41-82`; `build` `:90-133`)
- Modify: `test/support/fake_auth_server.dart` (`holdRequests` doc at `:109-112`; `verifyEmailLink` `:183-193`; `verifyEmailSignIn` `:204-213`)
- Test: `test/features/account/presentation/code_screen_test.dart` (imports `:1-15`; append after `'after a wrong code the field keeps the keyboard'` at `:186-206`)
- Test: `test/features/account/presentation/account_golden_test.dart` (new golden after `'code, wrong'` at `:152-165`)

**Interfaces:**
- Consumes: `MxTextField({focusNode, isEnabled, errorText, …})` (`lib/shared/widgets/mx_text_field.dart:52-75`); `MxInlineBanner({tone, message, actions})`; `MxButton(size: MxButtonSize.compact)`; `CodeController.verify` (`code_controller.dart:31`, unchanged) and its `CodeState.problem`.
- Produces: `FakeAuthGateway.holdVerifies` (`Completer<void>?`; while set, `verifyEmailLink` and `verifyEmailSignIn` wait on it, after the online check). No new ARB key: `commonRetry` exists.

Behaviour (spec 2.45):
- A wrong code (`SignInProblem.wrongCode`) still clears the field and shows the problem under it, as now.
- Offline, failed or rate-limited: the six digits stay, the field is not in its error state, and a warning `MxInlineBanner` shows the problem with a compact "Retry" (`commonRetry`) that checks the same digits again. If a digit was deleted meanwhile, Retry focuses the field instead.
- `isEnabled` stays true while verifying (a disabled field drops focus); the spinner already shows the check.
- A `FocusNode` requests focus on the first frame, and again after a wrong code.
- DECISION: the banner is a warning for all three problems (a refusal or limit with nothing lost); offline is not given its own neutral tone.

- [ ] **Step 1: Write the failing tests**

In `fake_auth_server.dart`, add below `holdRequests`:

```dart
  /// While set, code checks wait on it, as a slow network does.
  Completer<void>? holdVerifies;
```

and in both `verifyEmailLink` and `verifyEmailSignIn`, right after `server.checkOnline();`, add:

```dart
    await holdVerifies?.future;
```

In `code_screen_test.dart` add `import 'package:memox/shared/widgets/mx_spinner.dart';` and append after the keyboard test:

```dart
  accountTest('the field takes the keyboard when the step opens (2.45)', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('the field stays enabled while the code is checked (2.45)', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdVerifies = Completer<void>();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    held.complete();
    world.gateway.holdVerifies = null;
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest('offline keeps the six digits and says so; Retry checks them '
      'again (2.45)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    world.network.goOffline();

    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    expect(find.text(_en.accountOffline), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123456',
    );
    expect(signIns, 0);

    world.network.goOnline();
    await tester.pump();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountOffline), findsNothing);
  });

  accountTest('Retry with a digit missing focuses the field instead of '
      'checking (2.45)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    world.network.goOffline();
    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '12345');
    world.network.goOnline();
    await tester.pump();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(signIns, 0, reason: 'five digits are not a code');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });
```

The existing tests `'a wrong code clears the field and says so; …'` and `'after a wrong code the field keeps the keyboard'` stay as they are: they pin that a wrong code still clears and keeps focus.

Golden test: in `account_golden_test.dart`, after the `'code, wrong'` test:

```dart
    accountTest('code, offline with the digits kept, $theme', (
      tester,
      env,
      world,
    ) async {
      await world.coordinator.requestCode('a@example.com');
      await capture(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        'code_offline_kept',
        overrides: accountOverrides(world),
        before: () async {
          world.network.goOffline();
          await tester.enterText(find.byType(TextField), '123456');
          await _settle(tester);
          expect(find.text(_en.accountOffline), findsOneWidget);
          expect(find.text(_en.commonRetry), findsOneWidget);
        },
      );
    });
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/features/account/presentation/code_screen_test.dart`
Expected: FAIL. The autofocus test fails (`hasFocus` false), the enabled test fails (`enabled` is false while verifying), the offline test fails (the field is cleared; no Retry), the last test fails to find Retry.

- [ ] **Step 3: Implement**

`code_form_widget.dart`: add `import 'package:memox/shared/widgets/mx_inline_banner.dart';` (sorted). Replace the state class head and handlers (`:41-64`) with:

```dart
class _CodeFormWidgetState extends ConsumerState<CodeFormWidget> {
  static const int _clockDigits = 2;

  final _code = TextEditingController();
  final _focus = FocusNode();

  /// True while the digits stand unchecked because the check could not run
  /// (offline, failed, rate limited). The digits stay and Retry checks them
  /// again (2.45).
  var _hasKeptCode = false;

  CodeController get _controller =>
      ref.read(codeControllerProvider(widget.email, widget.purpose).notifier);

  @override
  void initState() {
    super.initState();
    // The keyboard opens with the step.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _changed(String text) async {
    if (text.length < MxTextField.codeLength) return;
    await _check(text);
  }

  /// Checks [text]. A refused code is cleared; a code that could not be
  /// checked is kept, with its problem and a Retry (2.45).
  Future<void> _check(String text) async {
    final isSignedIn = await _controller.verify(text);
    if (!mounted) return;
    if (isSignedIn) {
      widget.onSignedIn?.call();
      return;
    }
    final problem = ref
        .read(codeControllerProvider(widget.email, widget.purpose))
        .problem;
    final isRefused = problem == SignInProblem.wrongCode;
    setState(() => _hasKeptCode = problem != null && !isRefused);
    if (!isRefused) return;
    _code.clear();
    _focus.requestFocus();
  }

  /// Retry: the digits typed are checked again; with one missing, the field
  /// takes the focus so it can be completed.
  void _retry() {
    if (_code.text.length < MxTextField.codeLength) {
      _focus.requestFocus();
      return;
    }
    unawaited(_check(_code.text));
  }
```

In `_resend` (`:66`), make the first statement `_hasKeptCode = false;` (a resend replaces the problem, so the Retry that belongs to a check must not outlive it; the controller's state change rebuilds the widget). In `build`, replace the field and what follows it (`:105-117`):

```dart
        MxTextField(
          controller: _code,
          focusNode: _focus,
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null || _hasKeptCode
              ? null
              : signInProblemText(l10n, problem),
        ),
        if (state.isVerifying)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: Center(child: MxSpinner(semanticLabel: l10n.commonLoading)),
          ),
        if (problem != null && _hasKeptCode)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: MxInlineBanner(
              tone: MxBannerTone.warning,
              message: signInProblemText(l10n, problem),
              actions: [
                MxButton(
                  label: l10n.commonRetry,
                  size: MxButtonSize.compact,
                  onPressed: _retry,
                ),
              ],
            ),
          ),
```

(`isEnabled: !state.isVerifying` is removed: the default is enabled.) Update the class doc line "a wrong code clears the field (plan ruling 11)" to add "; a code that could not be checked keeps its digits and offers Retry".

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/code_screen_test.dart test/features/account/presentation/account_transition_layer_test.dart`
Expected: PASS (the layer test drives the same form inside the layer).

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 5 `.dart` files; `flutter analyze lib test`; guard exit 0 (`code_screen_test.dart` stays under 400 logical lines; if the guard says otherwise, move the four new tests to a new `code_screen_keep_test.dart`).

- [ ] **Step 6: Commit**

```bash
git add lib/features/account/presentation/widgets/sections/code_form_widget.dart test/support/fake_auth_server.dart test/features/account/presentation/code_screen_test.dart test/features/account/presentation/account_golden_test.dart
git commit -m "fix(account): a code that could not be checked keeps its digits and offers Retry (SP2b 2.45)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: new `code_offline_kept_{light,dark}.png`. May move: `code_waiting_*` (the field now has focus when the step opens) and `code_wrong_*` (the banner is not involved, but the field's focus edge/caret timing may differ). Anything else that moves is a defect.

---

### Task 31 (C6): Back waits while a sign-in command runs (2.46)

**Files:**
- Modify: `lib/features/account/presentation/screens/welcome_screen.dart` (`build` at `:75-153`; class doc `:25-29`)
- Modify: `lib/features/account/presentation/screens/sign_in_screen.dart` (imports `:7`; `build` at `:48-99`)
- Modify: `lib/features/account/presentation/screens/code_screen.dart` (imports `:5-13`; `build` at `:32-60`)
- Modify: `test/support/fake_auth_server.dart` (`pickGoogle` at `:215-220`; `holdRequests` doc)
- Create: `test/features/account/presentation/account_back_hold_test.dart`

**Interfaces:**
- Consumes: `SignInState.isRunning` (`sign_in_state.dart:56`); `CodeState.isBusy` (`code_state.dart:29`); `watchAppCloses` (from C4); `pumpLibraryScreenPushed` (`test/support/library_harness.dart:156`).
- Produces: no new API. `PopScope(canPop: !running)` wraps the shell on Welcome (Google link running), screen 30 (send or Google running) and screen 31 (verify or resend running). The app bar back on 30 and 31 reads `Navigator.maybePop`, so it is held too. The layer's own code page is not changed (spec scope).

- [ ] **Step 1: Write the failing tests**

In `fake_auth_server.dart`, change `pickGoogle` and the `holdRequests` doc:

```dart
  /// While set, code requests and Google picks wait on it, as a slow network
  /// does.
  Completer<void>? holdRequests;
```

```dart
  @override
  Future<GoogleCredential> pickGoogle() async {
    kill?.step();
    await _waitIfHeld();
    if (googleCancels) throw const GoogleCancelledFailure();
    return google;
  }
```

Create `test/features/account/presentation/account_back_hold_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

// SP2b 2.46: while a sign-in command runs, Back waits, so its result has a
// screen to land on.
void main() {
  accountTest('Welcome: Back waits while Google signs in, then leaves the app '
      'again', (tester, env, world) async {
    final closes = watchAppCloses(tester);
    await pumpLibraryScreen(
      tester,
      env,
      WelcomeScreen(onDone: () {}, onEmail: () {}),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountContinueGoogle));
    await tester.pump();

    await tester.binding.handlePopRoute();
    expect(closes, isEmpty);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.binding.handlePopRoute();
    expect(closes, hasLength(1));
  });

  accountTest('screen 30: Back and the app bar arrow wait while a code is '
      'sent', (tester, env, world) async {
    await pumpLibraryScreenPushed(
      tester,
      env,
      SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsNothing);
  });

  accountTest('screen 31: Back waits while the code is checked', (
    tester,
    env,
    world,
  ) async {
    var signIns = 0;
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreenPushed(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++),
      overrides: accountOverrides(world),
    );
    final held = world.gateway.holdVerifies = Completer<void>();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    held.complete();
    world.gateway.holdVerifies = null;
    await _settle(tester);
    expect(signIns, 1);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(CodeScreen), findsNothing);
  });

  accountTest('screen 31: Back waits while a new code is requested', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreenPushed(
      tester,
      env,
      CodeScreen(email: 'a@example.com', onSignedIn: () {}),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountResend));
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.back));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.byType(CodeScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/account/presentation/account_back_hold_test.dart`
Expected: FAIL: in each test the screen is gone (or `SystemNavigator.pop` was called) while the command is still held.

- [ ] **Step 3: Implement**

`welcome_screen.dart`: wrap the returned shell:

```dart
    return PopScope(
      // Back leaves the app, except while Google is signing in: its result
      // needs this screen to land on (2.46).
      canPop: !isRunning,
      child: MxAppShell(
        // … the existing body and footer, unchanged …
      ),
    );
```

and extend the class doc: "There is no back: Back leaves the app, as on any root, except while Google signs in (SP2b 2.46)."

`sign_in_screen.dart`: add `import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';` after the `account_manage_controller.dart` import. In `build`, after `isLeaving`:

```dart
    // A send or the Google pick holds Back: the spinner says what runs (2.46).
    final isRunning = ref.watch(
      signInControllerProvider(purpose).select((state) => state.isRunning),
    );
    return PopScope(
      canPop: !isRunning,
      child: MxAppShell(
        // … the existing appBar and body, unchanged …
      ),
    );
```

`code_screen.dart`: add `import 'package:memox/features/account/presentation/controllers/code_controller.dart';` before the `core/theme` imports' neighbours (sorted: after `memox/core/theme/foundations/app_icons.dart`). In `build`, wrap the shell the same way with:

```dart
    // A check or a resend holds Back (2.46).
    final isBusy = ref.watch(
      codeControllerProvider(email, purpose).select((state) => state.isBusy),
    );
    return PopScope(
      canPop: !isBusy,
      child: MxAppShell(
        // … unchanged …
      ),
    );
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/account_back_hold_test.dart test/features/account/presentation/welcome_screen_test.dart test/features/account/presentation/sign_in_screen_test.dart test/features/account/presentation/code_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 6 `.dart` files; `flutter analyze lib test`; guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/features/account/presentation/screens/welcome_screen.dart lib/features/account/presentation/screens/sign_in_screen.dart lib/features/account/presentation/screens/code_screen.dart test/support/fake_auth_server.dart test/features/account/presentation/account_back_hold_test.dart
git commit -m "fix(account): Back waits while a sign-in command runs (SP2b 2.46)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 32 (C7): A deletion refused for want of a session says it is unconfirmed (2.47)

**Files:**
- Modify: `lib/l10n/app_en.arb` (after `accountDeleteRefused` at `:7208-7211`)
- Modify: `lib/l10n/app_vi.arb` (after `accountDeleteRefused` at `:1392`)
- Modify: `lib/features/account/presentation/widgets/support/account_labels_widget.dart` (imports `:1-11`; new function after `signInProblemText` at `:15-24`)
- Modify: `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart` (imports `:1-12`; `_say` at `:79-94`)
- Create: `test/features/account/presentation/account_notice_text_test.dart`

**Interfaces:**
- Consumes: `AccountNotice`, `MergeNotDone`, `DeleteRefused(Failure failure)` (`lib/core/auth/auth_state.dart:80-99`); the coordinator's `_notice(DeleteRefused(error))` for `SessionInvalidFailure` (`account_coordinator_leave.dart:155-161`, unchanged).
- Produces: `String accountNoticeText(AppLocalizations l10n, AccountNotice notice)` (feature-local; the toast's text, extracted so it can be tested without driving the coordinator into a lost session); ARB key `accountDeleteUnknown`.

| Key | EN | VI |
|---|---|---|
| `accountDeleteUnknown` | Couldn't confirm the deletion. Sign in again to check. | Chưa xác nhận được việc xoá. Đăng nhập lại để kiểm tra. |

All other refusals keep `accountDeleteRefused` ("Nothing changed"). `DeleteRefused(LastAdminFailure())` is still a dialog, decided before this text is asked for.

- [ ] **Step 1: Write the failing test**

Create `test/features/account/presentation/account_notice_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// SP2b 2.47: the server may have taken a deletion whose session was dead, so
// "Nothing changed" would be a false state.
void main() {
  test('a deletion refused without a session says it is unconfirmed', () {
    expect(
      accountNoticeText(_en, const DeleteRefused(SessionInvalidFailure())),
      _en.accountDeleteUnknown,
    );
  });

  test('every other refusal keeps "Nothing changed"', () {
    for (final failure in const <Failure>[
      OfflineFailure(cause: 'x'),
      ServerFailure(cause: 'x'),
      LastAdminFailure(),
    ]) {
      expect(
        accountNoticeText(_en, DeleteRefused(failure)),
        _en.accountDeleteRefused,
        reason: failure.runtimeType.toString(),
      );
    }
  });

  test('a refused merge keeps its own line', () {
    expect(accountNoticeText(_en, const MergeNotDone()), _en.accountMergeNotDone);
  });
}
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/account/presentation/account_notice_text_test.dart`
Expected: compile FAILURE (`accountNoticeText` and `accountDeleteUnknown` are undefined).

- [ ] **Step 3: Implement**

`app_en.arb`, after the `accountDeleteRefused` block:

```json
  "accountDeleteUnknown": "Couldn't confirm the deletion. Sign in again to check.",
  "@accountDeleteUnknown": {
    "description": "Toast: a deletion refused for want of a session; the server may have taken it, so it must not say nothing changed (SP2b 2.47)."
  },
```

`app_vi.arb`, after the `accountDeleteRefused` line:

```json
  "accountDeleteUnknown": "Chưa xác nhận được việc xoá. Đăng nhập lại để kiểm tra.",
```

Run `flutter gen-l10n`.

`account_labels_widget.dart`: add `import 'package:memox/core/error/failure.dart';` (sorted, after `auth_state.dart`'s neighbours) and, after `signInProblemText`:

```dart
/// The toast for a one-off [notice] (plan ruling 8). A deletion refused for
/// want of a session cannot say "nothing changed": the server may have taken
/// it (SP2b 2.47).
String accountNoticeText(AppLocalizations l10n, AccountNotice notice) =>
    switch (notice) {
      MergeNotDone() => l10n.accountMergeNotDone,
      DeleteRefused(failure: SessionInvalidFailure()) =>
        l10n.accountDeleteUnknown,
      DeleteRefused() => l10n.accountDeleteRefused,
    };
```

`account_layer_host_widget.dart`: add `import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';` (sorted, after `account_transition_layer_widget.dart`) and replace the tail of `_say` (`:86-93`):

```dart
    showMxSnackbar(
      context,
      message: accountNoticeText(context.l10n, notice),
    );
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/account_notice_text_test.dart test/features/account/presentation/account_transition_layer_test.dart test/core/auth/account_coordinator_signout_test.dart test/l10n`
Expected: PASS.

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 4 `.dart` files; `flutter analyze lib test`; guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/features/account/presentation/widgets/support/account_labels_widget.dart lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart test/features/account/presentation/account_notice_text_test.dart
git commit -m "fix(account): a deletion refused without a session says it is unconfirmed (SP2b 2.47)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 33 (C8): A role call that never answers ends as offline (2.48a)

**Files:**
- Modify: `lib/features/account/data/datasources/user_role_remote_data_source.dart` (`_notFound` at `:13`; `_call` at `:33-36`)
- Create: `test/features/account/data/user_role_remote_data_source_test.dart`

**Interfaces:**
- Consumes: `RpcCall` (`lib/core/sync/supabase_sync_api.dart:5`); `mapUserRoleError` → `classifyAuthError` → `classifyRemoteError`, which already maps `TimeoutException` to `RemoteErrorKind.network` and so to `OfflineFailure` (`remote_error.dart:14-19`, `supabase_auth_errors.dart:15-17`).
- Produces: `static const Duration UserRoleRemoteDataSource.roleCallTimeout = Duration(seconds: 20)` (the Dio receive timeout, `lib/core/network/di/network_providers.dart:10`). `role_set` is idempotent, so the retry the sheet offers after the timeout is safe.

- [ ] **Step 1: Write the failing test**

Create `test/features/account/data/user_role_remote_data_source_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';

// SP2b 2.48: an RPC that never answers must not leave screen 33 spinning.
void main() {
  UserRoleRemoteDataSource silent() => UserRoleRemoteDataSource(
    rpc: (_, _) => Completer<Object?>().future,
    hasSession: () => true,
  );

  test('a role call that never answers times out at the call limit', () {
    fakeAsync((async) {
      Object? error;
      unawaited(
        silent().list('', null).then<void>(
          (_) {},
          onError: (Object caught) {
            error = caught;
          },
        ),
      );

      async.elapse(
        UserRoleRemoteDataSource.roleCallTimeout - const Duration(seconds: 1),
      );
      expect(error, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(error, isA<TimeoutException>());
    });
  });

  test('role_set times out too, and the repository reads it as offline', () {
    fakeAsync((async) {
      Object? error;
      unawaited(
        UserRoleRepositoryImpl(silent())
            .set('u1', AccountRole.user)
            .then<void>(
              (_) {},
              onError: (Object caught) {
                error = caught;
              },
            ),
      );

      async.elapse(UserRoleRemoteDataSource.roleCallTimeout);
      expect(error, isA<OfflineFailure>());
    });
  });
}
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/account/data/user_role_remote_data_source_test.dart`
Expected: compile FAILURE (`roleCallTimeout` is undefined).

- [ ] **Step 3: Implement**

In `user_role_remote_data_source.dart`, after `_notFound`:

```dart
  /// As long as the Dio receive timeout: a call that outlives it is offline,
  /// and `role_set` is idempotent, so the retry is safe (SP2b 2.48).
  static const Duration roleCallTimeout = Duration(seconds: 20);
```

Replace `_call`:

```dart
  Future<Object?> _call(String function, Map<String, Object?> params) async {
    if (!_hasSession()) throw const UserRoleSessionMissing();
    return _rpc(function, params).timeout(roleCallTimeout);
  }
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/data/user_role_remote_data_source_test.dart test/features/account/data/user_role_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 2 files; `flutter analyze lib test`; guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/features/account/data/datasources/user_role_remote_data_source.dart test/features/account/data/user_role_remote_data_source_test.dart
git commit -m "fix(account): a role call that never answers times out as offline (SP2b 2.48)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 34 (C9): Users: a first page shorter than the screen asks for the next (2.48b, screen 33)

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/users_list_widget.dart` (`_Rows.build` listener at `:125-133`; doc at `:105-107`)
- Test: `test/features/account/presentation/users_screen_test.dart` (append after `'the accounts, their join date and role, and the end'` at `:72-84`)

**Interfaces:**
- Consumes: `FakeUserRoleRepository.pageSize` and `.lists` (`test/support/users_fakes.dart:23-27`); Flutter's `ScrollMetricsNotification` (dispatched by `ScrollPosition.didUpdateScrollMetrics`, in a microtask after layout, never inside it).
- Produces: no new API. The listener handles `ScrollNotification` and `ScrollMetricsNotification`, so a page that does not fill the viewport (no scroll ever happens) still asks for the next one.

- [ ] **Step 1: Write the failing test**

Append inside `main()` of `users_screen_test.dart`:

```dart
  libraryTest('a first page shorter than the screen asks for the next ones '
      'after layout, without a scroll (2.48)', (tester, env) async {
    roles.pageSize = 1;

    await pump(tester, env);
    for (var page = 0; page < 3; page++) {
      await _settle(tester);
    }

    expect(find.text('bob@example.com'), findsOneWidget);
    expect(find.text('me@example.com'), findsOneWidget);
    expect(find.text(_en.usersNoMore), findsOneWidget);
    expect(roles.lists.map((ask) => ask.$2).toList(), [
      null,
      'ann@example.com',
      'bob@example.com',
    ]);
  });
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/account/presentation/users_screen_test.dart`
Expected: the new test FAILS: only `ann@example.com` shows, `lists` has one ask, and "No more users" is absent.

- [ ] **Step 3: Implement**

Replace `:125-133` in `users_list_widget.dart`:

```dart
    // A scroll asks for the next page near the end. A change of the metrics
    // does too (it comes out of layout, in a microtask), so a first page
    // shorter than the screen is not stranded: nothing would ever scroll
    // (SP2b 2.48).
    return NotificationListener<Notification>(
      onNotification: (notification) {
        final metrics = switch (notification) {
          ScrollNotification(:final metrics) => metrics,
          ScrollMetricsNotification(:final metrics) => metrics,
          _ => null,
        };
        if (metrics != null &&
            loaded.more == UsersMore.idle &&
            loaded.next != null &&
            metrics.extentAfter < _prefetchExtent) {
          unawaited(controller.loadMore());
        }
        return false;
      },
```

(the `child:` argument that follows is unchanged).

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/users_screen_test.dart test/features/account/presentation/users_controller_test.dart`
Expected: PASS. RISK (see Cluster notes): if the new test still fails because the metrics notification does not reach the listener in the test, the fallback is a `LayoutBuilder`-free post-frame check; report it to the controller instead of improvising.

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 2 files; `flutter analyze lib test`; guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/features/account/presentation/widgets/sections/users_list_widget.dart test/features/account/presentation/users_screen_test.dart
git commit -m "fix(account): Users asks for the next page when the first one does not fill the screen (SP2b 2.48)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 35 (C10): Monitoring: the same listener on screen 28's rows (2.48b)

**Files:**
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart` (`_Rows.build` listener at `:167-175`; doc at `:139-142`)
- Test: `test/features/monitoring/presentation/monitoring_screen_test.dart` (append after `'the next page loads near the end, and the end says so'` at `:233-257`)

**Interfaces:**
- Consumes: `LogPage.size` (100) and `LogPage.next` (non-null only for a full page, `log_page_model.dart:7-20`); `FakeMonitoringRepository.lastQuery` / `.queries`; `pageOf(count)` and `settleMonitoring` (`test/support/monitoring_*.dart`).
- Produces: no new API; the same two-notification listener as C9.

Note: this half of 2.48 cannot happen on a phone, because a page that has a next page holds 100 rows (about 4,800 px). It is applied because spec §3.7 says so, costs five lines, and is pinned with a tall viewport. DECISION 2 below lets the controller drop this task. **Merge risk:** the Monitoring cluster (2.38) edits the same file at `:75-140` (the failure and loaded switch); this task edits `:139-175` only.

- [ ] **Step 1: Write the failing test**

Append inside `main()` of `monitoring_screen_test.dart`:

```dart
  libraryTest('a full first page on a screen taller than its rows asks for '
      'the next one after layout (2.48)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    // 100 rows of 48 are shorter than this viewport: nothing can scroll.
    tester.view.physicalSize = const Size(360, 20000);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);
    await tester.pump();

    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after!.id, 'r99');
  });
```

(`pumpLibraryScreen` registered `tester.view.reset` as a teardown, so the size is restored.)

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/features/monitoring/presentation/monitoring_screen_test.dart`
Expected: the new test FAILS: `repository.queries` has length 1.

- [ ] **Step 3: Implement**

Replace `:167-175`:

```dart
    // A scroll asks for the next page near the end; so does a change of the
    // metrics after layout, so a page shorter than the screen is not
    // stranded (SP2b 2.48).
    return NotificationListener<Notification>(
      onNotification: (notification) {
        final metrics = switch (notification) {
          ScrollNotification(:final metrics) => metrics,
          ScrollMetricsNotification(:final metrics) => metrics,
          _ => null,
        };
        if (metrics != null &&
            loaded.more == MonitoringMore.idle &&
            hasMore &&
            metrics.extentAfter < _prefetchExtent) {
          unawaited(controller.loadMore());
        }
        return false;
      },
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/monitoring/presentation/monitoring_screen_test.dart test/features/monitoring/presentation/monitoring_list_controller_test.dart`
Expected: PASS (the existing fling tests still pass: scroll notifications are handled as before).

- [ ] **Step 5: Format, analyze, guard**

`dart format` on the 2 files; `flutter analyze lib test`; guard exit 0.

- [ ] **Step 6: Commit**

```bash
git add lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart test/features/monitoring/presentation/monitoring_screen_test.dart
git commit -m "fix(monitoring): the server list asks for the next page after layout too (SP2b 2.48)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

### Task 36 (C11): Detail files, index and spec lines for screens 29–33

**Files:**
- Modify: `docs/shared/ui/screen-handoff/29-welcome.md` (Entry points, `:15`)
- Modify: `docs/shared/ui/screen-handoff/30-sign-in.md` (Layout rows, Transition layer, Rulings, Copy)
- Modify: `docs/shared/ui/screen-handoff/31-code.md` (Layout, States, Rulings, Copy)
- Modify: `docs/shared/ui/screen-handoff/32-account.md` (after the command-refused sentence)
- Modify: `docs/shared/ui/screen-handoff/33-users.md` (End row; role sheet paragraph)
- Modify: `docs/shared/ui/screen-handoff/00-index.md` (row 31, `:50`)
- Modify: `docs/superpowers/specs/2026-09-30-account-ui-design.md` (`Recovering.isStuck` row at `:151`; notices paragraph after it)

**Interfaces:** documents only. A PR that changes a screen updates its detail file and its row in the screen index (CLAUDE.md). The docs gate is `python tools/docs/check.py`; it rejects a broken relative link, so the new golden row for `code_offline_kept` is added only after its PNGs exist (Step 4).

- [ ] **Step 1: Screen 29 (Welcome)**

In `29-welcome.md`, replace
`- No back arrow: Android Back leaves the app, as on any root.`
with
`- No back arrow: Android Back leaves the app, as on any root, except while Google is signing in: Back waits until its result has landed (SP2b 2.46).`

- [ ] **Step 2: Screen 30 (Sign-in, merge sheet, layer)**

In `30-sign-in.md`:

1. Replace the Email row's text `Checked on send; its problem shows under the field (`MxFieldMessage`). Text keyboard (UI-base row 150).` with
   `Checked on send; its problem shows under the field (`MxFieldMessage`). An address the server calls invalid shows the same line, not "try again" (SP2b 2.42). The same address (case and spaces ignored) sent again inside the 60 s resend wait reopens the code step without sending (SP2b 2.41). Text keyboard (UI-base row 150).`
2. Replace the Send code row's text `"Send code", the form's one fill; spins while sending and never greys out for a bad address.` with
   `"Send code", the form's one fill; spins while sending and never greys out for a bad address. While it, or Google, runs, Back (the arrow and the system) waits; the spinner shows what runs (SP2b 2.46).`
3. After the merge sheet table's closing sentence `A phone with no live deck skips the sheet and moves at once (R6).` append
   `Cancel on the sheet, or a switch that fails to start, forgets the Google account picked for it, so the next press shows the picker again; a started switch keeps it for the target sign-in (SP2b 2.40).`
4. In the Transition layer table replace the Stuck row with
   `| Stuck | "Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens." + "Close MemoX" (outline, closes the app, changes no data) beside Retry, in an `MxActionPair` with Close leading (SP2b R11). |`
5. In Rulings add the bullet:
   `- **SP2b (spec `2026-10-03-ui-hardening-sp2b-design.md` §3.7):** R11 the stuck layer's copy and "Close MemoX"; 2.40 a declined sheet forgets the Google pick; 2.41 a code just sent is not sent again; 2.42 an invalid address is the field's problem; 2.46 Back waits while a send or the Google pick runs.`
6. In Copy add the line:
   `- Stuck layer: "Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens." · "Close MemoX".`

- [ ] **Step 3: Screens 31, 32, 33 and the index**

`31-code.md`:
- In the Code row replace `A wrong code clears the field (plan ruling 11).` with `A wrong code clears the field (plan ruling 11) and keeps the keyboard; a code that could not be checked (offline, failed, rate limited) keeps its six digits, shows its problem in a warning `MxInlineBanner` with a compact "Retry" that checks them again, and leaves the field enabled (SP2b 2.45). The field takes the keyboard when the step opens.`
- Replace the Resend row's `until the 60 s wait ends` with `until the 60 s wait ends (counted from the last code sent, so leaving and coming back keeps what is left; a rate-limited resend starts the minute again: SP2b 2.41, 2.44)`.
- After the Layout paragraph about a right code add: `While a check or a resend runs, Back (the arrow and the system) waits (SP2b 2.46).`
- In the States table replace the `verifying` row's App cell `The field disabled, `MxSpinner` under it.` with `The field stays enabled, `MxSpinner` under it (2.45).`
- In Rulings add `- **SP2b 2.41, 2.44, 2.45, 2.46:** the wait persists; a rate-limited resend waits a minute; the digits stay when the check could not run; Back waits.`
- In Copy add `- Kept digits: the problem line (offline, failed, rate limited) as on screen 30, and "Retry".`

`32-account.md`: after the sentence ending `"Couldn't finish that. Nothing changed; try again."` add a paragraph:
`A deletion refused because the session was already gone toasts "Couldn't confirm the deletion. Sign in again to check.": the server may have taken it, so it never says nothing changed (SP2b 2.47). Every other refusal keeps "Couldn't delete the account. Nothing changed."`
and add `"Couldn't confirm the deletion. Sign in again to check."` to Copy.

`33-users.md`:
- In the End row append `A first page shorter than the screen asks for the next one after layout, with no scroll needed (SP2b 2.48).`
- After the paragraph that begins `**Role sheet**` append `A role call that never answers ends as offline after 20 s, so Save can be retried (`role_set` is idempotent; SP2b 2.48).`

`00-index.md`: change row 31 `| 31 | Code | 2 | FE-B9 |` to `| 31 | Code | 3 | FE-B9 |` (the count rises with the new golden, Step 4).

- [ ] **Step 4: The account-UI spec, then the golden row once the PNGs exist**

`docs/superpowers/specs/2026-09-30-account-ui-design.md`:
- Replace the `Recovering.isStuck` row of the layer table (`:151`) with
  `| `Recovering.isStuck` | "Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens." + "Close MemoX" (outline; `SystemNavigator.pop()`, no data changes) leading and Retry trailing in an `MxActionPair` (SP2b R11) |`
- In the notices paragraph, after `any other `DeleteRefused` → snackbar "Couldn't delete the account. Nothing changed."` add `; `DeleteRefused(SessionInvalid)` → "Couldn't confirm the deletion. Sign in again to check." (the server may have taken it; SP2b 2.47)`.

After the controller has generated the Linux goldens (the plan's golden task), add this row to the States table of `31-code.md`, after `wrong`:

```
| offline, digits kept | ![](../../../../test/features/account/presentation/goldens/code_offline_kept_light.png) | ![](../../../../test/features/account/presentation/goldens/code_offline_kept_dark.png) | Six digits kept, the warning banner with Retry (2.45). Golden `code_offline_kept_*`. |
```

Run `python tools/docs/check.py` (must pass) before committing; before the PNGs exist, commit Steps 1–3 and the spec lines only, and add this row in the golden commit.

- [ ] **Step 5: Commit**

```bash
git add docs/shared/ui/screen-handoff/29-welcome.md docs/shared/ui/screen-handoff/30-sign-in.md docs/shared/ui/screen-handoff/31-code.md docs/shared/ui/screen-handoff/32-account.md docs/shared/ui/screen-handoff/33-users.md docs/shared/ui/screen-handoff/00-index.md docs/superpowers/specs/2026-09-30-account-ui-design.md
git commit -m "docs(ui): detail files and the account UI spec for the SP2b account fixes (screens 29-33)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Goldens: none.

---

## Cluster notes

**Order and dependencies.** C1, C2, C3 are independent. C4 creates `watchAppCloses` in `test/support/account_harness.dart`, which C6 reuses (run C4 before C6). C5 adds `FakeAuthGateway.holdVerifies`, which C6 reuses (run C5 before C6). C6 edits the same `fake_auth_server.dart` as C5 but a different method. C2, C3 and C5 all append to `sign_in_controller_test.dart` / `code_screen_test.dart` in different places; if executed in parallel worktrees, expect trivial merge conflicts there. C11 follows all of them.

**Cross-cluster contact points.**
- `lib/core/error/failure.dart`: C3 only adds `InvalidEmailFailure`; another cluster may add its own class nearby.
- `lib/l10n/app_en.arb` / `app_vi.arb`: C4 edits `accountLayerStuck` (`:7187` / `:1388`) and C7 adds a key after `accountDeleteRefused`. Other clusters add keys in their own regions; resolve the textual conflicts by keeping both.
- `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart`: C10 edits `_Rows` (`:139-175`); the Monitoring cluster (2.38) edits `:75-140`. `test/features/monitoring/presentation/monitoring_screen_test.dart` is also shared.
- `docs/shared/ui/screen-handoff/00-index.md`: C11 touches only row 31.
- No `.drift` query is added or changed: nothing needs an owner in `verification_impact_map.json`.

**Goldens.** Move: `layer_stuck_*` (C4). New: `code_offline_kept_*` (C5). May move because the code field now has focus on open: `code_waiting_*`, `code_wrong_*` (C5). Everything else in `test/features/account/presentation/goldens/` must stay byte-identical; anything else moving is a defect.

**Risks.**
- C9/C10 depend on `ScrollMetricsNotification` reaching a `NotificationListener<Notification>` above the scrollable. The Flutter 3.47.5 source (`scroll_position.dart:670-677, 1082-1092`) dispatches it from a microtask after layout, so calling `loadMore` there is safe, but the test was not run. If it does not fire in the widget test, report to the controller; do not change the approach silently.
- C5's tests rely on `world.network.goOffline()` making `verifyEmailLink` throw `OfflineFailure` (it does: `FakeAuthGateway.verifyEmailLink` calls `server.checkOnline()`), and on the coordinator's reconnect listener (fired by `goOnline`) not changing the state class away from `Ready` anonymous.
- C6's Welcome test relies on `WidgetsBinding.handlePopRoute` reaching `SystemNavigator.pop` when the root route may pop, and not when `PopScope.canPop` is false (standard `Navigator.maybePop` semantics).
- C2 changes what the code step shows for an address sent a moment ago; the screen tests that call the coordinator directly are unaffected because nothing is recorded.
- Goldens cannot be run on Windows: C4 and C5 only compile them.

**DECISION list (for the controller to rule; recommended values given).**
1. **2.45 Retry placement and tone.** Recommended: a warning `MxInlineBanner` with a compact Retry under the field, for offline, failed and rate-limited alike (the field itself is not put in its error state). Alternative: the problem as the field's error text and a text Retry below it, or a neutral banner for offline.
2. **2.48 monitoring half (C10).** Unreachable on a phone (a page that has a next page is 100 rows). Recommended: keep it, as the spec says (five lines, pinned with a tall viewport). Alternative: drop C10 and say so in the PR.
3. **2.41 holds only the last send** (a single record, not a map per address). Recommended: single record. A map would also remember the previous address after a one-letter edit; that is not asked for.
4. **2.46 scope.** The layer's own code page (`_LayerCodePage`) is not held, as the spec lists only Welcome, 30 and 31. Recommended: leave as specified.
5. **2.47 extraction.** The toast text moves into a feature-local `accountNoticeText` so it is testable without driving the coordinator into a lost session. Recommended: keep (one function, no new layer).
6. **2.40 extra path.** `startLinkSwitch` also forgets the pick when the context is gone after the sheet (`!context.mounted`), beside the three paths the spec names. Recommended: keep (same intent, one condition).
7. **C11 ownership.** Spec §8 lists detail-file updates for all clusters' screens in one bullet. C11 covers screens 29–33 and the account UI spec only; the controller may fold it into a single docs task for the whole PR.
8. **Commit trailer.** Written as `Claude Opus 5.5` per this session's attribution rule; the SP1 plan used `Claude Opus 5.5`. The controller should unify across clusters.


---

### Task 37: Screen records, WBS, gates, goldens, golden review, the one audit

**Files:**
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`, `02-review-algorithm.md`, `03-starter-decks.md`, `06-trash.md`, `07-card-list.md` (move/tag sheets), `23-settings.md`, `24-daily-reminder.md`, `27-sync.md`, `28-monitoring.md` (screens 29–33 are Task 36), and their rows in `00-index.md` when a state count changes.
- Modify: `DESIGN.md` — the "a failure inside a dialog" pattern (a held dialog keeps its failure in an `MxInlineBanner`; a toast never sits under a scrim) and `MxDeckPickerSheet.isHeld`/`banner`.
- Modify: `docs/wbs_FE.md` — new row FE-D29 after FE-D28.
- Goldens: every new or moved PNG named by Tasks 1–36.

- [ ] **Step 1: Detail files.** For each screen, add the States rows, rulings and new copy lines each task introduced, citing the SP2b item numbers.
- [ ] **Step 2: WBS row:** `| FE-D29 | UI hardening SP2b: dialog giữ khi đang ghi và báo lỗi trong dialog, Trash tự dọn theo giờ server (R10), nhắc học/sync/monitoring không báo sai, tài khoản không kẹt ("Close MemoX", R11) | đang làm | FE-D28 | L | [spec](superpowers/specs/2026-10-03-ui-hardening-sp2b-design.md), [plan](superpowers/plans/2026-10-03-ui-hardening-sp2b.md) | SP3 |`
- [ ] **Step 3: Docs check.** `python tools/docs/generate.py`, then `python tools/docs/check.py` → `PASS — 0 error(s)`. Commit `docs: SP2b screen records and FE-D29`.
- [ ] **Step 4: Supabase gate.** `npx supabase db start` then `npx supabase test db` — green, including the new pgTAP file.
- [ ] **Step 5: The gate.** `MEMOX_TEST_BUNDLES=2 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → `✓ mechanical gates passed`.
- [ ] **Step 6: Goldens in the Linux container** (memory note `goldens-on-linux`; check free commit memory first; `docker cp`, no bind mounts, `-j 1`; the tarball keeps `lib/**/failures/`). Update, then compare green; commit `test(goldens): regenerate for SP2b`.
- [ ] **Step 7: Golden review** page against the SP2a head (`golden-compare`), handed to the owner before any merge.
- [ ] **Step 8: One `impeccable audit`** of SP2b's changed surface; fix what it finds in one batch; no further audit.
- [ ] **Step 9: Close out.** FE-D29 → `xong` with the evidence; docs check; commit.
