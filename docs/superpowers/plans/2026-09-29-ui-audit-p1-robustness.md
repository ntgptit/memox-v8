# UI audit P1: layout robustness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the audit's P1 layout-robustness findings at their source: the keyboard, large text, long content, missing spacing, and study faces that scroll without saying so.

**Architecture:** Mostly shared-widget changes. Each one is small, keeps its default, and is backward compatible:
- `MxFooterBar` drops its caption while the keyboard is up.
- `MxSettingsRow` moves a trailing control under the text at large text.
- `MxListRow` gains `titleMaxLines`.
- `MxActionSheetCommandRow` allows a 2-line subtitle.
- `StudyScrollFadeWidget` takes the card's ground colour.
- `StudyFaceCardWidget` and Browse wrap their scroll in the fade.

Feature call sites then adopt these, plus these direct changes:
- The editor and Import hide the deck-path header while typing.
- Explicit top gaps are added where they are missing.
- The session chrome is capped at 2 lines, and the footer hint steps aside while the keyboard is up (Fill).

Goldens are regenerated once, and the owner reviews them through `golden-compare`.

**Tech Stack:** Flutter 3.47.5, flutter_test (`tester.view.viewInsets`, `textScale`), golden tests.

**Spec:** [`docs/superpowers/specs/2026-09-29-ui-audit-per-screen.md`](../specs/2026-09-29-ui-audit-per-screen.md). In scope:
- Global Findings patterns 1 (fixed header and footer vs keyboard), 2 (1-line user content), 4 (missing gaps) and 6 (silent face scroll);
- the study-chrome item;
- the `MxSettingsRow` large-text item (screen 24).

Out of scope (a later density plan):
- patterns 3 (two primary CTAs) and 5 (hero repeats detail);
- `MxStudyTopBar` chip, `MxTagChip` width, lazy lists, `MxOptionRow` read-only state, `MxSettingsRow` destructive tone;
- the deck row's meta and badge (01), the card bulk-bar labels (07), the Trash footer labels (06);
- the Fill input's border (a design change).

## Global Constraints

