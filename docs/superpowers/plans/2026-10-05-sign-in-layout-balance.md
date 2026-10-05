# Sign-in layout balance (L1–L5) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the sign-in function gets a visible email field edge, even-width dialog/sheet pairs, one gap above dialog actions, a single-edge merge sheet, and a stopped layer whose actions sit in the footer — without changing any screen outside it.

**Architecture:** two shared widgets gain an opt-in that defaults to today's behaviour (`MxTextField.hasStrongEdge`, `MxSheetActions.isEvenSplit`); only sign-in code turns them on. The account confirm dialog passes the split through. The transition layer moves its stopped-state actions from the centred body into an `MxFooterBar`.

**Tech Stack:** Flutter, Riverpod, `flutter_test` with the repo's `pumpMx` / `accountTest` / `pumpLibraryScreen` harness, goldens in the Linux container.

**Spec:** `docs/superpowers/specs/2026-10-05-sign-in-layout-balance-design.md` (owner rulings L1–L5). Linear: DEV-166 (sign-in part). Branch `claude/nifty-maxwell-nz5nl3`, PR 208.

## Global Constraints

- No screen outside the sign-in function changes: every new parameter defaults to today's behaviour; screen 32 (`account_screen.dart`) passes nothing new.
- Tokens only (guard): no `Colors.*`, no `Color(0x…)`, no `textStyles.x.copyWith(`, no literal spacing/radius/stroke; predicates are `is…`/`has…`; files ≤400 logical lines.
- The strong edge is `colorScheme.outline` at `AppStroke.hairline`; focus, error and disabled edges are unchanged.
- An even split is 1:1; when a label does not fit its half on one line the pair stacks full width (existing `MxActionPair` behaviour), Cancel on top.
- Tests via `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>…`; goldens only in Task 4.
- Commit messages name `DEV-166` and end with the session's two attribution lines.

## Review Focus

1. **Screen 32's dialogs and every non-sign-in form field look exactly as before** → Task 4's golden run changes no `account_sign_out_*`, `account_delete_*`, `account_switch_*`, card editor, deck or settings golden; Task 2 asserts screen 32's confirm keeps the 10:13 split.
2. **An even pair whose label is too long for half the width** (the merge sheet's "Discard and continue") → stacks, both buttons full width (Task 1 test).
3. **A focused or errored strong-edge field** keeps the focus (2 dp primary ink) and error edges (Task 1 test).
4. **A stopped layer while the keyboard is irrelevant but the gesture inset is present** → the footer owns the bottom inset (MxFooterBar does) and nothing is duplicated in the body (Task 3 test: Retry is found once, inside the footer).
5. **A running layer** keeps no footer and its centred spinner (Task 3 test).

---

### Task 1: Opt-ins on the shared widgets (L1, L2)

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart`
- Modify: `lib/shared/widgets/mx_sheet_actions.dart`
- Modify: `DESIGN.md` (Inputs; Containers `MxSheetActions`)
- Test: `test/shared/widgets/mx_text_field_test.dart`, `test/shared/widgets/mx_sheet_actions_test.dart`

**Interfaces:**
- Produces: `MxTextField({…, bool hasStrongEdge = false})` (both constructors; copied in `_on`).
- Produces: `MxSheetActions({…, bool isEvenSplit = false})` (the pair constructor only).

- [ ] **Step 1: Failing tests.** In `mx_text_field_test.dart` (it already has `_decoration`, `_edge`, `scheme`, `ghost`):

```dart
  testWidgets('a strong edge rests on outline; focus and error are '
      'unchanged', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(hintText: 'Email', hasStrongEdge: true),
      ),
    );
    expect(_edge(_decoration(tester).enabledBorder), scheme.outline);
    expect(
      (_decoration(tester).enabledBorder! as OutlineInputBorder)
          .borderSide
          .width,
      1,
    );
    final focus = _edge(_decoration(tester).focusedBorder);
    expect(focus, isNot(scheme.outline));

    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxTextField(
          hintText: 'Email',
          hasStrongEdge: true,
          errorText: 'Wrong',
        ),
      ),
    );
    expect(_edge(_decoration(tester).enabledBorder), scheme.error);
  });

  testWidgets('without a strong edge the field keeps the ghost border', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Email')),
    );
    expect(_edge(_decoration(tester).enabledBorder), ghost);
  });
