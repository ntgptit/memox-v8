import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §4.1: the entities and the page's cursor.
void main() {
  test('a row\'s subtitle is the message\'s first line', () {
    expect(
      summary('a', message: '  first line\nsecond line').subtitle,
      'first line',
    );
  });

  test('with no message the subtitle is the error message\'s first line', () {
    expect(
      summary(
        'a',
        message: '   ',
        errorMessage: 'Bad state: closed\n#0 main',
        errorType: 'StateError',
      ).subtitle,
      'Bad state: closed',
    );
  });

  test('with neither, the subtitle is the error type, else none', () {
    expect(
      summary(
        'a',
        message: '   ',
        errorMessage: '\n',
        errorType: 'StateError',
      ).subtitle,
      'StateError',
    );
    expect(summary('a', message: '\n', errorType: null).subtitle, isNull);
  });

  test('a row keeps everything but its status when the status changes', () {
    final changed = summary(
      'a',
      level: LogLevel.warning,
    ).withStatus(LogStatus.fixed);

    expect(changed.status, LogStatus.fixed);
    expect(changed.id, 'a');
    expect(changed.level, LogLevel.warning);
    expect(changed.event, 'sync.push_failed');
  });

  test('a full page points at the row after its last', () {
    final page = pageOf(LogPage.size);

    expect(
      page.next,
      LogCursor(
        occurredAt: page.items.last.occurredAt,
        id: 'r${LogPage.size - 1}',
      ),
    );
  });

  test('a page that is not full is the last', () {
    expect(pageOf(LogPage.size - 1).next, isNull);
    expect(pageOf(0).next, isNull);
  });

  test('only a row with a status can be triaged', () {
    expect(record('a').canTriage, isTrue);
    expect(record('a', status: null).canTriage, isFalse);
  });

  test('a record\'s JSON has every field, in UTC', () {
    final json = record(
      'a',
      status: LogStatus.fixed,
      statusNote: 'index added',
    ).toJson();

    expect(json['occurredAt'], '2026-09-26T08:30:15.000Z');
    expect(json['level'], 'error');
    expect(json['status'], 'fixed');
    expect(json['statusNote'], 'index added');
    expect(json['context'], {'entity': 'deck', 'count': 3});
    expect(json.keys, hasLength(21));
  });
}
