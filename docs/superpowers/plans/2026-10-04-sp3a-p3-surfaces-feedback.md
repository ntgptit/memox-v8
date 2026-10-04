# SP3a Phase 3 — Surfaces, Feedback and States Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the 16 Phase 3 catalog components (`MxCard`, `MxSection`, `MxNote`, `MxBadge`, `MxStatusBadge`, `MxTagChip`, `MxIconTile`, `MxLinearProgress`, `MxSkeleton`, `MxDialog`, `MxBottomSheet`, `MxSheetActions`, `MxSnackbar`, `MxInlineBanner`, `MxEmptyState`, `MxErrorState`) with their theme slots, tests and full-HD light/dark goldens, and move each to `built`.

**Architecture:**
- **One style source per family**, in `lib/core/theme/components/`:
  - `surface_style.dart` (card tones, section label);
  - `mark_style.dart` (badge, status, tag, icon tile, progress tones);
  - `feedback_style.dart` (banner, empty-state tile);
  - `overlay_style.dart` (dialog, sheet, snackbar and card theme slots, the scrim).
- **Where widgets live.** Widgets in `lib/shared/widgets/` read only those functions and the generated scales (`AppSize`, `AppSpacing`, …). No literal colour, text style, size or duration appears in `lib/shared/`.
- **Overlays.** Opened through `showMxDialog`, `showMxBottomSheet` and `showMxSnackbar`, which own the route, the scrim and the motion, including reduced motion.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13 (Material 3 `DialogThemeData`, `BottomSheetThemeData`, `SnackBarThemeData`, `CardThemeData`); `flutter_test` goldens through the Phase 2 harness (`expectMxGolden`, 1080 × 2400 at 2.625); Python 3 standard library for the generator.

**Spec:** `docs/superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md` (§4.4 Phase 3, §5 component contract). Phase 2 plan: `docs/superpowers/plans/2026-10-04-sp3a-p2-primitives-controls.md`.

## Global Constraints

- **The API takes meaning, not looks.** Callers pass semantic tones, sizes and localized copy only. They never pass a `Color`, `TextStyle`, `BorderRadius`, `BorderSide`, `BoxShadow`, padding or icon size (spec §5). A composition slot (`MxCard.child`, `MxDialog.content`, `MxBottomSheet.child`) is allowed; a styling slot is not.
- **Every control keeps a 48 × 48 hit area** (The 48 Floor Rule). Text grows: every height is a minimum (The Text Grows Rule).
- **The owner's rulings of 2026-10-04 hold:**
  - `primary` is #4151C6 in both themes.
  - A selection never fills `primary`.
  - The Indigo Accent `on-primary-container` is the indigo foreground.
  - The Selection Ladder Rule and The Contrast Floor Rule apply in both themes.
  - The pre-SP2 code never supplies a value.
- **Every text restyle lives in `lib/core/theme/components/`.** `.apply(color:)` on a theme role is allowed in `lib/shared/`; `.copyWith(` and `TextStyle(` are not (guard `no_text_restyle`, `no_raw_text_style`).
- **No raw colour in `lib/shared/`**, not even `Colors.transparent` (guard `no_raw_color`). Do not name a record local `colors`: the guard reads `colors.x` as a `ColorScheme` role.
- **Code style.** Booleans read as predicates. There is no `else`; code returns early. A row centres its leading and trailing marks (guard `row_marks_centre_on_the_row`).
- **Goldens are full-HD composite sheets** named `mx_<component>__<state>__<variant>.png`, generated in the Linux container only.
- **Commit attribution.** Every commit ends with this session's two attribution lines.

## Decisions (approved by the owner, 2026-10-04)

The owner ruled that the pre-SP2 code may only flag that a decision is needed, never supply a value. Each value below comes from a semantic requirement, Material 3, accessibility or DESIGN.md. Impeccable (`shape`) reviewed each one, and the owner approved them.

| # | Decision | Value | Source |
|---|---|---|---|
| 1 | Generic progress fill | `secondary` (5.08:1 light, 6.71:1 dark on `surface-container-low`); a component that means a state passes that state's tone; never `primary` (2.35:1 on the dark track); no raw colour | The Contrast Floor Rule; Material 3 roles; owner |
| 2a | Icon tile | 32 / 40 / 48, glyph 16 / 20 / 24, r8 / r12 / r12 | Material 3 list leading container 40; 4dp grid; Shapes |
| 2b | Badge | at least 24, label centred, grows with text | Caption line plus padding on the 4dp grid |
| 2c | Tag chip | at least 24, dense 20; at most half the width it is given | 4dp grid; component layout policy |
| 2d | Status dot | 8, standalone and in the pill, 4 from its label | above Material 3's 6; one size |
| 2e | Progress | 4 regular, 8 thick | Material 3 track; Material 3 Expressive thick |
| 2f | Empty and error tile | 64, compact 48; empty r20, error r16; glyph 24 | 8dp grid; Shapes |
| 2g | Dialog widths | 340 / 320 / 300, never wider than the window less 2 × 16 | already in DESIGN.md |
| 2h | Grabber | 32 × 4 in `outline`, in a 48 band | Material 3 drag handle; The 48 Floor Rule |
| 2i | Skeleton | a line as tall as the text it stands for; the row tile is the medium icon tile | the layout does not jump on load |
| 3a | Sheet height | stops 72 below the top safe area; at most 640 wide | Material 3 modal bottom sheet |
| 3b | Component-internal values | the dialog scales from 0.92 over 200ms; skeleton lines at 60% / 40% | component contracts, not global tokens |
| 3c | `AppRatio` | not created | no reusable token remained |
| 4 | `MxButtonTone.inverse` | an `inverse-primary` label for any action on an inverse surface, with its pressed overlay and an `inverse-primary` focus ring | Material 3 inverse roles |
| 5 | Icon tile colour | semantic tones only, a closed set | spec §5 |
| 6 | Footer actions | equal shares while both labels fit one line (measured with `TextPainter`), the confirm trailing; otherwise stacked full width with the confirm on top; Cancel is outline; labels never cut | Material 3 stacked buttons; Android order |

## Review Focus

- **An overlay under reduced motion.** `showMxDialog` and `showMxBottomSheet` must open with no animation. Tested through `MediaQuery.disableAnimations` in Task 5.
- **A snackbar action for a TalkBack user.** It must not vanish after 4–8s. Tested in Task 6 (`persist`).
- **A tall sheet with a keyboard.** It stops 72 below the top safe area, scrolls, and rides above the keyboard. Tested in Task 5.
- **A long tag name or badge at large text.** It must not clip or overflow. The tag stops at half its row and is read whole. Tested in Task 3.
- **Status told by colour alone.** A bare status dot must still be named for TalkBack. Tested in Task 3.

---

### Task 1: Tokens, theme slots, the inverse tone and the footer measure

**Files:**
- Modify: `.impeccable/design.json` (`extensions.size`, `contrastPairs`)
- Regenerate: `lib/core/theme/foundations/app_size.dart`
- Create: `lib/core/theme/components/overlay_style.dart`
- Modify: `lib/core/theme/app_theme.dart`, `lib/core/theme/components/button_style.dart`, `lib/shared/widgets/primitives/mx_focus_ring.dart`, `lib/shared/widgets/mx_button.dart`
- Test: `test/core/theme/app_theme_test.dart`, `test/shared/widgets/mx_button_test.dart`; golden `mx_button__tones__*` re-rendered (it shows every tone)
- Modify: `DESIGN.md` (Colors › Primary and Secondary, The Selection Ladder Rule, and the component lines for the tag chip, sheet actions and bottom sheet: decisions 1, 2c, 3a, 6)

**Interfaces:**
- Produces:
  - the `AppSize` tokens of decision 2: `iconTileSmall/Medium/Large`, `badge`, `tagChip`, `tagChipDense`, `statusDot`, `progress`, `progressThick`, `emptyTile`, `emptyTileCompact`, `dialogSmall/Medium/Large`, `grabberWidth`, `grabberHeight`, `sheetTopClearance` and `sheetMaxWidth`;
  - `mxScrim(ColorScheme)`, `mxOverlayGround(ColorScheme)`, `mxDialogTheme`, `mxBottomSheetTheme`, `mxSnackBarTheme` and `mxCardTheme`;
  - `MxButtonTone.inverse`;
  - `mxCanButtonLabelFit({texts, label, width, textScaler})`;
  - `MxFocusRing(isOnInverse:)`.

- [ ] **Step 1: The token values and pairs**

Run from the repo root (a one-off, not committed). The status, success, warning and error fills already have their pairs on `surface-container-low`; only four pairs are new:

```bash
python3 - <<'PYEOF'
import json
from pathlib import Path
s = Path(".impeccable/design.json")
d = json.loads(s.read_text(encoding="utf-8"))
e = d["extensions"]
e["size"].update({"icon-tile-small": 32, "icon-tile-medium": 40, "icon-tile-large": 48, "badge": 24,
    "tag-chip": 24, "tag-chip-dense": 20, "status-dot": 8, "progress": 4, "progress-thick": 8,
    "empty-tile": 64, "empty-tile-compact": 48, "dialog-small": 300, "dialog-medium": 320,
    "dialog-large": 340, "grabber-width": 32, "grabber-height": 4, "sheet-top-clearance": 72,
    "sheet-max-width": 640})
pairs = e["contrastPairs"]
for bg in ("surface-container-low", "surface-container"):
    pairs.append({"fg": "secondary", "bg": bg, "min": 3.0, "use": "the generic progress fill on its track"})
for bg in ("warning-container", "error-container"):
    pairs.append({"fg": "on-primary-container", "bg": bg, "min": 4.5, "use": "a banner's text action"})
s.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
PYEOF
python3 tools/design/generate.py --write && python3 tools/design/generate.py --check
```

Expected: `wrote 12 files …` then `PASS …`. A `primary` on `surface-container-low` pair would fail at 2.35:1 in dark (decision 1).

- [ ] **Step 2: DESIGN.md first**

In `DESIGN.md`:
- **Colors › Primary.** Replace "Primary buttons, the FAB and progress fills, always under `on-primary` (#FFFFFF, 6.53:1); a selection is never a `primary` fill (The Selection Ladder Rule)." with "Primary buttons and the FAB, always under `on-primary` (#FFFFFF, 6.53:1); a selection is never a `primary` fill (The Selection Ladder Rule). `primary` stays the brand action role for any consumer whose contrast pair and meaning fit; the generic progress fill is `secondary` because #4151C6 holds only 2.35:1 on the dark track."
- **Colors › Secondary.** Replace "supporting tonal role; rarely painted directly." with "supporting tonal role; painted directly as the generic progress fill (`MxLinearProgress`), 3:1 or better on its track in both themes."
- **The Selection Ladder Rule.** Replace the Action line with "- **Action:** `primary` fill under `on-primary`: the primary button and the FAB. A selection never fills `primary`; a progress fill is `secondary` (the generic bar) or the tone of the state it means."
- **Component lines:**
  - "**MxTagChip** (22 or 18)" becomes "**MxTagChip** (24 or 20, minimums; at most half its row)";
  - "**MxSheetActions** (dialog and sheet footer, confirm takes 1.3 shares)" becomes "**MxSheetActions** (dialog and sheet footer: equal shares while both labels fit one line, else stacked with the confirm on top)";
  - "**MxBottomSheet** (top corners 20, chrome shadow, grabber)" becomes "**MxBottomSheet** (top corners 20, chrome shadow, a 32 × 4 grabber, 72 clear of the top, at most 640 wide)".

Run: `python3 tools/docs/check.py | tail -1` → `PASS`.

- [ ] **Step 3: Failing tests**

In `test/core/theme/app_theme_test.dart`, add inside the per-theme group, before `'the FAB slot has no elevation in any state'`:

```dart
      test('the overlay and card slots match the Mx surfaces', () {
        expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
        expect(theme.dialogTheme.elevation, 0);
        expect(
          theme.dialogTheme.barrierColor,
          scheme.scrim.withValues(alpha: AppOpacity.scrim),
        );
        expect(
          theme.bottomSheetTheme.modalBackgroundColor,
          scheme.surfaceContainerHigh,
        );
        expect(theme.bottomSheetTheme.showDragHandle, isFalse);
        expect(theme.snackBarTheme.backgroundColor, scheme.inverseSurface);
        expect(theme.snackBarTheme.actionTextColor, scheme.inversePrimary);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
        expect(theme.cardTheme.color, scheme.surfaceContainerLowest);
        expect(theme.cardTheme.elevation, 0);
      });
```

In `test/shared/widgets/mx_button_test.dart`, add `MxButtonTone.inverse: (Colors.transparent, s.inversePrimary),` to the `pairs` map after the warning entry, and at the end of `main`:

```dart
  testWidgets('on an inverse surface the ring is inverse-primary', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Undo', tone: MxButtonTone.inverse, onPressed: () {}),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      find.byType(MxButton),
      paints..rrect(color: mxThemes['light']!.colorScheme.inversePrimary),
    );
  });
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/shared/widgets/mx_button_test.dart` → compile failure on `MxButtonTone.inverse`.

- [ ] **Step 4: The slots, the tone, the ring and the measure**

