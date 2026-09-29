import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/logging_http_client.dart';

import '../../support/recording_log_sink.dart';

final _url = Uri.parse('https://x.supabase.co/rest/v1/rpc/sync_push?a=1');
final _logPush = Uri.parse('https://x.supabase.co/rest/v1/rpc/log_push');

// Spec 2026-09-29-network-logging-design.md §2, §5.
void main() {
  late RecordingLogSink sink;

  setUp(() => sink = RecordingLogSink());

  LoggingHttpClient client(MockClientHandler handler, {List<int>? ticks}) {
    var now = 0;
    final steps = [...?ticks];
    return LoggingHttpClient(
      inner: MockClient(handler),
      logger: AppLogger(sinks: [sink]),
      micros: () => now += steps.isEmpty ? 0 : steps.removeAt(0),
    );
  }

  test('a 200 logs debug net.request with the whole exchange', () async {
    final c = client(
      (request) async => http.Response(
        '{"ok":true}',
        200,
        headers: {'content-type': 'application/json'},
      ),
      ticks: [0, 12000],
    );

    await c.post(_url, headers: {'Authorization': 'Bearer t'}, body: '{"x":1}');

    final entry = sink.entries.single;
    expect(
      (entry.level, entry.category, entry.event),
      (LogLevel.debug, LogCategory.network, 'net.request'),
    );
    expect(entry.context['method'], 'POST');
    expect(entry.context['url'], '/rest/v1/rpc/sync_push?a=1');
    expect(entry.context['request_body'], '{"x":1}');
    expect(entry.context['response_body'], '{"ok":true}');
    expect(entry.context['status'], 200);
    expect(entry.context['duration_ms'], 12);
    expect(
      (entry.context['request_headers']! as Map)['Authorization'],
      'Bearer t',
    );
  });

  test('the caller gets the same response back', () async {
    final c = client(
      (request) async => http.Response.bytes(
        utf8.encode('{"a":"é"}'),
        201,
        headers: {'x-h': 'v'},
        reasonPhrase: 'Created',
      ),
    );

    final response = await c.get(_url);

    expect(response.statusCode, 201);
    expect(response.reasonPhrase, 'Created');
    expect(response.headers['x-h'], 'v');
    expect(utf8.decode(response.bodyBytes), '{"a":"é"}');
  });

  test('a 4xx or 5xx logs warning net.http_error', () async {
    final c = client((request) async => http.Response('{"code":"P0001"}', 400));

    await c.get(_url);

    expect(
      (sink.entries.single.level, sink.entries.single.event),
      (LogLevel.warning, 'net.http_error'),
    );
  });

  test('no connection logs info net.unreachable and rethrows', () async {
    final c = client((request) async => throw const SocketException('down'));

    await expectLater(c.get(_url), throwsA(isA<SocketException>()));

    expect(
      (sink.entries.single.level, sink.entries.single.event),
      (LogLevel.info, 'net.unreachable'),
    );
  });

  test('another error logs error net.failed and rethrows', () async {
    final c = client((request) async => throw StateError('bug'));

    await expectLater(c.get(_url), throwsStateError);

    final entry = sink.entries.single;
    expect((entry.level, entry.event), (LogLevel.error, 'net.failed'));
    expect(entry.stackTrace, isNotNull);
  });

  test('the log push logs nothing and still returns', () async {
    final c = client((request) async => http.Response('{"accepted":[]}', 200));

    final response = await c.post(_logPush, body: '{}');

    expect(response.statusCode, 200);
    expect(sink.entries, isEmpty);
  });

  test('a failing log_push logs nothing and still throws', () async {
    final c = client((request) async => throw const SocketException('down'));

    await expectLater(
      c.post(_logPush, body: '{}'),
      throwsA(isA<SocketException>()),
    );

    expect(sink.entries, isEmpty);
  });

  test('a body over 64 KB keeps its first 64 KB and says it was cut', () async {
    final big = 'a' * (LoggingHttpClient.maxBodyBytes + 10);
    final c = client((request) async => http.Response(big, 200));

    await c.get(_url);

    final context = sink.entries.single.context;
    expect(
      (context['response_body']! as String).length,
      LoggingHttpClient.maxBodyBytes,
    );
    expect(context['response_body_bytes'], LoggingHttpClient.maxBodyBytes + 10);
    expect(context['response_body_truncated'], isTrue);
  });

  test('a 64 KB cut inside a multi-byte character stays valid text', () async {
    final big = '${'a' * (LoggingHttpClient.maxBodyBytes - 1)}é tail';
    final c = client(
      (request) async => http.Response.bytes(utf8.encode(big), 200),
    );

    await c.get(_url);

    final body = sink.entries.single.context['response_body']! as String;
    expect(() => utf8.encode(body), returnsNormally);
    expect(body.endsWith('a'), isTrue);
  });

  test('a body that is not UTF-8 is logged as its size', () async {
    final c = client(
      (request) async => http.Response.bytes([0xff, 0xfe, 0x00], 200),
    );

    await c.get(_url);

    expect(sink.entries.single.context['response_body'], '<3 bytes, binary>');
  });

  test('a streamed request is sent intact', () async {
    List<int>? received;
    final c = client((request) async {
      received = request.bodyBytes;
      return http.Response('', 204);
    });
    final request = http.StreamedRequest('POST', _url);
    unawaited(
      Future(() {
        request.sink.add(utf8.encode('chunk'));
        request.sink.close();
      }),
    );

    await c.send(request);

    expect(utf8.decode(received!), 'chunk');
    expect(sink.entries.single.context['request_body'], '<streamed>');
  });
}
