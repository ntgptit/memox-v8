import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/mappers/log_mapper.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

// Monitoring spec §5: JSON to entity, missing fields, and the filter to JSON.
void main() {
  final now = DateTime.utc(2026, 9, 29, 12);

  test('the default filter asks for open warnings and errors, 100 a page', () {
    expect(queryFilterOf(const LogFilter(), null, now), {
      'levels': ['warning', 'error'],
      'statuses': ['open'],
      'limit': 100,
    });
  });

  test('a choice left open is left out, never an empty list', () {
    final json = queryFilterOf(
      const LogFilter().withLevels({}).withStatuses({}),
      null,
      now,
    );

    expect(json, {'limit': 100});
  });

  test('every choice is sent, the time as a moment, the device as a list', () {
    final filter = const LogFilter()
        .withCategories({LogCategory.db, LogCategory.sync})
        .withWindow(LogWindow.day)
        .withDevice('dev-1')
        .withUser('00000000-0000-0000-0000-00000000dead')
        .withSearch('push');
    final after = LogCursor(
      occurredAt: DateTime.utc(2026, 9, 29, 11, 30, 5, 123, 456),
      id: 'row-9',
    );

    expect(queryFilterOf(filter, after, now), {
      'levels': ['warning', 'error'],
      'statuses': ['open'],
      'categories': ['db', 'sync'],
      'search': 'push',
      'from': '2026-09-28T12:00:00.000Z',
      'deviceIds': ['dev-1'],
      'userId': '00000000-0000-0000-0000-00000000dead',
      'before': {'occurredAt': '2026-09-29T11:30:05.123456Z', 'id': 'row-9'},
      'limit': 100,
    });
  });

  test('a compact row becomes a summary', () {
    final row = summaryOfJson({
      'id': 'a',
      'occurred_at': '2026-09-29T10:00:00.5+00:00',
      'level': 'warning',
      'event': 'sync.rejected',
      'message': 'first line\nsecond',
      'error_message': 'Bad state: closed',
      'error_type': null,
      'status': 'open',
      'category': 'sync',
      'device_id': 'dev-1',
    });

    expect(row.occurredAt, DateTime.utc(2026, 9, 29, 10, 0, 0, 500));
    expect(row.level, LogLevel.warning);
    expect(row.status, LogStatus.open);
    expect(row.errorMessage, 'Bad state: closed');
    expect(row.subtitle, 'first line');
  });

  test('a compact row of a level with no status has none', () {
    final row = summaryOfJson({
      'id': 'a',
      'occurred_at': '2026-09-29T10:00:00+00:00',
      'level': 'debug',
      'event': 'db.query',
      'status': null,
    });

    expect(row.status, isNull);
    expect(row.message, isNull);
    expect(row.subtitle, isNull);
  });

  Map<String, Object?> full() => {
    'id': 'a',
    'occurred_at': '2026-09-26T08:30:15.25+00:00',
    'level': 'error',
    'source': 'server',
    'category': 'network',
    'event': 'server.exception',
    'message': 'boom',
    'error_type': 'StateError',
    'error_message': 'Bad state',
    'stack_trace': '#0 main',
    'context': {
      'sql': 'SELECT 1',
      'args': [1, 2],
    },
    'user_id': '00000000-0000-0000-0000-00000000dead',
    'device_id': 'dev-1',
    'app_version': '8.0.0',
    'build_number': '12',
    'platform': 'android',
    'os_version': '14',
    'status': 'fixed',
    'status_changed_at': '2026-09-27T09:00:00+00:00',
    'status_changed_by': '00000000-0000-0000-0000-0000000000ad',
    'status_note': 'index added',
    'received_at': '2026-09-26T08:31:00+00:00',
  };

  test('a whole row becomes a record, an unknown category kept as text', () {
    final record = recordOfJson(full());

    expect(record.category, 'network');
    expect(record.source, 'server');
    expect(record.context['args'], [1, 2]);
    expect(record.status, LogStatus.fixed);
    expect(record.statusChangedAt, DateTime.utc(2026, 9, 27, 9));
    expect(record.statusNote, 'index added');
    expect(record.canTriage, isTrue);
  });

  test('a row with only its required columns still maps', () {
    final record = recordOfJson({
      'id': 'a',
      'occurred_at': '2026-09-26T08:30:15+00:00',
      'level': 'info',
      'category': 'ui',
      'event': 'nav.push',
      'context': null,
    });

    expect(record.source, 'app');
    expect(record.context, isEmpty);
    expect(record.message, isNull);
    expect(record.stackTrace, isNull);
    expect(record.status, isNull);
    expect(record.statusChangedAt, isNull);
    expect(record.canTriage, isFalse);
  });

  test('a buffered row is an app row with no status', () {
    final record = recordOfEntry(
      LogEntry(
        id: 'a',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.sync,
        event: 'sync.failed',
        message: 'm',
        stackTrace: '#0 x',
        context: const {'k': 1},
        stamp: const LogStamp(deviceId: 'dev-1', platform: 'android'),
      ),
    );

    expect(record.source, 'app');
    expect(record.category, 'sync');
    expect(record.deviceId, 'dev-1');
    expect(record.platform, 'android');
    expect(record.canTriage, isFalse);
    expect(record.context, {'k': 1});
  });

  test('a buffered list row keeps the total of the buffer', () {
    final rows = pendingLogsOf(
      PendingLogRows(
        items: [
          PendingLog(
            id: 'a',
            occurredAt: now,
            level: LogLevel.warning,
            event: 'e',
            message: 'm',
            errorMessage: 'e',
          ),
        ],
        total: 42,
      ),
    );

    expect(rows.total, 42);
    expect(rows.items.single.id, 'a');
    expect(rows.items.single.errorMessage, 'e');
    expect(rows.items.single.status, isNull);
  });
}
