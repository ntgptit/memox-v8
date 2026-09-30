import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2: the Not sent tab, and the tabs together.
void main() {
  libraryTest('the Not sent tab shows the count, the note and the rows', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    String? opened;
    await pumpMonitoring(
      tester,
      env,
      repository,
      onOpenPendingLog: (id) => opened = id,
    );
    repository.watches.single.feed.add(
      PendingLogs(
        items: [
          summary('p1', status: null, event: 'sync.failed'),
          summary('p2', status: null, level: LogLevel.warning),
        ],
        total: 12,
      ),
    );
    await settleMonitoring(tester);

    expect(find.text('Not sent (12)'), findsOneWidget);
    await tester.tap(find.text('Not sent (12)'));
    await tester.pumpAndSettle();

    // The tab states the buffer's count; the list counts what it shows
    // (critique 2026-09-30 part 3b).
    expect(
      find.text(
        'These logs wait on this device. They are sent when MemoX is online.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('12 logs'), findsNothing);
    expect(find.text('2 AT THESE LEVELS'), findsOneWidget);
    // A row keeps an invisible pill for the time column's height (F5).
    final shown = find
        .byType(MxBadge)
        .evaluate()
        .where(
          (badge) =>
              badge.findAncestorWidgetOfExactType<Visibility>()?.visible !=
              false,
        );
    expect(shown, isEmpty, reason: 'no status');
    await tester.tap(find.text('sync.failed'));
    expect(opened, 'p1');
  });

  libraryTest('Not sent works while the server tab is offline', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    repository.watches.single.feed.add(
      PendingLogs(items: [summary('p1', status: null)], total: 1),
    );
    await settleMonitoring(tester);

    await tester.tap(find.text('Not sent (1)'));
    await tester.pumpAndSettle();

    expect(find.text('sync.push_failed'), findsOneWidget);
  });

  libraryTest('Not sent has words for an empty buffer and for a level with '
      'no row', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);
    await openNotSentTab(tester);
    repository.watches.single.feed.add(const PendingLogs(items: [], total: 0));
    await settleMonitoring(tester);
    expect(find.text('Nothing waiting'), findsOneWidget);

    repository.watches.single.feed.add(const PendingLogs(items: [], total: 4));
    await settleMonitoring(tester);
    expect(find.text('No logs at these levels'), findsOneWidget);
  });

  libraryTest('switching tabs keeps the pages of the server tab', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(3);
    await pumpMonitoring(tester, env, repository);
    repository.watches.single.feed.add(const PendingLogs(items: [], total: 0));
    await settleMonitoring(tester);

    await tester.tap(find.textContaining('Not sent ('));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(1));
    expect(find.text('3 OPEN'), findsOneWidget);
  });

  // Review focus: large text scale on a row with a long event name.
}
