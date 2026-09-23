import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/widget_harness.dart';

const _bodyKey = Key('body');
const _barKey = Key('bar');
const _footerKey = Key('footer');

Widget _fab() =>
    MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {});

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
}
