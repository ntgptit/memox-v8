import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

import 'card_fixtures.dart';
import 'deck_fixtures.dart';
import 'library_harness.dart';

/// The ids [seedTrash] leaves behind.
typedef TrashSeed = ({String korean, String words, String places});

/// Four Trash entries as kit 06 draws them, deleted at fixed times before
/// [libraryToday], newest first:
/// - the card "meokda · eat", 4 minutes ago, from Korean › Words;
/// - the root "Basics" (1 sub-deck, 2 cards), yesterday;
/// - "Places" (3 cards), 28 days ago, from Korean: 2 days left;
/// - the card "homework · bai tap", 719 hours ago, from Korean › Words: 1h
///   left.
Future<TrashSeed> seedTrash(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final places = await env.decks.sub(korean.id, 'Places');
  final basics = await env.decks.root('Basics');
  final greetings = await env.decks.sub(basics.id, 'Greetings');
  await insertCard(
    env.db,
    id: 'meokda',
    deckId: words.id,
    front: 'meokda',
    back: 'eat',
  );
  await insertCard(
    env.db,
    id: 'gada',
    deckId: words.id,
    front: 'gada',
    back: 'go',
  );
  await insertCard(
    env.db,
    id: 'homework',
    deckId: words.id,
    front: 'homework',
    back: 'bai tap',
  );
  for (final (index, front) in ['hello', 'thanks'].indexed) {
    await insertCard(env.db, id: 'g$index', deckId: greetings.id, front: front);
  }
  for (final (index, front) in ['school', 'market', 'station'].indexed) {
    await insertCard(env.db, id: 'p$index', deckId: places.id, front: front);
  }
  await env.cards.deleteCards(
    cardIds: {'homework'},
    now: libraryToday.subtract(trashRetention - const Duration(hours: 1)),
  );
  await env.decks.deleteDeck(
    deckId: places.id,
    now: libraryToday.subtract(const Duration(days: 28)),
  );
  await env.decks.deleteDeck(
    deckId: basics.id,
    now: libraryToday.subtract(const Duration(days: 1)),
  );
  await env.cards.deleteCards(
    cardIds: {'meokda'},
    now: libraryToday.subtract(const Duration(minutes: 4)),
  );
  return (korean: korean.id, words: words.id, places: places.id);
}
