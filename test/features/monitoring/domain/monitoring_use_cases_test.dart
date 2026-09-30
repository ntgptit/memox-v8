import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/usecases/get_pending_log_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/get_server_log_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/query_server_logs_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/set_log_status_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/monitoring_fakes.dart';

// ADR-011 D4: one use case per interaction of the Monitoring screens.
void main() {
  late FakeMonitoringRepository repository;

  setUp(() => repository = FakeMonitoringRepository());

  test('the query asks the repository at the clock\'s now', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 29, 9));
    final page = QueryServerLogsUseCase(repository, clock)(const LogFilter());

    expect(repository.lastQuery.after, isNull);
    expect(repository.lastQuery.now, DateTime(2026, 9, 29, 9));
    repository.lastQuery.answer(pageOf(2));
    expect((await page).items, hasLength(2));
  });

  test(
    'a server log that exists is Ok, one that is gone is notFound',
    () async {
      repository.servers['a'] = record('a');
      final get = GetServerLogUseCase(repository);

      expect((await get('a') as Ok).value.id, 'a');
      expect(
        (await get('gone') as Rejected).reason,
        MonitoringRejection.notFound,
      );
    },
  );

  test('a buffered log that was sent meanwhile is notFound', () async {
    repository.pendings['a'] = record('a', status: null);
    final get = GetPendingLogUseCase(repository);

    expect((await get('a') as Ok).value.id, 'a');
    expect(
      (await get('sent') as Rejected).reason,
      MonitoringRejection.notFound,
    );
  });

  test('an empty id is a programming error', () {
    expect(() => GetServerLogUseCase(repository)(''), throwsArgumentError);
    expect(() => GetPendingLogUseCase(repository)(''), throwsArgumentError);
    expect(
      () => SetLogStatusUseCase(repository)('', LogStatus.fixed),
      throwsArgumentError,
    );
  });

  test('a status change trims its note and drops a blank one', () async {
    repository.servers['a'] = record('a');
    final set = SetLogStatusUseCase(repository);

    await set('a', LogStatus.fixed, note: '  index added  ');
    await set('a', LogStatus.open, note: '   ');
    await set('a', LogStatus.fixed);

    expect(repository.statusChanges.map((c) => c.note), [
      'index added',
      null,
      null,
    ]);
  });

  test('a status change of a log that is gone is notFound', () async {
    final outcome = await SetLogStatusUseCase(repository)(
      'gone',
      LogStatus.fixed,
    );

    expect((outcome as Rejected).reason, MonitoringRejection.notFound);
  });

  test('the buffer is watched for the levels asked', () async {
    final rows = WatchPendingLogsUseCase(repository)({LogLevel.error});
    final seen = <PendingLogs>[];
    final sub = rows.listen(seen.add);
    repository.watches.single.feed.add(
      PendingLogs(items: [summary('a', status: null)], total: 7),
    );
    await pumpEventQueue();
    await sub.cancel();

    expect(repository.watches.single.levels, {LogLevel.error});
    expect(seen.single.total, 7);
  });
}
