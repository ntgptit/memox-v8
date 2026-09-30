import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_manage_controller.g.dart';

/// What an account command came to, for the screen to say.
enum AccountCommandResult {
  /// It ran; the transition layer shows the rest.
  done,

  /// Nothing ran: another command is running.
  none,

  /// Refused before anything changed: no network.
  offline,

  /// Refused before anything changed.
  failed,
}

/// Screen 32's and screen 30's account commands (account UI spec §5.6, §9):
/// what a sign-out would lose and whether a deletion can go, read once as
/// their dialog opens (B2), then the command. The state is true while one
/// runs.
@riverpod
class AccountManageController extends _$AccountManageController {
  @override
  bool build() => false;

  /// None online; offline, the changes not sent yet (spec §9 B4).
  Future<int> changesLostBySignOut() async {
    if (await ref.read(networkStatusProvider).isOnline) return 0;
    return ref.read(syncControlProvider).pendingCount();
  }

  /// A deletion needs the network (spec §9 B6).
  Future<bool> canDelete() => ref.read(networkStatusProvider).isOnline;

  /// R1: the target sign-in happens inside the transition layer.
  Future<AccountCommandResult> switchAccount() => _run(
    (accounts) => accounts.beginSwitch(choice: TransitionChoice.discard),
  );

  Future<AccountCommandResult> signOut({required bool discardUnsent}) =>
      _run((accounts) => accounts.signOut(discardUnsent: discardUnsent));

  Future<AccountCommandResult> deleteAccount() =>
      _run((accounts) => accounts.deleteAccount());

  /// From an expired sign-in (screen 30, spec §9 B8).
  Future<AccountCommandResult> continueWithoutAccount() =>
      _run((accounts) => accounts.continueWithoutAccount());

  Future<AccountCommandResult> _run(
    Future<void> Function(AccountCoordinator accounts) command,
  ) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || state) return AccountCommandResult.none;
    state = true;
    var result = AccountCommandResult.done;
    try {
      await command(accounts);
    } on OfflineFailure {
      result = AccountCommandResult.offline;
    } on Failure {
      result = AccountCommandResult.failed;
    } on StateError {
      // The account moved on meanwhile: P2 runs these only in Ready.
      result = AccountCommandResult.failed;
    }
    if (ref.mounted) state = false;
    return result;
  }
}
