# M3 colour roles only (the derived ink layer removed) — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every colour the app paints is a `ColorScheme` role or a `MxSemanticColors` role; `MxDerivedColors` and every alpha tint that grounds a foreground are gone; every foreground/ground pair is measured in one test; the goldens are regenerated once and reviewed image by image.

**Architecture:** Phase 0 freezes the derived layer's inputs so nothing moves before its turn; phase 1 adds the roles and the contrast table; phase 2 migrates the core theme owners (component themes, decorations, ramp, text styles, status resolver, the one focus ring); phase 3 migrates the shared widgets in three groups with state tests and a preview after each; phase 4 the features and the three layout defects found along the way; phase 5 deletes the layer and lands the guard; phase 6 regenerates the goldens, classifies the diff, updates `DESIGN.md` and the documents, and runs the one audit.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13, `ThemeExtension`, `flutter_test` goldens (`run_goldens.sh`), the `code-verification-guard-v2` ruleset (Python 3.12, pytest), the `golden-compare` skill.

**Spec:** `docs/superpowers/specs/2026-10-08-m3-color-roles-design.md` (approved 2026-10-09). The plan argues from it; §4.3 and §4.8 are the colour oracle, §4.9 and §4.12 the state oracle, §6.3 the gates.

## Global Constraints

- `primary` stays `#5265F5` in both themes (spec R1). No fill role is used as text where the table says under 4.5:1; no mix, lerp or alpha makes a ground or a foreground (The Role Pair Rule, §4.1).
- Values, verbatim from spec §4.2–§4.3: `outline` light `#7580A6` / dark `#7A89C6`; `primaryForeground` `#384CDD` / `#BCC2FF`; `warning` `#855300` / `#FFB95F`, `onWarning` `#FFFFFF` / `#472A00`, `warningContainer` `#FFDDB8` / `#653E00`, `onWarningContainer` `#2A1700` / `#FFDDB8`; `success` `#006B57` / `#67DABB`, `onSuccess` `#FFFFFF` / `#00382C`, `successContainer` `#85F7D6` / `#005141`, `onSuccessContainer` `#002019` / `#85F7D6`; `mastery` `#006D44` / `#77DAA4`, `onMastery` `#FFFFFF` / `#003921`, `masteryContainer` `#93F7BE` / `#005232`, `onMasteryContainer` `#002111` / `#93F7BE`; `streak` `#9D4300` / `#FFB690`.
- Hero = `surfaceContainerLow` + `outlineVariant` hairline in both themes, raised shadow in light, text `onSurface` / `onSurfaceVariant`, CTA primary filled (R18, V4b). Containers read in their on-container only; glyphs on a container are the role.
- Focus ring: `primaryForeground`, `AppStroke.focus`, outside the control by `AppStroke.focusOffset`; inside with the same inset for a full-bleed row (§4.13 P1, round 2 P1).
- Pressed state layer of a filled tone: `shadow` at `AppOpacity.pressed`; edged and text tones keep the ink layer (§4.13 round 2).
- R17: no blanket exception; the checked `MxSelectionCheckbox` on a dark sheet is the one recorded exception; the toggle's on thumb is `onPrimary`.
- Alpha stays only for `AppOpacity` state layers, the 0.38 dim, the scrim, the scroll fade and shadows (§6.1).
- Goldens: never `--update` before phase 6; never accept a regenerated golden without the classified `golden-compare` page (R15); the gate is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, goldens through `run_goldens.sh` in the Linux container only.
- Every subagent runs on Sonnet except the final whole-branch review (Opus) (CLAUDE.md hooks). Commits name the issue's `DEV-n` once the epic exists.
- Nothing outside §4.8 / §4.9 / the three found-along-the-way defects changes; a diff that is not a mapping is a regression (§6.2).

## Review Focus

1. A control placed on a semantic container (the cancel action inside a warning dialog, whose whole ground is `warningContainer`): the dark `outline` is 2.77 there. Expected: the cancel is the text tone in `primaryForeground` (5.02 / 5.48); Task 12 pins it in `mx_dialog_test.dart`.
2. A focus ring on a control inside a clipping card (`MxRowInk` under `MxCard`'s `Clip.antiAlias`): an outside ring would be cut off. Expected: the inside placement; Task 16 pins it with a render test.
3. `MasteryRamp.fill` at exactly 0.34 and 0.67 after the role swap: the band must not shift. Expected: 0.34 is reviewing (`primary`), 0.67 mastered (`mastery`); Task 8 pins the boundaries.
4. A `MxBadge` solid success tone: `onSuccess` is new and only this consumer paints it. Expected: white on `#006B57` light, `#00382C` on `#67DABB` dark; Task 11 pins it.
5. A long deck name on the Korean screen at 320 dp after the FAB clearance change: the last row must clear the FAB by 24 dp with the nav bar and without. Expected: `MxScrollClearance.fab` everywhere a FAB exists; Task 15 pins the tail in both shells.

---

## Phase 0 · Freeze

### Task 1: Freeze the derived layer's inputs

**Files:**
- Modify: `lib/core/theme/mx_derived_colors.dart`
- Test: `test/core/theme/mx_derived_colors_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `MxDerivedColors.resolve(ColorScheme, MxSemanticColors)`, `primaryInkOf`, `outlineEdgeOf` unchanged in signature, but computed from frozen pre-migration role values; only `scheme.brightness` is still read.

- [ ] **Step 1: Write the failing test**

Append to `test/core/theme/mx_derived_colors_test.dart`:

```dart
  test('phase 0 freeze: a changed role moves no derived colour', () {
    final moved = AppColorSchemes.light.copyWith(
      outline: const Color(0xFFFF0000),
      primary: const Color(0xFF00FF00),
      error: const Color(0xFF0000FF),
    );
    final movedSemantic = MxSemanticColors.light.copyWith(
      warning: const Color(0xFF123456),
      success: const Color(0xFF654321),
    );
    final frozen = MxDerivedColors.resolve(moved, movedSemantic);
    expect(frozen.outlineEdge, light.outlineEdge);
    expect(frozen.primaryInk, light.primaryInk);
    expect(frozen.dangerSoft, light.dangerSoft);
    expect(frozen.warningSoft, light.warningSoft);
    expect(frozen.successInk, light.successInk);
    expect(MxDerivedColors.primaryInkOf(moved), light.primaryInk);
    expect(MxDerivedColors.outlineEdgeOf(moved), light.outlineEdge);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/mx_derived_colors_test.dart`
Expected: FAIL on `frozen.outlineEdge` (the edge follows the red outline).

- [ ] **Step 3: Freeze the inputs**

In `lib/core/theme/mx_derived_colors.dart` add, above `MxDerivedColors`:

```dart
/// Phase 0 of the M3 colour-roles migration (spec 2026-10-08 §6, task 1):
/// the roles this layer derived from, frozen at their pre-migration values,
/// so a role's new value moves no consumer this layer still paints. The
/// layer and this record go in phase 5.
final class _FrozenRoles {
  const _FrozenRoles({
    required this.primary,
    required this.onSurface,
    required this.outline,
    required this.error,
    required this.surface,
    required this.surfaceBright,
    required this.warning,
    required this.success,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
  });

  static const light = _FrozenRoles(
    primary: Color(0xFF5265F5),
    onSurface: Color(0xFF0F1638),
    outline: Color(0xFF7C85AB),
    error: Color(0xFFC02447),
    surface: Color(0xFFF7F9FE),
    surfaceBright: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    success: Color(0xFF2BA88B),
    statusNew: Color(0xFF8C95B8),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF5265F5),
    statusMastered: Color(0xFF1F8A5B),
  );

  static const dark = _FrozenRoles(
    primary: Color(0xFF5265F5),
    onSurface: Color(0xFFE4E8FA),
    outline: Color(0xFF5A6BAE),
    error: Color(0xFFFF8FA3),
    surface: Color(0xFF0A0E27),
    surfaceBright: Color(0xFF232B5A),
    warning: Color(0xFFFFC658),
    success: Color(0xFF6FE0BD),
    statusNew: Color(0xFF6B75A3),
    statusLearning: Color(0xFFFFC658),
    statusReviewing: Color(0xFF8B9AFF),
    statusMastered: Color(0xFF6FE0BD),
  );

  static _FrozenRoles of(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? dark : light;

  final Color primary;
  final Color onSurface;
  final Color outline;
  final Color error;
  final Color surface;
  final Color surfaceBright;
  final Color warning;
  final Color success;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;
}
```

Then, in `resolve`, `primaryInkOf` and `outlineEdgeOf`: first line `final roles = _FrozenRoles.of(scheme);`, and replace every `scheme.<role>` and `semantic.<role>` read with `roles.<role>` (`scheme.error` → `roles.error`, `scheme.primary` → `roles.primary`, `scheme.surface` → `roles.surface`, `scheme.surfaceBright` → `roles.surfaceBright`, `scheme.outline` → `roles.outline`, `scheme.onSurface` → `roles.onSurface`, `semantic.warning` → `roles.warning`, `semantic.success` → `roles.success`, `semantic.statusNew…statusMastered` → `roles.…`). Change the private mixer to take the frozen on-surface: `static Color _ink(Color status, Color onSurface, double mix) => Color.lerp(status, onSurface, mix)!;` and pass `roles.onSurface` at every call. After the edit `grep -n "scheme\.\|semantic\." lib/core/theme/mx_derived_colors.dart` prints only `scheme.brightness` lines and the `semantic` parameter.

- [ ] **Step 4: Run the theme tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/`
Expected: PASS, including the existing hand-worked expectations (the values did not change).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/mx_derived_colors.dart test/core/theme/mx_derived_colors_test.dart
git commit -m "refactor(theme): freeze the derived layer's inputs before the colour-role migration"
```

## Phase 1 · Roles

### Task 2: `MxSemanticColors` in its new shape

**Files:**
- Modify: `lib/core/theme/mx_semantic_colors.dart`
- Test: `test/core/theme/mx_semantic_colors_test.dart`

**Interfaces:**
- Produces: `MxSemanticColors` members `primaryForeground`, `warning`, `onWarning`, `warningContainer`, `onWarningContainer`, `success`, `onSuccess`, `successContainer`, `onSuccessContainer`, `mastery`, `onMastery`, `masteryContainer`, `onMasteryContainer`, `streak` with the Global Constraints values; the old `statusNew`, `statusLearning`, `statusReviewing`, `statusMastered`, `errorFill`, `onErrorFill` kept at their old values until Task 17.

- [ ] **Step 1: Write the failing test**

Replace the `_expected` map in `test/core/theme/mx_semantic_colors_test.dart` with:

```dart
// Spec 2026-10-08 §4.3: Material 3 custom-colour sets at HCT tones 40 / 100 /
// 90 / 10 (light) and 80 / 20 / 30 / 90 (dark), plus the one brand foreground.
// The six legacy members keep their old values until task 17 deletes them.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'primaryForeground': ((c) => c.primaryForeground, 0xFF384CDD, 0xFFBCC2FF),
  'warning': ((c) => c.warning, 0xFF855300, 0xFFFFB95F),
  'onWarning': ((c) => c.onWarning, 0xFFFFFFFF, 0xFF472A00),
  'warningContainer': ((c) => c.warningContainer, 0xFFFFDDB8, 0xFF653E00),
  'onWarningContainer': ((c) => c.onWarningContainer, 0xFF2A1700, 0xFFFFDDB8),
  'success': ((c) => c.success, 0xFF006B57, 0xFF67DABB),
  'onSuccess': ((c) => c.onSuccess, 0xFFFFFFFF, 0xFF00382C),
  'successContainer': ((c) => c.successContainer, 0xFF85F7D6, 0xFF005141),
  'onSuccessContainer': ((c) => c.onSuccessContainer, 0xFF002019, 0xFF85F7D6),
  'mastery': ((c) => c.mastery, 0xFF006D44, 0xFF77DAA4),
  'onMastery': ((c) => c.onMastery, 0xFFFFFFFF, 0xFF003921),
  'masteryContainer': ((c) => c.masteryContainer, 0xFF93F7BE, 0xFF005232),
  'onMasteryContainer': ((c) => c.onMasteryContainer, 0xFF002111, 0xFF93F7BE),
  'streak': ((c) => c.streak, 0xFF9D4300, 0xFFFFB690),
  'statusNew': ((c) => c.statusNew, 0xFF8C95B8, 0xFF6B75A3),
  'statusLearning': ((c) => c.statusLearning, 0xFFF59E0B, 0xFFFFC658),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF5265F5, 0xFF8B9AFF),
  'statusMastered': ((c) => c.statusMastered, 0xFF1F8A5B, 0xFF6FE0BD),
  'errorFill': ((c) => c.errorFill, 0xFFDC2D4E, 0xFFB0485C),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
};
```

Add after the loop:

```dart
  test('lerp at 0 and 1 returns each end for every member', () {
    final at0 = MxSemanticColors.light.lerp(MxSemanticColors.dark, 0);
    final at1 = MxSemanticColors.light.lerp(MxSemanticColors.dark, 1);
    for (final MapEntry(key: name, value: (read, light, dark))
        in _expected.entries) {
      expect(read(at0).toARGB32(), light, reason: name);
      expect(read(at1).toARGB32(), dark, reason: name);
    }
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/mx_semantic_colors_test.dart`
Expected: FAIL to compile: `primaryForeground` is not defined.

- [ ] **Step 3: Rewrite the extension**

Replace the class body of `lib/core/theme/mx_semantic_colors.dart` (keep the imports) with:

```dart
/// MemoX's Material 3 custom-colour sets (spec 2026-10-08 §4.3), one per
/// product semantic Material has no role for, each in M3's shape (`x`, `onX`,
/// `xContainer`, `onXContainer`) at tone 40 / 100 / 90 / 10 in light and
/// 80 / 20 / 30 / 90 in dark, plus the one brand foreground. Every value is
/// a literal measured in `test/core/theme/token_contrast_test.dart`; nothing
/// here is mixed at runtime. Green means mastery, never tertiary.
@immutable
final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.primaryForeground,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.mastery,
    required this.onMastery,
    required this.masteryContainer,
    required this.onMasteryContainer,
    required this.streak,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.errorFill,
    required this.onErrorFill,
  });

  static const MxSemanticColors light = MxSemanticColors(
    primaryForeground: Color(0xFF384CDD),
    warning: Color(0xFF855300),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFDDB8),
    onWarningContainer: Color(0xFF2A1700),
    success: Color(0xFF006B57),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF85F7D6),
    onSuccessContainer: Color(0xFF002019),
    mastery: Color(0xFF006D44),
    onMastery: Color(0xFFFFFFFF),
    masteryContainer: Color(0xFF93F7BE),
    onMasteryContainer: Color(0xFF002111),
    streak: Color(0xFF9D4300),
    statusNew: Color(0xFF8C95B8),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF5265F5),
    statusMastered: Color(0xFF1F8A5B),
    errorFill: Color(0xFFDC2D4E),
    onErrorFill: Color(0xFFFFFFFF),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    primaryForeground: Color(0xFFBCC2FF),
    warning: Color(0xFFFFB95F),
    onWarning: Color(0xFF472A00),
    warningContainer: Color(0xFF653E00),
    onWarningContainer: Color(0xFFFFDDB8),
    success: Color(0xFF67DABB),
    onSuccess: Color(0xFF00382C),
    successContainer: Color(0xFF005141),
    onSuccessContainer: Color(0xFF85F7D6),
    mastery: Color(0xFF77DAA4),
    onMastery: Color(0xFF003921),
    masteryContainer: Color(0xFF005232),
    onMasteryContainer: Color(0xFF93F7BE),
    streak: Color(0xFFFFB690),
    statusNew: Color(0xFF6B75A3),
    statusLearning: Color(0xFFFFC658),
    statusReviewing: Color(0xFF8B9AFF),
    statusMastered: Color(0xFF6FE0BD),
    errorFill: Color(0xFFB0485C),
    onErrorFill: Color(0xFFFFFFFF),
  );

  /// The brand hue as text, icon, focus ring or selected mark on a neutral
  /// ground: indigo at tone 40 / 80, where `primary` (the brand fill, tone
  /// 49) is 4.39 / 4.11 on the page (spec §4.4, R8). Never a fill.
  final Color primaryForeground;

  /// A refusal or a limit where nothing was lost: the fill of a warning
  /// button and the glyph or text on a neutral ground.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// A finished session, a kept outcome: its own role, never [mastery].
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Mastery and progress green.
  final Color mastery;
  final Color onMastery;
  final Color masteryContainer;
  final Color onMasteryContainer;

  /// The Progress flame (FE-A9 D7); its one consumed member.
  final Color streak;

  /// Legacy members (deleted in the migration's phase 5, task 17).
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;
  final Color errorFill;
  final Color onErrorFill;

  @override
  MxSemanticColors copyWith({
    Color? primaryForeground,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? mastery,
    Color? onMastery,
    Color? masteryContainer,
    Color? onMasteryContainer,
    Color? streak,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? errorFill,
    Color? onErrorFill,
  }) => MxSemanticColors(
    primaryForeground: primaryForeground ?? this.primaryForeground,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    masteryContainer: masteryContainer ?? this.masteryContainer,
    onMasteryContainer: onMasteryContainer ?? this.onMasteryContainer,
    streak: streak ?? this.streak,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    errorFill: errorFill ?? this.errorFill,
    onErrorFill: onErrorFill ?? this.onErrorFill,
  );

  @override
  MxSemanticColors lerp(
    covariant ThemeExtension<MxSemanticColors>? other,
    double t,
  ) {
    if (other is! MxSemanticColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxSemanticColors(
      primaryForeground: mix(primaryForeground, other.primaryForeground),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      mastery: mix(mastery, other.mastery),
      onMastery: mix(onMastery, other.onMastery),
      masteryContainer: mix(masteryContainer, other.masteryContainer),
      onMasteryContainer: mix(onMasteryContainer, other.onMasteryContainer),
      streak: mix(streak, other.streak),
      statusNew: mix(statusNew, other.statusNew),
      statusLearning: mix(statusLearning, other.statusLearning),
      statusReviewing: mix(statusReviewing, other.statusReviewing),
      statusMastered: mix(statusMastered, other.statusMastered),
      errorFill: mix(errorFill, other.errorFill),
      onErrorFill: mix(onErrorFill, other.onErrorFill),
    );
  }
}
```

- [ ] **Step 4: Run the theme tests and the analyzer**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/ && flutter analyze lib/core/theme`
Expected: PASS; no analyzer error (the frozen derived layer reads nothing from the extension any more; direct consumers of `semantic.warning` etc. compile unchanged and now paint the tone-40/80 values, which is their §4.8 mapping).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/mx_semantic_colors.dart test/core/theme/mx_semantic_colors_test.dart
git commit -m "feat(theme): M3 custom-colour sets and the brand foreground in MxSemanticColors"
```

### Task 3: `outline` holds 3:1 on every ground

**Files:**
- Modify: `lib/core/theme/app_color_schemes.dart` (the two `outline:` lines)
- Test: `test/core/theme/app_color_schemes_test.dart`

- [ ] **Step 1: Write the failing test**

In `test/core/theme/app_color_schemes_test.dart` change the `_roles` row `'outline': (0xFF7C85AB, 0xFF5A6BAE),` to `'outline': (0xFF7580A6, 0xFF7A89C6),` and add a test:

```dart
  test('outline is a 3:1 control edge on page, card, low, container and '
      'sheet in both themes (spec 2026-10-08 §4.2)', () {
    for (final scheme in [AppColorSchemes.light, AppColorSchemes.dark]) {
      for (final ground in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
      ]) {
        final la = scheme.outline.computeLuminance();
        final lb = ground.computeLuminance();
        final ratio =
            (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
        expect(ratio, greaterThanOrEqualTo(3), reason: '$ground');
      }
    }
  });
