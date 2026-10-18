import '../../../../support/card_fixtures.dart';
import '../../../../support/deck_fixtures.dart';
import '../../../../support/library_harness.dart';

/// Korean › Words: annyeong (new) and gamsa (due, "thanks"); its id.
Future<String> seedAnnyeongGamsa(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(
    env.db,
    id: 'due1',
    deckId: words.id,
    front: 'gamsa',
    back: 'thanks',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  return words.id;
}
