import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_account_provider.g.dart';

/// The account this device's data belongs to (account UI spec §9 B3): the
/// confirmed one, or the last known while it is checked again or refused.
/// None on an anonymous device, while starting, and during a transition.
AccountUser? deviceAccountOf(AuthState? state) => switch (state) {
  Ready(:final user) when !user.isAnonymous => user,
  Validating(:final last?) when !last.isAnonymous => last,
  ReauthRequired(:final last) => last,
  _ => null,
};

/// [deviceAccountOf] the current state, for 23, 30 and 32.
@riverpod
AccountUser? deviceAccount(Ref ref) =>
    deviceAccountOf(ref.watch(authStateProvider).value);
