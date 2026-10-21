# Study Minimal UI + Progressive Disclosure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Screens 13 and 14 show only what the decision needs: the deck's name plus an ⓘ that opens a "Deck location" sheet, fewer weights, one warning, a quiet empty state and a folded hero.

**Architecture:**
- Two shared feature widgets, `StudySessionTitleWidget` (name, line, ⓘ) and `StudyDeckLocationSheet`, replace `StudyDeckPathWidget`. Screen 13's Resume card and screen 14's banner use them.
- One predicate on `StudyEntryOffer` decides both the note and the caption's lead.
- `MxEmptyState` gets its spacing fix and an opt-in quiet title at the shared owner.
- No data, rule or colour changes.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6, Riverpod, gen-l10n ARB (en, vi), flutter_test with goldens.

**Spec:** `docs/superpowers/specs/2026-10-21-study-minimal-progressive-disclosure-design.md` (read it; D1–D12 bind every task).

## Global Constraints

- No colour, tone or token change. No `fontWeight` outside `lib/core/theme/` (guard `no_bare_font_weight`). Text uses `context.texts.*` roles and changes only `color`.
- Roles:
  - lead line `itemTitle` (500);
  - content and metadata `body` (400), muted where secondary;
  - section labels `meta` (500, `MxListSectionHeader`);
  - key figures `figure`.
- The deck name is at most 2 lines, then an ellipsis. No parent in the card, ever (D2). Identity is the deck or session id.
- The sheet "Deck location" shows the path only: every level, no `maxLines`, scrolling (D3).
- Screen 13's paused tile shows only while the text scale is < 1.3 **and** the name, measured with `drawnTextPainter` in `itemTitle`, fits 2 lines beside it (D9).
- `MxEmptyState` action spacing:
  - the first rendered action is 24 under the text;
  - each later one is 8 under the one before;
  - no action, no gap (D10).
- Quiet title is opt-in, `itemTitle` (D11).
- ⓘ, "Open in Library" and every start are disabled while a start or a Resume runs (BR-STUDY-004).
- Session lifecycle, SRS, BR-STUDY-072/075/008 unchanged.
- Code style:
  - no `else`; early returns;
  - comments in English;
  - files ≤ 400 logical lines;
  - search with `rg`.
- One behaviour, one test: extend the test that owns the inputs; same-flow cases go in a table.
- Narrow checks per task:
  - `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <files>`;
  - `dod_check.sh --changed`;
  - `run_goldens.sh --changed --update` when a golden moves.

## Review Focus

1. **A deck name that is one long unbroken word** (Vietnamese or Korean without spaces) at 2.0 on 320 dp. Expect two lines with an ellipsis on screen, the whole name in the sheet, and no overflow. Pinned in Task 2 (the sheet) and Task 3 (the D9 table).
2. **A root-only session** (path of one level). Expect ⓘ still shown and the sheet listing the single level marked as the session's deck. Pinned in Task 2.
3. **Live flip of the note while the entry is open** (a card is trashed, so the body loses its choice). Expect the caption to gain "Ends today's session" in the same frame. Pinned in Task 5.
4. **"Open in Library" tapped twice, or while a start runs.** Expect one navigation (`go` is idempotent), and the button disabled while starting. Pinned in Task 6.
5. **Sheet open, then the session ends elsewhere.** Expect the sheet to keep its snapshot. Dismissing it shows the entry without the banner. Pinned in Task 2 (snapshot) and Task 4 (banner gone after dismiss).

---

### Task 1: `MxEmptyState` action spacing and quiet title (D10, D11)

**Files:**
- Modify: `lib/shared/widgets/mx_empty_state.dart` (constructor, fields, the title `Text` and the action block in `build`)
- Modify: `lib/app/gallery/gallery_states_section.dart` (add the four action combinations and a quiet title, compact)
- Test: `test/shared/widgets/mx_empty_state_test.dart`, `test/shared/widgets/shared_widgets_golden_test.dart`
- Docs: `DESIGN.md` (MxEmptyState entry: action spacing and the quiet title), `.claude/skills/forui-shared-widgets/` contract line if it lists `MxEmptyState` parameters (`rg -n "MxEmptyState" .claude/skills/forui-shared-widgets`)

**Interfaces:**
- Produces: `MxEmptyState({..., bool isQuiet = false})`. With `isQuiet`, the title is drawn in `context.texts.itemTitle` instead of `sectionTitle`.

- [ ] **Step 1: Write the failing tests**

Add to `test/shared/widgets/mx_empty_state_test.dart`:

```dart
  // Owner 2026-10-21 (D10): the first action drawn sits 24 under the text,
  // whatever its tone; the next 8 under it; no action, no gap.
  for (final (name, primary, secondary, firstLabel) in [
    ('primary', 'Create deck', null, 'Create deck'),
    ('secondary', null, 'Open in Library', 'Open in Library'),
    ('primary and secondary', 'Create deck', 'Open in Library', 'Create deck'),
  ]) {
    testWidgets('the first action ($name) sits 24 under the text, the next '
        '8 under it', (tester) async {
      await pumpMx(
        tester,
        MxEmptyState(
          icon: AppIcons.inbox,
          title: 'No cards yet',
          body: 'Add or import cards.',
          isCompact: true,
          actionLabel: primary,
          onAction: primary == null ? null : () {},
          secondaryActionLabel: secondary,
          onSecondaryAction: secondary == null ? null : () {},
        ),
      );
      final body = tester.getRect(find.text('Add or import cards.'));
      final first = tester.getRect(find.widgetWithText(MxButton, firstLabel));
      expect(first.top - body.bottom, const AppDimens().space24);
      if (primary == null || secondary == null) return;
      final second = tester.getRect(find.widgetWithText(MxButton, secondary));
      expect(second.top - first.bottom, const AppDimens().space8);
    });
  }

  testWidgets('with no action the card ends after the text', (tester) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.inbox,
        title: 'No cards yet',
        body: 'Add or import cards.',
        isCompact: true,
      ),
    );
    expect(find.byType(MxButton), findsNothing);
    final card = tester.getRect(find.byType(MxEmptyState));
    final body = tester.getRect(find.text('Add or import cards.'));
    expect(card.bottom - body.bottom, const AppDimens().space32);
  });

  testWidgets('a quiet title is the lead role, not the headline (D11)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.inbox,
        title: 'Nothing to study in this deck',
        isCompact: true,
        isQuiet: true,
      ),
    );
    final context = tester.element(find.byType(MxEmptyState));
    final title = tester.widget<Text>(
      find.text('Nothing to study in this deck'),
    );
    expect(title.style, context.texts.itemTitle);
  });
```

