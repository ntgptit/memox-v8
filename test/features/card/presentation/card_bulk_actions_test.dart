import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong (new1), gamsa (due1), mul (flag1, flagged);
/// Korean › Verbs: gada (verb1).
Future<({String words, String verbs})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final verbs = await env.decks.sub(korean.id, 'Verbs');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(env.db, id: 'due1', deckId: words.id, front: 'gamsa');
  await insertCard(
    env.db,
    id: 'flag1',
    deckId: words.id,
    front: 'mul',
    isFlagged: true,
  );
  await insertCard(env.db, id: 'verb1', deckId: verbs.id, front: 'gada');
  return (words: words.id, verbs: verbs.id);
}

Future<int> _count(
  LibraryEnv env,
  String sql, [
  List<String> args = const [],
]) async =>
    (await env.db
            .customSelect(
              sql,
              variables: [for (final arg in args) Variable<String>(arg)],
            )
            .getSingle())
        .read<int>('n');

Future<int> _activeCount(LibraryEnv env) =>
    _count(env, 'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL');

Future<void> _select(WidgetTester tester, List<String> fronts) async {
  await tester.longPress(find.text(fronts.first));
  await tester.pumpAndSettle();
  for (final front in fronts.skip(1)) {
    await tester.tap(find.text(front));
    await tester.pump();
  }
}

