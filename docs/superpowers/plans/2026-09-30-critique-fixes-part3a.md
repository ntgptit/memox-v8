# Critique 2026-09-30, part 3a — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clear the quick, safe Minors of the 2026-09-30 critique: part 1's deferred findings and the snapshot's mechanical ones (copy, glyphs, fixtures, doc drift).

**Architecture:** Local edits only: `MxSettingsRow` stops dimming its controls, banner actions put the primary last, the test helper counts an exact number of primaries, ARB copy changes, three glyph swaps, fixture corrections and records.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, ARB l10n (en, vi), goldens rendered in this Linux container.

**Spec:** `docs/superpowers/specs/2026-09-30-critique-fixes-part3a-design.md` (rulings R1–R5)

## Global Constraints

- Tests run at the default text scale only; light and dark both stay.
- Every string change lands in `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`; run `flutter gen-l10n` after ARB edits; a new `@key` puts `placeholders` before `description` (guard rule).
- New-card order: "In order" on the segment, "in creation order" in running text (R2).
- Refused rows: "{n} changes weren't accepted" (R3).
- Banner actions: primary last (R5, amends FE-B6).
- No new abstraction; the guard (`memox-v8`) stays clean; booleans read as predicates.
- Goldens only via `flutter test --tags golden --update-goldens` in this container.
- Commit after each task; English conventional messages ending with the session's Co-Authored-By and Claude-Session lines.

## Review Focus

- **A disabled `MxSettingsRow` whose trailing is plain text, not a control**: the text must still read as unavailable (Task 2 test "a disabled row's non-control trailing still dims").
- **Refused copy with one change**: the singular reads "1 change wasn't accepted" on 27, 23 and 13 (Task 4 tests use `rejectedCount: 1` and `2`).
- **Vietnamese plural**: `syncRejectedTitle` in vi renders for 1 and for 2 without an ICU error (Task 4 test pumps `vi`).
- **The helper with `expected: 0`**: a screen with no primary passes, one with a primary fails (Task 1 test).
- **Banner order under a busy reminder**: while the reminder is busy both actions stay in the new order, Try again disabled (Task 3 test).

---

### Task 1: The helper counts an exact number of primaries

**Files:**
- Modify: `test/shared/expect_one_primary.dart`
- Test: `test/shared/expect_one_primary_test.dart`

**Interfaces:**
- Produces: `void expectOnePrimaryPerDecision(WidgetTester tester, {int expected = 1})`.

- [ ] **Step 1: Failing tests.** Append to `expect_one_primary_test.dart`:

```dart
  testWidgets('no primary where one is due fails', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Edit', tone: MxButtonTone.outline, onPressed: () {}),
    );
    expect(
      () => expectOnePrimaryPerDecision(tester),
      throwsA(isA<TestFailure>()),
    );
    expectOnePrimaryPerDecision(tester, expected: 0);
  });
```

- [ ] **Step 2:** `flutter test test/shared/expect_one_primary_test.dart` → FAIL (`expected` is not a parameter).

- [ ] **Step 3: Implement.** Signature `void expectOnePrimaryPerDecision(WidgetTester tester, {int expected = 1})`; assertion `expect(count, expected, reason: 'expected $expected primary fill(s), found $count');`. Doc: "exactly [expected]; pass 0 for a screen that offers no decision".

- [ ] **Step 4:** Run the file, then every caller: `flutter test --exclude-tags golden test/features/settings test/features/study test/features/deck test/features/transfer test/shared` → PASS. A caller that now fails had no primary: read it; if the screen truly has none, pass `expected: 0` and say why in a comment.

- [ ] **Step 5: Commit** `test: the one-primary helper counts an exact number`.

### Task 2: A disabled settings row does not dim its controls twice

**Files:**
- Modify: `lib/shared/widgets/mx_settings_row.dart`
- Test: `test/shared/widgets/mx_settings_row_test.dart`

- [ ] **Step 1: Failing tests** (append):

