import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_link_provider.g.dart';

/// Whether this device can attach an account now: P2 links only the
/// anonymous user of `Ready`. Offline at first launch it cannot (plan
/// ruling 6).
@riverpod
bool canLink(Ref ref) => switch (ref.watch(authStateProvider).value) {
  Ready(:final user) => user.isAnonymous,
  _ => false,
};
