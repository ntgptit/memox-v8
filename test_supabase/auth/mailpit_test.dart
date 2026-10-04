import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_env.dart';
import 'support/mailpit.dart';

// The local stack and its Mailpit (spec 2026-10-05 §4, §7). Run through
// tools/supabase/run_auth_it.sh.
void main() {
  test('LocalEnv names a missing variable', () {
    expect(
      () => LocalEnv.fromMap(const {}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('MEMOX_IT_API_URL'),
        ),
      ),
    );
  });

  group('local stack', () {
    late LocalEnv env;
    late Mailpit mail;
    late SupabaseClient client;

    setUp(() {
      env = LocalEnv.read();
      mail = Mailpit(env.mailpitUrl);
      client = localClient(env);
    });

    tearDown(() => client.dispose());

    test('a code requested by email arrives through Mailpit', () async {
      final address = freshEmail();
      final asked = DateTime.now().toUtc();
      await client.auth.signInWithOtp(email: address);

      expect(
        await mail.codeFor(address, after: asked),
        matches(RegExp(r'^\d{6}$')),
      );
    });

    test('a second request reads the newer code', () async {
      final address = freshEmail();
      await client.auth.signInWithOtp(email: address);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final second = DateTime.now().toUtc();
      await client.auth.signInWithOtp(email: address);

      final code = await mail.codeFor(address, after: second);
      final response = await client.auth.verifyOTP(
        type: OtpType.email,
        email: address,
        token: code,
      );
      expect(response.session, isNotNull);
    });
  });
}
