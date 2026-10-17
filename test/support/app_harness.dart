import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';

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
