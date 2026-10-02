# Critique 2026-09-30 part 3c-1: Study home, Study entry, Session summary — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build spec 3c-1: the Study home workload card, the Study entry overline and direction note, and a Session summary that states each number once, explains wrong turns and sits centred.

**Architecture:** Presentation-only changes in `lib/features/study/presentation/` and two shared widgets (`MxAppBar`, `MxStatTile`), plus ARB copy. No domain or data change.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, ARB l10n (`flutter gen-l10n`), widget and golden tests.

**Spec:** `docs/superpowers/specs/2026-09-30-critique-fixes-part3c1-design.md`

## Global Constraints

- Authority: BR/UC > DESIGN.md > detail file (ADR-019). BR-MODE-017 keeps the direction lock stated; BR-STUDY-068 keeps the 13 block's content (Due total, overdue · today).
- No layout change beyond what an item names.
- Every user-facing string in `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`; `flutter gen-l10n` after ARB edits; `@key` lists `placeholders` before `description`; a key no widget reads is deleted from both.
- Straight apostrophes in en strings. Section headers and overlines render upper-cased; tests find `label.toUpperCase()`.
- Goldens are regenerated only in the last task.

## Review Focus

- **21, learning where answered ≠ learned:** the Answered tile shows (Task 4 test with learned 4, answered 9).
- **21, wrong = 0:** "0 of 23" shows and the explanation line does not (Task 4 test).
- **21, long content (large text):** the summary still scrolls from the top and nothing is clipped (Task 5 test at text scale 2).
- **App bar with a leading control:** keeps the content density's 8 dp start (Task 1 test).
- **Stat value at 360 dp with "241 of 241":** one line, no overflow error (Task 1 test).

---

### Task 1: Shared — an app bar without leading starts on the gutter; a stat value keeps one line

**Files:**
- Modify: `lib/shared/widgets/mx_app_bar.dart:50-64`, `lib/shared/widgets/mx_stat_tile.dart:42-50`
- Test: `test/shared/widgets/mx_app_bar_test.dart`, `test/shared/widgets/mx_stat_tile_test.dart`

**Interfaces:**
- Produces: `MxAppBar` start padding = `AppSpacing.gutter` when `leading == null`, else the density's side; `MxStatTile` value in `FittedBox(fit: BoxFit.scaleDown)` with `maxLines: 1`.

- [ ] **Step 1: Failing tests.** In `mx_app_bar_test.dart` add

```dart
  testWidgets('a content bar without a leading control starts its title on '
      'the gutter (critique 2026-09-30 part 3c-1)', (tester) async {
    await pumpMx(
      tester,
      const MxAppBar(title: 'Session summary', density: MxAppBarDensity.content),
    );
    expect(tester.getTopLeft(find.text('Session summary')).dx, AppSpacing.gutter);
  });

  testWidgets('with a leading control the content bar keeps its 8 start', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Words',
        density: MxAppBarDensity.content,
        leading: MxIconButton(icon: AppIcons.back, semanticLabel: 'Back', onPressed: () {}),
      ),
    );
    expect(
      tester.getTopLeft(find.byType(MxIconButton)).dx,
      AppSpacing.control,
    );
  });
```

In `mx_stat_tile_test.dart` add

```dart
  testWidgets('a long value keeps one line in a narrow column (critique '
      '2026-09-30 part 3c-1)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 96,
        child: MxStatTile(value: '241 of 241', label: 'Wrong turns'),
      ),
    );
    final value = tester.widget<Text>(find.text('241 of 241'));
    expect(value.maxLines, 1);
    expect(find.ancestor(of: find.text('241 of 241'), matching: find.byType(FittedBox)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```

(Use the imports and `pumpMx` helper each file already has; add `app_spacing.dart`, `app_icons.dart`, `mx_icon_button.dart` imports as needed.)

- [ ] **Step 2:** `flutter test --exclude-tags golden test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_stat_tile_test.dart` → the gutter and one-line tests FAIL.
- [ ] **Step 3: Implement.** `mx_app_bar.dart`: `start: leading == null ? AppSpacing.gutter : side,` with a comment "A bar without a leading control starts its title on the gutter, in line with the body (critique 2026-09-30 part 3c-1)". `mx_stat_tile.dart`: wrap the value `Text` as `FittedBox(fit: BoxFit.scaleDown, alignment: isBoxed ? AlignmentDirectional.centerStart : Alignment.center, child: Text(value, maxLines: 1, style: styles.statValue(ink)))`, doc line "The value keeps one line and scales down in a narrow column".
- [ ] **Step 4:** Run → PASS; then `flutter test --exclude-tags golden test/shared` → PASS.
- [ ] **Step 5: Commit** `fix(shared): a bar without leading starts on the gutter; a stat value keeps one line`.

