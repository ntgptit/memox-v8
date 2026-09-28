import 'package:flutter_test/flutter_test.dart';
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
    final line = find.text('1 change kept only on this device');
    await tester.scrollUntilVisible(line, 200);
    await tester.tap(line);
    expect(opened, 1);
  });
}
