import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/delete_cards_use_case.dart';
import 'package:memox/features/card/presentation/providers/delete_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Counts the deletes that reach the store; everything else is unused.
final class _CountingDecks implements DeckRepository {
  _CountingDecks(this._inner);

  final DeckRepository _inner;
  var deletes = 0;

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) {
    deletes++;
    return _inner.deleteDeck(deckId: deckId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _CountingCards implements CardRepository {
  _CountingCards(this._inner);

  final CardRepository _inner;
  var deletes = 0;

  @override
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) {
    deletes++;
    return _inner.deleteCards(cardIds: cardIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder _confirm(String label) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(label));

/// Two taps on Move to Trash in one frame, before the busy confirm is
/// drawn, move once (FE-B1 D15; final review).
void main() {
  libraryTest('a double tap on a deck’s Move to Trash deletes once', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    final decks = _CountingDecks(env.decks);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id),
      overrides: [
        deleteDeckUseCaseProvider.overrideWithValue(DeleteDeckUseCase(decks)),
      ],
    );
    await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    await tester.tap(_confirm(_en.deckDelete));
    await tester.tap(_confirm(_en.deckDelete));
    await tester.pumpAndSettle();
    expect(decks.deletes, 1);
  });

  libraryTest('a double tap on the cards’ Move to Trash deletes once', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'c1', deckId: words.id, front: 'annyeong');
    final cards = _CountingCards(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(
          deckId: words.id,
          algorithm: 'Eight boxes',
          onAddCard: () {},
          onOpenCard: (_) {},
        ),
      ),
      overrides: [
        deleteCardsUseCaseProvider.overrideWithValue(DeleteCardsUseCase(cards)),
      ],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardDelete));
    await tester.pumpAndSettle();

    await tester.tap(_confirm(_en.cardMoveToTrash));
    await tester.tap(_confirm(_en.cardMoveToTrash));
    await tester.pumpAndSettle();
    expect(cards.deletes, 1);
  });
}
