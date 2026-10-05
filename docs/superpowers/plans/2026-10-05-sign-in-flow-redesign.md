# Sign-in flow redesign (29 · 30 · 31) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** screens 29 Welcome, 30 Sign-in and 31 Code (and the transition layer's sign-in) share one frame (head in the body, one task, actions in an `MxFooterBar` above the keyboard), the code field draws six slots, and the critique's P1/P2 copy and state fixes land.

**Architecture:** layout and copy only; controllers, commands, routes and states do not change. The code field's slots live in the shared `MxTextField` (code variant) as a painted row over one hidden `TextField`. `SignInFormWidget` grows from a body column into the whole sign-in page (an `MxAppShell` with its footer), so screen 30 and the layer pass only their top bar and what sits under the field. `CodeFormWidget` paints the code step's title so both its hosts drop the app bar title.

**Tech Stack:** Flutter, Riverpod 3, `flutter_test` with the repo's `accountTest` / `pumpLibraryScreen` harness, ARB l10n (`flutter gen-l10n`, output not committed), goldens in the Linux container.

**Spec:** `docs/superpowers/specs/2026-10-05-sign-in-flow-redesign-design.md` (rulings S1–S10). Linear epic DEV-155.

## Global Constraints

- No change to any controller, state, provider, route or command; only `presentation/screens`, `presentation/widgets`, `lib/shared/widgets/mx_text_field.dart`, `lib/core/theme` tokens/styles, ARB files, tests, docs.
- Copy is exactly spec §6 (EN and VI). Every other string stays.
- Tokens only (guard `memox.design_token.*`, `memox_v8.design_system.*`): no `Colors.*`, no `Color(0x…)`, no `textStyles.x.copyWith(`, no literal spacing, radius, stroke width or duration. A combination no style expresses is added to `MxTextStyles`.
- New core tokens this plan adds, and only these: `AppSize.codeSlot = 56`, `AppOpacity.hidden = 0`, `MxTextStyles.emptyBodyStrong`; `MxTextStyles.fieldCode` loses its wide tracking. The owner approves them with the plan (CLAUDE.md, reuse-or-write).
- One fill per decision (One Indigo). Welcome online: Google. Welcome offline: "Continue without an account". Screen 30: "Send code". Screen 31: none.
- Heights are minimums, never fixed around text (The Text Grows Rule).
- Tests run through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>…`, never `flutter test <dir>`.
- Goldens are regenerated once, in Task 5, with `run_goldens.sh --update` in the Linux container; tasks 1–4 do not touch PNGs.
- Each commit message names the task's Linear sub-issue (`DEV-n`, from the ledger at the end) and ends with the session's attribution lines.

## Review Focus

1. **A narrow phone (320 dp wide)**: the six slots shrink to fit the 288 dp column instead of overflowing (Task 1, narrow-width test).
2. **A code pasted or autofilled as "123 456"**: the hidden field strips the space, the six slots show the six digits, and verify fires once (Task 1 paste test; Task 2 keeps the six-digit verify test).
3. **The keyboard is up on screen 30**: "Send code" stays reachable above it, because the footer is a sibling of the scroll inside `MxAppShell` (Task 3 asserts the actions live in the `MxFooterBar`, not the scroll).
4. **The account becomes ready while Welcome or Sign-in is open**: Welcome's footer switches from one primary to three buttons, and Sign-in's caption goes (Task 4 flips `authState` while mounted; Task 3 asserts the caption appears only while not ready).
5. **A re-auth whose email is not known yet** (it arrives a frame after the form): no empty eyebrow line, and the eyebrow appears when the email lands (Task 3 test with a null `initialEmail`, then the filled one).

---

### Task 1: `MxTextField` code variant draws six slots

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart` (code variant doc; new `autofocus`; `build` routes the code variant to `_CodeField`; `_field` loses its code branches)
- Modify: `lib/core/theme/foundations/app_size.dart` (add `codeSlot`)
- Modify: `lib/core/theme/foundations/app_opacity.dart` (add `hidden`)
- Modify: `lib/core/theme/mx_text_styles.dart` (`fieldCode` drops `_codeTracking`; remove `_codeTracking` if nothing else reads it)
- Modify: `DESIGN.md` (Components › Inputs, the `code` bullet)
- Test: `test/shared/widgets/mx_text_field_test.dart`, `test/core/theme/token_contrast_test.dart`

**Interfaces:**
- Produces: `MxTextField({…, bool autofocus = false})`, passed to the `TextField` in every variant.
- Produces: `@visibleForTesting static Key MxTextField.slotKey(int index)` returns `ValueKey('mx-code-slot-$index')`.
- Produces: `AppSize.codeSlot` (56), `AppOpacity.hidden` (0).

- [ ] **Step 1: Write the failing tests** in `mx_text_field_test.dart`. Replace the test "the code variant asks for digits, offers the one-time code and centres them" with the first test below, keep "keeps six digits and nothing else", and add the rest:

```dart
  testWidgets('the code variant asks for digits and offers the one-time '
      'code', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(label: 'Code', variant: MxTextFieldVariant.code),
    );
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
    expect(field.maxLines, 1);
    expect(field.showCursor, isFalse);
  });

  testWidgets('the code variant paints six slots, one digit in each', (
    tester,
  ) async {
    final controller = TextEditingController(text: '427');
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    for (var i = 0; i < MxTextField.codeLength; i++) {
      expect(find.byKey(MxTextField.slotKey(i)), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(MxTextField.slotKey(1)),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(MxTextField.slotKey(0))).width, 48);
    expect(
      tester.getSize(find.byKey(MxTextField.slotKey(0))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('a pasted "123 456" fills six slots', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.enterText(find.byType(TextField), '123 456');
    await tester.pump();

    expect(controller.text, '123456');
    expect(
      find.descendant(
        of: find.byKey(MxTextField.slotKey(5)),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the slot that takes the next digit carries the focus edge; '
      'the rest the outline; an error edges every slot', (tester) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    Border edgeOf(int i) =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byKey(MxTextField.slotKey(i)),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .border! as Border;

    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        autofocus: true,
      ),
    );
    await tester.pump();
    expect(edgeOf(2).top.color, derived.primaryInk);
    expect(edgeOf(2).top.width, 2);
    expect(edgeOf(3).top.color, scheme.outline);

    await pumpMx(
      tester,
      MxTextField(
        controller: controller,
        variant: MxTextFieldVariant.code,
        errorText: 'Wrong',
      ),
    );
    expect(edgeOf(0).top.color, scheme.error);
    expect(edgeOf(5).top.color, scheme.error);
  });

  testWidgets('a tap on a slot focuses the code', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(variant: MxTextFieldVariant.code),
    );

    await tester.tap(find.byKey(MxTextField.slotKey(4)));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('six slots fit a 288 wide column', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 288,
        child: MxTextField(variant: MxTextFieldVariant.code),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(MxTextField.slotKey(0))).width,
      lessThan(48),
    );
  });

  testWidgets('TalkBack still reads the code field by its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxTextField(label: 'Code, 6 digits', variant: MxTextFieldVariant.code),
    );

    expect(find.bySemanticsLabel('Code, 6 digits'), findsOneWidget);
    handle.dispose();
  });
```

In `token_contrast_test.dart`, add after the `('toggle off edge on a row', …)` pair:

```dart
    // The code field's slots (sign-in redesign 2026-10-05, §4.1): the edge
    // holds 3:1 against the page around it and the fill inside it.
    ('code slot edge on page', scheme.outline, page, _nonText),
    (
      'code slot edge on its fill',
      scheme.outline,
      scheme.surfaceContainerLow,
      _nonText,
    ),
```

- [ ] **Step 2: Run them to see them fail.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_text_field_test.dart test/core/theme/token_contrast_test.dart`. Expected: compile errors (`slotKey`, `autofocus` undefined). The two contrast pairs pass already (3.44/3.29 light, 3.75/3.02 dark); they pin the choice.

- [ ] **Step 3: Tokens and the style.** In `app_size.dart`:

```dart
  /// A code field's slot (sign-in redesign 2026-10-05): a minimum, so the
  /// digit grows with the text scale.
  static const double codeSlot = 56;
```

In `app_opacity.dart`:

```dart
  /// A control kept for input and semantics while something else paints it,
  /// such as the code field's hidden text field under its slots.
  static const double hidden = 0;
```

In `mx_text_styles.dart` `fieldCode` becomes the following, and `_codeTracking` is deleted if `grep -n _codeTracking lib/core/theme/mx_text_styles.dart` shows no other reader:

```dart
  /// A code slot's digit: the headline role with tabular figures. Each slot
  /// holds one digit, so the line needs no wide tracking.
  TextStyle get fieldCode => _texts.headlineSmall!.copyWith(
    fontFeatures: _tabular,
    color: _scheme.onSurface,
  );
```

- [ ] **Step 4: The code variant.** In `mx_text_field.dart`:
  - Rewrite the enum doc of `code` as below.
  - Add `this.autofocus = false` to both constructors (copy it in `_on`) and `final bool autofocus;` with the doc `/// Takes the focus when first shown, such as the sign-in code.`
  - Pass `autofocus: autofocus` to the `TextField` in `_field`.
  - In `build`, add `if (variant == MxTextFieldVariant.code) return _CodeField(field: this);` first.
  - In `_field`, delete the `isCode` local and every code branch: the keyboard type arm, the formatters, the autofill hints, the centring and the fill. `_geometry` and `_valueStyle` keep their code arms because the switches are exhaustive. Leave a comment that `_CodeField` draws the code variant.

```dart
  /// A sign-in code (account UI spec U2; sign-in redesign 2026-10-05 §4.1):
  /// six slots painted over one hidden field, which keeps the numeric
  /// keyboard, the one-time-code autofill, paste and the TalkBack label.
  code,
```

```dart
  /// A code slot, for tests that find one.
  @visibleForTesting
  static Key slotKey(int index) => ValueKey('mx-code-slot-$index');
```

Append to the file:

```dart
/// The code variant: six slots over one hidden field. The field fills the
/// row, so a tap on any slot focuses it and a long press offers paste; the
/// slots follow its text and focus.
class _CodeField extends StatefulWidget {
  const _CodeField({required this.field});

  final MxTextField field;

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.field.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus => widget.field.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  BorderSide _edge(BuildContext context, int index) {
    final colors = context.colors;
    if (widget.field.errorText != null) {
      return BorderSide(color: colors.error, width: AppStroke.hairline);
    }
    final isNext = _focus.hasFocus && index == _controller.text.length;
    if (isNext) {
      return BorderSide(
        color: context.derivedColors.primaryInk,
        width: AppStroke.focus,
      );
    }
    return BorderSide(color: colors.outline, width: AppStroke.hairline);
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final hidden = TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: field.autofocus,
      enabled: field.isEnabled,
      onChanged: field.onChanged,
      onSubmitted: field.onSubmitted,
      textInputAction: field.textInputAction,
      maxLines: 1,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(MxTextField.codeLength),
      ],
      autofillHints: const [AutofillHints.oneTimeCode],
      showCursor: false,
      style: context.textStyles.fieldCode,
      decoration: const InputDecoration.collapsed(hintText: null),
    );
    final slots = ListenableBuilder(
      listenable: Listenable.merge([_controller, _focus]),
      builder: (context, _) {
        final text = _controller.text;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          children: [
            for (var i = 0; i < MxTextField.codeLength; i++)
              Flexible(
                child: _CodeSlot(
                  key: MxTextField.slotKey(i),
                  digit: i < text.length ? text[i] : '',
                  edge: _edge(context, i),
                ),
              ),
          ],
        );
      },
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            slots,
            Positioned.fill(
              child: Opacity(
                opacity: AppOpacity.hidden,
                // The field stays in the tree for TalkBack and autofill.
                alwaysIncludeSemantics: true,
                child: field.label == null
                    ? hidden
                    : Semantics(label: field.label, child: hidden),
              ),
            ),
          ],
        ),
        if (field.errorText case final message?)
          MxFieldMessage(message: message),
      ],
    );
    if (field.isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}

/// One digit's box: 48 wide at most (it shrinks in a narrow column), 56 tall
/// at least, on the form fill.
class _CodeSlot extends StatelessWidget {
  const _CodeSlot({super.key, required this.digit, required this.edge});

  final String digit;
  final BorderSide edge;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppSize.touchTarget,
      minHeight: AppSize.codeSlot,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.fromBorderSide(edge),
      ),
      child: Center(child: Text(digit, style: context.textStyles.fieldCode)),
    ),
  );
}
```

Add `import 'package:memox/core/theme/foundations/app_stroke.dart';` if it is missing. If `context.derivedColors.primaryInk` has another name, use the getter that `test/core/theme/token_contrast_test.dart` reads as `derived.primaryInk`.

- [ ] **Step 5: Run the tests.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_text_field_test.dart test/core/theme/token_contrast_test.dart`. Expected: PASS. If the focus-edge test sees no focus after `autofocus`, add one more `await tester.pump();` (autofocus lands a frame later). Do not change the widget for this.

- [ ] **Step 6: DESIGN.md.** In Components › Inputs, replace "code (one centred line of six digits on the form fill, headline role with tabular figures and wide tracking, numeric keyboard and one-time-code autofill)" with:

  > code (six slots, 48 wide at most and 56 tall at least, r12 on the form fill, edged in `outline` (3:1 on the page and the fill), the slot that takes the next digit in a 2dp primary-ink edge, every slot in `error` on a wrong code; one hidden field under them keeps the numeric keyboard, one-time-code autofill, paste and the TalkBack label; headline role with tabular figures; sign-in redesign 2026-10-05)

  If `.impeccable/design.json` describes the code variant, make the same edit there.

- [ ] **Step 7: Analyzer and guard on the touched files.** Run `dart format lib/shared/widgets/mx_text_field.dart lib/core/theme test/shared/widgets/mx_text_field_test.dart test/core/theme/token_contrast_test.dart && flutter analyze lib/shared/widgets/mx_text_field.dart lib/core/theme`. Expected: no issues.

- [ ] **Step 8: Commit.** `git add` the files above, then `git commit -m "feat(shared): the code field draws six slots (DEV-n)"` with the attribution lines.

---

### Task 2: Screen 31 · the code step

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/code_form_widget.dart`
- Modify: `lib/features/account/presentation/screens/code_screen.dart` (app bar without title)
- Modify: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart` (`_LayerCodePage` app bar without title)
- Modify: `lib/core/theme/mx_text_styles.dart` (add `emptyBodyStrong`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/account/presentation/code_screen_test.dart`

**Interfaces:**
- Consumes: `MxTextField(variant: code, autofocus: true)` and `MxTextField.slotKey` from Task 1.
- Produces: `MxTextStyles.emptyBodyStrong`. `l10n.accountCodeSentTo` becomes a getter with no placeholder. New `l10n.accountCodeSpamHint`. `l10n.accountResendIn(time)` keeps its signature with new copy.

- [ ] **Step 1: Write the failing tests** in `code_screen_test.dart`.

  Update the existing tests first:
  - In "six digits sign in and say so", replace the `accountCodeSentTo` expectation with:
    ```dart
    expect(find.text(_en.accountCodeSentTo), findsOneWidget);
    expect(find.text('a@example.com'), findsOneWidget);
    ```
  - In "Resend waits a minute…", replace the first two lines after the pump with:
    ```dart
    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.accountResendIn('1:00')), findsNothing);
    ```
    Keep the last expectation (`find.text(_en.accountResendIn('1:00'))`).

  Then add:

