import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

SettingsScreen _screen({void Function()? onOpenSync}) => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  onAppOptionsReset: () {},
  onOpenSync: onOpenSync ?? () {},
);

void main() {
  libraryTest('no Sync section without Supabase', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);
    expect(find.text('Sync'), findsNothing);
  });

  libraryTest('the Sync row names the state and opens screen 27', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenSync: () => opened++),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 1)),
    );
    final line = find.text("1 change wasn't accepted");
    await tester.scrollUntilVisible(line, 200);
    await tester.tap(line);
    expect(opened, 1);
  });

  libraryTest('the Sync row hides when the status stream fails (spec §6)', (
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
    statuses.add(const SyncStatus(rejectedCount: 1));
    await tester.pump();
    final line = find.text("1 change wasn't accepted");
    await tester.scrollUntilVisible(line, 200);
    expect(line, findsOneWidget);

    statuses.addError(StateError('database closed'));
    await tester.pump();
    expect(line, findsNothing);
  });
}