Create `lib/core/theme/components/overlay_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// The modal scrim: the scheme's `scrim` at 45% (DESIGN.md, Elevation).
Color mxScrim(ColorScheme colors) =>
    colors.scrim.withValues(alpha: AppOpacity.scrim);

/// A floating surface's ground: the Sheet Ground, `surface-container-high`.
Color mxOverlayGround(ColorScheme colors) => colors.surfaceContainerHigh;

/// The dialog slot, matching `MxDialog`: the sheet ground, r20, no tint and
/// no elevation (its shadow is the overlay shadow `MxDialog` paints).
DialogThemeData mxDialogTheme(ColorScheme colors, TextTheme texts) =>
    DialogThemeData(
      backgroundColor: mxOverlayGround(colors),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
      barrierColor: mxScrim(colors),
      titleTextStyle: texts.titleLarge,
      contentTextStyle: texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
    );

/// The bottom-sheet slot, matching `MxBottomSheet`: the sheet ground, top
/// corners 20, the scrim, no Material drag handle (the sheet draws its own
/// grabber), at most 640 wide (Material 3).
BottomSheetThemeData mxBottomSheetTheme(ColorScheme colors) =>
    BottomSheetThemeData(
      backgroundColor: mxOverlayGround(colors),
      modalBackgroundColor: mxOverlayGround(colors),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: mxScrim(colors),
      showDragHandle: false,
      constraints: const BoxConstraints(maxWidth: AppSize.sheetMaxWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    );

/// The snackbar slot: the inverse surface, floating, r12, inset by the
/// gutter, its action in `inverse-primary`.
SnackBarThemeData mxSnackBarTheme(ColorScheme colors, TextTheme texts) =>
    SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.inverseSurface,
      contentTextStyle: texts.bodyMedium?.apply(color: colors.onInverseSurface),
      actionTextColor: colors.inversePrimary,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    );

/// The card slot, matching `MxCard`'s raised tone (its shadow and dark
/// hairline are painted by `MxCard`).
CardThemeData mxCardTheme(ColorScheme colors) => CardThemeData(
  color: colors.surfaceContainerLowest,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
  ),
);
```

In `lib/core/theme/app_theme.dart`, import `components/overlay_style.dart` and add to the `ThemeData(...)` call:

```dart
      dialogTheme: mxDialogTheme(scheme, textTheme),
      bottomSheetTheme: mxBottomSheetTheme(scheme),
      snackBarTheme: mxSnackBarTheme(scheme, textTheme),
      cardTheme: mxCardTheme(scheme),
```

In `lib/core/theme/components/button_style.dart`, add the tone at the end of `MxButtonTone`:

```dart
  /// The action on an inverse surface (a snackbar's Undo): no fill, an
  /// `inverse-primary` label.
  inverse,
```

add its pair at the end of the switch in `mxButtonStyle`:

```dart
    MxButtonTone.inverse => (Colors.transparent, colors.inversePrimary),
```

and append the footer measure (decision 6):

```dart
/// Whether [label] fits one line of a regular button [width] wide at the
/// reader's text scale; footers that share a row stack when it does not.
bool mxCanButtonLabelFit({
  required TextTheme texts,
  required String label,
  required double width,
  required TextScaler textScaler,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: label, style: texts.labelLarge),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final bool canFit =
      painter.width <= width - 2 * MxButtonSize.regular.horizontalPadding;
  painter.dispose();
  return canFit;
}
```

In `lib/shared/widgets/primitives/mx_focus_ring.dart`:
- add this field and a constructor parameter `this.isOnInverse = false,`;
- paint the ring with `widget.isOnInverse ? context.colors.inversePrimary : context.colors.onPrimaryContainer`.

```dart
  /// On an inverse surface (a snackbar) the ring is `inverse-primary`, the
  /// role that holds there; elsewhere it is the Indigo Accent.
  final bool isOnInverse;
```

In `lib/shared/widgets/mx_button.dart`, pass `isOnInverse: tone == MxButtonTone.inverse,` to its `MxFocusRing`.

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/shared/widgets` → all pass.

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_button_golden_test.dart`. Expected: `mx_button__tones__light.png` and `__dark.png` change, because they now show the inverse tone. The other button goldens do not change.

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`. Also: `python3 tools/design/test_generate.py` → `OK`.

- [ ] **Commit**

```bash
git add .impeccable/design.json lib test/core test/shared DESIGN.md
git commit -m "feat(sp3a-p3): Phase 3 tokens, overlay theme slots, the inverse tone and the footer measure

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 2: Surfaces — MxCard, MxNote, MxSection

**Files:**
- Create: `lib/core/theme/components/surface_style.dart`, `lib/shared/widgets/mx_card.dart`, `lib/shared/widgets/mx_note.dart`, `lib/shared/widgets/mx_section.dart`
- Test: `test/shared/widgets/mx_card_test.dart`, `test/shared/widgets/mx_note_test.dart`, `test/shared/widgets/mx_section_test.dart`; golden `test/shared/widgets/mx_surfaces_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxFocusRing`, `MxRowInk`, `MxIconButton`, `expectMxKeyboardRingOnly` (Phase 2).
- Produces: `MxCardTone`, `mxCardSurface(colors, semantic, {{tone, isSelected}})`, `mxSectionLabelStyle`; `MxCard({{child, tone, isSelected, isFullBleed, onTap}})`; `MxNote({{text, onDismiss, dismissLabel}})`, `MxNote.hint({{text}})`; `MxSection({{children, title, note}})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/mx_harness.dart';

BoxDecoration _surface(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxCardTone, Color> grounds = {
      MxCardTone.raised: s.surfaceContainerLowest,
      MxCardTone.hero: s.primaryContainer,
      MxCardTone.warning: x.warningContainer,
      MxCardTone.success: x.successContainer,
      MxCardTone.danger: s.errorContainer,
      MxCardTone.recessed: s.surfaceContainerLow,
    };
    for (final MapEntry(key: tone, value: ground) in grounds.entries) {
      testWidgets('$name: ${tone.name} sits on its ground', (tester) async {
        await pumpMx(
          tester,
          MxCard(tone: tone, child: const Text('Spanish')),
          theme: theme,
        );
        expect(_surface(tester).color, ground);
      });
    }

    testWidgets('$name: raised is a whisper in light, a hairline in dark', (
      tester,
    ) async {
      await pumpMx(tester, const MxCard(child: Text('Spanish')), theme: theme);
      final BoxDecoration box = _surface(tester);
      if (name == 'dark') {
        expect(box.border!.top.color, s.outlineVariant);
        expect(box.boxShadow, isEmpty);
        return;
      }
      expect(box.boxShadow, hasLength(1));
      expect(box.border!.top.style, BorderStyle.none);
    });

    testWidgets('$name: chosen is a 2dp Indigo Accent edge', (tester) async {
      await pumpMx(
        tester,
        const MxCard(isSelected: true, child: Text('Spanish')),
        theme: theme,
      );
      final BorderSide edge = _surface(tester).border!.top;
      expect(edge.color, s.onPrimaryContainer);
      expect(edge.width, AppStroke.control);
    });
  }

  testWidgets('a 20 interior, none when full-bleed', (tester) async {
    await pumpMx(tester, const MxCard(child: Text('Spanish')));
    expect(
      tester.getTopLeft(find.text('Spanish')) -
          tester.getTopLeft(find.byType(MxCard)),
      const Offset(AppSpacing.card, AppSpacing.card),
    );
    await pumpMx(
      tester,
      const MxCard(isFullBleed: true, child: Text('Spanish')),
    );
    expect(
      tester.getTopLeft(find.text('Spanish')),
      tester.getTopLeft(find.byType(MxCard)),
    );
  });

  testWidgets('tinted content reads in the tone\'s on-container', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      const MxCard(tone: MxCardTone.danger, child: Text('Failed')),
    );
    final RenderParagraph text = tester.renderObject(find.text('Failed'));
    expect(text.text.style!.color, s.onErrorContainer);
  });

  testWidgets('a tappable card taps and takes the keyboard ring', (
    tester,
  ) async {
    var taps = 0;
    final Widget card = SizedBox(
      width: 200,
      child: MxCard(onTap: () => taps++, child: const Text('Spanish')),
    );
    await pumpMx(tester, card);
    await tester.tap(find.text('Spanish'));
    expect(taps, 1);
    final Size painted = tester.getSize(find.byType(MxCard));
    await expectMxKeyboardRingOnly(tester, card, painted: painted);
  });
}
```

Create `test/shared/widgets/mx_note_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a note sits on the muted fill with a hairline edge', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxNote(text: 'Synced just now')),
    );
    final BoxDecoration box =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(MxNote),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(box.color, s.surfaceContainerLow);
    expect(box.border!.top.color, s.outlineVariant);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('the hint form has no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxNote.hint(text: 'Kept for 30 days')),
    );
    expect(
      find.descendant(
        of: find.byType(MxNote),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('a one-time note has a named close button', (tester) async {
    var dismissed = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxNote(
          text: 'Swipe a card to grade it',
          onDismiss: () => dismissed++,
          dismissLabel: 'Dismiss tip',
        ),
      ),
    );
    expect(find.byType(MxIconButton), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss tip'));
    expect(dismissed, 1);
  });
}
```

Create `test/shared/widgets/mx_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('an upper-cased overline over one card of split rows', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxSection(
          title: 'Study',
          note: 'Applies to new decks',
          children: [Text('Daily goal'), Text('New cards'), Text('Reviews')],
        ),
      ),
    );
    expect(find.text('STUDY'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('STUDY')),
      isSemantics(isHeader: true, label: 'STUDY'),
    );
    expect(find.byType(MxCard), findsOneWidget);
    expect(find.byType(MxNote), findsOneWidget);
    final double gap =
        tester.getTopLeft(find.text('New cards')).dy -
        tester.getBottomLeft(find.text('Daily goal')).dy;
    expect(gap, greaterThan(0));
    semantics.dispose();
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_note_test.dart test/shared/widgets/mx_section_test.dart`
Expected: compile failure, because the sources under test do not exist yet.

- [ ] **Step 3: Write the styles and widgets**

Create `lib/core/theme/components/surface_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// What a card means (DESIGN.md, Containers › MxCard); one tone at a time.
enum MxCardTone {
  /// The everyday card: `surface-container-lowest`, the whisper shadow in
  /// light and the `outline-variant` hairline in dark.
  raised,

  /// The screen's lead card: the Indigo Wash, `primary-container`.
  hero,

  /// A limit where nothing was lost: `warning-container`.
  warning,

  /// A finished, fine state: `success-container`.
  success,

  /// A failure the card reports: `error-container`.
  danger,

  /// A face set into the page: `surface-container-low`, flat.
  recessed,
}

/// A card's ground, the colour its content reads in, its edge and shadow.
({Color ground, Color content, BorderSide edge, List<BoxShadow> shadows})
mxCardSurface(
  ColorScheme colors,
  AppSemanticColors semantic, {
  required MxCardTone tone,
  required bool isSelected,
}) {
  final bool isDark = colors.brightness == Brightness.dark;
  final (Color ground, Color content) = switch (tone) {
    MxCardTone.raised => (colors.surfaceContainerLowest, colors.onSurface),
    MxCardTone.hero => (colors.primaryContainer, colors.onPrimaryContainer),
    MxCardTone.warning => (
      semantic.warningContainer,
      semantic.onWarningContainer,
    ),
    MxCardTone.success => (
      semantic.successContainer,
      semantic.onSuccessContainer,
    ),
    MxCardTone.danger => (colors.errorContainer, colors.onErrorContainer),
    MxCardTone.recessed => (colors.surfaceContainerLow, colors.onSurface),
  };
  final bool isRaised = tone == MxCardTone.raised;
  final AppShadow? whisper = isDark
      ? AppShadows.whisperDark
      : AppShadows.whisperLight;
  final List<BoxShadow> shadows = isRaised
      ? [?whisper?.on(colors.shadow)]
      : const <BoxShadow>[];
  BorderSide edge = BorderSide.none;
  if (isRaised && isDark) {
    edge = BorderSide(color: colors.outlineVariant, width: AppStroke.hairline);
  }
  // Chosen is the Indigo Accent edge on the card's own ground (The
  // Selection Ladder Rule), never a `primary` edge.
  if (isSelected) {
    edge = BorderSide(
      color: colors.onPrimaryContainer,
      width: AppStroke.control,
    );
  }
  return (ground: ground, content: content, edge: edge, shadows: shadows);
}

/// The overline above a section's card: the Section Label role in
/// `on-surface-variant` (the widget upper-cases the app's own words).
TextStyle? mxSectionLabelStyle(TextTheme texts, ColorScheme colors) =>
    texts.labelMedium?.apply(color: colors.onSurfaceVariant);
```

Create `lib/shared/widgets/mx_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

export 'package:memox/core/theme/components/surface_style.dart' show MxCardTone;

/// A surface that groups content (DESIGN.md, Containers › MxCard): r12, a
/// 20 interior, one tone at a time. Its content reads in the tone's colour.
class MxCard extends StatelessWidget {
  const MxCard({
    required this.child,
    this.tone = MxCardTone.raised,
    this.isSelected = false,
    this.isFullBleed = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final MxCardTone tone;

  /// Chosen: a 2dp Indigo Accent edge (The Selection Ladder Rule).
  final bool isSelected;

  /// Rows that run edge to edge: no interior padding, clipped to the corners.
  final bool isFullBleed;

  /// Makes the whole card one tappable surface.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = mxCardSurface(
      context.colors,
      context.semanticColors,
      tone: tone,
      isSelected: isSelected,
    );
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    Widget body = isFullBleed
        ? child
        : Padding(padding: const EdgeInsets.all(AppSpacing.card), child: child);
    body = IconTheme.merge(
      data: IconThemeData(color: surface.content),
      child: DefaultTextStyle.merge(
        style: context.texts.bodyMedium?.apply(color: surface.content),
        child: body,
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap != null) {
      body = MxRowInk(onTap: tap, borderRadius: radius, child: body);
    }
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: surface.ground,
        borderRadius: radius,
        border: Border.fromBorderSide(surface.edge),
        boxShadow: surface.shadows,
      ),
      child: ClipRRect(borderRadius: radius, child: body),
    );
    if (tap == null) {
      return card;
    }
    return MxFocusRing(borderRadius: radius, child: card);
  }
}
```

