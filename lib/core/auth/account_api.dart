import 'package:memox/core/auth/account_user.dart';

/// The account RPCs of migration 20261010 (auth spec §2.3). Every method
/// throws a `Failure`.
abstract interface class AccountApi {
  /// The caller's account; also marks it active.
  Future<AccountUser> me();

  /// A one-time token for this anonymous user's data (15 minutes).
  Future<String> claimBegin();

  /// Moves the claimed user's data into the caller's account; idempotent by
  /// [operationId] (a retry after a lost answer succeeds).
  Future<void> merge(String token, String operationId);

  /// The device has pulled the merged library; the receipt can go.
  Future<void> mergeAck(String operationId);

  Future<void> deleteAccount();
}
