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

part 'account_coordinator_switch.dart';
part 'account_coordinator_leave.dart';

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
    this._retryDelay = defaultAccountRetryDelay,
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
  final Duration Function(int attempt) _retryDelay;
  Timer? _retryTimer;
  var _retries = 0;

  AppLogger get _log => _logger ?? appLogger;

  AuthState _state = const Booting();
  final _states = StreamController<AuthState>.broadcast();
  late final _notices = StreamController<AccountNotice>.broadcast(
    onListen: _flushNotices,
  );

  /// Notices raised while nobody listened: start() runs before the first
  /// frame, and the layer host listens only after it. They go to the first
  /// listener, once (DEV-202).
  final _pendingNotices = <AccountNotice>[];
  final _subscriptions = <StreamSubscription<Object?>>[];
  Future<void> _tail = Future<void>.value();
  var _prepared = false;

  /// The transition this run of the app started. A reconnect or a retry
  /// must not treat it as found at start (Review Focus 2).
  String? _liveOpId;

  /// A Google account picked for a link that turned out to be another
  /// account's (#17). Kept in memory for the switch's target sign-in, so
  /// nobody picks twice; never persisted (spec §4).
  GoogleCredential? _pendingGoogle;

  AuthState get state => _state;

  /// How the signed-in account signs in (account UI spec §9 B1).
  Set<SignInMethod> get signInMethods => _gateway.signInMethods;

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
  /// waits for any sync run in progress, and drops the secrets of any other
  /// operation (spec §4). The gate shuts before the wait, as a transition's
  /// start does.
  Future<void> prepare() async {
    if (_prepared) return;
    _prepared = true;
    _emit(const Booting());
    final pending = await _store.transition();
    if (pending != null && pending.blocksWrites) _gate.close();
    await _sync.pause();
    await purgeAccountSecrets(_secrets, keepOpId: pending?.opId);
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
          // GoTrue reports a failed refresh, offline for one, on this stream
          // (final review I3). The next event or call tells what it meant.
          onError: (Object error) => _log.info(
            'auth.session_event_error',
            category: LogCategory.state,
            message: '$error',
          ),
        ),
      );
    final pending = await _store.transition();
    if (pending != null) return _drive(pending); // #1
    return _settle();
  });

  /// Runs again whatever stopped on an error (a network error's Retry).
  Future<void> retry() => _serial(_resume);

  /// A sync run was refused for want of an account (`UNAUTHORIZED` under a
  /// live JWT, DEV-192): the account is validated again, which finds the
  /// profile gone (#13), the session refused (#14), or nothing wrong. Only
  /// while Ready; a transition or a validation in flight already decides.
  Future<void> recheckSession() => _serial(() async {
    if (_state is! Ready) return;
    _log.warning('auth.sync_refused', category: LogCategory.state);
    return _validate();
  });

  // --- Sign-in and switch commands -----------------------------------------

  // --- The switch -------------------------------------------------------------

  AccountUser _readyUser() => switch (_state) {
    Ready(:final user) => user,
    _ => throw StateError('This needs a confirmed account, not $_state'),
  };

  Future<void> _ensureNoTransition() async {
    if (await _store.transition() != null) {
      throw StateError('An account transition is already running');
    }
  }

  /// A one-time result for the person (plan rulings 3 and 8): said to the
  /// listener, or kept until one listens.
  void _notice(AccountNotice notice) {
    if (_notices.isClosed) return;
    if (!_notices.hasListener) {
      _pendingNotices.add(notice);
      return;
    }
    _notices.add(notice);
  }

  void _flushNotices() {
    for (final notice in _pendingNotices) {
      _notices.add(notice);
    }
    _pendingNotices.clear();
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await Future.wait([
      for (final subscription in _subscriptions) subscription.cancel(),
    ]);
    await _states.close();
    await _notices.close();
  }

  // --- Start and validation -------------------------------------------------

  Future<void> _settle() async {
    final userId = _gateway.currentUserId; // R1
    final last = await _store.lastKnown();
    if (userId != null) {
      if (last != null && last.id != userId) return _adopt(last, userId);
      return _validate(); // #2, #5
    }
    // No session, yet the device's data belongs to an account: its session
    // was refused or lost, never a fresh start (final review C1).
    if (last != null) return _lost(sessionInvalid: true);
    if (!await _network.isOnline) return _emit(const LocalOnly()); // #3
    _emit(const Bootstrapping());
    try {
      await _gateway.signInAnonymously(); // #6
    } on OfflineFailure {
      return _emit(const LocalOnly()); // #7
    } on Failure catch (error, stackTrace) {
      _log.warning(
        'auth.bootstrap_failed',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
      _emit(const LocalOnly());
      return _scheduleRetry();
    }
    return _validate();
  }

  Future<void> _validate() async {
    await _sync.pause();
    _emit(Validating(await _store.lastKnown())); // R2
    try {
      final me = await _api.me();
      await _store.saveLastKnown(me, _now());
      _retryTimer?.cancel();
      _retries = 0;
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
    } on Failure catch (error, stackTrace) {
      // A server error of its own: stays Validating and tries again later
      // (final review I5).
      _log.warning(
        'auth.validate_failed',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleRetry();
    }
  }

  /// Tries a refused start again after a delay; a reconnect or a Retry may
  /// come first.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(
      _retryDelay(_retries++),
      () => _background('retry_failed', _resume),
    );
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
        return _driveSwitch(t);
      case TransitionKind.signOut:
      case TransitionKind.delete:
      case TransitionKind.clearToAnon:
        return _driveSignOut(t);
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
    bool isAwaitingTargetSignIn = false,
    Failure? error,
  }) => _liveOpId == t.opId
      ? Transitioning(
          t,
          isAwaitingTargetSignIn: isAwaitingTargetSignIn,
          error: error,
        )
      : Recovering(
          t,
          isAwaitingTargetSignIn: isAwaitingTargetSignIn,
          error: error,
        );

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

/// 30 s, doubling up to 5 minutes.
Duration defaultAccountRetryDelay(int attempt) {
  final seconds = 30 * (1 << attempt.clamp(0, 4));
  return Duration(seconds: seconds > 300 ? 300 : seconds);
}
