import 'package:memox/core/network/remote_error.dart';

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

/// The sync RPCs' refusal of a live JWT whose account is gone (DEV-192).
const _unauthorized = 'UNAUTHORIZED';

/// The kind of [error] a run threw (the transport's classification). A run
/// refused for want of an account is a sign-in failure, not a server one.
SyncFailureKind classifySyncFailure(Object error) {
  if (rpcErrorCode(error) == _unauthorized) return SyncFailureKind.signIn;
  return _transportKind(error);
}

SyncFailureKind _transportKind(Object error) =>
    switch (classifyRemoteError(error)) {
      RemoteErrorKind.network => SyncFailureKind.network,
      RemoteErrorKind.signIn => SyncFailureKind.signIn,
      RemoteErrorKind.server => SyncFailureKind.server,
      RemoteErrorKind.unknown => SyncFailureKind.unknown,
    };
