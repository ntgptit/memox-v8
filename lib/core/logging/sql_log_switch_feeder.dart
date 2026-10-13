import 'dart:async';

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/logging/sql_log_switch.dart';

/// Keeps [target] equal to the account's `log_sql_statements` row (SQL log
/// switch spec §4.3). The first value is the start of the app or of a new
/// account and is not logged; every later change writes one `info` row, so
/// the server log says why `db.query` rows stop or start on this device. A
/// failing stream leaves the switch as it is and is logged once.
final class SqlLogSwitchFeeder {
  SqlLogSwitchFeeder({
    required SqlLogSwitch target,
    required Stream<bool> flags,
    AppLogger? logger,
  }) : _target = target,
       _logger = logger {
    _subscription = flags.listen(_apply, onError: _unavailable);
  }

  final SqlLogSwitch _target;
  final AppLogger? _logger;
  late final StreamSubscription<bool> _subscription;
  var _hasRead = false;

  AppLogger get _log => _logger ?? appLogger;

  void _apply(bool enabled) {
    final isFirst = !_hasRead;
    _hasRead = true;
    if (_target.value == enabled) return;
    _target.value = enabled;
    if (isFirst) return;
    _log.info(
      'logging.sql_statements_changed',
      category: LogCategory.lifecycle,
      context: {'enabled': enabled},
    );
  }

  void _unavailable(Object error, StackTrace stackTrace) => _log.warning(
    'logging.sql_switch_unavailable',
    category: LogCategory.lifecycle,
    error: error,
    stackTrace: stackTrace,
  );

  void dispose() => unawaited(_subscription.cancel());
}