Create `lib/shared/widgets/mx_note.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// One calm information line (DESIGN.md, Containers › MxNote): the muted fill
/// with a hairline edge, or, as [MxNote.hint], the footnote form with neither.
/// A one-time note offers a close button; storing that it was dismissed is
/// the caller's.
class MxNote extends StatelessWidget {
  const MxNote({
    required this.text,
    this.onDismiss,
    this.dismissLabel,
    super.key,
  }) : isHint = false,
       assert(
         (onDismiss == null) == (dismissLabel == null),
         'A dismissible note names its close button.',
       );

  /// The footnote under a section or a form: no fill and no edge.
  const MxNote.hint({required this.text, super.key})
    : isHint = true,
      onDismiss = null,
      dismissLabel = null;

  final String text;
  final bool isHint;
  final VoidCallback? onDismiss;

  /// The close button's name, read aloud and shown as its tooltip.
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextStyle? style = isHint
        ? context.texts.bodySmall?.apply(color: colors.onSurfaceVariant)
        : context.texts.bodyMedium?.apply(color: colors.onSurfaceVariant);
    final VoidCallback? dismiss = onDismiss;
    final Widget line = Row(
      spacing: AppSpacing.control,
      children: [
        Icon(
          Icons.info_outline,
          size: AppIconSize.small,
          color: colors.onSurfaceVariant,
        ),
        Expanded(child: Text(text, style: style)),
        if (dismiss != null)
          MxIconButton(
            icon: Icons.close,
            semanticLabel: dismissLabel!,
            onPressed: dismiss,
          ),
      ],
    );
    if (isHint) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.micro),
        child: line,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.grouped,
          end: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
          top: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
          bottom: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
        ),
        child: line,
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A group of rows under an overline (DESIGN.md, Containers › MxSection): the
/// Section Label, one full-bleed card whose rows are split by hairlines, and
/// an optional footnote.
class MxSection extends StatelessWidget {
  const MxSection({required this.children, this.title, this.note, super.key});

  /// The overline; the widget upper-cases it.
  final String? title;

  /// The rows, at least one.
  final List<Widget> children;

  /// A product rule under the card, drawn as `MxNote.hint`.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final String? overline = title;
    final String? footnote = note;
    final Widget divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.colors.outlineVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.micro,
              bottom: AppSpacing.control,
            ),
            child: Semantics(
              header: true,
              child: Text(
                overline.toUpperCase(),
                style: mxSectionLabelStyle(context.texts, context.colors),
              ),
            ),
          ),
        MxCard(
          isFullBleed: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, row) in children.indexed) ...[
                if (index > 0) divider,
                row,
              ],
            ],
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.micro,
              end: AppSpacing.micro,
              top: AppSpacing.control,
            ),
            child: MxNote.hint(text: footnote),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_note_test.dart test/shared/widgets/mx_section_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_surfaces_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

Widget _row(String label) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  child: Text(label),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('card', 'tones'): () => _column([
      for (final tone in MxCardTone.values)
        MxCard(tone: tone, child: Text('${tone.name} · Spanish basics')),
      const MxCard(isSelected: true, child: Text('selected · Spanish basics')),
    ]),
    ('section', 'default'): () => _column([
      MxSection(
        title: 'Study',
        note: 'Applies to decks you create from now on.',
        children: [
          _row('Daily goal'),
          _row('New cards a day'),
          _row('Reviews'),
        ],
      ),
    ]),
    ('note', 'forms'): () => _column([
      const MxNote(text: 'Synced just now. Your cards are on this phone too.'),
      MxNote(
        text: 'Swipe a card left or right to grade it.',
        onDismiss: () {},
        dismissLabel: 'Dismiss tip',
      ),
      const MxNote.hint(text: 'Cards stay in Trash for 30 days.'),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_surfaces_golden_test.dart`
Expected: `All tests passed!` and, under `test/shared/widgets/goldens/`, `mx_card__*__light.png` / `__dark.png`, `mx_section__*__light.png` / `__dark.png`, `mx_note__*__light.png` / `__dark.png`.

- [ ] **Catalog**

Set the `Status` cell of `MxCard`, `MxSection`, `MxNote` to `built`. Append these contracts at the end of `### Contracts` (before `## Do's and Don'ts`):

```markdown
#### MxCard
- Variants: tones raised, hero, warning, success, danger, recessed (one at a time); `isSelected`; `isFullBleed`; tappable with `onTap`
- States: resting, selected (2dp Indigo Accent edge), pressed and focused when tappable
- Accessibility: a tappable card is one target with the keyboard ring; its content reads in the tone's `on-` role
- Tokens: `surface-container-lowest` (raised; whisper shadow in light, `outline-variant` hairline in dark), `primary-container`, `warning-container`, `success-container`, `error-container`, `surface-container-low` and their `on-` roles; `on-primary-container` (selected edge); `AppRadius.md`; `AppSpacing.card`
- Golden: tones__light, tones__dark


#### MxSection
- Variants: with or without an overline and a footnote
- States: one
- Accessibility: the overline is a header, upper-cased by the widget, 8 above the card; rows keep their own semantics
- Tokens: Section Label (`labelMedium`) in `on-surface-variant`; a full-bleed `MxCard`; `outline-variant` hairlines between rows; `MxNote.hint`
- Golden: default__light, default__dark


#### MxNote
- Variants: note (muted fill and hairline), dismissible note (with a named close button), hint (no fill, no edge)
- States: one
- Accessibility: the close button is named by `dismissLabel` and keeps its 48 hit; the glyph is decorative
- Tokens: `surface-container-low`, `outline-variant`, `on-surface-variant`; `bodyMedium` (note), `bodySmall` (hint); `AppIconSize.small`; `AppRadius.md`
- Golden: forms__light, forms__dark

```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (`check.py` requires each `built` component's source, widget test and every listed golden).

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`.

- [ ] **Commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p3): MxCard, MxNote and MxSection

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 3: Marks — MxBadge, MxStatusBadge, MxTagChip, MxIconTile

**Files:**
- Create: `lib/core/theme/components/mark_style.dart`, `lib/shared/widgets/mx_badge.dart`, `lib/shared/widgets/mx_status_badge.dart`, `lib/shared/widgets/mx_tag_chip.dart`, `lib/shared/widgets/mx_icon_tile.dart`
- Test: `test/shared/widgets/mx_badge_test.dart`, `test/shared/widgets/mx_status_badge_test.dart`, `test/shared/widgets/mx_tag_chip_test.dart`, `test/shared/widgets/mx_icon_tile_test.dart`; golden `test/shared/widgets/mx_marks_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: Task 1 sizes.
- Produces: `ToneColors`, `MxBadgeTone`, `MxStatusBadgeKind`, `MxIconTileTone`, `MxLinearProgressTone` and their colour functions (`mark_style.dart`, used again in Task 4); the four widgets.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxBadgeTone, (Color, Color)> pairs = {
      MxBadgeTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxBadgeTone.mastery: (
        x.statusMasteredContainer,
        x.onStatusMasteredContainer,
      ),
      MxBadgeTone.success: (x.successContainer, x.onSuccessContainer),
      MxBadgeTone.warning: (x.warningContainer, x.onWarningContainer),
      MxBadgeTone.danger: (s.errorContainer, s.onErrorContainer),
      MxBadgeTone.neutral: (s.surfaceContainerHigh, s.onSurfaceVariant),
    };
    for (final MapEntry(key: tone, value: (ground, content)) in pairs.entries) {
      testWidgets('$name: ${tone.name} is its container pair', (tester) async {
        await pumpMx(
          tester,
          MxBadge(label: '23 due', tone: tone),
          theme: theme,
        );
        final BoxDecoration box =
            tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Text>(find.text('23 due')).style!.color, content);
      });
    }
  }

  testWidgets('22 tall at rest, taller with large text', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));
    expect(tester.getSize(find.byType(MxBadge)).height, AppSize.badge);
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: MxBadge(label: '23 due')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MxBadge)).height,
      greaterThan(AppSize.badge),
    );
  });
}
```

Create `test/shared/widgets/mx_status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxStatusBadgeKind, (Color, Color)> pairs = {
      MxStatusBadgeKind.newCard: (x.statusNew, x.statusNewContainer),
      MxStatusBadgeKind.learning: (x.statusLearning, x.statusLearningContainer),
      MxStatusBadgeKind.reviewing: (
        x.statusReviewing,
        x.statusReviewingContainer,
      ),
      MxStatusBadgeKind.mastered: (x.statusMastered, x.statusMasteredContainer),
    };
    for (final MapEntry(key: kind, value: (mark, ground)) in pairs.entries) {
      testWidgets('$name: ${kind.name} dots its mark on its container', (
        tester,
      ) async {
        await pumpMx(
          tester,
          MxStatusBadge(kind: kind, label: kind.name),
          theme: theme,
        );
        final List<Color?> fills = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => (box.decoration as BoxDecoration).color)
            .toList();
        expect(fills, containsAll(<Color>[ground, mark]));
      });
    }
  }

  testWidgets('the dot form is 8 and still named for TalkBack', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatusBadge(
        kind: MxStatusBadgeKind.learning,
        label: 'Learning',
        isDot: true,
      ),
    );
    expect(
      tester.getSize(find.byType(MxStatusBadge)),
      const Size.square(AppSize.statusDot),
    );
    expect(find.text('Learning'), findsNothing);
    expect(
      tester.getSemantics(find.byType(MxStatusBadge)),
      isSemantics(label: 'Learning'),
    );
    semantics.dispose();
  });
}
```

Create `test/shared/widgets/mx_tag_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('22 on its own line, 18 dense', (tester) async {
    await pumpMx(tester, const MxTagChip(label: 'verbs'));
    expect(tester.getSize(find.byType(MxTagChip)).height, AppSize.tagChip);
    await pumpMx(tester, const MxTagChip(label: 'verbs', isDense: true));
    expect(tester.getSize(find.byType(MxTagChip)).height, AppSize.tagChipDense);
  });

  testWidgets('a long name stops at half its row and is read whole', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String name = 'irregular verbs of the past tense, chapter twelve';
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxTagChip(label: name),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(DecoratedBox).last).width,
      lessThanOrEqualTo(150),
    );
    expect(
      tester.getSemantics(find.byType(MxTagChip)),
      isSemantics(label: name),
    );
    semantics.dispose();
  });
}
```

Create `test/shared/widgets/mx_icon_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import 'support/mx_harness.dart';

void main() {
  for (final size in MxIconTileSize.values) {
    testWidgets('${size.name} is a ${size.box} square with a '
        '${size.glyph} glyph', (tester) async {
      await pumpMx(tester, MxIconTile(icon: Icons.style, size: size));
      expect(tester.getSize(find.byType(MxIconTile)), Size.square(size.box));
      expect(tester.widget<Icon>(find.byIcon(Icons.style)).size, size.glyph);
    });
  }

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxIconTileTone, (Color, Color)> pairs = {
      MxIconTileTone.tinted: (s.surfaceContainerHigh, s.onSurfaceVariant),
      MxIconTileTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxIconTileTone.warning: (x.warning, x.onWarning),
      MxIconTileTone.success: (x.successContainer, x.onSuccessContainer),
      MxIconTileTone.caution: (x.warningContainer, x.onWarningContainer),
      MxIconTileTone.danger: (s.errorContainer, s.onErrorContainer),
    };
    for (final MapEntry(key: tone, value: (ground, glyph)) in pairs.entries) {
      testWidgets('$name: ${tone.name} glyph on its ground', (tester) async {
        await pumpMx(
          tester,
          MxIconTile(icon: Icons.style, tone: tone),
          theme: theme,
        );
        final BoxDecoration box =
            tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Icon>(find.byIcon(Icons.style)).color, glyph);
      });
    }
  }

  testWidgets('decorative: TalkBack skips it', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, const MxIconTile(icon: Icons.style));
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    semantics.dispose();
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_badge_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_tag_chip_test.dart test/shared/widgets/mx_icon_tile_test.dart`
Expected: compile failure, because the sources under test do not exist yet.

- [ ] **Step 3: Write the styles and widgets**

Create `lib/core/theme/components/mark_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// A ground and the content that reads on it.
typedef ToneColors = ({Color ground, Color content});

/// What a badge says (DESIGN.md, Feedback and Status › MxBadge). Each tone
/// is its role's container under its `on-…-container`.
enum MxBadgeTone { primary, mastery, success, warning, danger, neutral }

ToneColors mxBadgeColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxBadgeTone tone,
) => switch (tone) {
  MxBadgeTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxBadgeTone.mastery => (
    ground: semantic.statusMasteredContainer,
    content: semantic.onStatusMasteredContainer,
  ),
  MxBadgeTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxBadgeTone.warning => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxBadgeTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
  MxBadgeTone.neutral => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
};

/// A card's learning status (DESIGN.md, Colors › Semantic › Status).
enum MxStatusBadgeKind { newCard, learning, reviewing, mastered }

