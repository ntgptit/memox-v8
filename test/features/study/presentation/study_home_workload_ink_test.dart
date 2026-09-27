import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_workload_widget.dart';

import '../../../support/library_harness.dart';

// The hero's "waiting" glyph is ink, so it reads in primaryInk on the hero
// ground (spec 2026-09-27 D2).
void main() {
  libraryTest('the waiting glyph is primaryInk (dark)', (tester, env) async {
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
      MxDerivedColors.primaryInkOf(AppColorSchemes.dark),
    );
  });
}
