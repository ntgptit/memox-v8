import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import 'library_harness.dart';
import 'topik_screen_fixtures.dart';

/// What screen 36 asked to open, recorded by its callbacks.
final class TopikDetailTaps {
  final attempts = <String>[];
  final summaries = <String>[];
  final reviews = <String>[];
  var backToTests = 0;
}

/// Screen 36 for [test] (or [testId]), reporting into [taps].
Widget topikTestDetailScreen(
  TopikTest test,
  TopikDetailTaps taps, {
  String? testId,
}) => TopikTestDetailScreen(
  testId: testId ?? test.testId,
  onOpenAttempt: taps.attempts.add,
  onOpenSummary: taps.summaries.add,
  onOpenReview: taps.reviews.add,
  onBackToTests: () => taps.backToTests++,
);

/// Screen 36 pumped and settled over a catalog of [test] alone.
Future<void> pumpTopikTestDetail(
  WidgetTester tester,
  LibraryEnv env,
  TopikTest test,
  TopikDetailTaps taps, {
  String? testId,
}) async {
  await pumpLibraryScreen(
    tester,
    env,
    topikTestDetailScreen(test, taps, testId: testId),
    overrides: topikContentOverrides([test]),
  );
  await tester.pumpAndSettle();
}

/// The value of Overall Progress' figure [label] (BR-TOPIK-020).
String topikDetailFigure(WidgetTester tester, String label) => tester
    .widget<MxStatTile>(
      find.byWidgetPredicate((w) => w is MxStatTile && w.label == label),
    )
    .value;
