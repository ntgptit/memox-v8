import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/mappers/monitoring_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

// ADR-016 D2, monitoring spec §4.1: the server's errors as Failures.
void main() {
  test('FORBIDDEN is not an admin', () {
    const error = PostgrestException(message: 'FORBIDDEN', code: 'P0001');

    expect(mapMonitoringError(error), isA<NotAdminFailure>());
  });

  test('no session is not an admin', () {
    expect(
      mapMonitoringError(const MonitoringSessionMissing()),
      isA<NotAdminFailure>(),
    );
  });

  test('a call that never arrived is offline', () {
    for (final error in <Object>[
      const SocketException('no route'),
      TimeoutException('slow'),
      http.ClientException('reset'),
      AuthRetryableFetchException(message: 'offline'),
    ]) {
      expect(
        mapMonitoringError(error),
        isA<OfflineFailure>(),
        reason: '$error',
      );
    }
  });

  test('another server error, or an answer that cannot be read, is the '
      'server\'s', () {
    for (final error in <Object>[
      const PostgrestException(message: 'boom', code: '500'),
      const FormatException('not json'),
      StateError('odd'),
    ]) {
      expect(mapMonitoringError(error), isA<ServerFailure>(), reason: '$error');
    }
  });

  test('a Failure passes through, and its cause is kept', () {
    const failure = OfflineFailure(cause: 'x');

    expect(mapMonitoringError(failure), same(failure));
    expect(
      (mapMonitoringError(StateError('odd')) as ServerFailure).cause,
      isA<StateError>(),
    );
  });
}