```dart
  testWidgets('a disabled row does not dim its control twice (critique '
      '2026-09-30 part 3a)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          subtitle: 'Turn the reminder on to choose a time',
          icon: AppIcons.clock,
          isEnabled: false,
          trailing: MxButton(
            label: '20:00',
            size: MxButtonSize.compact,
            onPressed: null,
          ),
        ),
      ),
    );
    final layers = find.ancestor(
      of: find.text('20:00'),
      matching: find.byType(Opacity),
    );
    expect(layers, findsOneWidget);
  });

  testWidgets("a disabled row's non-control trailing still dims", (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          isEnabled: false,
          trailing: Text('20:00'),
        ),
      ),
    );
    expect(
      find.ancestor(of: find.text('20:00'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });
```

(import `mx_button.dart`; `MxButton` has a const constructor if the first test does not compile as const, drop `const` there.)

- [ ] **Step 2:** Run the file → the first test FAILS (two Opacity layers).

- [ ] **Step 3: Implement.** Only dim a trailing or wide control that does not dim itself: add

```dart
  /// MxButton, MxToggle and MxStepper draw their own disabled opacity, so
  /// the row leaves them alone (critique 2026-09-30 part 3a).
  static bool _drawsOwnDisabledState(Widget control) =>
      control is MxButton || control is MxToggle || control is MxStepper;

  Widget _dimControl(Widget control) =>
      _drawsOwnDisabledState(control) ? control : _dim(control);
```

and use `_dimControl` for `trailing` and `below`/`wideControl` instead of `_dim`. Import `mx_button.dart`, `mx_toggle.dart`, `mx_stepper.dart`. Update the `isEnabled` doc ("… a control that draws its own disabled state is left to it").

- [ ] **Step 4:** `flutter test test/shared/widgets/mx_settings_row_test.dart test/features/reminders test/features/settings --exclude-tags golden` → PASS.

- [ ] **Step 5: Commit** `fix(shared): a disabled setting does not dim its control twice`.

### Task 3: Banner actions put the primary last (R5)

**Files:**
- Modify: `lib/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart:43-48`
- Test: `test/features/reminders/presentation/reminder_screen_test.dart:143-168`

- [ ] **Step 1: Update the test first.** Rename to `'permDenied: Try again outlined, then Open system settings last and primary (R5, amends FE-B6)'`; expected labels `[_en.reminderTryAgain, _en.reminderOpenSystemSettings]`, tones `[MxButtonTone.outline, MxButtonTone.primary]`.

- [ ] **Step 2:** Run the file → FAIL (old order).

- [ ] **Step 3: Implement.** In the `permissionDenied` branch, swap the two actions: `action(l10n.reminderTryAgain, tone: MxButtonTone.outline)` first, then the `MxButton` "Open system settings". Comment: `// The primary last, as every banner (R5; critique 2026-09-30 part 3a).`

- [ ] **Step 4:** Run `flutter test test/features/reminders --exclude-tags golden` → PASS. Add the Review Focus check in the same test file:

```dart
  libraryTest('permDenied while busy keeps the order; Try again is disabled', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform(
      permission: ReminderPermission.denied,
    );
    final s = await _pump(tester, env, platform: platform);
    await _toggle(tester);
    s.store.hold = Completer<void>();
    await tester.tap(find.text(_en.reminderTryAgain));
    await tester.pump();
    final buttons = tester
        .widgetList<MxButton>(
          find.descendant(
            of: find.byType(MxInlineBanner),
            matching: find.byType(MxButton),
          ),
        )
        .toList();
    expect(buttons.map((b) => b.label), [
      _en.reminderTryAgain,
      _en.reminderOpenSystemSettings,
    ]);
    expect(buttons.first.onPressed, isNull);
    s.store.hold!.complete();
    await _settle(tester);
  });
```

(If `FlakySettingsRepository.hold` does not gate the retry path, read `test/support/settings_fakes.dart` and hold the call the retry makes; the assertion stays.)

- [ ] **Step 5: Commit** `fix(reminders): banner actions put the primary last (R5)`.

