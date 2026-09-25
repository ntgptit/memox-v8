import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('56 tall on the page ground, below the status inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxAppBar(title: 'Library'),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(tester.getSize(find.byType(MxAppBar)).height, 56 + 24);
  });

  testWidgets('screen density: 24 title, 16 gutter', (tester) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(tester.widget<Text>(find.text('Library')).style!.fontSize, 24);
    expect(
      tester.getTopLeft(find.text('Library')).dx -
          tester.getTopLeft(find.byType(MxAppBar)).dx,
      16,
    );
  });

  testWidgets('content density: 16 title after the leading control', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Japanese N5',
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Japanese N5')).style!.fontSize, 16);
  });

  testWidgets('a long title ellipsises and the actions keep their width', (
    tester,
  ) async {
    final title = 'A deck name that is far too long to fit ' * 3;
    await pumpMx(
      tester,
      MxAppBar(
        title: title,
        density: MxAppBarDensity.content,
        actions: [
          MxIconButton(
            icon: AppIcons.search,
            semanticLabel: 'Search',
            onPressed: () {},
          ),
          MxIconButton(
            icon: AppIcons.more,
            semanticLabel: 'More',
            onPressed: () {},
          ),
        ],
      ),
    );
    final text = tester.widget<Text>(find.text(title));

    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(MxIconButton).last).width, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title is a header for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('2x text grows the bar instead of overflowing (R1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxAppBar(title: 'Progress'), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MxAppBar)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets(
    'a title widget takes the title slot between leading and actions',
    (tester) async {
      await pumpMx(
        tester,
        MxAppBar(
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
          titleWidget: const SizedBox(key: Key('slot'), height: 40),
          actions: [
            MxIconButton(
              icon: AppIcons.more,
              semanticLabel: 'More',
              onPressed: () {},
            ),
          ],
        ),
      );
      final slot = tester.getRect(find.byKey(const Key('slot')));
      final back = tester.getRect(find.byTooltip('Back'));
      final more = tester.getRect(find.byTooltip('More'));

      expect(slot.left, greaterThanOrEqualTo(back.right));
      expect(slot.right, lessThanOrEqualTo(more.left));
      expect(slot.width, greaterThan(200));
    },
  );

  test('takes a title or a title widget, not both and not neither', () {
    expect(
      () => MxAppBar(title: 'Library', titleWidget: const SizedBox()),
      throwsAssertionError,
    );
    expect(MxAppBar.new, throwsAssertionError);
  });

  testWidgets('a text action ends on the gutter, in either density', (
    tester,
  ) async {
    for (final density in MxAppBarDensity.values) {
      await pumpMx(
        tester,
        MxAppBar(
          title: 'Words',
          density: density,
          actions: [MxButton(label: 'Done', onPressed: () {})],
        ),
      );

      expect(
        tester.getTopRight(find.byType(MxAppBar)).dx -
            tester.getTopRight(find.byType(MxButton)).dx,
        16,
        reason: density.name,
      );
    }
  });
}
