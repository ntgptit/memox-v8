# Library alignment phase B — foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pieces phases C–E compose, so later screens change only presentation:
- the search field as a tappable trigger, and an app bar that holds a widget in its title slot;
- card list items that carry their tags and a due label;
- a card list view that carries the count of each display state.

The phase also corrects the spec where #33 or the existing theme already settled a decision.

**Architecture:**
- **Shared widgets.** `MxSearchField` gains a `trigger` constructor. `MxAppBar` gains a `titleWidget` slot.
- **Domain.** The card domain gains `CardDue`, derived from `learned_at`, `due_at` and the start of the local day. It reuses the calendar-day count of `DeckScheduleStatus`.
- **Data.** The card list read keeps its window and counts, and adds the tags of the window's cards (one statement) and the schedule rows of the deck (one statement, classified in Dart by `CardDisplayStatus.of`, the one definition of a display state). The stream is driven by the table updates of `card`, `card_schedule`, `card_tags` and `tags`, so tagging a card re-emits the list.
- **No new colour token.** The spec's A10 "mastery ink" is the existing `statusMasteredInk`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3 codegen, Drift 2.35, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` (§2 A10, A12, A13, A15, A16; §5; §6; §9 phase B).

## Global Constraints

- **Scope:**
  - `lib/shared/widgets/mx_search_field.dart`, `lib/shared/widgets/mx_app_bar.dart`, `lib/app/gallery/gallery_inputs_section.dart`;
  - `lib/features/card/domain/models/`, `lib/features/card/data/`;
  - their tests and docs.
  - No screen under `lib/features/*/presentation/` changes. The one presentation test that builds a `CardListView` by hand gains the new field.
- **Import map:** `card → {deck, srs, tags}` (domain models, entities, failures, di). `card` data may import `srs` and `tags` domain. Nothing imports `app/`.
- **No schema change and no migration.** If a read needs one, stop and report (spec §5).
- **The UI derives no count.** Every count and label comes from the read model (Library spec §1).
- **Gate:**
  - `dart format --set-exit-if-changed lib test`;
  - `flutter analyze` → "No issues found!";
  - `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` → 0 errors, 0 warnings;
  - `python3 .claude/skills/flutter-architecture/scripts/check_architecture.py`;
  - `flutter test`;
  - `python3 tools/docs/check.py`;
  - `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- **Codegen:** after pulling or editing `@riverpod` or `.drift` files, run `dart run build_runner build --delete-conflicting-outputs`.
- **Messages in `tools/` are English.** The docs and wbs files keep their language.
- **Commit trailer:**
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PJDjKsfDm9reH3a8cML75G
  ```

## Review Focus

- **A tag is added to or removed from a card while the list is open.** Expected: the list emits once more with the new tags, and the counts are unchanged (Task 5 test "tagging a card re-emits the list with its tags").
- **The window is empty (a deck with no cards, or a search that matches nothing).** Expected: no tag statement runs, the view has no items, and the status counts still count the whole deck (Task 5 test "an empty window reads no tags").
- **A card is due at a day boundary: due today at midnight, due tomorrow, overdue since yesterday.** Expected: "today", "later 1" and "overdue 1", counted on calendar dates (Task 4 tests).
- **A search or filter is active.** Expected: the status counts ignore both and describe the whole deck (Task 5 test "the status counts ignore the search and the filter").
- **The trigger field is tapped.** Expected: `onTap` runs once, no keyboard opens, nothing takes focus, and TalkBack reads a button named by the hint (Task 2 tests).

---

### Task 1: Correct the spec and the handoff after #33 and the theme check

