import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import 'library_harness.dart';

// The whole app, router and every screen. Apart from library_harness.dart so
// that only the tests that pump the app depend on all of it: diff-based test
// selection follows imports (build_verification_plan.py).

/// The whole app over [env] on a 1080×2400 (3x) phone, or at
/// [physicalSize], settled on the Library root.
Future<void> pumpMemoxApp(
  WidgetTester tester,
  LibraryEnv env, {
  AppSettingsEntity? initialSettings,
  bool isSettled = true,
  List<Override> overrides = const [],
  Size physicalSize = const Size(1080, 2400),
  double devicePixelRatio = 3,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...libraryBackend(env), ...overrides],
      retry: noProviderRetry,
      child: MemoxApp(initialSettings: initialSettings),
    ),
  );
  if (isSettled) await tester.pumpAndSettle();
}

/// Taps [finder], then settles every frame it started.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// [title] in the app bar; the page may show the same text elsewhere.
/// [skipOffstage] false also finds the bars of the routes under the top one.
Finder barTitle(String title, {bool skipOffstage = true}) => find.descendant(
  of: find.byType(MxAppBar, skipOffstage: skipOffstage),
  matching: find.text(title, skipOffstage: skipOffstage),
  skipOffstage: skipOffstage,
);

/// A tab label inside the bottom nav; the app bar may show the same text.
Finder bottomTab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

/// The app goes to the background and comes back, through every state.
void cycleLifecycle(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}
