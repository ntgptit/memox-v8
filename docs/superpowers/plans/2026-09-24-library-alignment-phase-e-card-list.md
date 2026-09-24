# Library Alignment Phase E — Card List (Screen 07) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An open deck of cards matches screen 07 of the V3 kit: an app bar the card feature owns (search, selection), a progress summary, filters, card-shaped rows with status, tags, flag and due chip, and the kit's bulk bar.

**Architecture:**
- `DeckLevelScreen` gains a `cardAppBar` builder. Its `cardContent` builder now also receives the root's algorithm and the breadcrumb the deck built.
- `app/router` composes both from `card/presentation` (spec A14, owner decision E-O1). `deck` still never imports `card`.
- The card feature's `CardDeckAppBarWidget` switches between the deck bar (back, name, search, `⋮`) and the selection bar (close, "N selected", "Select all M").
- `CardListSectionWidget` hides the breadcrumb, search, summary and filters while selecting.
- The read model gains a deck-wide `CardWorkload` computed from the schedules the list already reads.
- New shared pieces carry every colour: the `streak` token and `streakInk`, `MxFlagMark`, `MxStatusDistribution`, `MxCard.isSelected`, `MxStatusBadge.isPlain`, and `MxUnavailable`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3 (codegen), Drift, gen-l10n (en, vi), GoRouter.

**Spec:** `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` §4.4 (A13–A16), handoff `docs/shared/ui/screen-handoff/07-card-list.md` and `img/07-card-list/`.

## Owner decisions (brainstorm and Impeccable critique, 2026-09-24)

