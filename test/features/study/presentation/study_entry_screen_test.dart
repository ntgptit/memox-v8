import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// UC-STUDY-001 steps 1–4 on screen 14; IT-STUDY-001, IT-STUDY-004.

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: const Text('Deck'),
  breadcrumb: const SizedBox.shrink(),
);

Future<void> _learned(LibraryEnv env, String deckId, String id, DateTime due) =>
    insertCard(
      env.db,
      id: id,
      deckId: deckId,
      back: 'meaning $id',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: due,
      box: 2,
    );

MxStatTile _tile(WidgetTester tester, String label) => tester
    .widgetList<MxStatTile>(find.byType(MxStatTile))
    .singleWhere((tile) => tile.label == label);

void main() {
  libraryTest('New and Due are two figures, never one sum, and the overdue '
      'note counts the due cards from before today (IT-STUDY-001)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'n1', deckId: leaf.id);
    await insertCard(env.db, id: 'n2', deckId: leaf.id);
    await insertCard(env.db, id: 'n3', deckId: leaf.id);
    await _learned(env, leaf.id, 'd1', DateTime(2026, 9, 20));
    await _learned(env, leaf.id, 'd2', DateTime(2026, 9, 24, 8));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(leaf.id));

    expect(find.byType(MxStatTile), findsNWidgets(2));
    expect(_tile(tester, _en.studyEntryNew).value, '3');
    expect(_tile(tester, _en.studyEntryDue).value, '2');
    expect(find.text('5'), findsNothing);
    expect(find.text(_en.studyEntryOverdue(1)), findsOneWidget);
  });

  libraryTest('as the kit inks them: Due above zero is primary, New above '
      'zero is muted, a zero is a plain 0 (FE-A6 D17)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await _learned(env, root.id, 'd1', DateTime(2026, 9, 24, 8));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(_tile(tester, _en.studyEntryNew).value, '0');
    expect(_tile(tester, _en.studyEntryNew).emphasis, MxStatTileEmphasis.plain);
    expect(
      _tile(tester, _en.studyEntryDue).emphasis,
      MxStatTileEmphasis.primary,
    );
    expect(find.text(_en.studyEntryOverdue(0)), findsNothing);

    await insertCard(env.db, id: 'n1', deckId: root.id);
    await tester.pump();
    await tester.pump();
    expect(_tile(tester, _en.studyEntryNew).emphasis, MxStatTileEmphasis.muted);
  });

  libraryTest('the overdue note is in the warning ink (kit sm2)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await _learned(env, root.id, 'd1', DateTime(2026, 9, 20));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    final note = tester.widget<Text>(find.text(_en.studyEntryOverdue(1)));
    final context = tester.element(find.text(_en.studyEntryOverdue(1)));
    expect(note.style?.color, context.derivedColors.warningInk);
  });

  libraryTest('Eight boxes lists its four review modes, each with its count '
      'or its reason, none tappable before it is built (IT-STUDY-004, '
      'spec §3)', (tester, env) async {
    final root = await env.decks.root('Korean');
    for (final id in ['a', 'b', 'c']) {
      await _learned(env, root.id, id, DateTime(2026, 9, 20));
    }
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    final rows = tester.widgetList<MxOptionRow>(find.byType(MxOptionRow));
    expect(
      [for (final row in rows) row.title],
      [
        _en.cardModeMatch,
        _en.cardModeGuess,
        _en.cardModeRecall,
        _en.cardModeFill,
      ],
    );
    expect(rows.every((row) => row.onSelected == null), isTrue);
    // Only a mode the cards cannot run is dimmed (kit eightBox).
    expect([for (final row in rows) row.isDimmed], [false, true, false, true]);
    expect(
      [for (final row in rows) row.description],
      [
        _en.studyEntryModeMatchBody,
        _en.studyEntryReasonTooFewMeanings,
        _en.studyEntryModeRecallBody,
        _en.studyEntryReasonNoExample,
      ],
    );
    expect(
      find.widgetWithText(MxBadge, _en.studyEntryNotAvailable),
      findsNWidgets(2),
    );
    expect(find.widgetWithText(MxBadge, _en.studyComingSoon), findsNWidgets(2));
    expect(find.text(_en.studyEntryUnavailableNote), findsOneWidget);
    expect(find.byType(MxFooterBar), findsNothing);
  });

  libraryTest('SM-2 lists no review modes on the entry; Learn is coming '
      'soon while its stages are not built', (tester, env) async {
    final root = await env.decks.root('Korean', SchedulerType.sm2);
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(find.byType(MxOptionRow), findsNothing);
    expect(find.text(_en.studyEntryLearnTitle), findsOneWidget);
    expect(find.textContaining(_en.studyEntryLearnStagesSm2), findsOneWidget);
    expect(find.textContaining(_en.studyEntryLearnCount(1, 1)), findsOneWidget);
    expect(find.widgetWithText(MxBadge, _en.studyComingSoon), findsOneWidget);
  });

  libraryTest('with nothing due, no review mode is listed: only the Learn '
      'row (kit onlyNew), on Eight boxes as on SM-2', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(find.text(_en.studyEntryLearnTitle), findsOneWidget);
    expect(find.byType(MxOptionRow), findsNothing);
    expect(find.text(_en.studyEntryReviewHeader), findsNothing);
  });

  libraryTest('nothing new and nothing due is the calm empty state '
      '(BR-STUDY-008)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await _learned(env, root.id, 'later', DateTime(2026, 10, 1));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text(_en.studyEntryNothingTitle), findsOneWidget);
    // The hero stays above it, reading 0 and 0 (kit nothing).
    expect(_tile(tester, _en.studyEntryNew).value, '0');
    expect(_tile(tester, _en.studyEntryDue).value, '0');
    expect(find.byType(MxOptionRow), findsNothing);
  });

  libraryTest('loading draws the hero and the option list as skeletons '
      '(kit loading)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final pending = StreamController<Never>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(root.id),
      overrides: [
        studyEntryProvider(root.id).overrideWith((_) => pending.stream),
      ],
    );

    expect(find.byType(MxSkeletonList), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSkeleton && widget.isCircle,
      ),
      findsNWidgets(3),
    );
    expect(find.bySemanticsLabel(_en.commonLoading), findsOneWidget);
  });

  libraryTest('a read that fails says so and Retry reads again '
      '(UC-STUDY-001)', (tester, env) async {
    final root = await env.decks.root('Korean');
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(root.id),
      overrides: [
        studyEntryProvider(root.id).overrideWith((_) {
          reads++;
          return Stream.error(
            const UnknownDatabaseFailure(cause: '/data/memox.sqlite'),
          );
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.studyEntryErrorTitle), findsOneWidget);
    expect(find.text(_en.studyEntryErrorBody), findsOneWidget);
    final before = reads;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(reads, before + 1);
  });

  libraryTest('a deck deleted while its entry is open leaves with a message '
      '(UC-STUDY-001 E1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await pumpLibraryScreen(
      tester,
      env,
      MxAppShell(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => _screen(root.id))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyEntryScreen), findsOneWidget);

    await env.decks.deleteDeck(deckId: root.id);
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(find.text(_en.studyEntryDeckGone), findsOneWidget);
  });
}