```dart
  accountTest('the code step leads with its title, the address and the spam '
      'hint, and opens on the code', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump();

    expect(find.text(_en.accountCodeTitle), findsOneWidget);
    expect(find.text(_en.accountCodeSpamHint), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('while six digits are checked a spinner takes the wait line, '
      'and nothing under it moves', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    final before = tester.getTopLeft(find.text(_en.accountUseAnotherEmail));

    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.text(_en.accountResendIn('1:00')), findsNothing);
    expect(tester.getTopLeft(find.text(_en.accountUseAnotherEmail)), before);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
  });

  accountTest('a wrong code no longer asks for a new one while the wait runs', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(_en.accountCodeWrong, isNot(contains('new code')));
  });
```

Import `package:memox/shared/widgets/mx_spinner.dart`. If `holdRequests` does not delay `verifyOtp` in `test/support/fake_auth_server.dart`, have `verifyOtp` await `_waitIfHeld()` first, as the other gateway methods do (test support only).

- [ ] **Step 2: Run them to see them fail.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/code_screen_test.dart`. Expected: compile error (`accountCodeSentTo` takes an argument; `accountCodeSpamHint` undefined).

- [ ] **Step 3: Copy.** In `app_en.arb`:
  - `accountCodeSentTo`: "We sent a 6-digit code to". Drop the `placeholders` block from `@accountCodeSentTo` and set its description to "Screen 31: the lead; the address follows on its own line."
  - `accountResendIn`: "New code in {time}". Set its description to "Screen 31: the wait before a new code can be sent, as m:ss; a caption, not a button."
  - `accountCodeWrong`: "That code is wrong or has expired. Check the latest email."
  - Add after `accountUseAnotherEmail`:
    ```json
    "accountCodeSpamHint": "Check your spam folder if it hasn't arrived in a minute.",
    "@accountCodeSpamHint": {
      "description": "Screen 31: the footnote under the code."
    },
    ```

  In `app_vi.arb`:
  - `accountCodeSentTo`: "Mã 6 chữ số đã được gửi tới"
  - `accountResendIn`: "Có thể gửi mã mới sau {time}"
  - `accountCodeWrong`: "Mã sai hoặc đã hết hạn. Hãy xem email mới nhất."
  - `accountCodeSpamHint`: "Nếu sau một phút chưa thấy, hãy xem thư mục spam."

  Then run `flutter gen-l10n`.

- [ ] **Step 4: The style.** In `mx_text_styles.dart`, after `emptyBody`:

```dart
  /// The part of a lead the reader must check, such as the address a code
  /// went to: the lead at 600 in on-surface ink.
  TextStyle get emptyBodyStrong =>
      AppTypography.withWeight(_texts.bodyMedium!, FontWeight.w600).copyWith(
        height: _emptyBodyHeight,
        color: _scheme.onSurface,
      );
```

- [ ] **Step 5: The form.** In `code_form_widget.dart`:
  - Update the class doc to say: "the title, the lead and the address, six slots, a wait line that is a caption while the wait runs, a spinner while six digits are checked, and Resend once it may (sign-in redesign 2026-10-05 §4)".
  - Replace `build`'s returned `Column` with the code below.
  - Add the `_WaitLine` class.

```dart
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.accountCodeTitle, style: styles.screenTitle),
        ),
        const SizedBox(height: AppSpacing.control),
        Text(l10n.accountCodeSentTo, style: styles.emptyBody),
        Text(widget.email, style: styles.emptyBodyStrong),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _code,
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          autofocus: true,
          isEnabled: !state.isVerifying,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null ? null : signInProblemText(l10n, problem),
        ),
        const SizedBox(height: AppSpacing.grouped),
        _WaitLine(
          isVerifying: state.isVerifying,
          wait: state.canResend ? null : _clock(state.resendIn),
          isResending: state.isResending,
          onResend: () => unawaited(_resend()),
        ),
        MxNote.hint(text: l10n.accountCodeSpamHint),
        MxButton(
          label: l10n.accountUseAnotherEmail,
          tone: MxButtonTone.text,
          onPressed: state.isVerifying ? null : widget.onUseAnotherEmail,
        ),
      ],
    );
```

```dart
/// The line under the code, 48 tall at least so its three forms never move
/// what is below: a spinner while the code is checked, the wait as a
/// caption, then "Resend code" once a new code may go (critique 2026-10-05
/// P1: a disabled button read at 1.83:1).
class _WaitLine extends StatelessWidget {
  const _WaitLine({
    required this.isVerifying,
    required this.wait,
    required this.isResending,
    required this.onResend,
  });

  final bool isVerifying;

  /// The time left as m:ss, or null once a new code may be sent.
  final String? wait;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wait = this.wait;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
      child: Center(
        child: switch ((isVerifying, wait)) {
          (true, _) => MxSpinner(semanticLabel: l10n.commonLoading),
          (false, final String time) => Text(
            l10n.accountResendIn(time),
            style: context.textStyles.footerCaption,
          ),
          (false, null) => MxButton(
            label: l10n.accountResend,
            tone: MxButtonTone.text,
            isLoading: isResending,
            onPressed: onResend,
          ),
        },
      ),
    );
  }
}
```

  Imports: `mx_note.dart`, `app_size.dart`.

- [ ] **Step 6: The hosts drop the title.** In `code_screen.dart` and in `_LayerCodePage` (`account_transition_layer_widget.dart`), replace `title: l10n.accountCodeTitle,` with `titleWidget: const SizedBox.shrink(),`. Update `CodeScreen`'s doc to "the app bar holds Back; the step paints its own title".

- [ ] **Step 7: Run the tests.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/code_screen_test.dart test/features/account/presentation/account_transition_layer_test.dart`. Expected: PASS. A layer test that looks up the code title still finds it, because the step paints it.

