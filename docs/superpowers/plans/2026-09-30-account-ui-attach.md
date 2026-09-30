# Account UI, attach flow (P3a) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A person can attach an email or Google account to the device's anonymous user from a first-launch Welcome (29) or from Settings › Account (23), through Sign-in (30) and Code (31). A second device merges or discards its data through the merge sheet, and every account transition shows a blocking layer at the app root.

**Architecture:**
- **New feature.** `lib/features/account/` follows ADR-011:
  - `domain/` and `data/` hold only the device-local reads, which are the welcome flag and the library counts, behind a repository contract and three use cases.
  - `presentation/` sends commands straight to P2's `AccountCoordinator` (as `settings` does with `SyncCommands`) and reads `authStateProvider`.
- **Wiring in `app/`.**
  - The router adds Welcome as a top-level route and puts Sign-in and Code under `/settings`.
  - A two-rule redirect refreshes on the welcome flag and the account.
  - `MaterialApp.router`'s `builder` hosts the transition layer above the router, with its own `Navigator` and a child back-button dispatcher.
- **Shared.** Two widgets change: `MxButton` gains a `text` tone and a brand `mark`, and `MxTextField` gains a `code` variant (U2, U6).

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3.4 (codegen, `.g.dart` gitignored and generated with `dart run build_runner build --delete-conflicting-outputs`), go_router, Drift 2.35, fake_async.

**Spec:**
- Binding: `docs/superpowers/specs/2026-09-30-account-ui-design.md` (the addendum), with its rulings U1–U6 and R1–R6, §4 (router), §5.1–§5.5 and §6 (shape).
- Background: `docs/superpowers/specs/2026-09-30-auth-design.md` §3 (the state machine P2 built), which the addendum overrides in §7 and §8.
- Row P3a of the addendum's §7 is this plan's scope. P3b (screen 32, re-auth, sign-out and delete UI) is a later plan.

## Global Constraints

- **UI authority:** `DESIGN.md` and the reviewed goldens (ADR-019).
  - One primary fill per decision: Google on 29, "Send code" on 30, the confirm on the merge sheet, and Retry on the layer.
  - Copy comes only from `context.l10n`, and components hold no copy.
  - Failure copy is local-first: it says what is safe first.
- **Layers (ADR-011, `flutter-architecture`):**
  - presentation imports its own `domain/` and `di/`, `core/` and `shared/`, never `data/`;
  - every local read or write goes through one use case;
  - account commands go to `accountCoordinatorProvider` (core);
  - `test/architecture/boundary_rules.dart` gains `'account': {}`;
  - file suffixes follow `check_architecture.py`.
- **No cross-feature imports.** Settings takes the account section as a slot, which `app/` composes, as it does for `adminSection`.
- **Strings:** every key in `app_en.arb` has a `description` and a Vietnamese value in `app_vi.arb`. Run `flutter gen-l10n` after changing them, because `lib/l10n/generated` is untracked.
- **Tests:**
  - each run is at the default text scale (DESIGN.md Wrap Rule, R4);
  - goldens are English, light and dark, captured at 1080×2400 (3x) and tagged `golden`;
  - `no_real_clock_in_test`: no `DateTime.now()` in tests.
- **Task gate, per task:**
  - `dart format --output=none --set-exit-if-changed lib test`
  - `flutter analyze`
  - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
  - `python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8`
  - `flutter test <the task's test files> --exclude-tags golden`
- **Whole suite:** Task 13 runs it once, in the background (about 9 minutes).
- **Goldens:** rendered in this Linux container with `TZ=UTC` (the same image as `.claude/skills/flutter-testing/scripts/golden.Dockerfile`). Task 12 first proves parity: the existing goldens pass untouched before any is updated.
- **Commits:** end each message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2`. No model id appears anywhere else.
- **Files:** `max_file_lines` is 500 (an error); `no_large_source_file` is 400 (a warning, to avoid).

## Rulings made while planning

1. **Routes under Settings.** Sign-in is `/settings/sign-in?mode=link` and Code is `/settings/sign-in/code?mode=link&email=…`, both children of `/settings` on the root navigator, like Sync.
   - Reason: Back from the attach flow lands on Settings, and Welcome's email exit is one `go`.
   - The addendum's `/account/...` names are replaced.
   - Cost if wrong: two path constants.
2. **The link flow ends on `/settings`.** It gets there by an explicit `go`, and the redirect handles a deep link or a refresh. P3b moves both to `/settings/account` (32).
   - Cost if wrong: one constant.
3. **Welcome needs a build that can sign in.** `WelcomeDue` starts `false`, and `main` shows it only when the coordinator exists and `welcome_seen` is 0. No existing app test changes.
   - Cost if wrong: none; U1 still holds on real builds.
4. **Welcome's email exit** dismisses Welcome, then goes to Sign-in, with Settings under it. `from` is kept by the Google and "without" exits only.
   - Cost if wrong: the person lands on Settings after Back instead of the Library.
5. **The account row's subtitle** is "Your decks sync to this account": `me()` carries no sign-in method (`AccountUser` has none). P3b decides the method's source for screen 32.
   - Cost if wrong: one string.
6. **Offline or not ready yet.** Linking needs `Ready(anonymous)` (P2 throws `StateError` otherwise).
   - Welcome shows its sign-in buttons disabled with a note, and keeps "Continue without an account".
   - The Settings row is disabled with "Available when you're online".
   - Cost if wrong: copy.
7. **The email field keeps the form variant's text keyboard.** U2 approved only the `code` variant. An email variant is recorded as UI-base debt.
   - Cost if wrong: a keyboard type.
8. **Notices in P3a are snackbars, `DeleteRefused(LastAdmin)` included.** It is reachable only from P3b's delete, and P3b may make it a dialog.
   - Cost if wrong: one widget.
9. **Back while the layer shows.** A `PopScope` in the layer never sees the system Back, because the router's root dispatcher handles it first.
   - The layer host takes a `ChildBackButtonDispatcher` with priority on `GoRouter.backButtonDispatcher`.
   - Back pops the layer's inner navigator (code to form) and never leaves the layer.
   - Cost if wrong: a Back that navigates under the layer.
10. **Count failure.** When the library count fails, the merge sheet still shows, with a body that has no numbers.
    - Cost if wrong: one string.
11. **A wrong code clears the field**, so six fresh digits submit again.
    - Cost if wrong: retyping.
12. **Google identity-taken title.** The UI never sees the Google email, so the title reads "This Google account is already in use".
    - Cost if wrong: one string.
13. **The admin gate while `Booting`, `Bootstrapping` or `Validating`** shows a loading skeleton instead of "only an admin" (addendum §4).
    - Cost if wrong: a flash of the refusal.
14. **The discard warning** on the merge sheet is an `MxInlineBanner` in the danger tone, not the `MxNote` of addendum §5.3: something is lost there, and `MxNote` is one calm info line (`DESIGN.md`).
    - Cost if wrong: one widget.

## Review Focus

1. **First launch offline.** With `LocalOnly` or `Bootstrapping`, Welcome's sign-in buttons are disabled with the note, and "Continue without an account" still leaves (Task 9 test).
2. **System Back under the layer.** `handlePopRoute` while the layer shows keeps the page under it, and it pops the layer's code page back to the form (Task 10 test).
3. **Double tap.** A second "Send code" or Google press while one runs sends nothing (Task 5 test).
4. **Wrong, then right.** A wrong code clears the field and says so, and six correct digits then sign in (Task 8 test).
5. **Deep link while Welcome is due.** `/progress` becomes `/welcome?from=%2Fprogress`, and "Continue without an account" lands on Progress (Task 11 test).

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/shared/widgets/mx_button.dart` | `text` tone, brand `mark` | 1 |
| `lib/core/theme/foundations/app_icon_size.dart` | `brandMark = 18` | 1 |
| `assets/brand/google_g.png` (+ `2.0x/`, `3.0x/`, `4.0x/`), `pubspec.yaml` | Google's G, rendered from the official path | 1 |
| `lib/shared/widgets/mx_text_field.dart`, `lib/core/theme/mx_text_styles.dart` | `code` variant, `fieldCode` style | 2 |
| `DESIGN.md` | the two shared changes | 1, 2 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | every account string | 3 |
| `lib/core/theme/foundations/app_icons.dart` | `account`, `devices` | 3 |
| `lib/features/account/domain/...` | `LocalLibrary`, `AccountDeviceRepository`, 3 use cases | 3 |
| `lib/features/account/data/...` | `AccountDeviceDao`, `AccountDeviceRepositoryImpl` | 3 |
| `lib/features/account/di/account_device_repository_provider.dart` | binding | 3 |
| `lib/features/account/presentation/providers/*_use_case_provider.dart` | use-case providers | 3 |
| `lib/features/account/presentation/providers/welcome_due_provider.dart`, `lib/app/startup_welcome.dart`, `lib/main.dart` | the welcome flag in memory, read before the first frame | 4 |
| `lib/features/account/presentation/states/sign_in_state.dart`, `.../controllers/sign_in_controller.dart` | link and target sign-in commands | 5 |
| `lib/features/account/presentation/widgets/support/account_copy_widget.dart`, `.../providers/can_link_provider.dart` | problem, step and success copy; `googleMark`; whether a link can start | 5, 10 |
| `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart`, `.../screens/sign_in_screen.dart` | form and screen 30 | 7 |
| `.../states/code_state.dart`, `.../controllers/code_controller.dart`, `.../sections/code_form_widget.dart`, `.../screens/code_screen.dart` | screen 31 | 8 |
| `.../overlays/merge_choice_sheet_widget.dart` | #17's choice | 6 |
| `.../screens/welcome_screen.dart` | screen 29 | 9 |
| `.../states/account_step_state.dart`, `.../providers/unsent_count_provider.dart`, `.../sections/account_transition_layer_widget.dart`, `.../sections/account_layer_host_widget.dart` | the layer and notices | 10 |
| `lib/app/router/app_routes.dart`, `lib/app/router/account_redirect.dart`, `lib/app/router/app_router.dart`, `lib/app/app.dart` | routes, redirect, refresh, layer host | 11 |
| `.../sections/account_settings_section_widget.dart`, `settings_screen.dart`, `monitoring_admin_gate_widget.dart` | 23's Account section; admin gate loading | 11 |
| `test/support/account_harness.dart`, `test/support/fake_auth_server.dart` | account widget tests on `AuthWorld`; a rate-limit hook | 5 |
| goldens and golden tests | every new surface, light and dark | 12 |
| `docs/...` | detail files, index, WBS, UI-base register | 13 |

---

### Task 1: `MxButton` text tone and brand mark (U2, U6)

**Files:**
- Modify: `lib/shared/widgets/mx_button.dart`
- Modify: `lib/core/theme/foundations/app_icon_size.dart`
- Create: `assets/brand/google_g.png`, `assets/brand/2.0x/google_g.png`, `assets/brand/3.0x/google_g.png`, `assets/brand/4.0x/google_g.png`
- Modify: `pubspec.yaml` (assets)
- Modify: `DESIGN.md` (frontmatter `button-text`, Actions line)
- Test: `test/shared/widgets/mx_button_test.dart`

**Interfaces:**
- Produces:
  - `MxButtonTone.text`;
  - `MxButton({..., ImageProvider? mark})` (asserts `icon == null || mark == null`);
  - `AppIconSize.brandMark` (18);
  - the asset `assets/brand/google_g.png`.

- [ ] **Step 1: Render the G mark.** Headless Chromium renders Google's official G path (48×48 viewBox) with a transparent ground at 18, 36, 54 and 72 px:

```bash
S=/tmp/claude-0/-home-user-memox-v8/145740b4-0fc1-50a5-8b05-262c0c57b91d/scratchpad
cat > $S/g.html <<'EOF'
<!doctype html><html><head><style>html,body{margin:0;background:transparent}svg{display:block;width:100vw;height:100vh}</style></head><body><svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg></body></html>
EOF
SHELL_BIN=/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell
mkdir -p assets/brand/2.0x assets/brand/3.0x assets/brand/4.0x
for pair in ".:18" "2.0x:36" "3.0x:54" "4.0x:72"; do
  dir=${pair%%:*}; px=${pair##*:}
  $SHELL_BIN --no-sandbox --hide-scrollbars --default-background-color=00000000 \
    --window-size=$px,$px --screenshot=assets/brand/$dir/google_g.png file://$S/g.html 2>/dev/null
done
file assets/brand/google_g.png assets/brand/*/google_g.png
```

Expected: four PNGs, sized `18 x 18`, `36 x 36`, `54 x 54` and `72 x 72`, RGBA. Open the 72 px one with the Read tool and confirm the four-colour G on a transparent ground.

- [ ] **Step 2: Register the asset** in `pubspec.yaml` under `flutter: assets:`, after the templates:

```yaml
    # Google's G for "Continue with Google" (account UI spec U6), rendered
    # from the official path at 1x–4x; Flutter picks the density variant.
    - assets/brand/
```

- [ ] **Step 3: Write the failing tests** at the end of `main()` in `test/shared/widgets/mx_button_test.dart`:

```dart
  testWidgets('text tone has no fill and no edge, in primaryInk', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Skip', tone: MxButtonTone.text, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, MxDerivedColors.primaryInkOf(scheme));
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide.none,
    );
  });

  testWidgets('a brand mark is painted at 18 in the icon\'s place, and '
      'TalkBack reads the label only', (tester) async {
    await pumpMx(
      tester,
      MxButton(
        label: 'Continue with Google',
        mark: const AssetImage('assets/brand/google_g.png'),
        onPressed: () {},
      ),
    );
    final image = find.byType(Image);

    expect(tester.getSize(image), const Size.square(18));
    expect(tester.widget<Image>(image).excludeFromSemantics, isTrue);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
  });

  testWidgets('naturalWidth counts the brand mark and its gap', (
    tester,
  ) async {
    late double plain;
    late double marked;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          plain = MxButton(label: 'Go', onPressed: () {}).naturalWidth(context);
          marked = MxButton(
            label: 'Go',
            mark: const AssetImage('assets/brand/google_g.png'),
            onPressed: () {},
          ).naturalWidth(context);
          return const SizedBox();
        },
      ),
    );

    expect(marked - plain, 18 + 4);
  });
```

- [ ] **Step 4: Run them.**

Run: `flutter test test/shared/widgets/mx_button_test.dart --plain-name "text tone"`
Expected: a compile failure: `MxButtonTone.text` and `mark` are not defined.

- [ ] **Step 5: Implement.**

In `lib/core/theme/foundations/app_icon_size.dart`, add after `inline`:

```dart
  /// A brand's mark on a button, such as Google's G (account UI spec U6):
  /// the size its guidelines set beside a label.
  static const double brandMark = 18;
```

In `lib/shared/widgets/mx_button.dart`:

1. Add the tone to the enum, after `outline`, and extend the enum's doc comment with "and the quiet `text` action beside a decision's fill (account UI spec U2)":

```dart
  outline,
  text,
```

2. Add the parameter to the constructor, after `this.icon,`: `this.mark,`. Extend the initializer list, so the existing `assert(detail == null || …)` is followed by:

```dart
       assert(icon == null || mark == null, 'a glyph or a mark, not both');
```

3. Add the field after `icon`:

```dart
  /// A brand's own mark in place of [icon], such as Google's G (account UI
  /// spec U6), painted at [AppIconSize.brandMark] and never read aloud: the
  /// label names the action.
  final ImageProvider? mark;
```

4. In `build` and `naturalWidth`, pass `hasIcon: icon != null || mark != null` to `_geometryFor`.

5. In `naturalWidth`, replace the `iconWidth` line:

```dart
    final leadWidth = switch ((icon, mark)) {
      (_?, _) => AppIconSize.inline + AppSpacing.micro,
      (_, _?) => AppIconSize.brandMark + AppSpacing.micro,
      _ => 0.0,
    };
    final width = painter.width + leadWidth + geometry.padding * 2;
```

6. In `_paintFor`, add after the `outline` arm:

```dart
      // The quiet action beside a decision's fill (account UI spec U2): the
      // outline's ink without its edge.
      MxButtonTone.text => (
        fill: null,
        ink: context.derivedColors.primaryInk,
        edge: BorderSide.none,
      ),
```

7. In `_content`, replace the `body` expression:

```dart
    final lead = _lead();
    final body = lead == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [lead, Flexible(child: text)],
          );
```

   Then add the method under `_content`:

```dart
  /// The glyph or the brand mark before the label, if any.
  Widget? _lead() {
    if (icon case final glyph?) return Icon(glyph, size: AppIconSize.inline);
    if (mark case final image?) {
      return Image(
        image: image,
        width: AppIconSize.brandMark,
        height: AppIconSize.brandMark,
        excludeFromSemantics: true,
      );
    }
    return null;
  }
```

- [ ] **Step 6: Run the button tests.**

Run: `flutter test test/shared/widgets/mx_button_test.dart`
Expected: all pass, the three new ones included.

- [ ] **Step 7: Update `DESIGN.md`.**
   - In the frontmatter `components:`, after the `button-outline:` block:

```yaml
  button-text:
    textColor: "{colors.primary}"
    typography: "{typography.button-label}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 16px"
```

   - In `### Actions`, the MxButton line's first sentence becomes: "**MxButton**: tones primary, secondary, outline, text (no fill and no edge, Indigo Ink: the quiet action beside a decision's fill), destructive, dangerSoft, warning; …".
   - Add, before "`isLoading` swaps…": "an optional brand mark (an image at 18 in the icon's place, such as Google's G, never read aloud),".

