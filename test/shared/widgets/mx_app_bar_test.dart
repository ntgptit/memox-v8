import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/widget_harness.dart';

TextTheme _texts(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(MxAppBar))).textTheme;

void main() {
  testWidgets('64 tall on the page ground, below the status inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxAppBar(title: 'Library'),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(tester.getSize(find.byType(MxAppBar)).height, AppSize.appBar + 24);
  });

  testWidgets('screen density: titleLarge title, the 16 compact margin', (
    tester,
  ) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      tester.widget<Text>(find.text('Library')).style!.fontSize,
      _texts(tester).titleLarge!.fontSize,
    );
    expect(
      tester.getTopLeft(find.text('Library')).dx -
          tester.getTopLeft(find.byType(MxAppBar)).dx,
      AppSpacing.gutter,
    );
  });

  testWidgets('content density: titleMedium title after the leading control', (
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

    expect(
      tester.widget<Text>(find.text('Japanese N5')).style!.fontSize,
      _texts(tester).titleMedium!.fontSize,
    );
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
  testWidgets(
    'a search field in the bar keeps 4 above and below it and ends on the gutter',
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
          titleWidget: MxSearchField(
            controller: TextEditingController(),
            hintText: 'Search',
            clearLabel: 'Clear',
          ),
        ),
      );
      final bar = tester.getRect(find.byType(MxAppBar));
      final field = tester.getRect(find.byType(MxSearchField));

      expect(field.height, AppSize.search);
      expect(field.top - bar.top, AppSpacing.micro);
      expect(bar.bottom - field.bottom, AppSpacing.micro);
      // The field lines up with the content's side margin below it.
      expect(bar.right - field.right, AppSpacing.gutter);
    },
  );

  testWidgets('a content bar without a leading control starts its title on '
      'the gutter (critique 2026-09-30 part 3c-1)', (tester) async {
    await pumpMx(
      tester,
      const MxAppBar(
        title: 'Session summary',
        density: MxAppBarDensity.content,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Session summary')).dx,
      AppSpacing.gutter,
    );
  });

  testWidgets('with a leading control the content bar starts on the margin', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Words',
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(MxIconButton)).dx, AppSpacing.gutter);
  });
}
