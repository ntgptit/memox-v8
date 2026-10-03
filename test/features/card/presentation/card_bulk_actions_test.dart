import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

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
      final ids = await seedBulkCards(env);
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
      await selectCards(tester, ['annyeong', 'mul']);
      await tapBulk(tester, enL10n.cardExport);

      expect(exported, [
        {'new1', 'flag1'},
      ]);
      final checked = find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      );
      expect(checked, findsNWidgets(2));
    },
  );

  for (final (how, dismiss) in <(String, Future<void> Function(WidgetTester))>[
    ('Close', (tester) => tapBulk(tester, enL10n.exportClose)),
    ('Back', (tester) => tester.binding.handlePopRoute()),
    ('a scrim tap', (tester) => tester.tapAt(const Offset(20, 20))),
  ]) {
    libraryTest('Export of cards that are all gone prunes them whichever way '
        'the sheet is dismissed: $how (SP2a 2.19)', (tester, env) async {
      final ids = await seedBulkCards(env);
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: Builder(
            // As the router wires it (_exportSelection).
            builder: (context) => CardListSectionWidget(
              deckId: ids.words,
              algorithm: 'Eight boxes',
              onAddCard: () {},
              onOpenCard: (_) {},
              onExport: (selected) async {
                final skipped = await showCardExportSheet(
                  context,
                  CardExportScope.selection(deckId: ids.words, ids: selected),
                );
                ProviderScope.containerOf(context, listen: false)
                    .read(cardSelectionProvider(ids.words).notifier)
                    .prune(skipped);
              },
            ),
          ),
        ),
      );
      await selectCards(tester, ['annyeong', 'mul']);
      await env.db.customStatement(
        "DELETE FROM card WHERE id IN ('new1', 'flag1')",
      );

      await tapBulk(tester, enL10n.cardExport);
      await tapBulk(tester, enL10n.exportAction(2));
      expect(find.text(enL10n.exportStaleTitle), findsOneWidget);
      await dismiss(tester);
      await tester.pumpAndSettle();

      expect(find.text(enL10n.exportStaleTitle), findsNothing);
      expect(find.byType(MxSelectionCheckbox), findsNothing);
      expect(find.text(enL10n.cardExport), findsNothing);
    });
  }

  libraryTest('Flag sets the flag on every selected card', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagSet);

    expect(
      await countRows(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      3,
    );
    expect(find.text(enL10n.cardFlaggedToast(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Flag when every selected card is already gone says so, writes '
      'nothing and does not throw (SP2a 2.19)', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(
      tester,
      env,
      bulkSection(ids.words),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(_AllGoneCards()),
        ),
      ],
    );
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagSet);

    expect(tester.takeException(), isNull);
    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(find.text(enL10n.cardFlaggedToast(2)), findsNothing);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Remove flag clears it, never toggles (P3-L4)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['mul', 'annyeong']);
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagClear);

    expect(
      await countRows(env, 'SELECT COUNT(*) AS n FROM card WHERE is_flagged'),
      0,
    );
  });

  libraryTest('Tag adds one tag to every selected card', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(await countRows(env, 'SELECT COUNT(*) AS n FROM card_tags'), 2);
    expect(find.text(enL10n.cardTaggedToast(2, 'greetings')), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('a blank tag stays in the dialog, under the field', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong']);
    await tapBulk(tester, enL10n.cardTag);
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(enL10n.tagRejectionBlankName), findsOneWidget);
  });

  libraryTest(
    'a tag refused for one card writes nothing, keeps selection (RF2)',
    (tester, env) async {
      final ids = await seedBulkCards(env);
      final tags = TagRepositoryImpl(env.db);
      for (var i = 0; i < 10; i++) {
        await tags.attachByName(cardIds: {'new1'}, name: 'tag $i');
      }
      await pumpLibraryScreen(tester, env, bulkSection(ids.words));
      await selectCards(tester, ['annyeong', 'gamsa']);
      await tapBulk(tester, enL10n.cardTag);
      await tester.enterText(find.byType(EditableText).last, 'extra');
      await tester.tap(inDialog(enL10n.cardTagConfirm));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.cardTagLimitReached(1)), findsOneWidget);
      expect(await countRows(env, 'SELECT COUNT(*) AS n FROM card_tags'), 10);
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
    final ids = await seedBulkCards(env);
    final tags = TagRepositoryImpl(env.db);
    for (final card in ['new1', 'due1']) {
      for (var i = 0; i < 10; i++) {
        await tags.attachByName(cardIds: {card}, name: '$card tag $i');
      }
    }
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa', 'mul']);
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'extra');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardTagLimitReached(2)), findsOneWidget);
    expect(await countRows(env, 'SELECT COUNT(*) AS n FROM card_tags'), 20);
  });

  libraryTest('Move sends the cards to another deck of the root', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      await countRows(env, 'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [
        ids.verbs,
      ]),
      3,
    );
    expect(find.text(enL10n.cardMovedToast(2, 'Verbs')), findsOneWidget);
  });
}
