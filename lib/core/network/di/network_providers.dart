import 'package:dio/dio.dart';
import 'package:memox/core/network/api_config.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/network/request_id_interceptor.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

const _connectTimeout = Duration(seconds: 10);
const _receiveTimeout = Duration(seconds: 20);
const _sendTimeout = Duration(seconds: 20);

@Riverpod(keepAlive: true)
ApiConfig apiConfig(Ref ref) => ApiConfig.environment;

/// Where the Supabase project lives (ADR-015); sync, auth and the log
/// shipper run only when it is set. Network configuration, so it lives here
/// and not in sync's providers (DEV-177).
@Riverpod(keepAlive: true)
SupabaseConfig supabaseConfig(Ref ref) => SupabaseConfig.environment;

/// The one HTTP client (ADR-012): every API call goes through it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiConfigProvider).baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  )..interceptors.add(RequestIdInterceptor());
  ref.onDispose(dio.close);
  return dio;
}

/// The device's network hint (auth spec §6), one for the coordinator and
/// the screens that ask before an online-only step (account UI spec §9 B2).
@Riverpod(keepAlive: true)
NetworkStatus networkStatus(Ref ref) => ConnectivityNetworkStatus();
