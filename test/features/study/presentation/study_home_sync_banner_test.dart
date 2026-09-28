import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

const _rejected = '2 changes are kept only on this device.';
const _stale =
    "Some changes haven't reached the server for over a day. They're safe "
    'on this device.';

StudyHomeScreen _screen({void Function()? onOpenSync}) => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: onOpenSync ?? () {},
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

SyncStatus _waiting(LibraryEnv env, int hours) => SyncStatus(
  pendingCount: 1,
  oldestPendingAt: env.clock.now().toUtc().subtract(Duration(hours: hours)),
);

void main() {
  libraryTest('no banner without Supabase', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());
    await _settle(tester);
    expect(find.text('Details'), findsNothing);
  });

  libraryTest('no banner when nothing waits', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(const SyncStatus()),
    );
    await _settle(tester);
    expect(find.text('Details'), findsNothing);
  });

  libraryTest('refused rows show the banner; Details opens screen 27', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenSync: () => opened++),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 2)),
    );
    await _settle(tester);
    expect(find.text(_rejected), findsOneWidget);
    await tester.tap(find.text('Details'));
    expect(opened, 1);
  });

  libraryTest('a change waiting 25 h shows the stale banner', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(_waiting(env, 25)),
    );
    await _settle(tester);
    expect(find.text(_stale), findsOneWidget);
  });

  libraryTest('a change waiting 23 h shows no banner', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(_waiting(env, 23)),
    );
    await _settle(tester);
    expect(find.text(_stale), findsNothing);
  });

  libraryTest('Vietnamese at text scale 2 does not overflow', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      locale: const Locale('vi'),
      textScale: 2,
      overrides: syncOverrides(const SyncStatus(rejectedCount: 1234)),
    );
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });
}
