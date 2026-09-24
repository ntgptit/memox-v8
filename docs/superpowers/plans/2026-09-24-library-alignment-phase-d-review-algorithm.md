# Library Alignment Phase D — Review Algorithm & Reset (Screen 02) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A root deck's review algorithm is changed and its learning progress reset from its own screen, `/decks/deck/:deckId/algorithm`, drawn as screen 02 of the V3 handoff; the scheduler sheet goes.

**Architecture:** A new `DeckAlgorithmScreen` in `deck/presentation` reads the root's `DeckView` stream (`deckViewProvider`), switches through `DeckActionsController.changeScheduler` behind a confirmation dialog, and resets through a new `DeckActionsController.resetLearning` from a reset dialog that reads `ResetLearningSummary`. The router adds the child route and injects `onOpenAlgorithm` into `DeckLevelScreen`; the action sheet's "Review algorithm" calls it. Three shared additions carry the handoff's colour without feature-level styling: `MxIconTile` tones, a warning `MxCard`, and `MxOutcomeTile`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3 (codegen), Drift, gen-l10n (en, vi), GoRouter, `intl` `DateFormat`.

**Spec:** `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` §4.2 (and A9, A10), with the screen handoff `docs/shared/ui/screen-handoff/02-review-algorithm.md` and its images `docs/shared/ui/screen-handoff/img/02-review-algorithm/`.

## Owner decisions (popup, 2026-09-24)

| # | Decision |
|---|---|
| D-O1 | **`MxIconTile` gains solid tones** (`primary`, `warning`) and **`MxCard` a warning ground**, so the lock strip draws as the handoff does: open lock on a solid primary tile over the hero ground; lock on a solid warning tile over the warning-soft ground. |
| D-O2 | **A new shared `MxOutcomeTile({label, body, tone})`**, tones `kept` and `lost`, draws the reset dialog's two tiles: "Kept" in `statusMasteredInk` over the mastery tint (spec A10), "Lost" in `warningInk` over `warningSoft`. |
| D-O3 | **The reset use case providers live in `srs/di/`** (asked in the popup during Task 8): the boundary test lets `deck` import another feature's `di/`, not its `domain/usecases/`. |

## Rulings written into this plan

| # | Ruling |
|---|---|
| D-L1 | **E4, refused because the tree just locked:** the screen already redraws locked from the `DeckView` stream; the refusal's reason shows as a snackbar through `srsRejection`. The drawn state never decides validity: the switch always goes to the use case. |
| D-L2 | **E2, a switch that fails** (a thrown `Failure`): a danger `MxInlineBanner` "Couldn't switch." / "The deck still uses {algorithm}." with Retry, above the ALGORITHM header, until the next switch starts. A rejection (`Rejected`) is not E2; it goes to the snackbar. |
| D-L3 | **Gone or not a root** (BR-DECK-025): the screen body is `DeckGoneStateWidget`, whose "Back to Library" calls `onOpenAncestor(null)`. |
| D-L4 | **"Eight box" becomes "Eight boxes"** in `deckSchedulerEightBox` (en), as the handoff and the create dialog's copy say. The Vietnamese "Tám hộp" stays. |
| D-L5 | **The action sheet's command becomes `DeckAction.reviewAlgorithm`** and navigates; `deck_scheduler_sheet_widget.dart` and its copy (`deckSchedulerTitle`, `deckSchedulerChangeWarning`, `deckSchedulerLockedNote`, `deckSchedulerChangedToast`) are deleted in Task 8, closing UI-base debt row 93. |

## Global Constraints

- Flutter 3.47.5 at `/root/.flutter-sdk/3.47.5/flutter/bin` (`export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH`).
- Feature import map: `deck → {srs}`; `deck` never imports `card` (D8). `app/` composes.
- The guard (`python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`) must report 0 errors and 0 warnings: no raw Material widgets or `Icon(color:)` in feature presentation, no `.copyWith` on text styles in features, no literal user strings, booleans read as predicates (`isX`, `hasX`), no `ref.read` in `build`.
- Every user-visible string comes from `lib/l10n/app_en.arb` and `app_vi.arb`; in each `@key`, `placeholders` come before `description`.
- Dates show in local time, formatted for the locale: `DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(at.toLocal())`.
- Goldens (spec §8, C-O5): regenerate on Linux only the goldens of screens this phase changes (screen 02, the gallery, and any deck golden whose image changes). A golden run overwrites the tracked `test/**/failures/*.png`: restore them with `git checkout -- $(git diff --name-only | grep /failures/)` and delete the untracked ones; never commit them.
- Commit trailer:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PJDjKsfDm9reH3a8cML75G
  ```

## Review Focus

- **Locked while the screen is open** (a card finishes learning elsewhere): the stream redraws the locked state, and a switch already in its dialog is refused by the use case with the reason shown (Task 5 test "a switch refused because the tree just locked says why").
- **A reset while nothing has been studied** (`hasProgressToLose == false`): one sentence, no Kept/Lost tiles, the reset still runs (Task 6 test "nothing to lose says so and still resets").
- **The open session line**: "the open session" appears in Lost only when `openSessionCount > 0` (Task 6 tests).
- **Text scale 2 on a 360-wide phone**: the screen and the reset dialog do not overflow (Task 5 and Task 6 overflow tests).
- **The deck is deleted while the screen is open**: the gone state, never a crash (Task 5 test "a root deleted while open shows the gone state").

---

### Task 1: Spec and handoff record this phase's decisions

**Files:**
- Modify: `docs/superpowers/specs/2026-09-24-library-artifact-alignment-design.md` (§6 table)
- Modify: `docs/shared/ui/screen-handoff/02-review-algorithm.md` (Deviations table)

- [ ] **Step 1: Extend the spec's §6 table**

Append:

```markdown
| `MxIconTile` | `tone`: `tinted` (default), `primary` and `warning` solid fills with `onPrimary` / `onWarning` glyphs; `seed` only with `tinted` (phase D, owner decision D-O1). |
| `MxCard` | `isWarning`: the warning-soft ground with the warning border, for screen 02's locked strip (D-O1). |
| `MxOutcomeTile` | New: a label in its ink over a tinted ground and a body, tones `kept` (`statusMasteredInk` over the mastery tint, A10) and `lost` (`warningInk` over `warningSoft`) (D-O2). |
```

- [ ] **Step 2: Extend the handoff's Deviations table**

Append to `02-review-algorithm.md` Deviations:

```markdown
| Refused because the tree just locked: a message on the screen | The locked state from the stream, and the reason as a snackbar | Ruling D-L1 |
```

- [ ] **Step 3: Commit**

```bash
python3 tools/docs/check.py
git add docs
git commit -m "docs(library): phase D decisions for screen 02" -m "<trailer>"
```

Expected: `check.py` PASS with the 69-warning baseline.

---

### Task 2: Shared pieces — icon tile tones, warning card, outcome tile

**Files:**
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/shared/widgets/mx_icon_tile.dart`
- Modify: `lib/core/theme/app_decorations.dart`
- Modify: `lib/shared/widgets/mx_card.dart`
- Create: `lib/shared/widgets/mx_outcome_tile.dart`
- Modify: `lib/app/gallery/gallery_surfaces_section.dart`, `lib/app/gallery/gallery_status_section.dart`
- Test: `test/shared/widgets/mx_icon_tile_test.dart` (create it if it does not exist), `test/shared/widgets/mx_card_test.dart` (same), `test/shared/widgets/mx_outcome_tile_test.dart` (new)

