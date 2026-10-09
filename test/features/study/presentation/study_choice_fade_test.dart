import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';

import '../../../support/golden_harness.dart';

// A faded choice (a Guess option out of play) fades its card, fill and
// border included, not only its content (task 18, pixel probe).

Future<ui.Color> _pixelAtCentre(
  WidgetTester tester,
  Finder target,
  Color Function(Color) onSeen,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(goldenBoundaryKey),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(() => image.toByteData()))!;
  final centre = tester.getCenter(target);
  final offset = (centre.dy.round() * image.width + centre.dx.round()) * 4;
  final seen = Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
  image.dispose();
  return onSeen(seen);
}

void main() {
  // The selected tone's fill is far from the ground, so the fade is a clear
  // step in the pixel; the fade does not depend on the tone.
  testWidgets('a faded choice paints its card at AppOpacity.muted over the '
      'ground, not at full strength', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenBoundaryKey,
        child: MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: StudyChoiceWidget(
                  tone: StudyChoiceTone.selected,
                  isFaded: true,
                  semanticsLabel: 'a',
                  builder: (ink) => const SizedBox(width: 200, height: 56),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fill = AppDecorations.studyChoice(
      theme.colorScheme,
      MxSemanticColors.light,
      StudyChoiceTone.selected,
    ).color!;
    final ground = theme.scaffoldBackgroundColor;
    final expected = Color.alphaBlend(
      fill.withValues(alpha: AppOpacity.muted),
      ground,
    );
    final seen = await _pixelAtCentre(
      tester,
      find.byType(StudyChoiceWidget),
      (c) => c,
    );

    expect(fill, isNot(ground), reason: 'the probe needs a visible fill');
    for (final (got, want) in [
      (seen.r, expected.r),
      (seen.g, expected.g),
      (seen.b, expected.b),
    ]) {
      expect(got * 255, closeTo(want * 255, 2));
    }
  });
}
