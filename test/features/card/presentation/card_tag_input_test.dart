import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// Screens 08/09's tag input: Add beside the field, and Save adds what is
// typed there (critique 2026-09-30 part 3d-2, E8).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, … ; the tag input, once opened, is the last field.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder get _tagField => find.byType(EditableText).last;

Finder _button(String label) => find.widgetWithText(MxButton, label);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

Future<List<String>> _tagsOf(LibraryEnv env, String front) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT t.name AS name FROM card_tags ct '
            'JOIN tags t ON t.id = ct.tag_id '
            'JOIN card c ON c.id = ct.card_id WHERE c.front = ? '
            'ORDER BY t.name',
            variables: [Variable<String>(front)],
          )
          .get())
    row.read<String>('name'),
];

Future<void> _openTag(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(_en.cardAddTag));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.cardAddTag));
  await tester.pump();
  await tester.enterText(_tagField, name);
  await tester.pump();
}

void main() {
  libraryTest('Add adds the typed tag and keeps the field open', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await _openTag(tester, 'food');
    expect(
      tester.widget<MxButton>(_button(_en.cardTagConfirm)).onPressed,
      isNotNull,
    );

    await tester.tap(_button(_en.cardTagConfirm));
    await tester.pump();

    expect(find.text('food'), findsOneWidget);
    expect(tester.widget<EditableText>(_tagField).controller.text, isEmpty);
    expect(
      tester.widget<MxButton>(_button(_en.cardTagConfirm)).onPressed,
      isNull,
    );
  });

  libraryTest('edit: Save keeps the tag still in the field', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'food');

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
  });

  libraryTest('an invalid tag in the field stops Save and says why', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice'),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'x' * 51);

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.cardRejection(CardRejection.invalidTagName)),
      findsOneWidget,
    );
    expect(await _tagsOf(env, 'bap'), isEmpty);
    expect(find.byType(CardEditorScreen), findsOneWidget);
  });

  libraryTest('a name already on the card, typed again, saves once '
      '(Review Focus 1)', (tester, env) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await _openTag(tester, 'FOOD');

    await tester.tap(_button(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
  });

  libraryTest('create: Save adds the pending tag, and the next card starts '
      'with none and an empty field (Review Focus 2)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await _openTag(tester, 'food');

    await tester.tap(_button(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _tagsOf(env, 'bap'), ['food']);
    expect(find.text('food'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(EditableText),
        matching: find.text('food'),
      ),
      findsNothing,
    );
  });

  libraryTest('create: a refused tag stops Save and takes the focus, so its '
      'error is in view (final review)', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await _openTag(tester, 'x' * 51);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(_button(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.cardRejection(CardRejection.invalidTagName)),
      findsOneWidget,
    );
    expect(tester.widget<EditableText>(_tagField).focusNode.hasFocus, isTrue);
    expect(await _tagsOf(env, 'bap'), isEmpty);
  });
}
