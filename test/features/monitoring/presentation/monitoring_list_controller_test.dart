import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2, §3.5, §5: default filter, pages, a filter change
// starts again, and a stale answer never overwrites a newer one.

typedef _Body = void Function(
  FakeAsync async,
  MonitoringListController controller,
  MonitoringListState Function() state,
  FakeMonitoringRepository repository,
);

/// Runs [body] in fake time over a container whose repository is the fake,
/// after the first ask (made in a microtask) has been made.
void _run(_Body body) {
  fakeAsync((async) {
    final repository = FakeMonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    final keepAlive = container.listen(
      monitoringListControllerProvider,
      (_, _) {},
    );
    async.flushMicrotasks();
    body(
      async,
      container.read(monitoringListControllerProvider.notifier),
      () => container.read(monitoringListControllerProvider),
      repository,
    );
    keepAlive.close();
    container.dispose();
    async.flushMicrotasks();
  });
}

MonitoringListLoaded _loaded(MonitoringListState state) =>
    state.content as MonitoringListLoaded;

List<String> _ids(MonitoringListState state) => [
  for (final item in _loaded(state).items) item.id,
];

void main() {
  test('it opens on open warnings and errors, loading the first page', () {
    _run((async, controller, state, repository) {
      expect(state().filter.isDefault, isTrue);
      expect(state().content, isA<MonitoringListLoading>());
      expect(repository.queries, hasLength(1));
      expect(repository.lastQuery.filter, const LogFilter());
      expect(repository.lastQuery.after, isNull);

      repository.lastQuery.answer(pageOf(3));
      async.flushMicrotasks();

      expect(_ids(state()), ['r0', 'r1', 'r2']);
      expect(_loaded(state()).next, isNull);
    });
  });

  test(
    'a full page is followed by the next, and a short one ends the list',
    () {
      _run((async, controller, state, repository) {
        repository.lastQuery.answer(pageOf(LogPage.size));
        async.flushMicrotasks();
        final cursor = _loaded(state()).next;
        expect(cursor!.id, 'r99');

        unawaited(controller.loadMore());
        expect(_loaded(state()).more, MonitoringMore.loading);
        expect(repository.lastQuery.after, cursor);
        repository.lastQuery.answer(pageOf(5, prefix: 'p'));
        async.flushMicrotasks();

        expect(_loaded(state()).items, hasLength(LogPage.size + 5));
        expect(_loaded(state()).next, isNull);
        expect(_loaded(state()).more, MonitoringMore.idle);

        unawaited(controller.loadMore());
        expect(
          repository.queries,
          hasLength(2),
          reason: 'the end asks nothing',
        );
      });
    },
  );

  test('a second loadMore while one is in flight asks nothing', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      unawaited(controller.loadMore());
      unawaited(controller.loadMore());

      expect(repository.queries, hasLength(2));
    });
  });

  test('a failed page keeps the rows and loadMore is its retry', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      unawaited(controller.loadMore());
      repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      expect(_loaded(state()).more, MonitoringMore.failed);
      expect(_loaded(state()).items, hasLength(LogPage.size));

      unawaited(controller.loadMore());
      repository.lastQuery.answer(pageOf(2, prefix: 'p'));
      async.flushMicrotasks();

      expect(_loaded(state()).items, hasLength(LogPage.size + 2));
      expect(_loaded(state()).more, MonitoringMore.idle);
    });
  });

  test('a filter change starts again from the first page', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      final next = const LogFilter().withCategories({LogCategory.sync});
      controller.setFilter(next);

      expect(state().filter, next);
      expect(state().content, isA<MonitoringListLoading>());
      expect(repository.lastQuery.filter, next);
      expect(repository.lastQuery.after, isNull);
    });
  });

  test('the same filter again asks nothing', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.setFilter(const LogFilter());

      expect(repository.queries, hasLength(1));
    });
  });

  // Review focus: a filter change while a page is loading.
  test('a slow answer to the old filter never overwrites the new one', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      final fresh = repository.lastQuery;

      fresh.answer(pageOf(2, prefix: 'new'));
      async.flushMicrotasks();
      old.answer(pageOf(4, prefix: 'old'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0', 'new1']);
      expect(state().filter.categories, {LogCategory.db});
    });
  });

  test('an old answer that lands first is dropped too', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      final fresh = repository.lastQuery;

      old.answer(pageOf(4, prefix: 'old'));
      async.flushMicrotasks();
      expect(state().content, isA<MonitoringListLoading>());
      fresh.answer(pageOf(2, prefix: 'new'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0', 'new1']);
    });
  });

  test('an old failure never replaces the new rows', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));

      repository.lastQuery.answer(pageOf(1, prefix: 'new'));
      async.flushMicrotasks();
      old.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0']);
    });
  });

  test('a next page that lands after a filter change is dropped', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();
      unawaited(controller.loadMore());
      final more = repository.lastQuery;

      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      repository.lastQuery.answer(pageOf(1, prefix: 'new'));
      async.flushMicrotasks();
      more.answer(pageOf(5, prefix: 'late'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0']);
    });
  });

  test('the search asks once, 400 ms after the last keystroke', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.search('pu');
      async.elapse(monitoringSearchDebounce - const Duration(milliseconds: 1));
      controller.search('push');
      async.elapse(monitoringSearchDebounce - const Duration(milliseconds: 1));
      expect(repository.queries, hasLength(1));

      async.elapse(const Duration(milliseconds: 1));

      expect(repository.queries, hasLength(2));
      expect(repository.lastQuery.filter.search, 'push');
      expect(state().filter.search, 'push');
    });
  });

  // Final review M3: a filter applied while the search waits keeps the
  // search, and reads the filter as it is at apply time.
  test('a filter change before the search fires keeps the search', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.search('timeout');
      controller.updateFilter((filter) => filter.withLevels({LogLevel.error}));
      async.elapse(monitoringSearchDebounce * 2);

      expect(repository.lastQuery.filter.search, 'timeout');
      expect(repository.lastQuery.filter.levels, {LogLevel.error});
      expect(state().filter.search, 'timeout');
    });
  });

  test('a refresh before the search fires asks with the search', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.search('timeout');
      unawaited(controller.refresh());
      async.elapse(monitoringSearchDebounce * 2);

      expect(repository.lastQuery.filter.search, 'timeout');
      expect(state().filter.search, 'timeout');
    });
  });

  test('a pull to refresh keeps the rows until the first page lands', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(2));
      async.flushMicrotasks();

      var isDone = false;
      controller.refresh().then((_) => isDone = true);
      expect(_ids(state()), ['r0', 'r1']);
      expect(isDone, isFalse);
      repository.lastQuery.answer(pageOf(1, prefix: 'n'));
      async.flushMicrotasks();

      expect(_ids(state()), ['n0']);
      expect(isDone, isTrue);
    });
  });

  test('a failure is told apart: not an admin, offline, or other', () {
    for (final (error, expected) in <(Object, MonitoringLoadFailure)>[
      (const NotAdminFailure(cause: 'x'), MonitoringLoadFailure.notAdmin),
      (const OfflineFailure(cause: 'x'), MonitoringLoadFailure.offline),
      (const ServerFailure(cause: 'x'), MonitoringLoadFailure.other),
      (StateError('odd'), MonitoringLoadFailure.other),
    ]) {
      _run((async, controller, state, repository) {
        repository.lastQuery.fail(error);
        async.flushMicrotasks();

        expect((state().content as MonitoringListFailed).failure, expected);
      });
    }
  });

  test('a retry after a failure asks the first page again', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      controller.setFilter(const LogFilter().withSearch('a'));
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      expect(_ids(state()), ['r0']);
    });
  });

  test('clearing the filters resets every filter and the search', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();
      controller.setFilter(
        const LogFilter().withSearch('push').withCategories({LogCategory.db}),
      );
      repository.lastQuery.answer(pageOf(0));
      async.flushMicrotasks();

      controller.clearFilters();

      expect(state().filter.isDefault, isTrue);
      expect(repository.lastQuery.filter, const LogFilter());
    });
  });

  test('a row marked fixed leaves the default list', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(3));
      async.flushMicrotasks();

      controller.statusChanged('r1', LogStatus.fixed);

      expect(_ids(state()), ['r0', 'r2']);
    });
  });

  test('with no status filter the row stays and shows its new status', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();
      controller.setFilter(const LogFilter().withStatuses({}));
      repository.lastQuery.answer(pageOf(2));
      async.flushMicrotasks();

      controller.statusChanged('r1', LogStatus.fixed);

      expect(_ids(state()), ['r0', 'r1']);
      expect(_loaded(state()).items[1].status, LogStatus.fixed);
      expect(_loaded(state()).items[0].status, LogStatus.open);
    });
  });
}
