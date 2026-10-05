import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/supabase_account_api.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_control.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../test/support/fake_secret_store.dart';
import '../../../test/support/test_database.dart';
import 'local_env.dart';
import 'mailpit.dart';

/// The network as a device sees it (spec 2026-10-05 §3): while it is off the
/// status says so and every request fails, so "offline" holds whichever the
/// coordinator meets first.
class SwitchableNetwork implements NetworkStatus {
  var online = true;
  final _reconnects = StreamController<void>.broadcast();

  void setOnline(bool value) {
    final back = value && !online;
    online = value;
    if (back) _reconnects.add(null);
  }

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<void> get reconnects => _reconnects.stream;
}

class SwitchableHttpClient extends http.BaseClient {
  SwitchableHttpClient(this._network);

  final SwitchableNetwork _network;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!_network.online) throw const SocketException('offline');
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

typedef StoreFor = AccountStore Function(AppDatabase db);

/// One device built from the app's own classes, the way
/// `accountCoordinatorProvider` and sync_providers.dart wire them, on a real
/// local stack. Only the secret store and the network are fakes.
class LocalDevice {
  LocalDevice._(this.env, this.db, this.secrets, this.network, this.client);

  final LocalEnv env;
  final AppDatabase db;
  final FakeSecretStore secrets;
  final SwitchableNetwork network;
  final SupabaseClient client;
  late AccountCoordinator coordinator;
  late SyncCoordinator _sync;

  static Future<LocalDevice> launch(LocalEnv env, {StoreFor? store}) async {
    final network = SwitchableNetwork();
    final client = localClient(env, httpClient: SwitchableHttpClient(network));
    final device = LocalDevice._(
      env,
      openTestDatabase(),
      FakeSecretStore(),
      network,
      client,
    );
    await device._boot(store);
    return device;
  }

  /// The app restarted: a new coordinator on the same client, database and
  /// secrets, as the SDK's storage, Drift and the keystore survive a kill.
  Future<void> reboot({StoreFor? store}) async {
    await coordinator.dispose();
    await _boot(store);
  }

  Future<void> _boot(StoreFor? store) async {
    Future<Object?> rpc(String function, Map<String, Object?> params) =>
        client.rpc<Object?>(function, params: params);
    final syncStore = SyncStore(db);
    final cards = CardSyncAdapter(db);
    _sync = SyncCoordinator(
      api: SupabaseSyncApi(
        ensureSession: () async {
          if (client.auth.currentSession == null) {
            throw const SyncSessionMissing();
          }
        },
        rpc: rpc,
      ),
      store: syncStore,
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, syncStore),
        cards,
        CardScheduleSyncAdapter(db, syncStore),
        ReviewLogSyncAdapter(db),
        AccountSettingsSyncAdapter(db),
      ],
      afterPull: cards.ensureSchedules,
    );
    coordinator = AccountCoordinator(
      gateway: SupabaseAuthGateway(
        client.auth,
        pickGoogle: () => throw UnsupportedError('no Google here'),
      ),
      api: SupabaseAccountApi(
        rpc: rpc,
        refreshSession: () async {
          await client.auth.refreshSession();
        },
      ),
      store: (store ?? AccountStore.new)(db),
      secrets: secrets,
      // Sync runs only through syncNow(), so every test syncs where it
      // means to.
      sync: AppSyncControl(
        scheduler: null,
        coordinator: _sync,
        store: syncStore,
      ),
      localReset: LocalDataReset(db),
      gate: db.mutationGate,
      network: network,
      retryDelay: (_) => Duration.zero,
      logger: AppLogger(sinks: const []),
    );
    await coordinator.prepare();
    await coordinator.start();
    await waitFor<Ready>();
  }

  String? get userId => client.auth.currentSession?.user.id;

  AuthState get state => coordinator.state;

  /// The first state of type [T], now or later.
  Future<T> waitFor<T extends AuthState>({
    Duration timeout = const Duration(seconds: 20),
    bool Function(T state)? where,
  }) async {
    bool matches(AuthState s) => s is T && (where?.call(s) ?? true);
    if (matches(state)) return state as T;
    final next = await coordinator
        .watch()
        .firstWhere(matches)
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'No ${T.toString()} on this device; last state $state',
            timeout,
          ),
        );
    return next as T;
  }

  Future<String> createDeck(String name) async {
    final created = await DeckRepositoryImpl(db)
        .createRootDeck(name: name, schedulerType: SchedulerType.eightBox);
    return switch (created) {
      Ok(:final value) => value.id,
      Rejected(:final reason) => throw StateError('Deck refused: $reason'),
    };
  }

  /// The names of this device's decks, trash excluded.
  Future<Set<String>> deckNames() async {
    final rows = await db
        .customSelect('SELECT name FROM deck WHERE delete_batch_id IS NULL')
        .get();
    return {for (final row in rows) row.read<String>('name')};
  }

  Future<void> syncNow() => _sync.runOnce();

  /// The coordinator's own path: ask, read the mail, verify.
  Future<void> signInByEmail(Mailpit mail, String email) async {
    final asked = DateTime.now().toUtc();
    await coordinator.requestCode(email);
    final code = await mail.codeFor(email, after: asked);
    await coordinator.verifyCode(email, code);
  }

  Future<void> close() async {
    await coordinator.dispose();
    await client.dispose();
    await db.close();
  }
}
