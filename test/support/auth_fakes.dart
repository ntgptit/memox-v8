import 'dart:async';
import 'dart:math' as math;

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/database/app_database.dart' hide AccountTransition;
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/database/mutation_gate.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/sync_control.dart';

export 'fake_auth_server.dart';

import 'fake_auth_server.dart';
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

/// What the device holds; it survives a restart, as Drift does.
class FakeDevice {
  /// Whose library is on the device; null when it holds none.
  String? owner;
  var rows = 0;
  var pending = 0;

  /// Rows the server refused without a copy of its own: they exist only here.
  var refused = 0;
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
  Future<int> pendingCount() async => device.pending + device.refused;

  @override
  Future<void> pushPending() async {
    kill?.step();
    server.checkOnline();
    device.pushes.add((signedIn: gateway.currentUserId, owner: device.owner));
    device.pending = 0;
    if (device.refused > 0) {
      throw UnsentChangesFailure(count: device.refused);
    }
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
      ..pending = 0
      ..refused = 0;
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
      retryDelay: (_) => Duration.zero,
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