```

  If the existing error-edge colour differs from `scheme.error` (check how the existing error test reads it), assert the same value that test asserts.

  In `mx_sheet_actions_test.dart` (create it next to the other shared widget tests if missing; reuse `pumpMx` from `../../support/widget_harness.dart`):

```dart
  testWidgets('an even split gives Cancel and the confirm one width', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Continue',
          onConfirm: () {},
          isEvenSplit: true,
        ),
      ),
    );
    final cancel = tester.getSize(find.widgetWithText(MxButton, 'Cancel'));
    final confirm = tester.getSize(find.widgetWithText(MxButton, 'Continue'));
    expect(cancel.width, confirm.width);
    expect(cancel.height, confirm.height);
  });

  testWidgets('an even split stacks a label too long for its half, both full '
      'width', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Discard and continue with everything',
          onConfirm: () {},
          isEvenSplit: true,
        ),
      ),
    );
    final cancel = tester.getRect(find.widgetWithText(MxButton, 'Cancel'));
    final confirm = tester.getRect(
      find.widgetWithText(MxButton, 'Discard and continue with everything'),
    );
    expect(cancel.width, confirm.width);
    expect(cancel.top, lessThan(confirm.top));
  });

  testWidgets('by default the confirm takes the larger share', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Continue',
          onConfirm: () {},
        ),
      ),
    );
    expect(
      tester.getSize(find.widgetWithText(MxButton, 'Continue')).width,
      greaterThan(tester.getSize(find.widgetWithText(MxButton, 'Cancel')).width),
    );
  });
```

  (The stack test's label must not fit 160 dp; if "Discard and continue with everything" happens to fit, lengthen it.)

- [ ] **Step 2: Run, expect compile failures** (`hasStrongEdge`, `isEvenSplit` undefined): `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_text_field_test.dart test/shared/widgets/mx_sheet_actions_test.dart`.

- [ ] **Step 3: `MxTextField`.** Add the field (`/// Rests on the outline edge (3:1) instead of the ghost border, for a field that must read at a glance (sign-in, DEV-166).` `final bool hasStrongEdge;`), the constructor parameter `this.hasStrongEdge = false`, and `hasStrongEdge = field.hasStrongEdge` in `_on`. In `_field`, replace the `restingEdge` computation with:

```dart
    final themedRest = hasError ? fields.errorBorder : fields.enabledBorder;
    final restingEdge = edge(
      hasStrongEdge && !hasError
          ? _strongEdge(themedRest, colors.outline)
          : themedRest,
    );
```

  and add the static helper:

```dart
  /// The themed resting edge redrawn in [color] at a hairline.
  static InputBorder? _strongEdge(InputBorder? themed, Color color) =>
      switch (themed) {
        final OutlineInputBorder outline => outline.copyWith(
          borderSide: outline.borderSide.copyWith(
            color: color,
            width: AppStroke.hairline,
          ),
        ),
        _ => themed,
      };
```

  Import `app_stroke.dart` if missing. If `mx_text_field.dart` passes 400 logical lines (the guard reports it), move `_strongEdge` and `_geometry` into a `part`-free private helper file only if the guard insists; first try keeping it in place.

- [ ] **Step 4: `MxSheetActions`.** Add `this.isEvenSplit = false` to the pair constructor (`isEvenSplit = false` in `.custom`), the field `/// Cancel and the confirm share the width 1:1 (the sign-in confirms, 2026-10-05 L2).` `final bool isEvenSplit;`, and pass `leadingFlex: isEvenSplit ? 1 : _cancelShare, trailingFlex: isEvenSplit ? 1 : _confirmShare`. Update the class doc's first sentence to "The confirm takes 1.3 shares to Cancel's 1, or an even half each with [isEvenSplit], …".