| # | Decision |
|---|---|
| E-O1 | **The card feature builds the whole app bar of a deck of cards** through `DeckLevelScreen.cardAppBar(deckId, {title, leading, actions})`. The deck passes its back button and its `⋮`; the card feature adds search, or swaps to the selection bar. `cardContent` receives the breadcrumb so the card feature hides it while selecting. |
| E-O2 | **A `streak` token, a shared `MxFlagMark` and a shared `MxStatusDistribution`** (the four-state bar with its legend). |
| E-O3 | **Search opens from the app bar action**, as in the kit; closing it clears the term. |
| E-O4 | **`streakInk`**: the glyph colour of the flag. Light is `streak` 20% toward `onSurface` (#CA601D, ≥ 3.3:1 on every card ground); dark is `streak` itself (#FFAE6E, ≥ 9:1). The fill token keeps the kit's #F97316 / #FFAE6E. |
| E-O5 | **`MxCard.isSelected`**: a primary border around a selected card row. |

## Rulings written into this plan

| # | Ruling |
|---|---|
| E-L1 | **The summary's workload** (overdue · today · new) and its "Study this deck · N due" come from a deck-wide `CardWorkload` counted from the schedules the list read already loads (`activeSchedules`), with the same `CardDue.of` the rows use. There is no query or schema change. It is a `card` data change outside spec §5's list, recorded here. |
| E-L2 | **`DeckUnavailableWidget` (#41) moves to `lib/shared/widgets/mx_unavailable.dart` as `MxUnavailable`**, so the card feature marks its not-yet controls the same way without importing `deck`. |
| E-L3 | **While selecting**, the breadcrumb, search, summary and filters hide (the kit's selection state); the header reads "N of M selected" with no sort pill; the bulk bar is Move · Flag · Tag · Export *(unavailable)* · Delete; "Select all" lives in the app bar only. |
| E-L4 | **"Export all cards" in the deck sheet carries no count**: `DeckView` has no card count and the sheet reads only the view (C-L6). It is recorded as a Deviation. |
| E-L5 | **A deck of cards is never a root** (Task 4 ruling of phase 4a), so its sheet offers Move and never Review algorithm. Import and Export show only when `view.deck.contentType == DeckContentType.card`. |
| E-L6 | **The algorithm label on the summary** uses the card feature's own `cardSchedulerEightBox` / `cardSchedulerSm2`, as the card detail does. |

## Global Constraints

- Flutter 3.47.5 at `/root/.flutter-sdk/3.47.5/flutter/bin` (`export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH`).
- Feature import map:
  - `deck → {srs}`; `card → {deck, srs, tags}`, through the other feature's `domain/{entities,models,repositories,failures}` or its `di/` only (`test/architecture/boundaries_test.dart`);
  - `deck` never imports `card`; `app/` composes.
- The guard (`python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`) must report 0 errors and 0 warnings:
  - no `Icon(color:)`, raw Material widgets or `.copyWith` on text styles in feature presentation;
  - no literal user strings;
  - booleans read as predicates;
  - no `ref.read` in `build`.
- Every colour a feature shows comes from a shared widget or a token; a feature never paints an icon a colour.
- Copy comes from both ARB files; in each `@key`, `placeholders` come before `description`.
- WCAG 2.2 AA: text 4.5:1, meaningful non-text 3:1, 48dp targets, text scale 2 on a 360-wide phone holds.
- Goldens (C-O5): regenerate on Linux only the goldens of screens this phase changes: the card list, card selection and the gallery, plus any deck golden whose image changes. A golden run overwrites the tracked `test/**/failures/*.png`: restore them with `git checkout -- $(git diff --name-only | grep /failures/)`, delete the untracked ones, and never commit them.
- Commit trailer:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PJDjKsfDm9reH3a8cML75G
  ```

## Review Focus

- **Selecting, then leaving:** the system Back leaves selection before it leaves the deck, and the deck bar, breadcrumb and summary come back (Task 5 test "Back leaves selection, then the deck").
- **Search open, then closed:** closing clears the term and the full list returns; a filter survives it (Task 5 test "closing the search clears the term").
- **A deck with no mastered card and a deck with none at all:** the donut reads 0%, and the distribution draws no zero-width segment and never divides by zero (Task 2 and Task 6 tests).
- **Text scale 2 on a 360 phone:** the selection bar with "Select all 420" and a row with two long tags, a flag and "30d overdue" do not overflow (Task 5 and Task 7 overflow tests).
- **Disabled controls in TalkBack** (Tags chip, Export, Import, Study this deck): announced as not available yet (Task 6 and Task 8 tests).

---

### Task 1: Spec and handoff record this phase's decisions

**Files:**
- Modify: `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` (§5 and §6 tables)
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md` (Deviations)

- [ ] **Step 1:** Append to spec §5:

```markdown
| `card` domain + data | **Deck workload** (phase E, ruling E-L1): `CardListView.workload`, the overdue, today and new counts of the whole deck, counted from the schedules the list already reads with `CardDue.of`. No query or schema change. |
```

Append to spec §6:

```markdown
| Theme (phase E) | `streak` / `onStreak` semantic colours (#F97316 / #FFAE6E, #FFFFFF) and `streakInk` (light: 20% toward onSurface; dark: streak), owner decisions E-O2, E-O4. Icons `exportFile`, `importFile`. |
| `MxFlagMark` | New: the flag glyph in `streakInk` with its accessible label (E-O2). |
| `MxStatusDistribution` | New: the four display states as one stacked bar with a legend of counts (A13, E-O2). |
| `MxCard` | `isSelected`: a primary border (E-O5). |
| `MxStatusBadge` | `isPlain`: the uppercase label in its status ink, no pill (the card row's status line). |
| `MxUnavailable` | Moved from `deck` (ruling E-L2): a not-yet control announced as "Not available yet". |
```

- [ ] **Step 2:** Append to `07-card-list.md` Deviations:

```markdown
| "Export all {n} cards" in the deck sheet | "Export all cards", no count | Ruling E-L4: the sheet reads only `DeckView`, which has no card count |
| Flag in #F97316 | `streakInk` (#CA601D light) | E-O4: the kit orange reads 2.8:1 on the card, below the 3:1 non-text floor |
```

- [ ] **Step 3: Commit**

```bash
python3 tools/docs/check.py
git add docs
git commit -m "docs(library): phase E decisions for screen 07" -m "<trailer>"
```

Expected: `check.py` PASS, 69-warning baseline.

---

### Task 2: Theme and shared pieces

**Files:**
- Modify: `lib/core/theme/mx_semantic_colors.dart` (`streak`, `onStreak`)
- Modify: `lib/core/theme/mx_derived_colors.dart` (`streakInk`)
- Modify: `lib/core/theme/foundations/app_icons.dart` (`exportFile`, `importFile`)
- Create: `lib/shared/widgets/mx_flag_mark.dart`, `lib/shared/widgets/mx_status_distribution.dart`
- Create: `lib/shared/widgets/mx_unavailable.dart`; delete `lib/features/deck/presentation/widgets/support/deck_unavailable_widget.dart` and update its users
- Modify: `lib/shared/widgets/mx_card.dart` (`isSelected`), `lib/shared/widgets/mx_status_badge.dart` (`isPlain`)
- Modify: `lib/app/gallery/gallery_status_section.dart`, `gallery_surfaces_section.dart`
- Test: `test/core/theme/mx_derived_colors_test.dart`, `test/core/theme/mx_semantic_colors_test.dart` (if it exists), `test/shared/widgets/mx_flag_mark_test.dart`, `mx_status_distribution_test.dart`, `mx_card_test.dart`, `mx_status_badge_test.dart`, `mx_unavailable_test.dart` (new ones where absent)

**Interfaces:**
- Produces:
  - `MxSemanticColors.streak`, `.onStreak`; `MxDerivedColors.streakInk`;
  - `AppIcons.exportFile`, `AppIcons.importFile`;
  - `MxFlagMark({required String semanticLabel})`;
  - `MxStatusDistribution({required MxStatusCounts counts, required String Function(MxCardStatus) label})`, with `MxStatusCounts({newCards, learning, reviewing, mastered})`;
  - `MxCard({..., bool isSelected = false})`;
  - `MxStatusBadge({..., bool isPlain = false})`;
  - `MxUnavailable({required Widget child})`.

- [ ] **Step 1: Write the failing tests**

`mx_derived_colors_test.dart`:

```dart
  test('streakInk reads 3:1 as a glyph on every card ground (E-O4)', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (hi, lo) = la > lb ? (la, lb) : (lb, la);
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final (scheme, derived) in [
      (AppColorSchemes.light, light),
      (AppColorSchemes.dark, dark),
    ]) {
      for (final ground in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainer,
      ]) {
        expect(ratio(derived.streakInk, ground), greaterThanOrEqualTo(3));
      }
    }
    expect(dark.streakInk, MxSemanticColors.dark.streak);
    expect(light.streakInk, isColorCloseTo(0xFFCA601D));
  });
```

`mx_flag_mark_test.dart`:

```dart
void main() {
  testWidgets('the flag draws in streakInk and says it is flagged', (
    tester,
  ) async {
    await pumpMx(tester, const MxFlagMark(semanticLabel: 'Flagged'));
    final icon = tester.widget<Icon>(find.byType(Icon));
    final context = tester.element(find.byType(MxFlagMark));

    expect(icon.icon, AppIcons.flagged);
    expect(icon.color, context.derivedColors.streakInk);
    expect(find.bySemanticsLabel('Flagged'), findsOneWidget);
  });
}
```

`mx_status_distribution_test.dart`:

```dart
const _counts = MxStatusCounts(newCards: 100, learning: 140, reviewing: 100, mastered: 80);

String _label(MxCardStatus status) => status.name;

void main() {
  testWidgets('segments share the width by count; the legend names each', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 420,
        child: MxStatusDistribution(counts: _counts, label: _label),
      ),
    );
    final widths = [
      for (final status in MxCardStatus.values)
        tester.getSize(find.byKey(ValueKey(('segment', status)))).width,
    ];

    expect(widths[0], closeTo(widths[2], 0.5));
    expect(widths[1], greaterThan(widths[0]));
    for (final status in MxCardStatus.values) {
      expect(find.textContaining(status.name), findsOneWidget);
    }
  });

  testWidgets('an empty deck draws the track alone, no division by zero', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxStatusDistribution(
          counts: MxStatusCounts(newCards: 0, learning: 0, reviewing: 0, mastered: 0),
          label: _label,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey(('segment', MxCardStatus.newCard))), findsNothing);
  });

  testWidgets('a status with no card draws no segment', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxStatusDistribution(
          counts: MxStatusCounts(newCards: 3, learning: 0, reviewing: 0, mastered: 0),
          label: _label,
        ),
      ),
    );

    expect(find.byKey(const ValueKey(('segment', MxCardStatus.learning))), findsNothing);
    expect(find.byKey(const ValueKey(('segment', MxCardStatus.newCard))), findsOneWidget);
  });
}
```

`mx_card_test.dart`:

```dart
  testWidgets('a selected card edges in primary', (tester) async {
    await pumpMx(tester, const MxCard(isSelected: true, child: SizedBox(height: 40)));

    expect(_shape(tester).side.color, AppColorSchemes.light.primary);
  });
```

`mx_status_badge_test.dart`:

```dart
  testWidgets('a plain badge is its label, uppercase, in the status ink', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Beginning', isPlain: true),
    );
    final context = tester.element(find.byType(MxStatusBadge));
    final text = tester.widget<Text>(find.text('BEGINNING'));

    expect(text.style!.color, context.derivedColors.statusLearningInk);
    expect(find.byType(DecoratedBox), findsNothing);
  });
```

`mx_unavailable_test.dart`:

```dart
  testWidgets('a not-yet control says so to TalkBack', (tester) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: MxUnavailable(child: MxButton(label: 'Export', onPressed: null)),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MxButton)),
      matchesSemantics(hint: _en.commonNotAvailableYet, isButton: true, hasEnabledState: true),
    );
  });
```

Write the `MxUnavailable` test with `libraryTest`/`pumpLibraryScreen` (it needs localizations). If `matchesSemantics` is strict about other flags, assert with `isSemantics(hint: ...)` instead, as phase C did.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/core/theme test/shared/widgets`
Expected: compile errors, the new names do not exist.

- [ ] **Step 3: Implement**

`mx_semantic_colors.dart`:
- add `required this.streak, required this.onStreak` with `light: streak: Color(0xFFF97316), onStreak: Color(0xFFFFFFFF)` and `dark: streak: Color(0xFFFFAE6E), onStreak: Color(0xFFFFFFFF)`;
- add them to `copyWith` and `lerp`;
- change the doc to say streak is now bound, for the flag (phase E).

`mx_derived_colors.dart`: add `required this.streakInk`, a doc line ("The flag glyph: streak pulled toward onSurface until it reads 3:1 as a glyph on every card ground (E-O4)"), `static const double _streakInkLight = 0.20; static const double _streakInkDark = 0;`, and in `resolve`:

```dart
      streakInk: _ink(
        semantic.streak,
        scheme,
        isDark ? _streakInkDark : _streakInkLight,
      ),
```

`app_icons.dart`:

```dart
  static const IconData exportFile = Icons.file_upload_outlined; // upload
  static const IconData importFile = Icons.file_download_outlined; // download
```

`mx_flag_mark.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A flagged card's mark (screen 07): the filled flag in the streak ink,
/// named for TalkBack by the caller (E-O2, E-O4).
class MxFlagMark extends StatelessWidget {
  const MxFlagMark({super.key, required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Icon(
    AppIcons.flagged,
    size: AppIconSize.inline,
    color: context.derivedColors.streakInk,
    semanticLabel: semanticLabel,
  );
}
```

`mx_status_distribution.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// How many cards sit in each display state.
final class MxStatusCounts {
  const MxStatusCounts({
    required this.newCards,
    required this.learning,
    required this.reviewing,
    required this.mastered,
  });

  final int newCards;
  final int learning;
  final int reviewing;
  final int mastered;

  int of(MxCardStatus status) => switch (status) {
    MxCardStatus.newCard => newCards,
    MxCardStatus.learning => learning,
    MxCardStatus.reviewing => reviewing,
    MxCardStatus.mastered => mastered,
  };

  int get total => newCards + learning + reviewing + mastered;
}

/// A deck's cards by display state (screen 07, spec A13): one stacked bar,
/// each state a segment in its colour sized by its count, then a legend of
/// dots, names and counts. A state with no card draws no segment; an empty
/// deck draws the track alone.
class MxStatusDistribution extends StatelessWidget {
  const MxStatusDistribution({
    super.key,
    required this.counts,
    required this.label,
  });

  final MxStatusCounts counts;

  /// The state's name, from the caller's copy.
  final String Function(MxCardStatus status) label;

  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final present = [
      for (final status in MxCardStatus.values)
        if (counts.of(status) > 0) status,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.control,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: _barHeight,
            child: ColoredBox(
              color: context.colors.surfaceContainer,
              child: Row(
                children: [
                  for (final status in present)
                    Expanded(
                      key: ValueKey(('segment', status)),
                      flex: counts.of(status),
                      child: ColoredBox(color: statusColor(context, status)),
                    ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.grouped,
          runSpacing: AppSpacing.micro,
          children: [
            for (final status in MxCardStatus.values)
              MxStatusBadge(
                status: status,
                label: '${label(status)} ${counts.of(status)}',
              ),
          ],
        ),
      ],
    );
  }
}
```

`statusColor(BuildContext, MxCardStatus)` is the status colour `MxStatusBadge` already picks for its dot. Expose it from `mx_status_badge.dart` as a top-level function, and make the badge use it. If the legend's badge pill reads heavier than the kit's dot-and-text legend, draw the legend item as `Row(dot, Text(label, style: styles.workloadText), Text(count, style: styles.workloadTerm(context.colors.onSurface)))` using the same private dot. Choose it in Task 9's visual check, not now. The count text in the legend is data, not copy: build it with `NumberFormat.decimalPattern(locale)` rather than string interpolation if the guard flags `'${…} ${…}'` as a literal.

`mx_card.dart`: add `this.isSelected = false`, a doc line, and after picking `surface`:

```dart
    final edge = isSelected
        ? BorderSide(color: context.colors.primary, width: AppStroke.focus)
        : (surface.border as Border?)?.top ?? BorderSide.none;
```

Use it as the `RoundedRectangleBorder.side`, with `AppStroke.selected` replaced by the existing `AppStroke.focus` (2).

`mx_status_badge.dart`: add `this.isPlain = false` with `assert(!(isDot && isPlain), 'a dot or a plain label')`. When `isPlain`, return:

```dart
      Text(
        label.toUpperCase(),
        style: context.textStyles.badgeLabel(inkOf(context, status)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
```

`inkOf` is the label ink the pill already uses (`derivedColors.status*Ink`).

`mx_unavailable.dart`: copy `deck_unavailable_widget.dart` as `MxUnavailable` (same body, doc "A control whose feature does not exist yet (spec A4) …"). Replace every `DeckUnavailableWidget` with `MxUnavailable`, update imports, and delete the deck file.

Gallery:
- in `gallery_status_section.dart`, add `const MxFlagMark(semanticLabel: 'Flagged')`, an `MxStatusDistribution` over `MxStatusCounts(newCards: 100, learning: 140, reviewing: 100, mastered: 80)` with `label: (status) => status.name`, and a plain `MxStatusBadge(status: MxCardStatus.reviewing, label: 'Reviewing', isPlain: true)`;
- in `gallery_surfaces_section.dart`, add `const MxCard(isSelected: true, child: MxListSectionHeader(label: 'Selected card'))`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/core/theme test/shared/widgets test/features/deck --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add -A lib test
git commit -m "feat(shared): the streak token, flag mark, status distribution, selected card and MxUnavailable" -m "<trailer>"
```

---

### Task 3: The deck workload on the card list read

**Files:**
- Modify: `lib/features/card/domain/models/card_list_view_model.dart` (`CardWorkload`, `CardListView.workload`)
- Modify: `lib/features/card/data/mappers/card_mapper.dart` (`workloadOf`)
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart` (`_readCardList`)
- Test: `test/features/card/data/card_list_read_test.dart`

**Interfaces:**
- Produces: `CardWorkload({required int overdue, required int today, required int newCards})` with `int get due => overdue + today`; `CardListView.workload`.

- [ ] **Step 1: Write the failing test** in `card_list_read_test.dart`, following the file's own setup (its repository, `now`, and `insertCard` fixture):

```dart
  test('the workload counts the whole deck, whatever the search (E-L1)', () async {
    // 2 overdue, 1 today, 1 new, 1 later
    await insertCard(db, id: 'o1', deckId: deckId, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 20));
    await insertCard(db, id: 'o2', deckId: deckId, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 21));
    await insertCard(db, id: 't', deckId: deckId, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 24, 18));
    await insertCard(db, id: 'n', deckId: deckId);
    await insertCard(db, id: 'l', deckId: deckId, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 10, 2));

    final view = await firstView(query: const CardListQuery(searchTerm: 'zzz'));

    expect(view.items, isEmpty);
    expect(
      (view.workload.overdue, view.workload.today, view.workload.newCards),
      (2, 1, 1),
    );
    expect(view.workload.due, 3);
  });
```

`firstView` stands for however the file reads the first emission of `watchCardList`. If there is no helper, use `await repo.watchCardList(deckId: deckId, query: …, windowSize: 50).first`. Match the day to the file's `now`: the test above assumes 2026-09-24.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/card/data/card_list_read_test.dart`
Expected: compile error, `workload` does not exist.

- [ ] **Step 3: Implement**

`card_list_view_model.dart`:

```dart
/// What the whole deck asks of today (screen 07's summary, ruling E-L1):
/// overdue, due today and new cards, whatever the search and the filter.
final class CardWorkload {
  const CardWorkload({
    required this.overdue,
    required this.today,
    required this.newCards,
  });

  final int overdue;
  final int today;
  final int newCards;

  /// The cards a session would review now.
  int get due => overdue + today;
}
```

Add `required this.workload` and `final CardWorkload workload;` to `CardListView`, with a doc line.

`card_mapper.dart`:

```dart
/// The deck's workload from its schedule rows, by the rows' own due rule.
CardWorkload workloadOf(
  Iterable<CardSchedule> schedules, {
  required DateTime startOfToday,
}) {
  var overdue = 0;
  var today = 0;
  var newCards = 0;
  for (final schedule in schedules) {
    final due = CardDue.of(
      isLearned: schedule.learnedAt != null,
      dueAt: schedule.dueAt,
      startOfToday: startOfToday,
    );
    switch (due.kind) {
      case CardDueKind.overdue:
        overdue++;
      case CardDueKind.today:
        today++;
      case CardDueKind.newCard:
        newCards++;
      case CardDueKind.later:
        break;
    }
  }
  return CardWorkload(overdue: overdue, today: today, newCards: newCards);
}
```

`card_repository_impl.dart` `_readCardList`: add `workload: workloadOf(schedules, startOfToday: startOfToday),`. Update every other `CardListView(` constructor in `lib` and `test` (fakes, fixtures) with a `workload:` argument; `grep -rn "CardListView(" lib test` lists them.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/card --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(card): the deck workload on the card list read (ruling E-L1)" -m "<trailer>"
```

---

### Task 4: Copy for screen 07

**Files:**
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb`
- Test: `test/features/card/presentation/card_messages_test.dart` (create it if absent, as `deck_messages_test.dart` is built)

**Interfaces:**
- Produces (en / vi; `description` "Screen handoff 07 (library alignment phase E): <key>." unless noted):

| Key | en | vi | Placeholders |
|---|---|---|---|
| `cardSummaryOverline` | `Deck progress · {algorithm}` | `Tiến độ bộ thẻ · {algorithm}` | algorithm String |
| `cardSummaryMastered` | `{mastered} of {total, plural, =1{1 card} other{{total} cards}} mastered` | `Thuộc {mastered} trên {total} thẻ` | mastered int, total int |
| `cardStudyThisDue` | `Study this deck · {count} due` | `Học bộ thẻ này · {count} đến hạn` | count int |
| `cardStudyThis` | `Study this deck` | `Học bộ thẻ này` | |
| `cardFilterTags` | `Tags` | `Tag` | |
| `cardListShowing` | `Showing {shown} of {total}` | `Đang hiện {shown} trên {total}` | shown int, total int |
| `cardListSelectedOf` | `{selected} of {total} selected` | `Đã chọn {selected} trên {total}` | selected int, total int |
| `cardSelectAllCount` | `Select all {count}` | `Chọn tất cả {count}` | count int |
| `cardOpenSearch` | `Search cards` | `Tìm thẻ` | |
| `cardCloseSearch` | `Close search` | `Đóng tìm kiếm` | |
| `cardExport` | `Export` | `Xuất` | |
| `cardDueNew` | `New` | `Mới` | |
| `cardDueToday` | `Due today` | `Đến hạn hôm nay` | |
| `cardDueIn` | `In {days}d` | `Còn {days} ngày` | days int |
| `cardDueOverdue` | `{days}d overdue` | `Quá hạn {days} ngày` | days int |
| `cardTagsMore` | `+{count}` | `+{count}` | count int |
| `cardSortNewestPill` | `Newest first` | `Mới nhất trước` | |
| `cardSortDuePill` | `Due first` | `Đến hạn trước` | |
| `deckImportCards` | `Import cards` | `Nhập thẻ` | |
| `deckExportAll` | `Export all cards` | `Xuất mọi thẻ` | |

- [ ] **Step 1:** Write the failing test:

```dart
    test('screen 07 has ${locale.languageCode} copy', () {
      for (final copy in [
        l10n.cardSummaryOverline('SM-2'),
        l10n.cardSummaryMastered(80, 420),
        l10n.cardStudyThisDue(40),
        l10n.cardListShowing(7, 420),
        l10n.cardListSelectedOf(2, 420),
        l10n.cardSelectAllCount(420),
        l10n.cardDueIn(17),
        l10n.cardDueOverdue(30),
        l10n.cardTagsMore(8),
      ]) {
        expect(copy.trim(), isNotEmpty);
        expect(copy, isNot(contains('{')));
      }
    });
```

inside the per-locale loop (`for (final locale in AppLocalizations.supportedLocales)` with `final l10n = lookupAppLocalizations(locale);`).

- [ ] **Step 2:** Run: `flutter test test/features/card/presentation/card_messages_test.dart`. Expected: compile error.
- [ ] **Step 3:** Add the keys to both ARBs (parse and re-dump as JSON, 2-space indent, `ensure_ascii=False`, which is the files' format), then `flutter gen-l10n`.
- [ ] **Step 4:** Run it again. Expected: PASS.
- [ ] **Step 5: Commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(l10n): copy for screen 07, the card list" -m "<trailer>"
```

---

### Task 5: The card deck's app bar, search and selection (E-O1, E-O3)

**Files:**
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart` (`cardAppBar`; `cardContent` signature)
- Modify: `lib/features/card/presentation/states/card_list_request_state.dart` (`isSearchOpen`, `openSearch`, `closeSearch`)
- Create: `lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart` (takes the breadcrumb; hides it while selecting; search only when open; no selection header)
- Delete: `lib/features/card/presentation/widgets/sections/card_selection_header_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_list_toolbar_widget.dart` (search field shown only when open)
- Modify: `lib/app/router/app_router.dart` (`_deckLevel`)
- Modify: `test/support/library_harness.dart` (`deckScreen` gains `cardAppBar`; a new `cardDeckScreen(deckId)` that composes the real card builders like the router)
- Test: `test/features/card/presentation/card_deck_app_bar_test.dart` (new), `card_list_section_test.dart`, `card_selection_test.dart`, `test/app/library_routes_test.dart`

**Interfaces:**
- Consumes: Task 4 copy.
- Produces:
  - `DeckLevelScreen({..., required Widget Function(String deckId, {required String title, required Widget leading, required List<Widget> actions}) cardAppBar, required Widget Function(String deckId, {required SchedulerType schedulerType, required Widget breadcrumb}) cardContent})`;
  - `CardDeckAppBarWidget({required String deckId, required String title, required Widget leading, required List<Widget> actions})`;
  - `CardListSectionWidget({required deckId, required schedulerType, required breadcrumb, required onAddCard, required onOpenCard})`;
  - `CardListRequestState.isSearchOpen`, `CardListRequest.openSearch()`, `CardListRequest.closeSearch()`;
  - test helper `cardDeckScreen({required String deckId, ValueChanged<String>? onOpenCard, VoidCallback? onAddCard})`.

The app bar:
- **Not selecting:** `MxAppBar(title: title, density: content, leading: leading, actions: [MxIconButton(icon: AppIcons.search, semanticLabel: l10n.cardOpenSearch, onPressed: request.isSearchOpen ? closeSearch : openSearch), ...actions])`. While open, the action's icon is `AppIcons.close` and its label `cardCloseSearch`.
- **Selecting** (`cardSelectedCount` and `cardSelectionClose` already exist): `MxAppBar(titleWidget: Semantics(liveRegion: true, child: Text(l10n.cardSelectedCount(n), style: styles.contentTitle)), density: content, leading: MxIconButton(icon: AppIcons.close, semanticLabel: l10n.cardSelectionClose, onPressed: selection.clear), actions: [MxButton(label: l10n.cardSelectAllCount(total), size: MxButtonSize.compact, tone: MxButtonTone.secondary, onPressed: selectAll)])`. `total` is `view.counts.of(request.filter)`, the cards the current query lets through (BR-CARD-012); read it from the same `cardListProvider(...)` the section watches. The select-all call moves here from the section: `cardActionsControllerProvider.notifier.selectAll(deckId, query)`, then `cardSelectionProvider(deckId).notifier.selectAll(ids)`, and on a `Failure` the failure snackbar.

`CardListRequest`:

```dart
  /// E-O3: the app bar's search action opens the field.
  void openSearch() => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
    searchTerm: state.searchTerm,
    isSearchOpen: true,
  );

  /// Closing the search clears its term; the filter stays.
  void closeSearch() => state = CardListRequestState(
    filter: state.filter,
    sort: state.sort,
  );
```

Add `this.isSearchOpen = false` and `final bool isSearchOpen;` to the state. Make `show`, `sortBy`, `search` and `grow` carry `isSearchOpen: state.isSearchOpen`.

The section:
- takes `breadcrumb` and renders it at the top of its column when not selecting;
- renders the search field (autofocus) only while `request.isSearchOpen && !isSelecting`;
- drops `CardSelectionHeaderWidget` and its import;
- `_selectAll` moves to the app bar;
- the `PopScope` stays.

`DeckLevelScreen` `_OpenDeckContent`: for `DeckContentType.card`,
- `appBar` is `cardAppBar(deck.id, title: deck.name, leading: const _BackButton(), actions: [the ⋮ MxIconButton])`;
- the body is `cardContent(deck.id, schedulerType: view.schedulerType, breadcrumb: MxBreadcrumb(...))` without the outer column;
- the other content types keep today's bar and column.

Move the breadcrumb construction into a private `_breadcrumb()` method so both paths build the same one.

Router `_deckLevel`:

```dart
    cardAppBar: (id, {required title, required leading, required actions}) =>
        CardDeckAppBarWidget(deckId: id, title: title, leading: leading, actions: actions),
    cardContent: (id, {required schedulerType, required breadcrumb}) => CardListSectionWidget(
      deckId: id,
      schedulerType: schedulerType,
      breadcrumb: breadcrumb,
      onAddCard: () => addCard(id),
      onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
    ),
```

- [ ] **Step 1: Write the failing tests**

`card_deck_app_bar_test.dart`, over `cardDeckScreen`:

```dart
  libraryTest('the deck bar offers search; the field opens and closes', (
    tester,
    env,
  ) async {
    final words = await _cardDeck(env); // Korean › Words with 3 cards
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    expect(find.byType(MxSearchField), findsNothing);
    await tester.tap(find.byTooltip(_en.cardOpenSearch));
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsOneWidget);
  });

  libraryTest('closing the search clears the term (E-O3)', (tester, env) async {
    final words = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));
    await tester.tap(find.byTooltip(_en.cardOpenSearch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsNothing);

    await tester.tap(find.byTooltip(_en.cardCloseSearch));
    await tester.pumpAndSettle();

    expect(find.byType(CardRowWidget), findsNWidgets(3));
  });

  libraryTest('selecting swaps the bar: close, count, Select all; the '
      'breadcrumb hides', (tester, env) async {
    final words = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSelectedCount(1)), findsOneWidget);
    expect(find.text(_en.cardSelectAllCount(3)), findsOneWidget);
    expect(find.byType(MxBreadcrumb), findsNothing);
    await tester.tap(find.text(_en.cardSelectAllCount(3)));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardSelectedCount(3)), findsOneWidget);
  });

  libraryTest('Back leaves selection, then the deck', (tester, env) async {
    final words = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSelectedCount(1)), findsNothing);
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('the selection bar at 2x on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    final words = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id), textScale: 2);
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
```

`_cardDeck(env)` makes `Korean` › `Words` with `insertCard` × 3 (ids `a`, `b`, `c`).

Migrate `card_list_section_test.dart` and `card_selection_test.dart` to pump `cardDeckScreen`, and to open the search through `find.byTooltip(_en.cardOpenSearch)` before typing. Delete their expectations on `CardSelectionHeaderWidget`, and on the bulk bar's Select all, which moves to the app bar. Add to `library_routes_test.dart`:

```dart
  libraryTest('a deck of cards shows its search action in the app bar', (
    tester,
    env,
  ) async {
    // a deck of cards reachable from the root, as the file's fixtures allow
    ...
    expect(
      find.descendant(of: find.byType(MxAppBar), matching: find.byTooltip(_en.cardOpenSearch)),
      findsOneWidget,
    );
  });
```

Build the fixture with the file's helpers. A deck of cards needs `insertCard` on a sub-deck.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/card test/app --exclude-tags golden`
Expected: compile errors (`cardDeckScreen`, `cardAppBar`, `cardOpenSearch` wiring).

- [ ] **Step 3: Implement** as described above.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/card test/features/deck test/app test/architecture --exclude-tags golden`
Expected: PASS, including `boundaries_test.dart`.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add -A lib test
git commit -m "feat(card): the card deck's app bar with search and selection (E-O1, E-O3)" -m "Closes UI-base debt row 75." -m "<trailer>"
```

---

### Task 6: Summary card, filters and list header

**Files:**
- Create: `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`
- Modify: `card_list_toolbar_widget.dart` (Tags chip; header row)
- Modify: `card_list_section_widget.dart` (summary above the toolbar, hidden while selecting)
- Modify: `lib/features/card/presentation/widgets/support/card_list_labels_widget.dart` (`mxStatusCounts(CardStatusCounts)`, sort pill labels)
- Test: `test/features/card/presentation/card_deck_summary_test.dart` (new), `card_list_section_test.dart`

**Interfaces:**
- Consumes: `CardListView.statusCounts`, `.workload`, `.counts` (Task 3), `MxStatusDistribution`, `MxUnavailable`, `MxMasteryDonut`, `MxWorkloadBreakdownLine`, the Task 4 copy.
- Produces: `CardDeckSummaryWidget({required CardStatusCounts status, required CardWorkload workload, required SchedulerType schedulerType})`.

The summary card: `MxCard(isHero: true)` → `Column`:
1. `Row(MxMasteryDonut(fraction: total == 0 ? 0 : mastered / total), Expanded(Column(Text(cardSummaryOverline(algorithm).toUpperCase(), overline), Text(cardSummaryMastered(mastered, total), rowTitle), MxWorkloadBreakdownLine(overdueCount: workload.overdue, todayCount: workload.today, newCount: workload.newCards, overdueLabel: l10n.workloadOverdue, todayLabel: l10n.workloadToday, newLabel: l10n.workloadNew, fallback: total == 0 ? l10n.workloadNoCards : l10n.workloadNothingDue(total)))))`;
2. `MxStatusDistribution(counts: mxStatusCounts(status), label: (s) => l10n.cardStatus(cardDisplayStatusOf(s)))`;
3. `MxUnavailable(child: MxButton(label: workload.due > 0 ? l10n.cardStudyThisDue(workload.due) : l10n.cardStudyThis, icon: AppIcons.play, isBlock: true, onPressed: null))`.

`algorithm` is `schedulerType == SchedulerType.sm2 ? l10n.cardSchedulerSm2 : l10n.cardSchedulerEightBox` (ruling E-L6). `cardDisplayStatusOf(MxCardStatus)` is the inverse of `mxCardStatus`; add it next to it.

Toolbar:
- after the four `MxFilterChip`s, add `MxUnavailable(child: MxFilterChip(label: l10n.cardFilterTags, icon: AppIcons.tag, isSelected: false, onSelected: null))`;
- move the sort out of the chip row into a header: `MxListSectionHeader(label: isSelecting ? l10n.cardListSelectedOf(selected, total) : l10n.cardListShowing(shown, total), trailing: isSelecting ? null : MxChipTrigger(label: request.sort == CardListSort.newest ? l10n.cardSortNewestPill : l10n.cardSortDuePill, onPressed: onSort))`;
- `shown` is the loaded rows' count, `total` is `counts.of(request.filter)`, `selected` is the selection's size.

The section: while not selecting, the order is the breadcrumb, the search (when open), `CardDeckSummaryWidget`, the filters, then the header. While selecting, only the header and the rows show. The summary shows only when the deck holds a card (`statusCounts.total > 0`); the empty state covers an empty deck.

- [ ] **Step 1: Write the failing tests** (`card_deck_summary_test.dart`, over `cardDeckScreen`):

```dart
  libraryTest('the summary: algorithm, mastered of total, workload, the '
      'distribution, Study disabled', (tester, env) async {
    final words = await _deckWithWork(env); // 1 overdue, 1 today, 1 new, 1 mastered
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    expect(find.text(_en.cardSummaryOverline(_en.cardSchedulerEightBox).toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardSummaryMastered(1, 4)), findsOneWidget);
    expect(find.text('1 overdue · 1 today · 1 new', findRichText: true), findsOneWidget);
    expect(find.byType(MxStatusDistribution), findsOneWidget);
    final study = tester.widget<MxButton>(find.widgetWithText(MxButton, _en.cardStudyThisDue(2)));
    expect(study.onPressed, isNull);
  });

  libraryTest('Tags is shown, disabled, and says it is not available yet', (
    tester,
    env,
  ) async {
    final words = await _deckWithWork(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    final tags = tester.widget<MxFilterChip>(find.widgetWithText(MxFilterChip, _en.cardFilterTags));
    expect(tags.onSelected, isNull);
    expect(
      tester.getSemantics(find.widgetWithText(MxFilterChip, _en.cardFilterTags)),
      isSemantics(hint: _en.commonNotAvailableYet),
    );
  });

  libraryTest('the header counts what shows; selecting hides the summary', (
    tester,
    env,
  ) async {
    final words = await _deckWithWork(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    expect(find.text(_en.cardListShowing(4, 4).toUpperCase()), findsOneWidget);
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardDeckSummaryWidget), findsNothing);
    expect(find.text(_en.cardListSelectedOf(1, 4).toUpperCase()), findsOneWidget);
  });

  libraryTest('a deck with no mastered card reads 0%', (tester, env) async {
    final words = await _newCardsOnly(env, 3);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));

    expect(tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut)).fraction, 0);
    expect(tester.takeException(), isNull);
  });
```

"Mastered" needs a schedule the display rule counts as mastered. Read `CardDisplayStatus.of` and seed one card whose schedule meets it (for eight-box, a high `box`: `insertCard(..., box: 8, learnedAt: …, dueAt: …)`).

- [ ] **Step 2:** Run: `flutter test test/features/card/presentation/card_deck_summary_test.dart`. Expected: FAIL, no summary.
- [ ] **Step 3:** Implement as described.
- [ ] **Step 4:** Run: `flutter test test/features/card test/features/deck --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the deck summary, filters and list header of screen 07" -m "<trailer>"
```

---

### Task 7: The card row

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart`
- Create: `lib/features/card/presentation/widgets/support/card_due_chip_widget.dart`
- Modify: `card_list_section_widget.dart` (rows: one `CardRowWidget` per card, `AppSpacing.control` apart, no shared card)
- Test: `test/features/card/presentation/card_row_widget_test.dart` (new or existing)

**Interfaces:**
- Consumes: `CardListItem.due`, `.tags`, `.displayStatus`, `.isFlagged`; `MxFlagMark`, `MxCard.isSelected`, `MxStatusBadge.isPlain`, `MxTagChip`, `MxBadge`.
- Produces: `CardDueChipWidget({required CardDue due})`; `CardRowWidget({required item, required isSelecting, required isSelected, VoidCallback? onTap, VoidCallback? onLongPress})` (the `hasDivider` parameter goes).

The row: `MxCard(isFullBleed: true, isSelected: isSelected)` → `MxRowInk(onTap, child: Padding(EdgeInsets.all(AppSpacing.gutter), Row(crossAxisAlignment: start, spacing: grouped, children: [leading, Expanded(column), trailing])))`:
- **leading:** `isSelecting ? MxSelectionCheckbox(isChecked: isSelected) : MxStatusBadge(status, label, isDot: true)`, padded to the first line;
- **column** (spacing `AppSpacing.micro`):
  - `Text(front, maxLines: 1, overflow: ellipsis, style: compactTitle)`;
  - `Text(back, maxLines: 1, overflow: ellipsis, style: rowSubtitle)`;
  - `Wrap(spacing: control, runSpacing: micro, crossAxisAlignment: center, children: [MxStatusBadge(status, label, isPlain: true), for (tag in tags.take(2)) MxTagChip(label: tag.name, isDense: true), if (tags.length > 2) Text(l10n.cardTagsMore(tags.length - 2), style: rowSubtitle)])`;
- **trailing:** `Column(crossAxisAlignment: end, spacing: micro, children: [if (isFlagged) MxFlagMark(semanticLabel: l10n.cardFlagged), CardDueChipWidget(due: item.due)])`.

Keep the `MergeSemantics` + `Semantics(checked:)` + `GestureDetector(onLongPress:)` wrapper as it is today.

`CardDueChipWidget`:

```dart
/// A card's due chip (screen 07): new and later are neutral, today is
/// primary, overdue is warning.
class CardDueChipWidget extends StatelessWidget {
  const CardDueChipWidget({super.key, required this.due});

  final CardDue due;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone) = switch (due.kind) {
      CardDueKind.newCard => (l10n.cardDueNew, MxBadgeTone.neutral),
      CardDueKind.today => (l10n.cardDueToday, MxBadgeTone.primary),
      CardDueKind.later => (l10n.cardDueIn(due.days), MxBadgeTone.neutral),
      CardDueKind.overdue => (l10n.cardDueOverdue(due.days), MxBadgeTone.warning),
    };
    return MxBadge(label: label, tone: tone);
  }
}
```

The section lays the rows out as `Column(spacing: AppSpacing.control, children: [for (item in items) CardRowWidget(...)])`, replacing the single `MxCard(isFullBleed)` over all rows (ruling P3-L6 is superseded; record it in Task 9).

- [ ] **Step 1: Write the failing tests** (`card_row_widget_test.dart`, pumping the row inside `libraryTest` + `pumpLibraryScreen` with a `Scaffold`; build `CardListItem`s by hand, as `deck_row_widget_test.dart` builds tiles):

```dart
  libraryTest('a row: front, back, status label, two tags and +N, flag, due chip', (
    tester,
    env,
  ) async {
    await pump(tester, env, _item(
      isFlagged: true,
      due: const CardDue.overdue(30),
      tags: ['bà', 'Cấu trúc thường gặp', 'TOPIK', 'động từ'],
      status: CardDisplayStatus.reviewing,
    ));

    expect(find.text('front'), findsOneWidget);
    expect(find.text('back'), findsOneWidget);
    expect(find.text(_en.cardStatus(CardDisplayStatus.reviewing).toUpperCase()), findsOneWidget);
    expect(find.byType(MxTagChip), findsNWidgets(2));
    expect(find.text(_en.cardTagsMore(2)), findsOneWidget);
    expect(find.byType(MxFlagMark), findsOneWidget);
    expect(find.widgetWithText(MxBadge, _en.cardDueOverdue(30)), findsOneWidget);
  });

  libraryTest('the due chip reads new, today, in N days, N days overdue', (
    tester,
    env,
  ) async {
    for (final (due, label) in [
      (const CardDue.newCard(), _en.cardDueNew),
      (const CardDue.today(), _en.cardDueToday),
      (const CardDue.later(17), _en.cardDueIn(17)),
      (const CardDue.overdue(3), _en.cardDueOverdue(3)),
    ]) {
      await pump(tester, env, _item(due: due));
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  libraryTest('selecting shows a checkbox and edges the selected card', (
    tester,
    env,
  ) async {
    await pump(tester, env, _item(), isSelecting: true, isSelected: true);

    expect(find.byType(MxSelectionCheckbox), findsOneWidget);
    expect(tester.widget<MxCard>(find.byType(MxCard)).isSelected, isTrue);
  });

  libraryTest('a long row at 2x on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    await pump(
      tester,
      env,
      _item(
        front: '-(으)ㄹ 뿐만 아니라: không những… mà còn…',
        back: 'Nối hai mệnh đề, nhấn mạnh rằng ngoài điều thứ nhất còn có điều thứ hai',
        isFlagged: true,
        due: const CardDue.overdue(30),
        tags: ['Cấu trúc thường gặp trong đề thi', 'TOPIK II nâng cao', 'x'],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
```

Read `CardDue`'s constructors (`card_due_model.dart`) and `CardListItem`'s constructor before writing `_item`.

- [ ] **Step 2:** Run: `flutter test test/features/card/presentation/card_row_widget_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement as described.
- [ ] **Step 4:** Run: `flutter test test/features/card --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card row of screen 07: status, tags, flag and due chip" -m "<trailer>"
```

---

### Task 8: Bulk bar and the card deck's sheet

**Files:**
- Modify: `card_bulk_bar_widget.dart` (an action may be unavailable)
- Modify: `card_list_section_widget.dart` (`_bulkActions`)
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (Import, Export all for a deck of cards)
- Test: `test/features/card/presentation/card_bulk_actions_test.dart`, `test/features/deck/presentation/deck_action_sheet_test.dart`

**Interfaces:**
- Produces: `typedef CardBulkAction = ({IconData icon, String label, VoidCallback? onTap});` where a null `onTap` draws the action disabled inside `MxUnavailable`.

Bulk actions, in this order (ruling E-L3):
1. Move (`AppIcons.folder`, `cardMove`) → the move sheet;
2. Flag (`AppIcons.flag`) → the flag sheet;
3. Tag (`AppIcons.tag`) → the tag dialog;
4. Export (`AppIcons.exportFile`, `cardExport`, `onTap: null`);
5. Delete (`AppIcons.delete`) → the delete dialog.

`CardBulkBarWidget`: a null `onTap` wraps that column in `MxUnavailable` and passes `onTap: null` (and `isEnabled: false` if `MxRowInk` takes one) so it draws dimmed.

Deck sheet, when `view.deck.contentType == DeckContentType.card` (ruling E-L5), insert after "Study this deck":

```dart
        MxUnavailable(
          child: MxActionSheetCommandRow(
            icon: AppIcons.importFile,
            label: l10n.deckImportCards,
            onTap: () {},
            isEnabled: false,
          ),
        ),
        MxUnavailable(
          child: MxActionSheetCommandRow(
            icon: AppIcons.exportFile,
            label: l10n.deckExportAll,
            onTap: () {},
            isEnabled: false,
          ),
        ),
```

- [ ] **Step 1: Write the failing tests**

`card_bulk_actions_test.dart`: add, over `cardDeckScreen`:

```dart
  libraryTest('the bulk bar is Move · Flag · Tag · Export · Delete; Export is '
      'not available yet', (tester, env) async {
    final words = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();
    final bar = find.byType(CardBulkBarWidget);
    final labels = [_en.cardMove, _en.cardFlag, _en.cardTag, _en.cardExport, _en.cardDelete];
    final xs = [
      for (final label in labels)
        tester.getCenter(find.descendant(of: bar, matching: find.text(label))).dx,
    ];

    expect(xs, orderedEquals([...xs]..sort()));
    expect(find.descendant(of: bar, matching: find.text(_en.cardSelectAll)), findsNothing);
    expect(
      tester.getSemantics(find.descendant(of: bar, matching: find.text(_en.cardExport))),
      isSemantics(hint: _en.commonNotAvailableYet),
    );
  });
```

Migrate the existing bulk tests that tapped the bar's Select all to tap `_en.cardSelectAllCount(n)` in the app bar.

`deck_action_sheet_test.dart`:

```dart
  libraryTest('a deck of cards offers Import and Export, not available yet', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: words.id));
    await tester.tap(find.byTooltip(_en.deckActions));
    await tester.pumpAndSettle();

    for (final label in [_en.deckImportCards, _en.deckExportAll]) {
      final row = tester.widget<MxActionSheetCommandRow>(
        find.widgetWithText(MxActionSheetCommandRow, label),
      );
      expect(row.isEnabled, isFalse, reason: label);
    }
    expect(find.text(_en.deckMove), findsOneWidget);
  });

  libraryTest('a deck of decks offers no Import or Export', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byTooltip(_en.deckActions));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckImportCards), findsNothing);
  });
```

- [ ] **Step 2:** Run: `flutter test test/features/card/presentation/card_bulk_actions_test.dart test/features/deck/presentation/deck_action_sheet_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement as described.
- [ ] **Step 4:** Run: `flutter test test/features/card test/features/deck test/app --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the bulk bar of screen 07 and Import/Export in a card deck's sheet" -m "<trailer>"
```

---

### Task 9: Goldens, Impeccable audit, clean-up, ledgers, the full gate

**Files:**
- Modify: `test/features/card/presentation/card_list_golden_test.dart` (pump `cardDeckScreen`; add loaded-with-work, selection, search-open and empty goldens)
- Modify: goldens under `test/features/card/presentation/goldens/`, `test/app/goldens/` (gallery)
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb` (remove copy no code uses: `cardSortTrigger`, `cardSelectAll` if unused, the selection header's keys)
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (close row 75; supersede P3-L6; add rows for what remains)
- Modify: `docs/shared/ui/screen-handoff/00-index.md` (07 → `aligned`), `07-card-list.md` (Deviations found in Step 3)
- Modify: `docs/wbs_FE.md` (FE-A11 last cell)

- [ ] **Step 1: Goldens.** In `card_list_golden_test.dart`, pump `cardDeckScreen` through `pumpLibraryGolden`, seeding one card in each display state, two flagged, tags on two, and due kinds of every sort. Add these goldens, light and dark:
  - `card_list` (loaded);
  - `card_selection` (two selected);
  - `card_list_search` (search open with a term);
  - `card_list_empty`.

  Then regenerate:

```bash
flutter test --update-goldens --tags golden test/features/card/presentation/card_list_golden_test.dart
flutter test --update-goldens --tags golden --plain-name "Gallery" test/app/app_golden_test.dart
flutter test --tags golden test/features/card test/features/deck test/app
```

Regenerate any deck golden that now differs only because this phase changed it (the sheet of a deck of cards), and say which in the ledger. Restore and delete the `failures/` images.

- [ ] **Step 2: Impeccable audit (CLAUDE.md, a screen's workflow, step 5).** Run `/impeccable audit` on screen 07 with the new goldens as the visual evidence, against `img/07-card-list/` (loaded, selection, searchEmpty, empty; light and dark). Fix everything it finds in one batch, regenerate once, confirm once, and stop.

- [ ] **Step 3: Record what remains.** Add a Deviations row to `07-card-list.md` for each remaining difference, with its reason.

- [ ] **Step 4: Unused copy.** `grep` each candidate key in `lib` and `test` (excluding generated files) and delete the unused ones from both ARBs, then `flutter gen-l10n` and `flutter analyze`.

- [ ] **Step 5: Ledgers.**
  - UI-base spec §9:
    - row 75: append ` — closed by library alignment phase E (E-O1)`;
    - add a row: "Card rows are separate cards 8 apart, superseding ruling P3-L6 (one card over the window) — library alignment phase E".
  - `00-index.md`: row 07 → `aligned`.
  - `wbs_FE.md` FE-A11 last cell: `Phase A (#32), B (#34), C (#38), D (#42) xong; phase E (07) trong PR này — FE-A11 hoàn tất khi merge`.

- [ ] **Step 6: The full gate**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test
python3 tools/docs/generate.py && python3 tools/docs/check.py
GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- every command is clean except `flutter test` and DoD;
- those two fail only on goldens that also fail on `master` and that this phase did not regenerate;
- no non-golden test fails.

Restore and delete the `failures/` images afterwards.

- [ ] **Step 7: Commit**

```bash
git add lib test docs
git commit -m "test(card): screen 07 goldens on Linux; close debt row 75; ledgers" -m "<trailer>"
```
