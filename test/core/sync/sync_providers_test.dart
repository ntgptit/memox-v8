import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/sync_tables.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../../support/auth_fakes.dart';
import '../../support/deck_fixtures.dart';
import 'fake_sync_server.dart';

import '../../support/test_database.dart';

ProviderContainer _container(SupabaseConfig config) {
  final db = openTestDatabase();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      supabaseConfigProvider.overrideWithValue(config),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

/// Riverpod 3 pauses a provider nobody listens to, so the test listens.
Future<SyncStatus?> _status(ProviderContainer container) =>
    container.listen(syncStatusProvider.future, (_, _) {}).read();

void main() {
  test('a build without Supabase has no status and no commands', () async {
    final container = _container(
      const SupabaseConfig(url: '', publishableKey: ''),
    );

    expect(await _status(container), isNull);
    expect(container.read(syncCommandsProvider), isNull);
  });

  test('a build with Supabase reads the status from Drift', () async {
    final container = _container(
      const SupabaseConfig(url: 'https://x.supabase.co', publishableKey: 'k'),
    );

    final status = await _status(container);
    expect(status?.pendingCount, 0);
  });

  test('the coordinator cannot be built without the root override '
      '(DEV-173)', () {
    final container = _container(
      const SupabaseConfig(url: 'https://x.supabase.co', publishableKey: 'k'),
    );

    expect(
      () => container.read(syncCoordinatorProvider),
      // Riverpod wraps it; the message still names the missing override.
      throwsA(
        predicate(
          (error) => '$error'.contains('override syncAdaptersProvider'),
        ),
      ),
    );
  });

  test('with the app overrides sync covers the seven tables, parent before '
      'child (DEV-173)', () {
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        ...syncTableOverrides,
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    expect(container.read(syncAdaptersProvider).map((a) => a.entityType), [
      'delete_batch',
      'deck',
      'tag',
      'card',
      'card_schedule',
      'review_log',
      'account_settings',
    ]);
    expect(container.read(syncCoordinatorProvider), isNotNull);
  });

  test('a reconnect from networkStatusProvider makes the scheduler run at '
      'once, with no syncNow (DEV-203)', () async {
    final network = FakeNetworkStatus(FakeAuthServer());
    final api = FakeSyncServer();
    var pulls = 0;
    api.beforeChanges = (_) async => pulls++;
    final (:container, db: _) = _app(api, network);
    final scheduler = container.read(syncSchedulerProvider)!;

    scheduler.resume(); // the account is Ready: the first run
    await pumpEventQueue();
    expect(pulls, 1);

    network.goOnline();
    await pumpEventQueue();

    expect(pulls, 2);
  });

  test('a deck made through the repository reaches the server by the '
      "app's own wiring, with no syncNow (DEV-226)", () async {
    final api = FakeSyncServer();
    final (:container, :db) = _app(api, FakeNetworkStatus(FakeAuthServer()));
    final scheduler = container.read(syncSchedulerProvider)!;
    scheduler.resume();
    await pumpEventQueue();
    expect(api.pushCalls, 0, reason: 'nothing pending at the first run');

    final deck = await DeckRepositoryImpl(db).root('Korean');

    // The real debounce (2 s) runs on the wall clock: poll, at most 10 s.
    for (var i = 0; i < 100 && api.row('deck', deck.id) == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(api.row('deck', deck.id), isNotNull);
    expect(api.pushCalls, 1);
  });
}

/// The app's sync providers over a fresh database, a fake server and a
/// fake network: `syncTableOverrides` as `startApp` installs them.
({ProviderContainer container, AppDatabase db}) _app(
  FakeSyncServer api,
  FakeNetworkStatus network,
) {
  final db = openTestDatabase();
  final container = ProviderContainer(
    overrides: [
      ...syncTableOverrides,
      databaseProvider.overrideWithValue(db),
      supabaseConfigProvider.overrideWithValue(
        const SupabaseConfig(url: 'https://x.supabase.co', publishableKey: 'k'),
      ),
      networkStatusProvider.overrideWithValue(network),
      syncApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db);
}