- [ ] **Step 2: Run the tests and check they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_empty_state_test.dart`
Expected: compile error, because `isQuiet` is not defined. Comment out the quiet test and rerun: the 'secondary' case fails with `8.0` where `24.0` was expected.

- [ ] **Step 3: Implement**

In `mx_empty_state.dart`, add the field and the constructor parameter:

```dart
    this.isQuiet = false,
```

```dart
  /// The title in the lead role (`itemTitle`, 500) instead of the headline
  /// (`sectionTitle`, 600), for an empty state under other content on its
  /// screen (owner 2026-10-21). Opt-in: every other empty state keeps the
  /// headline.
  final bool isQuiet;
```

Then change the title style:

```dart
                        style: isQuiet
                            ? context.texts.itemTitle
                            : context.texts.sectionTitle,
```

Replace the three action `if` blocks with one list:

```dart
              // The first action drawn sits 24 under the text, whatever its
              // tone; each next one 8 under it (owner 2026-10-21).
              if (_actions(context) case final actions
                  when actions.isNotEmpty) ...[
                SizedBox(height: context.dimens.space24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: context.dimens.space8,
                  children: actions,
                ),
              ],
```

```dart
  List<Widget> _actions(BuildContext context) => [
    if ((actionLabel, onAction) case (final label?, final onPressed?))
      MxButton(label: label, onPressed: onPressed, isBlock: true),
    if (secondaryActionLabel case final label?)
      MxButton(
        label: label,
        tone: MxButtonTone.secondary,
        onPressed: onSecondaryAction,
        isBlock: true,
      ),
    if ((tertiaryActionLabel, onTertiaryAction) case (
      final label?,
      final onPressed?,
    ))
      MxButton(
        label: label,
        tone: MxButtonTone.outline,
        onPressed: onPressed,
        isBlock: true,
      ),
  ];
```

- [ ] **Step 4: Run the tests and check they pass**

Run: `run_tests.sh test/shared/widgets/mx_empty_state_test.dart`. Expected: all pass.

- [ ] **Step 5: Gallery and goldens**

In `gallery_states_section.dart`, after the tone loop, add one compact `MxEmptyState` per combination (secondary only; primary and secondary) and one with `isQuiet: true`.
- Use existing gallery ARB labels where they exist (`rg -n "gallery" lib/l10n/app_en.arb`).
- Add `galleryOpenInLibrary` only if no label fits.

Add the same three widgets to `shared_widgets_golden_test.dart` as one new golden, `empty_state_actions`.

Run:
- `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --changed --update`
- then `git status --short | rg png`

Expected:
- the new golden is added;
- **no other golden changes**. No consumer renders a lone secondary today, and primary-plus-secondary keeps 24 and 8. If any other golden moves, stop and explain it before continuing.

- [ ] **Step 6: Docs and commit**

DESIGN.md, MxEmptyState entry: add "The first action drawn sits 24 under the text whatever its tone, each next one 8; `isQuiet` draws the title in `itemTitle` for an empty state under other content (opt-in)."

```bash
git add lib/shared/widgets/mx_empty_state.dart lib/app/gallery test/shared DESIGN.md lib/l10n
git commit -m "feat(shared): MxEmptyState spaces its first action 24 whatever its tone; quiet title (DEV-323)"
```

---

### Task 2: `StudySessionTitleWidget` and `StudyDeckLocationSheet` (D2, D3)

**Files:**
- Create: `lib/features/study/presentation/widgets/support/study_session_title_widget.dart`
- Create: `lib/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (keys below), then run `flutter gen-l10n`
- Test: `test/features/study/presentation/study_deck_location_test.dart` (new)

**Interfaces:**
- Produces:
  - `StudySessionTitleWidget({required List<String> path, required Widget line, required VoidCallback? onShowLocation})`. It shows `path.last`, `line` under it at `spaceRowLine`, and a trailing ⓘ (`MxIconButton`, `AppIcons.info`, label `l10n.studyDeckLocationTitle`). A null `onShowLocation` disables ⓘ.
  - `Future<void> showStudyDeckLocationSheet(BuildContext context, List<String> path)`
  - `StudyDeckLocationSheetWidget({required List<String> path})`
- ARB keys (en / vi):
  - `studyDeckLocationTitle`: "Deck location" / "Vị trí bộ thẻ"
  - `studyDeckLocationLevel`: "{name}, level {level} of {count}" / "{name}, cấp {level} trên {count}"
  - `studyDeckLocationSessionDeck`: "{name}, the session's deck, level {level} of {count}" / "{name}, bộ thẻ của phiên, cấp {level} trên {count}"
  - `level` and `count` are `int`; give each key an `@` description.

- [ ] **Step 1: Write the failing tests**

