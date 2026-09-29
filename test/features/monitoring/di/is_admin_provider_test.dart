import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/monitoring/di/auth_session_provider.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

import '../../../support/monitoring_fakes.dart';

// ADR-018 §7, monitoring spec §4.4: the entry shows for an admin's session,
// and follows the session when a refreshed token adds the role.
void main() {
  test('an admin role in app_metadata is an admin, nothing else is', () {
    expect(isAdminSession(sessionWithRole('admin')), isTrue);
    expect(isAdminSession(sessionWithRole(null)), isFalse);
    expect(isAdminSession(sessionWithRole('editor')), isFalse);
    expect(isAdminSession(null), isFalse);
  });

  test('a role only in user_metadata is not an admin', () {
    final session = Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: const User(
        id: 'u',
        appMetadata: {},
        userMetadata: {'role': 'admin'},
        aud: 'authenticated',
        createdAt: '2026-09-29T00:00:00Z',
      ),
    );

    expect(isAdminSession(session), isFalse);
  });

  test('a build with no Supabase project has no admin', () {
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(sessionWithRole('admin')),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(isAdminProvider, (_, _) {});

    expect(container.read(isAdminProvider), isFalse);
  });

  // Review focus: a token refresh that adds the admin role while Settings is
  // open.
  test('a refreshed token that adds the role turns it on, and a sign-out '
      'turns it off', () async {
    final sessions = StreamController<Session?>();
    addTearDown(sessions.close);
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(
            url: 'https://x.supabase.co',
            publishableKey: 'k',
          ),
        ),
        authSessionProvider.overrideWith((ref) => sessions.stream),
      ],
    );
    addTearDown(container.dispose);
    final seen = <bool>[];
    container.listen(isAdminProvider, (_, next) => seen.add(next));

    expect(container.read(isAdminProvider), isFalse);
    sessions.add(sessionWithRole(null));
    await pumpEventQueue();
    sessions.add(sessionWithRole('admin'));
    await pumpEventQueue();
    expect(container.read(isAdminProvider), isTrue);
    sessions.add(null);
    await pumpEventQueue();

    expect(container.read(isAdminProvider), isFalse);
    expect(seen, [true, false]);
  });
}