- Tokens only (`AppSpacing`, `AppSize`, `AppOpacity`, `context.textStyles`, `context.colors`). New numeric thresholds are named `static const` on the widget, with a doc comment.
- Every shared-widget change is additive: current call sites compile and render unchanged at text scale 1.0 with no keyboard.
- The large-text threshold is `1.5` for moving `MxSettingsRow`'s trailing control (the audit's value). `StudyCtaRowWidget` keeps its own 1.3.
- No ARB change.
- Goldens are written only in the Linux renderer. Validate this container on `master` first, as in the previous plan.
- Before the owner is asked to merge, golden changes go through the `golden-compare` skill (CLAUDE.md "Golden review").
- Per-task gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test --exclude-tags golden <touched tests>`.
- Branch `ccr-98684bf9-8obmh2`, one commit per task.
- Ruling for this plan: the deck-path header stays fixed, as recorded in UI-base §9 row 81. It is hidden only while the keyboard is up, so the recorded layout does not change at rest.

## Review Focus

- **The keyboard opens and closes repeatedly.** The header and the caption must come back exactly as before, with no jump in scroll position of the focused field. Pinned in Task 2 by opening and closing the insets in one test.
- **A settings row at large text whose trailing control is a button, not a toggle** (screen 24's time button). It must stack the same way and keep its 48 dp target. Pinned in Task 3 with an `MxButton` trailing.
- **A study face whose content fits.** It must show no fade. Pinned in Task 6.
- **A 2-line cap on a context line that must still be heard in full.** TalkBack keeps the whole text. Pinned in Task 7 via `semanticsLabel`.
- **A `titleMaxLines: 2` row inside a divided list.** The divider stays under the taller row and rows keep their minimum height. Pinned in Task 4.

---

### Task 0: Baseline

- [ ] **Step 1:** `flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs` (the generated files are git-ignored).
- [ ] **Step 2:** `TZ=UTC flutter test --tags golden`. Expected: all pass. This validates the renderer; if it fails, use the `golden.Dockerfile` recipe in Task 8.
- [ ] **Step 3:** `flutter analyze`. Expected: no issues.

---

### Task 1: `MxFooterBar` drops its caption while the keyboard is up

**Files:**
- Modify: `lib/shared/widgets/mx_footer_bar.dart`
- Test: `test/shared/widgets/mx_footer_bar_test.dart`

**Interfaces:**
- Produces: no API change. The caption renders only when `MediaQuery.viewInsetsOf(context).bottom == 0`.

- [ ] **Step 1: Write the failing test** (append to `main()`)

```dart
  testWidgets('the caption steps aside while the keyboard is up', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: MxFooterBar(
          caption: 'Front and back are required to save.',
          child: MxButton(label: 'Save', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Front and back are required to save.'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });
```

Import `mx_button.dart` if missing.

- [ ] **Step 2:** Run `flutter test test/shared/widgets/mx_footer_bar_test.dart`. Expected: the new test FAILS (the caption is found).
- [ ] **Step 3: Implement.** In `build`, before the return:

```dart
    // While the keyboard is up the field needs the height; the caption is a
    // calm restatement of the rule and waits (audit 2026-09-29, pattern 1).
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
```

and change the caption guard to `if (caption case final caption? when !isTyping)`. Extend the class doc with: "The caption steps aside while the keyboard is up."

- [ ] **Step 4:** Re-run the file. Expected: all pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(shared): MxFooterBar drops its caption while the keyboard is up"`.

---

### Task 2: Editor and Import hide the deck-path header while typing

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` (the `body:` `Column`)
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart` (the `Column` at `body:` holding `widget.deckContext(...)`)
- Test: `test/features/card/presentation/card_editor_screen_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart`
- Golden: add `card editor, create, keyboard, $theme` to `test/features/card/presentation/card_editor_golden_test.dart`

**Interfaces:**
- Consumes: the Task 1 behaviour, which the goldens show together with this task.

- [ ] **Step 1: Write the failing tests.** In `card_editor_screen_test.dart`, add a test that pumps the create editor the way the file's first create test does, then:

```dart
    expect(find.byType(MxBreadcrumb), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900); // 300 dp at 3x
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsOneWidget);
```

Name it `'the deck path steps aside while typing and comes back after (audit P1)'`.

In `card_import_screen_test.dart`, add the same three-state check after the file's standard pump of the Import screen. Import `mx_breadcrumb.dart` in both files. If `tester.view.devicePixelRatio` in this harness is not 3, use `300 * tester.view.devicePixelRatio`.

- [ ] **Step 2:** Run both files. Expected: the new tests FAIL at the second expectation.
- [ ] **Step 3: Implement.** In both files, at the top of the builder that returns the body:

```dart
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
```

and put the header behind it, for example in the editor:

```dart
                children: [
                  if (!isTyping)
                    widget.deckContext(
                      widget.deckId,
                      _isCreating ? l10n.cardAddTitle : l10n.cardEditCrumb,
                    ),
                  Expanded(
                    child: MxScreenScroll(children: _fields(l10n, errors)),
                  ),
                ],
```

Do the same for `widget.deckContext(widget.deckId, l10n.importBreadcrumb)` in Import. Add a one-line comment at each site: `// The path is context, not input: it waits while the keyboard is up (audit P1, §9 row 81 kept at rest).`

- [ ] **Step 4:** Run both files. Expected: pass.
- [ ] **Step 5: Add the keyboard golden** in `card_editor_golden_test.dart`, inside the brightness loop:

```dart
    libraryTest('card editor, create, keyboard, $theme', (tester, env) async {
      final deckId = await _words(env);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
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
          'goldens/card_editor_create_keyboard_$theme.png',
        );
      });
    });
```

The PNG is written in Task 8.
- [ ] **Step 6:** Run `flutter test --exclude-tags golden test/features/card test/features/transfer`. Expected: pass.
- [ ] **Step 7:** Commit: `git commit -m "fix(ui): editor and import keep the field in view while typing"`.

---

### Task 3: `MxSettingsRow` stacks a trailing control at large text

**Files:**
- Modify: `lib/shared/widgets/mx_settings_row.dart`
- Test: `test/shared/widgets/mx_settings_row_test.dart`

**Interfaces:**
- Produces: `static const double stackTextScale = 1.5;`. At `MediaQuery.textScalerOf(context).scale(1) >= stackTextScale`, a `trailing` renders under the label and subtitle, start-aligned, in the `wideControl` position. Below it nothing changes.

- [ ] **Step 1: Write the failing tests**

```dart
  testWidgets('at large text a trailing control moves under the label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSettingsRow(
        label: 'Daily reminder',
        subtitle: 'One notification a day, only when cards are due.',
        icon: AppIcons.reminder,
        trailing: MxToggle(isOn: true, semanticLabel: 'Daily reminder', onChanged: (_) {}),
      ),
      textScale: 2,
    );

    expect(
      tester.getTopLeft(find.byType(MxToggle)).dy,
      greaterThan(tester.getBottomLeft(find.text('Daily reminder')).dy),
    );
  });

  testWidgets('a trailing button stacks too and keeps its 48 target', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSettingsRow(
        label: 'Time',
        trailing: MxButton(label: '20:00', size: MxButtonSize.compact, onPressed: () {}),
      ),
      textScale: 2,
    );

    expect(
      tester.getTopLeft(find.byType(MxButton)).dy,
      greaterThan(tester.getBottomLeft(find.text('Time')).dy),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('at normal text the trailing control stays beside the label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSettingsRow(
        label: 'Daily reminder',
        trailing: MxToggle(isOn: true, semanticLabel: 'Daily reminder', onChanged: (_) {}),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxToggle)).dy,
      lessThan(tester.getBottomLeft(find.text('Daily reminder')).dy),
    );
  });
```

Add any missing imports (`app_icons.dart`, `mx_toggle.dart`, `mx_button.dart`).

- [ ] **Step 2:** Run the file. Expected: the first two FAIL.
- [ ] **Step 3: Implement.** In `build`:

```dart
    final isStacked =
        trailing != null &&
        MediaQuery.textScalerOf(context).scale(1) >= stackTextScale;
    final below = isStacked ? trailing : wideControl;
```

- Use `below` wherever the column now places `wideControl` (the `if (wideControl case final control?)` block becomes `if (below case final control?)`).
- The row's `crossAxisAlignment` and the icon's top padding key off `below == null`, not `wideControl == null`.
- Render `?trailing` in the row only when `!isStacked`.
- `isNavigable` stays as it is.
- Add the constant with this doc: `/// From this text scale on, a trailing control moves under the text, so the label keeps its width (audit 2026-09-29, screen 24).`
- [ ] **Step 4:** Run `flutter test test/shared/widgets/mx_settings_row_test.dart test/features/settings test/features/reminders --exclude-tags golden`. Expected: pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(shared): MxSettingsRow stacks its trailing control at large text"`.

---

### Task 4: Long user content: `MxListRow.titleMaxLines` and a 2-line command-row subtitle

**Files:**
- Modify: `lib/shared/widgets/mx_list_row.dart`, `lib/shared/widgets/mx_action_sheet_command_row.dart`
- Modify adopters:
  - `lib/features/tags/presentation/widgets/items/tag_row_widget.dart`
  - `lib/features/study/presentation/widgets/sections/study_home_decks_widget.dart`
  - `lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart`
- Test: `test/shared/widgets/mx_list_row_test.dart`, `test/shared/widgets/mx_action_sheet_command_row_test.dart`

**Interfaces:**
- Produces: `MxListRow({…, int titleMaxLines = 1})`. `MxActionSheetCommandRow`'s subtitle now allows 2 lines (it was 1).

- [ ] **Step 1: Write the failing tests**

`mx_list_row_test.dart`:

```dart
  testWidgets('a user-named row may take two lines and keeps its divider', (
    tester,
  ) async {
    const name = 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc hiểu';
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxListRow(title: name, subtitle: '12 cards', titleMaxLines: 2),
      ),
    );
    final text = tester.widget<Text>(
      find.byWidgetPredicate((w) => w is Text && w.textSpan?.toPlainText() == name),
    );

    expect(text.maxLines, 2);
    expect(text.softWrap, isTrue);
    expect(tester.getSize(find.byType(MxListRow)).height,
        greaterThanOrEqualTo(AppSize.listRowMin));
  });
```

`mx_action_sheet_command_row_test.dart`: pump a row with a long subtitle, then assert `tester.widget<Text>(find.text(subtitle)).maxLines == 2`. Follow the file's existing pump pattern.

- [ ] **Step 2:** Run both files. Expected: FAIL (compile error on `titleMaxLines`; the subtitle has `maxLines` 1).
- [ ] **Step 3: Implement.**
  - `MxListRow`: add a field with the doc `/// 2 for a name the person chose (tag, deck), which must stay recognisable; content lists keep 1 so rows are one height.` In the title `Text.rich`, use `maxLines: titleMaxLines, softWrap: titleMaxLines > 1`.
  - Update the class doc's first sentence: "The title is one line by default and the sub one line, each with an ellipsis…".
  - `MxActionSheetCommandRow`: set the subtitle to `maxLines: 2` and keep the ellipsis.
  - Adopters: pass `titleMaxLines: 2` to the `MxListRow` in `tag_row_widget.dart`, `study_home_decks_widget.dart` and `progress_deck_row_widget.dart`.
- [ ] **Step 4:** Run `flutter test --exclude-tags golden test/shared/widgets test/features/tags test/features/study test/features/progress`. Expected: pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(ui): user-named rows and command subtitles keep their text"`.

---

### Task 5: Missing top gaps and the note gap

**Files:**
- Modify:
  - `lib/features/search/presentation/widgets/sections/search_body_widget.dart` (`SearchScreenNoResults`, `SearchScreenFailed`)
  - `lib/features/trash/presentation/screens/trash_screen.dart` (empty and error branches)
  - `lib/features/reminders/presentation/screens/reminder_screen.dart` (loaded scroll)
  - `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart` (after the `MxNote` and after the warning banner)
- Test: `test/features/search/presentation/library_search_screen_test.dart`, `test/features/trash/presentation/trash_screen_test.dart`, `test/features/settings/presentation/study_options_screen_test.dart`

- [ ] **Step 1: Write the failing tests.** Each asserts the gap below the app bar.
  - In the search no-results test (after the empty state is shown):

    ```dart
    expect(
      tester.getTopLeft(find.byType(MxEmptyState)).dy -
          tester.getBottomLeft(find.byType(MxAppBar)).dy,
      AppSpacing.control,
    );
    ```

  - In the Trash empty test: the same check.
  - In the study options loaded test:

    ```dart
    expect(
      tester.getTopLeft(find.byType(MxSection).first).dy -
          tester.getBottomLeft(find.byType(MxNote).first).dy,
      AppSpacing.gutter,
    );
    ```

  Add imports as needed. If an app bar's bottom edge differs from the scroll's top in that screen, measure from the `MxScreenScroll` top instead and assert `AppSpacing.control`.
- [ ] **Step 2:** Run the three files. Expected: the new checks FAIL (0).
- [ ] **Step 3: Implement.**
  - Put `const SizedBox(height: AppSpacing.control),` first in the `children` of those four `MxScreenScroll`s (Search no-results and failed, Trash empty and error) and of the Reminder loaded scroll. This is the convention already used by the list branches.
  - In Study options, put `const SizedBox(height: AppSpacing.gutter),` after the `MxNote` and after the `MxInlineBanner`. `MxSection`'s own bottom 16 already spaces the sections.
- [ ] **Step 4:** Run `flutter test --exclude-tags golden test/features/search test/features/trash test/features/reminders test/features/settings`. Expected: pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(ui): empty, error and note blocks keep the page's top and section gaps"`.

---

### Task 6: Study faces say when they scroll

**Files:**
- Modify:
  - `lib/features/study/presentation/widgets/support/study_scroll_fade_widget.dart`
  - `lib/features/study/presentation/widgets/support/study_face_card_widget.dart`
  - `lib/features/study/presentation/widgets/sections/study_browse_widget.dart` (`_Half`)
- Test: `test/features/study/presentation/study_support_widgets_test.dart`

**Interfaces:**
- Produces: `StudyScrollFadeWidget({required Widget child, Color? ground})`. `ground` defaults to `context.colors.surface`.

- [ ] **Step 1: Write the failing tests** (use the file's `_host` and `pumpLibraryScreen` pattern)

```dart
  libraryTest('a face with more below fades its bottom edge (audit P1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        SizedBox(
          height: 200,
          child: StudyFaceCardWidget(
            label: 'Meaning',
            child: Text(List.filled(30, 'a long meaning line').join('\n')),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('study-scroll-fade')), findsOneWidget);
  });

  libraryTest('a face that fits shows no fade', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const SizedBox(
          height: 400,
          child: StudyFaceCardWidget(label: 'Term', child: Text('reserve')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('study-scroll-fade')), findsNothing);
  });
```

- [ ] **Step 2:** Run the file. Expected: the first FAILS.
- [ ] **Step 3: Implement.**
  - `StudyScrollFadeWidget`: add `final Color? ground;` with the doc `/// The fill under the fade: the card's own ground inside a face.` Use `final ground = widget.ground ?? context.colors.surface;`.
  - `StudyFaceCardWidget`: wrap `Center(child: SingleChildScrollView(...))` in `StudyScrollFadeWidget(ground: isAnswer ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLowest, child: …)`. These are `AppDecorations.recessedCard` and `raisedCard` fills.
  - Browse `_Half`: wrap its `Center(SingleChildScrollView)` in `StudyScrollFadeWidget(ground: context.colors.surfaceContainerLowest, child: …)`.
- [ ] **Step 4:** Run `flutter test --exclude-tags golden test/features/study`. Expected: pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(study): faces fade their edge while more is below"`.

---

### Task 7: Session chrome is capped at 2 lines

**Files:**
- Modify: `lib/features/study/presentation/widgets/support/session_context_line_widget.dart`, `session_footer_hint_widget.dart`
- Test: `test/features/study/presentation/study_support_widgets_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
  libraryTest('the context line takes at most two lines and is heard whole', (
    tester,
    env,
  ) async {
    const text = 'Tiếng Hàn TOPIK I · Từ vựng sơ cấp · Learning · Stage 1 of 3 · Match';
    await pumpLibraryScreen(
      tester,
      env,
      _host(const SessionContextLineWidget(text: text)),
      textScale: 2,
    );
    final line = tester.widget<Text>(find.text(text.toUpperCase()));

    expect((line.maxLines, line.overflow), (2, TextOverflow.ellipsis));
    expect(line.semanticsLabel, text);
  });

  libraryTest('the footer hint takes at most two lines, glyph on the first', (
    tester,
    env,
  ) async {
    const text = 'Swipe left for next, right to look back · nothing is graded here';
    await pumpLibraryScreen(
      tester,
      env,
      _host(const SessionFooterHintWidget(icon: AppIcons.check, text: text)),
      textScale: 2,
    );

    expect(tester.widget<Text>(find.text(text)).maxLines, 2);
    expect(
      tester.widget<Row>(find.descendant(
        of: find.byType(SessionFooterHintWidget),
        matching: find.byType(Row),
      )).crossAxisAlignment,
      CrossAxisAlignment.start,
    );
  });
```

Add a third test for Fill, where the keyboard is up during the turn:

```dart
  libraryTest('the footer hint steps aside while the keyboard is up (Fill)', (
    tester,
    env,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await pumpLibraryScreen(
      tester,
      env,
      _host(const SessionFooterHintWidget(icon: AppIcons.edit, text: 'Type the term')),
    );

    expect(find.text('Type the term'), findsNothing);
  });
```

- [ ] **Step 2:** Run. Expected: FAIL (`maxLines` null; `crossAxisAlignment` center; the hint is still shown with the keyboard up).
- [ ] **Step 3: Implement.**
  - Context line: `maxLines: 2, overflow: TextOverflow.ellipsis`. The `semanticsLabel` stays the full text. Doc line: `/// Two lines at most: at large text it would take the face's room (audit P1).`
  - Footer hint: set the `Text` to `maxLines: 2, overflow: TextOverflow.ellipsis` and give it `semanticsLabel: text`. Set the `Row` to `crossAxisAlignment: CrossAxisAlignment.start`.
  - Footer hint while typing: at the top of `build`, `if (MediaQuery.viewInsetsOf(context).bottom > 0) return const SizedBox.shrink();`. Doc line: `/// While the keyboard is up (Fill) the rule steps aside so the input and its faces keep the height (audit P1, screen 20).`
- [ ] **Step 4:** Run `flutter test --exclude-tags golden test/features/study`. Expected: pass.
- [ ] **Step 5:** Commit: `git commit -m "fix(study): session context line and hint stay within two lines"`.

---

### Task 8: Goldens, golden review, gate

- [ ] **Step 1:** Run `TZ=UTC flutter test --tags golden --update-goldens` in the renderer validated in Task 0.
- [ ] **Step 2:** List the changed PNGs with `git status --short -- '*.png'`. Expected families:
  - reminder (large text);
  - card editor (with the new keyboard goldens);
  - tags, study home, progress (2-line titles where names are long);
  - search/trash empty and error;
  - study options;
  - study faces at large text and Browse.

  Any other family is a regression: investigate it with `systematic-debugging`.
- [ ] **Step 3:** Run the gate: `dart format --set-exit-if-changed lib test && flutter analyze && python3 .claude/skills/flutter-workflow/scripts/check_generated.py && bash .claude/skills/flutter-workflow/scripts/dod_check.sh && TZ=UTC flutter test --tags golden`. Expected: all exit 0.
- [ ] **Step 4:** Commit the PNGs: `git commit -m "test(golden): regenerate after the audit P1 robustness fixes"`.
- [ ] **Step 5:** **REQUIRED SUB-SKILL: golden-compare.** Build the page with `--base "$(git merge-base origin/master HEAD)"`, write each `why` from the diffs (family keys: `keyboard`, `large-text`, `names`, `gaps`, `study`), render, publish, and put the link in the reply asking the owner to review.
- [ ] **Step 6:** Update the spec's status line. Add at its top: `**Status:** P1 (patterns 1, 2, 4, 6, study chrome, MxSettingsRow large text) fixed by plan 2026-09-29-ui-audit-p1-robustness; density items open.` Commit, then push.
