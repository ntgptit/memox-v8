import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

void main() {
  testWidgets('sizeAppBar tall, below the status inset', (tester) async {
    await pumpMx(
      tester,
      const MxAppBar(title: 'Library'),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(
      tester.getSize(find.byType(MxAppBar)).height,
      const AppDimens().sizeAppBar + 24,
    );
  });

  // Without a leading control the title starts on the gutter (critique
  // 2026-09-30 part 3c-1): the bar starts at x 0, so the title's offset in the
  // bar is its offset on the screen.
  testWidgets('screen-title role, screen margin', (tester) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));
    final context = tester.element(find.text('Library'));

    expect(tester.getTopLeft(find.byType(MxAppBar)).dx, 0);
    expect(tester.getTopLeft(find.text('Library')).dx, context.screenMargin);
    expect(
      tester.widget<Text>(find.text('Library')).style,
      context.texts.screenTitle,
    );
    expect(
      tester.getTopLeft(find.text('Library')).dx -
          tester.getTopLeft(find.byType(MxAppBar)).dx,
      context.screenMargin,
    );
  });

  testWidgets('screen-title role after the leading control', (tester) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Japanese N5',
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Japanese N5')).style,
      tester.element(find.text('Japanese N5')).texts.screenTitle,
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

  testWidgets(
    'a title widget takes the title slot between leading and actions',
    (tester) async {
      await pumpMx(
        tester,
        MxAppBar(
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
      final back = tester.getRect(find.byType(MxIconButton).first);
      final more = tester.getRect(find.byType(MxIconButton).last);

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

  testWidgets('a text action ends on the gutter', (tester) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Words',
        isLastActionText: true,
        actions: [MxButton(label: 'Done', onPressed: () {})],
      ),
    );

    expect(
      tester.getTopRight(find.byType(MxAppBar)).dx -
          tester.getTopRight(find.byType(MxButton)).dx,
      tester.element(find.byType(MxAppBar)).screenMargin,
    );
  });
  testWidgets('a text action in a wrapper widget ends on the gutter', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Words',
        isLastActionText: true,
        actions: [_DoneAction(onPressed: () {})],
      ),
    );

    expect(
      tester.getTopRight(find.byType(MxAppBar)).dx -
          tester.getTopRight(find.byType(MxButton)).dx,
      tester.element(find.byType(MxAppBar)).screenMargin,
    );
  });

  testWidgets('an icon glyph in a wrapper widget sits on the margin', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Words',
        actions: [_MoreAction(onPressed: () {})],
      ),
    );

    expect(
      tester.getTopRight(find.byType(MxAppBar)).dx -
          tester.getTopRight(find.byIcon(AppIcons.more)).dx,
      tester.element(find.byType(MxAppBar)).screenMargin,
    );
  });

  testWidgets('a search field in a wrapper widget keeps the bar padding', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        isTitleField: true,
        titleWidget: _FieldSlot(controller: TextEditingController()),
      ),
    );
    final bar = tester.getRect(find.byType(MxAppBar));
    final field = tester.getRect(find.byType(MxSearchField));

    expect(field.top - bar.top, const AppDimens().space8);
    expect(
      bar.right - field.right,
      tester.element(find.byType(MxAppBar)).screenMargin,
    );
  });

  testWidgets(
    'a search field in the bar keeps 8 above and below it and ends on the gutter',
    (tester) async {
      await pumpMx(
        tester,
        MxAppBar(
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
          isTitleField: true,
          titleWidget: MxSearchField(
            controller: TextEditingController(),
            hintText: 'Search',
            clearLabel: 'Clear',
          ),
        ),
      );
      final bar = tester.getRect(find.byType(MxAppBar));
      final field = tester.getRect(find.byType(MxSearchField));

      expect(field.top - bar.top, const AppDimens().space8);
      expect(bar.bottom - field.bottom, const AppDimens().space8);
      // The field lines up with the content's screen margin below it.
      expect(
        bar.right - field.right,
        tester.element(find.byType(MxAppBar)).screenMargin,
      );
    },
  );

  group('icon glyphs line up with the body margin', () {
    Widget bar() => MxAppBar(
      title: 'Words',
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: 'Back',
        onPressed: () {},
      ),
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
    );

    for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
      testWidgets('${width.toInt()} wide window: glyphs sit on the $margin '
          'margin', (tester) async {
        await pumpMx(tester, WindowWidthScope(width: width, child: bar()));
        final barRect = tester.getRect(find.byType(MxAppBar));

        expect(
          tester.getTopLeft(find.byIcon(AppIcons.back)).dx - barRect.left,
          margin,
        );
        expect(
          barRect.right - tester.getTopRight(find.byIcon(AppIcons.more)).dx,
          margin,
        );
      });
    }

    testWidgets('the leading and trailing icons are in ForUI\'s ghost icon '
        'colour', (tester) async {
      await pumpMx(tester, bar());
      final ink = forUiTheme(
        tester,
        find.byType(MxAppBar),
      ).buttonStyles.ghost.lg.iconContentStyle.iconStyle.resolve({}).color;

      for (final icon in [AppIcons.back, AppIcons.search, AppIcons.more]) {
        expect(iconColor(tester, find.byIcon(icon)), ink);
      }
    });

    testWidgets('a disabled trailing icon takes ForUI\'s disabled ink', (
      tester,
    ) async {
      await pumpMx(
        tester,
        const MxAppBar(
          title: 'Words',
          actions: [
            MxIconButton(
              icon: AppIcons.search,
              semanticLabel: 'Search',
              onPressed: null,
            ),
          ],
        ),
      );
      final style = forUiTheme(
        tester,
        find.byType(MxAppBar),
      ).buttonStyles.ghost.lg.iconContentStyle.iconStyle;

      expect(
        iconColor(tester, find.byIcon(AppIcons.search)),
        style.resolve({FTappableVariant.disabled}).color,
      );
      expect(
        style.resolve({FTappableVariant.disabled}).color,
        isNot(style.resolve({}).color),
      );
    });
  });

  testWidgets('the bar paints no ground of its own; the shell does', (
    tester,
  ) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
  });
}

/// A feature widget that returns a compact text button, as the reorder bar's
/// Done does.
class _DoneAction extends StatelessWidget {
  const _DoneAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      MxButton(label: 'Done', size: MxButtonSize.small, onPressed: onPressed);
}

/// A feature widget that returns an icon button, as the deck menu does.
class _MoreAction extends StatelessWidget {
  const _MoreAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MxIconButton(
    icon: AppIcons.more,
    semanticLabel: 'More',
    onPressed: onPressed,
  );
}

class _FieldSlot extends StatelessWidget {
  const _FieldSlot({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MxSearchField(
    controller: controller,
    hintText: 'Search',
    clearLabel: 'Clear',
  );
}
