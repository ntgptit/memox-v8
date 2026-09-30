import 'dart:async';

import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/secret_store.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/database/mutation_gate.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/sync_control.dart';

/// The one owner of the account (auth spec §3, §5, §6): start, validation,
/// recovery and every transition, one step at a time. Features send it
/// commands; it publishes [AuthState].
///
/// Each stage is saved before the next step, so a rerun after a kill is a
/// no-op up to where it stopped. Each `OfflineFailure` keeps the record, and
/// the reconnect listener runs it again.
class AccountCoordinator {
  AccountCoordinator({
    required this._gateway,
    required this._api,
    required this._store,
    required this._secrets,
    required this._sync,
    required this._localReset,
    required this._gate,
    required this._network,
    this._flushLogs,
    this._newOpId = newId,
    this._now = DateTime.now,
    this._logger,
  });

  final AuthGateway _gateway;
  final AccountApi _api;
  final AccountStore _store;
  final SecretStore _secrets;
  final SyncControl _sync;
  final LocalDataReset _localReset;
  final MutationGate _gate;
  final NetworkStatus _network;
  final Future<void> Function()? _flushLogs;
  final String Function() _newOpId;
  final DateTime Function() _now;
  final AppLogger? _logger;

  AppLogger get _log => _logger ?? appLogger;

  AuthState _state = const Booting();
  final _states = StreamController<AuthState>.broadcast();
  final _notices = StreamController<AccountNotice>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  Future<void> _tail = Future<void>.value();
  var _prepared = false;

  /// The transition this run of the app started. A reconnect or a retry
  /// must not treat it as found at start (Review Focus 2).
  String? _liveOpId;

  AuthState get state => _state;

  /// The state now, then every change.
  Stream<AuthState> watch() {
    final controller = StreamController<AuthState>();
    controller.onListen = () {
      controller.add(_state);
      final subscription = _states.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    };
    return controller.stream;
  }

  Stream<AccountNotice> get notices => _notices.stream;

  /// Before the first frame, local only: shuts the gate if a blocking
  /// transition is pending, so no write slips in before recovery (#1, R3),
  /// and drops the secrets of any other operation (spec §4).
  Future<void> prepare() async {
    if (_prepared) return;
    _prepared = true;
    _emit(const Booting());
    await _sync.pause();
    final pending = await _store.transition();
    await purgeAccountSecrets(_secrets, keepOpId: pending?.opId);
    if (pending != null && pending.blocksWrites) _gate.close();
  }

  /// Recovers a pending transition or settles the session (#1–#3), then
  /// follows the network and the SDK.
  Future<void> start() => _serial(() async {
    await prepare();
    _subscriptions
      ..add(
        _network.reconnects.listen(
          (_) => _background('reconnect_failed', _resume),
        ),
      )
      ..add(
        _gateway.userIds.listen(
          (userId) =>
              _background('session_event_failed', () => _onUserId(userId)),
        ),
      );
    final pending = await _store.transition();
    if (pending != null) return _drive(pending); // #1
    return _settle();
  });

  /// Runs again whatever stopped on an error (a network error's Retry).
  Future<void> retry() => _serial(_resume);

  Future<void> dispose() async {
    await Future.wait([
      for (final subscription in _subscriptions) subscription.cancel(),
    ]);
    await _states.close();
    await _notices.close();
  }

  // --- Start and validation -------------------------------------------------

  Future<void> _settle() async {
    if (_gateway.currentUserId != null) return _validate(); // #2, #5 (R1)
    if (!await _network.isOnline) return _emit(const LocalOnly()); // #3
    _emit(const Bootstrapping());
    try {
      await _gateway.signInAnonymously(); // #6
    } on OfflineFailure {
      return _emit(const LocalOnly()); // #7
    }
    return _validate();
  }

  Future<void> _validate() async {
    await _sync.pause();
    _emit(Validating(await _store.lastKnown())); // R2
    try {
      final me = await _api.me();
      await _store.saveLastKnown(me, _now());
      _emit(Ready(me));
      _sync.resume(); // #9
      _log.info(
        'auth.ready',
        category: LogCategory.state,
        context: {'anonymous': me.isAnonymous, 'role': me.role.name},
      );
    } on OfflineFailure {
      // #8: stays Validating; the reconnect listener tries again.
    } on SessionInvalidFailure {
      return _lost(sessionInvalid: true);
    } on ProfileGoneFailure {
      return _lost(sessionInvalid: false);
    }
  }

  /// The session is refused (#10, #13, #14).
  Future<void> _lost({required bool sessionInvalid}) async {
    await _sync.pause();
    final last = await _store.lastKnown();
    if (last == null || last.isAnonymous) {
      return _begin(
        _newTransition(
          TransitionKind.anonRecovery,
          sourceUserId: _gateway.currentUserId ?? last?.id,
          sourceIsAnonymous: true,
        ),
      ); // #10
    }
    if (sessionInvalid) return _emit(ReauthRequired(last)); // #14
    return _begin(
      _newTransition(
        TransitionKind.clearToAnon,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ),
    ); // #13
  }

  // --- Events ---------------------------------------------------------------