```

(add `import 'dart:math' as math;`).

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_color_schemes_test.dart`
Expected: FAIL: the value row (0xFF7C85AB) and the sheet ratio 2.92 / 2.25.

- [ ] **Step 3: Change the two values**

In `lib/core/theme/app_color_schemes.dart`: light `outline: const Color(0xFF7580A6),`; dark `outline: const Color(0xFF7A89C6),`, each with the comment `// The control edge: 3:1 on every ground up to the sheet (spec 2026-10-08 §4.2).`

- [ ] **Step 4: Run the theme tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/`
Expected: PASS (the frozen derived layer still uses the old outline, so `outlineEdge` tests hold).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_color_schemes.dart test/core/theme/app_color_schemes_test.dart
git commit -m "feat(theme): outline holds 3:1 on every ground in both themes"
```

### Task 4: The contrast table

**Files:**
- Modify: `test/core/theme/token_contrast_test.dart` (rewrite)

**Interfaces:**
- Consumes: Task 2's members, Task 3's `outline`, `MasteryRamp.track(scheme)` (exists), `AppOpacity.pressed`.

- [ ] **Step 1: Rewrite the pair table**

Replace `_pairs` and the helpers in `test/core/theme/token_contrast_test.dart` with (keep `_contrast`, `_text`, `_nonText`, the `main` loop):

```dart
// Spec 2026-10-08 §4.3 / §4.8: every foreground / ground pair the app paints,
// by role. The table is the oracle: a new pair is added here first.

Color _layer(Color over, Color ground) =>
    Color.alphaBlend(over.withValues(alpha: AppOpacity.pressed), ground);

typedef _Pair = (String name, Color ink, Color ground, double minimum);

List<_Pair> _pairs(ColorScheme scheme, MxSemanticColors semantic) {
  final sheet = scheme.surfaceContainerHigh;
  final hero = scheme.surfaceContainerLow;
  final track = MasteryRamp.track(scheme);
  final grounds = [
    (scheme.surface, 'page'),
    (scheme.surfaceContainerLowest, 'card'),
    (scheme.surfaceContainerLow, 'low'),
    (scheme.surfaceContainer, 'container'),
    (sheet, 'sheet'),
  ];
  final containers = [
    (scheme.primaryContainer, 'primary container'),
    (scheme.errorContainer, 'error container'),
    (semantic.warningContainer, 'warning container'),
    (semantic.successContainer, 'success container'),
    (semantic.masteryContainer, 'mastery container'),
  ];
  return [
    for (final (ground, where) in grounds) ...[
      ('primaryForeground on $where', semantic.primaryForeground, ground, _text),
      ('warning on $where', semantic.warning, ground, _text),
      ('success on $where', semantic.success, ground, _text),
      ('mastery on $where', semantic.mastery, ground, _text),
      ('streak on $where', semantic.streak, ground, _text),
      ('error on $where', scheme.error, ground, _text),
      ('onSurface on $where', scheme.onSurface, ground, _text),
      ('onSurfaceVariant on $where', scheme.onSurfaceVariant, ground, _text),
      ('outline edge on $where', scheme.outline, ground, _nonText),
    ],
    // Text and glyphs on a container: its on-container, or the role.
    for (final (ground, where) in containers)
      ('primaryForeground ring on $where', semantic.primaryForeground, ground, _text),
    ('onPrimaryContainer on its container', scheme.onPrimaryContainer, scheme.primaryContainer, _text),
    ('onSurfaceVariant on the primary container', scheme.onSurfaceVariant, scheme.primaryContainer, _text),
    ('outline on the primary container', scheme.outline, scheme.primaryContainer, _nonText),
    ('onErrorContainer on its container', scheme.onErrorContainer, scheme.errorContainer, _text),
    ('error glyph on its container', scheme.error, scheme.errorContainer, _text),
    ('onWarningContainer on its container', semantic.onWarningContainer, semantic.warningContainer, _text),
    ('warning glyph on its container', semantic.warning, semantic.warningContainer, _text),
    ('onSuccessContainer on its container', semantic.onSuccessContainer, semantic.successContainer, _text),
    ('success glyph on its container', semantic.success, semantic.successContainer, _text),
    ('onMasteryContainer on its container', semantic.onMasteryContainer, semantic.masteryContainer, _text),
    ('mastery glyph on its container', semantic.mastery, semantic.masteryContainer, _text),
    ('warning on the primary container', semantic.warning, scheme.primaryContainer, _text),
    ('mastery on the primary container', semantic.mastery, scheme.primaryContainer, _text),
    // On-colours on their fills.
    ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
    ('onError on error', scheme.onError, scheme.error, _text),
    ('onWarning on warning', semantic.onWarning, semantic.warning, _text),
    ('onSuccess on success', semantic.onSuccess, semantic.success, _text),
    ('onMastery on mastery', semantic.onMastery, semantic.mastery, _text),
    // The brand fill where it identifies something (R7): the page, the card,
    // the hero and the progress track. Not the sheet (R17 covers that).
    ('primary fill on the page', scheme.primary, scheme.surface, _nonText),
    ('primary fill on the card', scheme.primary, scheme.surfaceContainerLowest, _nonText),
    ('primary fill on the hero', scheme.primary, hero, _nonText),
    ('progress fill on its track', scheme.primary, track, _nonText),
    ('learning fill on its track', semantic.warning, track, _nonText),
    ('mastered fill on its track', semantic.mastery, track, _nonText),
    // The donut label is text in its band's foreground, on the hero.
    for (final fraction in [0.0, 0.2, 0.5, 0.9, 1.0])
      ('donut label at $fraction on the hero', MasteryRamp.foreground(semantic, scheme, fraction), hero, _text),
    // Pressed state layers (spec §4.13 round 2): shadow over a filled tone.
    ('pressed primary label', scheme.onPrimary, _layer(scheme.shadow, scheme.primary), _text),
    ('pressed destructive label', scheme.onError, _layer(scheme.shadow, scheme.error), _text),
    ('pressed warning label', semantic.onWarning, _layer(scheme.shadow, semantic.warning), _text),
    // Toggle and checkbox marks (R17: the on-colour mark carries the state).
    ('toggle on thumb', scheme.onPrimary, scheme.primary, _nonText),
    ('toggle off thumb on its track', scheme.onSurfaceVariant, scheme.surfaceContainerHighest, _nonText),
    ('checked box mark', scheme.onPrimary, scheme.primary, _nonText),
    ('unchecked box edge on the sheet', scheme.outline, sheet, _nonText),
    // Chrome that did not move.
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    ('sheet grabber', scheme.onSurfaceVariant, sheet, _nonText),
    (
      'faded choice ink',
      Color.alphaBlend(scheme.onSurface.withValues(alpha: AppOpacity.muted), scheme.surface),
      Color.alphaBlend(scheme.surfaceContainerLowest.withValues(alpha: AppOpacity.muted), scheme.surface),
      _text,
    ),
  ];
}
```