- [ ] **Step 8: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/shared/widgets/mx_button.dart lib/core/theme/foundations/app_icon_size.dart assets/brand pubspec.yaml DESIGN.md test/shared/widgets/mx_button_test.dart
git commit -m "feat(shared): MxButton text tone and brand mark (account UI U2, U6)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

Expected: analyze and the checks clean. The shared golden `mx_button_*.png` gains the `text` tone row; it is regenerated in Task 12.

---

### Task 2: `MxTextField` code variant (U2)

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart`
- Modify: `lib/core/theme/mx_text_styles.dart`
- Modify: `lib/app/gallery/gallery_inputs_section.dart`
- Modify: `DESIGN.md` (Inputs line)
- Test: `test/shared/widgets/mx_text_field_test.dart`, `test/shared/widgets/input_widgets_golden_test.dart`

**Interfaces:**
- Produces:
  - `MxTextFieldVariant.code`;
  - `MxTextField.codeLength` (6);
  - `MxTextStyles.fieldCode`.

- [ ] **Step 1: Write the failing tests** at the end of `main()` in `test/shared/widgets/mx_text_field_test.dart` (reuse that file's imports; add `import 'package:flutter/services.dart';` if absent):

```dart
  testWidgets('the code variant asks for digits, offers the one-time code '
      'and centres them', (tester) async {
    await pumpMx(
      tester,
      const MxTextField(label: 'Code', variant: MxTextFieldVariant.code),
    );
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
    expect(field.textAlign, TextAlign.center);
    expect(field.maxLines, 1);
  });

  testWidgets('the code variant keeps six digits and nothing else', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      MxTextField(controller: controller, variant: MxTextFieldVariant.code),
    );

    await tester.enterText(find.byType(TextField), '12a3456789');

    expect(controller.text, '123456');
    expect(MxTextField.codeLength, 6);
  });
```

- [ ] **Step 2: Run them.**

Run: `flutter test test/shared/widgets/mx_text_field_test.dart --plain-name "code variant"`
Expected: a compile failure: `MxTextFieldVariant.code` is not defined.

- [ ] **Step 3: Add the style.** In `lib/core/theme/mx_text_styles.dart`, add under `fieldTermHint`, with the constant beside the other private constants:

```dart
  static const double _codeTracking = 6;

  /// A sign-in code (account UI spec §6): the headline role, tabular
  /// figures and wide tracking, so six digits read as one code.
  TextStyle get fieldCode => _texts.headlineSmall!.copyWith(
    letterSpacing: _codeTracking,
    fontFeatures: _tabular,
    color: _scheme.onSurface,
  );
```

- [ ] **Step 4: Implement the variant** in `lib/shared/widgets/mx_text_field.dart`:

1. Add `import 'package:flutter/services.dart';`.
2. Add to the enum, after `study`:

```dart
  /// A sign-in code (account UI spec U2): one centred line of six digits
  /// on the form fill, the numeric keyboard, the platform's one-time-code
  /// autofill.
  code,
```

3. Add under `_termLongAt`:

```dart
  /// The digits a sign-in code holds (auth spec O1).
  static const int codeLength = 6;
```

4. Add the `_geometry` arm:

```dart
    MxTextFieldVariant.code => (
      floor: AppSize.input,
      horizontal: AppSpacing.grouped,
      vertical: 0,
      radius: AppRadius.md,
      isMultiline: false,
    ),
```

5. Add the `_valueStyle` arm: `MxTextFieldVariant.code => styles.fieldCode,`.
6. In `_field`, after `final isBare = …`:

```dart
    final isCode = variant == MxTextFieldVariant.code;
```

7. In `_field`, change the fill line to `fillColor: isForm || isCode ? null : colors.surfaceContainerLowest,`.
8. In `TextField(...)`, change `textAlign` to `isBare || isCode ? TextAlign.center : TextAlign.start`, add the `code` arm `MxTextFieldVariant.code => TextInputType.number,` to the `keyboardType` switch, and add:

```dart
      inputFormatters: isCode
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(codeLength),
            ]
          : null,
      autofillHints: isCode ? const [AutofillHints.oneTimeCode] : null,
```

- [ ] **Step 5: Run the field tests.**

Run: `flutter test test/shared/widgets/mx_text_field_test.dart`
Expected: all pass.

- [ ] **Step 6: Add the golden case, the gallery entry and the design line.**
   - In `test/shared/widgets/input_widgets_golden_test.dart`, after the `'MxTextField states and MxFieldMessage tones'` test:

```dart
  testWidgets('MxTextField code variant', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_text_field_code',
      Column(
        spacing: 16,
        children: [
          const MxTextField(variant: MxTextFieldVariant.code),
          MxTextField(
            controller: TextEditingController(text: '123456'),
            variant: MxTextFieldVariant.code,
          ),
          MxTextField(
            controller: TextEditingController(text: '000000'),
            variant: MxTextFieldVariant.code,
            errorText: "That code is wrong or has expired.",
          ),
        ],
      ),
    );
  });
```

   - In `lib/app/gallery/gallery_inputs_section.dart`, after the `term` field:

```dart
      const MxTextField(variant: MxTextFieldVariant.code),
```

   - In `DESIGN.md`, `### Inputs`: the MxTextField line's variant list becomes "… term (24/700, r20), code (one centred line of six digits on the form fill, headline role with tabular figures and wide tracking, numeric keyboard and one-time-code autofill) and study (bare)".

- [ ] **Step 7: Gate and commit.** The golden `mx_text_field_code_*.png` is written in Task 12, and `--exclude-tags golden` skips it now.

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
flutter test test/shared/widgets/mx_text_field_test.dart test/app/gallery_test.dart --exclude-tags golden
git add lib/shared/widgets/mx_text_field.dart lib/core/theme/mx_text_styles.dart lib/app/gallery/gallery_inputs_section.dart DESIGN.md test/shared/widgets/mx_text_field_test.dart test/shared/widgets/input_widgets_golden_test.dart
git commit -m "feat(shared): MxTextField code variant (account UI U2)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

Expected: all clean; gallery tests pass.

---
### Task 3: Strings, icons and the account feature's local reads

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `test/architecture/boundary_rules.dart`
- Create: `lib/features/account/domain/models/local_library_model.dart`
- Create: `lib/features/account/domain/repositories/account_device_repository.dart`
- Create: `lib/features/account/domain/usecases/is_welcome_seen_use_case.dart`, `mark_welcome_seen_use_case.dart`, `count_local_library_use_case.dart`
- Create: `lib/features/account/data/datasources/account_device_dao.dart`
- Create: `lib/features/account/data/repositories/account_device_repository_impl.dart`
- Create: `lib/features/account/di/account_device_repository_provider.dart`
- Create: `lib/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart`, `mark_welcome_seen_use_case_provider.dart`, `count_local_library_use_case_provider.dart`
- Test: `test/features/account/data/account_device_repository_impl_test.dart`

**Interfaces:**
- Produces:
  - `LocalLibrary({required int decks, required int cards})` with `bool get isEmpty`;
  - `AccountDeviceRepository` with `isWelcomeSeen()`, `markWelcomeSeen()` and `countLibrary()`;
  - `IsWelcomeSeenUseCase()` returning `Future<bool>`, `MarkWelcomeSeenUseCase()` returning `Future<void>` and `CountLocalLibraryUseCase()` returning `Future<LocalLibrary>`;
  - the providers `isWelcomeSeenUseCaseProvider`, `markWelcomeSeenUseCaseProvider`, `countLocalLibraryUseCaseProvider` and `accountDeviceRepositoryProvider`;
  - `AppIcons.account` and `AppIcons.devices`;
  - every `l10n.account*` and `l10n.welcome*` key below.

- [ ] **Step 1: Add the strings.** Save this script as `$S/add_account_strings.py`, with `S` as in Task 1, then run `python3.13 $S/add_account_strings.py && flutter gen-l10n`. JSON round-trips both ARB files byte for byte, which was checked while planning.

```python
import json
from pathlib import Path

# (key, English, Vietnamese, description, placeholders)
S = "Account UI spec"
STRINGS = [
    ("accountSection", "Account", "Tài khoản", f"Screen 23: the Account section's overline ({S} §5.5).", None),
    ("accountSignIn", "Sign in", "Đăng nhập", f"Screen 23's row and screen 30's title: attach an account ({S} §5.5).", None),
    ("accountSignInHint", "Keep your decks if you reinstall or change phones", "Giữ bộ thẻ khi cài lại app hoặc đổi điện thoại", "Screen 23: under Sign in.", None),
    ("accountSignInLater", "Available when you're online", "Dùng được khi có mạng", "Screen 23: under a Sign in that must wait for the network (plan ruling 6).", None),
    ("accountSignedInHint", "Your decks sync to this account", "Bộ thẻ được đồng bộ với tài khoản này", "Screen 23: under the attached account's email (plan ruling 5).", None),
    ("welcomeLead", "Sign in to keep your decks safe and the same on every phone.", "Đăng nhập để giữ bộ thẻ an toàn và giống nhau trên mọi điện thoại.", "Screen 29: the line under the app name.", None),
    ("welcomeBenefitReinstall", "Keep your decks when you reinstall", "Giữ bộ thẻ khi cài lại app", "Screen 29: the first benefit.", None),
    ("welcomeBenefitPhones", "Study on several phones", "Học trên nhiều điện thoại", "Screen 29: the second benefit.", None),
    ("welcomeBenefitOffline", "Still works offline", "Vẫn dùng được khi không có mạng", "Screen 29: the third benefit.", None),
    ("accountContinueGoogle", "Continue with Google", "Tiếp tục với Google", "Screens 29 and 30: sign in with Google.", None),
    ("accountContinueEmail", "Continue with email", "Tiếp tục với email", "Screen 29: go to screen 30 for an email code.", None),
    ("accountContinueWithout", "Continue without an account", "Tiếp tục không cần tài khoản", "Screen 29: leave without signing in.", None),
    ("accountOfflineNote", "Signing in needs a connection. You can do it later in Settings.", "Đăng nhập cần có mạng. Bạn có thể làm sau trong Cài đặt.", "Screens 29 and 30: sign-in must wait for the network (plan ruling 6).", None),
    ("accountLinkLine", "Your decks stay on this phone and join the account.", "Bộ thẻ vẫn ở trên điện thoại này và được gắn vào tài khoản.", "Screen 30, link mode: what signing in does.", None),
    ("accountTargetLine", "Sign in to the account this phone moves to.", "Đăng nhập vào tài khoản mà điện thoại này sẽ chuyển sang.", "Transition layer: the target sign-in.", None),
    ("accountOr", "or", "hoặc", "Screen 30: between Google and the email field.", None),
    ("accountEmail", "Email address", "Địa chỉ email", "Screen 30: the email field's label and hint.", None),
    ("accountSendCode", "Send code", "Gửi mã", "Screen 30: send a 6-digit code to the email.", None),
    ("accountEmailInvalid", "Enter an email address, like name@example.com.", "Nhập địa chỉ email, ví dụ ten@example.com.", "Screen 30: the email is not an address.", None),
    ("accountRateLimited", "Too many tries. Wait a minute, then try again.", "Thử quá nhiều lần. Đợi một phút rồi thử lại.", f"Screens 30 and 31: rate limited ({S} R3).", None),
    ("accountOffline", "No connection. Nothing changed; try again when you're online.", "Không có mạng. Chưa có gì thay đổi; hãy thử lại khi có mạng.", "Screens 30 and 31: offline.", None),
    ("accountFailed", "Couldn't sign in. Nothing changed; try again.", "Không đăng nhập được. Chưa có gì thay đổi; hãy thử lại.", "Screens 30 and 31: any other failure.", None),
    ("accountSignedInAs", "Signed in as {email}", "Đã đăng nhập bằng {email}", "Toast after an account is attached.", {"email": {"type": "String"}}),
    ("accountSignedIn", "Signed in", "Đã đăng nhập", "Toast after an account is attached, its email not confirmed yet.", None),
    ("accountCodeTitle", "Enter the code", "Nhập mã", "Screen 31's title.", None),
    ("accountCodeSentTo", "Enter the 6-digit code sent to {email}", "Nhập mã 6 chữ số đã gửi tới {email}", "Screen 31: where the code went.", {"email": {"type": "String"}}),
    ("accountCodeLabel", "Code, 6 digits", "Mã, 6 chữ số", "Screen 31: the code field's TalkBack label.", None),
    ("accountCodeWrong", "That code is wrong or has expired. Check the latest email, or send a new code.", "Mã sai hoặc đã hết hạn. Xem email mới nhất, hoặc gửi mã mới.", f"Screen 31: a refused code ({S} R3).", None),
    ("accountResendIn", "Resend code in {time}", "Gửi lại mã sau {time}", "Screen 31: the resend countdown, as m:ss.", {"time": {"type": "String"}}),
    ("accountResend", "Resend code", "Gửi lại mã", "Screen 31: send a new code.", None),
    ("accountCodeResent", "A new code is on its way.", "Mã mới đang được gửi tới.", "Screen 31: toast after a resend.", None),
    ("accountUseAnotherEmail", "Use another email", "Dùng email khác", "Screen 31: back to the email.", None),
    ("accountTakenEmail", "{email} already has an account", "{email} đã có tài khoản", "Merge sheet: the title for an email.", {"email": {"type": "String"}}),
    ("accountTakenGoogle", "This Google account is already in use", "Tài khoản Google này đã được dùng", "Merge sheet: the title for Google (plan ruling 12).", None),
    ("accountMerge", "Merge into the account", "Gộp vào tài khoản", "Merge sheet: the default choice.", None),
    ("accountMergeCounts", "{decks, plural, =1{Your 1 deck} other{Your {decks} decks}} and {cards, plural, =1{1 card} other{{cards} cards}} join it.", "{decks} bộ thẻ và {cards} thẻ của bạn sẽ được gộp vào.", "Merge sheet: what merging brings.", {"decks": {"type": "int"}, "cards": {"type": "int"}}),
    ("accountMergePlain", "This phone's decks and cards join it.", "Bộ thẻ và thẻ trên điện thoại này sẽ được gộp vào.", "Merge sheet: what merging brings, when the count failed (plan ruling 10).", None),
    ("accountDiscard", "Discard this phone's data", "Bỏ dữ liệu trên điện thoại này", "Merge sheet: the other choice.", None),
    ("accountDiscardBody", "They're removed from this phone. The account's decks come down instead.", "Chúng bị xoá khỏi điện thoại này. Bộ thẻ của tài khoản sẽ được tải về thay thế.", "Merge sheet: what discarding does.", None),
    ("accountDiscardWarning", "This phone's decks and progress go for good.", "Bộ thẻ và tiến độ trên điện thoại này sẽ mất hẳn.", "Merge sheet: the warning once Discard is chosen.", None),
    ("accountContinue", "Continue", "Tiếp tục", "Merge sheet: confirm the merge.", None),
    ("accountDiscardContinue", "Discard and continue", "Bỏ và tiếp tục", "Merge sheet: confirm the discard.", None),
    ("accountStepSending", "Sending your changes…", "Đang gửi các thay đổi…", "Transition layer: pushing before the move.", None),
    ("accountStepPreparing", "Getting your decks ready…", "Đang chuẩn bị bộ thẻ…", "Transition layer: taking the merge claim.", None),
    ("accountStepMerging", "Merging…", "Đang gộp…", "Transition layer: the merge.", None),
    ("accountStepDownloading", "Downloading your decks…", "Đang tải bộ thẻ về…", "Transition layer: the full pull.", None),
    ("accountStepSigningOut", "Signing out…", "Đang đăng xuất…", "Transition layer: sign-out or clear.", None),
    ("accountStepDeleting", "Deleting your account…", "Đang xoá tài khoản…", "Transition layer: the deletion.", None),
    ("accountSafeToClose", "Nothing is lost if you close the app.", "Đóng app cũng không mất gì.", "Transition layer: the reassurance under the step.", None),
    ("accountLayerOffline", "No connection. Your data is safe on this phone.", "Không có mạng. Dữ liệu vẫn an toàn trên điện thoại này.", "Transition layer: a network error.", None),
    ("accountLayerFailed", "Something went wrong. Your data is safe on this phone.", "Đã có lỗi. Dữ liệu vẫn an toàn trên điện thoại này.", "Transition layer: any other error.", None),
    ("accountLayerStuck", "Something went wrong while moving your account. Your data is safe on this phone.", "Đã có lỗi khi chuyển tài khoản. Dữ liệu vẫn an toàn trên điện thoại này.", "Transition layer: a state the machine says cannot happen.", None),
    ("accountSignOutLosing", "Sign out now and lose {count, plural, =1{1 change} other{{count} changes}}", "Đăng xuất ngay, mất {count} thay đổi", "Transition layer: a sign-out stopped offline.", {"count": {"type": "int"}}),
    ("accountMergeNotDone", "Couldn't merge. Your decks are still on this phone.", "Không gộp được. Bộ thẻ vẫn còn trên điện thoại này.", "Toast: the merge was refused (auth spec #25).", None),
    ("accountLastAdmin", "An admin must remain. Give another person the admin role first.", "Phải còn ít nhất một admin. Hãy cấp quyền admin cho người khác trước.", "Toast: the last admin cannot delete the account (plan ruling 8).", None),
    ("accountDeleteRefused", "Couldn't delete the account. Nothing changed.", "Không xoá được tài khoản. Chưa có gì thay đổi.", "Toast: the deletion did not happen.", None),
]

def update(path, value_of, with_meta):
    file = Path(path)
    data = json.loads(file.read_text(encoding="utf-8"))
    for key, en, vi, description, placeholders in STRINGS:
        assert key not in data, key
        data[key] = value_of(en, vi)
        if with_meta:
            meta = {"description": description}
            if placeholders:
                meta = {"placeholders": placeholders, "description": description}
            data["@" + key] = meta
    file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

update("lib/l10n/app_en.arb", lambda en, vi: en, True)
update("lib/l10n/app_vi.arb", lambda en, vi: vi, False)
```

