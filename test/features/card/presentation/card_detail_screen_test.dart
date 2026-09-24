import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

CardDetailScreen _screen(String cardId, {ValueChanged<String>? onEdit}) =>
    CardDetailScreen(
      cardId: cardId,
      deckContext: (deckId, label) =>
          DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
      onEdit: onEdit ?? (_) {},
    );

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

/// A read that fails the first way a real database can.
final class _BrokenCards implements CardRepository {
  @override
  Stream<CardDetail?> watchDetail(String cardId) =>
      Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('the detail shows the card under its path; Edit asks for it', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(
      await _words(env),
      const CardDraft(front: 'bap', back: 'rice'),
    );
    final edits = <String>[];
    await pumpLibraryScreen(tester, env, _screen(card.id, onEdit: edits.add));
    await tester.pumpAndSettle();

    expect(_barTitle(_en.cardDetailTitle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text('Words'),
      ),
      findsOneWidget,
    );
    expect(find.text('bap'), findsOneWidget);
    expect(find.text(_en.cardScheduleBox(1, 8).toUpperCase()), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.cardEditAction));
    expect(edits, [card.id]);
  });

  libraryTest('a card deleted while open shows it is gone (E2)', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(await _words(env));
    await pumpLibraryScreen(tester, env, _screen(card.id));
    await tester.pumpAndSettle();
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pumpAndSettle();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.text(_en.cardDetailGoneBody), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.cardEditAction), findsNothing);
  });

  libraryTest('a link to a card that does not exist shows it is gone (E1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen('missing'));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.textContaining('missing'), findsNothing);
  });

  libraryTest('a failed read offers Retry and hides the cause (E3)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen('c'),
      overrides: [
        watchCardDetailUseCaseProvider.overrideWithValue(
          WatchCardDetailUseCase(_BrokenCards()),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(_en.cardLoadErrorEditTitle), findsOneWidget);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('the detail holds Vietnamese at 2x and meets the guidelines', (
    tester,
    env,
  ) async {
    final card = await env.cards.card(
      await _words(env),
      const CardDraft(
        front: 'Tiếng Việt có dấu, một thuật ngữ khá dài',
        back: 'nghĩa',
      ),
    );
    await pumpLibraryScreen(tester, env, _screen(card.id), textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
