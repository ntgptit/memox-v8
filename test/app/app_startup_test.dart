import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app_startup.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/study_fixtures.dart';

// Spec D9: main() runs the startup tasks before runApp, so a session left
// in_progress from an earlier day is never offered as resumable (Review
// Focus 5). started_at is a date this test is always well past, so the
// repository's default `now` needs no fake clock.

void main() {
  libraryTest('the startup tasks close an in_progress session from an '
      'earlier day as interrupted (spec D9, BR-STUDY-072)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'c1', deckId: leaf.id);
    await insertSession(
      env.db,
      id: 's',
      deckId: leaf.id,
      rootId: root.id,
      startedAt: DateTime(2026, 1, 2, 20),
    );

    await runStartupTasks(libraryContainer(env));

    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'abandoned');
    expect(row.read<String?>('end_reason'), 'interrupted');
  });
}