- [ ] **Step 8: Commit.** `git commit -m "feat(account): the code step leads with its address and waits in a caption (DEV-n)"` with the attribution lines.

---

### Task 3: Screen 30 · sign-in, re-auth and the layer's target sign-in

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart` (the whole page; `_OrDivider` removed)
- Modify: `lib/features/account/presentation/screens/sign_in_screen.dart`
- Modify: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart` (`_LayerPage`, `_TargetSignIn` removed)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/account/presentation/sign_in_screen_test.dart`, `test/features/account/presentation/account_transition_layer_test.dart`

**Interfaces:**
- Produces: `SignInFormWidget({required SignInPurpose purpose, required ValueChanged<String> onCodeSent, Widget? appBar, VoidCallback? onSignedIn, String? initialEmail, bool isEnabled = true, List<Widget> below = const []})`, which returns an `MxAppShell`.
- Produces l10n: `accountEmailHint`, `accountReauthTitle`, `accountContinueWithoutThis` (new); `accountReauthLine`, `accountWithoutTitle` (changed); `accountOr` (removed).

- [ ] **Step 1: Write the failing tests** in `sign_in_screen_test.dart`.

  Update the existing tests first:
  - In "the reauth line, and the last address filled in", change `expect(find.text('a@example.com'), findsOneWidget);` to `findsNWidgets(2)`. The second widget is the eyebrow.
  - In the two "Continue without an account…" re-auth tests, replace `_en.accountContinueWithout` with `_en.accountContinueWithoutThis`, in both the screen taps and the dialog's confirm lookup.

  Then add:

```dart
  accountTest('the two ways sit in the footer, Send code the one fill, and '
      'the form leads with its title', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    Finder inFooter(String text) => find.descendant(
      of: find.byType(MxFooterBar),
      matching: find.text(text),
    );
    expect(inFooter(_en.accountSendCode), findsOneWidget);
    expect(inFooter(_en.accountContinueGoogle), findsOneWidget);
    expect(_button(tester, _en.accountSendCode).tone, MxButtonTone.primary);
    expect(_button(tester, _en.accountContinueGoogle).tone, MxButtonTone.outline);
    expect(find.text(_en.accountSignIn), findsOneWidget);
    expect(find.text(_en.accountEmail), findsOneWidget);
    expect(find.text(_en.accountEmailHint), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);
  });
```

  In the existing "not ready to link" test, add this after its expectations:

```dart
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.text(_en.accountOfflineNote),
      ),
      findsOneWidget,
    );
```

  Inside `group('reauth', …)`:

```dart
    accountTest('re-auth names the account, says why, and keeps its way out '
        'in the body, out of the footer', (tester, env, world) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );
      await _settle(tester);

      expect(find.text(_en.accountReauthTitle), findsOneWidget);
      expect(find.text(_en.accountReauthLine), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MxFooterBar),
          matching: find.text(_en.accountContinueWithoutThis),
        ),
        findsNothing,
      );
      expect(find.text(_en.accountContinueWithoutThis), findsOneWidget);
    });
