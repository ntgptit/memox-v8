# SP3a Phase 4 — Generic Composition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the nine Phase 4 catalog components: `MxScreenScaffold`, `MxScreenScroll`, `MxAppBar`, `MxBreadcrumb`, `MxFooterBar`, `MxListRow`, `MxSettingsRow`, `MxListSectionHeader` and `MxActionSheetCommandRow`. Each comes with its theme slot, widget tests and full-HD light and dark goldens, and moves to `built`. This closes the SP3a catalog.

**Architecture:**
- **One style source.** `lib/core/theme/components/chrome_style.dart` holds:
  - the bar ground and title (`mxAppBarGround`, `mxAppBarTitleStyle`, `MxAppBarDensity`);
  - the row title (`mxRowTitleStyle`);
  - the command row's colours (`mxCommandRowColors`);
  - the `appBarTheme` slot (`mxAppBarTheme`).
- **Widgets.** They live in `lib/shared/widgets/`, read only those functions and the generated scales, and compose the Phase 2 and Phase 3 components. No literal colour, text style, size or duration appears in `lib/shared/`.
- **The frame.** `MxScreenScaffold` is built on Material's `Scaffold`, so the keyboard resize and the scroll notification that drives the bar's scrolled-under ground come from the framework.
  - The content keeps to the 720 column. Grounds span the window.
  - The FAB is layered over the body only.
  - It knows no tab, route or bottom bar.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13 (Material 3 `AppBarThemeData`, `ScrollNotificationObserver`); `flutter_test` goldens through the Phase 2 harness (`expectMxGolden`, 1080 × 2400 at 2.625).

**Spec:** `docs/superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md` (§4.4 Phase 4, §5 component contract, §7 definition of done). Phase 3 plan and its sign-off: `docs/superpowers/plans/2026-10-04-sp3a-p3-surfaces-feedback.md` (Outcome).

## Global Constraints

- **The API takes meaning, not looks** (spec §5). Callers pass semantic variants, typed `Mx*` slots and localized copy only. They never pass a `Color`, `TextStyle`, `BorderRadius`, `BorderSide`, `BoxShadow`, padding or icon size.
  - Composition slots are allowed: `MxScreenScaffold.body`, `MxFooterBar.actions`, the bar's `MxIconButton` actions and the header's `MxChipTrigger`.
- **Every control keeps a 48 × 48 hit area** (The 48 Floor Rule). Every height is a minimum (The Text Grows Rule). A title keeps one line (The Wrap Rule).
- **The owner's rulings hold:**
  - `primary` is #4151C6 in both themes, and a selection never fills it.
  - The Indigo Accent `on-primary-container` is the indigo foreground.
  - The pre-SP2 code may flag that a decision is needed, never supply a value.
- **The Phase 3 contracts are frozen** (P3 sign-off). This phase composes them and changes none of them.
  - A change needs a real root cause found while composing, a failing accessibility, contrast or gate check, or a reviewed DESIGN.md change.
  - The P3 deferred minors stay deferred unless one blocks a composition here.
- **Out of scope:** the navigation shell, `MxBottomNav`, `MxNavRail`, SCR-DECK-001, the deck row, `DeckPickerSheet` and every product-semantic or feature component (SP3b), plus the one-domain asks (SP3c).
- **Every text restyle lives in `lib/core/theme/components/`.** In `lib/shared/`, `.apply(color:)` on a theme role is allowed; `.copyWith(` and `TextStyle(` are not (guard `no_text_restyle`).
- **No raw colour in `lib/shared/`** (guard `no_raw_color`).
- **Code style:**
  - Booleans read as predicates.
  - There is no `else`; code returns early.
  - A row centres its leading and trailing marks (guard `row_marks_centre_on_the_row`).
  - Directional insets (`EdgeInsetsDirectional`, `PositionedDirectional`) wherever start and end differ.
- **Retired vocabulary.** Comments say "ripple", never "ink" (`check.py`, A2/A11).
- **Goldens** are full-HD composite sheets named `mx_<component>__<state>__<variant>.png`. They are generated in the Linux container only.
- **Commit attribution.** Every commit ends with this session's two attribution lines.

## Scope, consumers and dependencies

No screen spec names an `Mx*` type. The specs name roles ("App bar", "Breadcrumb", "Footer", "list row", "section header", "settings row", "command row"). A sweep of `docs/screens/spec/` (2026-10-04) maps those roles to the components below. Each has consumers in at least two domains, which is the spec §4.4 bar for `shared`.

| Component | Consumers (screen IDs) | Domains | Built on |
|---|---|---|---|
| MxScreenScaffold | ~33 of 34 page specs: DECK-001, CARD-001/002, SETTINGS-001, STUDY-009, TRANSFER-001 … | 14 | P1 tokens; `MxFab` (P2) |
| MxScreenScroll | DECK-001 and CARD-001 (FAB lists); TRASH, PROGRESS, MONITORING … | 11 | P1 tokens |
| MxAppBar | 26 specs: CARD-001 selection, TRASH-001, STUDY-009, SETTINGS-*, ACCOUNT-*, PROGRESS-001 … | 14 | `MxIconButton`, `MxButton` (P2) |
| MxBreadcrumb | CARD-001…004, DECK-001, STUDY-002, SETTINGS-001, SRS-001, PROGRESS-001, TRANSFER-001 | 7 | `MxRowInk`, `MxFocusRing` (P2) |
| MxFooterBar | CARD-002/003, SETTINGS-001, STUDY-002/009, TRASH-001, TRANSFER-001, MONITORING, SEARCH-001, PROGRESS-001 | 9 | `MxSheetActions` (P3) in its slot |
| MxListRow | TRASH-001, CARD-001, PROGRESS-001, SEARCH-001, ACCOUNT-006, STUDY-001/002/009, TAG-001, MONITORING | 9 | `MxIconTile`, `MxBadge` (P3); `MxSelectionCheckbox`, `MxIconButton`, `MxRowInk`, `MxFocusRing` (P2) |
| MxSettingsRow | SETTINGS-001/002, REMINDER, DECK-001 (sort sheet toggle), ACCOUNT-001/005 | 4 | `MxIconTile` (P3); `MxToggle`, `MxRowInk`, `MxFocusRing` (P2) |
| MxListSectionHeader | DECK-001, CARD-001 (with a sort trigger), STUDY-001/002, SEARCH-001, TRASH-001, TAG-001, SRS-001, PROGRESS-001, ACCOUNT-006, TRANSFER-002, MONITORING | 11 | `MxChipTrigger` (P2); `mxSectionLabelStyle` (P3) |
| MxActionSheetCommandRow | DECK-001, CARD-001, TAG-001, TRASH-001 | 4 | `MxRowInk`, `MxFocusRing` (P2); shown in `MxBottomSheet` (P3) |

**Spec conflicts flagged, not decided here.** The screen phases own these.
- CARD-003 puts "Save" in the bar (lines 24–25 and 135), and DESIGN.md forbids it ("a form's single save lives in its footer"). DESIGN.md wins (ADR-021); the spec is fixed in its screen phase.
- DECK-001's "(large)" bar is an SP3b feature header, not a third density.
- STUDY-009's muted title and centred short content, SEARCH-001's field in the bar, the three-button footer (ACCOUNT-002), the icon bulk bar (CARD-001), and the settings row's under-label stepper and tray (SETTINGS-002) each have one domain, so they move to SP3c.

## Review Focus

- **The footer inside the shell, with the keyboard up.** It must sit on the keyboard, not on the navigation bar's padding as well (no double inset). Pinned in Task 3 ('with the keyboard up the footer sits on it, not on the bar').
- **A disabled row.** It must not run its tap, and its reason stays readable. Pinned in Task 2 ('a disabled row does not run its tap', and the dimming test).
- **Twice the text in a full row** (a tile, a subtitle, a badge). Nothing clips or overflows. Pinned in Task 2 ('at twice the text a full row neither clips nor overflows').
- **A long path on a phone.** The current place stays whole, each ancestor stays a 48 target and is read whole, and the order flips in right-to-left text. Pinned in Task 3 (the breadcrumb tests).
- **A selection count in the bar.** TalkBack hears the count change only when the caller marks the title live, so taps elsewhere do not chatter. Pinned in Task 3 ('the title is a header; a live one announces its change').

## Decisions (for the owner's approval)

Each value comes from DESIGN.md, Material 3 or accessibility, never from pre-SP2 code. Impeccable (`shape`) reviewed the first draft, 2026-10-04: no rejections and 14 amendments, all folded in below (marked ✎).

