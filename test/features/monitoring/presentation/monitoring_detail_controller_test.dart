import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_detail_controller.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.3, §5: the detail reads one log and changes its status.
void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  final server = monitoringDetailControllerProvider('a', false);
  final local = monitoringDetailControllerProvider('a', true);

  Future<MonitoringDetailState> open(
    MonitoringDetailControllerProvider provider,
  ) async {
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    return container.read(provider);
  }

  test('a server log is read and shown', () async {
    repository.servers['a'] = record('a');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailLoaded).record.event,
      'sync.push_failed',
    );
    expect(state.changing, isNull);
    expect(state.notice, isNull);
  });

  test(
    'a buffered log is read from the buffer, and cannot be triaged',
    () async {
      repository.pendings['a'] = record('a', status: null);

      final state = await open(local);
      await container.read(local.notifier).setStatus(LogStatus.fixed);

      expect(state.content, isA<MonitoringDetailLoaded>());
      expect(repository.statusChanges, isEmpty);
    },
  );

  test('a log that is gone is told so', () async {
    final state = await open(server);

    expect(state.content, isA<MonitoringDetailGone>());
  });

  test('a read that fails is told apart, and a retry reads again', () async {
    repository.readError = const OfflineFailure(cause: 'x');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailFailed).failure,
      MonitoringLoadFailure.offline,
    );
    repository
      ..readError = null
      ..servers['a'] = record('a');
    await container.read(server.notifier).retry();
    expect(container.read(server).content, isA<MonitoringDetailLoaded>());
  });

  test('not an admin is its own failure', () async {
    repository.readError = const NotAdminFailure(cause: 'x');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailFailed).failure,
      MonitoringLoadFailure.notAdmin,
    );
  });

  test('marking fixed shows the server\'s row and says so', () async {
    repository.servers['a'] = record('a');
    await open(server);

    await container
        .read(server.notifier)
        .setStatus(LogStatus.fixed, note: 'index added');

    final state = container.read(server);
    final row = (state.content as MonitoringDetailLoaded).record;
    expect(row.status, LogStatus.fixed);
    expect(row.statusNote, 'index added');
    expect((state.notice! as StatusChanged).status, LogStatus.fixed);
    expect(state.changing, isNull);
    expect(repository.statusChanges.single.note, 'index added');
  });

  test('the list drops the row when its filter no longer matches', () async {
    repository.servers['a'] = record('a');
    repository.autoPage = LogPage(items: [summary('a'), summary('b')]);
    container.listen(monitoringListControllerProvider, (_, _) {});
    await pumpEventQueue();
    await open(server);

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    final list =
        container.read(monitoringListControllerProvider).content
            as MonitoringListLoaded;
    expect([for (final item in list.items) item.id], ['b']);
  });

  // Final review I1: leaving the page mid-change must not lose the answer.
  test(
    'a change that lands after the page is left still updates the list',
    () async {
      repository.servers['a'] = record('a');
      repository.autoPage = LogPage(items: [summary('a'), summary('b')]);
      container.listen(monitoringListControllerProvider, (_, _) {});
      await pumpEventQueue();
      final page = container.listen(server, (_, _) {});
      await pumpEventQueue();
      repository.statusGate = Completer<void>();

      final change = container.read(server.notifier).setStatus(LogStatus.fixed);
      page.close();
      await pumpEventQueue();
      repository.statusGate!.complete();
      await change;

      final list =
          container.read(monitoringListControllerProvider).content
              as MonitoringListLoaded;
      expect([for (final item in list.items) item.id], ['b']);
    },
  );

  test('a change with no list open does not open one', () async {
    repository.servers['a'] = record('a');
    await open(server);

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    expect(container.exists(monitoringListControllerProvider), isFalse);
  });

  // Review focus: a status change failing offline.
  test('a change that fails changes nothing and offers the same change '
      'again', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.statusError = const OfflineFailure(cause: 'x');

    await container
        .read(server.notifier)
        .setStatus(LogStatus.fixed, note: 'index added');

    final state = container.read(server);
    expect(
      (state.content as MonitoringDetailLoaded).record.status,
      LogStatus.open,
    );
    final failed = state.notice! as StatusChangeFailed;
    expect(failed.status, LogStatus.fixed);
    expect(failed.note, 'index added');
    expect(state.changing, isNull);

    repository.statusError = null;
    await container
        .read(server.notifier)
        .setStatus(failed.status, note: failed.note);
    expect(
      (container.read(server).content as MonitoringDetailLoaded).record.status,
      LogStatus.fixed,
    );
  });

  test('a second change waits for the first', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.statusGate = Completer<void>();

    final first = container.read(server.notifier).setStatus(LogStatus.fixed);
    await pumpEventQueue();
    expect(container.read(server).changing, LogStatus.fixed);
    await container.read(server.notifier).setStatus(LogStatus.open);
    repository.statusGate!.complete();
    await first;

    expect(repository.statusChanges, hasLength(1));
  });

  test('a change of a log that is gone leaves the page saying so', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.servers.remove('a');

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    expect(container.read(server).content, isA<MonitoringDetailGone>());
  });

  test('a context of 256 kB is read and kept whole', () async {
    final big = 'x' * (256 * 1024);
    repository.servers['a'] = record('a', context: {'args': big});

    final state = await open(server);

    final row = (state.content as MonitoringDetailLoaded).record;
    expect((row.context['args']! as String).length, 256 * 1024);
  });
}