Remove the `MxDerivedColors` import. `MasteryRamp.foreground` does not exist yet (Task 8): until then the file fails to compile, which is this task's RED.

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/token_contrast_test.dart`
Expected: FAIL to compile: `MasteryRamp.foreground` undefined.

- [ ] **Step 3: Commit the RED table (it turns green in Task 8)**

```bash
git add test/core/theme/token_contrast_test.dart
git commit -m "test(theme): the colour-role contrast table of spec 2026-10-08 (red until the ramp lands)"
```

## Phase 2 · Core owners

### Task 5: The one focus ring and the pressed layer

**Files:**
- Create: `lib/shared/widgets/mx_focus_ring.dart`
- Modify: `lib/core/theme/app_button_style.dart`
- Test: `test/shared/widgets/mx_focus_ring_test.dart`, `test/core/theme/app_button_style_test.dart` (create if absent)

**Interfaces:**
- Produces: `MxFocusRing({Key? key, required BorderRadius radius, MxFocusRingPlacement placement = MxFocusRingPlacement.outside, required Widget child})`; `enum MxFocusRingPlacement { outside, inside }`; `appButtonStyle({required Color? fill, required Color ink, required BorderSide edge, required Color pressedLayer, Color? focusColor, required double height, required double radius, required double padding, required TextStyle label})` where a null `focusColor` draws no ring (the Mx widget wraps itself in `MxFocusRing`) and a non-null one keeps the inside ring for a raw Material button.

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_focus_ring_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

import '../../support/widget_harness.dart';

void main() {
  Widget host({MxFocusRingPlacement placement = MxFocusRingPlacement.outside}) =>
      MxFocusRing(
        radius: BorderRadius.circular(AppRadius.md),
        placement: placement,
        child: SizedBox(
          width: 100,
          height: 40,
          child: TextButton(onPressed: () {}, child: const Text('Go')),
        ),
      );

  testWidgets('paints nothing while its child is not focused', (tester) async {
    await pumpMx(tester, host());
    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('paints a primaryForeground ring outside the child on focus', (
    tester,
  ) async {
    await pumpMx(tester, host());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    tester.widget<TextButton>(find.byType(TextButton)).focusNode;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
    final painter = paint.foregroundPainter! as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
    expect(painter.placement, MxFocusRingPlacement.outside);
    // The ring rect is the child's rect grown by the offset and half a stroke.
    expect(painter.ringRect(const Size(100, 40)).left, -3);
    expect(painter.ringRect(const Size(100, 40)).right, 103);
  });

  testWidgets('inside placement inset the ring by the same offset', (
    tester,
  ) async {
    await pumpMx(tester, host(placement: MxFocusRingPlacement.inside));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final painter =
        tester.widget<CustomPaint>(find.byType(CustomPaint).first)
            .foregroundPainter! as MxFocusRingPainter;
    expect(painter.ringRect(const Size(100, 40)).left, 3);
    expect(painter.ringRect(const Size(100, 40)).right, 97);
  });
}
```

(add `import 'package:flutter/services.dart';`).

`test/core/theme/app_button_style_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';

void main() {
  const fill = Color(0xFF5265F5);
  const ink = Color(0xFFFFFFFF);
  const shadow = Color(0xFF0F1638);
  ButtonStyle style({Color? focusColor}) => appButtonStyle(
    fill: fill,
    ink: ink,
    edge: BorderSide.none,
    pressedLayer: shadow,
    focusColor: focusColor,
    height: 48,
    radius: 12,
    padding: 16,
    label: const TextStyle(),
  );

  test('the pressed overlay is the pressed layer at AppOpacity.pressed', () {
    final overlay = style().overlayColor!.resolve({WidgetState.pressed});
    expect(overlay, shadow.withValues(alpha: AppOpacity.pressed));
  });

  test('no focusColor: the side never swaps on focus', () {
    expect(style().side!.resolve({WidgetState.focused}), BorderSide.none);
  });

  test('a focusColor keeps the inside ring for a raw Material button', () {
    final side = style(focusColor: ink).side!.resolve({WidgetState.focused});
    expect(side.color, ink);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_focus_ring_test.dart test/core/theme/app_button_style_test.dart`
Expected: FAIL to compile (`mx_focus_ring.dart` missing; `pressedLayer` unknown).

- [ ] **Step 3: Write `MxFocusRing`**

`lib/shared/widgets/mx_focus_ring.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Where the ring sits against its control.
enum MxFocusRingPlacement {
  /// `AppStroke.focusOffset` outside the control: buttons, chips, the
  /// toggle, the stepper, anything with room around it.
  outside,

  /// Inset by the same offset: a full-bleed row under a clipping card, where
  /// an outside ring would be cut off (spec 2026-10-08 §4.13 round 2, P1).
  inside,
}

/// The one focus ring (spec 2026-10-08 §4.13 P1): `AppStroke.focus` in
/// `primaryForeground`, drawn around [child] while focus is inside it. The
/// ring always borders the ground, never the control's fill, so it is one
/// measured pair on every ground (`token_contrast_test.dart`).
class MxFocusRing extends StatefulWidget {
  const MxFocusRing({
    super.key,
    required this.radius,
    this.placement = MxFocusRingPlacement.outside,
    required this.child,
  });

  /// The control's corner radius; the ring follows it.
  final BorderRadius radius;
  final MxFocusRingPlacement placement;
  final Widget child;

  @override
  State<MxFocusRing> createState() => _MxFocusRingState();
}

class _MxFocusRingState extends State<MxFocusRing> {
  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    // Not a focus target itself: it only hears its descendants' focus.
    final child = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: widget.child,
    );
    if (!_hasFocus) return child;
    return CustomPaint(
      foregroundPainter: MxFocusRingPainter(
        color: context.semanticColors.primaryForeground,
        radius: widget.radius,
        placement: widget.placement,
      ),
      child: child,
    );
  }
}

/// Paints the ring; public so a test can read its geometry.
class MxFocusRingPainter extends CustomPainter {
  const MxFocusRingPainter({
    required this.color,
    required this.radius,
    required this.placement,
  });

  final Color color;
  final BorderRadius radius;
  final MxFocusRingPlacement placement;

  /// The ring's centreline rect for a control of [size].
  Rect ringRect(Size size) {
    final delta = AppStroke.focusOffset + AppStroke.focus / 2;
    final rect = Offset.zero & size;
    return switch (placement) {
      MxFocusRingPlacement.outside => rect.inflate(delta),
      MxFocusRingPlacement.inside => rect.deflate(delta),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = ringRect(size);
    final rrect = switch (placement) {
      MxFocusRingPlacement.outside =>
        radius.toRRect(Offset.zero & size).inflate(rect.left.abs()),
      MxFocusRingPlacement.inside =>
        radius.toRRect(Offset.zero & size).deflate(rect.left),
    };
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(MxFocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.placement != placement;
}
```

- [ ] **Step 4: Change `appButtonStyle`**

`lib/core/theme/app_button_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The ButtonStyle every text-labelled control shares: the Mx widgets and the
/// theme's Material buttons (spec §4.6). One fill and one ink for every
/// state; dimming a disabled control is the caller's 0.38 Opacity. The
/// pressed overlay is [pressedLayer] at AppOpacity.pressed: `shadow` for a
/// filled tone, so the label stays 4.5:1 while held, the ink otherwise
/// (spec 2026-10-08 §4.13 round 2). An Mx widget passes no [focusColor] and
/// draws its ring with MxFocusRing outside the control; a raw Material
/// button keeps the inside ring in [focusColor].
ButtonStyle appButtonStyle({
  required Color? fill,
  required Color ink,
  required BorderSide edge,
  required Color pressedLayer,
  Color? focusColor,
  required double height,
  required double radius,
  required double padding,
  required TextStyle label,
}) {
  final focusRing = focusColor == null
      ? null
      : BorderSide(color: focusColor, width: AppStroke.focus);
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(fill),
    foregroundColor: WidgetStatePropertyAll(ink),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? pressedLayer.withValues(alpha: AppOpacity.pressed)
          : null,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => focusRing != null && states.contains(WidgetState.focused)
          ? focusRing
          : edge,
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: padding)),
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textStyle: WidgetStatePropertyAll(label),
  );
}
```

Callers of `appButtonStyle` (`app_component_themes.dart`, `mx_button.dart`, `mx_filter_chip.dart`, `mx_chip_trigger.dart`, `mx_stepper.dart`, `mx_snackbar.dart`) no longer compile: Task 6 fixes the theme, Tasks 11–12 the widgets. Until then run only the two test files.

- [ ] **Step 5: Run the two tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_focus_ring_test.dart test/core/theme/app_button_style_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/mx_focus_ring.dart lib/core/theme/app_button_style.dart test/shared/widgets/mx_focus_ring_test.dart test/core/theme/app_button_style_test.dart
git commit -m "feat(theme): the one focus ring outside the control and the shadow pressed layer"
```

### Task 6: Component themes on roles

**Files:**
- Modify: `lib/core/theme/app_component_themes.dart`, `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_component_themes_test.dart`

**Interfaces:**
- Produces: `AppComponentThemes.fields(scheme, semantic, texts)`, `filledButtons(scheme, semantic, texts)`, `outlinedButtons(scheme, semantic, texts)`, `textButtons(scheme, semantic, texts)`, `iconButtons(scheme, semantic)`; `dialogs`, `sheets`, `snackbars`, `tooltips` unchanged. (`MxTextStyles(texts, scheme)` is still the two-argument form until Task 9.)

- [ ] **Step 1: Write the failing tests**

Add to `test/core/theme/app_component_themes_test.dart`:

```dart
  group('spec 2026-10-08 roles', () {
    final scheme = AppColorSchemes.light;
    final semantic = MxSemanticColors.light;
    final texts = ThemeData(colorScheme: scheme).textTheme;

    test('a field rests on outline, disables to outlineVariant, focuses in '
        'primaryForeground and errs in error', () {
      final fields = AppComponentThemes.fields(scheme, semantic, texts);
      Color edge(InputBorder? b) => (b! as OutlineInputBorder).borderSide.color;
      expect(edge(fields.enabledBorder), scheme.outline);
      expect(edge(fields.disabledBorder), scheme.outlineVariant);
      expect(edge(fields.focusedBorder), semantic.primaryForeground);
      expect(edge(fields.errorBorder), scheme.error);
    });

    test('outlined and text buttons ink in primaryForeground; the outline '
        'edge is outline', () {
      final outlined = AppComponentThemes.outlinedButtons(scheme, semantic, texts).style!;
      final text = AppComponentThemes.textButtons(scheme, semantic, texts).style!;
      expect(outlined.foregroundColor!.resolve({}), semantic.primaryForeground);
      expect(outlined.side!.resolve({})!.color, scheme.outline);
      expect(text.foregroundColor!.resolve({}), semantic.primaryForeground);
    });

    test('the filled button presses through the shadow layer', () {
      final filled = AppComponentThemes.filledButtons(scheme, semantic, texts).style!;
      expect(
        filled.overlayColor!.resolve({WidgetState.pressed}),
        scheme.shadow.withValues(alpha: AppOpacity.pressed),
      );
    });

    test('the icon button focus ring is primaryForeground', () {
      final icon = AppComponentThemes.iconButtons(scheme, semantic).style!;
      expect(icon.side!.resolve({WidgetState.focused})!.color, semantic.primaryForeground);
    });
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_component_themes_test.dart`
Expected: FAIL to compile (the three-argument button themes do not exist).

- [ ] **Step 3: Rewrite the themes**

In `lib/core/theme/app_component_themes.dart`: delete the `mx_derived_colors.dart` import; replace `fields`, `_button`, `filledButtons`, `outlinedButtons`, `textButtons`, `iconButtons` with:

```dart
  /// Every form field (TextField contract): the muted fill that lightens on
  /// focus, the outline edge at rest, outlineVariant when disabled (SC 1.4.11
  /// exempts it), primaryForeground on focus, error in error, the 14 hint.
  static InputDecorationTheme fields(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts,
  ) => InputDecorationTheme(
    filled: true,
    isDense: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerLow,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.grouped),
    hintStyle: MxTextStyles(texts, scheme).inputHint,
    border: fieldEdge(scheme.outline),
    enabledBorder: fieldEdge(scheme.outline),
    disabledBorder: fieldEdge(scheme.outlineVariant),
    focusedBorder: fieldEdge(semantic.primaryForeground),
    errorBorder: fieldEdge(scheme.error),
    focusedErrorBorder: fieldEdge(scheme.error),
  );

  /// A Material button at the regular V3 size in [fill] and [ink]: 48 tall,
  /// radius 12, gutter padding, the 14/600 label, the pressed layer (shadow
  /// over a fill, the ink otherwise) and, for these raw Material buttons, the
  /// inside focus ring in primaryForeground. A disabled one dims under the
  /// global 0.38 rule.
  static ButtonStyle _button(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts, {
    required Color? fill,
    required Color ink,
    required BorderSide edge,
  }) {
    final style = appButtonStyle(
      fill: fill,
      ink: ink,
      edge: edge,
      pressedLayer: fill == null ? ink : scheme.shadow,
      focusColor: semantic.primaryForeground,
      height: AppSize.buttonRegular,
      radius: AppRadius.md,
      padding: AppSpacing.gutter,
      label: MxTextStyles(texts, scheme).buttonLabel,
    );
    Color? dimmed(Color? color) =>
        color?.withValues(alpha: color.a * AppOpacity.disabled);
    final dimmedEdge = edge == BorderSide.none
        ? edge
        : edge.copyWith(color: dimmed(edge.color));
    return style.copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? dimmedEdge
            : style.side?.resolve(states),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? dimmed(fill) : fill,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? dimmed(ink) : ink,
      ),
    );
  }

  /// FilledButton: the primary tone.
  static FilledButtonThemeData filledButtons(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts,
  ) => FilledButtonThemeData(
    style: _button(
      scheme,
      semantic,
      texts,
      fill: scheme.primary,
      ink: scheme.onPrimary,
      edge: BorderSide.none,
    ),
  );

  /// OutlinedButton: the outline tone.
  static OutlinedButtonThemeData outlinedButtons(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts,
  ) => OutlinedButtonThemeData(
    style: _button(
      scheme,
      semantic,
      texts,
      fill: null,
      ink: semantic.primaryForeground,
      edge: BorderSide(color: scheme.outline, width: AppStroke.hairline),
    ),
  );

  /// TextButton: primaryForeground, no fill — the framework's dialog actions.
  static TextButtonThemeData textButtons(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts,
  ) => TextButtonThemeData(
    style: _button(
      scheme,
      semantic,
      texts,
      fill: null,
      ink: semantic.primaryForeground,
      edge: BorderSide.none,
    ),
  );

  /// IconButton (IconButton contract): a 20 glyph in a 36 round ink box with
  /// a 48 touch area, the pressed overlay, and the focus ring on the
  /// circle's edge, which has no fill, so the ring borders the ground.
  static IconButtonThemeData iconButtons(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => IconButtonThemeData(
    style: ButtonStyle(
      iconSize: const WidgetStatePropertyAll(AppIconSize.compact),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? scheme.onSurface.withValues(alpha: AppOpacity.disabled)
            : scheme.onSurface,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? scheme.onSurface.withValues(alpha: AppOpacity.pressed)
            : null,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(
                color: semantic.primaryForeground,
                width: AppStroke.focus,
              )
            : null,
      ),
      shape: const WidgetStatePropertyAll(CircleBorder()),
      fixedSize: const WidgetStatePropertyAll(Size.square(AppSize.iconButtonInk)),
      minimumSize: const WidgetStatePropertyAll(Size.square(AppSize.iconButtonInk)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
  );
```

In `lib/core/theme/app_theme.dart` pass `semantic` to the four button/icon themes: `filledButtonTheme: AppComponentThemes.filledButtons(scheme, semantic, texts)`, `outlinedButtonTheme: AppComponentThemes.outlinedButtons(scheme, semantic, texts)`, `textButtonTheme: AppComponentThemes.textButtons(scheme, semantic, texts)`, `iconButtonTheme: AppComponentThemes.iconButtons(scheme, semantic)`.

- [ ] **Step 4: Run the theme tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_component_themes_test.dart test/core/theme/app_theme_test.dart`
Expected: PASS. Any existing assertion on `primaryInkOf` / `outlineEdgeOf` in `app_component_themes_test.dart` is rewritten to the role (not deleted).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_component_themes.dart lib/core/theme/app_theme.dart test/core/theme/app_component_themes_test.dart
git commit -m "feat(theme): component themes paint roles: outline edges, primaryForeground, shadow pressed layer"
```

### Task 7: `AppDecorations` on roles

**Files:**
- Modify: `lib/core/theme/app_decorations.dart`
- Test: `test/core/theme/app_decorations_test.dart`, `test/core/theme/app_decorations_study_choice_test.dart`

**Interfaces:**
- Produces: `AppDecorations.raisedCard(ColorScheme)`, `recessedCard(ColorScheme)`, `heroCard(ColorScheme)`, `warningCard(ColorScheme, MxSemanticColors)`, `successCard(ColorScheme, MxSemanticColors)`, `dangerCard(ColorScheme)`, `studyChoice(ColorScheme, MxSemanticColors, StudyChoiceTone, {bool isRecessed})`, `studyChoiceInk(ColorScheme, MxSemanticColors, StudyChoiceTone)`. `MxCard`, `MxFloatingNotice`, `progress_streak_widget`, `study_choice_widget` stop compiling until Tasks 12–14.

- [ ] **Step 1: Write the failing tests**

Replace the bodies of the two decoration tests with (keep their imports plus `mx_semantic_colors.dart`, drop `mx_derived_colors.dart`):

```dart
void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    final isDark = scheme.brightness == Brightness.dark;
    Color? edge(BoxDecoration d) => (d.border as Border?)?.top.color;

    test('$name raised card: lowest, outlineVariant hairline in dark only', () {
      final d = AppDecorations.raisedCard(scheme);
      expect(d.color, scheme.surfaceContainerLowest);
      expect(edge(d), isDark ? scheme.outlineVariant : null);
    });

    test('$name recessed card: low, outlineVariant hairline, no shadow', () {
      final d = AppDecorations.recessedCard(scheme);
      expect(d.color, scheme.surfaceContainerLow);
      expect(edge(d), scheme.outlineVariant);
      expect(d.boxShadow, isEmpty);
    });

    test('$name hero card (V4b): low, outlineVariant hairline, raised shadow', () {
      final d = AppDecorations.heroCard(scheme);
      expect(d.color, scheme.surfaceContainerLow);
      expect(edge(d), scheme.outlineVariant);
      expect(d.boxShadow, AppDecorations.raisedCard(scheme).boxShadow);
    });

    test('$name warning / success / danger cards are containers without an edge', () {
      expect(AppDecorations.warningCard(scheme, semantic).color, semantic.warningContainer);
      expect(edge(AppDecorations.warningCard(scheme, semantic)), null);
      expect(AppDecorations.successCard(scheme, semantic).color, semantic.successContainer);
      expect(edge(AppDecorations.successCard(scheme, semantic)), null);
      expect(AppDecorations.dangerCard(scheme).color, scheme.errorContainer);
      expect(edge(AppDecorations.dangerCard(scheme)), null);
    });
  }
}
```

and for the study choice:

```dart
void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    Color? edge(BoxDecoration d) => (d.border as Border?)?.top.color;
    BoxDecoration tone(StudyChoiceTone t, {bool isRecessed = false}) =>
        AppDecorations.studyChoice(scheme, semantic, t, isRecessed: isRecessed);
    Color ink(StudyChoiceTone t) => AppDecorations.studyChoiceInk(scheme, semantic, t);

    test('$name idle: raised or recessed ground with the outline edge', () {
      expect(tone(StudyChoiceTone.idle).color, scheme.surfaceContainerLowest);
      expect(edge(tone(StudyChoiceTone.idle)), scheme.outline);
      expect(tone(StudyChoiceTone.idle, isRecessed: true).color, scheme.surfaceContainerLow);
      expect(ink(StudyChoiceTone.idle), scheme.onSurface);
    });

    test('$name selected: primary on primary, onPrimary ink', () {
      expect(tone(StudyChoiceTone.selected).color, scheme.primary);
      expect(ink(StudyChoiceTone.selected), scheme.onPrimary);
    });

    test('$name right / wrong: containers, no edge, on-container ink', () {
      expect(tone(StudyChoiceTone.right).color, semantic.successContainer);
      expect(edge(tone(StudyChoiceTone.right)), null);
      expect(ink(StudyChoiceTone.right), semantic.onSuccessContainer);
      expect(tone(StudyChoiceTone.wrong).color, scheme.errorContainer);
      expect(edge(tone(StudyChoiceTone.wrong)), null);
      expect(ink(StudyChoiceTone.wrong), scheme.onErrorContainer);
    });
  }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_decorations_test.dart test/core/theme/app_decorations_study_choice_test.dart`
Expected: FAIL to compile (one-argument `raisedCard` does not exist).

- [ ] **Step 3: Rewrite `AppDecorations`**

Replace the class in `lib/core/theme/app_decorations.dart` (imports: `material`, `app_radius`, `app_shadows`, `app_stroke`, `mx_semantic_colors`):

```dart
/// Surface treatments shared by more than one component contract. Every
/// ground and edge is a role (spec 2026-10-08 §4.5–§4.6): a container has no
/// coloured edge; the decorative hairline is outlineVariant; a tappable
/// surface's edge is outline.
abstract final class AppDecorations {
  static Border _hairline(Color color) =>
      Border.all(color: color, width: AppStroke.hairline);

