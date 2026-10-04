import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/watch_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

/// Korean › Words (cards w1, w2) and Korean › Verbs (card v1); w1 and w2
/// go to the Trash one by one, then Verbs.
Future<({String words, String verbs})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final verbs = await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'w1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'w2', deckId: words.id, front: 'gamsa');
  await insertCard(env.db, id: 'v1', deckId: verbs.id, front: 'gada');
  await env.cards.deleteCards(cardIds: {'w1'}, now: libraryToday);
  await env.cards.deleteCards(cardIds: {'w2'}, now: libraryToday);
  await env.decks.deleteDeck(deckId: verbs.id, now: libraryToday);
  return (words: words.id, verbs: verbs.id);
}

/// What the store holds now: a fresh read of the Trash's stream.
Future<List<TrashEntry>> _entries(ProviderContainer container) =>
    container.read(watchTrashUseCaseProvider)().first;

/// A container over [env] whose auto-disposed controller stays alive.
ProviderContainer _container(LibraryEnv env) {
  final container = libraryContainer(env);
  container.listen(trashControllerProvider, (_, _) {});
  return container;
}

TrashEntry _named(List<TrashEntry> entries, String name) => entries.firstWhere(
  (entry) => switch (entry) {
    TrashCardEntry(:final front) => front == name,
    TrashDeckEntry(name: final deckName) => deckName == name,
  },
);

/// A plain test over a fresh [LibraryEnv]: drift's streams need the real
/// event loop, which a widget test's fake clock does not run.
void _trashTest(
  String description,
  Future<void> Function(LibraryEnv env) body,
) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(env);
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _trashTest('a selection is locked to the kind picked first (BR-TRASH-011)', (
    env,
  ) async {
    await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    trash.toggle(_named(entries, 'annyeong'), entries);
    trash.toggle(_named(entries, 'Verbs'), entries);
    trash.toggle(_named(entries, 'gamsa'), entries);
    var state = container.read(trashControllerProvider);
    expect(state.isSelecting, isTrue);
    expect(state.selected, hasLength(2));
    expect(state.kindIn(entries), TrashKind.card);

    // Emptied, the lock goes: a deck may be picked now.
    trash.toggle(_named(entries, 'annyeong'), entries);
    trash.toggle(_named(entries, 'gamsa'), entries);
    trash.toggle(_named(entries, 'Verbs'), entries);
    state = container.read(trashControllerProvider);
    expect(state.kindIn(entries), TrashKind.deck);
    expect(state.selected, {_named(entries, 'Verbs').batchId});
  });

  _trashTest('the filter keeps its kind; Select starts with nothing chosen', (
    env,
  ) async {
    await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    trash.chooseFilter(TrashFilter.decks);
    trash.startSelecting();
    final state = container.read(trashControllerProvider);
    expect(state.filter, TrashFilter.decks);
    expect(state.isSelecting, isTrue);
    expect(state.selected, isEmpty);
    expect(entries.where(TrashFilter.decks.accepts), hasLength(1));
    expect(entries.where(TrashFilter.cards.accepts), hasLength(2));
  });

  _trashTest('a restore lands and ends the selection; a refusal keeps it', (
    env,
  ) async {
    final ids = await _seed(env);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    var entries = await _entries(container);
    final annyeong = _named(entries, 'annyeong');
    trash.toggle(annyeong, entries);

    // The Verbs deck is in the Trash: no card goes there.
    final refused = await trash.restoreCards(
      batchIds: {annyeong.batchId},
      deckId: ids.verbs,
    );
    expect(
      refused,
      isA<Rejected<void, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.targetInTrash,
      ),
    );
    expect(container.read(trashControllerProvider).selected, hasLength(1));

    final restored = await trash.restoreCards(
      batchIds: {annyeong.batchId},
      deckId: ids.words,
    );
    expect(restored, isA<Ok<void, CardRejection>>());
    expect(container.read(trashControllerProvider).isSelecting, isFalse);
    entries = await _entries(container);
    expect(entries, hasLength(2));
  });

  _trashTest('a deck of a root goes back to the top level', (env) async {
    final japanese = await env.decks.root('Japanese');
    await env.decks.deleteDeck(deckId: japanese.id);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);

    final outcome = await trash.restoreDecks(
      batchIds: {entries.single.batchId},
      parentId: null,
    );
    expect(outcome, isA<Ok<void, DeckRejection>>());
    expect(await _entries(container), isEmpty);
  });

  _trashTest('a purge ends the selection and keeps what the store skips '
      '(spec D6)', (env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'w1', deckId: words.id, front: 'annyeong');
    // The card goes first, then its deck: the deck holds an older entry.
    await env.cards.deleteCards(cardIds: {'w1'});
    await env.decks.deleteDeck(deckId: words.id);
    final container = _container(env);
    final trash = container.read(trashControllerProvider.notifier);
    final entries = await _entries(container);
    final deck = _named(entries, 'Words');
    trash.toggle(deck, entries);

    final report = await trash.purge({deck.batchId});
    final state = container.read(trashControllerProvider);
    expect(report.purged, isEmpty);
    expect(state.isSelecting, isFalse);
    expect(state.blocked.keys, [deck.batchId]);
    expect(state.blocked[deck.batchId], {_named(entries, 'annyeong').batchId});

    // The next command lets the note go.
    trash.chooseFilter(TrashFilter.cards);
    expect(container.read(trashControllerProvider).blocked, isEmpty);
  });

  _trashTest('purgeExpired takes only what is past 30 days (UC-TRASH-001 '
      'A4)', (env) async {
    await _seed(env);
    final kanji = await env.decks.root('Kanji');
    await env.decks.deleteDeck(
      deckId: kanji.id,
      now: libraryToday.add(const Duration(days: 1)),
    );
    // The seeded batches reach 720 hours: the boundary is expired.
    env.clock.current = libraryToday.add(trashRetention);
    final container = _container(env);

    await container.read(trashControllerProvider.notifier).purgeExpired();
    final entries = await _entries(container);
    expect(entries, hasLength(1));
    expect(_named(entries, 'Kanji'), isA<TrashDeckEntry>());
  });
}
