import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/term_line.dart';
import '../../../support/wrap_rule.dart';

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

  // The path is the user's own text: two lines at most, "›" kept with the
  // deck after it, on a 360 dp phone and at a 1.3 text scale.
  for (final textScale in [1.0, 1.3]) {
    libraryTest('a long deck path stops at two lines with an ellipsis, never '
        'ends a line on "›", and nothing overflows (scale $textScale)', (
      tester,
      env,
    ) async {
      const rootName = 'IELTS Academic Word List';
      final deckName = ('Academic Vocabulary for Reading ' * 4).trim();
      final root = await env.decks.root(rootName, SchedulerType.sm2);
      final leaf = await env.decks.sub(root.id, deckName);
      await insertCard(env.db, id: 'n0', deckId: leaf.id);
      await env.entries.openLearningSession(deckId: leaf.id);
      await pumpLibraryScreen(
        tester,
        env,
        _screen(root.id),
        textScale: textScale,
      );

      final path = find.text(
        breadcrumbLine(_en.studyHomeResumeTitle(rootName, deckName)),
      );
      final text = tester.widget<Text>(path);
      expect((text.maxLines, text.overflow), (2, TextOverflow.ellipsis));
      // The label is a Semantics over the paragraph.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: path, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expectNoLineEndsOn(tester, path, '›');
      expect(tester.takeException(), isNull);
    });
  }

  libraryTest('a session on another root names that deck alone', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final japanese = await env.decks.root('Japanese', SchedulerType.sm2);
    await insertCard(env.db, id: 'k0', deckId: korean.id);
    await insertCard(env.db, id: 'j0', deckId: japanese.id);
    await env.entries.openLearningSession(deckId: korean.id);
    await pumpLibraryScreen(tester, env, _screen(japanese.id));

    expect(find.text('Korean'), findsOneWidget);
    expect(find.textContaining('›'), findsNothing);
    expect(_button(_en.studyEntryContinue), findsOneWidget);
  });
}
