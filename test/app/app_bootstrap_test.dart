import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app_bootstrap.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:memox/features/account/domain/usecases/is_welcome_seen_use_case.dart';
import 'package:memox/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';

import '../support/auth_fakes.dart';
import '../support/test_database.dart';

const _enabled = SupabaseConfig(
  url: 'https://x.supabase.co',
  publishableKey: 'k',
);

/// The account coordinator of an [AuthWorld], its prepare and start recorded
/// and its start held open as a slow network would hold it.
final class _RecordingCoordinator extends AccountCoordinator {
  _RecordingCoordinator(AuthWorld world, this.events, {required this.startGate})
    : super(
        gateway: world.gateway,
        api: world.api,
        store: world.store,
        secrets: world.secrets,
        sync: world.sync,
        localReset: FakeLocalDataReset(world.device),
        gate: world.gate,
        network: world.network,
        logger: AppLogger(sinks: const []),
      );

  final List<String> events;
  final Completer<void> startGate;

  @override
  Future<void> prepare() {
    events.add('prepare');
    return super.prepare();
  }

  @override
  Future<void> start() {
    events.add('start');
    return startGate.future;
  }
}

/// The device repository Welcome asks, its read recorded.
final class _RecordingDevice implements AccountDeviceRepository {
  _RecordingDevice(this.events);

  final List<String> events;

  @override
  Future<bool> isWelcomeSeen() async {
    events.add('welcome');
    return true;
  }

  @override
  Future<void> markWelcomeSeen() async {}

  @override
  Future<LocalLibrary> countLibrary() => throw UnimplementedError();
}

IsWelcomeSeenUseCase _recordingWelcome(List<String> events) =>
    IsWelcomeSeenUseCase(_RecordingDevice(events));

/// A database file under a regular file, so the open fails as it does on a
/// disk that cannot be written, until the blocker is removed.
File _blockedFile(String name) {
  final root = Directory.systemTemp.createTempSync('memox_$name');
  addTearDown(() => root.deleteSync(recursive: true));
  final blocker = File('${root.path}/blocker')..createSync();
  return File('${blocker.path}/app.db');
}

