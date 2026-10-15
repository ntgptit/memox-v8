import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';

import 'token_source.dart' show contrast;

// Component slots corrected from the Material 3 audit (DEV-385). Each test
// names its ledger finding (docs/shared/design/m3-adoption-ledger.md, §5).
void main() {
  const dimens = AppDimens();

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    final scheme = theme.colorScheme;

    group(name, () {
      // M3F-15: a pressed, hovered or focused on switch is told from its
      // track at the 3:1 non-text floor.
      test('M3F-15: every on state keeps the handle clear of the track', () {
        final sw = theme.switchTheme;
        const on = WidgetState.selected;
        for (final extra in [
          <WidgetState>{},
          {WidgetState.pressed},
          {WidgetState.hovered},
          {WidgetState.focused},
          {WidgetState.pressed, WidgetState.focused, WidgetState.hovered},
        ]) {
          final states = {on, ...extra};

          expect(
            contrast(
              sw.thumbColor!.resolve(states)!,
              sw.trackColor!.resolve(states)!,
            ),
            greaterThanOrEqualTo(3),
            reason: '$states',
          );
        }
      });

      // M3F-07: the icon button's ring is offset like the buttons', drawn
      // only when focused, and the container keeps no side.
      test('M3F-07: the icon button focus ring rides on the shape, offset', () {
        final style = theme.iconButtonTheme.style!;
        final focused =
            style.shape!.resolve({WidgetState.focused})! as MxFocusRingBorder;

        expect(focused.base, isA<CircleBorder>());
        expect(focused.gap, dimens.strokeFocusGap);
        expect(focused.ring.width, dimens.strokeFocus);
        expect(focused.ring.color, scheme.primary);
        expect(
          (style.shape!.resolve({})! as MxFocusRingBorder).ring,
          BorderSide.none,
        );
        expect(style.side?.resolve({WidgetState.focused}), isNull);
      });
    });
  }
}
