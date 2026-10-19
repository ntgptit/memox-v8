import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_account_starting_provider.g.dart';

/// Whether the account is still coming up at launch (`Booting`,
/// `Bootstrapping`): not offline, so the screens show no offline note while
/// they wait for it. `Validating` is not counted: offline with a session it
/// stays there until the network returns, and then the offline note is the
/// truth. `LocalOnly` and the rest are "unavailable", not "starting".
@riverpod
bool isAccountStarting(Ref ref) => switch (ref.watch(authStateProvider)) {
  AsyncData(:final value) => value is Booting || value is Bootstrapping,
  _ => true,
};
