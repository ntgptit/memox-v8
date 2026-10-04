import 'package:memox/features/account/presentation/screens/welcome_screen.dart';

import '../../../../../support/account_harness.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  accountTest('screen 29', (tester, env, world) async {
    await auditProductionScreen(
      tester,
      screen: WelcomeScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        WelcomeScreen(onDone: () {}, onEmail: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: accountOverrides(world),
      ),
    );
  });
}