**Files:**
- Modify: `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` (§2 rows A10 and A16, §4.2 "Reset" step 3, §4.4 FAB row and empty row, §6 theme row, §9 row B)
- Modify: `docs/shared/ui/screen-handoff/02-review-algorithm.md` (states row `resetConfirm`, deviations row "Kept")
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md` (layout row FAB, states row `empty`, deviations row "Add first card")
- Modify: `docs/shared/ui/screen-handoff/00-index.md` (status legend; rows 08 and 09)

**Interfaces:**
- Produces: the corrected decisions that Tasks 2–5 and phases C–E follow.

- [ ] **Step 1: Correct A10 and A16**

In the spec §2 table, replace the A10 row with:

```markdown
| A10 | The "Kept" label of the reset dialog uses `statusMasteredInk`. `statusMastered` equals `mastery` in both themes, and that ink is already pinned at ≥ 4.5:1 on every ground and on its own tint (`mx_derived_colors_test`). No new token. |
```

Replace the A16 row with:

```markdown
| A16 | Superseded by #33 (Library phase 4a): the card list's "New card" FAB and the unset deck's "New card" exist, and phases C–E keep them. The card detail (phase 4b) stays outside this project. |
```

- [ ] **Step 2: Follow the corrections through the spec**

- §4.2 "Reset" step 3: replace `**Kept** (mastery ink, A10)` with `**Kept** (\`statusMasteredInk\`, A10)`.
- §4.4 layout table, FAB row: replace `None until Library phase 4 (A16).` with `"New card", as #33 built it (A16); hidden while selecting.`
- §4.4 states table, `empty` row: replace `"Add first card" waits for phase 4 (A16).` with `"Add first card" opens the #33 editor (A16).`
- §6 table: delete the row whose first cell is `Theme`.
- §9 row B: replace `\`MxAppBar\` title slot, mastery ink token; the card status counts` with `\`MxAppBar\` title slot; the card status counts`.

- [ ] **Step 3: Follow them through the handoff files**

`02-review-algorithm.md`:
- states row `resetConfirm`: replace `"Kept" in the mastery ink token (spec A10)` with `"Kept" in \`statusMasteredInk\` (spec A10)`;
- deviations: replace the row `| "Kept" coloured with the mastery token | The mastery ink token, 4.5:1 | Spec A10, WCAG 2.2 AA |` with `| "Kept" coloured with the mastery token | \`statusMasteredInk\`, 4.5:1 | Spec A10, WCAG 2.2 AA |`.

`07-card-list.md`:
- layout row FAB: replace `| FAB | — | None until Library phase 4 (spec A16). |` with `| FAB | \`MxFab\` | "New card" (#33); hidden while selecting. |`;
- states row `empty`: replace `No "Add first card" (phase 4); "Import cards" disabled.` with `"Add first card" opens the editor (#33); "Import cards" disabled.`;
- deviations: delete the row whose first cell is `"Add first card", "New card" FAB`.

`00-index.md`:
- in "Status values", after the `not built` line, add: `- **built:** built from the artifact before its detail file exists; its deviations are in the UI-base debt register.`;
- rows 08 and 09: replace the status `not built` with `built`, and the detail cell `—` with `— (#33; UI-base §9 rows 79–84)`.

- [ ] **Step 4: Run the docs check**

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), 69 warning(s)`.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md docs/shared/ui/screen-handoff
git commit -m "docs(spec): align A10 and A16 with the theme and #33" -m "<trailer>"
```

---

### Task 2: `MxSearchField.trigger`

**Files:**
- Modify: `lib/shared/widgets/mx_search_field.dart`
- Modify: `lib/app/gallery/gallery_inputs_section.dart` (one entry after the existing `MxSearchField`)
- Test: `test/shared/widgets/mx_search_field_test.dart`

**Interfaces:**
- Produces: `const MxSearchField.trigger({Key? key, required String hintText, required VoidCallback onTap})`. The default constructor is unchanged for callers. Phase C uses the trigger on the Library root.

- [ ] **Step 1: Write the failing tests**

Append to `mx_search_field_test.dart`, inside `main()`:

```dart
  group('trigger', () {
    Future<void> pumpTrigger(WidgetTester tester, VoidCallback onTap) =>
        pumpMx(
          tester,
          SizedBox(
            width: 328,
            child: MxSearchField.trigger(
              hintText: 'Search decks',
              onTap: onTap,
            ),
          ),
        );

    testWidgets('looks like the resting field: 52 tall, resting fill, hint', (
      tester,
    ) async {
      await pumpTrigger(tester, () {});
      final field = tester.widget<TextField>(find.byType(TextField));

      expect(tester.getSize(find.byType(TextField)).height, 52);
      expect(field.decoration!.fillColor, scheme.surfaceContainer);
      expect(find.text('Search decks'), findsOneWidget);
    });

    testWidgets('a tap calls onTap once and takes no focus', (tester) async {
      var taps = 0;
      await pumpTrigger(tester, () => taps++);

      await tester.tap(find.byType(MxSearchField));
      await tester.pump();

      expect(taps, 1);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
        isFalse,
      );
    });

    testWidgets('reads as a button named by the hint, with no clear button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTrigger(tester, () {});

      expect(
        tester.getSemantics(find.byType(MxSearchField)),
        containsSemantics(
          label: 'Search decks',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(find.byType(MxIconButton), findsNothing);
      semantics.dispose();
    });
  });
```

