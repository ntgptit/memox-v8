import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final enL10n = lookupAppLocalizations(const Locale('en'));

Widget bulkSection(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong (new1), gamsa (due1), mul (flag1, flagged);
/// Korean › Verbs: gada (verb1).
Future<({String words, String verbs})> seedBulkCards(LibraryEnv env) async {
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

Future<int> countRows(
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

Future<int> countActiveCards(LibraryEnv env) => countRows(
  env,
  'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
);

Future<void> selectCards(WidgetTester tester, List<String> fronts) async {
  await tester.longPress(find.text(fronts.first));
  await tester.pumpAndSettle();
  for (final front in fronts.skip(1)) {
    await tester.tap(find.text(front));
    await tester.pump();
  }
}

Future<void> tapBulk(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));