```

  Add the import `package:memox/shared/widgets/mx_footer_bar.dart`. Add the Review Focus 5 test, which pumps `SignInFormWidget` directly:

```dart
  accountTest('a re-auth whose address is not known yet shows no eyebrow, '
      'then shows it when it lands', (tester, env, world) async {
    await refuseSession(world);
    final email = ValueNotifier<String?>(null);
    addTearDown(email.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      ValueListenableBuilder<String?>(
        valueListenable: email,
        builder: (_, value, _) => SignInFormWidget(
          purpose: SignInPurpose.reauth,
          initialEmail: value,
          onCodeSent: (_) {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    expect(find.text('a@example.com'), findsNothing);

    email.value = 'a@example.com';
    await tester.pump();

    expect(find.text('a@example.com'), findsNWidgets(2));
  });
```

  It imports `sign_in_form_widget.dart`. In `account_transition_layer_test.dart`, find the target sign-in test. If one exists, add the following to it; if none exists, add a test that pumps the layer in the `isAwaitingTargetSignIn` state the golden uses (`Transitioning(_switchAt(TransitionStage.claimed, hint: 'b@example.com'), isAwaitingTargetSignIn: true)`):

```dart
    expect(find.text(_en.commonCancel), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.text(_en.accountSendCode),
      ),
      findsOneWidget,
    );
```

- [ ] **Step 2: Run them to see them fail.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/sign_in_screen_test.dart test/features/account/presentation/account_transition_layer_test.dart`. Expected: compile errors (the new l10n getters are undefined).

- [ ] **Step 3: Copy.** In `app_en.arb`:
  - `accountReauthLine`: "This phone was signed out, so syncing paused. Your decks are still here."
  - `accountWithoutTitle`: "Continue without this account?"
  - Delete `accountOr` and `@accountOr`.
  - Add, with descriptions:
    - `accountEmailHint`: "name@example.com" ("Screen 30: the email field's hint.")
    - `accountReauthTitle`: "Sign in again" ("Screen 30, re-auth: the title.")
    - `accountContinueWithoutThis`: "Continue without this account" ("Screen 30, re-auth: the way out under the form and its dialog's confirm; Welcome keeps accountContinueWithout.")

  In `app_vi.arb`:
  - `accountReauthLine`: "Điện thoại này đã bị đăng xuất nên việc đồng bộ tạm dừng. Bộ thẻ vẫn còn ở đây."
  - `accountWithoutTitle`: "Tiếp tục không dùng tài khoản này?"
  - Delete `accountOr`.
  - Add `accountEmailHint` "ten@example.com", `accountReauthTitle` "Đăng nhập lại", `accountContinueWithoutThis` "Tiếp tục không dùng tài khoản này".

  Then run `flutter gen-l10n`.

- [ ] **Step 4: The page.** In `sign_in_form_widget.dart`:
  - Add the fields `appBar` (`/// The top bar: Back on screen 30, Cancel in the layer.`) and `below` (`/// What sits under the field, such as re-auth's way out (S9).`).
  - Update the class doc: "The sign-in page of screen 30 and of the transition layer (sign-in redesign 2026-10-05 §3): the title, the lead and the address in the body; Send code, the one fill, and Google in the footer, above the keyboard."
  - Replace `build` with the code below and delete `_OrDivider`.
  - Imports: `mx_app_shell.dart`, `mx_footer_bar.dart`, `mx_screen_scroll.dart`. Drop `app_stroke.dart` if it becomes unused.

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final state = ref.watch(signInControllerProvider(widget.purpose));
    final canAct = widget.isEnabled && !state.isRunning;
    final fieldProblem = state.problemTask == SignInTask.email
        ? state.problem
        : null;
    final isReauth = widget.purpose == SignInPurpose.reauth;
    // S9: re-auth names the account it signs in again to.
    final eyebrow = isReauth ? widget.initialEmail : null;
    // Plan ruling 6: only a link waits for the account to be ready.
    final isWaiting =
        !widget.isEnabled && widget.purpose == SignInPurpose.link;
    return MxAppShell(
      appBar: widget.appBar,
      body: MxScreenScroll(
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow, style: styles.eyebrow),
            const SizedBox(height: AppSpacing.micro),
          ],
          Semantics(
            header: true,
            child: Text(
              isReauth ? l10n.accountReauthTitle : l10n.accountSignIn,
              style: styles.screenTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Text(switch (widget.purpose) {
            SignInPurpose.link => l10n.accountLinkLine,
            SignInPurpose.target => l10n.accountTargetLine,
            SignInPurpose.reauth => l10n.accountReauthLine,
          }, style: styles.emptyBody),
          const SizedBox(height: AppSpacing.section),
          // The field announces the same label; TalkBack reads it once.
          ExcludeSemantics(
            child: Text(l10n.accountEmail, style: styles.fieldLabel),
          ),
          const SizedBox(height: AppSpacing.control),
          MxTextField(
            controller: _email,
            label: l10n.accountEmail,
            hintText: l10n.accountEmailHint,
            isEnabled: widget.isEnabled,
            textInputAction: TextInputAction.send,
            onSubmitted: canAct ? (_) => unawaited(_send()) : null,
            errorText: fieldProblem == null
                ? null
                : signInProblemText(l10n, fieldProblem),
          ),
          ...widget.below,
        ],
      ),
      footer: MxFooterBar(
        caption: isWaiting ? l10n.accountOfflineNote : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            MxButton(
              label: l10n.accountSendCode,
              isBlock: true,
              isLoading: state.task == SignInTask.email,
              onPressed: canAct ? () => unawaited(_send()) : null,
            ),
            MxButton(
              label: l10n.accountContinueGoogle,
              tone: MxButtonTone.outline,
              mark: googleMark,
              isBlock: true,
              isLoading: state.task == SignInTask.google,
              onPressed: canAct ? () => unawaited(_google()) : null,
            ),
          ],
        ),
      ),
    );
  }
