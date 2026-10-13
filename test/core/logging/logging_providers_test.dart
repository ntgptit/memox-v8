import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/network/supabase_config.dart';

import '../../support/auth_fakes.dart';

LogEntry _entry(int n) => LogEntry(
  id: 'id-$n',
  occurredAt: DateTime.utc(2026, 10, 6).add(Duration(seconds: n)),
  level: LogLevel.info,
  category: LogCategory.lifecycle,
  event: 'lifecycle.start',
);

// DEV-203: the log scheduler ships on the one reconnect signal, the
// network contract's, so a fake network drives it as it drives the
// coordinator.
void main() {
  test(
    'a reconnect from networkStatusProvider ships the buffer at once',
    () async {
      final server = FakeAuthServer();
      final network = FakeNetworkStatus(server);
      final logs = LogDatabase(NativeDatabase.memory());
      var pushes = 0;
      final api = LogApi(
        ensureSession: () async {},
        rpc: (function, params) async {
          pushes++;
          final entries = params['entries']! as List;
          return {
            'accepted': [
              for (final entry in entries)
                (entry! as Map<String, Object?>)['id'],
            ],
          };
        },
      );
      final container = ProviderContainer(
        overrides: [
          supabaseConfigProvider.overrideWithValue(
            const SupabaseConfig(
              url: 'https://x.supabase.co',
              publishableKey: 'k',
            ),
          ),
          logDatabaseProvider.overrideWithValue(logs),
          logApiProvider.overrideWithValue(api),
          networkStatusProvider.overrideWithValue(network),
          isForegroundProvider.overrideWithValue(() => true),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await logs.close();
      });
      await logs.insertAll([_entry(1)]);

      container.read(logSchedulerProvider); // started: the first run ships
      await pumpEventQueue();
      expect(pushes, 1);

      await logs.insertAll([_entry(2)]);
      network.goOnline();
      await pumpEventQueue();

      expect(pushes, 2);
      expect(await logs.count(), 0);
    },
  );
}
