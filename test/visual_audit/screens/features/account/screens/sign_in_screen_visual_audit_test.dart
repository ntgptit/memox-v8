import 'package:memox/features/account/presentation/screens/sign_in_screen.dart';

import '../../../../../support/account_harness.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  accountTest('screen 30', (tester, env, world) async {
    await auditProductionScreen(
      tester,
      screen: SignInScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        SignInScreen(onCodeSent: (_) {}, onSignedIn: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: accountOverrides(world),
      ),
    );
  });
}