/// A status's mark (its dot or bar) and its badge ground and label colour.
({Color mark, Color ground, Color content}) mxStatusColors(
  AppSemanticColors semantic,
  MxStatusBadgeKind kind,
) => switch (kind) {
  MxStatusBadgeKind.newCard => (
    mark: semantic.statusNew,
    ground: semantic.statusNewContainer,
    content: semantic.onStatusNewContainer,
  ),
  MxStatusBadgeKind.learning => (
    mark: semantic.statusLearning,
    ground: semantic.statusLearningContainer,
    content: semantic.onStatusLearningContainer,
  ),
  MxStatusBadgeKind.reviewing => (
    mark: semantic.statusReviewing,
    ground: semantic.statusReviewingContainer,
    content: semantic.onStatusReviewingContainer,
  ),
  MxStatusBadgeKind.mastered => (
    mark: semantic.statusMastered,
    ground: semantic.statusMasteredContainer,
    content: semantic.onStatusMasteredContainer,
  ),
};

/// A tag chip: read-only metadata on `surface-container-high`.
ToneColors mxTagColors(ColorScheme colors) =>
    (ground: colors.surfaceContainerHigh, content: colors.onSurfaceVariant);

/// What an icon tile says (DESIGN.md, Data Display › MxIconTile).
enum MxIconTileTone {
  /// The neutral tile beside a row: `surface-container-high`.
  tinted,

  /// The Indigo Wash: `primary-container`.
  primary,

  /// A solid warning square (a lock that refuses): `warning` under
  /// `on-warning`.
  warning,

  /// `success-container`.
  success,

  /// The soft warning ground: `warning-container`.
  caution,

  /// `error-container`.
  danger,
}

ToneColors mxIconTileColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxIconTileTone tone,
) => switch (tone) {
  MxIconTileTone.tinted => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
  MxIconTileTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxIconTileTone.warning => (
    ground: semantic.warning,
    content: semantic.onWarning,
  ),
  MxIconTileTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxIconTileTone.caution => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxIconTileTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
};

/// A progress fill's colour (DESIGN.md, MxLinearProgress). The generic bar
/// is `secondary`; a component that means a state (mastery, success, a
/// warning) passes that state's tone. Never `primary`: #4151C6 holds only
/// 2.35:1 on the dark track (The Contrast Floor Rule).
enum MxLinearProgressTone {
  secondary,
  newCard,
  learning,
  reviewing,
  mastered,
  success,
  warning,
  danger,
}

/// The fill and the track a progress bar is drawn in.
({Color fill, Color track}) mxProgressColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxLinearProgressTone tone,
) => (
  fill: switch (tone) {
    MxLinearProgressTone.secondary => colors.secondary,
    MxLinearProgressTone.newCard => semantic.statusNew,
    MxLinearProgressTone.learning => semantic.statusLearning,
    MxLinearProgressTone.reviewing => semantic.statusReviewing,
    MxLinearProgressTone.mastered => semantic.statusMastered,
    MxLinearProgressTone.success => semantic.success,
    MxLinearProgressTone.warning => semantic.warning,
    MxLinearProgressTone.danger => colors.error,
  },
  track: colors.surfaceContainerLow,
);
```

Create `lib/shared/widgets/mx_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart' show MxBadgeTone;

/// A short label in a semantic tone (DESIGN.md, MxBadge): a pill at least
/// 24 tall, its label centred, that grows with text; the tone's container under its `on-…-container`. The unit
/// belongs inside the label ("23 due").
class MxBadge extends StatelessWidget {
  const MxBadge({
    required this.label,
    this.tone = MxBadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final MxBadgeTone tone;

  /// A glyph before the label, for a counted status.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxBadgeColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final IconData? glyph = icon;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.badge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pair.ground,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (glyph != null)
                Icon(glyph, size: AppIconSize.small, color: pair.content),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: pair.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_status_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxStatusBadgeKind;

/// A card's learning status (DESIGN.md, MxStatusBadge): a pill with the
/// status dot and its label on the status container, or, with [isDot], the
/// bare 8 dot for dense rows, still named by [label] for TalkBack. A status
/// is never told by colour alone.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    required this.kind,
    required this.label,
    this.isDot = false,
    super.key,
  });

  final MxStatusBadgeKind kind;

  /// The status's localized name: shown in the pill, read aloud for a dot.
  final String label;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    final paint = mxStatusColors(context.semanticColors, kind);
    if (isDot) {
      return Semantics(
        label: label,
        child: _Dot(color: paint.mark, size: AppSize.statusDot),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.badge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paint.ground,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              _Dot(color: paint.mark, size: AppSize.statusDot),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: paint.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_tag_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A tag as read-only metadata (DESIGN.md, MxTagChip): a pill at least 24
/// tall on its own line, or 20 ([isDense]) inside a row. It hugs its name up
/// to half the width it is given, so a tag never dominates its row; a longer
/// name ends in an ellipsis and stays whole for TalkBack.
class MxTagChip extends StatelessWidget {
  const MxTagChip({required this.label, this.isDense = false, super.key});

  final String label;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxTagColors(context.colors);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, row) => ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDense ? AppSize.tagChipDense : AppSize.tagChip,
            maxWidth: row.maxWidth / 2,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pair.ground,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.control,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: pair.content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxIconTileTone;

/// An icon tile's geometry: box, radius and glyph.
enum MxIconTileSize {
  small(AppSize.iconTileSmall, AppRadius.sm, AppIconSize.small),
  medium(AppSize.iconTileMedium, AppRadius.md, AppIconSize.medium),
  large(AppSize.iconTileLarge, AppRadius.md, AppIconSize.large);

  const MxIconTileSize(this.box, this.radius, this.glyph);

  final double box;
  final double radius;
  final double glyph;
}

/// A glyph on a toned square beside a row or a heading (DESIGN.md,
/// MxIconTile). Decorative: the row or heading beside it names it.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    required this.icon,
    this.size = MxIconTileSize.medium,
    this.tone = MxIconTileTone.tinted,
    super.key,
  });

  final IconData icon;
  final MxIconTileSize size;
  final MxIconTileTone tone;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxIconTileColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size.box,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: pair.ground,
            borderRadius: BorderRadius.circular(size.radius),
          ),
          child: Icon(icon, size: size.glyph, color: pair.content),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_badge_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_tag_chip_test.dart test/shared/widgets/mx_icon_tile_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_marks_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import 'support/mx_harness.dart';

