import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_code_request_provider.g.dart';

/// The address whose code the person already asked for when it turned out
/// to have an account (#17): the layer's target sign-in sends that code
/// itself, once, instead of asking for "Send code" a second time (owner
/// 2026-10-08). Held in memory only, so a recovered switch never resends.
@Riverpod(keepAlive: true)
class SwitchCodeRequest extends _$SwitchCodeRequest {
  @override
  String? build() => null;

  void ask(String email) => state = email;

  void forget() => state = null;

  /// The address asked for, cleared as it is taken.
  String? take() {
    final email = state;
    state = null;
    return email;
  }
}
