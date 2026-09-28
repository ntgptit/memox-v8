import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

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
      succeeded = true;
      _failures = 0;
      await _report(() async => _onSucceeded?.call());
    } catch (error, stackTrace) {
      _failures++;
      log('Sync failed; retrying', error: error, stackTrace: stackTrace);
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

  /// A report that fails is logged; it never stops sync.
  Future<void> _report(Future<void> Function() report) async {
    try {
      await report();
    } catch (error, stackTrace) {
      log('Sync status not recorded', error: error, stackTrace: stackTrace);
    }
  }
}