`test/features/study/presentation/study_deck_location_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_session_title_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/text_cut.dart';
import '../../../support/widget_harness.dart';

// The session's deck by its name in the card, its location one tap away
// (owner 2026-10-21, spec D2, D3).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _title(List<String> path, {VoidCallback? onShow}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 280,
    child: Builder(
      builder: (context) => StudySessionTitleWidget(
        path: path,
        line: const Text('Learning · Browse'),
        onShowLocation:
            onShow ?? () => showStudyDeckLocationSheet(context, path),
      ),
    ),
  ),
);

const _deep = [
  'Tiếng Hàn TOPIK I',
  'Từ vựng sơ cấp theo chủ đề',
  'Chủ đề gia đình và trường học',
  'Bài 12',
  'Phần một',
  'Phần hai',
  'Phần ba',
  'Phần bốn',
  'Phần năm',
  'Độngtừthườnggặptrongđờisốnghằngngàykhôngcókhoảngtrắng',
];

void main() {
  libraryTest('the card names the deck alone, two lines then an ellipsis, '
      'and reads it whole', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, _title(_deep), textScale: 2);
    final name = tester.widget<Text>(find.text(_deep.last));
    expect((name.maxLines, name.overflow), (2, TextOverflow.ellipsis));
    expect(find.text(_deep.first), findsNothing);
    expect(find.bySemanticsLabel(_deep.last), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  libraryTest('ⓘ is a 48 target named Deck location; null disables it', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _title(_deep));
    await expectAccessibleTargets(tester);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).semanticLabel,
      _en.studyDeckLocationTitle,
    );
  });

  // Every level whole, the session's deck marked, each read with its depth;
  // at 1.0, 1.3 and 2.0 in bold on 320 dp it scrolls to the last level.
  for (final textScale in [1.0, 1.3, 2.0]) {
    libraryTest('the sheet lists every level whole and scrolls (scale '
        '$textScale, bold)', (tester, env) async {
      tester.view.physicalSize = const Size(320, 800);
      final handle = tester.ensureSemantics();
      await pumpLibraryScreen(
        tester,
        env,
        _title(_deep),
        textScale: textScale,
        isBoldText: true,
      );
      tester.view.physicalSize = const Size(320, 800);
      await tester.tap(find.byType(MxIconButton));
      await tester.pumpAndSettle();

      expect(find.text(_en.studyDeckLocationTitle), findsOneWidget);
      final sheet = find.byType(StudyDeckLocationSheetWidget);
      expectNoTextCut(tester, sheet);
      await tester.scrollUntilVisible(
        find.descendant(of: sheet, matching: find.text(_deep.last)),
        200,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(
        find.bySemanticsLabel(
          _en.studyDeckLocationSessionDeck(_deep.last, 10, 10),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(_en.studyDeckLocationLevel(_deep.first, 1, 10)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  libraryTest('a root-only session lists one level, marked as the session '
      "'s deck", (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, _title(const ['Korean']));
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(_en.studyDeckLocationSessionDeck('Korean', 1, 1)),
      findsOneWidget,
    );
    handle.dispose();
  });

  // A snapshot: the sheet shows the path it opened with.
  libraryTest('the sheet keeps the path it opened with', (tester, env) async {
    var path = const ['Korean', 'Grammar', 'Lesson'];
    late StateSetter rebuild;
    await pumpLibraryScreen(
      tester,
      env,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return _title(path);
        },
      ),
    );
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    rebuild(() => path = const ['Korean', 'Grammar II', 'Lesson']);
    await tester.pumpAndSettle();
    final sheet = find.byType(StudyDeckLocationSheetWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Grammar')),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run the tests and check they fail**

Run: `run_tests.sh test/features/study/presentation/study_deck_location_test.dart`
Expected: compile errors, because the widgets do not exist yet.

- [ ] **Step 3: Implement `study_session_title_widget.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// A session's deck by its name in a card (owner 2026-10-21, spec D2): the
/// name, the [line] under it, and an ⓘ that shows where the deck sits. The
/// name is the user's own text, two lines then an ellipsis; TalkBack reads
/// it whole. The ⓘ trails the whole block, so its 48 target never pads a
/// one-line name. Screens 13 and 14 share it.
class StudySessionTitleWidget extends StatelessWidget {
  const StudySessionTitleWidget({
    super.key,
    required this.path,
    required this.line,
    required this.onShowLocation,
  });

  /// The deck's path, root first; the card shows its last level only.
  final List<String> path;

  /// The session's line under the name.
  final Widget line;

  /// Opens the Deck location sheet; null while a start runs
  /// (BR-STUDY-004).
  final VoidCallback? onShowLocation;

  static const int _nameMaxLines = 2;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.spaceRowLine,
          children: [
            Text(
              path.last,
              maxLines: _nameMaxLines,
              overflow: TextOverflow.ellipsis,
              style: context.texts.itemTitle,
            ),
            line,
          ],
        ),
      ),
      MxIconButton(
        icon: AppIcons.info,
        semanticLabel: context.l10n.studyDeckLocationTitle,
        onPressed: onShowLocation,
      ),
    ],
  );
}
```

- [ ] **Step 4: Implement `study_deck_location_sheet_widget.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

/// Where a session's deck sits (owner 2026-10-21, spec D3): every level of
/// [path], root first, each drawn whole. It shows the path the card held
/// when it opened, reads nothing and writes nothing (BR-STUDY-075).
Future<void> showStudyDeckLocationSheet(
  BuildContext context,
  List<String> path,
) => showMxBottomSheet<void>(
  context,
  builder: (_) => StudyDeckLocationSheetWidget(path: List.unmodifiable(path)),
);

class StudyDeckLocationSheetWidget extends StatelessWidget {
  const StudyDeckLocationSheetWidget({super.key, required this.path});