Expected: `flutter gen-l10n` runs clean, and `flutter test test/app/l10n_test.dart` passes (every key has a description and a Vietnamese value).

- [ ] **Step 2: Add the icons.** In `lib/core/theme/foundations/app_icons.dart`, after `monitoring`:

```dart
  // Account (screens 23, 29).
  static const IconData account = Icons.person_outline; // user
  static const IconData devices = Icons.devices_outlined; // smartphone
```

- [ ] **Step 3: Register the feature** in `test/architecture/boundary_rules.dart`'s `allowedFeatureImports`, after `'monitoring': {},`:

```dart
  'account': {},
```

- [ ] **Step 4: Write the failing repository test** `test/features/account/data/account_device_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late AccountDeviceRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = AccountDeviceRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('a fresh device has not answered Welcome', () async {
    expect(await repository.isWelcomeSeen(), isFalse);
  });

  test('answering Welcome is kept, and queues nothing to sync', () async {
    await repository.markWelcomeSeen();

    expect(await repository.isWelcomeSeen(), isTrue);
    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });

  test('an empty device has nothing to merge', () async {
    final library = await repository.countLibrary();

    expect((library.decks, library.cards), (0, 0));
    expect(library.isEmpty, isTrue);
  });

  test('counts live decks and cards, never the Trash', () async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('Korean');
    await decks.root('English');
    await insertCard(db, id: 'c1', deckId: korean.id);
    await insertCard(db, id: 'c2', deckId: korean.id, deleteBatchId: 'b1');

    final library = await repository.countLibrary();

    expect((library.decks, library.cards), (2, 1));
    expect(library.isEmpty, isFalse);
  });
}
```

- [ ] **Step 5: Run it.**

Run: `flutter test test/features/account/data/account_device_repository_impl_test.dart`
Expected: a compile failure: `account_device_repository_impl.dart` does not exist.

- [ ] **Step 6: Write the domain.**

`lib/features/account/domain/models/local_library_model.dart`:

```dart
/// What this phone holds of its own library, for the merge choice (account
/// UI spec §5.3, R6): live decks and cards, the Trash left out.
final class LocalLibrary {
  const LocalLibrary({required this.decks, required this.cards});

  final int decks;
  final int cards;

  /// Nothing to merge or to lose: the switch asks nothing (auth spec #17).
  bool get isEmpty => decks == 0;
}
```

`lib/features/account/domain/repositories/account_device_repository.dart`:

```dart
import 'package:memox/features/account/domain/models/local_library_model.dart';

/// What the account screens read and write on this device alone (account
/// UI spec §3). The account itself belongs to the core coordinator. The one
/// implementation is `AccountDeviceRepositoryImpl`; the contract keeps
/// domain framework-free (ADR-010).
abstract interface class AccountDeviceRepository {
  /// Whether Welcome was answered on this device (`welcome_seen`).
  Future<bool> isWelcomeSeen();

  /// Records the answer. Device-only: a sign-out's reset keeps it, and sync
  /// never sends it.
  Future<void> markWelcomeSeen();

  /// The live decks and cards on this device.
  Future<LocalLibrary> countLibrary();
}
```

`lib/features/account/domain/usecases/is_welcome_seen_use_case.dart`:

```dart
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec U1: whether Welcome still has to show on this device.
final class IsWelcomeSeenUseCase {
  const IsWelcomeSeenUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<bool> call() => _device.isWelcomeSeen();
}
```

`lib/features/account/domain/usecases/mark_welcome_seen_use_case.dart`:

```dart
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec §5.1: every exit of Welcome answers it for good.
final class MarkWelcomeSeenUseCase {
  const MarkWelcomeSeenUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<void> call() => _device.markWelcomeSeen();
}
```

`lib/features/account/domain/usecases/count_local_library_use_case.dart`:

```dart
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec §5.3, R6: what a merge would bring, or that there is
/// nothing to ask about.
final class CountLocalLibraryUseCase {
  const CountLocalLibraryUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<LocalLibrary> call() => _device.countLibrary();
}
```

- [ ] **Step 7: Write the data layer.**

`lib/features/account/data/datasources/account_device_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for the account screens' device-only reads. It returns plain
/// values and runs inside the caller's guard.
final class AccountDeviceDao {
  AccountDeviceDao(this._db);

  final AppDatabase _db;

  Future<bool> welcomeSeen() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((row) => row.id.equals(appSettingsRowId))).getSingle();
    return row.welcomeSeen == 1;
  }

  /// Only `welcome_seen` changes, so the settings sync trigger, which
  /// watches the four synced columns, stays silent.
  Future<void> setWelcomeSeen() =>
      (_db.update(_db.appSettings)
            ..where((row) => row.id.equals(appSettingsRowId)))
          .write(const AppSettingsCompanion(welcomeSeen: Value(1)));

  /// Live decks, and live cards whose deck is live too.
  Future<(int, int)> liveCounts() async {
    final row = await _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM deck WHERE delete_batch_id IS NULL) AS decks, '
          '(SELECT COUNT(*) FROM card c JOIN deck d ON d.id = c.deck_id '
          'WHERE c.delete_batch_id IS NULL AND d.delete_batch_id IS NULL) '
          'AS cards',
          readsFrom: {_db.deck, _db.card},
        )
        .getSingle();
    return (row.read<int>('decks'), row.read<int>('cards'));
  }
}
```

`lib/features/account/data/repositories/account_device_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/account_device_dao.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// The welcome flag is a device-only column, like the reminder's delivery
/// time: its write opens no business transaction, so the account's gate
/// (auth spec R3) never refuses it.
final class AccountDeviceRepositoryImpl implements AccountDeviceRepository {
  AccountDeviceRepositoryImpl(AppDatabase db) : _dao = AccountDeviceDao(db);

  final AccountDeviceDao _dao;

  @override
  Future<bool> isWelcomeSeen() => guardDatabase(_dao.welcomeSeen);

  @override
  Future<void> markWelcomeSeen() => guardDatabase(_dao.setWelcomeSeen);

  @override
  Future<LocalLibrary> countLibrary() => guardDatabase(() async {
    final (decks, cards) = await _dao.liveCounts();
    return LocalLibrary(decks: decks, cards: cards);
  });
}
```

`lib/features/account/di/account_device_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_device_repository_provider.g.dart';

@riverpod
AccountDeviceRepository accountDeviceRepository(Ref ref) =>
    AccountDeviceRepositoryImpl(ref.watch(databaseProvider));
```

The three use-case providers, in `lib/features/account/presentation/providers/`, follow the settings pattern:

```dart
// is_welcome_seen_use_case_provider.dart
import 'package:memox/features/account/di/account_device_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/is_welcome_seen_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_welcome_seen_use_case_provider.g.dart';

@riverpod
IsWelcomeSeenUseCase isWelcomeSeenUseCase(Ref ref) =>
    IsWelcomeSeenUseCase(ref.watch(accountDeviceRepositoryProvider));
```

```dart
// mark_welcome_seen_use_case_provider.dart
import 'package:memox/features/account/di/account_device_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/mark_welcome_seen_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mark_welcome_seen_use_case_provider.g.dart';

@riverpod
MarkWelcomeSeenUseCase markWelcomeSeenUseCase(Ref ref) =>
    MarkWelcomeSeenUseCase(ref.watch(accountDeviceRepositoryProvider));
```

```dart
// count_local_library_use_case_provider.dart
import 'package:memox/features/account/di/account_device_repository_provider.dart';
import 'package:memox/features/account/domain/usecases/count_local_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'count_local_library_use_case_provider.g.dart';

@riverpod
CountLocalLibraryUseCase countLocalLibraryUseCase(Ref ref) =>
    CountLocalLibraryUseCase(ref.watch(accountDeviceRepositoryProvider));
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 8: Run the tests.**

Run: `flutter test test/features/account/data/account_device_repository_impl_test.dart test/app/l10n_test.dart test/architecture`
Expected: all pass.

- [ ] **Step 9: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/core/theme/foundations/app_icons.dart test/architecture/boundary_rules.dart lib/features/account test/features/account
git commit -m "feat(account): strings and the device's welcome flag and library counts (P3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 4: `WelcomeDue`, read before the first frame

**Files:**
- Create: `lib/features/account/presentation/providers/welcome_due_provider.dart`
- Create: `lib/app/startup_welcome.dart`
- Modify: `lib/main.dart`
- Test: `test/app/startup_welcome_test.dart`

**Interfaces:**
- Consumes: `isWelcomeSeenUseCaseProvider` and `markWelcomeSeenUseCaseProvider` (Task 3); `accountCoordinatorProvider` (P2).
- Produces:
  - `welcomeDueProvider`, a keep-alive `bool` with `show()` and `Future<void> dismiss()`;
  - `Future<void> showWelcomeIfDue(ProviderContainer container)`.

- [ ] **Step 1: Write the failing test** `test/app/startup_welcome_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup_welcome.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:memox/features/account/domain/usecases/is_welcome_seen_use_case.dart';
import 'package:memox/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';

import '../support/auth_fakes.dart';
import '../support/test_database.dart';

final class _FailingDevice implements AccountDeviceRepository {
  @override
  Future<bool> isWelcomeSeen() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<void> markWelcomeSeen() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<LocalLibrary> countLibrary() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');
}

void main() {
  late AppDatabase db;
  late AuthWorld world;

  setUp(() {
    db = openTestDatabase();
    world = AuthWorld()..boot();
  });
  tearDown(() async {
    await world.close();
    await db.close();
  });

  ProviderContainer containerWith(List<Override> overrides) {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a build that can sign in shows Welcome until it is answered', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);

    await showWelcomeIfDue(container);
    expect(container.read(welcomeDueProvider), isTrue);

    await AccountDeviceRepositoryImpl(db).markWelcomeSeen();
    final next = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);
    await showWelcomeIfDue(next);
    expect(next.read(welcomeDueProvider), isFalse);
  });

  test('a build with no Supabase project never shows Welcome', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(null),
    ]);

    await showWelcomeIfDue(container);

    expect(container.read(welcomeDueProvider), isFalse);
  });

  test('a failed read shows nothing', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
      isWelcomeSeenUseCaseProvider.overrideWithValue(
        IsWelcomeSeenUseCase(_FailingDevice()),
      ),
    ]);

    await showWelcomeIfDue(container);

    expect(container.read(welcomeDueProvider), isFalse);
  });

  test('dismiss lets go at once, then stores the answer', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);
    final due = container.read(welcomeDueProvider.notifier)..show();

    final saving = due.dismiss();
    expect(container.read(welcomeDueProvider), isFalse);
    await saving;

    expect(await AccountDeviceRepositoryImpl(db).isWelcomeSeen(), isTrue);
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/app/startup_welcome_test.dart`
Expected: a compile failure: `startup_welcome.dart` does not exist.

- [ ] **Step 3: Implement.**

`lib/features/account/presentation/providers/welcome_due_provider.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/account/presentation/providers/mark_welcome_seen_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_due_provider.g.dart';

/// Whether the router sends the app to Welcome (account UI spec U1, §4).
/// False until `main` finds `welcome_seen` unset on a build that can sign
/// in (plan ruling 3), and false again the moment Welcome is answered.
@Riverpod(keepAlive: true)
class WelcomeDue extends _$WelcomeDue {
  @override
  bool build() => false;

  /// Before the first frame: Welcome was never answered on this device.
  void show() => state = true;