### Task 4: Copy — order names, the defaults note, refused rows, apostrophes

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/settings/presentation/sync_screen_test.dart`, `settings_sync_section_test.dart`, `sync_labels_test.dart`, `test/features/study/presentation/study_home_sync_banner_test.dart`, `test/shared/widgets/mx_floating_notice_test.dart` (only if it quotes the refused copy), settings tests quoting "Created" or the defaults note

- [ ] **Step 1: Update the tests first.** Replace every quoted old string with the new one:
  - "N changes are kept only on this device" → "N changes weren't accepted"; "1 change kept only on this device" → "1 change wasn't accepted"; "2 changes are kept only on this device." → "2 changes weren't accepted.".
  - "Created" (segment) → "In order"; "created order" → "in creation order"; "Apply to sessions…" → "Applies to sessions…".
  Add to `sync_screen_test.dart`:

```dart
  libraryTest('one refused change reads in the singular (R3)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 1),
        FakeSyncCommands(),
      ),
    );
    expect(find.text("1 change wasn't accepted"), findsOneWidget);
  });
```

and to `sync_labels_test.dart` a vi check (Review Focus): `lookupAppLocalizations(const Locale('vi')).syncRejectedTitle(1)` and `(2)` both return non-empty strings containing "chưa được máy chủ nhận".

- [ ] **Step 2:** `flutter test --exclude-tags golden test/features/settings test/features/study test/shared` → FAIL on the changed strings.

- [ ] **Step 3: ARB (en).** `settingsOrderCreated` "In order"; `studyOptionsOrderCreatedShort` "in creation order"; `settingsStudyDefaultsNote` "Applies to sessions started from now on. A deck with its own study options keeps them."; `syncRejectedTitle` and `syncStatusRejected` `{count, plural, =1{1 change wasn't accepted} other{{count} changes weren't accepted}}`; `studyHomeSyncRejected` `{count, plural, =1{1 change wasn't accepted.} other{{count} changes weren't accepted.}}`. Replace `’` with `'` in `algorithmSwitchFailedTitle`, `importCaptionColumns`, `importProblemUnreadableTitle`, `importFailedTitle`, `exportFailedTitle`, `exportShareFailedTitle`, `reminderCouldNotTurnOnTitle`, `reminderCouldNotChangeTimeTitle`.

- [ ] **Step 4: ARB (vi).** `settingsOrderCreated` "Theo thứ tự tạo"; `studyOptionsOrderCreatedShort` "theo thứ tự tạo"; `syncRejectedTitle` and `syncStatusRejected` `{count, plural, other{{count} thay đổi chưa được máy chủ nhận}}`; `studyHomeSyncRejected` `{count, plural, other{{count} thay đổi chưa được máy chủ nhận.}}`. Run `flutter gen-l10n`. Then `grep -rn "’" lib/l10n/app_en.arb` → only non-apostrophe uses (quotes) remain; `grep -rn "kept only on this device" lib test` → none.

- [ ] **Step 5:** Re-run Step 2's command, plus `test/features/transfer test/features/reminders test/features/deck` (the apostrophe strings) → PASS; fix any test still quoting a curly apostrophe.

- [ ] **Step 6: Commit** `fix(copy): one name for the new-card order, refused rows say what happened, straight apostrophes`.

