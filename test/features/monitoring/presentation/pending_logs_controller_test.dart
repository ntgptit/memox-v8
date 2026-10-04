import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2: the Not sent tab watches the device buffer.
void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(pendingLogsControllerProvider, (_, _) {});
  });

  PendingLogs rows(int count, {int total = 0}) => PendingLogs(
    items: [for (var i = 0; i < count; i++) summary('p$i', status: null)],
    total: total,
  );

  test(
    'it watches warnings and errors first, and shows what arrives',
    () async {
      expect(repository.watches.single.levels, {
        LogLevel.warning,
        LogLevel.error,
      });
      expect(
        container.read(pendingLogsControllerProvider).logs.isLoading,
        isTrue,
      );

      repository.watches.single.feed.add(rows(2, total: 9));
      await pumpEventQueue();

      final logs = container
          .read(pendingLogsControllerProvider)
          .logs
          .requireValue;
      expect(logs.items, hasLength(2));
      expect(logs.total, 9);
    },
  );

  test('new levels watch again, keep the rows until the answer, and stop '
      'the old watch', () async {
    repository.watches.single.feed.add(rows(2));
    await pumpEventQueue();

    container.read(pendingLogsControllerProvider.notifier).setLevels({
      LogLevel.debug,
    });

    expect(repository.watches, hasLength(2));
    expect(repository.watches.last.levels, {LogLevel.debug});
    expect(repository.watches.first.feed.hasListener, isFalse);
    final state = container.read(pendingLogsControllerProvider);
    expect(state.levels, {LogLevel.debug});
    expect(state.logs.requireValue.items, hasLength(2));

    repository.watches.last.feed.add(rows(1));
    await pumpEventQueue();
    expect(
      container.read(pendingLogsControllerProvider).logs.requireValue.items,
      hasLength(1),
    );
  });

  test('every write to the buffer shows', () async {
    final feed = repository.watches.single.feed;

    feed.add(rows(1, total: 1));
    await pumpEventQueue();
    feed.add(rows(3, total: 3));
    await pumpEventQueue();

    expect(
      container.read(pendingLogsControllerProvider).logs.requireValue.total,
      3,
    );
  });

  test('a watch that fails shows its error', () async {
    repository.watches.single.feed.addError(StateError('closed'));
    await pumpEventQueue();

    expect(container.read(pendingLogsControllerProvider).logs.hasError, isTrue);
  });

  test('disposing stops the watch', () async {
    container.dispose();

    expect(repository.watches.single.feed.hasListener, isFalse);
  });
}