  /// The Card surface: the lowest container and radius 12; the whisper
  /// shadow in light and the outlineVariant hairline in dark, which has no
  /// shadow.
  static BoxDecoration raisedCard(ColorScheme scheme) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: scheme.brightness == Brightness.dark
        ? _hairline(scheme.outlineVariant)
        : null,
    boxShadow: AppShadows.whisper(scheme),
  );

  /// The answer face of a study card (screen 16a): the low container with
  /// the hairline in both themes, flat, so it reads as recessed under the
  /// raised prompt.
  static BoxDecoration recessedCard(ColorScheme scheme) =>
      raisedCard(scheme).copyWith(
        color: scheme.surfaceContainerLow,
        border: _hairline(scheme.outlineVariant),
        boxShadow: const [],
      );

  /// The hero Card (owner 2026-10-09, V4b): the low container with the
  /// hairline in both themes and the raised shadow in light: one tonal step
  /// above the page and the list cards, so the primary CTA inside it is the
  /// one indigo mass (3.31 / 4.20 against this ground).
  static BoxDecoration heroCard(ColorScheme scheme) =>
      raisedCard(scheme).copyWith(
        color: scheme.surfaceContainerLow,
        border: _hairline(scheme.outlineVariant),
      );

  /// A container has no edge in either theme; `copyWith(border: null)` would
  /// keep the dark raised card's hairline, so it is built directly.
  static BoxDecoration _container(ColorScheme scheme, Color color) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.whisper(scheme),
      );

  /// The warning Card: the warning container, for a state that asks for
  /// care such as a locked review algorithm (screen 02).
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _container(scheme, semantic.warningContainer);

  /// The success Card: the success container, a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _container(scheme, semantic.successContainer);

  /// The danger Card: the error container, a session stopped by an error.
  static BoxDecoration dangerCard(ColorScheme scheme) =>
      _container(scheme, scheme.errorContainer);

  /// The toned surface of a guess option and a match tile (screens 17 and
  /// 18): idle on the raised fill with the outline edge (a tappable card is a
  /// control), selected in primary, right in the success container and wrong
  /// in the error container, both without an edge. [isRecessed] gives an idle
  /// tile the answer face's recessed ground.
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final (Color fill, Color? edge) = switch (tone) {
      StudyChoiceTone.idle => (
        isRecessed ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        scheme.outline,
      ),
      StudyChoiceTone.selected => (scheme.primary, scheme.primary),
      StudyChoiceTone.right => (semantic.successContainer, null),
      StudyChoiceTone.wrong => (scheme.errorContainer, null),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: edge == null ? null : _hairline(edge),
    );
  }

  /// The ink on a [studyChoice] surface: a container's on-container.
  static Color studyChoiceInk(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone,
  ) => switch (tone) {
    StudyChoiceTone.idle => scheme.onSurface,
    StudyChoiceTone.selected => scheme.onPrimary,
    StudyChoiceTone.right => semantic.onSuccessContainer,
    StudyChoiceTone.wrong => scheme.onErrorContainer,
  };
}

/// The states of a study choice surface (screens 17 and 18).
enum StudyChoiceTone { idle, selected, right, wrong }
```

- [ ] **Step 4: Run the two tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_decorations_test.dart test/core/theme/app_decorations_study_choice_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_decorations.dart test/core/theme/app_decorations_test.dart test/core/theme/app_decorations_study_choice_test.dart
git commit -m "feat(theme): decorations paint roles: hero V4b, containers without edges, outline on a tappable card"
```

### Task 8: `MasteryRamp` on roles

**Files:**
- Modify: `lib/core/theme/mastery_ramp.dart`
- Test: `test/core/theme/mastery_ramp_test.dart`, `test/core/theme/token_contrast_test.dart` (turns green)

**Interfaces:**
- Produces: `MasteryRamp.fill(MxSemanticColors semantic, ColorScheme scheme, double fraction) → Color?` (learning `semantic.warning`, reviewing `scheme.primary`, mastered `semantic.mastery`, null at 0); `MasteryRamp.foreground(MxSemanticColors, ColorScheme, double) → Color` (`warning` / `primaryForeground` / `mastery`); `percent`, `track` unchanged. `MasteryRamp.ink` deleted.

- [ ] **Step 1: Write the failing test**

Replace the fill/ink tests in `test/core/theme/mastery_ramp_test.dart` with:

```dart
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    test('$name fill: null at 0, warning under 0.34, primary under 0.67, '
        'mastery from 0.67', () {
      expect(MasteryRamp.fill(semantic, scheme, 0), isNull);
      expect(MasteryRamp.fill(semantic, scheme, 0.01), semantic.warning);
      expect(MasteryRamp.fill(semantic, scheme, 0.3399), semantic.warning);
      expect(MasteryRamp.fill(semantic, scheme, 0.34), scheme.primary);
      expect(MasteryRamp.fill(semantic, scheme, 0.6699), scheme.primary);
      expect(MasteryRamp.fill(semantic, scheme, 0.67), semantic.mastery);
      expect(MasteryRamp.fill(semantic, scheme, 1), semantic.mastery);
    });

    test('$name foreground: the band role, primaryForeground for reviewing', () {
      expect(MasteryRamp.foreground(semantic, scheme, 0), semantic.warning);
      expect(MasteryRamp.foreground(semantic, scheme, 0.5), semantic.primaryForeground);
      expect(MasteryRamp.foreground(semantic, scheme, 0.9), semantic.mastery);
    });
  }
```

Keep the `percent` and the argument-range tests, retargeted to the new signature.

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/mastery_ramp_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: Rewrite the ramp**

`lib/core/theme/mastery_ramp.dart` (imports: `material`, `mx_semantic_colors`):

```dart
/// The single-colour mastery ramp (V3 MasteryRamp utility). One threshold
/// function feeds every mastery fill, so a 40% deck is the same colour on
/// every screen. It paints nothing itself.
abstract final class MasteryRamp {
  /// First fraction painted as reviewing (34%).
  static const double _reviewingFrom = 0.34;

  /// First fraction painted as mastered (67%).
  static const double _masteredFrom = 0.67;

  static void _check(double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
  }

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient. Learning is the warning role (tone
  /// 40 / 80, 5.90 / 9.01 on the track), reviewing the brand fill (4.20 /
  /// 3.31), mastered the mastery role (spec 2026-10-08 §4.7).
  static Color? fill(
    MxSemanticColors semantic,
    ColorScheme scheme,
    double fraction,
  ) {
    _check(fraction);
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.warning;
    if (fraction < _masteredFrom) return scheme.primary;
    return semantic.mastery;
  }

  /// The band's foreground for text beside or inside the fill, such as the
  /// donut's percentage: the role itself, except reviewing, whose fill is
  /// the brand and whose text is primaryForeground (The Role Pair Rule).
  /// 0 reads in the lowest band.
  static Color foreground(
    MxSemanticColors semantic,
    ColorScheme scheme,
    double fraction,
  ) {
    _check(fraction);
    if (fraction < _reviewingFrom) return semantic.warning;
    if (fraction < _masteredFrom) return semantic.primaryForeground;
    return semantic.mastery;
  }

  /// [fraction] as a whole percent that never rounds to a lie: 0 only at 0,
  /// 100 only at 1, and 1…99 between (deck mastery spec D13).
  static int percent(double fraction) {
    _check(fraction);
    if (fraction == 0) return 0;
    if (fraction == 1) return 100;
    return (fraction * 100).round().clamp(1, 99);
  }

  /// The unfilled track: surfaceContainerLow, so the primary fill keeps 3:1
  /// against it in dark too (FE-C1).
  static Color track(ColorScheme scheme) => scheme.surfaceContainerLow;
}
```

