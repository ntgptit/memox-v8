import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _button(String label) => find.widgetWithText(MxButton, label);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _toast(String message) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(message));

/// Korean › Food: its card went to the Trash first, then the deck, so the deck
/// holds an older entry and a purge skips it (invariant 36).
Future<void> _seedFood(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final food = await env.decks.sub(korean.id, 'Food');
  await insertCard(
    env.db,
    id: 'rice',
    deckId: food.id,
    front: 'bap',
    back: 'rice',
  );
  await env.cards.deleteCards(
    cardIds: {'rice'},
    now: libraryToday.subtract(const Duration(days: 2)),
  );
  await env.decks.deleteDeck(
    deckId: food.id,
    now: libraryToday.subtract(const Duration(days: 1)),
  );
}

/// Selects the two cards of [seedTrash].
Future<void> _selectCards(WidgetTester tester) async {
  await _tap(tester, _button(_en.trashSelect));
  await _tap(tester, find.text('meokda · eat'));
  await _tap(tester, find.text('homework · bai tap'));
}

void main() {
  libraryTest(
    'a failed purge keeps the dialog with a banner, and Delete is the retry '
    '(SP2b 2.27)',
    (tester, env) async {
      await seedTrash(env);
      final hold = WriteHold()
        ..open()
        ..failNext();
      await pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        overrides: [
          trashRepositoryProvider.overrideWithValue(
            HeldTrash(TrashRepositoryImpl(env.db), hold),
          ),
        ],
      );
      await _selectCards(tester);
      await _tap(tester, _button(_en.trashPurgeSelected(2)));
      await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
      await tester.pumpAndSettle();

      expect(find.byType(MxDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MxInlineBanner),
          matching: find.text(_en.failure(WriteHold.failure)),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
      await tester.pumpAndSettle();
      expect(find.byType(MxDialog), findsNothing);
      expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
    },
  );

  libraryTest(
    'a purge the store skips says so in a toast that names what the deck '
    'still holds (SP2b 2.31)',
    (tester, env) async {
      await _seedFood(env);
      await pumpLibraryScreen(tester, env, const TrashScreen());

      await _tap(tester, find.byTooltip(_en.trashEntryActions('Food')));
      await _tap(tester, find.text(_en.trashDeletePermanently));
      await _tap(tester, _inDialog(_en.trashPurgeConfirm(1)));

      expect(find.byType(MxDialog), findsNothing);
      expect(
        _toast(_en.trashPurgeBlocked('Food', 'bap · rice')),
        findsOneWidget,
      );
      expect(find.text(_en.trashPurgedDecks(1)), findsNothing);
    },
  );

  libraryTest(
    'a purge that takes one deck and keeps two says both in one toast '
    '(SP2b 2.31)',
    (tester, env) async {
      final korean = await env.decks.root('Korean');
      for (final (index, name) in ['Food', 'Travel'].indexed) {
        final deck = await env.decks.sub(korean.id, name);
        await insertCard(env.db, id: 'c$index', deckId: deck.id);
        await env.cards.deleteCards(
          cardIds: {'c$index'},
          now: libraryToday.subtract(const Duration(days: 3)),
        );
        await env.decks.deleteDeck(
          deckId: deck.id,
          now: libraryToday.subtract(const Duration(days: 2)),
        );
      }
      final basics = await env.decks.root('Basics');
      await env.decks.deleteDeck(
        deckId: basics.id,
        now: libraryToday.subtract(const Duration(days: 1)),
      );
      await pumpLibraryScreen(tester, env, const TrashScreen());

      await _tap(tester, _button(_en.trashSelect));
      for (final name in ['Food', 'Travel', 'Basics']) {
        await _tap(tester, find.text(name));
      }
      await _tap(tester, _button(_en.trashPurgeSelected(3)));
      await _tap(tester, _inDialog(_en.trashPurgeConfirm(3)));

      expect(
        _toast(
          _en.trashPurgedWithKept(
            _en.trashPurgedDecks(1),
            _en.trashPurgeKeptMany(2),
          ),
        ),
        findsOneWidget,
      );
    },
  );

  libraryTest(
    'a deck confirm names the deck, its sub-decks and its cards (SP2b 2.32)',
    (tester, env) async {
      await seedTrash(env);
      await pumpLibraryScreen(tester, env, const TrashScreen());

      await _tap(tester, find.byTooltip(_en.trashEntryActions('Basics')));
      await _tap(tester, find.text(_en.trashDeletePermanently));

      expect(find.text(_en.trashPurgeDeckBody('Basics', 1, 2)), findsOneWidget);
      expect(find.text(_en.trashPurgeBody(1)), findsNothing);
    },
  );

  libraryTest(
    'several decks name the totals of their sub-decks and cards (SP2b 2.32)',
    (tester, env) async {
      await seedTrash(env);
      await pumpLibraryScreen(tester, env, const TrashScreen());

      // Basics (1 sub-deck, 2 cards) and Places (no sub-decks, 3 cards).
      await _tap(tester, _button(_en.trashSelect));
      await _tap(tester, find.text('Basics'));
      await _tap(tester, find.text('Places'));
      await _tap(tester, _button(_en.trashPurgeSelected(2)));

      expect(find.text(_en.trashPurgeDecksTotalBody(2, 1, 5)), findsOneWidget);
    },
  );

  libraryTest('cards keep the count-only confirm (SP2b 2.32)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected(2)));

    expect(find.text(_en.trashPurgeBody(2)), findsOneWidget);
  });
}
