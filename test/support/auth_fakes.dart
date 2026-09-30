import 'dart:async';
import 'dart:math' as math;

import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/database/app_database.dart' hide AccountTransition;
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/database/mutation_gate.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/sync_control.dart';

import 'fake_secret_store.dart';
import 'test_database.dart';

/// The app killed at a step (auth spec §9, crash injection).
final class Killed implements Exception {
  const Killed();

  @override
  String toString() => 'Killed';
}

/// Every fake call is one step. [at] kills the flow at that step;
/// [offlineAt] cuts the network from that step on (spec §9, "Network").
class KillSwitch {
  int? at;
  int? offlineAt;
  FakeAuthServer? server;
  var steps = 0;

  void step() {
    steps++;
    if (offlineAt != null && steps == offlineAt) server!.offline = true;
    if (at != null && steps == at) throw const Killed();
  }
}

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

  /// The SDK lost its session without telling the server (a cleared app
  /// store, a kill mid-write): the refresh tokens stay valid.
  void forgetSession() => _set(null);

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIds => _ids.stream;

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
    _checkCode(email, code);
    server.users[_userId]!
      ..email = email
      ..isAnonymous = false;
    _ids.add(_userId);
  }

  @override
  Future<void> requestEmailSignIn(String email) async {
    kill?.step();
    server.checkOnline();
    server.sentCodes[email] = code;
  }

  @override
  Future<void> verifyEmailSignIn(String email, String code) async {
    kill?.step();
    server.checkOnline();
    _checkCode(email, code);
    _set((server.userByEmail(email) ?? server.addUser(email: email)).id);
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
      ..isAnonymous = false;
    _ids.add(_userId);
  }

  @override
  Future<void> signInGoogle(GoogleCredential credential) async {
    kill?.step();
    server.checkOnline();
    final email = credential.email!;
    _set((server.userByEmail(email) ?? server.addUser(email: email)).id);
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

/// What the device holds; it survives a restart, as Drift does.
class FakeDevice {
  /// Whose library is on the device; null when it holds none.
  String? owner;
  var rows = 0;
  var pending = 0;
  final pushes = <({String? signedIn, String? owner})>[];
  final pulls = <String?>[];
  var resets = 0;
  var markAllPendingCalls = 0;
}

class FakeSyncControl implements SyncControl {
  FakeSyncControl(this.device, this.gateway, this.server);

  final FakeDevice device;
  final FakeAuthGateway gateway;
  final FakeAuthServer server;
  KillSwitch? kill;
  var paused = true;
  var resumes = 0;

  @override
  Future<void> pause() async => paused = true;

  @override
  void resume() {
    paused = false;
    resumes++;
  }

  @override
  Future<int> pendingCount() async => device.pending;

  @override
  Future<void> pushPending() async {
    kill?.step();
    server.checkOnline();
    device.pushes.add((signedIn: gateway.currentUserId, owner: device.owner));
    device.pending = 0;
  }

  @override
  Future<void> pullAll() async {
    kill?.step();
    server.checkOnline();
    device.pulls.add(gateway.currentUserId);
    device.owner = gateway.currentUserId;
  }

  @override
  Future<void> markAllPending() async {
    kill?.step();
    device
      ..markAllPendingCalls += 1
      ..owner = gateway.currentUserId
      ..pending = math.max(device.pending, device.rows);
  }
}

class FakeLocalDataReset implements LocalDataReset {
  FakeLocalDataReset(this.device);

  final FakeDevice device;
  KillSwitch? kill;

  @override
  Future<void> run() async {
    kill?.step();
    device
      ..resets += 1
      ..owner = null
      ..rows = 0
      ..pending = 0;
  }
}

/// The real Drift store, each write one step of the kill switch.
class KillableAccountStore extends AccountStore {
  KillableAccountStore(super.db, this.kill);

  final KillSwitch kill;

  @override
  Future<AccountTransition> saveTransition(AccountTransition t) {
    kill.step();
    return super.saveTransition(t);
  }

  @override
  Future<void> clearTransition() {
    kill.step();
    return super.clearTransition();
  }

  @override
  Future<void> saveLastKnown(AccountUser user, DateTime at) {
    kill.step();
    return super.saveLastKnown(user, at);
  }

  @override
  Future<void> clearLastKnown() {
    kill.step();
    return super.clearLastKnown();
  }
}

class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus(this.server);

  final FakeAuthServer server;

  /// What the OS says, when it differs from what the server answers.
  bool? claimsOnline;
  final _reconnects = StreamController<void>.broadcast();

  @override
  Future<bool> get isOnline async => claimsOnline ?? !server.offline;

  @override
  Stream<void> get reconnects => _reconnects.stream;

  void goOffline() => server.offline = true;

  void goOnline() {
    server.offline = false;
    _reconnects.add(null);
  }
}

/// One device and one server. [boot] launches the app: the server, the
/// SDK's session, Drift, the secrets and the device's library survive it;
/// the coordinator, the gate and sync's run state do not.
class AuthWorld {
  AuthWorld() {
    kill.server = server;
    gateway = FakeAuthGateway(server)..kill = kill;
    api = FakeAccountApi(server, gateway)..kill = kill;
    secrets.onCall = kill.step;
    network = FakeNetworkStatus(server);
  }

  final server = FakeAuthServer();
  final kill = KillSwitch();
  final device = FakeDevice();
  final AppDatabase db = openTestDatabase();
  final secrets = FakeSecretStore();
  final notices = <AccountNotice>[];
  late final FakeAuthGateway gateway;
  late final FakeAccountApi api;
  late final FakeNetworkStatus network;
  late FakeSyncControl sync;
  late MutationGate gate;
  AccountCoordinator? _coordinator;
  var _opIds = 0;

  /// How often a sign-out shipped the logs (#39).
  var logFlushes = 0;

  AccountCoordinator get coordinator => _coordinator!;

  AuthState get state => coordinator.state;

  /// A store that is not killable, for the test's own reads and setup.
  AccountStore get store => AccountStore(db);

  AccountCoordinator boot() {
    final previous = _coordinator;
    if (previous != null) unawaited(previous.dispose());
    gate = MutationGate();
    sync = FakeSyncControl(device, gateway, server)..kill = kill;
    final coordinator = AccountCoordinator(
      gateway: gateway,
      api: api,
      store: KillableAccountStore(db, kill),
      secrets: secrets,
      sync: sync,
      localReset: FakeLocalDataReset(device)..kill = kill,
      gate: gate,
      network: network,
      flushLogs: () async => logFlushes++,
      newOpId: () => 'op-${_opIds++}',
      logger: AppLogger(sinks: const []),
    );
    coordinator.notices.listen(notices.add);
    return _coordinator = coordinator;
  }

  Future<void> close() async {
    await _coordinator?.dispose();
    await db.close();
  }
}

/// A launched device on its first anonymous user, with [rows] local rows of
/// which [pending] are not sent.
Future<String> readyAnonymous(
  AuthWorld world, {
  int rows = 3,
  int pending = 2,
}) async {
  world.boot();
  await world.coordinator.start();
  final id = world.gateway.currentUserId!;
  world.device
    ..owner = id
    ..rows = rows
    ..pending = pending;
  return id;
}
