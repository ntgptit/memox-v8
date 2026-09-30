import 'package:http/http.dart' as http;
import 'package:memox/core/network/logging_http_client.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one place that reaches `Supabase.instance` outside `core/auth`'s
/// gateway files (auth spec §5).

/// Before the first frame, when [config] names a project. Every request,
/// auth and RPC, is logged (ADR-018; network logging spec).
Future<void> initializeSupabase(SupabaseConfig config) => Supabase.initialize(
  url: config.url,
  publishableKey: config.publishableKey,
  httpClient: LoggingHttpClient(inner: http.Client()),
);

/// Calls the Postgres function [function] and returns its decoded JSON.
Future<Object?> supabaseRpc(String function, Map<String, Object?> params) =>
    Supabase.instance.client.rpc<Object?>(function, params: params);

/// Whether the SDK holds a session now. It never signs in.
bool hasSupabaseSession() =>
    Supabase.instance.client.auth.currentSession != null;
