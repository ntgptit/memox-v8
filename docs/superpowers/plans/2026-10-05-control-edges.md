# Control edges that hold 3:1 app-wide — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every edged input, every outline button and the six code slots rest on one edge that holds ≥3:1 on every ground in both themes, and a dialog's action pair lines up with its text.

**Architecture:**
- One derived token, `MxDerivedColors.outlineEdge`, is retuned. Light becomes `outline` lerped 10 % toward `onSurface`; dark is unchanged. A static `outlineEdgeOf(scheme)` exposes it, so the component themes can use it without the semantic palette.
- The fields theme and the raw OutlinedButton theme take that token.
- `MxTextField` drops its `hasStrongEdge` opt-in, and `MxCodeField` takes the token.
- `MxSheetActions`' dialog form changes its insets.

**Tech Stack:** Flutter 3.47.5, Dart, flutter_test; repo scripts `run_tests.sh`, `dod_check.sh` and `run_goldens.sh`; the `golden-compare` skill.

**Spec:** `docs/superpowers/specs/2026-10-05-control-edges-design.md` (owner rulings E1–E5, DEV-166)

## Global Constraints

- **Branch:** `claude/dev-166-control-edges`. Its own PR merges after PR 208 (E1).
- **Edge token:**
  - Light: `Color.lerp(scheme.outline, scheme.onSurface, 0.10)`, about #717AA0.
  - Dark: `Color.lerp(scheme.outline, scheme.onSurface, 0.25)`, unchanged (E5, spec §3.1).
  - If a light contrast row fails, raise 0.10 to the least step of 0.05 that holds, and record it in the commit message and the spec.
- **3:1 floor:** the edge must hold ≥3:1 (`_nonText`) on the page (`surface`), the field fill (`surfaceContainerLow`), the lowest ground (`surfaceContainerLowest`), the sheet and dialog ground (`surfaceContainerHigh`) and the warning ground (`warningSoft` over the page), in both themes.
- **Fields (E2):**
  - Resting edge: `border` and `enabledBorder` are 1 dp `outlineEdge`.
  - Disabled: Ghost Border.
  - Focus: 2 dp primary ink, unchanged.
  - Error: `error`, unchanged.
  - Study variant: bare, unchanged.
- **Dialog form of `MxSheetActions` (E4):** padding `EdgeInsets.fromLTRB(AppSpacing.card, AppSpacing.gutter, AppSpacing.card, AppSpacing.card)` (20, 16, 20, 20). The sheet form is unchanged (8 / 16 / 16).
- **House style:**
  - no `else`;
  - `is…` / `has…` predicate names;
  - ≤400 logical lines per file;
  - no raw colours in widgets, only tokens;
  - English comments, sparse.
- **Commits:** end each message with the two trailer lines the session uses (`Co-Authored-By: …` and `Claude-Session: …`). No model names anywhere else.
- **Running tests:** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>…` from the repo root. Never `--update-goldens` outside Task 5.

## Review Focus

1. **A field or an outline button inside a sheet or dialog** (rename deck, add tag) must still hold 3:1. Task 1 pins the sheet-ground row.
2. **A disabled field** keeps the faint Ghost Border, so it does not look enabled. Task 2 pins it.
3. **A field with an error** at rest keeps the `error` edge and is not overwritten by the new default. Task 2 pins it.
4. **`MxSheetActions.custom`** (Trash's footer, a single OK) in a dialog takes the same 20 insets. Task 3 pins it.
5. **A dialog pair that stacks** because of a long label keeps the 20 side insets. Task 3 pins it.

---

### Task 1: Retune Outline Edge and give the raw OutlinedButton theme the same edge

**Files:**
- Modify: `lib/core/theme/mx_derived_colors.dart` (the `outlineEdge:` entry around line 118, the constants around line 162)
- Modify: `lib/core/theme/app_component_themes.dart:112-123` (`outlinedButtons`)
- Test: `test/core/theme/token_contrast_test.dart`, `test/core/theme/mx_derived_colors_test.dart`, `test/core/theme/app_component_themes_test.dart`

**Interfaces:**
- Produces: `static Color MxDerivedColors.outlineEdgeOf(ColorScheme scheme)`. `MxDerivedColors.resolve(...).outlineEdge` returns the same value.

- [ ] **Step 1: Write the failing contrast rows.** In `test/core/theme/token_contrast_test.dart`, replace the dark-only block that starts `// Critique 2026-09-30 part 1 (R7)` (the `if (scheme.brightness == Brightness.dark) ...[ … ]` list) with rows for both themes:

```dart
    // The one control edge (DEV-166, spec 2026-10-05 control edges §3.1):
    // fields, outline buttons and code slots hold 3:1 on every ground they
    // sit on, in both themes.
    for (final (ground, where) in [
      (page, 'page'),
      (scheme.surfaceContainerLow, 'field fill'),
      (scheme.surfaceContainerLowest, 'lowest'),
      (sheet, 'sheet'),
      (Color.alphaBlend(derived.warningSoft, page), 'warning ground'),
    ])
      ('outline edge on $where', derived.outlineEdge, ground, _nonText),
```

  In the same file, delete the rows `'code slot edge on page'` and `'code slot edge on its fill'`, along with their two comments. The slots take `outlineEdge` in Task 2, and the rows above cover them.

- [ ] **Step 2: Write the failing derivation test.** In `test/core/theme/mx_derived_colors_test.dart`, add:

```dart
  test('outlineEdge: outline pulled toward onSurface, 10% light and 25% '
      'dark (DEV-166)', () {
    expect(
      light.outlineEdge,
      Color.lerp(
        AppColorSchemes.light.outline,
        AppColorSchemes.light.onSurface,
        0.10,
      ),
    );
    expect(
      dark.outlineEdge,
      Color.lerp(
        AppColorSchemes.dark.outline,
        AppColorSchemes.dark.onSurface,
        0.25,
      ),
    );
    expect(
      MxDerivedColors.outlineEdgeOf(AppColorSchemes.light),
      light.outlineEdge,
    );
  });
```

  `light` and `dark` are the resolved palettes the file already declares; check their names at the top of the file. Add the `AppColorSchemes` import if it is missing.

- [ ] **Step 3: Write the failing theme test.** In `test/core/theme/app_component_themes_test.dart`, the test whose `paintOf('Outlined')` expects `scheme.outlineVariant` (around line 111) changes to expect `MxDerivedColors.outlineEdgeOf(scheme)`. The disabled one around line 257 changes to `closeTo(MxDerivedColors.outlineEdgeOf(scheme).a * 0.38, 0.01)`.

- [ ] **Step 4: Run the tests and see them fail.**

  Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/token_contrast_test.dart test/core/theme/mx_derived_colors_test.dart test/core/theme/app_component_themes_test.dart`

  Expected:
  - the contrast rows fail for light (about 1.5:1);
  - the derivation test does not compile, because `outlineEdgeOf` is undefined.

- [ ] **Step 5: Implement.** In `lib/core/theme/mx_derived_colors.dart`, replace the `outlineEdge:` entry and its comment with:

```dart
      outlineEdge: outlineEdgeOf(scheme),
```

  Then add next to `primaryInkOf`:

```dart
  /// The one control edge: fields at rest, the outline button, the code
  /// slots. Outline pulled toward onSurface until it holds 3:1 on the page,
  /// the field fill, the sheet and the warning ground in both themes
  /// (DEV-166; replaces owner ruling R7's light outlineVariant).
  static Color outlineEdgeOf(ColorScheme scheme) => Color.lerp(
    scheme.outline,
    scheme.onSurface,
    scheme.brightness == Brightness.dark
        ? _outlineEdgeDark
        : _outlineEdgeLight,
  )!;