  /// Root first, ending with the session's deck; never empty.
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = path.length;
    return MxBottomSheet(
      title: l10n.studyDeckLocationTitle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.screenMargin),
        child: MxCard(
          isFullBleed: true,
          // The hairlines mark the levels; no indent, so ten levels keep
          // their width at a large text scale.
          child: MxDividedColumn(
            children: [
              for (final (index, name) in path.indexed)
                _Level(
                  name: name,
                  isSessionDeck: index == count - 1,
                  spoken: index == count - 1
                      ? l10n.studyDeckLocationSessionDeck(name, count, count)
                      : l10n.studyDeckLocationLevel(name, index + 1, count),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One level, drawn whole (no line cap): the levels above are quiet, the
/// session's deck is the lead.
class _Level extends StatelessWidget {
  const _Level({
    required this.name,
    required this.isSessionDeck,
    required this.spoken,
  });

  final String name;
  final bool isSessionDeck;
  final String spoken;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.dimens.space16,
      vertical: context.dimens.space12,
    ),
    child: Text(
      name,
      semanticsLabel: spoken,
      style: isSessionDeck
          ? context.texts.itemTitle
          : context.texts.body.copyWith(color: context.colors.mutedForeground),
    ),
  );
}
```

Check that `context.screenMargin` is the extension the export sheet uses: `rg -n "screenMargin" lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart`. Import that extension if it lives outside `theme_context.dart`.

- [ ] **Step 5: Add the ARB keys, then run gen-l10n and the tests**

Run:
- `flutter gen-l10n`
- `run_tests.sh test/features/study/presentation/study_deck_location_test.dart`

Expected: all pass. If the pump resets the view, the 320 dp case may need `tester.view.physicalSize` set after `pumpLibraryScreen` (the harness sets 360×800): set it, then `await tester.pump()` before tapping.

- [ ] **Step 6: Commit**

```bash
git add lib/features/study/presentation/widgets lib/l10n test/features/study/presentation/study_deck_location_test.dart
git commit -m "feat(study): the session deck by its name, its location in a sheet (DEV-323)"
```

---

### Task 3: Screen 13, the Resume card (D2, D9)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_home_resume_widget.dart` (`_Heading`)
- Test: `test/features/study/presentation/study_home_resume_test.dart`, `study_home_wrap_test.dart`, `study_home_screen_test.dart` (line ~144 expects the breadcrumb title; change it to the name)

**Interfaces:**
- Consumes: `StudySessionTitleWidget`, `showStudyDeckLocationSheet` (Task 2); `drawnTextPainter` (`lib/core/theme/app_typography.dart`); `MxIconTile.mediumBox`
- Produces: none new.

- [ ] **Step 1: Write the failing tests**

In `study_home_resume_test.dart`, replace the title tests (the ones that use `studyHomeResumeTitle`) with:

```dart
  libraryTest('the card names the deck alone with an ⓘ that opens its '
      'location; nothing is written', (tester, env) async {
    await _pump(tester, env, _session(deck: 'Words', root: 'Korean'));
    expect(find.text('Words'), findsOneWidget);
    expect(find.textContaining('›'), findsNothing);
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(find.byType(StudyDeckLocationSheetWidget), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StudyDeckLocationSheetWidget),
        matching: find.text('Korean'),
      ),
      findsOneWidget,
    );
  });

  libraryTest('while Resume runs the ⓘ is locked', (tester, env) async {
    await _pump(tester, env, _session(), isResuming: true);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).onPressed,
      isNull,
    );
  });

  // D9: the name before the decorative tile. The tile shows only under a
  // 1.3 text scale while the name, as drawn, fits two lines beside it.
  for (final (width, textScale, name, hasTile) in [
    (360.0, 1.0, 'Words', true),
    (360.0, 1.0, 'Từ vựng chủ đề gia đình và trường học cho kỳ thi TOPIK', false),
    (320.0, 1.0, 'Words', true),
    (360.0, 1.3, 'Words', false),
    (320.0, 2.0, 'Words', false),
  ]) {
    libraryTest('the paused tile at $width dp, scale $textScale, "$name": '
        '${hasTile ? 'shown' : 'gone'}; ⓘ stays; nothing overflows (bold)', (
      tester,
      env,
    ) async {
      await _pump(
        tester,
        env,
        _session(deck: name),
        width: width,
        textScale: textScale,
        isBoldText: true,
      );
      expect(find.byType(MxIconTile), hasTile ? findsOneWidget : findsNothing);
      expect(find.byType(MxIconButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
```

Extend `_pump` and `_session` in that file:
- `_pump` gets `bool isResuming = false` and `bool isBoldText = false`, forwarded to `StudyHomeResumeWidget(isResuming:)` and `pumpLibraryScreen(isBoldText:)`;
- `_session(deck:, root:)` builds `deckPath: [?root, deck]` as today.

Pick the long name in the table so that it does not fit two lines beside the tile at 360 dp and scale 1.0. If it fits, lengthen it until it does not, and keep it real Vietnamese.

- [ ] **Step 2: Run the tests and check they fail**

Run: `run_tests.sh test/features/study/presentation/study_home_resume_test.dart`
Expected: FAIL. The card still shows the path, and there is no ⓘ.

- [ ] **Step 3: Implement**

Replace `_Heading` in `study_home_resume_widget.dart`:

```dart
/// The paused tile, then the deck by its name with the session's kind and
/// mode under it and the ⓘ to its location (owner 2026-10-21, spec D2).
/// The name comes before the decorative tile (D9): the tile shows only
/// under a 1.3 text scale while the name, as drawn, fits two lines beside
/// it.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.session,
    required this.kind,
    required this.isResuming,
  });

  final ResumableSession session;
  final String kind;
  final bool isResuming;

  static const double _tileMaxTextScale = 1.3;
  static const int _nameMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = StudySessionTitleWidget(
      path: session.deckPath,
      // Short terms, laid out whole (The Wrap Rule).
      line: MxTermLine.text(
        l10n.studyEntryResumeLineNoProgress(kind, l10n.studyMode(session.mode)),
      ),
      onShowLocation: isResuming
          ? null
          : () => showStudyDeckLocationSheet(context, session.deckPath),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_hasRoomForTile(context, constraints.maxWidth)) return title;
        return Row(
          spacing: context.dimens.space12,
          children: [
            const ExcludeSemantics(
              child: MxIconTile(
                icon: AppIcons.pause,
                size: MxIconTileSize.medium,
                tone: MxIconTileTone.primary,
              ),
            ),
            Expanded(child: title),
          ],
        );
      },
    );
  }

  /// Under a 1.3 text scale, the name as drawn fits two lines in the width
  /// the tile and the ⓘ leave it.
  bool _hasRoomForTile(BuildContext context, double width) {
    if (MediaQuery.textScalerOf(context).scale(1) >= _tileMaxTextScale) {
      return false;
    }
    final dimens = context.dimens;
    final nameWidth =
        width - MxIconTile.mediumBox - dimens.space12 - dimens.sizeTarget;
    final painter = drawnTextPainter(
      context,
      session.deckPath.last,
      style: context.texts.itemTitle,
      maxLines: _nameMaxLines,
    )..layout(maxWidth: nameWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}
```

- Use the dimens slot that holds the 48 target (`rg -n "48" lib/core/theme/app_dimens.dart`, e.g. `sizeTarget` / `minTarget`); never write the literal 48.
- Pass `isResuming` from `StudyHomeResumeWidget.build`.
- Remove the `StudyDeckPathWidget` import and add imports for the new widgets and for `app_typography.dart`.

- [ ] **Step 4: Run the tests and check they pass, including the screen tests**

Run: `run_tests.sh test/features/study/presentation/study_home_resume_test.dart test/features/study/presentation/study_home_wrap_test.dart test/features/study/presentation/study_home_screen_test.dart`
- Update `study_home_screen_test.dart:144` to expect `find.text('Lesson')`.
- In `study_home_wrap_test.dart`, drop the "›" expectations for the title.

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/widgets/sections/study_home_resume_widget.dart test/features/study/presentation
git commit -m "feat(study): Study home's Resume card names the deck; the tile yields to it (DEV-323)"
```

---

### Task 4: Screen 14, the resume banner (§3.3), and the path widget removed

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_resume_widget.dart`
- Delete:
  - `lib/features/study/presentation/widgets/support/study_deck_path_widget.dart`
  - `test/features/study/presentation/study_deck_path_test.dart`
  - the ARB keys `studyHomeResumeTitle`, `studyHomeResumeTitleSpoken`, `studyEntryResumeBody` (en and vi)
- Test: `test/features/study/presentation/study_entry_other_deck_test.dart`, `study_entry_actions_test.dart`

**Interfaces:**
- Consumes: `StudySessionTitleWidget`, `showStudyDeckLocationSheet` (Task 2)
- Produces: none new.

- [ ] **Step 1: Write the failing tests**

In `study_entry_other_deck_test.dart`, replace the path assertions (`breadcrumbLine(_en.studyHomeResumeTitle(...))`) in the first test with:

```dart
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.textContaining('›'), findsNothing);
    expect(find.text(_en.studyEntryResumeBody), findsNothing);
    final line = find.byWidgetPredicate(
      (widget) => widget is MxTermLine && widget.role == MxTermLineRole.body,
    );
    expect(line, findsOneWidget);
    await tester.tap(find.byType(MxIconButton).last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StudyDeckLocationSheetWidget),
        matching: find.text('Korean'),
      ),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
```

- Delete `studyEntryResumeBody` from that first expectation once the key is removed (Step 4), and keep `findsNothing` on a literal `'Continue where you stopped.'`.
- Replace the two long-path tests (the ones using `breadcrumbLine`) with one test: a deck named by the long Vietnamese name at scales 1.0 and 1.3 shows `maxLines: 2` with an ellipsis and no exception.
- Add this test:

```dart
  // Two decks of one name: identity is the session id, never the name.
  libraryTest('two decks of one name: Continue opens the session, wherever '
      'its namesake is', (tester, env) async {
    final a = await env.decks.root('Korean', SchedulerType.sm2);
    final aLesson = await env.decks.sub(a.id, 'Lesson');
    final b = await env.decks.root('Japanese', SchedulerType.sm2);
    final bLesson = await env.decks.sub(b.id, 'Lesson');
    await insertCard(env.db, id: 'a0', deckId: aLesson.id);
    await insertCard(env.db, id: 'b0', deckId: bLesson.id);
    final opened = await env.entries.openLearningSession(deckId: aLesson.id);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    String? continued;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(bLesson.id, onOpen: (id) => continued = id),
    );
    await tester.tap(_button(_en.studyEntryContinue));
    await tester.pumpAndSettle();
    expect(continued, sessionId);
  });
```

- Add a this-deck case: the banner of this deck's session draws its line as `MxTermLineRole.itemTitle`, has no `MxIconButton` inside `StudyEntryResumeWidget`, and Continue sits `space16` under the track:

```dart
    final banner = find.byType(StudyEntryResumeWidget);
    expect(
      find.descendant(of: banner, matching: find.byType(MxIconButton)),
      findsNothing,
    );
    final track = tester.getRect(
      find.descendant(of: banner, matching: find.byType(MxLinearProgress)),
    );
    final cta = tester.getRect(_button(_en.studyEntryContinue));
    expect(cta.top - track.bottom, const AppDimens().space16);
```

  Put this in the existing `study_entry_actions_test.dart` test "today's open session shows the resume banner; …".

- [ ] **Step 2: Run the tests and check they fail**

Run: `run_tests.sh test/features/study/presentation/study_entry_other_deck_test.dart test/features/study/presentation/study_entry_actions_test.dart`
Expected: FAIL. The path is still drawn, and the body line is still there.

- [ ] **Step 3: Implement the banner**

In `study_entry_resume_widget.dart`, replace everything from the `SizedBox(height: context.dimens.space8)` after the overline down to the Continue button:

```dart
          SizedBox(height: context.dimens.space8),
          // The card's lead line is itemTitle: another deck's name leads, or
          // on this deck the session line (owner 2026-10-21, spec §3.3).
          if (isOnThisDeck)
            MxTermLine.text(
              sessionLine,
              role: MxTermLineRole.itemTitle,
              tone: MxTermTone.foreground,
            ),
          if (!isOnThisDeck)
            StudySessionTitleWidget(
              path: session.deckPath,
              line: MxTermLine.text(sessionLine),
              onShowLocation: isLocked
                  ? null
                  : () => showStudyDeckLocationSheet(context, session.deckPath),
            ),
          if (progress != null && progress.total > 0) ...[
            SizedBox(height: context.dimens.space8),
            MxLinearProgress(value: progress.completed / progress.total),
          ],
          // Content to the closing action is 16 (spacing spec L8).
          SizedBox(height: context.dimens.space16),
          MxButton(
            label: l10n.studyEntryContinue,
            icon: AppIcons.play,
            isBlock: true,
            onPressed: isLocked ? null : onContinue,
          ),
```

Compute `sessionLine` before the `return`:

```dart
    final sessionLine = progress == null
        ? l10n.studyEntryResumeLineNoProgress(kind, mode)
        : l10n.studyEntryResumeLine(
            kind,
            mode,
            progress.completed,
            progress.total,
          );
```

Update the class doc ("names it by its path" becomes "names it, its location one tap away").

- [ ] **Step 4: Remove the path widget and its keys**

- `git rm lib/features/study/presentation/widgets/support/study_deck_path_widget.dart test/features/study/presentation/study_deck_path_test.dart`
- Delete `studyHomeResumeTitle`, `studyHomeResumeTitleSpoken` and `studyEntryResumeBody`, with their `@` entries, from `app_en.arb`, and the same keys from `app_vi.arb`.
- Run `flutter gen-l10n`.
- Run `rg -n "studyHomeResumeTitle|studyEntryResumeBody|StudyDeckPathWidget|breadcrumbLine\(" lib test integration_test` and fix every hit. `breadcrumbLine` stays in `meta_line.dart` only if another caller remains; if none does, delete it and its test.

- [ ] **Step 5: Run the study tests**

Run: `run_tests.sh test/features/study`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add -A lib/features/study lib/l10n test/features/study lib/l10n/meta_line.dart
git commit -m "feat(study): the entry's banner names another deck's session; the path widget goes (DEV-323)"
```

---

### Task 5: One predicate for the note and the caption's lead (§3.4)

**Files:**
- Modify: `lib/features/study/presentation/states/study_entry_offer_state.dart` (add `isOtherSessionNoteShown`)
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart` (read it; move `_minModesToChoose` into the offer state)
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart` (the lead rule, the failed footer)
- Test: `test/features/study/presentation/study_entry_offer_state_test.dart`, `study_entry_actions_test.dart`

**Interfaces:**
- Produces: `StudyEntryOffer.isOtherSessionNoteShown` (bool), which is true when `canContinue` and the body offers a choice. A choice means `newCardCount > 0`, or `dueCardCount > 0 && reviews.length >= 2`. Also `StudyEntryOffer.isEndsSessionCaption` (bool): `canContinue && !isOtherSessionNoteShown`.

- [ ] **Step 1: Write the failing tests**

In `study_entry_offer_state_test.dart`, add a table test. First extend `_entry` to take `bool hasSession = false`; it then builds a `ResumableSession` with `sessionId: 's'`, `deckId: 'd'`, `deckPath: ['D']`, `kind: SessionKind.learning`, `mode: StudyMode.browse`, `progress: null`.

```dart
  // Spec §3.4: the note under "Or start another session" is the one full
  // warning; the caption leads with "Ends today's session" exactly when it
  // is not shown and a session can be continued.
  for (final (name, entry, note, lead) in [
    ('no session', _entry(fresh: 3, due: 2), false, false),
    ('learn beside a session', _entry(fresh: 3, due: 0, hasSession: true), true, false),
    ('sm2 due only beside a session', _entry(type: SchedulerType.sm2, fresh: 0, due: 2, hasSession: true), false, true),
    ('eight boxes, one mode, due only', _entry(fresh: 0, due: 2, reviews: [_mode(StudyMode.guess)], hasSession: true), false, true),
    ('eight boxes, two modes, due only', _entry(fresh: 0, due: 2, reviews: [_mode(StudyMode.guess), _mode(StudyMode.match)], hasSession: true), true, false),
  ]) {
    test('$name: note $note, caption lead $lead', () {
      final offer = studyEntryOfferOf(entry);
      expect(
        (offer.isOtherSessionNoteShown, offer.isEndsSessionCaption),
        (note, lead),
      );
    });
  }
```

In `study_entry_actions_test.dart`:
- Change the test "eight boxes beside an open session: the caption leads with …": with several modes the note shows, so the caption no longer leads. Assert `findTermLine(_en.studyEntryEndsSession, isContaining: true)` finds nothing, and that the caption holds the mode term.
- The "SM-2 with due cards alone beside an open session" test keeps its lead, unchanged.
- Add a failed-footer case to the existing failed-start test that sits beside a session with SM-2 due only:

```dart
    expect(
      findTermLine(_en.studyEntryEndsSession, isContaining: true),
      findsOneWidget,
      reason: 'Try again ends the session too, and no note says so',
    );
```

- Add the live flip (Review Focus 3): start beside a session with Eight boxes and two modes, where the note shows. Then trash cards until one mode is left (`env.cards.deleteCards`), `pumpAndSettle`, and check that the note is gone and the caption leads.

- [ ] **Step 2: Run the tests and check they fail**

Run: `run_tests.sh test/features/study/presentation/study_entry_offer_state_test.dart test/features/study/presentation/study_entry_actions_test.dart`
Expected: compile error (no `isOtherSessionNoteShown`), then failures on the caption.

- [ ] **Step 3: Implement**

In `study_entry_offer_state.dart`, add the fields and compute them:

```dart
  /// The body offers another start beside a session that can be continued:
  /// the section "Or start another session" and its note show, the one full
  /// warning that a start ends it (spec §3.4, BR-STUDY-072).
  final bool isOtherSessionNoteShown;

  /// The footer's caption leads with "Ends today's session": a session can
  /// be continued and no note says what a start does (spec §3.4).
  final bool isEndsSessionCaption;
```

```dart
/// A review list is shown only when there is a choice (BR-STUDY-055).
const int minModesToChoose = 2;
```

```dart
  final hasChoices =
      entry.newCardCount > 0 ||
      (entry.dueCardCount > 0 && reviews.length >= minModesToChoose);
  final canContinue = entry.resumable != null;
  final isNoteShown = canContinue && hasChoices;
```

Pass `canContinue: canContinue`, `isOtherSessionNoteShown: isNoteShown`, and `isEndsSessionCaption: canContinue && !isNoteShown`.

In `study_entry_body_widget.dart`:
- Use `offer.isOtherSessionNoteShown` for the section and the note.
- Use the shared `minModesToChoose` for `hasReviews`.
- Delete the private `_minModesToChoose`.

In `study_entry_footer_widget.dart`:
- Compute the offer before the `failed` branch.
- Replace the lead:

```dart
    // One warning: the note when it shows, else the caption's lead (spec
    // §3.4, BR-STUDY-072).
    final ends = offer.isEndsSessionCaption ? l10n.studyEntryEndsSession : null;
```

- In the `failed` branch, set `caption: ends` on the `MxFooterBar`.
- In the Learn branch, set the caption to `ends ?? (entry.dueCardCount == 0 ? l10n.studyEntryNothingDueCaption : null)`. This expression is unchanged, but `ends` is now null whenever the note shows.

- [ ] **Step 4: Run the tests and check they pass**

Run: `run_tests.sh test/features/study`. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation test/features/study/presentation
git commit -m "fix(study): one place says a start ends today's session (DEV-323)"
```

---

### Task 6: Hero at 0 and 0, quiet nothing states, "Open in Library" (§3.5, §3.6)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart` (`_NothingDue`, `onOpenInLibrary`)
- Modify: `lib/features/study/presentation/screens/study_entry_screen.dart` (`onOpenInLibrary` parameter, passed to the body)
- Modify: `lib/app/router/study_route_screens.dart` (wire it to `context.go(AppRoutes.deck(deckId))`)
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb`: `studyEntryOpenInLibrary` "Open in Library" / "Mở trong Thư viện" (check the vi word for Library: `rg -n '"library\w*": "Thư viện' lib/l10n/app_vi.arb`)
- Test: `test/features/study/presentation/study_entry_screen_test.dart`, and `test/app/` route test if one covers study_route_screens (`rg -ln "studyEntryScreen\(" test`)

**Interfaces:**
- Produces: `StudyEntryScreen({..., VoidCallback? onOpenInLibrary})` and `StudyEntryBodyWidget({..., VoidCallback? onOpenInLibrary})`.

- [ ] **Step 1: Write the failing tests**

Extend the test in `study_entry_screen_test.dart`, "nothing new and nothing due is the calm empty state, and it follows the cards: …". Give `_screen` an `onOpenInLibrary` parameter that appends to a list `library`.

```dart
    // Resting cards: the hero is the algorithm alone (spec D5), the title is
    // quiet (D11), no action (D7).
    expect(find.byType(MxStatTile), findsNothing);
    expect(find.text(_en.studyEntryLimit(20)), findsNothing);
    expect(
      tester.widget<MxEmptyState>(find.byType(MxEmptyState)).isQuiet,
      isTrue,
    );
    expect(find.text(_en.studyEntryOpenInLibrary), findsNothing);
```

and after the trash:

```dart
    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryOpenInLibrary));
    await tester.tap(find.widgetWithText(MxButton, _en.studyEntryOpenInLibrary));
    await tester.pumpAndSettle();
    expect(library, [root.id, root.id]);
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.studyEntryOpenInLibrary),
          )
          .tone,
      MxButtonTone.secondary,
    );