// DEV-176: startApp owns the start order the auth spec (§3.1 R1–R3), FE-A3
// D5, account UI spec U1 and ADR-018 require. DEV-195: a database that cannot
// open ends in a recovery result, logged, instead of an app that never paints.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLogger previous;
  late FlutterExceptionHandler? flutterOnError;
  late ErrorCallback? dispatcherOnError;
  late LogDatabase logs;
  final supabaseInits = <SupabaseConfig>[];

  setUp(() {
    previous = appLogger;
    flutterOnError = FlutterError.onError;
    dispatcherOnError = PlatformDispatcher.instance.onError;
    logs = LogDatabase(NativeDatabase.memory());
    supabaseInits.clear();
  });

  tearDown(() async {
    AppLogger.install(previous);
    FlutterError.onError = flutterOnError;
    PlatformDispatcher.instance.onError = dispatcherOnError;
    await logs.close();
  });

  Future<void> recordSupabase(SupabaseConfig config) async =>
      supabaseInits.add(config);

  /// Sync on, the log buffer in memory, no reminder plugins, and the
  /// schedulers as [overrides] say: a test that records them passes its own.
  ProviderContainer container(List<Override> overrides) {
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(_enabled),
        logDatabaseProvider.overrideWithValue(logs),
        reminderPluginsDataSourceProvider.overrideWithValue(null),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the start runs in the order the specs fix: logger, Supabase, the '
      'database, prepare, Welcome, both schedulers, start; and it returns '
      'while start() still waits (R1, R2)', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final world = AuthWorld()..boot();
    addTearDown(world.close);
    final events = <String>[];
    final startGate = Completer<void>();
    final coordinator = _RecordingCoordinator(
      world,
      events,
      startGate: startGate,
    );
    addTearDown(coordinator.dispose);
    final c = container([
      databaseProvider.overrideWithValue(db),
      accountCoordinatorProvider.overrideWithValue(coordinator),
      isWelcomeSeenUseCaseProvider.overrideWithValue(_recordingWelcome(events)),
      syncSchedulerProvider.overrideWith((ref) {
        events.add('sync scheduler');
        return null;
      }),
      logSchedulerProvider.overrideWith((ref) {
        events.add('log scheduler');
        return null;
      }),
    ]);

    final result = await startApp(c, initializeSupabase: recordSupabase);

    expect(result, isA<StartupReady>());
    expect(supabaseInits, [_enabled]);
    expect(events, [
      'prepare',
      'welcome',
      'sync scheduler',
      'log scheduler',
      'start',
    ]);
    expect(startGate.isCompleted, isFalse);
    startGate.complete();
  });

  test(
    'a database that cannot open ends in StartupDatabaseUnavailable, '
    'logged to the buffer, with no step after the guard run (DEV-195)',
    () async {
      final file = _blockedFile('full');
      final events = <String>[];
      final c = container([
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase(file));
          ref.onDispose(db.close);
          return db;
        }),
        isWelcomeSeenUseCaseProvider.overrideWithValue(
          _recordingWelcome(events),
        ),
        syncSchedulerProvider.overrideWith((ref) {
          events.add('sync scheduler');
          return null;
        }),
        logSchedulerProvider.overrideWithValue(null),
      ]);

      final result = await startApp(c, initializeSupabase: recordSupabase);

      expect(
        result,
        isA<StartupDatabaseUnavailable>().having(
          (r) => r.error,
          'error',
          isA<FileSystemException>(),
        ),
      );
      expect(events, isEmpty);
      await appLogger.flush();
      final rows = await logs.oldest(10);
      expect(
        rows.map((r) => r.event),
        contains('lifecycle.database_unavailable'),
      );
    },
  );

  test('Retry opens the database again from a fresh connection and, once the '
      'file opens, finishes the start (DEV-195)', () async {
    final file = _blockedFile('busy');
    var opens = 0;
    final c = container([
      databaseProvider.overrideWith((ref) {
        opens++;
        final db = AppDatabase(NativeDatabase(file));
        ref.onDispose(db.close);
        return db;
      }),
      accountCoordinatorProvider.overrideWithValue(null),
      syncSchedulerProvider.overrideWithValue(null),
      logSchedulerProvider.overrideWithValue(null),
    ]);

    final first = await startApp(c, initializeSupabase: recordSupabase);
    expect(first, isA<StartupDatabaseUnavailable>());

    File(file.parent.path).deleteSync(); // the disk is back
    final second = await retryStartApp(c);

    expect(second, isA<StartupReady>());
    expect(opens, 2);
  });

  test("after the start the tracer's switch follows the account's row, and "
      'again after Retry (SQL log switch spec §4.3)', () async {
    var db = openTestDatabase();
    addTearDown(() => db.close());
    final c = container([
      databaseProvider.overrideWith((ref) => db),
      accountCoordinatorProvider.overrideWithValue(null),
      syncSchedulerProvider.overrideWithValue(null),
      logSchedulerProvider.overrideWithValue(null),
    ]);

    expect(
      await startApp(c, initializeSupabase: recordSupabase),
      isA<StartupReady>(),
    );
    final sqlLog = c.read(sqlLogSwitchProvider);
    expect(sqlLog.value, isTrue);
    await db.customUpdate(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
      updates: {db.appSettings},
    );
    await pumpEventQueue();
    expect(sqlLog.value, isFalse);

    // Retry opens a new database: the switch follows the new row.
    final old = db;
    db = openTestDatabase();
    expect(await retryStartApp(c), isA<StartupReady>());
    await pumpEventQueue();
    expect(sqlLog.value, isTrue);
    await old.close();
  });

  test('the reminder reconciles through one path: the lifecycle hooks', () {
    final readers = Directory('lib/app')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => f.readAsStringSync().contains('reconcileReminderProvider'),
        )
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(readers, ['lib/app/app_lifecycle_hooks.dart']);
  });
}