- [ ] **Step 4: Run the ramp test and the contrast table**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/mastery_ramp_test.dart test/core/theme/token_contrast_test.dart`
Expected: PASS, every pair of Task 4 green in both themes. If a pair fails, the spec's number was wrong: stop and report it; never lower a floor.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/mastery_ramp.dart test/core/theme/mastery_ramp_test.dart test/core/theme/token_contrast_test.dart
git commit -m "feat(theme): the mastery ramp paints roles; the contrast table is green"
```

### Task 9: `MxTextStyles` takes the extension

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/theme_context.dart`, `lib/core/theme/app_component_themes.dart` (the three `MxTextStyles(texts, scheme)` calls)
- Test: `test/core/theme/mx_text_styles_ink_test.dart` → rename `test/core/theme/mx_text_styles_foreground_test.dart`

**Interfaces:**
- Produces: `MxTextStyles(TextTheme texts, ColorScheme scheme, MxSemanticColors semantic)`; `context.textStyles` builds it with `semanticColors`. The styles that were `_primaryInk` (`tabLabel(isSelected: true)`, `disclosureLabel`, `rowTitleMatch`, `requiredMarker`, `removableTagLabel`) read `semantic.primaryForeground`.

- [ ] **Step 1: Write the failing test**

`git mv test/core/theme/mx_text_styles_ink_test.dart test/core/theme/mx_text_styles_foreground_test.dart`; rewrite its body:

```dart
void main() {
  for (final (scheme, semantic, name) in [
    (AppColorSchemes.light, MxSemanticColors.light, 'light'),
    (AppColorSchemes.dark, MxSemanticColors.dark, 'dark'),
  ]) {
    final styles = MxTextStyles(
      ThemeData(colorScheme: scheme).textTheme,
      scheme,
      semantic,
    );
    test('$name brand text reads in primaryForeground, never primary', () {
      for (final style in [
        styles.disclosureLabel,
        styles.rowTitleMatch,
        styles.requiredMarker,
        styles.navLabel(isSelected: true),
      ]) {
        expect(style.color, semantic.primaryForeground);
      }
      expect(styles.navLabel(isSelected: false).color, scheme.onSurfaceVariant);
      // The removable tag chip becomes a primaryContainer pill (task 14).
      expect(styles.removableTagLabel.color, scheme.onPrimaryContainer);
    });
  }
}
```

(`navLabel` is the selected-tab style at `mx_text_styles.dart:174`.)

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/mx_text_styles_foreground_test.dart`
Expected: FAIL to compile (two-argument constructor).

- [ ] **Step 3: Change the class**

In `lib/core/theme/mx_text_styles.dart`: constructor `const MxTextStyles(this._texts, this._scheme, this._semantic);`, field `final MxSemanticColors _semantic;`, replace `Color get _primaryInk => MxDerivedColors.primaryInkOf(_scheme);` with `Color get _primaryForeground => _semantic.primaryForeground;` and every `_primaryInk` use with `_primaryForeground`, except `removableTagLabel`, which becomes `tagLabel.copyWith(color: _scheme.onPrimaryContainer)` (its chip is a `primaryContainer` pill from task 14); drop the `mx_derived_colors.dart` import, add `mx_semantic_colors.dart`. In `theme_context.dart`: `MxTextStyles get textStyles => MxTextStyles(texts, colors, semanticColors);`. In `app_component_themes.dart`: every `MxTextStyles(texts, scheme)` → `MxTextStyles(texts, scheme, semantic)` (`dialogs` and `snackbars` take a `MxSemanticColors semantic` parameter; `app_theme.dart` passes it).

- [ ] **Step 4: Run the theme tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat(theme): text styles read primaryForeground from the extension"
```

### Task 10: The card-status resolver

**Files:**
- Modify: `lib/shared/widgets/mx_status_badge.dart`
- Test: `test/shared/widgets/mx_status_badge_test.dart`

**Interfaces:**
- Produces: `extension MxCardStatusColors on MxCardStatus { Color fill(BuildContext); Color foreground(BuildContext); Color container(BuildContext); Color onContainer(BuildContext); }` (spec §4.7). `MxStatusBadge` paints the dot in `fill`, the pill in `container`, the label in `onContainer`.

- [ ] **Step 1: Write the failing test**

Add to `test/shared/widgets/mx_status_badge_test.dart`:

```dart
  testWidgets('status roles (spec 2026-10-08 §4.7): fill, foreground, '
      'container, on-container, both themes', (tester) async {
    for (final brightness in Brightness.values) {
      late BuildContext context;
      await pumpMx(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        brightness: brightness,
      );
      final colors = context.colors;
      final semantic = context.semanticColors;
      expect(MxCardStatus.newCard.fill(context), colors.outline);
      expect(MxCardStatus.newCard.foreground(context), colors.onSurfaceVariant);
      expect(MxCardStatus.newCard.container(context), colors.surfaceContainerHigh);
      expect(MxCardStatus.newCard.onContainer(context), colors.onSurfaceVariant);
      expect(MxCardStatus.learning.fill(context), semantic.warning);
      expect(MxCardStatus.learning.foreground(context), semantic.warning);
      expect(MxCardStatus.learning.container(context), semantic.warningContainer);
      expect(MxCardStatus.learning.onContainer(context), semantic.onWarningContainer);
      expect(MxCardStatus.reviewing.fill(context), colors.primary);
      expect(MxCardStatus.reviewing.foreground(context), semantic.primaryForeground);
      expect(MxCardStatus.reviewing.container(context), colors.primaryContainer);
      expect(MxCardStatus.reviewing.onContainer(context), colors.onPrimaryContainer);
      expect(MxCardStatus.mastered.fill(context), semantic.mastery);
      expect(MxCardStatus.mastered.foreground(context), semantic.mastery);
      expect(MxCardStatus.mastered.container(context), semantic.masteryContainer);
      expect(MxCardStatus.mastered.onContainer(context), semantic.onMasteryContainer);
    }
  });

  testWidgets('the pill is the container with its on-container label and '
      'the fill dot', (tester) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
      brightness: Brightness.dark,
    );
    final pill = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    expect((pill.decoration as BoxDecoration).color, MxSemanticColors.dark.warningContainer);
    expect(tester.widget<Text>(find.text('Learning')).style!.color, MxSemanticColors.dark.onWarningContainer);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_status_badge_test.dart`
Expected: FAIL to compile (`fill` undefined on `MxCardStatus`).

- [ ] **Step 3: Write the resolver and repaint the badge**

In `lib/shared/widgets/mx_status_badge.dart`, after the enum:

```dart
/// The one place a card status becomes colour (spec 2026-10-08 §4.7): the
/// fill of a dot or a bar, the foreground of text on a neutral ground, the
/// tonal ground of a pill and the text on it. The status badge, the card
/// row, the workload line and the Progress rows all read these.
extension MxCardStatusColors on MxCardStatus {
  Color fill(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.outline,
    MxCardStatus.learning => context.semanticColors.warning,
    MxCardStatus.reviewing => context.colors.primary,
    MxCardStatus.mastered => context.semanticColors.mastery,
  };

  Color foreground(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.onSurfaceVariant,
    MxCardStatus.learning => context.semanticColors.warning,
    MxCardStatus.reviewing => context.semanticColors.primaryForeground,
    MxCardStatus.mastered => context.semanticColors.mastery,
  };

  Color container(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.surfaceContainerHigh,
    MxCardStatus.learning => context.semanticColors.warningContainer,
    MxCardStatus.reviewing => context.colors.primaryContainer,
    MxCardStatus.mastered => context.semanticColors.masteryContainer,
  };

  Color onContainer(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.onSurfaceVariant,
    MxCardStatus.learning => context.semanticColors.onWarningContainer,
    MxCardStatus.reviewing => context.colors.onPrimaryContainer,
    MxCardStatus.mastered => context.semanticColors.onMasteryContainer,
  };
}
```

In `build`: delete the `semantic`, `color`, `derived`, `ink` locals and `_tint`; the dot is `_Dot(color: status.fill(context), …)`, the pill's `color: status.container(context)`, the label `style: context.textStyles.badgeLabel(status.onContainer(context))`.

- [ ] **Step 4: Run the test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_status_badge_test.dart`
Expected: PASS (existing assertions on the old ink are rewritten to `onContainer`).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_status_badge.dart test/shared/widgets/mx_status_badge_test.dart
git commit -m "feat(shared): one resolver from a card status to its roles; the status badge paints it"
```

**Phase 2 gate (evidence in the ledger):** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/ test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_focus_ring_test.dart` → PASS pasted; `flutter analyze lib/core/theme` → 0 issues. The shared widgets that call the changed signatures do not compile yet; that is phase 3's RED.

## Phase 3 · Shared widgets

Every task in this phase: the RED is the compile failure or the new state test; the GREEN is `run_tests.sh` on the group's test files; the preview is a throwaway golden test (deleted before the commit) that renders the group's gallery section light and dark into `.superpowers/sdd/<plan>/previews/<group>_<theme>.png` and is diffed against the baseline with the `golden-compare` renderer (§6.2). Baseline: the merge base (`git merge-base origin/master HEAD`, recorded in the ledger as `BASELINE=<sha>`); every pre-migration golden is read from it with `git show $BASELINE:<golden path>`, so nothing is copied and the final page (Task 19) builds from the same ref.

### Task 11: Group A — edges, hairlines and the brand foreground in shared widgets

**Files:**
- Modify: `lib/shared/widgets/mx_button.dart`, `mx_filter_chip.dart`, `mx_chip_trigger.dart`, `mx_stepper.dart`, `mx_toggle.dart`, `mx_option_row.dart`, `mx_selection_checkbox.dart`, `mx_code_field.dart`, `mx_row_ink.dart`, `mx_divided_column.dart`, `mx_sheet_actions.dart`, `mx_footer_bar.dart`, `mx_note.dart`, `mx_bottom_nav.dart`, `mx_nav_rail.dart`, `mx_search_field.dart`, `mx_spinner.dart`, `mx_stat_tile.dart`, `mx_workload_breakdown_line.dart`, `mx_snackbar.dart`, `mx_linear_progress.dart`, `mx_mastery_donut.dart`, `mx_badge.dart` (ink rows only; its containers are Task 13), `mx_dot_overline.dart` (unchanged, listed for the check)
- Test: the matching `test/shared/widgets/*_test.dart`, plus `test/shared/widgets/primary_ink_widgets_test.dart` → `role_foreground_widgets_test.dart`

**Interfaces:**
- Consumes: `MxFocusRing`, `appButtonStyle(pressedLayer:)`, `MxCardStatusColors`, `MasteryRamp.fill / foreground`.
- Produces: `MxRowInk({…, String? semanticLabel})` (Task 16 uses it); `MxToggle` on thumb `onPrimary`.

- [ ] **Step 1: Write the failing state tests**

Rename `primary_ink_widgets_test.dart` to `role_foreground_widgets_test.dart` and make it assert, for each widget below in both themes, the role instead of `primaryInk` (read the widget the way the existing test does; only the expected colour changes: `MxSemanticColors.<theme>.primaryForeground`). Add to `mx_toggle_test.dart`:

```dart
  testWidgets('on: the thumb is onPrimary (R17: the internal mark carries '
      'the state); off: the edge is outline', (tester) async {
    for (final brightness in Brightness.values) {
      final scheme = brightness == Brightness.light ? AppColorSchemes.light : AppColorSchemes.dark;
      await pumpMx(tester, MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Reminders'), brightness: brightness);
      expect(_thumbColor(tester), scheme.onPrimary);
      await pumpMx(tester, MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'), brightness: brightness);
      expect(_ring(tester)!.top.color, scheme.outline);
    }
  });

  testWidgets('focus: a ring outside the track in primaryForeground', (tester) async {
    await pumpMx(tester, MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Reminders'));
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byType(MxFocusRing), findsOneWidget);
    final painter = tester.widget<CustomPaint>(find.descendant(of: find.byType(MxFocusRing), matching: find.byType(CustomPaint)).first).foregroundPainter! as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
    expect(_ring(tester), isNull);
  });
```

