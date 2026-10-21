import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/term_line.dart';

// Screen 14 beside the app's open session of another deck: BR-STUDY-072,
// UC-STUDY-001 A3b.

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId, {ValueChanged<String>? onOpen}) =>
    StudyEntryScreen(
      deckId: deckId,
      title: const Text('Deck'),
      breadcrumb: const SizedBox.shrink(),
      onOpenSession: onOpen ?? (_) {},
    );

Finder _button(String label) => find.widgetWithText(MxButton, label);

/// The section over the other starts while a session can be continued.
final _otherSession = _en.studyEntryOtherSessionHeader.toUpperCase();

void main() {
  // Owner 2026-10-21: a start anywhere ends the app's open session
  // (BR-STUDY-072), so the entry of another deck shows that session too,
  // names its deck, leads with Continue and says what a start would end.
  // Before, the root's entry read only its own sessions: no banner, a
  // primary Review, and the start ended the sub-deck's session unseen.
  libraryTest('an open session of another deck shows on this entry with its '
      'deck; Continue takes it up; looking around ends nothing; a start '
      'ends it only after saying so (BR-STUDY-072)', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2, dueCards: 3);
    final opened = await env.entries.openReviewSession(
      deckId: leaf,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    final root = await rootOf(env.db, leaf);
    String? continued;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(root, onOpen: (id) => continued = id),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(breadcrumbLine(_en.studyHomeResumeTitle('Korean', 'Lesson'))),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.text(
              breadcrumbLine(_en.studyHomeResumeTitle('Korean', 'Lesson')),
            ),
          )
          .semanticsLabel,
      _en.studyHomeResumeTitleSpoken('Korean', 'Lesson'),
    );
    expect(find.text(_otherSession), findsOneWidget);
    expect(
      findTermLine(_en.studyEntryEndsSession, isContaining: true),
      findsOneWidget,
    );
    expect(
      tester.widget<MxButton>(_button(_en.studyEntryReviewInstead)).tone,
      MxButtonTone.outline,
    );
    expectOnePrimaryPerDecision(tester);
    // Opening this entry wrote nothing (BR-STUDY-075).
    expect(
      (await sessionOf(env.db, sessionId)).read<String>('status'),
      'in_progress',
    );

    await tester.tap(_button(_en.studyEntryContinue));
    await tester.pumpAndSettle();
    expect(continued, sessionId);
    expect(
      (await sessionOf(env.db, sessionId)).read<String>('status'),
      'in_progress',
    );
  });

  libraryTest('a start beside another deck\'s open session ends it, its '
      'answers kept, as BR-STUDY-072 rules', (tester, env) async {
    final leaf = await sm2Leaf(env.db, env.decks, dueCards: 3);
    final opened = await env.entries.openReviewSession(
      deckId: leaf,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    await pumpLibraryScreen(tester, env, _screen(await rootOf(env.db, leaf)));
    await tester.pumpAndSettle();

    await tester.tap(_button(_en.studyEntryReviewInstead));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studyDirectionStart));
    await tester.pumpAndSettle();

    final old = await sessionOf(env.db, sessionId);
    expect(
      (old.read<String>('status'), old.readNullable<String>('end_reason')),
      ('abandoned', 'user_exit'),
    );
  });
}
