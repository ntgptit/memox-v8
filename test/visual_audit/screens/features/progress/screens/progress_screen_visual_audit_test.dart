import 'package:flutter/widgets.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/progress_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 22, ${locale.languageCode}', (tester, env) async {
      // The held streak: its note is the longest overview.
      await progressLibrary(env, today: false);
      await auditProductionScreen(
        tester,
        screen: ProgressScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
        ),
      );
    });
  }
}
