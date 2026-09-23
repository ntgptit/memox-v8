import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import '../../support/widget_harness.dart';

enum _Range { week, month }

const _segments = [
  MxSegment(value: _Range.week, label: '7d'),
  MxSegment(value: _Range.month, label: '30d'),
];

BoxDecoration _thumb(WidgetTester tester, String label) =>
    tester
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('the active option sits on a raised lowest thumb', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSegmentedTray(
        segments: _segments,
        selected: _Range.week,
        onSelected: (_) {},
      ),
    );

    expect(_thumb(tester, '7d').color, scheme.surfaceContainerLowest);
    expect(_thumb(tester, '7d').boxShadow, AppShadows.whisper(scheme));
    expect(_thumb(tester, '30d').color, isNull);
    expect(tester.widget<Text>(find.text('7d')).style!.color, scheme.onSurface);
    expect(
      tester.widget<Text>(find.text('30d')).style!.color,
      scheme.onSurfaceVariant,
    );
  });

  testWidgets('a tap reports the option; 48×48 targets (I4)', (tester) async {
    _Range? picked;
    await pumpMx(
      tester,
      MxSegmentedTray(
        segments: _segments,
        selected: _Range.week,
        onSelected: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('30d'));

    expect(picked, _Range.month);
    expect(tester.getSize(find.byType(MxSegmentedTray<_Range>)).height, 48);
    await expectAccessibleTargets(tester);
  });

  testWidgets('announced as a selected exclusive option', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxSegmentedTray(
        segments: _segments,
        selected: _Range.week,
        onSelected: (_) {},
      ),
    );

    expect(
      tester.getSemantics(find.text('7d')),
      isSemantics(
        label: '7d',
        isSelected: true,
        isButton: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    handle.dispose();
  });

  test('two or three options only', () {
    expect(
      () => MxSegmentedTray(
        segments: const [MxSegment(value: 1, label: 'a')],
        selected: 1,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