### Task 2: 13 — the workload block is a summary card

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_home_workload_widget.dart:14-16,36-37`
- Test: `test/features/study/presentation/study_home_screen_test.dart`

- [ ] **Step 1: Failing test.** In the loaded test of `study_home_screen_test.dart` (the one that finds `studyHomeDueTitle`), add

```dart
    // A summary, not a door: no hero ground (critique 2026-09-30 part 3c-1,
    // R2; DESIGN.md: a hero leads somewhere tappable).
    final block = tester.widget<MxCard>(
      find.ancestor(
        of: find.text(_en.studyHomeDueTitle(10)),
        matching: find.byType(MxCard),
      ).first,
    );
    expect(block.isHero, isFalse);
```

(Use the due count that test's fixture produces.)
- [ ] **Step 2:** Run → FAIL (`isHero` true).
- [ ] **Step 3:** Drop `isHero: true`; class doc: "A summary card, not a hero: sessions start per deck, so it leads nowhere (critique 2026-09-30 part 3c-1)".
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/study/presentation/study_home_screen_test.dart test/features/study/presentation/study_home_workload_ink_test.dart` → PASS.
- [ ] **Step 5: Commit** `fix(study): Study home's workload is a summary card, not a hero`.

### Task 3: 14 — overline and limit line; the direction note leads with the lock

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart:30-42`, `lib/features/study/presentation/widgets/overlays/study_direction_sheet_widget.dart:65-86`, `lib/l10n/app_en.arb` (`studyEntryOverline` → `studyEntryLimit`; `studyDirectionNote`), `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/study_entry_screen_test.dart`, `test/features/study/presentation/study_entry_actions_test.dart:87`, `test/features/deck/presentation/deck_algorithm_screen_test.dart:347`

**Interfaces:**
- Produces: ARB `studyEntryLimit` "Up to {limit} cards per session" (vi "Tối đa {limit} thẻ mỗi phiên"); `studyEntryOverline` deleted.

- [ ] **Step 1: Failing tests.**
  - `study_entry_screen_test.dart`, in the eight-box loaded test: `expect(find.text(_en.studyScheduler(SchedulerType.eightBox).toUpperCase()), findsOneWidget); expect(find.text(_en.studyEntryLimit(20)), findsOneWidget);` (use that test's limit).
  - `deck_algorithm_screen_test.dart:347`: replace `_en.studyEntryOverline('SM-2', 20)` with the two finds: the scheduler name upper-cased and `_en.studyEntryLimit(20)`; read the surrounding test to keep its intent.
  - `study_entry_actions_test.dart:87`: after finding the note, assert it sits above the first option: `expect(tester.getTopLeft(find.text(_en.studyDirectionNote)).dy, lessThan(tester.getTopLeft(find.text(_en.studyDirectionTermFirst)).dy));` and `expect(_en.studyDirectionNote, startsWith("The direction can't change"));`.
- [ ] **Step 2:** Run the three files → FAIL.
- [ ] **Step 3: Implement.**
  - ARB en: `"studyEntryLimit": "Up to {limit} cards per session"` with `placeholders.limit` int and description "Screen 14: the plain line under the hero's overline, which names the algorithm alone (critique 2026-09-30 part 3c-1, R5)." Delete `studyEntryOverline`. vi `"Tối đa {limit} thẻ mỗi phiên"`.
  - `studyDirectionNote` en: "The direction can't change once the session starts. SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy." vi: "Không thể đổi chiều hỏi khi phiên đã bắt đầu. SM-2 có một chế độ ôn: mở đáp án rồi tự chấm lại · khó · tốt · dễ."
  - Hero: `final algorithm = l10n.studyScheduler(entry.schedulerType);` then `Column(spacing: AppSpacing.micro, children: [Text(algorithm.toUpperCase(), semanticsLabel: algorithm, style: styles.overline), Text(l10n.studyEntryLimit(entry.cardLimit), style: styles.rowDescription)])` in place of the single overline `Text` (keep the stat row below). Comment: "The algorithm alone as overline, the limit its own line: no orphan word (critique 2026-09-30 part 3c-1, R5)".
  - Sheet: move the `Padding(MxNote)` to be the first child of the `Column`, padding `fromLTRB(gutter, micro, gutter, grouped)`.
  - `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/study test/features/deck/presentation/deck_algorithm_screen_test.dart` → PASS.
- [ ] **Step 5: Commit** `fix(study): the entry hero names its algorithm and its limit apart; the direction note leads with the lock`.

### Task 4: 21 — tiles state what the body does not; wrong turns explained; schedulerChanged copy

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_hero_widget.dart:~84-88,~177-215`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/session_summary_test.dart:40-110,130-145`

**Interfaces:**
- Produces: ARB `summaryWrongExplained` "Wrong cards came back in later rounds." (vi "Thẻ sai quay lại ở các vòng sau."); `summarySchedulerChangedBody` reworded. `summaryStatReviewed` and `summaryStatLearned` are deleted if no widget reads them after this task (check `grep -rn` first; the facts widget may still read them).

- [ ] **Step 1: Failing tests.**
  - First test (line 40): the expected tiles become `[(_en.summaryStatWrong, _en.summaryWrongOf(3, 23))]`, then `expect(find.text(_en.summaryWrongExplained), findsOneWidget);`. Rename the test "…the body states the count; the one tile is wrong turns, explained (critique 2026-09-30 part 3c-1, R3)".
  - Left-early learning test (line 85, learned 4, answered 9): add `expect([for (final t in tester.widgetList<MxStatTile>(find.byType(MxStatTile))) t.label], [_en.summaryStatAnswered, _en.summaryStatWrong]);`.
  - New test: a finished learning session with `learnedCardCount: 12, answeredCardCount: 12, wrongTurnCount: 0, turnCount: 12` → tiles `[summaryStatWrong]` with value `_en.summaryWrongOf(0, 12)`, and `find.text(_en.summaryWrongExplained)` findsNothing.
  - The schedulerChanged test (line 130): `expect(find.text(_en.summarySchedulerChangedBody), findsOneWidget); expect(_en.summarySchedulerChangedBody, contains('Done takes you back to the deck'));`.
- [ ] **Step 2:** Run the file → FAIL.
- [ ] **Step 3: Implement.**
  - `_Stats`: build the tile list: `if (summary.answeredCardCount != finished) MxStatTile(value: studyCount(answered), label: summaryStatAnswered)`, then the wrong tile; each in `Expanded`; `crossAxisAlignment: CrossAxisAlignment.start` stays. Under the `Row`, when `summary.wrongTurnCount > 0`, a `Text(l10n.summaryWrongExplained, textAlign: TextAlign.center, style: styles.emptyBody)` after `SizedBox(height: AppSpacing.micro)` — return a `Column` from `_Stats`. Doc: "What the body does not state: answered only when it differs from the finished count, and wrong turns with their meaning (critique 2026-09-30 part 3c-1, R3)."
  - ARB en `summaryWrongExplained` with description "Screen 21: under the wrong-turns tile when wrong > 0; the facts card that explained it is hidden whenever the hero has stats (critique 2026-09-30 part 3c-1)." vi as above.
  - `summarySchedulerChangedBody` en: "The deck switched to a different review algorithm, so its learning sequence changed. Every card is new again; Done takes you back to the deck to start learning." vi: "Bộ thẻ đã chuyển sang thuật toán ôn tập khác nên chuỗi học đã thay đổi. Mọi thẻ lại là thẻ mới; Done đưa bạn về bộ thẻ để bắt đầu học." (use vi's word for the Done button: read `summaryDone` in `app_vi.arb` and use it in place of "Done").
  - Delete unused stat keys per the grep. `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/study` → PASS.
- [ ] **Step 5: Commit** `fix(study): the summary's tiles state what the body does not, and wrong turns say what they mean`.

