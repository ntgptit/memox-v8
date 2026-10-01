# Critique 2026-09-30 part 3d-2 (low-impact and cosmetic findings) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the critique's low-impact and cosmetic findings on 01, 02, 03, 05, 08/09, 10, 11, 12, 14, 24, 28, the Progress and Settings skeletons and `MxEmptyState`, plus the three 3d-1 deferred minors on 07, 15 and 27.

**Architecture:** Each item is a local change in its feature's presentation layer. Two shared widgets gain one small thing each (`MxStepper.minDigits`, `MxEmptyState`'s warning ink), approved by the owner (E14). The card form asks its tag editor to add pending text through a `GlobalKey` and a public `commitPending()`, the way a `Form` asks its `FormState` to validate. ARB keys are edited in both files, then `flutter gen-l10n`.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, ARB l10n (`flutter gen-l10n`), flutter_test with `libraryTest` / `pumpLibraryScreen` / `pumpMx`.

**Spec:** `docs/superpowers/specs/2026-10-01-critique-fixes-part3d2-design.md` (approved 2026-10-01, rulings E1–E14).

## Global Constraints

- Shared widgets change only as E14 says: `MxStepper` gains `int minDigits = 1`; `MxEmptyState` draws the warning glyph in `warningInk`. No other change to `lib/core` or `lib/shared`.
- BR-TAG-008: the tag delete dialog keeps "No card is deleted, hidden or changed — …" and the destructive confirm.
- BR-SRS-030: the reset dialog keeps its copy and tiles; only the confirm tone changes.
- BR-TAG-001/002: a tag added by "Add" or by Save goes through the same checks as Done (`CardDraft.checkTagNames`).
- BR-TRANSFER-003: "Include duplicates" stays; it moves.
- Copy, verbatim:
  - `deckSortRecent`: en "Date added", vi "Ngày tạo" (hint unchanged);
  - `importPickBody`: en "Nothing is added until you confirm.", vi "Chưa thêm gì cho tới khi bạn xác nhận.";
  - `exportStaleBody`: en "It was moved to another deck or sent to Trash meanwhile. Nothing was exported. Close this sheet, check your selection and export again.", vi "Thẻ đó vừa được chuyển sang bộ thẻ khác hoặc vào Thùng rác. Chưa xuất gì. Hãy đóng bảng này, xem lại các thẻ đã chọn rồi xuất lần nữa.";
  - removed from both ARBs: `starterSheetBody`, `monitoringCountOpen`, `monitoringCountOpenMore`.
- Every new or edited en ARB key keeps an `@key` with a `description` (`test/app/l10n_test.dart`).
- The guard counts logical lines: a file over 400 warns and fails the gate; `build()` over 100 lines fails. Split a test file rather than grow one past 400.
- Goldens regenerate only in the Linux container with `TZ=UTC`.
- Every commit message ends with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01WHcLQhgp72txzYGsDLm7JX`.

## Review Focus

1. 08/09 Save pressed while the tag field holds a name already on the card (any case): nothing is added twice and the save goes through. Pinned in Task 5.
2. 08 "Save and add another" after Save added a pending tag: the next card starts with no tags and an empty tag field. Pinned in Task 5.
3. 07 Retry while it runs: a second tap on Retry or on a bulk command does nothing. Pinned in Task 12.
4. 15 after a failed save, an edit then a successful save: the banner leaves and "Retry save" turns back to "Save". Pinned in Task 12.
5. 24 a typed minute "7" in the reminder dialog: it reads back as "07", and Save stores 7. Pinned in Task 9.

---

### Task 1: Library sort label and reorder (01, E2, E3)

**Files:**
- Modify: `lib/l10n/app_en.arb` (`deckSortRecent`), `lib/l10n/app_vi.arb` (`deckSortRecent`)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart:111-125`
- Test: `test/features/deck/presentation/deck_reorder_test.dart`

**Interfaces:** consumes `isReordering` already watched in `DeckLibraryRootWidget.build`.

- [ ] **Step 1: Write the failing tests**

Add to `deck_reorder_test.dart` (imports `MxSearchField` from `package:memox/shared/widgets/mx_search_field.dart`):

```dart
  libraryTest('reorder hides the search field; Done brings it back '
      '(critique 2026-09-30 part 3d-2, E3)', (tester, env) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byType(MxSearchField), findsOneWidget);

    await _startReorder(tester);
    expect(find.byType(MxSearchField), findsNothing);

    await tester.tap(find.text(_en.libraryReorderDone));
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsOneWidget);
  });

  test('the recent sort is named by date added, its hint says the order '
      '(critique 2026-09-30 part 3d-2, E2)', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    expect(_en.deckSortRecent, 'Date added');
    expect(_en.deckSortRecentHint, 'Newest first');
    expect(vi.deckSortRecent, 'Ngày tạo');
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/deck/presentation/deck_reorder_test.dart --plain-name "critique 2026-09-30 part 3d-2"`
Expected: FAIL — the search field is found while reordering; `deckSortRecent` is "Newest".

- [ ] **Step 3: Implement**

ARB: en `"deckSortRecent": "Date added"`, vi `"deckSortRecent": "Ngày tạo"` (keep the en `@deckSortRecent` description). Run `flutter gen-l10n`.

In `deck_library_root_widget.dart`, guard the search padding:

```dart
        children: [
          // Reorder mode leaves the deck list alone, as it leaves out the
          // summary and the sort pill (critique 2026-09-30 part 3d-2, E3).
          if (!isReordering)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.micro,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: MxSearchField.trigger(
                hintText: l10n.searchFieldHint,
                onTap: onSearch,
              ),
            ),
          Expanded(
```

- [ ] **Step 4: Run the file**

Run: `flutter test test/features/deck/presentation/deck_reorder_test.dart`
Expected: PASS (all). Then `flutter test test/features/deck` → PASS (a test that read "Newest" fails here: update it to `_en.deckSortRecent` and ledger it).

- [ ] **Step 5: Commit**

```bash
git add lib/l10n lib/features/deck test/features/deck
git commit -m "feat(deck): Date added sort label; search steps aside while reordering (critique 3d-2, E2 E3)"
```

---

### Task 2: Reset confirm and inert heroes (02, 14, E4, E5)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart:136-144`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_lock_strip_widget.dart:32-34`
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart:31-32`
- Test: `test/features/deck/presentation/deck_reset_dialog_test.dart`, `test/features/deck/presentation/deck_algorithm_screen_test.dart`, `test/features/study/presentation/study_entry_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

`deck_reset_dialog_test.dart` (import `package:memox/shared/widgets/mx_sheet_actions.dart`):

```dart
  libraryTest('the reset confirm is warning, not the action Indigo '
      '(critique 2026-09-30 part 3d-2, E4)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'a',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.isWarning, isTrue);
    expect(actions.isDestructive, isFalse);
  });
```

`deck_algorithm_screen_test.dart`:

```dart
  libraryTest('the unlocked strip is a plain card; the locked one warning '
      '(critique 2026-09-30 part 3d-2, E5)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    MxCard strip() => tester.widget<MxCard>(
      find.descendant(
        of: find.byType(DeckLockStripWidget),
        matching: find.byType(MxCard),
      ),
    );
    expect(strip().isHero, isFalse);
    expect(strip().isWarning, isFalse);

    await lockScheduler(env.db, korean.id);
    await tester.pumpAndSettle();
    expect(strip().isWarning, isTrue);
  });
```

`study_entry_screen_test.dart` (import `package:memox/features/study/presentation/widgets/sections/study_entry_hero_widget.dart` and `package:memox/shared/widgets/mx_card.dart`):

```dart
  libraryTest('the hero is a plain card: it leads nowhere (critique '
      '2026-09-30 part 3d-2, E5)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'n1', deckId: leaf.id);
    await pumpLibraryScreen(tester, env, _screen(leaf.id));

    final card = tester.widget<MxCard>(
      find
          .descendant(
            of: find.byType(StudyEntryHeroWidget),
            matching: find.byType(MxCard),
          )
          .first,
    );
    expect(card.isHero, isFalse);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/deck/presentation/deck_reset_dialog_test.dart test/features/deck/presentation/deck_algorithm_screen_test.dart test/features/study/presentation/study_entry_screen_test.dart --plain-name "part 3d-2"`
Expected: FAIL — `isWarning` false; `isHero` true (twice).

- [ ] **Step 3: Implement**

Reset dialog, in the `MxSheetActions(...)` call add after `isConfirmLoading: _isResetting,`:

```dart
        // An irreversible loss of progress, not of data: warning, as the
        // Lost tile (critique 2026-09-30 part 3d-2, E4).
        isWarning: true,
```

Lock strip:

```dart
      child: MxCard(
        // Status, not a door: no hero ground (critique 2026-09-30 part 3d-2,
        // E5; DESIGN.md "a hero leads somewhere tappable").
        isWarning: isLocked,
```

Study entry hero:

```dart
    // A summary, not a door (critique 2026-09-30 part 3d-2, E5).
    return MxCard(
      child: Column(
```

- [ ] **Step 4: Run the three files and the features**

Run: `flutter test test/features/deck test/features/study`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck lib/features/study test/features/deck test/features/study
git commit -m "feat(deck,study): warning reset confirm; inert strip and entry hero are plain cards (critique 3d-2, E4 E5)"
```

---

### Task 3: Starter sheet states the lock (03, E6)

**Files:**
- Modify: `lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart:92-98`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (remove `starterSheetBody` and `@starterSheetBody`)
- Test: `test/features/starter_decks/presentation/starter_library_screen_test.dart:123`

- [ ] **Step 1: Write the failing test**

Replace line 123 (`expect(find.text(_en.starterSheetBody(60, 2)), findsOneWidget);`) with:

```dart
    // The lock, not the counts the card already states (critique
    // 2026-09-30 part 3d-2, E6).
    expect(find.text(_en.deckSchedulerNote), findsOneWidget);
    expect(find.textContaining('sub-decks, as a new deck'), findsNothing);
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/starter_decks/presentation/starter_library_screen_test.dart --plain-name "choose: the sheet"`
Expected: FAIL — `deckSchedulerNote` not found.

- [ ] **Step 3: Implement**

In the sheet header replace the `starterSheetBody` text:

```dart
            // The lock, before the choice (BR-SRS-003; critique 2026-09-30
            // part 3d-2, E6). The card above states the counts.
            Text(l10n.deckSchedulerNote, style: styles.footerCaption),
```

Delete `starterSheetBody` and its `@starterSheetBody` block from `app_en.arb`, and `starterSheetBody` from `app_vi.arb`. Run `flutter gen-l10n`.

- [ ] **Step 4: Run the feature**

Run: `flutter test test/features/starter_decks test/app/l10n_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n lib/features/starter_decks test/features/starter_decks
git commit -m "feat(starter): the sheet states the lock instead of repeating the counts (critique 3d-2, E6)"
```

---

### Task 4: Tags empty state and delete note (05, E7)

**Files:**
- Modify: `lib/features/tags/presentation/screens/tags_screen.dart:139-148, 176-199`
- Modify: `lib/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart:35-51`
- Test: `test/features/tags/presentation/tags_screen_test.dart:101-110, 228-249`

- [ ] **Step 1: Write the failing tests**

Replace the body of `'empty: a library without tags says where they come from'` with:

```dart
    await _pump(tester, env, isSeeded: false);

    // Only the empty state: no search over nothing, no header that says it
    // twice (critique 2026-09-30 part 3d-2).
    expect(find.text(_en.tagsEmptyTitle), findsOneWidget);
    expect(find.text(_en.tagsGoToLibrary), findsOneWidget);
    expect(find.byType(MxSearchField), findsNothing);
    expect(find.text(_en.tagsNone.toUpperCase()), findsNothing);
```

In `'del: the dialog says no card is deleted; …'`, after `expect(find.text(_en.tagsDeleteSafe(46)), findsOneWidget);` add:

```dart
    // A neutral note, not a success card beside a destructive confirm
    // (critique 2026-09-30 part 3d-2, E7).
    expect(
      find.ancestor(
        of: find.text(_en.tagsDeleteSafe(46)),
        matching: find.byType(MxNote),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is MxCard && widget.isSuccess),
      findsNothing,
    );
```

(imports: `mx_search_field.dart`, `mx_note.dart`, `mx_card.dart` from `package:memox/shared/widgets/` as needed.)

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/tags/presentation/tags_screen_test.dart --plain-name "empty:"` and `--plain-name "del:"`
Expected: FAIL — the search field and the header show; the note is a success `MxCard`.

- [ ] **Step 3: Implement**

`tags_screen.dart` — the field and its gap show only when there is something to search:

```dart
      body: MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          // Nothing to search in a catalog with no tags (critique 2026-09-30
          // part 3d-2).
          if (catalog case AsyncData(:final value) when value.isEmpty)
            ..._catalog(l10n, value)
          else ...[
            MxSearchField(
              controller: _search,
              hintText: l10n.tagsSearchHint,
              clearLabel: l10n.tagsSearchClear,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.grouped),
            ...switch (catalog) {
              // the existing AsyncData / AsyncError / loading arms, unchanged
            },
          ],
        ],
      ),
```

Keep the three existing switch arms exactly as they are inside the `else`. In `_catalog`, the `tags.isEmpty` branch returns only the empty state:

```dart
    if (tags.isEmpty) {
      return [
        MxEmptyState(
          icon: AppIcons.tag,
          title: l10n.tagsEmptyTitle,
          body: l10n.tagsEmptyBody,
          actionLabel: l10n.tagsGoToLibrary,
          onAction: _back,
        ),
      ];
    }
```

and the header's label switch drops the `(true, _)` arm:

```dart
      label: shown.isEmpty ? l10n.tagsNoMatches : l10n.tagsCount(shown.length),
```

If `l10n.tagsNone` is then unused anywhere (`grep -rn tagsNone lib test`), remove it from both ARBs and run `flutter gen-l10n`; ledger it.

`tag_delete_dialog_widget.dart`:

```dart
      // A neutral note: the reassurance BR-TAG-008 asks for, without a
      // success ground beside the destructive confirm (critique 2026-09-30
      // part 3d-2, E7).
      content: MxNote(icon: AppIcons.safe, text: l10n.tagsDeleteSafe(count)),
```

Remove imports the dialog no longer uses (`mx_card.dart`, `theme_context.dart` if unused, `app_spacing.dart` if unused).

- [ ] **Step 4: Run the feature**

Run: `flutter test test/features/tags`
Expected: PASS (goldens excluded by tag on Windows; in the container they run in Task 14).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tags lib/l10n test/features/tags
git commit -m "feat(tags): empty catalog shows only its empty state; neutral delete note (critique 3d-2, E7)"
```

---

### Task 5: Tag input — Add button, Save adds the pending tag (08, 09, E8)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_tag_editor_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (`_save`, `_clearForNext`, the `CardTagEditorWidget(...)` call)
- Create: `test/features/card/presentation/card_tag_input_test.dart`

**Interfaces:**
- Produces: `class CardTagEditorWidgetState extends State<CardTagEditorWidget>` (made public) with
  - `bool commitPending()` — adds the typed name as Done would, without moving focus; returns `false` only when the name is refused (the field then shows why);
  - `void clearInput()` — empties the field and its error, closes it.

- [ ] **Step 1: Write the failing tests**

Create `card_tag_input_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// Screens 08/09's tag input: Add beside the field, and Save adds what is
// typed there (critique 2026-09-30 part 3d-2, E8).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _button(String label) => find.widgetWithText(MxButton, label);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

Future<List<String>> _tagsOf(LibraryEnv env, String front) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT t.name AS name FROM card_tags ct '
            'JOIN tags t ON t.id = ct.tag_id '
            'JOIN card c ON c.id = ct.card_id WHERE c.front = ? '
            'ORDER BY t.name',
            variables: [Variable<String>(front)],
          )
          .get())
    row.read<String>('name'),
];

Future<void> _openTag(WidgetTester tester, String name) async {
  await tester.tap(find.text(_en.cardAddTag));
  await tester.pump();
  await tester.enterText(_field(2), name);
  await tester.pump();
}

void main() {
  libraryTest('Add adds the typed tag and keeps the field open', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await _openTag(tester, 'food');
    expect(tester.widget<MxButton>(_button(_en.cardTagConfirm)).onPressed,
        isNotNull);

    await tester.tap(_button(_en.cardTagConfirm));
    await tester.pump();

    expect(find.text('food'), findsOneWidget);
    expect(tester.widget<EditableText>(_field(2)).controller.text, isEmpty);
    expect(tester.widget<MxButton>(_button(_en.cardTagConfirm)).onPressed,
        isNull);
  });

  libraryTest('edit: Save keeps the tag still in the field', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'food');

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
  });

  libraryTest('an invalid tag in the field stops Save and says why', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'x' * 51);

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardRejection(CardRejection.invalidTagName)),
        findsOneWidget);
    expect(await _tagsOf(env, 'bap'), isEmpty);
    expect(find.byType(CardEditorScreen), findsOneWidget);
  });

  libraryTest('a name already on the card, typed again, saves once '
      '(Review Focus 1)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'FOOD');

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
  });

  libraryTest('create: Save adds the pending tag, and the next card starts '
      'with none and an empty field (Review Focus 2)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await _openTag(tester, 'food');

    await tester.tap(_button(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
    expect(find.text('food'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(EditableText),
        matching: find.text('food'),
      ),
      findsNothing,
    );
  });
}
```

(Tables per `lib/core/database/tables/tags.drift`: `tags(id, name, …)`, `card_tags(card_id, tag_id)`.)

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/card/presentation/card_tag_input_test.dart`
Expected: FAIL — no "Add" button; Save drops the pending tag; no error on an invalid one.

- [ ] **Step 3: Implement the editor**

In `card_tag_editor_widget.dart`:

- Rename `_CardTagEditorWidgetState` to `CardTagEditorWidgetState` (and `createState`).
- `_reportPending` rebuilds, so Add follows the text:

```dart
  void _reportPending() {
    final isPending = _input.text.trim().isNotEmpty;
    if (isPending == _isPending) return;
    setState(() => _isPending = isPending);
    widget.onPendingChanged?.call(isPending);
  }
```

- `_add` returns whether it stood, and moves focus only when asked:

```dart
  /// Adds [name] as typed; false only when the tag rule refuses it, the
  /// field then saying why.
  bool _add(String name, {bool keepsFocus = true}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isAdding = false;
        _error = null;
      });
      return true;
    }
    final folded = TagEntity.fold(trimmed);
    if (widget.tags.any((tag) => TagEntity.fold(tag) == folded)) {
      _input.clear();
      if (keepsFocus) _focus.requestFocus();
      return true;
    }
    final next = [...widget.tags, trimmed];
    if (CardDraft.checkTagNames(next) case Rejected(:final reason)) {
      setState(() => _error = context.l10n.cardRejection(reason));
      return false;
    }
    setState(() => _error = null);
    _input.clear();
    widget.onChanged(next);
    if (keepsFocus) _focus.requestFocus();
    return true;
  }

  /// Save adds what is typed, as Done would (critique 2026-09-30 part 3d-2,
  /// E8). False when the name is refused: the caller saves nothing.
  bool commitPending() =>
      _input.text.trim().isEmpty || _add(_input.text, keepsFocus: false);

  /// The next card's form starts with an empty, closed input.
  void clearInput() {
    _input.clear();
    setState(() {
      _isAdding = false;
      _error = null;
    });
  }
```

- `onSubmitted: _add` becomes `onSubmitted: (name) => _add(name)`.
- The field gets Add in its trailing slot:

```dart
          if (_isAdding && !isFull)
            MxTextField(
              controller: _input,
              focusNode: _focus,
              label: l10n.cardTagHint,
              hintText: l10n.cardTagHint,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (name) => _add(name),
              // Done is not the only way to add (critique 2026-09-30 part
              // 3d-2, E8).
              trailing: MxButton(
                label: l10n.cardTagConfirm,
                size: MxButtonSize.compact,
                tone: MxButtonTone.text,
                onPressed: _isPending ? () => _add(_input.text) : null,
              ),
            ),
```

- Update the class dartdoc: "Done or Add adds the tag …".

- [ ] **Step 4: Implement the form**

In `card_editor_form_widget.dart`:

```dart
  final _tagEditor = GlobalKey<CardTagEditorWidgetState>();
```

`_save` starts:

```dart
  Future<void> _save() async {
    if (_isSaving) return;
    // The tag still in its field is part of the card (critique 2026-09-30
    // part 3d-2, E8); a refused one stops the save, saying why.
    if (!(_tagEditor.currentState?.commitPending() ?? true)) return;
    final draft = _draft();
```

`_clearForNext` adds, before `setState`:

```dart
    _tagEditor.currentState?.clearInput();
```

The editor call passes the key:

```dart
    CardTagEditorWidget(
      key: _tagEditor,
      tags: _tags,
```