```

Two taps call it twice; the app's `go` makes the second a no-op, and Task 6 Step 3 says so in the doc. Then the existing "a card arrives" step checks that the tiles return: `expect(find.byType(MxStatTile), findsNWidgets(2))`.

Add a test that "Open in Library" is disabled while a start runs. Use the `FailingEntries.gate` pattern from `study_entry_actions_test.dart`: an empty deck beside another deck's session, then a start gated open. Because the empty deck has nothing to start, use Continue on the banner as the start.

```dart
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.studyEntryOpenInLibrary),
          )
          .onPressed,
      isNull,
    );
```

Place that test in `study_entry_other_deck_test.dart`.

- [ ] **Step 2: Run the tests and check they fail**

Run: `run_tests.sh test/features/study/presentation/study_entry_screen_test.dart test/features/study/presentation/study_entry_other_deck_test.dart`
Expected: FAIL. The tiles still show, `isQuiet` is false, and there is no action.

- [ ] **Step 3: Implement**

In `study_entry_hero_widget.dart`:
- With `entry.newCardCount == 0 && entry.dueCardCount == 0`, return the `MxCard` holding only the algorithm overline `Text`.
- Otherwise keep today's build.
- Put the early return at the top of `build`, after `algorithm`.

```dart
    // At 0 and 0 the empty state below says it; the hero keeps the
    // algorithm alone (owner 2026-10-21, spec D5).
    if (entry.newCardCount == 0 && entry.dueCardCount == 0) {
      return MxCard(child: _Algorithm(name: algorithm));
    }