**Interfaces:**
- Produces:
  - `AppIcons.lock`, `AppIcons.lockOpen`, `AppIcons.resetProgress`;
  - `enum MxIconTileTone { tinted, primary, warning }`; `MxIconTile({..., MxIconTileTone tone = MxIconTileTone.tinted})`;
  - `AppDecorations.warningCard(ColorScheme, MxDerivedColors)`; `MxCard({..., bool isWarning = false})`;
  - `enum MxOutcomeTone { kept, lost }`; `MxOutcomeTile({required String label, required String body, required MxOutcomeTone tone})`.

- [ ] **Step 1: Write the failing tests**

`mx_icon_tile_test.dart` (add these cases; keep any that exist):

```dart
  testWidgets('a solid primary tile fills with primary under an onPrimary glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxIconTile(icon: AppIcons.lockOpen, tone: MxIconTileTone.primary),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(MxIconTile), matching: find.byType(DecoratedBox)),
    );
    final icon = tester.widget<Icon>(find.byIcon(AppIcons.lockOpen));
    final scheme = AppColorSchemes.light;

    expect((box.decoration as BoxDecoration).color, scheme.primary);
    expect(icon.color, scheme.onPrimary);
  });

  testWidgets('a solid warning tile fills with warning under an onWarning glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxIconTile(icon: AppIcons.lock, tone: MxIconTileTone.warning),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(MxIconTile), matching: find.byType(DecoratedBox)),
    );
    final icon = tester.widget<Icon>(find.byIcon(AppIcons.lock));

    expect((box.decoration as BoxDecoration).color, MxSemanticColors.light.warning);
    expect(icon.color, MxSemanticColors.light.onWarning);
  });

  test('a seed tints only', () {
    expect(
      () => MxIconTile(
        icon: AppIcons.lock,
        tone: MxIconTileTone.primary,
        seed: const Color(0xFF00AA00),
      ),
      throwsAssertionError,
    );
  });
```

`mx_card_test.dart`:

```dart
  testWidgets('a warning card fills with warning-soft and edges with the warning border', (
    tester,
  ) async {
    await pumpMx(tester, const MxCard(isWarning: true, child: SizedBox(height: 40)));
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(MxCard), matching: find.byType(Material)),
    );
    final derived = MxDerivedColors.light;
    final raised = AppDecorations.raisedCard(AppColorSchemes.light, derived).color!;

    expect(material.color, Color.alphaBlend(derived.warningSoft, raised));
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      derived.warningBorder,
    );
  });

  test('a card is hero or warning, not both', () {
    expect(
      () => MxCard(isHero: true, isWarning: true, child: const SizedBox()),
      throwsAssertionError,
    );
  });
```

Read `MxDerivedColors` for the name of its light instance (the existing `mx_derived_colors_test.dart` builds `light` and `dark`; reuse the same construction) and use it where this plan writes `MxDerivedColors.light`.

`mx_outcome_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';

import '../../support/widget_harness.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final tone in MxOutcomeTone.values) {
    testWidgets('${tone.name}: the label reads 4.5:1 on its ground over the dialog', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 160,
          child: MxOutcomeTile(label: 'Label', body: 'Body text', tone: tone),
        ),
      );
      final label = tester.widget<Text>(find.text('Label'));
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(MxOutcomeTile), matching: find.byType(DecoratedBox)).first,
      );
      final ground = Color.alphaBlend(
        (box.decoration as BoxDecoration).color!,
        AppColorSchemes.light.surfaceContainerHigh,
      );

      expect(_ratio(label.style!.color!, ground), greaterThanOrEqualTo(4.5));
      expect(find.text('Body text'), findsOneWidget);
    });
  }

  testWidgets('kept reads in the mastered ink, lost in the warning ink', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxOutcomeTile(label: 'Kept', body: 'a', tone: MxOutcomeTone.kept),
          MxOutcomeTile(label: 'Lost', body: 'b', tone: MxOutcomeTone.lost),
        ],
      ),
    );
    final context = tester.element(find.text('Kept'));

    expect(
      tester.widget<Text>(find.text('Kept')).style!.color,
      context.derivedColors.statusMasteredInk,
    );
    expect(
      tester.widget<Text>(find.text('Lost')).style!.color,
      context.derivedColors.warningInk,
    );
  });
}
```

(Add `import 'package:memox/core/theme/theme_context.dart';` for `context.derivedColors`; drop `mx_semantic_colors.dart` if unused.)

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_outcome_tile_test.dart`
Expected: compile errors: `MxIconTileTone`, `isWarning`, `MxOutcomeTile` are not defined.

- [ ] **Step 3: Implement**

`app_icons.dart` — add, next to the other glyphs, with the lucide name in the comment as the file does:

```dart
  static const IconData lock = Icons.lock_outline; // lock
  static const IconData lockOpen = Icons.lock_open_outlined; // lock-open
  static const IconData resetProgress = Icons.replay; // rotate-ccw
```

`mx_icon_tile.dart`:

```dart
/// The fill: the primary or seed tint (default), or a solid primary or
/// warning square whose glyph takes the matching on-colour (screen 02's
/// lock strip, owner decision D-O1).
enum MxIconTileTone { tinted, primary, warning }
```

Constructor gains `this.tone = MxIconTileTone.tinted` and the assert
`assert(seed == null || tone == MxIconTileTone.tinted, 'a seed only tints')`.
In `build`, replace the fill and glyph colours:

```dart
    final (fill, ink) = switch (tone) {
      MxIconTileTone.tinted => (
        (seed ?? colors.primary).withValues(alpha: tint),
        seed ?? colors.primary,
      ),
      MxIconTileTone.primary => (colors.primary, colors.onPrimary),
      MxIconTileTone.warning => (
        context.semanticColors.warning,
        context.semanticColors.onWarning,
      ),
    };
```

and use `fill` for the `BoxDecoration.color` and `ink` for the `Icon.color`.

`app_decorations.dart`:

```dart
  /// The warning-soft ground with the warning border: a state that asks
  /// for care, such as a locked review algorithm (screen 02).
  static BoxDecoration warningCard(ColorScheme scheme, MxDerivedColors derived) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.warningSoft, raised.color!),
      border: Border.all(color: derived.warningBorder, width: AppStroke.hairline),
    );
  }
