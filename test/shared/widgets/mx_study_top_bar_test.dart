import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../support/forui_expect.dart';
import '../../support/route_naming.dart';
import '../../support/widget_harness.dart';

MxStudyTopBar _bar({int current = 3, int total = 10, bool isClosable = true}) =>
    MxStudyTopBar(
      modeLabel: 'Review',
      current: current,
      total: total,
      counterLabel: '$current / $total',
      closeLabel: 'Close session',
      onClose: isClosable ? () {} : null,
    );

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

/// The track's and the fill's painted colours (ForUI's decorated boxes).
({Color? track, Color? fill}) _painted(WidgetTester tester) {
  final colors = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MxLinearProgress),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => (box.decoration as ShapeDecoration).color)
      .toList();
  return (track: colors.first, fill: colors.last);
}

void main() {
  testWidgets('fill is current/total; the counter shows the caller label', (
    tester,
  ) async {
    await pumpMx(tester, _bar());
    await tester.pumpAndSettle();

    expect(_fill(tester), 0.3);
    expect(find.text('3 / 10'), findsOneWidget);
  });

  // DEV-393: the session route is pushed full screen with this bar on top,
  // so its mode names the route, as the SDK AppBar's title does.
  for (final (platform, announces) in [
    (TargetPlatform.android, true),
    (TargetPlatform.iOS, false),
  ]) {
    testWidgets('the mode ${announces ? 'names' : 'does not name'} the route '
        'on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final handle = tester.ensureSemantics();
      await pumpMx(tester, _bar());
      final node = tester.getSemantics(find.text('REVIEW'));
      final count = routeNamingNodes(tester);
      debugDefaultTargetPlatformOverride = null;

      expect(node, isSemantics(label: 'Review', namesRoute: announces));
      expect(count, announces ? 1 : 0);
      handle.dispose();
    });
  }

  testWidgets('the badge is the mode label upper-cased', (tester) async {
    await pumpMx(tester, _bar());

    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets(
    'the fill is primary, in every mode (critique 2026-09-30 part 3c-2, R8)',
    (tester) async {
      await pumpMx(tester, _bar());
      await tester.pumpAndSettle();

      expect(_painted(tester).fill, appLightColors.primary);
    },
  );

  testWidgets('the track is the ramp\'s progress track (R6)', (tester) async {
    await pumpMx(tester, _bar());
    await tester.pumpAndSettle();

    expect(_painted(tester).track, MasteryRamp.track(appLightColors));
  });

  testWidgets('the fill animates over 200ms unless motion is reduced', (
    tester,
  ) async {
    await pumpMx(tester, _bar(current: 1));
    await tester.pumpAndSettle();
    await pumpMx(tester, _bar(current: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0.1, 0.5));
    await tester.pumpAndSettle();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMx(tester, _bar(current: 1));
    await pumpMx(tester, _bar(current: 9));
    await tester.pump();
    expect(_fill(tester), 0.9);
  });

  testWidgets('the mode chip takes at most 0.4 of the bar and ellipsizes', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxStudyTopBar(
        modeLabel: 'A very long study mode name that cannot fit',
        current: 3,
        total: 10,
        counterLabel: '3 / 10',
        closeLabel: 'Close session',
        onClose: () {},
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(MxStudyTopBar));
    final chip = tester.getRect(find.byType(MxToneBadge));
    // A long name fills the chip to its cap, 0.4 of the row.
    expect(chip.width, lessThanOrEqualTo(bar.width * 0.4));
    expect(chip.width, greaterThan(bar.width * 0.35));
    expect(
      tester.widget<Text>(find.textContaining('A VERY LONG')).overflow,
      TextOverflow.ellipsis,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chip is the primary tint with primary ink', (tester) async {
    await pumpMx(tester, _bar());

    final chip = tester.widget<MxToneBadge>(find.byType(MxToneBadge));
    expect(chip.ink, appLightColors.primary);
    expect(textColor(tester, find.text('REVIEW')), appLightColors.primary);
  });

  testWidgets('close is a labelled 48 target that fires onClose', (
    tester,
  ) async {
    var closed = 0;
    await pumpMx(
      tester,
      MxStudyTopBar(
        modeLabel: 'Review',
        current: 1,
        total: 2,
        counterLabel: '1 / 2',
        closeLabel: 'Close session',
        onClose: () => closed++,
      ),
    );
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();

    expect(closed, 1);
    await expectAccessibleTargets(tester);
  });

  // A held session (submitting) shows Close as disabled, not as a live
  // no-op (screen 37).
  testWidgets('onClose null: Close is a disabled node and fires nothing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _bar(isClosable: false));
    await tester.tap(find.byType(MxIconButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Close session')),
      isSemantics(
        label: 'Close session',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('the counter is a polite live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _bar());

    expect(
      tester.getSemantics(find.text('3 / 10')),
      isSemantics(label: '3 / 10', isLiveRegion: true),
    );
    handle.dispose();
  });

  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    testWidgets('${width.toInt()} wide window: the close glyph starts and the '
        'counter ends on the $margin screen margin', (tester) async {
      await pumpMx(tester, WindowWidthScope(width: width, child: _bar()));
      final bar = tester.getRect(find.byType(MxStudyTopBar));

      expect(
        tester.getTopLeft(find.byIcon(AppIcons.close)).dx - bar.left,
        margin,
      );
      expect(bar.right - tester.getTopRight(find.text('3 / 10')).dx, margin);
    });
  }

  testWidgets('M3F-18: the track is sizeTrack tall, read from the theme', (
    tester,
  ) async {
    Finder track() => find.descendant(
      of: find.byType(MxStudyTopBar),
      matching: find.byType(MxLinearProgress),
    );

    await pumpMx(tester, _bar());
    expect(tester.getSize(track()).height, const AppDimens().sizeTrack);

    await pumpMx(
      tester,
      Builder(
        builder: (context) => FTheme(
          data: FTheme.of(context).copyWith(extensions: [const _TallTrack()]),
          child: _bar(),
        ),
      ),
    );
    expect(tester.getSize(track()).height, 10);
  });

  test('current outside [1, total] or an empty session is rejected', () {
    expect(() => _bar(current: 0), throwsAssertionError);
    expect(() => _bar(current: 11), throwsAssertionError);
    expect(() => _bar(current: 1, total: 0), throwsAssertionError);
  });
}

/// The app's dimensions with a taller progress track, to prove the bar reads
/// its track height from the theme.
class _TallTrack extends AppDimens {
  const _TallTrack();

  @override
  double get sizeTrack => 10;
}
