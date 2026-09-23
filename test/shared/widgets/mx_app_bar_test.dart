import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