Add to `mx_option_row_test.dart`, `mx_selection_checkbox_test.dart`, `mx_code_field_test.dart`, `mx_filter_chip_test.dart`, `mx_button_test.dart` one test each with the same shape: the unselected ring / unchecked edge / slot edge / chip edge / outline-tone edge is `scheme.outline`; the selected radio ring, the next code slot, the outline and text tone ink, the chip's `MxFocusRing` are `primaryForeground`; the ghost tone's edge is `scheme.outline`; the primary tone's pressed overlay is `scheme.shadow.withValues(alpha: AppOpacity.pressed)` (read `TextButton.style.overlayColor`); a disabled code slot's edge is `scheme.outlineVariant`. Add to `mx_mastery_donut_test.dart`: the track is `scheme.outlineVariant`; at 0 the arc is null and the label is `semantic.warning`; at 0.5 the label is `semantic.primaryForeground`. Add to `mx_workload_breakdown_line_test.dart`: the overdue term is `semantic.warning`, today `semantic.primaryForeground`, new `scheme.onSurfaceVariant`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/`
Expected: FAIL (compile errors from Tasks 5–10, then the new assertions).

- [ ] **Step 3: Migrate the widgets**

Exact replacements (old → new), per file:

| File | Old | New |
|---|---|---|
| `mx_button.dart` | `ink: context.derivedColors.primaryInk` (outline, text) | `ink: context.semanticColors.primaryForeground` |
| | outline tone `color: context.derivedColors.outlineEdge` | `color: colors.outline` |
| | ghost tone `color: context.derivedColors.ghostBorder` | `color: colors.outline` |
| | `focusColor: context.derivedColors.primaryInk,` | `pressedLayer: paint.fill == null ? paint.ink : colors.shadow,` |
| | `final button = TextButton(…)` | wrap: `MxFocusRing(radius: BorderRadius.circular(geometry.radius), child: TextButton(…))` |
| | dangerSoft tone `fill: context.derivedColors.dangerSoft, ink: colors.error, edge: BorderSide(color: context.derivedColors.dangerBorder, …)` | `fill: colors.errorContainer, ink: colors.onErrorContainer, edge: BorderSide.none` |
| | destructive tone `fill: context.semanticColors.errorFill, ink: context.semanticColors.onErrorFill` | `fill: colors.error, ink: colors.onError` |
| `mx_filter_chip.dart` | `color: context.derivedColors.ghostBorder` | `color: colors.outline` |
| | `focusColor: context.derivedColors.primaryInk` | `pressedLayer: ink` and wrap the button in `MxFocusRing(radius: BorderRadius.circular(AppRadius.full), child: …)` |
| | `ink.withValues(alpha: _countOpacityResting)` | `colors.onSurfaceVariant` (delete `_countOpacityResting`) |
| `mx_chip_trigger.dart` | `focusColor: context.derivedColors.primaryInk` | `pressedLayer: colors.onSurfaceVariant` + `MxFocusRing` wrap |
| `mx_stepper.dart` | `: context.derivedColors.primaryInk` (edge) | `: context.semanticColors.primaryForeground` |
| | `focusColor: context.derivedColors.primaryInk` | `pressedLayer: colors.onSurface` + `MxFocusRing` around the stepper's field |
| `mx_toggle.dart` | `_ring`: focus branch | delete; `_ring` returns the off edge `_edge(context.colors.outline, AppStroke.control)` or null |
| | `color: widget.isOn ? colors.surfaceBright : colors.onSurfaceVariant` | `color: widget.isOn ? colors.onPrimary : colors.onSurfaceVariant` |
| | the `track` widget | wrapped in `MxFocusRing(radius: BorderRadius.circular(AppRadius.full), child: track)`; `_hasFocus` and its `onFocusChange` removed |
| `mx_option_row.dart` | `? context.derivedColors.primaryInk : context.derivedColors.outlineEdge` | `? context.semanticColors.primaryForeground : context.colors.outline` |
| `mx_selection_checkbox.dart` | `color: context.derivedColors.outlineEdge` | `color: context.colors.outline` |
| `mx_code_field.dart` | `color: context.derivedColors.primaryInk` | `color: context.semanticColors.primaryForeground` |
| | `? context.derivedColors.outlineEdge : context.derivedColors.ghostBorder` | `? colors.outline : colors.outlineVariant` |
| `mx_row_ink.dart` | the `DecoratedBox(position: foreground, border: _hasFocus ? …primaryInk…)` | `MxFocusRing(radius: BorderRadius.circular(AppRadius.md), placement: MxFocusRingPlacement.inside, child: widget.child)`; `_hasFocus` and `onFocusChange` removed; add `final String? semanticLabel;` passed to `Semantics(label: semanticLabel, …)` |
| `mx_divided_column.dart`, `mx_sheet_actions.dart`, `mx_footer_bar.dart`, `mx_note.dart`, `mx_bottom_nav.dart` (border) | `context.derivedColors.ghostBorder` / `derived.ghostBorder` | `context.colors.outlineVariant` |
| `mx_bottom_nav.dart`, `mx_nav_rail.dart` | `pillTint` (`primary.withValues(alpha: …)`) and the selected icon `primaryInk` | pill `colors.primaryContainer`, selected icon and label `colors.onPrimaryContainer`; delete `_pillTintLight/Dark` |
| `mx_search_field.dart` | `? context.derivedColors.primaryInk` | `? context.semanticColors.primaryForeground` |
| `mx_spinner.dart` | `: context.derivedColors.primaryInk` | `: context.semanticColors.primaryForeground` |
| `mx_stat_tile.dart` | `MxStatTileEmphasis.primary => context.derivedColors.primaryInk` | `=> context.semanticColors.primaryForeground` |
| `mx_workload_breakdown_line.dart` | `derivedColors.warningInk` / `primaryInk` / `statusNewInk` | `semanticColors.warning` / `semanticColors.primaryForeground` / `colors.onSurfaceVariant` |
| `mx_snackbar.dart` | `focusColor: colors.inversePrimary` | `pressedLayer: colors.inversePrimary, focusColor: colors.inversePrimary` (the one inside ring that stays: the snackbar is the invariant inverse surface) |
| `mx_linear_progress.dart` | `MasteryRamp.fill(context.semanticColors, context.derivedColors, value)` | `MasteryRamp.fill(context.semanticColors, context.colors, value)` |
| `mx_mastery_donut.dart` | `MasteryRamp.fill(semantic, derived, fraction) ?? derived.statusLearningInk` / `MasteryRamp.ink(…)` / `track: context.colors.surfaceContainer` | `MasteryRamp.fill(semantic, colors, fraction) ?? semantic.warning` / `MasteryRamp.foreground(semantic, colors, fraction)` / `track: colors.outlineVariant` |
| `mx_badge.dart` | the `ink` switch rows `warningInk`, `primaryInk`, `statusMasteredInk`, `successInk` | (true, _) → `onPrimary` stays for primary only: see Task 13 for the whole table |

After the table: `grep -rn "derivedColors\|primaryInkOf\|outlineEdgeOf" lib/shared/widgets/` lists only Task 12–13 files (`mx_card`, `mx_icon_tile`, `mx_inline_banner`, `mx_outcome_tile`, `mx_empty_state`, `mx_error_state`, `mx_action_sheet_command_row`, `mx_study_top_bar`, `mx_field_message`, `mx_floating_notice`, `mx_badge`).

- [ ] **Step 4: Run the group's tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_chip_trigger_test.dart test/shared/widgets/mx_stepper_test.dart test/shared/widgets/mx_stepper_input_test.dart test/shared/widgets/mx_toggle_test.dart test/shared/widgets/mx_option_row_test.dart test/shared/widgets/mx_selection_checkbox_test.dart test/shared/widgets/mx_code_field_test.dart test/shared/widgets/mx_row_ink_test.dart test/shared/widgets/mx_divided_column_test.dart test/shared/widgets/mx_sheet_actions_test.dart test/shared/widgets/mx_footer_bar_test.dart test/shared/widgets/mx_note_test.dart test/shared/widgets/mx_bottom_nav_test.dart test/shared/widgets/mx_nav_rail_test.dart test/shared/widgets/mx_search_field_test.dart test/shared/widgets/mx_spinner_test.dart test/shared/widgets/mx_stat_tile_test.dart test/shared/widgets/mx_workload_breakdown_line_test.dart test/shared/widgets/mx_snackbar_test.dart test/shared/widgets/mx_linear_progress_test.dart test/shared/widgets/mx_mastery_donut_test.dart test/shared/widgets/role_foreground_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Preview and diff (R15)**

Write `test/_preview_tmp/group_a_preview_test.dart` that pumps `GalleryInputsSection` and `GalleryActionsSection` (from `lib/app/gallery/`) with `expectThemedGoldens`-style capture into `.superpowers/sdd/2026-10-09-m3-color-roles/previews/group_a_<theme>.png` (absolute path via `matchesGoldenFile`), run `flutter test --update-goldens test/_preview_tmp/`, view both PNGs beside their baseline (`git show $BASELINE:test/app/gallery/goldens/<name>.png > previews/baseline_<name>.png`, then a two-column montage with Pillow as in `golden_compare.py`'s `render`), and write one line per visible difference in the ledger classed `expected (§4.8 row …)` or `regression`. Delete `test/_preview_tmp/`. A regression stops the task.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(shared): edges, hairlines, focus rings and the brand foreground on roles (group A)"
```

### Task 12: Group B — containers in shared widgets

**Files:**
- Modify: `lib/shared/widgets/mx_card.dart`, `mx_inline_banner.dart`, `mx_floating_notice.dart`, `mx_dialog.dart` (actions), `mx_outcome_tile.dart`, `mx_error_state.dart`, `mx_action_sheet_command_row.dart`, `mx_study_top_bar.dart`, `mx_field_message.dart`, `mx_empty_state.dart`
- Test: the matching tests

- [ ] **Step 1: Write the failing state tests**

In `mx_card_test.dart`: hero `Material.color == scheme.surfaceContainerLow` and shape side `scheme.outlineVariant` in both themes; warning `semantic.warningContainer` with `BorderSide.none`; selected edge `semantic.primaryForeground` at `AppStroke.control`. In `mx_inline_banner_test.dart`: warning ground `warningContainer`, title and message `onWarningContainer`, glyph `warning`; danger ground `errorContainer`, title `onErrorContainer`, glyph `error`. In `mx_dialog_test.dart`: a warning dialog's cancel is `MxButtonTone.text`. In `mx_outcome_tile_test.dart`: kept `successContainer` / `onSuccessContainer`, lost `warningContainer` / `onWarningContainer`, no edge. In `mx_error_state_test.dart`: tile `errorContainer`, glyph `error`. In `mx_action_sheet_command_row_test.dart`: tile `primaryContainer` with glyph `primaryForeground`, destructive tile `errorContainer` with glyph `error`, label `primaryForeground` / `error`. In `mx_study_top_bar_test.dart`: badge `primaryContainer` / `onPrimaryContainer`. In `mx_field_message_test.dart`: warning glyph and text `semantic.warning`. In `mx_empty_state_test.dart`: tile ground per tone (`primaryContainer`, `successContainer`, `warningContainer`, `errorContainer`, `surfaceContainerHigh`) and glyph (`primaryForeground`, `success`, `warning`, `error`, `onSurfaceVariant`).

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_inline_banner_test.dart test/shared/widgets/mx_dialog_test.dart test/shared/widgets/mx_outcome_tile_test.dart test/shared/widgets/mx_error_state_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart test/shared/widgets/mx_study_top_bar_test.dart test/shared/widgets/mx_field_message_test.dart test/shared/widgets/mx_empty_state_test.dart`
Expected: FAIL.

- [ ] **Step 3: Migrate the widgets**

| File | Old | New |
|---|---|---|
| `mx_card.dart` | `AppDecorations.heroCard(context.colors, context.derivedColors)` and the other five | `AppDecorations.heroCard(context.colors)`, `warningCard(context.colors, context.semanticColors)`, `successCard(context.colors, context.semanticColors)`, `dangerCard(context.colors)`, `recessedCard(context.colors)`, `raisedCard(context.colors)` |
| | `Border.all(color: context.colors.primary, width: AppStroke.control)` | `Border.all(color: context.semanticColors.primaryForeground, width: AppStroke.control)` |
| `mx_inline_banner.dart` | the `(ground, edge, ink, titleInk)` switch | warning → `(semantic.warningContainer, null, semantic.warning, semantic.onWarningContainer)`; danger → `(colors.errorContainer, null, colors.error, colors.onErrorContainer)`; the message style's colour `onWarningContainer` / `onErrorContainer`; the border is omitted when `edge == null` (the banner carries no action of its own; the outline-tone actions beside banners on Reminders, Study home and Sync sit on the page, not on the container) |
| `mx_floating_notice.dart` | `AppDecorations.warningCard(colors, derived)`, glyph `derivedColors.warningInk` | `AppDecorations.warningCard(context.colors, context.semanticColors)`, glyph `context.semanticColors.warning`, text `onWarningContainer` |
| `mx_dialog.dart` | the cancel action's tone when `isWarning` | `MxButtonTone.text` (ink `primaryForeground`, 5.02 / 5.48 on the warning container) |
| `mx_outcome_tile.dart` | the `(ground, edge, ink)` switch and `_keptTint` | kept → `(semantic.successContainer, semantic.onSuccessContainer)`, lost → `(semantic.warningContainer, semantic.onWarningContainer)`; no border |
| `mx_error_state.dart` | `color: context.derivedColors.dangerSoft` | `color: context.colors.errorContainer` |
| `mx_action_sheet_command_row.dart` | `? context.derivedColors.dangerSoft : colors.primary.withValues(alpha: _tileTint)`; `ink` `primaryInk` / error | tile `? colors.errorContainer : colors.primaryContainer`; glyph `? colors.error : context.semanticColors.primaryForeground`; label `? colors.error : context.semanticColors.primaryForeground`; delete `_tileTint` |
| `mx_study_top_bar.dart` | `accentColor.withValues(alpha: _badgeTint)`, `accentInk = derivedColors.primaryInk` | `colors.primaryContainer`, `accentInk = colors.onPrimaryContainer`; delete `_badgeTint` |
| `mx_field_message.dart` | `context.derivedColors.warningInk` (×2) | `context.semanticColors.warning` |
| `mx_empty_state.dart` | `_toneColor` and `_Tile(color:, ink:)` with `_tileTint` | `_Tile(ground:, ink:)`: primary → `(colors.primaryContainer, semantic.primaryForeground)`, neutral → `(colors.surfaceContainerHigh, colors.onSurfaceVariant)`, success → `(semantic.successContainer, semantic.success)`, warning → `(semantic.warningContainer, semantic.warning)`, danger → `(colors.errorContainer, colors.error)`; delete `_tileTint` |

- [ ] **Step 4: Run the group's tests**

Run: the Step 2 command.
Expected: PASS.

- [ ] **Step 5: Preview and diff**

As Task 11 Step 5, with `GallerySurfacesSection`, `GalleryStatesSection` and `GalleryOverlaysSection` into `previews/group_b_<theme>.png`.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(shared): containers and their on-colours replace the soft grounds and tints (group B)"
```

### Task 13: Group C — badges and icon tiles

**Files:**
- Modify: `lib/shared/widgets/mx_badge.dart`, `lib/shared/widgets/mx_icon_tile.dart`, `lib/app/gallery/gallery_surfaces_section.dart`
- Test: `test/shared/widgets/mx_badge_test.dart`, `test/shared/widgets/mx_icon_tile_test.dart`

**Interfaces:**
- Produces: `MxIconTile` loses `seed`; `enum MxIconTileTone { tinted, primary, mastery, warning, success, caution, danger }`.

- [ ] **Step 1: Write the failing tests**

`mx_badge_test.dart`: for each tone, tonal → `(container, onContainer)` and solid → `(role, onRole)` in both themes:

| Tone | Tonal ground / label | Solid fill / label |
|---|---|---|
| primary | `primaryContainer` / `onPrimaryContainer` | `primary` / `onPrimary` |
| mastery | `masteryContainer` / `onMasteryContainer` | `mastery` / `onMastery` |
| success | `successContainer` / `onSuccessContainer` | `success` / `onSuccess` |
| warning | `warningContainer` / `onWarningContainer` | `warning` / `onWarning` |
| danger | `errorContainer` / `onErrorContainer` | `error` / `onError` |
| neutral | `surfaceContainerHigh` / `onSurfaceVariant` | `onSurfaceVariant` / `surface` |

`mx_icon_tile_test.dart`: tinted → `(primaryContainer, primaryForeground)`, primary → `(primary, onPrimary)`, mastery → `(masteryContainer, mastery)`, warning → `(warning, onWarning)`, success → `(successContainer, success)`, caution → `(warningContainer, warning)`, danger → `(errorContainer, error)`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_badge_test.dart test/shared/widgets/mx_icon_tile_test.dart`
Expected: FAIL.

- [ ] **Step 3: Migrate**

`mx_badge.dart` build body:

```dart
    final colors = context.colors;
    final semantic = context.semanticColors;
    final (fill, ink) = switch ((isSolid, tone)) {
      (true, MxBadgeTone.primary) => (colors.primary, colors.onPrimary),
      (true, MxBadgeTone.mastery) => (semantic.mastery, semantic.onMastery),
      (true, MxBadgeTone.success) => (semantic.success, semantic.onSuccess),
      (true, MxBadgeTone.warning) => (semantic.warning, semantic.onWarning),
      (true, MxBadgeTone.danger) => (colors.error, colors.onError),
      (true, MxBadgeTone.neutral) => (colors.onSurfaceVariant, colors.surface),
      (false, MxBadgeTone.primary) => (colors.primaryContainer, colors.onPrimaryContainer),
      (false, MxBadgeTone.mastery) => (semantic.masteryContainer, semantic.onMasteryContainer),
      (false, MxBadgeTone.success) => (semantic.successContainer, semantic.onSuccessContainer),
      (false, MxBadgeTone.warning) => (semantic.warningContainer, semantic.onWarningContainer),
      (false, MxBadgeTone.danger) => (colors.errorContainer, colors.onErrorContainer),
      (false, MxBadgeTone.neutral) => (colors.surfaceContainerHigh, colors.onSurfaceVariant),
    };
```

and `color: fill` on the `DecoratedBox`; delete `_tint`. `mx_icon_tile.dart`: delete `seed`, `_primaryTintLight/Dark`, `_seedTint`, `tinted`, `tint`; the `(fill, ink)` switch becomes tinted → `(colors.primaryContainer, semantic.primaryForeground)`, primary → `(colors.primary, colors.onPrimary)`, mastery → `(semantic.masteryContainer, semantic.mastery)`, warning → `(semantic.warning, semantic.onWarning)`, success → `(semantic.successContainer, semantic.success)`, caution → `(semantic.warningContainer, semantic.warning)`, danger → `(colors.errorContainer, colors.error)`. Gallery: `MxIconTile(icon: AppIcons.folder, seed: context.semanticColors.mastery)` → `const MxIconTile(icon: AppIcons.folder, tone: MxIconTileTone.mastery)`.

- [ ] **Step 4: Run the tests, then the whole shared suite**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/ test/app/`
Expected: PASS (except golden tests, which fail by design until phase 6: run them with `flutter test --tags golden --exclude-tags ''`? No: skip goldens here; `run_tests.sh` reports them, the ledger records "goldens: stale, phase 6").

- [ ] **Step 5: Preview and diff**

As Task 11 Step 5, with `GalleryStatusSection` into `previews/group_c_<theme>.png`.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets lib/app/gallery test/shared/widgets
git commit -m "feat(shared): badges and icon tiles paint M3 custom-colour sets (group C)"
```

**Phase 3 gates (evidence in the ledger):**
- CHECK STATE COVERAGE: `run_tests.sh test/shared/` output pasted; every §4.9 row has a named test in Tasks 5, 10–13.
- CHECK DEGRADE: `grep -rn "derivedColors" lib/shared` → empty; the unchanged consumers of `outline` (breadcrumb, history rail), `inversePrimary` (snackbar) and `outlineVariant` (dashed note, theme preview) rendered in the previews and read.
- CHECK SIMILAR: `grep -rn "withValues(alpha" lib/shared lib/core/theme` → only `AppOpacity.*`, `color.a * AppOpacity.disabled`, the scrim, `alpha: 0` in `mx_scroll_fade.dart`; pasted and classed.

## Phase 4 · Features

### Task 14: Feature consumers on roles

**Files:**
- Modify (20): `lib/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart`, `progress/…/progress_today_widget.dart`, `progress/…/progress_deck_row_widget.dart`, `progress/…/progress_streak_widget.dart`, `card/…/card_row_widget.dart`, `card/…/card_add_details_widget.dart`, `card/…/card_history_event_widget.dart`, `card/…/card_removable_tag_chip_widget.dart`, `card/…/card_schedule_widget.dart`, `settings/…/sync_status_section_widget.dart`, `settings/…/theme_choice_card_widget.dart`, `study/…/study_entry_hero_widget.dart`, `study/…/study_fill_widget.dart`, `study/…/study_recall_widget.dart`, `study/…/session_summary_facts_widget.dart`, `study/…/study_browse_widget.dart`, `study/…/recall_countdown_bar_widget.dart`, `study/…/study_choice_widget.dart`, `tags/…/tag_rename_dialog_widget.dart`, `transfer/…/import_step_tracker_widget.dart`, `transfer/…/import_preview_row_widget.dart`
- Test: the feature tests that assert a colour (`grep -rln "derivedColors\|MxDerivedColors\|statusLearningInk\|warningInk" test/features`)

- [ ] **Step 1: Write the failing tests**

For each feature test found by the grep, change the expected colour to the role from the table below (same assertion, new expectation). Add to `test/features/card/presentation/card_row_test.dart` (or the nearest widget test): the four status labels read `MxCardStatus.<status>.foreground(context)`; add to `test/features/study/presentation/study_choice_test.dart` (or the match/guess widget test): right tone ink `onSuccessContainer`, wrong `onErrorContainer`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/`
Expected: FAIL (compile errors in the feature widgets, then the assertions).

- [ ] **Step 3: Migrate**

| File | Old | New |
|---|---|---|
| `monitoring_code_card_widget.dart` | `color: context.derivedColors.primaryInk` | `color: context.semanticColors.primaryForeground` |
| `progress_today_widget.dart` | `color: context.derivedColors.statusLearningInk` | `color: context.semanticColors.warning` |
| `progress_deck_row_widget.dart` | `captionIn(derived.statusLearningInk)` / `captionIn(derived.primaryInk)` | `captionIn(MxCardStatus.learning.foreground(context))` / `captionIn(MxCardStatus.reviewing.foreground(context))` |
| `progress_streak_widget.dart` | `AppDecorations.recessedCard(colors, derived)` | `AppDecorations.recessedCard(context.colors)` |
| `card_row_widget.dart` | `_statusInk` switch on `derived.status…Ink` | `static MxCardStatus _badgeStatus(CardDisplayStatus s) => switch (s) { newCard => MxCardStatus.newCard, beginning => MxCardStatus.learning, reviewing => MxCardStatus.reviewing, mastered => MxCardStatus.mastered };` and `_badgeStatus(status).foreground(context)` |
| `card_add_details_widget.dart` | glyph `derivedColors.primaryInk`; edge `derivedColors.outlineEdge` | `semanticColors.primaryForeground`; `colors.outline` |
| `card_history_event_widget.dart` | `derived.warningInk` / `derived.successInk` | `semantic.warning` / `semantic.success` |
| `card_removable_tag_chip_widget.dart` | `colors.primary.withValues(alpha: _tint)` and glyph `primaryInk` | `colors.primaryContainer`; glyph `semantic.primaryForeground`; the label already reads `onPrimaryContainer` through `removableTagLabel` (task 9); delete `_tint` |
| `card_schedule_widget.dart` | `< 0 => colors.primary.withValues(alpha: _pastAlpha)` | `< 0 => colors.primary`; delete `_pastAlpha` |
| `sync_status_section_widget.dart` | `derivedColors.successInk` | `semanticColors.success` |
| `theme_choice_card_widget.dart` | `derivedColors.primaryInk` | `semanticColors.primaryForeground` |
| `study_entry_hero_widget.dart` | `statusNote(context.derivedColors.warningInk)` | `statusNote(context.semanticColors.warning)` |
| `study_fill_widget.dart`, `study_recall_widget.dart`, `import_preview_row_widget.dart` (note), `session_summary_facts_widget.dart`, `recall_countdown_bar_widget.dart`, `tag_rename_dialog_widget.dart` | `derivedColors.warningInk` | `semanticColors.warning`; in `tag_rename_dialog_widget.dart` the note sits on the warning card → `semanticColors.onWarningContainer` |
| `study_browse_widget.dart`, `import_step_tracker_widget.dart` (track) | `derivedColors.ghostBorder` | `colors.outlineVariant` |
| `study_choice_widget.dart` | `AppDecorations.studyChoiceInk(colors, derived, tone)` / `studyChoice(colors, derived, tone, …)` | `studyChoiceInk(colors, context.semanticColors, tone)` / `studyChoice(colors, context.semanticColors, tone, …)` |
| `import_preview_row_widget.dart` (glyphs) | `derivedColors.successInk` / `warningInk` | `semanticColors.success` / `warning` |
| `session_summary_facts_widget.dart` | wrong count on the summary hero (a container) | `semantic.onSuccessContainer` / `onWarningContainer` / `onErrorContainer` per the hero's tone (the widget receives the tone; the count keeps its weight) |

After the table: `grep -rn "derivedColors\|MxDerivedColors" lib/features` → empty.

- [ ] **Step 4: Run the feature tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/`
Expected: PASS except goldens (stale until phase 6; recorded).

- [ ] **Step 5: Commit**

```bash
git add lib/features test/features
git commit -m "feat(features): every screen paints colour roles"
```

### Task 15: FAB clearance at its one owner

**Files:**
- Modify: `lib/shared/widgets/mx_screen_scroll.dart`, `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart:289-292`, `lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart:91,100`, `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart:97,105`
- Test: `test/shared/widgets/mx_screen_scroll_test.dart`, `test/features/card/presentation/card_list_section_test.dart:437`

- [ ] **Step 1: Write the failing test**

In `mx_screen_scroll_test.dart`: the enum has two values (`MxScrollClearance.values.length == 2`); `fab` gives a bottom padding of `AppSpacing.section + AppSize.fab + AppSpacing.section` (100) plus the inset. In `card_list_section_test.dart:437` change the asserted clearance to `MxScrollClearance.fab`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_screen_scroll_test.dart test/features/card/presentation/card_list_section_test.dart`
Expected: FAIL (three values; `fabAboveNav` asserted).

- [ ] **Step 3: Delete the branch that never ran**

`mx_screen_scroll.dart`: `enum MxScrollClearance { base, fab }` with the doc "The FAB's shell never carries the bottom bar (`_MxFabLocation` places it `AppSpacing.section` above the content), so one FAB clearance exists: 24 + 52 + 24 (spec 2026-10-08 §4.13 round 2, P2)."; remove the `fabAboveNav` case. The three feature sites: `MxScrollClearance.fabAboveNav` → `MxScrollClearance.fab`.

- [ ] **Step 4: Run the tests**

Run: the Step 2 command plus `test/features/deck/`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_screen_scroll.dart lib/features test/shared/widgets/mx_screen_scroll_test.dart test/features
git commit -m "fix(shared): a list under a FAB clears it by 24 dp; the nav branch that never ran is gone"
```

### Task 16: The due strip's label

**Files:**
- Modify: `lib/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/deck/presentation/deck_due_strip_test.dart` (or the deck level test that pumps the strip)

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the tappable strip names its destination', (tester) async {
    await pumpMx(tester, DeckDueStripWidget(level: level, onOpen: () {}));
    expect(
      tester.getSemantics(find.byType(InkWell)),
      matchesSemantics(isButton: true, label: 'Open Study'),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_due_strip_test.dart`
Expected: FAIL (no label).

- [ ] **Step 3: Add the string and pass it**

`app_en.arb`: `"libraryDueOpen": "Open Study",` with `"@libraryDueOpen": {"description": "The due strip's tap, read by a screen reader"}`; `app_vi.arb`: `"libraryDueOpen": "Mở trang Học",`. Run `flutter gen-l10n`. In the strip: `MxRowInk(onTap: onOpen, semanticLabel: l10n.libraryDueOpen, child: …)` (the parameter Task 11 added).

- [ ] **Step 4: Run the test**

Run: the Step 2 command.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck lib/l10n test/features/deck
git commit -m "fix(deck): the due strip names where its tap goes"
```

**Phase 4 gates (evidence in the ledger):**
- CHECK STATE COVERAGE / TRANSITIONS: for the §4.12 risk rows (01 rename dialog field focus and error, 07 status badges, 08 validation edges, 16a answer buttons, 21 summary hero tones, 23a radio on the sheet, 30 field on the sheet) a widget test exists and ran; its name and result pasted.
- CHECK DEGRADE: `run_tests.sh test/features/` output; the three unchanged `outline` / `outlineVariant` consumers read.
- CHECK SIMILAR: `grep -rn "withValues(alpha\|Color\.lerp\|HSLColor\|Color(0x" lib/features lib/shared lib/app` pasted; every hit classed (state layer / scrim / fade / shadow / a finding fixed in this phase).

## Phase 5 · Delete and guard

### Task 17: Delete the derived layer and the legacy members

**Files:**
- Delete: `lib/core/theme/mx_derived_colors.dart`, `test/core/theme/mx_derived_colors_test.dart`
- Modify: `lib/core/theme/theme_context.dart` (remove `_derived`, `derivedColors`), `lib/core/theme/mx_semantic_colors.dart` (remove the six legacy members everywhere: fields, constructor, both constants, `copyWith`, `lerp`), `test/core/theme/mx_semantic_colors_test.dart` (remove their six rows)

- [ ] **Step 1: Write the failing test**

In `mx_semantic_colors_test.dart` remove the six legacy rows and add `test('no legacy member survives', () { expect(MxSemanticColors.light.toString(), isNot(contains('statusNew'))); });` — the real RED is the build: after deletion `flutter analyze` must report zero references.

- [ ] **Step 2: Delete and run the analyzer**

`git rm lib/core/theme/mx_derived_colors.dart test/core/theme/mx_derived_colors_test.dart`; edit the three files; run `flutter analyze lib test`.
Expected: 0 issues. `grep -rn "derivedColors\|MxDerivedColors\|statusLearningInk\|errorFill\|statusReviewing\b" lib test` → empty.

- [ ] **Step 3: Run the whole non-golden suite**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core test/shared test/features test/app`
Expected: PASS except golden comparisons (stale by design; listed in the ledger).