```

Extract the overline `Text` into `_Algorithm` and use it in both builds.

In `study_entry_body_widget.dart`:
- Pass `onOpenInLibrary: start.isStarting ? null : onOpenInLibrary` and `isEmpty` into `_NothingDue`.
- `_NothingDue` sets `isQuiet: true` and, only when `isEmpty`, `secondaryActionLabel: context.l10n.studyEntryOpenInLibrary` and `onSecondaryAction: onOpenInLibrary`.

```dart
class _NothingDue extends StatelessWidget {
  const _NothingDue({required this.isEmpty, required this.onOpenInLibrary});

  /// The deck and its subtree hold no live card.
  final bool isEmpty;

  /// Opens this deck in the Library, where cards are added (spec D7); null
  /// while a start runs (BR-STUDY-004).
  final VoidCallback? onOpenInLibrary;

  @override
  Widget build(BuildContext context) => MxEmptyState(
    icon: AppIcons.learned,
    title: isEmpty
        ? context.l10n.studyEntryNoCardsTitle
        : context.l10n.studyEntryNothingInDeckTitle,
    body: isEmpty
        ? context.l10n.studyEntryNoCardsBody
        : context.l10n.studyEntryNothingBody,
    tone: MxEmptyStateTone.success,
    isCompact: true,
    isQuiet: true,
    secondaryActionLabel: isEmpty
        ? context.l10n.studyEntryOpenInLibrary
        : null,
    onSecondaryAction: isEmpty ? onOpenInLibrary : null,
  );
}
```

`MxEmptyState` asserts `onSecondaryAction == null || secondaryActionLabel != null`, and that holds.

In `study_entry_screen.dart`, add:

```dart
  /// Opens this deck in the Library, where cards are added or imported
  /// (spec D7); composed by `app/`. Null hides the action.
  final VoidCallback? onOpenInLibrary;
