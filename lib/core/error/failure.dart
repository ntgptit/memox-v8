import 'dart:async';

import 'package:drift/isolate.dart' show DriftRemoteException;
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
///
/// The app's connection runs in a background isolate (drift_flutter), where
/// a [sqlite3.SqliteException] arrives wrapped in a [DriftRemoteException].
/// A [Failure] is already mapped: a repository that runs inside another's
/// transaction maps first, and the outer one must not wrap it again.
Failure mapDatabaseError(Object error) {
  if (error is Failure) return error;
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  if (cause is! sqlite3.SqliteException) {
    return UnknownDatabaseFailure(cause: cause);
  }
  return switch (cause.resultCode) {
    _sqliteConstraint => ConstraintFailure(cause: cause),
    _sqliteBusy || _sqliteLocked => DatabaseLockedFailure(cause: cause),
    _ => UnknownDatabaseFailure(cause: cause),
  };
}

/// A watch reports its database errors the way a one-shot read does.
extension DatabaseErrorStream<T> on Stream<T> {
  Stream<T> mapDatabaseErrors() => transform(
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(mapDatabaseError(error), stackTrace),
    ),
  );
}