- [ ] **Step 4: Commit**

```bash
git add -A lib/core/theme test/core/theme
git commit -m "refactor(theme): the derived colour layer and the legacy semantic members are gone"
```

### Task 18: The guard rule

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`
- Create: `code-verification-guard-v2/tests/fixtures/derived_color/valid.dart`, `…/invalid.dart`, `code-verification-guard-v2/tests/test_memox_v8_derived_color_rule.py`
- Modify: `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py` (the rule-id list, if it enumerates ids)

- [ ] **Step 1: Write the fixtures and the failing pytest**

`valid.dart`:

```dart
// Legitimate colour handling (spec 2026-10-08 §6.1): none of these is a
// rebuilt derived colour.
final tween = ColorTween(begin: a, end: b);
final mid = Color.lerp(from, to, animation.value);
final pressed = ink.withValues(alpha: AppOpacity.pressed);
final dimmed = color.withValues(alpha: color.a * AppOpacity.disabled);
final clear = ground.withValues(alpha: 0);
final scrim = scheme.scrim.withValues(alpha: AppEffects.scrimOpacity);
```

`invalid.dart` (one finding per line):

```dart
final ink = Color.lerp(scheme.primary, scheme.onSurface, 0.25);
final edge = HSLColor.fromColor(scheme.outline).withSaturation(0.3).toColor();
final soft = Color.alphaBlend(error.withValues(alpha: 0.08), surface);
final tint = primary.withValues(alpha: _tint);
```

`test_memox_v8_derived_color_rule.py`:

```python
"""The derived-colour rule bans a rebuilt colour, not colour maths."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries" / "projects" / "memox-v8" / "rules"
    / "memox-design-token-rules.yaml"
)
FIXTURE_DIR = Path(__file__).parent / "fixtures" / "derived_color"
RULE = "memox.design_token.no_derived_color"


def _rule_config() -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == RULE:
            return deepcopy(rule_config)
    raise AssertionError(f"Rule not found: {RULE}")


def _violations(tmp_path: Path, relative: str, source: str) -> list:
    source_path = tmp_path / relative
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")
    rule_config = _rule_config()
    rule_config["enabled"] = True
    return RuleFactory().create(rule_config).check(tmp_path)


def test_valid_colour_handling_is_clean(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "valid.dart").read_text(encoding="utf-8")
    assert _violations(tmp_path, "lib/shared/widgets/sample.dart", source) == []


def test_each_rebuilt_colour_is_one_finding(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "invalid.dart").read_text(encoding="utf-8")
    found = _violations(tmp_path, "lib/shared/widgets/sample.dart", source)
    assert len(found) == 4


def test_the_theme_extension_lerp_is_excluded(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "invalid.dart").read_text(encoding="utf-8")
    assert _violations(tmp_path, "lib/core/theme/mx_semantic_colors.dart", source) == []
```

- [ ] **Step 2: Run the pytest to verify it fails**

Run: `cd code-verification-guard-v2 && python3 -m pytest tests/test_memox_v8_derived_color_rule.py -q`
Expected: FAIL: rule not found.

- [ ] **Step 3: Add the scope and the rule**

`scopes.yaml`, after `ui_and_theme_surfaces`:

```yaml
  # Where a colour is painted or defined: the derived-colour rule reads it.
  color_role_surfaces:
    include:
      - lib/features/*/presentation/**/*.dart
      - lib/shared/**/*.dart
      - lib/app/**/*.dart
      - lib/core/theme/**/*.dart
    exclude:
      - lib/core/theme/mx_semantic_colors.dart
      # The foundations define the alphas (shadows, opacity, effects).
      - lib/core/theme/foundations/**
      - '**/*.g.dart'
      - '**/*.freezed.dart'
```

`memox-design-token-rules.yaml`, at the end of `rules:`:

```yaml
  # The derived colour layer (MxDerivedColors, deleted 2026-10) was built three
  # ways: a lerp with a constant factor, an HSL rewrite of a role, a tint at a
  # literal or private alpha. Each is banned where colour is painted; the
  # animation lerp, ColorTween, AppOpacity state layers, the disabled dim, the
  # scrim and a fade's clear end are not matched (spec 2026-10-08 §6.1).
  - id: memox.design_token.no_derived_color
    type: regex
    severity: error
    enabled: true
    message: >-
      A colour is a ColorScheme or MxSemanticColors role; a foreground or a
      ground is never mixed from another role, and an overlay's alpha is an
      AppOpacity token. Add a measured role to MxSemanticColors instead.
    scopes:
      - color_role_surfaces
    patterns:
      - '\bColor\.lerp\s*\([^;]*,\s*(?:0?\.\d+|1(?:\.0)?|0)\s*\)'
      - '\bHS[LV]Color\s*\.\s*fromColor\s*\('
      - '\bColor\.alphaBlend\s*\('
      - '\.withValues\(\s*alpha:\s*(?!AppOpacity\.|[A-Za-z_][A-Za-z0-9_]*\.a\s*\*\s*AppOpacity\.|AppEffects\.|0\s*[,)])'
    tags:
      - memox-v8
      - design-token
      - ui
    fix:
      hint: Use a role from ColorScheme or MxSemanticColors; alpha only through AppOpacity.
```

Add the id to the ruleset-contract test's list if it enumerates ids.

- [ ] **Step 4: Run the pytest and the gate**

Run: `cd code-verification-guard-v2 && python3 -m pytest tests/test_memox_v8_derived_color_rule.py tests/test_memox_v8_ruleset_contract.py -q && cd .. && bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: pytest PASS; the gate PASS except the golden step (stale, phase 6). A guard hit in `lib/` is a same-cause defect: fix the code, not the pattern.

- [ ] **Step 5: Commit**

```bash
git add code-verification-guard-v2
git commit -m "guard(memox-v8): no_derived_color bans a rebuilt colour, not colour maths"
```

## Phase 6 · Goldens, documents, audit

### Task 19: Regenerate the goldens once and classify every diff

**Files:**
- Modify: `test/**/goldens/*.png` (regenerated)
- Create: the `golden-compare` review page (its skill writes it)

- [ ] **Step 1: Regenerate**

Run (Linux container only): `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`
Expected: every golden file rewritten; `git status --short test | wc -l` ≈ 546.

- [ ] **Step 2: Compare against the baseline**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` → PASS (the new baseline matches itself). Then build the review page with the skill: `python3 .claude/skills/golden-compare/scripts/golden_compare.py build --base $BASELINE --out <scratchpad>/golden-review` (the working tree is the head), per the skill's SKILL.md: one page, grouped by screen, every changed image before · after · diff.

- [ ] **Step 3: Classify**

On the page, each image carries one class written by the executor after viewing it: **expected** (only §4.8 / §4.9 mappings and the ring offset moved), **unexpected** (anything else), **unresolved** (cannot tell: re-render larger or add a test). Every **unexpected** is a defect: fix it (its own RED→GREEN test), regenerate that golden, reclassify. The page goes to the owner only when no **unexpected** remains; the ledger holds the counts per class.

- [ ] **Step 4: Commit the goldens**

```bash
git add test
git commit -m "test(goldens): the colour-role migration's baseline, reviewed image by image"
```

### Task 20: `DESIGN.md`, `design.json`, the UI-base spec, the detail files

**Files:**
- Modify: `DESIGN.md` (frontmatter and the Colors section, lines ~1–60 and ~220–260; the Components rows that name an ink, a ghost edge, an outline edge or a soft ground), `.impeccable/design.json` (narrative sentences on derived inks and ghost borders; component CSS: focus ring `#4151C6` → `#384CDD`, edges, tints), `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§4 `DERIVED_COLOR` paragraph → a pointer to the colour-roles spec; §9 row 174), `docs/shared/ui/screen-handoff/01-deck-list.md`, `07-card-list.md`, `14-study-entry.md`, `21-session-summary.md`, `02-review-algorithm.md` (rulings that name a derived colour; the Transitions tables reconciled per §4.12 for the screens the audit renders)
- Test: `python3 tools/docs/check.py`

- [ ] **Step 1: Rewrite the Colors section**

Replace the `### Primary` … `### Named Rules` blocks with the role vocabulary of spec §4.11: Primary (`primary` the brand fill `#5265F5` in both themes; `primary-foreground` `#384CDD` / `#BCC2FF` the brand as text, icon, focus ring or selected mark; `primary-container` / `on-primary-container` the wash: nav pill, tonal badge, icon tile, command tile); Neutral (`outline` `#7580A6` / `#7A89C6` the control edge, `outline-variant` the hairline and divider; the hero `surface-container-low` + hairline (owner 2026-10-09, V4b)); Semantic (the four sets with their four members and tones; the status mapping of §4.7; the one R17 exception: the checked selection box on a dark sheet). Named Rules: keep The One Indigo Rule and The Green Means Progress Rule; replace The Ink Is Not The Fill Rule and The Contrast Floor Rule with **The Role Pair Rule** (spec §4.1 text, the three floors, the focus ring outside the control, the shadow pressed layer). Frontmatter: delete `warning-ink`, `status-new/learning/reviewing/mastered`, `error-fill`, `on-error-fill`; add `primary-foreground`, `warning-container`, `on-warning-container`, `on-success`, `success-container`, `on-success-container`, `mastery-container`, `on-mastery-container`, the new `outline`, the new `warning`, `on-warning`, `success`, `mastery`, `streak`.

- [ ] **Step 2: `design.json`, the UI-base spec, the detail files**

`design.json`: every sentence that says "derived", "ink", "ghost border", "outlineEdge" is rewritten to the role; the focus ring CSS uses `#384CDD` with `outline-offset: 2px`. UI-base spec §4: the `DERIVED_COLOR` paragraph becomes "Derived colours were retired by `2026-10-08-m3-color-roles-design.md`; every colour is a role." §9 row 174: `| 174 | The derived ink layer (17 colours mixed at runtime) stood in for the roles the fills failed as; closed by DEV-<epic>: Material 3 roles only, one brand foreground, the custom-colour sets, the outline value, the one focus ring, supersedes rows 3, 20, 30, 58, 60, 67, 105, 121, 122, 141, 145 | owner 2026-10-09 |`. Detail files: the rulings that cite `primaryInk`, `warningInk`, `ghostBorder`, `outlineEdge`, `surfaceHero` get the role name and the date; the screen index row of each touched screen says so.

- [ ] **Step 3: Check the docs**

Run: `python3 tools/docs/check.py`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add DESIGN.md .impeccable/design.json docs
git commit -m "docs(design): DESIGN.md names the roles; The Role Pair Rule; the register closes the ink layer"
```

### Task 21: The screen-level audit and the gate

**Files:**
- Modify: the detail files' States / Transitions evidence columns (§4.12); `.superpowers/sdd/2026-10-09-m3-color-roles/progress.md` (the ledger)

- [ ] **Step 1: Render the states without a golden**

For each §4.12 row's "rendered" states (104 states), one throwaway test per screen under `test/_audit_tmp/` renders the state in both themes into `.superpowers/sdd/2026-10-09-m3-color-roles/audit/<screen>_<state>_<theme>.png`; view each; write the row's verdict (`VERIFIED` / `FAILED` / `UNVERIFIED` with the reason) and its evidence into the detail file's States table and the Transitions table rows the §4.12 column names. The three R17 contexts (tag filter sheet checkbox, Library sort toggle, Monitoring level toggle) and the two heroes with the focus ring are rendered the same way. Delete `test/_audit_tmp/`.

- [ ] **Step 2: One `impeccable audit`**

Run the Impeccable `audit` (native) on the changed system: `DESIGN.md` Colors, the gallery, the five audit screens of highest risk (01, 07, 14, 21, 30). Fix everything it finds in one batch (each fix RED→GREEN, goldens of the touched screens regenerated and reclassified on the review page); never a second audit.

- [ ] **Step 3: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh && bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: PASS and PASS; the output pasted into the ledger.

- [ ] **Step 4: Commit**

```bash
git add docs test
git commit -m "docs(screens): states and transitions verified after the colour-role migration"
```

**Phase 6 gates (evidence in the ledger):** CHECK STATE COVERAGE and CHECK STATE TRANSITIONS: the §4.12 table with every row's verdict and evidence type; CHECK DEGRADE: the gate and the goldens green, the unchanged consumers listed and read; CHECK SIMILAR: the phase-5 grep rerun on the final diff, empty of new hits; the classified golden page approved by the owner image by image; the final whole-branch review (Opus) rebuilds the states and transitions from the code and compares them with the tables.

## Execution notes

- The ledger (`.superpowers/sdd/2026-10-09-m3-color-roles/progress.md`) carries every gate's pasted output, every `Ruling:` and every preview classification; the PR body and the Done comments quote it.
- Golden comparison tests fail from Task 7 to Task 19 by design; `run_tests.sh` is always given explicit non-golden files or directories, and the ledger says "goldens: stale, phase 6" at each task until Task 19.
- A measured number in the spec that a test contradicts is reported to the owner, never adjusted in the test.
