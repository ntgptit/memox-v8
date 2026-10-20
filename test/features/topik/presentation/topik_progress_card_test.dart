import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_progress_card_widget.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/relative_time.dart';

import '../../../support/library_harness.dart';
import '../../../support/term_line.dart';

// Screen 36's Overall Progress (BR-TOPIK-020): a figure with no value shows a
// dash and says what it means to TalkBack (owner, Q-P6-5).
void main() {
  Future<void> host(
    WidgetTester tester,
    LibraryEnv env,
    TopikTestProgress progress,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: SingleChildScrollView(
          child: TopikProgressCardWidget(
            progress: progress,
            now: DateTime.utc(2026, 10, 16),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SemanticsNode tile(WidgetTester tester, String label) => tester.getSemantics(
    find.byWidgetPredicate((w) => w is MxStatTile && w.label == label),
  );

  libraryTest('before any submitted attempt, accuracy, best and average show '
      'a dash and read "None yet"', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikTestProgress(
        sessions: 1,
        completed: 0,
        completionPercent: 0,
        accuracyPercent: null,
        bestScore: null,
        averageScore: null,
        lastActivityAt: DateTime.utc(2026, 10, 15),
        totalTimeMs: 60000,
      ),
    );

    expect(find.text('–'), findsNWidgets(3));
    for (final label in ['Accuracy', 'Best', 'Average']) {
      expect(
        tile(tester, label),
        matchesSemantics(label: label, value: 'None yet'),
        reason: label,
      );
    }
    handle.dispose();
  });

  libraryTest('a figure with a value reads that value', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikTestProgress(
        sessions: 2,
        completed: 1,
        completionPercent: 50,
        accuracyPercent: 80,
        bestScore: 72,
        averageScore: 72,
        lastActivityAt: DateTime.utc(2026, 10, 15),
        totalTimeMs: 60000,
      ),
    );

    expect(tile(tester, 'Best'), matchesSemantics(label: 'Best', value: '72'));
    // BR-TOPIK-020: Sessions, Completed and Completion each have a figure.
    expect(
      tile(tester, 'Sessions'),
      matchesSemantics(label: 'Sessions', value: '2'),
    );
    expect(
      tile(tester, 'Completed'),
      matchesSemantics(label: 'Completed', value: '1'),
    );
    expect(
      tile(tester, 'Completion'),
      matchesSemantics(label: 'Completion', value: '50%'),
    );
    // Short terms: the line breaks only between them (The Wrap Rule).
    final en = lookupAppLocalizations(const Locale('en'));
    expectTermLineRule(
      tester,
      findTermLine(
        en.topikLastActivity(
          en.ago(DateTime.utc(2026, 10, 15), DateTime.utc(2026, 10, 16)),
          en.duration(60000),
        ),
      ),
    );
    handle.dispose();
  });
}