```

  `find.text(_en.accountEmail)` still matches the painted label inside `ExcludeSemantics`.

- [ ] **Step 5: Screen 30.** In `sign_in_screen.dart`:
  - `build` returns the `SignInFormWidget` below instead of the `MxAppShell`.
  - `_leave`'s `confirmLabel` becomes `l10n.accountContinueWithoutThis`.
  - Drop the imports that become unused (`mx_app_shell`, `mx_note`, `mx_screen_scroll`).

```dart
    return SignInFormWidget(
      appBar: MxAppBar(
        titleWidget: const SizedBox.shrink(),
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      purpose: purpose,
      isEnabled: canAct,
      initialEmail: isReauth ? ref.watch(deviceAccountProvider)?.email : null,
      onCodeSent: onCodeSent,
      onSignedIn: () {
        saySignedIn(context, stateAfterCommand(ref));
        onSignedIn();
      },
      below: [
        // S9: the way out sits in the body, 32 under the form, out of the
        // footer's thumb path.
        if (isReauth) ...[
          const SizedBox(height: AppSpacing.major),
          MxButton(
            label: l10n.accountContinueWithoutThis,
            tone: MxButtonTone.text,
            isBlock: true,
            onPressed: canAct && !isLeaving
                ? () => unawaited(_leave(context, ref))
                : null,
          ),
        ],
      ],
    );
```

- [ ] **Step 6: The layer.** In `_LayerPage.build` (`account_transition_layer_widget.dart`):
  - Build the Cancel bar once: `final appBar = canCancel ? MxAppBar(...) : null;`, with the current contents.
  - Then use the code below, and delete `_TargetSignIn`.
  - Its doc line moves onto the `if`: "The target sign-in: the address, then the code on the layer's navigator (§3.3)."

```dart
    if (isSigningIn) {
      return SignInFormWidget(
        appBar: appBar,
        purpose: SignInPurpose.target,
        initialEmail: view.transition.targetHint,
        onCodeSent: (email) => unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _LayerCodePage(email)),
          ),
        ),
      );
    }
    return MxAppShell(
      appBar: appBar,
      body: SafeArea(child: _Progress(view: view)),
    );
```

- [ ] **Step 7: Run the tests.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/sign_in_screen_test.dart test/features/account/presentation/account_transition_layer_test.dart test/features/account/presentation/welcome_screen_test.dart`. Expected: PASS. Welcome still opens screen 30 by callback, so its tests are unaffected.

- [ ] **Step 8: Commit.** `git commit -m "feat(account): sign-in leads with its title and keeps its ways in the footer (DEV-n)"` with the attribution lines.

---

### Task 4: Screen 29 · Welcome

**Files:**
- Modify: `lib/features/account/presentation/screens/welcome_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/account/presentation/welcome_screen_test.dart`

**Interfaces:**
- Produces l10n: `welcomeLead` (changed); `welcomeBenefitOffline` (removed).

- [ ] **Step 1: Write the failing tests.** In `welcome_screen_test.dart`, replace the body of "first launch offline: sign-in waits and says why, and without still leaves (Review Focus 1)" after the pump with:

```dart
    expect(find.text(_en.accountContinueGoogle), findsNothing);
    expect(find.text(_en.accountContinueEmail), findsNothing);
    final without = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.accountContinueWithout),
    );
    expect(without.tone, MxButtonTone.primary);
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.text(_en.accountOfflineNote),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(_en.accountContinueWithout));
    await _settle(tester);
    expect(dones, 1);
```

  Add:

```dart
  accountTest('the lead says MemoX works without an account, and two '
      'benefits follow', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    expect(find.text(_en.welcomeLead), findsOneWidget);
    expect(find.text(_en.welcomeBenefitReinstall), findsOneWidget);
    expect(find.text(_en.welcomeBenefitPhones), findsOneWidget);
    expect(find.byType(MxSettingsRow), findsNWidgets(2));
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.accountContinueGoogle),
          )
          .tone,
      MxButtonTone.primary,
    );
  });

  accountTest('when the account becomes ready, the three ways come back '
      '(Review Focus 4)', (tester, env, world) async {
    final auth = ValueNotifier<AuthState>(const LocalOnly());
    addTearDown(auth.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        shown,
        authStateOfListenable(auth),
      ],
    );
    expect(find.text(_en.accountContinueGoogle), findsNothing);

    auth.value = world.state;
    await _settle(tester);

    expect(find.text(_en.accountContinueGoogle), findsOneWidget);
    expect(find.text(_en.accountContinueEmail), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);
  });
```

  The second test needs `authStateOfListenable`. Look in `test/support/account_harness.dart` for a helper that drives `authStateProvider` from a changing value. If there is none, add one next to `authStateOf` in that file, overriding `authStateProvider` with a stream of the notifier's values:

```dart
/// Overrides the auth state with [state]'s values as they change.
Override authStateOfListenable(ValueListenable<AuthState> state) =>
    authStateProvider.overrideWith((ref) {
      final controller = StreamController<AuthState>();
      void push() => controller.add(state.value);
      state.addListener(push);
      push();
      ref.onDispose(() {
        state.removeListener(push);
        unawaited(controller.close());
      });
      return controller.stream;
    });
```

  Follow the shape of the existing `authStateOf`. If `authStateProvider` is not a `StreamProvider`, override it the way `authStateOf` does. `world.state` is the ready state the harness exposes; use whatever `authStateOf` is normally given for "can link".

  Imports: `mx_footer_bar.dart`, `mx_settings_row.dart`, `auth_state.dart`, `package:flutter/foundation.dart`.

