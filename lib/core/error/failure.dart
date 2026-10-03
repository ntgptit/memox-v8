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
/// [message] is safe to show; [cause] is for logs only and is never shown to
/// the user (BR-CORE-005). It is logged whole, card content included
/// (ADR-018: nothing is redacted).
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

/// A read or change only an admin may make, from a caller that is not one or
/// has no session (ADR-018 §7). The server's `FORBIDDEN`.
final class NotAdminFailure extends Failure {
  const NotAdminFailure({required super.cause})
    : super(message: 'Only an admin can see this.');
}

/// A server call that never reached the server (no connection, a timeout).
/// The kind of failure sync calls `network`.
final class OfflineFailure extends Failure {
  const OfflineFailure({required super.cause})
    : super(message: "Can't reach the server.");
}

/// The server was reached and could not answer: an error of its own, or an
/// answer this build cannot read.
final class ServerFailure extends Failure {
  const ServerFailure({required super.cause})
    : super(message: "The server couldn't answer.");
}

/// How an identity was being attached when it turned out to belong to
/// another account (auth spec §3.2 `IDENTITY_TAKEN`).
enum IdentityMethod { email, google }

/// An account step that the server or the identity provider refused (auth
/// spec §3.2, §5). A call that never arrived stays [OfflineFailure], and an
/// admin-only refusal stays [NotAdminFailure] (plan ruling 1).
sealed class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.cause});
}

/// The SDK's session was refused: its refresh token, session or user is gone.
final class SessionInvalidFailure extends AuthFailure {
  const SessionInvalidFailure({super.cause})
    : super(message: 'The sign-in is no longer valid.');
}

/// A live token whose user no longer has a profile: the account was
/// deleted (`me()` → `UNAUTHORIZED`).
final class ProfileGoneFailure extends AuthFailure {
  const ProfileGoneFailure({super.cause})
    : super(message: 'This account no longer exists.');
}

final class IdentityTakenFailure extends AuthFailure {
  const IdentityTakenFailure({required this.method, super.cause})
    : super(message: 'That sign-in belongs to another account.');

  final IdentityMethod method;
}

/// A code the server refused. GoTrue answers a wrong and an expired code
/// alike (plan ruling 2).
final class InvalidCodeFailure extends AuthFailure {
  const InvalidCodeFailure({super.cause})
    : super(message: 'The code is wrong or has expired.');
}

final class RateLimitedFailure extends AuthFailure {
  const RateLimitedFailure({super.cause})
    : super(message: 'Too many attempts. Wait, then try again.');
}

/// An address the server refused as not a valid one (GoTrue
/// `email_address_invalid`, or a `validation_failed` about the email). The
/// field says "check the address", not "try again" (SP2b 2.42).
final class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure({super.cause})
    : super(message: 'That email address is not valid.');
}

/// The claim token was used, expired or never existed (`CLAIM_INVALID`).
final class ClaimInvalidFailure extends AuthFailure {
  const ClaimInvalidFailure({super.cause})
    : super(message: 'The merge could not be completed.');
}

final class LastAdminFailure extends AuthFailure {
  const LastAdminFailure({super.cause})
    : super(message: 'An admin must remain.');
}

final class AnonymousUserFailure extends AuthFailure {
  const AnonymousUserFailure({super.cause})
    : super(message: 'An anonymous user cannot be an admin.');
}

final class GoogleCancelledFailure extends AuthFailure {
  const GoogleCancelledFailure({super.cause})
    : super(message: 'Google sign-in was cancelled.');
}

/// Signing in again as another account would clear [count] changes not yet
/// sent; the caller asks first (plan ruling 6).
final class UnsentChangesFailure extends AuthFailure {
  const UnsentChangesFailure({required this.count})
    : super(message: 'Changes on this phone are not sent yet.');

  final int count;
}

/// A business write while the account is changing (R3). Nothing was
/// written.
final class MutationBlockedFailure extends Failure {
  const MutationBlockedFailure()
    : super(message: 'The account is changing. Try again in a moment.');
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

/// [body], with an unexpected database error leaving as the [Failure]
/// [mapDatabaseError] makes of it, with its original stack trace. The Future
/// twin of [DatabaseErrorStream.mapDatabaseErrors]; a closure, so a throw
/// before the body's first await is mapped too.
Future<T> guardDatabase<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Object catch (error, stackTrace) {
    Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
  }
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