### Task 5: Glyphs and notes

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_add_details_widget.dart:12,55`, `lib/features/transfer/presentation/widgets/items/import_preview_row_widget.dart:93-96`, `lib/features/settings/presentation/screens/theme_screen.dart:97`, `lib/app/gallery/gallery_states_section.dart`
- Test: `test/features/card/presentation/` (editor test), `test/features/transfer/presentation/import_preview_row_test.dart`, theme screen test, gallery test if one lists states

- [ ] **Step 1: Failing tests.**
  - Card editor: in the create-screen test that finds "Add details", add `expect(find.byIcon(AppIcons.add), findsWidgets); expect(find.byIcon(AppIcons.details), findsNothing);` (scope the first to the disclosure with `find.descendant` if other plus glyphs exist).
  - `import_preview_row_test.dart`: `expect(find.descendant(of: row, matching: find.byIcon(AppIcons.alert)), findsOneWidget);` and none of `AppIcons.close`.
  - Theme screen test: `expect(find.byWidgetPredicate((w) => w is MxNote && w.isHint), findsOneWidget);` (use the field `MxNote.hint` sets; read `lib/shared/widgets/mx_note.dart` for its name).

- [ ] **Step 2:** Run those files → FAIL.

- [ ] **Step 3: Implement.** Add-details glyph `AppIcons.add` (class doc: "a plus, the label…"; if `AppIcons.details` has no other use, remove it from `app_icons.dart`). Preview row invalid glyph `AppIcons.alert`. Theme note `MxNote.hint(text: l10n.settingsAppliesAtOnce)`. Gallery: after the first `MxErrorState`, add

```dart
      MxErrorState(
        title: context.l10n.galleryCouldNotLoadDecks,
        body: context.l10n.galleryLoadErrorBody,
        icon: AppIcons.offline,
        retryLabel: context.l10n.commonRetry,
        onRetry: () {},
      ),
```

- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/card test/features/transfer test/features/settings test/app` → PASS.

- [ ] **Step 5: Commit** `fix(ui): a plus for Add details, an alert for an invalid import row, a hint note on Theme`.

### Task 6: Tests and fixtures

**Files:**
- Modify: `test/features/transfer/presentation/card_import_screen_test.dart`, `test/features/reminders/presentation/reminder_screen_test.dart`, `test/features/card/presentation/card_list_golden_test.dart`, `test/features/deck/presentation/deck_level_screen_golden_test.dart:63`, `test/features/search/presentation/library_search_golden_test.dart:171-204`, `test/features/card/presentation/card_detail_golden_test.dart:16-60`

- [ ] **Step 1: Import blank cell.** In `'a short or blank sample cell shows no sample'`, after `expect(find.text('mul'), findsOneWidget);` add, for Column B and C rows, that each `ImportMappingRowWidget` other than the first holds exactly two `Text`s (column name and header):

```dart
    final rows = find.byType(ImportMappingRowWidget);
    for (var i = 1; i < 3; i++) {
      expect(
        find.descendant(of: rows.at(i), matching: find.byType(Text)),
        findsNWidgets(3), // column name, header, the field chip's label
      );
    }
```

Run it; if the count differs because the chip renders more `Text`s, count against the chip-free `Column` (`find.descendant(of: rows.at(i), matching: find.byType(Column))`). This test must pass on current code (it pins behaviour); watch it fail once by temporarily returning `'x'` from `sampleOf`, then restore.

- [ ] **Step 2: Preview loading.** In `reminder_screen_test.dart`:

```dart
  libraryTest('while the preview loads the row keeps its place', (
    tester,
    env,
  ) async {
    final never = Completer<ReminderDigest?>();
    await _pump(
      tester,
      env,
      overrides: [
        reminderPreviewDigestProvider.overrideWith((ref) => never.future),
      ],
    );
    expect(find.text(_en.reminderPreviewTitle), findsOneWidget);
    expect(find.text(_en.reminderPreviewHint), findsOneWidget);
    expect(find.text(_en.reminderPreviewNothingDue), findsNothing);
    expect(tester.takeException(), isNull);
  });
```

- [ ] **Step 3: Card search golden with results.** In `card_list_golden_test.dart`, add `card list, search results, $theme`: seed as the existing search golden, open search, enter a term that matches two cards (read the seed for one), set `tester.view.viewInsets = const FakeViewPadding(bottom: 900)` (300 dp at 3x) and `addTearDown(tester.view.resetViewInsets)`, `pumpAndSettle`, capture `goldens/card_list_search_results_$theme.png`.

- [ ] **Step 4: Due strip chevron.** In `deck_level_screen_golden_test.dart:63` pass `deckScreen(onOpenStudyHome: () {})` for the `library_decks` golden.

