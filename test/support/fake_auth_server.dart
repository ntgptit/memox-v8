import 'dart:async';

import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/error/failure.dart';

import 'auth_fakes.dart' show KillSwitch;

/// GoTrue, the account RPCs and the SDK, in memory (auth spec §9).
class FakeUser {
  FakeUser(
    this.id, {
    this.email,
    this.isAnonymous = false,
    this.role = AccountRole.user,
  });

  final String id;
  String? email;
  bool isAnonymous;
  AccountRole role;
  final methods = <SignInMethod>{};
}

/// GoTrue and the account RPCs, in memory.
class FakeAuthServer {
  final users = <String, FakeUser>{};

  /// Refresh token → user id.
  final refreshTokens = <String, String>{};

  /// Claim token → source user id.
  final claims = <String, String>{};
  final receipts =
      <String, ({String source, String target, bool acknowledged})>{};
  final sentCodes = <String, String>{};
  var offline = false;
  var anonymousCreated = 0;
  var _next = 0;

  /// Runs right after a merge commits and before it answers.
  void Function()? afterMergeCommit;

  String nextId(String prefix) => '$prefix${_next++}';

  FakeUser addUser({
    String? email,
    bool anonymous = false,
    AccountRole role = AccountRole.user,
  }) {
    final user = FakeUser(
      nextId(anonymous ? 'anon-' : 'user-'),
      email: email,
      isAnonymous: anonymous,
      role: role,
    );
    users[user.id] = user;
    if (anonymous) anonymousCreated++;
    return user;
  }

  String issueToken(String userId) {
    final token = nextId('rt-');
    refreshTokens[token] = userId;
    return token;
  }

  void revokeTokensOf(String userId) =>
      refreshTokens.removeWhere((_, id) => id == userId);

  void deleteUser(String userId) {
    users.remove(userId);
    revokeTokensOf(userId);
    claims.removeWhere((_, id) => id == userId);
  }

  FakeUser? userByEmail(String email) =>
      users.values.where((user) => user.email == email).firstOrNull;

  void checkOnline() {
    if (offline) throw const OfflineFailure(cause: 'fake offline');
  }
}

/// The SDK. Its session survives a restart, as SharedPreferences does.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway(this.server);

  static const code = '123456';

  final FakeAuthServer server;
  KillSwitch? kill;
  String? _userId;
  String? _refreshToken;
  final _ids = StreamController<String?>.broadcast();

  /// Every user id the SDK held, in order.
  final history = <String?>[];
  GoogleCredential google = const GoogleCredential(
    idToken: 'google-id-token',
    email: 'g@example.com',
  );
  var googleCancels = false;

  /// The next code request fails with this, as GoTrue's rate limit does.
  Failure? failNextRequest;

  /// While set, code requests wait on it, as a slow network does.
  Completer<void>? holdRequests;

  /// While set, code checks wait on it, as a slow network does.
  Completer<void>? holdVerifies;

  Future<void> _waitIfHeld() async => holdRequests?.future;

  void _failIfAsked() {
    final failure = failNextRequest;
    if (failure == null) return;
    failNextRequest = null;
    throw failure;
  }

  /// Runs right after a target sign-in succeeds, before it returns.
  void Function()? afterSignIn;

  void _set(String? userId) {
    _userId = userId;
    _refreshToken = userId == null ? null : server.issueToken(userId);
    history.add(userId);
    _ids.add(userId);
  }

  /// Test setup: the SDK already holds [userId]'s session.
  void adopt(String userId) => _set(userId);

  /// The server refused the refresh token and the SDK dropped the session on
  /// its own (Review Focus 1).
  void dropSession() {
    server.revokeTokensOf(_userId!);
    _set(null);
  }

  /// The SDK's auth stream reports an error, as GoTrue does for a token
  /// refresh that fails offline (final review I3).
  void emitError() =>
      _ids.addError(const OfflineFailure(cause: 'refresh failed offline'));

  /// The SDK lost its session without telling the server (a cleared app
  /// store, a kill mid-write): the refresh tokens stay valid.
  void forgetSession() => _set(null);

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIds => _ids.stream;

  @override
  Set<SignInMethod> get signInMethods =>
      Set.of(server.users[_userId]?.methods ?? const <SignInMethod>{});

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> signInAnonymously() async {
    kill?.step();
    server.checkOnline();
    _set(server.addUser(anonymous: true).id);
  }

  @override
  Future<void> requestEmailLink(String email) async {
    kill?.step();
    server.checkOnline();
    _failIfAsked();
    await _waitIfHeld();
    final owner = server.userByEmail(email);
    if (owner != null && owner.id != _userId) {
      throw const IdentityTakenFailure(method: IdentityMethod.email);
    }
    server.sentCodes[email] = code;
  }

  @override
  Future<void> verifyEmailLink(String email, String code) async {
    kill?.step();
    server.checkOnline();
    await holdVerifies?.future;
    _checkCode(email, code);
    server.users[_userId]!
      ..email = email
      ..isAnonymous = false
      ..methods.add(SignInMethod.email);
    _ids.add(_userId);
  }

  @override
  Future<void> requestEmailSignIn(String email) async {
    kill?.step();
    server.checkOnline();
    _failIfAsked();
    await _waitIfHeld();
    server.sentCodes[email] = code;
  }

  @override
  Future<void> verifyEmailSignIn(String email, String code) async {
    kill?.step();
    server.checkOnline();
    await holdVerifies?.future;
    _checkCode(email, code);
    final user = server.userByEmail(email) ?? server.addUser(email: email);
    user.methods.add(SignInMethod.email);
    _set(user.id);
    afterSignIn?.call();
  }

  @override
  Future<GoogleCredential> pickGoogle() async {
    kill?.step();
    if (googleCancels) throw const GoogleCancelledFailure();
    return google;
  }

  @override
  Future<void> linkGoogle(GoogleCredential credential) async {
    kill?.step();
    server.checkOnline();
    final owner = server.userByEmail(credential.email!);
    if (owner != null && owner.id != _userId) {
      throw const IdentityTakenFailure(method: IdentityMethod.google);
    }
    server.users[_userId]!
      ..email = credential.email
      ..isAnonymous = false
      ..methods.add(SignInMethod.google);
    _ids.add(_userId);
  }

  @override
  Future<void> signInGoogle(GoogleCredential credential) async {
    kill?.step();
    server.checkOnline();
    final email = credential.email!;
    final user = server.userByEmail(email) ?? server.addUser(email: email);
    user.methods.add(SignInMethod.google);
    _set(user.id);
    afterSignIn?.call();
  }

  @override
  Future<void> restoreSession(String refreshToken) async {
    kill?.step();
    server.checkOnline();
    final userId = server.refreshTokens.remove(refreshToken);
    if (userId == null || !server.users.containsKey(userId)) {
      throw const SessionInvalidFailure();
    }
    _set(userId);
  }

  @override
  Future<void> signOutLocal() async {
    kill?.step();
    final userId = _userId;
    _set(null);
    if (userId != null && !server.offline) server.revokeTokensOf(userId);
  }

  void _checkCode(String email, String code) {
    if (server.sentCodes[email] != code) throw const InvalidCodeFailure();
  }
}

