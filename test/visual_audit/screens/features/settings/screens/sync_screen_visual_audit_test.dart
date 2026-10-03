import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/sync_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 27', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: SyncScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        SyncScreen(onSignIn: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: syncOverrides(
          SyncStatus(
            lastSuccessAt: env.clock.now(),
            pendingCount: 3,
            rejectedCount: 2,
          ),
        ),
      ),
    );
  });
}