`commitPending` calls `onChanged` synchronously, whose `setState(() => _tags = tags)` assigns before `_draft()` reads `_tags`.

- [ ] **Step 5: Run the card feature**

Run: `flutter test test/features/card`
Expected: PASS. A pre-existing test that pressed Save with pending text and expected it dropped would now fail: update it to the new rule and ledger it.

- [ ] **Step 6: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "feat(card): Add beside the tag field; Save adds the tag still typed (critique 3d-2, E8)"
```

---

### Task 6: Card detail history and Algorithm (10, E9)

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_history_event_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_schedule_widget.dart`
- Test: `test/features/card/presentation/card_history_scroll_test.dart:146-166, 317-355`, `test/features/card/presentation/card_detail_blocks_test.dart`

- [ ] **Step 1: Write the failing tests**

In `'each answer shows the values its row stored (BR-CARD-016)'`, replace the block from `// The mode carries the Study glyph` to `expect(find.byIcon(AppIcons.library), findsNothing);` with:

```dart
    // The badge is the event's one glyph; the metadata is text (critique
    // 2026-09-30 part 3d-2, E9).
    for (final glyph in [AppIcons.study, AppIcons.progress, AppIcons.calendar,
        AppIcons.hint, AppIcons.timeout]) {
      expect(
        find.descendant(
          of: find.byType(CardHistoryEventWidget),
          matching: find.byIcon(glyph),
        ),
        findsNothing,
        reason: '$glyph',
      );
    }
```

In `'a lapse is warning, relearning neutral, any other answer success …'`, after the tone `expect`, add:

```dart
      final badge = tester.widget<MxBadge>(find.byType(MxBadge));
      // The badge names the outcome it is toned by; the kind is text
      // beside it (critique 2026-09-30 part 3d-2, E9).
      expect(badge.label, _en.cardHistoryAction(action), reason: '$action');
      expect(find.text(_en.cardHistoryKind(kind)), findsOneWidget);
```

(`cardHistoryAction` and `cardHistoryKind` are extension methods in `card_history_labels_widget.dart`; import it if the test does not already.)

In `card_detail_blocks_test.dart`, add:

```dart
  libraryTest('Algorithm takes a row of its own, the card\'s full width '
      '(critique 2026-09-30 part 3d-2, E9)', (tester, env) async {
    final deckId = await _words(env);
    await insertCard(
      env.db,
      id: 'c',
      deckId: deckId,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 28),
      box: 3,
    );
    await pumpLibraryScreen(
      tester,
      env,
      _host('c', (detail) => [CardScheduleWidget(detail: detail)]),
    );
    await tester.pumpAndSettle();

    final label = find.text(_en.cardFactScheduler);
    final due = find.text(_en.cardFactDue);
    // Below the paired facts, and starting where the left column starts.
    expect(tester.getTopLeft(label).dy, greaterThan(tester.getTopLeft(due).dy));
    expect(tester.getTopLeft(label).dx, tester.getTopLeft(due).dx);
    final value = find.textContaining(_en.cardSchedulerEightBox);
    expect(
      tester.getSize(value).width,
      greaterThan(tester.getSize(find.byType(CardScheduleWidget)).width / 2),
    );
  });
```

If the value text is shorter than half the card even when spanning, assert instead that the `Expanded` holding it is the only child of its `Row`: find the `Row` ancestor of `label` and check it has one `Expanded` child; ledger the swap.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/card/presentation/card_history_scroll_test.dart test/features/card/presentation/card_detail_blocks_test.dart`
Expected: FAIL — meta glyphs found; the badge reads the kind; Algorithm sits in a half-width column.

- [ ] **Step 3: Implement the history event**

In `card_history_event_widget.dart`, the badge and the text swap:

```dart
                // The badge is the outcome its tone states; the kind is text
                // (critique 2026-09-30 part 3d-2, E9).
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.control,
                  runSpacing: AppSpacing.micro,
                  children: [
                    MxBadge(
                      label: l10n.cardHistoryAction(action),
                      tone: tone,
                      icon: icon,
                    ),
                    Text(
                      l10n.cardHistoryKind(entry.kind),
                      style: context.textStyles.rowTitle,
                    ),
                  ],
                ),
```

`_meta` returns `List<String>` (drop each tuple's icon), the `Wrap` renders `for (final text in _meta(l10n, locale)) Text(text, style: context.textStyles.rowDescription)`, and the `_Meta` class and now-unused imports (`app_icon_size.dart`) go. Keep the comment above the `Wrap` accurate: the badge holds a short outcome.

- [ ] **Step 4: Implement the Algorithm row**

In `card_schedule_widget.dart`, take the scheduler `_Fact` out of `_facts` into its own getter and place it after the paired loop:

```dart
            for (var i = 0; i < facts.length; i += 2)
              Row(
                // … unchanged …
              ),
            // Its value is the longest; a row of its own keeps it on one
            // line (critique 2026-09-30 part 3d-2, E9).
            _schedulerFact(context),
```

```dart
  Widget _schedulerFact(BuildContext context) {
    final l10n = context.l10n;
    return _Fact(
      icon: AppIcons.scheduler,
      label: l10n.cardFactScheduler,
      value: l10n.cardFactSchedulerValue(
        l10n.cardScheduler(detail.schedulerType),
        detail.schedule.generation,
      ),
    );
  }
```

- [ ] **Step 5: Run the card feature**

Run: `flutter test test/features/card`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "feat(card): history badge names its outcome, text-only metadata, Algorithm on its own row (critique 3d-2, E9)"
```

---

### Task 7: Import layout (11, E10)

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart:69-95`
- Modify: `lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart:176-189`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`importPickBody`)
- Create: `test/features/transfer/presentation/card_import_layout_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `card_import_layout_test.dart`, copying `_file`, `_context`, `_pump` and `_tap` from `card_import_screen_test.dart` (same imports), then:

```dart
void main() {
  libraryTest('the duplicates toggle comes before the rows (critique '
      '2026-09-30 part 3d-2, E10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await insertCard(env.db, id: 'x', deckId: deck.id, front: 'mul', back: 'water');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back\nmul,water\nbul,fire\n'),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);

    expect(
      tester.getTopLeft(find.text(_en.importIncludeDuplicates)).dy,
      lessThan(tester.getTopLeft(find.byType(ImportPreviewRowWidget).first).dy),
    );
  });

  libraryTest('the source step draws one surface and names the formats once '
      '(critique 2026-09-30 part 3d-2, E10)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id);

    expect(
      find.ancestor(
        of: find.byType(MxEmptyState),
        matching: find.byType(MxCard),
      ),
      findsNothing,
    );
    expect(find.text(_en.importPickBody), findsOneWidget);
    expect(_en.importPickBody, isNot(contains('csv')));
  });
}
```

(imports: `import_preview_row_widget.dart` from `lib/features/transfer/presentation/widgets/items/`, `mx_empty_state.dart`, `mx_card.dart`.)

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/transfer/presentation/card_import_layout_test.dart`
Expected: FAIL — the toggle is below the rows; an `MxCard` wraps the empty state; the body names the formats.

- [ ] **Step 3: Implement**

`import_preview_section_widget.dart` — move the `if (preview.duplicates > 0) MxSection(…)` block (unchanged) to sit right after `const SizedBox(height: AppSpacing.grouped),` and before the rows' `MxSection`, with a comment `// Before the rows it governs (critique 2026-09-30 part 3d-2, E10).`