```

  Add `static const double _outlineEdgeLight = 0.10;` beside `_outlineEdgeDark`.

  In `lib/core/theme/app_component_themes.dart` `outlinedButtons`, replace `scheme.outlineVariant` with `MxDerivedColors.outlineEdgeOf(scheme)`.

- [ ] **Step 6: Run the tests and see them pass.** Use the same command as Step 4; expected PASS. If a light row fails, raise `_outlineEdgeLight` by 0.05 at a time to the least value that passes, and update Step 2's expectation to match.

- [ ] **Step 7: Commit.**

```bash
git add lib/core/theme/mx_derived_colors.dart lib/core/theme/app_component_themes.dart test/core/theme/
git commit -m "fix(theme): one control edge that holds 3:1 in both themes (DEV-166)"
```

---

### Task 2: Fields and code slots rest on Outline Edge; drop `hasStrongEdge`

**Files:**
- Modify: `lib/core/theme/app_component_themes.dart:30-55` (`fields`)
- Modify: `lib/shared/widgets/mx_text_field.dart`:
  - the `hasStrongEdge` constructor parameter (around line 64);
  - its copy (around line 88);
  - the field and its doc (around lines 114-116);
  - its use in `_field` (around lines 285-290);
  - the `_strongEdge` helper.
- Modify: `lib/shared/widgets/mx_code_field.dart:92`
- Modify: `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart` (remove `hasStrongEdge: true` and its comment)
- Test:
  - `test/core/theme/app_component_themes_test.dart`
  - `test/shared/widgets/mx_text_field_test.dart`
  - `test/shared/widgets/mx_code_field_test.dart`
  - `test/features/account/presentation/sign_in_layout_test.dart`

**Interfaces:**
- Consumes: `MxDerivedColors.outlineEdgeOf(ColorScheme)` from Task 1.
- Produces: `MxTextField` without `hasStrongEdge`. Every other parameter is unchanged.

- [ ] **Step 1: Write the failing tests.**

  **`test/core/theme/app_component_themes_test.dart`:**
  - In `'fields: filled, ghost edge, radius 12, no label gap'`, rename it to `'fields: filled, outline edge at rest, ghost when disabled, radius 12, no label gap'`. Expect `enabledBorder` and `border` to be `MxDerivedColors.outlineEdgeOf(scheme)`, and `disabledBorder` to be `ghost`.
  - In `'a raw TextField takes the V3 field'`, expect `MxDerivedColors.outlineEdgeOf(scheme)` instead of `ghost`.

  **`test/shared/widgets/mx_text_field_test.dart`:**
  - Replace `'edges: ghost at rest, primaryInk focused'` with:

```dart
  testWidgets('edges: outline edge at rest, primaryInk focused, ghost '
      'disabled (DEV-166)', (tester) async {
    final rest = MxDerivedColors.outlineEdgeOf(scheme);
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    expect(_edge(_decoration(tester).enabledBorder), rest);
    expect(
      _edge(_decoration(tester).focusedBorder),
      MxDerivedColors.primaryInkOf(scheme),
    );

    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(isEnabled: false)),
    );
    expect(_edge(_decoration(tester).disabledBorder), ghost);
  });

  testWidgets('every edged variant rests on the outline edge (DEV-166)', (
    tester,
  ) async {
    for (final variant in [
      MxTextFieldVariant.form,
      MxTextFieldVariant.detail,
      MxTextFieldVariant.meaning,
      MxTextFieldVariant.term,
    ]) {
      await pumpMx(
        tester,
        SizedBox(width: 300, child: MxTextField(variant: variant)),
      );
      expect(
        _edge(_decoration(tester).enabledBorder),
        MxDerivedColors.outlineEdgeOf(scheme),
        reason: '$variant',
      );
    }
  });
```

  - Delete the test `'a strong edge rests on outline; focus and error are unchanged (DEV-166)'`.
  - Keep the existing error-edge test; it pins Review Focus 3.

  **`test/shared/widgets/mx_code_field_test.dart`:**
  - Change `expect(edgeOf(3).top.color, scheme.outline);` to `expect(edgeOf(3).top.color, derived.outlineEdge);`.
  - Rename the test's `'the rest the outline'` to `'the rest the outline edge'`.

  **`test/features/account/presentation/sign_in_layout_test.dart`:**
  - In `'the email field rests on the outline edge (2026-10-05 L1)'`, expect `MxDerivedColors.outlineEdgeOf(AppColorSchemes.light)` instead of `AppColorSchemes.light.outline`.
  - Add the `MxDerivedColors` import.

- [ ] **Step 2: Run the tests and see them fail.**

  Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_component_themes_test.dart test/shared/widgets/mx_text_field_test.dart test/shared/widgets/mx_code_field_test.dart test/features/account/presentation/sign_in_layout_test.dart`

  Expected: FAIL on the resting edge (ghost or `outline` found, `outlineEdge` expected).

- [ ] **Step 3: Implement.**

  **`AppComponentThemes.fields`:**

```dart
    final ghost = MxDerivedColors.resolve(scheme, semantic).ghostBorder;
    // Every edged field rests on the one control edge (3:1, DEV-166); a
    // disabled one keeps the ghost hairline, as 1.4.11 exempts it.
    final rest = MxDerivedColors.outlineEdgeOf(scheme);
```

  Then set `border: fieldEdge(rest)` and `enabledBorder: fieldEdge(rest)`, and keep `disabledBorder: fieldEdge(ghost)`.

  **`MxTextField`:**
  - Delete the `hasStrongEdge` parameter, its copy line, the field and its doc, and the `_strongEdge` helper.
  - In `_field`, make the resting edge:

```dart
    final restingEdge = edge(
      hasError ? fields.errorBorder : fields.enabledBorder,
    );
```

  - Remove the `themedRest` local if nothing else uses it.
  - Run `dart analyze` to catch any unused import, such as `app_stroke.dart` if `_strongEdge` was its only user.

  **`MxCodeField` line 92:**

```dart
    return BorderSide(
      color: context.derivedColors.outlineEdge,
      width: AppStroke.hairline,
    );
```

  **`SignInFormWidget`:** delete the `// The field reads at a glance…` comment and `hasStrongEdge: true,`.

- [ ] **Step 4: Run the tests and see them pass.** Use the same command as Step 2, plus `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared test/features/account`. Expected: PASS.

  Fix any other test that still asserts the old resting `ghost` on a field or `outline` on a slot. Change only the expected colour, and list each file in the commit message.

- [ ] **Step 5: Commit.**

```bash
git add lib/ test/
git commit -m "fix(ui): every edged field and code slot rests on the control edge; drop hasStrongEdge (DEV-166)"
```

---

### Task 3: The dialog's action pair lines up with its text

**Files:**
- Modify: `lib/shared/widgets/mx_sheet_actions.dart:105-110` (the `!isInSheet` branch)
- Test: `test/shared/widgets/mx_sheet_actions_test.dart`

**Interfaces:**
- Produces: no API change. The dialog form pads `EdgeInsets.fromLTRB(20, 16, 20, 20)` through `AppSpacing` tokens.

- [ ] **Step 1: Write the failing tests.** In `test/shared/widgets/mx_sheet_actions_test.dart`:

  **Edit** `'cancel outline at 1 share, confirm primary at 1.3; 16 inset'`:
  - rename it to `'cancel outline at 1 share, confirm primary at 1.3; 20 at the sides, 16 on top (DEV-166)'`;
  - change the comment to `// 340 − 20 − 20 − 8 = 292, split 10 : 13.`;
  - change the widths to `closeTo(292 * 10 / 23, 0.01)` and `closeTo(292 * 13 / 23, 0.01)`;
  - change the offset to `const Offset(20, 16)`.

  **Add** the bottom-inset test:

```dart
  testWidgets('a dialog pair ends 20 above the dialog edge (DEV-166)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy -
          tester.getBottomLeft(_button('Cancel')).dy,
      20,
    );
  });
```

  **Add** the custom-footer test (Review Focus 4):

```dart
  testWidgets('a custom footer in a dialog takes the same insets (DEV-166)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions.custom(
          children: [
            Expanded(
              child: MxButton(label: 'OK', isBlock: true, onPressed: () {}),
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(_button('OK')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(20, 16),
    );
  });
```

  **Add** the stacked-pair test (Review Focus 5). Use a confirm label too long for its share at width 340, for example `'Discard everything on this phone and continue'`:

```dart
  testWidgets('a stacked dialog pair keeps the 20 side insets (DEV-166)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Discard everything on this phone and continue',
          onConfirm: () {},
        ),
      ),
    );
    final box = tester.getRect(find.byType(MxSheetActions));
    for (final label in [
      'Cancel',
      'Discard everything on this phone and continue',
    ]) {
      final button = tester.getRect(_button(label));
      expect(button.left - box.left, 20, reason: label);
      expect(box.right - button.right, 20, reason: label);
    }
  });
```

  Leave `'in a sheet: a ghost rule on top, then 8 16 16'` unchanged; it must keep passing. If the file has `isEvenSplit` width tests that use 300, change them to 292.

- [ ] **Step 2: Run the tests and see them fail.**

  Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_sheet_actions_test.dart`

  Expected: FAIL on the 16 versus 20 offsets and widths. The sheet test passes.

- [ ] **Step 3: Implement.** Replace the `!isInSheet` padding in `lib/shared/widgets/mx_sheet_actions.dart`:

```dart
    if (!isInSheet) {
      // A dialog's pair lines up with its title and body (20), 16 under the
      // content (L3) and 20 above the edge (DEV-166).
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.gutter,
          AppSpacing.card,
          AppSpacing.card,
        ),
        child: row,
      );
    }
```

  Update the class doc above the `isInSheet` field (around line 69), which says "instead of 16 all round". It should now say "instead of 16 on top and 20 at the sides and bottom".

- [ ] **Step 4: Run the tests and see them pass.**

  Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_sheet_actions_test.dart test/shared test/features`

  Expected: PASS. Fix any other test that measured the old 16 inset or the 300 width; change only the expected number. The L3 test in `sign_in_layout_test.dart` (16 above the pair) must pass unchanged.

