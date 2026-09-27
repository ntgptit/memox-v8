import 'package:flutter/widgets.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/progress_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 22 inside a deck, ${locale.languageCode}', (
      tester,
      env,
    ) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      await studiedSubDeck(
        env,
        root.id,
        root.id,
        'Động từ',
        days: [(daysAgo: 0, learning: 2, reviewing: 6)],
      );
      await studiedSubDeck(env, root.id, root.id, 'Tính từ');
      await auditProductionScreen(
        tester,
        screen: DeckProgressScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          DeckProgressScreen(
            deckId: root.id,
            onOpenDeck: (_) {},
            onOpenAncestor: (_) {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
        ),
      );
    });
  }
}
