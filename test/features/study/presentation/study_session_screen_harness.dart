import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// What the session screen tests share: the session on a leaf, the screen
// pushed over a page, and the swipe that moves a Browse card on.

final studyEn = lookupAppLocalizations(const Locale('en'));

/// A learning session on a leaf (a root holds no card, BR-DECK-004), on the
/// harness's day.
Future<String> seedSession(LibraryEnv env, List<String> ids) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (final id in ids) {
    await insertCard(
      env.db,
      id: id,
      deckId: leaf.id,
      front: 'front $id',
      back: 'back $id',
    );
  }
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openLearningSession(deckId: leaf.id);
  return (opened as Ok<String, StudyRejection>).value;
}

/// The screen pushed over a page, as the router pushes it, so Back and
/// leaving act on a real route.
Future<void> pumpSessionScreen(
  WidgetTester tester,
  LibraryEnv env,
  String id, {
  ValueChanged<String>? onDone,
  ValueChanged<String>? onStudyDeck,
  ValueChanged<String?>? onLeave,
}) async {
  await pumpLibraryScreen(
    tester,
    env,
    MxAppShell(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StudySessionScreen(
                  sessionId: id,
                  onDone: onDone ?? (_) {},
                  onStudyDeck: onStudyDeck ?? (_) {},
                  onLeave: onLeave ?? (_) {},
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> swipeLeft(WidgetTester tester) async {
  await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
  await tester.pumpAndSettle();
}
