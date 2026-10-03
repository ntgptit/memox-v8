import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2, §3.4, §5: the Server tab.
MxInlineBanner _banner(WidgetTester tester) =>
    tester.widget<MxInlineBanner>(find.byType(MxInlineBanner).first);

/// The status pills a row shows; a row without one keeps an invisible pill
/// for the time column's height (F5).
List<Element> _shownBadges() => find
    .byType(MxBadge)
    .evaluate()
    .where(
      (badge) =>
          badge.findAncestorWidgetOfExactType<Visibility>()?.visible != false,
    )
    .toList();

void main() {
  libraryTest('it opens on open warnings and errors, with their count', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', event: 'sync.push_failed'),
          summary('b', level: LogLevel.warning, event: 'db.slow_query'),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    // The chip names the filter; the header counts logs (critique
    // 2026-09-30 part 3d-2, E11).
    expect(find.text('2 LOGS'), findsOneWidget);
    expect(find.text('sync.push_failed'), findsOneWidget);
    expect(find.text('db.slow_query'), findsOneWidget);
    expect(find.text('message of a'), findsOneWidget);
    // The chip and the header say Open: rows do not repeat it (critique
    // 2026-09-30 part 3b).
    expect(_shownBadges(), isEmpty);
    expect(repository.lastQuery.filter.isDefault, isTrue);
  });

  libraryTest('with both statuses chosen, each row says which it is', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', event: 'sync.push_failed'),
          summary('b', level: LogLevel.warning, event: 'db.slow_query'),
        ],
      );
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Status');
    await tester.tap(find.byType(MxToggle).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(_shownBadges(), hasLength(2));
  });

  libraryTest('a row reads as level, event, time and status', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a', event: 'sync.push_failed')]);
    final semantics = tester.ensureSemantics();

    await pumpMonitoring(tester, env, repository);

    expect(
      find.bySemanticsLabel(RegExp('Error, sync.push_failed, .*, Open')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  libraryTest('the time is HH:mm today and a short date before', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('today', at: libraryToday.subtract(const Duration(hours: 1))),
          summary('older', at: DateTime(2026, 9, 20, 22, 5)),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Sep 20'), findsOneWidget);
  });

  libraryTest('a tap on a row opens its detail', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a')]);
    String? opened;

    await pumpMonitoring(
      tester,
      env,
      repository,
      onOpenServerLog: (id) => opened = id,
    );
    await tester.tap(find.byType(MxListRow));

    expect(opened, 'a');
  });

  libraryTest('while the first page loads the list is a skeleton', (
    tester,
    env,
  ) async {
    await pumpMonitoring(tester, env, FakeMonitoringRepository());

    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('no open problems is a calm empty state', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(0);

    await pumpMonitoring(tester, env, repository);

    expect(find.text('No open problems'), findsOneWidget);
    expect(find.text('Warnings and errors will show here.'), findsOneWidget);
  });

  libraryTest('another filter with no match offers to clear the filters', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(0);
    await pumpMonitoring(tester, env, repository);
    await tester.enterText(find.byType(TextField).first, 'nothing');
    await tester.pump(const Duration(milliseconds: 400));
    await settleMonitoring(tester);

    expect(find.text('Nothing matches'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settleMonitoring(tester);

    expect(find.text('No open problems'), findsOneWidget);
    expect(repository.lastQuery.filter.isDefault, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });

  libraryTest('offline says so and points at Not sent, with a Retry', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text("Can't reach the server"), findsOneWidget);
    expect(find.textContaining('under Not sent'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await settleMonitoring(tester);
    expect(repository.queries, hasLength(2));
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await settleMonitoring(tester);

    await tester.tap(find.widgetWithText(MxButton, 'Not sent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('another failure is a local-first error with a Retry', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const ServerFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text("Couldn't load logs"), findsOneWidget);
    expect(
      find.text('Nothing was lost. Try again in a moment.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await settleMonitoring(tester);
    repository.lastQuery.answer(pageOf(1));
    await settleMonitoring(tester);

    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text('r0'), findsNothing);
    expect(find.text('sync.push_failed'), findsOneWidget);
  });

  libraryTest('FORBIDDEN says only an admin can see this', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const NotAdminFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text('Only an admin can see this'), findsOneWidget);
    // Impeccable 2026-09-29 F7: nothing to search or filter on this page.
    expect(find.byType(MxSearchField), findsNothing);
    expect(find.byType(MxChipTrigger), findsNothing);
  });

  libraryTest('the next page loads near the end, and the end says so', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);
    expect(find.text('100+ LOGS'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pump();
    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after!.id, 'r99');
    repository.lastQuery.answer(pageOf(3, prefix: 'p'));
    await settleMonitoring(tester);
    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pumpAndSettle();

    expect(find.text('No more logs'), findsOneWidget);
    expect(repository.queries, hasLength(2));
    await tester.fling(find.byType(ListView), const Offset(0, 20000), 8000);
    await tester.pumpAndSettle();
    expect(find.text('103 LOGS'), findsOneWidget);
  });

  libraryTest('a full first page on a screen taller than its rows asks for '
      'the next one after layout (2.48)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    // 100 rows of 48 are shorter than this viewport: nothing can scroll.
    tester.view.physicalSize = const Size(360, 20000);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);
    await tester.pump();

    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after!.id, 'r99');
  });

  libraryTest('a failed page keeps the rows and offers Retry, not a loop', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pump();
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load more logs."), findsOneWidget);
    expect(repository.queries, hasLength(2), reason: 'no retry loop');
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.queries, hasLength(3));
  });

  libraryTest('pull to refresh asks the first page again', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(2);
    await pumpMonitoring(tester, env, repository);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after, isNull);
  });

  libraryTest('a pull to refresh that fails offline keeps the rows under a '
      'warning with Retry; Retry is busy until the answer lands '
      '(SP2b 2.38, audit M1, m7)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.queries, hasLength(2));
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await tester.pumpAndSettle();

    const warning =
        "Nothing was lost. Couldn't refresh the list. The rows below are from the last time it loaded.";
    expect(find.text(warning), findsOneWidget);
    expect(_banner(tester).tone, MxBannerTone.warning);
    expect(find.text('2 LOGS'), findsOneWidget);
    expect(find.text('message of r0'), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.queries, hasLength(3));
    expect(find.text(warning), findsOneWidget, reason: 'stays while it runs');
    expect(
      tester
          .widget<MxButton>(
            find.descendant(
              of: find.byType(MxInlineBanner),
              matching: find.byType(MxButton),
            ),
          )
          .isLoading,
      isTrue,
    );
    repository.lastQuery.answer(pageOf(1, prefix: 'n'));
    await tester.pumpAndSettle();
    expect(find.text('message of n0'), findsOneWidget);
    expect(find.text(warning), findsNothing);
  });

  libraryTest('a lost admin role on refresh replaces the rows (SP2b 2.38)', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    repository.lastQuery.fail(const NotAdminFailure(cause: 'x'));
    await tester.pumpAndSettle();

    expect(find.text('Only an admin can see this'), findsOneWidget);
    expect(find.text('message of r0'), findsNothing);
  });

  libraryTest('the search asks once the field has been still for 400 ms', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tester.enterText(find.byType(TextField).first, 'push');
    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.queries, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));

    expect(repository.lastQuery.filter.search, 'push');
  });

  libraryTest('an info row has no status and a debug row its own glyph', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', level: LogLevel.info, status: null),
          summary('b', level: LogLevel.debug, status: null),
          summary('c', status: LogStatus.fixed),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    expect(find.widgetWithText(MxBadge, 'Fixed'), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  // Impeccable 2026-09-29 F5: the time column reads at one height.
  libraryTest('a row sets its time at the same height with or without a '
      'status', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', level: LogLevel.info, status: null, event: 'a.event'),
          summary('b', event: 'b.event'),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    double timeBelowTitle(String event) {
      final row = find.ancestor(
        of: find.text(event),
        matching: find.byType(MxListRow),
      );
      final time = find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(r'^(\d\d:\d\d|[A-Z][a-z]{2} \d{1,2})$')
                  .hasMatch(widget.data ?? ''),
        ),
      );
      return tester.getTopLeft(time).dy -
          tester.getTopLeft(find.text(event)).dy;
    }

    expect(timeBelowTitle('a.event'), timeBelowTitle('b.event'));
  });
}
