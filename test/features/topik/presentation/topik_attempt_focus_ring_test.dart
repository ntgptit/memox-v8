import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

import '../../../support/choice_focus_ring.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';

// DEV-391, screen 37: Tab reaches a TOPIK option, and the theme's focus ring,
// drawn outside the tile, is neither cut by the layout nor drawn over the
// tile's own fill, picked or not.

void main() {
  final reading = topikTestFixture();

  for (final brightness in Brightness.values) {
    libraryTest('Tab gives each of the four options a whole ring, picked or '
        'not (${brightness.name})', (tester, env) async {
      final attempt = await topikSeedAttempt(env, reading, answers: {1: 2});
      await pumpTopikAttempt(
        tester,
        env,
        attempt.id,
        catalog: [reading],
        brightness: brightness,
      );

      final rings = await tabThroughChoiceTiles(tester, count: 4);

      expect(
        rings.map((ring) => ring.tone),
        containsAll([MxChoiceTone.idle, MxChoiceTone.selected]),
      );
      for (final ring in rings) {
        expectRingVisible(tester, ring);
      }
    });
  }
}
