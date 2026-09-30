import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';

// Auth spec §5 and O8: the admin entry shows for a confirmed admin only, and
// follows the account; a build with no Supabase project stays local.
const _admin = AccountUser(
  id: 'a',
  isAnonymous: false,
  role: AccountRole.admin,
);
const _user = AccountUser(id: 'u', isAnonymous: false, role: AccountRole.user);

void main() {
  test(
    'a build with no Supabase project is local only and has no admin',
    () async {
      final container = ProviderContainer(
        overrides: [
          supabaseConfigProvider.overrideWithValue(
            const SupabaseConfig(url: '', publishableKey: ''),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(isAdminProvider, (_, _) {});
      await container.read(authStateProvider.future);

      expect(container.read(accountCoordinatorProvider), isNull);
      expect(container.read(authStateProvider).value, isA<LocalOnly>());
      expect(container.read(isAdminProvider), isFalse);
    },
  );

  test(
    'admin follows the confirmed account; validating is not admin yet',
    () async {
      final states = StreamController<AuthState>();
      addTearDown(states.close);
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => states.stream)],
      );
      addTearDown(container.dispose);
      final seen = <bool>[];
      container.listen(isAdminProvider, (_, next) => seen.add(next));

      states.add(const Validating(_admin));
      await pumpEventQueue();
      expect(container.read(isAdminProvider), isFalse);
      states.add(const Ready(_admin));
      await pumpEventQueue();
      expect(container.read(isAdminProvider), isTrue);
      expect(container.read(currentAccountProvider), _admin);
      states.add(const Ready(_user));
      await pumpEventQueue();

      expect(container.read(isAdminProvider), isFalse);
      expect(seen, [true, false]);
    },
  );
}
