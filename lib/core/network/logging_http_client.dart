import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:memox/core/logging/app_logger.dart';

/// Logs every request the Supabase client sends (spec
/// 2026-09-29-network-logging-design.md): the whole exchange at `debug`, an
/// HTTP error as a warning, no connection at `info`, anything else as an
/// error. The log push is never logged: each push would log the next one.
final class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient({
    required this._inner,
    this._logger,
    int Function()? micros,
  }) : _micros = micros ?? (() => _stopwatch.elapsedMicroseconds);

  /// A body past this many bytes is logged as its head (spec D6).
  static const maxBodyBytes = 65536;

  static const _logPushPath = '/rpc/log_push';
  static final _stopwatch = Stopwatch()..start();

  final http.Client _inner;
  final AppLogger? _logger;
  final int Function() _micros;

  AppLogger get _log => _logger ?? appLogger;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith(_logPushPath)) return _inner.send(request);
    final sent = request is http.Request ? request.bodyBytes : null;
    final start = _micros();
    final http.StreamedResponse response;
    final List<int> received;
    try {
      response = await _inner.send(request);
      received = await response.stream.toBytes();
    } on Object catch (error, stackTrace) {
      _failed(request, sent, start, error, stackTrace);
      rethrow;
    }
    _done(request, sent, response, received, start);
    return http.StreamedResponse(
      Stream.value(received),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  void _done(
    http.BaseRequest request,
    List<int>? sent,
    http.StreamedResponse response,
    List<int> received,
    int start,
  ) {
    final context = {
      ..._requestContext(request, sent, start),
      'status': response.statusCode,
      'response_headers': response.headers,
      ..._body('response', received),
    };
    if (response.statusCode >= 400) {
      _log.warning(
        'net.http_error',
        category: LogCategory.network,
        context: context,
      );
      return;
    }
    _log.debug('net.request', category: LogCategory.network, context: context);
  }

  void _failed(
    http.BaseRequest request,
    List<int>? sent,
    int start,
    Object error,
    StackTrace stackTrace,
  ) {
    final context = _requestContext(request, sent, start);
    if (_isUnreachable(error)) {
      _log.info(
        'net.unreachable',
        category: LogCategory.network,
        message: '$error',
        context: context,
      );
      return;
    }
    _log.error(
      'net.failed',
      category: LogCategory.network,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  Map<String, Object?> _requestContext(
    http.BaseRequest request,
    List<int>? sent,
    int start,
  ) => {
    'method': request.method,
    'url': request.url.hasQuery
        ? '${request.url.path}?${request.url.query}'
        : request.url.path,
    'request_headers': request.headers,
    if (sent == null)
      'request_body': '<streamed>'
    else
      ..._body('request', sent),
    'duration_ms': (_micros() - start) ~/ 1000,
  };

  /// The body as text, its head past [maxBodyBytes] (cut before the character
  /// the limit falls in), or its size when it is not UTF-8.
  static Map<String, Object?> _body(String side, List<int> bytes) {
    final cut = bytes.length > maxBodyBytes;
    final head = cut ? bytes.sublist(0, _charBoundary(bytes)) : bytes;
    final String text;
    try {
      text = utf8.decode(head);
    } on FormatException {
      return {'${side}_body': '<${bytes.length} bytes, binary>'};
    }
    return {
      '${side}_body': text,
      'bytes_${side == 'request' ? 'sent' : 'received'}': bytes.length,
      if (cut) ...{
        '${side}_body_bytes': bytes.length,
        '${side}_body_truncated': true,
      },
    };
  }

  /// Where to cut [bytes] at [maxBodyBytes] without splitting a UTF-8
  /// character: back past at most three continuation bytes to the lead byte.
  /// Bytes that are not UTF-8 leave the cut where it is, and fail to decode.
  static int _charBoundary(List<int> bytes) {
    var end = maxBodyBytes;
    while (end > maxBodyBytes - _maxContinuation &&
        bytes[end] & _continuationMask == _continuationBits) {
      end--;
    }
    return end;
  }

  static const _maxContinuation = 3;
  static const _continuationMask = 0xC0;
  static const _continuationBits = 0x80;

  static bool _isUnreachable(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException;
}
