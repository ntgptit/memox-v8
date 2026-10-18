import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

import '../../../support/choice_focus_ring.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import 'support/study_screen_helpers.dart';

// DEV-391: Tab reaches a Match tile and a Guess option, and the theme's focus
// ring, drawn outside the tile, is neither cut by the layout nor drawn over
// the tile's own fill.

void main() {
  for (final brightness in Brightness.values) {
    libraryTest('Match: Tab gives each of the ten tiles a whole ring '
        '(${brightness.name})', (tester, env) async {
      final id = await openFiveDueReview(
        env.db,
        env.decks,
        libraryToday,
        StudyMode.match,
      );
      await pumpLibraryScreen(
        tester,
        env,
        studySessionScreen(id),
        brightness: brightness,
      );

      final rings = await tabThroughChoiceTiles(tester, count: 10);

      for (final ring in rings) {
        expect(ring.tone, MxChoiceTone.idle);
        expectRingVisible(tester, ring);
      }
    });

    libraryTest('Guess: Tab gives each of the five options a whole ring '
        '(${brightness.name})', (tester, env) async {
      final id = await openFiveDueReview(
        env.db,
        env.decks,
        libraryToday,
        StudyMode.guess,
      );
      await pumpLibraryScreen(
        tester,
        env,
        studySessionScreen(id),
        brightness: brightness,
      );

      final rings = await tabThroughChoiceTiles(tester, count: 5);

      for (final ring in rings) {
        expectRingVisible(tester, ring);
      }
    });
  }
}