```

Pass it to `StudyEntryBodyWidget`. In `study_route_screens.dart`:

```dart
      // Screen 14 is the deck route's child: one level up the same stack,
      // and a second tap goes nowhere new.
      onOpenInLibrary: () => context.go(AppRoutes.deck(deckId)),
```

- [ ] **Step 4: Run the tests and check they pass**

Run: `run_tests.sh test/features/study test/app`. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat(study): a quiet nothing state, the hero folds at 0 and 0, Open in Library (DEV-323)"
```

---

### Task 7: Docs, goldens, gate

**Files:**
- `docs/features/study/rules/BR-STUDY-072-phien-do-khi-mo-app.md`: replace "MUST nêu deck của phiên bằng đường dẫn đầy đủ … tối đa hai dòng …" with "MUST nêu tên deck của phiên (tối đa hai dòng), đường dẫn đầy đủ xem qua nút ⓘ (sheet Vị trí bộ thẻ); định danh là id, không dựa vào tên".
- `docs/shared/ui/screen-handoff/13-study-home.md`:
  - Layout row "Resume card": name + ⓘ, and D9 on the tile;
  - the loaded and resumeLargeText rows;
  - new Transitions rows: ⓘ → sheet → dismiss; ⓘ locked while resuming;
  - Rulings: owner 2026-10-21 (spec D2, D3, D9) supersedes the full path;
  - Accessibility: ⓘ label, focus order;
  - Copy: drop the "{root} › … › {deck}" line, add "Deck location".
