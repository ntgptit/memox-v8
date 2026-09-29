import 'package:drift/drift.dart';
import 'package:memox/core/logging/app_logger.dart';

/// Logs every statement [AppDatabase] runs (ADR-018; spec
/// 2026-09-29-app-logging-design.md §3): `debug db.query`, a slow one as
/// `db.slow_query`, a failing one as `error db.query_failed`.
///
/// The log buffer has its own database without this tracer, so writing a log
/// never logs.
final class TracingInterceptor extends QueryInterceptor {
  TracingInterceptor({this._logger, int Function()? micros})
    : _micros = micros ?? _stopwatch.elapsedMicroseconds.toInt;

  static const slowMs = 50;
  static const verySlowMs = 150;

  // Elapsed time only: the database layer never reads the wall clock.
  static final _stopwatch = Stopwatch()..start();

  final AppLogger? _logger;
  final int Function() _micros;

  AppLogger get _log => _logger ?? appLogger;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _trace(
    'select',
    statement,
    args,
    () => executor.runSelect(statement, args),
  );

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _trace(
    'insert',
    statement,
    args,
    () => executor.runInsert(statement, args),
  );

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _trace(
    'update',
    statement,
    args,
    () => executor.runUpdate(statement, args),
  );

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _trace(
    'delete',
    statement,
    args,
    () => executor.runDelete(statement, args),
  );

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _trace(
    'custom',
    statement,
    args,
    () => executor.runCustom(statement, args),
  );

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _trace('batch', statements.statements.join(';\n'), [
    for (final run in statements.arguments) run.arguments,
  ], () => executor.runBatched(statements));

  @override
  Future<void> commitTransaction(TransactionExecutor inner) =>
      _transaction('commit', inner.send);

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) =>
      _transaction('rollback', inner.rollback);

  /// One `debug db.transaction` as it ends; its statements log on their own.
  Future<void> _transaction(String outcome, Future<void> Function() end) async {
    final start = _micros();
    try {
      await end();
    } on Object catch (error, stackTrace) {
      _failed('transaction', outcome, const [], start, error, stackTrace);
      rethrow;
    }
    _log.debug(
      'db.transaction',
      category: LogCategory.db,
      context: {'outcome': outcome, 'duration_ms': _elapsedMs(start)},
    );
  }

  Future<T> _trace<T>(
    String kind,
    String sql,
    List<Object?> args,
    Future<T> Function() run,
  ) async {
    final start = _micros();
    final T result;
    try {
      result = await run();
    } on Object catch (error, stackTrace) {
      _failed(kind, sql, args, start, error, stackTrace);
      rethrow;
    }
    _done(kind, sql, args, _elapsedMs(start));
    return result;
  }

  void _failed(
    String kind,
    String sql,
    List<Object?> args,
    int start,
    Object error,
    StackTrace stackTrace,
  ) => _log.error(
    'db.query_failed',
    category: LogCategory.db,
    error: error,
    stackTrace: stackTrace,
    context: _context(kind, sql, args, _elapsedMs(start)),
  );

  void _done(String kind, String sql, List<Object?> args, int ms) {
    final context = _context(kind, sql, args, ms);
    if (ms >= verySlowMs) {
      _log.warning('db.slow_query', category: LogCategory.db, context: context);
    } else if (ms >= slowMs) {
      _log.info('db.slow_query', category: LogCategory.db, context: context);
    } else {
      _log.debug('db.query', category: LogCategory.db, context: context);
    }
  }

  int _elapsedMs(int startMicros) => (_micros() - startMicros) ~/ 1000;

  static Map<String, Object?> _context(
    String kind,
    String sql,
    List<Object?> args,
    int ms,
  ) => {
    'kind': kind,
    'sql': sql,
    'args': [for (final arg in args) _arg(arg)],
    'duration_ms': ms,
  };

  // A blob is logged by its size; everything else as it is.
  static Object? _arg(Object? arg) => switch (arg) {
    Uint8List(:final length) => '<blob $length bytes>',
    List<Object?>() => [for (final item in arg) _arg(item)],
    _ => arg,
  };
}
