import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';

import '../../../../../support/account_harness.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  accountTest('screen 31', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await auditProductionScreen(
      tester,
      screen: CodeScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        CodeScreen(email: 'a@example.com', onSignedIn: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: accountOverrides(world),
      ),
    );
  });
}