| # | Decision | Value | Source | DESIGN.md change | Test |
|---|---|---|---|---|---|
| 1 | Scaffold scope | A frame with these slots: bar, pinned breadcrumb (outside the scroll), one body (any widget), in-flow footer, FAB. It knows no tab, route or bottom bar; the shell hands it the room left as the bottom inset. No banner slot. | Layout ("every screen is a column in `MxScreenScaffold`"); spec §4.2 | contract | slots in order |
| 2 | Content column ✎ | The body, breadcrumb, footer and bar content keep to the 720 column; the bar and footer grounds span the window | The Column Rule | contract | 1000-wide window |
| 3 | FAB ✎ | 16 inside the column's end edge (the start edge in right-to-left text), 16 above the footer or the system bar, over the body only. The scaffold never hides it; the caller passes none while its own state hides it (selecting, searching). | Layout; CARD-001:51 | contract | position, RTL, inset |
| 4 | Clear tail | 48 (`pageEnd`) under pinned chrome; with a FAB, the FAB plus a gutter on each side (52 + 2 × 16), derived, no new token | The Clear Tail Rule; INV-UI-006 | contract | last item clears the FAB |
| 5 | Insets ✎ | The body and footer ride above the keyboard; the footer clears the system bar on its own ground; no inset is hard-coded and none is applied twice | Layout; INV-UI-005 | contract | keyboard, nav bar, both together |
| 6 | Scroll body | A 16 gutter, the tail, `children` or `builder` (TRASH and MONITORING page long lists). No pull-to-refresh, paging or centring variant (one domain each → SP3c). Rows sit in a full-bleed `MxCard`, not straight on the gutter. | Layout; no speculative structure | contract | gutter, tail, builder |
| 7 | Bar ground ✎ | Flat `surface` at rest, so the bar merges with the page. Once content scrolls under it: `surface-container` (Material 3's scrolled-under container), with no hairline, shadow or tint. `on-surface` and `on-surface-variant` on `surface-container` are already declared pairs (both pass in both themes). | Elevation ("tonal first"); Material 3 small top app bar | contract + `appBarTheme` slot | per theme, at rest and scrolled |
| 8 | Bar densities ✎ | `screen`: the Title role with the -0.5 screen-title tracking (a component override). `content`: Body Large. Two only. | MxAppBar line; Typography › Character | contract | title style |
| 9 | Bar leading ✎ | none (the title on the gutter), back or close (the title 8 past the control's 48 target, which sits 4 from the edge). Named by the platform's words; pops through `Navigator.maybePop`, so `PopScope` and predictive back still decide. | MxAppBar line (critique 3c-1) | contract | 16 / 60, labels, RTL |
| 10 | Bar actions ✎ | Up to 3 `MxIconButton`s, or one text action alone (text tone, never a primary fill); asserted. The title keeps one line with an ellipsis. | One Indigo Rule; a form's save lives in its footer | contract | a 4th is refused; 360 phone |
| 11 | Selection in the bar | No mode: the caller passes close and "{n} selected"; `isTitleLive` makes the title a live region | Do's ("the selected count lives in the app bar title only") | contract | header + live region |
| 12 | Breadcrumb ✎ | One line, never scrolled. The current place keeps its full width while each ancestor keeps a 48 target; the ancestors share the rest and end in an ellipsis. Each label is read whole. Tappable ancestors are 48 buttons with ripple and ring. The current place reads as selected. The separator `chevron_right` 16 mirrors in right-to-left text. Body in `on-surface` / `on-surface-variant`. | spec §4.2 (presentation-neutral); The 48 Floor Rule | contract | narrow path, semantics, RTL |
| 13 | Footer ✎ | `surface` under a 1dp `outline-variant` hairline, no shadow; 16 across and 12 down; the caption in Caption / `on-surface-variant`, 8 above the actions. The actions are a slot: `MxSheetActions` now, `MxActionPair` (SP3c) later, with no footer change. | Do's ("tone and a 1px outline-variant hairline first") | MxFooterBar line: "its caption in `on-surface-variant`" (was `AppOpacity.muted`, alpha over a known ground) | geometry, colours |
| 14 | List row geometry | At least 48; 16 across and 12 down; the leading mark (`MxIconTile` medium 40, or `MxSelectionCheckbox`) 12 from the text; the shared ripple (`MxRowInk`) and the ring | MxOptionRow precedent; Material 3 list leading 40 | contract | geometry |
| 15 | List row text ✎ | The title keeps one line with an ellipsis and is read whole; the subtitle wraps to two lines | The Wrap Rule; TRASH meta | MxListRow line and catalog row: "a one-line title … a subtitle of up to two lines" (was "grows to two title lines") | one line, read whole |
| 16 | List row trailing ✎ | Exactly one of: none, chevron, `MxBadge`, a value, one `MxIconButton` (its own node and focus stop). A badge and the chevron never meet, by construction. A compact button trailing (STUDY-002 alone) moves to SP3c. | MxListRow line | listed in the line | each trailing; separate node |
| 17 | Row states | Tappable or inert (full contrast); disabled dims the leading mark, title and chevron (`AppOpacity.disabled`), never the subtitle; checked while selecting; one TalkBack node | MxListRow / MxSettingsRow lines | contract | semantics, dimming |
| 18 | Section header ✎ | The Section Label upper-cased by the widget (the app's own words), `on-surface-variant`, a header. 16 across and 8 down alone; at least 48 with a trailing `MxChipTrigger` (DECK-001 and CARD-001 sort). Count, text and button trailings have one domain each → SP3c. `MxSection` heads a card; this heads a list. | Section Label; Do's | MxSection line names the split | header, heights |
| 19 | Settings row ✎ | Navigation (chevron), action (no chevron), value (full contrast), toggle (the whole row is one switch node and one focus stop). The lead tile is in `iconTone`. The under-label stepper and tray, and the trailing button, have one domain → SP3c. | MxSettingsRow line (critique 3a, tone pass) | contract | each kind |
| 20 | Settings disabled | Dims the tile, label and chevron, never the subtitle; the toggle draws its own disabled state, not dimmed again | MxSettingsRow line | contract | per part |
| 21 | Large text ✎ | The settings label wraps beside its end mark; no stacking logic | The Wrap Rule (owner 2026-09-30) over the Text Grows Rule's clause | Text Grows Rule: drop "the settings row stacks its trailing control at large scale" | 2.0 scale, no overflow |
| 22 | Command row ✎ | A 24 glyph in `on-surface-variant` (Material 3 menu leading icon, not a tile); Body Large label; an optional subtitle; `isDestructive` paints glyph and label `error`. `error` on `surface-container-high` (the sheet ground) is already a declared pair that passes. No disabled state (no consumer). | Material 3 menus; sheet ground pairs | contract | colours per theme, button |
| 23 | Catalog consumers | Corrected from the sweep: ScreenScroll +DECK, SEARCH, TAG, SETTINGS; Breadcrumb +TRANSFER; SettingsRow +ACCOUNT; FooterBar −DECK; CommandRow = CARD, DECK, TAG, TRASH | evidence | catalog rows | `check.py` |
| 24 | Guard ✎ | No new rule. `no_raw_screen_chrome` already bans a raw `AppBar` and `SliverAppBar` in features, and `ListTile` and `BottomAppBar` are already banned. | existing guard | — | — |
| 25 | Theme slots ✎ | `appBarTheme` (decision 7). No `listTileTheme`: the guard leaves no raw `ListTile` to theme. | spec §5 | — | `app_theme_test` |
| 26 | Token | `AppSize.appBar` = 56, the value DESIGN.md states ("app bar 56"), used by the theme slot and the widget | The Text Grows Rule | — | generator check |

---

### Task 1: The app bar token, the chrome styles, the theme slot, and the Phase 4 DESIGN.md rules

**Files:**
- Modify: `.impeccable/design.json` (`extensions.size`)
- Regenerate: `lib/core/theme/foundations/app_size.dart`
- Create: `lib/core/theme/components/chrome_style.dart`
- Modify: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_theme_test.dart`
- Modify: `DESIGN.md` (decisions 13, 15, 18, 21 and 23; the Text Grows Rule; the MxScreenScaffold line)

**Interfaces:**
- Produces:
  - `AppSize.appBar` (56);
  - `MxAppBarDensity { screen, content }`;
  - `mxAppBarGround(ColorScheme, {required bool isScrolledUnder})`;
  - `mxAppBarTitleStyle(TextTheme, ColorScheme, MxAppBarDensity)`;
  - `mxRowTitleStyle(TextTheme, ColorScheme)`;
  - `mxCommandRowColors(ColorScheme, {required bool isDestructive})` returning `({Color glyph, Color label})`;
  - `mxAppBarTheme(ColorScheme, TextTheme)`.

- [ ] **Step 1: The token**

From the repo root (a one-off, not committed):

```bash
python3 - <<'PYEOF'
import json
from pathlib import Path
s = Path(".impeccable/design.json")
d = json.loads(s.read_text(encoding="utf-8"))
d["extensions"]["size"]["app-bar"] = 56
s.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
PYEOF
python3 tools/design/generate.py --write && python3 tools/design/generate.py --check
```

Expected: `wrote 12 files …` then `PASS …`.

No contrast pair is added. `on-surface` and `on-surface-variant` on `surface-container` (decision 7), and `error` on `surface-container-high` (decision 22), are already declared, and the check above proves them in both themes.

- [ ] **Step 2: DESIGN.md first**

In `DESIGN.md`:

- **Typography › The Text Grows Rule.** Replace "; the settings row stacks its trailing control at large scale." with "." (decision 21).
- **Containers.**
  - Replace "**MxFooterBar** (in-flow commit bar; its caption at `AppOpacity.muted`)" with "**MxFooterBar** (in-flow commit bar; its caption in `on-surface-variant`)" (decision 13).
  - Replace "**MxSection** (overline plus card;" with "**MxSection** (overline plus card, where `MxListSectionHeader` heads a list;" (decision 18).
- **Navigation.** Replace "**MxScreenScaffold** and **MxScreenScroll** (tail clearance for FAB and nav)" with "**MxScreenScaffold** and **MxScreenScroll** (tail clearance for the FAB; the navigation shell supplies its bar as the bottom inset)" (decision 1).
- **Lists.** Replace "**MxListRow** (48 minimum, grows to two title lines; a trailing badge or the chevron, never both)" with "**MxListRow** (48 minimum; a one-line title read whole and a subtitle of up to two lines; one trailing mark — chevron, badge, value or an icon button — so a badge and the chevron never meet)" (decisions 15, 16).
- **Catalog rows.** These are decision 23; the statuses stay `planned` until each component's task.
  - `MxScreenScroll` Consumers become `ACCOUNT, CARD, DECK, MONITORING, PROGRESS, SEARCH, SETTINGS, STUDY, TAG, TRANSFER, TRASH`.
  - `MxBreadcrumb` becomes `CARD, DECK, PROGRESS, SETTINGS, SRS, STUDY, TRANSFER`.
  - `MxFooterBar` becomes `ACCOUNT, CARD, MONITORING, PROGRESS, SEARCH, SETTINGS, STUDY, TRANSFER, TRASH`.
  - `MxSettingsRow` becomes `ACCOUNT, DECK, REMINDER, SETTINGS`.
  - `MxActionSheetCommandRow` becomes `CARD, DECK, TAG, TRASH`.
  - `MxListRow`'s Role becomes "List row, 48 minimum, a one-line title".

Run: `python3 tools/docs/check.py | tail -1` → `PASS — 0 error(s), …`.

- [ ] **Step 3: The failing test**

In `test/core/theme/app_theme_test.dart`, import `package:memox/core/theme/foundations/app_size.dart`, and add this inside the per-theme group, before `'the overlay and card slots match the Mx surfaces'`:

```dart
      test('the app bar slot matches MxAppBar', () {
        final AppBarThemeData bar = theme.appBarTheme;
        expect(bar.backgroundColor, isA<WidgetStateColor>());
        final WidgetStateColor ground =
            bar.backgroundColor! as WidgetStateColor;
        expect(ground.resolve(<WidgetState>{}), scheme.surface);
        expect(
          ground.resolve(<WidgetState>{WidgetState.scrolledUnder}),
          scheme.surfaceContainer,
        );
        expect(bar.elevation, 0);
        expect(bar.scrolledUnderElevation, 0);
        expect(bar.surfaceTintColor, Colors.transparent);
        expect(bar.toolbarHeight, AppSize.appBar);
        expect(bar.centerTitle, isFalse);
        expect(bar.foregroundColor, scheme.onSurface);
      });
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: FAIL on 'the app bar slot matches MxAppBar' (the slot is Flutter's default).

- [ ] **Step 4: The styles and the slot**

Create `lib/core/theme/components/chrome_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// How much a top bar's title says (DESIGN.md, MxAppBar): `screen` names a
/// destination, `content` sits over a pushed task or form whose content
/// leads.
enum MxAppBarDensity { screen, content }

/// Screen titles track tighter than the Title role (DESIGN.md, Typography ›
/// Character): a component override, not a new role.
const double _screenTitleTracking = -0.5;

/// Row titles track slightly tighter than Body Large (component override).
const double _rowTitleTracking = -0.1;

/// The top bar's ground: flat `surface` over a page that has not scrolled, so
/// the bar merges with it; one tonal step (`surface-container`, Material 3's
/// scrolled-under container) once content passes under it. Never a shadow or
/// a tint.
Color mxAppBarGround(ColorScheme colors, {required bool isScrolledUnder}) =>
    isScrolledUnder ? colors.surfaceContainer : colors.surface;

/// The bar's title in `on-surface`: the Title role for a destination, Body
/// Large over content.
TextStyle? mxAppBarTitleStyle(
  TextTheme texts,
  ColorScheme colors,
  MxAppBarDensity density,
) {
  if (density == MxAppBarDensity.content) {
    return texts.titleMedium?.apply(color: colors.onSurface);
  }
  return texts.titleLarge?.copyWith(
    color: colors.onSurface,
    letterSpacing: _screenTitleTracking,
  );
}

/// A list row's title: Body Large with the row tracking.
TextStyle? mxRowTitleStyle(TextTheme texts, ColorScheme colors) => texts
    .bodyLarge
    ?.copyWith(color: colors.onSurface, letterSpacing: _rowTitleTracking);

/// The `AppBarTheme` slot, so a raw bar (the placeholder shell until SP3b)
/// already looks like `MxAppBar`.
AppBarThemeData mxAppBarTheme(ColorScheme colors, TextTheme texts) =>
    AppBarThemeData(
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => mxAppBarGround(
          colors,
          isScrolledUnder: states.contains(WidgetState.scrolledUnder),
        ),
      ),
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: AppSize.appBar,
      titleSpacing: AppSpacing.gutter,
      titleTextStyle: mxAppBarTitleStyle(texts, colors, MxAppBarDensity.screen),
      iconTheme: IconThemeData(color: colors.onSurfaceVariant),
      actionsIconTheme: IconThemeData(color: colors.onSurfaceVariant),
    );

/// A command row's glyph and label: `on-surface-variant` and `on-surface`,
/// both `error` when the command destroys.
({Color glyph, Color label}) mxCommandRowColors(
  ColorScheme colors, {
  required bool isDestructive,
}) {
  if (isDestructive) {
    return (glyph: colors.error, label: colors.error);
  }
  return (glyph: colors.onSurfaceVariant, label: colors.onSurface);
}
```

In `lib/core/theme/app_theme.dart`, import `components/chrome_style.dart` and add to the `ThemeData(...)` call, before `dialogTheme:`:

```dart
      appBarTheme: mxAppBarTheme(scheme, textTheme),
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: all pass.

- [ ] **Verify**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/dod.log 2>&1; tail -3 /tmp/dod.log`
Expected: `✓ mechanical gates passed`.

Run (Linux container): `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: every golden matches.

- [ ] **Commit**

```bash
git add .impeccable/design.json lib/core/theme test/core/theme DESIGN.md
git commit -m "feat(sp3a-p4): the app bar token and theme slot, chrome styles, Phase 4 DESIGN.md rules

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```

---

### Task 2: Rows — MxListRow, MxListSectionHeader, MxSettingsRow, MxActionSheetCommandRow

**Files:**
- Create: `lib/shared/widgets/mx_list_row.dart`
- Create: `lib/shared/widgets/mx_list_section_header.dart`
- Create: `lib/shared/widgets/mx_settings_row.dart`
- Create: `lib/shared/widgets/mx_action_sheet_command_row.dart`
- Test: `test/shared/widgets/mx_list_row_test.dart`
- Test: `test/shared/widgets/mx_list_section_header_test.dart`
- Test: `test/shared/widgets/mx_settings_row_test.dart`
- Test: `test/shared/widgets/mx_action_sheet_command_row_test.dart`
- Golden: `test/shared/widgets/mx_rows_golden_test.dart`
- Modify: `DESIGN.md` (catalog status and contracts)

**Interfaces:**
- Consumes: `mxRowTitleStyle`, `mxCommandRowColors` (Task 1); `MxIconTile`, `MxBadge` (Phase 3); `MxIconButton`, `MxToggle`, `MxSelectionCheckbox`, `MxChipTrigger`, `MxRowInk`, `MxFocusRing` (Phase 2).
- Produces: `MxListRow`, `MxListRowTrailing` (`none`, `chevron`, `badge`, `value`, `iconButton`); `MxListSectionHeader`; `MxSettingsRow` (`.navigation`, `.action`, `.value`, `.toggle`), `MxSettingsRowKind`; `MxActionSheetCommandRow`.

- [ ] **Step 1: The failing tests**

Create `test/shared/widgets/mx_list_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import 'support/mx_harness.dart';

Widget _in(Widget row) => SizedBox(width: 380, child: row);

double _opacityOver(WidgetTester tester, Finder finder) {
  final Finder dim = find.ancestor(of: finder, matching: find.byType(Opacity));
  if (dim.evaluate().isEmpty) {
    return 1;
  }
  return tester.widget<Opacity>(dim.first).opacity;
}

void main() {
  testWidgets('48 at least; 16 across and 12 down', (tester) async {
    await pumpMx(tester, _in(const MxListRow(title: 'Spanish')));
    final Rect row = tester.getRect(find.byType(MxListRow));
    final Rect title = tester.getRect(find.text('Spanish'));
    expect(row.height, greaterThanOrEqualTo(AppSize.tapTarget));
    expect(title.left - row.left, 16);
    expect(title.top - row.top, 12);
  });

  testWidgets('a leading tile is the medium icon tile, 12 from the text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(const MxListRow(title: 'Spanish', icon: Icons.style)),
    );
    final Rect tile = tester.getRect(find.byType(MxIconTile));
    expect(tile.width, AppSize.iconTileMedium);
    expect(tester.getRect(find.text('Spanish')).left - tile.right, 12);
  });

  testWidgets('the title keeps one line and is read whole', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String long =
        'Irregular verbs of the past tense with every exception, chapter twelve';
    await pumpMx(
      tester,
      _in(const MxListRow(title: long, subtitle: 'Due today')),
    );
    expect(tester.renderObject<RenderParagraph>(find.text(long)).maxLines, 1);
    expect(
      tester.getSemantics(find.byType(MxListRow)),
      isSemantics(label: '$long\nDue today'),
    );
    semantics.dispose();
  });

  testWidgets('the subtitle wraps to two lines at most', (tester) async {
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Spanish',
          subtitle:
              'Was in Library › Languages › Spanish › Verbs, removed on Monday '
              'by you, and kept for thirty days before it goes for good',
        ),
      ),
    );
    expect(tester.widget<Text>(find.textContaining('Was in')).maxLines, 2);
  });

  testWidgets('a tappable row is a button with the keyboard ring', (
    tester,
  ) async {
    var taps = 0;
    final Widget row = _in(
      MxListRow(
        title: 'Spanish',
        trailing: const MxListRowTrailing.chevron(),
        onTap: () => taps++,
      ),
    );
    await pumpMx(tester, row);
    await tester.tap(find.text('Spanish'));
    expect(taps, 1);
    await expectMxKeyboardRingOnly(
      tester,
      row,
      painted: tester.getSize(find.byType(MxListRow)),
    );
  });

  testWidgets('a disabled row dims its mark and title, never its subtitle', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          subtitle: 'Available when you are online',
          icon: Icons.cloud,
          trailing: const MxListRowTrailing.chevron(),
          onTap: () {},
          isEnabled: false,
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Spanish')), AppOpacity.disabled);
    expect(_opacityOver(tester, find.byType(MxIconTile)), AppOpacity.disabled);
    expect(
      _opacityOver(tester, find.byIcon(Icons.chevron_right)),
      AppOpacity.disabled,
    );
    expect(_opacityOver(tester, find.text('Available when you are online')), 1);
  });

  testWidgets('a selecting row reads checked', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(MxListRow(title: 'hola', isChecked: true, onTap: () {})),
    );
    expect(
      tester.getSemantics(find.text('hola')),
      isSemantics(isChecked: true, hasCheckedState: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a badge and a value read with the row', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Spanish',
          trailing: MxListRowTrailing.badge('3 days left', MxBadgeTone.warning),
        ),
      ),
    );
    expect(find.byType(MxBadge), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Spanish')),
      isSemantics(label: 'Spanish\n3 days left'),
    );
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Cards',
          trailing: MxListRowTrailing.value('120'),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('120')).style?.color,
      mxThemes['light']!.colorScheme.onSurfaceVariant,
    );
    semantics.dispose();
  });

  testWidgets('a trailing action is its own node beside the row', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var opened = 0;
    var more = 0;
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          onTap: () => opened++,
          trailing: MxListRowTrailing.iconButton(
            MxIconButton(
              icon: Icons.more_vert,
              semanticLabel: 'More for Spanish',
              onPressed: () => more++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    expect((opened, more), (0, 1));
    expect(
      tester.getSemantics(find.text('Spanish')).label,
      isNot(contains('More for Spanish')),
    );
    semantics.dispose();
  });

  testWidgets('in right-to-left text the chevron leads from the left', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          trailing: const MxListRowTrailing.chevron(),
          onTap: () {},
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getRect(find.byIcon(Icons.chevron_right)).left,
      lessThan(tester.getRect(find.text('Spanish')).left),
    );
  });

  testWidgets('a disabled row does not run its tap', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _in(MxListRow(title: 'Sync', onTap: () => taps++, isEnabled: false)),
    );
    await tester.tap(find.text('Sync'));
    expect(taps, 0);
  });

  testWidgets('at twice the text a full row neither clips nor overflows', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxListRow(
            title: 'Japanese kana',
            subtitle: '46 cards · reviewed today',
            icon: Icons.style,
            trailing: const MxListRowTrailing.badge('3 days left'),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

Create `test/shared/widgets/mx_list_section_header_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets(
      '$name: the Section Label, upper-cased, in on-surface-variant',
      (tester) async {
        await pumpMx(
          tester,
          const MxListSectionHeader(title: 'Decks'),
          theme: theme,
        );
        final Text label = tester.widget<Text>(find.text('DECKS'));
        expect(label.style?.color, theme.colorScheme.onSurfaceVariant);
        expect(label.style?.fontSize, theme.textTheme.labelMedium?.fontSize);
      },
    );
  }

  testWidgets('a header for TalkBack; 8 down when it stands alone', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 380, child: MxListSectionHeader(title: 'Decks')),
    );
    expect(
      tester.getSemantics(find.text('DECKS')),
      isSemantics(isHeader: true),
    );
    final Rect header = tester.getRect(find.byType(MxListSectionHeader));
    final Rect label = tester.getRect(find.text('DECKS'));
    expect(label.top - header.top, 8);
    expect(label.left - header.left, 16);
    semantics.dispose();
  });

  testWidgets('48 tall with a trailing chip trigger at its end', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxListSectionHeader(
          title: 'Cards',
          trigger: MxChipTrigger(label: 'Newest', onOpen: () => opened++),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxListSectionHeader)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    await tester.tap(find.text('Newest'));
    expect(opened, 1);
  });
}
```

Create `test/shared/widgets/mx_settings_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

Widget _in(Widget row) => SizedBox(width: 380, child: row);

double _opacityOver(WidgetTester tester, Finder finder) {
  final Finder dim = find.ancestor(of: finder, matching: find.byType(Opacity));
  if (dim.evaluate().isEmpty) {
    return 1;
  }
  return tester.widget<Opacity>(dim.first).opacity;
}

void main() {
  testWidgets('navigation shows the chevron and opens', (tester) async {
    var opened = 0;
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.navigation(
          title: 'Account',
          icon: Icons.person,
          onTap: () => opened++,
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.text('Account'));
    expect(opened, 1);
  });

  testWidgets('an action row shows no chevron and is a button', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.action(
          title: 'Sign out',
          icon: Icons.logout,
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(
      tester.getSemantics(find.text('Sign out')),
      isSemantics(label: 'Sign out', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a following value reads in full in on-surface-variant', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MxSettingsRow.value(
          title: 'Review order',
          icon: Icons.sort,
          value: 'Due first',
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Due first')), 1);
    expect(
      tester.widget<Text>(find.text('Due first')).style?.color,
      mxThemes['light']!.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('the whole toggle row is one switch', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final List<bool> changes = [];
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.toggle(
          title: 'Daily reminder',
          subtitle: 'At 20:00',
          icon: Icons.notifications,
          isOn: false,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.text('Daily reminder'));
    await tester.tap(find.byType(MxToggle));
    expect(changes, [true, true]);
    expect(
      tester.getSemantics(find.text('Daily reminder')),
      isSemantics(
        label: 'Daily reminder\nAt 20:00',
        hasToggledState: true,
        isToggled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('disabled dims tile, label and chevron, not the reason', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.navigation(
          title: 'Sync',
          subtitle: 'Available when you are online',
          icon: Icons.sync,
          onTap: () {},
          isEnabled: false,
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Sync')), AppOpacity.disabled);
    expect(_opacityOver(tester, find.byType(MxIconTile)), AppOpacity.disabled);
    expect(
      _opacityOver(tester, find.byIcon(Icons.chevron_right)),
      AppOpacity.disabled,
    );
    expect(_opacityOver(tester, find.text('Available when you are online')), 1);
  });

  testWidgets('a disabled toggle is not dimmed twice', (tester) async {
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.toggle(
          title: 'Daily reminder',
          icon: Icons.notifications,
          isOn: true,
          onChanged: (_) {},
          isEnabled: false,
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.byType(MxToggle),
        matching: find.descendant(
          of: find.byType(MxSettingsRow),
          matching: find.byType(Opacity),
        ),
      ),
      findsNothing,
    );
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).onChanged, isNull);
  });

  testWidgets('at twice the text the label wraps beside its value', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxSettingsRow.value(
            title: 'Cards per session',
            icon: Icons.layers,
            value: '20',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

Create `test/shared/widgets/mx_action_sheet_command_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets(
      '$name: a 24 glyph in on-surface-variant; destroying is error',
      (tester) async {
        await pumpMx(
          tester,
          MxActionSheetCommandRow(
            icon: Icons.edit,
            label: 'Rename',
            onTap: () {},
          ),
          theme: theme,
        );
        final Icon glyph = tester.widget<Icon>(find.byIcon(Icons.edit));
        expect(glyph.size, AppIconSize.large);
        expect(glyph.color, s.onSurfaceVariant);
        expect(
          tester.widget<Text>(find.text('Rename')).style?.color,
          s.onSurface,
        );
        await pumpMx(
          tester,
          MxActionSheetCommandRow(
            icon: Icons.delete,
            label: 'Delete forever',
            subtitle: 'Cannot be undone',
            isDestructive: true,
            onTap: () {},
          ),
          theme: theme,
        );
        expect(tester.widget<Icon>(find.byIcon(Icons.delete)).color, s.error);
        expect(
          tester.widget<Text>(find.text('Delete forever')).style?.color,
          s.error,
        );
        expect(
          tester.widget<Text>(find.text('Cannot be undone')).style?.color,
          s.onSurfaceVariant,
        );
      },
    );
  }

  testWidgets('a 48 button that runs its command', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var ran = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxActionSheetCommandRow(
          icon: Icons.restore,
          label: 'Restore',
          subtitle: 'Back to Library',
          onTap: () => ran++,
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxActionSheetCommandRow)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    expect(
      tester.getSemantics(find.text('Restore')),
      isSemantics(label: 'Restore\nBack to Library', isButton: true),
    );
    await tester.tap(find.text('Restore'));
    expect(ran, 1);
    semantics.dispose();
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_list_section_header_test.dart test/shared/widgets/mx_settings_row_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart`
Expected: compile failure — the widgets do not exist yet.

- [ ] **Step 2: The widgets**

`lib/shared/widgets/mx_list_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

enum _Trailing { none, chevron, badge, value, iconButton }

/// What ends a list row: exactly one of a closed set, so a badge and the
/// chevron never meet (DESIGN.md, MxListRow).
class MxListRowTrailing {
  const MxListRowTrailing.none()
    : _kind = _Trailing.none,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = null;

  /// The row opens a place; mirrors in right-to-left text.
  const MxListRowTrailing.chevron()
    : _kind = _Trailing.chevron,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = null;

  const MxListRowTrailing.badge(
    String label, [
    this._tone = MxBadgeTone.neutral,
  ]) : _kind = _Trailing.badge,
       _text = label,
       _button = null;

  /// A plain value, read at full contrast in `on-surface-variant`.
  const MxListRowTrailing.value(String value)
    : _kind = _Trailing.value,
      _text = value,
      _tone = MxBadgeTone.neutral,
      _button = null;

  /// One action of its own (an overflow ⋮): its own TalkBack node and focus
  /// stop, apart from the row's tap.
  const MxListRowTrailing.iconButton(MxIconButton button)
    : _kind = _Trailing.iconButton,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = button;

  final _Trailing _kind;
  final String? _text;
  final MxBadgeTone _tone;
  final MxIconButton? _button;
}

/// One row of a list (DESIGN.md, MxListRow): at least 48 tall, 16 across and
/// 12 down; an optional leading icon tile (40) or selection checkbox 12 from
/// the text; a one-line title (cut with an ellipsis, read whole); a subtitle
/// of up to two lines; one trailing mark. Tappable rows carry the shared ripple
/// and the keyboard ring; inert rows stay at full contrast. A disabled row
/// dims its leading mark, title and chevron, never the subtitle that says
/// why. TalkBack reads the row as one node carrying every fact.
class MxListRow extends StatelessWidget {
  const MxListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTone = MxIconTileTone.tinted,
    this.isChecked,
    this.trailing = const MxListRowTrailing.none(),
    this.onTap,
    this.isEnabled = true,
    super.key,
  }) : assert(icon == null || isChecked == null, 'One leading mark.');

  final String title;
  final String? subtitle;

  /// A leading tile in [iconTone].
  final IconData? icon;
  final MxIconTileTone iconTone;

  /// A leading selection checkbox while the list is selecting; `null` hides it.
  final bool? isChecked;

  final MxListRowTrailing trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final double emphasis = isEnabled ? 1 : AppOpacity.disabled;
    final VoidCallback? tap = isEnabled ? onTap : null;
    final String? detail = subtitle;
    final Widget? lead = _leading();
    final Widget? end = _trailing(context);
    final Widget facts = Row(
      children: [
        if (lead != null) ...[
          Opacity(opacity: emphasis, child: lead),
          const SizedBox(width: AppSpacing.grouped),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: emphasis,
                child: Semantics(
                  label: title,
                  excludeSemantics: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mxRowTitleStyle(context.texts, colors),
                  ),
                ),
              ),
              if (detail != null)
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.apply(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (end != null) ...[
          const SizedBox(width: AppSpacing.grouped),
          if (trailing._kind == _Trailing.chevron)
            Opacity(opacity: emphasis, child: end)
          else
            end,
        ],
      ],
    );
    final MxIconButton? action = trailing._button;
    // Beside a trailing action the row stops short; the action's 48 target
    // carries its own inner space.
    final Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: action == null ? AppSpacing.gutter : AppSpacing.micro,
          top: AppSpacing.grouped,
          bottom: AppSpacing.grouped,
        ),
        child: facts,
      ),
    );
    final Widget pressable = tap == null
        ? body
        : MxFocusRing(
            borderRadius: BorderRadius.zero,
            child: MxRowInk(onTap: tap, child: body),
          );
    // One TalkBack node carrying every fact, the ripple's tap and focus included.
    final Widget row = MergeSemantics(
      child: Semantics(
        button: tap != null,
        enabled: isEnabled,
        checked: isChecked,
        child: pressable,
      ),
    );
    if (action == null) {
      return row;
    }
    // The trailing action is its own node beside the row, never merged in.
    return Row(
      children: [
        Expanded(child: row),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.micro),
          child: action,
        ),
      ],
    );
  }

  Widget? _leading() {
    final bool? checked = isChecked;
    if (checked != null) {
      return ExcludeSemantics(child: MxSelectionCheckbox(isChecked: checked));
    }
    final IconData? glyph = icon;
    if (glyph == null) {
      return null;
    }
    return MxIconTile(icon: glyph, tone: iconTone);
  }

  Widget? _trailing(BuildContext context) {
    final ColorScheme colors = context.colors;
    return switch (trailing._kind) {
      _Trailing.none || _Trailing.iconButton => null,
      _Trailing.chevron => ExcludeSemantics(
        child: Icon(
          Icons.chevron_right,
          size: AppIconSize.large,
          color: colors.onSurfaceVariant,
        ),
      ),
      _Trailing.badge => MxBadge(label: trailing._text!, tone: trailing._tone),
      _Trailing.value => Text(
        trailing._text!,
        style: context.texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
      ),
    };
  }
}
```

`lib/shared/widgets/mx_list_section_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// The overline over a list (DESIGN.md, MxListSectionHeader): the Section
/// Label in `on-surface-variant`, upper-cased by the widget (pass the app's
/// own words, never user data), read as a header. 16 across; 8 down when it
/// stands alone, at least 48 tall when it carries a trailing chip trigger
/// (sort or filter). `MxSection` heads a card; this heads a list.
class MxListSectionHeader extends StatelessWidget {
  const MxListSectionHeader({required this.title, this.trigger, super.key});

