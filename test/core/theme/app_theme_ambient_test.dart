import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

// What `ThemeData` leaves to the SDK when `_build` does not set it: the
// ambient glyph colour (M3F-12), the row hover and focus layers (M3F-13) and
// the platform density (M3F-14). Each is proved on a rendered widget under the
// production theme, not only on the theme field.
void main() {
  const dimens = AppDimens();

  for (final brightness in Brightness.values) {
    final scheme = brightness == Brightness.light
        ? buildLightTheme().colorScheme
        : buildDarkTheme().colorScheme;

    // M3F-12: black 87% in light, pure white in dark.
    testWidgets('M3F-12: a bare Icon paints onSurfaceVariant ($brightness)', (
      tester,
    ) async {
      late IconThemeData ambient;
      await pumpMx(
        tester,
        Builder(
          builder: (context) {
            ambient = IconTheme.of(context);
            return const Icon(AppIcons.close);
          },
        ),
        brightness: brightness,
      );

      expect(ambient.color, scheme.onSurfaceVariant);
      expect(ambient.size, dimens.sizeIcon);
      expect(
        tester.getSize(find.byIcon(AppIcons.close)),
        const Size.square(24),
      );
    });

    // M3F-13: the row hover was black 4% / white 4%, focus 12%.
    testWidgets('M3F-13: a hovered row paints onSurface at opacityHover '
        '($brightness)', (tester) async {
      await pumpMx(
        tester,
        MxRowInk(onTap: () {}, child: const SizedBox(width: 300, height: 56)),
        brightness: brightness,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(MxRowInk)));
      await tester.pumpAndSettle();

      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Material),
          ),
        ),
        paints..rect(
          color: scheme.onSurface.withValues(alpha: dimens.opacityHover),
        ),
      );
    });

    testWidgets('M3F-13: a focused row paints onSurface at opacityFocus '
        '($brightness)', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpMx(
        tester,
        MxRowInk(onTap: () {}, child: const SizedBox(width: 300, height: 56)),
        brightness: brightness,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Material),
          ),
        ),
        paints..rect(
          color: scheme.onSurface.withValues(alpha: dimens.opacityFocus),
        ),
      );
    });
  }

  // M3F-14: under linux, windows and macOS the SDK default density is
  // (-2, -2) with shrink-wrapped taps: a 40 button and a 48 field.
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.macOS,
  ]) {
    testWidgets('M3F-14: a button is 48 and a field 56 on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      await pumpMx(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxButton(label: 'Add', onPressed: () {}),
            const SizedBox(width: 300, child: MxTextField(hintText: 'Name')),
          ],
        ),
      );

      final button = tester.getSize(find.byType(MxButton)).height;
      final field = tester.getSize(find.byType(TextField)).height;
      // Reset in the body: the binding checks it before any teardown runs.
      debugDefaultTargetPlatformOverride = null;

      expect(button, 48);
      expect(field, dimens.sizeInput);
    });
  }
}
