import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// How a call to the server failed, whatever the call was.
enum RemoteErrorKind { network, signIn, server, unknown }

/// The kind of [error] a server call threw. The transport's errors are
/// checked before the sign-in's, since a retryable fetch is also an
/// AuthException.
RemoteErrorKind classifyRemoteError(Object error) => switch (error) {
  SocketException() ||
  TimeoutException() ||
  http.ClientException() ||
  AuthRetryableFetchException() => RemoteErrorKind.network,
  AuthException() => RemoteErrorKind.signIn,
  PostgrestException() ||
  FormatException() ||
  TypeError() => RemoteErrorKind.server,
  _ => RemoteErrorKind.unknown,
};

/// The business code a Postgres function raised: its exception message
/// (SQLSTATE P0001, Supabase backend spec §4). Null for any other error.
String? rpcErrorCode(Object error) =>
    error is PostgrestException ? error.message : null;
