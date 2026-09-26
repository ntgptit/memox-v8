@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openRestore(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip(_en.trashEntryActions(name)));
  await _settle(tester);
  await tester.tap(find.text(_en.trashRestore));
  await _settle(tester);
}

/// Selects the two cards of [seedTrash].
Future<void> _selectCards(WidgetTester tester) async {
  await tester.tap(find.text(_en.trashSelect));
  await _settle(tester);
  await tester.tap(find.text('meokda · eat'));
  await _settle(tester);
  await tester.tap(find.text('homework · bai tap'));
  await _settle(tester);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('trash, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_all_$theme.png');
      });
    });

    libraryTest('trash actions, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await tester.tap(find.byTooltip(_en.trashEntryActions('meokda · eat')));
        await _settle(tester);
        await expectBoundaryGolden(tester, 'goldens/trash_actions_$theme.png');
      });
    });

    libraryTest('trash restore target, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await _openRestore(tester, 'meokda · eat');
        await expectBoundaryGolden(
          tester,
          'goldens/trash_restore_target_$theme.png',
        );
      });
    });

    libraryTest('trash no restore target, $theme', (tester, env) async {
      final seed = await seedTrash(env);
      await env.decks.deleteDeck(deckId: seed.words, now: libraryToday);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await _openRestore(tester, 'meokda · eat');
        await expectBoundaryGolden(
          tester,
          'goldens/trash_no_target_$theme.png',
        );
      });
    });

    libraryTest('trash selection, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await _selectCards(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/trash_selection_$theme.png',
        );
      });
    });

    libraryTest('trash purge confirm, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await _selectCards(tester);
        await tester.tap(find.text(_en.trashPurgeSelected(2)));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/trash_purge_confirm_$theme.png',
        );
      });
    });

    libraryTest('trash purge blocked, $theme', (tester, env) async {
      // Korean › Food: its card goes first, then the deck, which so holds
      // an older entry (invariant 36).
      final korean = await env.decks.root('Korean');
      final food = await env.decks.sub(korean.id, 'Food');
      await insertCard(env.db, id: 'rice', deckId: food.id, front: 'bap');
      await env.cards.deleteCards(
        cardIds: {'rice'},
        now: libraryToday.subtract(const Duration(days: 3)),
      );
      await env.decks.deleteDeck(
        deckId: food.id,
        now: libraryToday.subtract(const Duration(days: 2)),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await tester.tap(find.byTooltip(_en.trashEntryActions('Food')));
        await _settle(tester);
        await tester.tap(find.text(_en.trashDeletePermanently));
        await _settle(tester);
        await tester.tap(find.text(_en.trashPurgeConfirm(1)));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/trash_purge_blocked_$theme.png',
        );
      });
    });

    libraryTest('trash empty, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_empty_$theme.png');
      });
    });

    libraryTest('trash error, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const TrashScreen(),
          brightness,
          overrides: [
            trashEntriesProvider.overrideWith(
              (ref) => Stream.error(StateError('read failed')),
            ),
          ],
        );
        await expectBoundaryGolden(tester, 'goldens/trash_error_$theme.png');
      });
    });
  }
}
