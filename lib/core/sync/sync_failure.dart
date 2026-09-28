import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a sync run failed, as screen 27 says it (sync status spec §4, §5.4).
/// Stored by name in `sync_state`.
enum SyncFailureKind {
  network,
  signIn,
  server,
  unknown;

  static SyncFailureKind? parse(String? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

/// The kind of [error] a run threw. The transport's errors are checked
/// before the sign-in's, since a retryable fetch is also an AuthException.
SyncFailureKind classifySyncFailure(Object error) => switch (error) {
  SocketException() ||
  TimeoutException() ||
  http.ClientException() ||
  AuthRetryableFetchException() => SyncFailureKind.network,
  AuthException() => SyncFailureKind.signIn,
  PostgrestException() ||
  FormatException() ||
  TypeError() => SyncFailureKind.server,
  _ => SyncFailureKind.unknown,
};
