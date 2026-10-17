import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

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
      Color fillColor() => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;

      await pumpMx(tester, _bar());
      expect(fillColor(), lightColorScheme.primary);
    },
  );

  testWidgets('the track is progress-track (R6)', (tester) async {
    await pumpMx(tester, _bar());
    final track = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byType(FractionallySizedBox),
            matching: find.byType(ColoredBox),
          )
          .first,
    );

    expect(track.color, lightColorScheme.surfaceContainerHighest);
  });

  testWidgets('the fill animates over 200ms unless motion is reduced', (
    tester,
  ) async {
    await pumpMx(tester, _bar(current: 1));
    await pumpMx(tester, _bar(current: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0.1, 0.5));
    await tester.pumpAndSettle();

    Widget reduced(int current) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: _bar(current: current)),
      ),
    );
    await tester.pumpWidget(reduced(1));
    await tester.pumpWidget(reduced(9));
    await tester.pump();
    expect(_fill(tester), 0.9);
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
    await tester.tap(find.byTooltip('Close session'));

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
    await tester.tap(find.byTooltip('Close session'));

    expect(
      tester.getSemantics(find.byTooltip('Close session')),
      isSemantics(
        tooltip: 'Close session',
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
      matching: find.byType(ClipRRect),
    );

    await pumpMx(tester, _bar());
    expect(tester.getSize(track()).height, const AppDimens().sizeTrack);

    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              extensions: [
                ...theme.extensions.values.where((e) => e is! AppDimens),
                const AppDimens(sizeTrack: 10),
              ],
            ),
            child: _bar(),
          );
        },
      ),
    );
    expect(tester.getSize(track()).height, 10);
    expect(
      tester.widget<ClipRRect>(track()).borderRadius,
      BorderRadius.circular(5),
    );
  });

  test('current outside [1, total] or an empty session is rejected', () {
    expect(() => _bar(current: 0), throwsAssertionError);
    expect(() => _bar(current: 11), throwsAssertionError);
    expect(() => _bar(current: 1, total: 0), throwsAssertionError);
  });
}
