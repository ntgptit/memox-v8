import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2, SP2b 2.38: a refresh that fails keeps the rows.

void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(monitoringListControllerProvider, (_, _) {});
  });

  MonitoringListController controller() =>
      container.read(monitoringListControllerProvider.notifier);
  MonitoringListState state() =>
      container.read(monitoringListControllerProvider);
  MonitoringListLoaded loaded() => state().content as MonitoringListLoaded;
  List<String> ids() => [for (final item in loaded().items) item.id];

  /// The first page, answered with [page].
  Future<void> open(LogPage page) async {
    await pumpEventQueue();
    repository.lastQuery.answer(page);
    await pumpEventQueue();
  }

  /// A refresh asked and answered with a failure.
  Future<void> refreshFailing(Object error) async {
    final refreshing = controller().refresh();
    await pumpEventQueue();
    repository.lastQuery.fail(error);
    await refreshing;
  }

  test(
    'a refresh that fails keeps the rows and says which way it failed',
    () async {
      await open(pageOf(2));

      await refreshFailing(const OfflineFailure(cause: 'x'));
      expect(ids(), ['r0', 'r1']);
      expect(loaded().refreshFailure, MonitoringLoadFailure.offline);

      await refreshFailing(const ServerFailure(cause: 'x'));
      expect(ids(), ['r0', 'r1']);
      expect(loaded().refreshFailure, MonitoringLoadFailure.other);
    },
  );

  test('a refresh asked again clears the warning at once, and a page that '
      'lands replaces the rows', () async {
    await open(pageOf(2));
    await refreshFailing(const OfflineFailure(cause: 'x'));

    final again = controller().refresh();
    await pumpEventQueue();
    expect(loaded().refreshFailure, isNull);
    expect(ids(), ['r0', 'r1']);
    repository.lastQuery.answer(pageOf(1, prefix: 'n'));
    await again;

    expect(ids(), ['n0']);
    expect(loaded().refreshFailure, isNull);
  });

  test('a lost admin role still replaces the rows', () async {
    await open(pageOf(2));

    await refreshFailing(const NotAdminFailure(cause: 'x'));

    expect(
      (state().content as MonitoringListFailed).failure,
      MonitoringLoadFailure.notAdmin,
    );
  });

  test('an empty list has no rows to keep: the failure page stands', () async {
    await open(pageOf(0));

    await refreshFailing(const OfflineFailure(cause: 'x'));

    expect(
      (state().content as MonitoringListFailed).failure,
      MonitoringLoadFailure.offline,
    );
  });

  test(
    'a new filter clears the rows first, so its failure is the full page',
    () async {
      await open(pageOf(2));

      controller().setFilter(const LogFilter().withSearch('a'));
      await pumpEventQueue();
      repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
      await pumpEventQueue();

      expect(state().content, isA<MonitoringListFailed>());
    },
  );

  test(
    'with a filter set, a failed refresh keeps the rows and the filter',
    () async {
      await open(pageOf(1));
      final filter = const LogFilter().withSearch('push');
      controller().setFilter(filter);
      await pumpEventQueue();
      repository.lastQuery.answer(pageOf(2, prefix: 'f'));
      await pumpEventQueue();

      await refreshFailing(const OfflineFailure(cause: 'x'));

      expect(ids(), ['f0', 'f1']);
      expect(state().filter, filter);
      expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
    },
  );

  test(
    'a page that was loading when the refresh failed is not left spinning',
    () async {
      await open(pageOf(LogPage.size));
      final more = controller().loadMore();
      await pumpEventQueue();
      expect(loaded().more, MonitoringMore.loading);

      await refreshFailing(const OfflineFailure(cause: 'x'));
      // The dropped page answers late; nothing changes.
      repository.queries[1].answer(pageOf(3, prefix: 'p'));
      await more;

      expect(loaded().more, MonitoringMore.idle);
      expect(loaded().items, hasLength(LogPage.size));
      expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
    },
  );

  test('a next page that lands keeps the warning: the first rows are still '
      'from the earlier load', () async {
    await open(pageOf(LogPage.size));
    await refreshFailing(const OfflineFailure(cause: 'x'));

    final more = controller().loadMore();
    await pumpEventQueue();
    repository.lastQuery.answer(pageOf(3, prefix: 'p'));
    await more;

    expect(loaded().items, hasLength(LogPage.size + 3));
    expect(loaded().refreshFailure, MonitoringLoadFailure.offline);
  });
}
