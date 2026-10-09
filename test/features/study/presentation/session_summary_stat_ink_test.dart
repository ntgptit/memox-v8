import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// DEV-359: the hero's stats read on the container they sit on (spec 4.6), at
// the text floor of 4.5:1 in both themes.

const double _textFloor = 4.5;

const _learned = SessionSummary(
  cardCount: 20,
  learnedCardCount: 15,
  wrongTurnCount: 3,
  answeredCardCount: 20,
  turnCount: 23,
  cardLimit: 50,
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome,
  Brightness brightness,
) => pumpLibraryScreen(
  tester,
  env,
  brightness: brightness,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: () {},
    onStudyDeck: () {},
  ),
);

/// The colours a tile paints its value and its label in, and its ground.
({Color value, Color label, Color ground}) _read(
  WidgetTester tester,
  Finder tile,
) {
  final texts = tester
      .widgetList<Text>(find.descendant(of: tile, matching: find.byType(Text)))
      .toList();
  final ground = tester.widget<Material>(
    find.ancestor(of: tile, matching: find.byType(Material)).first,
  );
  return (
    value: texts[0].style!.color!,
    label: texts[1].style!.color!,
    ground: ground.color!,
  );
}

void main() {
  for (final brightness in Brightness.values) {
    final scheme = brightness == Brightness.light
        ? AppColorSchemes.light
        : AppColorSchemes.dark;
    final semantic = brightness == Brightness.light
        ? MxSemanticColors.light
        : MxSemanticColors.dark;

    libraryTest('success tone, ${brightness.name}: both stats read in the '
        'on-container, at 4.5:1 or more on the container', (tester, env) async {
      await _pump(
        tester,
        env,
        summaryView(kind: SessionKind.learning, summary: _learned),
        SummaryOutcome.learningFinished,
        brightness,
      );

      final tiles = find.byType(MxStatTile);
      expect(tiles, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final read = _read(tester, tiles.at(i));
        expect(read.ground, semantic.successContainer);
        expect(read.value, semantic.onSuccessContainer);
        expect(read.label, semantic.onSuccessContainer);
        expect(
          _contrast(read.value, read.ground),
          greaterThanOrEqualTo(_textFloor),
        );
        expect(
          _contrast(read.label, read.ground),
          greaterThanOrEqualTo(_textFloor),
        );
      }
    });

    libraryTest('paused tone, ${brightness.name}: the plain card keeps the '
        'neutral roles', (tester, env) async {
      await _pump(
        tester,
        env,
        summaryView(kind: SessionKind.learning, summary: _learned),
        SummaryOutcome.interrupted,
        brightness,
      );

      final tiles = find.byType(MxStatTile);
      expect(tiles, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        final read = _read(tester, tiles.at(i));
        expect(read.value, scheme.onSurface);
        expect(read.label, scheme.onSurfaceVariant);
        expect(
          _contrast(read.value, read.ground),
          greaterThanOrEqualTo(_textFloor),
        );
        expect(
          _contrast(read.label, read.ground),
          greaterThanOrEqualTo(_textFloor),
        );
      }
    });

    // The ended and error tones draw no stats (drawsStats), so no tile of
    // theirs can sit on a warning or error container.
    libraryTest('ended and error tones, ${brightness.name}: no stat tile', (
      tester,
      env,
    ) async {
      for (final outcome in [
        SummaryOutcome.reset,
        SummaryOutcome.contentDeleted,
        SummaryOutcome.saveError,
      ]) {
        await _pump(
          tester,
          env,
          summaryView(summary: _learned),
          outcome,
          brightness,
        );
        expect(find.byType(MxStatTile), findsNothing, reason: outcome.name);
      }
    });
  }
}
