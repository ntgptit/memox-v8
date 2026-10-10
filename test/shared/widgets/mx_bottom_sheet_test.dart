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

  testWidgets('surface: the card ground, top radius 20, the chrome shadow', (
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

    expect(surface.color, scheme.surfaceContainerLowest);
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(20)),
    );
    expect(shadow, AppShadows.chrome(scheme));
  });

  testWidgets('a 36×4 onSurfaceVariant grabber, 8 above and 4 below '
      '(FE-C1)', (tester) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(1)));
    final bar = find.descendant(
      of: find.byKey(_grabberKey),
      matching: find.byType(DecoratedBox),
    );

    expect(tester.getSize(bar), const Size(36, 4));
    expect(
      (tester.widget<DecoratedBox>(bar).decoration as BoxDecoration).color,
      scheme.onSurfaceVariant,
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

  testWidgets('showMxBottomSheet: a 56% scrim; a scrim tap closes it (RF2)', (
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
      scheme.scrim.withValues(alpha: 0.56),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);
  });

  testWidgets('a held sheet ignores a drag, a scrim tap and Back', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) => MxBottomSheet(isHeld: true, child: _rows(2)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(MxBottomSheet), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
  });

  testWidgets('the grabber dismisses the sheet for a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) => const MxBottomSheet(child: Text('Sheet')),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final grabber = find.byKey(const ValueKey('mx-sheet-grabber'));
    final label = MaterialLocalizations.of(tester.element(grabber))
        .modalBarrierDismissLabel;
    final node = tester.getSemantics(grabber);
    expect(node.label, label);
    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    handle.dispose();
  });

  testWidgets('a sheet clears the keyboard', (tester) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          final size = MediaQuery.sizeOf(context);
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: MxBottomSheet(child: TextField()),
              ),
            ),
          );
        },
      ),
    );

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.byType(TextField)).dy,
      lessThanOrEqualTo(screen.height - 300),
    );
  });

  // SW-REV-008: the head every sheet drew by hand, now the sheet's own.
  group('title and subtitle (SW-REV-008)', () {
    testWidgets('the title 16/700 20 in and 4 below the grabber; the subtitle '
        '12 under it, 4 apart; 12 above the content', (tester) async {
      await pumpMx(
        tester,
        const MxBottomSheet(
          title: 'Move to deck',
          subtitle: 'Cards keep their progress.',
          child: SizedBox(height: 40, child: Text('Content')),
        ),
      );
      final sheet = tester.getTopLeft(find.byType(MxBottomSheet));
      final title = tester.widget<Text>(find.text('Move to deck'));
      final subtitle = tester.widget<Text>(
        find.text('Cards keep their progress.'),
      );

      expect(title.style!.fontSize, 16);
      expect(title.style!.fontWeight, FontWeight.w700);
      expect(subtitle.style!.fontSize, 12);
      // The grabber block is 8 + 4 + 4 = 16, then the head's 4.
      expect(
        tester.getTopLeft(find.text('Move to deck')) - sheet,
        const Offset(20, 20),
      );
      expect(
        tester.getTopLeft(find.text('Cards keep their progress.')).dy -
            tester.getBottomLeft(find.text('Move to deck')).dy,
        4,
      );
      expect(
        tester.getTopLeft(find.text('Content')).dy -
            tester.getBottomLeft(find.text('Cards keep their progress.')).dy,
        12,
      );
    });

    testWidgets('a long title stops at two lines with an ellipsis', (
      tester,
    ) async {
      final long = List.filled(12, 'Korean vocabulary').join(' ');
      await pumpMx(
        tester,
        MxBottomSheet(title: long, child: const SizedBox(height: 40)),
      );
      final title = tester.widget<Text>(find.text(long));
      expect((title.maxLines, title.overflow), (2, TextOverflow.ellipsis));
    });

    // Through the real modal route: the title is a heading. Android names
    // the route by the route's own label, so no route name is claimed here
    // (final review 2026-10-08).
    testWidgets('opened as a sheet, the title is a heading to TalkBack', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        Builder(
          builder: (context) => MxButton(
            label: 'Open',
            onPressed: () => showMxBottomSheet<void>(
              context,
              builder: (_) => const MxBottomSheet(
                title: 'Sort',
                child: SizedBox(height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Sort')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });
}
