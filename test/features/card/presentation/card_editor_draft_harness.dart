import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_draft_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// SP2a 2.14–2.18 (R9): the card being written survives a closed editor, a
// killed process, a refused or deleted target and a change from another
// device. The draft lives in `card_draft`, on this device only.
//
// What the draft tests share: the editor screens, its fields and the fakes.

final enL10n = lookupAppLocalizations(const Locale('en'));

/// Past the 500 ms pause that starts a draft write.
const draftPause = Duration(milliseconds: 600);

Widget deckContextHeader(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen createScreen(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: deckContextHeader);

CardEditorScreen editScreen(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: deckContextHeader);

/// Front, back, then the tag input once opened.
Finder fieldAt(int index) => find.byType(EditableText).at(index);

Finder footerSave(String label) => find.widgetWithText(MxButton, label);

String textAt(WidgetTester tester, int index) =>
    tester.widget<EditableText>(fieldAt(index)).controller.text;

CardDraftRepositoryImpl draftsOf(LibraryEnv env) =>
    CardDraftRepositoryImpl(env.db);

Future<String> seedWordsDeck(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

/// An edit that waits until the test lets it through.
final class HeldEdits implements CardRepository {
  HeldEdits(this._cards, {this.then});

  final CardRepository _cards;

  /// What the edit ends with; null lets it through to the real repository.
  final Future<Outcome<void, CardRejection>> Function()? then;
  final release = Completer<void>();

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? expectedUpdatedAt,
    DateTime? now,
  }) async {
    await release.future;
    if (then != null) return then!();
    return _cards.editCard(
      cardId: cardId,
      draft: draft,
      expectedUpdatedAt: expectedUpdatedAt,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
