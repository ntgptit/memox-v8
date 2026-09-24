import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

const _grabberKey = ValueKey('mx-sheet-grabber');
const _footerKey = ValueKey('footer');
const _rowKey = ValueKey('row');

Widget _rows(int count) => Column(
  children: [
    for (var i = 0; i < count; i++)
      SizedBox(key: ValueKey('row-$i'), height: 48, width: double.infinity),
  ],
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('surface: container-high, top radius 20, the chrome shadow', (
    tester,
  ) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(2)));
    final shadow =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxBottomSheet),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .boxShadow;
    final surface = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(MxBottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(surface.color, scheme.surfaceContainerHigh);
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(20)),
    );
    expect(shadow, AppShadows.chrome(scheme));
  });

  testWidgets('a 36×4 outlineVariant grabber, 8 above and 4 below', (
    tester,
  ) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(1)));
    final bar = find.descendant(
      of: find.byKey(_grabberKey),
      matching: find.byType(DecoratedBox),
    );

    expect(tester.getSize(bar), const Size(36, 4));
    expect(
      (tester.widget<DecoratedBox>(bar).decoration as BoxDecoration).color,
      scheme.outlineVariant,
    );
    expect(tester.getSize(find.byKey(_grabberKey)).height, 16);

    await pumpMx(tester, MxBottomSheet(hasGrabber: false, child: _rows(1)));
    expect(find.byKey(_grabberKey), findsNothing);
  });

  testWidgets('long content stops at 85%, scrolls; the footer stays (RF1)', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxBottomSheet(
        footer: MxButton(
          key: _footerKey,
          label: 'Cancel',
          onPressed: () => taps++,
        ),
        child: _rows(40),
      ),
    );

    expect(
      tester.getSize(find.byType(MxBottomSheet)).height,
      lessThanOrEqualTo(800 * 0.85),
    );
    final before = tester.getTopLeft(find.byKey(const ValueKey('row-10'))).dy;
    await tester.drag(
      find.byKey(const ValueKey('row-2')),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-10'))).dy,
      lessThan(before),
    );
    await tester.tap(find.byKey(_footerKey));
    expect(taps, 1);
  });

  testWidgets('a row ripple paints on the sheet; the gesture inset is kept', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBottomSheet(
        footer: const SizedBox(key: _footerKey, height: 40),
        child: InkWell(
          key: _rowKey,
          onTap: () {},
          child: const SizedBox(height: 48),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
    );

    expect(
      tester.widget<Material>(
        find
            .ancestor(of: find.byKey(_rowKey), matching: find.byType(Material))
            .first,
      ),
      same(
        tester.widget<Material>(
          find
              .descendant(
                of: find.byType(MxBottomSheet),
                matching: find.byType(Material),
              )
              .first,
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.byType(MxBottomSheet)).dy -
          tester.getBottomLeft(find.byKey(_footerKey)).dy,
      24,
    );
  });

  testWidgets('showMxBottomSheet: a 45% scrim; a scrim tap closes it (RF2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) => MxBottomSheet(child: _rows(2)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MxBottomSheet), findsOneWidget);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      scheme.scrim.withValues(alpha: 0.45),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);
  });
}