  /// Every exit of Welcome (spec §5.1). The router lets go at once, then the
  /// answer is stored; a failed write only shows Welcome again next launch.
  Future<void> dismiss() async {
    state = false;
    try {
      await ref.read(markWelcomeSeenUseCaseProvider)();
    } on Failure catch (error, stackTrace) {
      appLogger.warning(
        'account.welcome_not_saved',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
```

`lib/app/startup_welcome.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';

/// Account UI spec U1: Welcome shows once on every device of a build that
/// can sign in (plan ruling 3), decided before the first frame so nothing
/// flashes. A failed or slow read shows nothing; the next launch asks
/// again.
Future<void> showWelcomeIfDue(ProviderContainer container) async {
  if (container.read(accountCoordinatorProvider) == null) return;
  final bool isSeen;
  try {
    isSeen = await container
        .read(isWelcomeSeenUseCaseProvider)()
        .timeout(startupSettingsLimit);
  } on Failure {
    return;
  } on TimeoutException {
    return;
  }
  if (!isSeen) container.read(welcomeDueProvider.notifier).show();
}
```

In `lib/main.dart`, import `package:memox/app/startup_welcome.dart`, and right after `await accounts?.prepare();` add:

```dart
  // Account UI spec U1: the first launch's Welcome, before the first frame.
  await showWelcomeIfDue(container);
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run the test.**

Run: `flutter test test/app/startup_welcome_test.dart`
Expected: 4 pass.

- [ ] **Step 5: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account/presentation/providers/welcome_due_provider.dart lib/app/startup_welcome.dart lib/main.dart test/app/startup_welcome_test.dart
git commit -m "feat(account): Welcome due before the first frame (U1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 5: Sign-in commands (`SignInController`) and the account test harness

**Files:**
- Create: `lib/features/account/presentation/states/sign_in_state.dart`
- Create: `lib/features/account/presentation/controllers/sign_in_controller.dart`
- Create: `lib/features/account/presentation/providers/can_link_provider.dart`
- Create: `lib/features/account/presentation/widgets/support/account_copy_widget.dart`
- Create: `test/support/account_harness.dart`
- Modify: `test/support/fake_auth_server.dart` (a rate-limit hook)
- Test: `test/features/account/presentation/sign_in_controller_test.dart`

**Interfaces:**
- Consumes: `accountCoordinatorProvider`, `authStateProvider` and `AccountCoordinator.requestCode/continueWithGoogle` (P2).
- Produces:
  - `enum SignInPurpose { link, target }`, `enum SignInTask { google, email }`;
  - `enum SignInProblem { invalidEmail, wrongCode, rateLimited, offline, failed }`;
  - `enum SignInOutcome { signedIn, codeSent, identityTaken, none, failed }`;
  - `SignInState({SignInTask? task, SignInProblem? problem, SignInTask? problemTask})` with `bool get isRunning`;
  - `SignInProblem signInProblemOf(Object error)` and `bool isEmailAddress(String text)`;
  - `signInControllerProvider(SignInPurpose)`, with `Future<SignInOutcome> continueWithGoogle()` and `Future<SignInOutcome> sendCode(String email)`;
  - `canLinkProvider` (`bool`);
  - `googleMark`, `signInProblemText(AppLocalizations, SignInProblem)` and `saySignedIn(BuildContext, AccountUser?)`;
  - the test helpers `accountTest`, `accountOverrides(AuthWorld)`, `linkEmail(AuthWorld, [String])`, `authStateOf(AuthState)` and `transitionOf(...)`, plus `FakeAuthGateway.failNextRequest`.

- [ ] **Step 1: Add the rate-limit hook** to `FakeAuthGateway` in `test/support/fake_auth_server.dart`. Put the field after `googleCancels`:

```dart
  /// The next code request fails with this, as GoTrue's rate limit does.
  Failure? failNextRequest;

  void _failIfAsked() {
    final failure = failNextRequest;
    if (failure == null) return;
    failNextRequest = null;
    throw failure;
  }
```

   Call `_failIfAsked();` right after `server.checkOnline();` in `requestEmailLink` and in `requestEmailSignIn`. If the file does not import `package:memox/core/error/failure.dart` yet, add that import.

- [ ] **Step 2: Write the harness** `test/support/account_harness.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';

import 'auth_fakes.dart';
import 'fake_auth_server.dart';
import 'library_harness.dart';

/// A widget test over the library backend and one device of [AuthWorld],
/// started on its first anonymous user. The tree goes before the world's
/// database closes, so no stream outlives the test. If `start()` ever
/// stalls under the widget clock, run it in `tester.runAsync`.
void accountTest(
  String description,
  Future<void> Function(WidgetTester tester, LibraryEnv env, AuthWorld world)
  body,
) {
  libraryTest(description, (tester, env) async {
    final world = AuthWorld();
    try {
      await readyAnonymous(world);
      await body(tester, env, world);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await world.close();
    }
  });
}

/// The app's account providers on [world]: its coordinator and its sync.
List<Override> accountOverrides(AuthWorld world) => [
  accountCoordinatorProvider.overrideWithValue(world.coordinator),
  syncControlProvider.overrideWithValue(world.sync),
];

/// [world]'s anonymous user attached to [email] through a code.
Future<void> linkEmail(AuthWorld world, [String email = 'a@example.com']) async {
  await world.coordinator.requestCode(email);
  await world.coordinator.verifyCode(email, FakeAuthGateway.code);
}

/// [state] as the only account state, for a surface that renders it.
Override authStateOf(AuthState state) =>
    authStateProvider.overrideWith((ref) => Stream.value(state));

/// A transition record for a rendering test.
AccountTransition transitionOf(
  TransitionKind kind,
  TransitionStage stage, {
  TransitionChoice? choice,
  String? targetHint,
}) {
  final at = DateTime(2026, 9, 30, 9);
  return AccountTransition(
    opId: 'op-render',
    kind: kind,
    stage: stage,
    createdAt: at,
    updatedAt: at,
    choice: choice,
    targetHint: targetHint,
  );
}
```

- [ ] **Step 3: Write the failing controller test** `test/features/account/presentation/sign_in_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/fake_auth_server.dart';

void main() {
  late AuthWorld world;
  late ProviderContainer container;
  final provider = signInControllerProvider(SignInPurpose.link);

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world);
    container = ProviderContainer(overrides: accountOverrides(world));
    container.listen(provider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await world.close();
  });

  SignInController controller() => container.read(provider.notifier);
  SignInState state() => container.read(provider);

  test('a mistyped address is refused before anything is sent', () async {
    expect(await controller().sendCode('a@'), SignInOutcome.failed);

    expect(state().problem, SignInProblem.invalidEmail);
    expect(state().problemTask, SignInTask.email);
    expect(world.server.sentCodes, isEmpty);
  });

  test('a free address gets a code', () async {
    expect(
      await controller().sendCode(' a@example.com '),
      SignInOutcome.codeSent,
    );

    expect(world.server.sentCodes['a@example.com'], FakeAuthGateway.code);
    expect(state().problem, isNull);
    expect(state().isRunning, isFalse);
  });

  test("another account's address is identity taken, with nothing to say",
      () async {
    world.server.addUser(email: 'b@example.com');

    expect(
      await controller().sendCode('b@example.com'),
      SignInOutcome.identityTaken,
    );
    expect(state().problem, isNull);
  });

  test('offline says offline', () async {
    world.network.goOffline();

    expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);
    expect(state().problem, SignInProblem.offline);
  });

  test('a rate limit says so', () async {
    world.gateway.failNextRequest = const RateLimitedFailure();

    expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);
    expect(state().problem, SignInProblem.rateLimited);
  });

  test('a second press while one runs sends nothing (Review Focus 3)',
      () async {
    final first = controller().sendCode('a@example.com');
    final second = await controller().sendCode('a@example.com');

    expect(second, SignInOutcome.none);
    expect(await first, SignInOutcome.codeSent);
  });

  test('Google attaches the account to this user', () async {
    expect(await controller().continueWithGoogle(), SignInOutcome.signedIn);

    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'g@example.com'),
    );
    expect(state().isRunning, isFalse);
  });

  test('a cancelled Google pick says nothing', () async {
    world.gateway.googleCancels = true;

    expect(await controller().continueWithGoogle(), SignInOutcome.none);
    expect(state().problem, isNull);
  });

  test('a Google failure is marked as Google\'s', () async {
    world.network.goOffline();

    expect(await controller().continueWithGoogle(), SignInOutcome.failed);
    expect(state().problemTask, SignInTask.google);
  });
}
```

- [ ] **Step 4: Run it.**

Run: `flutter test test/features/account/presentation/sign_in_controller_test.dart`
Expected: a compile failure: `sign_in_controller.dart` does not exist.

- [ ] **Step 5: Implement the state.** `lib/features/account/presentation/states/sign_in_state.dart`:

```dart
import 'package:memox/core/error/failure.dart';

/// Who the sign-in form signs in (account UI spec §5.2): this anonymous
/// user's link, or the switch's target inside the transition layer. Each
/// has its own controller, since the layer's form can stand over screen
/// 30's.
enum SignInPurpose { link, target }

/// The command the form is running.
enum SignInTask { google, email }

/// What went wrong; `signInProblemText` gives the local-first copy.
enum SignInProblem { invalidEmail, wrongCode, rateLimited, offline, failed }

/// What a command came to, for the screen to act on.
enum SignInOutcome {
  /// The account is attached, or the switch's target signed in.
  signedIn,

  /// A code is on its way to the address.
  codeSent,

  /// The identity belongs to another account (auth spec #17).
  identityTaken,

  /// Nothing to show: a cancelled Google pick, or a press while one runs.
  none,

  /// [SignInState.problem] says why.
  failed,
}

/// The form's state: what runs, and what went wrong with which command.
final class SignInState {
  const SignInState({this.task, this.problem, this.problemTask});

  final SignInTask? task;
  final SignInProblem? problem;

  /// Which command [problem] belongs to: an email problem shows under the
  /// field, a Google one as a toast.
  final SignInTask? problemTask;

  bool get isRunning => task != null;
}

/// The problem a refused command shows (spec R3: a wrong and an expired
/// code read alike; a rate limit carries no wait).
SignInProblem signInProblemOf(Object error) => switch (error) {
  InvalidCodeFailure() => SignInProblem.wrongCode,
  RateLimitedFailure() => SignInProblem.rateLimited,
  OfflineFailure() => SignInProblem.offline,
  _ => SignInProblem.failed,
};

final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A plausible address: one `@`, a dotted domain, no spaces. The server
/// decides the rest.
bool isEmailAddress(String text) => _emailShape.hasMatch(text);
```

- [ ] **Step 6: Implement the controller.** `lib/features/account/presentation/controllers/sign_in_controller.dart`:

```dart
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller.g.dart';

/// Screen 30's and the layer's commands (account UI spec §5.2): Google, or
/// a code to an address. The coordinator decides whether a sign-in links
/// this user or signs in the switch's target; [purpose] only keeps the two
/// forms' states apart.
@riverpod
class SignInController extends _$SignInController {
  @override
  SignInState build(SignInPurpose purpose) => const SignInState();

  Future<SignInOutcome> continueWithGoogle() =>
      _run(SignInTask.google, (accounts) => accounts.continueWithGoogle());

  /// A text that is not an address is refused here, before anything is
  /// sent.
  Future<SignInOutcome> sendCode(String email) async {
    final address = email.trim();
    if (!isEmailAddress(address)) {
      state = const SignInState(
        problem: SignInProblem.invalidEmail,
        problemTask: SignInTask.email,
      );
      return SignInOutcome.failed;
    }
    return _run(
      SignInTask.email,
      (accounts) => accounts.requestCode(address),
      done: SignInOutcome.codeSent,
    );
  }

  Future<SignInOutcome> _run(
    SignInTask task,
    Future<void> Function(AccountCoordinator accounts) command, {
    SignInOutcome done = SignInOutcome.signedIn,
  }) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || state.isRunning) return SignInOutcome.none;
    state = SignInState(task: task);
    SignInProblem? problem;
    var outcome = done;
    try {
      await command(accounts);
    } on IdentityTakenFailure {
      outcome = SignInOutcome.identityTaken;
    } on GoogleCancelledFailure {
      outcome = SignInOutcome.none;
    } on Failure catch (error) {
      problem = signInProblemOf(error);
      outcome = SignInOutcome.failed;
    } on StateError {
      // The account moved on meanwhile: P2 takes a sign-in only in Ready
      // (plan ruling 6).
      problem = SignInProblem.failed;
      outcome = SignInOutcome.failed;
    }
    if (ref.mounted) {
      state = SignInState(
        problem: problem,
        problemTask: problem == null ? null : task,
      );
    }
    return outcome;
  }
}
```

- [ ] **Step 7: Implement `canLink` and the copy helpers.**

`lib/features/account/presentation/providers/can_link_provider.dart`:

```dart
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_link_provider.g.dart';

/// Whether this device can attach an account now: P2 links only the
/// anonymous user of `Ready`. Offline at first launch it cannot (plan
/// ruling 6).
@riverpod
bool canLink(Ref ref) => switch (ref.watch(authStateProvider).value) {
  Ready(:final user) => user.isAnonymous,
  _ => false,
};
```

`lib/features/account/presentation/widgets/support/account_copy_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Google's G on "Continue with Google" (account UI spec U6).
const AssetImage googleMark = AssetImage('assets/brand/google_g.png');

/// The local-first line for a refused sign-in step.
String signInProblemText(AppLocalizations l10n, SignInProblem problem) =>
    switch (problem) {
      SignInProblem.invalidEmail => l10n.accountEmailInvalid,
      SignInProblem.wrongCode => l10n.accountCodeWrong,
      SignInProblem.rateLimited => l10n.accountRateLimited,
      SignInProblem.offline => l10n.accountOffline,
      SignInProblem.failed => l10n.accountFailed,
    };

/// The toast after an account is attached (spec §5.2): its email once
/// `me()` confirmed it.
void saySignedIn(BuildContext context, AccountUser? account) {
  final l10n = context.l10n;
  final email = account?.email;
  showMxSnackbar(
    context,
    message: email == null ? l10n.accountSignedIn : l10n.accountSignedInAs(email),
  );
}
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 8: Run the tests.**

Run: `flutter test test/features/account/presentation/sign_in_controller_test.dart`
Expected: 9 pass.

- [ ] **Step 9: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account test/support/account_harness.dart test/support/fake_auth_server.dart test/features/account
git commit -m "feat(account): sign-in commands for the link and the switch's target

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---
### Task 6: The merge choice (#17)

**Files:**
- Create: `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart`
- Test: `test/features/account/presentation/merge_choice_sheet_test.dart`

**Interfaces:**
- Consumes: `countLocalLibraryUseCaseProvider` and `LocalLibrary` (Task 3); `AccountCoordinator.beginSwitch({required TransitionChoice choice, String? targetHint})` (P2).
- Produces:
  - `Future<bool> startLinkSwitch(BuildContext context, WidgetRef ref, {String? email})`, which returns whether the switch started (`email` is null for Google);
  - `MergeChoiceSheetWidget({required String? email, required LocalLibrary? library})`, which pops a `TransitionChoice`, or null on Cancel.

- [ ] **Step 1: Write the failing test** `test/features/account/presentation/merge_choice_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:memox/features/account/domain/usecases/count_local_library_use_case.dart';
import 'package:memox/features/account/presentation/providers/count_local_library_use_case_provider.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

final class _UncountableDevice implements AccountDeviceRepository {
  @override
  Future<LocalLibrary> countLibrary() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<bool> isWelcomeSeen() async => true;

  @override
  Future<void> markWelcomeSeen() async {}
}

/// A button that starts the switch for [email], as screen 30 does.
Widget _host({String? email = 'b@example.com'}) => Scaffold(
  body: Consumer(
    builder: (context, ref, _) => TextButton(
      onPressed: () => startLinkSwitch(context, ref, email: email),
      child: const Text('go'),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  accountTest('a phone with decks asks, and merge is the default', (
    tester,
    env,
    world,
  ) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.text(_en.accountTakenEmail('b@example.com')), findsOneWidget);
    expect(find.text(_en.accountMergeCounts(1, 0)), findsOneWidget);
    expect(find.text(_en.accountDiscardWarning), findsNothing);

    await tester.tap(find.text(_en.accountContinue));
    await _settle(tester);

    expect(
      world.state,
      isA<Transitioning>()
          .having((s) => s.transition.choice, 'choice', TransitionChoice.merge)
          .having((s) => s.transition.targetHint, 'hint', 'b@example.com'),
    );
  });

  accountTest('discarding is its own choice, confirmed in the destructive '
      'tone', (tester, env, world) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('go'));
    await _settle(tester);

    await tester.tap(find.text(_en.accountDiscard));
    await tester.pump();

    expect(find.text(_en.accountDiscardWarning), findsOneWidget);
    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.isDestructive, isTrue);
    expect(actions.confirmLabel, _en.accountDiscardContinue);

    await tester.tap(find.text(_en.accountDiscardContinue));
    await _settle(tester);
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.transition.choice,
        'choice',
        TransitionChoice.discard,
      ),
    );
  });

  accountTest('an empty phone moves without asking', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.byType(MergeChoiceSheetWidget), findsNothing);
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.transition.choice,
        'choice',
        TransitionChoice.discard,
      ),
    );
  });

  accountTest('Cancel starts nothing', (tester, env, world) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('go'));
    await _settle(tester);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);

    expect(world.state, isA<Ready>());
  });

  accountTest('Google\'s title, and a failed count still asks, without '
      'numbers', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(email: null),
      overrides: [
        ...accountOverrides(world),
        countLocalLibraryUseCaseProvider.overrideWithValue(
          CountLocalLibraryUseCase(_UncountableDevice()),
        ),
      ],
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.text(_en.accountTakenGoogle), findsOneWidget);
    expect(find.text(_en.accountMergePlain), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/features/account/presentation/merge_choice_sheet_test.dart`
Expected: a compile failure: `merge_choice_sheet_widget.dart` does not exist.

- [ ] **Step 3: Implement** `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/presentation/providers/count_local_library_use_case_provider.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Auth spec #17 and account UI spec §5.3: the sign-in belongs to another
/// account. A phone with decks asks, merging by default; an empty one
/// moves without asking. [email] is the address typed, null for Google.
/// Returns whether the switch started; the transition layer takes over
/// from there.
Future<bool> startLinkSwitch(
  BuildContext context,
  WidgetRef ref, {
  String? email,
}) async {
  final accounts = ref.read(accountCoordinatorProvider);
  if (accounts == null) return false;
  LocalLibrary? library;
  try {
    library = await ref.read(countLocalLibraryUseCaseProvider)();
  } on Failure {
    library = null; // Plan ruling 10: ask anyway, without numbers.
  }
  if (!context.mounted) return false;
  final choice = library != null && library.isEmpty
      ? TransitionChoice.discard
      : await showMxBottomSheet<TransitionChoice>(
          context,
          builder: (_) =>
              MergeChoiceSheetWidget(email: email, library: library),
        );
  if (choice == null || !context.mounted) return false;
  try {
    await accounts.beginSwitch(choice: choice, targetHint: email);
    return true;
  } on Failure catch (error) {
    if (context.mounted) {
      showMxSnackbar(context, message: context.l10n.failure(error));
    }
    return false;
  }
}

/// Merge (default) or discard, then a confirm in the choice's own tone, so
/// losing this phone's data takes two deliberate taps (spec §5.3, O4).
class MergeChoiceSheetWidget extends StatefulWidget {
  const MergeChoiceSheetWidget({
    super.key,
    required this.email,
    required this.library,
  });

  /// The address that has an account; null for Google.
  final String? email;

  /// What merging brings; null when it could not be counted.
  final LocalLibrary? library;

  @override
  State<MergeChoiceSheetWidget> createState() =>
      _MergeChoiceSheetWidgetState();
}

class _MergeChoiceSheetWidgetState extends State<MergeChoiceSheetWidget> {
  var _choice = TransitionChoice.merge;

  bool get _isDiscarding => _choice == TransitionChoice.discard;

  void _choose(TransitionChoice choice) => setState(() => _choice = choice);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = widget.email;
    final library = widget.library;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          email == null
              ? l10n.accountTakenGoogle
              : l10n.accountTakenEmail(email),
          style: context.textStyles.compactTitle,
        ),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: _isDiscarding
            ? l10n.accountDiscardContinue
            : l10n.accountContinue,
        onConfirm: () => Navigator.of(context).pop(_choice),
        isDestructive: _isDiscarding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxOptionRow(
            title: l10n.accountMerge,
            description: library == null
                ? l10n.accountMergePlain
                : l10n.accountMergeCounts(library.decks, library.cards),
            isSelected: !_isDiscarding,
            onSelected: () => _choose(TransitionChoice.merge),
          ),
          MxOptionRow(
            title: l10n.accountDiscard,
            description: l10n.accountDiscardBody,
            isSelected: _isDiscarding,
            onSelected: () => _choose(TransitionChoice.discard),
            hasDivider: false,
          ),
          if (_isDiscarding)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.grouped,
                AppSpacing.gutter,
                0,
              ),
              // Something is lost here, so the danger tone, not a note.
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                message: l10n.accountDiscardWarning,
              ),
            ),
        ],
      ),
    );
  }
}
```

Keep the `account_coordinator.dart` import even though no name from it is written: `beginSwitch` is an extension method of that library, and it resolves only while the library is imported.

- [ ] **Step 4: Run the test.**

Run: `flutter test test/features/account/presentation/merge_choice_sheet_test.dart`
Expected: 5 pass.

- [ ] **Step 5: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account test/features/account
git commit -m "feat(account): merge choice sheet, merge by default (auth #17)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 7: The sign-in form and screen 30

**Files:**
- Create: `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart`
- Create: `lib/features/account/presentation/screens/sign_in_screen.dart`
- Test: `test/features/account/presentation/sign_in_screen_test.dart`

**Interfaces:**
- Consumes:
  - `signInControllerProvider` and the state enums, `canLinkProvider`, `googleMark`, `signInProblemText` and `saySignedIn` (Task 5);
  - `startLinkSwitch` (Task 6);
  - `MxButton.mark` (Task 1).
- Produces:
  - `SignInFormWidget({required SignInPurpose purpose, required ValueChanged<String> onCodeSent, VoidCallback? onSignedIn, String? initialEmail, bool isEnabled = true})`;
  - `SignInScreen({required ValueChanged<String> onCodeSent, required VoidCallback onSignedIn})`.

- [ ] **Step 1: Write the failing test** `test/features/account/presentation/sign_in_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  late List<String> codesSent;
  late int signIns;

  SignInScreen screen() => SignInScreen(
    onCodeSent: codesSent.add,
    onSignedIn: () => signIns++,
  );

  setUp(() {
    codesSent = [];
    signIns = 0;
  });

  accountTest('an address gets a code, and the code screen is next', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(codesSent, ['a@example.com']);
  });

  accountTest('a mistyped address is said under the field, and nothing is '
      'sent', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountEmailInvalid), findsOneWidget);
    expect(codesSent, isEmpty);
    expect(world.server.sentCodes, isEmpty);
  });

  accountTest('Google attaches the account, says so and leaves', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('g@example.com')), findsOneWidget);
  });

  accountTest("another account's address asks to merge", (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: 'b@example.com');
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'b@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.byType(MergeChoiceSheetWidget), findsOneWidget);
  });

  accountTest('offline says that nothing changed', (tester, env, world) async {
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);

    expect(find.text(_en.accountOffline), findsOneWidget);
  });

  accountTest('not ready to link: the form waits and says why', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
    );

    expect(_button(tester, _en.accountSendCode).onPressed, isNull);
    expect(_button(tester, _en.accountContinueGoogle).onPressed, isNull);
    expect(find.text(_en.accountOfflineNote), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/features/account/presentation/sign_in_screen_test.dart`
Expected: a compile failure: `sign_in_screen.dart` does not exist.

- [ ] **Step 3: Implement the form.** `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The sign-in of screen 30 and of the transition layer (account UI spec
/// §5.2, §6): Google as the outline, "or", then the address and "Send
/// code", the form's one fill. The address is checked on send; its problem
/// shows under the field, and a Google problem shows as a toast.
class SignInFormWidget extends ConsumerStatefulWidget {
  const SignInFormWidget({
    super.key,
    required this.purpose,
    required this.onCodeSent,
    this.onSignedIn,
    this.initialEmail,
    this.isEnabled = true,
  });

  final SignInPurpose purpose;

  /// A code went to this address: the code step is next.
  final ValueChanged<String> onCodeSent;

  /// Google signed in (the link; the layer follows the state instead).
  final VoidCallback? onSignedIn;

  /// The address typed before, such as the switch's target.
  final String? initialEmail;

  /// False while this device cannot sign in yet (plan ruling 6).
  final bool isEnabled;

  @override
  ConsumerState<SignInFormWidget> createState() => _SignInFormWidgetState();
}

class _SignInFormWidgetState extends ConsumerState<SignInFormWidget> {
  late final _email = TextEditingController(text: widget.initialEmail);

  SignInController get _controller =>
      ref.read(signInControllerProvider(widget.purpose).notifier);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    final outcome = await _controller.continueWithGoogle();
    if (!mounted) return;
    final problem = ref.read(signInControllerProvider(widget.purpose)).problem;
    if (outcome == SignInOutcome.failed && problem != null) {
      showMxSnackbar(context, message: signInProblemText(context.l10n, problem));
      return;
    }
    await _follow(outcome, email: null);
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    final outcome = await _controller.sendCode(email);
    if (!mounted) return;
    await _follow(outcome, email: email);
  }

  Future<void> _follow(SignInOutcome outcome, {required String? email}) async {
    switch (outcome) {
      case SignInOutcome.signedIn:
        widget.onSignedIn?.call();
      case SignInOutcome.codeSent:
        widget.onCodeSent(email!);
      case SignInOutcome.identityTaken:
        await startLinkSwitch(context, ref, email: email);
      case SignInOutcome.none || SignInOutcome.failed:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider(widget.purpose));
    final canAct = widget.isEnabled && !state.isRunning;
    final fieldProblem = state.problemTask == SignInTask.email
        ? state.problem
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.purpose == SignInPurpose.link
              ? l10n.accountLinkLine
              : l10n.accountTargetLine,
          style: context.texts.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        MxButton(
          label: l10n.accountContinueGoogle,
          tone: MxButtonTone.outline,
          mark: googleMark,
          isBlock: true,
          isLoading: state.task == SignInTask.google,
          onPressed: canAct ? () => unawaited(_google()) : null,
        ),
        const SizedBox(height: AppSpacing.section),
        _OrDivider(label: l10n.accountOr),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _email,
          label: l10n.accountEmail,
          hintText: l10n.accountEmail,
          isEnabled: widget.isEnabled,
          textInputAction: TextInputAction.send,
          onSubmitted: canAct ? (_) => unawaited(_send()) : null,
          errorText: fieldProblem == null
              ? null
              : signInProblemText(l10n, fieldProblem),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxButton(
          label: l10n.accountSendCode,
          isBlock: true,
          isLoading: state.task == SignInTask.email,
          onPressed: canAct ? () => unawaited(_send()) : null,
        ),
      ],
    );
  }
}

