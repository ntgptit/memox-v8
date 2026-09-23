import 'package:sqlite3/sqlite3.dart' as sqlite3;

// SQLite primary result codes (https://sqlite.org/rescode.html). An extended
// code such as SQLITE_CONSTRAINT_CHECK (275) carries its primary code in the
// low byte, which `SqliteException.resultCode` exposes.
const _sqliteBusy = 5;
const _sqliteLocked = 6;
const _sqliteConstraint = 19;

/// Unexpected failures from the database boundary. Never rendered directly —
/// [message] is safe to show, [cause] is for logs only and must never
/// contain card content (card content is never logged, per CLAUDE.md /
/// the spec's error rules).
sealed class Failure {
  const Failure({required this.message, this.cause});
  final String message;
  final Object? cause;
}

final class ConstraintFailure extends Failure {
  const ConstraintFailure({required super.cause})
    : super(message: 'That change breaks a data rule.');
}

final class DatabaseLockedFailure extends Failure {
  const DatabaseLockedFailure({required super.cause})
    : super(message: 'The database is busy. Try again.');
}

final class UnknownDatabaseFailure extends Failure {
  const UnknownDatabaseFailure({required super.cause})
    : super(message: 'Something went wrong.');
}

/// Maps a raw exception from the Drift/sqlite3 boundary to one [Failure].
/// This is the single place that inspects driver-specific error shapes —
/// no repository does this itself.
Failure mapDatabaseError(Object error) {
  if (error is! sqlite3.SqliteException) {
    return UnknownDatabaseFailure(cause: error);
  }
  return switch (error.resultCode) {
    _sqliteConstraint => ConstraintFailure(cause: error),
    _sqliteBusy || _sqliteLocked => DatabaseLockedFailure(cause: error),
    _ => UnknownDatabaseFailure(cause: error),
  };
}
