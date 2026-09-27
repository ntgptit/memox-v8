# MemoX V8 Trash Screen Implementation Plan (FE-B1, plan 2 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish FE-B1 in [`docs/wbs_FE.md`](../../wbs_FE.md). This plan builds kit screen 06,
the Trash, over the BE-B1 use cases:
- what was deleted, filtered by kind;
- a restore to a place the person picks;
- a selection locked to one kind;
- delete for good.

It also adds every way into the Trash, and the auto-purge at start, on resume and on
opening. Plan 1 made the deletes say "Trash".

**Architecture:**
- **The screen.** `lib/features/trash/presentation/` gains one `@riverpod` controller
  (the filter, the kind-locked selection, restore and purge, through the seven BE-B1
  use cases), a stream provider for the entries, and one screen made of `Mx*` widgets:
  a row, an actions sheet, a restore sheet, a purge dialog and a selection bar.
- **The ways in.** `deck` and `card` learn about the Trash only through an
  `onOpenTrash` callback, which `app/` wires to the new root-navigator route
  `/decks/trash`.
- **The auto-purge.** `app/` runs it at start and on every resume, and the screen runs
  it when it opens.
- **One shared change.** `MxButton` gains `isAutofocused`.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, gen-l10n (en, vi). No new package.

**Spec:** [`docs/superpowers/specs/2026-09-26-trash-ui-design.md`](../specs/2026-09-26-trash-ui-design.md)
§3 (D1, D2, D4–D11, D15), §4, §6–§9. Use case: UC-TRASH-001 (steps 3–7, A2–A6,
E1–E6). The kit is the visual authority: "MemoX — Mobile UI Kit v3", screen 06
(15 states), with the pre-plan critique in
`.impeccable/critique/2026-09-26T10-32-30Z__trash-kit.md`.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` with plan 1 done
([delete flows](2026-09-26-trash-delete-flows.md)). Generated code is not committed.
In a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- Every task was built and committed in a scratch worktree of this branch, and each
  task's blocks below are that commit's files and diffs.
- The full gate (`dod_check.sh --force`) passed there with a clean `flutter analyze`,
  a clean guard and clean architecture boundaries. The goldens ran separately in this
  Linux container and were compared with the kit captures.
- The blocks were replayed mechanically onto a clean checkout of plan 1's last commit,
  and the result matched the scratch files byte for byte.
- Rules were then broken on purpose, and each break failed a test:
  - the resume purge removed;
  - the purge on opening removed;
  - Keep in Trash not focused;
  - the kind lock removed from the controller;
  - the Library's Open Trash wired to nothing.

## Clarifications (rulings; amend the spec where they differ)

- **Q1 (D5).** `MemoxApp` runs `PurgeExpiredTrashUseCase` in `initState` and from an
  `AppLifecycleListener`'s `onResume`. `TrashScreen` runs it in `initState` through the
  controller.
  - A `Failure` is swallowed: the entries stay until the next try, and nothing is
    said.
  - Spec §10's "when it regains focus" needs no hook. Only the Trash's own sheets and
    dialogs cover it, and a return from another app is a resume.
- **Q2 (D8, selection).**
  - "Select" enters selection with nothing chosen, and the title reads "Select
    entries". A long-press picks its entry at once.
  - The first pick locks the kind, and the other kind's rows cannot be tapped (a null
    `onTap`). The controller refuses them too.
  - The filters hide while selecting. The list stays the current filter's, and the
    header counts the locked kind in it.
- **Q3 (restore).**
  - The restore sheet is an `MxDeckPickerSheet` whose targets read as paths, as in the
    move sheets (ruling P3-L8).
  - A top-level deck has the single target "Top level".
  - The kit draws only a card's sheet, so a deck's rule and its empty body are V8 copy.
    A card's empty body names its top-level deck (kit noTarget).
  - A refusal closes the sheet with a toast, as the move sheets do (spec §6 says "in
    the sheet"; the modal sheet would hide a toast). The list follows the store while
    the sheet is open.
- **Q4 (delete for good).**
  - The dialog runs the purge itself, so "Delete {n}" spins (D15). "Keep in Trash" is
    the primary and takes the focus through the new `MxButton.isAutofocused`
    (BR-TRASH-011).
  - The toast shows only when something was purged.
  - Blocked batches become warning `MxInlineBanner`s (`MxNote` is info only), one per
    batch still in the Trash with a named inner entry. They stay until the next
    command.
- **Q5 (spec §4, the ways in).**
  - `onOpenTrash` is threaded as a callback, as the import and export entries are. It
    is required on `DeckLevelScreen`, optional (hidden when null) everywhere below it
    and on the card screens.
  - `app/`'s `_openTrash` captures the `GoRouter`, not the page's context, because a
    toast's action can outlive its page.
  - The Library's app bar reads Trash · Coming soon, and Coming soon drops its Trash
    line.
- **Q6.** `trash` may not import `card` or `deck` presentation. Its restore refusals
  therefore map through its own `TrashRejectionMessage` to the same messages, and a
  test pins that they read the same in en and vi.
- **Q7 (time).**
  - Time left is whole days rounded up. Under a day it is hours rounded up, never less
    than 1h. It uses the warning ink under 3 days.
  - "deleted {ago}" reads just now / minutes / hours / yesterday / days.
  - The clock is `dayClockProvider`, read at each build.
- **Q8.** The restore target providers are families keyed by `TrashBatchIds`, a set
  with value equality.
- **Q9.** `test/visual_audit/screens/screen_audit_coverage_test.dart` requires a visual
  audit beside every production screen. Task 2 adds the list's and Task 4 the
  selection's, at 1x and 2x.
- **Q10.** The error state keeps the app's local-first body, "Nothing was lost. Try
  again in a moment.", which every Library screen uses. The kit reads "Your data is
  safe on this device…".

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screen 06 is the visual authority. Every difference is in Q1–Q10, in
  `docs/shared/ui/screen-handoff/06-trash.md`, or in UI-base §9 rows 108–112.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens;
  - no raw colour, `TextStyle`, spacing, radius or anonymous `Duration` literal;
  - no `ref.read` inside `build`;
  - no literal user string, TalkBack labels included;
  - booleans read as predicates;
  - no source file over 400 lines.
- File suffixes and buckets follow the guard: `_provider`, `_controller`, `_state`,
  `_screen`, and `_widget` in `items/`, `sections/`, `overlays/` or `support/`.
- Every read and write goes through a use case (ADR-011 D4). `trash` imports only
  `card` and `deck` domain, never their presentation (the architecture check). `deck`
  and `card` never import `trash`.
- No message carries an id or a path (BR-CORE-005). The names shown are the person's
  own text on their own device (BR-TRASH-012).
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- Goldens render in the Linux container only. On Windows, run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **An entry expires while the Trash is open and the app comes back from the
   background.** It leaves the list in place. Test: "a resume purges what expired
   meanwhile, and the open Trash drops it in place".
2. **A card and a deck picked in one selection.** The deck cannot join, and the note
   says why. Test: "Select starts with nothing chosen; the first pick locks the kind".
3. **Delete for good on a deck that still holds an older entry.** Nothing is lost, and
   the banner names what holds it. Test: "a purge the store skips names what it still
   holds".
4. **Open Trash from a toast whose page has gone.** The Trash still opens. Tests: "a
   refused Undo opens the Trash" and "the toast of several cards opens the Trash".
5. **A 360 dp phone at text scale 2.** Nothing overflows and every target is 48 dp.
   Tests: the screen 06 visual audit, list and selection.

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/features/trash/presentation/providers/*_use_case_provider.dart`, `…/trash_entries_provider.dart` | 1 | the seven use cases; the entries stream |
| `lib/features/trash/presentation/{states/trash_state,controllers/trash_controller}.dart` | 1 | filter, kind-locked selection, restore, purge |
| `lib/features/trash/presentation/screens/trash_screen.dart` | 2–4, 6 | screen 06 |
| `lib/features/trash/presentation/widgets/{items/trash_entry_row,overlays/trash_entry_actions_sheet,support/trash_labels}_widget.dart` | 2 | the row, its actions, the labels |
| `lib/features/trash/presentation/{providers/trash_restore_targets_provider,widgets/overlays/trash_restore_sheet_widget,widgets/support/trash_rejection_message_widget}.dart` | 3 | restore |
| `lib/features/trash/presentation/widgets/{overlays/trash_purge_dialog,sections/trash_selection_bar}_widget.dart`, `lib/shared/widgets/mx_button.dart` | 4 | selection and delete for good |
| `lib/app/router/*`, `lib/features/deck/presentation/**`, `lib/features/card/presentation/**` | 5 | the route and every Open Trash |
| `lib/app/app.dart` | 6 | the auto-purge at start and on resume |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/core/theme/foundations/app_icons.dart` | 2–5 | the copy; `AppIcons.restore` |
| `docs/**` | 7 | detail file 06, index, register, UC, README, WBS |

---


### Task 1: The Trash's providers, state and controller

**Files:**
- Create: `lib/features/trash/presentation/controllers/trash_controller.dart`
- Create: `lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/purge_trash_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/restore_decks_from_trash_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/trash_entries_provider.dart`
- Create: `lib/features/trash/presentation/providers/watch_card_restore_targets_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/watch_deck_restore_targets_use_case_provider.dart`
- Create: `lib/features/trash/presentation/providers/watch_trash_use_case_provider.dart`
- Create: `lib/features/trash/presentation/states/trash_state.dart`
- Test (create): `test/features/trash/presentation/trash_controller_test.dart`

**Interfaces:**
- Consumes: BE-B1's `WatchTrashUseCase`, `RestoreCardsFromTrashUseCase`,
  `RestoreDecksFromTrashUseCase`, `PurgeTrashUseCase` (its value is a `PurgeReport`),
  `PurgeExpiredTrashUseCase`, `WatchCardRestoreTargetsUseCase` and
  `WatchDeckRestoreTargetsUseCase`, each read from the DI container.
- Produces:
  - one `…UseCaseProvider` per use case, and `trashEntriesProvider`
    (`Stream<List<TrashEntry>>`);
  - `enum TrashFilter {all, cards, decks}` with `bool accepts(TrashEntry)`;
    `enum TrashKind {card, deck}` with `static TrashKind of(TrashEntry)`;
  - `TrashState({filter, isSelecting, selected, blocked})` with
    `TrashKind? kindIn(List<TrashEntry>)`; `blocked` is
    `Map<String, Set<String>>`;
  - `trashControllerProvider`: `chooseFilter(TrashFilter)`, `startSelecting()`,
    `stopSelecting()`, `toggle(TrashEntry entry, List<TrashEntry> entries)` (refuses
    the other kind), `restoreCards({required Set<String> batchIds, required String
    deckId}) → Future<Outcome<void, CardRejection>>`, `restoreDecks({required
    Set<String> batchIds, required String? parentId}) → Future<Outcome<void,
    DeckRejection>>` (both end the selection on `Ok`), `purge(Set<String> batchIds) →
    Future<PurgeReport>` (ends the selection, sets `blocked`), `purgeExpired()`.

- [ ] **Step 1: Write the failing tests**

The tests are plain `test()`s over a `LibraryEnv`: a Drift stream awaited inside
`testWidgets` never completes under its fake clock. An autoDispose provider read from a
bare container is kept alive with `container.listen`.

`test/features/trash/presentation/trash_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/watch_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

/// Korean › Words (cards w1, w2) and Korean › Verbs (card v1); w1 and w2
/// go to the Trash one by one, then Verbs.
Future<({String words, String verbs})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final verbs = await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'w1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'w2', deckId: words.id, front: 'gamsa');
  await insertCard(env.db, id: 'v1', deckId: verbs.id, front: 'gada');
  await env.cards.deleteCards(cardIds: {'w1'}, now: libraryToday);
  await env.cards.deleteCards(cardIds: {'w2'}, now: libraryToday);
  await env.decks.deleteDeck(deckId: verbs.id, now: libraryToday);
  return (words: words.id, verbs: verbs.id);
}

/// What the store holds now: a fresh read of the Trash's stream.
Future<List<TrashEntry>> _entries(ProviderContainer container) =>
    container.read(watchTrashUseCaseProvider)().first;

/// A container over [env] whose auto-disposed controller stays alive.
ProviderContainer _container(LibraryEnv env) {
  final container = libraryContainer(env);
  container.listen(trashControllerProvider, (_, _) {});
  return container;
}

TrashEntry _named(List<TrashEntry> entries, String name) => entries.firstWhere(
  (entry) => switch (entry) {
    TrashCardEntry(:final front) => front == name,
    TrashDeckEntry(name: final deckName) => deckName == name,
  },
);

/// A plain test over a fresh [LibraryEnv]: drift's streams need the real
/// event loop, which a widget test's fake clock does not run.
void _trashTest(
  String description,
  Future<void> Function(LibraryEnv env) body,
) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(env);
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _trashTest('a selection is locked to the kind picked first (BR-TRASH-011)', (
    env,
  ) async {
    await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    trash.toggle(_named(entries, 'annyeong'), entries);
    trash.toggle(_named(entries, 'Verbs'), entries);
    trash.toggle(_named(entries, 'gamsa'), entries);
    var state = container.read(trashControllerProvider);
    expect(state.isSelecting, isTrue);
    expect(state.selected, hasLength(2));
    expect(state.kindIn(entries), TrashKind.card);

    // Emptied, the lock goes: a deck may be picked now.
    trash.toggle(_named(entries, 'annyeong'), entries);
    trash.toggle(_named(entries, 'gamsa'), entries);
    trash.toggle(_named(entries, 'Verbs'), entries);
    state = container.read(trashControllerProvider);
    expect(state.kindIn(entries), TrashKind.deck);
    expect(state.selected, {_named(entries, 'Verbs').batchId});
  });

  _trashTest('the filter keeps its kind; Select starts with nothing chosen', (
    env,
  ) async {
    await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    trash.chooseFilter(TrashFilter.decks);
    trash.startSelecting();
    final state = container.read(trashControllerProvider);
    expect(state.filter, TrashFilter.decks);
    expect(state.isSelecting, isTrue);
    expect(state.selected, isEmpty);
    expect(entries.where(TrashFilter.decks.accepts), hasLength(1));
    expect(entries.where(TrashFilter.cards.accepts), hasLength(2));
  });

  _trashTest('a restore lands and ends the selection; a refusal keeps it', (
    env,
  ) async {
    final ids = await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    var entries = await _entries(container);
    final annyeong = _named(entries, 'annyeong');
    trash.toggle(annyeong, entries);

    // The Verbs deck is in the Trash: no card goes there.
    final refused = await trash.restoreCards(
      batchIds: {annyeong.batchId},
      deckId: ids.verbs,
    );
    expect(
      refused,
      isA<Rejected<void, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.targetInTrash,
      ),
    );
    expect(container.read(trashControllerProvider).selected, hasLength(1));

    final restored = await trash.restoreCards(
      batchIds: {annyeong.batchId},
      deckId: ids.words,
    );
    expect(restored, isA<Ok<void, CardRejection>>());
    expect(container.read(trashControllerProvider).isSelecting, isFalse);
    entries = await _entries(container);
    expect(entries, hasLength(2));
  });

  _trashTest('a deck of a root goes back to the top level', (env) async {
    final japanese = await env.decks.root('Japanese');
    await env.decks.deleteDeck(deckId: japanese.id);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    final outcome = await trash.restoreDecks(
      batchIds: {entries.single.batchId},
      parentId: null,
    );
    expect(outcome, isA<Ok<void, DeckRejection>>());
    expect(await _entries(container), isEmpty);
  });

  _trashTest('a purge ends the selection and keeps what the store skips '
      '(spec D6)', (env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'w1', deckId: words.id, front: 'annyeong');
    // The card goes first, then its deck: the deck holds an older entry.
    await env.cards.deleteCards(cardIds: {'w1'});
    await env.decks.deleteDeck(deckId: words.id);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);
    final deck = _named(entries, 'Words');
    trash.toggle(deck, entries);

    final report = await trash.purge({deck.batchId});
    final state = container.read(trashControllerProvider);
    expect(report.purged, isEmpty);
    expect(state.isSelecting, isFalse);
    expect(state.blocked.keys, [deck.batchId]);
    expect(state.blocked[deck.batchId], {_named(entries, 'annyeong').batchId});

    // The next command lets the note go.
    trash.chooseFilter(TrashFilter.cards);
    expect(container.read(trashControllerProvider).blocked, isEmpty);
  });

  _trashTest('purgeExpired takes only what is past 30 days (UC-TRASH-001 '
      'A4)', (env) async {
    await _seed(env);
    final kanji = await env.decks.root('Kanji');
    await env.decks.deleteDeck(
      deckId: kanji.id,
      now: libraryToday.add(const Duration(days: 1)),
    );
    // The seeded batches reach 720 hours: the boundary is expired.
    env.clock.current = libraryToday.add(trashRetention);
    final container = _container(env);

    await container.read(trashControllerProvider.notifier).purgeExpired();
    final entries = await _entries(container);
    expect(entries, hasLength(1));
    expect(_named(entries, 'Kanji'), isA<TrashDeckEntry>());
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/trash/presentation/trash_controller_test.dart
```

Expected: FAIL to compile: `trash_controller.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/trash/presentation/controllers/trash_controller.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/purge_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/restore_decks_from_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_controller.g.dart';

/// Screen 06 (UC-TRASH-001): the filter, the selection locked to one kind
/// (BR-TRASH-011), and the commands, each through its use case. A database
/// `Failure` is thrown through; the widget says so and the selection stays
/// (E5).
@riverpod
class TrashController extends _$TrashController {
  @override
  TrashState build() => const TrashState();

  void chooseFilter(TrashFilter filter) => state = TrashState(filter: filter);

  /// "Select": the rows become checkboxes, nothing chosen yet.
  void startSelecting() =>
      state = TrashState(filter: state.filter, isSelecting: true);

  void stopSelecting() => state = TrashState(filter: state.filter);

  /// A tap while selecting, or the long-press that starts it. An entry of
  /// the other kind is refused (BR-TRASH-011).
  void toggle(TrashEntry entry, List<TrashEntry> entries) {
    final kind = state.kindIn(entries);
    if (kind != null && kind != TrashKind.of(entry)) return;
    final selected = {...state.selected};
    if (!selected.remove(entry.batchId)) selected.add(entry.batchId);
    state = TrashState(
      filter: state.filter,
      isSelecting: true,
      selected: selected,
    );
  }

  /// Restores the cards of [batchIds] into [deckId] (UC-TRASH-001 step 7).
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
  }) async {
    final outcome = await ref.read(restoreCardsFromTrashUseCaseProvider)(
      batchIds: batchIds,
      deckId: deckId,
    );
    if (outcome is Ok && ref.mounted) stopSelecting();
    return outcome;
  }

  /// Restores the decks of [batchIds] under [parentId], or to the top level
  /// for null (BR-TRASH-006).
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
  }) async {
    final outcome = await ref.read(restoreDecksFromTrashUseCaseProvider)(
      batchIds: batchIds,
      parentId: parentId,
    );
    if (outcome is Ok && ref.mounted) stopSelecting();
    return outcome;
  }

  /// Deletes [batchIds] for good (UC-TRASH-001 A3). The batches the store
  /// skips stay, and the screen names them (spec D6).
  Future<PurgeReport> purge(Set<String> batchIds) async {
    final report = await ref.read(purgeTrashUseCaseProvider)(
      batchIds: batchIds,
    );
    if (ref.mounted) {
      state = TrashState(filter: state.filter, blocked: report.blocked);
    }
    return report;
  }

  /// The auto-purge when the Trash opens (UC-TRASH-001 A4).
  Future<void> purgeExpired() => ref.read(purgeExpiredTrashUseCaseProvider)();
}
```

`lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purge_expired_trash_use_case_provider.g.dart';

@riverpod
PurgeExpiredTrashUseCase purgeExpiredTrashUseCase(Ref ref) =>
    PurgeExpiredTrashUseCase(
      ref.watch(trashRepositoryProvider),
      ref.watch(dayClockProvider),
    );
```

`lib/features/trash/presentation/providers/purge_trash_use_case_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/purge_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purge_trash_use_case_provider.g.dart';

@riverpod
PurgeTrashUseCase purgeTrashUseCase(Ref ref) => PurgeTrashUseCase(
  ref.watch(trashRepositoryProvider),
  ref.watch(dayClockProvider),
);
```

`lib/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_cards_from_trash_use_case_provider.g.dart';

@riverpod
RestoreCardsFromTrashUseCase restoreCardsFromTrashUseCase(Ref ref) =>
    RestoreCardsFromTrashUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/trash/presentation/providers/restore_decks_from_trash_use_case_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_decks_from_trash_use_case_provider.g.dart';

@riverpod
RestoreDecksFromTrashUseCase restoreDecksFromTrashUseCase(Ref ref) =>
    RestoreDecksFromTrashUseCase(ref.watch(deckRepositoryProvider));
```

`lib/features/trash/presentation/providers/trash_entries_provider.dart`:

```dart
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/providers/watch_trash_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_entries_provider.g.dart';

/// What is in the Trash, newest first (UC-TRASH-001 steps 3-4). A restore
/// or a purge drops its rows here in place.
@riverpod
Stream<List<TrashEntry>> trashEntries(Ref ref) =>
    ref.watch(watchTrashUseCaseProvider)();
```

`lib/features/trash/presentation/providers/watch_card_restore_targets_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_restore_targets_use_case_provider.g.dart';

@riverpod
WatchCardRestoreTargetsUseCase watchCardRestoreTargetsUseCase(Ref ref) =>
    WatchCardRestoreTargetsUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/trash/presentation/providers/watch_deck_restore_targets_use_case_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_deck_restore_targets_use_case_provider.g.dart';

@riverpod
WatchDeckRestoreTargetsUseCase watchDeckRestoreTargetsUseCase(Ref ref) =>
    WatchDeckRestoreTargetsUseCase(ref.watch(deckRepositoryProvider));
```

`lib/features/trash/presentation/providers/watch_trash_use_case_provider.dart`:

```dart
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_trash_use_case_provider.g.dart';

@riverpod
WatchTrashUseCase watchTrashUseCase(Ref ref) =>
    WatchTrashUseCase(ref.watch(trashRepositoryProvider));
```

`lib/features/trash/presentation/states/trash_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

/// The Trash's filter chips (UC-TRASH-001 A6).
enum TrashFilter {
  all,
  cards,
  decks;

  bool accepts(TrashEntry entry) => switch (this) {
    TrashFilter.all => true,
    TrashFilter.cards => entry is TrashCardEntry,
    TrashFilter.decks => entry is TrashDeckEntry,
  };
}

/// The two kinds a selection is locked to (BR-TRASH-011).
enum TrashKind {
  card,
  deck;

  static TrashKind of(TrashEntry entry) => switch (entry) {
    TrashCardEntry() => TrashKind.card,
    TrashDeckEntry() => TrashKind.deck,
  };
}

/// Screen 06's own state; the entries come from the store's stream.
@immutable
final class TrashState {
  const TrashState({
    this.filter = TrashFilter.all,
    this.isSelecting = false,
    this.selected = const {},
    this.blocked = const {},
  });

  final TrashFilter filter;

  /// "Select" or a long-press turned the rows into checkboxes.
  final bool isSelecting;

  /// The chosen batches, all of one kind.
  final Set<String> selected;

  /// The last purge's skipped batches, each with the batches still inside
  /// it (spec D6). They stay until the next command.
  final Map<String, Set<String>> blocked;

  /// The kind the selection is locked to, read from [entries]; null while
  /// nothing is chosen.
  TrashKind? kindIn(List<TrashEntry> entries) {
    for (final entry in entries) {
      if (selected.contains(entry.batchId)) return TrashKind.of(entry);
    }
    return null;
  }
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/trash
flutter analyze
```

Expected: PASS, 6 tests in `trash_controller_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/trash/presentation/controllers/trash_controller.dart \
  lib/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart \
  lib/features/trash/presentation/providers/purge_trash_use_case_provider.dart \
  lib/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart \
  lib/features/trash/presentation/providers/restore_decks_from_trash_use_case_provider.dart \
  lib/features/trash/presentation/providers/trash_entries_provider.dart \
  lib/features/trash/presentation/providers/watch_card_restore_targets_use_case_provider.dart \
  lib/features/trash/presentation/providers/watch_deck_restore_targets_use_case_provider.dart \
  lib/features/trash/presentation/providers/watch_trash_use_case_provider.dart \
  lib/features/trash/presentation/states/trash_state.dart \
  test/features/trash/presentation/trash_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(trash): the Trash controller: filter, kind-locked selection, restore, purge (FE-B1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: Screen 06: the list, its filters and each entry's commands

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Create: `lib/features/trash/presentation/screens/trash_screen.dart`
- Create: `lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart`
- Create: `lib/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart`
- Create: `lib/features/trash/presentation/widgets/support/trash_labels_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/trash/presentation/goldens/trash_actions_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_actions_light.png`
- Create: `test/features/trash/presentation/goldens/trash_all_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_all_light.png`
- Create: `test/features/trash/presentation/goldens/trash_empty_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_empty_light.png`
- Create: `test/features/trash/presentation/goldens/trash_error_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_error_light.png`
- Test (create): `test/features/trash/presentation/trash_golden_test.dart`
- Test (create): `test/features/trash/presentation/trash_screen_test.dart`
- Test (create): `test/support/trash_screen_fixtures.dart`
- Test (create): `test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 1's `trashEntriesProvider`, `trashControllerProvider`, `TrashFilter`;
  `dayClockProvider`.
- Produces:
  - `TrashScreen()` (a `ConsumerStatefulWidget`; Tasks 3, 4 and 6 extend it);
  - `TrashEntryRowWidget({entry, now, onTap, onLongPress, onActions, isSelecting,
    isSelected})`, one TalkBack node labelled `trashEntrySemantics`;
  - `enum TrashEntryAction {restore, purge}` and
    `showTrashEntryActionsSheet(context, {entry, now}) → Future<TrashEntryAction?>`;
  - the labels in `trash_labels_widget.dart`: `trashEntryName`, `trashOrigin`,
    `trashParent`, `trashDeletedAgo`, `trashTimeLeft`, `isTrashExpiringSoon` (Q7);
  - `AppIcons.restore`;
  - `test/support/trash_screen_fixtures.dart`'s `seedTrash(env) → (korean, words,
    places)`: two cards and two decks in the Trash at fixed times before
    `libraryToday`, one of them expiring within the hour.

- [ ] **Step 1: Write the failing tests**

`test/features/trash/presentation/trash_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('trash, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_all_$theme.png');
      });
    });

    libraryTest('trash actions, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await tester.tap(find.byTooltip(_en.trashEntryActions('meokda · eat')));
        await _settle(tester);
        await expectBoundaryGolden(tester, 'goldens/trash_actions_$theme.png');
      });
    });

    libraryTest('trash empty, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_empty_$theme.png');
      });
    });

    libraryTest('trash error, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const TrashScreen(),
          brightness,
          overrides: [
            trashEntriesProvider.overrideWith(
              (ref) => Stream.error(StateError('read failed')),
            ),
          ],
        );
        await expectBoundaryGolden(tester, 'goldens/trash_error_$theme.png');
      });
    });
  }
}
```

`test/features/trash/presentation/trash_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _chip(String label) =>
    find.descendant(of: find.byType(MxFilterChip), matching: find.text(label));

void main() {
  libraryTest('entries read newest first with their kind, age, time left and '
      'origin (UC-TRASH-001 step 3)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text(_en.trashNote), findsOneWidget);
    expect(find.text(_en.trashEntriesHeader(4).toUpperCase()), findsOneWidget);
    final names = ['meokda · eat', 'Basics', 'Places', 'homework · bai tap'];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort());

    expect(
      find.text(_en.trashCardMeta(_en.trashDeletedMinutes(4))),
      findsOneWidget,
    );
    expect(
      find.text(_en.trashDeckMeta(1, 2, _en.trashDeletedYesterday)),
      findsOneWidget,
    );
    expect(find.text(_en.trashDaysLeft(30)), findsOneWidget);
    expect(find.text(_en.trashDaysLeft(2)), findsOneWidget);
    expect(find.text(_en.trashHoursLeft(1)), findsOneWidget);
    expect(find.text(_en.trashWasIn('Korean › Words')), findsNWidgets(2));
    expect(find.text(_en.trashWasIn(_en.trashTopLevel)), findsOneWidget);
  });

  libraryTest('each filter counts its kind and shows only it (A6)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.tap(_chip(_en.trashFilterDecks));
    await tester.pumpAndSettle();
    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text(_en.trashEntriesHeader(2).toUpperCase()), findsOneWidget);

    await tester.tap(_chip(_en.trashFilterCards));
    await tester.pumpAndSettle();
    expect(find.text('Basics'), findsNothing);
    expect(find.text('homework · bai tap'), findsOneWidget);
  });

  libraryTest('an empty Trash says so, with no note and no filters', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
    expect(find.text(_en.trashEmptyBody), findsOneWidget);
    expect(find.text(_en.trashNote), findsNothing);
    expect(find.byType(MxFilterChip), findsNothing);
  });

  libraryTest('a failed read says so; Retry reads again (E5)', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        trashEntriesProvider.overrideWith((ref) {
          reads++;
          return Stream.error(StateError('read failed'));
        }),
      ],
    );

    expect(find.text(_en.trashLoadErrorTitle), findsOneWidget);
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(reads, 2);
  });

  libraryTest('while the entries load, skeleton rows stand in', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        trashEntriesProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('⋮ offers Restore… and Delete permanently for its entry', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.tap(find.byTooltip(_en.trashEntryActions('meokda · eat')));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.trashCardActionsMeta(_en.trashDeletedMinutes(4), 'Words')),
      findsOneWidget,
    );
    expect(find.text(_en.trashRestore), findsOneWidget);
    expect(find.text(_en.trashDeletePermanently), findsOneWidget);
  });

  libraryTest('a row is one TalkBack node with every fact (spec D15)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(
      find.bySemanticsLabel(
        'Places, ${_en.trashDeckMeta(0, 3, _en.trashDeletedDays(28))}, '
        '${_en.trashDaysLeft(2)}, ${_en.trashWasIn('Korean')}',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
```

`test/support/trash_screen_fixtures.dart`:

```dart
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

import 'card_fixtures.dart';
import 'deck_fixtures.dart';
import 'library_harness.dart';

/// The ids [seedTrash] leaves behind.
typedef TrashSeed = ({String korean, String words, String places});

/// Four Trash entries as kit 06 draws them, deleted at fixed times before
/// [libraryToday], newest first:
/// - the card "meokda · eat", 4 minutes ago, from Korean › Words;
/// - the root "Basics" (1 sub-deck, 2 cards), yesterday;
/// - "Places" (3 cards), 28 days ago, from Korean: 2 days left;
/// - the card "homework · bai tap", 719 hours ago, from Korean › Words: 1h
///   left.
Future<TrashSeed> seedTrash(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final places = await env.decks.sub(korean.id, 'Places');
  final basics = await env.decks.root('Basics');
  final greetings = await env.decks.sub(basics.id, 'Greetings');
  await insertCard(
    env.db,
    id: 'meokda',
    deckId: words.id,
    front: 'meokda',
    back: 'eat',
  );
  await insertCard(
    env.db,
    id: 'gada',
    deckId: words.id,
    front: 'gada',
    back: 'go',
  );
  await insertCard(
    env.db,
    id: 'homework',
    deckId: words.id,
    front: 'homework',
    back: 'bai tap',
  );
  for (final (index, front) in ['hello', 'thanks'].indexed) {
    await insertCard(env.db, id: 'g$index', deckId: greetings.id, front: front);
  }
  for (final (index, front) in ['school', 'market', 'station'].indexed) {
    await insertCard(env.db, id: 'p$index', deckId: places.id, front: front);
  }
  await env.cards.deleteCards(
    cardIds: {'homework'},
    now: libraryToday.subtract(trashRetention - const Duration(hours: 1)),
  );
  await env.decks.deleteDeck(
    deckId: places.id,
    now: libraryToday.subtract(const Duration(days: 28)),
  );
  await env.decks.deleteDeck(
    deckId: basics.id,
    now: libraryToday.subtract(const Duration(days: 1)),
  );
  await env.cards.deleteCards(
    cardIds: {'meokda'},
    now: libraryToday.subtract(const Duration(minutes: 4)),
  );
  return (korean: korean.id, words: words.id, places: places.id);
}
```

`test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/trash_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 06, the list', (tester, env) async {
    await seedTrash(env);
    await auditProductionScreen(
      tester,
      screen: TrashScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/trash/presentation/trash_screen_test.dart
```

Expected: FAIL to compile: `trash_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index a34743c..81637c4 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -47,6 +47,7 @@ abstract final class AppIcons {
   static const IconData repeat = Icons.repeat; // repeat
   static const IconData lapses = Icons.replay; // rotate-ccw
   static const IconData resetProgress = Icons.replay; // rotate-ccw
+  static const IconData restore = Icons.replay; // rotate-ccw
   static const IconData lock = Icons.lock_outline; // lock
   static const IconData lockOpen = Icons.lock_open_outlined; // lock-open
   static const IconData timeout = Icons.timer_off_outlined; // timer-off
```

`lib/features/trash/presentation/screens/trash_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 06, the Trash (UC-TRASH-001): what was deleted, newest first,
/// filtered by kind, each entry with its time left.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  static const int _skeletonRows = 3;

  TrashController _trash() => ref.read(trashControllerProvider.notifier);

  Future<void> _openActions(TrashEntry entry) async {
    await showTrashEntryActionsSheet(
      context,
      entry: entry,
      now: ref.read(dayClockProvider).now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = ref.watch(trashEntriesProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.libraryTrash,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (entries) {
        AsyncData(:final value) when value.isEmpty => MxScreenScroll(
          children: [
            MxEmptyState(
              icon: AppIcons.delete,
              title: l10n.trashEmptyTitle,
              body: l10n.trashEmptyBody,
            ),
          ],
        ),
        AsyncData(:final value) => MxScreenScroll(children: _list(l10n, value)),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.trashLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(trashEntriesProvider),
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
    );
  }

  /// The note, the filters with their counts (A6), the header, the rows.
  List<Widget> _list(AppLocalizations l10n, List<TrashEntry> entries) {
    final state = ref.watch(trashControllerProvider);
    final now = ref.watch(dayClockProvider).now();
    final shown = entries.where(state.filter.accepts).toList();
    return [
      const SizedBox(height: AppSpacing.control),
      MxNote(icon: AppIcons.history, text: l10n.trashNote),
      const SizedBox(height: AppSpacing.grouped),
      _Filters(
        selected: state.filter,
        entries: entries,
        onSelected: _trash().chooseFilter,
      ),
      MxListSectionHeader(
        label: l10n.trashEntriesHeader(shown.length),
        isAfterFilterBand: true,
      ),
      for (final entry in shown)
        TrashEntryRowWidget(
          key: ValueKey(entry.batchId),
          entry: entry,
          now: now,
          onTap: () => unawaited(_openActions(entry)),
          onActions: () => unawaited(_openActions(entry)),
        ),
    ];
  }
}

/// All · Cards · Decks, each with its count (kit 06).
class _Filters extends StatelessWidget {
  const _Filters({
    required this.selected,
    required this.entries,
    required this.onSelected,
  });

  final TrashFilter selected;
  final List<TrashEntry> entries;
  final ValueChanged<TrashFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      // The chips never shrink or wrap, so their row scrolls.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: AppSpacing.micro,
          children: [
            for (final filter in TrashFilter.values)
              MxFilterChip(
                label: switch (filter) {
                  TrashFilter.all => l10n.trashFilterAll,
                  TrashFilter.cards => l10n.trashFilterCards,
                  TrashFilter.decks => l10n.trashFilterDecks,
                },
                count: entries.where(filter.accepts).length,
                isSelected: filter == selected,
                onSelected: (_) => onSelected(filter),
              ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

/// One Trash entry (kit 06): its kind, its name and time left, what went
/// with it and when, and where it was (information only, BR-TRASH-012).
/// Selecting, it is a checkbox; an entry of the other kind cannot be picked
/// (BR-TRASH-011).
class TrashEntryRowWidget extends StatelessWidget {
  const TrashEntryRowWidget({
    super.key,
    required this.entry,
    required this.now,
    required this.onTap,
    this.onLongPress,
    this.onActions,
    this.isSelecting = false,
    this.isSelected = false,
  });

  final TrashEntry entry;
  final DateTime now;

  /// Null while selecting for an entry of the other kind.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The ⋮ command; absent while selecting.
  final VoidCallback? onActions;
  final bool isSelecting;
  final bool isSelected;

  static const double _rowPadding = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = trashEntryName(entry);
    final meta = _meta(context);
    final timeLeft = trashTimeLeft(l10n, entry, now);
    final origin = l10n.trashWasIn(trashOrigin(l10n, entry));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxCard(
        isFullBleed: true,
        isSelected: isSelected,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // One TalkBack node with every fact, whatever the ellipsis
              // hides (spec D15); the ⋮ stays its own control.
              child: Semantics(
                container: true,
                excludeSemantics: true,
                button: !isSelecting,
                checked: isSelecting ? isSelected : null,
                enabled: onTap != null,
                label: l10n.trashEntrySemantics(name, meta, timeLeft, origin),
                child: GestureDetector(
                  onLongPress: onLongPress,
                  child: MxRowInk(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(_rowPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.grouped,
                        children: [
                          if (isSelecting)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.micro,
                              ),
                              child: MxSelectionCheckbox(isChecked: isSelected),
                            )
                          else
                            MxIconTile(
                              icon: entry is TrashDeckEntry
                                  ? AppIcons.library
                                  : AppIcons.cardDeck,
                            ),
                          Expanded(
                            child: _Lines(
                              name: name,
                              timeLeft: timeLeft,
                              isExpiringSoon: isTrashExpiringSoon(entry, now),
                              meta: meta,
                              origin: origin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onActions case final onActions? when !isSelecting)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.micro,
                  right: AppSpacing.micro,
                ),
                child: MxIconButton(
                  icon: AppIcons.more,
                  semanticLabel: l10n.trashEntryActions(name),
                  onPressed: onActions,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _meta(BuildContext context) {
    final l10n = context.l10n;
    final ago = trashDeletedAgo(l10n, entry.deletedAt, now);
    return switch (entry) {
      TrashCardEntry() => l10n.trashCardMeta(ago),
      TrashDeckEntry(:final subDeckCount, :final cardCount) =>
        l10n.trashDeckMeta(subDeckCount, cardCount, ago),
    };
  }
}

class _Lines extends StatelessWidget {
  const _Lines({
    required this.name,
    required this.timeLeft,
    required this.isExpiringSoon,
    required this.meta,
    required this.origin,
  });

  final String name;
  final String timeLeft;
  final bool isExpiringSoon;
  final String meta;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final ink = isExpiringSoon
        ? context.derivedColors.warningInk
        : context.colors.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.micro,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: AppSpacing.control,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.rowTitle,
              ),
            ),
            Text(timeLeft, style: styles.badgeLabel(ink)),
          ],
        ),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.rowDescription,
        ),
        Text(
          origin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.rowDescription,
        ),
      ],
    );
  }
}
```

`lib/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// A Trash entry's two commands (kit 06 actions).
enum TrashEntryAction { restore, purge }

/// Opens [entry]'s commands; completes with the chosen one, or null when
/// dismissed.
Future<TrashEntryAction?> showTrashEntryActionsSheet(
  BuildContext context, {
  required TrashEntry entry,
  required DateTime now,
}) => showMxBottomSheet<TrashEntryAction>(
  context,
  builder: (_) => TrashEntryActionsSheetWidget(entry: entry, now: now),
);

/// Restore asks for a target (BR-TRASH-006); Delete permanently is the one
/// destructive command (BR-TRASH-011).
class TrashEntryActionsSheetWidget extends StatelessWidget {
  const TrashEntryActionsSheetWidget({
    super.key,
    required this.entry,
    required this.now,
  });

  final TrashEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final ago = trashDeletedAgo(l10n, entry.deletedAt, now);
    final parent = trashParent(l10n, entry);
    void choose(TrashEntryAction action) => Navigator.of(context).pop(action);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(
              trashEntryName(entry),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: styles.compactTitle,
            ),
            Text(switch (entry) {
              TrashCardEntry() => l10n.trashCardActionsMeta(ago, parent),
              TrashDeckEntry() => l10n.trashDeckActionsMeta(ago, parent),
            }, style: styles.rowDescription),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.restore,
              label: l10n.trashRestore,
              subtitle: l10n.trashRestoreHint,
              hasChevron: true,
              onTap: () => choose(TrashEntryAction.restore),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: l10n.trashDeletePermanently,
              subtitle: l10n.trashDeletePermanentlyHint,
              isDestructive: true,
              hasChevron: true,
              onTap: () => choose(TrashEntryAction.purge),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/trash/presentation/widgets/support/trash_labels_widget.dart`:

```dart
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Between two decks of a path. Each feature has its own join (ruling
/// P3-L8).
const String trashPathSeparator = ' › ';

/// Between a card's front and back in its name (kit 06).
const String trashSidesSeparator = ' · ';

/// Under this much time left, the row says so in the warning ink (kit 06).
const Duration trashExpiringSoon = Duration(days: 3);

/// The entry as the person knows it: a deck's name, a card's two sides.
String trashEntryName(TrashEntry entry) => switch (entry) {
  TrashDeckEntry(:final name) => name,
  TrashCardEntry(:final front, :final back) =>
    '$front$trashSidesSeparator$back',
};

/// The decks the item was in, root first; a root was at the top level.
String trashOrigin(AppLocalizations l10n, TrashEntry entry) =>
    entry.origin.isEmpty
    ? l10n.trashTopLevel
    : entry.origin.map((deck) => deck.name).join(trashPathSeparator);

/// The deck the item was in, the origin's last; the top level for a root.
String trashParent(AppLocalizations l10n, TrashEntry entry) =>
    entry.origin.isEmpty ? l10n.trashTopLevel : entry.origin.last.name;

/// How long ago the entry was deleted, for "deleted {ago}".
String trashDeletedAgo(
  AppLocalizations l10n,
  DateTime deletedAt,
  DateTime now,
) {
  final elapsed = now.difference(deletedAt);
  if (elapsed.inHours < 1) return l10n.trashDeletedMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.trashDeletedHours(elapsed.inHours);
  if (elapsed.inDays == 1) return l10n.trashDeletedYesterday;
  return l10n.trashDeletedDays(elapsed.inDays);
}

/// The time until the auto-purge takes the entry (BR-TRASH-009): whole days
/// rounded up, then hours under a day, never less than one.
String trashTimeLeft(AppLocalizations l10n, TrashEntry entry, DateTime now) {
  final left = entry.expiresAt.difference(now);
  if (left >= _day) return l10n.trashDaysLeft(_roundedUp(left, _day));
  final hours = _roundedUp(left, _hour);
  return l10n.trashHoursLeft(hours < 1 ? 1 : hours);
}

const Duration _day = Duration(days: 1);
const Duration _hour = Duration(hours: 1);

bool isTrashExpiringSoon(TrashEntry entry, DateTime now) =>
    entry.expiresAt.difference(now) < trashExpiringSoon;

int _roundedUp(Duration value, Duration unit) =>
    (value.inMicroseconds + unit.inMicroseconds - 1) ~/ unit.inMicroseconds;
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 7b4fe29..2c38a58 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1321,6 +1321,200 @@
   "@libraryTrash": {
     "description": "Screen handoff 01/04 (library alignment phase C): libraryTrash."
   },
+  "trashNote": "Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go.",
+  "@trashNote": {
+    "description": "Screen 06: the retention note over the list (BR-TRASH-009, BR-TRASH-006)."
+  },
+  "trashSelect": "Select",
+  "@trashSelect": {
+    "description": "Screen 06: the app bar action that turns the rows into checkboxes (BR-TRASH-011)."
+  },
+  "trashFilterAll": "All",
+  "@trashFilterAll": {
+    "description": "Screen 06: the filter chip for every entry."
+  },
+  "trashFilterCards": "Cards",
+  "@trashFilterCards": {
+    "description": "Screen 06: the filter chip for card entries."
+  },
+  "trashFilterDecks": "Decks",
+  "@trashFilterDecks": {
+    "description": "Screen 06: the filter chip for deck entries."
+  },
+  "trashEntriesHeader": "{count, plural, =1{1 entry · newest first} other{{count} entries · newest first}}",
+  "@trashEntriesHeader": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: the list header (UC-TRASH-001 step 3)."
+  },
+  "trashCardMeta": "Card · deleted {ago}",
+  "@trashCardMeta": {
+    "placeholders": {
+      "ago": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: a card row's meta line; ago is a trashDeleted* phrase."
+  },
+  "trashDeckMeta": "Deck · {subDeckCount, plural, =1{1 sub-deck} other{{subDeckCount} sub-decks}} · {cardCount, plural, =1{1 card} other{{cardCount} cards}} · deleted {ago}",
+  "@trashDeckMeta": {
+    "placeholders": {
+      "subDeckCount": {
+        "type": "int"
+      },
+      "cardCount": {
+        "type": "int"
+      },
+      "ago": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: a deck row's meta line; ago is a trashDeleted* phrase."
+  },
+  "trashDeletedMinutes": "{count, plural, =0{just now} =1{1 minute ago} other{{count} minutes ago}}",
+  "@trashDeletedMinutes": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: when an entry was deleted, under an hour ago."
+  },
+  "trashDeletedHours": "{count, plural, =1{1 hour ago} other{{count} hours ago}}",
+  "@trashDeletedHours": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: when an entry was deleted, under a day ago."
+  },
+  "trashDeletedYesterday": "yesterday",
+  "@trashDeletedYesterday": {
+    "description": "Screen 06: when an entry was deleted, a day ago."
+  },
+  "trashDeletedDays": "{count} days ago",
+  "@trashDeletedDays": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: when an entry was deleted, two days ago or more."
+  },
+  "trashWasIn": "Was in {path}",
+  "@trashWasIn": {
+    "placeholders": {
+      "path": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: where the item was; information only (BR-TRASH-012)."
+  },
+  "trashTopLevel": "Top level",
+  "@trashTopLevel": {
+    "description": "Screen 06: the place of a top-level deck, and its one restore target."
+  },
+  "trashDaysLeft": "{count, plural, =1{1 day left} other{{count} days left}}",
+  "@trashDaysLeft": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: time until the auto-purge (BR-TRASH-009)."
+  },
+  "trashHoursLeft": "{count}h left",
+  "@trashHoursLeft": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06: time until the auto-purge, under a day (BR-TRASH-009)."
+  },
+  "trashEntryActions": "Actions for {name}",
+  "@trashEntryActions": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: the row's ⋮ label."
+  },
+  "trashEntrySemantics": "{name}, {meta}, {timeLeft}, {origin}",
+  "@trashEntrySemantics": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      },
+      "meta": {
+        "type": "String"
+      },
+      "timeLeft": {
+        "type": "String"
+      },
+      "origin": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: what TalkBack reads for a row, every fact the ellipsis may hide (spec D15)."
+  },
+  "trashCardActionsMeta": "Card · deleted {ago} · was in {deck}",
+  "@trashCardActionsMeta": {
+    "placeholders": {
+      "ago": {
+        "type": "String"
+      },
+      "deck": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: the actions sheet's sub-line for a card."
+  },
+  "trashDeckActionsMeta": "Deck · deleted {ago} · was in {deck}",
+  "@trashDeckActionsMeta": {
+    "placeholders": {
+      "ago": {
+        "type": "String"
+      },
+      "deck": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: the actions sheet's sub-line for a deck."
+  },
+  "trashRestore": "Restore…",
+  "@trashRestore": {
+    "description": "Screen 06: the actions sheet command that asks for a target (BR-TRASH-006)."
+  },
+  "trashRestoreHint": "Choose which deck it goes to",
+  "@trashRestoreHint": {
+    "description": "Screen 06: the Restore command's sub-line."
+  },
+  "trashDeletePermanently": "Delete permanently",
+  "@trashDeletePermanently": {
+    "description": "Screen 06: the actions sheet command that purges one entry (BR-TRASH-010)."
+  },
+  "trashDeletePermanentlyHint": "Cannot be undone · history lost",
+  "@trashDeletePermanentlyHint": {
+    "description": "Screen 06: the Delete permanently command's sub-line."
+  },
+  "trashEmptyTitle": "Trash is empty",
+  "@trashEmptyTitle": {
+    "description": "Screen 06: the empty state title."
+  },
+  "trashEmptyBody": "Decks and cards you delete stay here for 30 days before they are removed for good.",
+  "@trashEmptyBody": {
+    "description": "Screen 06: the empty state body (BR-TRASH-009)."
+  },
+  "trashLoadErrorTitle": "Couldn't open Trash",
+  "@trashLoadErrorTitle": {
+    "description": "Screen 06: the error state title (UC-TRASH-001 E5)."
+  },
   "libraryDueTitle": "{count, plural, =1{1 card due} other{{count} cards due}}",
   "@libraryDueTitle": {
     "placeholders": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index ff4523c..8e2afa8 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -276,6 +276,33 @@
   "libraryStarterDecks": "Bộ thẻ mẫu",
   "libraryTags": "Tag",
   "libraryTrash": "Thùng rác",
+  "trashNote": "Được giữ 30 ngày kể từ khi xoá, rồi tự động bị xoá hẳn. Khi khôi phục, app sẽ hỏi item đi về đâu.",
+  "trashSelect": "Chọn",
+  "trashFilterAll": "Tất cả",
+  "trashFilterCards": "Thẻ",
+  "trashFilterDecks": "Bộ thẻ",
+  "trashEntriesHeader": "{count, plural, other{{count} mục · mới nhất trước}}",
+  "trashCardMeta": "Thẻ · đã xoá {ago}",
+  "trashDeckMeta": "Bộ thẻ · {subDeckCount} bộ thẻ con · {cardCount} thẻ · đã xoá {ago}",
+  "trashDeletedMinutes": "{count, plural, =0{vừa xong} other{{count} phút trước}}",
+  "trashDeletedHours": "{count, plural, other{{count} giờ trước}}",
+  "trashDeletedYesterday": "hôm qua",
+  "trashDeletedDays": "{count} ngày trước",
+  "trashWasIn": "Từng ở {path}",
+  "trashTopLevel": "Cấp cao nhất",
+  "trashDaysLeft": "{count, plural, other{còn {count} ngày}}",
+  "trashHoursLeft": "còn {count} giờ",
+  "trashEntryActions": "Thao tác cho {name}",
+  "trashEntrySemantics": "{name}, {meta}, {timeLeft}, {origin}",
+  "trashCardActionsMeta": "Thẻ · đã xoá {ago} · từng ở {deck}",
+  "trashDeckActionsMeta": "Bộ thẻ · đã xoá {ago} · từng ở {deck}",
+  "trashRestore": "Khôi phục…",
+  "trashRestoreHint": "Chọn bộ thẻ để đưa về",
+  "trashDeletePermanently": "Xoá vĩnh viễn",
+  "trashDeletePermanentlyHint": "Không thể hoàn tác · mất lịch sử",
+  "trashEmptyTitle": "Thùng rác trống",
+  "trashEmptyBody": "Bộ thẻ và thẻ bạn xoá được giữ ở đây 30 ngày trước khi bị xoá hẳn.",
+  "trashLoadErrorTitle": "Không mở được Thùng rác",
   "libraryDueTitle": "{count} thẻ đến hạn",
   "libraryDecksCount": "{count} bộ thẻ",
   "libraryDueDecksHeader": "Bộ thẻ có thẻ đến hạn",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/trash test/visual_audit/screens/features/trash
flutter test test/features/trash test/visual_audit test/l10n
flutter analyze
```

Expected: PASS. Eight new goldens; compare each with
`docs/shared/ui/screen-handoff/img/06-trash/`:
- `trash_all_*` with `all-*`: the note, the three filters with counts, "4 entries ·
  newest first", and each row with its tile, name, time left, meta and "Was in";
- `trash_actions_*` with `actions-*`: the name, "Card · deleted … · was in …",
  "Restore…" and the destructive "Delete permanently";
- `trash_empty_*` with `empty-*`; `trash_error_*` with `error-*` (Q10).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/trash/presentation/screens/trash_screen.dart \
  lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart \
  lib/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart \
  lib/features/trash/presentation/widgets/support/trash_labels_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/trash/presentation/trash_golden_test.dart \
  test/features/trash/presentation/trash_screen_test.dart \
  test/support/trash_screen_fixtures.dart \
  test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart \
  test/features/trash/presentation/goldens/trash_actions_dark.png \
  test/features/trash/presentation/goldens/trash_actions_light.png \
  test/features/trash/presentation/goldens/trash_all_dark.png \
  test/features/trash/presentation/goldens/trash_all_light.png \
  test/features/trash/presentation/goldens/trash_empty_dark.png \
  test/features/trash/presentation/goldens/trash_empty_light.png \
  test/features/trash/presentation/goldens/trash_error_dark.png \
  test/features/trash/presentation/goldens/trash_error_light.png
git commit -m "$(cat <<'EOF'
feat(trash): screen 06 lists what was deleted, by kind (FE-B1, UC-TRASH-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: Restore to a place the person picks

**Files:**
- Create: `lib/features/trash/presentation/providers/trash_restore_targets_provider.dart`
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart`
- Modify: `lib/features/trash/presentation/states/trash_state.dart`
- Create: `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart`
- Create: `lib/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Create: `test/features/trash/presentation/goldens/trash_no_target_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_no_target_light.png`
- Create: `test/features/trash/presentation/goldens/trash_restore_target_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_restore_target_light.png`
- Test (modify): `test/features/trash/presentation/trash_golden_test.dart`
- Test (create): `test/features/trash/presentation/trash_rejection_message_test.dart`
- Test (create): `test/features/trash/presentation/trash_restore_test.dart`

**Interfaces:**
- Consumes: Task 1's `restoreCards`, `restoreDecks` and the two target use case
  providers; Task 2's screen, `TrashEntryAction.restore` and labels; `MxDeckPickerSheet`.
- Produces:
  - `TrashBatchIds(Set<String> ids)`, a key with value equality (Q8);
  - `cardRestoreTargetsProvider(TrashBatchIds) → Stream<List<CardMoveTarget>>` and
    `deckRestoreTargetsProvider(TrashBatchIds) → Stream<DeckRestoreTargets>`;
  - `showTrashRestoreSheet(context, {required List<TrashEntry> entries}) →
    Future<bool>` (true once they are back); Task 4 opens it for a selection;
  - `extension TrashRejectionMessage on AppLocalizations` with
    `trashCardRejection(CardRejection)` and `trashDeckRejection(DeckRejection)` (Q6).

- [ ] **Step 1: Write the failing tests**

`test/features/trash/presentation/trash_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/trash/presentation/trash_golden_test.dart b/test/features/trash/presentation/trash_golden_test.dart
index 035c7a0..e2bff13 100644
--- a/test/features/trash/presentation/trash_golden_test.dart
+++ b/test/features/trash/presentation/trash_golden_test.dart
@@ -18,6 +18,13 @@ Future<void> _settle(WidgetTester tester) async {
   await tester.pump(const Duration(milliseconds: 400));
 }
 
+Future<void> _openRestore(WidgetTester tester, String name) async {
+  await tester.tap(find.byTooltip(_en.trashEntryActions(name)));
+  await _settle(tester);
+  await tester.tap(find.text(_en.trashRestore));
+  await _settle(tester);
+}
+
 void main() {
   for (final brightness in Brightness.values) {
     final theme = brightness.name;
@@ -40,6 +47,31 @@ void main() {
       });
     });
 
+    libraryTest('trash restore target, $theme', (tester, env) async {
+      await seedTrash(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
+        await _openRestore(tester, 'meokda · eat');
+        await expectBoundaryGolden(
+          tester,
+          'goldens/trash_restore_target_$theme.png',
+        );
+      });
+    });
+
+    libraryTest('trash no restore target, $theme', (tester, env) async {
+      final seed = await seedTrash(env);
+      await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
+        await _openRestore(tester, 'meokda · eat');
+        await expectBoundaryGolden(
+          tester,
+          'goldens/trash_no_target_$theme.png',
+        );
+      });
+    });
+
     libraryTest('trash empty, $theme', (tester, env) async {
       await withRealShadows(() async {
         await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
```

`test/features/trash/presentation/trash_rejection_message_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);

    test('a refused restore reads as the card and deck features say it '
        '(${locale.languageCode})', () {
      for (final reason in CardRejection.values) {
        expect(
          l10n.trashCardRejection(reason),
          l10n.cardRejection(reason),
          reason: reason.name,
        );
      }
      for (final reason in DeckRejection.values) {
        expect(
          l10n.trashDeckRejection(reason),
          l10n.deckRejection(reason),
          reason: reason.name,
        );
      }
    });
  }
}
```

`test/features/trash/presentation/trash_restore_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _inSheet(String text) => find.descendant(
  of: find.byType(MxDeckPickerSheet),
  matching: find.text(text),
);

Future<void> _openRestore(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip(_en.trashEntryActions(name)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.trashRestore));
  await tester.pumpAndSettle();
}

Future<bool> _isActive(LibraryEnv env, String table, String id) async =>
    (await env.db
            .customSelect(
              'SELECT delete_batch_id IS NULL AS active FROM $table WHERE id = ?',
              variables: [Variable<String>(id)],
            )
            .getSingle())
        .read<bool>('active');

void main() {
  libraryTest('a card goes back into a deck the person picks (UC-TRASH-001 '
      'steps 5-7)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');

    expect(find.text(_en.trashRestoreOneTitle('meokda · eat')), findsOneWidget);
    expect(find.text(_en.trashRestoreCardsRule), findsOneWidget);
    // Places is in the Trash and Korean holds decks: Words alone.
    expect(
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.byType(MxListRow),
      ),
      findsOneWidget,
    );
    await tester.tap(_inSheet('Korean › Words'));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.trashRestoredOne('meokda · eat', 'Words')),
      findsOneWidget,
    );
    expect(find.text('meokda · eat'), findsNothing);
    expect(await _isActive(env, 'card', 'meokda'), isTrue);
  });

  libraryTest('a top-level deck goes back to the top level, which the person '
      'still confirms (BR-TRASH-006)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'Basics');

    expect(find.text(_en.trashRestoreRootsRule), findsOneWidget);
    await tester.tap(_inSheet(_en.trashTopLevel));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.trashRestoredOne('Basics', _en.trashTopLevel)),
      findsOneWidget,
    );
    expect(find.text('Basics'), findsNothing);
  });

  libraryTest('a sub-deck goes under a deck that could take it by a move', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'Places');

    expect(find.text(_en.trashRestoreDecksRule), findsOneWidget);
    await tester.tap(_inSheet('Korean'));
    await tester.pumpAndSettle();

    expect(find.text(_en.trashRestoredOne('Places', 'Korean')), findsOneWidget);
    expect(await _isActive(env, 'deck', seed.places), isTrue);
  });

  libraryTest('with nowhere to go, the sheet says why and offers OK (E1)', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');

    expect(find.text(_en.trashRestoreEmptyTitle), findsOneWidget);
    expect(
      find.text(_en.trashRestoreNoCardTargetBody('Korean')),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.commonOk));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(await _isActive(env, 'card', 'meokda'), isFalse);
  });

  libraryTest('the targets follow the store while the sheet is open (E2)', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');
    expect(_inSheet('Korean › Words'), findsOneWidget);

    await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
    await tester.pumpAndSettle();
    expect(_inSheet('Korean › Words'), findsNothing);
    expect(find.text(_en.trashRestoreEmptyTitle), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/trash/presentation/trash_restore_test.dart test/features/trash/presentation/trash_rejection_message_test.dart
```

Expected: FAIL to compile: `trash_rejection_message_widget.dart` does not exist and
`trashRestoredOne` is not a member of `AppLocalizations`.

- [ ] **Step 3: Implement**

`lib/features/trash/presentation/providers/trash_restore_targets_provider.dart`:

```dart
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/trash/presentation/providers/watch_card_restore_targets_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/watch_deck_restore_targets_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_restore_targets_provider.g.dart';

/// The decks the cards of [batchIds] can go back into, live (BR-TRASH-006).
@riverpod
Stream<List<CardMoveTarget>> cardRestoreTargets(
  Ref ref,
  TrashBatchIds batchIds,
) => ref.watch(watchCardRestoreTargetsUseCaseProvider)(batchIds: batchIds.ids);

/// Where the decks of [batchIds] can go back to, live (BR-TRASH-006).
@riverpod
Stream<DeckRestoreTargets> deckRestoreTargets(
  Ref ref,
  TrashBatchIds batchIds,
) => ref.watch(watchDeckRestoreTargetsUseCaseProvider)(batchIds: batchIds.ids);
```

`lib/features/trash/presentation/screens/trash_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/trash/presentation/screens/trash_screen.dart b/lib/features/trash/presentation/screens/trash_screen.dart
index 8ef3373..ed8be80 100644
--- a/lib/features/trash/presentation/screens/trash_screen.dart
+++ b/lib/features/trash/presentation/screens/trash_screen.dart
@@ -11,6 +11,7 @@ import 'package:memox/features/trash/presentation/providers/trash_entries_provid
 import 'package:memox/features/trash/presentation/states/trash_state.dart';
 import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
 import 'package:memox/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart';
+import 'package:memox/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
@@ -39,11 +40,18 @@ class _TrashScreenState extends ConsumerState<TrashScreen> {
   TrashController _trash() => ref.read(trashControllerProvider.notifier);
 
   Future<void> _openActions(TrashEntry entry) async {
-    await showTrashEntryActionsSheet(
+    final action = await showTrashEntryActionsSheet(
       context,
       entry: entry,
       now: ref.read(dayClockProvider).now(),
     );
+    if (action == null || !mounted) return;
+    switch (action) {
+      case TrashEntryAction.restore:
+        await showTrashRestoreSheet(context, entries: [entry]);
+      case TrashEntryAction.purge:
+        break;
+    }
   }
 
   @override
```

`lib/features/trash/presentation/states/trash_state.dart` (apply this diff):

```diff
diff --git a/lib/features/trash/presentation/states/trash_state.dart b/lib/features/trash/presentation/states/trash_state.dart
index 1a29a71..388f5b2 100644
--- a/lib/features/trash/presentation/states/trash_state.dart
+++ b/lib/features/trash/presentation/states/trash_state.dart
@@ -56,3 +56,19 @@ final class TrashState {
     return null;
   }
 }
+
+/// The batches a restore sheet is for, equal by value so a provider keyed
+/// by it is found again.
+@immutable
+final class TrashBatchIds {
+  const TrashBatchIds(this.ids);
+
+  final Set<String> ids;
+
+  @override
+  bool operator ==(Object other) =>
+      other is TrashBatchIds && setEquals(other.ids, ids);
+
+  @override
+  int get hashCode => Object.hashAllUnordered(ids);
+}
```

`lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/trash_restore_targets_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks where [entries], all of one kind, go back to, then restores them
/// there (UC-TRASH-001 steps 5-7). Nothing is written before a target is
/// chosen (BR-TRASH-006). Completes true once they are back.
Future<bool> showTrashRestoreSheet(
  BuildContext context, {
  required List<TrashEntry> entries,
}) async =>
    await showMxBottomSheet<bool>(
      context,
      builder: (_) => TrashRestoreSheetWidget(entries: entries),
    ) ??
    false;

/// A place the entries can go: a deck, or the top level (null).
typedef _Target = ({String? id, String name, String label});

class TrashRestoreSheetWidget extends ConsumerStatefulWidget {
  const TrashRestoreSheetWidget({super.key, required this.entries});

  final List<TrashEntry> entries;

  @override
  ConsumerState<TrashRestoreSheetWidget> createState() =>
      _TrashRestoreSheetWidgetState();
}

class _TrashRestoreSheetWidgetState
    extends ConsumerState<TrashRestoreSheetWidget> {
  static const int _skeletonRows = 3;

  /// One restore at a time: a second tap before the first lands does
  /// nothing.
  var _isRestoring = false;

  late final _batchIds = TrashBatchIds({
    for (final entry in widget.entries) entry.batchId,
  });

  bool get _isCards => widget.entries.first is TrashCardEntry;

  Future<void> _restore(_Target target) async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    final trash = ref.read(trashControllerProvider.notifier);
    try {
      final String? refusal;
      if (_isCards) {
        final outcome = await trash.restoreCards(
          batchIds: _batchIds.ids,
          deckId: target.id!,
        );
        if (!mounted) return;
        refusal = switch (outcome) {
          Ok() => null,
          Rejected(:final reason) => context.l10n.trashCardRejection(reason),
        };
      } else {
        final outcome = await trash.restoreDecks(
          batchIds: _batchIds.ids,
          parentId: target.id,
        );
        if (!mounted) return;
        refusal = switch (outcome) {
          Ok() => null,
          Rejected(:final reason) => context.l10n.trashDeckRejection(reason),
        };
      }
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message:
            refusal ??
            switch (widget.entries) {
              [final entry] => l10n.trashRestoredOne(
                trashEntryName(entry),
                target.name,
              ),
              final entries => l10n.trashRestoredMany(
                entries.length,
                target.name,
              ),
            },
      );
      Navigator.of(context).pop(refusal == null);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targets = _isCards
        ? ref
              .watch(cardRestoreTargetsProvider(_batchIds))
              .whenData(
                (targets) => [
                  for (final target in targets)
                    _deck(target.id, target.name, target.path),
                ],
              )
        : ref
              .watch(deckRestoreTargetsProvider(_batchIds))
              .whenData(
                (targets) => switch (targets) {
                  DeckRestoreTopLevel() => [
                    (
                      id: null,
                      name: l10n.trashTopLevel,
                      label: l10n.trashTopLevel,
                    ),
                  ],
                  DeckRestoreUnder(:final decks) => [
                    for (final target in decks)
                      _deck(target.id, target.name, target.path),
                  ],
                },
              );
    return switch (targets) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: _title(l10n),
        rule: _rule(l10n, value),
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: target.label,
              icon: target.id == null ? AppIcons.library : AppIcons.folder,
              isEnabled: !_isRestoring,
              onTap: () => unawaited(_restore(target)),
            ),
        ],
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(false),
        emptyTitle: l10n.trashRestoreEmptyTitle,
        emptyBody: _emptyBody(l10n),
      ),
      AsyncError() => MxBottomSheet(
        child: MxErrorState(
          title: l10n.trashLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(
            _isCards
                ? cardRestoreTargetsProvider(_batchIds)
                : deckRestoreTargetsProvider(_batchIds),
          ),
        ),
      ),
      _ => MxBottomSheet(
        child: Column(
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

  static _Target _deck(String id, String name, List<DeckPathEntry> path) => (
    id: id,
    name: name,
    label: [
      for (final entry in path) entry.name,
      name,
    ].join(trashPathSeparator),
  );

  String _title(AppLocalizations l10n) => switch (widget.entries) {
    [final entry] => l10n.trashRestoreOneTitle(trashEntryName(entry)),
    final entries when _isCards => l10n.trashRestoreCardsTitle(entries.length),
    final entries => l10n.trashRestoreDecksTitle(entries.length),
  };

  String _rule(AppLocalizations l10n, List<_Target> targets) {
    if (_isCards) return l10n.trashRestoreCardsRule;
    final isTopLevel = targets.length == 1 && targets.single.id == null;
    return isTopLevel ? l10n.trashRestoreRootsRule : l10n.trashRestoreDecksRule;
  }

  /// A card names its top-level deck, where an empty sub-deck would take it
  /// (kit 06 noTarget).
  String _emptyBody(AppLocalizations l10n) {
    final origin = widget.entries.first.origin;
    if (!_isCards || origin.isEmpty) return l10n.trashRestoreNoDeckTargetBody;
    return l10n.trashRestoreNoCardTargetBody(origin.first.name);
  }
}
```

`lib/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart`:

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for a refused restore (UC-TRASH-001 E2). The trash feature
/// may not reach into `card` or `deck` presentation, so it maps their
/// reasons itself, to the same messages. Exhaustive with no default, so a
/// new reason fails to compile until it has copy.
extension TrashRejectionMessage on AppLocalizations {
  String trashCardRejection(CardRejection reason) => switch (reason) {
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
    CardRejection.targetInTrash => cardRejectionTargetInTrash,
  };

  String trashDeckRejection(DeckRejection reason) => switch (reason) {
    DeckRejection.blankName => deckRejectionBlankName,
    DeckRejection.nameTooLong => deckRejectionNameTooLong,
    DeckRejection.depthExceeded => deckRejectionDepthExceeded,
    DeckRejection.notADeckContainer => deckRejectionNotADeckContainer,
    DeckRejection.notACardContainer => deckRejectionNotACardContainer,
    DeckRejection.subtreeSchedulerMismatch =>
      deckRejectionSubtreeSchedulerMismatch,
    DeckRejection.movingIntoOwnSubtree => deckRejectionMovingIntoOwnSubtree,
    DeckRejection.rootCannotMove => deckRejectionRootCannotMove,
    DeckRejection.notFound => deckRejectionNotFound,
    DeckRejection.notSiblings => deckRejectionNotSiblings,
    DeckRejection.sameParent => deckRejectionSameParent,
    DeckRejection.targetNotFound => deckRejectionTargetNotFound,
    DeckRejection.targetInTrash => deckRejectionTargetInTrash,
    DeckRejection.rootRestoresToTopLevel => deckRejectionRootRestoresToTopLevel,
    DeckRejection.subDeckNeedsParent => deckRejectionSubDeckNeedsParent,
  };
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 2c38a58..b26d43a 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1515,6 +1515,86 @@
   "@trashLoadErrorTitle": {
     "description": "Screen 06: the error state title (UC-TRASH-001 E5)."
   },
+  "trashRestoreOneTitle": "Restore “{name}” to…",
+  "@trashRestoreOneTitle": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06 restore sheet title for one entry (UC-TRASH-001 step 5)."
+  },
+  "trashRestoreCardsTitle": "{count, plural, =1{Restore 1 card to…} other{Restore {count} cards to…}}",
+  "@trashRestoreCardsTitle": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 restore sheet title for selected cards."
+  },
+  "trashRestoreDecksTitle": "{count, plural, =1{Restore 1 deck to…} other{Restore {count} decks to…}}",
+  "@trashRestoreDecksTitle": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 restore sheet title for selected decks."
+  },
+  "trashRestoreCardsRule": "Its schedule, history, flag and tags come back with it. Only decks in the same tree that hold cards or are empty are offered.",
+  "@trashRestoreCardsRule": {
+    "description": "Screen 06 restore sheet rule for cards (kit 06, BR-TRASH-006)."
+  },
+  "trashRestoreDecksRule": "Its sub-decks and cards come back with it, schedules and history included. Only decks that could take it by a move are offered.",
+  "@trashRestoreDecksRule": {
+    "description": "Screen 06 restore sheet rule for sub-decks (BR-TRASH-006; the kit draws only cards)."
+  },
+  "trashRestoreRootsRule": "A top-level deck goes back to the top level, with everything in it.",
+  "@trashRestoreRootsRule": {
+    "description": "Screen 06 restore sheet rule for top-level decks (BR-TRASH-006)."
+  },
+  "trashRestoreEmptyTitle": "Nowhere to restore right now",
+  "@trashRestoreEmptyTitle": {
+    "description": "Screen 06 restore sheet with no target (UC-TRASH-001 E1)."
+  },
+  "trashRestoreNoCardTargetBody": "No deck in “{root}” can hold cards at the moment. Create an empty sub-deck there, then restore.",
+  "@trashRestoreNoCardTargetBody": {
+    "placeholders": {
+      "root": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06 restore sheet with no card target (kit 06 noTarget); root is the top-level deck the cards came from."
+  },
+  "trashRestoreNoDeckTargetBody": "No deck can take it at the moment. Restore or create the deck it goes under first, then restore.",
+  "@trashRestoreNoDeckTargetBody": {
+    "description": "Screen 06 restore sheet with no deck target (UC-TRASH-001 E1)."
+  },
+  "trashRestoredOne": "“{name}” restored to {deck}",
+  "@trashRestoredOne": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      },
+      "deck": {
+        "type": "String"
+      }
+    },
+    "description": "Snackbar after one entry is restored (kit 06 restored)."
+  },
+  "trashRestoredMany": "{count, plural, =1{1 entry restored to {deck}} other{{count} entries restored to {deck}}}",
+  "@trashRestoredMany": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      },
+      "deck": {
+        "type": "String"
+      }
+    },
+    "description": "Snackbar after several entries are restored."
+  },
   "libraryDueTitle": "{count, plural, =1{1 card due} other{{count} cards due}}",
   "@libraryDueTitle": {
     "placeholders": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 8e2afa8..c557045 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -303,6 +303,17 @@
   "trashEmptyTitle": "Thùng rác trống",
   "trashEmptyBody": "Bộ thẻ và thẻ bạn xoá được giữ ở đây 30 ngày trước khi bị xoá hẳn.",
   "trashLoadErrorTitle": "Không mở được Thùng rác",
+  "trashRestoreOneTitle": "Khôi phục “{name}” về…",
+  "trashRestoreCardsTitle": "{count, plural, other{Khôi phục {count} thẻ về…}}",
+  "trashRestoreDecksTitle": "{count, plural, other{Khôi phục {count} bộ thẻ về…}}",
+  "trashRestoreCardsRule": "Lịch ôn, lịch sử, cờ và tag trở lại cùng thẻ. Chỉ các bộ thẻ cùng cây đang chứa thẻ hoặc còn trống được đưa ra.",
+  "trashRestoreDecksRule": "Bộ thẻ con và thẻ trở lại cùng nó, kể cả lịch ôn và lịch sử. Chỉ các bộ thẻ có thể nhận nó khi di chuyển được đưa ra.",
+  "trashRestoreRootsRule": "Bộ thẻ cấp cao nhất trở lại cấp cao nhất, cùng mọi thứ bên trong.",
+  "trashRestoreEmptyTitle": "Chưa có chỗ để khôi phục",
+  "trashRestoreNoCardTargetBody": "Chưa có bộ thẻ nào trong “{root}” chứa được thẻ. Hãy tạo một bộ thẻ con trống ở đó rồi khôi phục.",
+  "trashRestoreNoDeckTargetBody": "Chưa có bộ thẻ nào nhận được nó. Hãy khôi phục hoặc tạo bộ thẻ cha trước rồi khôi phục.",
+  "trashRestoredOne": "Đã khôi phục “{name}” về {deck}",
+  "trashRestoredMany": "{count, plural, other{Đã khôi phục {count} mục về {deck}}}",
   "libraryDueTitle": "{count} thẻ đến hạn",
   "libraryDecksCount": "{count} bộ thẻ",
   "libraryDueDecksHeader": "Bộ thẻ có thẻ đến hạn",
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/trash
flutter test test/features/trash test/l10n
flutter analyze
bash tools/check_architecture.sh
```

Expected: PASS, and the architecture check is clean: `trash` imports no `card` or `deck`
presentation. Four new goldens:
- `trash_restore_target_*` with `restoreTarget-*`: "Restore “meokda · eat” to…", the
  rule, and the targets as paths (Q3);
- `trash_no_target_*` with `noTarget-*`: "Nowhere to restore right now", the body naming
  the root, and OK.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/trash/presentation/providers/trash_restore_targets_provider.dart \
  lib/features/trash/presentation/screens/trash_screen.dart \
  lib/features/trash/presentation/states/trash_state.dart \
  lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart \
  lib/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/trash/presentation/trash_golden_test.dart \
  test/features/trash/presentation/trash_rejection_message_test.dart \
  test/features/trash/presentation/trash_restore_test.dart \
  test/features/trash/presentation/goldens/trash_no_target_dark.png \
  test/features/trash/presentation/goldens/trash_no_target_light.png \
  test/features/trash/presentation/goldens/trash_restore_target_dark.png \
  test/features/trash/presentation/goldens/trash_restore_target_light.png
git commit -m "$(cat <<'EOF'
feat(trash): restore asks where each entry goes (FE-B1, UC-TRASH-001 steps 5-7)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: Selection and delete for good

**Files:**
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart`
- Create: `lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart`
- Create: `lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart`
- Modify: `lib/features/trash/presentation/widgets/support/trash_labels_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/shared/widgets/mx_button.dart`
- Modify: `test/features/trash/presentation/goldens/trash_actions_dark.png`
- Modify: `test/features/trash/presentation/goldens/trash_actions_light.png`
- Modify: `test/features/trash/presentation/goldens/trash_all_dark.png`
- Modify: `test/features/trash/presentation/goldens/trash_all_light.png`
- Modify: `test/features/trash/presentation/goldens/trash_no_target_dark.png`
- Modify: `test/features/trash/presentation/goldens/trash_no_target_light.png`
- Create: `test/features/trash/presentation/goldens/trash_purge_blocked_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_purge_blocked_light.png`
- Create: `test/features/trash/presentation/goldens/trash_purge_confirm_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_purge_confirm_light.png`
- Modify: `test/features/trash/presentation/goldens/trash_restore_target_dark.png`
- Modify: `test/features/trash/presentation/goldens/trash_restore_target_light.png`
- Create: `test/features/trash/presentation/goldens/trash_selection_dark.png`
- Create: `test/features/trash/presentation/goldens/trash_selection_light.png`
- Test (modify): `test/features/trash/presentation/trash_golden_test.dart`
- Test (create): `test/features/trash/presentation/trash_selection_test.dart`
- Test (modify): `test/shared/widgets/mx_button_test.dart`
- Test (modify): `test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 1's `startSelecting`, `stopSelecting`, `toggle`, `purge` and
  `TrashState.blocked`; Task 3's `showTrashRestoreSheet`.
- Produces:
  - `MxButton(isAutofocused: bool = false)`, which takes the focus when it shows;
  - `showTrashPurgeDialog(context, {required List<TrashEntry> entries}) →
    Future<bool>`, which runs the purge itself (Q4);
  - `TrashSelectionBarWidget({required int count, required VoidCallback onRestore,
    required VoidCallback onPurge})`;
  - `trashNamesSeparator` in the labels.

- [ ] **Step 1: Write the failing tests**

`test/features/trash/presentation/trash_golden_test.dart` (apply this diff):

```diff
diff --git a/test/features/trash/presentation/trash_golden_test.dart b/test/features/trash/presentation/trash_golden_test.dart
index e2bff13..59a2135 100644
--- a/test/features/trash/presentation/trash_golden_test.dart
+++ b/test/features/trash/presentation/trash_golden_test.dart
@@ -7,6 +7,8 @@ import 'package:memox/features/trash/presentation/providers/trash_entries_provid
 import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 
+import '../../../support/card_fixtures.dart';
+import '../../../support/deck_fixtures.dart';
 import '../../../support/golden_harness.dart';
 import '../../../support/library_harness.dart';
 import '../../../support/trash_screen_fixtures.dart';
@@ -25,6 +27,16 @@ Future<void> _openRestore(WidgetTester tester, String name) async {
   await _settle(tester);
 }
 
+/// Selects the two cards of [seedTrash].
+Future<void> _selectCards(WidgetTester tester) async {
+  await tester.tap(find.text(_en.trashSelect));
+  await _settle(tester);
+  await tester.tap(find.text('meokda · eat'));
+  await _settle(tester);
+  await tester.tap(find.text('homework · bai tap'));
+  await _settle(tester);
+}
+
 void main() {
   for (final brightness in Brightness.values) {
     final theme = brightness.name;
@@ -72,6 +84,61 @@ void main() {
       });
     });
 
+    libraryTest('trash selection, $theme', (tester, env) async {
+      await seedTrash(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
+        await _selectCards(tester);
+        await expectBoundaryGolden(
+          tester,
+          'goldens/trash_selection_$theme.png',
+        );
+      });
+    });
+
+    libraryTest('trash purge confirm, $theme', (tester, env) async {
+      await seedTrash(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
+        await _selectCards(tester);
+        await tester.tap(find.text(_en.trashPurgeSelected));
+        await _settle(tester);
+        await expectBoundaryGolden(
+          tester,
+          'goldens/trash_purge_confirm_$theme.png',
+        );
+      });
+    });
+
+    libraryTest('trash purge blocked, $theme', (tester, env) async {
+      // Korean › Food: its card goes first, then the deck, which so holds
+      // an older entry (invariant 36).
+      final korean = await env.decks.root('Korean');
+      final food = await env.decks.sub(korean.id, 'Food');
+      await insertCard(env.db, id: 'rice', deckId: food.id, front: 'bap');
+      await env.cards.deleteCards(
+        cardIds: {'rice'},
+        now: libraryToday.subtract(const Duration(days: 3)),
+      );
+      await env.decks.deleteDeck(
+        deckId: food.id,
+        now: libraryToday.subtract(const Duration(days: 2)),
+      );
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
+        await tester.tap(find.byTooltip(_en.trashEntryActions('Food')));
+        await _settle(tester);
+        await tester.tap(find.text(_en.trashDeletePermanently));
+        await _settle(tester);
+        await tester.tap(find.text(_en.trashPurgeConfirm(1)));
+        await tester.pumpAndSettle();
+        await expectBoundaryGolden(
+          tester,
+          'goldens/trash_purge_blocked_$theme.png',
+        );
+      });
+    });
+
     libraryTest('trash empty, $theme', (tester, env) async {
       await withRealShadows(() async {
         await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
```

`test/features/trash/presentation/trash_selection_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
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
  libraryTest('Select starts with nothing chosen; the first pick locks the '
      'kind (BR-TRASH-011)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _tap(tester, _button(_en.trashSelect));

    expect(find.text(_en.trashSelectTitle), findsOneWidget);
    expect(find.byType(MxFilterChip), findsNothing);
    final restore = tester.widget<MxButton>(
      _button(_en.trashRestoreSelected(0)),
    );
    expect(restore.onPressed, isNull);

    await _tap(tester, find.text('meokda · eat'));
    expect(find.text(_en.trashCardsSelected(1)), findsOneWidget);
    expect(
      find.text(_en.trashSelectedOfCards(1, 2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_en.trashCardsOnly), findsOneWidget);

    // A deck cannot join a selection of cards.
    await _tap(tester, find.text('Basics'));
    expect(find.text(_en.trashCardsSelected(1)), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.trashSelectionClose));
    expect(find.text(_en.libraryTrash), findsOneWidget);
    expect(find.byType(MxFilterChip), findsNWidgets(3));
  });

  libraryTest('a long-press starts the selection with its entry (spec D8)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.longPress(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text(_en.trashDecksSelected(1)), findsOneWidget);
    expect(find.text(_en.trashDecksOnly), findsOneWidget);
  });

  libraryTest('Restore 2… asks one target for both, then ends the selection '
      '(UC-TRASH-001 A2)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    await _tap(tester, _button(_en.trashRestoreSelected(2)));
    expect(find.text(_en.trashRestoreCardsTitle(2)), findsOneWidget);
    await _tap(tester, find.text('Korean › Words'));

    expect(find.text(_en.trashRestoredMany(2, 'Words')), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text(_en.libraryTrash), findsOneWidget);
  });

  libraryTest('Delete for good names the count, focuses Keep in Trash, and '
      'deletes only on its own button (BR-TRASH-011)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected));

    expect(find.text(_en.trashPurgeCardsTitle(2)), findsOneWidget);
    expect(find.text(_en.trashPurgeBody(2)), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      focused.findAncestorWidgetOfExactType<MxButton>()?.label,
      _en.trashPurgeKeep,
    );

    await _tap(tester, _inDialog(_en.trashPurgeKeep));
    expect(find.text('meokda · eat'), findsOneWidget);

    await _tap(tester, _button(_en.trashPurgeSelected));
    await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text('homework · bai tap'), findsNothing);
  });

  libraryTest('a purge the store skips names what it still holds (spec D6)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final food = await env.decks.sub(korean.id, 'Food');
    await insertCard(
      env.db,
      id: 'rice',
      deckId: food.id,
      front: 'bap',
      back: 'rice',
    );
    // The card goes first, then its deck: the deck holds an older entry.
    await env.cards.deleteCards(
      cardIds: {'rice'},
      now: libraryToday.subtract(const Duration(days: 2)),
    );
    await env.decks.deleteDeck(
      deckId: food.id,
      now: libraryToday.subtract(const Duration(days: 1)),
    );
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await _tap(tester, find.byTooltip(_en.trashEntryActions('Food')));
    await _tap(tester, find.text(_en.trashDeletePermanently));
    expect(find.text(_en.trashPurgeDecksTitle(1)), findsOneWidget);
    await _tap(tester, _inDialog(_en.trashPurgeConfirm(1)));

    expect(find.text('Food'), findsOneWidget);
    expect(find.text(_en.trashPurgedDecks(1)), findsNothing);
    expect(
      find.text(_en.trashPurgeBlocked('Food', 'bap · rice')),
      findsOneWidget,
    );
  });
}
```

`test/shared/widgets/mx_button_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_button_test.dart b/test/shared/widgets/mx_button_test.dart
index 518a14e..a60e052 100644
--- a/test/shared/widgets/mx_button_test.dart
+++ b/test/shared/widgets/mx_button_test.dart
@@ -102,6 +102,27 @@ void main() {
     );
   });
 
+  testWidgets('isAutofocused takes the focus when it shows', (tester) async {
+    await pumpMx(
+      tester,
+      Column(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          MxButton(label: 'Delete', onPressed: () {}),
+          MxButton(label: 'Keep', onPressed: () {}, isAutofocused: true),
+        ],
+      ),
+    );
+    await tester.pump();
+
+    final focused = FocusManager.instance.primaryFocus!.context!;
+    expect(
+      find.ancestor(of: find.text('Keep'), matching: find.byType(TextButton)),
+      findsOneWidget,
+    );
+    expect(focused.findAncestorWidgetOfExactType<MxButton>()?.label, 'Keep');
+  });
+
   testWidgets('a tap calls onPressed', (tester) async {
     var taps = 0;
     await pumpMx(tester, MxButton(label: 'Go', onPressed: () => taps++));
```

`test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart` (apply this diff):

```diff
diff --git a/test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart b/test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart
index 8056ecd..a1044b1 100644
--- a/test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart
+++ b/test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart
@@ -1,10 +1,14 @@
+import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
+import 'package:memox/l10n/generated/app_localizations.dart';
 
 import '../../../../../support/library_harness.dart';
 import '../../../../../support/trash_screen_fixtures.dart';
 import '../../../../screen_audit.dart';
 
+final _en = lookupAppLocalizations(const Locale('en'));
+
 void main() {
   libraryTest('screen 06, the list', (tester, env) async {
     await seedTrash(env);
@@ -20,4 +24,27 @@ void main() {
       ),
     );
   });
+
+  libraryTest('screen 06, selecting', (tester, env) async {
+    await seedTrash(env);
+    await auditProductionScreen(
+      tester,
+      screen: TrashScreen,
+      pump: (brightness, scale) async {
+        await pumpLibraryScreen(
+          tester,
+          env,
+          const TrashScreen(),
+          brightness: brightness,
+          textScale: scale,
+        );
+        // The scope outlives a re-pump: select only the first time.
+        if (find.text(_en.trashSelect).evaluate().isEmpty) return;
+        await tester.tap(find.text(_en.trashSelect));
+        await tester.pumpAndSettle();
+        await tester.tap(find.text('meokda · eat'));
+        await tester.pumpAndSettle();
+      },
+    );
+  });
 }
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/shared/widgets/mx_button_test.dart test/features/trash/presentation/trash_selection_test.dart
```

Expected: FAIL to compile: `MxButton` has no `isAutofocused`, and
`trash_purge_dialog_widget.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/trash/presentation/screens/trash_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/trash/presentation/screens/trash_screen.dart b/lib/features/trash/presentation/screens/trash_screen.dart
index ed8be80..bbe7d92 100644
--- a/lib/features/trash/presentation/screens/trash_screen.dart
+++ b/lib/features/trash/presentation/screens/trash_screen.dart
@@ -12,6 +12,11 @@ import 'package:memox/features/trash/presentation/states/trash_state.dart';
 import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
 import 'package:memox/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart';
 import 'package:memox/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart';
+import 'package:memox/shared/widgets/mx_inline_banner.dart';
+import 'package:memox/shared/widgets/mx_button.dart';
+import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
+import 'package:memox/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart';
+import 'package:memox/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
@@ -50,7 +55,7 @@ class _TrashScreenState extends ConsumerState<TrashScreen> {
       case TrashEntryAction.restore:
         await showTrashRestoreSheet(context, entries: [entry]);
       case TrashEntryAction.purge:
-        break;
+        await showTrashPurgeDialog(context, entries: [entry]);
     }
   }
 
@@ -58,8 +63,75 @@ class _TrashScreenState extends ConsumerState<TrashScreen> {
   Widget build(BuildContext context) {
     final l10n = context.l10n;
     final entries = ref.watch(trashEntriesProvider);
-    return MxAppShell(
-      appBar: MxAppBar(
+    final state = ref.watch(trashControllerProvider);
+    final loaded = entries.value ?? const <TrashEntry>[];
+    final selected = [
+      for (final entry in loaded)
+        if (state.selected.contains(entry.batchId)) entry,
+    ];
+    // Back leaves selection before it leaves the Trash.
+    return PopScope(
+      canPop: !state.isSelecting,
+      onPopInvokedWithResult: (didPop, _) {
+        if (!didPop) _trash().stopSelecting();
+      },
+      child: MxAppShell(
+        appBar: _appBar(l10n, state, loaded),
+        footer: state.isSelecting
+            ? TrashSelectionBarWidget(
+                count: selected.length,
+                onRestore: () => unawaited(
+                  showTrashRestoreSheet(context, entries: selected),
+                ),
+                onPurge: () =>
+                    unawaited(showTrashPurgeDialog(context, entries: selected)),
+              )
+            : null,
+        body: switch (entries) {
+          AsyncData(:final value) when value.isEmpty => MxScreenScroll(
+            children: [
+              MxEmptyState(
+                icon: AppIcons.delete,
+                title: l10n.trashEmptyTitle,
+                body: l10n.trashEmptyBody,
+              ),
+            ],
+          ),
+          AsyncData(:final value) => MxScreenScroll(
+            children: _list(l10n, value),
+          ),
+          AsyncError() => MxScreenScroll(
+            children: [
+              MxErrorState(
+                title: l10n.trashLoadErrorTitle,
+                body: l10n.libraryLoadErrorBody,
+                retryLabel: l10n.commonRetry,
+                onRetry: () => ref.invalidate(trashEntriesProvider),
+              ),
+            ],
+          ),
+          _ => MxScreenScroll(
+            children: [
+              MxSkeletonList(
+                semanticLabel: l10n.commonLoading,
+                rows: _skeletonRows,
+              ),
+            ],
+          ),
+        },
+      ),
+    );
+  }
+
+  /// Back, "Trash" and Select; while selecting, close and the count of the
+  /// kind picked (kit 06 selection).
+  MxAppBar _appBar(
+    AppLocalizations l10n,
+    TrashState state,
+    List<TrashEntry> entries,
+  ) {
+    if (!state.isSelecting) {
+      return MxAppBar(
         title: l10n.libraryTrash,
         density: MxAppBarDensity.content,
         leading: MxIconButton(
@@ -67,68 +139,124 @@ class _TrashScreenState extends ConsumerState<TrashScreen> {
           semanticLabel: l10n.commonBack,
           onPressed: () => unawaited(Navigator.of(context).maybePop()),
         ),
-      ),
-      body: switch (entries) {
-        AsyncData(:final value) when value.isEmpty => MxScreenScroll(
-          children: [
-            MxEmptyState(
-              icon: AppIcons.delete,
-              title: l10n.trashEmptyTitle,
-              body: l10n.trashEmptyBody,
-            ),
-          ],
-        ),
-        AsyncData(:final value) => MxScreenScroll(children: _list(l10n, value)),
-        AsyncError() => MxScreenScroll(
-          children: [
-            MxErrorState(
-              title: l10n.trashLoadErrorTitle,
-              body: l10n.libraryLoadErrorBody,
-              retryLabel: l10n.commonRetry,
-              onRetry: () => ref.invalidate(trashEntriesProvider),
+        actions: [
+          if (entries.isNotEmpty)
+            MxButton(
+              label: l10n.trashSelect,
+              size: MxButtonSize.compact,
+              tone: MxButtonTone.secondary,
+              onPressed: _trash().startSelecting,
             ),
-          ],
-        ),
-        _ => MxScreenScroll(
-          children: [
-            MxSkeletonList(
-              semanticLabel: l10n.commonLoading,
-              rows: _skeletonRows,
-            ),
-          ],
-        ),
+        ],
+      );
+    }
+    final count = state.selected.length;
+    return MxAppBar(
+      title: switch (state.kindIn(entries)) {
+        null => l10n.trashSelectTitle,
+        TrashKind.card => l10n.trashCardsSelected(count),
+        TrashKind.deck => l10n.trashDecksSelected(count),
       },
+      density: MxAppBarDensity.content,
+      leading: MxIconButton(
+        icon: AppIcons.close,
+        semanticLabel: l10n.trashSelectionClose,
+        onPressed: _trash().stopSelecting,
+      ),
     );
   }
 
-  /// The note, the filters with their counts (A6), the header, the rows.
+  /// The note, the filters with their counts (A6, none while selecting),
+  /// the header, the rows, then why the other kind waits and what a purge
+  /// skipped (spec D6).
   List<Widget> _list(AppLocalizations l10n, List<TrashEntry> entries) {
     final state = ref.watch(trashControllerProvider);
     final now = ref.watch(dayClockProvider).now();
     final shown = entries.where(state.filter.accepts).toList();
+    final kind = state.kindIn(entries);
     return [
       const SizedBox(height: AppSpacing.control),
       MxNote(icon: AppIcons.history, text: l10n.trashNote),
       const SizedBox(height: AppSpacing.grouped),
-      _Filters(
-        selected: state.filter,
-        entries: entries,
-        onSelected: _trash().chooseFilter,
-      ),
+      if (!state.isSelecting)
+        _Filters(
+          selected: state.filter,
+          entries: entries,
+          onSelected: _trash().chooseFilter,
+        ),
       MxListSectionHeader(
-        label: l10n.trashEntriesHeader(shown.length),
-        isAfterFilterBand: true,
+        label: _header(l10n, state, shown, kind),
+        isAfterFilterBand: !state.isSelecting,
       ),
       for (final entry in shown)
         TrashEntryRowWidget(
           key: ValueKey(entry.batchId),
           entry: entry,
           now: now,
-          onTap: () => unawaited(_openActions(entry)),
+          isSelecting: state.isSelecting,
+          isSelected: state.selected.contains(entry.batchId),
+          onTap: switch (state.isSelecting) {
+            false => () => unawaited(_openActions(entry)),
+            // The other kind cannot be picked (BR-TRASH-011).
+            true when kind != null && kind != TrashKind.of(entry) => null,
+            true => () => _trash().toggle(entry, entries),
+          },
+          onLongPress: state.isSelecting
+              ? null
+              : () => _trash().toggle(entry, entries),
           onActions: () => unawaited(_openActions(entry)),
         ),
+      if (kind != null)
+        MxNote(
+          text: kind == TrashKind.card
+              ? l10n.trashCardsOnly
+              : l10n.trashDecksOnly,
+        ),
+      for (final note in _blockedNotes(l10n, state, entries))
+        Padding(
+          padding: const EdgeInsets.only(top: AppSpacing.control),
+          child: MxInlineBanner(tone: MxBannerTone.warning, message: note),
+        ),
     ];
   }
+
+  String _header(
+    AppLocalizations l10n,
+    TrashState state,
+    List<TrashEntry> shown,
+    TrashKind? kind,
+  ) {
+    int total(TrashKind of) =>
+        shown.where((entry) => TrashKind.of(entry) == of).length;
+    final count = state.selected.length;
+    return switch (kind) {
+      TrashKind.card => l10n.trashSelectedOfCards(count, total(TrashKind.card)),
+      TrashKind.deck => l10n.trashSelectedOfDecks(count, total(TrashKind.deck)),
+      null => l10n.trashEntriesHeader(shown.length),
+    };
+  }
+
+  /// One sentence per batch the last purge skipped and still in the Trash,
+  /// naming what it still holds (spec D6).
+  Iterable<String> _blockedNotes(
+    AppLocalizations l10n,
+    TrashState state,
+    List<TrashEntry> entries,
+  ) sync* {
+    final byBatch = {for (final entry in entries) entry.batchId: entry};
+    for (final MapEntry(key: batchId, value: inner) in state.blocked.entries) {
+      final blocked = byBatch[batchId];
+      final names = [
+        for (final id in inner)
+          if (byBatch[id] case final entry?) trashEntryName(entry),
+      ];
+      if (blocked == null || names.isEmpty) continue;
+      yield l10n.trashPurgeBlocked(
+        trashEntryName(blocked),
+        names.join(trashNamesSeparator),
+      );
+    }
+  }
 }
 
 /// All · Cards · Decks, each with its count (kit 06).
```

`lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before [entries], all of one kind, are deleted for good
/// (UC-TRASH-001 A3). Completes true once the purge ran; the batches the
/// store skipped are the screen's to name (spec D6).
Future<bool> showTrashPurgeDialog(
  BuildContext context, {
  required List<TrashEntry> entries,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => TrashPurgeDialogWidget(entries: entries),
    ) ??
    false;

/// The strong confirmation of BR-TRASH-011: the exact count, the lost
/// history, the focus on Keep in Trash, the destructive tone on Delete only.
/// Delete spins while the batches go (spec D15).
class TrashPurgeDialogWidget extends ConsumerStatefulWidget {
  const TrashPurgeDialogWidget({super.key, required this.entries});

  final List<TrashEntry> entries;

  @override
  ConsumerState<TrashPurgeDialogWidget> createState() =>
      _TrashPurgeDialogWidgetState();
}

class _TrashPurgeDialogWidgetState
    extends ConsumerState<TrashPurgeDialogWidget> {
  /// Kit 06: Keep in Trash 1.2, Delete 1.
  static const int _keepShare = 12;
  static const int _deleteShare = 10;

  var _isPurging = false;

  bool get _isCards => widget.entries.first is TrashCardEntry;

  Future<void> _purge() async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isPurging) return;
    setState(() => _isPurging = true);
    try {
      final report = await ref.read(trashControllerProvider.notifier).purge({
        for (final entry in widget.entries) entry.batchId,
      });
      if (!mounted) return;
      final purged = report.purged.length;
      if (purged > 0) {
        final l10n = context.l10n;
        showMxSnackbar(
          context,
          message: _isCards
              ? l10n.trashPurgedCards(purged)
              : l10n.trashPurgedDecks(purged),
        );
      }
      Navigator.of(context).pop(true);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isPurging = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = widget.entries.length;
    return MxDialog(
      title: _isCards
          ? l10n.trashPurgeCardsTitle(count)
          : l10n.trashPurgeDecksTitle(count),
      body: l10n.trashPurgeBody(count),
      actions: MxSheetActions.custom(
        children: [
          Expanded(
            flex: _keepShare,
            child: MxButton(
              label: l10n.trashPurgeKeep,
              onPressed: () => Navigator.of(context).pop(false),
              isBlock: true,
              isAutofocused: true,
            ),
          ),
          Expanded(
            flex: _deleteShare,
            child: MxButton(
              label: l10n.trashPurgeConfirm(count),
              icon: AppIcons.delete,
              tone: MxButtonTone.destructive,
              isBlock: true,
              isLoading: _isPurging,
              onPressed: _purge,
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Screen 06's bar while selecting: Restore the selection after asking
/// where, or delete it for good (UC-TRASH-001 A2). Both wait for a pick.
class TrashSelectionBarWidget extends StatelessWidget {
  const TrashSelectionBarWidget({
    super.key,
    required this.count,
    required this.onRestore,
    required this.onPurge,
  });

  final int count;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  /// Kit 06: Restore 1.3, Delete for good 1.
  static const int _restoreShare = 13;
  static const int _purgeShare = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPick = count > 0;
    return MxFooterBar(
      child: Row(
        spacing: AppSpacing.control,
        children: [
          Expanded(
            flex: _restoreShare,
            child: MxButton(
              label: l10n.trashRestoreSelected(count),
              icon: AppIcons.restore,
              isBlock: true,
              onPressed: hasPick ? onRestore : null,
            ),
          ),
          Expanded(
            flex: _purgeShare,
            child: MxButton(
              label: l10n.trashPurgeSelected,
              icon: AppIcons.delete,
              tone: MxButtonTone.destructive,
              isBlock: true,
              onPressed: hasPick ? onPurge : null,
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/trash/presentation/widgets/support/trash_labels_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/trash/presentation/widgets/support/trash_labels_widget.dart b/lib/features/trash/presentation/widgets/support/trash_labels_widget.dart
index af68ec0..2b822c4 100644
--- a/lib/features/trash/presentation/widgets/support/trash_labels_widget.dart
+++ b/lib/features/trash/presentation/widgets/support/trash_labels_widget.dart
@@ -8,6 +8,9 @@ const String trashPathSeparator = ' › ';
 /// Between a card's front and back in its name (kit 06).
 const String trashSidesSeparator = ' · ';
 
+/// Between the names of the entries a blocked purge still holds.
+const String trashNamesSeparator = ', ';
+
 /// Under this much time left, the row says so in the warning ink (kit 06).
 const Duration trashExpiringSoon = Duration(days: 3);
 
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index b26d43a..7731c06 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1595,6 +1595,147 @@
     },
     "description": "Snackbar after several entries are restored."
   },
+  "trashSelectTitle": "Select entries",
+  "@trashSelectTitle": {
+    "description": "Screen 06 app bar while selecting, before anything is chosen."
+  },
+  "trashCardsSelected": "{count, plural, =1{1 card selected} other{{count} cards selected}}",
+  "@trashCardsSelected": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 app bar while cards are selected (kit 06 selection)."
+  },
+  "trashDecksSelected": "{count, plural, =1{1 deck selected} other{{count} decks selected}}",
+  "@trashDecksSelected": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 app bar while decks are selected."
+  },
+  "trashSelectedOfCards": "{count} of {total} cards",
+  "@trashSelectedOfCards": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      },
+      "total": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 list header while cards are selected."
+  },
+  "trashSelectedOfDecks": "{count} of {total} decks",
+  "@trashSelectedOfDecks": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      },
+      "total": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 list header while decks are selected."
+  },
+  "trashSelectionClose": "Clear selection",
+  "@trashSelectionClose": {
+    "description": "Screen 06: the close control while selecting."
+  },
+  "trashCardsOnly": "Only cards are selectable while cards are selected — a selection never mixes cards and decks.",
+  "@trashCardsOnly": {
+    "description": "Screen 06: why decks cannot be picked (BR-TRASH-011)."
+  },
+  "trashDecksOnly": "Only decks are selectable while decks are selected — a selection never mixes cards and decks.",
+  "@trashDecksOnly": {
+    "description": "Screen 06: why cards cannot be picked (BR-TRASH-011)."
+  },
+  "trashRestoreSelected": "Restore {count}…",
+  "@trashRestoreSelected": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 selection bar: restores the selection after asking for a target."
+  },
+  "trashPurgeSelected": "Delete for good",
+  "@trashPurgeSelected": {
+    "description": "Screen 06 selection bar: purges the selection after the dialog (BR-TRASH-010)."
+  },
+  "trashPurgeCardsTitle": "{count, plural, =1{Delete 1 card permanently?} other{Delete {count} cards permanently?}}",
+  "@trashPurgeCardsTitle": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 purge dialog title for cards (BR-TRASH-011: the exact count)."
+  },
+  "trashPurgeDecksTitle": "{count, plural, =1{Delete 1 deck permanently?} other{Delete {count} decks permanently?}}",
+  "@trashPurgeDecksTitle": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 purge dialog title for decks."
+  },
+  "trashPurgeBody": "{count, plural, =1{It disappears for good, together with its study history. This cannot be undone.} other{They disappear for good, together with their study history. This cannot be undone.}}",
+  "@trashPurgeBody": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 purge dialog body (BR-TRASH-011: history is lost)."
+  },
+  "trashPurgeKeep": "Keep in Trash",
+  "@trashPurgeKeep": {
+    "description": "Screen 06 purge dialog: the safe choice, focused by default (BR-TRASH-011)."
+  },
+  "trashPurgeConfirm": "Delete {count}",
+  "@trashPurgeConfirm": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Screen 06 purge dialog: the destructive confirm."
+  },
+  "trashPurgedCards": "{count, plural, =1{1 card deleted permanently} other{{count} cards deleted permanently}}",
+  "@trashPurgedCards": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Snackbar after a purge of cards (kit 06 purged)."
+  },
+  "trashPurgedDecks": "{count, plural, =1{1 deck deleted permanently} other{{count} decks deleted permanently}}",
+  "@trashPurgedDecks": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Snackbar after a purge of decks."
+  },
+  "trashPurgeBlocked": "“{deck}” still contains an entry deleted earlier (“{entries}”). It can be removed for good once that entry is gone.",
+  "@trashPurgeBlocked": {
+    "placeholders": {
+      "deck": {
+        "type": "String"
+      },
+      "entries": {
+        "type": "String"
+      }
+    },
+    "description": "Screen 06: a purge the store skipped (spec D6; the kit's youngerInside says 'later', invariant 36 allows only 'earlier')."
+  },
   "libraryDueTitle": "{count, plural, =1{1 card due} other{{count} cards due}}",
   "@libraryDueTitle": {
     "placeholders": {
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index c557045..049359b 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -314,6 +314,24 @@
   "trashRestoreNoDeckTargetBody": "Chưa có bộ thẻ nào nhận được nó. Hãy khôi phục hoặc tạo bộ thẻ cha trước rồi khôi phục.",
   "trashRestoredOne": "Đã khôi phục “{name}” về {deck}",
   "trashRestoredMany": "{count, plural, other{Đã khôi phục {count} mục về {deck}}}",
+  "trashSelectTitle": "Chọn mục",
+  "trashCardsSelected": "{count, plural, other{Đã chọn {count} thẻ}}",
+  "trashDecksSelected": "{count, plural, other{Đã chọn {count} bộ thẻ}}",
+  "trashSelectedOfCards": "{count} trên {total} thẻ",
+  "trashSelectedOfDecks": "{count} trên {total} bộ thẻ",
+  "trashSelectionClose": "Bỏ chọn",
+  "trashCardsOnly": "Khi đang chọn thẻ thì chỉ chọn được thẻ — một lựa chọn không trộn thẻ và bộ thẻ.",
+  "trashDecksOnly": "Khi đang chọn bộ thẻ thì chỉ chọn được bộ thẻ — một lựa chọn không trộn thẻ và bộ thẻ.",
+  "trashRestoreSelected": "Khôi phục {count}…",
+  "trashPurgeSelected": "Xoá hẳn",
+  "trashPurgeCardsTitle": "{count, plural, other{Xoá vĩnh viễn {count} thẻ?}}",
+  "trashPurgeDecksTitle": "{count, plural, other{Xoá vĩnh viễn {count} bộ thẻ?}}",
+  "trashPurgeBody": "{count, plural, other{Chúng biến mất hẳn, cùng lịch sử học. Không thể hoàn tác.}}",
+  "trashPurgeKeep": "Giữ trong Thùng rác",
+  "trashPurgeConfirm": "Xoá {count}",
+  "trashPurgedCards": "{count, plural, other{Đã xoá vĩnh viễn {count} thẻ}}",
+  "trashPurgedDecks": "{count, plural, other{Đã xoá vĩnh viễn {count} bộ thẻ}}",
+  "trashPurgeBlocked": "“{deck}” vẫn chứa một mục đã xoá trước đó (“{entries}”). Có thể xoá hẳn khi mục đó không còn.",
   "libraryDueTitle": "{count} thẻ đến hạn",
   "libraryDecksCount": "{count} bộ thẻ",
   "libraryDueDecksHeader": "Bộ thẻ có thẻ đến hạn",
```

`lib/shared/widgets/mx_button.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_button.dart b/lib/shared/widgets/mx_button.dart
index b322936..2329ef8 100644
--- a/lib/shared/widgets/mx_button.dart
+++ b/lib/shared/widgets/mx_button.dart
@@ -38,6 +38,7 @@ class MxButton extends StatelessWidget {
     this.icon,
     this.isBlock = false,
     this.isLoading = false,
+    this.isAutofocused = false,
   });
 
   final String label;
@@ -54,6 +55,10 @@ class MxButton extends StatelessWidget {
   /// Replaces the label with a spinner, keeps the width and blocks presses.
   final bool isLoading;
 
+  /// Takes the focus when it first shows: the safe choice of a destructive
+  /// dialog (BR-TRASH-011).
+  final bool isAutofocused;
+
   /// A caller-constrained label wraps to at most this many lines.
   static const int _maxWrappedLines = 2;
 
@@ -66,6 +71,7 @@ class MxButton extends StatelessWidget {
     final geometry = _geometryFor(size, hasIcon: icon != null);
     final button = TextButton(
       onPressed: isLoading ? null : onPressed,
+      autofocus: isAutofocused,
       style: appButtonStyle(
         fill: paint.fill,
         ink: paint.ink,
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/trash test/visual_audit/screens/features/trash
flutter test test/shared test/features/trash test/visual_audit
flutter analyze
```

Expected: PASS. Six new goldens and eight changed:
- `trash_selection_*` with `selection-*`: close, "2 cards selected", the checkboxes,
  the deck row dimmed, the kind-lock note, and "Restore 2…" · "Delete for good";
- `trash_purge_confirm_*` with `purgeConfirm-*`: "Delete 2 cards permanently?", "Keep in
  Trash" (primary) and "Delete 2" (destructive);
- `trash_purge_blocked_*` with `youngerInside-*`: the warning banner naming what the
  deck still holds (D6);
- `trash_all_*`, `trash_actions_*`, `trash_restore_target_*` and `trash_no_target_*`
  change only by the "Select" button in the app bar.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/trash/presentation/screens/trash_screen.dart \
  lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart \
  lib/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart \
  lib/features/trash/presentation/widgets/support/trash_labels_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/shared/widgets/mx_button.dart \
  test/features/trash/presentation/trash_golden_test.dart \
  test/features/trash/presentation/trash_selection_test.dart \
  test/shared/widgets/mx_button_test.dart \
  test/visual_audit/screens/features/trash/screens/trash_screen_visual_audit_test.dart \
  test/features/trash/presentation/goldens/trash_actions_dark.png \
  test/features/trash/presentation/goldens/trash_actions_light.png \
  test/features/trash/presentation/goldens/trash_all_dark.png \
  test/features/trash/presentation/goldens/trash_all_light.png \
  test/features/trash/presentation/goldens/trash_no_target_dark.png \
  test/features/trash/presentation/goldens/trash_no_target_light.png \
  test/features/trash/presentation/goldens/trash_purge_blocked_dark.png \
  test/features/trash/presentation/goldens/trash_purge_blocked_light.png \
  test/features/trash/presentation/goldens/trash_purge_confirm_dark.png \
  test/features/trash/presentation/goldens/trash_purge_confirm_light.png \
  test/features/trash/presentation/goldens/trash_restore_target_dark.png \
  test/features/trash/presentation/goldens/trash_restore_target_light.png \
  test/features/trash/presentation/goldens/trash_selection_dark.png \
  test/features/trash/presentation/goldens/trash_selection_light.png
git commit -m "$(cat <<'EOF'
feat(trash): a kind-locked selection and delete for good (FE-B1, BR-TRASH-011)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: The route and every way into the Trash

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/features/card/presentation/screens/card_detail_screen.dart`
- Modify: `lib/features/card/presentation/screens/card_editor_screen.dart`
- Modify: `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_gone_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart`
- Modify: `lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/app/goldens/app_library_dark.png`
- Modify: `test/app/goldens/app_library_light.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_light.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_trashed_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_trashed_light.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_2x_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_2x_light.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_decks_light.png`
- Modify: `test/features/deck/presentation/goldens/library_empty_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_empty_light.png`
- Test (modify): `test/app/trash_routes_test.dart`
- Test (modify): `test/features/deck/presentation/deck_level_screen_test.dart`
- Test (modify): `test/features/deck/presentation/open_deck_screen_test.dart`
- Test (modify): `test/support/library_harness.dart`

**Interfaces:**
- Consumes: Task 2's `TrashScreen`; plan 1's `showDeckTrashedSnackbar`,
  `showCardsTrashedSnackbar`, `CardTrashSectionWidget`, the delete dialogs and the gone
  states.
- Produces:
  - `AppRoutes.trashChild` (`trash`) and `AppRoutes.trash` (`/decks/trash`), a route on
    the root navigator;
  - `DeckLevelScreen({required VoidCallback onOpenTrash})`, and an optional
    `VoidCallback? onOpenTrash` on every widget and function below it and on
    `CardEditorScreen.create`/`.edit` and `CardDetailScreen` (Q5);
  - `commonOpenTrash`; `comingSoonTrashBody` is removed.
  - `test/support/library_harness.dart`'s `deckScreen({VoidCallback? onOpenTrash})`.

- [ ] **Step 1: Write the failing tests**

`test/app/trash_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/trash_routes_test.dart b/test/app/trash_routes_test.dart
index 547fa7e..bee70ce 100644
--- a/test/app/trash_routes_test.dart
+++ b/test/app/trash_routes_test.dart
@@ -3,6 +3,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
+import 'package:memox/shared/widgets/mx_bottom_nav.dart';
 import 'package:memox/shared/widgets/mx_button.dart';
 import 'package:memox/shared/widgets/mx_dialog.dart';
 
@@ -20,8 +21,126 @@ Future<void> _tap(WidgetTester tester, Finder finder) async {
   await tester.pumpAndSettle();
 }
 
+/// Korean › Words with the cards bap and gim.
+Future<String> _seed(LibraryEnv env) async {
+  final words = await env.decks.sub(
+    (await env.decks.root('Korean')).id,
+    'Words',
+  );
+  await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
+  await insertCard(env.db, id: 'c1', deckId: words.id, front: 'gim');
+  return words.id;
+}
+
+Future<void> _openWords(WidgetTester tester) async {
+  await _tap(tester, find.text('Korean'));
+  await _tap(tester, find.text('Words'));
+}
+
+Finder _inDialog(String text) =>
+    find.descendant(of: find.byType(MxDialog), matching: find.text(text));
+
+/// The Trash is on screen, above the shell (FE-B1 D2).
+void _expectTrash() {
+  expect(_barTitle(_en.libraryTrash), findsOneWidget);
+  expect(find.byType(MxBottomNav), findsNothing);
+}
+
 /// The routes around the Trash (FE-B1).
 void main() {
+  libraryTest('the Library’s Trash opens screen 06 above the shell; Back '
+      'returns (FE-B1 D1, D2)', (tester, env) async {
+    await _seed(env);
+    await pumpMemoxApp(tester, env);
+
+    await _tap(tester, find.byTooltip(_en.libraryTrash));
+    _expectTrash();
+    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
+
+    await _tap(tester, find.byTooltip(_en.commonBack));
+    expect(_barTitle(_en.navLibrary), findsOneWidget);
+    expect(find.byType(MxBottomNav), findsOneWidget);
+  });
+
+  libraryTest('the toast of several cards opens the Trash (FE-B1 D4)', (
+    tester,
+    env,
+  ) async {
+    await _seed(env);
+    await pumpMemoxApp(tester, env);
+    await _openWords(tester);
+    await tester.longPress(find.text('bap'));
+    await tester.pumpAndSettle();
+    await _tap(tester, find.text('gim'));
+    await _tap(tester, find.text(_en.cardDelete));
+    await _tap(tester, _inDialog(_en.cardMoveToTrash));
+
+    expect(find.text(_en.cardsTrashedToast(2)), findsOneWidget);
+    await _tap(tester, find.text(_en.commonOpenTrash));
+    _expectTrash();
+    expect(find.text(_en.trashEntriesHeader(2).toUpperCase()), findsOneWidget);
+  });
+
+  libraryTest('a refused Undo opens the Trash (UC-TRASH-001 E3)', (
+    tester,
+    env,
+  ) async {
+    final words = await _seed(env);
+    await pumpMemoxApp(tester, env);
+    await _openWords(tester);
+    await tester.longPress(find.text('bap'));
+    await tester.pumpAndSettle();
+    await _tap(tester, find.text(_en.cardDelete));
+    await _tap(tester, _inDialog(_en.cardMoveToTrash));
+    // Meanwhile its deck goes to the Trash as well.
+    await env.decks.deleteDeck(deckId: words);
+    await tester.pumpAndSettle();
+
+    await _tap(tester, find.text(_en.commonUndo));
+    expect(
+      find.text(_en.cardUndoRefused(_en.cardRejectionTargetInTrash)),
+      findsOneWidget,
+    );
+    // The toast's, not the gone deck's behind it.
+    await _tap(
+      tester,
+      find.descendant(
+        of: find.byType(SnackBar),
+        matching: find.text(_en.commonOpenTrash),
+      ),
+    );
+    _expectTrash();
+  });
+
+  libraryTest('a card detail whose card went to the Trash leads there (FE-B1 '
+      'D11)', (tester, env) async {
+    await _seed(env);
+    await pumpMemoxApp(tester, env);
+    await _openWords(tester);
+    await _tap(tester, find.text('bap'));
+    await env.cards.deleteCards(cardIds: {'c0'});
+    await tester.pumpAndSettle();
+
+    expect(find.text(_en.cardDetailGoneBody), findsOneWidget);
+    await _tap(tester, find.text(_en.commonOpenTrash));
+    _expectTrash();
+  });
+
+  libraryTest('an open deck gone to the Trash leads there (FE-B1 D11)', (
+    tester,
+    env,
+  ) async {
+    final words = await _seed(env);
+    await pumpMemoxApp(tester, env);
+    await _openWords(tester);
+    await env.decks.deleteDeck(deckId: words);
+    await tester.pumpAndSettle();
+
+    expect(find.text(_en.deckGoneBody), findsOneWidget);
+    await _tap(tester, find.text(_en.commonOpenTrash));
+    _expectTrash();
+  });
+
   libraryTest('Move to Trash from the editor returns to the card list with '
       'Undo (FE-B1 D13)', (tester, env) async {
     final words = await env.decks.sub(
```

`test/features/deck/presentation/deck_level_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_level_screen_test.dart b/test/features/deck/presentation/deck_level_screen_test.dart
index eedc97b..fb3c99f 100644
--- a/test/features/deck/presentation/deck_level_screen_test.dart
+++ b/test/features/deck/presentation/deck_level_screen_test.dart
@@ -279,19 +279,24 @@ void main() {
     expect(find.text(_vi.libraryDecksCount(2).toUpperCase()), findsOneWidget);
   });
 
-  libraryTest('the root app bar holds Coming soon, which lists what waits', (
-    tester,
-    env,
-  ) async {
-    await pumpLibraryScreen(tester, env, deckScreen());
+  libraryTest('the root app bar holds Trash and Coming soon, which lists what '
+      'waits (FE-B1 D1)', (tester, env) async {
+    var trashOpened = 0;
+    await pumpLibraryScreen(
+      tester,
+      env,
+      deckScreen(onOpenTrash: () => trashOpened++),
+    );
+    await tester.tap(find.byTooltip(_en.libraryTrash));
+    expect(trashOpened, 1);
 
-    // Reorder moved to a row's sheet (ruling C-L4): one action only.
+    // Reorder moved to a row's sheet (ruling C-L4): Trash and Coming soon.
     expect(
       find.descendant(
         of: find.byType(MxAppBar),
         matching: find.byType(MxIconButton),
       ),
-      findsOneWidget,
+      findsNWidgets(2),
     );
     await tester.tap(find.byTooltip(_en.libraryComingSoon));
     await tester.pumpAndSettle();
@@ -300,7 +305,6 @@ void main() {
     for (final feature in [
       _en.libraryStarterDecks,
       _en.libraryTags,
-      _en.libraryTrash,
       _en.deckStudyOptions,
       _en.comingSoonProgressSort,
     ]) {
```

`test/features/deck/presentation/open_deck_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/open_deck_screen_test.dart b/test/features/deck/presentation/open_deck_screen_test.dart
index 8935999..8f5b8d7 100644
--- a/test/features/deck/presentation/open_deck_screen_test.dart
+++ b/test/features/deck/presentation/open_deck_screen_test.dart
@@ -224,17 +224,20 @@ void main() {
     expect(find.text(_en.deckUnsetTitle), findsOneWidget);
   });
 
-  libraryTest('a deck deleted while open says it is no longer here (A8)', (
-    tester,
-    env,
-  ) async {
+  libraryTest('a deck deleted while open says it is no longer here and leads '
+      'back or to the Trash (A8, FE-B1 D11)', (tester, env) async {
     final korean = await env.decks.root('Korean');
     final words = await env.decks.sub(korean.id, 'Words');
     String? ancestor = 'unset';
+    var trashOpened = 0;
     await pumpLibraryScreen(
       tester,
       env,
-      deckScreen(deckId: words.id, onOpenAncestor: (id) => ancestor = id),
+      deckScreen(
+        deckId: words.id,
+        onOpenAncestor: (id) => ancestor = id,
+        onOpenTrash: () => trashOpened++,
+      ),
     );
 
     await env.decks.deleteDeck(deckId: words.id);
@@ -242,8 +245,9 @@ void main() {
 
     expect(find.text(_en.deckGoneTitle), findsOneWidget);
     expect(find.byType(SnackBar), findsNothing);
-    // Trash waits under Coming soon (spec A4, amended): Back is the one way.
-    expect(find.byType(MxButton), findsOneWidget);
+    expect(find.byType(MxButton), findsNWidgets(2));
+    await tester.tap(find.text(_en.commonOpenTrash));
+    expect(trashOpened, 1);
     await tester.tap(find.text(_en.deckBackToLibrary));
     expect(ancestor, isNull);
   });
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index cc7548d..41ae968 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -196,6 +196,7 @@ DeckLevelScreen deckScreen({
   ValueChanged<String>? onImportCards,
   ValueChanged<DeckEntity>? onExportCards,
   ValueChanged<String>? onOpenStudy,
+  VoidCallback? onOpenTrash,
 }) => DeckLevelScreen(
   deckId: deckId,
   onOpenDeck: onOpenDeck ?? (_) {},
@@ -206,6 +207,7 @@ DeckLevelScreen deckScreen({
   onAddCard: onAddCard ?? (_) {},
   onImportCards: onImportCards ?? (_) {},
   onExportCards: onExportCards ?? (_) {},
+  onOpenTrash: onOpenTrash ?? () {},
   cardContent: cardContent ?? (_) => const SizedBox.shrink(),
   cardAppBar:
       cardAppBar ??
@@ -229,6 +231,7 @@ DeckLevelScreen cardDeckScreen(String deckId) => deckScreen(
     onOpenCard: (_) {},
     onExport: (_) {},
     onStudy: () {},
+    onOpenTrash: () {},
   ),
   cardAppBar: (view, back, actions) =>
       CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/app/trash_routes_test.dart
```

Expected: FAIL to compile: `DeckLevelScreen` has no `onOpenTrash`, and `commonOpenTrash`
is not a member of `AppLocalizations`.

- [ ] **Step 3: Implement**

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index fa6defa..adc6fc0 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -9,6 +9,7 @@ import 'package:memox/app/router/app_routes.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
 import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
+import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
 import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
@@ -61,6 +62,7 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                         builder: (context, state) => CardEditorScreen.create(
                           deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                           deckContext: _deckContext,
+                          onOpenTrash: _openTrash(context),
                         ),
                       ),
                       // A full-screen task above the shell: no bottom bar
@@ -90,6 +92,13 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                       ),
                     ],
                   ),
+                  // A full-screen task above the shell: no bottom bar
+                  // (FE-B1 D2).
+                  GoRoute(
+                    path: AppRoutes.trashChild,
+                    parentNavigatorKey: rootNavigator,
+                    builder: (context, state) => const TrashScreen(),
+                  ),
                   GoRoute(
                     path: AppRoutes.searchChild,
                     builder: (context, state) => LibrarySearchScreen(
@@ -103,6 +112,7 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                       cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                       deckContext: _deckContext,
                       onEdit: (id) => unawaited(_editCard(context, id)),
+                      onOpenTrash: _openTrash(context),
                     ),
                     routes: [
                       GoRoute(
@@ -110,6 +120,7 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
                         builder: (context, state) => CardEditorScreen.edit(
                           cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                           deckContext: _deckContext,
+                          onOpenTrash: _openTrash(context),
                         ),
                       ),
                     ],
@@ -162,6 +173,7 @@ GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
 DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
   void addCard(String id) => unawaited(context.push(AppRoutes.newCard(id)));
   void study(String id) => unawaited(context.push(AppRoutes.studyEntry(id)));
+  final openTrash = _openTrash(context);
   return DeckLevelScreen(
     deckId: deckId,
     onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
@@ -175,6 +187,7 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
     onExportCards: (deck) => unawaited(
       showDeckExportSheet(context, deckId: deck.id, deckName: deck.name),
     ),
+    onOpenTrash: openTrash,
     cardAppBar: (view, back, actions) =>
         CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
     cardBreadcrumb: (id, child) =>
@@ -185,6 +198,7 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
       onAddCard: () => addCard(view.deck.id),
       onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
       onStudy: () => study(view.deck.id),
+      onOpenTrash: openTrash,
       onExport: (ids) => unawaited(
         showCardExportSheet(
           context,
@@ -207,6 +221,13 @@ StudyEntryScreen _studyEntry(String deckId) => StudyEntryScreen(
   ),
 );
 
+/// Opens the Trash on the root navigator (FE-B1 D2). The router pushes it,
+/// not the page's context: a toast's action can outlive its page.
+VoidCallback _openTrash(BuildContext context) {
+  final router = GoRouter.of(context);
+  return () => unawaited(router.push(AppRoutes.trash));
+}
+
 /// Opens the editor over the card detail. The editor closes with true when
 /// it moved the card to the Trash; the detail, whose card is gone, closes
 /// with it (FE-B1 D13).
```

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index be415bd..6799906 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -24,6 +24,11 @@ abstract final class AppRoutes {
 
   static const String deckSearch = '$decks/$searchChild';
 
+  /// The Trash (screen 06), relative to [decks]: a full-screen task on the
+  /// root navigator (FE-B1 D2).
+  static const String trashChild = 'trash';
+  static const String trash = '$decks/$trashChild';
+
   /// A root deck's review algorithm (screen 02), relative to [deckChild].
   static const String algorithmChild = 'algorithm';
 
```

`lib/features/card/presentation/screens/card_detail_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/screens/card_detail_screen.dart b/lib/features/card/presentation/screens/card_detail_screen.dart
index a65f69b..e335eed 100644
--- a/lib/features/card/presentation/screens/card_detail_screen.dart
+++ b/lib/features/card/presentation/screens/card_detail_screen.dart
@@ -30,6 +30,7 @@ class CardDetailScreen extends ConsumerWidget {
     required this.cardId,
     required this.deckContext,
     required this.onEdit,
+    this.onOpenTrash,
   });
 
   final String cardId;
@@ -38,6 +39,9 @@ class CardDetailScreen extends ConsumerWidget {
   /// Edit for [cardId]: the router opens the editor.
   final ValueChanged<String> onEdit;
 
+  /// Opens the Trash from the gone state (FE-B1 D11).
+  final VoidCallback? onOpenTrash;
+
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final l10n = context.l10n;
@@ -66,6 +70,7 @@ class CardDetailScreen extends ConsumerWidget {
         cardId: cardId,
         detail: detail,
         deckContext: deckContext,
+        onOpenTrash: onOpenTrash,
       ),
     );
   }
@@ -77,11 +82,13 @@ class _DetailBody extends ConsumerWidget {
     required this.cardId,
     required this.detail,
     required this.deckContext,
+    this.onOpenTrash,
   });
 
   final String cardId;
   final AsyncValue<Outcome<CardDetail, CardRejection>> detail;
   final Widget Function(String deckId, String currentLabel) deckContext;
+  final VoidCallback? onOpenTrash;
 
   static const int _skeletonRows = 4;
 
@@ -110,6 +117,7 @@ class _DetailBody extends ConsumerWidget {
         title: l10n.cardGoneTitle,
         body: l10n.cardDetailGoneBody,
         onBack: () => unawaited(Navigator.of(context).maybePop()),
+        onOpenTrash: onOpenTrash,
       ),
       AsyncError() => MxScreenScroll(
         children: [
```

`lib/features/card/presentation/screens/card_editor_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/screens/card_editor_screen.dart b/lib/features/card/presentation/screens/card_editor_screen.dart
index cc19fc2..a8a15dc 100644
--- a/lib/features/card/presentation/screens/card_editor_screen.dart
+++ b/lib/features/card/presentation/screens/card_editor_screen.dart
@@ -22,33 +22,51 @@ class CardEditorScreen extends StatelessWidget {
     super.key,
     required String this.deckId,
     required this.deckContext,
+    this.onOpenTrash,
   }) : cardId = null;
 
   const CardEditorScreen.edit({
     super.key,
     required String this.cardId,
     required this.deckContext,
+    this.onOpenTrash,
   }) : deckId = null;
 
   final String? deckId;
   final String? cardId;
   final Widget Function(String deckId, String currentLabel) deckContext;
 
+  /// Opens the Trash from a gone state and a refused Undo (FE-B1 D11).
+  final VoidCallback? onOpenTrash;
+
   @override
   Widget build(BuildContext context) {
     if (deckId case final deckId?) {
-      return CardEditorFormWidget(deckId: deckId, deckContext: deckContext);
+      return CardEditorFormWidget(
+        deckId: deckId,
+        deckContext: deckContext,
+        onOpenTrash: onOpenTrash,
+      );
     }
-    return _EditLoader(cardId: cardId!, deckContext: deckContext);
+    return _EditLoader(
+      cardId: cardId!,
+      deckContext: deckContext,
+      onOpenTrash: onOpenTrash,
+    );
   }
 }
 
 /// The card to edit while it loads, fails or is gone (ruling P4a-L4).
 class _EditLoader extends ConsumerWidget {
-  const _EditLoader({required this.cardId, required this.deckContext});
+  const _EditLoader({
+    required this.cardId,
+    required this.deckContext,
+    this.onOpenTrash,
+  });
 
   final String cardId;
   final Widget Function(String deckId, String currentLabel) deckContext;
+  final VoidCallback? onOpenTrash;
 
   static const int _skeletonRows = 4;
 
@@ -72,6 +90,7 @@ class _EditLoader extends ConsumerWidget {
         deckId: value.card.deckId,
         detail: value,
         deckContext: deckContext,
+        onOpenTrash: onOpenTrash,
       ),
       AsyncData(value: Rejected()) => MxAppShell(
         appBar: bar,
@@ -79,6 +98,7 @@ class _EditLoader extends ConsumerWidget {
           title: l10n.cardGoneTitle,
           body: l10n.cardGoneBody,
           onBack: back,
+          onOpenTrash: onOpenTrash,
         ),
       ),
       AsyncError() => MxAppShell(
```

`lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart b/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
index b972325..2a6e2ba 100644
--- a/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
+++ b/lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart
@@ -26,12 +26,14 @@ Future<bool> showDeleteCardsDialog(
   BuildContext context, {
   required Set<String> cardIds,
   CardTrashPreview? preview,
+  VoidCallback? onOpenTrash,
 }) async =>
     await showMxDialog<bool>(
       context,
       builder: (_) => CardDeleteDialogWidget(
         cardIds: cardIds,
         preview: cardIds.length == 1 ? preview : null,
+        onOpenTrash: onOpenTrash,
       ),
     ) ??
     false;
@@ -43,11 +45,15 @@ class CardDeleteDialogWidget extends ConsumerStatefulWidget {
     super.key,
     required this.cardIds,
     this.preview,
+    this.onOpenTrash,
   });
 
   final Set<String> cardIds;
   final CardTrashPreview? preview;
 
+  /// Rides on the toast of several cards and on a refused Undo (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   @override
   ConsumerState<CardDeleteDialogWidget> createState() =>
       _CardDeleteDialogWidgetState();
@@ -73,6 +79,7 @@ class _CardDeleteDialogWidgetState
             context,
             batchIds: batchIds,
             front: widget.preview?.front,
+            onOpenTrash: widget.onOpenTrash,
           );
         case Rejected(:final reason):
           showMxSnackbar(context, message: context.l10n.cardRejection(reason));
```

`lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart b/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
index 69f79f1..0b4170b 100644
--- a/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart
@@ -43,6 +43,7 @@ class CardEditorFormWidget extends ConsumerStatefulWidget {
     required this.deckId,
     required this.deckContext,
     this.detail,
+    this.onOpenTrash,
   });
 
   /// The deck the card is written to.
@@ -52,6 +53,9 @@ class CardEditorFormWidget extends ConsumerStatefulWidget {
   /// The card to edit; null creates.
   final CardDetail? detail;
 
+  /// Opens the Trash from the gone state and a refused Undo (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   @override
   ConsumerState<CardEditorFormWidget> createState() =>
       _CardEditorFormWidgetState();
@@ -287,6 +291,7 @@ class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
                     : l10n.cardGoneTitle,
                 body: _isCreating ? l10n.cardDeckGoneBody : l10n.cardGoneBody,
                 onBack: _leave,
+                onOpenTrash: widget.onOpenTrash,
               )
             : Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -384,7 +389,8 @@ class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
       onPendingChanged: (isPending) =>
           setState(() => _hasPendingTag = isPending),
     ),
-    if (_card case final card?) CardTrashSectionWidget(card: card),
+    if (_card case final card?)
+      CardTrashSectionWidget(card: card, onOpenTrash: widget.onOpenTrash),
   ];
 
   /// One optional field's input, message and touch.
```

`lib/features/card/presentation/widgets/sections/card_gone_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_gone_widget.dart b/lib/features/card/presentation/widgets/sections/card_gone_widget.dart
index d62b3a7..b8191b1 100644
--- a/lib/features/card/presentation/widgets/sections/card_gone_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_gone_widget.dart
@@ -5,20 +5,24 @@ import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_empty_state.dart';
 import 'package:memox/shared/widgets/mx_screen_scroll.dart';
 
-/// The editor once its card or deck is gone (ruling P4a-L4): it says why and
-/// that nothing was saved, and leads back to the deck.
+/// The editor or the detail once its card or deck is gone (ruling P4a-L4):
+/// it says why, and leads back to the deck or to the Trash (FE-B1 D11).
 class CardGoneWidget extends StatelessWidget {
   const CardGoneWidget({
     super.key,
     required this.title,
     required this.body,
     required this.onBack,
+    this.onOpenTrash,
   });
 
   final String title;
   final String body;
   final VoidCallback onBack;
 
+  /// Hidden without it.
+  final VoidCallback? onOpenTrash;
+
   @override
   Widget build(BuildContext context) => MxScreenScroll(
     children: [
@@ -30,6 +34,10 @@ class CardGoneWidget extends StatelessWidget {
         tone: MxEmptyStateTone.neutral,
         actionLabel: context.l10n.cardBackToDeck,
         onAction: onBack,
+        secondaryActionLabel: onOpenTrash == null
+            ? null
+            : context.l10n.commonOpenTrash,
+        onSecondaryAction: onOpenTrash,
       ),
     ],
   );
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
index 7dc475b..2be752b 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
@@ -48,6 +48,7 @@ class CardListSectionWidget extends ConsumerStatefulWidget {
     required this.onOpenCard,
     this.onExport,
     this.onStudy,
+    this.onOpenTrash,
   });
 
   final String deckId;
@@ -68,6 +69,10 @@ class CardListSectionWidget extends ConsumerStatefulWidget {
   /// The summary's Study this deck: the router opens the Study Entry.
   final VoidCallback? onStudy;
 
+  /// Opens the Trash (screen 06), for the toasts and the gone state
+  /// (FE-B1). Hidden without it.
+  final VoidCallback? onOpenTrash;
+
   @override
   ConsumerState<CardListSectionWidget> createState() =>
       _CardListSectionWidgetState();
@@ -215,6 +220,7 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
               context,
               cardIds: selected,
               preview: _previewOf(selected),
+              onOpenTrash: widget.onOpenTrash,
             ),
           ),
         ),
```

`lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart b/lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart
index 5c09201..a7e2817 100644
--- a/lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart
@@ -14,10 +14,17 @@ import 'package:memox/shared/widgets/mx_card.dart';
 /// dialog as the list's (FE-B1 D13), then closes the editor with true, so
 /// the page that opened it can close too.
 class CardTrashSectionWidget extends StatelessWidget {
-  const CardTrashSectionWidget({super.key, required this.card});
+  const CardTrashSectionWidget({
+    super.key,
+    required this.card,
+    this.onOpenTrash,
+  });
 
   final CardEntity card;
 
+  /// Rides on a refused Undo's toast (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   Future<void> _move(BuildContext context) async {
     // Taken before the dialog: once the card is gone the editor swaps the
     // form for its gone state, and [context] with it. The edits are left
@@ -27,6 +34,7 @@ class CardTrashSectionWidget extends StatelessWidget {
       context,
       cardIds: {card.id},
       preview: (front: card.front, back: card.back),
+      onOpenTrash: onOpenTrash,
     );
     if (isMoved && navigator.mounted) navigator.pop(true);
   }
```

`lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart b/lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart
index 7346600..0706d05 100644
--- a/lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart
+++ b/lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart
@@ -12,8 +12,8 @@ import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_snackbar.dart';
 
 /// Says cards went to the Trash (FE-B1 D3, D4). One card, named by its
-/// [front] when the caller has it, gets Undo for 8 seconds; several do not
-/// (BR-TRASH-008).
+/// [front] when the caller has it, gets Undo for 8 seconds; several get
+/// [onOpenTrash] instead (BR-TRASH-008), as a refused Undo does.
 ///
 /// The toast outlives the dialog and often the screen that showed it, so it
 /// lives on the root navigator and Undo reads the app's container, not a
@@ -22,6 +22,7 @@ void showCardsTrashedSnackbar(
   BuildContext context, {
   required List<String> batchIds,
   String? front,
+  VoidCallback? onOpenTrash,
 }) {
   final host = Navigator.of(context, rootNavigator: true).context;
   final l10n = context.l10n;
@@ -34,11 +35,16 @@ void showCardsTrashedSnackbar(
           : l10n.cardTrashedToast(front),
       actionLabel: l10n.commonUndo,
       duration: AppDurations.undoWindow,
-      onAction: () => unawaited(_undo(host, container, batchId)),
+      onAction: () => unawaited(_undo(host, container, batchId, onOpenTrash)),
     );
     return;
   }
-  showMxSnackbar(host, message: l10n.cardsTrashedToast(batchIds.length));
+  showMxSnackbar(
+    host,
+    message: l10n.cardsTrashedToast(batchIds.length),
+    actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
+    onAction: onOpenTrash,
+  );
 }
 
 /// The card goes back into its deck; a refusal says why and leaves it in
@@ -47,6 +53,7 @@ Future<void> _undo(
   BuildContext host,
   ProviderContainer container,
   String batchId,
+  VoidCallback? onOpenTrash,
 ) async {
   try {
     final outcome = await container
@@ -57,6 +64,8 @@ Future<void> _undo(
       showMxSnackbar(
         host,
         message: l10n.cardUndoRefused(l10n.cardRejection(reason)),
+        actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
+        onAction: onOpenTrash,
       );
     }
   } on Failure catch (failure) {
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/screens/deck_level_screen.dart b/lib/features/deck/presentation/screens/deck_level_screen.dart
index 06bd3b3..e4cefbb 100644
--- a/lib/features/deck/presentation/screens/deck_level_screen.dart
+++ b/lib/features/deck/presentation/screens/deck_level_screen.dart
@@ -45,6 +45,7 @@ class DeckLevelScreen extends StatelessWidget {
     required this.onAddCard,
     required this.onImportCards,
     required this.onExportCards,
+    required this.onOpenTrash,
     required this.cardFab,
   });
 
@@ -86,6 +87,10 @@ class DeckLevelScreen extends StatelessWidget {
   /// sheet over the whole deck.
   final ValueChanged<DeckEntity> onExportCards;
 
+  /// Opens the Trash (screen 06): the Library's app bar, a gone deck, a
+  /// refused Undo (FE-B1).
+  final VoidCallback onOpenTrash;
+
   /// A deck of cards' FAB, from the card feature like [cardContent] (spec
   /// D8). It hides itself while cards are selected.
   final Widget Function(String deckId) cardFab;
@@ -97,6 +102,7 @@ class DeckLevelScreen extends StatelessWidget {
       onSearch: onSearch,
       onOpenAlgorithm: onOpenAlgorithm,
       onOpenStudy: onOpenStudy,
+      onOpenTrash: onOpenTrash,
     ),
     final id => _OpenDeck(
       deckId: id,
@@ -110,6 +116,7 @@ class DeckLevelScreen extends StatelessWidget {
       onAddCard: onAddCard,
       onImportCards: onImportCards,
       onExportCards: onExportCards,
+      onOpenTrash: onOpenTrash,
       cardFab: cardFab,
     ),
   };
@@ -129,6 +136,7 @@ class _OpenDeck extends ConsumerWidget {
     required this.onAddCard,
     required this.onImportCards,
     required this.onExportCards,
+    required this.onOpenTrash,
     required this.cardFab,
   });
 
@@ -146,6 +154,10 @@ class _OpenDeck extends ConsumerWidget {
   final ValueChanged<String> onAddCard;
   final ValueChanged<String> onImportCards;
   final ValueChanged<DeckEntity> onExportCards;
+
+  /// Opens the Trash (screen 06): the Library's app bar, a gone deck, a
+  /// refused Undo (FE-B1).
+  final VoidCallback onOpenTrash;
   final Widget Function(String deckId) cardFab;
 
   static const int _skeletonRows = 4;
@@ -172,6 +184,7 @@ class _OpenDeck extends ConsumerWidget {
         onAddCard: onAddCard,
         onImportCards: onImportCards,
         onExportCards: onExportCards,
+        onOpenTrash: onOpenTrash,
         cardFab: cardFab,
       ),
       AsyncError() => MxAppShell(
@@ -190,7 +203,10 @@ class _OpenDeck extends ConsumerWidget {
       // Spec A8: deleted while open. Say so; the way back is the Library.
       AsyncData(value: Rejected()) => MxAppShell(
         appBar: bar,
-        body: DeckGoneStateWidget(onBackToLibrary: () => onOpenAncestor(null)),
+        body: DeckGoneStateWidget(
+          onBackToLibrary: () => onOpenAncestor(null),
+          onOpenTrash: onOpenTrash,
+        ),
       ),
       _ => MxAppShell(
         appBar: bar,
@@ -221,6 +237,7 @@ class _OpenDeckContent extends ConsumerWidget {
     required this.onAddCard,
     required this.onImportCards,
     required this.onExportCards,
+    required this.onOpenTrash,
     required this.cardFab,
   });
 
@@ -238,6 +255,10 @@ class _OpenDeckContent extends ConsumerWidget {
   final ValueChanged<String> onAddCard;
   final ValueChanged<String> onImportCards;
   final ValueChanged<DeckEntity> onExportCards;
+
+  /// Opens the Trash (screen 06): the Library's app bar, a gone deck, a
+  /// refused Undo (FE-B1).
+  final VoidCallback onOpenTrash;
   final Widget Function(String deckId) cardFab;
 
   @override
@@ -267,6 +288,7 @@ class _OpenDeckContent extends ConsumerWidget {
               ? () => onExportCards(deck)
               : null,
           onOpenStudy: onOpenStudy,
+          onOpenTrash: onOpenTrash,
           isOpenDeck: true,
         ),
       ),
@@ -321,6 +343,7 @@ class _OpenDeckContent extends ConsumerWidget {
                 onOpenDeck: onOpenDeck,
                 onOpenAlgorithm: onOpenAlgorithm,
                 onOpenStudy: onOpenStudy,
+                onOpenTrash: onOpenTrash,
                 schedulerType: view.schedulerType,
                 // Owner decision C-O6: its sub-decks are at level 10.
                 hasDeepestSubDecks: deck.depth == DeckEntity.maxDepth - 1,
```

`lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
index 0c55b62..75c2f85 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
@@ -33,7 +33,6 @@ class DeckComingSoonSheetWidget extends StatelessWidget {
       l10n.libraryStarterDecks,
       l10n.comingSoonStarterDecksBody,
     ),
-    (AppIcons.delete, l10n.libraryTrash, l10n.comingSoonTrashBody),
   ];
 
   @override
```

`lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
index 8ba7e69..cce0ea8 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart
@@ -21,10 +21,12 @@ import 'package:memox/shared/widgets/mx_snackbar.dart';
 Future<bool> showDeleteDeckDialog(
   BuildContext context, {
   required DeckEntity deck,
+  VoidCallback? onOpenTrash,
 }) async =>
     await showMxDialog<bool>(
       context,
-      builder: (_) => DeckDeleteDialogWidget(deck: deck),
+      builder: (_) =>
+          DeckDeleteDialogWidget(deck: deck, onOpenTrash: onOpenTrash),
     ) ??
     false;
 
@@ -33,10 +35,17 @@ Future<bool> showDeleteDeckDialog(
 /// since the Trash keeps them for 30 days, and it spins while the deck
 /// moves (FE-B1 D15).
 class DeckDeleteDialogWidget extends ConsumerStatefulWidget {
-  const DeckDeleteDialogWidget({super.key, required this.deck});
+  const DeckDeleteDialogWidget({
+    super.key,
+    required this.deck,
+    this.onOpenTrash,
+  });
 
   final DeckEntity deck;
 
+  /// Rides on a refused Undo's toast (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   @override
   ConsumerState<DeckDeleteDialogWidget> createState() =>
       _DeckDeleteDialogWidgetState();
@@ -63,6 +72,7 @@ class _DeckDeleteDialogWidgetState
             deckName: widget.deck.name,
             summary: summary,
             batchId: batchId,
+            onOpenTrash: widget.onOpenTrash,
           );
         case Rejected(:final reason):
           showMxSnackbar(context, message: context.l10n.deckRejection(reason));
```

`lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart
index 0467531..68da7dd 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart
@@ -4,13 +4,20 @@ import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_empty_state.dart';
 import 'package:memox/shared/widgets/mx_screen_scroll.dart';
 
-/// The open deck was deleted while it was on screen (spec A8): say so, and
-/// go back to the Library. Trash waits under Coming soon (spec A4, amended).
+/// The open deck went to the Trash while it was on screen (spec A8): say
+/// so, and go back to the Library or open the Trash (FE-B1 D11).
 class DeckGoneStateWidget extends StatelessWidget {
-  const DeckGoneStateWidget({super.key, required this.onBackToLibrary});
+  const DeckGoneStateWidget({
+    super.key,
+    required this.onBackToLibrary,
+    this.onOpenTrash,
+  });
 
   final VoidCallback onBackToLibrary;
 
+  /// Hidden without it.
+  final VoidCallback? onOpenTrash;
+
   @override
   Widget build(BuildContext context) {
     final l10n = context.l10n;
@@ -22,6 +29,10 @@ class DeckGoneStateWidget extends StatelessWidget {
           body: l10n.deckGoneBody,
           actionLabel: l10n.deckBackToLibrary,
           onAction: onBackToLibrary,
+          secondaryActionLabel: onOpenTrash == null
+              ? null
+              : l10n.commonOpenTrash,
+          onSecondaryAction: onOpenTrash,
         ),
       ],
     );
```

`lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
index c4e46a2..1909737 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart
@@ -25,6 +25,7 @@ class DeckLevelBodyWidget extends ConsumerWidget {
     required this.emptyState,
     required this.schedulerType,
     required this.hasDeepestSubDecks,
+    this.onOpenTrash,
   });
 
   final String? parentId;
@@ -36,6 +37,9 @@ class DeckLevelBodyWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Opens the Trash (screen 06), for a refused Undo (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   /// The open deck's algorithm for its summary card; null at the root.
   final SchedulerType? schedulerType;
 
@@ -69,6 +73,7 @@ class DeckLevelBodyWidget extends ConsumerWidget {
                   onOpenDeck: onOpenDeck,
                   onOpenAlgorithm: onOpenAlgorithm,
                   onOpenStudy: onOpenStudy,
+                  onOpenTrash: onOpenTrash,
                   emptyState: emptyState,
                   schedulerType: schedulerType,
                   hasDeepestSubDecks: hasDeepestSubDecks,
```

`lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
index 46d8f2f..dda876c 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart
@@ -31,6 +31,7 @@ class DeckLevelListWidget extends ConsumerWidget {
     required this.emptyState,
     required this.schedulerType,
     required this.hasDeepestSubDecks,
+    this.onOpenTrash,
   });
 
   final DeckLevel level;
@@ -43,6 +44,9 @@ class DeckLevelListWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Opens the Trash (screen 06), for a refused Undo (FE-B1).
+  final VoidCallback? onOpenTrash;
+
   /// Shown when the level holds no deck at all (ruling L4).
   final Widget emptyState;
 
@@ -138,6 +142,7 @@ class DeckLevelListWidget extends ConsumerWidget {
                       onOpenDeck: onOpenDeck,
                       onOpenAlgorithm: onOpenAlgorithm,
                       onOpenStudy: onOpenStudy,
+                      onOpenTrash: onOpenTrash,
                       isOpenDeck: false,
                     ),
                   ),
```

`lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
index abcdf30..abfcec4 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart
@@ -27,6 +27,7 @@ class DeckLibraryRootWidget extends ConsumerWidget {
     required this.onSearch,
     required this.onOpenAlgorithm,
     required this.onOpenStudy,
+    required this.onOpenTrash,
   });
 
   final ValueChanged<String> onOpenDeck;
@@ -36,6 +37,9 @@ class DeckLibraryRootWidget extends ConsumerWidget {
   /// A deck's Study Entry (screen 14), from an action sheet or a summary.
   final ValueChanged<String> onOpenStudy;
 
+  /// Opens the Trash (screen 06) from the app bar (FE-B1 D1).
+  final VoidCallback onOpenTrash;
+
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final l10n = context.l10n;
@@ -64,6 +68,11 @@ class DeckLibraryRootWidget extends ConsumerWidget {
             ? const [DeckReorderDoneWidget(parentId: null)]
             // Features that wait are named in one place (spec A4, amended).
             : [
+                MxIconButton(
+                  icon: AppIcons.delete,
+                  semanticLabel: l10n.libraryTrash,
+                  onPressed: onOpenTrash,
+                ),
                 MxIconButton(
                   icon: AppIcons.upcoming,
                   semanticLabel: l10n.libraryComingSoon,
@@ -99,6 +108,7 @@ class DeckLibraryRootWidget extends ConsumerWidget {
               onOpenDeck: onOpenDeck,
               onOpenAlgorithm: onOpenAlgorithm,
               onOpenStudy: onOpenStudy,
+              onOpenTrash: onOpenTrash,
               schedulerType: null,
               hasDeepestSubDecks: false,
               emptyState: MxEmptyState(
```

`lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
index ff00273..e6b4fa8 100644
--- a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
@@ -15,7 +15,8 @@ import 'package:memox/shared/widgets/mx_snackbar.dart';
 /// Opens a deck's action sheet and then the chosen command's own dialog or
 /// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮.
 /// [onImportCards] offers Import on a deck that takes cards (UC-TRANSFER-001),
-/// [onExportCards] Export on a deck of cards (UC-TRANSFER-002). It reads
+/// [onExportCards] Export on a deck of cards (UC-TRANSFER-002);
+/// [onOpenTrash] rides on a refused Undo's toast (FE-B1). It reads
 /// the deck's view once first, so a deck gone meanwhile says so instead
 /// (ruling C-L6).
 Future<void> openDeckActions(
@@ -29,6 +30,7 @@ Future<void> openDeckActions(
   required bool isOpenDeck,
   VoidCallback? onImportCards,
   VoidCallback? onExportCards,
+  VoidCallback? onOpenTrash,
 }) async {
   // A row's deck has no listener yet: keep its view alive until it emits,
   // or the auto-disposed provider would never complete the read.
@@ -79,7 +81,12 @@ Future<void> openDeckActions(
     case DeckAction.reorder:
       ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
     case DeckAction.delete:
-      await _deleteDeck(context, view: view, isOpenDeck: isOpenDeck);
+      await _deleteDeck(
+        context,
+        view: view,
+        isOpenDeck: isOpenDeck,
+        onOpenTrash: onOpenTrash,
+      );
   }
 }
 
@@ -90,11 +97,16 @@ Future<void> _deleteDeck(
   BuildContext context, {
   required DeckView view,
   required bool isOpenDeck,
+  VoidCallback? onOpenTrash,
 }) async {
   // Taken before the dialog: once the deck is gone its screen swaps its
   // content, and [context] with it.
   final navigator = Navigator.of(context);
-  final isDeleted = await showDeleteDeckDialog(context, deck: view.deck);
+  final isDeleted = await showDeleteDeckDialog(
+    context,
+    deck: view.deck,
+    onOpenTrash: onOpenTrash,
+  );
   if (!isDeleted || !isOpenDeck || !navigator.mounted) return;
   await navigator.maybePop();
 }
```

`lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart b/lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart
index 638e098..93881af 100644
--- a/lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart
@@ -17,12 +17,13 @@ import 'package:memox/shared/widgets/mx_snackbar.dart';
 ///
 /// The toast outlives the dialog and often the screen that showed it, so it
 /// lives on the root navigator and Undo reads the app's container, not a
-/// widget's.
+/// widget's. A refused Undo offers [onOpenTrash] when there is one.
 void showDeckTrashedSnackbar(
   BuildContext context, {
   required String deckName,
   required DeckDeletionSummary summary,
   required String batchId,
+  VoidCallback? onOpenTrash,
 }) {
   final host = Navigator.of(context, rootNavigator: true).context;
   final container = ProviderScope.containerOf(context, listen: false);
@@ -36,7 +37,7 @@ void showDeckTrashedSnackbar(
     ),
     actionLabel: l10n.commonUndo,
     duration: AppDurations.undoWindow,
-    onAction: () => unawaited(_undo(host, container, batchId)),
+    onAction: () => unawaited(_undo(host, container, batchId, onOpenTrash)),
   );
 }
 
@@ -46,6 +47,7 @@ Future<void> _undo(
   BuildContext host,
   ProviderContainer container,
   String batchId,
+  VoidCallback? onOpenTrash,
 ) async {
   try {
     final outcome = await container
@@ -56,6 +58,8 @@ Future<void> _undo(
       showMxSnackbar(
         host,
         message: l10n.deckUndoRefused(l10n.deckRejection(reason)),
+        actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
+        onAction: onOpenTrash,
       );
     }
   } on Failure catch (failure) {
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 7731c06..40ac591 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -40,6 +40,10 @@
   "@commonUndo": {
     "description": "Snackbar action that reverses the last move to the Trash (BR-TRASH-008)."
   },
+  "commonOpenTrash": "Open Trash",
+  "@commonOpenTrash": {
+    "description": "Opens screen 06, the Trash: the Library app bar, the gone states and the Trash toasts (FE-B1 D1, D4, D11)."
+  },
   "commonRetry": "Retry",
   "@commonRetry": {
     "description": "Generic retry action after a failure."
@@ -2309,10 +2313,6 @@
   "@comingSoonTagsBody": {
     "description": "Coming soon: what tags do."
   },
-  "comingSoonTrashBody": "Restore deleted decks and cards.",
-  "@comingSoonTrashBody": {
-    "description": "Coming soon: what the trash does."
-  },
   "comingSoonStudyOptionsBody": "Session size and new-card order.",
   "@comingSoonStudyOptionsBody": {
     "description": "Coming soon: what study options do."
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 049359b..49a9a81 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -10,6 +10,7 @@
   "openGallery": "Thư viện component",
   "commonCancel": "Hủy",
   "commonUndo": "Hoàn tác",
+  "commonOpenTrash": "Mở Thùng rác",
   "commonRetry": "Thử lại",
   "commonLoading": "Đang tải",
   "libraryCreateDeck": "Tạo bộ thẻ",
@@ -426,7 +427,6 @@
   "libraryComingSoonBody": "Những tính năng này sẽ có ở phiên bản sau. Mọi thứ bạn thêm bây giờ đều được giữ.",
   "comingSoonStarterDecksBody": "Bộ thẻ có sẵn để sao chép.",
   "comingSoonTagsBody": "Gắn nhãn thẻ, lọc theo nhãn.",
-  "comingSoonTrashBody": "Khôi phục bộ thẻ và thẻ đã xoá.",
   "comingSoonStudyOptionsBody": "Số thẻ mỗi phiên, thứ tự thẻ mới.",
   "comingSoonProgressSort": "Sắp xếp theo độ thuộc",
   "comingSoonProgressSortBody": "Bộ thẻ thuộc ít nhất lên trước.",
```

- [ ] **Step 4: Generate, render the goldens, run the whole suite**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/app test/features/deck test/features/card
flutter test
flutter analyze
bash tools/check_architecture.sh
```

Expected: PASS, and the architecture check is clean: `deck` and `card` never import
`trash`. Twelve goldens change:
- `app_library_*`, `library_decks_*`, `library_decks_2x_*` and `library_empty_*`: the
  Library's app bar reads Trash · Coming soon (D1);
- `library_coming_soon_*`: no Trash line;
- `library_deck_trashed_*`: the gone state behind the toast gains "Open Trash" (D11).

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_router.dart \
  lib/app/router/app_routes.dart \
  lib/features/card/presentation/screens/card_detail_screen.dart \
  lib/features/card/presentation/screens/card_editor_screen.dart \
  lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart \
  lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart \
  lib/features/card/presentation/widgets/sections/card_gone_widget.dart \
  lib/features/card/presentation/widgets/sections/card_list_section_widget.dart \
  lib/features/card/presentation/widgets/sections/card_trash_section_widget.dart \
  lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart \
  lib/features/deck/presentation/screens/deck_level_screen.dart \
  lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart \
  lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/trash_routes_test.dart \
  test/features/deck/presentation/deck_level_screen_test.dart \
  test/features/deck/presentation/open_deck_screen_test.dart \
  test/support/library_harness.dart \
  test/app/goldens/app_library_dark.png \
  test/app/goldens/app_library_light.png \
  test/features/deck/presentation/goldens/library_coming_soon_dark.png \
  test/features/deck/presentation/goldens/library_coming_soon_light.png \
  test/features/deck/presentation/goldens/library_deck_trashed_dark.png \
  test/features/deck/presentation/goldens/library_deck_trashed_light.png \
  test/features/deck/presentation/goldens/library_decks_2x_dark.png \
  test/features/deck/presentation/goldens/library_decks_2x_light.png \
  test/features/deck/presentation/goldens/library_decks_dark.png \
  test/features/deck/presentation/goldens/library_decks_light.png \
  test/features/deck/presentation/goldens/library_empty_dark.png \
  test/features/deck/presentation/goldens/library_empty_light.png
git commit -m "$(cat <<'EOF'
feat(trash): the Library, toasts and gone states open the Trash (FE-B1 D1, D4, D11)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 6: The auto-purge at start, on resume and on opening

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart`
- Test (create): `test/app/trash_auto_purge_test.dart`

**Interfaces:**
- Consumes: Task 1's `purgeExpiredTrashUseCaseProvider` and
  `TrashController.purgeExpired()`.
- Produces: `MemoxApp` runs the purge in `initState` and on every resume through an
  `AppLifecycleListener`; `TrashScreen` runs it in `initState` (Q1).

- [ ] **Step 1: Write the failing tests**

`test/app/trash_auto_purge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words with the card bap, deleted [age] before [libraryToday].
Future<void> _seedDeleted(LibraryEnv env, Duration age) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(
    env.db,
    id: 'c0',
    deckId: words.id,
    front: 'bap',
    back: 'rice',
  );
  await env.cards.deleteCards(cardIds: {'c0'}, now: libraryToday.subtract(age));
}

Future<int> _batches(LibraryEnv env) async =>
    (await env.db
            .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
            .getSingle())
        .read<int>('n');

/// The app goes to the background and comes back, through every state.
void _cycleLifecycle(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  libraryTest('the app purges what expired when it starts (FE-B1 D5)', (
    tester,
    env,
  ) async {
    await _seedDeleted(env, trashRetention + const Duration(days: 1));
    expect(await _batches(env), 1);

    await pumpMemoxApp(tester, env);
    expect(await _batches(env), 0);
  });

  libraryTest('a resume purges what expired meanwhile, and the open Trash '
      'drops it in place (UC-TRASH-001 A4)', (tester, env) async {
    await _seedDeleted(env, trashRetention - const Duration(hours: 1));
    await pumpMemoxApp(tester, env);
    await tester.tap(find.byTooltip(_en.libraryTrash));
    await tester.pumpAndSettle();
    expect(find.text('bap · rice'), findsOneWidget);

    env.clock.current = libraryToday.add(const Duration(hours: 2));
    _cycleLifecycle(tester);
    await tester.pumpAndSettle();

    expect(find.text('bap · rice'), findsNothing);
    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
  });

  libraryTest('opening the Trash purges what expired since the start', (
    tester,
    env,
  ) async {
    await _seedDeleted(env, trashRetention - const Duration(hours: 1));
    await pumpMemoxApp(tester, env);
    expect(await _batches(env), 1);

    env.clock.current = libraryToday.add(const Duration(hours: 2));
    await tester.tap(find.byTooltip(_en.libraryTrash));
    await tester.pumpAndSettle();

    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
    expect(await _batches(env), 0);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/app/trash_auto_purge_test.dart
```

Expected: FAIL, 3 of 3: the expired entries are still in the store, and still in the
open Trash after the resume.

- [ ] **Step 3: Implement**

`lib/app/app.dart` (apply this diff):

```diff
diff --git a/lib/app/app.dart b/lib/app/app.dart
index 70cb311..2b79b7e 100644
--- a/lib/app/app.dart
+++ b/lib/app/app.dart
@@ -10,10 +10,12 @@ import 'package:memox/app/router/app_router.dart';
 import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/theme/app_theme.dart';
 import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';
+import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 
-/// The composition root: themes, localization and the router, and the
-/// start-up close of an earlier day's open study session (FE-A6 D9).
+/// The composition root: themes, localization and the router, the start-up
+/// close of an earlier day's open study session (FE-A6 D9), and the Trash's
+/// auto-purge at start and on every resume (FE-B1 D5).
 class MemoxApp extends ConsumerStatefulWidget {
   const MemoxApp({super.key, this.hasGallery = kDebugMode});
 
@@ -29,6 +31,10 @@ class _MemoxAppState extends ConsumerState<MemoxApp> {
   // location and a disposed app releases its router.
   late final GoRouter _router = buildAppRouter(hasGallery: widget.hasGallery);
 
+  /// A resume after a day away purges what expired meanwhile (UC-TRASH-001
+  /// A4).
+  late final AppLifecycleListener _lifecycle;
+
   @override
   void initState() {
     super.initState();
@@ -40,6 +46,20 @@ class _MemoxAppState extends ConsumerState<MemoxApp> {
     // anything could offer it (BR-STUDY-072). Unawaited: the entry already
     // offers no earlier day's session, so no frame waits for it.
     unawaited(_closeStaleSessions());
+    unawaited(_purgeExpiredTrash());
+    _lifecycle = AppLifecycleListener(
+      onResume: () => unawaited(_purgeExpiredTrash()),
+    );
+  }
+
+  /// BR-TRASH-009: what is past 30 days leaves for good. A failed purge
+  /// keeps it for the next start, resume or visit to the Trash.
+  Future<void> _purgeExpiredTrash() async {
+    try {
+      await ref.read(purgeExpiredTrashUseCaseProvider)();
+    } on Failure {
+      // Nothing to say: the entries stay in the Trash until the next try.
+    }
   }
 
   Future<void> _closeStaleSessions() async {
@@ -52,6 +72,7 @@ class _MemoxAppState extends ConsumerState<MemoxApp> {
 
   @override
   void dispose() {
+    _lifecycle.dispose();
     _router.dispose();
     super.dispose();
   }
```

`lib/features/trash/presentation/screens/trash_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/trash/presentation/screens/trash_screen.dart b/lib/features/trash/presentation/screens/trash_screen.dart
index bbe7d92..2a44741 100644
--- a/lib/features/trash/presentation/screens/trash_screen.dart
+++ b/lib/features/trash/presentation/screens/trash_screen.dart
@@ -3,6 +3,7 @@ import 'dart:async';
 import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:memox/core/clock/di/day_clock_provider.dart';
+import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/core/theme/foundations/app_spacing.dart';
 import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
@@ -44,6 +45,22 @@ class _TrashScreenState extends ConsumerState<TrashScreen> {
 
   TrashController _trash() => ref.read(trashControllerProvider.notifier);
 
+  @override
+  void initState() {
+    super.initState();
+    unawaited(_purgeExpired());
+  }
+
+  /// Opening the Trash purges what expired (UC-TRASH-001 A4); the stream
+  /// drops those rows in place. A failure keeps them for the next try.
+  Future<void> _purgeExpired() async {
+    try {
+      await _trash().purgeExpired();
+    } on Failure {
+      // The list still shows; the next start, resume or visit retries.
+    }
+  }
+
   Future<void> _openActions(TrashEntry entry) async {
     final action = await showTrashEntryActionsSheet(
       context,
```

- [ ] **Step 4: Run**

```bash
flutter test test/app test/features/trash
flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/app.dart \
  lib/features/trash/presentation/screens/trash_screen.dart \
  test/app/trash_auto_purge_test.dart
git commit -m "$(cat <<'EOF'
feat(trash): expired entries go at start, on resume and when the Trash opens (FE-B1 D5)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 7: Detail file 06, index, register, use case, WBS; the gate

**Files:**
- Modify: `docs/features/trash/README.md`
- Modify: `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`
- Create: `docs/shared/ui/screen-handoff/06-trash.md`
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents). The kit's captures of screen 06 are already in
`docs/shared/ui/screen-handoff/img/06-trash/`.

- [ ] **Step 1: Update the documents**

`docs/features/trash/README.md` (apply this diff):

```diff
diff --git a/docs/features/trash/README.md b/docs/features/trash/README.md
index d0945a1..aea3c87 100644
--- a/docs/features/trash/README.md
+++ b/docs/features/trash/README.md
@@ -1,6 +1,6 @@
 ---
 feature: trash
-code: [lib/features/trash/domain, lib/features/trash/data, lib/features/trash/di]
+code: [lib/features/trash/domain, lib/features/trash/data, lib/features/trash/di, lib/features/trash/presentation]
 depends_on: [card, deck, srs]
 ---
 ## Phạm vi
@@ -33,5 +33,4 @@ Nguồn: trigger của UC-TRASH-001.
 
 | Thứ | Vì sao |
 |---|---|
-| Màn Trash, câu chữ của hộp thoại xoá, snackbar Undo và thời gian của nó, lúc gọi auto-purge, xác nhận purge | FE-B1 ([`wbs_FE.md`](../../wbs_FE.md)); tới lúc đó hộp thoại xoá giữ câu chữ "xoá vĩnh viễn" và chưa gì gọi auto-purge (spec D15) |
 | Đồng bộ batch giữa các thiết bị | `owner_id` luôn NULL; thuộc sub-project auth/sync sau |
```

`docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md` (apply this diff):

```diff
diff --git a/docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md b/docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
index 924209c..696adff 100644
--- a/docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
+++ b/docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md
@@ -3,7 +3,7 @@ id: UC-TRASH-001
 title: Trash và khôi phục item đã xoá
 status: ready
 rules: [BR-CARD-010, BR-CARD-012, BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-015, BR-DECK-017, BR-DECK-018, BR-SRS-006, BR-TRASH-001, BR-TRASH-002, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-006, BR-TRASH-007, BR-TRASH-008, BR-TRASH-009, BR-TRASH-010, BR-TRASH-011, BR-TRASH-012]
-code: [lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart, lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart, lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart, lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart, lib/features/trash/domain/usecases/purge_trash_use_case.dart, lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart, lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/undo_card_deletion_use_case.dart]
+code: [lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart, lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart, lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart, lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart, lib/features/trash/domain/usecases/purge_trash_use_case.dart, lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart, lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/undo_card_deletion_use_case.dart, lib/features/trash/presentation/controllers/trash_controller.dart, lib/features/trash/presentation/screens/trash_screen.dart, lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart, lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 49b35ac..562bbce 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -35,7 +35,7 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 03 | Starter decks | 10 | FE-B4 | out of V8 | — |
 | 04 | Library search | 5 | FE-A1, FE-A10 | aligned | [04-library-search.md](04-library-search.md) |
 | 05 | Tags | 12 | FE-B2 | out of V8 | — |
-| 06 | Trash | 15 | FE-B1 | not built | — (FE-B1 plan 2) |
+| 06 | Trash | 15 | FE-B1 | aligned | [06-trash.md](06-trash.md) |
 | 07 | Card list | 15 | FE-A2 | aligned | [07-card-list.md](07-card-list.md) |
 | 08 | Card create | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
 | 09 | Card edit | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84; Move to Trash in [07-card-list.md](07-card-list.md)) |
```

`docs/shared/ui/screen-handoff/01-deck-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/01-deck-list.md b/docs/shared/ui/screen-handoff/01-deck-list.md
index cd087e7..4e42a5a 100644
--- a/docs/shared/ui/screen-handoff/01-deck-list.md
+++ b/docs/shared/ui/screen-handoff/01-deck-list.md
@@ -71,7 +71,7 @@ One `MxBottomSheet`, "Sort & filter":
 | deckMaxDepth | ![](img/01-deck-list/deckMaxDepth-light.png) | ![](img/01-deck-list/deckMaxDepth-dark.png) | No FAB. |
 | deckLoading | ![](img/01-deck-list/deckLoading-light.png) | ![](img/01-deck-list/deckLoading-dark.png) | As drawn. |
 | deckError | ![](img/01-deck-list/deckError-light.png) | ![](img/01-deck-list/deckError-dark.png) | As drawn. |
-| deckNotFound | ![](img/01-deck-list/deckNotFound-light.png) | ![](img/01-deck-list/deckNotFound-dark.png) | The kit's body. Back to Library only until FE-B1 plan 2 adds Open Trash; replaces ruling P2-L7. |
+| deckNotFound | ![](img/01-deck-list/deckNotFound-light.png) | ![](img/01-deck-list/deckNotFound-dark.png) | The kit's body, Back to Library and Open Trash (FE-B1 D11); replaces ruling P2-L7. |
 | deckOverflow | ![](img/01-deck-list/deckOverflow-light.png) | ![](img/01-deck-list/deckOverflow-dark.png) | As drawn. |
 | deckMove | ![](img/01-deck-list/deckMove-light.png) | ![](img/01-deck-list/deckMove-dark.png) | As drawn (UC-DECK-005 checks). |
 | deckDelete | ![](img/01-deck-list/deckDelete-light.png) | ![](img/01-deck-list/deckDelete-dark.png) | As rootDelete. |
@@ -81,6 +81,7 @@ One `MxBottomSheet`, "Sort & filter":
 
 | Artifact | V8 | Wins |
 |---|---|---|
+| Starter decks · Tags · Trash in the root app bar | Trash · Coming soon (which names starter decks and tags) | FE-B4 and FE-B2 wait (FE-B1 D1) |
 | A trash glyph over the Move to Trash dialog's title, the deck's name in bold | No glyph; the name in quotes | `MxDialog` has no glyph slot; no per-site text styling |
 | "Can't undo — “{deck}” is in Trash too. Restore it from here and choose a deck." on screen 06 | "Can't undo. {reason} Restore it from Trash and choose a deck." where the deck was deleted | An Undo happens where the item was deleted; the rejection carries no deck name (FE-B1 D7) |
 | Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
@@ -100,13 +101,12 @@ One `MxBottomSheet`, "Sort & filter":
 
 | Element | Shown as | Waits for |
 |---|---|---|
-| Starter decks, Tags, Trash actions | under Coming soon | FE-B4, FE-B2, FE-B1 |
+| Starter decks, Tags actions | under Coming soon | FE-B4, FE-B2 |
 | "Browse starter decks" | under Coming soon | FE-B4 |
 | Study options | under Coming soon | FE-A3 |
 | Sort by progress | under Coming soon | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Mastery bar, donut | hidden | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Due strip tap | not interactive | FE-A8 |
-| "Open Trash" | under Coming soon (as Trash) | FE-B1 |
 | Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at level 10 | absent; the header says "· level 10" | a later phase (owner decision C-O6) |
 
 ## Copy
@@ -118,7 +118,7 @@ One `MxBottomSheet`, "Sort & filter":
 - Due filter, none: "Nothing due right now" · "No deck has cards waiting. The next card becomes due tomorrow at 00:00." · "Show all decks".
 - Create: "New deck" · "Holds sub-decks; sub-decks hold cards." · "Name" · "Review algorithm · required" · "Eight boxes" / "Cards move up a box each time you remember them, back to box 1 when you forget. Forgiving of long breaks." · "SM-2" / "Intervals adapt to how well you recall each card. You grade yourself: again · hard · good · easy." · "Locks once the first card finishes learning. After that, only “Reset learning progress” starts a new cycle." · "Cancel" · "Create deck".
 - Rename: "Rename deck" · "Only the name changes — sub-decks, cards and schedules stay as they are." · "Rename".
-- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash" (FE-B1 plan 2).
+- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash".
 - Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck to Trash?" · "“{name}” goes to Trash with its {n} sub-decks and {n} cards." · "Recoverable from Trash for 30 days. Any open study session on these cards ends." · "Cancel" · "Move to Trash" · "“{name}” moved to Trash · {n} sub-decks, {n} cards" · "Undo".
 - Move: "Move “{name}” to…" · "Its {n} sub-decks and {n} cards come along, schedules included. Only decks in the same review algorithm can receive it." · "Move here".
 - Sort & filter: as in "Sort & filter sheet".
```

`docs/shared/ui/screen-handoff/06-trash.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 06 · Trash

Everything deleted in the last 30 days, newest first. Each entry can be restored to a
place the person picks, or deleted for good. UC-TRASH-001; spec
[2026-09-26-trash-ui-design.md](../../../superpowers/specs/2026-09-26-trash-ui-design.md)
§6.

## Entry points

- **The Library's app bar:** the Trash icon, beside Coming soon (D1).
- **Toasts:** the toast after several cards move to the Trash, and every refused Undo,
  both through "Open Trash" (D4, UC-TRASH-001 E3).
- **Gone states:** the "no longer here" states of an open deck, the card editor and the
  card detail, through "Open Trash" (D11).

The Trash is a full-screen task on the root navigator, `/decks/trash`, with no bottom
bar (D2). Opening it runs the auto-purge, as the app's start and every resume do (D5).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back, "Trash" and "Select" (a compact secondary `MxButton`; hidden when the Trash is empty). While selecting: close, then "Select entries", "{n} cards selected" or "{n} decks selected". |
| Note | `MxNote` (history icon) | "Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go." |
| Filters | `MxFilterChip` × 3 | All · Cards · Decks, each with its count (A6). Hidden while selecting. |
| Header | `MxListSectionHeader` | "{n} entries · newest first"; while selecting, "{n} of {m} cards" or "decks". |
| Rows | `MxCard` + `MxRowInk` per entry | The kind's tile (a checkbox while selecting). The name ("front · back" for a card), and the time left on the right, in the warning ink under 3 days. Then "Card · deleted {ago}" or "Deck · {n} sub-decks · {m} cards · deleted {ago}", then "Was in {path}" or "Was in Top level". Then `⋮`. The row is one TalkBack node with every fact (D15). |
| Kind lock | `MxNote` | "Only cards are selectable while cards are selected — a selection never mixes cards and decks." (or decks). |
| Blocked purge | `MxInlineBanner` (warning) | One per batch the last purge skipped (D6). |
| Bar | `MxFooterBar` | While selecting: "Restore {n}…" (primary) · "Delete for good" (destructive). Both are disabled until a pick. |
| Actions | `MxBottomSheet` + `MxActionSheetCommandRow` × 2 | The name and "{kind} · deleted {ago} · was in {deck}"; "Restore…" / "Choose which deck it goes to"; "Delete permanently" / "Cannot be undone · history lost" (destructive). |
| Restore | `MxDeckPickerSheet` | "Restore “{name}” to…" or "Restore {n} cards/decks to…", the rule, then the targets as paths, or the single "Top level" for top-level decks. With no target: "Nowhere to restore right now", why, and OK. |
| Delete for good | `MxDialog` + `MxSheetActions.custom` | "Delete {n} cards permanently?", "They disappear for good, together with their study history. This cannot be undone.", "Keep in Trash" (primary, focused) · "Delete {n}" (destructive, spinning while it runs). |
| Toasts | `MxSnackbar` | "“{name}” restored to {deck}" / "{n} entries restored to {deck}"; "{n} cards deleted permanently". |

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| all | ![](img/06-trash/all-light.png) | ![](img/06-trash/all-dark.png) | As drawn; the tile is tinted, and "Was in" has no glyph. |
| cards | ![](img/06-trash/cards-light.png) | ![](img/06-trash/cards-dark.png) | As drawn. |
| decks | ![](img/06-trash/decks-light.png) | ![](img/06-trash/decks-dark.png) | As drawn. |
| actions | ![](img/06-trash/actions-light.png) | ![](img/06-trash/actions-dark.png) | As drawn; a row tap opens it too. |
| restoreTarget | ![](img/06-trash/restoreTarget-light.png) | ![](img/06-trash/restoreTarget-dark.png) | Targets read as paths, without counts or "where it was". |
| noTarget | ![](img/06-trash/noTarget-light.png) | ![](img/06-trash/noTarget-dark.png) | As drawn. |
| restored | ![](img/06-trash/restored-light.png) | ![](img/06-trash/restored-dark.png) | As drawn. |
| undoRefused | ![](img/06-trash/undoRefused-light.png) | ![](img/06-trash/undoRefused-dark.png) | Shown where the item was deleted, with Open Trash (UI-base row 109). |
| selection | ![](img/06-trash/selection-light.png) | ![](img/06-trash/selection-dark.png) | As drawn; "Delete for good" is a filled destructive button. |
| purgeConfirm | ![](img/06-trash/purgeConfirm-light.png) | ![](img/06-trash/purgeConfirm-dark.png) | No glyph, left-aligned (UI-base row 108). |
| purged | ![](img/06-trash/purged-light.png) | ![](img/06-trash/purged-dark.png) | As drawn. |
| youngerInside | ![](img/06-trash/youngerInside-light.png) | ![](img/06-trash/youngerInside-dark.png) | **Deviation:** "deleted earlier", in a warning banner (D6). |
| empty | ![](img/06-trash/empty-light.png) | ![](img/06-trash/empty-dark.png) | As drawn. |
| loading | ![](img/06-trash/loading-light.png) | ![](img/06-trash/loading-dark.png) | Skeleton rows. |
| error | ![](img/06-trash/error-light.png) | ![](img/06-trash/error-dark.png) | The app's local-first body, "Nothing was lost. Try again in a moment." |

Goldens: `test/features/trash/presentation/goldens/trash_{all,actions,restore_target,no_target,selection,purge_confirm,purge_blocked,empty,error}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "“X” still contains a card deleted later" | "“X” still contains an entry deleted earlier (“Y”)", in a warning banner, one per blocked batch | Invariant 36 (spec D6) |
| A restore target with its name, path, card count and "where it was" | The path, as the move sheets show targets | `CardMoveTarget` and `DeckMoveTarget` carry no counts (ruling P3-L8) |
| A card's restore sheet only | A deck's sheet with its own rule, and "Top level" for a top-level deck | BR-TRASH-006 |
| "Select" as a text link | A compact secondary `MxButton` | Ruling E-L3 |
| A neutral grey kind tile; "Was in" after a corner glyph | The tinted `MxIconTile`; the text alone | The shared tile's tones; no per-site glyph ink |
| "Delete for good" as a red outline | A filled destructive `MxButton` | `MxButton` has no destructive outline |
| A refusal inside the restore sheet | The sheet closes and the refusal is a toast; the list follows the store | As the move sheets (spec §6) |

## Copy

- Header: "Trash" · "Select" · "Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go." · "All" · "Cards" · "Decks" · "{n} entries · newest first".
- Row: "Card · deleted {ago}" · "Deck · {n} sub-decks · {m} cards · deleted {ago}" · "just now" / "{n} minutes ago" / "{n} hours ago" / "yesterday" / "{n} days ago" · "{n} days left" · "{n}h left" · "Was in {path}" · "Top level" · "Actions for {name}".
- Actions: "Restore…" · "Choose which deck it goes to" · "Delete permanently" · "Cannot be undone · history lost".
- Restore: "Restore “{name}” to…" · "Its schedule, history, flag and tags come back with it. Only decks in the same tree that hold cards or are empty are offered." · "Nowhere to restore right now" · "No deck in “{root}” can hold cards at the moment. Create an empty sub-deck there, then restore." · "“{name}” restored to {deck}".
- Selection: "Select entries" · "{n} cards selected" · "{n} of {m} cards" · "Only cards are selectable while cards are selected — a selection never mixes cards and decks." · "Restore {n}…" · "Delete for good" · "Clear selection".
- Delete for good: "Delete {n} cards permanently?" · "They disappear for good, together with their study history. This cannot be undone." · "Keep in Trash" · "Delete {n}" · "{n} cards deleted permanently".
- Empty and error: "Trash is empty" · "Decks and cards you delete stay here for 30 days before they are removed for good." · "Couldn't open Trash".
```

`docs/shared/ui/screen-handoff/07-card-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/07-card-list.md b/docs/shared/ui/screen-handoff/07-card-list.md
index 1268d97..1b3a323 100644
--- a/docs/shared/ui/screen-handoff/07-card-list.md
+++ b/docs/shared/ui/screen-handoff/07-card-list.md
@@ -41,7 +41,7 @@ Study this deck · Rename · Move to another deck · Import cards (screen 11) ·
 | bulkFailed | ![](img/07-card-list/bulkFailed-light.png) | ![](img/07-card-list/bulkFailed-dark.png) | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Trash keep their sheet or dialog open and say it there. The selection stays. |
 | delCard | ![](img/07-card-list/delCard-light.png) | ![](img/07-card-list/delCard-dark.png) | One selected card, as drawn, without the glyph. Several: "Move {n} cards to Trash?" without the preview. The confirm spins while they move (FE-B1 D15). |
 | delDeck | ![](img/07-card-list/delDeck-light.png) | ![](img/07-card-list/delDeck-dark.png) | As screen 01 deckDelete. |
-| trashed | ![](img/07-card-list/trashed-light.png) | ![](img/07-card-list/trashed-dark.png) | One card: as drawn, Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash", no Undo (D4); FE-B1 plan 2 adds Open Trash. |
+| trashed | ![](img/07-card-list/trashed-light.png) | ![](img/07-card-list/trashed-dark.png) | One card: as drawn, Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash" with Open Trash, no Undo (D4). |
 
 Not captured: `cardActions` gives way to the card detail: a tap opens it (#35). The card
 editor (screen 09) moves its card to the Trash from its "More" card with the same dialog
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index 0351784..425cdb3 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -487,12 +487,12 @@ item names where it comes from.
 | 84 | A top-level deck holds sub-decks only, so its empty state offers New sub-deck alone, with its own copy; New card shows where the deck's create options include cards | library phase 4a (Task 4 ruling) |
 | 85 | The card detail follows the V3 kit (10) over library spec §6.6: a schedule card with the eight-box ramp or the SM-2 facts, history grouped by cycle, Load older history, and an end-of-history line | library phase 4b P4b-L1 |
 | 86 | History events show the absolute date and time only, with no timeline rail or dots and no "Finished learning" note; cycle headers carry no reset date, which the backend does not store | library phase 4b P4b-L3, P4b-L4 |
-| 87 | The card detail's gone state offers Back to deck only; Open Trash waits for Trash | library phase 4b P4b-L5 |
+| 87 | The card detail's gone state offers Back to deck only; Open Trash waits for Trash — closed by FE-B1 (D11) | library phase 4b P4b-L5 |
 | 88 | The card detail's deck path includes the destination line of the editor's header, which the kit's detail does not show | library phase 4b P4b-L8 |
 | 89 | The card detail puts the status badge and flag above the front, not beside it, so a long front keeps the full width | library phase 4b (Task 5 golden review) |
 | 90 | A history event's badge carries the kind only (Learning, Review, Repeat) and the action is text beside it: `MxBadge` never wraps, so the kit's "kind · action" pill overflowed at text scale 2 | library deferred minors |
 | 91 | On the empty Library, "Browse starter decks" is disabled without the spec A4 "not available yet" hint: `MxEmptyState` has no slot for a hint on its secondary action. Every other waiting control on screen 01 carries it — superseded by row 92: the button is gone | Impeccable review (critique + audit) |
-| 92 | Controls whose feature does not exist yet are hidden, not drawn disabled as the kit draws them. The Library root's "Coming soon" app-bar action opens a sheet naming each: Study, Study options, Sort by progress, Tags, Starter decks, Trash, Import and export (library alignment spec A4, amended 2026-09-25) | owner decision after the Impeccable critique |
+| 92 | Controls whose feature does not exist yet are hidden, not drawn disabled as the kit draws them. The Library root's "Coming soon" app-bar action opens a sheet naming each: Study, Study options, Sort by progress, Tags, Starter decks, Trash, Import and export (library alignment spec A4, amended 2026-09-25) — Trash left the sheet for its own app-bar icon with FE-B1 (D1) | owner decision after the Impeccable critique |
 | 91 | A deck row's meta and the due strip's tile carry no coloured glyph: the guard bans `Icon(color:)` in feature code | library alignment phase C (C-L1) |
 | 92 | The deck row's name is `rowTitle` (14/600), not the kit's 14/700, and the search match is a named role (`rowTitleMatch`) drawn by `MxListRow.titleMatch`, with no tinted mark: no per-site text styling | library alignment phase C (C-L2, C-O7) |
 | 93 | "Review algorithm" opens the scheduler sheet, not screen 02, until phase D — closed by library alignment phase D | library alignment phase C (C-L3) |
@@ -513,6 +513,8 @@ item names where it comes from.
 | 108 | The Move to Trash dialogs (screens 01, 07, 09) draw no trash glyph over or beside their title: `MxDialog` has no glyph slot | FE-B1 plan 1 |
 | 109 | A refused Undo reads "Can't undo. {reason} Restore it from Trash and choose a deck." where the item was deleted, not screen 06's "Can't undo — “{deck}” is in Trash too. Restore it from here…": the rejection carries no deck name | FE-B1 D7 |
 | 110 | Move to Trash names no counts the dialog cannot read: the card note says "with its schedule and history", not "with its 7 answers of history", and the editor's "More" card says "Leaves this deck", not the deck's name, which the path above it shows | FE-B1 plan 1 |
+| 111 | A Trash restore target reads as its path, without the kit's card count or "where it was": `CardMoveTarget` and `DeckMoveTarget` carry no counts, as in the move sheets | FE-B1 plan 2 |
+| 112 | Screen 06's kind tile is the tinted `MxIconTile`, not the kit's grey one, and "Was in" has no corner glyph; "Select" is a compact secondary `MxButton` (ruling E-L3); "Delete for good" is a filled destructive `MxButton`, not a red outline | FE-B1 plan 2 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 8696c76..512435a 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -87,7 +87,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 
 | ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
 |---|---|---|---|---|---|---|
-| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | đang làm | BE-B1, FE-A1, FE-A2 | M | [spec](superpowers/specs/2026-09-26-trash-ui-design.md); [plan 1: luồng xoá, Undo, câu chữ](superpowers/plans/2026-09-26-trash-delete-flows.md) xong; plan 2 (màn 06, lối vào, auto-purge) còn lại. Hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
+| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | xong | BE-B1, FE-A1, FE-A2 | M | [spec](superpowers/specs/2026-09-26-trash-ui-design.md); [plan 1: luồng xoá, Undo, câu chữ](superpowers/plans/2026-09-26-trash-delete-flows.md); [plan 2: màn 06, lối vào, auto-purge](superpowers/plans/2026-09-26-trash-screen.md); [screen handoff 06](shared/ui/screen-handoff/06-trash.md). Hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
 | FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
 | FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
 | FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
```

- [ ] **Step 2: Regenerate the docs index and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: no error. The existing warnings stay. `wbs_FE.md` links this plan, which is
already on the branch.

- [ ] **Step 3: The gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: every gate green.

- [ ] **Step 4: Commit and push**

```bash
git add \
  docs/features/trash/README.md \
  docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/06-trash.md \
  docs/shared/ui/screen-handoff/07-card-list.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_FE.md \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(trash): FE-B1 done: detail file 06, register rows 111-112, UC-TRASH-001

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
