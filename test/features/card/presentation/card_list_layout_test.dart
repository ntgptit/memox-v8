import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/card/presentation/states/card_search_open_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

/// Screen 07's layout: the search behind the app bar's action, the deck
/// summary, the header, the selection and the four-command bulk bar.
final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
    // As the router wires it: the bulk bar holds its five commands.
    onExport: (_) {},
  ),
);

/// Korean › Words: annyeong (new) and gamsa (due, "thanks").
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
  await insertCard(
    env.db,
    id: 'due1',
    deckId: words.id,
    front: 'gamsa',
    back: 'thanks',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  return words.id;
}

/// The app bar's search action: here, straight on the state.
Future<void> _openSearch(WidgetTester tester, String deckId) async {
  ProviderScope.containerOf(tester.element(find.byType(CardListSectionWidget)))
      .read(cardSearchOpenProvider(deckId).notifier)
      .open();
  await tester.pumpAndSettle();
}

/// Flags that fail the first way a real database can.
final class _FailingFlags implements CardRepository {
  @override
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fails the first write and any while [isFailing]; counts every call.
final class _FlakyFlags implements CardRepository {
  final calls = <(Set<String>, bool)>[];
  var isFailing = true;

  @override
  Future<Outcome<BulkOutcome, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) {
    calls.add((cardIds, isFlagged));
    if (isFailing) {
      return Future.error(const UnknownDatabaseFailure(cause: 'locked'));
    }
    return Future.value(const Ok(BulkOutcome(done: {})));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('the search field waits for the search action; closing clears', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    expect(find.byType(MxSearchField), findsNothing);

    await _openSearch(tester, deckId);
    await tester.enterText(find.byType(EditableText), 'thank');
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsOneWidget);

    ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    ).read(cardSearchOpenProvider(deckId).notifier).close();
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsNothing);
    expect(find.byType(CardRowWidget), findsNWidgets(2));
  });

  libraryTest('the summary leads, then the filters, then Showing n of total', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    // Every card shows: the chips count, the header only names the list
    // (critique 2026-09-30 part 3b).
    final header = find.text(_en.cardListHeader.toUpperCase());
    expect(find.textContaining('SHOWING'), findsNothing);

    expect(find.byType(CardDeckSummaryWidget), findsOneWidget);
    expect(header, findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(CardDeckSummaryWidget)).dy,
      lessThan(tester.getTopLeft(header).dy),
    );
    expect(
      find.widgetWithText(MxChipTrigger, _en.cardSortNewest),
      findsOneWidget,
    );
  });

  libraryTest('selecting hides the summary; the header counts the selection', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(find.byType(CardDeckSummaryWidget), findsNothing);
    expect(find.byType(MxFilterChip), findsNothing);
    // The selected count lives in the app bar title only (critique
    // 2026-09-30 part 3b).
    expect(find.byType(MxListSectionHeader), findsNothing);
  });

  libraryTest('a filter narrows the list: the header says how many of the '
      "deck's cards show (critique 2026-09-30 part 3b)", (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterDue));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardShowingOf(1, 2).toUpperCase()), findsOneWidget);
    expect(find.text(_en.cardListHeader.toUpperCase()), findsNothing);
  });

  libraryTest('the bulk bar offers Move, Flag, Tag, Export, Delete (kit 07)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    final bar = find.byType(CardBulkBarWidget);
    for (final label in [
      _en.cardMove,
      _en.cardFlag,
      _en.cardTag,
      _en.cardExport,
      _en.cardDelete,
    ]) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
    expect(
      find.descendant(of: bar, matching: find.byType(Text)),
      findsNWidgets(5),
    );
  });

  libraryTest('a failed bulk command keeps the selection and says so (E-L6)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(deckId),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(_FailingFlags()),
        ),
      ],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlag));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlagSet));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBulkFailedTitle), findsOneWidget);
    // The selection stays after the failure.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('the section with a selection meets the target guidelines', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('a row keeps its own state when the summary steps aside', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    final row = find.widgetWithText(CardRowWidget, 'gamsa');
    final before = tester.element(row);

    await tester.longPress(row);
    await tester.pumpAndSettle();

    expect(find.byType(CardDeckSummaryWidget), findsNothing);
    expect(identical(tester.element(row), before), isTrue);
  });

  libraryTest('selecting hides the search field; it returns with its term', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await _openSearch(tester, deckId);
    await tester.enterText(find.byType(EditableText), 'a');
    await tester.pumpAndSettle();

    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsNothing);

    ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    ).read(cardSelectionProvider(deckId).notifier).clear();
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'a',
    );
  });

  libraryTest('the add FAB steps aside while search is open, so it covers '
      'no row (critique 2026-09-30 part 3d-1)', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardListSectionWidget(
          deckId: deckId,
          algorithm: 'Eight boxes',
          onAddCard: () {},
          onOpenCard: (_) {},
          onExport: (_) {},
        ),
        floatingActionButton: CardAddFabWidget(
          deckId: deckId,
          onAddCard: () {},
        ),
      ),
    );
    expect(find.byType(MxFab), findsOneWidget);

    await _openSearch(tester, deckId);
    expect(find.byType(MxFab), findsNothing);

    ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    ).read(cardSearchOpenProvider(deckId).notifier).close();
    await tester.pumpAndSettle();
    expect(find.byType(MxFab), findsOneWidget);
  });

  Future<_FlakyFlags> failOneFlag(WidgetTester tester, LibraryEnv env) async {
    final flags = _FlakyFlags();
    final deckId = await _seed(env);
    await pumpLibraryScreen(
      tester,
      env,
      _section(deckId),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(flags),
        ),
      ],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlag));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlagSet));
    await tester.pumpAndSettle();
    return flags;
  }

  libraryTest('Retry repeats the failed flag with the same cards and choice '
      '(critique 2026-09-30 part 3d-1)', (tester, env) async {
    final flags = await failOneFlag(tester, env);
    flags.isFailing = false;

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pumpAndSettle();

    expect(flags.calls, hasLength(2));
    expect(flags.calls.last, flags.calls.first);
    expect(find.text(_en.cardBulkFailedTitle), findsNothing);
    expect(find.text(_en.cardFlaggedToast(1)), findsOneWidget);
  });

  libraryTest('a retry that fails again keeps the banner and the selection '
      '(Review Focus 2)', (tester, env) async {
    final flags = await failOneFlag(tester, env);

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pumpAndSettle();

    expect(flags.calls, hasLength(2));
    expect(find.text(_en.cardBulkFailedTitle), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsOneWidget,
    );
  });

  libraryTest('a changed selection drops the failed flag: Retry never writes '
      'the cards of an earlier attempt (critique 2026-09-30 part 3d-1, final '
      'review)', (tester, env) async {
    final flags = await failOneFlag(tester, env);

    await tester.tap(find.text('gamsa'));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardBulkFailedTitle), findsNothing);
    expect(find.widgetWithText(MxButton, _en.commonRetry), findsNothing);
    expect(flags.calls, hasLength(1));
  });
}
