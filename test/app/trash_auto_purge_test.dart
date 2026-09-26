import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words with the card bap, deleted [age] before [libraryToday].
Future<void> _seedDeleted(LibraryEnv env, Duration age) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(
    env.db,
    id: 'c0',
    deckId: words.id,
    front: 'bap',
    back: 'rice',
  );
  await env.cards.deleteCards(cardIds: {'c0'}, now: libraryToday.subtract(age));
}

Future<int> _batches(LibraryEnv env) async =>
    (await env.db
            .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
            .getSingle())
        .read<int>('n');

/// The app goes to the background and comes back, through every state.
void _cycleLifecycle(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  libraryTest('the app purges what expired when it starts (FE-B1 D5)', (
    tester,
    env,
  ) async {
    await _seedDeleted(env, trashRetention + const Duration(days: 1));
    expect(await _batches(env), 1);

    await pumpMemoxApp(tester, env);
    expect(await _batches(env), 0);
  });

  libraryTest('a resume purges what expired meanwhile, and the open Trash '
      'drops it in place (UC-TRASH-001 A4)', (tester, env) async {
    await _seedDeleted(env, trashRetention - const Duration(hours: 1));
    await pumpMemoxApp(tester, env);
    await tester.tap(find.byTooltip(_en.libraryTrash));
    await tester.pumpAndSettle();
    expect(find.text('bap · rice'), findsOneWidget);

    env.clock.current = libraryToday.add(const Duration(hours: 2));
    _cycleLifecycle(tester);
    await tester.pumpAndSettle();

    expect(find.text('bap · rice'), findsNothing);
    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
  });

  libraryTest('opening the Trash purges what expired since the start', (
    tester,
    env,
  ) async {
    await _seedDeleted(env, trashRetention - const Duration(hours: 1));
    await pumpMemoxApp(tester, env);
    expect(await _batches(env), 1);

    env.clock.current = libraryToday.add(const Duration(hours: 2));
    await tester.tap(find.byTooltip(_en.libraryTrash));
    await tester.pumpAndSettle();

    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
    expect(await _batches(env), 0);
  });
}