`import_source_section_widget.dart` — unwrap:

```dart
    if (draft.source == null) {
      return [
        // MxEmptyState draws its own surface (critique 2026-09-30 part 3d-2,
        // E10).
        MxEmptyState(
          icon: AppIcons.fileUp,
          title: l10n.importPickTitle,
          body: l10n.importPickBody,
          isCompact: true,
          actionLabel: l10n.importPickAction,
          onAction: widget.onChooseFile,
        ),
        ..._helper(l10n),
      ];
    }
```

Drop the `mx_card.dart` import if unused. ARB: en `"importPickBody": "Nothing is added until you confirm."`, vi `"importPickBody": "Chưa thêm gì cho tới khi bạn xác nhận."`; update the en description if it mentions the formats. Run `flutter gen-l10n`.

- [ ] **Step 4: Run the feature**

Run: `flutter test test/features/transfer`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer lib/l10n test/features/transfer
git commit -m "feat(import): duplicates toggle before the rows; one surface and one format line at the source (critique 3d-2, E10)"
```

---

### Task 8: Export stale copy (12)

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`exportStaleBody`)
- Test: `test/features/transfer/presentation/card_export_sheet_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
  test('the stale copy asks for what the sheet offers: Close (critique '
      '2026-09-30 part 3d-2)', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    expect(
      _en.exportStaleBody,
      'It was moved to another deck or sent to Trash meanwhile. Nothing was '
      'exported. Close this sheet, check your selection and export again.',
    );
    expect(
      vi.exportStaleBody,
      'Thẻ đó vừa được chuyển sang bộ thẻ khác hoặc vào Thùng rác. Chưa xuất '
      'gì. Hãy đóng bảng này, xem lại các thẻ đã chọn rồi xuất lần nữa.',
    );
  });
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/transfer/presentation/card_export_sheet_test.dart --plain-name "stale copy"`
Expected: FAIL — "Refresh the selection".

- [ ] **Step 3: Implement**

Set both ARB values verbatim (Global Constraints). Run `flutter gen-l10n`.

- [ ] **Step 4: Run the feature**

Run: `flutter test test/features/transfer`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n test/features/transfer
git commit -m "fix(export): stale copy asks for Close, which the sheet offers (critique 3d-2)"
```

---

### Task 9: Two-digit reminder time and warning ink (24, E14)

**Files:**
- Modify: `lib/shared/widgets/mx_stepper.dart` (constructor, field, the three `value.toString()` uses at ~102, ~194, ~205)
- Modify: `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart` (both steppers)
- Modify: `lib/shared/widgets/mx_empty_state.dart:103-107`
- Test: `test/shared/widgets/mx_stepper_test.dart`, `test/shared/widgets/mx_empty_state_test.dart`, `test/features/reminders/presentation/reminder_screen_test.dart:346-362`

**Interfaces:** Produces `MxStepper({…, int minDigits = 1})`.

- [ ] **Step 1: Write the failing tests**

`mx_stepper_test.dart` (extend `_stepper` with `int minDigits = 1` passed through):

```dart
  testWidgets('minDigits pads the value, its edit seed and its semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _stepper(value: 5, minDigits: 2));
    expect(find.text('05'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(_valueKey)),
      matchesSemantics(value: '05', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('by default a value keeps its digits', (tester) async {
    await pumpMx(tester, _stepper(value: 5));
    expect(find.text('5'), findsOneWidget);
  });
```

If `_valueKey` is not on the semantics node, read the value with `find.bySemanticsLabel` the way the file's existing semantics test does; ledger the swap. If the existing `_stepper` gives no `onValueSubmitted`, the node is not a button: drop `isButton`/`hasTapAction` from the matcher.

`mx_empty_state_test.dart` (exists; `pumpMx` takes `brightness`):

```dart
  testWidgets('the warning glyph reads in warning ink, light and dark '
      '(critique 2026-09-30 part 3d-2, E14)', (tester) async {
    for (final brightness in Brightness.values) {
      await pumpMx(
        tester,
        const MxEmptyState(
          icon: AppIcons.library,
          tone: MxEmptyStateTone.warning,
          title: 'This deck no longer accepts cards',
        ),
        brightness: brightness,
      );
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.library));
      expect(
        icon.color,
        tester.element(find.byIcon(AppIcons.library)).derivedColors.warningInk,
      );
    }
  });
```

`reminder_screen_test.dart` — in `'a typed minute outside 0–59 disables Save'`, the minute now reads "00": change `find.text('0').last` to `find.text('00').last`. Add:

```dart
  libraryTest('the hour and minute read in two digits; a typed 7 reads 07 '
      '(critique 2026-09-30 part 3d-2, Review Focus 5)', (tester, env) async {
    await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);
    await tester.tap(find.text('20:00'));
    await settleReminderScreen(tester);

    expect(find.text('20'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    await tester.tap(find.text('00'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('07'), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.reminderTimeSave));
    await settleReminderScreen(tester);
    expect(find.text('20:07'), findsOneWidget);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/shared/widgets/mx_stepper_test.dart test/shared/widgets/mx_empty_state_test.dart test/features/reminders/presentation/reminder_screen_test.dart`
Expected: FAIL — no `minDigits`; the warning glyph is amber; the minute reads "0".

- [ ] **Step 3: Implement**

`mx_stepper.dart`:

```dart
    this.minDigits = 1,
```

```dart
  /// The value shows at least this many digits, zero-padded: a clock's
  /// minute reads "05" (critique 2026-09-30 part 3d-2, E14).
  final int minDigits;
```

and in the state:

```dart
  String get _text => widget.value.toString().padLeft(widget.minDigits, '0');
```

used at the edit seed (`final text = _text;`), the display (`_ => Text(_text, style: style)`) and the semantics (`value: _text`).

Reminder dialog: both `MxStepper(...)` calls get `minDigits: 2,`.

`mx_empty_state.dart`:

```dart
                ink: switch (tone) {
                  MxEmptyStateTone.primary => context.derivedColors.primaryInk,
                  MxEmptyStateTone.success => context.derivedColors.successInk,
                  // As the caution tile and the warning banner (critique
                  // 2026-09-30 part 3d-2, E14).
                  MxEmptyStateTone.warning => context.derivedColors.warningInk,
                  _ => toneColor,
                },
```

Update the `_Tile.ink` dartdoc to name warningInk.

- [ ] **Step 4: Run the shared widgets and reminders**

