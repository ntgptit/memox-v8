import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

import '../../support/forui_expect.dart';
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
  final colors = appLightColors;

  testWidgets('surface: the background, a hairline border and the large '
      'radius on top', (tester) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(2)));
    final surface = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(MxBottomSheet),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.border != null);
    final context = tester.element(find.byType(MxBottomSheet));

    expect(surface.color, colors.background);
    expect(
      (surface.border! as Border).top,
      BorderSide(color: colors.border, width: context.hairline),
    );
    expect(
      surface.borderRadius,
      BorderRadius.vertical(top: context.radii.xl2.topLeft),
    );
  });

  testWidgets('what the sheet holds is tinted over its background', (
    tester,
  ) async {
    late Color base;
    await pumpMx(
      tester,
      MxBottomSheet(
        child: Builder(
          builder: (context) {
            base = MxTintBase.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(base, colors.background);
  });

  testWidgets('a 32×4 muted-foreground handle centred in a 48×48 target '
      '(FE-C1)', (tester) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(1)));
    final bar = find.descendant(
      of: find.byKey(_grabberKey),
      matching: find.byType(DecoratedBox),
    );

    expect(tester.getSize(bar), const Size(32, 4));
    expect(
      (tester.widget<DecoratedBox>(bar).decoration as BoxDecoration).color,
      colors.mutedForeground,
    );
    expect(tester.getSize(find.byKey(_grabberKey)), const Size(48, 48));
    expect(tester.getCenter(bar), tester.getCenter(find.byKey(_grabberKey)));

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
    // The row is an empty box with nothing to hit; the drag lands on the
    // list around it, which is what scrolls.
    await tester.drag(
      find.byKey(const ValueKey('row-2')),
      const Offset(0, -300),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-10'))).dy,
      lessThan(before),
    );
    await tester.tap(find.byKey(_footerKey));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a tappable row inside takes its tap; the gesture inset is '
      'kept', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxBottomSheet(
        footer: const SizedBox(key: _footerKey, height: 40),
        child: GestureDetector(
          key: _rowKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(height: 48),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
    );

    await tester.tap(find.byKey(_rowKey));
    expect(taps, 1);
    expect(
      tester.getBottomLeft(find.byType(MxBottomSheet)).dy -
          tester.getBottomLeft(find.byKey(_footerKey)).dy,
      24,
    );
  });

  testWidgets("showMxBottomSheet: ForUI's scrim; a scrim tap closes it "
      '(RF2)', (tester) async {
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
      forUiTheme(
        tester,
        find.byType(MxBottomSheet),
      ).modalSheetStyle.barrierFilter,
      isNotNull,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);
  });

  testWidgets('showMxBottomSheet returns what the sheet pops with', (
    tester,
  ) async {
    String? result;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () async => result = await showMxBottomSheet<String>(
            context,
            builder: (sheet) => MxBottomSheet(
              child: MxButton(
                label: 'Pick',
                onPressed: () => Navigator.of(sheet).pop('picked'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(result, 'picked');
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
        builder: (context) => MxButton(
          label: 'open',
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) => const MxBottomSheet(child: Text('Sheet')),
          ),
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
    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => candidate.id == node.id),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    handle.dispose();
  });

  testWidgets('a sheet clears the keyboard', (tester) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) =>
                const MxBottomSheet(child: SizedBox(key: _rowKey, height: 48)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final rest = tester.getBottomLeft(find.byKey(_rowKey)).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.byKey(_rowKey)).dy,
      lessThanOrEqualTo(screen.height - 300),
    );
    expect(rest, greaterThan(screen.height - 300));
  });

  // SW-REV-008: the head every sheet drew by hand, now the sheet's own.
  group('title and subtitle (SW-REV-008)', () {
    testWidgets('the title in the item-title role, space24 in and space4 '
        'below the grabber; the subtitle in the body role, muted, space4 '
        'under it; space12 above the content', (tester) async {
      await pumpMx(
        tester,
        const MxBottomSheet(
          title: 'Move to deck',
          subtitle: 'Cards keep their progress.',
          child: SizedBox(height: 40, child: Text('Content')),
        ),
      );
      const dimens = AppDimens();
      final texts = tester.element(find.byType(MxBottomSheet)).texts;
      final sheet = tester.getTopLeft(find.byType(MxBottomSheet));
      final grabber = tester.getSize(find.byKey(_grabberKey)).height;
      final title = tester.widget<Text>(find.text('Move to deck'));
      final subtitle = tester.widget<Text>(
        find.text('Cards keep their progress.'),
      );

      expect(title.style, texts.itemTitle);
      expect(
        subtitle.style,
        texts.body.copyWith(color: colors.mutedForeground),
      );
      expect(
        tester.getTopLeft(find.text('Move to deck')) - sheet,
        Offset(dimens.space24, grabber + dimens.space4),
      );
      expect(
        tester.getTopLeft(find.text('Cards keep their progress.')).dy -
            tester.getBottomLeft(find.text('Move to deck')).dy,
        dimens.space4,
      );
      expect(
        tester.getTopLeft(find.text('Content')).dy -
            tester.getBottomLeft(find.text('Cards keep their progress.')).dy,
        dimens.space12,
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
