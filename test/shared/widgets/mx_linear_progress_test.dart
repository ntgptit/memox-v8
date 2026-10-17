import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import '../../support/widget_harness.dart';

// FE-A8 H2: the themed track that 13's Resume card and 14's resume banner
// draw; decorative (S7). It is ForUI's FDeterminateProgress with MemoX's
// colours, height and motion (ForUI-first directive).

Widget _bar(Widget progress) => SizedBox(width: 200, child: progress);

final _barFinder = find.byType(MxLinearProgress);

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

/// The track's and the fill's painted colours: ForUI draws the track as a
/// decorated box and the fill as a decorated container inside it.
({Color? track, Color? fill}) _painted(WidgetTester tester) {
  final boxes = tester
      .widgetList<DecoratedBox>(
        find.descendant(of: _barFinder, matching: find.byType(DecoratedBox)),
      )
      .map((box) => (box.decoration as ShapeDecoration).color)
      .toList();
  return (track: boxes.first, fill: boxes.last);
}

void main() {
  testWidgets('the fill is the value, and the track says nothing of its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _bar(const MxLinearProgress(value: 0.6)));
    await tester.pumpAndSettle();

    expect(_fill(tester), 0.6);
    expect(tester.getSize(_barFinder).height, const AppDimens().sizeTrack);
    // No node of its own: the whole track sits under ExcludeSemantics, so
    // ForUI's "Loading" progress node never reaches TalkBack.
    expect(
      find.descendant(of: _barFinder, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    expect(find.byType(FDeterminateProgress), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the track is the ramp track and the plain fill is success', (
    tester,
  ) async {
    await pumpMx(tester, _bar(const MxLinearProgress(value: 0.5)));
    await tester.pumpAndSettle();

    final painted = _painted(tester);
    expect(painted.track, MasteryRamp.track(appLightColors));
    expect(painted.fill, tester.element(_barFinder).status.successFill);
  });

  testWidgets('a tone picks the fill colour: primary, neutral, warning', (
    tester,
  ) async {
    Future<Color?> fillOf(MxProgressTone tone) async {
      await pumpMx(tester, _bar(MxLinearProgress(value: 0.5, tone: tone)));
      await tester.pumpAndSettle();
      return _painted(tester).fill;
    }

    expect(await fillOf(MxProgressTone.primary), appLightColors.primary);
    expect(
      await fillOf(MxProgressTone.neutral),
      appLightColors.mutedForeground,
    );
    expect(
      await fillOf(MxProgressTone.warning),
      tester.element(_barFinder).status.warningFill,
    );
  });

  testWidgets('the height is sizeTrack, read from the theme', (tester) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => FTheme(
          data: FTheme.of(context).copyWith(extensions: [const _TallTrack()]),
          child: _bar(const MxLinearProgress(value: 0.5)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(_barFinder).height, 10);
  });

  group('motion', () {
    testWidgets('a change eases over 200ms, then rests on the value', (
      tester,
    ) async {
      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.2)));
      await tester.pumpAndSettle();
      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.8)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_fill(tester), inExclusiveRange(0.2, 0.8));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_fill(tester), 0.8);
    });

    // A bar mounting (a row scrolled into view, a screen opened) shows its
    // value at once, as before the migration; only a change eases.
    testWidgets('the first frame draws the value; a later change eases', (
      tester,
    ) async {
      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.6)));
      expect(_fill(tester), 0.6);

      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.2)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_fill(tester), inExclusiveRange(0.2, 0.6));
      await tester.pumpAndSettle();
      expect(_fill(tester), 0.2);
    });

    testWidgets(
      'isInstant draws the value on the first frame and on a change',
      (tester) async {
        await pumpMx(
          tester,
          _bar(const MxLinearProgress(value: 0.6, isInstant: true)),
        );
        expect(_fill(tester), 0.6);

        await pumpMx(
          tester,
          _bar(const MxLinearProgress(value: 0.25, isInstant: true)),
        );
        await tester.pump();
        expect(_fill(tester), 0.25);
      },
    );

    testWidgets('reduced motion draws the value at once, first frame and '
        'change', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.2)));
      expect(_fill(tester), 0.2);

      await pumpMx(tester, _bar(const MxLinearProgress(value: 0.9)));
      await tester.pump();
      expect(_fill(tester), 0.9);
    });
  });

  group('mastery (deck mastery spec D8, D13)', () {
    Future<double> drawn(WidgetTester tester, double value) async {
      await pumpMx(tester, _bar(MxLinearProgress.mastery(value: value)));
      await tester.pumpAndSettle();
      return _fill(tester);
    }

    testWidgets('sizeTrack tall, filled in the ramp colour', (tester) async {
      await pumpMx(tester, _bar(const MxLinearProgress.mastery(value: 0.5)));
      await tester.pumpAndSettle();

      expect(tester.getSize(_barFinder).height, const AppDimens().sizeTrack);
      expect(_painted(tester).fill, appLightColors.primary);
    });

    testWidgets('any mastery shows, and a deck short of 100% never looks '
        'full: the fill keeps its height in from either end', (tester) async {
      expect(await drawn(tester, 0.0001), const AppDimens().sizeTrack / 200);
      expect(
        await drawn(tester, 0.9999),
        1 - const AppDimens().sizeTrack / 200,
      );
      expect(await drawn(tester, 0.5), 0.5);
      expect(await drawn(tester, 1), 1);
    });

    testWidgets('a bar narrower than twice its height centres the fill', (
      tester,
    ) async {
      await pumpMx(
        tester,
        const SizedBox(width: 6, child: MxLinearProgress.mastery(value: 0.1)),
      );
      await tester.pumpAndSettle();

      expect(_fill(tester), 0.5);
    });

    testWidgets('0 paints the track alone', (tester) async {
      expect(await drawn(tester, 0), 0);
    });
  });

  test('a value outside 0 to 1 is a programming error', () {
    expect(() => MxLinearProgress(value: 1.2), throwsAssertionError);
  });
}

/// The app's dimensions with a taller progress track, to prove the bar reads
/// its height from the theme.
class _TallTrack extends AppDimens {
  const _TallTrack();

  @override
  double get sizeTrack => 10;
}