Add `import 'package:memox/shared/widgets/mx_icon_button.dart';` to the imports if it is not there.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/widgets/mx_search_field_test.dart`
Expected: compile error, `MxSearchField.trigger` is not defined.

- [ ] **Step 3: Implement the trigger**

In `mx_search_field.dart`:

1. Make the fields nullable and add `onTap`:

```dart
  final TextEditingController? controller;
  final String hintText;

  /// The clear button's accessible name.
  final String? clearLabel;

  /// Also called with '' when the query is cleared.
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  /// Set by [MxSearchField.trigger]: the field stands for a search that
  /// opens elsewhere.
  final VoidCallback? onTap;
```

2. Keep the default constructor's contract with typed initializing formals, and add the trigger:

```dart
  const MxSearchField({
    super.key,
    required TextEditingController this.controller,
    required this.hintText,
    required String this.clearLabel,
    this.onChanged,
    this.focusNode,
  }) : onTap = null;

  /// A read-only field that opens the search elsewhere (screen 01's root
  /// search). It takes no focus, never shows a clear button, and reads as a
  /// button named by [hintText].
  const MxSearchField.trigger({
    super.key,
    required this.hintText,
    required VoidCallback this.onTap,
  }) : controller = null,
       clearLabel = null,
       onChanged = null,
       focusNode = null;
```

3. In the state, own a controller when none is given, and use `_controller` everywhere `widget.controller` was used:

```dart
  FocusNode? _ownFocusNode;
  TextEditingController? _ownController;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
```

In `initState`, `didUpdateWidget`, `dispose` and `_clear`, replace `widget.controller` with `_controller`, and in `didUpdateWidget` compare `oldWidget.controller != widget.controller` and move the listener from `oldWidget.controller ?? _ownController` to `_controller`. In `dispose`, add `_ownController?.dispose();`.

4. In `build`, pass `controller: _controller`, and use `widget.clearLabel!` in the clear button. The clear button only shows with a query, which a trigger never has. Then wrap the field when it is a trigger. Rename the returned `TextField(...)` to `final field = TextField(...);` and end `build` with:

```dart
    final onTap = widget.onTap;
    if (onTap == null) return field;
    return Semantics(
      button: true,
      label: widget.hintText,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: IgnorePointer(child: field),
      ),
    );
```

Also set `readOnly: widget.onTap != null,` on the `TextField`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_search_field_test.dart`
Expected: PASS, the existing tests and the 3 new ones.

- [ ] **Step 5: Add the gallery entry**

In `gallery_inputs_section.dart`, directly after the existing `MxSearchField(...)` child, add:

```dart
      MxSearchField.trigger(hintText: 'Search decks', onTap: () {}),
```

Run: `flutter test test/app/gallery_test.dart test/shared/widgets/input_widgets_golden_test.dart`
Expected: PASS.

- [ ] **Step 6: Gate slice and commit**

```bash
dart format lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets/mx_search_field.dart lib/app/gallery/gallery_inputs_section.dart test/shared/widgets/mx_search_field_test.dart
git commit -m "feat(ui): MxSearchField.trigger, a search field that opens the search elsewhere" -m "<trailer>"
```

Expected: format clean, "No issues found!", guard 0/0.

---

### Task 3: `MxAppBar.titleWidget`

**Files:**
- Modify: `lib/shared/widgets/mx_app_bar.dart`
- Modify: `lib/app/gallery/gallery_inputs_section.dart` (one entry after the Task 2 entry)
- Test: `test/shared/widgets/mx_app_bar_test.dart`

**Interfaces:**
- Produces: `MxAppBar({Key? key, String? title, Widget? titleWidget, MxAppBarDensity density, Widget? leading, List<Widget> actions})`, with exactly one of `title` or `titleWidget` (asserted). Phase C puts `MxSearchField` there on screen 04.

- [ ] **Step 1: Write the failing tests**

Append to `mx_app_bar_test.dart`, inside `main()`:

```dart
  testWidgets('a title widget takes the title slot between leading and actions', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
        titleWidget: const SizedBox(key: Key('slot'), height: 40),
        actions: [
          MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
        ],
      ),
    );
    final slot = tester.getRect(find.byKey(const Key('slot')));
    final back = tester.getRect(find.byTooltip('Back'));
    final more = tester.getRect(find.byTooltip('More'));

    expect(slot.left, greaterThanOrEqualTo(back.right));
    expect(slot.right, lessThanOrEqualTo(more.left));
    expect(slot.width, greaterThan(200));
  });

  test('takes a title or a title widget, not both and not neither', () {
    expect(
      () => MxAppBar(title: 'Library', titleWidget: const SizedBox()),
      throwsAssertionError,
    );
    expect(MxAppBar.new, throwsAssertionError);
  });
```