```

`mx_card.dart`: add `this.isWarning = false` with `assert(!(isHero && isWarning), 'a hero or a warning card')`, a doc comment `/// The warning-soft ground (screen 02's locked strip, D-O1).`, and pick the surface:

```dart
    final surface = switch ((isHero, isWarning)) {
      (true, _) => AppDecorations.heroCard(context.colors, context.derivedColors),
      (_, true) => AppDecorations.warningCard(context.colors, context.derivedColors),
      _ => AppDecorations.raisedCard(context.colors, context.derivedColors),
    };
```

`mx_outcome_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What an outcome keeps or loses (the reset dialog of screen 02, D-O2).
enum MxOutcomeTone { kept, lost }

/// A labelled consequence: the label in its tone's ink over its tint, and
/// the body under it. "Kept" uses the mastered ink (spec A10), "Lost" the
/// warning ink; both reach 4.5:1 on their ground.
class MxOutcomeTile extends StatelessWidget {
  const MxOutcomeTile({
    super.key,
    required this.label,
    required this.body,
    required this.tone,
  });

  final String label;
  final String body;
  final MxOutcomeTone tone;

  static const double _tint = 0.12;

  @override
  Widget build(BuildContext context) {
    final derived = context.derivedColors;
    final styles = context.textStyles;
    final (ground, edge, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        context.semanticColors.statusMastered.withValues(alpha: _tint),
        derived.ghostBorder,
        derived.statusMasteredInk,
      ),
      MxOutcomeTone.lost => (
        derived.warningSoft,
        derived.warningBorder,
        derived.warningInk,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: edge, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.grouped),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(label, style: styles.badgeLabel(ink)),
            Text(body, style: styles.rowDescription),
          ],
        ),
      ),
    );
  }
}
```

If `context.semanticColors` names the mastered status colour differently, use that name (it is `semantic.statusMastered` in `mx_derived_colors_test.dart`).

Gallery: in `gallery_surfaces_section.dart`, add to the icon-tile `Row` two tiles, `MxIconTile(icon: AppIcons.lockOpen, size: MxIconTileSize.medium, tone: MxIconTileTone.primary)` and the same with `AppIcons.lock` and `MxIconTileTone.warning`, and after the hero card a `const MxCard(isWarning: true, child: MxListSectionHeader(label: 'Warning card'))`. In `gallery_status_section.dart`, add a `Row(spacing: AppSpacing.control, children: [Expanded(child: MxOutcomeTile(label: 'Kept', body: 'Decks, cards and history', tone: MxOutcomeTone.kept)), Expanded(child: MxOutcomeTile(label: 'Lost', body: 'Schedules and due dates', tone: MxOutcomeTone.lost))])`. The gallery is debug-only, so its literals are allowed where the file already uses them.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/shared/widgets test/core/theme --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(shared): icon tile tones, a warning card and the outcome tile for screen 02" -m "<trailer>"
```

---

### Task 3: Copy for screen 02

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/deck/presentation/deck_messages_test.dart`

**Interfaces:**
- Produces (en value / vi value; `description` "Screen handoff 02 (library alignment phase D): <key>." unless noted):

| Key | en | vi | Placeholders |
|---|---|---|---|
| `algorithmUnlockedTitle` | `Can still be changed` | `Vẫn còn đổi được` | |
| `algorithmUnlockedBody` | `Locks once the first card finishes learning.` | `Sẽ khoá khi thẻ đầu tiên học xong.` | |
| `algorithmLockedTitle` | `Locked · cycle {cycle}` | `Đã khoá · chu kỳ {cycle}` | cycle int |
| `algorithmLockedBody` | `The first card finished learning on {date}. Only a reset opens a new cycle.` | `Thẻ đầu tiên học xong ngày {date}. Chỉ đặt lại mới mở chu kỳ mới.` | date String |
| `algorithmHeader` | `Algorithm` | `Thuật toán` | |
| `algorithmEightBoxDescription` | `Remembered → one box up (1 · 2 · 4 · 8 · 16 · 32 · 64 · 128 days). Forgotten → back to box 1. Forgiving of long breaks. Review modes: match, guess, recall, fill.` | `Nhớ → lên một hộp (1 · 2 · 4 · 8 · 16 · 32 · 64 · 128 ngày). Quên → về hộp 1. Dễ tha thứ khi nghỉ lâu. Chế độ ôn: ghép, đoán, nhớ lại, điền.` | |
| `algorithmSm2Description` | `Intervals adapt to how well you recall each card; you grade yourself again · hard · good · easy. One review mode: self-assess.` | `Khoảng cách tự điều chỉnh theo mức bạn nhớ từng thẻ; bạn tự chấm lại · khó · tốt · dễ. Một chế độ ôn: tự đánh giá.` | |
| `algorithmSwitchNote` | `Switching re-initialises every card's schedule in this tree and closes any open study session. Choosing the current algorithm changes nothing.` | `Đổi thuật toán sẽ khởi tạo lại lịch của mọi thẻ trong cây này và đóng phiên học đang mở. Chọn thuật toán hiện tại thì không có gì thay đổi.` | |
| `algorithmLockedNote` | `To change the algorithm now, reset learning progress below and choose the algorithm for the new cycle.` | `Muốn đổi thuật toán bây giờ, hãy đặt lại tiến độ học bên dưới và chọn thuật toán cho chu kỳ mới.` | |
| `algorithmStartOverHeader` | `Start over` | `Bắt đầu lại` | |
| `algorithmResetTitle` | `Reset learning progress` | `Đặt lại tiến độ học` | |
| `algorithmResetBody` | `Every card in this tree becomes new and a new cycle begins. You choose the algorithm for it. Decks, cards, tags and past history are kept.` | `Mọi thẻ trong cây này trở lại thẻ mới và một chu kỳ mới bắt đầu. Bạn chọn thuật toán cho chu kỳ đó. Bộ thẻ, thẻ, tag và lịch sử cũ được giữ nguyên.` | |
| `algorithmResetAction` | `Reset learning progress…` | `Đặt lại tiến độ học…` | |
| `algorithmSwitchTitle` | `Switch to {algorithm}?` | `Chuyển sang {algorithm}?` | algorithm String |
| `algorithmSwitchBody` | `Every card's schedule in this tree starts over and any open study session closes. No history is lost.` | `Lịch của mọi thẻ trong cây này bắt đầu lại và phiên học đang mở sẽ đóng. Không mất lịch sử nào.` | |
| `algorithmSwitchConfirm` | `Switch` | `Chuyển` | |
| `algorithmSwitchedToast` | `Switched to {algorithm} · every card starts fresh` | `Đã chuyển sang {algorithm} · mọi thẻ bắt đầu lại` | algorithm String |
| `algorithmSwitchFailedTitle` | `Couldn’t switch.` | `Không chuyển được.` | |
| `algorithmSwitchFailedBody` | `The deck still uses {algorithm}.` | `Bộ thẻ vẫn dùng {algorithm}.` | algorithm String |
| `resetDialogTitle` | `Reset learning progress?` | `Đặt lại tiến độ học?` | |
| `resetDialogIntro` | `This starts cycle {cycle} for {deck} and its {count, plural, =1{1 card} other{{count} cards}}.` | `Việc này bắt đầu chu kỳ {cycle} cho {deck} và {count} thẻ của nó.` | cycle int, deck String, count int |
| `resetKeptLabel` | `Kept` | `Giữ lại` | |
| `resetKeptBody` | `Decks, sub-decks, cards, tags, notes, and every past answer (labelled cycle {cycle})` | `Bộ thẻ, bộ thẻ con, thẻ, tag, ghi chú và mọi câu trả lời cũ (ghi là chu kỳ {cycle})` | cycle int |
| `resetLostLabel` | `Lost` | `Mất` | |
| `resetLostBody` | `Every card's schedule, due date and progress. {count, plural, =1{The card becomes new} other{All {count} cards become new}}` | `Lịch, ngày đến hạn và tiến độ của mọi thẻ. Cả {count} thẻ trở lại thẻ mới` | count int |
| `resetLostBodyWithSession` | `Every card's schedule, due date and progress; the open session. {count, plural, =1{The card becomes new} other{All {count} cards become new}}` | `Lịch, ngày đến hạn và tiến độ của mọi thẻ; phiên học đang mở. Cả {count} thẻ trở lại thẻ mới` | count int |
| `resetNothingToLose` | `Nothing has been studied in this cycle yet, so there is nothing to lose. A new cycle starts with the algorithm you pick.` | `Chu kỳ này chưa học gì nên không mất gì cả. Chu kỳ mới bắt đầu với thuật toán bạn chọn.` | |
| `resetAlgorithmHeader` | `Algorithm for the new cycle` | `Thuật toán cho chu kỳ mới` | |
| `resetKeep` | `Keep {algorithm}` | `Giữ {algorithm}` | algorithm String |
| `resetSwitchTo` | `Switch to {algorithm}` | `Chuyển sang {algorithm}` | algorithm String |
| `resetConfirm` | `Reset and start cycle {cycle}` | `Đặt lại và bắt đầu chu kỳ {cycle}` | cycle int |
| `resetRunning` | `Resetting…` | `Đang đặt lại…` | |
| `resetDoneToast` | `Cycle {cycle} started · {count, plural, =1{1 card is new again} other{{count} cards are new again}}` | `Đã bắt đầu chu kỳ {cycle} · {count} thẻ trở lại thẻ mới` | cycle int, count int |