Widget _wrap(List<Widget> children) => SizedBox(
  width: 380,
  child: Wrap(spacing: 8, runSpacing: 12, children: children),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('badge', 'tones'): () => _wrap([
      for (final tone in MxBadgeTone.values)
        MxBadge(label: '${tone.name} 23', tone: tone),
      const MxBadge(label: '4 due', icon: Icons.schedule),
    ]),
    ('status_badge', 'kinds'): () => _wrap([
      for (final kind in MxStatusBadgeKind.values)
        MxStatusBadge(kind: kind, label: kind.name),
      for (final kind in MxStatusBadgeKind.values)
        MxStatusBadge(kind: kind, label: kind.name, isDot: true),
    ]),
    ('tag_chip', 'sizes'): () => _wrap(const [
      MxTagChip(label: 'verbs'),
      MxTagChip(label: 'irregular verbs of the past tense'),
      MxTagChip(label: 'verbs', isDense: true),
      MxTagChip(label: 'travel', isDense: true),
    ]),
    ('icon_tile', 'tones'): () => _wrap([
      for (final size in MxIconTileSize.values)
        for (final tone in MxIconTileTone.values)
          MxIconTile(icon: Icons.style_outlined, size: size, tone: tone),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_marks_golden_test.dart`
Expected: `All tests passed!` and, under `test/shared/widgets/goldens/`, `mx_badge__*__light.png` / `__dark.png`, `mx_status_badge__*__light.png` / `__dark.png`, `mx_tag_chip__*__light.png` / `__dark.png`, `mx_icon_tile__*__light.png` / `__dark.png`.

- [ ] **Catalog**

Set the `Status` cell of `MxBadge`, `MxStatusBadge`, `MxTagChip`, `MxIconTile` to `built`. Append these contracts at the end of `### Contracts` (before `## Do's and Don'ts`):

```markdown
#### MxBadge
- Variants: tones primary, mastery, success, warning, danger, neutral; optional glyph
- States: one
- Accessibility: read as its label; 24 is a minimum, the label centred, and it grows with text
- Tokens: each tone's container under its `on-…-container` (`surface-container-high` / `on-surface-variant` for neutral); `labelSmall`; `AppSize.badge`; `AppRadius.full`
- Golden: tones__light, tones__dark


#### MxStatusBadge
- Variants: kinds new, learning, reviewing, mastered; pill or bare dot (`isDot`)
- States: one
- Accessibility: a status is never colour alone: the pill shows its label, the dot is named by it for TalkBack
- Tokens: `status-*` (dot), `status-*-container` / `on-status-*-container` (pill); one 8 dot (`AppSize.statusDot`), 4 from its label; `AppSize.badge`
- Golden: kinds__light, kinds__dark


#### MxTagChip
- Variants: 24 on its own line, 20 dense (both minimums); hugs its name up to half the width it is given
- States: one
- Accessibility: read whole even when the chip ends in an ellipsis
- Tokens: `surface-container-high`, `on-surface-variant`; `labelSmall`; `AppSize.tagChip`, `AppSize.tagChipDense`
- Golden: sizes__light, sizes__dark


#### MxIconTile
- Variants: sizes small (32, r8, 16 glyph), medium (40, r12, 20; Material 3's list leading container), large (48, r12, 24); tones tinted, primary, warning (solid), success, caution (warning container), danger — a closed set; no raw colour
- States: one
- Accessibility: decorative; the row or heading beside it names it
- Tokens: `surface-container-high` / `on-surface-variant`, `primary-container`, `warning` / `on-warning`, `success-container`, `warning-container`, `error-container` and their `on-` roles; `AppSize.iconTile*`
- Golden: tones__light, tones__dark

```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (`check.py` requires each `built` component's source, widget test and every listed golden).

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`.

- [ ] **Commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p3): MxBadge, MxStatusBadge, MxTagChip and MxIconTile

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 4: Progress and loading — MxLinearProgress, MxSkeleton

**Files:**
- Create: `lib/shared/widgets/mx_linear_progress.dart`, `lib/shared/widgets/mx_skeleton.dart`
- Test: `test/shared/widgets/mx_linear_progress_test.dart`, `test/shared/widgets/mx_skeleton_test.dart`; golden `test/shared/widgets/mx_progress_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `mxProgressColors`, `MxLinearProgressTone` (Task 3); the Task 1 sizes.
- Produces: `MxLinearProgress({{value, semanticLabel, semanticValue, tone, size}})`, `MxLinearProgressSize`; `MxSkeleton.line({{widthFactor}})`, `MxSkeleton.tile()`, `MxSkeletonRow`, `MxSkeletonList({{semanticLabel, rowCount}})`, `MxSkeletonGroup({{semanticLabel, child}})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_linear_progress_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import 'support/mx_harness.dart';

Finder _fill() => find
    .descendant(
      of: find.byType(MxLinearProgress),
      matching: find.byType(DecoratedBox),
    )
    .at(1);

Widget _bar(
  double value, {
  MxLinearProgressSize size = MxLinearProgressSize.regular,
}) => SizedBox(
  width: 200,
  child: MxLinearProgress(value: value, semanticLabel: 'Session', size: size),
);

void main() {
  testWidgets('the fill is the value\'s share of the track', (tester) async {
    await pumpMx(tester, _bar(0.25));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()).width, 50);
    expect(
      tester.getSize(find.byType(MxLinearProgress)).height,
      AppSize.progress,
    );
  });

  testWidgets('0 draws no fill; 100% fills the track', (tester) async {
    await pumpMx(tester, _bar(0));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(MxLinearProgress),
        matching: find.byType(DecoratedBox),
      ),
      findsOneWidget,
    );
    await pumpMx(tester, _bar(1));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()).width, 200);
  });

  testWidgets('a small share above 0 still shows a dot', (tester) async {
    await pumpMx(tester, _bar(0.001, size: MxLinearProgressSize.thick));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()), const Size.square(AppSize.progressThick));
  });

  testWidgets('it fills from the start edge in RTL', (tester) async {
    await pumpMx(tester, _bar(0.25), textDirection: TextDirection.rtl);
    await tester.pumpAndSettle();
    expect(
      tester.getTopRight(_fill()).dx,
      tester.getTopRight(find.byType(MxLinearProgress)).dx,
    );
  });

  testWidgets('thick is 8', (tester) async {
    await pumpMx(tester, _bar(0.5, size: MxLinearProgressSize.thick));
    expect(
      tester.getSize(find.byType(MxLinearProgress)).height,
      AppSize.progressThick,
    );
  });

  testWidgets('TalkBack reads what it measures and its value', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 200,
        child: MxLinearProgress(
          value: 0.62,
          semanticLabel: 'Mastery',
          semanticValue: '62%',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(MxLinearProgress)),
      isSemantics(label: 'Mastery', value: '62%'),
    );
    semantics.dispose();
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxLinearProgressTone, Color> fills = {
      MxLinearProgressTone.secondary: s.secondary,
      MxLinearProgressTone.newCard: x.statusNew,
      MxLinearProgressTone.learning: x.statusLearning,
      MxLinearProgressTone.reviewing: x.statusReviewing,
      MxLinearProgressTone.mastered: x.statusMastered,
      MxLinearProgressTone.success: x.success,
      MxLinearProgressTone.warning: x.warning,
      MxLinearProgressTone.danger: s.error,
    };
    for (final MapEntry(key: tone, value: fill) in fills.entries) {
      testWidgets('$name: ${tone.name} fills on the low track', (tester) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 200,
            child: MxLinearProgress(
              value: 0.5,
              semanticLabel: 'Bar',
              tone: tone,
            ),
          ),
          theme: theme,
        );
        await tester.pumpAndSettle();
        final List<Color?> colors = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(MxLinearProgress),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => (box.decoration as BoxDecoration).color)
            .toList();
        expect(colors, [s.surfaceContainerLow, fill]);
      });
    }

    testWidgets('$name: the generic bar is secondary, never primary', (
      tester,
    ) async {
      await pumpMx(tester, _bar(0.5), theme: theme);
      await tester.pumpAndSettle();
      final Color? fill =
          (tester.widget<DecoratedBox>(_fill()).decoration as BoxDecoration)
              .color;
      expect(fill, s.secondary);
      expect(fill, isNot(s.primary));
    });
  }
}
```

Create `test/shared/widgets/mx_skeleton_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a list of rows is read once as what is loading', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonList(semanticLabel: 'Loading decks', rowCount: 4),
      ),
    );
    expect(find.byType(MxSkeletonRow), findsNWidgets(4));
    expect(find.bySemanticsLabel('Loading decks'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a row is the medium icon tile and two text-high lines', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonGroup(
          semanticLabel: 'Loading',
          child: MxSkeletonRow(),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxSkeleton).first),
      const Size.square(AppSize.iconTileMedium),
    );
    final TextTheme texts = mxThemes['light']!.textTheme;
    expect(
      tester.getSize(find.byType(MxSkeleton).at(1)).height,
      texts.bodyLarge!.fontSize,
    );
    expect(
      tester.getSize(find.byType(MxSkeleton).at(2)).height,
      texts.bodySmall!.fontSize,
    );
  });

  testWidgets('it pulses, and rests under reduced motion', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonList(semanticLabel: 'Loading', rowCount: 1),
      ),
    );
    final FadeTransition fade = tester.widget(
      find
          .descendant(
            of: find.byType(MxSkeleton),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    final double start = fade.opacity.value;
    await tester.pump(const Duration(milliseconds: 700));
    expect(fade.opacity.value, isNot(start));
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox(
              width: 360,
              child: MxSkeletonList(semanticLabel: 'Loading', rowCount: 1),
            ),
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(MxSkeleton),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(MxSkeleton),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      AppOpacity.skeletonLow,
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_linear_progress_test.dart test/shared/widgets/mx_skeleton_test.dart`
Expected: compile failure, because the sources under test do not exist yet.

- [ ] **Step 3: Write the styles and widgets**

Create `lib/shared/widgets/mx_linear_progress.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxLinearProgressTone;

/// A bar's thickness.
enum MxLinearProgressSize {
  regular(AppSize.progress),
  thick(AppSize.progressThick);

  const MxLinearProgressSize(this.height);

  final double height;
}

/// A determinate bar (DESIGN.md, MxLinearProgress): a flat fill on a
/// `surface-container-low` pill track, never a gradient. It knows a value, a
/// tone, a size and what TalkBack reads; it knows nothing of mastery, which
/// is composed on top of it. Any value above 0 shows at least a dot as long
/// as the bar is thick, so a small share never reads as none.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({
    required this.value,
    required this.semanticLabel,
    this.semanticValue,
    this.tone = MxLinearProgressTone.secondary,
    this.size = MxLinearProgressSize.regular,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;

  /// What the bar measures, read aloud.
  final String semanticLabel;

  /// The localized value read aloud ("62%", "12 of 20").
  final String? semanticValue;
  final MxLinearProgressTone tone;
  final MxLinearProgressSize size;

  @override
  Widget build(BuildContext context) {
    final paint = mxProgressColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final bool isStill = MediaQuery.disableAnimationsOf(context);
    final BorderRadius pill = BorderRadius.circular(AppRadius.full);
    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: SizedBox(
        height: size.height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: paint.track, borderRadius: pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: isStill ? Duration.zero : AppDurations.standard,
            builder: (context, fraction, _) => LayoutBuilder(
              builder: (context, track) {
                if (fraction <= 0) {
                  return const SizedBox.shrink();
                }
                final double share = track.maxWidth * fraction;
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: share < size.height ? size.height : share,
                    height: size.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: paint.fill,
                        borderRadius: pill,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The share of the text column a row's title and meta lines take, so the
/// placeholder reads as a title over a shorter line (component contract).
const double _titleShare = 0.6;
const double _metaShare = 0.4;

/// One placeholder shape (DESIGN.md, MxSkeleton), as large as what replaces
/// it, so the layout does not jump on load. It pulses with the
/// `MxSkeletonGroup` above it (opacity 0.45 to 0.75 over 1.4s, no shimmer)
/// and rests at 0.45 without one or under reduced motion.
class MxSkeleton extends StatelessWidget {
  /// A text line as tall as the row title it stands for ([isMeta]: the
  /// caption under it), [widthFactor] of the space it is given.
  const MxSkeleton.line({this.widthFactor = 1, this.isMeta = false, super.key})
    : isTile = false;

  /// The tile a row leads with: the medium `MxIconTile`.
  const MxSkeleton.tile({super.key})
    : isTile = true,
      isMeta = false,
      widthFactor = 1;

  final double widthFactor;
  final bool isMeta;
  final bool isTile;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? pulse = _Pulse.of(context);
    final Color fill = context.colors.surfaceContainerHighest;
    final TextStyle? text = isMeta
        ? context.texts.bodySmall
        : context.texts.bodyLarge;
    final Widget sized = isTile
        ? SizedBox.square(
            dimension: AppSize.iconTileMedium,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          )
        : FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: widthFactor,
            child: SizedBox(
              height: text?.fontSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          );
    if (pulse == null) {
      return Opacity(opacity: AppOpacity.skeletonLow, child: sized);
    }
    return FadeTransition(opacity: pulse, child: sized);
  }
}

/// The standard list placeholder: the row's tile and two lines, title and
/// meta, on a list row's padding.
class MxSkeletonRow extends StatelessWidget {
  const MxSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          MxSkeleton.tile(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                MxSkeleton.line(widthFactor: _titleShare),
                MxSkeleton.line(widthFactor: _metaShare, isMeta: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [rowCount] skeleton rows under one pulse, read as one "loading" region.
class MxSkeletonList extends StatelessWidget {
  const MxSkeletonList({
    required this.semanticLabel,
    this.rowCount = 3,
    super.key,
  });

  /// What is loading, read aloud once ("Loading your decks").
  final String semanticLabel;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return MxSkeletonGroup(
      semanticLabel: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < rowCount; i++) const MxSkeletonRow()],
      ),
    );
  }
}

/// One pulse shared by every skeleton below it, and one live region that
/// names what is loading; the shapes themselves are silent.
class MxSkeletonGroup extends StatefulWidget {
  const MxSkeletonGroup({
    required this.semanticLabel,
    required this.child,
    super.key,
  });

  final String semanticLabel;
  final Widget child;

  @override
  State<MxSkeletonGroup> createState() => _MxSkeletonGroupState();
}

class _MxSkeletonGroupState extends State<MxSkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: AppOpacity.skeletonLow, end: AppOpacity.skeletonHigh),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: AppOpacity.skeletonHigh, end: AppOpacity.skeletonLow),
      weight: 1,
    ),
  ]).animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      return;
    }
    if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isStill = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      container: true,
      child: ExcludeSemantics(
        child: _Pulse(opacity: isStill ? null : _opacity, child: widget.child),
      ),
    );
  }
}

class _Pulse extends InheritedWidget {
  const _Pulse({required this.opacity, required super.child});

  final Animation<double>? opacity;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Pulse>()?.opacity;

  @override
  bool updateShouldNotify(_Pulse old) => old.opacity != opacity;
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_linear_progress_test.dart test/shared/widgets/mx_skeleton_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_progress_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('linear_progress', 'tones'): () => _column([
      for (final (index, tone) in MxLinearProgressTone.values.indexed)
        MxLinearProgress(
          value: 0.2 + index * 0.1,
          semanticLabel: tone.name,
          tone: tone,
          size: index.isEven
              ? MxLinearProgressSize.regular
              : MxLinearProgressSize.thick,
        ),
    ]),
    ('skeleton', 'list'): () => const SizedBox(
      width: 380,
      child: MxSkeletonList(semanticLabel: 'Loading decks'),
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_progress_golden_test.dart`
Expected: `All tests passed!` and, under `test/shared/widgets/goldens/`, `mx_linear_progress__*__light.png` / `__dark.png`, `mx_skeleton__*__light.png` / `__dark.png`.

- [ ] **Catalog**

Set the `Status` cell of `MxLinearProgress`, `MxSkeleton` to `built`. Append these contracts at the end of `### Contracts` (before `## Do's and Don'ts`):

```markdown
#### MxLinearProgress
- Variants: tones secondary (the generic bar, default), newCard, learning, reviewing, mastered, success, warning, danger — a component that means a state passes that state's tone; sizes regular (4, Material 3's track), thick (8, Material 3 Expressive)
- States: 0 (no fill), any share (a value above 0 shows at least a dot as long as the bar is thick), 1 (full); animated over 200ms, still under reduced motion
- Accessibility: named by `semanticLabel` with a localized `semanticValue`; fills from the start edge in RTL; knows nothing of mastery
- Tokens: fill `secondary` (5.08:1 light, 6.71:1 dark on the track; never `primary`, 2.35:1 on the dark track), `status-*`, `success`, `warning`, `error`; track `surface-container-low`; `AppSize.progress*`; `AppRadius.full`; every fill 3:1 on its track
- Golden: tones__light, tones__dark


#### MxSkeleton
- Variants: a line and a tile shape, the standard row (a tile and two lines), a list of rows, and a group that shares one pulse
- States: pulsing (0.45 to 0.75 over 1.4s), resting at 0.45 under reduced motion
- Accessibility: one live region names what is loading; the shapes are silent
- Tokens: `surface-container-highest`; `AppOpacity.skeleton*`; `AppDurations.skeletonPulse`; a line as tall as the text it stands for (title `bodyLarge`, meta `bodySmall`), the title line at 60% and the meta at 40% of the text column (component contract); the row tile is the medium icon tile (40, r12)
- Golden: list__light, list__dark

```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (`check.py` requires each `built` component's source, widget test and every listed golden).

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`.

- [ ] **Commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p3): MxLinearProgress and the MxSkeleton family

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 5: Overlays — MxSheetActions, MxDialog, MxBottomSheet

**Files:**
- Create: `lib/shared/widgets/mx_sheet_actions.dart`, `lib/shared/widgets/mx_dialog.dart`, `lib/shared/widgets/mx_bottom_sheet.dart`
- Test: `test/shared/widgets/mx_sheet_actions_test.dart`, `test/shared/widgets/mx_dialog_test.dart`, `test/shared/widgets/mx_bottom_sheet_test.dart`; golden `test/shared/widgets/mx_overlays_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `mxScrim`, `mxOverlayGround`, `mxCanButtonLabelFit` (Task 1); `MxButton`, `MxOptionRow` (Phase 2).
- Produces: `MxSheetActions({{confirmLabel, onConfirm, cancelLabel, onCancel, tone, isConfirmLoading, isInSheet}})`, `MxSheetActionsTone`; `showMxDialog<T>(context, {{builder, isDismissible}})`, `MxDialog({{title, actions, message, content, width}})`, `MxDialogWidth`; `showMxBottomSheet<T>(context, {{builder}})`, `MxBottomSheet({{child, title, actions}})`.

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_sheet_actions_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

Widget _footer(String confirm, {double width = 328}) => SizedBox(
  width: width,
  child: MxSheetActions(
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: confirm,
    onConfirm: () {},
  ),
);

void main() {
  testWidgets('short labels share the row equally, the confirm trailing', (
    tester,
  ) async {
    await pumpMx(tester, _footer('Save'));
    final Rect cancel = tester.getRect(find.byType(MxButton).first);
    final Rect confirm = tester.getRect(find.byType(MxButton).last);
    expect(cancel.width, confirm.width);
    expect(cancel.top, confirm.top);
    expect(confirm.left, greaterThan(cancel.left));
    expect(
      tester.widget<MxButton>(find.byType(MxButton).first).tone,
      MxButtonTone.outline,
    );
  });

  testWidgets('a label that would wrap stacks them, the confirm on top', (
    tester,
  ) async {
    await pumpMx(tester, _footer('Move everything to Trash for good'));
    final Rect top = tester.getRect(
      find.text('Move everything to Trash for good'),
    );
    final Rect bottom = tester.getRect(find.text('Cancel'));
    expect(top.top, lessThan(bottom.top));
    expect(tester.getSize(find.byType(MxButton).first).width, 328);
  });

  testWidgets('a lone confirm spans the row', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(confirmLabel: 'Done', onConfirm: () {}),
      ),
    );
    expect(tester.getSize(find.byType(MxButton)).width, 328);
  });

  testWidgets('the tone sets the confirm; loading blocks it', (tester) async {
    var confirmed = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxSheetActions(
          confirmLabel: 'Delete',
          onConfirm: () => confirmed++,
          tone: MxSheetActionsTone.destructive,
          isConfirmLoading: true,
        ),
      ),
    );
    final MxButton button = tester.widget(find.byType(MxButton));
    expect(button.tone, MxButtonTone.destructive);
    expect(button.isLoading, isTrue);
    await tester.tap(find.byType(MxButton));
    expect(confirmed, 0);
  });

  testWidgets('in a sheet it sits under a hairline on the gutter', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxSheetActions(
          confirmLabel: 'Done',
          onConfirm: () {},
          isInSheet: true,
        ),
      ),
    );
    final BoxDecoration box =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as BoxDecoration;
    expect(
      box.border!.top.color,
      mxThemes['light']!.colorScheme.outlineVariant,
    );
    expect(
      tester.getTopLeft(find.byType(MxButton)).dx -
          tester.getTopLeft(find.byType(MxSheetActions)).dx,
      AppSpacing.gutter,
    );
  });
}
```

Create `test/shared/widgets/mx_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

