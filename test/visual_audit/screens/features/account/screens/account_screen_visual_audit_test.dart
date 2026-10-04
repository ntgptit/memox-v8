import 'package:memox/features/account/presentation/screens/account_screen.dart';

import '../../../../../support/account_harness.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  accountTest('screen 32', (tester, env, world) async {
    await linkEmail(world);
    await auditProductionScreen(
      tester,
      screen: AccountScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        AccountScreen(onSignInAgain: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: accountOverrides(world),
      ),
    );
  });
}