  final String title;
  final MxChipTrigger? trigger;

  @override
  Widget build(BuildContext context) {
    final MxChipTrigger? end = trigger;
    final Widget label = Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: mxSectionLabelStyle(context.texts, context.colors),
      ),
    );
    if (end == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.control,
        ),
        child: label,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            Expanded(child: label),
            end,
          ],
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_settings_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// How a settings row reads at its end (DESIGN.md, MxSettingsRow).
enum MxSettingsRowKind {
  /// Opens a page: a chevron, mirrored in right-to-left text.
  navigation,

  /// Runs an action or opens a dialog: no chevron.
  action,

  /// A value that follows another setting: plain text at full contrast.
  value,

  /// On or off: the whole row is one switch.
  toggle,
}

/// One setting (DESIGN.md, MxSettingsRow): a lead `MxIconTile` (40) in
/// [iconTone], the label, an optional subtitle that says why, and its end
/// mark. The label wraps beside the end mark at any text scale. A disabled
/// row dims its tile, label and chevron, never the subtitle; the toggle draws
/// its own disabled state and is not dimmed again. 48 minimum, 16 across and
/// 12 down; one TalkBack node.
class MxSettingsRow extends StatelessWidget {
  const MxSettingsRow.navigation({
    required this.title,
    required this.icon,
    required VoidCallback this.onTap,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.navigation,
       value = null,
       isOn = false,
       onChanged = null;

  const MxSettingsRow.action({
    required this.title,
    required this.icon,
    required VoidCallback this.onTap,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.action,
       value = null,
       isOn = false,
       onChanged = null;

  const MxSettingsRow.value({
    required this.title,
    required this.icon,
    required String this.value,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    super.key,
  }) : kind = MxSettingsRowKind.value,
       onTap = null,
       isOn = false,
       onChanged = null,
       isEnabled = true;

  const MxSettingsRow.toggle({
    required this.title,
    required this.icon,
    required this.isOn,
    required this.onChanged,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.toggle,
       value = null,
       onTap = null;

  final MxSettingsRowKind kind;
  final String title;
  final String? subtitle;
  final IconData icon;
  final MxIconTileTone iconTone;
  final String? value;
  final VoidCallback? onTap;
  final bool isOn;
  final ValueChanged<bool>? onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final double emphasis = isEnabled ? 1 : AppOpacity.disabled;
    final VoidCallback? tap = _tap();
    final String? why = subtitle;
    final bool isToggle = kind == MxSettingsRowKind.toggle;
    final Widget facts = Row(
      children: [
        Opacity(
          opacity: emphasis,
          child: MxIconTile(icon: icon, tone: iconTone),
        ),
        const SizedBox(width: AppSpacing.grouped),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: emphasis,
                child: Text(
                  title,
                  style: mxRowTitleStyle(context.texts, colors),
                ),
              ),
              if (why != null)
                Text(
                  why,
                  style: context.texts.bodyMedium?.apply(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ..._end(context, emphasis),
      ],
    );
    final Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: facts,
      ),
    );
    final Widget pressable = tap == null
        ? body
        : MxFocusRing(
            borderRadius: BorderRadius.zero,
            child: MxRowInk(onTap: tap, child: body),
          );
    // One TalkBack node: a button, or the switch itself for a toggle row.
    return MergeSemantics(
      child: Semantics(
        button: tap != null && !isToggle,
        toggled: isToggle ? isOn : null,
        enabled: isEnabled,
        child: pressable,
      ),
    );
  }

  VoidCallback? _tap() {
    if (!isEnabled) {
      return null;
    }
    final ValueChanged<bool>? change = onChanged;
    if (kind == MxSettingsRowKind.toggle && change != null) {
      return () => change(!isOn);
    }
    return onTap;
  }

  List<Widget> _end(BuildContext context, double emphasis) {
    final ColorScheme colors = context.colors;
    final String? shown = value;
    return switch (kind) {
      MxSettingsRowKind.action => const <Widget>[],
      MxSettingsRowKind.navigation => [
        const SizedBox(width: AppSpacing.grouped),
        Opacity(
          opacity: emphasis,
          child: ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: AppIconSize.large,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
      MxSettingsRowKind.value => [
        const SizedBox(width: AppSpacing.grouped),
        Text(
          shown ?? '',
          style: context.texts.bodyMedium?.apply(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
      // The row is the switch: the toggle only draws, so it is one focus
      // stop and one TalkBack node with the row.
      MxSettingsRowKind.toggle => [
        const SizedBox(width: AppSpacing.grouped),
        ExcludeFocus(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: MxToggle(
                isOn: isOn,
                onChanged: isEnabled ? onChanged : null,
              ),
            ),
          ),
        ),
      ],
    };
  }
}
```

`lib/shared/widgets/mx_action_sheet_command_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One command in an action sheet (DESIGN.md, MxActionSheetCommandRow): a 24
/// glyph in `on-surface-variant` (Material 3's menu leading icon, not a
/// tile), the label in Body Large and an optional subtitle; a destructive
/// command paints its glyph and label in `error` (4.5:1 on the sheet ground)
/// and its words say so too. 48 minimum, 16 across and 12 down; a button.
class MxActionSheetCommandRow extends StatelessWidget {
  const MxActionSheetCommandRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final paint = mxCommandRowColors(colors, isDestructive: isDestructive);
    final String? detail = subtitle;
    // One TalkBack node, a button, carrying the ripple's tap and focus.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: MxFocusRing(
          borderRadius: BorderRadius.zero,
          child: MxRowInk(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.grouped,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: AppIconSize.large,
                        color: paint.glyph,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: mxRowTitleStyle(
                              context.texts,
                              colors,
                            )?.apply(color: paint.label),
                          ),
                          if (detail != null)
                            Text(
                              detail,
                              style: context.texts.bodyMedium?.apply(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_list_section_header_test.dart test/shared/widgets/mx_settings_row_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_rows_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children,
  ),
);

/// The command rows sit on the sheet ground, as they do in a sheet.
class _OnSheet extends StatelessWidget {
  const _OnSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: child,
  );
}

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('list_row', 'forms'): () => _column([
      const MxListRow(title: 'Spanish'),
      MxListRow(
        title: 'Japanese kana',
        subtitle: '46 cards · reviewed today',
        icon: Icons.style,
        trailing: const MxListRowTrailing.chevron(),
        onTap: () {},
      ),
      MxListRow(
        title: 'hola',
        subtitle: 'hello',
        isChecked: true,
        onTap: () {},
      ),
      const MxListRow(
        title: 'French verbs',
        subtitle: 'Was in Library › Languages › French, removed on Monday',
        icon: Icons.delete_outline,
        iconTone: MxIconTileTone.warning,
        trailing: MxListRowTrailing.badge('3 days left', MxBadgeTone.warning),
      ),
      const MxListRow(
        title: 'Total cards',
        trailing: MxListRowTrailing.value('1,204'),
      ),
      MxListRow(
        title: 'verbs',
        subtitle: '120 cards',
        onTap: () {},
        trailing: MxListRowTrailing.iconButton(
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: 'More for verbs',
            onPressed: () {},
          ),
        ),
      ),
      MxListRow(
        title: 'Sync history',
        subtitle: 'Available when you are online',
        icon: Icons.cloud_outlined,
        trailing: const MxListRowTrailing.chevron(),
        onTap: () {},
        isEnabled: false,
      ),
    ]),
    ('list_section_header', 'forms'): () => _column([
      const MxListSectionHeader(title: 'Recent'),
      MxListSectionHeader(
        title: 'Cards',
        trigger: MxChipTrigger(label: 'Newest first', onOpen: () {}),
      ),
    ]),
    ('settings_row', 'kinds'): () => _column([
      MxSettingsRow.navigation(
        title: 'Account',
        subtitle: 'Signed in',
        icon: Icons.person_outline,
        onTap: () {},
      ),
      MxSettingsRow.action(
        title: 'Export cards',
        icon: Icons.upload_outlined,
        onTap: () {},
      ),
      const MxSettingsRow.value(
        title: 'Review order',
        icon: Icons.sort,
        value: 'Due first',
      ),
      MxSettingsRow.toggle(
        title: 'Daily reminder',
        subtitle: 'At 20:00',
        icon: Icons.notifications_none,
        isOn: true,
        onChanged: (_) {},
      ),
      MxSettingsRow.toggle(
        title: 'Sync over mobile data',
        subtitle: 'Available when you are online',
        icon: Icons.sync,
        isOn: false,
        onChanged: (_) {},
        isEnabled: false,
      ),
    ]),
    ('action_sheet_command_row', 'forms'): () => _column([
      _OnSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MxActionSheetCommandRow(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: Icons.tune,
              label: 'Study options',
              subtitle: 'Cards per session · new-card order',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: Icons.delete_forever_outlined,
              label: 'Delete forever',
              subtitle: 'Cannot be undone · history lost',
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
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

Run (Linux container): `flutter test --update-goldens --tags golden test/shared/widgets/mx_rows_golden_test.dart`
Expected: it writes `mx_list_row__forms__*`, `mx_list_section_header__forms__*`, `mx_settings_row__kinds__*` and `mx_action_sheet_command_row__forms__*` (light and dark). Open each one, light and dark, before the commit: nothing clipped, nothing overflowing, the rules of the contracts below visible.

- [ ] **Catalog**

Set the `Status` cell of `MxListRow`, `MxListSectionHeader`, `MxSettingsRow`, `MxActionSheetCommandRow` to `built` (Task 1 already corrected their Consumers). Append these contracts at the end of `### Contracts`, before `## Do's and Don'ts`:

```markdown
#### MxListRow
- Variants: leading none, an `MxIconTile` (medium, 40, in `iconTone`) or an `MxSelectionCheckbox`; a title and an optional subtitle; trailing exactly one of none, chevron, `MxBadge`, a value, or one `MxIconButton`
- States: tappable or inert; disabled; checked while selecting
- Accessibility: 48 minimum, 16 across and 12 down, the leading mark 12 from the text; the title keeps one line with an ellipsis and is read whole; the subtitle wraps to two lines; a tappable row is one button with the shared ripple and the keyboard ring; an inert row stays at full contrast; disabled dims the leading mark, title and chevron (`AppOpacity.disabled`), never the subtitle that says why; one TalkBack node carrying every fact; a trailing icon button is its own node and focus stop; the chevron mirrors in right-to-left text
- Tokens: `on-surface` (title, row tracking), `on-surface-variant` (subtitle, value, chevron); `bodyLarge`, `bodyMedium`; `AppSize.tapTarget`; `AppSpacing.gutter`, `AppSpacing.grouped`
- Golden: forms__light, forms__dark


#### MxListSectionHeader
- Variants: a title alone, or with a trailing `MxChipTrigger` (sort or filter)
- States: one
- Accessibility: the overline over a list (`MxSection` heads a card); the Section Label upper-cased by the widget, so it takes the app's own words, never user data; a header; 16 across and 8 down alone, at least 48 tall with a trigger
- Tokens: `labelMedium` (Section Label) in `on-surface-variant`; `AppSize.tapTarget`
- Golden: forms__light, forms__dark


#### MxSettingsRow
- Variants: navigation (chevron), action (no chevron), value (plain text that follows another setting), toggle (the whole row is the switch); a lead `MxIconTile` in `iconTone` (tinted by default) and an optional subtitle
- States: enabled, disabled; toggle on and off
- Accessibility: 48 minimum, 16 across and 12 down; the label wraps beside its end mark at any text scale; disabled dims the tile, label and chevron, never the subtitle that says why, and the toggle draws its own disabled state, not dimmed again; one TalkBack node: a button, or the switch for a toggle row
- Tokens: `on-surface`, `on-surface-variant`; `bodyLarge`, `bodyMedium`; `AppOpacity.disabled`; through `MxIconTile` and `MxToggle`
- Golden: kinds__light, kinds__dark


#### MxActionSheetCommandRow
- Variants: a glyph, a label and an optional subtitle; `isDestructive`
- States: one
- Accessibility: a 24 glyph in `on-surface-variant` (Material 3's menu leading icon, not a tile); a destructive command paints its glyph and label in `error` (4.5:1 on the sheet ground, declared) and its words say so; 48 minimum, 16 across and 12 down; one TalkBack node, a button
- Tokens: `on-surface`, `on-surface-variant`, `error`; `bodyLarge`, `bodyMedium`; `AppIconSize.large`
- Golden: forms__light, forms__dark
```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (a `built` component needs its source, its widget test and every golden it lists).

- [ ] **Verify**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/dod.log 2>&1; tail -3 /tmp/dod.log`
Expected: `✓ mechanical gates passed`.

Run (Linux container): `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: every golden matches.

- [ ] **Commit**

```bash
git add lib/shared/widgets/mx_list_row.dart lib/shared/widgets/mx_list_section_header.dart lib/shared/widgets/mx_settings_row.dart lib/shared/widgets/mx_action_sheet_command_row.dart test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_list_section_header_test.dart test/shared/widgets/mx_settings_row_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart test/shared/widgets/mx_rows_golden_test.dart test/shared/widgets/goldens DESIGN.md
git commit -m "feat(sp3a-p4): MxListRow, MxListSectionHeader, MxSettingsRow and MxActionSheetCommandRow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```


---

### Task 3: Screen chrome — MxAppBar, MxBreadcrumb, MxFooterBar, MxScreenScaffold, MxScreenScroll

**Files:**
- Create: `lib/shared/widgets/mx_app_bar.dart`
- Create: `lib/shared/widgets/mx_breadcrumb.dart`
- Create: `lib/shared/widgets/mx_footer_bar.dart`
- Create: `lib/shared/widgets/mx_screen_scaffold.dart`
- Create: `lib/shared/widgets/mx_screen_scroll.dart`
- Test: `test/shared/widgets/mx_app_bar_test.dart`
- Test: `test/shared/widgets/mx_breadcrumb_test.dart`
- Test: `test/shared/widgets/mx_footer_bar_test.dart`
- Test: `test/shared/widgets/mx_screen_scaffold_test.dart`
- Test: `test/shared/widgets/mx_screen_scroll_test.dart`
- Golden: `test/shared/widgets/mx_chrome_golden_test.dart`
- Golden: `test/shared/widgets/mx_frame_golden_test.dart`
- Modify: `DESIGN.md` (catalog status and contracts)

**Interfaces:**
- Consumes: `mxAppBarGround`, `mxAppBarTitleStyle`, `AppSize.appBar` (Task 1); `MxListRow` (Task 2, in the frame golden); `MxCard`, `MxSheetActions` (Phase 3); `MxFab`, `MxIconButton`, `MxButton`, `MxRowInk`, `MxFocusRing` (Phase 2). The five ship together: the scaffold takes the bar, the breadcrumb and the footer by type, and the bar's scrolled-under test needs the scaffold and the scroll under it.
- Produces: `MxAppBar` (a `PreferredSizeWidget`), `MxAppBarLeading`, `MxAppBarTextAction`, `MxAppBarDensity` (re-exported); `MxBreadcrumb`, `MxBreadcrumbItem`; `MxFooterBar`; `MxScreenScaffold`, `MxScreenScaffoldScope.hasFabOf`; `MxScreenScroll` and `MxScreenScroll.builder`.

- [ ] **Step 1: The failing tests**

Create `test/shared/widgets/mx_app_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import 'support/mx_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  MxAppBar bar, {
  ThemeData? theme,
  Size size = const Size(400, 800),
  TextDirection direction = TextDirection.ltr,
  Widget? body,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? mxThemes['light'],
      home: Directionality(
        textDirection: direction,
        child: MxScreenScaffold(
          appBar: bar,
          body:
              body ??
              MxScreenScroll(
                children: [
                  for (var i = 0; i < 40; i++)
                    const SizedBox(height: 56, child: Text('Row')),
                ],
              ),
        ),
      ),
    ),
  );
}

Color _ground(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(
            of: find.byType(MxAppBar),
            matching: find.byType(Material),
          )
          .first,
    )
    .color!;

MxIconButton _icon(IconData icon) => MxIconButton(
  icon: icon,
  semanticLabel: icon.codePoint.toString(),
  onPressed: () {},
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets(
      '$name: flat surface at rest, one tonal step when scrolled under',
      (tester) async {
        await _pump(tester, const MxAppBar(title: 'Library'), theme: theme);
        expect(tester.getSize(find.byType(MxAppBar)).height, AppSize.appBar);
        expect(_ground(tester), s.surface);
        await tester.drag(find.byType(Scrollable), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(_ground(tester), s.surfaceContainer);
      },
    );
  }

  testWidgets('with no leading control the title starts on the gutter', (
    tester,
  ) async {
    await _pump(tester, const MxAppBar(title: 'Study'));
    expect(tester.getRect(find.text('Study')).left, 16);
  });

  testWidgets('after back the title starts 8 past its 48 target', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Edit card', leading: MxAppBarLeading.back),
    );
    expect(tester.getRect(find.text('Edit card')).left, 4 + 48 + 8);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).semanticLabel,
      'Back',
    );
  });

  testWidgets('on a wide window its content keeps to the column', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Study'),
      size: const Size(1000, 800),
    );
    expect(tester.getSize(find.byType(MxAppBar)).width, 1000);
    expect(
      tester.getRect(find.text('Study')).left,
      (1000 - AppBreakpoints.contentMax) / 2 + 16,
    );
  });

  testWidgets('close runs the caller instead of popping', (tester) async {
    var closed = 0;
    await _pump(
      tester,
      MxAppBar(
        title: '3 selected',
        leading: MxAppBarLeading.close,
        onLeading: () => closed++,
        isTitleLive: true,
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
  });

  testWidgets('the title is a header; a live one announces its change', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const MxAppBar(
        title: '3 selected',
        leading: MxAppBarLeading.close,
        isTitleLive: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('3 selected')),
      isSemantics(isHeader: true, isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('screen density uses the Title role, content Body Large', (
    tester,
  ) async {
    await _pump(tester, const MxAppBar(title: 'Library'));
    final TextTheme texts = mxThemes['light']!.textTheme;
    Text title() => tester.widget<Text>(find.text('Library'));
    expect(title().style?.fontSize, texts.titleLarge?.fontSize);
    await _pump(
      tester,
      const MxAppBar(title: 'Library', density: MxAppBarDensity.content),
    );
    expect(title().style?.fontSize, texts.titleMedium?.fontSize);
  });

  testWidgets('a long title keeps one line and the actions keep their place', (
    tester,
  ) async {
    await _pump(
      tester,
      MxAppBar(
        title: 'Irregular verbs of the past tense, chapter twelve',
        leading: MxAppBarLeading.back,
        actions: [
          _icon(Icons.search),
          _icon(Icons.tag),
          _icon(Icons.more_vert),
        ],
      ),
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.textContaining('Irregular')).maxLines, 1);
    expect(
      tester.getRect(find.byIcon(Icons.more_vert)).right,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('a fourth icon action is refused', (tester) async {
    await _pump(
      tester,
      MxAppBar(
        title: 'Deck',
        actions: [
          _icon(Icons.search),
          _icon(Icons.tag),
          _icon(Icons.delete),
          _icon(Icons.more_vert),
        ],
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('one text action, in the text tone', (tester) async {
    var selected = 0;
    await _pump(
      tester,
      MxAppBar(
        title: 'Trash',
        textAction: MxAppBarTextAction(
          label: 'Select',
          onPressed: () => selected++,
        ),
      ),
    );
    await tester.tap(find.text('Select'));
    expect(selected, 1);
    expect(
      tester.getRect(find.text('Select')).right,
      lessThanOrEqualTo(400 - 4),
    );
  });

  testWidgets('in right-to-left text back leads from the right', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Edit card', leading: MxAppBarLeading.back),
      direction: TextDirection.rtl,
    );
    expect(tester.getRect(find.byType(MxIconButton)).right, 400 - 4);
  });
}
```

Create `test/shared/widgets/mx_breadcrumb_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/mx_harness.dart';

MxBreadcrumb _path(VoidCallback onLibrary) => MxBreadcrumb(
  items: [
    MxBreadcrumbItem(label: 'Library', onTap: onLibrary),
    const MxBreadcrumbItem(label: 'Spanish'),
    const MxBreadcrumbItem(label: 'New card'),
  ],
);

void main() {
  testWidgets('an ancestor is a 48 target that goes there', (tester) async {
    var went = 0;
    await pumpMx(tester, SizedBox(width: 380, child: _path(() => went++)));
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Library'),
              matching: find.byType(InkWell),
            ),
          )
          .height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    await tester.tap(find.text('Library'));
    expect(went, 1);
  });

  testWidgets('TalkBack hears ancestors as buttons and the current place', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(tester, SizedBox(width: 380, child: _path(() {})));
    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isButton: true),
    );
    expect(
      tester.getSemantics(find.text('New card')),
      isSemantics(label: 'New card', isSelected: true, isButton: false),
    );
    semantics.dispose();
  });

  testWidgets('on a phone the current place stays whole', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String long = 'Irregular verbs of the past tense';
    await pumpMx(
      tester,
      SizedBox(
        width: 412,
        child: MxBreadcrumb(
          items: [
            MxBreadcrumbItem(label: 'Library', onTap: () {}),
            MxBreadcrumbItem(label: 'Spanish for travellers', onTap: () {}),
            const MxBreadcrumbItem(label: long),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject<RenderParagraph>(find.text(long)).didExceedMaxLines,
      isFalse,
    );
    expect(
      tester.getSemantics(find.text('Spanish for travellers')),
      isSemantics(label: 'Spanish for travellers'),
    );
    semantics.dispose();
  });

  testWidgets('in right-to-left text the path runs from the right', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 380, child: _path(() {})),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getRect(find.text('Library')).left,
      greaterThan(tester.getRect(find.text('New card')).left),
    );
  });
}
```

Create `test/shared/widgets/mx_footer_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

const Key _actions = ValueKey<String>('actions');

MxFooterBar _footer() => MxFooterBar(
  caption: 'Saved on this phone',
  actions: MxSheetActions(
    key: _actions,
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: 'Save card',
    onConfirm: () {},
  ),
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets('$name: the page ground under an outline-variant hairline', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(width: 400, child: _footer()),
        theme: theme,
      );
      final BoxDecoration box =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(MxFooterBar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(box.color, s.surface);
      expect(box.boxShadow, isNull);
      expect(
        (box.border! as Border).top,
        BorderSide(color: s.outlineVariant, width: AppStroke.hairline),
      );
      expect(
        tester.widget<Text>(find.text('Saved on this phone')).style?.color,
        s.onSurfaceVariant,
      );
    });
  }

  testWidgets('16 across, 12 down, the caption 8 above the actions', (
    tester,
  ) async {
    await pumpMx(tester, SizedBox(width: 400, child: _footer()));
    final Rect bar = tester.getRect(find.byType(MxFooterBar));
    final Rect caption = tester.getRect(find.text('Saved on this phone'));
    final Rect actions = tester.getRect(find.byKey(_actions));
    expect(caption.left - bar.left, 16);
    expect(caption.top - bar.top, 12);
    expect(actions.top - caption.bottom, 8);
    expect(bar.bottom - actions.bottom, 12);
  });

  testWidgets('on a wide window its content keeps to the column', (
    tester,
  ) async {
    await pumpMx(tester, SizedBox(width: 1000, child: _footer()));
    expect(
      tester.getSize(find.byKey(_actions)).width,
      AppBreakpoints.contentMax - 32,
    );
  });
}
```

Create `test/shared/widgets/mx_screen_scaffold_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';

import 'support/mx_harness.dart';

const Key _body = ValueKey<String>('body');

MxScreenScaffold _screen({bool hasFooter = false, bool hasFab = false}) =>
    MxScreenScaffold(
      appBar: const MxAppBar(title: 'Spanish'),
      breadcrumb: const MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library'),
          MxBreadcrumbItem(label: 'Spanish'),
        ],
      ),
      body: const SizedBox.expand(key: _body),
      footer: hasFooter
          ? const MxFooterBar(caption: 'Saved on this phone')
          : null,
      fab: hasFab
          ? MxFab(icon: Icons.add, semanticLabel: 'New card', onPressed: () {})
          : null,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(400, 800),
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: mxThemes['light'],
      home: Directionality(textDirection: direction, child: screen),
    ),
  );
}

void main() {
  testWidgets('bar, pinned breadcrumb, body, then the footer', (tester) async {
    await _pump(tester, _screen(hasFooter: true));
    final double bar = tester.getRect(find.byType(MxAppBar)).bottom;
    final Rect path = tester.getRect(find.byType(MxBreadcrumb));
    final Rect body = tester.getRect(find.byKey(_body));
    final Rect footer = tester.getRect(find.byType(MxFooterBar));
    expect(path.top, greaterThanOrEqualTo(bar));
    expect(body.top, greaterThanOrEqualTo(path.bottom));
    expect(footer.top, greaterThanOrEqualTo(body.bottom));
    expect(footer.bottom, 800);
  });

  testWidgets('on a wide window the body keeps to the 720 column', (
    tester,
  ) async {
    await _pump(tester, _screen(), size: const Size(1000, 800));
    final Rect body = tester.getRect(find.byKey(_body));
    expect(body.width, AppBreakpoints.contentMax);
    expect(body.left, (1000 - AppBreakpoints.contentMax) / 2);
  });

  testWidgets('the FAB sits 16 inside the column, above the footer', (
    tester,
  ) async {
    await _pump(
      tester,
      _screen(hasFooter: true, hasFab: true),
      size: const Size(1000, 800),
    );
    final Rect fab = tester.getRect(find.byType(MxFab));
    final Rect footer = tester.getRect(find.byType(MxFooterBar));
    final double columnEnd = (1000 + AppBreakpoints.contentMax) / 2;
    expect(fab.right, columnEnd - 16);
    expect(fab.bottom, footer.top - 16);
  });

  testWidgets('in right-to-left text the FAB moves to the start edge', (
    tester,
  ) async {
    await _pump(tester, _screen(hasFab: true), direction: TextDirection.rtl);
    expect(tester.getRect(find.byType(MxFab)).left, 16);
  });

  testWidgets('the FAB clears the system bar when no footer holds it', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    await _pump(tester, _screen(hasFab: true));
    expect(tester.getRect(find.byType(MxFab)).bottom, 800 - 48 - 16);
  });

  testWidgets('the footer rides above the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pump(tester, _screen(hasFooter: true));
    expect(
      tester.getRect(find.byType(MxFooterBar)).bottom,
      lessThanOrEqualTo(800 - 300),
    );
  });

  testWidgets('the footer clears the navigation bar on its own ground', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    await _pump(tester, _screen(hasFooter: true));
    expect(tester.getRect(find.byType(MxFooterBar)).bottom, 800);
    expect(
      tester.getRect(find.text('Saved on this phone')).bottom,
      lessThanOrEqualTo(800 - 48),
    );
  });

  testWidgets('with the keyboard up the footer sits on it, not on the bar', (
    tester,
  ) async {
    // The platform zeroes the bottom padding while the keyboard covers the
    // system bar; the view padding still names the bar.
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pump(tester, _screen(hasFooter: true));
    expect(tester.getRect(find.byType(MxFooterBar)).bottom, 800 - 300);
  });
}
```

Create `test/shared/widgets/mx_screen_scroll_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import 'support/mx_harness.dart';

const Key _last = ValueKey<String>('last');

Widget _rows() => MxScreenScroll(
  children: [
    for (var i = 0; i < 30; i++) const SizedBox(height: 56, child: Text('Row')),
    const SizedBox(key: _last, height: 56),
  ],
);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: mxThemes['light'], home: screen));
}

Future<void> _toEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a 16 gutter on both sides', (tester) async {
    await _pump(tester, MxScreenScaffold(body: _rows()));
    final Rect row = tester.getRect(find.text('Row').first);
    expect(row.left, AppSpacing.gutter);
    expect(
      tester
          .getRect(
            find
                .ancestor(
                  of: find.text('Row').first,
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .right,
      400 - AppSpacing.gutter,
    );
  });

  testWidgets('a 48 tail under pinned chrome', (tester) async {
    await _pump(tester, MxScreenScaffold(body: _rows()));
    await _toEnd(tester);
    expect(tester.getRect(find.byKey(_last)).bottom, 800 - AppSpacing.pageEnd);
  });

  testWidgets('the last item ends clear of a FAB', (tester) async {
    await _pump(
      tester,
      MxScreenScaffold(
        body: _rows(),
        fab: MxFab(icon: Icons.add, semanticLabel: 'New', onPressed: () {}),
      ),
    );
    await _toEnd(tester);
    expect(
      tester.getRect(find.byKey(_last)).bottom,
      tester.getRect(find.byType(MxFab)).top - AppSpacing.gutter,
    );
  });

  testWidgets('a long list builds as it scrolls in', (tester) async {
    await _pump(
      tester,
      MxScreenScaffold(
        body: MxScreenScroll.builder(
          itemCount: 1000,
          itemBuilder: (_, index) =>
              SizedBox(height: 56, child: Text('$index')),
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('999'), findsNothing);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_screen_scaffold_test.dart test/shared/widgets/mx_screen_scroll_test.dart`
Expected: compile failure — the widgets do not exist yet.

- [ ] **Step 2: The widgets**

`lib/shared/widgets/mx_app_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

export 'package:memox/core/theme/components/chrome_style.dart'
    show MxAppBarDensity;

/// What sits before the title: nothing (the title starts on the gutter, in
/// line with the body), back, or close (a task or a selection to leave).
enum MxAppBarLeading { none, back, close }

/// The bar's one text action ("Select", "Edit"): the text tone, never a
/// primary fill (a form's save lives in its footer).
class MxAppBarTextAction {
  const MxAppBarTextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

/// The most icon actions a bar carries: with a leading control on a 360
/// phone the title keeps a readable share.
const int _maxIconActions = 3;

/// The top bar (DESIGN.md, MxAppBar): 56 tall, flat `surface` that steps to
/// `surface-container` once content scrolls under it; a leading control, a
/// one-line title, and up to three icon actions or one text action. Its
/// content keeps to the 720 column while its ground spans the window.
///
/// Selecting is not a mode of the bar: the caller passes `close` and the
/// count as the title ("3 selected"), and [isTitleLive] so TalkBack hears the
/// count change.
class MxAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MxAppBar({
    required this.title,
    this.density = MxAppBarDensity.screen,
    this.leading = MxAppBarLeading.none,
    this.onLeading,
    this.actions = const <MxIconButton>[],
    this.textAction,
    this.isTitleLive = false,
    super.key,
  });

  final String title;
  final MxAppBarDensity density;
  final MxAppBarLeading leading;

  /// Runs instead of the default, which pops through `Navigator.maybePop` so
  /// a caller's `PopScope` (and predictive back) still decides.
  final VoidCallback? onLeading;

  /// At most three; none when [textAction] is set.
  final List<MxIconButton> actions;
  final MxAppBarTextAction? textAction;
  final bool isTitleLive;

  @override
  Size get preferredSize => const Size.fromHeight(AppSize.appBar);

  @override
  State<MxAppBar> createState() => _MxAppBarState();
}

class _MxAppBarState extends State<MxAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _isScrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  // The screen's own vertical scroll only, as Material's AppBar reads it.
  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) {
      return;
    }
    if (!defaultScrollNotificationPredicate(notification)) {
      return;
    }
    if (axisDirectionToAxis(notification.metrics.axisDirection) !=
        Axis.vertical) {
      return;
    }
    final bool isUnder = notification.metrics.extentBefore > 0;
    if (isUnder == _isScrolledUnder) {
      return;
    }
    setState(() => _isScrolledUnder = isUnder);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.actions.length <= _maxIconActions,
      'MxAppBar carries at most $_maxIconActions icon actions.',
    );
    assert(
      widget.textAction == null || widget.actions.isEmpty,
      'MxAppBar carries icon actions or one text action, not both.',
    );
    final ColorScheme colors = context.colors;
    return Material(
      color: mxAppBarGround(colors, isScrolledUnder: _isScrolledUnder),
      child: SafeArea(
        bottom: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMax,
              minHeight: AppSize.appBar,
            ),
            child: Row(
              children: [
                _leading(context),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: widget.isTitleLive,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mxAppBarTitleStyle(
                        context.texts,
                        colors,
                        widget.density,
                      ),
                    ),
                  ),
                ),
                ..._trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The title starts on the gutter; after a leading control it starts 8
  // past that control's 48 target, which sits 4 from the edge.
  Widget _leading(BuildContext context) {
    if (widget.leading == MxAppBarLeading.none) {
      return const SizedBox(width: AppSpacing.gutter);
    }
    final MaterialLocalizations words = MaterialLocalizations.of(context);
    final bool isBack = widget.leading == MxAppBarLeading.back;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.micro,
        end: AppSpacing.control,
      ),
      child: MxIconButton(
        icon: isBack ? Icons.arrow_back : Icons.close,
        semanticLabel: isBack
            ? words.backButtonTooltip
            : words.closeButtonTooltip,
        onPressed: widget.onLeading ?? () => Navigator.maybePop(context),
      ),
    );
  }

  List<Widget> _trailing() {
    final MxAppBarTextAction? text = widget.textAction;
    if (text != null) {
      return [
        MxButton(
          label: text.label,
          onPressed: text.onPressed,
          tone: MxButtonTone.text,
          size: MxButtonSize.small,
        ),
        const SizedBox(width: AppSpacing.micro),
      ];
    }
    if (widget.actions.isEmpty) {
      return const [SizedBox(width: AppSpacing.gutter)];
    }
    return [...widget.actions, const SizedBox(width: AppSpacing.micro)];
  }
}
```

`lib/shared/widgets/mx_breadcrumb.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One place on a path: its label and, for a place one can go back to, what
/// going there does.
class MxBreadcrumbItem {
  const MxBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// A path of places (DESIGN.md, MxBreadcrumb), presentation-neutral: it knows
/// no deck, ancestor or route. The last item is where the reader is; the ones
/// before it are ancestors, each a 48 target when it can be tapped. One line:
/// when the path does not fit, the current place keeps its full width and
/// the ancestors share what is left, each cut with an ellipsis but read whole
/// by TalkBack. The separator mirrors in right-to-left text.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({required this.items, super.key});

  /// At least one; the last is the current place.
  final List<MxBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'MxBreadcrumb needs at least one item.');
    final TextStyle? style = context.texts.bodyMedium;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    return Padding(
      // The labels line up with the body's gutter; the ripple reaches past them.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter - AppSpacing.micro,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final List<double> natural = [
            for (final item in items)
              _labelWidth(item.label, style, scaler, direction) +
                  2 * AppSpacing.micro,
          ];
          final double separators =
              (items.length - 1) * (AppIconSize.small + 2 * AppSpacing.micro);
          final List<double> widths = _share(
            natural,
            math.max(0, box.maxWidth - separators),
          );
          final int last = items.length - 1;
          return Row(
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0) const _Separator(),
                SizedBox(
                  width: widths[index],
                  child: _Place(item: item, isCurrent: index == last),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static double _labelWidth(
    String label,
    TextStyle? style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textScaler: scaler,
      textDirection: direction,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  /// The current place (last) takes its natural width while at least a 48
  /// target is left for each ancestor; the ancestors then share the rest,
  /// a short one keeping its natural width and giving the remainder on.
  static List<double> _share(List<double> natural, double room) {
    final int last = natural.length - 1;
    final double floor = last * AppSize.tapTarget;
    final double current = math.min(natural[last], math.max(0, room - floor));
    final List<double> widths = List<double>.filled(natural.length, 0);
    widths[last] = current;
    double left = room - current;
    final List<int> open = [for (var i = 0; i < last; i++) i]
      ..sort((a, b) => natural[a].compareTo(natural[b]));
    for (final (rank, index) in open.indexed) {
      final double fair = left / (open.length - rank);
      final double take = math.min(natural[index], fair);
      widths[index] = take;
      left -= take;
    }
    return widths;
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
      child: ExcludeSemantics(
        child: Icon(
          Icons.chevron_right,
          size: AppIconSize.small,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.item, required this.isCurrent});

  final MxBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final VoidCallback? tap = isCurrent ? null : item.onTap;
    final Widget label = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodyMedium?.apply(
              color: isCurrent ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    final Widget read = Semantics(
      label: item.label,
      selected: isCurrent,
      button: tap != null,
      excludeSemantics: true,
      child: label,
    );
    if (tap == null) {
      return read;
    }
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);
    return MxFocusRing(
      borderRadius: radius,
      child: MxRowInk(onTap: tap, borderRadius: radius, child: read),
    );
  }
}
```

`lib/shared/widgets/mx_footer_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The in-flow commit bar under a screen's body (DESIGN.md, MxFooterBar):
/// the page ground under a 1dp `outline-variant` hairline (no shadow), 16
/// across and 12 down, an optional caption in `on-surface-variant` 8 above
/// the actions. It clears the system bar and rides above the keyboard with
/// the screen. The actions are a slot: `MxSheetActions` today, the footer
/// pair (`MxActionPair`) once it is built.
class MxFooterBar extends StatelessWidget {
  const MxFooterBar({this.caption, this.actions, super.key})
    : assert(caption != null || actions != null, 'An empty footer.');

  final String? caption;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final String? words = caption;
    final Widget? commit = actions;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMax,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.grouped,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.control,
                children: [
                  if (words != null)
                    Text(
                      words,
                      style: context.texts.bodySmall?.apply(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ?commit,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_screen_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// A screen's frame (DESIGN.md, Layout): the top bar, an optional pinned
/// breadcrumb, one body, an optional in-flow footer, and the FAB layered over
/// the body (never over the footer). It knows no tab, route or bottom bar: the
/// navigation shell hands it the room left over as the bottom inset.
///
/// The body, breadcrumb and footer content sit in the column, centred at
/// 720 (The Column Rule); the page ground fills the rest. The body and the
/// footer ride above the keyboard.
class MxScreenScaffold extends StatelessWidget {
  const MxScreenScaffold({
    required this.body,
    this.appBar,
    this.breadcrumb,
    this.footer,
    this.fab,
    super.key,
  });

  final MxAppBar? appBar;

  /// Pinned under the bar, outside the scroll.
  final MxBreadcrumb? breadcrumb;

  /// Any body: an `MxScreenScroll`, an `MxEmptyState`, a centred form.
  final Widget body;

  final MxFooterBar? footer;

  /// The caller passes `null` while its own state hides the FAB (selecting,
  /// searching); the scroll body's tail follows.
  final MxFab? fab;

  @override
  Widget build(BuildContext context) {
    final MxBreadcrumb? path = breadcrumb;
    final MxFooterBar? commit = footer;
    final MxFab? action = fab;
    Widget region = MxScreenScaffoldScope(hasFab: action != null, child: body);
    if (action != null) {
      region = Stack(
        children: [
          Positioned.fill(child: region),
          PositionedDirectional(
            end: AppSpacing.gutter,
            bottom: AppSpacing.gutter + MediaQuery.paddingOf(context).bottom,
            child: action,
          ),
        ],
      );
    }
    // The footer clears the system bar itself; the body above it does not.
    if (commit != null) {
      region = MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: region,
      );
    }
    return Scaffold(
      appBar: appBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null) _InColumn(child: path),
          Expanded(child: _InColumn(child: region)),
          ?commit,
        ],
      ),
    );
  }
}

/// Centres its child in the 720 content column.
class _InColumn extends StatelessWidget {
  const _InColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMax),
        child: child,
      ),
    );
  }
}

/// Tells the screen's scroll body whether a FAB floats over it, so its tail
/// clears the FAB (The Clear Tail Rule).
class MxScreenScaffoldScope extends InheritedWidget {
  const MxScreenScaffoldScope({
    required this.hasFab,
    required super.child,
    super.key,
  });

  final bool hasFab;

  /// `false` outside a scaffold.
  static bool hasFabOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MxScreenScaffoldScope>()
          ?.hasFab ??
      false;

  @override
  bool updateShouldNotify(MxScreenScaffoldScope oldWidget) =>
      hasFab != oldWidget.hasFab;
}
```

`lib/shared/widgets/mx_screen_scroll.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';

/// A screen's one scroll body (DESIGN.md, Layout): the 16 gutter on both
/// sides and a tail, so the last item is never trapped. The tail is 48 under
/// pinned chrome, or clears the FAB (its 52 plus a gutter on each side) while
/// one floats over the body (The Clear Tail Rule), above the system bar.
/// The first item starts flush; the gaps between items are the screen's own.
class MxScreenScroll extends StatelessWidget {
  const MxScreenScroll({required this.children, this.controller, super.key})
    : itemCount = null,
      itemBuilder = null;

  /// A long list, built as it scrolls in.
  const MxScreenScroll.builder({
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.controller,
    super.key,
  }) : children = const <Widget>[];

  final List<Widget> children;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final double tail = MxScreenScaffoldScope.hasFabOf(context)
        ? AppSize.fab + 2 * AppSpacing.gutter
        : AppSpacing.pageEnd;
    // The system insets the scaffold leaves to the body (a cutout, the
    // status bar without a top bar, the system bar without a footer).
    final EdgeInsets system = MediaQuery.paddingOf(context);
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      AppSpacing.gutter + system.left,
      system.top,
      AppSpacing.gutter + system.right,
      tail + system.bottom,
    );
    final IndexedWidgetBuilder? build = itemBuilder;
    final int? count = itemCount;
    if (build != null && count != null) {
      return ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: count,
        itemBuilder: build,
      );
    }
    return ListView(
      controller: controller,
      padding: padding,
      children: children,
    );
  }
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_screen_scaffold_test.dart test/shared/widgets/mx_screen_scroll_test.dart`
Expected: all pass.

- [ ] **Goldens**

Create `test/shared/widgets/mx_chrome_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

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

MxIconButton _icon(IconData icon, String label) =>
    MxIconButton(icon: icon, semanticLabel: label, onPressed: () {});

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('app_bar', 'forms'): () => _column([
      const MxAppBar(title: 'Study'),
      MxAppBar(
        title: 'Spanish',
        leading: MxAppBarLeading.back,
        actions: [
          _icon(Icons.auto_awesome, 'Generate'),
          _icon(Icons.sell_outlined, 'Tags'),
          _icon(Icons.delete_outline, 'Trash'),
        ],
      ),
      const MxAppBar(
        title: 'Edit card',
        density: MxAppBarDensity.content,
        leading: MxAppBarLeading.back,
      ),
      MxAppBar(
        title: 'Trash',
        leading: MxAppBarLeading.back,
        textAction: MxAppBarTextAction(label: 'Select', onPressed: () {}),
      ),
      const MxAppBar(title: '3 selected', leading: MxAppBarLeading.close),
    ]),
    ('breadcrumb', 'forms'): () => _column([
      MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library', onTap: () {}),
          const MxBreadcrumbItem(label: 'Spanish'),
        ],
      ),
      MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library', onTap: () {}),
          MxBreadcrumbItem(label: 'Languages', onTap: () {}),
          MxBreadcrumbItem(label: 'Spanish for travellers', onTap: () {}),
          const MxBreadcrumbItem(label: 'Review algorithm'),
        ],
      ),
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

Create `test/shared/widgets/mx_frame_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

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

MxIconButton _icon(IconData icon, String label) =>
    MxIconButton(icon: icon, semanticLabel: label, onPressed: () {});

Widget _frame(MxScreenScaffold screen) =>
    SizedBox(height: 420, child: ClipRect(child: screen));

const List<String> _decks = [
  'Spanish',
  'Japanese kana',
  'French verbs',
  'Anatomy',
  'Chemistry',
  'Music theory',
];

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('screen_scaffold', 'frames'): () => _column([
      _frame(
        MxScreenScaffold(
          appBar: MxAppBar(
            title: 'Library',
            actions: [
              _icon(Icons.search, 'Search'),
              _icon(Icons.more_vert, 'More'),
            ],
          ),
          body: MxScreenScroll(
            children: [
              MxCard(
                isFullBleed: true,
                child: Column(
                  children: [
                    for (final deck in _decks)
                      MxListRow(
                        title: deck,
                        subtitle: '24 cards',
                        icon: Icons.style,
                        trailing: const MxListRowTrailing.chevron(),
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ],
          ),
          fab: MxFab(
            icon: Icons.add,
            semanticLabel: 'New deck',
            onPressed: () {},
          ),
        ),
      ),
      _frame(
        MxScreenScaffold(
          appBar: const MxAppBar(
            title: 'New card',
            density: MxAppBarDensity.content,
            leading: MxAppBarLeading.close,
          ),
          breadcrumb: MxBreadcrumb(
            items: [
              MxBreadcrumbItem(label: 'Library', onTap: () {}),
              MxBreadcrumbItem(label: 'Spanish', onTap: () {}),
              const MxBreadcrumbItem(label: 'New card'),
            ],
          ),
          body: const MxScreenScroll(children: [SizedBox(height: 120)]),
          footer: MxFooterBar(
            caption: 'Saved on this phone',
            actions: MxSheetActions(
              cancelLabel: 'Cancel',
              onCancel: () {},
              confirmLabel: 'Save card',
              onConfirm: () {},
            ),
          ),
        ),
      ),
    ]),
    ('footer_bar', 'forms'): () => _column([
      const MxFooterBar(caption: 'Read-only · resets change nothing here'),
      MxFooterBar(
        caption: 'Saved on this phone',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Save card',
          onConfirm: () {},
        ),
      ),
      MxFooterBar(
        caption: 'Starting…',
        actions: MxSheetActions(
          confirmLabel: 'Study this deck',
          onConfirm: () {},
          isConfirmLoading: true,
        ),
      ),
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

Run (Linux container): `flutter test --update-goldens --tags golden test/shared/widgets/mx_chrome_golden_test.dart test/shared/widgets/mx_frame_golden_test.dart`
Expected: it writes `mx_app_bar__forms__*`, `mx_breadcrumb__forms__*`, `mx_footer_bar__forms__*` and `mx_screen_scaffold__frames__*` (light and dark). Open each one, light and dark, before the commit: nothing clipped, nothing overflowing, the rules of the contracts below visible.

- [ ] **Catalog**

Set the `Status` cell of `MxAppBar`, `MxBreadcrumb`, `MxFooterBar`, `MxScreenScaffold`, `MxScreenScroll` to `built` (Task 1 already corrected their Consumers). Append these contracts at the end of `### Contracts`, before `## Do's and Don'ts`:

```markdown
#### MxAppBar
- Variants: densities screen (the Title role, -0.5 tracking as a component override) and content (Body Large); leading none (the title starts on the gutter), back or close (the title starts 8 past the control's 48 target); up to three `MxIconButton` actions, or one text action in the text tone (never a primary fill)
- States: flat `surface` at rest; `surface-container` once content scrolls under it (Material 3's scrolled-under container; no shadow, no tint)
- Accessibility: 56 tall; the title keeps one line with an ellipsis and is a header; `isTitleLive` makes a selection count a live region; back and close are named by the platform's words and pop through `Navigator.maybePop` unless the caller runs its own; the ground spans the window, the content keeps to the 720 column
- Tokens: `surface`, `surface-container`, `on-surface`, `on-surface-variant`; `titleLarge`, `titleMedium`; `AppSize.appBar`; the `appBarTheme` slot matches it
- Golden: forms__light, forms__dark


#### MxBreadcrumb
- Variants: items of a label and an optional `onTap`; the last item is the current place
- States: one
- Accessibility: presentation-neutral (knows no deck, ancestor or route); one line; the current place keeps its full width while each ancestor keeps at least a 48 target, the ancestors share the rest and end in an ellipsis; each ancestor that can be tapped is a 48 button with the ripple and the keyboard ring; the current place reads as selected; every label is read whole; the separator mirrors in right-to-left text
- Tokens: `bodyMedium`; `on-surface` (current), `on-surface-variant` (ancestors, separator); `chevron_right` at `AppIconSize.small`
- Golden: forms__light, forms__dark


#### MxFooterBar
- Variants: a caption, actions (a slot: `MxSheetActions` today, `MxActionPair` once built), or both
- States: as its actions (enabled, disabled, loading)
- Accessibility: in flow under the body, the page ground under a 1dp `outline-variant` hairline and no shadow; 16 across, 12 down, the caption 8 above the actions; it clears the system bar and rides above the keyboard; its content keeps to the 720 column
- Tokens: `surface`, `outline-variant`; caption `bodySmall` in `on-surface-variant`
- Golden: forms__light, forms__dark


#### MxScreenScaffold
- Variants: a top bar (optional), a pinned breadcrumb (optional, outside the scroll), one body (any widget), an in-flow footer (optional), a FAB (optional)
- States: with or without a FAB (the caller passes none while its own state hides it), above the keyboard
- Accessibility: knows no tab, route or bottom bar; the shell hands it the room left as the bottom inset; the FAB sits 16 inside the column's end edge (the start edge in right-to-left text) and 16 above the footer or the system bar, never over the footer; the body and the footer ride above the keyboard
- Tokens: `surface` (page ground); `AppBreakpoints.contentMax` (720 column); `AppSpacing.gutter`
- Golden: frames__light, frames__dark


#### MxScreenScroll
- Variants: a list of children, or `builder` for a long list
- States: tail 48 (`pageEnd`) under pinned chrome; with a FAB the tail clears it (the FAB's 52 plus a gutter on each side)
- Accessibility: the gutter and the tail add the system insets the scaffold leaves to the body; the first item starts flush, the gaps between items are the screen's own; rows sit in a full-bleed surface (`MxCard`), not straight on the gutter
- Tokens: `AppSpacing.gutter`, `AppSpacing.pageEnd`, `AppSize.fab`
- Golden: none — seen in `mx_screen_scaffold__frames`

```

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …` (a `built` component needs its source, its widget test and every golden it lists).

- [ ] **Verify**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/dod.log 2>&1; tail -3 /tmp/dod.log`
Expected: `✓ mechanical gates passed`.

Run (Linux container): `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: every golden matches.

- [ ] **Commit**

```bash
git add lib/shared/widgets/mx_app_bar.dart lib/shared/widgets/mx_breadcrumb.dart lib/shared/widgets/mx_footer_bar.dart lib/shared/widgets/mx_screen_scaffold.dart lib/shared/widgets/mx_screen_scroll.dart test/shared/widgets/mx_app_bar_test.dart test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_screen_scaffold_test.dart test/shared/widgets/mx_screen_scroll_test.dart test/shared/widgets/mx_chrome_golden_test.dart test/shared/widgets/mx_frame_golden_test.dart test/shared/widgets/goldens DESIGN.md
git commit -m "feat(sp3a-p4): MxAppBar, MxBreadcrumb, MxFooterBar, MxScreenScaffold and MxScreenScroll

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5"
```


---

### Task 4: Review, Impeccable, gate and sign-off

- [ ] **Step 1: Impeccable after the build** (CLAUDE.md, a screen's workflow, step 5)
  - Critique the 16 new goldens against `DESIGN.md` and the contracts above.
  - Fix everything found in one batch.
  - That fix ends with exactly one `impeccable audit`. If the audit finds something, fix it in one batch and report it; never run a further audit.
- [ ] **Step 2: The final whole-branch review on Opus** of this phase's commits.
  - The reviewer gets the plan, the spec, this Review Focus and the ledger's `Ruling:` lines.
  - Fix Critical and Important findings in one pass, each RED→GREEN with the full suite.
  - Ledger the minors as `Final: minor (deferred)`.
- [ ] **Step 3: The gate.**
  - `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` must end with `✓ mechanical gates passed`.
  - `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` must match every golden (Linux container).
- [ ] **Step 4: The owner's pages.**
  - Build the `golden-compare` page for this phase's goldens: 16 new, and none changed (the Phase 3 contracts are frozen, so a changed P2/P3 golden is a finding, not a note).
  - Republish the shared-widget gallery (`python3 tools/design/gallery.py --out <scratchpad>/mx-gallery.html`, same artifact).
- [ ] **Step 5: The record.**
  - In `docs/wbs_FE.md`, set SP3a-P4 to `xong` with its evidence.
  - Run `python3 tools/docs/generate.py` and `python3 tools/docs/check.py`, then commit and push.
- [ ] **Step 6: Sign-off.** Ask the owner through `AskUserQuestion` with:
  - the gate, the pages, the Impeccable and review findings, the rulings and the deferred minors.

## Definition of Done

- The nine components are `built` in the catalog, each with its source, widget test and listed goldens (`check.py` enforces this). With them, every SP3a catalog entry is `built` (spec §7).
- `generate.py --check`, `check.py`, the guard, `flutter analyze` and the full suite are green (`dod_check.sh`). `run_goldens.sh` matches.
- Each component's widget test covers:
  - its states;
  - its 48 target where it has one;
  - its semantics (one node per row, a header, live and selected states);
  - RTL;
  - both themes where it paints a colour;
  - the geometry DESIGN.md states, measured with `getRect`.
- No Phase 2 or Phase 3 golden changes.
- Impeccable has critiqued the build, the fix has had its one audit, the Opus review is resolved, the owner has the `golden-compare` page and the gallery, and the owner has signed off.

---

## Outcome (owner sign-off, 2026-10-04)

Phase 4 is accepted: 9/9 components built, gate 2017/2017, 78/78 goldens, no Critical finding. The three Important findings of the final review (scaffold insets) and the owner's breadcrumb finding (a non-colour cue: an openable ancestor is underlined) are fixed with regression tests (`5d60346`, `b85e7667`).

**Rulings kept** (owner, at sign-off):
- In dark, the text action "Select" reads near-white. This is the Indigo Accent (`on-primary-container`), and its contrast passes. It is reviewed again in SP3b on a real screen.
- The bar's ground switches without a transition, because DESIGN.md asks for none. No animation is added just for polish.
- Checkbox rows start their text earlier than tile rows. A selecting list never mixes the two leadings.
- The title starts at 60 after a leading control (contract).
- The "…" place keeps a 48 width (The 48 Floor Rule).

**Deferred minors** (final review). These are not pulled into a later phase as a batch. One is taken up only if it blocks a composition, breaks a contract, or becomes Important.
- `MxScreenScaffold` centres a short body (an empty state wants that; a short form may not).
- `MxBreadcrumb` measures without the bold-text setting.
- `MxAppBar` cannot grow past 56 above 2.0× text.
- `MxListRow` and `MxSettingsRow` use a `LayoutBuilder` for a capped trailing, which rules out intrinsic sizing.
- On a 720–800 window the cutout inset is partly doubled inside the column.
- Test gaps around the bar's ground:
  - nested or horizontal scrolls;
  - a bare `Scaffold`;
  - an observer swap.
- The text-scale tests assert that no exception is thrown, not that nothing clips.
- Tooling: `run_tests.sh` did not report a test file that failed to compile. `flutter analyze` in the gate catches it.

