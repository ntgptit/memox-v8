import 'package:memox/features/settings/presentation/screens/study_defaults_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 23a', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: StudyDefaultsScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const StudyDefaultsScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