Change the en value of `deckSchedulerEightBox` to `Eight boxes` (ruling D-L4).

- [ ] **Step 1: Write the failing test**

In `deck_messages_test.dart`, inside the per-locale loop, add:

```dart
    test('screen 02 has ${locale.languageCode} copy', () {
      for (final copy in [
        l10n.algorithmLockedTitle(2),
        l10n.algorithmLockedBody('15 Oct 2025'),
        l10n.resetDialogIntro(2, 'Korean', 1248),
        l10n.resetLostBodyWithSession(1),
        l10n.resetDoneToast(2, 1),
        l10n.algorithmSwitchedToast('SM-2'),
      ]) {
        expect(copy.trim(), isNotEmpty);
        expect(copy, isNot(contains('{')));
      }
    });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/deck/presentation/deck_messages_test.dart`
Expected: compile error, the getters do not exist.

- [ ] **Step 3: Add the keys**

Add every key in the table to both ARB files (en with `@key` metadata; placeholders before description), then `flutter gen-l10n`.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter gen-l10n && flutter test test/features/deck/presentation/deck_messages_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(l10n): copy for screen 02, review algorithm and reset" -m "<trailer>"
```

---

### Task 4: The reset read and write reach the deck presentation

**Files:**
- Create: `lib/features/deck/presentation/providers/get_reset_learning_summary_use_case_provider.dart`
- Create: `lib/features/deck/presentation/providers/reset_learning_progress_use_case_provider.dart`
- Create: `lib/features/deck/presentation/providers/reset_learning_summary_provider.dart`
- Modify: `lib/features/deck/presentation/controllers/deck_actions_controller.dart`
- Test: `test/features/deck/presentation/deck_reset_wiring_test.dart` (new)

**Interfaces:**
- Consumes: `GetResetLearningSummaryUseCase`, `ResetLearningProgressUseCase` (`lib/features/srs/domain/usecases/`), `scheduleRepositoryProvider` (`lib/features/srs/di/`).
- Produces:
  - `resetLearningSummaryProvider(String rootDeckId)` → `Future<Outcome<ResetLearningSummary, SrsRejection>>`;
  - `DeckActionsController.resetLearning({required String rootDeckId, SchedulerType? schedulerType})` → `Future<Outcome<void, SrsRejection>>`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/reset_learning_summary_provider.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

void main() {
  libraryTest('the summary counts the tree and what a reset takes', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 30));
    await insertCard(env.db, id: 'b', deckId: words.id);
    final container = env.container();

    final outcome = await container.read(resetLearningSummaryProvider(korean.id).future);

    final summary = (outcome as Ok).value;
    expect(summary.cardCount, 2);
    expect(summary.learnedCardCount, 1);
    expect(summary.schedulerType, SchedulerType.sm2);
    expect(summary.hasProgressToLose, isTrue);
  });

  libraryTest('resetLearning starts a new cycle with the chosen algorithm', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    final container = env.container();

    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .resetLearning(rootDeckId: korean.id, schedulerType: SchedulerType.eightBox);

    expect(outcome, isA<Ok<void, Object>>());
    final root = await env.db.customSelect(
      'SELECT generation, scheduler_type, first_answered_at FROM deck WHERE id = ?',
      variables: [Variable<String>(korean.id)],
    ).getSingle();
    expect(root.read<int>('generation'), 2);
    expect(root.read<String>('scheduler_type'), 'eight_box');
    expect(root.read<DateTime?>('first_answered_at'), isNull);
  });
}
```