/// "or" between two hairlines.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: SizedBox(
        height: AppStroke.hairline,
        child: ColoredBox(color: context.derivedColors.ghostBorder),
      ),
    );
    return Row(
      spacing: AppSpacing.grouped,
      children: [
        line,
        Text(
          label,
          style: context.texts.labelSmall!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        line,
      ],
    );
  }
}
```

- [ ] **Step 4: Implement screen 30.** `lib/features/account/presentation/screens/sign_in_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 30 in its link mode (account UI spec §5.2): attach Google or an
/// email to this device's anonymous user. Its decks stay where they are.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({
    super.key,
    required this.onCodeSent,
    required this.onSignedIn,
  });

  final ValueChanged<String> onCodeSent;

  /// The account is attached: the flow closes (plan ruling 2).
  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canLink = ref.watch(canLinkProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountSignIn,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          if (!canLink) ...[
            MxNote(text: l10n.accountOfflineNote),
            const SizedBox(height: AppSpacing.gutter),
          ],
          SignInFormWidget(
            purpose: SignInPurpose.link,
            isEnabled: canLink,
            onCodeSent: onCodeSent,
            onSignedIn: () {
              saySignedIn(context, ref.read(currentAccountProvider));
              onSignedIn();
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test.**

Run: `flutter test test/features/account/presentation/sign_in_screen_test.dart`
Expected: 6 pass.

- [ ] **Step 6: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account test/features/account
git commit -m "feat(account): sign-in form and screen 30 (link)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 8: The code step and screen 31

**Files:**
- Create: `lib/features/account/presentation/states/code_state.dart`
- Create: `lib/features/account/presentation/controllers/code_controller.dart`
- Create: `lib/features/account/presentation/widgets/sections/code_form_widget.dart`
- Create: `lib/features/account/presentation/screens/code_screen.dart`
- Test: `test/features/account/presentation/code_controller_test.dart`, `test/features/account/presentation/code_screen_test.dart`

**Interfaces:**
- Consumes: `SignInPurpose`, `SignInProblem`, `signInProblemOf`, `signInProblemText` and `saySignedIn` (Task 5); `MxTextFieldVariant.code` and `MxButtonTone.text` (Tasks 1–2); `AccountCoordinator.verifyCode(email, code)` and `requestCode(email)` (P2).
- Produces:
  - `CodeState({bool isVerifying, bool isResending, SignInProblem? problem, Duration resendIn})`, with `isBusy`, `canResend` and `copyWith({Duration? resendIn})`;
  - `codeControllerProvider(String email, SignInPurpose purpose)`, with `Future<bool> verify(String code)`, `Future<bool> resend()` and `static const Duration resendWait`;
  - `CodeFormWidget({required String email, required SignInPurpose purpose, VoidCallback? onSignedIn, required VoidCallback onUseAnotherEmail})`;
  - `CodeScreen({required String email, required VoidCallback onSignedIn})`.

- [ ] **Step 1: Write the failing controller test** `test/features/account/presentation/code_controller_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/fake_auth_server.dart';

void main() {
  late AuthWorld world;
  final provider = codeControllerProvider(
    'a@example.com',
    SignInPurpose.link,
  );

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world);
    await world.coordinator.requestCode('a@example.com');
  });
  tearDown(() => world.close());

  ProviderContainer containerOf() {
    final container = ProviderContainer(overrides: accountOverrides(world));
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    return container;
  }

  test('Resend waits a minute, counting down each second', () {
    fakeAsync((async) {
      final container = ProviderContainer(overrides: accountOverrides(world));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).resendIn, CodeController.resendWait);
      async.elapse(const Duration(seconds: 59));
      expect(container.read(provider).resendIn, const Duration(seconds: 1));
      expect(container.read(provider).canResend, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(container.read(provider).canResend, isTrue);

      container.dispose();
    });
  });

  test('the right code signs in', () async {
    final container = containerOf();

    expect(
      await container.read(provider.notifier).verify(FakeAuthGateway.code),
      isTrue,
    );
    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'a@example.com'),
    );
  });

  test('a wrong code says so, and the wait goes on', () async {
    final container = containerOf();

    expect(await container.read(provider.notifier).verify('000000'), isFalse);
    expect(container.read(provider).problem, SignInProblem.wrongCode);
    expect(container.read(provider).isVerifying, isFalse);
    expect(container.read(provider).canResend, isFalse);
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/features/account/presentation/code_controller_test.dart`
Expected: a compile failure: `code_controller.dart` does not exist.

- [ ] **Step 3: Implement the state and the controller.**

`lib/features/account/presentation/states/code_state.dart`:

```dart
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

/// Screen 31's state (account UI spec §5.2): a check or a resend running,
/// the last problem, and the wait before "Resend code" works again.
final class CodeState {
  const CodeState({
    this.isVerifying = false,
    this.isResending = false,
    this.problem,
    this.resendIn = Duration.zero,
  });

  final bool isVerifying;
  final bool isResending;
  final SignInProblem? problem;

  /// Zero once a new code may be asked for.
  final Duration resendIn;

  bool get isBusy => isVerifying || isResending;

  bool get canResend => resendIn == Duration.zero && !isBusy;

  CodeState copyWith({Duration? resendIn}) => CodeState(
    isVerifying: isVerifying,
    isResending: isResending,
    problem: problem,
    resendIn: resendIn ?? this.resendIn,
  );
}
```

`lib/features/account/presentation/controllers/code_controller.dart`:

```dart
import 'dart:async';

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'code_controller.g.dart';

/// Screen 31's commands (account UI spec §5.2): check six digits, and ask
/// for a new code once the wait is over. One per address and purpose, so
/// the layer's code step never shares a countdown with screen 31's.
@riverpod
class CodeController extends _$CodeController {
  /// Between two codes to one address (spec §5.2).
  static const Duration resendWait = Duration(seconds: 60);
  static const Duration _tick = Duration(seconds: 1);

  Timer? _timer;

  @override
  CodeState build(String email, SignInPurpose purpose) {
    ref.onDispose(() => _timer?.cancel());
    _startWait();
    return const CodeState(resendIn: resendWait);
  }

  /// True when the code signed in.
  Future<bool> verify(String code) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || state.isBusy) return false;
    state = CodeState(isVerifying: true, resendIn: state.resendIn);
    SignInProblem? problem;
    try {
      await accounts.verifyCode(email, code);
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    if (ref.mounted) {
      state = CodeState(problem: problem, resendIn: state.resendIn);
    }
    return problem == null;
  }

  /// True when a new code is on its way; the wait starts again.
  Future<bool> resend() async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || !state.canResend) return false;
    state = const CodeState(isResending: true);
    SignInProblem? problem;
    try {
      await accounts.requestCode(email);
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    if (!ref.mounted) return problem == null;
    final isSent = problem == null;
    state = CodeState(
      problem: problem,
      resendIn: isSent ? resendWait : Duration.zero,
    );
    if (isSent) _startWait();
    return isSent;
  }

  void _startWait() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (timer) {
      final left = state.resendIn - _tick;
      if (left > Duration.zero) {
        state = state.copyWith(resendIn: left);
        return;
      }
      timer.cancel();
      state = state.copyWith(resendIn: Duration.zero);
    });
  }
}
```

Run `dart run build_runner build --delete-conflicting-outputs`, then run the controller test.
Expected: 3 pass.

- [ ] **Step 4: Write the failing screen test** `test/features/account/presentation/code_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  CodeScreen screen() =>
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++);

  accountTest('six digits sign in and say so', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountCodeSentTo('a@example.com')), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('a@example.com')), findsOneWidget);
  });

  accountTest('a wrong code clears the field and says so; the right one then '
      'signs in (Review Focus 4)', (tester, env, world) async {
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
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(signIns, 0);

    await tester.enterText(find.byType(TextField), '123456');
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest('Resend waits a minute, then sends a new code and waits again',
      (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    final waiting = find.widgetWithText(MxButton, _en.accountResendIn('1:00'));
    expect(tester.widget<MxButton>(waiting).onPressed, isNull);

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(find.text(_en.accountCodeResent), findsOneWidget);
    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run it.**

Run: `flutter test test/features/account/presentation/code_screen_test.dart`
Expected: a compile failure: `code_screen.dart` does not exist.

- [ ] **Step 6: Implement the form and screen 31.**

`lib/features/account/presentation/widgets/sections/code_form_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The code step of screen 31 and of the transition layer (account UI spec
/// §5.2): six digits check at once; a wrong code clears the field (plan
/// ruling 11); "Resend code" counts down its wait in its label.
class CodeFormWidget extends ConsumerStatefulWidget {
  const CodeFormWidget({
    super.key,
    required this.email,
    required this.purpose,
    required this.onUseAnotherEmail,
    this.onSignedIn,
  });

  final String email;
  final SignInPurpose purpose;
  final VoidCallback onUseAnotherEmail;

  /// The code signed in (the link; the layer follows the state instead).
  final VoidCallback? onSignedIn;

  @override
  ConsumerState<CodeFormWidget> createState() => _CodeFormWidgetState();
}

class _CodeFormWidgetState extends ConsumerState<CodeFormWidget> {
  static const int _clockDigits = 2;

  final _code = TextEditingController();

  CodeController get _controller => ref.read(
    codeControllerProvider(widget.email, widget.purpose).notifier,
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _changed(String text) async {
    if (text.length < MxTextField.codeLength) return;
    final isSignedIn = await _controller.verify(text);
    if (!mounted) return;
    if (!isSignedIn) {
      _code.clear();
      return;
    }
    widget.onSignedIn?.call();
  }

  Future<void> _resend() async {
    final isSent = await _controller.resend();
    if (!mounted || !isSent) return;
    showMxSnackbar(context, message: context.l10n.accountCodeResent);
  }

  /// The wait as m:ss.
  String _clock(Duration wait) {
    final seconds = wait.inSeconds % Duration.secondsPerMinute;
    return '${wait.inMinutes}:${seconds.toString().padLeft(_clockDigits, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(
      codeControllerProvider(widget.email, widget.purpose),
    );
    final problem = state.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountCodeSentTo(widget.email),
          style: context.texts.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _code,
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          isEnabled: !state.isVerifying,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null ? null : signInProblemText(l10n, problem),
        ),
        if (state.isVerifying)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: Center(child: MxSpinner(semanticLabel: l10n.commonLoading)),
          ),
        const SizedBox(height: AppSpacing.grouped),
        MxButton(
          label: state.canResend
              ? l10n.accountResend
              : l10n.accountResendIn(_clock(state.resendIn)),
          tone: MxButtonTone.text,
          isLoading: state.isResending,
          onPressed: state.canResend ? () => unawaited(_resend()) : null,
        ),
        MxButton(
          label: l10n.accountUseAnotherEmail,
          tone: MxButtonTone.text,
          onPressed: state.isVerifying ? null : widget.onUseAnotherEmail,
        ),
      ],
    );
  }
}
```

`lib/features/account/presentation/screens/code_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 31 (account UI spec §5.2): the six digits sent to [email].
class CodeScreen extends ConsumerWidget {
  const CodeScreen({super.key, required this.email, required this.onSignedIn});

  final String email;

