import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_tab_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// M3F-19: the tabs, the search field and the note sit on the screen margin,
// as the app bar and the filter chips beside them.

Future<void> _widen(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  await tester.pump();
}

void main() {
  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    libraryTest(
      'the tabs are bounded and the search field starts and ends on the $margin '
      'screen margin at ${width.toInt()} wide',
      (tester, env) async {
        final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
        await pumpMonitoring(tester, env, repository);
        await _widen(tester, width);

        // The tray is centred at its own width: the gutter bounds it.
        final tray = tester
            .widget<Padding>(
              find
                  .ancestor(
                    of: find.byType(MxSegmentedTray<MonitoringTab>),
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect((tray.left, tray.right), (margin, margin));
        final field = tester.getRect(find.byType(MxSearchField));
        expect((field.left, width - field.right), (margin, margin));
      },
    );

    libraryTest('the Not sent note starts on the $margin screen margin at '
        '${width.toInt()} wide', (tester, env) async {
      final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
      await pumpMonitoring(tester, env, repository);
      repository.watches.single.feed.add(
        PendingLogs(items: [summary('p1', status: null)], total: 1),
      );
      await settleMonitoring(tester);
      await tester.tap(find.text('Not sent (1)'));
      await tester.pumpAndSettle();
      await _widen(tester, width);

      expect(tester.getTopLeft(find.byType(MxNote)).dx, margin);
    });
  }
}
