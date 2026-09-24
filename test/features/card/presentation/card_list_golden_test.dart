@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// A deck of cards in every status, one flagged, shown as its open deck.
/// Romanized fronts: the golden test font has no Hangul glyphs.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final rows = [
    ('annyeonghaseyo', 'hello', null, 1),
    ('gamsahamnida', 'thank you', DateTime(2026, 9, 24), 2),
    ('sarang', 'love', DateTime(2026, 9, 30), 5),
    ('mul', 'water', DateTime(2026, 12, 1), 8),
  ];
  for (final (index, (front, back, due, box)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      learnedAt: due == null ? null : DateTime(2026, 9, 1),
      dueAt: due,
      box: box,
      isFlagged: index == 1,
      createdAt: DateTime(2026, 9, 1 + index),
    );
  }
  return words.id;
}

/// The open deck as `app/` composes it (A14).
Widget _screen(String deckId) => deckScreen(
  deckId: deckId,
  cardContent: (view) => CardListSectionWidget(
    deckId: view.deck.id,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
  cardAppBar: (view, actions) =>
      CardDeckAppBarWidget(view: view, deckActions: actions),
  cardBreadcrumb: (id, child) =>
      CardDeckBreadcrumbWidget(deckId: id, child: child),
  cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
);

/// Flags that fail the first way a real database can.
final class _FailingFlags implements CardRepository {
  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: 'disk'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card list, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await expectBoundaryGolden(tester, 'goldens/card_list_$theme.png');
      });
    });

    libraryTest('card selection, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.longPress(find.text('sarang'));
        await _settle(tester);
        await expectBoundaryGolden(tester, 'goldens/card_selection_$theme.png');
      });
    });

    libraryTest('card search, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.tap(find.byTooltip(_en.cardSearchOpen));
        await _settle(tester);
        await tester.enterText(find.byType(EditableText), 'zzz');
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/card_list_search_$theme.png',
        );
      });
    });

    libraryTest('card bulk failed, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(deckId),
          brightness,
          overrides: [
            setCardsFlaggedUseCaseProvider.overrideWithValue(
              SetCardsFlaggedUseCase(_FailingFlags()),
            ),
          ],
        );
        await tester.longPress(find.text('sarang'));
        await _settle(tester);
        await tester.tap(find.text(_en.cardFlag));
        await _settle(tester);
        await tester.tap(find.text(_en.cardFlagSet));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/card_list_bulk_failed_$theme.png',
        );
      });
    });
  }
}
