import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 09 (Card edit) whose detail file cites no
// executed test: loadError.

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

/// The first read of a card fails the first way a real database can; the
/// next ones are [_cards]'.
final class _FlakyCards implements CardRepository {
  _FlakyCards(this._cards);

  final CardRepository _cards;
  var reads = 0;

  @override
  Stream<CardDetail?> watchDetail(String cardId) {
    if (++reads == 1) {
      return Stream.error(
        const UnknownDatabaseFailure(cause: '/data/memox.sqlite'),
      );
    }
    return _cards.watchDetail(cardId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('loadError: a card that cannot be read is a full-screen error in '
      'plain words with Retry and Back; Retry loads the form', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final card = await env.cards.card(
      words.id,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final cards = _FlakyCards(env.cards);
    await pumpLibraryScreen(
      tester,
      env,
      CardEditorScreen.edit(cardId: card.id, deckContext: _context),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(cards),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.cardLoadErrorEditTitle), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorBody), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.text(_en.cardEditTitle),
      ),
      findsOneWidget,
    );
    // No form, no actions of the form while the card is unknown.
    expect(find.byType(EditableText), findsNothing);
    expect(find.widgetWithText(MxButton, _en.cardSaveChanges), findsNothing);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(cards.reads, 2);
    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text('bap'), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.cardSaveChanges), findsOneWidget);
  });
}