MxDialog _dialog(VoidCallback onConfirm, {MxDialogWidth? width}) => MxDialog(
  title: 'Move to Trash?',
  message: '"Spanish" and its 120 cards move to Trash for 30 days.',
  width: width ?? MxDialogWidth.medium,
  actions: MxSheetActions(
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: 'Move to Trash',
    onConfirm: onConfirm,
    tone: MxSheetActionsTone.destructive,
  ),
);

void main() {
  testWidgets('it opens over the scrim and closes on its action', (
    tester,
  ) async {
    var confirmed = 0;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxDialog<void>(
            context,
            builder: (_) => _dialog(() => confirmed++),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Move to Trash?'), findsOneWidget);
    final ModalBarrier barrier = tester.widget(find.byType(ModalBarrier).last);
    final ColorScheme s = mxThemes['light']!.colorScheme;
    expect(barrier.color, s.scrim.withValues(alpha: 0.45));
    await tester.tap(find.text('Move to Trash'));
    expect(confirmed, 1);
  });

  for (final width in MxDialogWidth.values) {
    testWidgets('${width.name} is ${width.extent} wide on a wide window', (
      tester,
    ) async {
      await pumpMx(tester, _dialog(() {}, width: width));
      expect(
        tester.getSize(find.byType(DecoratedBox).first).width,
        width.extent,
      );
    });
  }

  testWidgets('the sheet ground at r20, named for TalkBack', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, _dialog(() {}));
    final BoxDecoration box =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as BoxDecoration;
    expect(box.color, mxThemes['light']!.colorScheme.surfaceContainerHigh);
    expect(box.borderRadius, BorderRadius.circular(AppRadius.xl));
    expect(find.bySemanticsLabel('Move to Trash?'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('never wider than the window less its gutters', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMx(tester, _dialog(() {}, width: MxDialogWidth.large));
    expect(
      tester.getSize(find.byType(DecoratedBox).first).width,
      lessThan(AppSize.dialogLarge),
    );
  });

  testWidgets('under reduced motion it opens at once', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showMxDialog<void>(context, builder: (_) => _dialog(() {})),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    final ScaleTransition scale = tester.widget(
      find
          .ancestor(
            of: find.byType(MxDialog),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, 1);
  });
}
```

Create `test/shared/widgets/mx_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

Widget _opener(Widget Function(BuildContext) sheet) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showMxBottomSheet<void>(context, builder: sheet),
    child: const Text('Open'),
  ),
);

void main() {
  testWidgets('it opens with a grabber, a header title and its footer', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          title: 'Sort & filter',
          actions: MxSheetActions(
            confirmLabel: 'Apply',
            onConfirm: () {},
            isInSheet: true,
          ),
          child: const SizedBox(height: 80, child: Text('Options')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Sort & filter')),
      isSemantics(isHeader: true, label: 'Sort & filter'),
    );
    final Finder grabber = find.byWidgetPredicate(
      (w) =>
          w is SizedBox &&
          w.width == AppSize.grabberWidth &&
          w.height == AppSize.grabberHeight,
    );
    expect(grabber, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a long body stops 72 below the top and scrolls', (tester) async {
    await pumpMx(
      tester,
      _opener(
        (_) => MxBottomSheet(
          child: Column(children: List<Widget>.filled(60, const Text('Row'))),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(MxBottomSheet)).dy,
      greaterThanOrEqualTo(AppSize.sheetTopClearance),
    );
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('it rides above the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await pumpMx(
      tester,
      _opener((_) => const MxBottomSheet(child: SizedBox(height: 80))),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final double window =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final double keyboard = 300 / tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.byType(SizedBox).last).dy,
      lessThanOrEqualTo(window - keyboard),
    );
  });

  testWidgets('under reduced motion it opens at once', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: _opener((_) => const MxBottomSheet(child: Text('Body'))),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    // The ink ripple of the tap may still run; the sheet itself is placed.
    final Offset opened = tester.getTopLeft(find.byType(MxBottomSheet));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MxBottomSheet)), opened);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_sheet_actions_test.dart test/shared/widgets/mx_dialog_test.dart test/shared/widgets/mx_bottom_sheet_test.dart`
Expected: compile failure, because the sources under test do not exist yet.

- [ ] **Step 3: Write the styles and widgets**

Create `lib/shared/widgets/mx_sheet_actions.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// What a dialog's or sheet's confirm does.
enum MxSheetActionsTone { primary, destructive, warning }

/// The footer every dialog and sheet ends with (DESIGN.md, MxSheetActions).
/// Cancel and the confirm share the row equally while both labels fit one
/// line at the reader's text scale, the confirm on the trailing side; when
/// either would wrap they stack full width, the confirm on top. A lone
/// confirm spans the row. Labels are never cut. In a sheet it sits under a
/// hairline on the gutter.
class MxSheetActions extends StatelessWidget {
  const MxSheetActions({
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.tone = MxSheetActionsTone.primary,
    this.isConfirmLoading = false,
    this.isInSheet = false,
    super.key,
  });

  final String confirmLabel;

  /// `null` disables the confirm, as while a form is invalid.
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final MxSheetActionsTone tone;

  /// The confirm spins and blocks taps while its work runs.
  final bool isConfirmLoading;
  final bool isInSheet;

  @override
  Widget build(BuildContext context) {
    final Widget confirm = MxButton(
      label: confirmLabel,
      onPressed: onConfirm,
      isLoading: isConfirmLoading,
      tone: switch (tone) {
        MxSheetActionsTone.primary => MxButtonTone.primary,
        MxSheetActionsTone.destructive => MxButtonTone.destructive,
        MxSheetActionsTone.warning => MxButtonTone.warning,
      },
    );
    return _framed(context, _actions(context, confirm));
  }

  Widget _actions(BuildContext context, Widget confirm) {
    final String? cancel = cancelLabel;
    if (cancel == null) {
      return confirm;
    }
    // One primary per decision: Cancel is the outline tone.
    final Widget dismiss = MxButton(
      label: cancel,
      onPressed: onCancel,
      tone: MxButtonTone.outline,
    );
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, footer) {
        final double share = (footer.maxWidth - AppSpacing.control) / 2;
        final bool isSideBySide =
            mxCanButtonLabelFit(
              texts: context.texts,
              label: cancel,
              width: share,
              textScaler: scaler,
            ) &&
            mxCanButtonLabelFit(
              texts: context.texts,
              label: confirmLabel,
              width: share,
              textScaler: scaler,
            );
        if (isSideBySide) {
          return Row(
            spacing: AppSpacing.control,
            children: [
              Expanded(child: dismiss),
              Expanded(child: confirm),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.control,
          children: [confirm, dismiss],
        );
      },
    );
  }

