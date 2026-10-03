import 'dart:async';

import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/providers/query_server_logs_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monitoring_list_controller.g.dart';

/// How long the search field stays still before it asks the server
/// (monitoring spec §3.2).
const Duration monitoringSearchDebounce = Duration(milliseconds: 400);

/// The Server tab (monitoring spec §3.2, §3.5): the filter, the pages read
/// so far and the one read in flight. A filter change, a search and a pull
/// to refresh start again from the first page; an answer to an earlier ask
/// than the latest is dropped, so a slow response never overwrites a newer
/// one.
@riverpod
class MonitoringListController extends _$MonitoringListController {
  Timer? _debounce;

  /// Bumped by every ask from the first page; an answer carries the number
  /// it was asked under.
  var _generation = 0;

  @override
  MonitoringListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadFirst);
    return const MonitoringListState();
  }

  /// The search text typed but not yet asked: every other ask carries it
  /// instead of dropping it (final review M3).
  String? _pendingSearch;

  /// The filter with the pending search applied.
  LogFilter get _intended {
    final text = _pendingSearch;
    return text == null ? state.filter : state.filter.withSearch(text);
  }

  /// A new filter: the first page of it, at once.
  void setFilter(LogFilter next) {
    _debounce?.cancel();
    _pendingSearch = null;
    if (next == state.filter) return;
    state = MonitoringListState(filter: next);
    unawaited(_loadFirst());
  }

  /// A change to the filter as it is now, the pending search included, not
  /// as it was when a sheet opened.
  void updateFilter(LogFilter Function(LogFilter current) change) =>
      setFilter(change(_intended));

  /// Every filter and the search back to the default.
  void clearFilters() => setFilter(const LogFilter());

  /// After a failure: the first page again, the failure gone at once.
  void retry() {
    final filter = _intended;
    _debounce?.cancel();
    _pendingSearch = null;
    state = MonitoringListState(filter: filter);
    unawaited(_loadFirst());
  }

  /// The search field changed: asked [monitoringSearchDebounce] after the
  /// last change.
  void search(String text) {
    _debounce?.cancel();
    _pendingSearch = text;
    _debounce = Timer(monitoringSearchDebounce, () => setFilter(_intended));
  }

  /// Pull to refresh: the first page again, the rows kept until it lands.
  /// A search still waiting is asked now.
  Future<void> refresh() {
    final filter = _intended;
    _debounce?.cancel();
    _pendingSearch = null;
    if (filter != state.filter) state = MonitoringListState(filter: filter);
    // The last refresh's warning goes at once, as a retry's failure does; it
    // comes back if this one fails too (SP2b 2.38).
    if (_loaded case final shown? when shown.refreshFailure != null) {
      _show(shown.withRefreshFailure(null));
    }
    return _loadFirst();
  }

  /// One more page, keeping the rows until it arrives; after a failure it is
  /// the retry.
  Future<void> loadMore() async {
    final current = state.content;
    if (current is! MonitoringListLoaded) return;
    final after = current.next;
    if (after == null || current.more == MonitoringMore.loading) return;
    final generation = _generation;
    final filter = state.filter;
    _show(current.withMore(MonitoringMore.loading));
    try {
      final page = await ref.read(queryServerLogsUseCaseProvider)(
        filter,
        after: after,
      );
      if (!_isCurrent(generation)) return;
      final latest = _loaded;
      if (latest == null) return;
      state = MonitoringListState(
        filter: filter,
        content: MonitoringListLoaded(
          items: [...latest.items, ...page.items],
          next: page.next,
          refreshFailure: latest.refreshFailure,
        ),
      );
    } on Object {
      if (!_isCurrent(generation)) return;
      final latest = _loaded;
      if (latest == null) return;
      _show(latest.withMore(MonitoringMore.failed));
    }
  }

  /// The detail changed [id]'s status: it shows the new one, or, when the
  /// filter no longer matches it, leaves the list.
  void statusChanged(String id, LogStatus status) {
    final current = _loaded;
    if (current == null) return;
    final wanted = state.filter.statuses;
    final keeps = wanted.isEmpty || wanted.contains(status);
    _show(
      current.withItems([
        for (final item in current.items)
          if (item.id != id) item else if (keeps) item.withStatus(status),
      ]),
    );
  }

  MonitoringListLoaded? get _loaded {
    final content = state.content;
    return content is MonitoringListLoaded ? content : null;
  }

  void _show(MonitoringListContent content) =>
      state = MonitoringListState(filter: state.filter, content: content);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<void> _loadFirst() async {
    if (!ref.mounted) return;
    final generation = ++_generation;
    final filter = state.filter;
    try {
      final page = await ref.read(queryServerLogsUseCaseProvider)(filter);
      if (!_isCurrent(generation)) return;
      state = MonitoringListState(
        filter: filter,
        content: MonitoringListLoaded(items: page.items, next: page.next),
      );
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      final failure = MonitoringLoadFailure.of(error);
      final shown = _loaded;
      // A pull to refresh that fails keeps the rows (SP2b 2.38). A new filter
      // cleared them first, an empty list has none to keep, and a lost admin
      // role must not leave logs on screen.
      if (shown != null &&
          shown.items.isNotEmpty &&
          failure != MonitoringLoadFailure.notAdmin) {
        // A page that was loading is dropped by the generation guard.
        _show(shown.withMore(MonitoringMore.idle).withRefreshFailure(failure));
        return;
      }
      _show(MonitoringListFailed(failure));
    }
  }
}