- [ ] **Step 5: Commit.**

```bash
git add lib/shared/widgets/mx_sheet_actions.dart test/
git commit -m "fix(ui): a dialog's action pair lines up with its text (DEV-166)"
```

---

### Task 4: Documents

**Files:**
- Modify: `DESIGN.md`:
  - the Colors line about Outline Edge and Ghost Border (around line 241);
  - Inputs (around line 338);
  - MxButton (around line 329);
  - the `MxSheetActions` / `MxDialog` entry.
- Modify: detail files in `docs/shared/ui/screen-handoff/` that name the field's ghost edge or the dialog pair's 16 inset (find them by grep in Step 1).
- Modify: `docs/superpowers/specs/2026-10-05-control-edges-design.md`, only if Task 1 raised the light step above 0.10.

- [ ] **Step 1: Find what names the old values.**

  Run: `grep -rn -i "ghost edge\|ghost border\|hasStrongEdge\|outline-variant in light\|light keeps\|16 all round" DESIGN.md docs/shared/ui/screen-handoff/`

  Expected: the hits are the lines to edit.

- [ ] **Step 2: Edit `DESIGN.md`.**

  **Colors (Outline Edge).** Replace the sentence about the outline button's edge with:

  > The edge of every control that must hold 3:1 is the derived **Outline Edge** (`outlineEdge`): `outline` pulled 10% toward `on-surface` in light (≈ #717AA0: 3.99:1 on the page, 3.82 on the field fill, 3.40 on the sheet) and 25% in dark (≈ #7C8AC1: 5.67, 4.57, 3.40). Fields at rest, the outline button and the code slots use it (DEV-166, replacing R7's light `outline-variant`). The Ghost Border stays the everyday hairline of cards, sections, dividers and a disabled field.

  **Inputs.** Make these replacements:
  - "Ghost edge, primary-ink edge on focus" becomes "Outline Edge at rest (3:1 on every ground), Ghost Border when disabled, primary-ink edge on focus".
  - The code variant's "edged in `outline` (3:1 on the page and the fill)" becomes "edged in Outline Edge".
  - Delete the sentence that begins "`hasStrongEdge` rests a field…".

  **MxButton.** "The outline tone's edge is `outlineEdge`." becomes "The outline tone's edge is Outline Edge, 3:1 on every ground in both themes."

  **MxSheetActions.** Where the dialog footer's padding is described, it becomes "16 above, 20 at the sides and bottom, so the pair lines up with the dialog's title and body (DEV-166); the sheet form stays 8 / 16 / 16 under a ghost rule". If no padding is described yet, add that clause to the `MxSheetActions` entry.

- [ ] **Step 3: Edit the detail files that Step 1 found.** Each change is one clause naming the new edge or inset, with "(DEV-166)".

- [ ] **Step 4: Check the docs.**

  Run: `python3 tools/docs/check.py`

  Expected: `PASS — 0 error(s)`.

- [ ] **Step 5: Commit.**

```bash
git add DESIGN.md docs/
git commit -m "docs(design): one control edge, dialog action insets (DEV-166)"
```

---

### Task 5: Gate, goldens, golden review, audit

**Files:**
- Modify: `test/**/goldens/*.png` (regenerated)

- [ ] **Step 1: Run the gate.**

  Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`

  Expected: `✓ mechanical gates passed`.

- [ ] **Step 2: Regenerate the goldens (Linux container only).**

  Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `git status --short | grep png | wc -l`.

  Expected: many PNGs change. Every one shows an edged field, a light outline button, a dialog pair or a code slot.

- [ ] **Step 3: Build the golden review page** with the `golden-compare` skill. Use base `git merge-base origin/claude/nifty-maxwell-nz5nl3 HEAD` (PR 208's head), so only this branch's changes show. Group the families by cause:
  - field edge;
  - outline button edge;
  - dialog pair inset;
  - code slots.

  Any diff that fits none of these goes to `systematic-debugging` before the page is published.

- [ ] **Step 4: Run one `impeccable audit`** of the changed goldens against `DESIGN.md`. Fix anything it finds in one batch, then stop.

- [ ] **Step 5: Commit the goldens.**

```bash
git add test/
git commit -m "test(goldens): control edges and dialog action insets (DEV-166)"
```

- [ ] **Step 6: Hand over.** Send the owner the golden review page link and the approve / request-changes popup. Pushing the branch and opening the PR wait for the owner's approval of the goldens.
