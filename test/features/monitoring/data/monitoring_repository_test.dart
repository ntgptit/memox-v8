import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// Monitoring spec §5: FORBIDDEN is not an admin, a network error is offline,
// and the buffer is read through the log database.
void main() {
  late LogDatabase local;
  late List<(String, Map<String, Object?>)> calls;
  Object? Function(String function) answer = (_) => null;
  final now = DateTime.utc(2026, 9, 29, 12);

  MonitoringRepositoryImpl repository() => MonitoringRepositoryImpl(
    remote: MonitoringRemoteDataSource(
      rpc: (function, params) async {
        calls.add((function, params));
        final result = answer(function);
        if (result is Exception) throw result;
        return result;
      },
      hasSession: () => true,
    ),
    local: local,
  );

  Map<String, Object?> compact(int i) => {
    'id': 'r$i',
    'occurred_at': DateTime.utc(2026, 9, 29, 11, 59 - i % 60).toIso8601String(),
    'level': 'error',
    'event': 'sync.failed',
    'message': 'm$i',
    'status': 'open',
  };

  setUp(() {
    local = LogDatabase(NativeDatabase.memory());
    calls = [];
    answer = (_) => null;
  });
  tearDown(() => local.close());

  test('a page maps its rows, and a full page has a next cursor', () async {
    answer = (_) => {
      'items': [for (var i = 0; i < LogPage.size; i++) compact(i)],
    };

    final page = await repository().queryServer(
      const LogFilter(),
      null,
      now: now,
    );

    expect(page.items, hasLength(100));
    expect(page.next!.id, 'r99');
    final sent = calls.single.$2['filter']! as Map<String, Object?>;
    expect(sent['levels'], ['warning', 'error']);
  });

  test('a short page is the last', () async {
    answer = (_) => {
      'items': [compact(0)],
    };

    final page = await repository().queryServer(
      const LogFilter(),
      null,
      now: now,
    );

    expect(page.next, isNull);
  });

  test('FORBIDDEN is a NotAdminFailure, for a read and a change', () async {
    answer = (_) => const PostgrestException(message: 'FORBIDDEN');

    await expectLater(
      repository().queryServer(const LogFilter(), null, now: now),
      throwsA(isA<NotAdminFailure>()),
    );
    await expectLater(
      repository().setStatus('a', LogStatus.fixed, null),
      throwsA(isA<NotAdminFailure>()),
    );
  });

  test('a network error is an OfflineFailure', () async {
    answer = (_) => const SocketException('no route');

    await expectLater(
      repository().queryServer(const LogFilter(), null, now: now),
      throwsA(isA<OfflineFailure>()),
    );
    await expectLater(
      repository().getServer('a'),
      throwsA(isA<OfflineFailure>()),
    );
  });

  test('a log that is gone is null', () async {
    answer = (_) => const PostgrestException(message: 'NOT_FOUND');

    expect(await repository().getServer('a'), isNull);
    expect(await repository().setStatus('a', LogStatus.open, null), isNull);
  });

  test('the row the server returns after a change is the record', () async {
    answer = (_) => {
      'id': 'a',
      'occurred_at': '2026-09-26T08:30:15+00:00',
      'level': 'error',
      'category': 'sync',
      'event': 'sync.failed',
      'status': 'fixed',
      'status_note': 'index added',
    };

    final record = await repository().setStatus(
      'a',
      LogStatus.fixed,
      'index added',
    );

    expect(record!.status, LogStatus.fixed);
    expect(record.statusNote, 'index added');
  });

  test('the buffer is watched and read through the log database', () async {
    await local.insertAll([
      LogEntry(
        id: 'a',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.sync,
        event: 'sync.failed',
        message: 'boom',
        stackTrace: '#0 x',
      ),
      LogEntry(
        id: 'b',
        occurredAt: now,
        level: LogLevel.debug,
        category: LogCategory.db,
        event: 'db.query',
      ),
    ]);

    final pending = await repository().watchPending({LogLevel.error}).first;
    final record = await repository().getPending('a');

    expect(pending.items.map((row) => row.id), ['a']);
    expect(pending.total, 2);
    expect(record!.stackTrace, '#0 x');
    expect(await repository().getPending('nope'), isNull);
  });

  test('a buffer read that fails is a database Failure', () async {
    await local.customStatement('DROP TABLE log_entry');

    await expectLater(
      repository().getPending('a'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });
}
