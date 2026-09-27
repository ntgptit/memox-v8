import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/request_id_interceptor.dart';

void main() {
  test('every request gets its own X-Request-ID', () {
    final interceptor = RequestIdInterceptor();
    final first = RequestOptions(path: '/a');
    final second = RequestOptions(path: '/b');

    interceptor.onRequest(first, RequestInterceptorHandler());
    interceptor.onRequest(second, RequestInterceptorHandler());

    expect(first.headers[RequestIdInterceptor.header], isNotEmpty);
    expect(
      first.headers[RequestIdInterceptor.header],
      isNot(second.headers[RequestIdInterceptor.header]),
    );
  });
}
