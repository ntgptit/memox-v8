import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/presentation/providers/edit_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened; the optional fields sit
/// between them once "Add details" is open.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

final class _FailingCards implements CardRepository {
  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Cards whose edit waits until the test lets it land.
final class _HeldEdits implements CardRepository {
  final release = Completer<Outcome<void, CardRejection>>();

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) => release.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MxIconButton _iconButton(WidgetTester tester, String label) =>
    tester.widget<MxIconButton>(
      find.byWidgetPredicate(
        (widget) => widget is MxIconButton && widget.semanticLabel == label,
      ),
    );

void main() {
  libraryTest('edit: while the save runs, Back, Cancel and the flag are off, '
      'not dead taps (closing audit 2026-10-17)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    final cards = _HeldEdits();
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(EditCardUseCase(cards)),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pump();

    expect(_iconButton(tester, _en.commonBack).onPressed, isNull);
    expect(_iconButton(tester, _en.cardFlagLabel).onPressed, isNull);
    expect(
      tester.widget<MxButton>(_footerSave(_en.commonCancel)).onPressed,
      isNull,
    );

    cards.release.complete(const Ok(null));
    await tester.pumpAndSettle();
  });

  libraryTest('edit: a failed save names the changes, not the card, and the '
      'body names the button as it reads (audit 2026-10-17)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(
      tester,
      env,
      _edit(card.id),
      overrides: [
        editCardUseCaseProvider.overrideWithValue(
          EditCardUseCase(_FailingCards()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSaveChangesFailedTitle), findsOneWidget);
    expect(find.text(_en.cardSaveFailedBody), findsOneWidget);
    expect(_en.cardSaveFailedBody, contains(_en.cardRetrySave));
    expect(_footerSave(_en.cardRetrySave), findsOneWidget);
  });
}