  Widget _framed(BuildContext context, Widget actions) {
    if (!isInSheet) {
      return actions;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.outlineVariant,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        child: actions,
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/overlay_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// A dialog's width cap; it is never wider than the window less its gutters.
enum MxDialogWidth {
  small(AppSize.dialogSmall),
  medium(AppSize.dialogMedium),
  large(AppSize.dialogLarge);

  const MxDialogWidth(this.extent);

  final double extent;
}

/// The scale a dialog grows from as it fades in (component contract).
const double _enterScale = 0.92;

/// Opens [builder] (an `MxDialog`) over the 45% scrim. It fades in and
/// scales from 0.92 over 200ms, and opens at once under reduced motion.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final bool isStill = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: mxScrim(context.colors),
    transitionDuration: isStill ? Duration.zero : AppDurations.standard,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The centred modal for a decision or a short form (DESIGN.md, MxDialog):
/// the sheet ground, r20, the overlay shadow, a 20 interior; its title, an
/// optional message and content, and the `MxSheetActions` footer.
class MxDialog extends StatelessWidget {
  const MxDialog({
    required this.title,
    required this.actions,
    this.message,
    this.content,
    this.width = MxDialogWidth.medium,
    super.key,
  });

  final String title;
  final String? message;

  /// A short form or a list under the message.
  final Widget? content;
  final MxSheetActions actions;
  final MxDialogWidth width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = colors.brightness == Brightness.dark;
    final AppShadow overlay = isDark
        ? AppShadows.overlayDark
        : AppShadows.overlayLight;
    final String? body = message;
    final Widget? extra = content;
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width.extent),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mxOverlayGround(colors),
                borderRadius: radius,
                boxShadow: [overlay.on(colors.shadow)],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.control,
                            children: [
                              Text(title, style: context.texts.titleLarge),
                              if (body != null)
                                Text(
                                  body,
                                  style: context.texts.bodyMedium?.apply(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ?extra,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      actions,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_bottom_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/overlay_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Opens [builder] (an `MxBottomSheet`) from the bottom over the 45% scrim,
/// sliding up over 260ms, at once under reduced motion.
Future<T?> showMxBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final bool isStill = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AnimationStyle(
      duration: isStill ? Duration.zero : AppDurations.sheet,
      reverseDuration: isStill ? Duration.zero : AppDurations.sheet,
    ),
  );
}

/// The bottom-anchored modal for action lists, pickers and short forms
/// (DESIGN.md, MxBottomSheet): top corners 20, the chrome shadow, a grabber,
/// an optional title, a scrolling body and a pinned footer. It stops 72
/// below the top safe area (Material 3), so the page behind stays in view to
/// tap away, and rides above the keyboard.
class MxBottomSheet extends StatelessWidget {
  const MxBottomSheet({
    required this.child,
    this.title,
    this.actions,
    super.key,
  });

  final String? title;
  final Widget child;

  /// The pinned footer.
  final MxSheetActions? actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = colors.brightness == Brightness.dark;
    final AppShadow chrome = isDark
        ? AppShadows.chromeDark
        : AppShadows.chromeLight;
    final MediaQueryData media = MediaQuery.of(context);
    final String? heading = title;
    final MxSheetActions? footer = actions;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              media.size.height -
              media.padding.top -
              media.viewInsets.bottom -
              AppSize.sheetTopClearance,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mxOverlayGround(colors),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            boxShadow: [chrome.on(colors.shadow)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Grabber(),
              if (heading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.card,
                    end: AppSpacing.card,
                    bottom: AppSpacing.grouped,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(heading, style: context.texts.titleLarge),
                  ),
                ),
              Flexible(child: SingleChildScrollView(child: child)),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// The 32 × 4 pill at the top (Material 3's drag handle) in `outline`, 3:1
/// on the sheet ground, centred in a 48 band so the drag has a full target.
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.tapTarget,
      child: Center(
        child: SizedBox(
          width: AppSize.grabberWidth,
          height: AppSize.grabberHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.outline,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_sheet_actions_test.dart test/shared/widgets/mx_dialog_test.dart test/shared/widgets/mx_bottom_sheet_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_overlays_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('dialog', 'decision'): () => SizedBox(
      width: 380,
      child: MxDialog(
        title: 'Move "Spanish" to Trash?',
        message: 'Its 120 cards go with it. Trash keeps them for 30 days.',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move to Trash',
          onConfirm: () {},
          tone: MxSheetActionsTone.destructive,
        ),
      ),
    ),
    ('bottom_sheet', 'picker'): () => SizedBox(
      width: 380,
      child: MxBottomSheet(
        title: 'Sort & filter',
        actions: MxSheetActions(
          cancelLabel: 'Reset',
          onCancel: () {},
          confirmLabel: 'Apply',
          onConfirm: () {},
          isInSheet: true,
        ),
        child: Column(
          children: [
            MxOptionRow(
              title: 'Manual order',
              isSelected: true,
              onSelected: () {},
            ),
            MxOptionRow(
              title: 'Date added',
              isSelected: false,
              onSelected: () {},
            ),
          ],
        ),
      ),
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_overlays_golden_test.dart`
Expected: `All tests passed!` and, under `test/shared/widgets/goldens/`, `mx_dialog__*__light.png` / `__dark.png`, `mx_bottom_sheet__*__light.png` / `__dark.png`.

- [ ] **Catalog**

Set the `Status` cell of `MxSheetActions`, `MxDialog`, `MxBottomSheet` to `built`. Append these contracts at the end of `### Contracts` (before `## Do's and Don'ts`):

```markdown
#### MxSheetActions
- Variants: confirm tones primary, destructive, warning; with or without Cancel (outline tone: one primary per decision); in a dialog or in a sheet (under a hairline, on the gutter)
- States: enabled, confirm disabled, confirm loading
- Accessibility: buttons named by their labels; Cancel and the confirm share the row equally, the confirm trailing, while both labels fit one line at the reader's text scale (measured); otherwise they stack full width, the confirm on top; a label is never cut; a lone confirm spans the row
- Tokens: through `MxButton`; `outline-variant` hairline in a sheet
- Golden: none — seen in `mx_dialog__decision` and `mx_bottom_sheet__picker`


#### MxDialog
- Variants: widths small (300), medium (320), large (340), never wider than the window less its gutters; optional message and content
- States: opening (fade and scale from 0.92 over 200ms, a component contract; at once under reduced motion), open
- Accessibility: a named route scope; the 45% scrim dismisses unless told not to; its footer is `MxSheetActions`
- Tokens: `surface-container-high`; `AppRadius.xl`; overlay shadow; `scrim` at `AppOpacity.scrim`; `titleLarge`, `bodyMedium` in `on-surface-variant`; `AppSpacing.card`
- Golden: decision__light, decision__dark


#### MxBottomSheet
- Variants: with or without a title and a pinned footer
- States: opening (slides up over 260ms; at once under reduced motion), open, above the keyboard
- Accessibility: the title is a header; the sheet stops 72 below the top safe area (Material 3) and the body scrolls; it rides above the keyboard; the grabber sits in a 48 band
- Tokens: `surface-container-high`; top corners `AppRadius.xl`; chrome shadow; grabber 32 × 4 in `outline` (3:1; Material 3's handle); `AppSize.sheetTopClearance` (72), `AppSize.sheetMaxWidth` (640)
- Golden: picker__light, picker__dark

```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (`check.py` requires each `built` component's source, widget test and every listed golden).

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`.

- [ ] **Commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p3): MxSheetActions, MxDialog and MxBottomSheet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 6: Feedback — MxSnackbar, MxInlineBanner, MxEmptyState, MxErrorState

**Files:**
- Create: `lib/core/theme/components/feedback_style.dart`, `lib/shared/widgets/mx_snackbar.dart`, `lib/shared/widgets/mx_inline_banner.dart`, `lib/shared/widgets/mx_empty_state.dart`, `lib/shared/widgets/mx_error_state.dart`
- Test: `test/shared/widgets/mx_snackbar_test.dart`, `test/shared/widgets/mx_inline_banner_test.dart`, `test/shared/widgets/mx_empty_state_test.dart`, `test/shared/widgets/mx_error_state_test.dart`; golden `test/shared/widgets/mx_feedback_golden_test.dart`
- Modify: `DESIGN.md` (catalog)

**Interfaces:**
- Consumes: `MxButtonTone.inverse` (Task 1); `ToneColors` (Task 3); `MxNote.hint` (Task 2); the harness `settle:` parameter (below).
- Produces: `showMxSnackbar(context, {{message, actionLabel, onAction, isUndo}})`, `MxSnackbar`; `MxInlineBanner({{tone, message, title, actions}})`, `MxInlineBannerAction`, `MxInlineBannerTone`; `MxEmptyState(...)`, `MxEmptyStateAction`, `MxEmptyStateTone`; `MxErrorState({{title, message, retryLabel, onRetry, isNetwork}})`.

- [ ] **Step 0: The harness waits for an entrance**

In `test/shared/widgets/support/mx_harness.dart`, `expectMxGolden` gains `Duration? settle,` after `FocusNode? focus,`. After the focus block, before the capture:

```dart
  if (settle != null) {
    await tester.pump(settle);
  }
```

and its doc comment ends: "[settle] lets an entrance (a snackbar's) finish before the capture."

- [ ] **Step 1: Write the failing tests**

Create `test/shared/widgets/mx_snackbar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import 'support/mx_harness.dart';

Widget _trigger({
  String? action,
  VoidCallback? onAction,
  bool isUndo = false,
}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showMxSnackbar(
      context,
      message: 'Deck moved to Trash',
      actionLabel: action,
      onAction: onAction,
      isUndo: isUndo,
    ),
    child: const Text('Go'),
  ),
);

void main() {
  testWidgets('a message stays 4s', (tester) async {
    await pumpMx(tester, _trigger());
    await tester.tap(find.text('Go'));
    await tester.pump();
    final SnackBar bar = tester.widget(find.byType(SnackBar));
    expect(bar.duration, AppDurations.toast);
    expect(find.text('Deck moved to Trash'), findsOneWidget);
  });

  testWidgets('Undo stays 8s, reads in inverse-primary and closes it', (
    tester,
  ) async {
    var undone = 0;
    await pumpMx(
      tester,
      _trigger(action: 'Undo', onAction: () => undone++, isUndo: true),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    final SnackBar bar = tester.widget(find.byType(SnackBar));
    expect(bar.duration, AppDurations.toastWithUndo);
    final MxButton undo = tester.widget(find.byType(MxButton));
    expect(undo.tone, MxButtonTone.inverse);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('with TalkBack on, an action keeps it up', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Scaffold(
            body: _trigger(action: 'Undo', onAction: () {}, isUndo: true),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isTrue);
  });
}
```

Create `test/shared/widgets/mx_inline_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxInlineBannerTone, (Color, Color, Color)> tones = {
      MxInlineBannerTone.warning: (
        x.warningContainer,
        x.warning,
        x.onWarningContainer,
      ),
      MxInlineBannerTone.danger: (
        s.errorContainer,
        s.error,
        s.onErrorContainer,
      ),
    };
    for (final MapEntry(key: tone, value: (ground, edge, content))
        in tones.entries) {
      testWidgets('$name: ${tone.name} reads in its container\'s on-role', (
        tester,
      ) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 340,
            child: MxInlineBanner(
              tone: tone,
              title: 'Sync paused',
              message: 'Nothing was lost; changes wait on this phone.',
            ),
          ),
          theme: theme,
        );
        final BoxDecoration box =
            tester
                    .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                    .decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(box.border!.top.color, edge);
        expect(
          tester.widget<Text>(find.text('Sync paused')).style!.color,
          content,
        );
        expect(tester.widget<Icon>(find.byType(Icon).first).color, content);
      });
    }
  }

  testWidgets('its primary action comes last', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 340,
        child: MxInlineBanner(
          tone: MxInlineBannerTone.warning,
          message: 'Reminders are off in system settings.',
          actions: [
            MxInlineBannerAction(
              label: 'Open settings',
              onPressed: () {},
              isPrimary: true,
            ),
            MxInlineBannerAction(label: 'Try again', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Try again')).dx,
      lessThan(tester.getTopLeft(find.text('Open settings')).dx),
    );
    final List<MxButton> buttons = tester
        .widgetList<MxButton>(find.byType(MxButton))
        .toList();
    expect(buttons.last.tone, MxButtonTone.primary);
    expect(buttons.first.tone, MxButtonTone.text);
  });
}
```

Create `test/shared/widgets/mx_empty_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import 'support/mx_harness.dart';

Size _tile(WidgetTester tester) => tester.getSize(
  find
      .descendant(
        of: find.byType(MxEmptyState),
        matching: find.byType(SizedBox),
      )
      .first,
);

void main() {
  testWidgets('a 64 tile, a header title, two actions and a footnote', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var created = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxEmptyState(
          icon: Icons.style,
          title: 'No decks yet',
          message: 'Make a deck, or import one you exported before.',
          action: MxEmptyStateAction(
            label: 'Create deck',
            onPressed: () => created++,
          ),
          secondaryAction: MxEmptyStateAction(
            label: 'Import cards',
            onPressed: () {},
          ),
          footnote: 'Decks stay on this phone until you sign in.',
        ),
      ),
    );
    expect(_tile(tester), const Size.square(AppSize.emptyTile));
    expect(
      tester.getSemantics(find.text('No decks yet')),
      isSemantics(isHeader: true, label: 'No decks yet'),
    );
    final List<MxButton> buttons = tester
        .widgetList<MxButton>(find.byType(MxButton))
        .toList();
    expect(buttons.first.tone, MxButtonTone.primary);
    expect(buttons.last.tone, MxButtonTone.text);
    expect(find.byType(MxNote), findsOneWidget);
    await tester.tap(find.text('Create deck'));
    expect(created, 1);
    semantics.dispose();
  });

  testWidgets('compact is a 48 tile', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxEmptyState(
          icon: Icons.search_off,
          title: 'No results',
          isCompact: true,
        ),
      ),
    );
    expect(_tile(tester), const Size.square(AppSize.emptyTileCompact));
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxEmptyStateTone, (Color, Color)> pairs = {
      MxEmptyStateTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxEmptyStateTone.neutral: (s.surfaceContainerHigh, s.onSurfaceVariant),
      MxEmptyStateTone.success: (x.successContainer, x.onSuccessContainer),
      MxEmptyStateTone.warning: (x.warningContainer, x.onWarningContainer),
      MxEmptyStateTone.danger: (s.errorContainer, s.onErrorContainer),
    };
    for (final MapEntry(key: tone, value: (ground, glyph)) in pairs.entries) {
      testWidgets('$name: ${tone.name} tile', (tester) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 360,
            child: MxEmptyState(icon: Icons.style, title: 'Done', tone: tone),
          ),
          theme: theme,
        );
        final BoxDecoration box =
            tester
                    .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                    .decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Icon>(find.byIcon(Icons.style)).color, glyph);
      });
    }
  }
}
```

Create `test/shared/widgets/mx_error_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a load failure offers Retry', (tester) async {
    var retries = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxErrorState(
          title: "Couldn't load your library",
          message: 'Nothing was lost. Try again in a moment.',
          retryLabel: 'Retry',
          onRetry: () => retries++,
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    expect(
      tester.getSize(
        find
            .descendant(
              of: find.byType(MxErrorState),
              matching: find.byType(SizedBox),
            )
            .first,
      ),
      const Size.square(AppSize.emptyTile),
    );
  });

  testWidgets('without Retry it is the not-found form', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxErrorState(title: 'This deck is gone'),
      ),
    );
    expect(find.byType(MxButton), findsNothing);
  });

  testWidgets('a network failure shows cloud-off', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxErrorState(
          title: "Couldn't reach the server",
          retryLabel: 'Retry',
          onRetry: () {},
          isNetwork: true,
        ),
      ),
    );
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_snackbar_test.dart test/shared/widgets/mx_inline_banner_test.dart test/shared/widgets/mx_empty_state_test.dart test/shared/widgets/mx_error_state_test.dart`
Expected: compile failure, because the sources under test do not exist yet.

- [ ] **Step 3: Write the styles and widgets**

Create `lib/core/theme/components/feedback_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// How bad an inline banner's news is (DESIGN.md, Feedback and Status).
enum MxInlineBannerTone { warning, danger }

/// A banner's container ground, its edge and the `on-` role its glyph,
/// title and message read in.
({Color ground, Color edge, Color content}) mxBannerColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxInlineBannerTone tone,
) => switch (tone) {
  MxInlineBannerTone.warning => (
    ground: semantic.warningContainer,
    edge: semantic.warning,
    content: semantic.onWarningContainer,
  ),
  MxInlineBannerTone.danger => (
    ground: colors.errorContainer,
    edge: colors.error,
    content: colors.onErrorContainer,
  ),
};

/// A banner's bold title: Body at 700 in the banner's content colour.
TextStyle? mxBannerTitleStyle(TextTheme texts, Color content) {
  final TextStyle? body = texts.bodyMedium;
  if (body == null) {
    return null;
  }
  return AppTypography.withWeight(body.apply(color: content), FontWeight.w700);
}

/// What an empty state's tile says (DESIGN.md, MxEmptyState).
enum MxEmptyStateTone { primary, neutral, success, warning, danger }

ToneColors mxEmptyTileColors(
  ColorScheme colors,
  AppSemanticColors semantic,
  MxEmptyStateTone tone,
) => switch (tone) {
  MxEmptyStateTone.primary => (
    ground: colors.primaryContainer,
    content: colors.onPrimaryContainer,
  ),
  MxEmptyStateTone.neutral => (
    ground: colors.surfaceContainerHigh,
    content: colors.onSurfaceVariant,
  ),
  MxEmptyStateTone.success => (
    ground: semantic.successContainer,
    content: semantic.onSuccessContainer,
  ),
  MxEmptyStateTone.warning => (
    ground: semantic.warningContainer,
    content: semantic.onWarningContainer,
  ),
  MxEmptyStateTone.danger => (
    ground: colors.errorContainer,
    content: colors.onErrorContainer,
  ),
};
```

Create `lib/shared/widgets/mx_snackbar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Shows one transient message (DESIGN.md, MxSnackbar), replacing any that
/// shows: 4s, or 8s when it offers Undo ([isUndo]). While TalkBack is on, a
/// message with an action stays until it is used or dismissed, so the
/// action can be reached.
void showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool isUndo = false,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();
  final bool hasAction = actionLabel != null && onAction != null;
  messenger.showSnackBar(
    SnackBar(
      duration: isUndo ? AppDurations.toastWithUndo : AppDurations.toast,
      persist: hasAction && MediaQuery.accessibleNavigationOf(context),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.gutter,
        end: AppSpacing.micro,
      ),
      content: MxSnackbar(
        message: message,
        actionLabel: actionLabel,
        onAction: hasAction
            ? () {
                messenger.hideCurrentSnackBar();
                onAction();
              }
            : null,
      ),
    ),
  );
}

/// The content of a snackbar: the message in `on-inverse-surface` and one
/// optional action in `inverse-primary`, inside a 48 row.
class MxSnackbar extends StatelessWidget {
  const MxSnackbar({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? action = actionLabel;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.apply(
                color: context.colors.onInverseSurface,
              ),
            ),
          ),
          if (action != null)
            MxButton(
              label: action,
              onPressed: onAction,
              tone: MxButtonTone.inverse,
              size: MxButtonSize.compact,
            ),
        ],
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_inline_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/feedback_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

export 'package:memox/core/theme/components/feedback_style.dart'
    show MxInlineBannerTone;

/// One action of a banner; the primary one is drawn last.
class MxInlineBannerAction {
  const MxInlineBannerAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// The banner's main action, filled; a screen that already shows a
  /// primary for this decision passes `false` (The One Indigo Rule).
  final bool isPrimary;
}

/// A warning or danger owned by its screen (DESIGN.md, MxInlineBanner): the
/// container ground with a hairline in the tone's role; glyph, bold title and
/// message in the container's `on-` role; actions at the end, primary last.
class MxInlineBanner extends StatelessWidget {
  const MxInlineBanner({
    required this.tone,
    required this.message,
    this.title,
    this.actions = const <MxInlineBannerAction>[],
    super.key,
  });

  final MxInlineBannerTone tone;
  final String message;
  final String? title;
  final List<MxInlineBannerAction> actions;

