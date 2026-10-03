@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

final _screen = MonitoringScreen(
  onOpenServerLog: (_) {},
  onOpenPendingLog: (_) {},
);

/// Open warnings and errors over today and the day before: what the
/// default filter returns.
LogPage _openPage() => LogPage(
  items: [
    summary(
      'a',
      event: 'sync.push_failed',
      message: 'The server refused the push\nsecond line',
      at: libraryToday.subtract(const Duration(minutes: 12)),
    ),
    summary(
      'b',
      level: LogLevel.warning,
      event: 'db.slow_query',
      message: 'SELECT * FROM card WHERE deck_id = ? ORDER BY created_at',
      at: libraryToday.subtract(const Duration(hours: 3)),
    ),
    summary(
      'c',
      event: 'ui.uncaught',
      message: null,
      errorType: 'StateError',
      at: DateTime(2026, 9, 23, 18, 40),
    ),
  ],
);

/// Every level and both statuses: what the filter returns once widened.
LogPage _allPage() => LogPage(
  items: [
    ..._openPage().items,
    summary(
      'd',
      event: 'sync.rejected',
      message: 'deck 3f2a refused: CONFLICT',
      status: LogStatus.fixed,
      at: DateTime(2026, 9, 22, 21, 15),
    ),
    summary(
      'e',
      level: LogLevel.info,
      status: null,
      event: 'sync.pull',
      message: '12 changes in 340 ms',
      at: DateTime(2026, 9, 22, 8, 5),
    ),
    summary(
      'f',
      level: LogLevel.debug,
      status: null,
      event: 'db.query',
      message: 'SELECT 1',
      at: DateTime(2026, 9, 20, 22, 5),
    ),
  ],
);

/// What the device has not sent yet: no row has a status.
List<LogSummaryEntity> _pending() => [
  summary(
    'p1',
    event: 'sync.failed',
    message: 'No connection',
    status: null,
    at: libraryToday.subtract(const Duration(minutes: 2)),
  ),
  summary(
    'p2',
    level: LogLevel.warning,
    event: 'db.slow_query',
    message: 'SELECT * FROM card WHERE deck_id = ?',
    status: null,
    at: libraryToday.subtract(const Duration(minutes: 40)),
  ),
  // Every row is at the default levels, as the list's header counts them
  // (critique 2026-09-30 part 3b).
  summary(
    'p3',
    level: LogLevel.error,
    event: 'sync.pull_failed',
    message: 'Server error',
    status: null,
    at: libraryToday.subtract(const Duration(hours: 2)),
  ),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> golden(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      FakeMonitoringRepository repository, {
      Future<void> Function()? act,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await act?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/monitoring_${state}_$theme.png',
        );
      });
    }

    libraryTest('monitoring, list loaded, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_loaded',
        FakeMonitoringRepository()..autoPage = _openPage(),
      );
    });

    libraryTest('monitoring, list all levels, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_all_levels',
        FakeMonitoringRepository()..autoPage = _allPage(),
        act: () async {
          ProviderScope.containerOf(
                tester.element(find.byType(MonitoringScreen)),
              )
              .read(monitoringListControllerProvider.notifier)
              .setFilter(const LogFilter().withLevels({}).withStatuses({}));
          await _settle(tester);
        },
      );
    });

    libraryTest('monitoring, list empty, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_empty',
        FakeMonitoringRepository()..autoPage = pageOf(0),
      );
    });

    libraryTest('monitoring, list offline, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository();
      await golden(
        tester,
        env,
        'list_offline',
        repository,
        act: () async {
          repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
          await _settle(tester);
        },
      );
    });

    // SP2b 2.38: a pull to refresh failed; the rows stay under a warning.
    libraryTest('monitoring, list refresh failed, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository();
      await golden(
        tester,
        env,
        'list_refresh_failed',
        repository,
        act: () async {
          repository.lastQuery.answer(_openPage());
          await _settle(tester);
          unawaited(
            ProviderScope.containerOf(
              tester.element(find.byType(MonitoringScreen)),
            ).read(monitoringListControllerProvider.notifier).refresh(),
          );
          await tester.pump();
          repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
          await _settle(tester);
          expect(
            find.textContaining("Couldn't refresh the list"),
            findsOneWidget,
          );
        },
      );
    });

    libraryTest('monitoring, not sent, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository()..autoPage = _openPage();
      await golden(
        tester,
        env,
        'not_sent',
        repository,
        act: () async {
          repository.watches.single.feed.add(
            PendingLogs(items: _pending(), total: 27),
          );
          await _settle(tester);
          await tester.tap(find.textContaining('Not sent ('));
          await _settle(tester);
          // Lets the tap's ink ripple fade out of the picture (F4).
          await tester.pump(const Duration(seconds: 2));
        },
      );
    });

    libraryTest('monitoring, level sheet, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'level_sheet',
        FakeMonitoringRepository()..autoPage = _openPage(),
        act: () async {
          await tester.tap(
            find.descendant(
              of: find.byType(MxChipTrigger),
              matching: find.textContaining('Level'),
            ),
          );
          await _settle(tester);
        },
      );
    });
  }
}