- [ ] **Step 2: Run them to see them fail.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/welcome_screen_test.dart`. Expected: FAIL. The offline test still finds Google, and there are three `MxSettingsRow`.

- [ ] **Step 3: Copy.**
  - `app_en.arb`: `welcomeLead` becomes "MemoX works on this phone without an account, offline too. Signing in adds:". Delete `welcomeBenefitOffline` and its `@` entry.
  - `app_vi.arb`: `welcomeLead` becomes "MemoX dùng được trên điện thoại này mà không cần tài khoản, cả khi không có mạng. Đăng nhập thêm cho bạn:". Delete `welcomeBenefitOffline`.
  - Run `flutter gen-l10n`.

- [ ] **Step 4: The screen.** In `welcome_screen.dart`:
  - Delete the offline `MxSettingsRow` and the `if (!canLink) MxNote(...)` line. Drop the `mx_note.dart` import.
  - Replace `footer:` with the code below.
  - Update the class doc to: "…the name, an honest lead and two benefits on top; the ways on in the thumb zone: Google, the one fill, while the account can link; otherwise only "Continue without an account", the one usable way, with the note under it (sign-in redesign 2026-10-05 S10)."

```dart
      footer: MxFooterBar(
        caption: canLink ? null : l10n.accountOfflineNote,
        child: canLink
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.grouped,
                children: [
                  MxButton(
                    label: l10n.accountContinueGoogle,
                    mark: googleMark,
                    isBlock: true,
                    isLoading: isRunning,
                    onPressed: canSignIn
                        ? () => unawaited(_google(context, ref))
                        : null,
                  ),
                  MxButton(
                    label: l10n.accountContinueEmail,
                    tone: MxButtonTone.outline,
                    isBlock: true,
                    onPressed: canSignIn ? () => _leave(ref, onEmail) : null,
                  ),
                  without(MxButtonTone.text),
                ],
              )
            : without(MxButtonTone.primary),
      ),
```

  with this local function declared in `build`, just before `return MxAppShell(`:

```dart
    // "Continue without an account": the quiet skip beside the ways in, or
    // the one fill when none of them can be used (S10).
    MxButton without(MxButtonTone tone) => MxButton(
      label: l10n.accountContinueWithout,
      tone: tone,
      isBlock: true,
      onPressed: isRunning ? null : () => _leave(ref, onDone),
    );
```

- [ ] **Step 5: Run the tests.** Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/account/presentation/welcome_screen_test.dart`. Expected: PASS.

- [ ] **Step 6: Commit.** `git commit -m "feat(account): Welcome tells the truth offline and keeps one usable way (DEV-n)"` with the attribution lines.

---

### Task 5: Records, goldens and the gate

**Files:**
- Modify: `docs/shared/ui/screen-handoff/29-welcome.md`, `30-sign-in.md`, `31-code.md`, `00-index.md` (rows 29–31)
- Modify: `DESIGN.md` (One Indigo Rule: the S7 sentence)
- Modify: `docs/superpowers/specs/2026-09-30-account-ui-design.md` (pointers at §5.1, §5.2, §6)
- Regenerate: the goldens listed in spec §8 (`test/features/account/presentation/goldens/`, `test/shared/widgets/goldens/mx_text_field_code_*`)

- [ ] **Step 1: Detail files.** Rewrite the Layout tables of 29, 30 (link, re-auth, transition layer target row) and 31 to match spec §3–§5 exactly.
  - Add a ruling bullet to each: "**Sign-in redesign 2026-10-05 (spec `2026-10-05-sign-in-flow-redesign-design.md`, S1–S10):** …", with one line naming what changed on that screen.
  - In 30, the F1 ruling gains: "the target sign-in follows the sign-in frame; F1 holds for the running, error and stuck states".
  - Update each Copy section to spec §6.
  - In `00-index.md`, update the one-line description of rows 29–31 if it names layout that changed.

- [ ] **Step 2: DESIGN.md and the account spec.**
  - Under **The One Indigo Rule**, append: "A screen that asks *which way* fills its first way (Welcome: Google); a screen for one way fills that way's commit and outlines the other (Sign-in: Send code, then Google) (sign-in redesign 2026-10-05, S7)."
  - In `2026-09-30-account-ui-design.md`, add at the top of §5.1, §5.2 and §6: "> Layout amended by `2026-10-05-sign-in-flow-redesign-design.md`."

- [ ] **Step 3: The gate.** Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`. Fix any format, analyze, guard or docs finding in place, then re-run once.

- [ ] **Step 4: Goldens.**
  - Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`.
  - Run `git status --short -- 'test/**/goldens/*.png'`. Expected: only the files in spec §8 change. Any other changed PNG is a regression: find its cause before going on.
  - Open each changed light and dark PNG with the Read tool and check it against spec §3–§5.
  - Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (compare). Expected: PASS.

- [ ] **Step 5: Auth integration run.** Run `bash tools/supabase/run_auth_it.sh`. If Docker is missing in the container, record "not run: no Docker" in the ledger and in the PR. Never pass it silently.

- [ ] **Step 6: Commit.** `git commit -m "docs(account): sign-in redesign records and goldens (DEV-n)"` with the attribution lines. Then push: `git push -u origin claude/nifty-maxwell-nz5nl3`.

After this task, CLAUDE.md's screen workflow continues outside the plan:
1. Impeccable critique and audit of the new goldens against DESIGN.md, with one fix batch and its one audit.
2. The final whole-branch review on Opus.
3. The golden review page (`golden-compare`) for the owner, before any merge.

---

## Ledger

| Task | Linear | Status | Notes |
|---|---|---|---|
| 1 · code field six slots | DEV-n | | |
| 2 · screen 31 | DEV-n | | |
| 3 · screen 30, re-auth, layer | DEV-n | | |
| 4 · screen 29 | DEV-n | | |
| 5 · records, goldens, gate | DEV-n | | |
