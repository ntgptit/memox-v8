import 'dart:async';
import 'dart:math' as math;

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/sync/sync_failure.dart';

/// When a sync runs: at start, after a debounced burst of triggers, and on
/// backoff after a failure. At most one run at a time (app deck-sync spec §5).
class SyncScheduler {
  SyncScheduler({
    required this._run,
    required this._triggers,
    this._reconnects = const Stream.empty(),
    this._onSucceeded,
    this._onFailed,
    this.debounce = const Duration(seconds: 2),
    this.minBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 5),
    this._logger,
  });

  final Future<void> Function() _run;
  final Stream<void> _triggers;

  /// The network came back: retry at once and forget the backoff.
  final Stream<void> _reconnects;

  /// Records a run that ended without an error (sync status spec §4).
  final Future<void> Function()? _onSucceeded;

  /// Records a run's error; the scheduler still backs off.
  final Future<void> Function(Object error)? _onFailed;
  final Duration debounce;
  final Duration minBackoff;
  final Duration maxBackoff;

  /// Where a failed run is logged; [appLogger] unless the run itself empties
  /// the log buffer (ADR-018 §3), which must not log into what it ships.
  final AppLogger? _logger;

  AppLogger get _log => _logger ?? appLogger;

  final _subscriptions = <StreamSubscription<void>>[];
  Timer? _timer;
  var _running = false;
  var _rerun = false;
  var _failures = 0;

  /// Callers of [syncNow] waiting for the next run to end.
  final _waiters = <Completer<bool>>[];

  void start() {
    _subscriptions
      ..add(
        _triggers.listen((_) {
          // During a backoff a local write waits for the retry: offline, a
          // burst of edits must not hammer the server every 2 s.
          if (_failures == 0) {
            _schedule(debounce);
          }
        }),
      )
      ..add(
        _reconnects.listen((_) {
          _failures = 0;
          _schedule(Duration.zero);
        }),
      );
    _schedule(Duration.zero);
  }

  /// Sync now (screen 27): forget the backoff and run at once, or right after
  /// the run in progress. True when that run succeeded.
  Future<bool> syncNow() {
    final waiter = Completer<bool>();
    _waiters.add(waiter);
    _failures = 0;
    if (_running) {
      _rerun = true;
    } else {
      _schedule(Duration.zero);
    }
    return waiter.future;
  }

  void dispose() {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final waiter in _waiters) {
      waiter.complete(false);
    }
    _waiters.clear();
  }

  Duration backoffFor(int failures) {
    final factor = math.pow(2, math.min(failures - 1, 16)).toInt();
    final delay = minBackoff * factor;
    return delay > maxBackoff ? maxBackoff : delay;
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    final waiting = [..._waiters];
    _waiters.clear();
    var succeeded = false;
    try {
      await _run();
      // A success that cannot be recorded fails the run, which backs off and
      // is retried (sync status spec §6).
      await _onSucceeded?.call();
      succeeded = true;
      _failures = 0;
    } catch (error, stackTrace) {
      _failures++;
      _logFailure(error, stackTrace);
      await _report(() async => _onFailed?.call(error));
    } finally {
      _running = false;
      for (final waiter in waiting) {
        waiter.complete(succeeded);
      }
      if (_waiters.isNotEmpty || (succeeded && _rerun)) {
        _schedule(Duration.zero);
      } else if (!succeeded) {
        _schedule(backoffFor(_failures));
      }
      _rerun = false;
    }
  }

  /// Offline is a normal state here; only another failure is an error an
  /// admin has to look at (ADR-018 §6).
  void _logFailure(Object error, StackTrace stackTrace) {
    final context = {'failures': _failures};
    if (classifySyncFailure(error) == SyncFailureKind.network) {
      _log.info(
        'sync.failed',
        category: LogCategory.sync,
        message: '$error',
        context: context,
      );
      return;
    }
    _log.error(
      'sync.failed',
      category: LogCategory.sync,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// A failure that cannot be recorded is logged; the run already failed and
  /// backs off either way.
  Future<void> _report(Future<void> Function() report) async {
    try {
      await report();
    } catch (error, stackTrace) {
      _log.warning(
        'sync.status_not_recorded',
        category: LogCategory.sync,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
