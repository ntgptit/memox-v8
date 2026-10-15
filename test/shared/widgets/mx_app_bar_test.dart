import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/route_naming.dart';
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

  testWidgets('titleLarge title, screen margin', (tester) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));
    final context = tester.element(find.text('Library'));

    expect(
      tester.widget<Text>(find.text('Library')).style,
      context.texts.titleLarge,
    );
    expect(
      tester.getTopLeft(find.text('Library')).dx -
          tester.getTopLeft(find.byType(MxAppBar)).dx,
      context.screenMargin,
    );
  });

  testWidgets('titleLarge title after the leading control', (tester) async {
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
      tester.element(find.text('Japanese N5')).texts.titleLarge,
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

  testWidgets('the title is a header for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      tester.getSemantics(find.text('Library')),
      isSemantics(label: 'Library', isHeader: true),
    );
    handle.dispose();
  });

  // M3F-08: the SDK AppBar wraps its title in `namesRoute` on every platform
  // but iOS and macOS, so TalkBack announces the new screen on each push.
  for (final (platform, announces) in [
    (TargetPlatform.android, true),
    (TargetPlatform.linux, true),
    (TargetPlatform.windows, true),
    (TargetPlatform.fuchsia, true),
    (TargetPlatform.iOS, false),
    (TargetPlatform.macOS, false),
  ]) {
    testWidgets('M3F-08: the title ${announces ? 'names' : 'does not name'} '
        'the route on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final handle = tester.ensureSemantics();
      await pumpMx(tester, const MxAppBar(title: 'Library'));
      final title = tester.getSemantics(find.text('Library'));
      // Reset in the body: the binding checks it before any teardown runs.
      debugDefaultTargetPlatformOverride = null;

      expect(
        title,
        isSemantics(label: 'Library', isHeader: true, namesRoute: announces),
      );
      expect(routeNamingNodes(tester), announces ? 1 : 0);
      handle.dispose();
    });
  }

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

  testWidgets('a content bar without a leading control starts its title on '
      'the gutter (critique 2026-09-30 part 3c-1)', (tester) async {
    await pumpMx(tester, const MxAppBar(title: 'Session summary'));
    expect(
      tester.getTopLeft(find.text('Session summary')).dx,
      tester.element(find.byType(MxAppBar)).screenMargin,
    );
  });

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

    testWidgets('the leading icon is onSurface, the trailing ones '
        'onSurfaceVariant', (tester) async {
      await pumpMx(tester, bar());
      Color? glyph(IconData icon) =>
          IconTheme.of(tester.element(find.byIcon(icon))).color;

      expect(glyph(AppIcons.back), lightColorScheme.onSurface);
      expect(glyph(AppIcons.search), lightColorScheme.onSurfaceVariant);
      expect(glyph(AppIcons.more), lightColorScheme.onSurfaceVariant);
    });

    testWidgets('a disabled trailing icon dims onSurfaceVariant', (
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

      expect(
        IconTheme.of(tester.element(find.byIcon(AppIcons.search))).color,
        lightColorScheme.onSurfaceVariant.withValues(
          alpha: const AppDimens().opacityDisabledContent,
        ),
      );
    });

    testWidgets('a bar without a leading control still starts its title on '
        'the margin', (tester) async {
      await pumpMx(tester, const MxAppBar(title: 'Library'));

      expect(
        tester.getTopLeft(find.text('Library')).dx,
        tester.element(find.byType(MxAppBar)).screenMargin,
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
