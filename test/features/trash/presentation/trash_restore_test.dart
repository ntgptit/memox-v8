import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _inSheet(String text) => find.descendant(
  of: find.byType(MxDeckPickerSheet),
  matching: find.text(text),
);

Future<void> _openRestore(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip(_en.trashEntryActions(name)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.trashRestore));
  await tester.pumpAndSettle();
}

Future<bool> _isActive(LibraryEnv env, String table, String id) async =>
    (await env.db
            .customSelect(
              'SELECT delete_batch_id IS NULL AS active FROM $table WHERE id = ?',
              variables: [Variable<String>(id)],
            )
            .getSingle())
        .read<bool>('active');

void main() {
  libraryTest('a card goes back into a deck the person picks (UC-TRASH-001 '
      'steps 5-7)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');

    expect(find.text(_en.trashRestoreOneTitle('meokda · eat')), findsOneWidget);
    expect(find.text(_en.trashRestoreCardsRule), findsOneWidget);
    // Places is in the Trash and Korean holds decks: Words alone.
    expect(
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.byType(MxListRow),
      ),
      findsOneWidget,
    );
    await tester.tap(_inSheet('Korean › Words'));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.trashRestoredOne('meokda · eat', 'Words')),
      findsOneWidget,
    );
    expect(find.text('meokda · eat'), findsNothing);
    expect(await _isActive(env, 'card', 'meokda'), isTrue);
  });

  libraryTest('a top-level deck goes back to the top level, which the person '
      'still confirms (BR-TRASH-006)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'Basics');

    expect(find.text(_en.trashRestoreRootsRule), findsOneWidget);
    await tester.tap(_inSheet(_en.trashTopLevel));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.trashRestoredOne('Basics', _en.trashTopLevel)),
      findsOneWidget,
    );
    expect(find.text('Basics'), findsNothing);
  });

  libraryTest('a sub-deck goes under a deck that could take it by a move', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'Places');

    expect(find.text(_en.trashRestoreDecksRule), findsOneWidget);
    await tester.tap(_inSheet('Korean'));
    await tester.pumpAndSettle();

    expect(find.text(_en.trashRestoredOne('Places', 'Korean')), findsOneWidget);
    expect(await _isActive(env, 'deck', seed.places), isTrue);
  });

  libraryTest('with nowhere to go, the sheet says why and offers OK (E1)', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');

    expect(find.text(_en.trashRestoreEmptyTitle), findsOneWidget);
    expect(
      find.text(_en.trashRestoreNoCardTargetBody('Korean')),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.commonOk));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(await _isActive(env, 'card', 'meokda'), isFalse);
  });

  libraryTest('the targets follow the store while the sheet is open (E2)', (
    tester,
    env,
  ) async {
    final seed = await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _openRestore(tester, 'meokda · eat');
    expect(_inSheet('Korean › Words'), findsOneWidget);

    await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
    await tester.pumpAndSettle();
    expect(_inSheet('Korean › Words'), findsNothing);
    expect(find.text(_en.trashRestoreEmptyTitle), findsOneWidget);
  });
}
