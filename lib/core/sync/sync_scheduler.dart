import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

/// When a sync runs: at start, after a debounced burst of triggers, and on
/// backoff after a failure. At most one run at a time (app deck-sync spec §5).
class SyncScheduler {
  SyncScheduler({
    required this._run,
    required this._triggers,
    this.debounce = const Duration(seconds: 2),
    this.minBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 5),
  });

  final Future<void> Function() _run;
  final Stream<void> _triggers;
  final Duration debounce;
  final Duration minBackoff;
  final Duration maxBackoff;

  StreamSubscription<void>? _subscription;
  Timer? _timer;
  var _running = false;
  var _rerun = false;
  var _failures = 0;

  void start() {
    _subscription = _triggers.listen((_) => _schedule(debounce));
    _schedule(Duration.zero);
  }

  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
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
    try {
      await _run();
      _failures = 0;
      if (_rerun) {
        _schedule(Duration.zero);
      }
    } catch (error, stackTrace) {
      _failures++;
      log('Sync failed; retrying', error: error, stackTrace: stackTrace);
      _schedule(backoffFor(_failures));
    } finally {
      _running = false;
      _rerun = false;
    }
  }
}