Future<void> _bulk(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

/// Every id was gone when the write ran: the repository writes nothing and
/// answers `notFound` (SP2a 2.19).
final class _AllGoneCards implements CardRepository {
  @override
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) async => const Rejected(CardRejection.notFound);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest(
    'Export hands the selection over and keeps it (UC-TRANSFER-002 A1)',
    (tester, env) async {
      final ids = await _seed(env);
      final exported = <Set<String>>[];
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: CardListSectionWidget(
            deckId: ids.words,
            algorithm: 'Eight boxes',
            onAddCard: () {},
            onOpenCard: (_) {},
            onExport: exported.add,
          ),
        ),
      );
      await _select(tester, ['annyeong', 'mul']);
      await _bulk(tester, _en.cardExport);

      expect(exported, [
        {'new1', 'flag1'},
      ]);
      final checked = find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      );
      expect(checked, findsNWidgets(2));
    },
  );

  libraryTest('Flag sets the flag on every selected card', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagSet);

    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      3,
    );
    expect(find.text(_en.cardFlaggedToast(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Flag when every selected card is already gone says so, writes '
      'nothing and does not throw (SP2a 2.19)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(ids.words),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(_AllGoneCards()),
        ),
      ],
    );
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagSet);

    expect(tester.takeException(), isNull);
    expect(find.text(_en.cardBulkAllGone(2)), findsOneWidget);
    expect(find.text(_en.cardFlaggedToast(2)), findsNothing);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Remove flag clears it, never toggles (P3-L4)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['mul', 'annyeong']);
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagClear);

    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      0,
    );
  });

  libraryTest('Tag adds one tag to every selected card', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 2);
    expect(find.text(_en.cardTaggedToast(2, 'greetings')), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('a blank tag stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);
    await _bulk(tester, _en.cardTag);
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
  });

  libraryTest(
    'a tag refused for one card writes nothing, keeps selection (RF2)',
    (tester, env) async {
      final ids = await _seed(env);
      final tags = TagRepositoryImpl(env.db);
      for (var i = 0; i < 10; i++) {
        await tags.attachByName(cardIds: {'new1'}, name: 'tag $i');
      }
      await pumpLibraryScreen(tester, env, _section(ids.words));
      await _select(tester, ['annyeong', 'gamsa']);
      await _bulk(tester, _en.cardTag);
      await tester.enterText(find.byType(EditableText).last, 'extra');
      await tester.tap(_inDialog(_en.cardTagConfirm));
      await tester.pumpAndSettle();

      expect(find.text(_en.cardTagLimitReached(1)), findsOneWidget);
      expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 10);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is MxSelectionCheckbox && widget.isChecked,
        ),
        findsNWidgets(2),
      );
    },
  );

  libraryTest('Tag names how many cards are full, not only that one is '
      '(SP2a 2.21)', (tester, env) async {
    final ids = await _seed(env);
    final tags = TagRepositoryImpl(env.db);
    for (final card in ['new1', 'due1']) {
      for (var i = 0; i < 10; i++) {
        await tags.attachByName(cardIds: {card}, name: '$card tag $i');
      }
    }
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa', 'mul']);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'extra');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardTagLimitReached(2)), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 20);
  });

  libraryTest('Move sends the cards to another deck of the root', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [
        ids.verbs,
      ]),
      3,
    );
    expect(find.text(_en.cardMovedToast(2, 'Verbs')), findsOneWidget);
  });

  libraryTest('Trash asks with the count; Cancel keeps the selection; '
      'several cards get no Undo (FE-B1 D4)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardDelete);

    expect(find.text(_en.cardDeleteTitle(2)), findsOneWidget);
    expect(find.text(_en.cardDeleteNote(2)), findsOneWidget);
    await tester.tap(_inDialog(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsNWidgets(2),
    );

    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();
    expect(await _activeCount(env), 2);
    expect(find.text(_en.cardsTrashedToast(2)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsNothing);
  });

  libraryTest('one card shows its text; Undo puts it back (UC-TRASH-001 '
      'A1)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);
    await _bulk(tester, _en.cardDelete);

    expect(find.text(_en.cardDeleteTitle(1)), findsOneWidget);
    expect(_inDialog('annyeong'), findsOneWidget);
    expect(_inDialog('back'), findsOneWidget);
    expect(find.text(_en.cardDeleteNote(1)), findsOneWidget);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();
    expect(await _activeCount(env), 3);
    expect(find.text(_en.cardTrashedToast('annyeong')), findsOneWidget);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();
    expect(await _activeCount(env), 4);
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('a refused Undo says why; the card stays in the Trash '
      '(UC-TRASH-001 E3)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();
    // Meanwhile its deck goes to the Trash as well.
    await env.decks.deleteDeck(deckId: ids.words);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.cardUndoRefused(_en.cardRejectionTargetInTrash)),
      findsOneWidget,
    );
    expect(
      await _count(
        env,
        "SELECT COUNT(*) AS n FROM card WHERE id = 'new1' "
        'AND delete_batch_id IS NULL',
      ),
      0,
    );
  });

  libraryTest('Move to Trash spins while the cards move (FE-B1 D15)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.pumpAndSettle();
  });

  libraryTest('Move skips a card that went meanwhile and says so (SP2a 2.19)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardMovedToast(1, 'Verbs'), 1)),
      findsOneWidget,
    );
    expect(
      await _count(env, 'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [
        ids.verbs,
      ]),
      2,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Flag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardFlag);
    await _bulk(tester, _en.cardFlagSet);

    expect(
      find.text(_en.bulkToast(_en.cardFlaggedToast(1), 1)),
      findsOneWidget,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Tag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardTaggedToast(1, 'greetings'), 1)),
      findsOneWidget,
    );
  });

  libraryTest('Trash skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.bulkToast(_en.cardsTrashedToast(1), 1)),
      findsOneWidget,
    );
    expect(await _activeCount(env), 2);
  });

  /// Both selected cards go behind the screen's back; the action then
  /// refuses as a whole (SP2a 2.19), says how many, and prunes them.
  Future<void> selectThenLoseBoth(WidgetTester tester, LibraryEnv env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'new1', 'due1'});
    await tester.pumpAndSettle();
  }

  libraryTest('Move when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await _bulk(tester, _en.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Tag when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await _bulk(tester, _en.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(_inDialog(_en.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Trash when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardMoveToTrash));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('the bulk bar meets the target guidelines', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);

    await expectAccessibleTargets(tester);
  });
}
