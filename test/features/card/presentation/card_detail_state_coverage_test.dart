import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 10 (Card detail) whose detail file cites no
// executed test: historyError.

final _en = lookupAppLocalizations(const Locale('en'));

CardDetailScreen _screen(String cardId) => CardDetailScreen(
  cardId: cardId,
  deckContext: (deckId, label) =>
      DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
  onEdit: (_) {},
);

/// The first page of the history fails the first way a real database can;
/// the next reads are [_cards]'.
final class _FlakyFirstPage implements CardRepository {
  _FlakyFirstPage(this._cards);

  final CardRepository _cards;
  var reads = 0;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    if (++reads == 1) {
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('historyError: a first history page that fails is an error in '
      'plain words with Retry, under the content; Retry shows the history', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final card = await env.cards.card(
      words.id,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await logReview(
      env.db,
      id: 'r0',
      cardId: card.id,
      at: DateTime(2026, 9, 1),
    );
    final history = _FlakyFirstPage(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(card.id),
      overrides: [
        loadCardHistoryPageUseCaseProvider.overrideWithValue(
          LoadCardHistoryPageUseCase(history),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.cardHistoryLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorBody), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
    expect(find.byType(CardHistoryEventWidget), findsNothing);
    // The content stays above the error.
    expect(find.text('bap'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(MxErrorState)).dy,
      greaterThan(tester.getTopLeft(find.text('bap')).dy),
    );

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(history.reads, 2);
    expect(find.byType(MxErrorState), findsNothing);
    expect(find.byType(CardHistoryEventWidget), findsOneWidget);
  });
}
