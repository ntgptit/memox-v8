import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/account_harness.dart';
import '../../support/auth_fakes.dart';

User _user({List<String> providers = const [], String? email}) =>
    User.fromJson({
      'id': 'u1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-09-30T00:00:00Z',
      'email': ?email,
      'identities': [
        for (final (index, provider) in providers.indexed)
          {
            'id': 'i$index',
            'user_id': 'u1',
            'identity_data': <String, dynamic>{},
            'provider': provider,
          },
      ],
    })!;

void main() {
  group('signInMethodsOf', () {
    test('reads the identities GoTrue lists', () {
      expect(signInMethodsOf(_user(providers: ['google'])), {
        SignInMethod.google,
      });
      expect(signInMethodsOf(_user(providers: ['email', 'google'])), {
        SignInMethod.email,
        SignInMethod.google,
      });
    });

    test('an unknown provider and no session name nothing', () {
      expect(signInMethodsOf(_user(providers: ['anonymous'])), isEmpty);
      expect(signInMethodsOf(null), isEmpty);
    });
  });

  group('the coordinator and its provider', () {
    late AuthWorld world;
    late ProviderContainer container;

    setUp(() async {
      world = AuthWorld();
      await readyAnonymous(world);
      container = ProviderContainer(overrides: accountOverrides(world));
      container.listen(signInMethodsProvider, (_, _) {});
    });
    tearDown(() async {
      container.dispose();
      await world.close();
    });

    test('an anonymous user has no method; a linked email has one', () async {
      expect(world.coordinator.signInMethods, isEmpty);

      await linkEmail(world);
      await pumpEventQueue();

      expect(world.coordinator.signInMethods, {SignInMethod.email});
      expect(container.read(signInMethodsProvider), {SignInMethod.email});
    });

    test('the UI and the coordinator share one network status', () {
      expect(container.read(networkStatusProvider), same(world.network));
    });
  });
}