  @override
  Widget build(BuildContext context) {
    final paint = mxBannerColors(context.colors, context.semanticColors, tone);
    final String? heading = title;
    final List<MxInlineBannerAction> ordered = [
      for (final action in actions)
        if (!action.isPrimary) action,
      for (final action in actions)
        if (action.isPrimary) action,
    ];
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paint.ground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: paint.edge, width: AppStroke.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.grouped),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.control,
            children: [
              Row(
                spacing: AppSpacing.control,
                children: [
                  Icon(
                    tone == MxInlineBannerTone.danger
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    size: AppIconSize.medium,
                    color: paint.content,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (heading != null)
                          Text(
                            heading,
                            style: mxBannerTitleStyle(
                              context.texts,
                              paint.content,
                            ),
                          ),
                        Text(
                          message,
                          style: context.texts.bodyMedium?.apply(
                            color: paint.content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (ordered.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.control,
                  children: [
                    for (final action in ordered)
                      MxButton(
                        label: action.label,
                        onPressed: action.onPressed,
                        size: MxButtonSize.small,
                        tone: action.isPrimary
                            ? MxButtonTone.primary
                            : MxButtonTone.text,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/feedback_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

export 'package:memox/core/theme/components/feedback_style.dart'
    show MxEmptyStateTone;

/// An empty state's action: a label and what it does.
class MxEmptyStateAction {
  const MxEmptyStateAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Nothing here yet, and what to do (DESIGN.md, MxEmptyState): a toned r20
/// tile (64, or 48 [isCompact]), 8 to the title and its message, 12 to up to
/// two actions (the first filled, 8 apart) and an optional footnote.
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.tone = MxEmptyStateTone.primary,
    this.action,
    this.secondaryAction,
    this.footnote,
    this.isCompact = false,
    super.key,
  }) : assert(
         secondaryAction == null || action != null,
         'A second action follows a first.',
       );

  final IconData icon;
  final String title;
  final String? message;
  final MxEmptyStateTone tone;
  final MxEmptyStateAction? action;
  final MxEmptyStateAction? secondaryAction;

  /// A product rule under the actions, drawn as `MxNote.hint`.
  final String? footnote;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tile = mxEmptyTileColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final String? body = message;
    final MxEmptyStateAction? first = action;
    final MxEmptyStateAction? second = secondaryAction;
    final String? rule = footnote;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.gutter : AppSpacing.section,
        vertical: isCompact ? AppSpacing.section : AppSpacing.major,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: isCompact
                  ? AppSize.emptyTileCompact
                  : AppSize.emptyTile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tile.ground,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(icon, size: AppIconSize.large, color: tile.content),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleLarge,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.control),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.apply(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (first != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxButton(label: first.label, onPressed: first.onPressed),
          ],
          if (second != null) ...[
            const SizedBox(height: AppSpacing.control),
            MxButton(
              label: second.label,
              onPressed: second.onPressed,
              tone: MxButtonTone.text,
            ),
          ],
          if (rule != null) ...[
            const SizedBox(height: AppSpacing.control),
            MxNote.hint(text: rule),
          ],
        ],
      ),
    );
  }
}
```

Create `lib/shared/widgets/mx_error_state.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// An inline load failure with Retry, or, without [onRetry], the "not
/// found" form (DESIGN.md, MxErrorState): an r16 `error-container` tile, the
/// empty state's 64, with
/// the alert glyph (cloud-off only for a network failure), a title, an
/// optional message in the local-first voice and the Retry button.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.isNetwork = false,
    super.key,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'Retry has a label and an action, or neither.',
       );

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool isNetwork;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final String? body = message;
    final String? retry = retryLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.section,
        vertical: AppSpacing.major,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSize.emptyTile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  isNetwork ? Icons.cloud_off_outlined : Icons.error_outline,
                  size: AppIconSize.large,
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleLarge,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.control),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.apply(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (retry != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxButton(
              label: retry,
              onPressed: onRetry,
              tone: MxButtonTone.secondary,
              icon: Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_snackbar_test.dart test/shared/widgets/mx_inline_banner_test.dart test/shared/widgets/mx_empty_state_test.dart test/shared/widgets/mx_error_state_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_feedback_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('inline_banner', 'tones'): () => _column([
      MxInlineBanner(
        tone: MxInlineBannerTone.warning,
        title: 'Reminders are off',
        message: 'System settings block MemoX notifications.',
        actions: [
          MxInlineBannerAction(
            label: 'Open settings',
            onPressed: () {},
            isPrimary: true,
          ),
          MxInlineBannerAction(label: 'Try again', onPressed: () {}),
        ],
      ),
      const MxInlineBanner(
        tone: MxInlineBannerTone.danger,
        message: "Couldn't sync. Nothing was lost; changes wait on this phone.",
      ),
    ]),
    ('empty_state', 'forms'): () => _column([
      MxEmptyState(
        icon: Icons.style_outlined,
        title: 'No decks yet',
        message: 'Make a deck, or import one you exported before.',
        action: MxEmptyStateAction(label: 'Create deck', onPressed: () {}),
        secondaryAction: MxEmptyStateAction(
          label: 'Import cards',
          onPressed: () {},
        ),
      ),
      const MxEmptyState(
        icon: Icons.check_circle_outline,
        title: 'All caught up',
        tone: MxEmptyStateTone.success,
        isCompact: true,
      ),
    ]),
    ('error_state', 'forms'): () => _column([
      MxErrorState(
        title: "Couldn't load your library",
        message: 'Nothing was lost. Try again in a moment.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
      const MxErrorState(title: 'This deck is gone'),
    ]),
    ('snackbar', 'forms'): () => const Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _SnackbarStage(message: 'Deck saved'),
        _SnackbarStage(message: 'Deck moved to Trash', actionLabel: 'Undo'),
      ],
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
          // A snackbar slides in; let it land before the capture.
          settle: const Duration(milliseconds: 600),
        );
      });
    }
  }
}

/// A phone-width stage that shows one real snackbar as it opens.
class _SnackbarStage extends StatefulWidget {
  const _SnackbarStage({required this.message, this.actionLabel});

  final String message;
  final String? actionLabel;

  @override
  State<_SnackbarStage> createState() => _SnackbarStageState();
}

class _SnackbarStageState extends State<_SnackbarStage> {
  bool _isShown = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      height: 96,
      child: ScaffoldMessenger(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              if (_isShown) {
                return const SizedBox.expand();
              }
              _isShown = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => showMxSnackbar(
                  context,
                  message: widget.message,
                  actionLabel: widget.actionLabel,
                  onAction: widget.actionLabel == null ? null : () {},
                ),
              );
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }
}
```

Run (Linux container): `flutter test --update-goldens test/shared/widgets/mx_feedback_golden_test.dart`
Expected: `All tests passed!` and, under `test/shared/widgets/goldens/`, `mx_inline_banner__*__light.png` / `__dark.png`, `mx_empty_state__*__light.png` / `__dark.png`, `mx_error_state__*__light.png` / `__dark.png`, `mx_snackbar__*__light.png` / `__dark.png`.

- [ ] **Catalog**

Set the `Status` cell of `MxSnackbar`, `MxInlineBanner`, `MxEmptyState`, `MxErrorState` to `built`. Append these contracts at the end of `### Contracts` (before `## Do's and Don'ts`):

```markdown
#### MxSnackbar
- Variants: message only (at most two lines); one action (`isUndo` keeps it 8s)
- States: shown 4s or 8s; held while TalkBack is on and it carries an action
- Accessibility: the action is reachable for TalkBack; it replaces any snackbar already shown
- Tokens: `inverse-surface`, `on-inverse-surface`, `inverse-primary` (the action: `MxButton`'s inverse tone, for any action on an inverse surface, with its pressed overlay and an `inverse-primary` focus ring); `AppRadius.md`; `AppDurations.toast`, `AppDurations.toastWithUndo`
- Golden: forms__light, forms__dark


#### MxInlineBanner
- Variants: tones warning, danger; optional title; up to two actions, the primary last
- States: one
- Accessibility: a live region; glyph plus words, never colour alone
- Tokens: `warning-container` / `on-warning-container` / `warning` edge, `error-container` / `on-error-container` / `error` edge; `AppRadius.md`; `AppIconSize.medium`
- Golden: tones__light, tones__dark


#### MxEmptyState
- Variants: tones primary, neutral, success, warning, danger; compact; up to two actions (the first filled); footnote; tile 8 to the title, 8 to the message, 12 to the actions, 8 between them
- States: one
- Accessibility: the title is a header; the tile is decorative
- Tokens: each tone's container under its `on-…-container`; `AppSize.emptyTile` (64), `AppSize.emptyTileCompact` (48); `AppRadius.xl`; glyph `AppIconSize.large`; `titleLarge`, `bodyMedium`
- Golden: forms__light, forms__dark


#### MxErrorState
- Variants: with Retry (load failure), without (not found); network glyph
- States: one
- Accessibility: the title is a header and a live region; the message speaks in the local-first voice
- Tokens: `error-container`, `on-error-container`; the empty state's tile (`AppSize.emptyTile`, 64); `AppRadius.lg`; glyph `AppIconSize.large`; `titleLarge`, `bodyMedium`
- Golden: forms__light, forms__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (`check.py` requires each `built` component's source, widget test and every listed golden).

- [ ] **Verify**

Run: `dart format --output=none --set-exit-if-changed lib test` → no change; `flutter analyze lib/core/theme lib/shared test/shared test/core` → `No issues found!`; `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` → `Errors: 0`.

- [ ] **Commit**

```bash
git add lib test/shared DESIGN.md
git commit -m "feat(sp3a-p3): MxSnackbar, MxInlineBanner, MxEmptyState and MxErrorState

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 7: Review, Impeccable, gate and sign-off

**Files:**
- Modify (only if findings): the component, its style or `DESIGN.md`, with the goldens it changes
- Modify: `docs/wbs_FE.md`

- [ ] **Step 1: The gate and the goldens**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → every gate passes.
Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` → 62 goldens match.

- [ ] **Step 2: Impeccable critique of the Phase 3 goldens**

Run the `impeccable` skill's `critique` on the 30 new `mx_*` goldens against DESIGN.md (Components, Colors, Elevation, Shapes) and the contracts. Assessments A and B run on two Sonnet sub-agents. Fix every finding in one batch, at the layer A10 names, and re-render what it touches. Then run one `impeccable audit` of the fix. Report what it found and run no further audit.

- [ ] **Step 3: The final whole-branch review**

Build the review package with `review-package <plan> <first P3 commit>^ HEAD`, and dispatch the reviewer on Opus with this plan's Review Focus. Fix Critical and Important findings in one pass, each RED→GREEN. Ledger the minors.

- [ ] **Step 4: The golden review page and the gallery**

Build the `golden-compare` page for the 30 added goldens (base: the commit before Task 2), publish it, and republish the shared-widget gallery (`python3 tools/design/gallery.py --out <scratchpad>/mx-gallery.html`).

- [ ] **Step 5: WBS, push and sign-off**

In `docs/wbs_FE.md`, set SP3a-P3 to `xong` with this plan's link and the evidence; set the next column of SP3a to Plan P4. Run `python3 tools/docs/generate.py` and `python3 tools/docs/check.py | tail -1` → `PASS`. Commit, push, and ask the owner for the Phase 3 sign-off through `AskUserQuestion`. Include the gate, the golden page, the gallery, the Impeccable and review findings, and the decision table.

---

## Outcome (owner sign-off, 2026-10-04)

Phase 3 is accepted as is: 16 components, gate 1931/1931, component goldens pass, no Critical finding, every Important finding fixed with a regression test (`710be57`).

**Frozen contracts.** From the sign-off, the semantic contracts of the 16 components are the baseline and their goldens are the verification baseline (DESIGN.md stays the source). A later phase changes a Phase 3 component only when:
1. the composition exposes a real root cause in the lower component;
2. an accessibility, contrast or gate check fails; or
3. its DESIGN.md contract changes through review.

An aesthetic preference alone never reopens one.

**Design debt.** Four critique questions are recorded as `- Debt:` lines with their review triggers on the `MxCard`, `MxBadge`, `MxLinearProgress` and `MxSheetActions` contracts in DESIGN.md (owner phase: SP3b review).

**Deferred minors (final review).** These are not pulled into a later phase as a batch. One is taken up only if it blocks a composition, breaks a component's contract, or becomes Important once the component is composed.
- `MxSheetActions`: no assert that `cancelLabel` and `onCancel` come together.
- `MxSheetActions`: no text-scale stacking test; `mxCanButtonLabelFit` hardcodes `TextDirection.ltr` (width-neutral) without a comment.
- `showMxDialog`: the transition builder allocates a `CurvedAnimation` per frame.
- `mx_bottom_sheet_test`: the keyboard finder is brittle; the reduced-motion tests in the sheet and dialog are weak.
- `MxSkeleton`: line height is the font size, not the text-scaled line height; a live `disableAnimations` toggle is untested.
- `MxErrorState`: the live region covers the title only.
- `MxInlineBanner`: its tone icon has no label.
- `MxSection`: the overline's `toUpperCase` is not locale-aware.
- `MxLinearProgress`: its `Semantics` has no `container`; "as long as the bar is thick" in its doc is unclear.
- Golden harness: `debugDisableShadows` is restored outside a `finally`.
- `MxCard`: the selected edge is painted beneath a full-bleed child.

**Ruling.** "Selecting a card shifts its content" does not reproduce: a `DecoratedBox` border never insets its child. The test 'choosing a card moves neither its size nor its content' pins this.
