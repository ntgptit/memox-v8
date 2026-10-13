import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';

// Pins the V3 foundations values (01-foundations.md). A change here is a
// design change and must come from the handoff, not from a call site.
void main() {
  test('spacing is the V3 rhythm', () {
    expect(
      [
        context.dimens.space4,
        context.dimens.space8,
        context.dimens.space12,
        context.dimens.space16,
        context.dimens.space24,
        context.dimens.space24,
        context.dimens.space32,
        context.dimens.space48,
      ],
      [4, 8, 12, 16, 20, 24, 32, 48],
    );
  });

  test('radius roles are the V3 call sites', () {
    expect(
      [
        context.dimens.radiusXs,
        context.dimens.radiusSm,
        context.dimens.radiusMd,
        context.dimens.radiusLg,
        context.dimens.radiusXl,
        AppRadius.full,
      ],
      [4, 8, 12, 16, 20, 999],
    );
  });

  test('component geometry is the V3 dimension table', () {
    expect(context.dimens.sizeButton, 48);
    expect(context.dimens.sizeButtonSmall, 36);
    expect(context.dimens.sizeButtonSmall, 32);
    expect(context.dimens.sizeChip, 28);
    expect(context.dimens.sizeInput, 52);
    expect(AppSize.iconButtonInk, 36);
    expect(context.dimens.sizeControl, 48);
    expect(context.dimens.sizeControl, 48);
    expect(context.dimens.sizeAppBar, 56);
    expect(context.dimens.sizeNav, 80);
    expect(context.dimens.sizeNav, 64);
    expect(context.dimens.sizeFab, 52);
  });

  test('icon sizes are the V3 roles and never below 16', () {
    expect(
      [
        context.dimens.sizeIconInline,
        context.dimens.sizeIconCompact,
        context.dimens.sizeIcon,
        context.dimens.sizeIconTile,
        AppIconSize.illustrative,
      ],
      [16, 20, 24, 32, 40],
    );
  });

  test('strokes, state opacities and glass effect', () {
    expect(context.dimens.strokeHairline, 1);
    expect(context.dimens.strokeFocus, 2);
    expect(AppStroke.focusOffset, 2);
    expect(context.dimens.opacityDisabledContent, 0.38);
    expect(context.dimens.opacityPressed, 0.12);
    expect(AppEffects.glassOpacity, 0.84);
    expect(AppEffects.glassBlur, 18);
  });

  test('durations are the ones the widget contracts state', () {
    expect(Durations.short3, const Duration(milliseconds: 160));
    expect(Durations.short4, const Duration(milliseconds: 200));
    expect(Durations.short4, const Duration(milliseconds: 220));
    expect(Durations.medium2, const Duration(milliseconds: 260));
    expect(AppDurations.spinnerCycle, const Duration(milliseconds: 800));
    expect(AppDurations.skeletonPulse, const Duration(milliseconds: 1400));
  });

  test('the indicator stroke is the spinner arc width', () {
    expect(context.dimens.strokeIndicator, 2);
  });

  test('control and selected-ring strokes', () {
    expect(context.dimens.strokeControl, 2);
    expect(AppStroke.selectedRing, 6);
  });

  test('the scrim is drawn at 45% (spec §5)', () {
    expect(AppEffects.scrimOpacity, 0.45);
  });
}
