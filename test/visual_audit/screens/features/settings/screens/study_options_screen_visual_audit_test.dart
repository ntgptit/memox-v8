import 'package:flutter/widgets.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 15', (tester, env) async {
    final root = await env.decks.root('Korean TOPIK I');
    final sub = await env.decks.sub(root.id, 'Từ vựng');
    await auditProductionScreen(
      tester,
      screen: StudyOptionsScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        StudyOptionsScreen(deckId: sub.id, breadcrumb: const SizedBox.shrink()),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
