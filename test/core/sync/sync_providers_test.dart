import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_status.dart';

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
}
