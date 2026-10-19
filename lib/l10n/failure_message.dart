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

  /// The copy for a held flow's end ([runHeld]): the [failure]'s, or
  /// the unknown one for a bug.
  String heldFailure(Failure? failure) =>
      failure == null ? failureUnknown : this.failure(failure);
}