`pumpMx` lays the widget out at the harness's phone width, 360 or more, so the slot is wider than 200.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/shared/widgets/mx_app_bar_test.dart`
Expected: compile error, no named parameter `titleWidget`.

- [ ] **Step 3: Implement the slot**

In `mx_app_bar.dart`, replace the constructor and the `title` field with:

```dart
  const MxAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.density = MxAppBarDensity.screen,
    this.leading,
    this.actions = const [],
  }) : assert(
         (title == null) != (titleWidget == null),
         'MxAppBar takes a title or a titleWidget, not both',
       );

  final String? title;

  /// Takes the title's place and its width, such as the search field of
  /// screen 04. It brings its own semantics; no header flag is added.
  final Widget? titleWidget;
```

In `build`, replace the `Expanded` child with:

```dart
                Expanded(
                  child:
                      titleWidget ??
                      Semantics(
                        header: true,
                        child: Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isContent
                              ? styles.contentTitle
                              : styles.screenTitle,
                        ),
                      ),
                ),
```

`MxAppBar.new` with no arguments hits the assert (`null != null` is false). It is torn off in the test so that no const expression evaluates it at compile time.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_app_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Add the gallery entry**

In `gallery_inputs_section.dart`, after the Task 2 entry, add:

```dart
      MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
        titleWidget: MxSearchField(
          controller: _search,
          hintText: 'Search decks',
          clearLabel: 'Clear search',
        ),
      ),
```

Add the imports `package:memox/shared/widgets/mx_app_bar.dart`, `package:memox/shared/widgets/mx_icon_button.dart` and `package:memox/core/theme/foundations/app_icons.dart` if missing.

The gallery's first search field and this one share the `_search` controller. That is harmless in a debug gallery, and it keeps the section free of a second controller to dispose.

Run: `flutter test test/app/gallery_test.dart`
Expected: PASS.

- [ ] **Step 6: Gate slice and commit**

```bash
dart format lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets/mx_app_bar.dart lib/app/gallery/gallery_inputs_section.dart test/shared/widgets/mx_app_bar_test.dart
git commit -m "feat(ui): MxAppBar.titleWidget for a search field in the app bar" -m "<trailer>"
```

---

### Task 4: `CardDue`

**Files:**
- Create: `lib/features/card/domain/models/card_due_model.dart`
- Test: `test/features/card/domain/card_due_model_test.dart`

**Interfaces:**
- Consumes: `DeckScheduleStatus.overdueDays(DateTime? from, DateTime startOfToday)` (`lib/features/deck/domain/models/deck_schedule_status_model.dart`).
- Produces:
  - `enum CardDueKind { newCard, overdue, today, later }`;
  - `final class CardDue { CardDueKind kind; int days; factory CardDue.of({required bool isLearned, required DateTime? dueAt, required DateTime startOfToday}); }` with value equality.
  - Task 5 puts it on `CardListItem.due`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';

// The start of the local day the list reads at (BR-STUDY-068).
final _today = DateTime(2026, 9, 23);

CardDue _due(DateTime? dueAt, {bool isLearned = true}) =>
    CardDue.of(isLearned: isLearned, dueAt: dueAt, startOfToday: _today);

