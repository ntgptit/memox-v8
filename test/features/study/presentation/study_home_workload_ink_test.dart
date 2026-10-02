import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';

import '../../../support/library_harness.dart';

// The "waiting" glyph follows its eyebrow in onSurfaceVariant; it no longer
// borrows the Required ink (critique 2026-09-30 part 2, P2).
void main() {
  libraryTest('the waiting glyph is the eyebrow ink (dark)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: StudyHomeWorkloadWidget(
          workload: const RootDeckWorkload(
            decks: [
              StudyHomeDeck(
                deckId: 'd1',
                name: 'Verbs',
                schedulerType: SchedulerType.eightBox,
                cardCount: 4,
                overdueCount: 0,
                dueTodayCount: 2,
                newCount: 0,
              ),
            ],
            nextDueAt: null,
          ),
          now: DateTime.utc(2026, 9, 27),
        ),
      ),
      brightness: Brightness.dark,
    );

    final glyph = find.byIcon(AppIcons.dueNow).first;
    expect(
      IconTheme.of(tester.element(glyph)).color,
      AppColorSchemes.dark.onSurfaceVariant,
    );
  });
}
