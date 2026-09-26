import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

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

      expect(find.text(_en.tagRejectionTooManyTags), findsOneWidget);
      expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 10);
      expect(find.text(_en.cardSelectedOf(2, 3).toUpperCase()), findsOneWidget);
    },
  );

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

  libraryTest('Delete asks with the count; Cancel keeps the selection', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong', 'gamsa']);
    await _bulk(tester, _en.cardDelete);

    expect(find.text(_en.cardDeleteTitle(2)), findsOneWidget);
    await tester.tap(_inDialog(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardSelectedOf(2, 3).toUpperCase()), findsOneWidget);

    await _bulk(tester, _en.cardDelete);
    await tester.tap(_inDialog(_en.cardDelete));
    await tester.pumpAndSettle();
    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
      ),
      2,
    );
    expect(find.text(_en.cardDeletedToast(2)), findsOneWidget);
  });

  libraryTest('the bulk bar meets the target guidelines', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(ids.words));
    await _select(tester, ['annyeong']);

    await expectAccessibleTargets(tester);
  });
}
