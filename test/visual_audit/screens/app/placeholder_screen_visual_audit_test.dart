import 'package:memox/app/placeholder_screen.dart';

import '../../../support/library_harness.dart';
import '../../screen_audit.dart';

void main() {
  libraryTest('a tab that is not built yet', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: PlaceholderScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        PlaceholderScreen(title: 'Study', onOpenGallery: () {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