Run: `flutter test test/shared test/features/reminders test/features/settings`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared lib/features/reminders test/shared test/features/reminders
git commit -m "feat(shared): MxStepper minDigits for a two-digit reminder time; warning ink in MxEmptyState (critique 3d-2, E14)"
```

---

### Task 10: Monitoring header and stack trace (28, E11)

**Files:**
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart:87, 145-170`
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart:81-102`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (remove `monitoringCountOpen`, `monitoringCountOpenMore` and their `@` blocks)
- Test: `test/features/monitoring/presentation/monitoring_screen_test.dart:47`, `test/features/monitoring/presentation/monitoring_detail_screen_test.dart:142-172`

- [ ] **Step 1: Write the failing tests**

`monitoring_screen_test.dart:47`: `expect(find.text('2 OPEN'), findsOneWidget);` becomes:

```dart
    // The chip names the filter; the header counts logs (critique
    // 2026-09-30 part 3d-2, E11).
    expect(find.text(_en.monitoringCountLogs(2).toUpperCase()), findsOneWidget);
```

(add `_en` if the file has none: `final _en = lookupAppLocalizations(const Locale('en'));`.)

Replace `'a stack trace marks where each frame starts'` with:

```dart
  libraryTest('a stack trace marks each frame and hangs its wrapped lines '
      '(Impeccable 2026-09-29 F6; critique 2026-09-30 part 3d-2, E11)', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        stackTrace:
            '#0      a (a.dart:1)\n<asynchronous suspension>\n#1      b',
      );

    await _pump(tester, env, repository);

    final zero = find.text('#0');
    final first = find.text('a (a.dart:1)');
    final suspension = find.text('<asynchronous suspension>');
    final base = tester.widget<Text>(first).style?.color;
    expect(tester.widget<Text>(zero).style?.color, isNot(base));
    expect(
      tester.widget<Text>(find.text('#1')).style?.color,
      tester.widget<Text>(zero).style?.color,
    );
    // The frame's text and any line under it start past the #n cell.
    expect(tester.getTopLeft(first).dx, greaterThan(tester.getTopLeft(zero).dx));
    expect(tester.getTopLeft(suspension).dx, tester.getTopLeft(first).dx);
    expect(find.byType(SelectionArea), findsWidgets);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/presentation/monitoring_screen_test.dart test/features/monitoring/presentation/monitoring_detail_screen_test.dart`
Expected: FAIL — "2 OPEN"; the trace is one `SelectableText`.

- [ ] **Step 3: Implement the header**

In `monitoring_server_list_widget.dart`, the header no longer depends on the filter:

```dart
    // The chip names the filter (critique 2026-09-30 part 3d-2, E11).
    final header = hasMore
        ? l10n.monitoringCountLogsMore(count)
        : l10n.monitoringCountLogs(count);
```

Remove the now-unused `isDefaultFilter` field, constructor parameter and the argument at line 87. Remove the two keys from both ARBs; run `flutter gen-l10n`. Update the doc comment above the header if it mentions "open".

- [ ] **Step 4: Implement the trace**

In `monitoring_code_card_widget.dart`:

```dart
      // One frame per row: the #n in a fixed cell, so a wrapped line hangs
      // under the frame's text (critique 2026-09-30 part 3d-2, E11). Still
      // selectable, across frames.
      _CardKind.stackTrace => SelectionArea(
        child: _StackTrace(
          text: text,
          style: styles.code,
          frameStyle: styles.code.copyWith(
            color: context.derivedColors.primaryInk,
          ),
        ),
      ),
```

```dart
class _StackTrace extends StatelessWidget {
  const _StackTrace({
    required this.text,
    required this.style,
    required this.frameStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle frameStyle;

  static final RegExp _frame = RegExp(r'^#\d+');

  /// The cell holds "#99" and a space, in the code face at the text scale.
  static const String _cellSample = '#99 ';

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: _cellSample, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final cell = painter.width;
    painter.dispose();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in text.split('\n'))
          if (_frame.matchAsPrefix(line) case final match?)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: cell,
                  child: Text(match[0]!, style: frameStyle),
                ),
                Expanded(
                  child: Text(line.substring(match.end).trimLeft(), style: style),
                ),
              ],
            )
          else
            Padding(
              padding: EdgeInsetsDirectional.only(start: cell),
              child: Text(line.trimLeft(), style: style),
            ),
      ],
    );
  }
}
```

Remove the old `_trace` method and the class-level `_frame` if nothing else uses it. Update the `.stackTrace` constructor's dartdoc ("each frame's `#n` in the primary ink, in a cell its wrapped lines hang under").

- [ ] **Step 5: Run the feature**

Run: `flutter test test/features/monitoring test/app/l10n_test.dart`
Expected: PASS. A test that relied on `monitoringCountOpen` or on the trace being a `SelectableText` fails here: update it and ledger it.

- [ ] **Step 6: Commit**

```bash
git add lib/features/monitoring lib/l10n test/features/monitoring
git commit -m "feat(monitoring): header counts logs; stack-trace frames hang-indent (critique 3d-2, E11)"
```

---

### Task 11: Progress and Settings skeletons (22, 23, E12)

**Files:**
- Create: `lib/features/progress/presentation/widgets/sections/progress_skeleton_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart`
- Modify: `lib/features/progress/presentation/screens/progress_screen.dart:55`, `lib/features/progress/presentation/screens/deck_progress_screen.dart:83`, `lib/features/settings/presentation/screens/settings_screen.dart:67, 140-143`
- Test: `test/features/progress/presentation/progress_screen_test.dart:~330-342`, `test/features/settings/presentation/settings_screen_test.dart:~175-188`

**Interfaces:**
- Produces: `ProgressSkeletonWidget({Key? key, required String semanticLabel, bool hasSummary = true})`; `SettingsSkeletonWidget({Key? key, required String semanticLabel})`.

- [ ] **Step 1: Write the failing tests**

In the Progress loading test (the one with `find.bySemanticsLabel(_en.progressLoading)`), add:

```dart
    // Shaped like the screen: Today, Streak, then the deck list (critique
    // 2026-09-30 part 3d-2, E12).
    expect(find.byType(ProgressSkeletonWidget), findsOneWidget);
    expect(find.byType(MxSkeletonList), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ProgressSkeletonWidget),
        matching: find.byType(MxCard),
      ),
      findsNWidgets(3),
    );
```

In the Settings loading test, replace `expect(find.byType(MxSkeletonList), findsOneWidget);` with:

```dart
    expect(find.byType(SettingsSkeletonWidget), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SettingsSkeletonWidget),
        matching: find.byType(MxCard),
      ),
      findsNWidgets(3),
    );
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/progress/presentation/progress_screen_test.dart test/features/settings/presentation/settings_screen_test.dart`
Expected: FAIL to compile (`ProgressSkeletonWidget`, `SettingsSkeletonWidget` undefined).

- [ ] **Step 3: Implement**

