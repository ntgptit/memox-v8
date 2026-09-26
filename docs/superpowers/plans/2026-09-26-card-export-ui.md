# MemoX V8 Card Export UI Implementation Plan (FE-B3, plan 2 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish FE-B3 in [`docs/wbs_FE.md`](../../wbs_FE.md) with the export half: kit sheet
12, "Export cards", over the BE-B3 export use cases. It opens from the open deck's `⋮`
(the whole deck) and from the card list's bulk bar (the selection).

**Architecture:**
- **Sheet and controller.** `lib/features/transfer/presentation/` gains a bottom sheet
  and one `@riverpod` controller per sheet. The controller is keyed by the sheet's scope,
  a value object: the whole deck with its count, or a set of card ids. It builds the
  file, hands it to the share sheet, and holds the format, whether a file is being
  prepared, and one problem.
- **The sheet never loads.** A whole-deck export counts the deck's cards through a new
  use case before the sheet opens. A selection knows its size.
- **Entry points.** The deck feature and the card feature learn about export only through
  callbacks. `app/` wires them, because neither may import `transfer`.
- **One shared widget change.** `MxSheetActions` gains a loading confirm.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, Drift, gen-l10n (en, vi). No new package: `share_plus` came with BE-B3.

**Spec:** [`docs/superpowers/specs/2026-09-26-card-transfer-design.md`](../specs/2026-09-26-card-transfer-design.md)
§6–§8, with the owner's kit rulings of 2026-09-26 (E1–E6 and the primary label, below).
Use case: UC-TRANSFER-002. The kit is the visual authority: "MemoX — Mobile UI Kit v3",
screen 12, 9 states.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` with plan 1 done
([import plan](2026-09-26-card-import-ui.md)). Generated code is not committed: in a fresh
working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first.

**How this plan was checked:**
- Every task was built and committed in a scratch worktree of this branch, and each
  task's blocks below are that commit's files and diffs.
- The full gate (`dod_check.sh --force`) passed there with 1,551 host tests, a clean
  `flutter analyze`, a clean guard and clean architecture boundaries.
- The goldens were compared with the kit captures.
- Rules were then broken on purpose, and each break failed a test:
  - a dismissed share sheet reported as an error;
  - the share made after the sheet closed;
  - a second tap building a second file;
  - Export offered on every deck;
  - the count including cards in the Trash;
  - Export clearing the selection.
- The first review of the goldens found two things, both fixed in the code below:
  - the format overline, the banner and the note were not lined up with the title;
  - the one-card title read "Export the 1 card".

## Clarifications (rulings; amend the spec where they differ)

- **X1 (owner, ruling E1; UC-TRANSFER-002 A3 beats the kit).** Closing the share sheet
  leaves the export sheet open as it was, with the same scope and format. The kit closes
  it.
- **X2 (owner, ruling E2; spec §7).** The toast is "Handed {n} cards to the system." It
  names no file, unlike the kit.
- **X3 (owner, ruling E3; UC step 2).** CSV carries a "Recommended" badge.
- **X4 (owner, ruling E4).** Problems map to banners like this:
  - a read failure (a thrown `Failure`) and an encode failure (`encodeFailed`) share the
    kit's "Couldn't prepare the file";
  - a share failure (`shareFailed`) has its own copy;
  - both offer Try again, which exports again with the same scope and format;
  - no share target, a stale selection and an empty scope offer Close only.
- **X5 (owner, ruling E5; UC E5).** The `⋮` sheet offers "Export cards" only on a deck of
  cards, which holds at least one card (E-L1). The bulk bar gains Export between Tag and
  Delete. Coming soon drops its transfer row, and `AppIcons.transfer` goes with it.
- **X6 (owner, ruling E6; UC A1).** Export keeps the selection. Cancel while a file is
  prepared closes the sheet, and nothing is shared: the controller is auto-disposed with
  the sheet, and `_build` stops once `ref.mounted` is false.
- **X7 (owner).** The primary action reads "Export {n} cards" (UC step 3), not the kit's
  "Export and share". It keeps the share glyph.
- **X8 (UC UI states: "no loading state").** The whole-deck entry,
  `showDeckExportSheet`, counts the cards through `CountExportCardsUseCase` before the
  sheet opens.
  - The use case reads a new `CardRepository.countCards` (live cards only).
  - `app/` has no `WidgetRef`, so the entry reads it with
    `ProviderScope.containerOf(context, listen: false)`.
  - A count of 0 opens the sheet on "nothing to export".
- **X9.** The deck feature takes `ValueChanged<DeckEntity> onExportCards`. The card list
  takes an optional `ValueChanged<Set<String>> onExport`; Export is hidden without it.
  `app/` passes both. `library_harness.cardDeckScreen` passes `onExport` as `app/` does,
  so the card list goldens show the kit's five-action bar.
- **X10.** `MxSheetActions` gains `isConfirmLoading`: the confirm spins and cannot be
  pressed, and Cancel stays live. The kit's "Preparing…" needs it, and no other widget
  has that pair.
- **X11.** The kit's stale-selection copy says "sent to Trash". V8.0 has no Trash, so it
  reads "moved or deleted". The kit draws one glyph per banner; `MxInlineBanner` shows
  its tone's glyph.
- **X12.** The Android build is unchanged: this plan adds no plugin. The `build-apk` run
  owed since plan 1 still stands.

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screen 12 is the visual authority. Every difference is in X1–X12 or in
  `docs/shared/ui/screen-handoff/12-card-export.md`.
- **Guard rules:**
  - only `Mx*` widgets and theme tokens;
  - no raw colour, `TextStyle`, spacing or radius literal;
  - `IconTheme.merge` instead of `Icon(color:)`;
  - no `ref.read` inside `build`;
  - no literal user string;
  - booleans read as predicates.
- File suffixes and widget buckets follow the guard (`_controller`, `_state`, `_provider`,
  `_use_case`, `_widget` in `overlays/` or `support/`).
- Every read goes through a use case (ADR-011 D4). The import map is unchanged:
  `transfer` imports `card`, and `card` and `deck` never import `transfer`.
- Nothing logs card content or a file name. No message carries a path, a file name or an
  id (BR-CORE-005, BR-TRANSFER-014).
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- Goldens render in the Linux container only; on Windows run
  `flutter test --exclude-tags golden` and never `--update-goldens`.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **The user backs out of the share sheet:** no error, and the export sheet is as it was.
   Tests: "closing the share sheet is a cancel…" (controller) and "closing the share sheet
   keeps the export sheet as it was" (sheet).
2. **The user cancels while the file is prepared:** nothing is shared later. Test:
   "closing the sheet while the file is prepared shares nothing".
3. **A selected card is deleted or moved meanwhile:** no partial file, and Close only.
   Tests: "a selection with a card gone meanwhile exports nothing (E6)", in both files.
4. **Export tapped twice:** one file. Test: "a second tap while the file is prepared
   makes no second file (A4)".
5. **Export from the bulk bar:** the selection stays for the next command. Tests: "Export
   hands the selection over and keeps it" and the route test.

## File map

| File | Task | Responsibility |
|---|---|---|
| `lib/features/card/data/datasources/card_dao.dart`, `…/card_repository.dart`, `…/card_repository_impl.dart` | 1 | `countCards` |
| `lib/features/transfer/domain/usecases/count_export_cards_use_case.dart` | 1 | the count before the sheet |
| `lib/features/transfer/presentation/providers/{build_export,share_export,count_export_cards}_use_case_provider.dart` | 1 | the three export use cases |
| `lib/features/transfer/presentation/states/card_export_state.dart` | 2 | scope, problem, state |
| `lib/features/transfer/presentation/controllers/card_export_controller.dart` | 2 | build, share, map outcomes |
| `test/support/fake_export_share.dart` | 2 | the share sheet in tests |
| `lib/shared/widgets/mx_sheet_actions.dart` | 3 | `isConfirmLoading` |
| `lib/core/theme/foundations/app_icons.dart` | 3, 4 | `share`, `fileDown`; `transfer` removed |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | 3, 4 | the sheet's copy; entry labels; Coming soon loses export |
| `lib/features/transfer/presentation/widgets/{overlays/card_export_sheet_widget,support/export_labels_widget}.dart` | 3 | the sheet and its two entry functions |
| `lib/features/deck/presentation/**` (4 files), `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`, `lib/app/router/app_router.dart` | 4 | the entry points |
| `tools/design/screen_states.json`, `docs/**` | 5 | kit capture, detail file, index, WBS, use cases |

---


### Task 1: The count before the sheet, and the export use case providers

**Files:**
- Modify: `lib/features/card/data/datasources/card_dao.dart`
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart`
- Modify: `lib/features/card/domain/repositories/card_repository.dart`
- Create: `lib/features/transfer/domain/usecases/count_export_cards_use_case.dart`
- Create: `lib/features/transfer/presentation/providers/build_export_use_case_provider.dart`
- Create: `lib/features/transfer/presentation/providers/count_export_cards_use_case_provider.dart`
- Create: `lib/features/transfer/presentation/providers/share_export_use_case_provider.dart`
- Test (create): `test/features/card/data/card_count_test.dart`

**Interfaces:**
- Produces: `CardRepository.countCards(String deckId) → Future<int>`, the live cards of the
  deck, and 0 for a deck that is gone; `CardDao.liveCount`;
  `CountExportCardsUseCase(CardRepository)` with `Future<int> call(String deckId)`;
  `countExportCardsUseCaseProvider`, `buildExportUseCaseProvider`,
  `shareExportUseCaseProvider`.

- [ ] **Step 1: Write the failing test**

`test/features/card/data/card_count_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The count a whole-deck export names before its sheet opens
// (UC-TRANSFER-002 step 1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db),
      TagRepositoryImpl(db),
    );
  });
  tearDown(() => db.close());

  test(
    'counts the live cards of the deck, not those of others or in the Trash',
    () async {
      final root = await decks.root('r');
      final leaf = await decks.sub(root.id, 'l');
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'a', deckId: leaf.id);
      await insertCard(db, id: 'b', deckId: leaf.id);
      await insertCard(db, id: 'c', deckId: leaf.id, deleteBatchId: 'batch');
      await insertCard(db, id: 'x', deckId: other.id);

      expect(await cards.countCards(leaf.id), 2);
      expect(await cards.countCards(root.id), 0);
      expect(await cards.countCards('missing'), 0);
    },
  );
}
```

- [ ] **Step 2: Run it to see it fail**

```bash
flutter test test/features/card/data/card_count_test.dart
```

Expected: FAIL to compile: `countCards` is not defined.

- [ ] **Step 3: Implement**

`lib/features/card/data/datasources/card_dao.dart` (apply this diff):

```diff
diff --git a/lib/features/card/data/datasources/card_dao.dart b/lib/features/card/data/datasources/card_dao.dart
index 99d5dda..55b1ff6 100644
--- a/lib/features/card/data/datasources/card_dao.dart
+++ b/lib/features/card/data/datasources/card_dao.dart
@@ -46,6 +46,15 @@ final class CardDao {
     };
   }
 
+  /// How many live cards [deckId] holds.
+  Future<int> liveCount(String deckId) {
+    final count = _db.card.id.count();
+    final query = _db.selectOnly(_db.card)
+      ..addColumns([count])
+      ..where(_db.card.deckId.equals(deckId) & _db.card.deleteBatchId.isNull());
+    return query.map((row) => row.read(count)!).getSingle();
+  }
+
   /// The live cards of [deckId], or those among [ids], by `created_at`, then
   /// `id` (BR-TRANSFER-010).
   Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) =>
```

`lib/features/card/data/repositories/card_repository_impl.dart` (apply this diff):

```diff
diff --git a/lib/features/card/data/repositories/card_repository_impl.dart b/lib/features/card/data/repositories/card_repository_impl.dart
index 974a894..637c7e7 100644
--- a/lib/features/card/data/repositories/card_repository_impl.dart
+++ b/lib/features/card/data/repositories/card_repository_impl.dart
@@ -353,6 +353,10 @@ final class CardRepositoryImpl implements CardRepository {
     });
   }
 
+  @override
+  Future<int> countCards(String deckId) =>
+      _mapped(() => _dao.liveCount(deckId));
+
   @override
   Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
     required String deckId,
```

`lib/features/card/domain/repositories/card_repository.dart` (apply this diff):

```diff
diff --git a/lib/features/card/domain/repositories/card_repository.dart b/lib/features/card/domain/repositories/card_repository.dart
index ef2a2b9..a8f836e 100644
--- a/lib/features/card/domain/repositories/card_repository.dart
+++ b/lib/features/card/domain/repositories/card_repository.dart
@@ -108,6 +108,11 @@ abstract interface class CardRepository {
     DateTime? now,
   });
 
+  /// UC-TRANSFER-002 step 1: how many live cards [deckId] holds, the count a
+  /// whole-deck export names before its sheet opens; 0 for a deck that is
+  /// gone.
+  Future<int> countCards(String deckId);
+
   /// UC-TRANSFER-002 step 4: the deck's name and its live cards, or those of
   /// [cardIds], in one read that writes nothing (BR-TRANSFER-010,
   /// BR-TRANSFER-011). A missing deck, or an id that is gone or in another
```

`lib/features/transfer/domain/usecases/count_export_cards_use_case.dart`:

```dart
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRANSFER-002 step 1: how many cards a whole-deck export holds, read
/// before its sheet opens so the sheet itself never loads. 0 opens the
/// sheet on "nothing to export" (E5).
final class CountExportCardsUseCase {
  const CountExportCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<int> call(String deckId) => _cards.countCards(deckId);
}
```

`lib/features/transfer/presentation/providers/build_export_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_export_use_case_provider.g.dart';

@riverpod
BuildExportUseCase buildExportUseCase(Ref ref) => BuildExportUseCase(
  ref.watch(cardRepositoryProvider),
  ref.watch(transferFileRepositoryProvider),
);
```

`lib/features/transfer/presentation/providers/count_export_cards_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/count_export_cards_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'count_export_cards_use_case_provider.g.dart';

@riverpod
CountExportCardsUseCase countExportCardsUseCase(Ref ref) =>
    CountExportCardsUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/transfer/presentation/providers/share_export_use_case_provider.dart`:

```dart
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/share_export_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_export_use_case_provider.g.dart';

@riverpod
ShareExportUseCase shareExportUseCase(Ref ref) =>
    ShareExportUseCase(ref.watch(exportShareRepositoryProvider));
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card
flutter analyze
```

Expected: PASS; no analyzer issue. Every fake `CardRepository` in the tests implements
`noSuchMethod`, so the new method breaks none of them.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/transfer/domain/usecases/count_export_cards_use_case.dart \
  lib/features/transfer/presentation/providers/build_export_use_case_provider.dart \
  lib/features/transfer/presentation/providers/count_export_cards_use_case_provider.dart \
  lib/features/transfer/presentation/providers/share_export_use_case_provider.dart \
  test/features/card/data/card_count_test.dart
git commit -m "$(cat <<'EOF'
feat(transfer): count a deck's cards before its export sheet opens

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: The export sheet's state and controller

**Files:**
- Create: `lib/features/transfer/presentation/controllers/card_export_controller.dart`
- Create: `lib/features/transfer/presentation/states/card_export_state.dart`
- Test (create): `test/features/transfer/presentation/card_export_controller_test.dart`
- Test (create): `test/support/fake_export_share.dart`

**Interfaces:**
- Consumes: Task 1's `buildExportUseCaseProvider` and `shareExportUseCaseProvider`;
  `dayClockProvider` for the file's date.
- Produces: `CardExportScope.deck({deckId, deckName, cardCount})` and
  `CardExportScope.selection({deckId, ids})`, with value equality; `enum CardExportProblem`
  (`prepareFailed`, `shareFailed`, `noShareTarget`, `staleSelection`, `nothingToExport`,
  and `isFinal`); `CardExportState({format, isPreparing, problem, isHandedOver})` and
  `canExport`; `cardExportControllerProvider(scope)` with `chooseFormat(TransferFormat)`
  and `Future<void> export()`; `FakeExportShare` for tests.

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/presentation/card_export_controller_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:memox/features/transfer/presentation/controllers/card_export_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/test_database.dart';

// The export sheet's states over the real card repository, the real
// encoders run inline, and a fake share sheet (UC-TRANSFER-002).

/// The encoders run inline, and each write waits for [hold] when it is set.
final class _HeldFiles implements TransferFileRepository {
  final _inner = TransferFileRepositoryImpl(
    run: <Q, R>(callback, message) async => callback(message),
  );
  Completer<void>? hold;

  @override
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  ) async {
    await hold?.future;
    return _inner.write(rows, format);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Throws on the read, the way a locked database does (E3), until
/// [isBroken] turns false.
final class _BrokenRead implements CardRepository {
  _BrokenRead(this._cards);

  final CardRepository _cards;
  var isBroken = true;

  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) async {
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'locked');
    return _cards.exportSnapshot(deckId: deckId, cardIds: cardIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckEntity leaf;
  late FakeExportShare share;
  late _HeldFiles files;
  late CardExportScope wholeDeck;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db);
    final root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    await insertCard(db, id: 'a', deckId: leaf.id, front: 'menu', back: 'x');
    await insertCard(db, id: 'b', deckId: leaf.id, front: 'bill', back: 'y');
    share = FakeExportShare();
    files = _HeldFiles();
    wholeDeck = CardExportScope.deck(
      deckId: leaf.id,
      deckName: 'Nhà hàng',
      cardCount: 2,
    );
  });
  tearDown(() => db.close());

  ProviderContainer container({CardRepository Function(CardRepository)? wrap}) {
    final cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db),
      TagRepositoryImpl(db),
    );
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(
          FakeDayClock(DateTime(2026, 9, 26, 9)),
        ),
        transferFileRepositoryProvider.overrideWithValue(files),
        exportShareRepositoryProvider.overrideWithValue(share),
        if (wrap != null) cardRepositoryProvider.overrideWithValue(wrap(cards)),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  ({CardExportController sheet, CardExportState Function() state}) open(
    ProviderContainer c,
    CardExportScope scope,
  ) {
    final provider = cardExportControllerProvider(scope);
    c.listen(provider, (_, _) {});
    return (sheet: c.read(provider.notifier), state: () => c.read(provider));
  }

  test(
    'the whole deck is handed over as a CSV named for the deck and today',
    () async {
      final (:sheet, :state) = open(container(), wholeDeck);
      expect(state().format, TransferFormat.csv);

      await sheet.export();

      expect(state().isHandedOver, isTrue);
      expect(share.shared.single.fileName, 'Nhà-hàng-2026-09-26.csv');
    },
  );

  test('the chosen format is the one written (A2)', () async {
    final (:sheet, :state) = open(container(), wholeDeck);

    sheet.chooseFormat(TransferFormat.xlsx);
    await sheet.export();

    expect(share.shared.single.format, TransferFormat.xlsx);
    expect(share.shared.single.fileName, endsWith('.xlsx'));
  });

  test(
    'closing the share sheet is a cancel: the sheet is as it was (A3)',
    () async {
      share.answer = const Ok(ExportShareResult.dismissed);
      final (:sheet, :state) = open(container(), wholeDeck);
      sheet.chooseFormat(TransferFormat.tsv);

      await sheet.export();

      expect(
        (state().format, state().isPreparing, state().problem),
        (TransferFormat.tsv, false, null),
      );
      expect(state().isHandedOver, isFalse);
    },
  );

  test(
    'no share target is final; a share error can be tried again (E1, E2)',
    () async {
      share.answer = const Rejected(TransferRejection.shareUnavailable);
      final (:sheet, :state) = open(container(), wholeDeck);
      await sheet.export();
      expect(state().problem, CardExportProblem.noShareTarget);
      expect(state().canExport, isFalse);

      share.answer = const Rejected(TransferRejection.shareFailed);
      final retry = open(container(), wholeDeck);
      await retry.sheet.export();
      expect(retry.state().problem, CardExportProblem.shareFailed);
      expect(retry.state().canExport, isTrue);

      share.answer = const Ok(ExportShareResult.shared);
      await retry.sheet.export();
      expect(retry.state().isHandedOver, isTrue);
    },
  );

  test('a selection with a card gone meanwhile exports nothing (E6)', () async {
    final (:sheet, :state) = open(
      container(),
      CardExportScope.selection(deckId: leaf.id, ids: {'a', 'gone'}),
    );

    await sheet.export();

    expect(state().problem, CardExportProblem.staleSelection);
    expect(share.shared, isEmpty);
  });

  test(
    'a scope of no card opens on nothing to export and never builds (E5)',
    () async {
      final (:sheet, :state) = open(
        container(),
        CardExportScope.deck(
          deckId: leaf.id,
          deckName: 'Nhà hàng',
          cardCount: 0,
        ),
      );
      expect(state().problem, CardExportProblem.nothingToExport);

      await sheet.export();

      expect(share.shared, isEmpty);
    },
  );

  test('a read that fails says so and Try again builds again (E3)', () async {
    late _BrokenRead broken;
    final (:sheet, :state) = open(
      container(wrap: (cards) => broken = _BrokenRead(cards)),
      wholeDeck,
    );

    await sheet.export();
    expect(state().problem, CardExportProblem.prepareFailed);
    expect(share.shared, isEmpty);

    broken.isBroken = false;
    await sheet.export();
    expect(state().isHandedOver, isTrue);
  });

  test(
    'a second tap while the file is prepared makes no second file (A4)',
    () async {
      files.hold = Completer<void>();
      final (:sheet, :state) = open(container(), wholeDeck);

      final first = sheet.export();
      await pumpEventQueue();
      expect(state().isPreparing, isTrue);
      final second = sheet.export();
      files.hold!.complete();
      await Future.wait([first, second]);

      expect(share.shared, hasLength(1));
    },
  );

  test('closing the sheet while the file is prepared shares nothing', () async {
    files.hold = Completer<void>();
    final c = container();
    final provider = cardExportControllerProvider(wholeDeck);
    final open = c.listen(provider, (_, _) {});
    final writing = c.read(provider.notifier).export();
    await pumpEventQueue();

    open.close();
    await pumpEventQueue();
    files.hold!.complete();
    await writing;

    expect(share.shared, isEmpty);
  });
}
```

`test/support/fake_export_share.dart`:

```dart
import 'dart:async';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';

/// The system share sheet as a test drives it: it keeps every file handed
/// to it and answers [answer] (UC-TRANSFER-002 steps 6–7, A3, E1, E2).
final class FakeExportShare implements ExportShareRepository {
  final List<ExportArtifact> shared = [];
  Outcome<ExportShareResult, TransferRejection> answer = const Ok(
    ExportShareResult.shared,
  );

  @override
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  ) async {
    shared.add(artifact);
    return answer;
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/presentation/card_export_controller_test.dart
```

Expected: FAIL to compile: the controller and its state do not exist.

- [ ] **Step 3: Implement**

`lib/features/transfer/presentation/controllers/card_export_controller.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/providers/build_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/share_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_export_controller.g.dart';

/// One export sheet over [scope] (kit 12, UC-TRANSFER-002). It lives as
/// long as the sheet: closing the sheet while a file is prepared shares
/// nothing.
@riverpod
class CardExportController extends _$CardExportController {
  @override
  CardExportState build(CardExportScope scope) => CardExportState(
    problem: scope.cardCount == 0 ? CardExportProblem.nothingToExport : null,
  );

  /// Step 3, A2: CSV, TSV or XLSX; fixed while a file is prepared.
  void chooseFormat(TransferFormat format) {
    if (state.isPreparing || state.isHandedOver) return;
    state = CardExportState(format: format, problem: state.problem);
  }

  /// Steps 4–7: build the file and hand it to the share sheet. A second
  /// call while one runs does nothing (A4).
  Future<void> export() async {
    if (!state.canExport) return;
    final format = state.format;
    state = CardExportState(format: format, isPreparing: true);
    // Null once the state says why, or once the sheet has closed.
    final artifact = await _build(format);
    if (artifact == null) return;

    final shared = await ref.read(shareExportUseCaseProvider)(artifact);
    if (!ref.mounted) return;
    state = switch (shared) {
      Ok(value: ExportShareResult.shared) => CardExportState(
        format: format,
        isHandedOver: true,
      ),
      // A3: a cancel, not an error; the sheet is as it was.
      Ok(value: ExportShareResult.dismissed) => CardExportState(format: format),
      Rejected(reason: TransferRejection.shareUnavailable) => CardExportState(
        format: format,
        problem: CardExportProblem.noShareTarget,
      ),
      Rejected() => CardExportState(
        format: format,
        problem: CardExportProblem.shareFailed,
      ),
    };
  }

  /// Steps 4–5, E3–E6: the file, or null once the state says why not or
  /// the sheet has closed meanwhile.
  Future<ExportArtifact?> _build(TransferFormat format) async {
    final Outcome<ExportArtifact, TransferRejection> built;
    try {
      built = await ref.read(buildExportUseCaseProvider)(
        deckId: scope.deckId,
        format: format,
        today: ref.read(dayClockProvider).now(),
        cardIds: scope.cardIds,
      );
    } on Failure {
      if (ref.mounted) _fail(format, CardExportProblem.prepareFailed);
      return null;
    }
    if (!ref.mounted) return null;
    switch (built) {
      case Ok(:final value):
        return value;
      case Rejected(:final reason):
        _fail(format, switch (reason) {
          TransferRejection.emptyScope => CardExportProblem.nothingToExport,
          TransferRejection.staleSelection => CardExportProblem.staleSelection,
          _ => CardExportProblem.prepareFailed,
        });
        return null;
    }
  }

  void _fail(TransferFormat format, CardExportProblem problem) =>
      state = CardExportState(format: format, problem: problem);
}
```

`lib/features/transfer/presentation/states/card_export_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// What one export sheet exports, fixed by its entry point
/// (UC-TRANSFER-002 step 1, BR-TRANSFER-007): the whole deck, counted before
/// the sheet opens, or the cards selected on the card list (A1).
@immutable
final class CardExportScope {
  const CardExportScope.deck({
    required this.deckId,
    required String this.deckName,
    required this.cardCount,
  }) : cardIds = null;

  CardExportScope.selection({required this.deckId, required Set<String> ids})
    : cardIds = Set.unmodifiable(ids),
      deckName = null,
      cardCount = ids.length;

  final String deckId;

  /// The deck's name for the whole-deck subtitle; null for a selection.
  final String? deckName;
  final int cardCount;

  /// The selected cards; null for the whole deck.
  final Set<String>? cardIds;

  bool get isSelection => cardIds != null;

  @override
  bool operator ==(Object other) =>
      other is CardExportScope &&
      other.deckId == deckId &&
      other.deckName == deckName &&
      other.cardCount == cardCount &&
      setEquals(other.cardIds, cardIds);

  @override
  int get hashCode => Object.hash(
    deckId,
    deckName,
    cardCount,
    cardIds == null ? null : Object.hashAllUnordered(cardIds!),
  );
}

/// Why the sheet cannot export as it stands (kit 12's banners).
enum CardExportProblem {
  /// E3, E4: the cards could not be read or the file could not be written.
  prepareFailed,

  /// E2: the platform failed while sharing.
  shareFailed,

  /// E1: this device has no share sheet.
  noShareTarget,

  /// E6: a selected card is gone or has moved.
  staleSelection,

  /// E5: the scope holds no card.
  nothingToExport;

  /// A problem Try again cannot fix: the sheet offers Close only.
  bool get isFinal => switch (this) {
    prepareFailed || shareFailed => false,
    noShareTarget || staleSelection || nothingToExport => true,
  };
}

/// The export sheet (kit 12): the format, whether a file is being
/// prepared, the problem if any, and whether the file was handed over.
@immutable
final class CardExportState {
  const CardExportState({
    this.format = TransferFormat.csv,
    this.isPreparing = false,
    this.problem,
    this.isHandedOver = false,
  });

  /// CSV by default (UC-TRANSFER-002 step 2).
  final TransferFormat format;

  /// Building or sharing; the primary action is locked (A4).
  final bool isPreparing;
  final CardExportProblem? problem;

  /// The share sheet took the file (step 7); the sheet closes.
  final bool isHandedOver;

  bool get canExport =>
      !isPreparing && !isHandedOver && !(problem?.isFinal ?? false);
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/transfer/presentation/card_export_controller_test.dart
flutter analyze
```

Expected: 9 tests PASS; no analyzer issue.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/transfer/presentation/controllers/card_export_controller.dart \
  lib/features/transfer/presentation/states/card_export_state.dart \
  test/features/transfer/presentation/card_export_controller_test.dart \
  test/support/fake_export_share.dart
git commit -m "$(cat <<'EOF'
feat(transfer): the export sheet state and controller (UC-TRANSFER-002)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: The export sheet

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Create: `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/support/export_labels_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/shared/widgets/mx_sheet_actions.dart`
- Create: `test/features/transfer/presentation/goldens/export_deck_dark.png`
- Create: `test/features/transfer/presentation/goldens/export_deck_light.png`
- Create: `test/features/transfer/presentation/goldens/export_failed_dark.png`
- Create: `test/features/transfer/presentation/goldens/export_failed_light.png`
- Create: `test/features/transfer/presentation/goldens/export_stale_dark.png`
- Create: `test/features/transfer/presentation/goldens/export_stale_light.png`
- Test (create): `test/features/transfer/presentation/card_export_golden_test.dart`
- Test (create): `test/features/transfer/presentation/card_export_sheet_test.dart`
- Test (modify): `test/shared/widgets/mx_sheet_actions_test.dart`

**Interfaces:**
- Consumes: Task 2's controller and state; Task 1's `countExportCardsUseCaseProvider`.
- Produces: `showCardExportSheet(BuildContext, CardExportScope)` (the toast once the file
  is handed over); `showDeckExportSheet(BuildContext, {deckId, deckName})` (count, then
  the sheet); `CardExportSheetWidget`; `ExportLabels` (format and problem copy);
  `MxSheetActions.isConfirmLoading`; `AppIcons.share`, `AppIcons.fileDown`; the `export*`
  messages in en and vi.

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/presentation/card_export_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:memox/features/transfer/presentation/providers/build_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Kit 12's sheet as the app draws it, light and dark: the whole deck, a
// failed file and a stale selection (rulings E1–E6).

final _en = lookupAppLocalizations(const Locale('en'));

const _open = 'Open export';

/// An encoder that fails, the way a full disk does (E4).
final class _FailingFiles implements TransferFileRepository {
  @override
  Future<Outcome<Never, TransferRejection>> write(rows, format) async =>
      const Rejected(TransferRejection.encodeFailed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(
      WidgetTester tester,
      LibraryEnv env,
      CardExportScope Function(String deckId) scope, {
      bool isFailing = false,
    }) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(env.db, id: 'a', deckId: deck.id);
      await pumpLibraryGolden(
        tester,
        env,
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => MxButton(
                label: _open,
                onPressed: () => showCardExportSheet(context, scope(deck.id)),
              ),
            ),
          ),
        ),
        brightness,
        overrides: [
          exportShareRepositoryProvider.overrideWithValue(FakeExportShare()),
          if (isFailing)
            buildExportUseCaseProvider.overrideWith(
              (ref) => BuildExportUseCase(
                ref.watch(cardRepositoryProvider),
                _FailingFiles(),
              ),
            ),
        ],
      );
      await tester.tap(find.text(_open));
      await tester.pumpAndSettle();
    }

    CardExportScope wholeDeck(String deckId) =>
        CardExportScope.deck(deckId: deckId, deckName: 'Words', cardCount: 1);

    libraryTest('export whole deck, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(tester, env, wholeDeck);
        await expectBoundaryGolden(tester, 'goldens/export_deck_$theme.png');
      });
    });

    libraryTest('export failed, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(tester, env, wholeDeck, isFailing: true);
        await tester.tap(find.widgetWithText(MxButton, _en.exportAction(1)));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/export_failed_$theme.png');
      });
    });

    libraryTest('export stale selection, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(
          tester,
          env,
          (deckId) =>
              CardExportScope.selection(deckId: deckId, ids: {'a', 'gone'}),
        );
        await tester.tap(find.widgetWithText(MxButton, _en.exportAction(2)));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/export_stale_$theme.png');
      });
    });
  }
}
```

`test/features/transfer/presentation/card_export_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/library_harness.dart';
import '../../../visual_audit/screen_audit.dart';

// The export sheet over the real backend and a fake share sheet
// (UC-TRANSFER-002, kit 12, rulings E1–E6).

final _en = lookupAppLocalizations(const Locale('en'));

const _open = 'Open export';

/// A page whose one button opens the sheet the way an entry point does.
class _Host extends StatelessWidget {
  const _Host(this.open);

  final Future<void> Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) =>
            MxButton(label: _open, onPressed: () => open(context)),
      ),
    ),
  );
}

Finder _button(String label) => find.widgetWithText(MxButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<({String deckId, FakeExportShare share})> _seed(
  WidgetTester tester,
  LibraryEnv env, {
  CardExportScope Function(String deckId)? scope,
  bool isWholeDeckEntry = false,
}) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  await insertCard(env.db, id: 'a', deckId: deck.id, front: 'mul');
  await insertCard(env.db, id: 'b', deckId: deck.id, front: 'bul');
  final share = FakeExportShare();
  await pumpLibraryScreen(
    tester,
    env,
    _Host(
      (context) => isWholeDeckEntry
          ? showDeckExportSheet(context, deckId: deck.id, deckName: 'Words')
          : showCardExportSheet(context, scope!(deck.id)),
    ),
    overrides: [exportShareRepositoryProvider.overrideWithValue(share)],
  );
  await _tap(tester, _button(_open));
  return (deckId: deck.id, share: share);
}

void main() {
  libraryTest(
    'the whole deck is counted, then handed over; the toast says so (steps 1–7)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        isWholeDeckEntry: true,
      );

      expect(find.text(_en.exportTitleDeck(2)), findsOneWidget);
      expect(find.text(_en.exportBodyDeck('Words')), findsOneWidget);
      expect(find.text(_en.exportRecommended), findsOneWidget);
      final csv = find.widgetWithText(MxOptionRow, _en.exportFormatCsv);
      expect(tester.widget<MxOptionRow>(csv).isSelected, isTrue);

      await _tap(tester, _button(_en.exportAction(2)));

      expect(find.byType(CardExportSheetWidget), findsNothing);
      expect(find.text(_en.exportHandedOver(2)), findsOneWidget);
      expect(share.shared.single.format, TransferFormat.csv);
      expect(share.shared.single.fileName, startsWith('Words-'));
    },
  );

  libraryTest(
    'a selection names its count; XLSX is written when chosen (A1, A2)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      );
      expect(find.text(_en.exportTitleSelection(1)), findsOneWidget);
      expect(find.text(_en.exportBodySelection), findsOneWidget);

      await _tap(tester, find.text(_en.exportFormatXlsx));
      await _tap(tester, _button(_en.exportAction(1)));

      expect(share.shared.single.format, TransferFormat.xlsx);
    },
  );

  libraryTest(
    'closing the share sheet keeps the export sheet as it was (A3, ruling E1)',
    (tester, env) async {
      await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      ).then((seeded) async {
        seeded.share.answer = const Ok(ExportShareResult.dismissed);
        await _tap(tester, find.text(_en.exportFormatTsv));
        await _tap(tester, _button(_en.exportAction(1)));
      });

      expect(find.byType(CardExportSheetWidget), findsOneWidget);
      final tsv = find.widgetWithText(MxOptionRow, _en.exportFormatTsv);
      expect(tester.widget<MxOptionRow>(tsv).isSelected, isTrue);
      expect(find.text(_en.exportHandedOver(1)), findsNothing);
    },
  );

  libraryTest(
    'a share error offers Try again; no share target offers Close only (E1, E2)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      );
      share.answer = const Rejected(TransferRejection.shareFailed);
      await _tap(tester, _button(_en.exportAction(1)));
      expect(find.text(_en.exportShareFailedTitle), findsOneWidget);

      share.answer = const Rejected(TransferRejection.shareUnavailable);
      await _tap(tester, _button(_en.exportTryAgain));
      expect(find.text(_en.exportNoTargetTitle), findsOneWidget);
      expect(_button(_en.exportTryAgain), findsNothing);

      await _tap(tester, _button(_en.exportClose));
      expect(find.byType(CardExportSheetWidget), findsNothing);
    },
  );

  libraryTest('a selection with a card gone meanwhile exports nothing (E6)', (
    tester,
    env,
  ) async {
    final (:deckId, :share) = await _seed(
      tester,
      env,
      scope: (deckId) =>
          CardExportScope.selection(deckId: deckId, ids: {'a', 'gone'}),
    );

    await _tap(tester, _button(_en.exportAction(2)));

    expect(find.text(_en.exportStaleTitle), findsOneWidget);
    expect(_button(_en.exportClose), findsOneWidget);
    expect(share.shared, isEmpty);
  });

  libraryTest('an empty deck opens on nothing to export (E5)', (
    tester,
    env,
  ) async {
    await _seed(
      tester,
      env,
      scope: (deckId) =>
          CardExportScope.deck(deckId: deckId, deckName: 'Words', cardCount: 0),
    );

    expect(find.text(_en.exportEmptyTitle), findsOneWidget);
    expect(_button(_en.exportClose), findsOneWidget);
  });

  libraryTest('the sheet meets the target guidelines at 1x and 2x text', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: deck.id);
    await auditProductionScreen(
      tester,
      screen: CardExportSheetWidget,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _Host(
            (context) => showCardExportSheet(
              context,
              CardExportScope.deck(
                deckId: deck.id,
                deckName: 'Words',
                cardCount: 1,
              ),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        );
        if (find.byType(CardExportSheetWidget).evaluate().isEmpty) {
          await _tap(tester, _button(_open));
        }
      },
    );
  });
}
```

`test/shared/widgets/mx_sheet_actions_test.dart` (apply this diff):

```diff
diff --git a/test/shared/widgets/mx_sheet_actions_test.dart b/test/shared/widgets/mx_sheet_actions_test.dart
index d5c5ff2..e1c60ca 100644
--- a/test/shared/widgets/mx_sheet_actions_test.dart
+++ b/test/shared/widgets/mx_sheet_actions_test.dart
@@ -46,6 +46,29 @@ void main() {
     );
   });
 
+  testWidgets(
+    'a loading confirm spins and cannot be pressed; Cancel stays live',
+    (tester) async {
+      var cancelled = 0;
+      await pumpMx(
+        tester,
+        _width(
+          MxSheetActions(
+            cancelLabel: 'Cancel',
+            onCancel: () => cancelled++,
+            confirmLabel: 'Preparing',
+            onConfirm: () {},
+            isConfirmLoading: true,
+          ),
+        ),
+      );
+
+      expect(tester.widget<MxButton>(_button('Preparing')).isLoading, isTrue);
+      await tester.tap(_button('Cancel'));
+      expect(cancelled, 1);
+    },
+  );
+
   testWidgets('a destructive confirm, with its glyph passed through', (
     tester,
   ) async {
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/presentation/card_export_sheet_test.dart test/shared/widgets/mx_sheet_actions_test.dart
```

Expected: FAIL to compile: `isConfirmLoading`, the sheet and the `export*` messages do
not exist.

- [ ] **Step 3: Implement**

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index 0422015..f77d9b7 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -68,6 +68,9 @@ abstract final class AppIcons {
   static const IconData arrowRight = Icons.arrow_forward; // arrow-right
   static const IconData preview = Icons.visibility_outlined; // eye
   static const IconData download = Icons.download; // download
+  // Card export (kit 12).
+  static const IconData share = Icons.share_outlined; // share-2
+  static const IconData fileDown = Icons.file_download_outlined; // file-down
   static const IconData library = Icons.layers_outlined;
   static const IconData librarySelected = Icons.layers;
   static const IconData study = Icons.play_circle_outline;
```

`lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/controllers/card_export_controller.dart';
import 'package:memox/features/transfer/presentation/providers/count_export_cards_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/support/export_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Opens the export sheet over [scope] (kit 12, UC-TRANSFER-002) and, once
/// the share sheet took the file, says so without naming where it went
/// (BR-TRANSFER-014, ruling E2).
Future<void> showCardExportSheet(
  BuildContext context,
  CardExportScope scope,
) async {
  final isHandedOver =
      await showMxBottomSheet<bool>(
        context,
        builder: (_) => CardExportSheetWidget(scope: scope),
      ) ??
      false;
  if (!isHandedOver || !context.mounted) return;
  showMxSnackbar(
    context,
    message: context.l10n.exportHandedOver(scope.cardCount),
  );
}

/// The whole-deck entry (the deck's ⋮): counts the deck's cards first, so
/// the sheet opens knowing its scope and never loads (UC-TRANSFER-002 UI).
Future<void> showDeckExportSheet(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) async {
  final count = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(countExportCardsUseCaseProvider);
  final int cardCount;
  try {
    cardCount = await count(deckId);
  } on Failure catch (failure) {
    if (!context.mounted) return;
    showMxSnackbar(context, message: context.l10n.failure(failure));
    return;
  }
  if (!context.mounted) return;
  await showCardExportSheet(
    context,
    CardExportScope.deck(
      deckId: deckId,
      deckName: deckName,
      cardCount: cardCount,
    ),
  );
}

/// Kit 12: the fixed scope, the three formats, what the file holds, and one
/// action. It closes itself once the file is handed over.
class CardExportSheetWidget extends ConsumerWidget {
  const CardExportSheetWidget({super.key, required this.scope});

  final CardExportScope scope;

  CardExportController _sheet(WidgetRef ref) =>
      ref.read(cardExportControllerProvider(scope).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = cardExportControllerProvider(scope);
    ref.listen(provider, (_, next) {
      if (next.isHandedOver) Navigator.of(context).pop(true);
    });
    final state = ref.watch(provider);
    final problem = state.problem;
    return MxBottomSheet(
      header: _Header(scope: scope),
      footer: _Actions(
        scope: scope,
        state: state,
        onExport: () => _sheet(ref).export(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (problem != null) _Problem(problem: problem),
            // The overline, the banner and the note line up with the title.
            Padding(
              padding:
                  const EdgeInsets.only(top: AppSpacing.micro) +
                  const EdgeInsets.symmetric(horizontal: AppSpacing.control),
              child: MxListSectionHeader(
                label: context.l10n.exportFormatSection,
              ),
            ),
            for (final (index, format) in TransferFormat.values.indexed)
              _FormatRow(
                format: format,
                isSelected: state.format == format,
                isLast: index == TransferFormat.values.length - 1,
                onSelected: state.isPreparing
                    ? null
                    : () => _sheet(ref).chooseFormat(format),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.grouped,
                AppSpacing.grouped,
                AppSpacing.grouped,
                AppSpacing.control,
              ),
              child: MxNote(
                text: context.l10n.exportContentNote,
                icon: AppIcons.fileText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scope});

  final CardExportScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final deckName = scope.deckName;
    return Padding(
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
            deckName == null
                ? l10n.exportTitleSelection(scope.cardCount)
                : l10n.exportTitleDeck(scope.cardCount),
            style: styles.compactTitle,
          ),
          Text(
            deckName == null
                ? l10n.exportBodySelection
                : l10n.exportBodyDeck(deckName),
            style: styles.dialogBody,
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.problem});

  final CardExportProblem problem;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.exportProblem(problem);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.grouped,
        0,
        AppSpacing.grouped,
        AppSpacing.grouped,
      ),
      child: MxInlineBanner(
        tone: problem == CardExportProblem.prepareFailed
            ? MxBannerTone.danger
            : MxBannerTone.warning,
        title: copy.title,
        message: copy.body,
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.format,
    required this.isSelected,
    required this.isLast,
    required this.onSelected,
  });

  final TransferFormat format;
  final bool isSelected;
  final bool isLast;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (name, body) = l10n.exportFormat(format);
    return MxOptionRow(
      title: name,
      description: body,
      isSelected: isSelected,
      onSelected: onSelected,
      hasDivider: !isLast,
      trailing: format == TransferFormat.csv
          ? MxBadge(label: l10n.exportRecommended, tone: MxBadgeTone.primary)
          : null,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.scope,
    required this.state,
    required this.onExport,
  });

  final CardExportScope scope;
  final CardExportState state;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void close() => Navigator.of(context).pop(false);
    final problem = state.problem;
    if (problem != null && problem.isFinal) {
      return MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.exportClose,
              onPressed: close,
              tone: MxButtonTone.outline,
              isBlock: true,
            ),
          ),
        ],
      );
    }
    final isRetry = problem != null;
    return MxSheetActions(
      isInSheet: true,
      cancelLabel: l10n.commonCancel,
      onCancel: close,
      confirmLabel: state.isPreparing
          ? l10n.exportPreparing
          : isRetry
          ? l10n.exportTryAgain
          : l10n.exportAction(scope.cardCount),
      confirmIcon: isRetry ? AppIcons.retry : AppIcons.share,
      isConfirmLoading: state.isPreparing,
      onConfirm: onExport,
    );
  }
}
```

`lib/features/transfer/presentation/widgets/support/export_labels_widget.dart`:

```dart
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The export sheet's copy for its domain values (kit 12).
extension ExportLabels on AppLocalizations {
  /// A format's name and what it is for (UC-TRANSFER-002 step 2).
  (String, String) exportFormat(TransferFormat format) => switch (format) {
    TransferFormat.csv => (exportFormatCsv, exportFormatCsvBody),
    TransferFormat.tsv => (exportFormatTsv, exportFormatTsvBody),
    TransferFormat.xlsx => (exportFormatXlsx, exportFormatXlsxBody),
  };

  /// A problem's banner: what happened and what to do (E1–E6).
  ({String title, String body}) exportProblem(CardExportProblem problem) =>
      switch (problem) {
        CardExportProblem.prepareFailed => (
          title: exportFailedTitle,
          body: exportFailedBody,
        ),
        CardExportProblem.shareFailed => (
          title: exportShareFailedTitle,
          body: exportShareFailedBody,
        ),
        CardExportProblem.noShareTarget => (
          title: exportNoTargetTitle,
          body: exportNoTargetBody,
        ),
        CardExportProblem.staleSelection => (
          title: exportStaleTitle,
          body: exportStaleBody,
        ),
        CardExportProblem.nothingToExport => (
          title: exportEmptyTitle,
          body: exportEmptyBody,
        ),
      };
}
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 8ca6999..5160ef6 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -2956,5 +2956,142 @@
   "deckUnsetImport": "Import cards from a file",
   "@deckUnsetImport": {
     "description": "An empty deck's third option: opens the import."
+  },
+  "exportTitleDeck": "{count, plural, =1{Export 1 card} other{Export all {count} cards}}",
+  "@exportTitleDeck": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Export sheet title for the whole deck (kit 12)."
+  },
+  "exportTitleSelection": "{count, plural, =1{Export 1 selected card} other{Export {count} selected cards}}",
+  "@exportTitleSelection": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Export sheet title for a selection (UC-TRANSFER-002 A1)."
+  },
+  "exportBodyDeck": "Every card in {deck}, whatever filter or search is active.",
+  "@exportBodyDeck": {
+    "placeholders": {
+      "deck": {
+        "type": "String"
+      }
+    },
+    "description": "Export sheet subtitle for the whole deck."
+  },
+  "exportBodySelection": "Only the cards you selected.",
+  "@exportBodySelection": {
+    "description": "Export sheet subtitle for a selection."
+  },
+  "exportFormatSection": "Format",
+  "@exportFormatSection": {
+    "description": "Export sheet: the format section's overline."
+  },
+  "exportFormatCsv": "CSV",
+  "@exportFormatCsv": {
+    "description": "Export format name."
+  },
+  "exportFormatCsvBody": "Comma-separated · opens anywhere",
+  "@exportFormatCsvBody": {
+    "description": "Export format: what CSV is for."
+  },
+  "exportFormatTsv": "TSV",
+  "@exportFormatTsv": {
+    "description": "Export format name."
+  },
+  "exportFormatTsvBody": "Tab-separated · safest for commas in text",
+  "@exportFormatTsvBody": {
+    "description": "Export format: what TSV is for."
+  },
+  "exportFormatXlsx": "XLSX",
+  "@exportFormatXlsx": {
+    "description": "Export format name."
+  },
+  "exportFormatXlsxBody": "Excel workbook",
+  "@exportFormatXlsxBody": {
+    "description": "Export format: what XLSX is."
+  },
+  "exportRecommended": "Recommended",
+  "@exportRecommended": {
+    "description": "The badge on the default format, CSV (UC-TRANSFER-002 step 2)."
+  },
+  "exportContentNote": "Six columns: front, back, example, hint, pronunciation, tags. No schedule, no history — this is content, not a backup.",
+  "@exportContentNote": {
+    "description": "Export sheet: what the file holds and what it leaves out (BR-TRANSFER-008)."
+  },
+  "exportAction": "{count, plural, =1{Export 1 card} other{Export {count} cards}}",
+  "@exportAction": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Export sheet primary action (UC-TRANSFER-002 step 3)."
+  },
+  "exportPreparing": "Preparing…",
+  "@exportPreparing": {
+    "description": "Export sheet primary action while the file is built and shared."
+  },
+  "exportClose": "Close",
+  "@exportClose": {
+    "description": "Export sheet: the one action once nothing can be exported."
+  },
+  "exportTryAgain": "Try again",
+  "@exportTryAgain": {
+    "description": "Export sheet: export again after a failure (E2–E4)."
+  },
+  "exportHandedOver": "{count, plural, =1{Handed 1 card to the system.} other{Handed {count} cards to the system.}}",
+  "@exportHandedOver": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Toast once the share sheet took the file; never says where it was saved (BR-TRANSFER-014)."
+  },
+  "exportFailedTitle": "Couldn’t prepare the file",
+  "@exportFailedTitle": {
+    "description": "Export banner: the cards could not be read or the file written (E3, E4)."
+  },
+  "exportFailedBody": "Nothing was shared. Your cards are unchanged — try again.",
+  "@exportFailedBody": {
+    "description": "Export banner body for E3, E4."
+  },
+  "exportShareFailedTitle": "Couldn’t hand the file over",
+  "@exportShareFailedTitle": {
+    "description": "Export banner: the platform failed while sharing (E2)."
+  },
+  "exportShareFailedBody": "The share sheet stopped with an error. Nothing was shared — try again.",
+  "@exportShareFailedBody": {
+    "description": "Export banner body for E2."
+  },
+  "exportNoTargetTitle": "No app on this device can receive a file",
+  "@exportNoTargetTitle": {
+    "description": "Export banner: no share sheet (E1)."
+  },
+  "exportNoTargetBody": "Install a file manager, drive or mail app, then export again.",
+  "@exportNoTargetBody": {
+    "description": "Export banner body for E1."
+  },
+  "exportStaleTitle": "A selected card is no longer in this deck",
+  "@exportStaleTitle": {
+    "description": "Export banner: a selected card is gone or moved (E6)."
+  },
+  "exportStaleBody": "It was moved or deleted meanwhile. Nothing was exported. Refresh the selection and export again.",
+  "@exportStaleBody": {
+    "description": "Export banner body for E6."
+  },
+  "exportEmptyTitle": "There is nothing to export",
+  "@exportEmptyTitle": {
+    "description": "Export banner: the scope holds no card (E5)."
+  },
+  "exportEmptyBody": "This deck has no cards. Add or import cards first.",
+  "@exportEmptyBody": {
+    "description": "Export banner body for E5."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 5685816..4d35f02 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -595,5 +595,33 @@
   "importCloseAction": "Đóng",
   "importTryAgain": "Thử lại",
   "deckActionImport": "Nhập thẻ",
-  "deckUnsetImport": "Nhập thẻ từ tệp"
+  "deckUnsetImport": "Nhập thẻ từ tệp",
+  "exportTitleDeck": "{count, plural, other{Xuất toàn bộ {count} thẻ}}",
+  "exportTitleSelection": "{count, plural, other{Xuất {count} thẻ đã chọn}}",
+  "exportBodyDeck": "Mọi thẻ trong {deck}, bất kể bộ lọc hay tìm kiếm đang bật.",
+  "exportBodySelection": "Chỉ những thẻ bạn đã chọn.",
+  "exportFormatSection": "Định dạng",
+  "exportFormatCsv": "CSV",
+  "exportFormatCsvBody": "Phân tách bằng dấu phẩy · mở được ở mọi nơi",
+  "exportFormatTsv": "TSV",
+  "exportFormatTsvBody": "Phân tách bằng tab · an toàn nhất khi chữ có dấu phẩy",
+  "exportFormatXlsx": "XLSX",
+  "exportFormatXlsxBody": "Sổ tính Excel",
+  "exportRecommended": "Nên dùng",
+  "exportContentNote": "Sáu cột: front, back, example, hint, pronunciation, tags. Không có lịch ôn, không có lịch sử — đây là nội dung, không phải bản sao lưu.",
+  "exportAction": "{count, plural, other{Xuất {count} thẻ}}",
+  "exportPreparing": "Đang chuẩn bị…",
+  "exportClose": "Đóng",
+  "exportTryAgain": "Thử lại",
+  "exportHandedOver": "{count, plural, other{Đã giao {count} thẻ cho hệ thống.}}",
+  "exportFailedTitle": "Không chuẩn bị được tệp",
+  "exportFailedBody": "Chưa chia sẻ gì. Thẻ của bạn không đổi — hãy thử lại.",
+  "exportShareFailedTitle": "Không giao được tệp",
+  "exportShareFailedBody": "Bảng chia sẻ dừng vì lỗi. Chưa chia sẻ gì — hãy thử lại.",
+  "exportNoTargetTitle": "Không ứng dụng nào trên máy nhận được tệp",
+  "exportNoTargetBody": "Hãy cài một ứng dụng quản lý tệp, lưu trữ hoặc email, rồi xuất lại.",
+  "exportStaleTitle": "Một thẻ đã chọn không còn trong bộ thẻ này",
+  "exportStaleBody": "Thẻ đó vừa bị chuyển hoặc xoá. Chưa xuất gì. Hãy chọn lại rồi xuất lần nữa.",
+  "exportEmptyTitle": "Không có gì để xuất",
+  "exportEmptyBody": "Bộ thẻ này chưa có thẻ. Hãy thêm hoặc nhập thẻ trước."
 }
```

`lib/shared/widgets/mx_sheet_actions.dart` (apply this diff):

```diff
diff --git a/lib/shared/widgets/mx_sheet_actions.dart b/lib/shared/widgets/mx_sheet_actions.dart
index 6cf636d..9d2c47c 100644
--- a/lib/shared/widgets/mx_sheet_actions.dart
+++ b/lib/shared/widgets/mx_sheet_actions.dart
@@ -17,6 +17,7 @@ class MxSheetActions extends StatelessWidget {
     this.confirmIcon,
     this.isDestructive = false,
     this.isInSheet = false,
+    this.isConfirmLoading = false,
   }) : children = const [];
 
   /// A custom footer (Trash restore / delete-forever, a single OK) in place
@@ -31,7 +32,8 @@ class MxSheetActions extends StatelessWidget {
        confirmLabel = null,
        onConfirm = null,
        confirmIcon = null,
-       isDestructive = false;
+       isDestructive = false,
+       isConfirmLoading = false;
 
   final String? cancelLabel;
   final VoidCallback? onCancel;
@@ -44,6 +46,10 @@ class MxSheetActions extends StatelessWidget {
   /// The destructive Button tone on the confirm.
   final bool isDestructive;
 
+  /// The confirm's work is running: it spins and cannot be pressed; Cancel
+  /// stays live.
+  final bool isConfirmLoading;
+
   /// The sheet form: a ghost rule on top and 8 16 16 padding, instead of 16
   /// all round.
   final bool isInSheet;
@@ -74,6 +80,7 @@ class MxSheetActions extends StatelessWidget {
                   label: confirmLabel!,
                   onPressed: onConfirm,
                   icon: confirmIcon,
+                  isLoading: isConfirmLoading,
                   tone: isDestructive
                       ? MxButtonTone.destructive
                       : MxButtonTone.primary,
```

- [ ] **Step 4: Generate, render the goldens, run and look**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test --tags golden --update-goldens test/features/transfer/presentation/card_export_golden_test.dart
flutter test test/features/transfer test/shared/widgets/mx_sheet_actions_test.dart test/app/l10n_test.dart
flutter analyze
```

Expected: PASS. Six goldens: `export_{deck,failed,stale}_{light,dark}.png`. Compare them
with `docs/shared/ui/screen-handoff/img/12-card-export/` (Task 5 captures it): the overline,
the banner and the note start at the title's 20 dp; CSV is selected with "Recommended";
the footer is Cancel and the primary, or Close alone.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart \
  lib/features/transfer/presentation/widgets/support/export_labels_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/shared/widgets/mx_sheet_actions.dart \
  test/features/transfer/presentation/card_export_golden_test.dart \
  test/features/transfer/presentation/card_export_sheet_test.dart \
  test/shared/widgets/mx_sheet_actions_test.dart \
  test/features/transfer/presentation/goldens/export_deck_dark.png \
  test/features/transfer/presentation/goldens/export_deck_light.png \
  test/features/transfer/presentation/goldens/export_failed_dark.png \
  test/features/transfer/presentation/goldens/export_failed_light.png \
  test/features/transfer/presentation/goldens/export_stale_dark.png \
  test/features/transfer/presentation/goldens/export_stale_light.png
git commit -m "$(cat <<'EOF'
feat(transfer): the export sheet (kit 12, UC-TRANSFER-002)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: The entry points

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `test/features/card/presentation/goldens/card_list_bulk_failed_dark.png`
- Modify: `test/features/card/presentation/goldens/card_list_bulk_failed_light.png`
- Modify: `test/features/card/presentation/goldens/card_selection_dark.png`
- Modify: `test/features/card/presentation/goldens/card_selection_light.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_dark.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_light.png`
- Test (modify): `test/app/library_routes_test.dart`
- Test (modify): `test/features/card/presentation/card_bulk_actions_test.dart`
- Test (modify): `test/features/deck/presentation/deck_action_sheet_test.dart`
- Test (modify): `test/features/deck/presentation/deck_level_screen_test.dart`
- Test (modify): `test/support/library_harness.dart`

**Interfaces:**
- Consumes: Task 3's `showDeckExportSheet` and `showCardExportSheet`.
- Produces: `DeckLevelScreen.onExportCards` (`ValueChanged<DeckEntity>`);
  `DeckAction.exportCards` and the sheet's `canExport`; `openDeckActions(onExportCards:)`;
  `CardListSectionWidget.onExport` (`ValueChanged<Set<String>>?`); the `deckActionExport`
  and `cardExport` messages. Coming soon's `comingSoonTransfer*` messages and
  `AppIcons.transfer` are removed.

- [ ] **Step 1: Write the failing tests**

`test/app/library_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/library_routes_test.dart b/test/app/library_routes_test.dart
index 1387cc0..8971c51 100644
--- a/test/app/library_routes_test.dart
+++ b/test/app/library_routes_test.dart
@@ -245,6 +245,33 @@ void main() {
     },
   );
 
+  libraryTest(
+    'Export opens its sheet from the deck and from a selection (UC-TRANSFER-002)',
+    (tester, env) async {
+      final words = await env.decks.sub(
+        (await env.decks.root('Korean')).id,
+        'Words',
+      );
+      await insertCard(env.db, id: 'a', deckId: words.id, front: 'bap');
+      await insertCard(env.db, id: 'b', deckId: words.id, front: 'mul');
+      await pumpMemoxApp(tester, env);
+      await _tap(tester, find.text('Korean'));
+      await _tap(tester, find.text('Words'));
+
+      await _tap(tester, find.byTooltip(_en.deckActions));
+      await _tap(tester, find.text(_en.deckActionExport));
+      expect(find.text(_en.exportTitleDeck(2)), findsOneWidget);
+      await _tap(tester, find.widgetWithText(MxButton, _en.commonCancel));
+
+      await tester.longPress(find.text('bap'));
+      await tester.pumpAndSettle();
+      await _tap(tester, find.text(_en.cardExport));
+      expect(find.text(_en.exportTitleSelection(1)), findsOneWidget);
+      await _tap(tester, find.widgetWithText(MxButton, _en.commonCancel));
+      expect(_barTitle(_en.cardSelectedCount(1)), findsOneWidget);
+    },
+  );
+
   libraryTest('Close on a typed card asks; Discard leaves (RF2)', (
     tester,
     env,
```

`test/features/card/presentation/card_bulk_actions_test.dart` (apply this diff):

```diff
diff --git a/test/features/card/presentation/card_bulk_actions_test.dart b/test/features/card/presentation/card_bulk_actions_test.dart
index 12c1f89..dc68308 100644
--- a/test/features/card/presentation/card_bulk_actions_test.dart
+++ b/test/features/card/presentation/card_bulk_actions_test.dart
@@ -73,6 +73,37 @@ Finder _inDialog(String text) =>
     find.descendant(of: find.byType(MxDialog), matching: find.text(text));
 
 void main() {
+  libraryTest(
+    'Export hands the selection over and keeps it (UC-TRANSFER-002 A1)',
+    (tester, env) async {
+      final ids = await _seed(env);
+      final exported = <Set<String>>[];
+      await pumpLibraryScreen(
+        tester,
+        env,
+        Scaffold(
+          body: CardListSectionWidget(
+            deckId: ids.words,
+            algorithm: 'Eight boxes',
+            onAddCard: () {},
+            onOpenCard: (_) {},
+            onExport: exported.add,
+          ),
+        ),
+      );
+      await _select(tester, ['annyeong', 'mul']);
+      await _bulk(tester, _en.cardExport);
+
+      expect(exported, [
+        {'new1', 'flag1'},
+      ]);
+      final checked = find.byWidgetPredicate(
+        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
+      );
+      expect(checked, findsNWidgets(2));
+    },
+  );
+
   libraryTest('Flag sets the flag on every selected card', (tester, env) async {
     final ids = await _seed(env);
     await pumpLibraryScreen(tester, env, _section(ids.words));
```

`test/features/deck/presentation/deck_action_sheet_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_action_sheet_test.dart b/test/features/deck/presentation/deck_action_sheet_test.dart
index 010487f..98ceb75 100644
--- a/test/features/deck/presentation/deck_action_sheet_test.dart
+++ b/test/features/deck/presentation/deck_action_sheet_test.dart
@@ -105,6 +105,42 @@ void main() {
     },
   );
 
+  libraryTest(
+    'only a deck of cards offers Export (UC-TRANSFER-002 E5, ruling E5)',
+    (tester, env) async {
+      final korean = await env.decks.root('Korean');
+      final words = await env.decks.sub(korean.id, 'Words');
+      final empty = await env.decks.sub(korean.id, 'Empty');
+      await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
+      final exported = <String>[];
+
+      for (final (deckId, isOffered) in [
+        (korean.id, false),
+        (empty.id, false),
+        (words.id, true),
+      ]) {
+        await pumpLibraryScreen(
+          tester,
+          env,
+          deckScreen(
+            deckId: deckId,
+            onExportCards: (deck) => exported.add(deck.name),
+          ),
+        );
+        await _openSheet(tester);
+        expect(
+          find.text(_en.deckActionExport),
+          isOffered ? findsOneWidget : findsNothing,
+        );
+        await tester.tapAt(Offset.zero);
+        await tester.pumpAndSettle();
+      }
+
+      await _choose(tester, _en.deckActionExport);
+      expect(exported, ['Words']);
+    },
+  );
+
   libraryTest('Rename renames the open deck', (tester, env) async {
     final korean = await env.decks.root('Korean');
     await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
```

`test/features/deck/presentation/deck_level_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_level_screen_test.dart b/test/features/deck/presentation/deck_level_screen_test.dart
index 774fb78..9a6e5b5 100644
--- a/test/features/deck/presentation/deck_level_screen_test.dart
+++ b/test/features/deck/presentation/deck_level_screen_test.dart
@@ -303,10 +303,11 @@ void main() {
       _en.comingSoonStudy,
       _en.deckStudyOptions,
       _en.comingSoonProgressSort,
-      _en.comingSoonTransfer,
     ]) {
       expect(find.text(feature), findsOneWidget, reason: feature);
     }
+    // Import and export shipped (FE-B3): neither waits here any more.
+    expect(find.text(_en.deckActionExport), findsNothing);
   });
 
   libraryTest('the search field opens the search', (tester, env) async {
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
index 9e4ca78..a5ae92e 100644
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -14,6 +14,7 @@ import 'package:memox/features/card/presentation/widgets/sections/card_deck_brea
 import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
 import 'package:memox/features/card/domain/repositories/card_repository.dart';
 import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
+import 'package:memox/features/deck/domain/entities/deck_entity.dart';
 import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
 import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
 import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
@@ -182,6 +183,7 @@ DeckLevelScreen deckScreen({
   VoidCallback? onSearch,
   ValueChanged<String>? onOpenAlgorithm,
   ValueChanged<String>? onImportCards,
+  ValueChanged<DeckEntity>? onExportCards,
 }) => DeckLevelScreen(
   deckId: deckId,
   onOpenDeck: onOpenDeck ?? (_) {},
@@ -190,6 +192,7 @@ DeckLevelScreen deckScreen({
   onOpenAlgorithm: onOpenAlgorithm ?? (_) {},
   onAddCard: onAddCard ?? (_) {},
   onImportCards: onImportCards ?? (_) {},
+  onExportCards: onExportCards ?? (_) {},
   cardContent: cardContent ?? (_) => const SizedBox.shrink(),
   cardAppBar:
       cardAppBar ??
@@ -211,6 +214,7 @@ DeckLevelScreen cardDeckScreen(String deckId) => deckScreen(
     algorithm: 'Eight boxes',
     onAddCard: () {},
     onOpenCard: (_) {},
+    onExport: (_) {},
   ),
   cardAppBar: (view, back, actions) =>
       CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/presentation/card_bulk_actions_test.dart test/features/deck/presentation/deck_action_sheet_test.dart test/app/library_routes_test.dart
```

Expected: FAIL to compile: `onExport`, `onExportCards` and `cardExport` do not exist.

- [ ] **Step 3: Implement**

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index aaad1b4..158d413 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -19,6 +19,8 @@ import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart'
 import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
 import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
+import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
+import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_app_shell.dart';
 import 'package:memox/shared/widgets/mx_bottom_nav.dart';
@@ -146,6 +148,9 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
         unawaited(context.push(AppRoutes.deckAlgorithm(id))),
     onAddCard: addCard,
     onImportCards: (id) => unawaited(context.push(AppRoutes.importCards(id))),
+    onExportCards: (deck) => unawaited(
+      showDeckExportSheet(context, deckId: deck.id, deckName: deck.name),
+    ),
     cardAppBar: (view, back, actions) =>
         CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
     cardBreadcrumb: (id, child) =>
@@ -155,6 +160,12 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
       algorithm: context.l10n.cardScheduler(view.schedulerType),
       onAddCard: () => addCard(view.deck.id),
       onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
+      onExport: (ids) => unawaited(
+        showCardExportSheet(
+          context,
+          CardExportScope.selection(deckId: view.deck.id, ids: ids),
+        ),
+      ),
     ),
     cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () => addCard(id)),
   );
```

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index f77d9b7..fb4a983 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -57,7 +57,6 @@ abstract final class AppIcons {
   // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
   static const IconData starterDecks = Icons.auto_awesome_outlined; // sparkles
   static const IconData upcoming = Icons.upcoming_outlined; // calendar-plus
-  static const IconData transfer = Icons.import_export; // arrow-up-down
   static const IconData dueNow = Icons.bolt_outlined; // zap
   static const IconData cardDeck = Icons.copy_all_outlined; // copy
   // Card import (kit 11).
```

`lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
index 572b3a6..e4eb78a 100644
--- a/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
+++ b/lib/features/card/presentation/widgets/sections/card_list_section_widget.dart
@@ -46,6 +46,7 @@ class CardListSectionWidget extends ConsumerStatefulWidget {
     required this.algorithm,
     required this.onAddCard,
     required this.onOpenCard,
+    this.onExport,
   });
 
   final String deckId;
@@ -59,6 +60,10 @@ class CardListSectionWidget extends ConsumerStatefulWidget {
   /// A row tap outside selection: the router opens the card's detail.
   final ValueChanged<String> onOpenCard;
 
+  /// Export on the bulk bar: the router opens the export sheet over the
+  /// selection, which stays (UC-TRANSFER-002 A1). Null hides it.
+  final ValueChanged<Set<String>>? onExport;
+
   @override
   ConsumerState<CardListSectionWidget> createState() =>
       _CardListSectionWidgetState();
@@ -150,11 +155,11 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
     if (await write && mounted) _selection().clear();
   }
 
-  /// The bulk bar's commands over [selected]: Move, Flag, Tag, Delete.
-  /// Export waits under Coming soon (spec A4, amended); Select all is in the
-  /// app bar (spec A14).
+  /// The bulk bar's commands over [selected]: Move, Flag, Tag, Export,
+  /// Delete (kit 07). Select all is in the app bar (spec A14).
   List<CardBulkAction> _bulkActions(Set<String> selected) {
     final l10n = context.l10n;
+    final onExport = widget.onExport;
     return [
       (
         icon: AppIcons.folder,
@@ -181,6 +186,12 @@ class _CardListSectionWidgetState extends ConsumerState<CardListSectionWidget> {
           _clearAfter(showCardTagDialog(context, cardIds: selected)),
         ),
       ),
+      if (onExport != null)
+        (
+          icon: AppIcons.fileDown,
+          label: l10n.cardExport,
+          onTap: () => onExport(selected),
+        ),
       (
         icon: AppIcons.delete,
         label: l10n.cardDelete,
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/screens/deck_level_screen.dart b/lib/features/deck/presentation/screens/deck_level_screen.dart
index 5160743..cdb1b36 100644
--- a/lib/features/deck/presentation/screens/deck_level_screen.dart
+++ b/lib/features/deck/presentation/screens/deck_level_screen.dart
@@ -43,6 +43,7 @@ class DeckLevelScreen extends StatelessWidget {
     required this.cardBreadcrumb,
     required this.onAddCard,
     required this.onImportCards,
+    required this.onExportCards,
     required this.cardFab,
   });
 
@@ -77,6 +78,10 @@ class DeckLevelScreen extends StatelessWidget {
   /// import screen.
   final ValueChanged<String> onImportCards;
 
+  /// Export a deck of cards (UC-TRANSFER-002): the router opens the export
+  /// sheet over the whole deck.
+  final ValueChanged<DeckEntity> onExportCards;
+
   /// A deck of cards' FAB, from the card feature like [cardContent] (spec
   /// D8). It hides itself while cards are selected.
   final Widget Function(String deckId) cardFab;
@@ -98,6 +103,7 @@ class DeckLevelScreen extends StatelessWidget {
       cardBreadcrumb: cardBreadcrumb,
       onAddCard: onAddCard,
       onImportCards: onImportCards,
+      onExportCards: onExportCards,
       cardFab: cardFab,
     ),
   };
@@ -115,6 +121,7 @@ class _OpenDeck extends ConsumerWidget {
     required this.cardBreadcrumb,
     required this.onAddCard,
     required this.onImportCards,
+    required this.onExportCards,
     required this.cardFab,
   });
 
@@ -128,6 +135,7 @@ class _OpenDeck extends ConsumerWidget {
   final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
   final ValueChanged<String> onAddCard;
   final ValueChanged<String> onImportCards;
+  final ValueChanged<DeckEntity> onExportCards;
   final Widget Function(String deckId) cardFab;
 
   static const int _skeletonRows = 4;
@@ -152,6 +160,7 @@ class _OpenDeck extends ConsumerWidget {
         cardBreadcrumb: cardBreadcrumb,
         onAddCard: onAddCard,
         onImportCards: onImportCards,
+        onExportCards: onExportCards,
         cardFab: cardFab,
       ),
       AsyncError() => MxAppShell(
@@ -199,6 +208,7 @@ class _OpenDeckContent extends ConsumerWidget {
     required this.cardBreadcrumb,
     required this.onAddCard,
     required this.onImportCards,
+    required this.onExportCards,
     required this.cardFab,
   });
 
@@ -212,6 +222,7 @@ class _OpenDeckContent extends ConsumerWidget {
   final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
   final ValueChanged<String> onAddCard;
   final ValueChanged<String> onImportCards;
+  final ValueChanged<DeckEntity> onExportCards;
   final Widget Function(String deckId) cardFab;
 
   @override
@@ -235,6 +246,11 @@ class _OpenDeckContent extends ConsumerWidget {
           onOpenDeck: onOpenDeck,
           onOpenAlgorithm: onOpenAlgorithm,
           onImportCards: canCreateCard ? () => onImportCards(deck.id) : null,
+          // A deck of cards holds at least one (E-L1); an empty one has
+          // nothing to export (UC-TRANSFER-002 E5).
+          onExportCards: deck.contentType == DeckContentType.card
+              ? () => onExportCards(deck)
+              : null,
           isOpenDeck: true,
         ),
       ),
```

`lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
index 3e1e1be..7048f09 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
@@ -15,6 +15,7 @@ enum DeckAction {
   move,
   reviewAlgorithm,
   importCards,
+  exportCards,
   reorder,
   delete,
 }
@@ -28,6 +29,7 @@ Future<DeckAction?> showDeckActionSheet(
   required bool canReorder,
   required bool hasOpen,
   bool canImport = false,
+  bool canExport = false,
 }) => showMxBottomSheet<DeckAction>(
   context,
   builder: (_) => DeckActionSheetWidget(
@@ -35,6 +37,7 @@ Future<DeckAction?> showDeckActionSheet(
     canReorder: canReorder,
     hasOpen: hasOpen,
     canImport: canImport,
+    canExport: canExport,
   ),
 );
 
@@ -45,6 +48,7 @@ class DeckActionSheetWidget extends StatelessWidget {
     required this.canReorder,
     required this.hasOpen,
     this.canImport = false,
+    this.canExport = false,
   });
 
   final DeckView view;
@@ -54,6 +58,10 @@ class DeckActionSheetWidget extends StatelessWidget {
   /// deckActions, UC-TRANSFER-001).
   final bool canImport;
 
+  /// The deck holds cards: Export opens the export sheet (kit 12,
+  /// UC-TRANSFER-002).
+  final bool canExport;
+
   /// From a row, the deck is not open yet; Open leads.
   final bool hasOpen;
 
@@ -126,6 +134,13 @@ class DeckActionSheetWidget extends StatelessWidget {
           hasChevron: true,
           onTap: () => choose(DeckAction.importCards),
         ),
+      if (canExport)
+        MxActionSheetCommandRow(
+          icon: AppIcons.fileDown,
+          label: l10n.deckActionExport,
+          hasChevron: true,
+          onTap: () => choose(DeckAction.exportCards),
+        ),
       if (canReorder)
         MxActionSheetCommandRow(
           icon: AppIcons.reorder,
```

`lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
index 6ec5cb6..83019be 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart
@@ -35,7 +35,6 @@ class DeckComingSoonSheetWidget extends StatelessWidget {
       l10n.comingSoonStarterDecksBody,
     ),
     (AppIcons.delete, l10n.libraryTrash, l10n.comingSoonTrashBody),
-    (AppIcons.transfer, l10n.comingSoonTransfer, l10n.comingSoonTransferBody),
   ];
 
   @override
```

`lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
index eda7090..ee413ba 100644
--- a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
@@ -14,7 +14,8 @@ import 'package:memox/shared/widgets/mx_snackbar.dart';
 
 /// Opens a deck's action sheet and then the chosen command's own dialog or
 /// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮.
-/// [onImportCards] offers Import on a deck that takes cards (UC-TRANSFER-001). It reads
+/// [onImportCards] offers Import on a deck that takes cards (UC-TRANSFER-001),
+/// [onExportCards] Export on a deck of cards (UC-TRANSFER-002). It reads
 /// the deck's view once first, so a deck gone meanwhile says so instead
 /// (ruling C-L6).
 Future<void> openDeckActions(
@@ -26,6 +27,7 @@ Future<void> openDeckActions(
   required ValueChanged<String> onOpenAlgorithm,
   required bool isOpenDeck,
   VoidCallback? onImportCards,
+  VoidCallback? onExportCards,
 }) async {
   // A row's deck has no listener yet: keep its view alive until it emits,
   // or the auto-disposed provider would never complete the read.
@@ -55,6 +57,7 @@ Future<void> openDeckActions(
     canReorder: canReorder,
     hasOpen: !isOpenDeck,
     canImport: onImportCards != null,
+    canExport: onExportCards != null,
   );
   if (action == null || !context.mounted) return;
   switch (action) {
@@ -68,6 +71,8 @@ Future<void> openDeckActions(
       onOpenAlgorithm(deckId);
     case DeckAction.importCards:
       onImportCards?.call();
+    case DeckAction.exportCards:
+      onExportCards?.call();
     case DeckAction.reorder:
       ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
     case DeckAction.delete:
```

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index 5160ef6..1fe471f 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1751,14 +1751,6 @@
   "@comingSoonProgressSortBody": {
     "description": "Coming soon: what the progress sort does."
   },
-  "comingSoonTransfer": "Export cards",
-  "@comingSoonTransfer": {
-    "description": "Coming soon: the export feature's name (import shipped, FE-B3)."
-  },
-  "comingSoonTransferBody": "Cards to a file, for a spreadsheet or another app.",
-  "@comingSoonTransferBody": {
-    "description": "Coming soon: what export does."
-  },
   "cardDeckProgress": "Deck progress · {algorithm}",
   "@cardDeckProgress": {
     "placeholders": {
@@ -3093,5 +3085,13 @@
   "exportEmptyBody": "This deck has no cards. Add or import cards first.",
   "@exportEmptyBody": {
     "description": "Export banner body for E5."
+  },
+  "deckActionExport": "Export cards",
+  "@deckActionExport": {
+    "description": "Deck action sheet: opens the export sheet over the whole deck (UC-TRANSFER-002)."
+  },
+  "cardExport": "Export",
+  "@cardExport": {
+    "description": "Bulk bar: export the selected cards (UC-TRANSFER-002 A1)."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 4d35f02..e49958b 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -349,8 +349,6 @@
   "comingSoonStudyOptionsBody": "Số thẻ mỗi phiên, thứ tự thẻ mới.",
   "comingSoonProgressSort": "Sắp xếp theo độ thuộc",
   "comingSoonProgressSortBody": "Bộ thẻ thuộc ít nhất lên trước.",
-  "comingSoonTransfer": "Xuất thẻ",
-  "comingSoonTransferBody": "Thẻ ra tệp, cho bảng tính hoặc ứng dụng khác.",
   "cardDeckProgress": "Tiến độ bộ thẻ · {algorithm}",
   "cardMasteredOf": "{mastered}/{total} thẻ đã thuộc",
   "cardShowingOf": "Đang hiện {shown}/{total}",
@@ -623,5 +621,7 @@
   "exportStaleTitle": "Một thẻ đã chọn không còn trong bộ thẻ này",
   "exportStaleBody": "Thẻ đó vừa bị chuyển hoặc xoá. Chưa xuất gì. Hãy chọn lại rồi xuất lần nữa.",
   "exportEmptyTitle": "Không có gì để xuất",
-  "exportEmptyBody": "Bộ thẻ này chưa có thẻ. Hãy thêm hoặc nhập thẻ trước."
+  "exportEmptyBody": "Bộ thẻ này chưa có thẻ. Hãy thêm hoặc nhập thẻ trước.",
+  "deckActionExport": "Xuất thẻ",
+  "cardExport": "Xuất"
 }
```

- [ ] **Step 4: Regenerate, re-render the goldens, run**

```bash
flutter gen-l10n
flutter test --tags golden --update-goldens test/features/deck test/features/card test/app
flutter test test/features/deck test/features/card test/app test/features/transfer test/shared test/visual_audit
flutter analyze
```

Expected: PASS. Six goldens change, and only these:
- `library_coming_soon_{light,dark}`: the export row is gone.
- `card_selection_{light,dark}` and `card_list_bulk_failed_{light,dark}`: the bulk bar
  reads Move · Flag · Tag · Export · Delete.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_router.dart \
  lib/core/theme/foundations/app_icons.dart \
  lib/features/card/presentation/widgets/sections/card_list_section_widget.dart \
  lib/features/deck/presentation/screens/deck_level_screen.dart \
  lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart \
  lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/app/library_routes_test.dart \
  test/features/card/presentation/card_bulk_actions_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_level_screen_test.dart \
  test/support/library_harness.dart \
  test/features/card/presentation/goldens/card_list_bulk_failed_dark.png \
  test/features/card/presentation/goldens/card_list_bulk_failed_light.png \
  test/features/card/presentation/goldens/card_selection_dark.png \
  test/features/card/presentation/goldens/card_selection_light.png \
  test/features/deck/presentation/goldens/library_coming_soon_dark.png \
  test/features/deck/presentation/goldens/library_coming_soon_light.png
git commit -m "$(cat <<'EOF'
feat(transfer): export from the deck sheet and the bulk bar (UC-TRANSFER-002)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: The sheet's handoff, the documents and the gate

**Files:**
- Modify: `tools/design/screen_states.json`
- Modify: `docs/README.md`
- Modify: `docs/features/transfer/README.md`
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`
- Create: `docs/shared/ui/screen-handoff/12-card-export.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/shared/ui/screen-handoff/img/12-card-export/*.png (18 files)`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents).

- [ ] **Step 1: Capture the kit's screen 12**

`tools/design/screen_states.json` (apply this diff):

```diff
diff --git a/tools/design/screen_states.json b/tools/design/screen_states.json
index c259f11..029898c 100644
--- a/tools/design/screen_states.json
+++ b/tools/design/screen_states.json
@@ -100,6 +100,22 @@
         { "id": "rejects", "label": "Deck rejects" }
       ]
     },
+    {
+      "num": "12",
+      "dir": "12-card-export",
+      "title": "Card export",
+      "states": [
+        { "id": "wholeDeck", "label": "Whole deck" },
+        { "id": "selection", "label": "Selection" },
+        { "id": "preparing", "label": "Preparing" },
+        { "id": "handedOver", "label": "Handed over" },
+        { "id": "shareClosed", "label": "Share closed" },
+        { "id": "failed", "label": "Failed" },
+        { "id": "noShareTarget", "label": "No share target" },
+        { "id": "staleSelection", "label": "Stale selection" },
+        { "id": "nothingToExport", "label": "Nothing to export" }
+      ]
+    },
     {
       "num": "13",
       "dir": "13-study-home",
```

```bash
node tools/design/capture_screens.mjs --html <artifact.html> --only 12
```

Expected: 18 images in `docs/shared/ui/screen-handoff/img/12-card-export/`.

- [ ] **Step 2: Write the detail file and update the documents**

`docs/README.md` (apply this diff):

```diff
diff --git a/docs/README.md b/docs/README.md
index 5f74c4e..abf4a71 100644
--- a/docs/README.md
+++ b/docs/README.md
@@ -60,7 +60,7 @@ Hai trục độc lập (thuật toán SRS và StudyMode) và hai loại phiên:
 
 | # | Feature | Notes |
 |---|---|---|
-| N1 | Import/export | Trong V8.0 theo [spec card transfer](superpowers/specs/2026-09-26-card-transfer-design.md) (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-001…BR-TRANSFER-014): import CSV/TSV/XLSX hoặc văn bản dán (màn 11), export nội dung (sheet 12) — không phải backup. Backend BE-B3 xong; UI là FE-B3 |
+| N1 | Import/export | Trong V8.0 theo [spec card transfer](superpowers/specs/2026-09-26-card-transfer-design.md) (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-001…BR-TRANSFER-014): import CSV/TSV/XLSX hoặc văn bản dán (màn 11), export nội dung (sheet 12) — không phải backup. Backend BE-B3 và UI FE-B3 xong |
 | N2 | Nhắc nhở ôn tập hằng ngày | Sub-project sau (UC-REMINDER-001, BR-REMINDER-001…BR-REMINDER-012): opt-in, mặc định tắt, một tóm tắt mỗi ngày dựng từ workload đến hạn tại thời điểm hiện tại. Quyền notification chỉ được xin **sau** khi người dùng bật (BR-REMINDER-011) |
 | N3 | Tag/phân loại card | Sub-project sau (UC-TAG-001, BR-TAG-003…BR-TAG-011): catalog phạm vi library, lọc nhiều tag theo OR, đổi tên có gộp, và xoá. Ngoài phạm vi: tag phân cấp, màu tag, taxonomy chia sẻ |
 
```

`docs/features/transfer/README.md` (apply this diff):

```diff
diff --git a/docs/features/transfer/README.md b/docs/features/transfer/README.md
index 4823cfe..cab94e4 100644
--- a/docs/features/transfer/README.md
+++ b/docs/features/transfer/README.md
@@ -1,11 +1,11 @@
 ---
 feature: transfer
-code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di]
+code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di, lib/features/transfer/presentation]
 depends_on: [card, deck, tags]
 ---
 ## Phạm vi
 
-**Phạm vi:** Card Transfer: backend BE-B3 xong; màn hình import (kit 11) và sheet export (kit 12) là FE-B3. Thiết kế: [spec card transfer](../../superpowers/specs/2026-09-26-card-transfer-design.md).
+**Phạm vi:** Card Transfer: backend BE-B3 và giao diện FE-B3 xong — màn import ([kit 11](../../shared/ui/screen-handoff/11-card-import.md)) và sheet export ([kit 12](../../shared/ui/screen-handoff/12-card-export.md)). Thiết kế: [spec card transfer](../../superpowers/specs/2026-09-26-card-transfer-design.md).
 
 Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).
 
```

`docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md` (apply this diff):

```diff
diff --git a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
index 28f2a79..ffd8297 100644
--- a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
+++ b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
@@ -7,7 +7,7 @@ code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, l
 ---
 ## Mục tiêu / Actor / Precondition
 
-**Phạm vi:** backend xong ở BE-B3; màn hình là FE-B3 ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md)).
+**Phạm vi:** backend BE-B3 và màn import FE-B3 đã xong ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md), [màn 11](../../../shared/ui/screen-handoff/11-card-import.md)).
 
 **Actor:** Người dùng
 **Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
```

`docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md` (apply this diff):

```diff
diff --git a/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md b/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
index 6b9d0b1..6860a80 100644
--- a/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
+++ b/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
@@ -3,11 +3,11 @@ id: UC-TRANSFER-002
 title: Export card của một deck ra file
 status: ready
 rules: [BR-CARD-012, BR-DECK-015, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-TAG-001, BR-TAG-002, BR-TRANSFER-007, BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014]
-code: [lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/features/transfer/domain/usecases/share_export_use_case.dart]
+code: [lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/features/transfer/domain/usecases/share_export_use_case.dart, lib/features/transfer/domain/usecases/count_export_cards_use_case.dart, lib/features/transfer/presentation/controllers/card_export_controller.dart, lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
-**Phạm vi:** backend xong ở BE-B3; sheet export là FE-B3 ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md)).
+**Phạm vi:** backend BE-B3 và sheet export FE-B3 đã xong ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md), [màn 12](../../../shared/ui/screen-handoff/12-card-export.md)).
 
 **Actor:** Người dùng
 **Trigger:** Chọn `Export cards` trong overflow menu của card list, hoặc
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 0ab75fa..34b084f 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -41,7 +41,7 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 09 | Card edit | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
 | 10 | Card detail | 7 | FE-A2 | built | — (#35, #36; UI-base §9 rows 85–90) |
 | 11 | Card import | 16 | FE-B3 | aligned | [11-card-import.md](11-card-import.md) |
-| 12 | Card export | 9 | FE-B3 | not built | — |
+| 12 | Card export | 9 | FE-B3 | aligned | [12-card-export.md](12-card-export.md) |
 | 13 | Study home | 7 | FE-A8 | not built | [13-study-home.md](13-study-home.md) |
 | 14 | Study entry | 9 | FE-A6, FE-A7 | not built | [14-study-entry.md](14-study-entry.md) |
 | 15 | Study options | 7 | FE-A3 | not built | — |
```

`docs/shared/ui/screen-handoff/07-card-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/07-card-list.md b/docs/shared/ui/screen-handoff/07-card-list.md
index f06574b..48aada1 100644
--- a/docs/shared/ui/screen-handoff/07-card-list.md
+++ b/docs/shared/ui/screen-handoff/07-card-list.md
@@ -16,13 +16,13 @@ An open deck whose content type is `card`: the card section of `DeckLevelScreen`
 | Filters | `MxFilterChip` | All · Due · New · Flagged with counts; the Tags filter waits under Coming soon (FE-B2). |
 | Header | `MxListSectionHeader` + `MxChipTrigger` | "Showing {n} of {total}" (selecting: "{n} of {total} selected"); sort "Newest first ⌄" / "Due first ⌄". |
 | Rows | card surface per row, 8 apart | Status dot (checkbox while selecting); front 16/700 and back 12, one line each; uppercase status label in its ink, up to two `MxTagChip`s and "+{n}"; trailing flag in the warning colour (E-L2) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
-| Bulk bar | `MxFooterBar` with four icon buttons | Move · Flag · Tag · Delete; Export waits under Coming soon (FE-B3). |
+| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Delete. |
 | FAB | `MxFab` | "New card" (#33); hidden while selecting. |
 
 ## Deck action sheet (`⋮`)
 
-Rename · Move to another deck · Import cards (screen 11) · Delete. Study and Export wait
-under Coming soon (spec A4; FE-A6, FE-B3).
+Rename · Move to another deck · Import cards (screen 11) · Export cards (screen 12) ·
+Delete. Study waits under Coming soon (spec A4; FE-A6).
 
 ## States
 
@@ -50,7 +50,7 @@ detail: a tap opens it (#35).
 | Artifact | V8 | Wins |
 |---|---|---|
 | Move to Trash with Undo, for cards and for the deck | Permanent delete with a count, no Undo | BR-DECK-022, BR-DECK-023, UC-CARD-002 |
-| Tags filter, Export, Study | Hidden; named under Coming soon | Spec A4 (amended) |
+| Tags filter, Study | Hidden; named under Coming soon | Spec A4 (amended) |
 | An empty card list | The deck is unset again: screen 01's unset state | BR-DECK-015, ruling E-L1 |
 | The flag in the streak colour | The flag in the warning colour; the theme has no streak token | Ruling E-L2 |
 | "Select all" as a text link | A compact secondary `MxButton` | Ruling E-L3 |
```

`docs/shared/ui/screen-handoff/12-card-export.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 12 · Card export

A bottom sheet that hands a deck's cards, or the selected ones, to the system share
sheet as a CSV, TSV or XLSX file. UC-TRANSFER-002; spec
[2026-09-26-card-transfer-design.md](../../../superpowers/specs/2026-09-26-card-transfer-design.md)
§6, §8.

## Entry points

- The open deck's `⋮` sheet, "Export cards": a deck of cards only. An unset deck, a root
  and a deck of decks do not offer it (UC-TRANSFER-002 E5). The deck's cards are
  counted before the sheet opens, so the sheet never loads.
- The card list's bulk bar, "Export": the selected cards. The selection stays after the
  export (A1).

## Layout

| Region | Widget | Design |
|---|---|---|
| Header | `MxBottomSheet` header | "Export all {n} cards" and "Every card in {deck}, whatever filter or search is active."; for a selection, "Export {n} selected cards" and "Only the cards you selected." |
| Problem | `MxInlineBanner` | One banner per problem, above the formats. Danger for a file that could not be prepared, warning otherwise. |
| Formats | `MxListSectionHeader` + `MxOptionRow` × 3 | CSV (default, "Recommended" badge), TSV, XLSX, each with what it is for. Locked while a file is prepared. |
| Content note | `MxNote` (file icon) | The six columns; no schedule, no history. |
| Footer | `MxSheetActions` (sheet form) | Cancel · "Export {n} cards" with the share icon; "Preparing…" spinning while the file is built and shared (A4); "Try again" after a failure it can fix; Close alone when it cannot. |
| Toast | `MxSnackbar` | "Handed {n} cards to the system." once the share sheet took the file. |

The overline, the banner and the note line up with the title (20 dp).

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| wholeDeck | ![](img/12-card-export/wholeDeck-light.png) | ![](img/12-card-export/wholeDeck-dark.png) | CSV carries "Recommended"; the action reads "Export {n} cards". |
| selection | ![](img/12-card-export/selection-light.png) | ![](img/12-card-export/selection-dark.png) | As wholeDeck. |
| preparing | ![](img/12-card-export/preparing-light.png) | ![](img/12-card-export/preparing-dark.png) | As drawn; Cancel closes the sheet and nothing is shared. |
| handedOver | ![](img/12-card-export/handedOver-light.png) | ![](img/12-card-export/handedOver-dark.png) | The toast names no file. |
| shareClosed | ![](img/12-card-export/shareClosed-light.png) | ![](img/12-card-export/shareClosed-dark.png) | **Deviation:** the export sheet stays open, as it was. |
| failed | ![](img/12-card-export/failed-light.png) | ![](img/12-card-export/failed-dark.png) | For a read or encode failure. A share failure has its own copy, also with Try again. |
| noShareTarget | ![](img/12-card-export/noShareTarget-light.png) | ![](img/12-card-export/noShareTarget-dark.png) | As drawn; the banner shows the warning glyph. |
| staleSelection | ![](img/12-card-export/staleSelection-light.png) | ![](img/12-card-export/staleSelection-dark.png) | "Moved or deleted", not "sent to Trash": V8.0 has no Trash. |
| nothingToExport | ![](img/12-card-export/nothingToExport-light.png) | ![](img/12-card-export/nothingToExport-dark.png) | Reached only by a deck emptied between the count and the export, or by a count of 0. |

Goldens: `test/features/transfer/presentation/goldens/export_{deck,failed,stale}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| Closing the share sheet closes the export sheet | The export sheet stays open with its scope and format | UC-TRANSFER-002 A3 (ruling E1) |
| "Handed 12 cards to the system as nha-hang-2026-09-16.csv" | "Handed 12 cards to the system." | Spec §7, BR-TRANSFER-014 (ruling E2) |
| CSV without a label | CSV carries a "Recommended" badge | UC-TRANSFER-002 step 2 (ruling E3) |
| One "Couldn't prepare the file" for every failure | Read and encode failures share it; a share failure has its own copy; both offer Try again | UC-TRANSFER-002 E2–E4 (ruling E4) |
| `deckActions` offers "Export all N cards" on every deck | "Export cards" on a deck of cards only; Coming soon no longer lists export | UC-TRANSFER-002 E5 (ruling E5) |
| "Export and share" | "Export {n} cards" | UC-TRANSFER-002 step 3 (owner 2026-09-26) |
| A file name folded to ASCII (`nha-hang-…`) | The deck's own letters (`Nhà-hàng-2026-09-26.csv`) | BR-TRANSFER-013, backend plan C5 |
| A glyph per banner (share, copy) | The banner's tone glyph | `MxInlineBanner` has no glyph slot |
| "Moved or sent to Trash" | "Moved or deleted" | V8.0 has no Trash (BR-DECK-022) |

## Copy

- Header: "Export all {n} cards" · "Every card in {deck}, whatever filter or search is active." · "Export {n} selected cards" · "Only the cards you selected."
- Formats: "Format" · "CSV" · "Comma-separated · opens anywhere" · "TSV" · "Tab-separated · safest for commas in text" · "XLSX" · "Excel workbook" · "Recommended".
- Note: "Six columns: front, back, example, hint, pronunciation, tags. No schedule, no history — this is content, not a backup."
- Actions: "Cancel" · "Export {n} cards" · "Preparing…" · "Try again" · "Close".
- Problems: "Couldn’t prepare the file" · "Couldn’t hand the file over" · "No app on this device can receive a file" · "A selected card is no longer in this deck" · "There is nothing to export".
- Toast: "Handed {n} cards to the system."
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index f3f8b96..c3bb849 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -89,7 +89,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 |---|---|---|---|---|---|---|
 | FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | [README trash](features/trash/README.md) | Sau BE-B1 |
 | FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
-| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | đang làm | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md); test trong `test/features/transfer/presentation/` | Plan 2: sheet export (màn 12), Export trên bulk bar và `⋮` |
+| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
 | FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
 | FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |
 
```

- [ ] **Step 3: Regenerate the docs index and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: no error (the existing warnings stay).

- [ ] **Step 4: The gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: every gate green.

- [ ] **Step 5: Commit and push**

```bash
git add \
  tools/design/screen_states.json \
  docs/README.md \
  docs/features/transfer/README.md \
  docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md \
  docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/07-card-list.md \
  docs/shared/ui/screen-handoff/12-card-export.md \
  docs/wbs_FE.md \
  docs/shared/ui/screen-handoff/img/12-card-export \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(transfer): screen 12 handoff; FE-B3 done

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```
