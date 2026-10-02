import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

const _rejected = "2 changes weren't accepted.";
const _stale = "Some changes haven't synced in over a day. They're safe here.";

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
    // A link out of a warning, not the screen's decision (critique
    // 2026-09-30 part 1).
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Details')).tone,
      MxButtonTone.outline,
    );
    expectOnePrimaryPerDecision(tester);
    await tester.tap(find.text('Details'));
    expect(opened, 1);
  });

  libraryTest("one refused row reads in the singular (critique 2026-09-30 "
      'part 3a, R3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 1)),
    );
    await _settle(tester);
    expect(find.text("1 change wasn't accepted."), findsOneWidget);
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

  libraryTest('the notice hides when the status stream fails (spec §6)', (
    tester,
    env,
  ) async {
    final statuses = StreamController<SyncStatus?>();
    addTearDown(statuses.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        syncStatusProvider.overrideWith((ref) => statuses.stream),
        ...syncOverrides(const SyncStatus()).skip(1),
      ],
    );
    statuses.add(const SyncStatus(rejectedCount: 2));
    await _settle(tester);
    expect(find.text(_rejected), findsOneWidget);

    statuses.addError(StateError('database closed'));
    await _settle(tester);
    expect(find.text(_rejected), findsNothing);
  });
}
