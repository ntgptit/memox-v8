import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

// Pins the foundations ("Flashcard Color Tokens" §4, ADR-022). A change
// here is a design change and must come from that spec, not from a call
// site. flashcard_tokens_spec_test.dart pins each new field too.
void main() {
  test('spacing is the spec rhythm', () {
    expect(
      [
        AppSpacing.micro,
        AppSpacing.control,
        AppSpacing.grouped,
        AppSpacing.gutter,
        AppSpacing.gutterMedium,
        AppSpacing.cardCompact,
        AppSpacing.card,
        AppSpacing.section,
        AppSpacing.major,
        AppSpacing.pageEnd,
      ],
      [4, 8, 12, 16, 24, 16, 24, 24, 32, 48],
    );
  });

  test('radius roles are the M3 shape scale', () {
    expect(
      [
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
        AppRadius.full,
      ],
      [4, 8, 12, 16, 28, 999],
    );
  });

  test('component geometry is the spec dimension table', () {
    expect(AppSize.buttonRegular, 40);
    expect(AppSize.buttonSmall, 32);
    expect(AppSize.buttonCompact, 32);
    expect(AppSize.chip, 28);
    expect(AppSize.input, 52);
    expect(AppSize.search, 56);
    expect(AppSize.iconButtonInk, 36);
    expect(AppSize.touchTarget, 48);
    expect(AppSize.listRowMin, 48);
    expect(AppSize.appBar, 64);
    expect(AppSize.bottomNavBlock, 64);
    expect(AppSize.bottomNavBar, 64);
    expect(AppSize.fab, 52);
  });

  test('a painted button never falls below the touch target', () {
    expect(AppSize.buttonRegular, lessThan(AppSize.touchTarget));
    expect(AppSize.buttonSmall, lessThan(AppSize.touchTarget));
  });

  test('icon sizes are the V3 roles and never below 16', () {
    expect(
      [
        AppIconSize.inline,
        AppIconSize.compact,
        AppIconSize.standard,
        AppIconSize.large,
        AppIconSize.illustrative,
      ],
      [16, 20, 24, 32, 40],
    );
  });

  test('strokes and state opacities', () {
    expect(AppStroke.hairline, 1);
    expect(AppStroke.focus, 2);
    expect(AppStroke.focusOffset, 2);
    expect(AppOpacity.disabled, 0.38);
    expect(AppOpacity.disabledContainer, 0.12);
    expect(AppOpacity.hover, 0.08);
    expect(AppOpacity.pressed, 0.10);
    expect(AppOpacity.focus, 0.10);
    expect(AppOpacity.dragged, 0.16);
  });

  test('durations are the ones the widget contracts state', () {
    expect(AppDurations.selection, const Duration(milliseconds: 100));
    expect(AppDurations.toggle, const Duration(milliseconds: 150));
    expect(AppDurations.standard, const Duration(milliseconds: 200));
    expect(AppDurations.scrimFade, const Duration(milliseconds: 200));
    expect(AppDurations.sheet, const Duration(milliseconds: 300));
    expect(AppDurations.pageTransition, const Duration(milliseconds: 400));
    expect(AppDurations.longTransition, const Duration(milliseconds: 600));
    expect(AppDurations.spinnerCycle, const Duration(milliseconds: 800));
    expect(AppDurations.skeletonPulse, const Duration(milliseconds: 1400));
  });

  test('the indicator stroke is the spinner arc width', () {
    expect(AppStroke.indicator, 2);
  });

  test('control and selected-ring strokes', () {
    expect(AppStroke.control, 2);
    expect(AppStroke.selectedRing, 6);
  });

  test('the scrim is drawn at 56% (spec 2026-10-10 §4)', () {
    expect(AppEffects.scrimOpacity, 0.56);
  });
}
