import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// Screen 17, Match (UC-STUDY-005): BR-STUDY-049, BR-STUDY-060, BR-STUDY-062,
// BR-STUDY-063, BR-STUDY-070; FE-A6 P3 rulings M1, M2, C1, C3, C4, C7, C8.

final _en = lookupAppLocalizations(const Locale('en'));

const _terms = ['term 1', 'term 2', 'term 3', 'term 4', 'term 5'];
const _meanings = ['apple', 'banana', 'cherry', 'date', 'elder'];

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// One board of five pairs: term N goes with the Nth meaning.
Future<String> _match(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.match);

StudyChoiceWidget _tile(WidgetTester tester, String text) =>
    tester.widget<StudyChoiceWidget>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(StudyChoiceWidget),
      ),
    );

Color? _groundOf(WidgetTester tester, String text) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.ancestor(
                          of: find.text(text),
                          matching: find.byType(StudyChoiceWidget),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;

Future<void> _pair(WidgetTester tester, String term, String meaning) async {
  await tester.tap(find.text(term));
  await tester.pump();
  await tester.tap(find.text(meaning));
  await tester.pump();
  await tester.pump();
}

/// The footer hint's glyph (critique 2026-10-02, F7).
IconData _hintIcon(WidgetTester tester) => tester
    .widget<SessionFooterHintWidget>(find.byType(SessionFooterHintWidget))
    .icon;

void main() {
  libraryTest('terms on the left, meanings on the right, with the hint '
      '(BR-STUDY-049)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    for (final text in [..._terms, ..._meanings]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(
      tester.getCenter(find.text('term 1')).dx,
      lessThan(tester.getCenter(find.text('apple')).dx),
    );
    expect(find.textContaining(_en.studyMatchHint), findsOneWidget);
    expect(_hintIcon(tester), AppIcons.info);
  });

  libraryTest('a term, then its meaning: both are matched, in the success '
      'tone, and the match is announced (M1, C1, C3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _pair(tester, 'term 1', 'apple');
    await tester.pumpAndSettle();

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.right);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.right);
    expect(
      find.bySemanticsLabel(
        _en.studyMatchTileMatched(_en.studyMatchTerm('term 1')),
      ),
      findsOneWidget,
    );
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyMatchAnnounceRight),
    );
    handle.dispose();
  });

  libraryTest('a wrong pair flashes wrong with the hint swapped, then both go '
      'back to idle and stay unmatched (M2, C7, BR-STUDY-062)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _pair(tester, 'term 1', 'banana');

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.wrong);
    expect(_tile(tester, 'banana').tone, StudyChoiceTone.wrong);
    // M3-F1: a wrong tile carries the cross, as a wrong Guess option does.
    expect(
      find.descendant(
        of: find.byType(StudyChoiceWidget),
        matching: find.byIcon(AppIcons.close),
      ),
      findsNWidgets(2),
    );
    // The same cards' other sides are not part of the wrong pair.
    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.idle);
    expect(find.textContaining(_en.studyMatchHintWrong), findsOneWidget);
    expect(_hintIcon(tester), AppIcons.repeat);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(_en.studyMatchHintWrong),
    );

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'banana').tone, StudyChoiceTone.idle);
    expect(find.textContaining(_en.studyMatchHint), findsOneWidget);
    expect(_hintIcon(tester), AppIcons.info);
    expect(await turnKindsOf(env.db, 'ST-01'), hasLength(1));
    handle.dispose();
  });

  libraryTest('a meaning first, then its term: the pair is matched and '
      'answered on the term (BR-STUDY-062; critique 2026-09-30 part 3c-2, '
      'R3)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.selected);

    await tester.tap(find.text('term 1'));
    await tester.pump();
    await tester.pump();

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.right);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.right);
    expect(await turnKindsOf(env.db, 'ST-01'), isNotEmpty);
  });

  libraryTest('a second meaning moves the selection (R3)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.tap(find.text('banana'));
    await tester.pump();

    expect(_tile(tester, 'apple').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'banana').tone, StudyChoiceTone.selected);
    expect(await turnKindsOf(env.db, 'ST-01'), isEmpty);
  });

  libraryTest('a second term moves the selection (M1, R3)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('term 1'));
    await tester.pump();
    await tester.tap(find.text('term 2'));
    await tester.pump();

    expect(_tile(tester, 'term 1').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.selected);
    expect(await turnKindsOf(env.db, 'ST-01'), isEmpty);
  });

  libraryTest('a meaning, then the wrong term: both flash wrong, the turn is '
      "the term's, and nothing stays selected (Review Focus 3)", (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.tap(find.text('term 2'));
    await tester.pump();
    await tester.pump();

    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.wrong);
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.wrong);
    expect(await turnKindsOf(env.db, 'ST-02'), isNotEmpty);
    expect(await turnKindsOf(env.db, 'ST-01'), isEmpty);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(_tile(tester, 'apple').tone, StudyChoiceTone.idle);
    expect(_tile(tester, 'term 2').tone, StudyChoiceTone.idle);
  });

  libraryTest('idle meanings are recessed, idle terms raised (R3)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final scheme = Theme.of(tester.element(find.text('apple'))).colorScheme;

    expect(_groundOf(tester, 'apple'), scheme.surfaceContainerLow);
    expect(_groundOf(tester, 'term 1'), scheme.surfaceContainerLowest);
  });

  libraryTest('tiles take no tap while a wrong pair flashes (BR-STUDY-004)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _pair(tester, 'term 1', 'banana');
    await _pair(tester, 'term 2', 'banana');

    expect(await turnKindsOf(env.db, 'ST-02'), isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  });

  libraryTest('five right pairs finish the board, and the review ends with '
      'nothing selected', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    for (var i = 0; i < 5; i++) {
      await _pair(tester, _terms[i], _meanings[i]);
      await tester.pumpAndSettle();
    }

    expect(find.text(_en.summaryReviewFinished), findsOneWidget);
  });

  libraryTest('nothing overflows and each tile is at '
      'least 48 tall (C4)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byWidget(_tile(tester, 'apple'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  libraryTest('TalkBack reads the terms first, then the meanings (C8)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    double keyOf(String text) =>
        (_tile(tester, text).sortKey! as OrdinalSortKey).order;
    final lastTerm = [for (final t in _terms) keyOf(t)]
        .reduce((a, b) => a > b ? a : b);
    final firstMeaning = [for (final m in _meanings) keyOf(m)]
        .reduce((a, b) => a < b ? a : b);
    expect(lastTerm, lessThan(firstMeaning));
  });

  libraryTest('the context line names the round; the board, not the line, '
      'shows the pairs left (critique 2026-09-30)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final line = _en.studyContextRound(
      _en.studyContextReview('Lesson', _en.studyKindReview),
      1,
    );

    expect(find.bySemanticsLabel(line), findsOneWidget);

    await _pair(tester, 'term 1', 'apple');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(line), findsOneWidget);
    handle.dispose();
  });

  /// Seven due cards: a board of five, then a board of two (BR-STUDY-049).
  Future<String> sevenDue(LibraryEnv env) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    const meanings = [..._meanings, 'fig', 'grape'];
    for (final (index, meaning) in meanings.indexed) {
      await insertCard(
        env.db,
        id: 'M${index + 1}',
        deckId: leaf.id,
        front: 'term ${index + 1}',
        back: meaning,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 10 + index),
        box: 2,
      );
    }
    await lockScheduler(env.db, root.id);
    final opened = await studyEntryRepository(
      env.db,
      env.clock.now,
    ).openReviewSession(deckId: leaf.id, mode: StudyMode.match);
    return (opened as Ok<String, StudyRejection>).value;
  }

  libraryTest('the last right pair of a board leads to the next board, whose '
      'tiles take taps (Review Focus 4; final review, critical)', (
    tester,
    env,
  ) async {
    final id = await sevenDue(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    for (var i = 0; i < 5; i++) {
      await _pair(tester, _terms[i], _meanings[i]);
      await tester.pumpAndSettle();
    }
    expect(find.text('term 6'), findsOneWidget);

    await tester.tap(find.text('term 6'));
    await tester.pump();
    expect(_tile(tester, 'term 6').tone, StudyChoiceTone.selected);

    await tester.tap(find.text('fig'));
    await tester.pumpAndSettle();
    expect(_tile(tester, 'term 6').tone, StudyChoiceTone.right);
  });

  libraryTest('a wrong pair carried into round 2 is asked there, and the '
      'round answers (BR-STUDY-060, BR-STUDY-062)', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _pair(tester, 'term 1', 'banana');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await _pair(tester, _terms[i], _meanings[i]);
      await tester.pumpAndSettle();
    }

    // Round 2 holds the pair that went wrong.
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('term 2'), findsNothing);
    await _pair(tester, 'term 1', 'apple');
    await tester.pumpAndSettle();

    expect(find.text(_en.summaryReviewFinished), findsOneWidget);
  });

  libraryTest('a wrong tile carries its state in its label during the flash '
      '(C3; Impeccable after P3)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    await _pair(tester, 'term 1', 'banana');

    expect(
      find.bySemanticsLabel(
        _en.studyMatchTileWrong(_en.studyMatchTerm('term 1')),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    handle.dispose();
  });

  libraryTest('at normal size no fade is drawn', (tester, env) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    expect(find.byKey(const ValueKey('study-scroll-fade')), findsNothing);
  });

  libraryTest('a tile eases into its tone (Impeccable after P3)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));

    final box = tester.widget<TweenAnimationBuilder<Decoration>>(
      find.descendant(
        of: find.ancestor(
          of: find.text('term 1'),
          matching: find.byType(StudyChoiceWidget),
        ),
        matching: find.byType(TweenAnimationBuilder<Decoration>),
      ),
    );
    expect(box.duration, AppDurations.standard);
  });

  libraryTest('a tile keeps its content in place as its tone changes, and '
      'its ink eases with its surface (Impeccable after P3)', (
    tester,
    env,
  ) async {
    final id = await _match(env);
    await pumpLibraryScreen(tester, env, _screen(id));
    final before = tester.getRect(find.text('term 1'));
    Color inkOf() => tester.widget<Text>(find.text('term 1')).style!.color!;
    final idleInk = inkOf();

    await tester.tap(find.text('term 1'));
    await tester.pump();
    await tester.pump(AppDurations.standard ~/ 2);
    final midInk = inkOf();
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text('term 1')), before);
    expect(midInk, isNot(anyOf(idleInk, inkOf())));
  });
}