Read `test/support/library_harness.dart` first: `LibraryEnv` exposes the database and a way to build a `ProviderContainer` with its overrides. If it has no `container()` helper, build one in the test from the same overrides the harness passes to `ProviderScope` (`ProviderContainer(overrides: libraryOverrides(env))` or the harness's equivalent), and `addTearDown(container.dispose)`. Use `drift`'s `Variable` import (`package:drift/drift.dart show Variable`). If `SchedulerType` stores `eight_box` under another code, compare with `SchedulerType.eightBox.code`.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_reset_wiring_test.dart`
Expected: compile error, `resetLearningSummaryProvider` and `resetLearning` are not defined.

- [ ] **Step 3: Implement**

`get_reset_learning_summary_use_case_provider.dart`:

```dart
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_reset_learning_summary_use_case_provider.g.dart';

@riverpod
GetResetLearningSummaryUseCase getResetLearningSummaryUseCase(Ref ref) =>
    GetResetLearningSummaryUseCase(ref.watch(scheduleRepositoryProvider));
```

`reset_learning_progress_use_case_provider.dart`:

```dart
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/usecases/reset_learning_progress_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_learning_progress_use_case_provider.g.dart';

@riverpod
ResetLearningProgressUseCase resetLearningProgressUseCase(Ref ref) =>
    ResetLearningProgressUseCase(ref.watch(scheduleRepositoryProvider));
```

`reset_learning_summary_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/providers/get_reset_learning_summary_use_case_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_learning_summary_provider.g.dart';

/// What resetting [rootDeckId]'s tree would clear, for the reset dialog
/// (UC-SRS-001 step 2).
@riverpod
Future<Outcome<ResetLearningSummary, SrsRejection>> resetLearningSummary(
  Ref ref,
  String rootDeckId,
) => ref.watch(getResetLearningSummaryUseCaseProvider)(rootDeckId: rootDeckId);
```

`deck_actions_controller.dart` — add the import of `reset_learning_progress_use_case_provider.dart` and:

```dart
  /// UC-SRS-001 steps 3 to 5: a new cycle for [rootDeckId]'s tree, keeping
  /// its algorithm or switching to [schedulerType].
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) => ref.read(resetLearningProgressUseCaseProvider)(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_reset_wiring_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add lib test
git commit -m "feat(deck): the reset summary and the reset command for screen 02" -m "<trailer>"
```

---

### Task 5: The algorithm screen and the switch

**Files:**
- Create: `lib/features/deck/presentation/screens/deck_algorithm_screen.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_lock_strip_widget.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_algorithm_options_widget.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_start_over_widget.dart`
- Create: `lib/features/deck/presentation/widgets/overlays/deck_switch_algorithm_dialog_widget.dart`
- Modify: `test/support/library_harness.dart` (a `deckAlgorithmScreen(...)` builder)
- Test: `test/features/deck/presentation/deck_algorithm_screen_test.dart` (new)

**Interfaces:**
- Consumes: `deckViewProvider(deckId)` (`AsyncValue<Outcome<DeckView, DeckRejection>>`), `DeckActionsController.changeScheduler`, `DeckGoneStateWidget({required VoidCallback onBackToLibrary})`, `schedulerType(...)` (`scheduler_type_label_widget.dart`), `srsRejection(...)` (`srs_rejection_message_widget.dart`), Task 2 and Task 3.
- Produces:
  - `DeckAlgorithmScreen({required String deckId, required ValueChanged<String?> onOpenAncestor})`;
  - `Future<bool> showSwitchAlgorithmDialog(BuildContext, {required String algorithm})` (true when confirmed);
  - `DeckStartOverWidget({required VoidCallback onReset})`, which Task 6 wires to the reset dialog.

The screen, top to bottom, inside `MxScreenScroll`:
1. `MxAppBar(title: l10n.deckReviewAlgorithm, density: content, leading: back)`, then `MxBreadcrumb` Library › root name › `deckReviewAlgorithm` (last segment untappable), as `_OpenDeckContent` builds it;
2. `DeckLockStripWidget(view: view)`: unlocked → `MxCard(isHero)` with `MxIconTile(icon: AppIcons.lockOpen, size: medium, tone: primary)`, `algorithmUnlockedTitle` (`rowTitle`) and `algorithmUnlockedBody` (`rowDescription`); locked → `MxCard(isWarning)` with `MxIconTile(icon: AppIcons.lock, size: medium, tone: warning)`, `algorithmLockedTitle(deck.generation!)` and `algorithmLockedBody(date)` where `date` is `deck.firstAnsweredAt` formatted as the Global Constraints say. Wrap the strip in `Semantics(container: true)` so TalkBack reads title and body together;
3. when `_switchFailedFrom != null`: `MxInlineBanner(tone: MxBannerTone.danger, title: l10n.algorithmSwitchFailedTitle, message: l10n.algorithmSwitchFailedBody(l10n.schedulerType(_switchFailedFrom!)), actions: [MxButton(label: l10n.commonRetry, size: MxButtonSize.compact, onPressed: () => _switchTo(_retryTarget!))])` (ruling D-L2);
4. `MxListSectionHeader(label: l10n.algorithmHeader)` and `DeckAlgorithmOptionsWidget`: an `MxCard(isFullBleed: true)` with one `MxOptionRow` per `SchedulerType.values` — title `schedulerType(type)`, description `algorithmEightBoxDescription` / `algorithmSm2Description`, `isSelected: type == view.schedulerType`, `onSelected` null when locked or while switching, `trailing: MxSpinner()` on the row being switched to, `hasDivider` false on the last;
5. `MxNote(text: isLocked ? l10n.algorithmLockedNote : l10n.algorithmSwitchNote, icon: isLocked ? AppIcons.lock : AppIcons.info)`;
6. `MxListSectionHeader(label: l10n.algorithmStartOverHeader)` and `DeckStartOverWidget`: `MxCard` with `algorithmResetTitle` (`rowTitle`), `algorithmResetBody` (`rowDescription`) and `MxButton(label: l10n.algorithmResetAction, tone: MxButtonTone.outline, icon: AppIcons.resetProgress, onPressed: onReset)`. In this task `onReset` is `() {}`; Task 6 replaces it.

States of `deckViewProvider(deckId)`:
- `AsyncData(value: Ok(:final value))` with `value.deck.isRoot` → the screen above;
- `AsyncData(value: Ok())` for a non-root, or `AsyncData(value: Rejected())` → `DeckGoneStateWidget(onBackToLibrary: () => onOpenAncestor(null))` (D-L3);
- `AsyncError()` → `MxErrorState(title: l10n.deckLoadErrorTitle, body: l10n.libraryLoadErrorBody, retryLabel: l10n.commonRetry, onRetry: () => ref.invalidate(provider))`;
- otherwise four `MxSkeletonRow`s.

The switch (a `ConsumerStatefulWidget` state holds `SchedulerType? _switchingTo`, `SchedulerType? _switchFailedFrom`, `SchedulerType? _retryTarget`):

```dart
  Future<void> _onSelected(DeckView view, SchedulerType type) async {
    // UC-DECK-002 A4: the current algorithm changes nothing.
    if (type == view.schedulerType) return;
    final l10n = context.l10n;
    final isConfirmed = await showSwitchAlgorithmDialog(
      context,
      algorithm: l10n.schedulerType(type),
    );
    if (!isConfirmed || !mounted) return;
    await _switchTo(view, type);
  }

  Future<void> _switchTo(DeckView view, SchedulerType type) async {
    setState(() {
      _switchingTo = type;
      _switchFailedFrom = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .changeScheduler(rootDeckId: view.deck.id, schedulerType: type);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.algorithmSwitchedToast(l10n.schedulerType(type)),
          // D-L1: a tree that just locked, or a deck gone meanwhile.
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      setState(() => _switchingTo = null);
    } on Failure {
      if (!mounted) return;
      // D-L2 (UC-DECK-002 E2): nothing changed; say so with Retry.
      setState(() {
        _switchingTo = null;
        _switchFailedFrom = view.schedulerType;
        _retryTarget = type;
      });
    }
  }
```

Adjust the Retry button to call `_switchTo(view, _retryTarget!)`.

`deck_switch_algorithm_dialog_widget.dart`:

```dart
/// UC-DECK-002 steps 3–4 (spec A9): a switch asks first, without the
/// destructive tone, because nothing is deleted.
Future<bool> showSwitchAlgorithmDialog(
  BuildContext context, {
  required String algorithm,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return MxDialog(
          title: l10n.algorithmSwitchTitle(algorithm),
          body: l10n.algorithmSwitchBody,
          actions: MxSheetActions(
            cancelLabel: l10n.commonCancel,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: l10n.algorithmSwitchConfirm,
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    ) ??
    false;
```

- [ ] **Step 1: Write the failing tests**

Add to `test/support/library_harness.dart`:

```dart
/// Screen 02 for [deckId], with its breadcrumb callback.
DeckAlgorithmScreen deckAlgorithmScreen({
  required String deckId,
  ValueChanged<String?>? onOpenAncestor,
}) => DeckAlgorithmScreen(
  deckId: deckId,
  onOpenAncestor: onOpenAncestor ?? (_) {},
);
```

`deck_algorithm_screen_test.dart`:

```dart
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('unlocked: the current algorithm is selected; switching asks first', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));

    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
    expect(find.text(_en.algorithmSwitchNote), findsOneWidget);
    final sm2 = tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, _en.deckSchedulerSm2));
    expect(sm2.isSelected, isTrue);

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    expect(find.text(_en.algorithmSwitchTitle(_en.deckSchedulerEightBox)), findsOneWidget);
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.algorithmSwitchedToast(_en.deckSchedulerEightBox)),
      findsOneWidget,
    );
    final eightBox = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.deckSchedulerEightBox),
    );
    expect(eightBox.isSelected, isTrue);
  });

  libraryTest('cancelling the switch changes nothing (UC-DECK-002 A3)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    final sm2 = tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, _en.deckSchedulerSm2));
    expect(sm2.isSelected, isTrue);
  });

  libraryTest('tapping the current algorithm does nothing (UC-DECK-002 A4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));

    await tester.tap(find.text(_en.deckSchedulerSm2));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
  });

  libraryTest('locked: cycle and date named, options disabled, the note points to reset', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));

    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
    expect(find.text(_en.algorithmLockedBody('Sep 20, 2026')), findsOneWidget);
    expect(find.text(_en.algorithmLockedNote), findsOneWidget);
    for (final title in [_en.deckSchedulerSm2, _en.deckSchedulerEightBox]) {
      final row = tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, title));
      expect(row.onSelected, isNull, reason: title);
    }
    expect(find.text(_en.algorithmResetAction), findsOneWidget);
  });

  libraryTest('a switch refused because the tree just locked says why (E4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await lockScheduler(env.db, korean.id);
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.srsRejectionSchedulerLocked), findsOneWidget);
    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
  });

  libraryTest('a root deleted while open shows the gone state', (tester, env) async {
    final korean = await env.decks.root('Korean');
    String? ancestor = 'unset';
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id, onOpenAncestor: (id) => ancestor = id),
    );

    await env.decks.deleteDeck(deckId: korean.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    await tester.tap(find.text(_en.deckBackToLibrary));
    expect(ancestor, isNull);
  });

  libraryTest('a sub-deck has no algorithm screen (BR-DECK-025)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: words.id));

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    expect(find.byType(MxOptionRow), findsNothing);
  });

  libraryTest('the breadcrumb leads to the Library and the root', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final opened = <String?>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id, onOpenAncestor: opened.add),
    );

    await tester.tap(find.descendant(of: find.byType(MxBreadcrumb), matching: find.text('Korean')));
    await tester.tap(find.descendant(of: find.byType(MxBreadcrumb), matching: find.text(_en.navLibrary)));

    expect(opened, [korean.id, null]);
  });

  libraryTest('at 2x on a 360 phone the locked screen does not overflow', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Từ vựng tiếng Hàn rất dài để thử cỡ chữ', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id), textScale: 2);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

Imports: `flutter/material.dart`, `flutter_test`, `app_localizations.dart`, `scheduler_type_model.dart`, `mx_option_row.dart`, `mx_dialog.dart`, `mx_breadcrumb.dart`, and the `support/` files `deck_fixtures.dart`, `library_harness.dart`, `widget_harness.dart`. The locked date: `lockScheduler` writes `DateTime(2026, 9, 20)`; `DateFormat.yMMMd('en')` gives `Sep 20, 2026`. If the harness stores it as UTC and the local offset shifts the day, compare with `DateFormat.yMMMd('en').format(DateTime(2026, 9, 20).toLocal())` instead of the literal.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_algorithm_screen_test.dart`
Expected: compile error, `DeckAlgorithmScreen` does not exist.

- [ ] **Step 3: Implement** the files listed, as described above this task's steps. Each section widget is a `StatelessWidget` taking what it draws; the screen is a `ConsumerStatefulWidget`; the switch methods live on its state.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_algorithm_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): screen 02, the review algorithm and its switch" -m "<trailer>"
```

---

### Task 6: The reset dialog

**Files:**
- Create: `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart`
- Modify: `lib/features/deck/presentation/screens/deck_algorithm_screen.dart` (`onReset`)
- Test: `test/features/deck/presentation/deck_reset_dialog_test.dart` (new)

**Interfaces:**
- Consumes: `resetLearningSummaryProvider`, `DeckActionsController.resetLearning` (Task 4), `MxOutcomeTile` (Task 2), Task 3 copy, `DeckStartOverWidget.onReset` (Task 5).
- Produces: `Future<void> showResetLearningDialog(BuildContext, {required DeckView view})`.

Dialog (`ConsumerStatefulWidget`, state `SchedulerType _choice = view.schedulerType`, `bool _isResetting = false`):

- `MxDialog(title: l10n.resetDialogTitle, content: ..., actions: MxSheetActions(...))`. The `content` is a `Column` of:
  - while the summary loads: `MxSkeletonRow()`; on `Rejected(:reason)`: `Text(l10n.srsRejection(reason))`;
  - `summary.hasProgressToLose` false: `Text(l10n.resetNothingToLose, style: rowDescription)`;
  - otherwise: `Text(l10n.resetDialogIntro(cycle + 1, view.deck.name, summary.cardCount))`, then `IntrinsicHeight(child: Row(crossAxisAlignment: stretch, spacing: grouped, children: [Expanded(MxOutcomeTile(label: resetKeptLabel, body: resetKeptBody(cycle), tone: kept)), Expanded(MxOutcomeTile(label: resetLostLabel, body: summary.openSessionCount > 0 ? resetLostBodyWithSession(summary.cardCount) : resetLostBody(summary.cardCount), tone: lost))]))`, where `cycle = view.deck.generation!`;
  - `MxListSectionHeader(label: l10n.resetAlgorithmHeader)` and an `MxCard(isFullBleed: true)` of two `MxOptionRow`s: `resetKeep(schedulerType(current))` and `resetSwitchTo(schedulerType(other))`, selected by `_choice`, both disabled while resetting.
- Actions: `cancelLabel: commonCancel`, `onCancel` pops (disabled while resetting: pass a no-op), `confirmLabel: _isResetting ? l10n.resetRunning : l10n.resetConfirm(cycle + 1)`, `confirmIcon: AppIcons.resetProgress`, `onConfirm: summary loaded && !_isResetting ? _reset : null`.
- `_reset`:

```dart
  Future<void> _reset() async {
    setState(() => _isResetting = true);
    final view = widget.view;
    final cycle = view.deck.generation! + 1;
    final cardCount = _summary!.cardCount;
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .resetLearning(
            rootDeckId: view.deck.id,
            schedulerType: _choice == view.schedulerType ? null : _choice,
          );
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.resetDoneToast(cycle, cardCount),
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      // UC-SRS-001 E1: rolled back; the dialog stays for another try.
      setState(() => _isResetting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }
```

`_summary` is the loaded `ResetLearningSummary` read in `build` from `ref.watch(resetLearningSummaryProvider(view.deck.id))`; keep it in a field set from `build` only through the watched value (no `ref.read` in `build`).

In `DeckAlgorithmScreen`, `onReset: () => unawaited(showResetLearningDialog(context, view: view))`.

- [ ] **Step 1: Write the failing tests**

```dart
final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _openReset(WidgetTester tester) async {
  await tester.tap(find.text(_en.algorithmResetAction));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('with progress: cycle, Kept and Lost; keeping the algorithm resets it', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 30));
    await insertCard(env.db, id: 'b', deckId: words.id);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));
    await _openReset(tester);

    expect(find.text(_en.resetDialogIntro(2, 'Korean', 2)), findsOneWidget);
    expect(find.text(_en.resetKeptBody(1)), findsOneWidget);
    expect(find.text(_en.resetLostBody(2)), findsOneWidget);
    final keep = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.resetKeep(_en.deckSchedulerSm2)),
    );
    expect(keep.isSelected, isTrue);

    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDoneToast(2, 2)), findsOneWidget);
    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
    final sm2 = tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, _en.deckSchedulerSm2));
    expect(sm2.isSelected, isTrue);
  });

  libraryTest('switching in the reset starts the new cycle on the other algorithm', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));
    await _openReset(tester);

    await tester.tap(find.text(_en.resetSwitchTo(_en.deckSchedulerEightBox)));
    await tester.pump();
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    final eightBox = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.deckSchedulerEightBox),
    );
    expect(eightBox.isSelected, isTrue);
  });

  libraryTest('nothing to lose says so and still resets (UC-SRS-001 A2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));
    await _openReset(tester);

    expect(find.text(_en.resetNothingToLose), findsOneWidget);
    expect(find.byType(MxOutcomeTile), findsNothing);
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDoneToast(2, 0)), findsOneWidget);
  });

  libraryTest('an open session is named among what is lost', (tester, env) async {
    final (rootId, _, _) = await insertStudyTree(env.db, 'r');
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: rootId));
    await _openReset(tester);

    expect(find.textContaining('the open session'), findsOneWidget);
  });

  libraryTest('cancelling the reset changes nothing (UC-SRS-001 A3)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id));
    await _openReset(tester);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
  });

  libraryTest('the reset dialog at 2x on a 360 phone does not overflow', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 30));
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: korean.id), textScale: 2);
    await _openReset(tester);

    expect(tester.takeException(), isNull);
  });
}
```

Read `test/support/srs_fixtures.dart` for `insertStudyTree`'s parameters and what it returns (the root id is the first element); if its root is not the tree's root deck, use the id it names as the root. Imports as in Task 5, plus `card_fixtures.dart`, `srs_fixtures.dart` and `mx_outcome_tile.dart`.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_reset_dialog_test.dart`
Expected: FAIL: the reset button opens nothing.

- [ ] **Step 3: Implement** the dialog as described, and wire `onReset`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck/presentation/deck_reset_dialog_test.dart test/features/deck/presentation/deck_algorithm_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck): the reset dialog of screen 02 (UC-SRS-001)" -m "<trailer>"
```

---

### Task 7: The route, the entry from the action sheet, and the scheduler sheet goes

**Files:**
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart` (`onOpenAlgorithm`)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`, `deck_level_list_widget.dart` (thread `onOpenAlgorithm`)
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (`DeckAction.reviewAlgorithm`)
- Delete: `lib/features/deck/presentation/widgets/overlays/deck_scheduler_sheet_widget.dart`
- Modify: `test/support/library_harness.dart` (`deckScreen(onOpenAlgorithm:)`)
- Test: `test/features/deck/presentation/deck_action_sheet_test.dart`, `test/app/library_routes_test.dart`

**Interfaces:**
- Consumes: `DeckAlgorithmScreen` (Task 5).
- Produces: `AppRoutes.algorithmChild = 'algorithm'`, `AppRoutes.deckAlgorithm(String deckId)`; `DeckLevelScreen({..., required ValueChanged<String> onOpenAlgorithm})`; `openDeckActions(..., required ValueChanged<String> onOpenAlgorithm)`.

- [ ] **Step 1: Migrate and write the tests**

In `deck_action_sheet_test.dart`, the tests that choose `_en.deckReviewAlgorithm` and expect the scheduler sheet (its title `deckSchedulerTitle` or its options) now expect the callback:

```dart
  libraryTest('Review algorithm opens screen 02 for a root', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenAlgorithm: opened.add),
    );
    await _choose(tester, _en.deckReviewAlgorithm);

    expect(opened, [korean.id]);
  });
```

Delete the scheduler-sheet tests this replaces (the ones that pick an option in the sheet or read `deckSchedulerChangedToast` / `deckSchedulerLockedNote`); their behaviour now lives in `deck_algorithm_screen_test.dart`. Keep the test that a sub-deck's sheet has no "Review algorithm".

In `library_routes_test.dart`, add:

```dart
  libraryTest('Review algorithm pushes screen 02; Back returns to the deck', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.byTooltip(_en.deckActions));
    await _tap(tester, find.text(_en.deckReviewAlgorithm));

    expect(find.text(_en.algorithmHeader.toUpperCase()), findsOneWidget);
    await _back(tester);
    expect(_barTitle('Korean'), findsOneWidget);
  });
```

Use the helpers the file already defines (`_seed`, `_tap`, `_back`, `_barTitle`); if `_seed` makes no root named `Korean`, open the root it makes.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/deck/presentation/deck_action_sheet_test.dart test/app/library_routes_test.dart`
Expected: FAIL: `onOpenAlgorithm` is not a parameter; the route does not exist.

- [ ] **Step 3: Implement**

`app_routes.dart`:

```dart
  /// A root deck's review algorithm (screen 02), relative to [deckChild].
  static const String algorithmChild = 'algorithm';

  /// Screen 02 for the root [deckId].
  static String deckAlgorithm(String deckId) => '${deck(deckId)}/$algorithmChild';
```

`app_router.dart`: under the `deckChild` route's `routes`, next to `cardNewChild`:

```dart
                    GoRoute(
                      path: AppRoutes.algorithmChild,
                      builder: (context, state) => DeckAlgorithmScreen(
                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                        onOpenAncestor: (id) => _openAncestor(context, id),
                      ),
                    ),
```

and in `_deckLevel`: `onOpenAlgorithm: (id) => unawaited(context.push(AppRoutes.deckAlgorithm(id))),`.

`DeckLevelScreen` gains `required this.onOpenAlgorithm` (`/// A root's review algorithm: the router opens screen 02.`), passed to `_LibraryRoot` and `_OpenDeck`/`_OpenDeckContent`, to `DeckLevelBodyWidget` → `DeckLevelListWidget` (new required `ValueChanged<String> onOpenAlgorithm`), and to every `openDeckActions` call.

`deck_actions_flow_widget.dart`: `openDeckActions` gains `required ValueChanged<String> onOpenAlgorithm`, and:

```dart
    case DeckAction.reviewAlgorithm:
      onOpenAlgorithm(deckId);
```

replacing the `changeScheduler` case and the `deck_scheduler_sheet_widget.dart` import.

`deck_action_sheet_widget.dart`: rename `DeckAction.changeScheduler` to `DeckAction.reviewAlgorithm`.

Delete `deck_scheduler_sheet_widget.dart`. `test/support/library_harness.dart`'s `deckScreen` gains `ValueChanged<String>? onOpenAlgorithm` defaulting to `(_) {}`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/deck test/app --exclude-tags golden`
Expected: PASS.

- [ ] **Step 5: Gate slice and commit**

```bash
dart format lib test && flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
git add -A lib test
git commit -m "feat(deck): Review algorithm opens screen 02; the scheduler sheet goes" -m "<trailer>"
```

---

### Task 8: Goldens, visual check, clean-up, ledgers, the full gate

**Files:**
- Create: `test/features/deck/presentation/deck_algorithm_golden_test.dart`
- Modify: gallery goldens (`test/app/goldens/`), the new screen 02 goldens
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb` (delete copy no code uses)
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (close row 93)
- Modify: `docs/shared/ui/screen-handoff/00-index.md` (02 → `aligned`), `02-review-algorithm.md` (Deviations found in Step 3)
- Modify: `docs/wbs_FE.md` (FE-A4 and FE-A11)

- [ ] **Step 1: The screen 02 goldens**

```dart
@Tags(['golden'])
library;

// imports: flutter/material, flutter_test, scheduler_type_model, app_localizations,
// support/card_fixtures, deck_fixtures, golden_harness, library_harness

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('algorithm unlocked, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckAlgorithmScreen(deckId: korean.id), brightness);
        await expectBoundaryGolden(tester, 'goldens/library_algorithm_unlocked_$theme.png');
      });
    });

    libraryTest('algorithm locked, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await lockScheduler(env.db, korean.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckAlgorithmScreen(deckId: korean.id), brightness);
        await expectBoundaryGolden(tester, 'goldens/library_algorithm_locked_$theme.png');
      });
    });

    libraryTest('reset dialog, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      final words = await env.decks.sub(korean.id, 'Words');
      await insertCard(env.db, id: 'a', deckId: words.id, learnedAt: DateTime(2026, 9, 1), dueAt: DateTime(2026, 9, 30));
      await lockScheduler(env.db, korean.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckAlgorithmScreen(deckId: korean.id), brightness);
        await tester.tap(find.text(_en.algorithmResetAction));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(tester, 'goldens/library_algorithm_reset_$theme.png');
      });
    });
  }
}
```

Match `pumpLibraryGolden`'s real signature in `test/support/library_harness.dart` (as `deck_screens_golden_test.dart` calls it).

- [ ] **Step 2: Regenerate the changed goldens only**

```bash
flutter test --update-goldens --tags golden test/features/deck/presentation/deck_algorithm_golden_test.dart
flutter test --update-goldens --tags golden --plain-name "Gallery" test/app/app_golden_test.dart
flutter test --tags golden test/features/deck test/app
git status --short -- test | grep -v /failures/
```

Expected: new `library_algorithm_*` PNGs and the two gallery PNGs change. A deck golden that now fails only because the sheet's labels changed (`deckSchedulerEightBox`) is a changed screen: regenerate that file too, and say which in the ledger. Restore and delete the `failures/` images.

- [ ] **Step 3: Look at them against the handoff**

Open with the Read tool, light and dark: `library_algorithm_unlocked` against `img/02-review-algorithm/unlocked-*.png`, `library_algorithm_locked` against `locked-*`, `library_algorithm_reset` against `resetConfirm-*`. List every difference not in the handoff's Deviations table; fix them in one batch, re-run Step 2 once, look once more, and stop. Record what remains as Deviations rows with the reason.

- [ ] **Step 4: Remove unused copy**

Run: `grep -rn "deckSchedulerTitle\|deckSchedulerChangeWarning\|deckSchedulerLockedNote\|deckSchedulerChangedToast" lib test | grep -v generated`

Delete each key no code or test uses from both ARB files (parse and re-dump them as JSON with 2-space indent and `ensure_ascii=False`, which is the files' format), run `flutter gen-l10n` and `flutter analyze`.

- [ ] **Step 5: Debt register, index, ledgers**

- UI-base spec §9 row 93 (`"Review algorithm" opens the scheduler sheet, not screen 02, until phase D`): append ` — closed by library alignment phase D`.
- `00-index.md`: row 02 → `aligned`.
- `wbs_FE.md`: FE-A4 status → `xong`, and its last cell → `Màn 02 của screen handoff, phase D của FE-A11 (PR này)`; FE-A11's last cell → `Phase A (#32), B (#34), C (#38) xong; phase D (02) trong PR này; phase E sau khi merge`.

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

Expected: every command clean except `flutter test` and DoD, which fail only on goldens that also fail on master and that this phase did not regenerate; every regenerated golden passes; no non-golden test fails. Restore and delete the `failures/` images.

**Scope check:** `git diff --stat origin/master...HEAD -- lib/features/card lib/features/srs` prints nothing.

- [ ] **Step 7: Commit**

```bash
git add lib test docs
git commit -m "test(deck): screen 02 goldens on Linux; close debt row 93; ledgers" -m "<trailer>"
```
