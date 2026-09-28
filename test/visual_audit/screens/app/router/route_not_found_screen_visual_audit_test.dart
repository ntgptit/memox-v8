import 'package:memox/app/router/route_not_found_screen.dart';

import '../../../../support/library_harness.dart';
import '../../../screen_audit.dart';

void main() {
  libraryTest('not found (IT-NAV-005)', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: RouteNotFoundScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const RouteNotFoundScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