void main() {
  test('a card not learned yet is new, whatever its due date', () {
    expect(_due(null, isLearned: false).kind, CardDueKind.newCard);
    expect(_due(DateTime(2026, 9, 1), isLearned: false).kind, CardDueKind.newCard);
  });

  test('due at the start of today, or later today, is today', () {
    expect(_due(DateTime(2026, 9, 23)), const CardDue.today());
    expect(_due(DateTime(2026, 9, 23, 18)), const CardDue.today());
  });

  test('due before today is overdue by calendar days', () {
    expect(_due(DateTime(2026, 9, 22)), const CardDue.overdue(1));
    expect(_due(DateTime(2026, 9, 20)), const CardDue.overdue(3));
  });

  test('due after today is later by calendar days', () {
    expect(_due(DateTime(2026, 9, 24)), const CardDue.later(1));
    expect(_due(DateTime(2026, 10, 10)), const CardDue.later(17));
  });

  test('a learned card without a due date reads as new', () {
    expect(_due(null).kind, CardDueKind.newCard);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/domain/card_due_model_test.dart`
Expected: compile error, the file does not exist.

- [ ] **Step 3: Implement**

```dart
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';

/// Which way a card's next review lies from today.
enum CardDueKind { newCard, overdue, today, later }

/// When a card comes back, as its row in the card list says it (screen 07):
/// "New", "Due today", "In N d", "N d overdue". Derived on read, never
/// stored; days are counted on calendar dates, like a deck's overdue run
/// (BR-STUDY-067).
final class CardDue {
  const CardDue._(this.kind, this.days);

  const CardDue.newCard() : this._(CardDueKind.newCard, 0);
  const CardDue.today() : this._(CardDueKind.today, 0);
  const CardDue.overdue(int days) : this._(CardDueKind.overdue, days);
  const CardDue.later(int days) : this._(CardDueKind.later, days);

  /// [isLearned] is `learned_at` set (BR-CARD-007); [startOfToday] is the
  /// start of the local day the list reads at.
  factory CardDue.of({
    required bool isLearned,
    required DateTime? dueAt,
    required DateTime startOfToday,
  }) {
    if (!isLearned || dueAt == null) return const CardDue.newCard();
    if (dueAt.isBefore(startOfToday)) {
      return CardDue.overdue(
        DeckScheduleStatus.overdueDays(dueAt, startOfToday),
      );
    }
    // The same calendar count, from today forward to the due date.
    final ahead = DeckScheduleStatus.overdueDays(startOfToday, dueAt);
    return ahead == 0 ? const CardDue.today() : CardDue.later(ahead);
  }

  final CardDueKind kind;

  /// Calendar days overdue or ahead; 0 for new and today.
  final int days;

  @override
  bool operator ==(Object other) =>
      other is CardDue && other.kind == kind && other.days == days;

  @override
  int get hashCode => Object.hash(kind, days);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/domain/card_due_model_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test
flutter analyze
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add lib/features/card/domain/models/card_due_model.dart test/features/card/domain/card_due_model_test.dart
git commit -m "feat(card): CardDue, when a card comes back as its row says it" -m "<trailer>"
```

---

### Task 5: The card list read carries tags, due labels and status counts

**Files:**
- Modify: `lib/features/card/domain/models/card_list_view_model.dart`
- Modify: `lib/features/card/data/datasources/card_list_dao.dart`
- Modify: `lib/features/card/data/mappers/card_mapper.dart`
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart` (`watchCardList`)
- Modify: `lib/features/card/domain/repositories/card_repository.dart` (the `watchCardList` doc comment)
- Test: `test/features/card/data/card_list_read_test.dart`
- Test: `test/features/card/presentation/card_list_section_test.dart` (the hand-built `CardListView` around line 286)

**Interfaces:**
- Consumes: `CardDue.of` (Task 4); `startOfLocalDay` (`lib/features/srs/domain/models/due_date_model.dart`); `CardDisplayStatus.of`, `scheduleStateOf`; `TagEntity` (`lib/features/tags/domain/entities/tag_entity.dart`).
- Produces:
  - `CardListItem` gains `final CardDue due;` and `final List<TagEntity> tags;`, sorted by folded name, then id (BR-TAG-001).
  - `final class CardStatusCounts { int newCards, beginning, reviewing, mastered; int get total; }`.
  - `CardListView` gains `final CardStatusCounts statusCounts;`, covering the whole deck and ignoring search and filter.
  - DAO:
    - `Future<List<(CardRow, CardSchedule)>> window({deckId, query, limit, now})` replaces `watchWindow`;
    - `Future<List<CardSchedule>> activeSchedules(String deckId)`;
    - `Future<Map<String, List<Tag>>> tagsOf(List<String> cardIds)`;
    - `Stream<void> changes()`.
  - Phase E reads these fields.

- [ ] **Step 1: Write the failing tests**

In `card_list_read_test.dart`, add `import 'package:memox/features/card/domain/models/card_due_model.dart';`, keep a `late TagRepositoryImpl tags;` beside `cards`, and in `setUp` create it once and pass it to `CardRepositoryImpl`:

```dart
    tags = TagRepositoryImpl(db, now: clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock),
      tags,
      now: clock,
    );
```

Replace the test `an emission is two statements, the window and the counts, and a change emits once` with:

```dart
  test('an emission is four statements, whatever the window holds, and a change emits once', () async {
    counter.selects = 0;
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: const CardListQuery(),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();
    // The window, the filter counts, the deck's schedules, the window's tags.
    expect((views.length, counter.selects), (1, 4));

    await insertCard(db, id: 'another', deckId: mixed.id);
    await pumpEventQueue();

    expect((views.length, counter.selects), (2, 8));
    expect(views.last.counts.all, 5);
    await subscription.cancel();
  });
```

Add these tests:

```dart
  test('each item carries its due label, counted from the start of today', () async {
    final view = await list();
    final due = {for (final item in view.items) item.id: item.due};

    expect(due, {
      'new': const CardDue.newCard(),
      'begin': const CardDue.today(),
      'review': const CardDue.overdue(1),
      'master': const CardDue.later(30),
    });
  });

  test('each item carries its tags, by folded name', () async {
    await tags.attachByName(cardIds: {'begin'}, name: 'verb');
    await tags.attachByName(cardIds: {'begin'}, name: 'Adjective');

    final view = await list();
    final begin = view.items.firstWhere((item) => item.id == 'begin');
    final others = view.items.where((item) => item.id != 'begin');

    expect([for (final tag in begin.tags) tag.name], ['Adjective', 'verb']);
    expect(others.every((item) => item.tags.isEmpty), isTrue);
  });

  test('tagging a card re-emits the list with its tags', () async {
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: const CardListQuery(),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();

    await tags.attachByName(cardIds: {'new'}, name: 'verb');
    await pumpEventQueue();

    expect(views, hasLength(2));
    final tagged = views.last.items.firstWhere((item) => item.id == 'new');
    expect([for (final tag in tagged.tags) tag.name], ['verb']);
    expect(views.last.counts.all, 4);
    await subscription.cancel();
  });

  test('the status counts cover the deck: one card in each display state', () async {
    final view = await list();

    expect(
      (
        view.statusCounts.newCards,
        view.statusCounts.beginning,
        view.statusCounts.reviewing,
        view.statusCounts.mastered,
        view.statusCounts.total,
      ),
      (1, 1, 1, 1, 4),
    );
  });

  test('the status counts ignore the search and the filter', () async {
    final view = await list(
      query: const CardListQuery(
        filter: CardListFilter.flagged,
        searchTerm: 'benevolent',
      ),
    );

    expect(view.items, hasLength(1));
    expect(view.statusCounts.total, 4);
  });

  test('an empty window reads no tags', () async {
    counter.selects = 0;
    final view = await list(query: const CardListQuery(searchTerm: 'zzz'));

    expect(view.items, isEmpty);
    expect(view.statusCounts.total, 4);
    expect(counter.selects, 3);
  });
```

The fixture's `master` card is due 2026-10-23 and the list reads on 2026-09-23, which is 30 calendar days ahead. The `review` card was due 2026-09-22: overdue 1. The `begin` card is due 2026-09-23: today.

In `card_list_section_test.dart`, add `statusCounts` to the hand-built view:

```dart
      const CardListView(
        items: [],
        hasMore: false,
        counts: CardListCounts(all: 0, due: 0, newCards: 0, flagged: 0),
        statusCounts: CardStatusCounts(
          newCards: 0,
          beginning: 0,
          reviewing: 0,
          mastered: 0,
        ),
      ),
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card/data/card_list_read_test.dart`
Expected: compile errors: `due`, `tags`, `statusCounts` and `CardStatusCounts` are not defined.

- [ ] **Step 3: Extend the models**

In `card_list_view_model.dart`, add the imports `card_due_model.dart` and `package:memox/features/tags/domain/entities/tag_entity.dart`. Then:

- `CardListItem`: add `required this.due, required this.tags,` to the constructor, with the fields:

```dart
  /// When the card comes back, from its schedule and the list's day.
  final CardDue due;

  /// Its tags, by folded name then id (BR-TAG-001).
  final List<TagEntity> tags;
```

- Add after `CardListCounts`:

```dart
/// How many of the deck's active cards show each display state
/// (BR-CARD-008, BR-SRS-013), whatever the search and the filter: the deck's
/// progress, not the list's.
final class CardStatusCounts {
  const CardStatusCounts({
    required this.newCards,
    required this.beginning,
    required this.reviewing,
    required this.mastered,
  });

  final int newCards;
  final int beginning;
  final int reviewing;
  final int mastered;

  int get total => newCards + beginning + reviewing + mastered;
}
```

- `CardListView`: add `required this.statusCounts,` and `final CardStatusCounts statusCounts;`.

- [ ] **Step 4: Extend the DAO**

In `card_list_dao.dart`:

- Replace `watchWindow` with a one-shot read of the same query:

```dart
  /// Up to [limit] cards with their schedule rows, in [query]'s order.
  Future<List<(CardRow, CardSchedule)>> window({
    required String deckId,
    required CardListQuery query,
    required int limit,
    required DateTime now,
  }) async {
    final select =
        _db.select(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..where(_predicate(deckId: deckId, query: query, now: now))
          ..orderBy(_order(query.sort))
          ..limit(limit);
    return [
      for (final row in await select.get())
        (row.readTable(_card), row.readTable(_schedule)),
    ];
  }
```

- Add, after `ids`:

```dart
  /// The schedule rows of every active card of [deckId], outside any search
  /// or filter, for the display-state counts (BR-CARD-008).
  Future<List<CardSchedule>> activeSchedules(String deckId) {
    final select = _db.select(_schedule).join([
      innerJoin(_card, _card.id.equalsExp(_schedule.cardId)),
    ])..where(_card.deckId.equals(deckId) & _card.deleteBatchId.isNull());
    return select.map((row) => row.readTable(_schedule)).get();
  }

  /// The tags of [cardIds] in one statement, each card's by folded name then
  /// id (BR-TAG-001). No statement for no card.
  Future<Map<String, List<Tag>>> tagsOf(List<String> cardIds) async {
    if (cardIds.isEmpty) return const {};
    final links = _db.cardTags;
    final tags = _db.tags;
    final select =
        _db.select(links).join([
            innerJoin(tags, tags.id.equalsExp(links.tagId)),
          ])
          ..where(links.cardId.isIn(cardIds))
          ..orderBy([OrderingTerm.asc(tags.nameFolded), OrderingTerm.asc(tags.id)]);
    final byCard = <String, List<Tag>>{};
    for (final row in await select.get()) {
      byCard
          .putIfAbsent(row.readTable(links).cardId, () => [])
          .add(row.readTable(tags));
    }
    return byCard;
  }

  /// Fires after every write to a table the list reads: cards, schedules,
  /// and the tags on cards. A transaction fires once.
  Stream<void> changes() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_card, _schedule, _db.cardTags, _db.tags]),
  );
```

Update the class doc's first sentence to "The card list read model (UC-CARD-001): a window, the filter counts, the deck's display states and the window's tags."

- [ ] **Step 5: Extend the mapper**

In `card_mapper.dart`, add the imports `card_due_model.dart`, `card_list_view_model.dart` (if not there) and `package:memox/features/srs/domain/models/due_date_model.dart`. Then replace `listItemOf` with:

```dart
CardListItem listItemOf(
  CardRow card,
  CardSchedule schedule, {
  required List<Tag> tags,
  required DateTime startOfToday,
}) => CardListItem(
  id: card.id,
  front: card.front,
  back: card.back,
  isFlagged: card.isFlagged == 1,
  dueAt: schedule.dueAt,
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
  due: CardDue.of(
    isLearned: schedule.learnedAt != null,
    dueAt: schedule.dueAt,
    startOfToday: startOfToday,
  ),
  tags: [for (final tag in tags) TagEntity(id: tag.id, name: tag.name)],
);

/// The display state of every schedule row, counted once each.
CardStatusCounts statusCountsOf(Iterable<CardSchedule> schedules) {
  var newCards = 0;
  var beginning = 0;
  var reviewing = 0;
  var mastered = 0;
  for (final schedule in schedules) {
    switch (CardDisplayStatus.of(scheduleStateOf(schedule))) {
      case CardDisplayStatus.newCard:
        newCards++;
      case CardDisplayStatus.beginning:
        beginning++;
      case CardDisplayStatus.reviewing:
        reviewing++;
      case CardDisplayStatus.mastered:
        mastered++;
    }
  }
  return CardStatusCounts(
    newCards: newCards,
    beginning: beginning,
    reviewing: reviewing,
    mastered: mastered,
  );
}
```

Remove the `due_date_model.dart` import from this step if the mapper does not use it. The repository passes `startOfToday`.

- [ ] **Step 6: Drive the list from table changes**

In `card_repository_impl.dart`, add `import 'package:memox/features/srs/domain/models/due_date_model.dart';` and replace `watchCardList` with:

```dart
  @override
  Stream<CardListView> watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) => _watchCardList(
    deckId: deckId,
    query: query,
    windowSize: windowSize,
    now: now,
  ).mapDatabaseErrors();

  /// Once now, then once after every write the list could see (the DAO's
  /// [CardListDao.changes]); tagging a card is such a write.
  Stream<CardListView> _watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) async* {
    Future<CardListView> read() => _readCardList(
      deckId: deckId,
      query: query,
      windowSize: windowSize,
      now: now,
    );
    yield await read();
    await for (final _ in _listDao.changes()) {
      yield await read();
    }
  }

  Future<CardListView> _readCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) async {
    final rows = await _listDao.window(
      deckId: deckId,
      query: query,
      limit: windowSize + 1,
      now: now,
    );
    final counts = await _listDao.counts(
      deckId: deckId,
      searchTerm: query.searchTerm,
      now: now,
    );
    final schedules = await _listDao.activeSchedules(deckId);
    final shown = rows.take(windowSize).toList();
    final tags = await _listDao.tagsOf([for (final (card, _) in shown) card.id]);
    final startOfToday = startOfLocalDay(now);
    return CardListView(
      items: [
        for (final (card, schedule) in shown)
          listItemOf(
            card,
            schedule,
            tags: tags[card.id] ?? const [],
            startOfToday: startOfToday,
          ),
      ],
      hasMore: rows.length > windowSize,
      counts: CardListCounts(
        all: counts.all,
        due: counts.due,
        newCards: counts.newCards,
        flagged: counts.flagged,
      ),
      statusCounts: statusCountsOf(schedules),
    );
  }
```

In `card_repository.dart`, extend the `watchCardList` doc comment with: `Each item carries its tags and due label, and the view counts the deck's display states whatever the search and filter. Emits again on every change of a card, a schedule row or a card's tags.`

- [ ] **Step 7: Run the tests to verify they pass**

Run:
```bash
flutter test test/features/card/data/card_list_read_test.dart
flutter test test/features/card
```
Expected: PASS. The first command covers the 6 new tests and the rewritten statement test; the second runs the whole card feature, including its presentation tests on the real backend.

If `tags.attachByName` returns a rejection in these tests, the fixture deck is not a deck of cards for the tag repository. Stop and read `TagRepositoryImpl.attachByName`, and do not change the assertions.

- [ ] **Step 8: Gate slice and commit**

```bash
dart format lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add lib/features/card test/features/card
git commit -m "feat(card): the card list read carries tags, due labels and display-state counts" -m "<trailer>"
```

---

### Task 6: Ledgers and the full gate

**Files:**
- Modify: `docs/wbs_BE.md` (a BE-A9 row at the end of the V8.0 table that holds BE-A1…BE-A8)
- Modify: `docs/wbs_FE.md` (the FE-A11 row's last cell)
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9, only if the gate surfaces a contradiction to record

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Record the backend item**

Append after the `| BE-A8 |` row of the V8.0 table in `docs/wbs_BE.md`, keeping that table's column count. Read the header row first and fill each column in order:

```markdown
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

If the table has a different number of columns, keep the ID, content, status, dependencies, size, evidence and next-step values, and place them under the matching headers.

- [ ] **Step 2: Move FE-A11 on**

In `docs/wbs_FE.md`, replace the last cell of the FE-A11 row, `Phase A (handoff) trong PR này; phase B sau khi merge`, with `Phase A xong (#32); phase B (nền) trong PR này; phase C sau khi merge`.

- [ ] **Step 3: Run the full gate**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test
python3 tools/docs/generate.py && python3 tools/docs/check.py
GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- format clean; "No issues found!";
- guard 0/0; architecture OK;
- `flutter test`: every non-golden test passes. Goldens fail only where they fail on `master` in this environment. On `1c00754` that is 57 goldens, because they were generated on another platform (FE-D1). Compare the failing names with that baseline; any other golden failure is this phase's;
- docs check PASS; DoD passes.

A golden that fails here but passes on `master` is this phase's to fix, most likely the gallery. Reproduce it with `flutter test test/app/app_golden_test.dart`.

**Scope check:** `git diff --stat origin/master...HEAD -- lib/features/*/presentation lib/core/database` must print nothing.

- [ ] **Step 4: Commit**

```bash
git add docs/wbs_BE.md docs/wbs_FE.md docs/_generated
git commit -m "docs(wbs): the card list read for the screen handoff (BE-A9) and FE-A11 phase B" -m "<trailer>"
```
