import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

final _en = AppLocalizationsEn();

StudyHomeDeck _deck(
  String name, {
  int overdue = 0,
  int today = 0,
  int fresh = 0,
}) => StudyHomeDeck(
  deckId: name,
  name: name,
  schedulerType: SchedulerType.eightBox,
  cardCount: overdue + today + fresh + 1,
  overdueCount: overdue,
  dueTodayCount: today,
  newCount: fresh,
);

/// The workload card over [decks], listed in BR-STUDY-076 order as the
/// screen lists them.
Future<List<String>> _pump(
  WidgetTester tester,
  LibraryEnv env,
  List<StudyHomeDeck> decks, {
  bool hasResume = false,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final opened = <String>[];
  await pumpLibraryScreen(
    tester,
    env,
    Scaffold(
      body: StudyHomeWorkloadWidget(
        workload: RootDeckWorkload(decks: decks, nextDueAt: null),
        now: DateTime.utc(2026, 9, 27),
        hasResume: hasResume,
        onOpenDeck: opened.add,
      ),
    ),
    brightness: brightness,
    textScale: textScale,
  );
  return opened;
}

void main() {
  // The "waiting" glyph follows its eyebrow in onSurfaceVariant; it no
  // longer borrows the Required foreground (critique 2026-09-30 part 2, P2).
  libraryTest('the waiting glyph is the eyebrow colour (dark)', (
    tester,
    env,
  ) async {
    await _pump(tester, env, [
      _deck('Verbs', today: 2),
    ], brightness: Brightness.dark);

    final glyph = find.byIcon(AppIcons.dueNow).first;
    expect(
      IconTheme.of(tester.element(glyph)).color,
      appDarkColors.mutedForeground,
    );
  });

  // Study home spec H2: the way in opens the first deck of the list with a
  // due card, a tie falling to the list's own order; new cards alone are no
  // review.
  for (final (name, decks, target) in <(String, List<StudyHomeDeck>, String?)>[
    (
      'the first due deck of the list',
      [_deck('IELTS', overdue: 3), _deck('Kanji', today: 2)],
      'IELTS',
    ),
    (
      'a tie: the one listed first',
      [_deck('Alpha', today: 1), _deck('Beta', today: 1)],
      'Alpha',
    ),
    (
      // BR-STUDY-076 never lists it first; the target still needs a due card.
      'a deck with new cards alone, never, wherever it is listed',
      [_deck('New only', fresh: 9), _deck('Due', today: 1)],
      'Due',
    ),
    (
      // The card says nothing is due and leaves the counts to the rows.
      'new cards alone: nothing due, no counts, no way in',
      [_deck('New only', fresh: 9)],
      null,
    ),
  ]) {
    libraryTest('the workload card opens $name (Study home spec H2)', (
      tester,
      env,
    ) async {
      final opened = await _pump(tester, env, decks);

      if (target == null) {
        expect(find.byType(MxButton), findsNothing);
        expect(find.text(_en.studyHomeCaughtUpTitle), findsOneWidget);
        expect(
          find.textContaining(_en.studyHomeAcrossDecks(1), findRichText: true),
          findsNothing,
        );
        return;
      }
      final button = find.widgetWithText(
        MxButton,
        _en.studyHomeReviewDeck(target),
      );
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(opened, [target]);
    });
  }

  libraryTest('"across K decks" counts the decks with a due card, not those '
      'with new cards alone (BR-STUDY-068)', (tester, env) async {
    await _pump(tester, env, [
      _deck('IELTS', overdue: 3),
      _deck('Kanji', today: 2),
      _deck('IT', fresh: 2),
    ]);
    expect(
      find.textContaining(_en.studyHomeAcrossDecks(2), findRichText: true),
      findsOneWidget,
    );
  });

  // Owner review 2026-10-21: at the default and a large text scale.
  for (final textScale in [1.0, 1.3]) {
    libraryTest('a long deck name on the way in stops at two lines with an '
        'ellipsis, nothing overflows (plan Review Focus 3, scale '
        '$textScale)', (tester, env) async {
      final long = ('IELTS Academic Word List ' * 4).trim();
      await _pump(tester, env, [_deck(long, overdue: 1)], textScale: textScale);

      final label = tester.widget<Text>(
        find.text(_en.studyHomeReviewDeck(long)),
      );
      expect((label.maxLines, label.overflow), (2, TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });
  }

  libraryTest('the way in is the one fill without a Resume card, an outline '
      'under one (Study home spec H4)', (tester, env) async {
    for (final (hasResume, tone) in [
      (false, MxButtonTone.primary),
      (true, MxButtonTone.outline),
    ]) {
      await _pump(tester, env, [
        _deck('IELTS', overdue: 3),
      ], hasResume: hasResume);
      final button = tester.widget<MxButton>(find.byType(MxButton));
      expect((button.tone, button.isBlock), (tone, true), reason: '$hasResume');
    }
  });
}