  /// A reconnect or a retry: the pending transition, else what waited.
  Future<void> _resume() async {
    final pending = await _store.transition();
    if (pending != null) return _drive(pending);
    return switch (_state) {
      LocalOnly() => _settle(), // #4
      Validating() => _validate(), // #8
      _ => Future<void>.value(),
    };
  }

  /// The SDK dropped the session on its own, as when its refresh token is
  /// refused (Review Focus 1). A transition's own sign-out is ignored.
  Future<void> _onUserId(String? userId) async {
    if (userId != null || _gateway.currentUserId != null) return;
    if (await _store.transition() != null) return;
    if (_state is Ready || _state is Validating) {
      return _lost(sessionInvalid: true);
    }
  }

  // --- Transitions ----------------------------------------------------------

  /// Records [t], then runs it.
  Future<void> _begin(AccountTransition t) async {
    if (t.blocksWrites) _gate.close();
    await _sync.pause();
    await _store.saveTransition(t);
    _liveOpId = t.opId;
    _log.info(
      'auth.transition_started',
      category: LogCategory.state,
      context: {'kind': t.kind.name, 'op': t.opId},
    );
    return _drive(t);
  }

  Future<void> _drive(AccountTransition t) async {
    switch (t.kind) {
      case TransitionKind.anonRecovery:
        return _driveAnonRecovery(t);
      case TransitionKind.switchAccount:
      case TransitionKind.signOut:
      case TransitionKind.delete:
      case TransitionKind.clearToAnon:
        // Tasks 11 and 12 of the core-auth plan drive these. Until then a
        // pending one keeps the gate shut.
        _log.error(
          'auth.transition_unsupported',
          category: LogCategory.state,
          context: {'kind': t.kind.name},
        );
        return _emit(Recovering(t, stuck: true));
    }
  }

  /// #10–#12: sign out the refused session, sign in a new anonymous user
  /// (never a second one: R1), queue the whole library under it.
  Future<void> _driveAnonRecovery(AccountTransition t) async {
    _emit(_inTransition(t));
    var s = t;
    if (s.stage == TransitionStage.started) {
      final source = s.sourceUserId;
      if (source != null && _gateway.currentUserId == source) {
        await _gateway.signOutLocal(); // #10
      }
      if (_gateway.currentUserId == null) {
        try {
          await _gateway.signInAnonymously(); // #11
        } on OfflineFailure {
          return _emit(const LocalOnly()); // the record waits for a reconnect
        }
      }
      s = await _save(
        s.copyWith(
          stage: TransitionStage.newAnon,
          targetUserId: _gateway.currentUserId,
        ),
      );
    }
    await _sync.markAllPending(); // #12, idempotent
    await _store.saveLastKnown(
      AccountUser(
        id: s.targetUserId ?? _gateway.currentUserId!,
        isAnonymous: true,
        role: AccountRole.user,
      ),
      _now(),
    ); // plan ruling 7: the device's data now belongs to the new user
    await _drop(s);
    return _validate();
  }

  /// The end of a transition: its secrets and record go, the gate opens.
  Future<void> _drop(AccountTransition s) async {
    await _secrets.delete(backupSecretKey(s.opId));
    await _secrets.delete(claimSecretKey(s.opId));
    await _store.clearTransition();
    if (_liveOpId == s.opId) _liveOpId = null;
    _gate.open();
    _log.info(
      'auth.transition_done',
      category: LogCategory.state,
      context: {'kind': s.kind.name, 'stage': s.stage.name, 'op': s.opId},
    );
  }

  Future<AccountTransition> _save(AccountTransition t) =>
      _store.saveTransition(t.copyWith(updatedAt: _now()));

  AccountTransition _newTransition(
    TransitionKind kind, {
    TransitionChoice? choice,
    String? sourceUserId,
    bool? sourceIsAnonymous,
    String? targetHint,
  }) {
    final at = _now();
    return AccountTransition(
      opId: _newOpId(),
      kind: kind,
      choice: choice,
      sourceUserId: sourceUserId,
      sourceIsAnonymous: sourceIsAnonymous,
      targetHint: targetHint,
      stage: TransitionStage.started,
      createdAt: at,
      updatedAt: at,
    );
  }

  /// [Transitioning] for a flow this run started, [Recovering] for one found
  /// at start.
  AuthState _inTransition(
    AccountTransition t, {
    bool needsTargetSignIn = false,
    Failure? error,
  }) => _liveOpId == t.opId
      ? Transitioning(t, needsTargetSignIn: needsTargetSignIn, error: error)
      : Recovering(t, needsTargetSignIn: needsTargetSignIn, error: error);

  // --- Plumbing -------------------------------------------------------------

  /// Runs [step] after every earlier one. Its result or error goes to its
  /// caller only.
  Future<T> _serial<T>(Future<T> Function() step) {
    final result = _tail.then((_) => step());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// A step no caller waits on: a failure is logged, and the state stays
  /// where the step stopped.
  void _background(String event, Future<void> Function() step) {
    unawaited(
      _serial(step).catchError((Object error, StackTrace stackTrace) {
        _log.error(
          'auth.$event',
          category: LogCategory.state,
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  void _emit(AuthState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}
