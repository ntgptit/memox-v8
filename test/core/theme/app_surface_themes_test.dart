import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';

// The overlay themes (app_surface_themes.dart): dialog, bottom sheet, snack
// bar and tooltip carry their Material 3 values, with the Design System's
// surfaces and tokens.
void main() {
  const dimens = AppDimens();

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    final scheme = theme.colorScheme;

    group(name, () {
      test(
        'dialog: Material 3 text roles, insets and a transparent shadow',
        () {
          final dialog = theme.dialogTheme;
          expect(dialog.backgroundColor, scheme.surfaceContainerHigh);
          expect(
            (dialog.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(dimens.radiusXl),
          );
          expect(
            dialog.barrierColor,
            scheme.scrim.withValues(alpha: dimens.opacityScrim),
          );
          // The elevation is Material 3's 6; its shadow is not drawn.
          expect(dialog.elevation, 6);
          expect(dialog.shadowColor, Colors.transparent);
          expect(
            dialog.titleTextStyle!.fontSize,
            theme.textTheme.headlineSmall!.fontSize,
          );
          expect(dialog.titleTextStyle!.color, scheme.onSurface);
          expect(
            dialog.contentTextStyle!.fontSize,
            theme.textTheme.bodyMedium!.fontSize,
          );
          expect(dialog.contentTextStyle!.color, scheme.onSurfaceVariant);
          expect(
            dialog.actionsPadding,
            EdgeInsets.fromLTRB(
              dimens.space24,
              0,
              dimens.space24,
              dimens.space24,
            ),
          );
          expect(dialog.constraints, const BoxConstraints(minWidth: 280));
        },
      );

      test(
        'sheet: the low container, a transparent shadow, the drag handle',
        () {
          final sheet = theme.bottomSheetTheme;
          expect(sheet.backgroundColor, scheme.surfaceContainerLow);
          expect(sheet.modalBackgroundColor, scheme.surfaceContainerLow);
          expect(sheet.elevation, 1);
          expect(sheet.modalElevation, 1);
          expect(sheet.shadowColor, Colors.transparent);
          expect(
            (sheet.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.vertical(top: Radius.circular(dimens.radiusXl)),
          );
          expect(sheet.dragHandleColor, scheme.onSurfaceVariant);
          expect(sheet.dragHandleSize, const Size(32, 4));
          expect(
            sheet.modalBarrierColor,
            scheme.scrim.withValues(alpha: dimens.opacityScrim),
          );
        },
      );

      test(
        'snack bar: the inverse surface, radiusXs, the action threshold',
        () {
          final bar = theme.snackBarTheme;
          expect(bar.backgroundColor, scheme.inverseSurface);
          expect(bar.actionTextColor, scheme.inversePrimary);
          expect(
            (bar.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(dimens.radiusXs),
          );
          expect(bar.actionOverflowThreshold, 0.25);
        },
      );

      test('tooltip: 24 tall at least, space8 across and space4 down', () {
        expect(
          theme.tooltipTheme.constraints,
          const BoxConstraints(minHeight: 24),
        );
        expect(
          theme.tooltipTheme.padding,
          EdgeInsets.symmetric(
            horizontal: dimens.space8,
            vertical: dimens.space4,
          ),
        );
      });
    });
  }
}
