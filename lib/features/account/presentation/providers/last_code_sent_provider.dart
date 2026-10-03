import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_code_sent_provider.g.dart';

/// The last sign-in code this app run sent: for which sign-in, to which
/// address, and when.
typedef CodeSent = ({SignInPurpose purpose, String email, DateTime sentAt});

/// Which code is on its way, so leaving the code step and coming back, or
/// pressing "Send code" again for the same address, does not ask the server
/// for another one inside the resend wait (SP2b 2.41, 2.44). In memory and
/// feature-local; only the last send is held.
@Riverpod(keepAlive: true)
class LastCodeSent extends _$LastCodeSent {
  @override
  CodeSent? build() => null;

  /// A code went to [email] for [purpose] at [at].
  void record(SignInPurpose purpose, String email, DateTime at) =>
      state = (purpose: purpose, email: _keyOf(email), sentAt: at);

  /// What is left of [wait] since the last recorded send, in whole seconds
  /// (rounded up, never above [wait], so a clock set back adds nothing). Null
  /// when the last send was to another address or purpose, or none was
  /// recorded: the caller decides what that means.
  Duration? waitLeft(
    SignInPurpose purpose,
    String email,
    DateTime now,
    Duration wait,
  ) {
    final last = state;
    if (last == null ||
        last.purpose != purpose ||
        last.email != _keyOf(email)) {
      return null;
    }
    final left = wait - now.difference(last.sentAt);
    if (left <= Duration.zero) return Duration.zero;
    if (left >= wait) return wait;
    return Duration(
      seconds: (left.inMicroseconds / Duration.microsecondsPerSecond).ceil(),
    );
  }
}

/// "A@x.com" and "a@x.com " are one address.
String _keyOf(String email) => email.trim().toLowerCase();
