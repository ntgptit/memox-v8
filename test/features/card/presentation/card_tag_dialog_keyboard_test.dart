import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/add_tag_to_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _maxTagLength = 50;

/// Opens the dialog for two cards and records what it completes with.
Widget _host(Set<String> cardIds, List<bool> results) => Scaffold(
  body: Builder(
    builder: (context) => MxButton(
      label: 'Open',
      onPressed: () async =>
          results.add(await showCardTagDialog(context, cardIds: cardIds)),
    ),
  ),
);

Future<Set<String>> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'due1', deckId: words.id, front: 'gamsa');
  return {'new1', 'due1'};
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<int> _links(LibraryEnv env) async =>
    (await env.db
            .customSelect('SELECT COUNT(*) AS n FROM card_tags')
            .getSingle())
        .read<int>('n');

Future<List<String>> _tagNames(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT name FROM tags WHERE name = ?',
            variables: [const Variable<String>('greetings')],
          )
          .get())
    row.read<String>('name'),
];

// The tag field declares the Done action (card_tag_dialog_widget.dart): the
// keyboard does what the Tag button does.
void main() {
  late List<bool> results;

  setUp(() => results = []);

  libraryTest('the keyboard Done tags every card, says so and completes true', (
    tester,
    env,
  ) async {
    final cardIds = await _seed(env);
    await pumpLibraryScreen(tester, env, _host(cardIds, results));
    await _open(tester);

    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(await _links(env), 2);
    expect(await _tagNames(env), ['greetings']);
    expect(find.text(_en.cardTaggedToast(2, 'greetings')), findsOneWidget);
    expect(results, [true]);
  });

  libraryTest('the keyboard Done on an empty name stays in the dialog with the '
      'reason under the field, as the button does', (tester, env) async {
    final cardIds = await _seed(env);
    await pumpLibraryScreen(tester, env, _host(cardIds, results));
    await _open(tester);

    await tester.enterText(find.byType(EditableText).last, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
    expect(await _links(env), 0);
    expect(results, isEmpty);
  });

  libraryTest('the keyboard Done on a name over the limit stays in the dialog '
      'with the reason under the field', (tester, env) async {
    final cardIds = await _seed(env);
    await pumpLibraryScreen(tester, env, _host(cardIds, results));
    await _open(tester);

    await tester.enterText(
      find.byType(EditableText).last,
      'a' * (_maxTagLength + 1),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagRejectionNameTooLong), findsOneWidget);
    expect(await _links(env), 0);
    expect(results, isEmpty);
  });

  libraryTest('the keyboard Done while the tag is written does not write '
      'twice, and the dialog is held until it lands', (tester, env) async {
    final cardIds = await _seed(env);
    final gate = Completer<void>();
    final controller = _CountingTag(gate);
    await pumpLibraryScreen(
      tester,
      env,
      _host(cardIds, results),
      overrides: [cardActionsControllerProvider.overrideWith(() => controller)],
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText).last, 'greetings');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.writes, 1);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isTrue);

    gate.complete();
    await tester.pumpAndSettle();

    expect(controller.writes, 1);
    expect(find.byType(MxDialog), findsNothing);
    expect(await _links(env), 2);
    expect(results, [true]);
  });
}

/// Counts the tag writes that reach the use case, and holds each until
/// [gate] opens.
final class _CountingTag extends CardActionsController {
  _CountingTag(this.gate);

  final Completer<void> gate;
  var writes = 0;

  @override
  Future<Outcome<void, TagRejection>> addTag({
    required Set<String> cardIds,
    required String tagName,
  }) async {
    writes++;
    // Read before the wait, as the real call does: nothing keeps this
    // controller alive across it.
    final addTag = ref.read(addTagToCardsUseCaseProvider);
    await gate.future;
    return addTag(cardIds: cardIds, tagName: tagName);
  }
}
