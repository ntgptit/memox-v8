import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 23', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: SettingsScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        SettingsScreen(
          onOpenTheme: () {},
          onOpenLanguage: () {},
          onOpenGallery: () {},
        ),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