- [ ] **Step 5: Load-more failed.** Before `expectBoundaryGolden` in the load-more test, assert `expect(find.byType(MxInlineBanner), findsOneWidget);`. Run the golden test without `--update-goldens`: if the assertion fails, find why the tap did not reach the failure (use superpowers:systematic-debugging: read `search_load_more_widget.dart` and `_LaterPagesFail`; the fix is in the test's pumping or the fake's page threshold, never in production code), then capture.

- [ ] **Step 6: Card detail cycles.** In `card_detail_golden_test.dart` `_seed`, after inserting the card, make the root deck and the card's schedule agree with the history's newest cycle:

```dart
  final root = (await env.decks.root('Korean')).id;
  await env.db.customStatement(
    'UPDATE deck SET generation = 2 WHERE id = ?',
    [root],
  );
  await env.db.customStatement(
    "UPDATE card_schedule SET generation = 2 WHERE card_id = 'c'",
  );
```

(`env.decks.root('Korean')` returns the existing root; if it creates a second one, capture the root id from the first call instead.)

- [ ] **Step 7:** `flutter test --exclude-tags golden test/features/transfer test/features/reminders` → PASS; the golden changes are taken in Task 8.

- [ ] **Step 8: Commit** `test: pin the import blank cell and the preview loading; fixtures show the fixes`.

### Task 7: Records

**Files:**
- Modify: `DESIGN.md`, `docs/shared/ui/screen-handoff/{01-deck-list,07-card-list,08-card-create,13-study-home,15-study-options,16-study-browse,16a-study-self-assess,23-settings,24-daily-reminder,25-theme,27-sync}.md`, `docs/wbs_FE.md`

- [ ] **Step 1: DESIGN.md.** Under `MxInlineBanner` in Components: "actions put the primary last (Material 3; R5 amends FE-B6)". Under `MxSettingsRow`: "a control that draws its own disabled state (MxButton, MxToggle, MxStepper) is not dimmed again".
- [ ] **Step 2: Detail files.** 01: delete the stale Pending row about the due strip; the decks golden shows its chevron. 07: make the legend and sort-chip copy match `card_list_light.png` ("Newest ⇅", no four-state legend); add the `card_list_search_results` golden row. 08: the single Save is in the footer (remove the app-bar Save). 13, 23, 27: the refused copy "{n} changes weren't accepted". 15 and 23: "In order" / "in creation order" and "Applies to sessions…". 16, 16a: use the name the app shows for the mode (read `cardModeSelfAssess` in `app_en.arb`) in headings and tables. 24: banner order (R5) and the loading note. 25: the note is a hint.
- [ ] **Step 3: WBS.** Add row FE-D9 "Critique 2026-09-30 phần 3a: Minor nhanh và an toàn (…)" status "đang làm", dependency FE-D8, links to this spec and plan. Run `python3 tools/docs/generate.py`.
- [ ] **Step 4: Commit** `docs: record critique part 3a`.

### Task 8: Goldens, gates, review

- [ ] **Step 1:** `flutter test --tags golden` (no update) and list the failing goldens; expected: dark and light screens with a disabled settings row (24 off states), 24 perm denied (order), 23/15 (order name, note), 27/13/23 refused copy, 08 create/edit (glyph), 11 preview (glyph), 25 theme (note), gallery states, 01 decks (chevron), 04 load-more, 10 detail top/history, new `card_list_search_results`. Anything else is a regression: stop and debug.
- [ ] **Step 2:** `flutter test --tags golden --update-goldens`; view 4 changed goldens with Read; commit `test(goldens): regenerate for critique part 3a`.
- [ ] **Step 3: Gates.** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`, `FLUTTER_ROOT=… bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → all pass (fix guard warnings in the task that caused them).
- [ ] **Step 4:** Golden review page with `golden-compare` (base = the commit before Task 1), families per item group, `why` in Vietnamese.
- [ ] **Step 5:** Whole-branch review of this part's range (superpowers:requesting-code-review, most capable model), one fix pass, then `finishing-a-development-branch`.
