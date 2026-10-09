import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';

// Screen 17, Match: a tile's tone eases in (Impeccable after P3).

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<String> _match(LibraryEnv env) =>
    openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.match);

void main() {
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
