import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_entry.dart';

// ADR-018 §3: the log push uses sync's session and never signs in itself.
void main() {
  final entry = LogEntry(
    id: '11111111-0000-0000-0000-000000000001',
    occurredAt: DateTime.utc(2026, 9, 29),
    level: LogLevel.info,
    category: LogCategory.db,
    event: 'db.query',
  );

  test('with no session yet, the push fails without calling the server', () {
    var calls = 0;
    final api = LogApi(
      ensureSession: existingSessionOnly(() => false),
      rpc: (_, _) async {
        calls++;
        return {'accepted': <String>[]};
      },
    );

    expect(api.push([entry]), throwsA(isA<LogSessionMissing>()));
    expect(calls, 0);
  });

  test('with a session, the push goes', () async {
    final api = LogApi(
      ensureSession: existingSessionOnly(() => true),
      rpc: (_, params) async => {
        'accepted': [entry.id],
      },
    );

    expect(await api.push([entry]), {entry.id});
  });
}
