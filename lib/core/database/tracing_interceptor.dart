import 'package:drift/drift.dart';
import 'package:memox/core/logging/app_logger.dart';

/// Logs every statement [AppDatabase] runs (ADR-018; spec
/// 2026-09-29-app-logging-design.md §3): `debug db.query`, a slow one as
/// `db.slow_query`, a failing one as `error db.query_failed`.
///
/// The log buffer has its own database without this tracer, so writing a log
/// never logs.
///
/// A statement on the `card_draft` table logs its SQL and the number of its
/// arguments, never the arguments: they are the card text being written, and
/// the log ships to the server (SP2a R9).
///
/// A statement's time is what its caller waits for: it starts when the tracer
/// sees the call, so it includes the wait for Drift's lock on the connection
/// (statements queue behind each other). A `db.slow_query` can therefore mean
/// a busy connection, not a slow statement; read its neighbours in the log.
final class TracingInterceptor extends QueryInterceptor {
  TracingInterceptor({this._logger, int Function()? micros})
    : _micros = micros ?? (() => _stopwatch.elapsedMicroseconds);

  static const slowMs = 50;
  static const verySlowMs = 150;

  /// A batch keeps the arguments of its first runs only: a bulk import is
  /// thousands of runs of one statement. Its context carries `runs`, the real
  /// count.
  static const maxBatchArgs = 50;

  /// The table whose statements log without their arguments.
  static const _draftTable = 'card_draft';

  // Elapsed time only: the database layer never reads the wall clock.
  static final _stopwatch = Stopwatch()..start();

  final AppLogger? _logger;
  final int Function() _micros;

  /// When each open transaction began, on [_micros]'s clock. Drift hands the
  /// commit or rollback the executor [beginTransaction] returned.
  final _transactionStarts = Expando<int>('transaction start');

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
  ) => _trace(
    'batch',
    statements.statements.join(';\n'),
    [for (final run in statements.arguments.take(maxBatchArgs)) run.arguments],
    () => executor.runBatched(statements),
    runs: statements.arguments.length,
  );

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    final transaction = super.beginTransaction(parent);
    _transactionStarts[transaction] = _micros();
    return transaction;
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) =>
      _transaction('commit', inner, inner.send);

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) =>
      _transaction('rollback', inner, inner.rollback);

  /// One `debug db.transaction` as it ends; its statements log on their own.
  /// `duration_ms` runs from the begin to the end of the commit or rollback;
  /// `commit_ms` (`rollback_ms`) is that last call alone.
  Future<void> _transaction(
    String outcome,
    TransactionExecutor transaction,
    Future<void> Function() end,
  ) async {
    final endStart = _micros();
    final begin = _transactionStarts[transaction] ?? endStart;
    try {
      await end();
    } on Object catch (error, stackTrace) {
      _failed('transaction', outcome, const [], endStart, error, stackTrace);
      rethrow;
    }
    _log.debug(
      'db.transaction',
      category: LogCategory.db,
      context: {
        'outcome': outcome,
        'duration_ms': _elapsedMs(begin),
        '${outcome}_ms': _elapsedMs(endStart),
      },
    );
  }

  Future<T> _trace<T>(
    String kind,
    String sql,
    List<Object?> args,
    Future<T> Function() run, {
    int? runs,
  }) async {
    final start = _micros();
    final T result;
    try {
      result = await run();
    } on Object catch (error, stackTrace) {
      _failed(kind, sql, args, start, error, stackTrace, runs: runs);
      rethrow;
    }
    _done(kind, sql, args, _elapsedMs(start), runs: runs);
    return result;
  }

  void _failed(
    String kind,
    String sql,
    List<Object?> args,
    int start,
    Object error,
    StackTrace stackTrace, {
    int? runs,
  }) => _log.error(
    'db.query_failed',
    category: LogCategory.db,
    error: _isDraft(sql) ? _DraftStatementError(error) : error,
    stackTrace: stackTrace,
    context: _context(kind, sql, args, _elapsedMs(start), runs),
  );

  void _done(String kind, String sql, List<Object?> args, int ms, {int? runs}) {
    final context = _context(kind, sql, args, ms, runs);
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
    int? runs,
  ) => {
    'kind': kind,
    'sql': sql,
    if (_isDraft(sql))
      'arg_count': args.length
    else
      'args': [for (final arg in args) _arg(arg)],
    'duration_ms': ms,
    'runs': ?runs,
  };

  static bool _isDraft(String sql) => sql.contains(_draftTable);

  // A blob is logged by its size; everything else as it is.
  static Object? _arg(Object? arg) => switch (arg) {
    Uint8List(:final length) => '<blob $length bytes>',
    List<Object?>() => [for (final item in arg) _arg(item)],
    _ => arg,
  };
}

/// What a failing `card_draft` statement logs in place of its error: the
/// driver's message repeats the statement's parameters, which are the draft.
final class _DraftStatementError implements Exception {
  _DraftStatementError(Object cause) : _type = cause.runtimeType;

  final Type _type;

  @override
  String toString() => '$_type on a card_draft statement (message withheld)';
}