- [ ] **Step 5: Run the tests** (same command) → PASS.

- [ ] **Step 6: DESIGN.md.** Inputs: after the MxTextField sentence on edges add "`hasStrongEdge` rests a field on the `outline` edge (3:1) instead of the ghost edge; the sign-in email field sets it (2026-10-05 L1; DEV-166 owns the rest of the app)." Containers: in the `MxSheetActions` mention add "(`isEvenSplit` shares 1:1, the sign-in confirms, L2)".

- [ ] **Step 7: Commit.** `dart format` + `flutter analyze` on touched lib files, then `git commit -m "feat(shared): opt-in strong field edge and even action pair (DEV-166)"` + attribution lines.

---

### Task 2: Sign-in uses them; dialog gap; merge sheet edge (L1–L4)

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart` (email field `hasStrongEdge: true`)
- Modify: `lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart` (`isEvenSplit` through `confirmAccountStep` and `AccountConfirmDialogWidget`; `confirmUnsentLoss` passes true; L3 gap)
- Modify: `lib/features/account/presentation/screens/sign_in_screen.dart` (`_leave` passes `isEvenSplit: true`)
- Modify: `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart` (`isEvenSplit: true`; header horizontal padding `AppSpacing.gutter`)
- Test: `test/features/account/presentation/sign_in_screen_test.dart`, `account_confirm_dialog_test.dart`, `merge_choice_sheet_test.dart`, `account_screen_test.dart`

**Interfaces:**
- Consumes: `MxTextField.hasStrongEdge`, `MxSheetActions.isEvenSplit` (Task 1).
- Produces: `confirmAccountStep(…, {bool isEvenSplit = false})`; `AccountConfirmDialogWidget({…, this.isEvenSplit = false})`.

- [ ] **Step 1: Failing tests.**
  - `sign_in_screen_test.dart`: the email `TextField`'s decoration `enabledBorder` colour equals `AppColorSchemes.light.outline` (read via `tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration.enabledBorder`).
  - `account_confirm_dialog_test.dart`: `confirmUnsentLoss` shows Cancel and Continue at equal widths; a `confirmAccountStep` with a note and one without leave the same gap between the last content's bottom and the actions' top (measure `tester.getBottomLeft(<last text or note>).dy` vs `tester.getTopLeft(find.byType(MxSheetActions)).dy` — compare the button's top, not the padding box, if `MxSheetActions` has outer padding: use the Cancel `MxButton`'s top in both cases).
  - `merge_choice_sheet_test.dart`: Cancel and Continue equal width (short label); the title's left equals the first `MxOptionRow` title's left (both at 16 from the sheet's left).
  - `account_screen_test.dart` (Review Focus 1): screen 32's sign-out confirm keeps a wider confirm than Cancel.

- [ ] **Step 2: Run them, expect failures.**

- [ ] **Step 3: Implement.**
  - Email field: add `hasStrongEdge: true` to the `MxTextField` in `SignInFormWidget`.
  - `confirmAccountStep` gains `bool isEvenSplit = false`, passed to `AccountConfirmDialogWidget(isEvenSplit: isEvenSplit)`, which passes it to `MxSheetActions`. `confirmUnsentLoss` passes `isEvenSplit: true`. `sign_in_screen.dart` `_leave` passes `isEvenSplit: true`. Screen 32 is untouched.
  - Merge sheet: `MxSheetActions(isEvenSplit: true, …)`; header `EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.micro, AppSpacing.gutter, AppSpacing.grouped)`.
  - **L3:** find why the gap after a note is larger (inspect `MxInlineBanner`/`MxNote` outer padding or margins, and how `AccountConfirmDialogWidget` passes `note` as `content`). Fix it in the account code (e.g. pass the note without the extra outer spacing). If the only cause is inside `MxDialog`/`MxInlineBanner` and cannot be neutralised from the account code, stop and report it (NEEDS_CONTEXT) with the measured numbers — do not change the shared widget.

- [ ] **Step 4: Run the four test files → PASS.**

- [ ] **Step 5: Commit.** `feat(account): sign-in field edge, even confirms, one gap, merge sheet edge (DEV-166)`.

---

### Task 3: A stopped layer keeps its actions in the footer (L5)

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
- Test: `test/features/account/presentation/account_transition_layer_test.dart`

**Interfaces:**
- Internal only: `_LayerPage` passes `footer:` to `MxAppShell` when the view is stopped; `_Progress` keeps only the banner in its stopped branch; a new private `_StoppedActions` (ConsumerWidget, takes the `view`) owns Retry, `_retry`, `_isSignOutStoppedOffline` and `_SignOutNow`.

- [ ] **Step 1: Failing tests** in `account_transition_layer_test.dart`, pumping the layer in the stopped states the goldens use (`layer_offline`, `layer_sign_out_offline`, `layer_stuck`; see `account_golden_test.dart` for the `AuthState` values) and in the running state (`layer_sending`):
  - stopped: `find.descendant(of: find.byType(MxFooterBar), matching: find.text(_en.commonRetry))` findsOneWidget and `find.text(_en.commonRetry)` findsOneWidget (not duplicated in the body);
  - sign-out offline: the "Sign out now and lose 2 changes" button is inside the footer (override `unsentCountProvider` to 2 as the golden does);
  - running: `find.byType(MxFooterBar)` findsNothing and the `MxSpinner` is present.
  Keep every existing layer test (Retry still retries, Cancel still cancels).

- [ ] **Step 2: Run, expect failures.**

- [ ] **Step 3: Implement.**
  - In `_LayerPage.build`, compute `isStopped` as today and return `MxAppShell(appBar: appBar, body: SafeArea(child: _Progress(view: view)), footer: isStopped ? MxFooterBar(child: _StoppedActions(view: view)) : null)`.
  - In `_Progress`, the stopped branch keeps only the live-region `MxInlineBanner`; the column stays centred. Move `_retry` and `_isSignOutStoppedOffline` to `_StoppedActions`.
  - `_StoppedActions.build` returns a `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.grouped, children: [MxButton(label: l10n.commonRetry, isBlock: true, onPressed: () => unawaited(_retry(ref))), if (_isSignOutStoppedOffline(view.error)) const _SignOutNow()])`.
  - Update the doc comments (the layer's stopped actions sit in the footer, 2026-10-05 L5; the running state stays centred).

- [ ] **Step 4: Run → PASS.** Also run `test/features/account/presentation/account_screen_test.dart` (flows that end in the layer).

- [ ] **Step 5: Commit.** `feat(account): a stopped layer keeps its actions in the footer (DEV-166)`.

---

### Task 4: Records, goldens, gate

**Files:**
- Modify: `docs/shared/ui/screen-handoff/30-sign-in.md` (L1–L5; amend ruling F1: "content centred; a stopped layer's actions sit in the footer (2026-10-05 L5)"; merge sheet and dialog rows), `31-code.md` (the loss dialog's even pair)
- Regenerate: goldens

- [ ] **Step 1: Detail files** as above, citing `2026-10-05-sign-in-layout-balance-design.md` L1–L5.
- [ ] **Step 2: Gate.** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → `✓ mechanical gates passed`.
- [ ] **Step 3: Goldens.** `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`; `git status --short -- '*.png'`. Allowed: `sign_in_*`, `layer_target_*`, `layer_offline_*`, `layer_sign_out_offline_*`, `layer_stuck_*`, `merge_sheet_*`, and any account golden that shows a sign-in confirm dialog. Any other changed PNG (screen 32's `account_*` dialogs, card, deck, settings, shared widgets) is a regression: stop and report. Open each changed PNG (light and dark) and check it against the spec. Then `run_goldens.sh` compare → PASS.
- [ ] **Step 4: Commit and push.** `docs(account): sign-in layout balance records and goldens (DEV-166)`; `git push -u origin claude/nifty-maxwell-nz5nl3`.

After the plan: Impeccable audit of the changed goldens (one), the final whole-branch review of this range, the golden review page for the owner.
