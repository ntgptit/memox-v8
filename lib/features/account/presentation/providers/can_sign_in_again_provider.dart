import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_sign_in_again_provider.g.dart';

/// Whether screen 30's reauth form can act: P2 takes a re-auth only while
/// the session is refused (auth spec #36, #37).
@riverpod
bool canSignInAgain(Ref ref) =>
    ref.watch(authStateProvider).value is ReauthRequired;