### Task 5: 21 — a short summary sits centred

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart:~47-68`
- Test: `test/features/study/presentation/session_summary_test.dart`

- [ ] **Step 1: Failing tests.** Add

```dart
  libraryTest('a short summary sits centred above the footer (critique '
      '2026-09-30 part 3c-1, R4)', (tester, env) async {
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);
    final hero = tester.getRect(find.byType(SessionSummaryHeroWidget));
    final bar = tester.getRect(find.byType(MxAppBar));
    final footer = tester.getRect(find.byType(MxFooterBar));
    final spaceCentre = (bar.bottom + footer.top) / 2;
    expect((hero.center.dy - spaceCentre).abs(), lessThan(AppSpacing.gutter));
  });

  libraryTest('a long summary still scrolls from the top', (tester, env) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);
    final hero = tester.getRect(find.byType(SessionSummaryHeroWidget));
    final bar = tester.getRect(find.byType(MxAppBar));
    expect(hero.top - bar.bottom, lessThan(AppSpacing.section));
    expect(tester.takeException(), isNull);
  });
```

(Add imports for the hero widget, `MxAppBar`, `MxFooterBar`, `AppSpacing`. If the harness has its own text-scale helper, use it instead.)
- [ ] **Step 2:** Run → the centred test FAILS (hero near the top).
- [ ] **Step 3: Implement.** Replace `MxScreenScroll` with a local `_CentredScroll` in the same file: `LayoutBuilder` → `SingleChildScrollView(padding: EdgeInsetsDirectional.only(start: AppSpacing.gutter, end: AppSpacing.gutter, bottom: AppSpacing.section + MediaQuery.paddingOf(context).bottom), child: ConstrainedBox(constraints: BoxConstraints(minHeight: max(0, constraints.maxHeight - AppSpacing.section - bottomInset)), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: children)))`. Doc: "The summary's one moment: centred when it fits, scrolled from the top when it does not (critique 2026-09-30 part 3c-1, R4). One caller, so it lives here." Keep the children list as it is.
- [ ] **Step 4:** `flutter test --exclude-tags golden test/features/study` → PASS.
- [ ] **Step 5: Commit** `fix(study): a short session summary sits centred`.

### Task 6: Records

**Files:**
- Modify: `DESIGN.md` (MxStatTile, MxAppBar lines), `docs/shared/ui/screen-handoff/{13-study-home,14-study-entry,21-session-summary}.md`, `docs/wbs_FE.md`

- [ ] **Step 1: DESIGN.md.** In the components list: `MxStatTile` "(its value keeps one line and scales down in a narrow column)"; `MxAppBar` "(a bar without a leading control starts its title on the gutter)". Cite critique 2026-09-30 part 3c-1.
- [ ] **Step 2: Detail files.** 13: the workload block is a summary card, not a hero (R2). 14: overline = algorithm; the limit line; the direction note first, lock first; Copy section. 21: the app bar row (content density, title on the gutter; fix the table's "screen density"), the Hero row's tiles per R3 with the explanation line, the centred layout (R4), the schedulerChanged copy, and a Rulings line "Critique 2026-09-30 part 3c-1 amends FE-A6 D17: a tile states only what the body does not".
- [ ] **Step 3: WBS.** Row FE-D11 "Critique 2026-09-30 phần 3c-1: Study home, Study entry, Session summary (…)" status "đang làm", dependency FE-D10, links. `python3 tools/docs/generate.py`, `python3 tools/docs/check.py` → PASS.
- [ ] **Step 4: Commit** `docs: record critique part 3c-1`.

### Task 7: Goldens, gates, review

- [ ] **Step 1:** `flutter test --tags golden` (no update); expected failures: `study_home_*` with the workload block (loaded, sync_*, no_resume), `study_entry_*` (hero overline and limit; `study_entry_direction_sheet`), `summary_*` (all states with the app bar; stats states change tiles and centring), any golden with a content app bar without leading (list them and confirm each has no leading), `mx_stat_tile` and the gallery if they picture a stat tile or such a bar. Anything else is a regression: stop and debug.
- [ ] **Step 2:** `flutter test --tags golden --update-goldens`; view four changed goldens (summary review, summary learning, study home loaded, study entry eight box); commit `test(goldens): regenerate for critique part 3c-1`.
- [ ] **Step 3: Gates.** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`, `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`, full `TZ=UTC flutter test --exclude-tags golden`.
- [ ] **Step 4:** Golden review page with `golden-compare` (base = this plan's commit), `why` in Vietnamese.
- [ ] **Step 5:** Whole-branch review of this part's range (most capable model), one fix pass, then finishing-a-development-branch.
