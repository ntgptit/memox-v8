import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_fill_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_guess_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_match_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_recall_widget.dart';

import 'content_steps.dart';
import 'device_app.dart';

// Study steps through the UI (FE-D3 spec D9): the SETUP-STUDY-EB-5-FULL
// fixture and one right answer in whichever mode the session shows. The
// finders mirror study_{browse,match,guess,recall,fill}_test.dart.

/// SETUP-STUDY-EB-5-FULL (docs/shared/testing/agent-execution-guide.md):
/// front → (back, example).
const studyCards = {
  '사과': ('apple', 'I eat an apple.'),
  '물': ('water', 'Drink water.'),
  '책': ('book', 'This is a book.'),
  '산': ('mountain', 'The mountain is high.'),
  '바다': ('sea', 'The sea is calm.'),
};

const studyRoot = 'Korean';
const studyLeaf = 'Chapter 1';

/// Korean (Eight boxes) › Chapter 1 with ST-01…ST-05, from the Library root.
Future<void> seedStudyDeck(WidgetTester tester) async {
  await createRootDeck(tester, studyRoot);
  await openDeck(tester, studyRoot);
  await createSubDeck(tester, studyLeaf);
  await openDeck(tester, studyLeaf);
  for (final MapEntry(key: front, value: (back, example))
      in studyCards.entries) {
    await createCard(tester, front, back, example: example);
  }
  await goToLibraryRoot(tester);
}

/// The Study tab, then the entry of the deck [name].
Future<void> openStudyEntry(WidgetTester tester, String name) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.navStudy).last);
  await tester.pump(const Duration(milliseconds: 500));
  await tapText(tester, name);
}

/// From the Library root: the deck [name]'s "Study this deck".
Future<void> studyFromLibrary(WidgetTester tester, String name) async {
  await openDeck(tester, name);
  await tapText(tester, l10nOf(tester).studyThisDeck);
}

/// The entry's Learn button, for the fixture's five new cards.
Future<void> startLearning(WidgetTester tester) async {
  await tapText(tester, l10nOf(tester).studyEntryLearnCta(studyCards.length));
  await _waitForTurn(tester);
}

final _modes = <Type, String>{
  StudyBrowseWidget: 'browse',
  StudyMatchWidget: 'match',
  StudyGuessWidget: 'guess',
  StudyRecallWidget: 'recall',
  StudyFillWidget: 'fill',
};

/// The mode on screen, or null between turns.
String? modeOnScreen() {
  for (final MapEntry(key: type, value: name) in _modes.entries) {
    if (find.byType(type).evaluate().isNotEmpty) return name;
  }
  return null;
}

Future<void> _waitForTurn(WidgetTester tester) =>
    waitUntil(tester, () => modeOnScreen() != null, 'a study turn shows');

/// The fixture texts inside the mode on screen, in fixture order.
List<String> _shown(Type mode) => [
  for (final MapEntry(key: front, value: (back, _)) in studyCards.entries)
    for (final text in [front, back])
      if (find
          .descendant(of: find.byType(mode), matching: find.text(text))
          .evaluate()
          .isNotEmpty)
        text,
];

Type _typeOf(String mode) =>
    _modes.entries.firstWhere((entry) => entry.value == mode).key;

/// Where the session stands: the mode, the fixture texts it shows, and the
/// "current / total" counter (IT-PLAT-003).
String sessionCheckpoint(WidgetTester tester) {
  final mode = modeOnScreen() ?? 'none';
  final counter = find
      .byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            RegExp(r'^\d+ / \d+$').hasMatch(widget.text.toPlainText()),
      )
      .evaluate()
      .map((element) => (element.widget as RichText).text.toPlainText())
      .join();
  final shown = mode == 'none' ? const <String>[] : _shown(_typeOf(mode));
  return [mode, shown.join(','), counter].join('|');
}

Future<void> _tapIn(WidgetTester tester, Type mode, String text) async {
  final target = find.descendant(
    of: find.byType(mode),
    matching: find.text(text),
  );
  await waitFor(tester, target, timeout: const Duration(seconds: 5));
  await tester.tap(target.first);
  await tester.pump(const Duration(milliseconds: 400));
}

String _backOf(String front) => studyCards[front]!.$1;

String _frontOf(String back) =>
    studyCards.entries.firstWhere((entry) => entry.value.$1 == back).key;

/// One right answer in the mode on screen, then waits for what comes next:
/// another turn, or the end of the session.
Future<void> answerTurn(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  final mode = modeOnScreen();
  final before = sessionCheckpoint(tester);
  switch (mode) {
    case 'browse':
      await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
      await tester.pump(const Duration(milliseconds: 600));
    case 'match':
      // One board holds every pair: match each front shown with its back.
      for (final front in studyCards.keys) {
        final onBoard = find.descendant(
          of: find.byType(StudyMatchWidget),
          matching: find.text(front),
        );
        if (onBoard.evaluate().isEmpty) continue;
        await _tapIn(tester, StudyMatchWidget, front);
        await _tapIn(tester, StudyMatchWidget, _backOf(front));
      }
    case 'guess':
      final front = _shown(StudyGuessWidget).firstWhere(studyCards.containsKey);
      await _tapIn(tester, StudyGuessWidget, _backOf(front));
    case 'recall':
      await tester.tap(find.text(l10n.studyRecallShowMeaning));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(l10n.studyRecallRemembered));
      await tester.pump(const Duration(milliseconds: 400));
    case 'fill':
      final back = _shown(StudyFillWidget)
          .firstWhere((text) => !studyCards.containsKey(text));
      await tester.enterText(
        find.descendant(
          of: find.byType(StudyFillWidget),
          matching: find.byType(EditableText),
        ),
        _frontOf(back),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(l10n.studyFillCheck));
      await tester.pump(const Duration(milliseconds: 400));
    default:
      throw TestFailure('No study turn on screen');
  }
  // A right answer moves on by itself; Next or Continue, if one shows.
  for (final label in [l10n.studyGuessNext, l10n.studyContinue]) {
    if (find.text(label).evaluate().isNotEmpty) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
  await waitUntil(
    tester,
    () =>
        isSessionOver(tester) ||
        (modeOnScreen() != null && sessionCheckpoint(tester) != before),
    'the session moves past $before',
  );
}

/// Whether the session's summary shows (finished or left early).
bool isSessionOver(WidgetTester tester) =>
    find.byType(SessionSummaryWidget).evaluate().isNotEmpty;

/// Signals the script for a real system Back, then waits for [expected].
Future<void> pressSystemBack(WidgetTester tester, Finder expected) async {
  signal('back');
  await waitFor(tester, expected);
}
