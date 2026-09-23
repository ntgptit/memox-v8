import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

// Pins the V3 foundations values (01-foundations.md). A change here is a
// design change and must come from the handoff, not from a call site.
void main() {
  test('spacing is the V3 rhythm', () {
    expect(
      [
        AppSpacing.micro,
        AppSpacing.control,
        AppSpacing.grouped,
        AppSpacing.gutter,
        AppSpacing.card,
        AppSpacing.section,
        AppSpacing.major,
        AppSpacing.pageEnd,
      ],
      [4, 8, 12, 16, 20, 24, 32, 48],
    );
  });

  test('radius roles are the V3 call sites', () {
    expect(
      [
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
        AppRadius.full,
      ],
      [4, 8, 12, 16, 20, 999],
    );
  });

  test('component geometry is the V3 dimension table', () {
    expect(AppSize.buttonRegular, 48);
    expect(AppSize.buttonSmall, 36);
    expect(AppSize.buttonCompact, 32);
    expect(AppSize.chip, 28);
    expect(AppSize.input, 52);
    expect(AppSize.iconButtonInk, 36);
    expect(AppSize.touchTarget, 48);
    expect(AppSize.listRowMin, 48);
    expect(AppSize.appBar, 56);
    expect(AppSize.bottomNavBlock, 80);
    expect(AppSize.bottomNavBar, 64);
    expect(AppSize.fab, 52);
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

  test('strokes, state opacities and glass effect', () {
    expect(AppStroke.hairline, 1);
    expect(AppStroke.focus, 2);
    expect(AppStroke.focusOffset, 2);
    expect(AppOpacity.disabled, 0.38);
    expect(AppOpacity.pressed, 0.12);
    expect(AppEffects.glassOpacity, 0.84);
    expect(AppEffects.glassBlur, 18);
  });

  test('durations are the ones the widget contracts state', () {
    expect(AppDurations.toggle, const Duration(milliseconds: 160));
    expect(AppDurations.standard, const Duration(milliseconds: 200));
    expect(AppDurations.scrimFade, const Duration(milliseconds: 220));
    expect(AppDurations.sheet, const Duration(milliseconds: 260));
    expect(AppDurations.spinnerCycle, const Duration(milliseconds: 800));
    expect(AppDurations.skeletonPulse, const Duration(milliseconds: 1400));
  });
}