`progress_skeleton_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 22 loading in its own shape: the Today card, the Streak card and
/// the deck list, on one pulse (critique 2026-09-30 part 3d-2, E12). A
/// deck's level has no summary cards.
class ProgressSkeletonWidget extends StatelessWidget {
  const ProgressSkeletonWidget({
    super.key,
    required this.semanticLabel,
    this.hasSummary = true,
  });

  final String semanticLabel;
  final bool hasSummary;

  static const int _deckRows = 3;
  static const double _eyebrowWidth = 72;
  static const double _figureHeight = 28;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            if (hasSummary)
              for (var i = 0; i < 2; i++)
                const MxCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.grouped,
                    children: [
                      MxSkeleton(width: _eyebrowWidth),
                      MxSkeleton(height: _figureHeight),
                    ],
                  ),
                ),
            MxCard(
              child: Column(
                children: [
                  for (var i = 0; i < _deckRows; i++) const MxSkeletonRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

`settings_skeleton_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 23 loading as its sections: three cards of rows, on one pulse
/// (critique 2026-09-30 part 3d-2, E12).
class SettingsSkeletonWidget extends StatelessWidget {
  const SettingsSkeletonWidget({super.key, required this.semanticLabel});

  final String semanticLabel;

  static const List<int> _rowsPerSection = [2, 3, 2];
  static const double _headerWidth = 96;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final rows in _rowsPerSection) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.control),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MxSkeleton(width: _headerWidth),
                ),
              ),
              MxCard(
                child: Column(
                  children: [for (var i = 0; i < rows; i++) const MxSkeletonRow()],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
```

Screens:
- `progress_screen.dart:55`: `_ => [ProgressSkeletonWidget(semanticLabel: l10n.progressLoading)],`
- `deck_progress_screen.dart:83`: `ProgressSkeletonWidget(semanticLabel: l10n.progressLoading, hasSummary: false),`
- `settings_screen.dart:140-143`: `SettingsSkeletonWidget(semanticLabel: l10n.commonLoading),`; remove `_skeletonRows` if now unused.

If `MxCard` pads rows differently from the loaded list cards, match the loaded card (read `progress_by_deck` / `MxSection` padding) rather than invent values; ledger it.

- [ ] **Step 4: Run the features**

Run: `flutter test test/features/progress test/features/settings`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress lib/features/settings test/features/progress test/features/settings
git commit -m "feat(progress,settings): loading skeletons in each screen's shape (critique 3d-2, E12)"
```

---

### Task 12: The 3d-1 minors — 07 Retry, 15 banner, 27 row (E13)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (`_writeFlag`, the banner, the bulk bar)
- Modify: `lib/features/settings/presentation/states/study_options_state.dart` (`edited`)
- Modify: `lib/features/settings/presentation/screens/sync_screen.dart:158`
- Create: `test/features/card/presentation/card_list_flag_retry_test.dart`
- Test: `test/features/settings/presentation/study_options_controller_test.dart`, `test/features/settings/presentation/study_options_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

`card_list_flag_retry_test.dart` — copy `_section` and `_seed` from `card_list_layout_test.dart` (same imports), plus:

```dart
/// Fails the first write; holds the next until [release].
final class _HeldFlags implements CardRepository {
  final calls = <(Set<String>, bool)>[];
  Completer<void>? held;

  void release() => held?.complete();

  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) async {
    calls.add((cardIds, isFlagged));
    if (calls.length == 1) {
      throw const UnknownDatabaseFailure(cause: 'locked');
    }
    await (held = Completer<void>()).future;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('while Retry runs the banner stays with a spinning Retry, and '
      'neither Retry nor the bulk bar takes a tap (critique 2026-09-30 part '
      '3d-2; Review Focus 3)', (tester, env) async {
    final flags = _HeldFlags();
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(deckId),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(flags),
        ),
      ],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlag));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlagSet));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pump();

    expect(find.text(_en.cardBulkFailedTitle), findsOneWidget);
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, _en.commonRetry))
          .isLoading,
      isTrue,
    );
    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.tap(find.text(_en.cardFlag), warnIfMissed: false);
    await tester.pump();
    expect(flags.calls, hasLength(2));
    expect(find.text(_en.cardFlagSet), findsNothing);

    flags.release();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardBulkFailedTitle), findsNothing);
    expect(find.text(_en.cardFlaggedToast(1)), findsOneWidget);
  });
}
```

(`dart:async` for `Completer`; the bulk command's label is `_en.cardFlag` as in `failOneFlag`.)

`study_options_controller_test.dart` — in `'a failed save keeps the draft, and Retry save writes it (E4)'`, after `expect((await _stored(rig)).source, StudyOptionsSource.appDefaults);` add:

```dart
    // An edit keeps the failure in view until a save lands (critique
    // 2026-09-30 part 3d-2, E13).
    _controller(rig).stepCardLimit(1);
    expect(_state(rig).save, StudyOptionsSave.failed);
    expect(_state(rig).cardLimit, 22);
```

and change the later `expect((await _stored(rig)).options.cardLimit, 21);` to `22`.

`study_options_screen_test.dart` — at the end of `'a failed save shows a danger banner at the top; …'` add:

```dart
    // An edit keeps it; a save that lands clears it (critique 2026-09-30
    // part 3d-2, E13; Review Focus 4).
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    expect(banner, findsOneWidget);
    expect(find.text(_en.cardRetrySave), findsOneWidget);

    store.isFailing = false;
    await tester.tap(find.text(_en.cardRetrySave));
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    expect(find.text(_en.cardRetrySave), findsNothing);
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/card/presentation/card_list_flag_retry_test.dart test/features/settings/presentation/study_options_controller_test.dart test/features/settings/presentation/study_options_screen_test.dart`
Expected: FAIL — the banner vanishes on Retry; an edit resets `save` to idle.

- [ ] **Step 3: Implement 07**

In `card_list_section_widget.dart`:

```dart
  /// A flag write is running: Retry spins and the bulk bar holds still
  /// (critique 2026-09-30 part 3d-2).
  var _isFlagging = false;
```

`_writeFlag`:

```dart
  Future<void> _writeFlag(Set<String> cardIds, bool isFlagged) async {
    if (_isFlagging) return;
    setState(() => _isFlagging = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .setFlagged(cardIds: cardIds, isFlagged: isFlagged);
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() => _failedFlag = null);
      switch (outcome) {
        // … the Ok and Rejected arms, unchanged …
      }
    } on Failure {
      if (!mounted) return;
      setState(() => _failedFlag = (cardIds, isFlagged));
    } finally {
      if (mounted) setState(() => _isFlagging = false);
    }
  }
```

The Retry button: `isLoading: _isFlagging,` and `onPressed: _isFlagging ? null : () => unawaited(_writeFlag(ids, isFlagged)),`. The bulk bar:

```dart
          if (isSelecting)
            IgnorePointer(
              ignoring: _isFlagging,
              child: CardBulkBarWidget(actions: _bulkActions(selected)),
            ),
```

Update `_writeFlag`'s dartdoc: "Retry repeats it, the banner staying while it runs".

- [ ] **Step 4: Implement 15 and 27**

`study_options_state.dart`, `edited` keeps a failure:

```dart
  /// The draft after an edit. A failed save stays in view until a save
  /// lands: the banner states the deck's stored values, still true while
  /// the person edits (critique 2026-09-30 part 3d-2, E13).
  StudyOptionsState edited({
    …
  }) => StudyOptionsState(
    …,
    save: save == StudyOptionsSave.failed
        ? StudyOptionsSave.failed
        : StudyOptionsSave.idle,
    timesSaved: timesSaved,
  );
