import 'package:memox/features/trash/presentation/screens/trash_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/trash_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 06, the list', (tester, env) async {
    await seedTrash(env);
    await auditProductionScreen(
      tester,
      screen: TrashScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