class FakeAccountApi implements AccountApi {
  FakeAccountApi(this.server, this.gateway);

  final FakeAuthServer server;
  final FakeAuthGateway gateway;
  KillSwitch? kill;
  var meCalls = 0;

  /// How many next `me()` calls the server answers with an error of its own.
  var serverFailuresOnMe = 0;

  FakeUser _caller() {
    final id = gateway.currentUserId;
    if (id == null) throw const SessionInvalidFailure();
    return server.users[id] ?? (throw const ProfileGoneFailure());
  }

  @override
  Future<AccountUser> me() async {
    kill?.step();
    server.checkOnline();
    meCalls++;
    if (serverFailuresOnMe > 0) {
      serverFailuresOnMe--;
      throw const ServerFailure(cause: 'fake 5xx');
    }
    final user = _caller();
    return AccountUser(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
      role: user.role,
    );
  }

  @override
  Future<String> claimBegin() async {
    kill?.step();
    server.checkOnline();
    final user = _caller();
    if (!user.isAnonymous) throw const ServerFailure(cause: 'NOT_ANONYMOUS');
    server.claims.removeWhere((_, id) => id == user.id);
    final token = server.nextId('claim-');
    server.claims[token] = user.id;
    return token;
  }

  @override
  Future<void> merge(String token, String operationId) async {
    kill?.step();
    server.checkOnline();
    final target = _caller();
    final receipt = server.receipts[operationId];
    if (receipt != null && receipt.target == target.id) return;
    final source = server.claims.remove(token);
    if (source == null ||
        source == target.id ||
        !(server.users[source]?.isAnonymous ?? false)) {
      throw const ClaimInvalidFailure();
    }
    server.receipts[operationId] = (
      source: source,
      target: target.id,
      acknowledged: false,
    );
    server.deleteUser(source);
    server.afterMergeCommit?.call();
  }

  @override
  Future<void> mergeAck(String operationId) async {
    kill?.step();
    server.checkOnline();
    final target = _caller();
    final receipt = server.receipts[operationId];
    if (receipt == null || receipt.target != target.id) return;
    server.receipts[operationId] = (
      source: receipt.source,
      target: receipt.target,
      acknowledged: true,
    );
  }

  @override
  Future<void> deleteAccount() async {
    kill?.step();
    server.checkOnline();
    final user = _caller();
    final admins = server.users.values
        .where((u) => u.role == AccountRole.admin)
        .length;
    if (user.role == AccountRole.admin && admins <= 1) {
      throw const LastAdminFailure();
    }
    server.deleteUser(user.id);
  }
}
