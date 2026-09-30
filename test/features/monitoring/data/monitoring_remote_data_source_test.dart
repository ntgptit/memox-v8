import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// ADR-018 §7: the three admin RPCs, on the session sync holds.
void main() {
  final calls = <(String, Map<String, Object?>)>[];
  Object? answer;
  Object? error;
  var hasSession = true;

  MonitoringRemoteDataSource source() => MonitoringRemoteDataSource(
    rpc: (function, params) async {
      calls.add((function, params));
      if (error case final thrown?) throw thrown;
      return answer;
    },
    hasSession: () => hasSession,
  );

  setUp(() {
    calls.clear();
    answer = null;
    error = null;
    hasSession = true;
  });

  test('query sends the filter and returns the items', () async {
    answer = {
      'items': [
        {'id': 'a'},
        {'id': 'b'},
      ],
    };

    final rows = await source().query({'limit': 100});

    expect(calls.single.$1, 'log_query');
    expect(calls.single.$2, {
      'filter': {'limit': 100},
    });
    expect(rows.map((row) => row['id']), ['a', 'b']);
  });

  test('get and setStatus name their arguments as the SQL does', () async {
    answer = {'id': 'a'};

    await source().get('a');
    await source().setStatus('a', 'fixed', 'index added');

    expect(calls.map((call) => call.$1), ['log_get', 'log_set_status']);
    expect(calls[0].$2, {'log_id': 'a'});
    expect(calls[1].$2, {
      'log_id': 'a',
      'new_status': 'fixed',
      'note': 'index added',
    });
  });

  test('NOT_FOUND is null, for a read and for a change', () async {
    error = const PostgrestException(message: 'NOT_FOUND', code: 'P0001');

    expect(await source().get('a'), isNull);
    expect(await source().setStatus('a', 'open', null), isNull);
  });

  test('another error goes up as it is', () {
    error = const PostgrestException(message: 'FORBIDDEN', code: 'P0001');

    expect(source().get('a'), throwsA(isA<PostgrestException>()));
    expect(source().query({}), throwsA(isA<PostgrestException>()));
  });

  test('with no session the server is not asked', () async {
    hasSession = false;

    await expectLater(
      source().query({}),
      throwsA(isA<MonitoringSessionMissing>()),
    );
    await expectLater(
      source().setStatus('a', 'fixed', null),
      throwsA(isA<MonitoringSessionMissing>()),
    );
    expect(calls, isEmpty);
  });
}
