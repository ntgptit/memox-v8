import 'package:flutter/foundation.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The copy a database [Failure] shows (ruling L2). It never shows the
/// failure's cause, and it says first that nothing was lost where that is
/// true (PRODUCT.md, Brand commitments; BR-CORE-005).
extension FailureMessage on AppLocalizations {
  String failure(Failure failure) => switch (failure) {
    ConstraintFailure() => failureConstraint,
    DatabaseLockedFailure() => failureBusy,
    UnknownDatabaseFailure() => failureUnknown,
    NotAdminFailure() => failureNotAdmin,
    OfflineFailure() => failureOffline,
    ServerFailure() => failureServer,
    MutationBlockedFailure() => failureAccountBusy,
    AuthFailure() => failureAccount,
  };
}

/// What a write's catch-all tells the person. A database [Failure] is told as
/// it is; anything else is reported (as the card editor's and the import
/// undo's catch-alls do) and told as an unknown failure. Either way the
/// caller releases its busy flag and keeps its form for another try
/// (SP2b 2.26, 2.27).
Failure failureOfThrown(
  Object error,
  StackTrace stack, {
  required String library,
}) {
  if (error is Failure) return error;
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stack, library: library),
  );
  return UnknownDatabaseFailure(cause: error);
}
