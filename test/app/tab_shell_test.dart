import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/app_harness.dart';

// FE-C5: the tab shell shows a rail from 600 dp, and a bar when the window is
// short (spec 2026-09-28-tablet-rail-design.md D1, D2, D7).

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Finder _railItem(String label) =>
    find.descendant(of: find.byType(MxNavRail), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('599 wide: the bottom nav; 600 wide: the rail', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(599, 900),
      devicePixelRatio: 1,
    );
    expect(find.byType(MxBottomNav), findsOneWidget);
    expect(find.byType(MxNavRail), findsNothing);

    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(find.byType(MxNavRail), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
  });

  libraryTest('a compact-height window gets the bar at any width', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(900, 479),
      devicePixelRatio: 1,
    );
    expect(find.byType(MxBottomNav), findsOneWidget);
    expect(find.byType(MxNavRail), findsNothing);

    tester.view.physicalSize = const Size(900, 480);
    await tester.pumpAndSettle();
    expect(find.byType(MxNavRail), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
  });

  libraryTest('beside the rail the margin follows the window, not the pane: '
      '620 wide is a medium window', (tester, env) async {
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(620, 900),
      devicePixelRatio: 1,
    );

    final branch = tester.element(find.byType(MxAppShell).last);
    // The pane is 620 - 80 = 540, which alone would read as compact.
    expect(MediaQuery.sizeOf(branch).width, 540);
    expect(branch.windowSize, WindowSize.medium);
    expect(branch.screenMargin, branch.dimens.marginScreenMedium);
    expect(
      tester.getTopLeft(_barTitle(_en.navLibrary)).dx,
      80 + branch.dimens.marginScreenMedium,
    );
  });

  libraryTest('the rail switches branches and keeps each stack; a re-tap '
      'returns to the root', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(1280, 800),
      devicePixelRatio: 1,
    );
    await _tap(tester, find.text('Korean'));
    expect(_barTitle('Korean'), findsOneWidget);

    await _tap(tester, _railItem(_en.navStudy));
    expect(_barTitle('Korean'), findsNothing);
    await _tap(tester, _railItem(_en.navLibrary));
    expect(_barTitle('Korean'), findsOneWidget);

    await _tap(tester, _railItem(_en.navLibrary));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('rotating across 600 keeps the open deck', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(400, 900),
      devicePixelRatio: 1,
    );
    await _tap(tester, find.text('Korean'));

    tester.view.physicalSize = const Size(900, 500);
    await tester.pumpAndSettle();

    expect(find.byType(MxNavRail), findsOneWidget);
    expect(_barTitle('Korean'), findsOneWidget);

    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomNav), findsOneWidget);
    expect(_barTitle('Korean'), findsOneWidget);
  });

  libraryTest('the branch is measured without the rail: its width and no '
      'start inset twice', (tester, env) async {
    tester.view.padding = const FakeViewPadding(left: 32);
    addTearDown(tester.view.resetPadding);
    await pumpMemoxApp(
      tester,
      env,
      physicalSize: const Size(1280, 800),
      devicePixelRatio: 1,
    );

    final rail = tester.getRect(find.byType(MxNavRail));
    expect(rail.width, 80 + 32);
    // Full height, destinations from the top (spec §3).
    expect((rail.top, rail.height), (0, 800));
    expect(tester.getTopLeft(_railItem(_en.navLibrary)).dy, lessThan(100));
    final branch = tester.element(find.byType(MxAppShell).last);
    expect(MediaQuery.paddingOf(branch).left, 0);
    expect(MediaQuery.sizeOf(branch).width, 1280 - 80 - 32);
  });
}
