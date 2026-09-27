import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Tags each request with an `X-Request-ID`, which the server echoes and logs,
/// so a failure can be matched with the server's log line.
class RequestIdInterceptor extends Interceptor {
  static const header = 'X-Request-ID';

  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[header] = _uuid.v4();
    handler.next(options);
  }
}
