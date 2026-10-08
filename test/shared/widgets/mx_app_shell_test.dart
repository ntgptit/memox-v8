import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import '../../support/widget_harness.dart';

const _bodyKey = Key('body');
const _barKey = Key('bar');
const _footerKey = Key('footer');
const _navKey = Key('nav');

Widget _fab() =>
    MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {});

/// [shell] on a 1280×800 window, outside the phone frame (FE-C5).
Future<void> _pumpWide(
  WidgetTester tester,
  Widget shell, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Directionality(textDirection: direction, child: shell),
    ),
  );
}

void main() {
  testWidgets('page ground is surface; app bar above the body', (tester) async {
    await pumpMxPage(
      tester,
      const MxAppShell(
        appBar: MxAppBar(title: 'Library'),
        body: SizedBox.expand(key: _bodyKey),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColorSchemes.light.surface,
    );
    expect(
      tester.getTopLeft(find.byKey(_bodyKey)).dy,
      tester.getBottomLeft(find.byType(MxAppBar)).dy,
    );
  });

  testWidgets('without an app bar the body clears the status inset', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      const MxAppShell(body: SizedBox.expand(key: _bodyKey)),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(tester.getTopLeft(find.byKey(_bodyKey)).dy, 24);
  });

  testWidgets('the footer is in-flow below the body', (tester) async {
    await pumpMxPage(
      tester,
      const MxAppShell(
        body: SizedBox.expand(key: _bodyKey),
        footer: SizedBox(key: _footerKey, height: 72),
      ),
    );

    expect(tester.getBottomLeft(find.byKey(_bodyKey)).dy, 800 - 72);
    expect(tester.getBottomLeft(find.byKey(_footerKey)).dy, 800);
  });

  testWidgets('FAB without nav: 16 from the edge, 24 + inset from the bottom', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(body: const SizedBox.expand(), fab: _fab()),
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpAndSettle();
    final fab = tester.getRect(find.byType(MxFab));

    expect(fab.right, 360 - 16);
    expect(fab.bottom, 800 - 24 - 20);
  });

  group('the gesture inset is added once', () {
    double scrollTail(WidgetTester tester) => tester
        .widget<ListView>(find.byType(ListView))
        .padding!
        .resolve(TextDirection.ltr)
        .bottom;
    final rows = [const SizedBox(height: 40)];

    testWidgets('a footer owns it; the scroll above adds only its 24', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          body: MxScreenScroll(children: rows),
          footer: const SizedBox(key: _footerKey, height: 72),
        ),
        padding: const EdgeInsets.only(bottom: 20),
      );

      expect(scrollTail(tester), 24);
    });

    testWidgets('a bottom nav owns it; the scroll above adds only its 24', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          body: MxScreenScroll(children: rows),
          bottomBar: const SizedBox(key: _barKey, height: 80 + 20),
        ),
        padding: const EdgeInsets.only(bottom: 20),
      );

      expect(scrollTail(tester), 24);
    });

    testWidgets('an app bar does not hand the nav-owned inset back', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          appBar: const MxAppBar(title: 'Library'),
          body: MxScreenScroll(children: rows),
          bottomBar: const SizedBox(key: _barKey, height: 80 + 20),
        ),
        padding: const EdgeInsets.only(bottom: 20),
      );

      expect(scrollTail(tester), 24);
    });
  });

  test('a FAB over a footer has no anchor rule and is rejected', () {
    expect(
      () => MxAppShell(
        body: const SizedBox(),
        footer: const SizedBox(),
        fab: _fab(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('FAB above nav: 4 over the bar, inset counted once', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(
        body: const SizedBox.expand(),
        bottomBar: const SizedBox(key: _barKey, height: 80 + 20),
        fab: _fab(),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(MxFab)).bottom,
      tester.getTopLeft(find.byKey(_barKey)).dy - 4,
    );
  });

  testWidgets('wide: the column is 720 and centred; the ground fills the '
      'window (FE-C5)', (tester) async {
    await _pumpWide(
      tester,
      const MxAppShell(
        appBar: MxAppBar(title: 'Library', key: _barKey),
        body: SizedBox.expand(key: _bodyKey),
      ),
    );

    final body = tester.getRect(find.byKey(_bodyKey));
    expect((body.left, body.width), ((1280 - 720) / 2, 720));
    expect(tester.getRect(find.byKey(_barKey)).width, 720);
    expect(tester.getSize(find.byType(Scaffold)).width, 1280);
  });

  testWidgets('wide: the FAB sits 16 in from the column edge, mirrored in '
      'RTL (FE-C5)', (tester) async {
    for (final (direction, left) in [
      (TextDirection.ltr, 1000.0 - 16 - 52),
      (TextDirection.rtl, 280.0 + 16),
    ]) {
      await _pumpWide(
        tester,
        MxAppShell(body: const SizedBox.expand(), fab: _fab()),
        direction: direction,
      );
      expect(
        tester.getTopLeft(find.byType(MxFab)).dx,
        left,
        reason: '$direction',
      );
    }
  });

  testWidgets('a notice floats over the bottom of the body', (tester) async {
    await pumpMxPage(
      tester,
      const MxAppShell(
        appBar: MxAppBar(title: 'Study'),
        body: SizedBox.expand(key: _bodyKey),
        notice: MxFloatingNotice(message: 'Some changes wait'),
      ),
    );
    final body = tester.getRect(find.byKey(_bodyKey));
    final notice = tester.getRect(find.byType(MxFloatingNotice));

    expect(body.bottom, 800);
    expect(notice.bottom, 800 - 16);
    expect((notice.left, notice.right), (16, 344));
  });

  testWidgets('the body is padded below so its end clears the notice', (
    tester,
  ) async {
    late double bottomPadding;
    await pumpMxPage(
      tester,
      MxAppShell(
        body: Builder(
          builder: (context) {
            bottomPadding = MediaQuery.paddingOf(context).bottom;
            return const SizedBox.expand();
          },
        ),
        notice: const MxFloatingNotice(message: 'Some changes wait'),
      ),
    );
    await tester.pump();
    final notice = tester.getRect(find.byType(MxFloatingNotice));

    expect(bottomPadding, 800 - notice.top);
  });

  testWidgets('the bottom bar sits below the body, never over it (DEV-302)', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(
        body: const SizedBox.expand(key: _bodyKey),
        bottomBar: MxBottomNav(
          key: _navKey,
          destinations: const [
            MxNavDestination(
              icon: AppIcons.library,
              selectedIcon: AppIcons.librarySelected,
              label: 'Library',
            ),
            MxNavDestination(
              icon: AppIcons.study,
              selectedIcon: AppIcons.studySelected,
              label: 'Study',
            ),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      tester.getBottomLeft(find.byKey(_bodyKey)).dy,
      tester.getTopLeft(find.byKey(_navKey)).dy,
    );
  });
}
