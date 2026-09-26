import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The real schedules, except that the first switch fails in the database
/// (UC-DECK-002 E2).
final class _FirstSwitchFails implements ScheduleRepository {
  _FirstSwitchFails(this._real);

  final ScheduleRepository _real;
  var _hasFailed = false;

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  }) async {
    if (!_hasFailed) {
      _hasFailed = true;
      throw const DatabaseLockedFailure(cause: 'locked');
    }
    return _real.changeScheduler(rootDeckId: rootDeckId, newType: newType);
  }

  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) => _real.initializeCards(deckId: deckId, cardIds: cardIds);

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) =>
      _real.recordTurn(turn);

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) =>
      _real.completeLearning(cardId: cardId, generation: generation, now: now);

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) =>
      _real.resetLearning(rootDeckId: rootDeckId, schedulerType: schedulerType);

  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) => _real.resetSummary(rootDeckId: rootDeckId);
}

MxOptionRow _option(WidgetTester tester, String title) =>
    tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, title));

void main() {
  libraryTest('unlocked: the current algorithm is selected; switching asks '
      'first', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );

    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
    expect(find.text(_en.algorithmSwitchNote), findsOneWidget);
    expect(_option(tester, _en.deckSchedulerSm2).isSelected, isTrue);

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.algorithmSwitchTitle(_en.deckSchedulerEightBox)),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.algorithmSwitchedToast(_en.deckSchedulerEightBox)),
      findsOneWidget,
    );
    expect(_option(tester, _en.deckSchedulerEightBox).isSelected, isTrue);
  });

  libraryTest('cancelling the switch changes nothing (UC-DECK-002 A3)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    expect(_option(tester, _en.deckSchedulerSm2).isSelected, isTrue);
  });

  libraryTest('tapping the current algorithm does nothing (UC-DECK-002 A4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );

    await tester.tap(find.text(_en.deckSchedulerSm2));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
  });

  libraryTest('locked: cycle and date named, options disabled, the note '
      'points to the reset', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    final date = DateFormat.yMMMd('en').format(DateTime(2026, 9, 20));

    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
    expect(find.text(_en.algorithmLockedBody(date)), findsOneWidget);
    expect(find.text(_en.algorithmLockedNote), findsOneWidget);
    for (final title in [_en.deckSchedulerSm2, _en.deckSchedulerEightBox]) {
      expect(_option(tester, title).onSelected, isNull, reason: title);
    }
    expect(find.text(_en.algorithmResetAction), findsOneWidget);
  });

  libraryTest('a switch refused because the tree just locked says why (E4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await lockScheduler(env.db, korean.id);
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.srsRejectionSchedulerLocked), findsOneWidget);
    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
    expect(_option(tester, _en.deckSchedulerSm2).isSelected, isTrue);
  });

  libraryTest('a switch that fails says the deck kept its algorithm; Retry '
      'switches (E2)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(
          _FirstSwitchFails(ScheduleRepositoryImpl(env.db)),
        ),
      ],
    );

    await tester.tap(find.text(_en.deckSchedulerEightBox));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.algorithmSwitchConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.algorithmSwitchFailedTitle), findsOneWidget);
    expect(
      find.text(_en.algorithmSwitchFailedBody(_en.deckSchedulerSm2)),
      findsOneWidget,
    );
    expect(_option(tester, _en.deckSchedulerSm2).isSelected, isTrue);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(_en.algorithmSwitchFailedTitle), findsNothing);
    expect(_option(tester, _en.deckSchedulerEightBox).isSelected, isTrue);
  });

  libraryTest('a root deleted while open shows the gone state', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    String? ancestor = 'unset';
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(
        deckId: korean.id,
        onOpenAncestor: (id) => ancestor = id,
      ),
    );

    await env.decks.deleteDeck(deckId: korean.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    await tester.tap(find.text(_en.deckBackToLibrary));
    expect(ancestor, isNull);
  });

  libraryTest('a sub-deck has no algorithm screen (BR-DECK-025)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: words.id));

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    expect(find.byType(MxOptionRow), findsNothing);
  });

  libraryTest('the breadcrumb leads to the root and the Library', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final opened = <String?>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id, onOpenAncestor: opened.add),
    );
    Finder crumb(String label) => find.descendant(
      of: find.byType(MxBreadcrumb),
      matching: find.text(label),
    );

    await tester.tap(crumb('Korean'));
    await tester.tap(crumb(_en.navLibrary));

    expect(opened, [korean.id, null]);
  });

  libraryTest('at 2x on a 360 phone the locked screen does not overflow', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root(
      'Từ vựng tiếng Hàn rất dài để thử cỡ chữ',
      SchedulerType.sm2,
    );
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
