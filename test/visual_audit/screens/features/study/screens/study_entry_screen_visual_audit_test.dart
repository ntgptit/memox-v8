import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/study_fixtures.dart';
import '../../../../screen_audit.dart';

StudyEntryScreen _entry(String deckId) => StudyEntryScreen(
  deckId: deckId,
  deckContext: (id, label) =>
      DeckContextHeaderWidget(deckId: id, currentLabel: label),
  onBackToLibrary: () {},
  onSessionReady: (_) {},
);

Future<void> _audit(WidgetTester tester, LibraryEnv env, String deckId) =>
    auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        _entry(deckId),
        brightness: brightness,
        textScale: scale,
      ),
    );

void main() {
  libraryTest('screen 14, cards to study, sessions coming soon', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await _audit(tester, env, leaf.id);
  });

  libraryTest('screen 14, nothing to do', (tester, env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(
      env.db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await _audit(tester, env, leaf.id);
  });

  libraryTest("screen 14, today's session to continue", (tester, env) async {
    final ids = await seedBrowseSession(
      env.db,
      env.decks,
      startedAt: libraryToday,
    );
    await _audit(tester, env, ids.deckId);
  });
}
