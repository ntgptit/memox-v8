import 'package:memox/features/account/domain/models/local_library_model.dart';

/// What the account screens read and write on this device alone (account
/// UI spec §3). The account itself belongs to the core coordinator. The one
/// implementation is `AccountDeviceRepositoryImpl`; the contract keeps
/// domain framework-free (ADR-010).
abstract interface class AccountDeviceRepository {
  /// Whether Welcome was answered on this device (`welcome_seen`).
  Future<bool> isWelcomeSeen();

  /// Records the answer. Device-only: a sign-out's reset keeps it, and sync
  /// never sends it.
  Future<void> markWelcomeSeen();

  /// The live decks and cards on this device.
  Future<LocalLibrary> countLibrary();
}
