import 'package:memox/features/settings/presentation/screens/language_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 26', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: LanguageScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const LanguageScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
