@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

const _trace = '''
#0      SyncCoordinator.runOnce (package:memox/core/sync/sync_coordinator.dart:42:7)
<asynchronous suspension>
#1      SyncScheduler._run (package:memox/core/sync/sync_scheduler.dart:88:11)
<asynchronous suspension>
#2      SyncScheduler.start.<anonymous closure> (package:memox/core/sync/sync_scheduler.dart:61:5)''';

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
      bool isLocal = false,
      bool isScrolled = false,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          MonitoringDetailScreen(logId: 'a', isLocal: isLocal),
          brightness,
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await _settle(tester);
        if (isScrolled) {
          await tester.fling(
            find.byType(ListView),
            const Offset(0, -3000),
            6000,
          );
          await _settle(tester);
        }
        await expectBoundaryGolden(
          tester,
          'goldens/monitoring_detail_${state}_$theme.png',
        );
      });
    }

    libraryTest('monitoring detail, open error, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'open',
        FakeMonitoringRepository()
          ..servers['a'] = record('a', stackTrace: _trace),
      );
    });

    libraryTest('monitoring detail, open error, trace, $theme', (
      tester,
      env,
    ) async {
      await golden(
        tester,
        env,
        'open_trace',
        FakeMonitoringRepository()
          ..servers['a'] = record('a', stackTrace: _trace),
        isScrolled: true,
      );
    });

    libraryTest('monitoring detail, fixed error with note, $theme', (
      tester,
      env,
    ) async {
      await golden(
        tester,
        env,
        'fixed',
        FakeMonitoringRepository()
          ..servers['a'] = record(
            'a',
            stackTrace: _trace,
            status: LogStatus.fixed,
            statusNote: 'Added an index on card.deck_id',
            statusChangedBy: '00000000-0000-0000-0000-0000000000ad',
            statusChangedAt: DateTime.utc(2026, 9, 27, 9, 30, 5),
          ),
        isScrolled: true,
      );
    });

    libraryTest('monitoring detail, local row, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'local',
        FakeMonitoringRepository()
          ..pendings['a'] = record(
            'a',
            status: null,
            stackTrace: _trace,
            userId: null,
          ),
        isLocal: true,
      );
    });
  }
}