```

`sync_screen.dart:158`: `height: AppSize.buttonRegular,` with the comment `// The button it stands in for (critique 2026-09-30 part 3d-2).` No test can tell it apart today (both are 48); the existing Syncing tests cover the row.

- [ ] **Step 5: Run the features**

Run: `flutter test test/features/card test/features/settings`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/card lib/features/settings test/features/card test/features/settings
git commit -m "fix(card,settings): Retry spins and holds the bulk bar; a failed save survives edits; syncing row on the button token (critique 3d-2)"
```

---

### Task 13: Records

**Files:**
- Modify: `DESIGN.md` (the `MxStepper` and `MxEmptyState` entries, lines ~339 and ~345)
- Modify: detail files `docs/shared/ui/screen-handoff/{01,02,03,05,07,08,09,10,11,12,14,15,22,23,24,27,28}-*.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (rows 152–160)
- Modify: `docs/wbs_FE.md` (row FE-D16)
- Regenerate: `docs/_generated` with `python3 tools/docs/generate.py`

- [ ] **Step 1: DESIGN.md**

- `**MxStepper** (bounded integer, press-and-hold repeat)` → `**MxStepper** (bounded integer, press-and-hold repeat; `minDigits` zero-pads the value, as the reminder's "07" : "05", critique 2026-09-30 part 3d-2)`.
- In the `**MxEmptyState**` entry, after "success tints with success and draws its glyph in success ink, critique 2026-09-30 tone pass" add "; warning draws its glyph in warning ink (part 3d-2)".

- [ ] **Step 2: Detail files**

Each file gets one line in its rulings/notes list, in the form the 3d-1 lines use (`- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** …`), and any row the change makes stale is corrected:
- 01: "Date added" names the recent sort (hint "Newest first"; the doc's sort line already says "Date added"); the search field is hidden while reordering.
- 02: the unlocked strip is a plain card (row at line ~13 "Unlocked: hero ground" becomes "Unlocked: plain card, open lock on primary"); the reset confirm is warning (row ~51).
- 03: the sheet's body is the lock line `deckSchedulerNote`; fix the copy row that quotes `starterSheetBody` (~20-21).
- 05: the true-empty state shows only the empty state; the delete note is a neutral `MxNote` (row ~25 "MxCard (success)" becomes "MxNote").
- 07: Retry spins while it runs and the bulk bar holds still.
- 08 and 09: "Add" beside the tag field; Save adds the tag still typed, or stops with its error.
- 10: the history badge names the outcome, the kind is text, the metadata has no glyphs (amend the §9-row-90 line ~43 and the T5 line ~49); "Algorithm" on its own row.
- 11: "Include duplicates" sits before the rows; the source step's empty state has no wrapping card and its body is "Nothing is added until you confirm."
- 12: the stale copy now reads "… Close this sheet, check your selection and export again."
- 14: the hero is a plain card.
- 15: a failed save's banner stays through edits until a save lands.
- 22 and 23: loading shows the screen's own skeleton (replace "Skeleton rows (UI-base row 125)" / "loading is MxSkeletonList").
- 24: hour and minute read in two digits.
- 27: the syncing row is the button's height token.
- 28: the list header counts logs with any filter (row ~35 and copy line ~100); the stack trace hangs wrapped lines under each frame.

- [ ] **Step 3: UI-base register**

Append rows 152–160 to §9, one per lower finding of E1, source "critique 2026-09-30, deferred by part 3d-2 (E1)":
152 06 a trash row states two time forms (deleted ago and time left);
153 09 optional fields always open in edit (documented as intended);
154 10 the section header and the cycle header share one style;
155 14 the session limit is reached only through the unlabeled options icon;
156 15 read-only app defaults offer no way to Settings;
157 22 the streak card nests a tile; the deck name shows twice on deck progress (global P2-L4);
158 24 the denied banner says "turn the reminder on again" beside "Try again";
159 27 the status values sit in the small subtitle line;
160 05 the merge dialog is dense; the actions sheet's header differs from other sheets.

- [ ] **Step 4: WBS and generated docs**

Add under FE-D15 in `docs/wbs_FE.md`:

```
| FE-D16 | Critique 2026-09-30 phần 3d-2: 01 nhãn "Ngày tạo" và ẩn tìm kiếm khi sắp xếp, 02 Reset warning và dải mở khoá là card thường, 03 câu khoá trong sheet starter, 05 empty state gọn và ghi chú xoá trung tính, 08/09 nút Add và Save thêm tag đang gõ, 10 badge theo kết quả và Algorithm một hàng, 11 nút gạt trùng lên trước, 12 câu báo lỗi, 14 hero thường, 24 giờ phút hai chữ số, 28 header và stack trace, skeleton Progress/Settings, MxEmptyState warning ink, các lỗi nhỏ 07/15/27 | đang làm | FE-D15 | S | [spec](superpowers/specs/2026-10-01-critique-fixes-part3d2-design.md) và [plan](superpowers/plans/2026-10-01-critique-fixes-part3d2.md) | — |
```

Run: `python3 tools/docs/generate.py`
Expected: exit 0; `git status` shows `docs/_generated/*` updated if any open question or index changed.

- [ ] **Step 5: Run the docs checks**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > .superpowers/sdd/2026-10-01-critique-fixes-part3d2/gate.log 2>&1; echo $?`
Expected: `0`. On failure read the tail of the log and fix (most likely: an ARB description, a stale doc link, a guard length).

- [ ] **Step 6: Commit**

```bash
git add DESIGN.md docs
git commit -m "docs: part 3d-2 rulings in DESIGN.md, detail files, the UI-base register and the WBS"
```

---

### Task 14: Goldens, gate and review

- [ ] **Step 1: Regenerate goldens (Linux container)**

Run: `TZ=UTC flutter test --tags golden --update-goldens > .superpowers/sdd/2026-10-01-critique-fixes-part3d2/goldens-update.log 2>&1; echo $?`
Expected: `0`. Then `git status --short test | grep goldens` lists the changed PNGs. Expected changes: deck algorithm (02), study entry (14), tags empty/delete (05), card editor with a tag field (08/09, if a golden shows the field open), card detail (10), import preview/source (11), reminder dialog (24), monitoring detail trace and list header (28), progress/settings loading if a golden captures them, import result (`MxEmptyState` warning). An unexpected file is a finding: read its diff before keeping it.

- [ ] **Step 2: Run goldens clean**

Run: `TZ=UTC flutter test --tags golden > .superpowers/sdd/2026-10-01-critique-fixes-part3d2/goldens.log 2>&1; echo $?`
Expected: `0`, every golden passing.

- [ ] **Step 3: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): regenerate for part 3d-2"
```

- [ ] **Step 4: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > .superpowers/sdd/2026-10-01-critique-fixes-part3d2/gate.log 2>&1; echo $?`
Expected: `0`.

- [ ] **Step 5: Final whole-branch review and golden review**

Per executing-plans: review package from the 3d-2 start commit, a fresh reviewer on the most capable model, one fix pass. Then build the `golden-compare` page (base = the commit before Task 1, head = HEAD) and give the owner the link before any approval.
