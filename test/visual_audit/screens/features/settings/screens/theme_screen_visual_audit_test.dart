import 'package:memox/features/settings/presentation/screens/theme_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 25', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: ThemeScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const ThemeScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