- `docs/shared/ui/screen-handoff/14-study-entry.md`:
  - Layout rows: Resume banner, Hero (0/0), Nothing-due state (quiet title, Open in Library), Footer caption rule;
  - States rows: resume, nothing, nothingEmpty, nothing beside another deck's session;
  - Transitions: ⓘ → sheet; Open in Library → Library level (session untouched; disabled while starting); note flip ↔ caption lead; sheet snapshot;
  - Rulings: replace "Owner 2026-10-21 (hierarchy)" with "the card's lead line is itemTitle"; record the same-name risk (D2);
  - Copy.
- `docs/shared/ui/screen-handoff/00-index.md`: state counts, if they change.
- `python tools/docs/generate.py`

- [ ] **Step 1: Write the docs above.**

- [ ] **Step 2: Re-render goldens**

Run:
- `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --changed --update`
- `git status --short | rg png`

Expected: the goldens the spec §7 lists, plus the new sheet golden. Add it to `study_entry_actions_golden_test.dart` as 'study entry, deck location sheet': the root's entry beside the deep session, ⓘ tapped, light and dark. Also add the `MxEmptyState` gallery golden from Task 1. Read each changed PNG. An unexplained change is a regression: go to systematic-debugging.

- [ ] **Step 3: Full gate**

Run:
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
- then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`

Expected: "mechanical gates passed", and all goldens pass.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "docs(study): 13 and 14 name the deck, its location on demand; goldens (DEV-323)"
```

- [ ] **Step 5: Review and hand-off** (not code)
  - Run an Impeccable audit of every changed state of 13 and 14 and of the sheet. Fix its findings in one batch.
  - Then the final whole-branch review on Opus.
  - Then build the golden-compare page and ask the owner (AskUserQuestion) to approve the PR.