  /// The account is attached: the flow closes (plan ruling 2).
  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void back() => unawaited(Navigator.of(context).maybePop());
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountCodeTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          CodeFormWidget(
            email: email,
            purpose: SignInPurpose.link,
            onUseAnotherEmail: back,
            onSignedIn: () {
              saySignedIn(context, ref.read(currentAccountProvider));
              onSignedIn();
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run both tests.**

Run: `flutter test test/features/account/presentation/code_controller_test.dart test/features/account/presentation/code_screen_test.dart`
Expected: 6 pass.

- [ ] **Step 8: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account test/features/account
git commit -m "feat(account): code step and screen 31, with the resend wait

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---
### Task 9: Welcome, screen 29

**Files:**
- Create: `lib/features/account/presentation/screens/welcome_screen.dart`
- Test: `test/features/account/presentation/welcome_screen_test.dart`

**Interfaces:**
- Consumes:
  - `welcomeDueProvider` (Task 4);
  - `signInControllerProvider`, `canLinkProvider`, `googleMark`, `saySignedIn` and `signInProblemText` (Task 5);
  - `startLinkSwitch` (Task 6).
- Produces: `WelcomeScreen({required VoidCallback onDone, required VoidCallback onEmail})`.

- [ ] **Step 1: Write the failing test** `test/features/account/presentation/welcome_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int dones;
  late int emails;

  setUp(() {
    dones = 0;
    emails = 0;
  });

  WelcomeScreen screen() =>
      WelcomeScreen(onDone: () => dones++, onEmail: () => emails++);

  final shown = welcomeDueProvider.overrideWithBuild((ref, _) => true);

  bool isDue(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(WelcomeScreen)),
  ).read(welcomeDueProvider);

  accountTest('Continue without an account answers Welcome for good and '
      'goes on', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueWithout));
    await _settle(tester);

    expect(dones, 1);
    expect(isDue(tester), isFalse);
    expect(await AccountDeviceRepositoryImpl(env.db).isWelcomeSeen(), isTrue);
  });

  accountTest('Google attaches the account, says so and goes on', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    expect(dones, 1);
    expect(isDue(tester), isFalse);
    expect(find.text(_en.accountSignedInAs('g@example.com')), findsOneWidget);
  });

  accountTest('Continue with email goes to screen 30', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueEmail));
    await _settle(tester);

    expect(emails, 1);
    expect(isDue(tester), isFalse);
  });

  accountTest('first launch offline: sign-in waits and says why, and '
      'without still leaves (Review Focus 1)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        shown,
        authStateOf(const LocalOnly()),
      ],
    );

    MxButton button(String label) =>
        tester.widget<MxButton>(find.widgetWithText(MxButton, label));
    expect(button(_en.accountContinueGoogle).onPressed, isNull);
    expect(button(_en.accountContinueEmail).onPressed, isNull);
    expect(find.text(_en.accountOfflineNote), findsOneWidget);

    await tester.tap(find.text(_en.accountContinueWithout));
    await _settle(tester);
    expect(dones, 1);
  });

  accountTest("a Google account that is another account's asks to merge, "
      'and the choice leaves Welcome', (tester, env, world) async {
    world.server.addUser(email: 'g@example.com');
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    expect(find.byType(MergeChoiceSheetWidget), findsOneWidget);
    expect(find.text(_en.accountTakenGoogle), findsOneWidget);

    await tester.tap(find.text(_en.accountContinue));
    await _settle(tester);

    expect(dones, 1);
    expect(world.state, isA<Transitioning>());
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/features/account/presentation/welcome_screen_test.dart`
Expected: a compile failure: `welcome_screen.dart` does not exist.

- [ ] **Step 3: Implement** `lib/features/account/presentation/screens/welcome_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 29 (account UI spec U1, §5.1, §6): the first launch invites an
/// account. The name, the promise and three benefits sit on top; the three
/// ways on sit in the thumb zone, Google the one fill. Every exit answers
/// Welcome for good. There is no back: Back leaves the app, as on any
/// root.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key, required this.onDone, required this.onEmail});

  /// Goes on to where the launch was headed.
  final VoidCallback onDone;

  /// Opens screen 30 for an email code (plan ruling 4).
  final VoidCallback onEmail;

  static const _link = SignInPurpose.link;

  /// The router lets go of Welcome first, so the navigation that follows
  /// is not sent back to it.
  void _leave(WidgetRef ref, VoidCallback next) {
    unawaited(ref.read(welcomeDueProvider.notifier).dismiss());
    next();
  }

  Future<void> _google(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(signInControllerProvider(_link).notifier)
        .continueWithGoogle();
    if (!context.mounted) return;
    switch (outcome) {
      case SignInOutcome.signedIn:
        saySignedIn(context, ref.read(currentAccountProvider));
        _leave(ref, onDone);
      case SignInOutcome.identityTaken:
        final isSwitching = await startLinkSwitch(context, ref);
        if (isSwitching && context.mounted) _leave(ref, onDone);
      case SignInOutcome.failed:
        final problem = ref.read(signInControllerProvider(_link)).problem;
        if (problem == null) return;
        showMxSnackbar(
          context,
          message: signInProblemText(context.l10n, problem),
        );
      case SignInOutcome.codeSent || SignInOutcome.none:
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canLink = ref.watch(canLinkProvider);
    final isRunning = ref.watch(signInControllerProvider(_link)).isRunning;
    final canSignIn = canLink && !isRunning;
    return MxAppShell(
      body: SafeArea(
        bottom: false,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.major),
            // Plan U5: a tile until MemoX has its own icon (UI-base debt).
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: MxIconTile(
                icon: AppIcons.library,
                size: MxIconTileSize.large,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Semantics(
              header: true,
              child: Text(l10n.appTitle, style: context.textStyles.screenTitle),
            ),
            const SizedBox(height: AppSpacing.control),
            Text(
              l10n.welcomeLead,
              style: context.texts.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            MxSection(
              children: [
                MxSettingsRow(
                  label: l10n.welcomeBenefitReinstall,
                  icon: AppIcons.safe,
                ),
                MxSettingsRow(
                  label: l10n.welcomeBenefitPhones,
                  icon: AppIcons.devices,
                ),
                MxSettingsRow(
                  label: l10n.welcomeBenefitOffline,
                  icon: AppIcons.offline,
                ),
              ],
            ),
            if (!canLink) MxNote(text: l10n.accountOfflineNote),
          ],
        ),
      ),
      footer: MxFooterBar(
        child: Column(
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
            MxButton(
              label: l10n.accountContinueWithout,
              tone: MxButtonTone.text,
              isBlock: true,
              onPressed: isRunning ? null : () => _leave(ref, onDone),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test.**

Run: `flutter test test/features/account/presentation/welcome_screen_test.dart`
Expected: 5 pass.

- [ ] **Step 5: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account test/features/account
git commit -m "feat(account): Welcome, screen 29 (U1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 10: The transition layer, its Back and the notices

**Files:**
- Create: `lib/features/account/presentation/states/account_step_state.dart`
- Create: `lib/features/account/presentation/providers/unsent_count_provider.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart`
- Modify: `lib/features/account/presentation/widgets/support/account_copy_widget.dart` (step copy)
- Modify: `lib/app/app.dart` (`builder:`)
- Test: `test/features/account/presentation/account_step_state_test.dart`, `test/features/account/presentation/account_transition_layer_test.dart`

**Interfaces:**
- Consumes:
  - `SignInFormWidget` (Task 7) and `CodeFormWidget` (Task 8);
  - from P2: `AuthState` (`Transitioning`, `Recovering`), `AccountTransition`, `AccountCoordinator.retry()`, `cancelSwitch()`, `signOut({bool discardUnsent})` and `notices`, and `syncControlProvider`.
- Produces:
  - `enum AccountStep { sending, preparing, merging, downloading, signingOut, deleting }`;
  - `AccountStep accountStepOf(AccountTransition t)` and `bool canCancelSwitch(AccountTransition t)`;
  - `typedef BlockingView` and `BlockingView? blockingViewOf(AuthState? state)`;
  - `unsentCountProvider` (`Future<int>`);
  - `accountStepText(AppLocalizations, AccountStep)`;
  - `AccountTransitionLayerWidget({required GlobalKey<NavigatorState> navigatorKey})` and `AccountLayerHostWidget({required BackButtonDispatcher backButtons, required Widget child})`.

- [ ] **Step 1: Write the failing unit test** `test/features/account/presentation/account_step_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';

import '../../../support/account_harness.dart';

void main() {
  const merge = TransitionChoice.merge;
  const discard = TransitionChoice.discard;

  test('a switch sends, prepares, merges or downloads by its stage', () {
    AccountStep step(TransitionStage stage, TransitionChoice choice) =>
        accountStepOf(
          transitionOf(TransitionKind.switchAccount, stage, choice: choice),
        );

    expect(step(TransitionStage.started, merge), AccountStep.sending);
    expect(step(TransitionStage.sourcePushed, merge), AccountStep.preparing);
    expect(step(TransitionStage.claimed, merge), AccountStep.preparing);
    expect(step(TransitionStage.targetSignedIn, merge), AccountStep.merging);
    expect(
      step(TransitionStage.targetSignedIn, discard),
      AccountStep.downloading,
    );
    expect(step(TransitionStage.localCleared, merge), AccountStep.downloading);
  });

  test('sign-out sends first; deletion deletes first; both then sign out',
      () {
    AccountStep step(TransitionKind kind, TransitionStage stage) =>
        accountStepOf(transitionOf(kind, stage));

    expect(
      step(TransitionKind.signOut, TransitionStage.started),
      AccountStep.sending,
    );
    expect(
      step(TransitionKind.signOut, TransitionStage.signedOut),
      AccountStep.signingOut,
    );
    expect(
      step(TransitionKind.delete, TransitionStage.started),
      AccountStep.deleting,
    );
    expect(
      step(TransitionKind.delete, TransitionStage.serverDeleted),
      AccountStep.signingOut,
    );
    expect(
      step(TransitionKind.clearToAnon, TransitionStage.started),
      AccountStep.signingOut,
    );
  });

  test('a switch can be cancelled only before the target signs in', () {
    bool can(TransitionStage stage) => canCancelSwitch(
      transitionOf(TransitionKind.switchAccount, stage, choice: merge),
    );

    expect(can(TransitionStage.claimed), isTrue);
    expect(can(TransitionStage.targetSignedIn), isFalse);
    expect(
      canCancelSwitch(
        transitionOf(TransitionKind.signOut, TransitionStage.started),
      ),
      isFalse,
    );
  });

  test('only a transition that blocks writes shows the layer', () {
    final signOut = transitionOf(
      TransitionKind.signOut,
      TransitionStage.started,
    );
    final recovery = transitionOf(
      TransitionKind.anonRecovery,
      TransitionStage.started,
    );
    const offline = OfflineFailure(cause: 'test');

    final view = blockingViewOf(Transitioning(signOut, error: offline));
    expect(view?.transition, signOut);
    expect(view?.error, offline);
    expect(blockingViewOf(Recovering(signOut, isStuck: true))?.isStuck, isTrue);
    expect(blockingViewOf(Transitioning(recovery)), isNull);
    expect(
      blockingViewOf(
        const Ready(
          AccountUser(id: 'u', isAnonymous: true, role: AccountRole.user),
        ),
      ),
      isNull,
    );
    expect(blockingViewOf(null), isNull);
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/features/account/presentation/account_step_state_test.dart`
Expected: a compile failure: `account_step_state.dart` does not exist.

- [ ] **Step 3: Implement the states, the count and the copy.**

`lib/features/account/presentation/states/account_step_state.dart`:

```dart
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

/// The step the transition layer names (account UI spec §5.4).
enum AccountStep { sending, preparing, merging, downloading, signingOut, deleting }

/// What the layer shows: a transition that blocks writes, and how it stands.
typedef BlockingView = ({
  AccountTransition transition,
  bool isAwaitingTargetSignIn,
  Failure? error,
  bool isStuck,
});

/// The layer's view of [state], or null when nothing blocks. An anonymous
/// recovery lets writes through, so it shows nothing (auth spec §3.2).
BlockingView? blockingViewOf(AuthState? state) => switch (state) {
  Transitioning(
    :final transition,
    :final isAwaitingTargetSignIn,
    :final error,
  )
      when transition.blocksWrites =>
    (
      transition: transition,
      isAwaitingTargetSignIn: isAwaitingTargetSignIn,
      error: error,
      isStuck: false,
    ),
  Recovering(
    :final transition,
    :final isAwaitingTargetSignIn,
    :final error,
    :final isStuck,
  )
      when transition.blocksWrites =>
    (
      transition: transition,
      isAwaitingTargetSignIn: isAwaitingTargetSignIn,
      error: error,
      isStuck: isStuck,
    ),
  _ => null,
};

/// The step for the stage the record reached. The coordinator saves each
/// stage before the next step, so the stage names the step running.
AccountStep accountStepOf(AccountTransition t) => switch (t.kind) {
  TransitionKind.switchAccount => switch (t.stage) {
    TransitionStage.started => AccountStep.sending,
    TransitionStage.sourcePushed ||
    TransitionStage.claimed => AccountStep.preparing,
    TransitionStage.targetSignedIn when t.merges => AccountStep.merging,
    _ => AccountStep.downloading,
  },
  TransitionKind.signOut =>
    t.stage == TransitionStage.started
        ? AccountStep.sending
        : AccountStep.signingOut,
  TransitionKind.delete =>
    t.stage == TransitionStage.started
        ? AccountStep.deleting
        : AccountStep.signingOut,
  TransitionKind.clearToAnon ||
  TransitionKind.anonRecovery => AccountStep.signingOut,
};

/// Auth spec #22: a switch goes back to where it started only before the
/// target signs in.
bool canCancelSwitch(AccountTransition t) =>
    t.kind == TransitionKind.switchAccount &&
    t.stage.isBefore(TransitionStage.targetSignedIn);
```

`lib/features/account/presentation/providers/unsent_count_provider.dart`:

```dart
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unsent_count_provider.g.dart';

/// The changes not sent yet (account UI spec §5.4): what signing out now,
/// offline, would lose.
@riverpod
Future<int> unsentCount(Ref ref) =>
    ref.watch(syncControlProvider).pendingCount();
```

In `account_copy_widget.dart`, add the import `package:memox/features/account/presentation/states/account_step_state.dart` and:

```dart
/// The layer's line for [step] (spec §5.4).
String accountStepText(AppLocalizations l10n, AccountStep step) =>
    switch (step) {
      AccountStep.sending => l10n.accountStepSending,
      AccountStep.preparing => l10n.accountStepPreparing,
      AccountStep.merging => l10n.accountStepMerging,
      AccountStep.downloading => l10n.accountStepDownloading,
      AccountStep.signingOut => l10n.accountStepSigningOut,
      AccountStep.deleting => l10n.accountStepDeleting,
    };
```

Run `dart run build_runner build --delete-conflicting-outputs`, then run the unit test.
Expected: 4 pass.

- [ ] **Step 4: Write the failing layer test** `test/features/account/presentation/account_transition_layer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/unsent_count_provider.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../../support/account_harness.dart';
import '../../../support/fake_auth_server.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// The app on Settings › Theme, a page a stray Back would pop.
Future<void> _onThemePage(WidgetTester tester, LibraryEnv env, AuthWorld world) async {
  await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
  await tester.tap(
    find.descendant(
      of: find.byType(MxBottomNav),
      matching: find.text(_en.navSettings),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.settingsTheme));
  await _settle(tester);
  expect(find.byType(ThemeScreen), findsOneWidget);
}

void main() {
  accountTest('a switch covers the app, keeps Back inside, and Cancel puts '
      'the page back (Review Focus 2)', (tester, env, world) async {
    await _onThemePage(tester, env, world);

    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);
    expect(find.text(_en.accountTargetLine), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);

    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    expect(find.byType(CodeFormWidget), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(CodeFormWidget), findsNothing);
    expect(find.byType(SignInFormWidget), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(find.byType(ThemeScreen), findsOneWidget);
    expect(world.state, isA<Ready>());
  });

  accountTest('the layer signs in the target, and the switch finishes '
      'behind it', (tester, env, world) async {
    world.server.addUser(email: 'b@example.com');
    await _onThemePage(tester, env, world);
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(CodeFormWidget),
        matching: find.byType(TextField),
      ),
      FakeAuthGateway.code,
    );
    await _settle(tester);
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'b@example.com'),
    );
  });

  accountTest('no connection says the data is safe, and Retry carries on', (
    tester,
    env,
    world,
  ) async {
    await _onThemePage(tester, env, world);
    world.network.goOffline();
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.discard,
      targetHint: 'b@example.com',
    );
    await _settle(tester);

    expect(find.text(_en.accountLayerOffline), findsOneWidget);
    expect(find.text(_en.commonCancel), findsOneWidget);

    world.network.goOnline();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.byType(SignInFormWidget), findsOneWidget);
  });

  accountTest('a refused merge is said once the device is back', (
    tester,
    env,
    world,
  ) async {
    world.server.addUser(email: 'b@example.com');
    await _onThemePage(tester, env, world);
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.merge,
      targetHint: 'b@example.com',
    );
    await _settle(tester);
    world.server.claims.clear();

    await world.coordinator.requestCode('b@example.com');
    await world.coordinator.verifyCode('b@example.com', FakeAuthGateway.code);
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(find.text(_en.accountMergeNotDone), findsOneWidget);
  });

  libraryTest('a sign-out stopped offline offers to go on and lose the '
      'changes', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(TransitionKind.signOut, TransitionStage.started),
            error: const OfflineFailure(cause: 'test'),
          ),
        ),
        unsentCountProvider.overrideWith((ref) async => 2),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerOffline), findsOneWidget);
    expect(find.text(_en.accountSignOutLosing(2)), findsOneWidget);
    expect(find.text(_en.commonCancel), findsNothing);
  });

  libraryTest('stuck says the data is safe and offers only Retry', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Recovering(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.merged,
              choice: TransitionChoice.merge,
            ),
            isStuck: true,
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountLayerStuck), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.text(_en.commonCancel), findsNothing);
  });

  libraryTest('running, it names the step and says closing loses nothing', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.targetSignedIn,
              choice: TransitionChoice.merge,
            ),
          ),
        ),
      ],
    );
    await tester.pump();

    expect(find.text(_en.accountStepMerging), findsWidgets);
    expect(find.text(_en.accountSafeToClose), findsOneWidget);
  });
}
```

`settingsTheme` is the row label the existing settings tests tap. If its key has another name, use the one `test/app/settings_routes_test.dart` uses. `account_coordinator.dart` is imported so the `beginSwitch`, `requestCode` and `verifyCode` extension methods resolve.

- [ ] **Step 5: Run it.**

Run: `flutter test test/features/account/presentation/account_transition_layer_test.dart`
Expected: a compile failure: `account_transition_layer_widget.dart` does not exist.

- [ ] **Step 6: Implement the layer.** `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/providers/unsent_count_provider.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_copy_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The transition layer (account UI spec U4, §5.4, §6): over the whole app
/// while a switch, sign-out, deletion or clear runs. Its own navigator
/// holds the target sign-in's code step; the host sends Back here.
class AccountTransitionLayerWidget extends StatelessWidget {
  const AccountTransitionLayerWidget({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const _LayerPage(),
      transitionDuration: Duration.zero,
    ),
  );
}

class _LayerPage extends ConsumerWidget {
  const _LayerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = blockingViewOf(ref.watch(authStateProvider).value);
    if (view == null) return const SizedBox.shrink();
    final canCancel = canCancelSwitch(view.transition) && !view.isStuck;
    final isSigningIn = view.isAwaitingTargetSignIn && !view.isStuck;
    return MxAppShell(
      appBar: canCancel
          ? MxAppBar(
              titleWidget: const SizedBox.shrink(),
              density: MxAppBarDensity.content,
              actions: [
                MxButton(
                  label: context.l10n.commonCancel,
                  tone: MxButtonTone.text,
                  size: MxButtonSize.small,
                  onPressed: () => unawaited(_cancel(context, ref)),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: isSigningIn
            ? _TargetSignIn(targetHint: view.transition.targetHint)
            : _Progress(view: view),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(accountCoordinatorProvider)?.cancelSwitch();
    } on Failure catch (error) {
      if (context.mounted) {
        showMxSnackbar(context, message: context.l10n.failure(error));
      }
    } on StateError {
      // The switch passed the target sign-in meanwhile; the layer follows.
      return;
    }
  }
}

/// The target sign-in, first the address, then the code on the layer's
/// navigator.
class _TargetSignIn extends StatelessWidget {
  const _TargetSignIn({required this.targetHint});

  final String? targetHint;

  @override
  Widget build(BuildContext context) => MxScreenScroll(
    children: [
      const SizedBox(height: AppSpacing.gutter),
      SignInFormWidget(
        purpose: SignInPurpose.target,
        initialEmail: targetHint,
        onCodeSent: (email) => unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _LayerCodePage(email)),
          ),
        ),
      ),
    ],
  );
}

