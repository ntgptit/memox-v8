import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: DeckStudyHeaderWidget(deckId: deckId, part: DeckStudyHeaderPart.title),
  breadcrumb: DeckStudyHeaderWidget(
    deckId: deckId,
    part: DeckStudyHeaderPart.breadcrumb,
  ),
  onOpenSession: (_) {},
);

void main() {
  libraryTest('screen 14, new and due cards on Eight boxes', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'n1', deckId: leaf.id);
    for (final id in ['a', 'b', 'c']) {
      await insertCard(
        env.db,
        id: id,
        deckId: leaf.id,
        back: 'meaning $id',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
        box: 2,
      );
    }
    await lockScheduler(env.db, root.id);
    await auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        _screen(leaf.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 14, nothing due', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'later',
      deckId: root.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 10, 1),
      box: 2,
    );
    await lockScheduler(env.db, root.id);
    await auditProductionScreen(
      tester,
      screen: StudyEntryScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        _screen(root.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
