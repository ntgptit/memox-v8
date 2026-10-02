# Critique 2026-09-30 part 3d-1 (per-screen flows) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the eight per-screen flow findings of spec 3d-1: Learn offered once on 14, the card list's FAB and failed bulk flag on 07, Save on a pristine edit on 09, a visible failed save on 15, Progress rows on 22, Trash notices on 06, and sync status on 27 and 23.

**Architecture:** Each item is a local change in its feature's presentation layer; no new shared widget and no change to `lib/core` or `lib/shared`. Two predicates or state fields are added beside existing ones (`syncNeedsAttention` beside `syncIsSettled`; the card list's failed flag write kept as a record). New copy goes into both ARBs.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, ARB l10n (`flutter gen-l10n`), flutter_test with `libraryTest` / `pumpLibraryScreen`.

**Spec:** `docs/superpowers/specs/2026-10-01-critique-fixes-part3d1-design.md` (approved 2026-10-01, rulings D1–D5).

## Global Constraints

- No change to `lib/core` or `lib/shared` (owner, 2026-10-01: the syncing status is a local row on 27, not an `MxButton` API).
- BR-PROGRESS-001: a Progress row reports exactly the four numbers (unique active cards, active days, learning and reviewing card-days); nothing is added.
- BR-TRASH-011: the kind lock stays; only its note moves.
- New copy, verbatim:
  - `studyOptionsNotSavedTitle`: en "Not saved", vi "Chưa lưu";
  - `progressRowCardsDays`: en "{cards, plural, =1{1 card} other{{cards} cards}} · {days, plural, =1{1 active day} other{{days} active days}}", vi "{cards} thẻ · {days} ngày có học";
  - `progressRowCardDaysLead`: en "Card-days: ", vi "Lượt theo ngày: ";
  - `syncSyncing`: en "Syncing…", vi "Đang đồng bộ…".
- Goldens regenerate only in the Linux container with `TZ=UTC`.
- Every commit message ends with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01WHcLQhgp72txzYGsDLm7JX`.

## Review Focus

1. 14 with a review leading the footer and new cards present: the Learn row must keep its button, or learning becomes unreachable. Pinned in Task 1.
2. 07 a failed flag retried and failing again: the banner comes back and the selection stays. Pinned in Task 3.
3. 09 a pristine edit where only the flag toggles: that is a change, so Save enables. Pinned in Task 4.
4. 22 a sub-deck level (deck progress screen) whose rows also open levels: they get the chevron too, and a level's total row does not. Pinned in Task 6.
5. 27 a sync that fails while "Syncing…" shows: the button returns and the failure banner shows. Pinned in Task 8.

---

### Task 1: Study entry, Learn once (14, D2)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_learn_widget.dart`
- Test: `test/features/study/presentation/study_entry_actions_test.dart`

**Interfaces:** consumes `entryFooterActionOf(StudyEntryOffer)` and `EntryFooterAction` from `study_entry_offer_state.dart` (existing).

- [ ] **Step 1: Write the failing tests**

In `study_entry_actions_test.dart`, change the first test's seed to keep a review in the footer, so its row button still exists:

```dart
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 2);
```

and add:

```dart
  libraryTest('with only new cards Learn is offered once, in the footer '
      '(critique 2026-09-30 part 3d-1, D2)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    await pumpLibraryScreen(tester, env, _screen(leaf));

    expect(_button(_en.studyEntryLearn), findsNothing);
    expect(_button(_en.studyEntryLearnCta(2)), findsOneWidget);
  });

  libraryTest('with a review in the footer the Learn row keeps its button '
      '(D2; Review Focus 1)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 2);
    await pumpLibraryScreen(tester, env, _screen(leaf));

    expect(_button(_en.studyEntryLearn), findsOneWidget);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/study/presentation/study_entry_actions_test.dart --plain-name "D2"`
