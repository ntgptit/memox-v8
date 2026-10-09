import 'dart:async';

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/google_credential_source.dart';
import 'package:memox/core/auth/secure_secret_store.dart';
import 'package:memox/core/auth/supabase_account_api.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Returns the synced settings to their defaults inside LocalDataReset's
/// transaction; the device's own columns (reminder, welcome) stay. Overridden
/// at the composition root by the settings feature (DEV-173).
@Riverpod(keepAlive: true)
Future<void> Function() syncedSettingsReset(Ref ref) => throw StateError(
  'override syncedSettingsResetProvider at the root (lib/app/sync_tables.dart)',
);

/// The account's one owner (auth spec §5). Null when this build names no
/// Supabase project (plan ruling 20). `startApp` (app_bootstrap.dart) prepares and starts it.
@Riverpod(keepAlive: true)
AccountCoordinator? accountCoordinator(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return null;
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(dayClockProvider);
  final google = GoogleCredentialSource();
  final coordinator = AccountCoordinator(
    gateway: SupabaseAuthGateway.instance(pickGoogle: google.pick),
    api: SupabaseAccountApi.instance(),
    store: AccountStore(db),
    secrets: SecureSecretStore(),
    sync: ref.watch(syncControlProvider),
    localReset: LocalDataReset(
      db,
      resetSyncedSettings: ref.watch(syncedSettingsResetProvider),
    ),
    gate: db.mutationGate,
    network: ref.watch(networkStatusProvider),
    flushLogs: () async {
      await ref.read(logSchedulerProvider)?.syncNow();
    },
    now: clock.now,
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
}

/// Where the account stands: the single source of truth for sync, the
/// router and every screen (auth spec §5).
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  final coordinator = ref.watch(accountCoordinatorProvider);
  if (coordinator == null) return Stream.value(const LocalOnly());
  return coordinator.watch();
}

/// The account `me()` confirmed, or null until one is.
@Riverpod(keepAlive: true)
AccountUser? currentAccount(Ref ref) =>
    switch (ref.watch(authStateProvider).value) {
      Ready(:final user) => user,
      _ => null,
    };

/// Whether to show admin entries (ADR-018 §7, auth spec O8): a confirmed
/// account whose `profiles.role` is admin. Visibility only: the RPCs check
/// again (`FORBIDDEN`).
@Riverpod(keepAlive: true)
bool isAdmin(Ref ref) => ref.watch(currentAccountProvider)?.isAdmin ?? false;

/// How the signed-in account signs in, again on every account change
/// (account UI spec §9 B1).
@riverpod
Set<SignInMethod> signInMethods(Ref ref) {
  ref.watch(authStateProvider);
  return ref.watch(accountCoordinatorProvider)?.signInMethods ?? const {};
}
