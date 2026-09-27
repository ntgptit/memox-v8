import 'package:flutter/widgets.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/starter_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 03, ${locale.languageCode}', (tester, env) async {
      final library = StarterLibraryFake(env);
      // One card says "In library" and "Add another copy", the longest.
      await library.addStarterDeck(
        templateId: everydayTemplate.templateId,
        schedulerType: everydayTemplate.suggestedScheduler,
      );
      await auditProductionScreen(
        tester,
        screen: StarterLibraryScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          StarterLibraryScreen(onOpenDeck: (_) {}, onCreateDeck: () {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [library.asOverride],
        ),
      );
    });
  }
}
