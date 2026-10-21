import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_resume_widget.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../shared/expect_one_primary.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/text_cut.dart';

// Screen 14 beside the app's open session of another deck: BR-STUDY-072,
// UC-STUDY-001 A3b.

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(
  String deckId, {
  ValueChanged<String>? onOpen,
  VoidCallback? onOpenInLibrary,
}) => StudyEntryScreen(
  deckId: deckId,
  title: const Text('Deck'),
  breadcrumb: const SizedBox.shrink(),
  onOpenSession: onOpen ?? (_) {},
  onOpenInLibrary: onOpenInLibrary,
);

/// A start that runs: every action is locked (BR-STUDY-004).
class _Starting extends StudyEntryController {
  @override
  StudyStartState build(String deckId) =>
      const StudyStartState(status: StudyStartStatus.starting);
}

Finder _button(String label) => find.widgetWithText(MxButton, label);

/// Drags enough to reach the end of the entry at any text scale.
const _maxDrags = 5;

/// The section over the other starts while a session can be continued.
final _otherSession = _en.studyEntryOtherSessionHeader.toUpperCase();

void main() {
  // Owner 2026-10-21: a start anywhere ends the app's open session
  // (BR-STUDY-072), so the entry of another deck shows that session too,
  // names its deck, leads with Continue and says what a start would end.
  // Before, the root's entry read only its own sessions: no banner, a
  // primary Review, and the start ended the sub-deck's session unseen.
  libraryTest('an open session of another deck shows on this entry with its '
      'deck and says what a start would end; Continue takes it up; looking '
      'around ends nothing (BR-STUDY-072)', (tester, env) async {
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

    // The deck alone, its line quiet under it; its location one tap away
    // (owner 2026-10-21, spec §3.3).
    final banner = find.byType(StudyEntryResumeWidget);
    expect(
      find.descendant(of: banner, matching: find.text('Lesson')),
      findsOneWidget,
    );
    expect(find.textContaining('›'), findsNothing);
    expect(find.text('Continue where you stopped.'), findsNothing);
    expect(
      find.descendant(
        of: banner,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is MxTermLine && widget.role == MxTermLineRole.body,
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: banner, matching: find.byType(MxIconButton)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StudyDeckLocationSheetWidget),
        matching: find.text('Korean'),
      ),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(StudyDeckLocationSheetWidget), findsNothing);
    // The overline says it is another deck's (owner 2026-10-21).
    expect(
      find.text(_en.studyEntryResumeOverlineOtherDeck.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_otherSession), findsOneWidget);
    expect(find.text(_en.studyEntryOtherSessionNote), findsOneWidget);
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

  // The name is the user's own text: two lines at most, then an ellipsis,
  // on a 360 dp phone and at a 1.3 text scale.
  for (final textScale in [1.0, 1.3]) {
    libraryTest('a deck name longer than two lines ends in an ellipsis; '
        'nothing overflows (scale $textScale)', (tester, env) async {
      final deckName = ('Academic Vocabulary for Reading ' * 4).trim();
      final root = await env.decks.root('IELTS', SchedulerType.sm2);
      final leaf = await env.decks.sub(root.id, deckName);
      await insertCard(env.db, id: 'n0', deckId: leaf.id);
      await env.entries.openLearningSession(deckId: leaf.id);
      await pumpLibraryScreen(
        tester,
        env,
        _screen(root.id),
        textScale: textScale,
      );

      final name = find.text(deckName);
      final text = tester.widget<Text>(name);
      expect((text.maxLines, text.overflow), (2, TextOverflow.ellipsis));
      expect(
        tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }

  // Two decks of one name: identity is the session id, never the name
  // (owner 2026-10-21, spec D2).
  libraryTest('two decks of one name: Continue opens the session, wherever '
      'its namesake is', (tester, env) async {
    final a = await env.decks.root('Korean', SchedulerType.sm2);
    final aLesson = await env.decks.sub(a.id, 'Lesson');
    final b = await env.decks.root('Japanese', SchedulerType.sm2);
    final bLesson = await env.decks.sub(b.id, 'Lesson');
    await insertCard(env.db, id: 'a0', deckId: aLesson.id);
    await insertCard(env.db, id: 'b0', deckId: bLesson.id);
    final opened = await env.entries.openLearningSession(deckId: aLesson.id);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    String? continued;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(bLesson.id, onOpen: (id) => continued = id),
    );
    await tester.tap(_button(_en.studyEntryContinue));
    await tester.pumpAndSettle();
    expect(continued, sessionId);
  });

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

  // Final review I2: this deck has nothing to do while another deck's
  // session is open. The banner leads with Continue alone, then the
  // nothing-to-do state; no section over starts, since none is offered.
  libraryTest("a caught-up deck beside another deck's session: the banner, "
      'Continue alone, then nothing to study in this deck', (
    tester,
    env,
  ) async {
    final leaf = await sm2Leaf(env.db, env.decks, newCards: 2);
    await env.entries.openLearningSession(deckId: leaf);
    final rest = await env.decks.root('Japanese', SchedulerType.sm2);
    await insertCard(
      env.db,
      id: 'r0',
      deckId: rest.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 12, 1),
    );
    await lockScheduler(env.db, rest.id);
    await pumpLibraryScreen(tester, env, _screen(rest.id));

    expect(find.text('Lesson'), findsOneWidget);
    // The title says it is this deck that has nothing (owner 2026-10-21).
    expect(find.text(_en.studyEntryNothingInDeckTitle), findsOneWidget);
    expect(find.byType(MxButton), findsOneWidget);
    expect(_button(_en.studyEntryContinue), findsOneWidget);
    expect(find.text(_otherSession), findsNothing);
    expectOnePrimaryPerDecision(tester);
  });

  // Owner review 2026-10-21: the footer is the body's neighbour, never over
  // it. With the banner, the section, Learn and the mode list, at a large
  // text scale and in bold, the end of the body scrolls clear of the footer
  // and the footer's start is whole.
  for (final textScale in [1.0, 1.3, 2.0]) {
    libraryTest('scrolled to the end, the last option clears the footer and '
        'the footer is whole (scale $textScale, bold)', (tester, env) async {
      final leaf = await insertFiveDue(env.db, env.decks);
      for (var i = 0; i < 2; i++) {
        await insertCard(env.db, id: 'n$i', deckId: leaf.id);
      }
      final other = await env.decks.root('Japanese');
      await insertCard(env.db, id: 'j0', deckId: other.id);
      await env.entries.openLearningSession(deckId: other.id);
      await pumpLibraryScreen(
        tester,
        env,
        _screen(leaf.id),
        textScale: textScale,
        isBoldText: true,
      );
      // The list builds lazily, so one drag stops at the extent known so
      // far; drag until the end is really reached.
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      for (var drag = 0; drag < _maxDrags; drag++) {
        await tester.drag(scrollable, const Offset(0, -4000));
        await tester.pumpAndSettle();
        if (position.pixels >= position.maxScrollExtent) break;
      }
      expect(position.pixels, position.maxScrollExtent);

      final footer = tester.getRect(find.byType(MxFooterBar));
      final last = tester.getRect(find.byType(MxOptionRow).last);
      expect(last.bottom, lessThanOrEqualTo(footer.top));
      expectNoTextCut(tester, find.byType(MxFooterBar));

      expect(tester.takeException(), isNull);
    });
  }

  // Spec D7, BR-STUDY-004: while a start runs, the empty deck's way to the
  // Library is locked with every other action.
  libraryTest('while a start runs, Open in Library is locked', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _screen(root.id, onOpenInLibrary: () {}),
      overrides: [
        studyEntryControllerProvider(root.id).overrideWith(_Starting.new),
      ],
    );
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.studyEntryOpenInLibrary),
          )
          .onPressed,
      isNull,
    );
  });

  // Spec D7: with no way to the Library wired, the action is not drawn,
  // rather than drawn disabled.
  libraryTest('without onOpenInLibrary the empty deck shows no action', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen(root.id));
    expect(find.text(_en.studyEntryNoCardsTitle), findsOneWidget);
    expect(find.text(_en.studyEntryOpenInLibrary), findsNothing);
  });
}
