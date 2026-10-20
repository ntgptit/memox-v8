import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_decks_widget.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/term_line.dart';

StudyHomeScreen _screen() => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // Plan Review Focus 2: on a 360 dp phone at a 1.3 text scale the rows'
  // counts wrap between whole terms with no dot at a line edge.
  libraryTest('at a 1.3 text scale a row\'s counts keep the Wrap Rule '
      '(spec W1)', (tester, env) async {
    final root = await env.decks.root('Kanji N5 Vocabulary');
    final leaf = await env.decks.sub(root.id, 'Leaf');
    for (final (id, dueAt) in [
      ('late', DateTime(2026, 9, 20)),
      ('now', DateTime(2026, 9, 24, 8)),
      ('new', null),
    ]) {
      await insertCard(
        env.db,
        id: id,
        deckId: leaf.id,
        learnedAt: dueAt == null ? null : DateTime(2026, 9, 1),
        dueAt: dueAt,
        box: 2,
      );
    }
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(), textScale: 1.3);
    await _settle(tester);

    final lines = find.descendant(
      of: find.byType(StudyHomeDecksWidget),
      matching: find.byType(MxTermLine),
    );
    expect(lines, findsWidgets);
    for (final element in lines.evaluate()) {
      expectTermLineRule(tester, find.byWidget(element.widget));
    }
  });
}