/// The code step inside the layer. It closes itself once the target has
/// signed in: the switch then runs on under the progress.
class _LayerCodePage extends ConsumerWidget {
  const _LayerCodePage(this.email);

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (_, next) {
      final view = blockingViewOf(next.value);
      if (view == null || !view.isAwaitingTargetSignIn) {
        unawaited(Navigator.of(context).maybePop());
      }
    });
    final l10n = context.l10n;
    void back() => unawaited(Navigator.of(context).maybePop());
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountCodeTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          CodeFormWidget(
            email: email,
            purpose: SignInPurpose.target,
            onUseAnotherEmail: back,
          ),
        ],
      ),
    );
  }
}

/// The step, or what stopped it and how to go on (spec §5.4).
class _Progress extends ConsumerWidget {
  const _Progress({required this.view});

  final BlockingView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final error = view.error;
    final isStopped = error != null || view.isStuck;
    final step = accountStepText(l10n, accountStepOf(view.transition));
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.pageEnd),
        if (isStopped) ...[
          Semantics(
            liveRegion: true,
            child: MxInlineBanner(
              tone: MxBannerTone.warning,
              message: view.isStuck
                  ? l10n.accountLayerStuck
                  : error is OfflineFailure
                  ? l10n.accountLayerOffline
                  : l10n.accountLayerFailed,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          MxButton(
            label: l10n.commonRetry,
            isBlock: true,
            onPressed: () => unawaited(_retry(ref)),
          ),
          if (_isSignOutStoppedOffline(error)) ...[
            const SizedBox(height: AppSpacing.grouped),
            const _SignOutNow(),
          ],
        ] else ...[
          Center(
            child: MxSpinner(size: MxSpinnerSize.large, semanticLabel: step),
          ),
          const SizedBox(height: AppSpacing.section),
          Semantics(
            liveRegion: true,
            child: Text(
              step,
              textAlign: TextAlign.center,
              style: context.textStyles.screenTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Text(
            l10n.accountSafeToClose,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Auth spec #39: offline, a sign-out waits to send unless its loss is
  /// accepted (plan ruling 10 of P2).
  bool _isSignOutStoppedOffline(Failure? error) =>
      view.transition.kind == TransitionKind.signOut &&
      view.transition.choice != TransitionChoice.discard &&
      (error is OfflineFailure || error is UnsentChangesFailure);

  Future<void> _retry(WidgetRef ref) async {
    try {
      await ref.read(accountCoordinatorProvider)?.retry();
    } on Failure catch (error, stackTrace) {
      // The state carries what stopped; the log keeps why.
      appLogger.warning(
        'account.retry_failed',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// "Sign out now and lose n changes": the offline way on (spec §5.4).
class _SignOutNow extends ConsumerWidget {
  const _SignOutNow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unsentCountProvider).value;
    if (count == null) return const SizedBox.shrink();
    return MxButton(
      label: context.l10n.accountSignOutLosing(count),
      tone: MxButtonTone.dangerSoft,
      isBlock: true,
      onPressed: () => unawaited(
        ref.read(accountCoordinatorProvider)?.signOut(discardUnsent: true),
      ),
    );
  }
}
```

The file is about 290 lines, under the 400-line warning.

- [ ] **Step 7: Implement the host.** `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The app root's account layer (account UI spec U4, §5.4). While a
/// transition blocks writes, it covers the router, hides the app from
/// TalkBack, and takes the system Back with priority over the router's
/// root dispatcher (plan ruling 9). It also says the coordinator's one-off
/// notices (plan ruling 8).
class AccountLayerHostWidget extends ConsumerStatefulWidget {
  const AccountLayerHostWidget({
    super.key,
    required this.backButtons,
    required this.child,
  });

  /// The router's root dispatcher.
  final BackButtonDispatcher backButtons;

  /// The router.
  final Widget child;

  @override
  ConsumerState<AccountLayerHostWidget> createState() =>
      _AccountLayerHostWidgetState();
}

class _AccountLayerHostWidgetState
    extends ConsumerState<AccountLayerHostWidget> {
  final _layerNavigator = GlobalKey<NavigatorState>();
  ChildBackButtonDispatcher? _heldBack;
  StreamSubscription<AccountNotice>? _notices;

  @override
  void initState() {
    super.initState();
    _notices = ref.read(accountCoordinatorProvider)?.notices.listen(_say);
    ref.listenManual(
      authStateProvider,
      (_, next) => _holdBack(isBlocking: blockingViewOf(next.value) != null),
      fireImmediately: true,
    );
  }

  void _holdBack({required bool isBlocking}) {
    final held = _heldBack;
    if (isBlocking && held == null) {
      _heldBack = widget.backButtons.createChildBackButtonDispatcher()
        ..addCallback(_onBack)
        ..takePriority();
      return;
    }
    if (isBlocking || held == null) return;
    held.removeCallback(_onBack);
    widget.backButtons.forget(held);
    _heldBack = null;
  }

  /// Back steps back inside the layer, never out of it.
  Future<bool> _onBack() async {
    await _layerNavigator.currentState?.maybePop();
    return true;
  }

  void _say(AccountNotice notice) {
    if (!mounted) return;
    final l10n = context.l10n;
    showMxSnackbar(
      context,
      message: switch (notice) {
        MergeNotDone() => l10n.accountMergeNotDone,
        DeleteRefused(failure: LastAdminFailure()) => l10n.accountLastAdmin,
        DeleteRefused() => l10n.accountDeleteRefused,
      },
    );
  }

  @override
  void dispose() {
    unawaited(_notices?.cancel());
    _holdBack(isBlocking: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBlocking =
        blockingViewOf(ref.watch(authStateProvider).value) != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (isBlocking)
          BlockSemantics(
            child: AccountTransitionLayerWidget(navigatorKey: _layerNavigator),
          ),
      ],
    );
  }
}
```

- [ ] **Step 8: Host it at the app root.** In `lib/app/app.dart`, import `package:memox/features/account/presentation/widgets/sections/account_layer_host_widget.dart` and add to `MaterialApp.router(...)`, after `routerConfig: _router,`:

```dart
      // Account UI spec U4: the transition layer sits above the router,
      // with the router's Back dispatcher to take priority over.
      builder: (context, child) => AccountLayerHostWidget(
        backButtons: _router.backButtonDispatcher,
        child: child!,
      ),
```

Update the class doc comment to name "the account transition layer (account UI spec U4)" among what the composition root holds.

- [ ] **Step 9: Run the tests.**

Run: `flutter test test/features/account/presentation/account_transition_layer_test.dart test/features/account/presentation/account_step_state_test.dart test/app`
Expected: all pass. The existing app tests are unchanged, because with no coordinator the host only wraps the router.

- [ ] **Step 10: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/features/account lib/app/app.dart test/features/account
git commit -m "feat(account): transition layer at the app root, with Back and notices (U4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---
### Task 11: Routes, the redirect, Settings › Account, and the admin gate's wait

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Create: `lib/app/router/account_redirect.dart`
- Create: `lib/app/router/account_routes.dart`
- Create: `lib/app/router/study_route_screens.dart`, which takes `_studyEntry` and `_studyOptions` out of `app_router.dart` so that file stays under 500 lines
- Modify: `lib/app/router/app_router.dart`, `lib/app/app.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart` (the `accountSection` slot)
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart`
- Test:
  - `test/app/account_redirect_test.dart`
  - `test/app/account_routes_test.dart`
  - `test/features/account/presentation/account_settings_section_test.dart`
  - `test/features/monitoring/presentation/monitoring_admin_gate_test.dart`

**Interfaces:**
- Consumes: `WelcomeScreen` (Task 9), `SignInScreen` (Task 7), `CodeScreen` (Task 8), `welcomeDueProvider` (Task 4) and `canLinkProvider` (Task 5).
- Produces:
  - in `AppRoutes`: `welcome`, `welcomeFromParam`, `welcomeFrom(String)`, `settingsSignInChild`, `settingsSignIn`, `settingsSignInCodeChild`, `settingsSignInCode`, `accountModeParam`, `accountEmailParam`, `accountLinkMode`, `settingsSignInLink` and `settingsSignInCodeLink(String)`;
  - `String? accountRedirect(Uri location, {required bool isWelcomeDue, required bool hasAccount})` and `AccountRouteRefresh`;
  - `buildAppRouter({bool hasGallery, Listenable? refreshListenable, GoRouterRedirect? redirect})`;
  - `AccountSettingsSectionWidget({required VoidCallback onSignIn})`;
  - `SettingsScreen({..., Widget? accountSection})`.

- [ ] **Step 1: Write the failing redirect test** `test/app/account_redirect_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/account_redirect.dart';
import 'package:memox/app/router/app_routes.dart';

void main() {
  String? redirect(
    String location, {
    bool isWelcomeDue = false,
    bool hasAccount = false,
  }) => accountRedirect(
    Uri.parse(location),
    isWelcomeDue: isWelcomeDue,
    hasAccount: hasAccount,
  );

  test('Welcome takes any location while it is due, and keeps it', () {
    expect(redirect('/decks', isWelcomeDue: true), '/welcome?from=%2Fdecks');
    expect(
      redirect('/progress', isWelcomeDue: true),
      '/welcome?from=%2Fprogress',
    );
    expect(redirect('/welcome?from=%2Fdecks', isWelcomeDue: true), isNull);
  });

  test('nothing redirects once Welcome is answered', () {
    expect(redirect('/decks'), isNull);
    expect(redirect(AppRoutes.settingsSignInLink), isNull);
  });

  test('the attach flow closes once the device holds an account', () {
    expect(
      redirect(AppRoutes.settingsSignInLink, hasAccount: true),
      AppRoutes.settings,
    );
    expect(
      redirect(AppRoutes.settingsSignInCodeLink('a@example.com'), hasAccount: true),
      AppRoutes.settings,
    );
    expect(
      redirect('${AppRoutes.settingsSignIn}?mode=reauth', hasAccount: true),
      isNull,
      reason: 'P3b re-auth signs in an account',
    );
  });

  test('the paths are what the routes register', () {
    expect(AppRoutes.settingsSignInLink, '/settings/sign-in?mode=link');
    expect(
      AppRoutes.settingsSignInCodeLink('a@example.com'),
      '/settings/sign-in/code?mode=link&email=a%40example.com',
    );
    expect(AppRoutes.welcomeFrom('/decks'), '/welcome?from=%2Fdecks');
  });
}
```

- [ ] **Step 2: Run it.**

Run: `flutter test test/app/account_redirect_test.dart`
Expected: a compile failure: `account_redirect.dart` does not exist.

- [ ] **Step 3: Add the paths and the redirect.**

In `lib/app/router/app_routes.dart`, after the Monitoring block:

```dart
  /// The first-launch Welcome (screen 29, account UI spec §4) and the
  /// location the launch was headed to.
  static const String welcome = '/welcome';
  static const String welcomeFromParam = 'from';

  static String welcomeFrom(String location) => Uri(
    path: welcome,
    queryParameters: {welcomeFromParam: location},
  ).toString();

  /// Attaching an account (screens 30 and 31), relative to [settings] on
  /// the root navigator like Sync (P3a plan ruling 1). The mode names the
  /// flow: P3a has the link; P3b adds re-auth.
  static const String settingsSignInChild = 'sign-in';
  static const String settingsSignIn = '$settings/$settingsSignInChild';
  static const String settingsSignInCodeChild = 'code';
  static const String settingsSignInCode =
      '$settingsSignIn/$settingsSignInCodeChild';
  static const String accountModeParam = 'mode';
  static const String accountEmailParam = 'email';
  static const String accountLinkMode = 'link';
  static const String settingsSignInLink =
      '$settingsSignIn?$accountModeParam=$accountLinkMode';

  static String settingsSignInCodeLink(String email) => Uri(
    path: settingsSignInCode,
    queryParameters: {
      accountModeParam: accountLinkMode,
      accountEmailParam: email,
    },
  ).toString();
```

`lib/app/router/account_redirect.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/app/router/app_routes.dart';

/// The router's two account rules (account UI spec §4). Signing in stays
/// optional, so nothing else redirects:
/// - Welcome until it is answered, keeping the location asked for;
/// - no attach flow once the device holds an account (P3a plan ruling 2).
String? accountRedirect(
  Uri location, {
  required bool isWelcomeDue,
  required bool hasAccount,
}) {
  if (isWelcomeDue && location.path != AppRoutes.welcome) {
    return AppRoutes.welcomeFrom(location.toString());
  }
  final mode =
      location.queryParameters[AppRoutes.accountModeParam] ??
      AppRoutes.accountLinkMode;
  final isAttach =
      location.path.startsWith(AppRoutes.settingsSignIn) &&
      mode == AppRoutes.accountLinkMode;
  if (hasAccount && isAttach) return AppRoutes.settings;
  return null;
}

/// Tells the router to run [accountRedirect] again: the welcome flag or
/// the account changed.
final class AccountRouteRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
```

Run the redirect test. Expected: 4 pass.

- [ ] **Step 4: Write the failing section and gate tests.**

`test/features/account/presentation/account_settings_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  late int opens;

  setUp(() => opens = 0);

  Widget section() => Scaffold(
    body: AccountSettingsSectionWidget(onSignIn: () => opens++),
  );

  accountTest('an anonymous device is offered Sign in', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.accountSignInHint), findsOneWidget);
    await tester.tap(find.text(_en.accountSignIn));
    expect(opens, 1);
  });

  accountTest('offline, Sign in waits and says when it will work', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: [...accountOverrides(world), authStateOf(const LocalOnly())],
    );

    expect(find.text(_en.accountSignInLater), findsOneWidget);
    final row = tester.widget<MxSettingsRow>(find.byType(MxSettingsRow));
    expect(row.isEnabled, isFalse);
  });

  accountTest('an attached account shows its email', (tester, env, world) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: accountOverrides(world),
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountSignedInHint), findsOneWidget);
  });

  libraryTest('a build that cannot sign in shows nothing', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: [accountCoordinatorProvider.overrideWithValue(null)],
    );

    expect(find.byType(MxSettingsRow), findsNothing);
  });
}
```

If `MxListSectionHeader` does not upper-case its label in the widget tree (check `mx_list_section_header.dart`), use `find.text(_en.accountSection)`.

`test/features/monitoring/presentation/monitoring_admin_gate_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

void main() {
  libraryTest('while the account is still being confirmed, the gate waits '
      'instead of refusing (plan ruling 13)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringAdminGateWidget(child: Text('logs')),
      overrides: [
        isAdminProvider.overrideWithValue(false),
        authStateOf(const Validating(null)),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byType(MxEmptyState), findsNothing);
    expect(find.text('logs'), findsNothing);
  });

  libraryTest('a settled non-admin is refused', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringAdminGateWidget(child: Text('logs')),
      overrides: [
        isAdminProvider.overrideWithValue(false),
        authStateOf(const LocalOnly()),
      ],
    );

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('logs'), findsNothing);
  });
}
```

- [ ] **Step 5: Run them.**

Run: `flutter test test/features/account/presentation/account_settings_section_test.dart test/features/monitoring/presentation/monitoring_admin_gate_test.dart`
Expected: a compile failure (the section widget does not exist), and the gate's first test fails.

- [ ] **Step 6: Implement the section and the gate's wait.**

`lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's first section (account UI spec §5.5): attach an account, or
/// the account attached. Settings takes it as a slot, so the two features
/// stay apart; `app/` composes them. A build that cannot sign in shows
/// nothing.
class AccountSettingsSectionWidget extends ConsumerWidget {
  const AccountSettingsSectionWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its link mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountCoordinatorProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final account = switch (ref.watch(authStateProvider).value) {
      Ready(:final user) when !user.isAnonymous => user,
      Validating(:final last?) when !last.isAnonymous => last,
      ReauthRequired(:final last) => last,
      _ => null,
    };
    final canLink = ref.watch(canLinkProvider);
    return MxSection(
      title: l10n.accountSection,
      children: [
        if (account == null)
          MxSettingsRow(
            label: l10n.accountSignIn,
            subtitle: canLink ? l10n.accountSignInHint : l10n.accountSignInLater,
            icon: AppIcons.account,
            isEnabled: canLink,
            onTap: canLink ? onSignIn : null,
          )
        else
          // P3b adds the chevron to screen 32 (plan ruling 5).
          MxSettingsRow(
            label: account.email ?? l10n.accountSignedIn,
            subtitle: l10n.accountSignedInHint,
            icon: AppIcons.account,
          ),
      ],
    );
  }
}
```

In `monitoring_admin_gate_widget.dart`:
- import `package:memox/core/auth/auth_state.dart` and `package:memox/shared/widgets/mx_skeleton.dart`;
- add after `if (ref.watch(isAdminProvider)) return child;`:

```dart
    // While the account is still being confirmed, isAdmin is not known yet
    // (account UI spec §4): wait instead of refusing.
    final isSettling = switch (ref.watch(authStateProvider).value) {
      null || Booting() || Bootstrapping() || Validating() => true,
      _ => false,
    };
```

- in the body's `children`, replace the lone `MxEmptyState(...)` with:

```dart
          if (isSettling)
            MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _waitRows)
          else
            MxEmptyState(
              // the existing arguments, unchanged
            ),
```

- and add `static const int _waitRows = 3;` to the class.

In `settings_screen.dart`, add the constructor parameter `this.accountSection,` and the field:

```dart
  /// The Account section, which `app/` composes from the account feature
  /// (account UI spec §5.5); first in the list.
  final Widget? accountSection;
```

   Then add `?accountSection,` as the first child of the loaded `MxScreenScroll`.

- [ ] **Step 7: Run the section and gate tests, and Monitoring's own tests.**

Run: `flutter test test/features/account/presentation/account_settings_section_test.dart test/features/monitoring`
Expected: all pass.

- [ ] **Step 8: Write the failing app-routes test** `test/app/account_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/account_harness.dart';
import '../support/fake_auth_server.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

void main() {
  accountTest('Welcome takes the launch while it is due, and Continue '
      'without an account lands where it was headed', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        welcomeDueProvider.overrideWithBuild((ref, _) => true),
      ],
    );

    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountContinueWithout));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(DeckLevelScreen), findsOneWidget);
    expect(await AccountDeviceRepositoryImpl(env.db).isWelcomeSeen(), isTrue);
  });

  accountTest('a deep link while Welcome is due returns there after it '
      '(Review Focus 5)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...accountOverrides(world),
        welcomeDueProvider.overrideWithBuild((ref, _) => true),
      ],
    );

    _router(tester).go(AppRoutes.progress);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text(_en.accountContinueWithout));
    await tester.pumpAndSettle();
    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.progress,
    );
  });

  accountTest('Settings › Sign in, the code, and the flow ends on Settings '
      'showing the account', (tester, env, world) async {
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    await tester.tap(
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navSettings),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.accountSignIn));
    await _settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.tap(find.text(_en.accountSendCode));
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await _settle(tester);
    await _settle(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(CodeScreen), findsNothing);
    expect(find.text('a@example.com'), findsOneWidget);
  });

  accountTest('the attach flow is closed to a device that holds an account', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));

    _router(tester).go(AppRoutes.settingsSignInLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  libraryTest('a build that cannot sign in has no Account section and no '
      'Welcome', (tester, env) async {
    await pumpMemoxApp(tester, env);

    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navSettings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_en.accountSignIn), findsNothing);
  });
}
```

- [ ] **Step 9: Run it.**

Run: `flutter test test/app/account_routes_test.dart`
Expected: FAIL. No `/welcome` route exists and the redirect is not wired, so Welcome never shows and the Settings row is absent.

- [ ] **Step 10: Wire the routes.**

`lib/app/router/study_route_screens.dart` takes `_studyEntry` and `_studyOptions` from `app_router.dart` unchanged, made public as `studyEntryScreen(BuildContext context, String deckId)` and `studyOptionsScreen(BuildContext context, String deckId)`, with their doc comments and imports: `StudyEntryScreen`, `StudyOptionsScreen`, `DeckStudyHeaderWidget`, `AppRoutes`, `go_router`, `dart:async` and `l10n_context`. Replace the two call sites in `app_router.dart`, and remove the imports that only they used.

`lib/app/router/account_routes.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_settings_section_widget.dart';

/// Screen 29 (account UI spec §5.1): the first launch, over everything.
/// Its exits go on to where the launch was headed; email opens screen 30
/// with Settings under it (P3a plan ruling 4).
GoRoute welcomeRoute() => GoRoute(
  path: AppRoutes.welcome,
  builder: (context, state) {
    final from =
        state.uri.queryParameters[AppRoutes.welcomeFromParam] ??
        AppRoutes.decks;
    return WelcomeScreen(
      onDone: () => context.go(from),
      onEmail: () => context.go(AppRoutes.settingsSignInLink),
    );
  },
);

/// Screens 30 and 31 (spec §5.2) under Settings, on the root navigator
/// like Sync (plan ruling 1). The flow ends on Settings (plan ruling 2).
GoRoute signInRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsSignInChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => SignInScreen(
    onCodeSent: (email) =>
        unawaited(context.push(AppRoutes.settingsSignInCodeLink(email))),
    onSignedIn: () => context.go(AppRoutes.settings),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.settingsSignInCodeChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) => CodeScreen(
        email: state.uri.queryParameters[AppRoutes.accountEmailParam] ?? '',
        onSignedIn: () => context.go(AppRoutes.settings),
      ),
    ),
  ],
);

/// Screen 23's Account section (spec §5.5).
Widget accountSettingsSection(BuildContext context) =>
    AccountSettingsSectionWidget(
      onSignIn: () => unawaited(context.push(AppRoutes.settingsSignInLink)),
    );
```

In `lib/app/router/app_router.dart`:

```dart
GoRouter buildAppRouter({
  bool hasGallery = kDebugMode,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
```

- The `GoRouter(` arguments gain `refreshListenable: refreshListenable, redirect: redirect,`.
- The `SettingsScreen(` gains `accountSection: accountSettingsSection(context),`.
- Settings' `routes: [` gains `signInRoute(rootNavigator),` after the Sync route.
- The top-level routes gain `welcomeRoute(),` before the study-session route.
- Import `account_routes.dart` and `study_route_screens.dart`.
- The doc comment gains "Welcome and the account's attach flow (account UI spec §4), with the redirect `app.dart` passes."

In `lib/app/app.dart`:
- import `account_redirect.dart`, `core/auth/di/auth_providers.dart` and `features/account/presentation/providers/welcome_due_provider.dart`;
- replace the router field with:

```dart
  /// Runs the router's account rules again when their inputs change.
  final _accountRoutes = AccountRouteRefresh();

  // Owned here, not at top level, so each app instance starts at its initial
  // location and a disposed app releases its router.
  late final GoRouter _router = buildAppRouter(
    hasGallery: widget.hasGallery,
    refreshListenable: _accountRoutes,
    redirect: (context, state) => accountRedirect(
      state.uri,
      isWelcomeDue: ref.read(welcomeDueProvider),
      hasAccount: ref.read(currentAccountProvider)?.isAnonymous == false,
    ),
  );
```

- at the end of `initState()`:

```dart
    // Account UI spec §4: the welcome flag and the account drive the
    // redirect.
    ref
      ..listenManual(welcomeDueProvider, (_, _) => _accountRoutes.ping())
      ..listenManual(currentAccountProvider, (_, _) => _accountRoutes.ping());
```

- in `dispose()`, before `_router.dispose();`: `_accountRoutes.dispose();`.

Check the length: `wc -l lib/app/router/app_router.dart` must print under 500.

- [ ] **Step 11: Run the route tests and every app test.**

Run: `flutter test test/app --exclude-tags golden`
Expected: all pass, `account_routes_test.dart` included.

- [ ] **Step 12: Gate and commit.**

```bash
dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
git add lib/app lib/features test/app test/features
git commit -m "feat(app): Welcome and attach routes, the account redirect, Settings › Account

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

---

### Task 12: Goldens and the golden review page

**Files:**
- Modify: `test/support/account_harness.dart` (`precacheGoogleMark`)
- Create: `test/features/account/presentation/account_golden_test.dart`
- Create: `test/features/account/presentation/goldens/*.png` (30)
- Modify: `test/shared/widgets/goldens/mx_button_{light,dark}.png`; create `test/shared/widgets/goldens/mx_text_field_code_{light,dark}.png`

**Interfaces:**
- Consumes: every surface from Tasks 6–11.
- Produces: `Future<void> precacheGoogleMark(WidgetTester tester)` and the golden files.

- [ ] **Step 1: Prove this container renders like the reviewed goldens.** Before any golden changes, run untouched goldens:

Run: `TZ=UTC flutter test --tags golden test/features/settings test/features/study test/app/app_golden_test.dart > $S/golden_parity.txt 2>&1; tail -3 $S/golden_parity.txt`
Expected: `All tests passed!`
- If this fails, stop: the environment differs from the golden image's. Report it; do not update anything.

- [ ] **Step 2: Add the precache helper** to `test/support/account_harness.dart`, with `import 'package:flutter/material.dart';` and the copy widget's import:

```dart
/// Google's G decoded before a golden captures it: an asset image
/// otherwise paints its first frame empty.
Future<void> precacheGoogleMark(WidgetTester tester) async {
  await tester.runAsync(
    () => precacheImage(googleMark, tester.element(find.byType(Scaffold).first)),
  );
  await tester.pump();
}
```

- [ ] **Step 3: Write the golden test** `test/features/account/presentation/account_golden_test.dart`.
   - Each case pumps its surface with `pumpLibraryGolden(tester, env, screen, brightness, overrides: …)`, calls `precacheGoogleMark` when the G shows, and then runs `withRealShadows(() => expectBoundaryGolden(tester, 'goldens/<name>_${brightness.name}.png'))`.
   - Use `accountTest` for the cases that need a live coordinator, and `libraryTest` plus `authStateOf` for those that only render.
   - Loop over `Brightness.values`, as `settings_screen_golden_test.dart` does.

| Name | Surface and state |
|---|---|
| `welcome_ready` | `WelcomeScreen` on `Ready(anonymous)` |
| `welcome_offline` | `WelcomeScreen` with `authStateOf(const LocalOnly())` |
| `sign_in_link` | `SignInScreen` |
| `sign_in_invalid` | `SignInScreen` after sending `a@` |
| `code_waiting` | `CodeScreen` after `requestCode('a@example.com')` |
| `code_wrong` | `CodeScreen` after entering `000000` |
| `merge_sheet_merge` | the Task 6 host after `go`, with one deck and two cards |
| `merge_sheet_discard` | the same, with Discard chosen |
| `layer_sending` | `AccountTransitionLayerWidget` on `Transitioning(switch, started, merge)` |
| `layer_merging` | on `Transitioning(switch, targetSignedIn, merge)` |
| `layer_offline` | on `Transitioning(switch, started, merge, error: OfflineFailure)` |
| `layer_target` | on `Transitioning(switch, claimed, merge, hint b@example.com, isAwaitingTargetSignIn: true)` |
| `layer_sign_out_offline` | on `Transitioning(signOut, started, error: OfflineFailure)`, `unsentCount` 2 |
| `layer_stuck` | on `Recovering(switch, merged, merge, isStuck: true)` |
| `settings_account` | `SettingsScreen` with `accountSection: AccountSettingsSectionWidget(onSignIn: () {})`, anonymous; above it the "Account" section |

That is 15 names in 2 themes, 30 files. The code screens need `accountTest`: `requestCode` must have run before `CodeScreen` shows `accountCodeSentTo`.

- [ ] **Step 4: Write the goldens.**

Run: `TZ=UTC flutter test --tags golden --update-goldens test/features/account test/shared/widgets/shared_widgets_golden_test.dart test/shared/widgets/input_widgets_golden_test.dart`
Then run: `git status --short 'test/**/goldens/*.png'`
Expected: 30 new files under `test/features/account/presentation/goldens/`, 2 new `mx_text_field_code_*`, and 2 changed `mx_button_*`. Nothing else.

- [ ] **Step 5: Look at every new golden** with the Read tool, in light and dark.
   - Check against `DESIGN.md`: one fill per decision, the ink roles, 48 targets, nothing clipped, and the G mark crisp.
   - Fix any defect in the widget, not in the golden, and rerun Step 4 for that file.

- [ ] **Step 5b: Run Impeccable after the build** (CLAUDE.md, a screen's workflow, step 5).
   - Run `critique` and `audit` over the new goldens against `DESIGN.md`.
   - Fix everything found in one batch, rerun Step 4 for the touched files, and confirm once. Never loop on polish.
   - Record each ruling it produces in the detail files of Task 13.

- [ ] **Step 6: Run the whole golden suite** to prove nothing else moved.

Run: `TZ=UTC flutter test --tags golden > $S/golden_all.txt 2>&1; tail -3 $S/golden_all.txt`
Expected: `All tests passed!`

- [ ] **Step 7: Commit.**

```bash
git add test/support/account_harness.dart test/features/account test/shared/widgets/goldens
git commit -m "test(goldens): account screens, merge sheet, transition layer; MxButton text tone; code field

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

- [ ] **Step 8: Build the golden review page** with the `golden-compare` skill (CLAUDE.md, Golden review).
   - It shows every added and changed golden against `master` as Before · After · Diff, with one sentence each.
   - The page and its images stay in the scratchpad and on claude.ai, never in the repo.
   - Keep its link for the merge request.

---

### Task 13: Documents and the whole gate

**Files:**
- Create: `docs/shared/ui/screen-handoff/29-welcome.md`, `30-sign-in.md`, `31-code.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`, `docs/shared/ui/screen-handoff/23-settings.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9, the rows after 148)
- Modify: `docs/superpowers/specs/2026-09-30-account-ui-design.md` (§4 paths, the P3a status)
- Modify: `docs/wbs_FE.md`

- [ ] **Step 1: Write the detail files** in the `27-sync.md` shape: the `<!-- Hand-written screen record. -->` line, a title and a lead, then Entry points, Layout, States (golden tables with relative image links), Rulings and Copy.
   - **29 · Welcome.**
     - Entry: launch redirect, once.
     - Layout: §5.1 and §6 of the addendum, as built.
     - States: `welcome_ready`, `welcome_offline`.
     - Rulings: U1, U5, plan rulings 3, 4 and 6.
     - Copy: the `welcome*` and `accountContinue*` strings.
   - **30 · Sign-in.**
     - Entry: 23's Account row, Welcome's email, and the layer's target sign-in.
     - Layout: the form. It also holds the **merge sheet** section and the **transition layer** section, both app-root overlays with no number of their own.
     - States:
       - `sign_in_link`, `sign_in_invalid`;
       - `merge_sheet_merge`, `merge_sheet_discard`;
       - `layer_sending`, `layer_merging`, `layer_offline`, `layer_target`, `layer_sign_out_offline`, `layer_stuck`.
     - Rulings: R1, R3, plan rulings 1, 2, 7 to 12 and 14.
     - Copy.
   - **31 · Code.**
     - States: `code_waiting`, `code_wrong`.
     - Rulings: R3, plan ruling 11.
     - Copy.

- [ ] **Step 2: Update the index and screen 23.**
   - In `00-index.md`, after row 28, add:
     - `| 29 | Welcome (first launch) | 2 | FE-B9 | built | [29-welcome.md](29-welcome.md) (shape in the account UI spec) |`
     - `| 30 | Sign-in, merge sheet, transition layer | 10 | FE-B9 | built | [30-sign-in.md](30-sign-in.md) (shape in the account UI spec) |`
     - `| 31 | Code | 2 | FE-B9 | built | [31-code.md](31-code.md) |`
   - In `23-settings.md`:
     - add the Account section as the first layout row: "`MxSection` 'Account' + `MxSettingsRow`: anonymous 'Sign in' (disabled offline, 'Available when you're online'), an account's email with 'Your decks sync to this account'; composed by `app/` as a slot like Admin";
     - add the `settings_account_*` golden rows;
     - add FE-B9 to its row in the index.

- [ ] **Step 3: Update the registers.**
   - Add two rows to the UI-base register (§9), after row 148, in its format:
     - **149.** Screen 29's head is an `MxIconTile` (large, tinted, the deck glyph) because the launcher icon is still Flutter's default. Replace it with MemoX's icon when one exists. Source: account UI spec U5.
     - **150.** The email field on screen 30 uses the form variant's text keyboard. An email keyboard needs an `MxTextField` variant, which U2 did not approve. Source: P3a plan ruling 7.
   - In the addendum:
     - §4's route list becomes `/welcome?from=`, `/settings/sign-in?mode=link|reauth` and `/settings/sign-in/code?mode=…&email=…`, each with "(P3a plan ruling 1)";
     - the status line gains "P3a implemented by `docs/superpowers/plans/2026-09-30-account-ui-attach.md`".
   - In `docs/wbs_FE.md`, after the FE-B8 row, add:
     - `FE-B9`: "UI gắn tài khoản (P3a của auth): màn 29 Welcome, 30 Đăng nhập, 31 Mã, sheet gộp, lớp chặn ở gốc app, mục Account ở màn 23; `MxButton` tone `text` và logo G, `MxTextField` variant `code`". Status: `xong` once merged. Dependencies: SB-A2 and SB-A3 (P2). Size L. Evidence: spec, plan, the detail files, 30 goldens, the PR. Next step: "P3b: màn 32, re-auth, đăng xuất, xoá".
     - `FE-B10`: "UI quản lý tài khoản (P3b): màn 32, banner đăng nhập lại ở 23 và 13, `mode=reauth`, đăng xuất và xoá tài khoản", with status `chưa làm` and dependency FE-B9.

- [ ] **Step 4: Run the docs check and the whole gate.**

```bash
python3.13 tools/docs/check.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh
python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8
flutter test --exclude-tags golden > $S/suite.txt 2>&1; tail -3 $S/suite.txt
TZ=UTC flutter test --tags golden > $S/golden_all.txt 2>&1; tail -3 $S/golden_all.txt
```

Run the two suite commands in the background (about 9 minutes), and wait with Monitor for the output file's last line.
Expected:
- the docs check reports `PASS — 0 error(s)`;
- format, analyze, the architecture check and the guard are clean;
- both suites end with `All tests passed!`.

- [ ] **Step 5: Commit.**

```bash
git add docs
git commit -m "docs(account): screens 29–31, index, UI-base rows 149–150, FE-B9/B10

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```
