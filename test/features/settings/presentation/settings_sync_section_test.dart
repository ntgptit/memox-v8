import 'dart:async';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

SettingsScreen _screen({void Function()? onOpenSync}) => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  resetAppOptions: () async => const Ok(null),
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

  Finder syncTile() => find.ancestor(
    of: find.byIcon(AppIcons.sync),
    matching: find.byType(MxIconTile),
  );

  libraryTest('the Sync tile is success once sync is settled (critique '
      '2026-09-30 tone pass, T4)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(SyncStatus(lastSuccessAt: env.clock.now())),
    );
    await tester.scrollUntilVisible(syncTile(), 200);
    expect(tester.widget<MxIconTile>(syncTile()).tone, MxIconTileTone.success);
  });

  Future<MxIconTileTone> toneFor(
    WidgetTester tester,
    LibraryEnv env,
    SyncStatus status,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(status),
    );
    await tester.scrollUntilVisible(syncTile(), 200);
    return tester.widget<MxIconTile>(syncTile()).tone;
  }

  libraryTest('the Sync tile is warning while changes were refused '
      '(critique 2026-09-30 part 3d-1, D5)', (tester, env) async {
    expect(
      await toneFor(tester, env, const SyncStatus(rejectedCount: 1)),
      MxIconTileTone.warning,
    );
  });

  libraryTest('the Sync tile is warning after a failed run (D5)', (
    tester,
    env,
  ) async {
    final failure = LastSyncFailure(SyncFailureKind.network, env.clock.now());
    expect(
      await toneFor(tester, env, SyncStatus(lastFailure: failure)),
      MxIconTileTone.warning,
    );
  });

  libraryTest('the Sync tile stays tinted while changes only wait (D5)', (
    tester,
    env,
  ) async {
    expect(
      await toneFor(tester, env, const SyncStatus(pendingCount: 2)),
      MxIconTileTone.tinted,
    );
  });
}