Expected: "Learn is offered once" FAILS (the row's Learn button is found); the other passes already and stays as a pin.

- [ ] **Step 3: Implement**

In `StudyEntryLearnWidget._trailing`, replace `if (!offer.canLearn) return null;` with:

```dart
    // With only new cards the footer offers Learn; the row does not offer
    // it again (critique 2026-09-30 part 3d-1, D2).
    if (!offer.canLearn ||
        entryFooterActionOf(offer) == EntryFooterAction.learn) {
      return null;
    }
```

and add to the class doc: `When the footer already offers Learn, the row has no button (critique 2026-09-30 part 3d-1, D2).`

- [ ] **Step 4: Run the study entry tests**

Run: `flutter test --exclude-tags golden test/features/study/presentation/study_entry_actions_test.dart test/features/study/presentation/study_entry_screen_test.dart`
Expected: PASS. A test that tapped the row's Learn on an only-new deck now finds nothing: seed it with `dueCards: 2` and ledger the edit.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study test/features/study
git commit -m "fix(study): Learn is offered once with only new cards (3d-1 D2)"
```

---

### Task 2: Card list, no FAB while searching (07)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_add_fab_widget.dart`
- Test: `test/features/card/presentation/card_list_layout_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
  libraryTest('the add FAB steps aside while search is open, so it covers '
      'no row (critique 2026-09-30 part 3d-1)', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(
          deckId: deckId,
          algorithm: 'Eight boxes',
          onAddCard: () {},
          onOpenCard: (_) {},
          onExport: (_) {},
        ),
        floatingActionButton: CardAddFabWidget(
          deckId: deckId,
          onAddCard: () {},
        ),
      ),
    );
    expect(find.byType(MxFab), findsOneWidget);

    await _openSearch(tester, deckId);
    expect(find.byType(MxFab), findsNothing);

    ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    ).read(cardSearchOpenProvider(deckId).notifier).close();
    await tester.pumpAndSettle();
    expect(find.byType(MxFab), findsOneWidget);
  });
```

Imports: `card_add_fab_widget.dart`, `package:memox/shared/widgets/mx_fab.dart`.

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/card/presentation/card_list_layout_test.dart --plain-name "steps aside"`
Expected: FAIL: the FAB is still found while search is open.

- [ ] **Step 3: Implement**

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selecting or searching, adding waits (critique 2026-09-30 part 3d-1):
    // the FAB would cover a row's badge under the keyboard.
    final isBusy =
        ref.watch(cardSelectionProvider(deckId)).isNotEmpty ||
        ref.watch(cardSearchOpenProvider(deckId));
    if (isBusy) return const SizedBox.shrink();
    return MxFab(
      icon: AppIcons.add,
      semanticLabel: context.l10n.cardNewCard,
      onPressed: onAddCard,
    );
  }
```

Import `card_search_open_state.dart`; update the class doc to name search.

- [ ] **Step 4: Run the card list tests**

Run: `flutter test --exclude-tags golden test/features/card/presentation`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "fix(card): the add FAB steps aside while searching (3d-1)"
```

---

### Task 3: Card list, retry a failed bulk flag (07)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (`_hasBulkFailed`, `_flag`, `_clearAfter`, the banner)
- Test: `test/features/card/presentation/card_list_layout_test.dart`

- [ ] **Step 1: Write the failing tests**

Add a fake next to `_FailingFlags`:

```dart
/// Fails the first write and any while [isFailing]; counts every call.
final class _FlakyFlags implements CardRepository {
  final calls = <(Set<String>, bool)>[];
  var isFailing = true;

  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) {
    calls.add((cardIds, isFlagged));
    if (isFailing) {
      return Future.error(const UnknownDatabaseFailure(cause: 'locked'));
    }
    return Future.value(const Ok(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

and the tests:

```dart
  Future<_FlakyFlags> failOneFlag(WidgetTester tester, LibraryEnv env) async {
    final flags = _FlakyFlags();
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
    return flags;
  }

  libraryTest('Retry repeats the failed flag with the same cards and choice '
      '(critique 2026-09-30 part 3d-1)', (tester, env) async {
    final flags = await failOneFlag(tester, env);
    flags.isFailing = false;

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pumpAndSettle();

    expect(flags.calls, hasLength(2));
    expect(flags.calls.last, flags.calls.first);
    expect(find.text(_en.cardBulkFailedTitle), findsNothing);
    expect(find.text(_en.cardFlaggedToast(1)), findsOneWidget);
  });

  libraryTest('a retry that fails again keeps the banner and the selection '
      '(Review Focus 2)', (tester, env) async {
    final flags = await failOneFlag(tester, env);

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pumpAndSettle();

    expect(flags.calls, hasLength(2));
    expect(find.text(_en.cardBulkFailedTitle), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsOneWidget,
    );
  });
```

Import `package:memox/shared/widgets/mx_button.dart` if missing. If the flag-set sheet label differs, read `showCardFlagSheet` and use its label; ledger it.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/card/presentation/card_list_layout_test.dart --plain-name "3d-1"`
Expected: FAIL: no Retry button in the banner.

- [ ] **Step 3: Implement**

In `_CardListSectionWidgetState`, replace `var _hasBulkFailed = false;` with:

```dart
  /// The flag write that failed, kept so Retry repeats it as it was
  /// (critique 2026-09-30 part 3d-1); null when nothing failed.
  (Set<String>, bool)? _failedFlag;

  bool get _hasBulkFailed => _failedFlag != null;
```

Split `_flag`:

```dart
  Future<void> _flag(Set<String> cardIds) async {
    setState(() => _failedFlag = null);
    final isFlagged = await showCardFlagSheet(context);
    if (isFlagged == null || !mounted) return;
    await _writeFlag(cardIds, isFlagged);
  }

  /// Ruling P3-L4: set or clear, as chosen. The selection goes only once the
  /// write landed (IT-ORG-014); a failure keeps it and says so (E-L6).
  Future<void> _writeFlag(Set<String> cardIds, bool isFlagged) async {
    setState(() => _failedFlag = null);
    try {
      // the existing body of the try block, unchanged
    } on Failure {
      if (!mounted) return;
      setState(() => _failedFlag = (cardIds, isFlagged));
    }
  }
```

In `_clearAfter`, `setState(() => _hasBulkFailed = false);` becomes `setState(() => _failedFlag = null);`. The banner gets:

```dart
                actions: [
                  if (_failedFlag case (final ids, final isFlagged))
                    MxButton(
                      label: l10n.commonRetry,
                      size: MxButtonSize.compact,
                      onPressed: () => unawaited(_writeFlag(ids, isFlagged)),
                    ),
                ],
```

- [ ] **Step 4: Run the card list tests**

Run: `flutter test --exclude-tags golden test/features/card/presentation`
Expected: PASS, including the existing "a failed bulk command keeps the selection".

- [ ] **Step 5: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "fix(card): a failed bulk flag offers Retry (3d-1)"
```

---

### Task 4: Card edit, Save waits for a change (09)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (`_onSave`)
- Test: `test/features/card/presentation/card_editor_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
  MxButton saveChanges(WidgetTester tester) =>
      tester.widget<MxButton>(_footerSave(_en.cardSaveChanges));

  libraryTest('edit: Save waits for a change and goes quiet when it is '
      'undone (critique 2026-09-30 part 3d-1)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    expect(saveChanges(tester).onPressed, isNull);

    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNotNull);

    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNull);
  });

  libraryTest('edit: the flag alone is a change (Review Focus 3)', (
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

    await tester.tap(find.byTooltip(_en.cardFlagLabel));
    await tester.pump();
    expect(saveChanges(tester).onPressed, isNotNull);
  });
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/card/presentation/card_editor_screen_test.dart --plain-name "3d-1"`
Expected: FAIL: Save is enabled on the pristine edit.

- [ ] **Step 3: Implement**

```dart
  /// In edit, Save waits for a change (critique 2026-09-30 part 3d-1);
  /// create saves whatever is valid.
  VoidCallback? get _onSave =>
      _draft().check() is Ok &&
          !_isSaving &&
          !_deckRejects &&
          (_isCreating || _isDirty)
      ? () => unawaited(_save())
      : null;
```

- [ ] **Step 4: Run the card tests**

Run: `flutter test --exclude-tags golden test/features/card`
Expected: PASS. A test that saved an unchanged edit now needs a change first; make one and ledger it.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card test/features/card
git commit -m "fix(card): Save waits for a change when editing (3d-1)"
```

---

### Task 5: Study options, a failed save is visible (15)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart`
- Modify: `lib/features/settings/presentation/widgets/sections/study_options_footer_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`studyOptionsNotSavedTitle`)
- Test: `test/features/settings/presentation/study_options_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add (it reuses the failure test's seed and steps):

```dart
  libraryTest('a failed save shows a danger banner at the top; the caption '
      'stays the local-only line (critique 2026-09-30 part 3d-1)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(ids.subId),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    final banner = find.widgetWithText(
      MxInlineBanner,
      _en.studyOptionsNotSavedTitle,
    );
    expect(banner, findsOneWidget);
    expect(tester.widget<MxInlineBanner>(banner).tone, MxBannerTone.danger);
    expect(
      find.descendant(
        of: banner,
        matching: find.text(
          _en.studyOptionsSaveFailed(20, _en.studyOptionsOrderCreatedShort),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.studyOptionsLocalOnly), findsOneWidget);
  });
```

- [ ] **Step 2: Add the key, run the test to see it fail**

Add `studyOptionsNotSavedTitle` (en "Not saved", vi "Chưa lưu") to both ARBs and run `flutter gen-l10n`.
Run: `flutter test test/features/settings/presentation/study_options_screen_test.dart --plain-name "3d-1"`
Expected: FAIL: no banner.

- [ ] **Step 3: Implement**

In `StudyOptionsFormWidget.build`, watch the save state and add the banner after the unreadable-override banner:

```dart
    final save = ref.watch(
      studyOptionsControllerProvider(deckId).select((s) => s.save),
    );
```

```dart
        if (save == StudyOptionsSave.failed) ...[
          // A failed save leads the page, not a muted caption (critique
          // 2026-09-30 part 3d-1); the footer keeps Retry save.
          MxInlineBanner(
            tone: MxBannerTone.danger,
            title: l10n.studyOptionsNotSavedTitle,
            message: l10n.studyOptionsSaveFailed(
              stored.options.cardLimit,
              studyOptionsOrderName(l10n, stored.options.newCardOrder),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
```

In `StudyOptionsFooterWidget`, drop the `StudyOptionsSave.failed =>` arm of `caption`, so a failed save reads `studyOptionsLocalOnly` there.

- [ ] **Step 4: Run the settings tests**

Run: `flutter test --exclude-tags golden test/features/settings`
Expected: PASS; the existing "a failed save names what the deck still uses" still finds the sentence (now in the banner).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings lib/l10n test/features/settings
git commit -m "fix(settings): a failed study options save shows a banner (3d-1)"
```

---

### Task 6: Progress rows and the first CTA (22, D3, BR-PROGRESS-001)

**Files:**
- Modify: `lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart`
- Modify: `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart:61` (tone)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`progressRowCardsDays`, `progressRowCardDaysLead`; remove `progressRowCards` and `progressRowDays` if nothing else uses them)
- Test: `test/features/progress/presentation/progress_screen_test.dart`, `test/features/progress/presentation/deck_progress_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

In `progress_screen_test.dart`, replace the end of the first test (the `'26'` and `'13'` expectations) with:

```dart
    final total = await _row(tester, _en.progressAllDecks);
    expect(
      find.descendant(
        of: total,
        matching: find.text(_en.progressRowCardsDays(26, 6)),
      ),
      findsOneWidget,
    );
    // The total opens nothing, so it has no chevron (D3).
    expect(
      find.descendant(of: total, matching: find.byIcon(AppIcons.chevronRight)),
      findsNothing,
    );
    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(
        of: topik,
        matching: find.text(_en.progressRowCardsDays(13, 6)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: topik,
        matching: find.textContaining(_en.progressRowCardDaysLead),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topik, matching: find.byIcon(AppIcons.chevronRight)),
      findsOneWidget,
    );
```

and in the never-studied test add:

```dart
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.progressStartStudying),
          )
          .tone,
      MxButtonTone.primary,
    );
```

Add a Vietnamese check:

```dart
  libraryTest('a deck row reads its card-days in Vietnamese (D3)', (
    tester,
    env,
  ) async {
    final vi = lookupAppLocalizations(const Locale('vi'));
    await progressLibrary(env);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(_Taps()),
      locale: const Locale('vi'),
    );
    await _settle(tester);

    final topik = await _row(tester, 'Tiếng Hàn TOPIK I · Từ vựng');
    expect(
      find.descendant(
        of: topik,
        matching: find.textContaining(vi.progressRowCardDaysLead),
      ),
      findsOneWidget,
    );
  });
```

In `deck_progress_screen_test.dart` (Review Focus 4), in the test that shows a level with sub-decks, assert a sub-deck row has `find.byIcon(AppIcons.chevronRight)` and the level's total row has none; if the file pins `'{n}'` digits in a row, move those to `_en.progressRowCardsDays(n, d)` and ledger it.

Imports as needed: `app_icons.dart`, `mx_button.dart`.

- [ ] **Step 2: Add the keys, run the tests to see them fail**

Add `progressRowCardsDays` and `progressRowCardDaysLead` (Global Constraints) to both ARBs with the en placeholders metadata, run `flutter gen-l10n`.
Run: `flutter test test/features/progress/presentation/progress_screen_test.dart`
Expected: FAIL on the new lines, the chevron and the CTA tone.

- [ ] **Step 3: Implement the row**

```dart
    return MxListRow(
      titleMaxLines: 2,
      title: name,
      meta: isActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.progressRowCardsDays(
                    numbers.activeCards,
                    numbers.activeDays,
                  ),
                  style: caption,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.progressRowCardDaysLead),
                      TextSpan(
                        text: l10n.progressRowLearning(
                          numbers.learningCardDays,
                        ),
                        style: styles.captionIn(derived.statusLearningInk),
                      ),
                      const TextSpan(text: _separator),
                      TextSpan(
                        text: l10n.progressRowReviewing(
                          numbers.reviewingCardDays,
                        ),
                        style: styles.captionIn(derived.primaryInk),
                      ),
                    ],
                  ),
                  style: caption,
                ),
              ],
            )
          : Text(l10n.progressNoActivity, style: caption),
      // A deck opens its level; the total opens nothing (D3, FE-A9 D2).
      hasChevron: onOpen != null,
      onTap: onOpen,
      hasDivider: hasDivider,
    );
```

Remove the now-unused `colors` local. Update the class doc: `The card count and active days lead the meta line, the card-days follow under their label, and a deck ends in a chevron (critique 2026-09-30 part 3d-1, D3).`

In `progress_today_widget.dart`, the never-studied `MxButton` takes `tone: MxButtonTone.primary` (the screen's only action).

Run `grep -rn "progressRowCards\b\|progressRowDays" lib test`; remove each key from both ARBs when nothing references it, and rerun `flutter gen-l10n`.

- [ ] **Step 4: Run the progress tests**

Run: `flutter test --exclude-tags golden test/features/progress`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress lib/l10n test/features/progress
git commit -m "fix(progress): rows name their card-days and open with a chevron (3d-1 D3)"
```

---

### Task 7: Trash notices above the list (06, D4)

**Files:**
- Modify: `lib/features/trash/presentation/screens/trash_screen.dart` (`_list`)
- Test: `test/features/trash/presentation/trash_selection_test.dart`

- [ ] **Step 1: Write the failing tests**

In the first test, after `expect(find.text(_en.trashKindLock), findsOneWidget);`, add:

```dart
    // Above the list, not after it (critique 2026-09-30 part 3d-1, D4).
    expect(
      tester.getTopLeft(find.text(_en.trashKindLock)).dy,
      lessThan(tester.getTopLeft(find.text('meokda · eat')).dy),
    );
```

In the purge-blocked test, after the banner expectation, add:

```dart
    expect(
      tester
          .getTopLeft(find.text(_en.trashPurgeBlocked('Food', 'bap · rice')))
          .dy,
      lessThan(tester.getTopLeft(find.text('Food')).dy),
    );
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/trash/presentation/trash_selection_test.dart`
Expected: the two new expectations FAIL (the notices sit below the rows).

- [ ] **Step 3: Implement**

In `_list`, build the notices once and place them right after the retention note block, before `_Filters`:

```dart
    final notices = [
      if (kind != null) MxNote(text: l10n.trashKindLock),
      for (final note in _blockedNotes(l10n, state, entries))
        MxInlineBanner(tone: MxBannerTone.warning, message: note),
    ];
```

```dart
      // Why the other kind waits and what a purge skipped, above the rows
      // they are about (critique 2026-09-30 part 3d-1, D4).
      for (final notice in notices) ...[
        notice,
        const SizedBox(height: AppSpacing.grouped),
      ],
```

Delete the two old trailing items after the rows, and update the method doc: `The note, then why the other kind waits and what a purge skipped (D4), the filters with their counts (A6, none while selecting), the header, then the rows.`

- [ ] **Step 4: Run the trash tests**

Run: `flutter test --exclude-tags golden test/features/trash`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trash test/features/trash
git commit -m "fix(trash): notices sit above the rows they are about (3d-1 D4)"
```

---

### Task 8: Sync status (27, 23, D5)

**Files:**
- Modify: `lib/features/settings/presentation/screens/sync_screen.dart` (the Sync now button)
- Modify: `lib/features/settings/presentation/widgets/support/sync_labels_widget.dart` (`syncNeedsAttention`)
- Modify: `lib/features/settings/presentation/widgets/sections/settings_sync_section_widget.dart` (`iconTone`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`syncSyncing`)
- Test: `test/features/settings/presentation/sync_screen_test.dart`, `sync_labels_test.dart`, `settings_sync_section_test.dart`

- [ ] **Step 1: Write the failing tests**

`sync_labels_test.dart`:

```dart
  test('needs attention: the last run failed or a change was refused '
      '(critique 2026-09-30 part 3d-1, D5)', () {
    final at = DateTime(2026, 9, 28, 0, 10);
    expect(syncNeedsAttention(const SyncStatus()), isFalse);
    expect(syncNeedsAttention(SyncStatus(lastSuccessAt: at)), isFalse);
    expect(syncNeedsAttention(const SyncStatus(pendingCount: 2)), isFalse);
    expect(syncNeedsAttention(const SyncStatus(rejectedCount: 1)), isTrue);
    expect(
      syncNeedsAttention(
        SyncStatus(
          lastFailure: LastSyncFailure(SyncFailureKind.network, at),
        ),
      ),
      isTrue,
    );
  });
```

`settings_sync_section_test.dart`: rename `'the Sync tile stays tinted while changes were refused (T4)'` to `'the Sync tile is warning while changes were refused (D5)'` and expect `MxIconTileTone.warning`; add the same test with `SyncStatus(lastFailure: LastSyncFailure(SyncFailureKind.network, env.clock.now()))` expecting warning, and one with `const SyncStatus(pendingCount: 2)` expecting tinted.

`sync_screen_test.dart`:

```dart
  libraryTest('while Sync now runs the screen says Syncing…; the button comes '
      'back after (critique 2026-09-30 part 3d-1, D5)', (tester, env) async {
    final commands = FakeSyncCommands()..hold = Completer<bool>();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await _settle(tester);

    expect(find.text('Syncing…'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);

    commands.hold!.complete(true);
    await _settle(tester);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Syncing…'), findsNothing);
  });

  libraryTest('a sync that fails while Syncing… shows brings the button and '
      'the failure back (Review Focus 5)', (tester, env) async {
    final commands = FakeSyncCommands()..hold = Completer<bool>();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await _settle(tester);

    commands.hold!.complete(false);
    await _settle(tester);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Syncing…'), findsNothing);
  });
```

If `FakeSyncCommands` reports failure differently from `complete(false)`, read `test/support/sync_fakes.dart` and the existing "a failed Sync now says nothing was lost" test and follow it; ledger it.

- [ ] **Step 2: Add the key, run the tests to see them fail**

Add `syncSyncing` (en "Syncing…", vi "Đang đồng bộ…") to both ARBs, `flutter gen-l10n`.
Run: `flutter test test/features/settings/presentation/sync_labels_test.dart test/features/settings/presentation/settings_sync_section_test.dart test/features/settings/presentation/sync_screen_test.dart`
Expected: FAIL to compile (`syncNeedsAttention`), then on the tone and the missing "Syncing…".

- [ ] **Step 3: Implement**

`sync_labels_widget.dart`, beside `syncIsSettled`:

```dart
/// Something needs the person: the last run failed or a change was
/// refused. Screen 23's Sync tile turns warning (critique 2026-09-30 part
/// 3d-1, D5).
bool syncNeedsAttention(SyncStatus status) =>
    status.lastFailure != null || status.rejectedCount > 0;
```

`settings_sync_section_widget.dart`:

```dart
          iconTone: switch (status) {
            _ when syncNeedsAttention(status) => MxIconTileTone.warning,
            _ when syncIsSettled(status) => MxIconTileTone.success,
            _ => MxIconTileTone.tinted,
          },
```

`sync_screen.dart`: while `task == SyncTask.syncNow`, draw a local row in place of the button:

```dart
            if (task == SyncTask.syncNow)
              const _SyncingRow()
            else
              MxButton(
                // unchanged, without isLoading
              ),
```

```dart
/// The manual sync running: the spinner and its word, at a button's height
/// (critique 2026-09-30 part 3d-1, D5). Local: the other async buttons keep
/// the spinner alone.
class _SyncingRow extends StatelessWidget {
  const _SyncingRow();

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.syncSyncing;
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: AppSize.touchTarget,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          children: [
            const MxSpinner(),
            Text(label, style: context.textStyles.rowDescription),
          ],
        ),
      ),
    );
  }
}
```

Use the size the screen's `MxButton` actually has if it is not `AppSize.touchTarget` (read `MxButton`'s regular height) and the spinner size the screen's other inline spinners use; ledger both.

- [ ] **Step 4: Run the settings tests**

Run: `flutter test --exclude-tags golden test/features/settings`
Expected: PASS. A test that asserted `isLoading` on Sync now (none expected) moves to "Syncing…"; ledger it.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings lib/l10n test/features/settings
git commit -m "fix(sync): Syncing… while it runs; the Sync tile warns on failure (3d-1 D5)"
```

---

### Task 9: Records, goldens and the gate

**Files:**
- Modify: `docs/shared/ui/screen-handoff/06-trash.md`, `07-card-list.md`, `09-card-edit.md`, `14-study-entry.md`, `15-study-options.md`, `22-progress.md`, `23-settings.md`, `27-sync.md`
- Modify: `docs/wbs_FE.md` (row FE-D15 after FE-D14)
- Modify: `test/**/goldens/*.png` (regenerated)

- [ ] **Step 1: Detail files**

Under each file's `## Rulings`, append one line beginning `- **Critique 2026-09-30 part 3d-1 (spec \`2026-10-01-critique-fixes-part3d1-design.md\`):**` and stating that screen's change in one sentence (as in spec §3). In 22, also update the List row of the layout table: the meta line is "{n} cards · {d} active days" then "Card-days: {l} learning · {r} reviewing", deck rows end in a chevron, the total has none, and the never-studied "Start studying" is primary. In 27, replace any line that says the Sync now button spins while running.

- [ ] **Step 2: WBS**

```
| FE-D15 | Critique 2026-09-30 phần 3d-1: 14 Learn chỉ ở footer khi chỉ có thẻ mới, 07 FAB ẩn khi tìm kiếm và Retry cho flag hàng loạt lỗi, 09 Save chờ thay đổi, 15 banner khi lưu lỗi, 22 hàng có chevron và nhãn card-days, nút Start studying primary, 06 banner lên trên danh sách, 27 "Đang đồng bộ…" và 23 ô icon warning khi sync lỗi | đang làm | FE-D14 | S | [spec](superpowers/specs/2026-10-01-critique-fixes-part3d1-design.md) và [plan](superpowers/plans/2026-10-01-critique-fixes-part3d1.md) | — |
```

- [ ] **Step 3: Docs check and commit**

Run: `python3 tools/docs/check.py | tail -1` (run `python3 tools/docs/generate.py` first if it reports a stale generated file)
Expected: `PASS — 0 error(s), …`

```bash
git add docs
git commit -m "docs: record critique 2026-09-30 part 3d-1"
```

- [ ] **Step 4: Goldens (Linux container)**

Run: `TZ=UTC flutter test --tags golden --update-goldens 2>&1 | tail -1; git status --short | grep goldens`
Expected: all pass; changed goldens are limited to study entry only-new, card list (if a FAB or banner shows), card edit (Save tone), study options failed, progress (rows, never), trash (purge blocked, selection), sync syncing, settings loaded. Anything else is a finding to debug before committing.

- [ ] **Step 5: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/3d1-dod.log 2>&1; echo $?; grep -E "All tests passed|Some tests failed|failed gates" /tmp/3d1-dod.log | tail -2; TZ=UTC flutter test --tags golden 2>&1 | tail -1`
Expected: exit 0, all tests passed, goldens pass.

- [ ] **Step 6: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): regenerate for part 3d-1"
```
