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

  /// A Google account picked for a link that turned out to be another
  /// account's (#17). Kept in memory for the switch's target sign-in, so
  /// nobody picks twice; never persisted (spec §4).
  GoogleCredential? _pendingGoogle;

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

  // --- Sign-in and switch commands -----------------------------------------

  /// Sends a 6-digit code to [email]: to attach it to this anonymous user
  /// (#16), to sign in to the switch's target (#21), or to sign in again
  /// (#36). Throws [IdentityTakenFailure] when a link's email has an account
  /// (#17). Throws [UnsentChangesFailure] when a re-auth names another
  /// account while changes are unsent, unless [confirmedLoss] (ruling 6).
  Future<void> requestCode(String email, {bool confirmedLoss = false}) =>
      _serial(() async {
        switch (await _signInContext()) {
          case _SignIn.link:
            return _gateway.requestEmailLink(email);
          case _SignIn.target:
            return _gateway.requestEmailSignIn(email);
          case _SignIn.reauth:
            await _checkReplace(email, confirmedLoss: confirmedLoss);
            return _gateway.requestEmailSignIn(email);
        }
      });

  Future<void> verifyCode(String email, String code) => _serial(() async {
    switch (await _signInContext()) {
      case _SignIn.link:
        await _gateway.verifyEmailLink(email, code);
        return _validate(); // #16
      case _SignIn.target:
        return _signInTarget(
          () => _gateway.verifyEmailSignIn(email, code),
        ); // #21
      case _SignIn.reauth:
        await _gateway.verifyEmailSignIn(email, code);
        return _afterReauth(); // #36, #37
    }
  });

  Future<void> continueWithGoogle({bool confirmedLoss = false}) => _serial(
    () async {
      final context = await _signInContext();
      final credential = _pendingGoogle ?? await _gateway.pickGoogle();
      try {
        switch (context) {
          case _SignIn.link:
            await _gateway.linkGoogle(credential);
            _pendingGoogle = null;
            await _validate(); // #16
          case _SignIn.target:
            await _signInTarget(() => _gateway.signInGoogle(credential));
            _pendingGoogle = null; // #21
          case _SignIn.reauth:
            await _checkReplace(credential.email, confirmedLoss: confirmedLoss);
            await _gateway.signInGoogle(credential);
            _pendingGoogle = null;
            await _afterReauth(); // #36, #37
        }
      } on IdentityTakenFailure {
        _pendingGoogle = credential; // #17
        rethrow;
      } on UnsentChangesFailure {
        _pendingGoogle = credential; // asked again with confirmedLoss
        rethrow;
      }
    },
  );

  /// Starts moving this device to another account: #18 from an anonymous
  /// user whose identity is taken, #34 "Switch account" from an account.
  /// The gate shuts, the source's changes are sent and, for a merge, a claim
  /// is taken. Then the state asks for the target sign-in.
  Future<void> beginSwitch({
    required TransitionChoice choice,
    String? targetHint,
  }) => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    if (choice == TransitionChoice.merge && !user.isAnonymous) {
      throw ArgumentError.value(
        choice,
        'choice',
        'only an anonymous user merges',
      );
    }
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: choice,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
        targetHint: targetHint,
      ),
    );
  });

  /// Before the target sign-in: back to the source as it was (#22). With the
  /// source's session gone, the source is treated as lost (plan ruling 9).
  Future<void> cancelSwitch() => _serial(() async {
    final t = await _store.transition();
    final userId = _gateway.currentUserId;
    if (t == null ||
        t.kind != TransitionKind.switchAccount ||
        !t.stage.isBefore(TransitionStage.targetSignedIn) ||
        (userId != null && userId != t.sourceUserId)) {
      throw StateError('No switch to cancel before the target sign-in');
    }
    _pendingGoogle = null;
    await _drop(t);
    if (userId == t.sourceUserId) return _validate(); // #22
    return _lost(sessionInvalid: true);
  });

  /// Signs this device out (#39–#41). X's changes are sent first; offline,
  /// that waits unless [discardUnsent]. Then the logs are shipped, the
  /// session goes, the device's account data is cleared, and a new
  /// anonymous user starts.
  Future<void> signOut({bool discardUnsent = false}) => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    return _begin(
      _newTransition(
        TransitionKind.signOut,
        choice: discardUnsent ? TransitionChoice.discard : null,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
      ),
    );
  });

  /// Deletes the account on the server, then clears the device like a
  /// sign-out (#42–#44). Online only: offline, it refuses before anything
  /// changes.
  Future<void> deleteAccount() => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    if (!await _network.isOnline) {
      throw const OfflineFailure(
        cause: 'deleting an account needs the network',
      );
    }
    return _begin(
      _newTransition(
        TransitionKind.delete,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
      ),
    );
  });

  /// From REAUTH_REQUIRED: gives up the refused account. Its data on this
  /// device goes, and a new anonymous user starts (#38).
  Future<void> continueWithoutAccount() => _serial(() async {
    final last = switch (_state) {
      ReauthRequired(:final last) => last,
      _ => throw StateError('Only a refused sign-in continues without it'),
    };
    return _begin(
      _newTransition(
        TransitionKind.clearToAnon,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ),
    );
  });

  /// Ruling 6: a re-auth as another account clears this device, so unsent
  /// changes are confirmed first.
  Future<void> _checkReplace(
    String? email, {
    required bool confirmedLoss,
  }) async {
    final last = (_state as ReauthRequired).last;
    if (confirmedLoss || _sameEmail(email, last.email)) return;
    final count = await _sync.pendingCount();
    if (count > 0) throw UnsentChangesFailure(count: count);
  }

  static bool _sameEmail(String? a, String? b) =>
      a != null &&
      b != null &&
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// #36: the same account, validated. #37: another one, a discard switch
  /// that is past the sign-in.
  Future<void> _afterReauth() async {
    final last = (_state as ReauthRequired).last;
    final userId = _gateway.currentUserId!;
    if (userId == last.id) return _validate();
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: TransitionChoice.discard,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ).copyWith(targetUserId: userId, stage: TransitionStage.targetSignedIn),
    );
  }

  Future<_SignIn> _signInContext() async {
    final pending = await _store.transition();
    if (pending != null) {
      if (pending.kind == TransitionKind.switchAccount) return _SignIn.target;
      throw StateError('No sign-in during ${pending.kind.name}');
    }
    return switch (_state) {
      Ready(:final user) when user.isAnonymous => _SignIn.link,
      ReauthRequired() => _SignIn.reauth,
      _ => throw StateError('No account step takes a sign-in in $_state'),
    };
  }

  /// #21, and ruling 4: A's refresh token is kept just before the SDK
  /// replaces it with B's. A refused sign-in changes nothing.
  Future<void> _signInTarget(Future<void> Function() signIn) async {
    final t = (await _store.transition())!;
    _liveOpId = t.opId;
    final source = t.sourceUserId;
    if (t.merges &&
        t.stage.isBefore(TransitionStage.merged) &&
        source != null &&
        _gateway.currentUserId == source) {
      final token = _gateway.refreshToken;
      if (token != null) {
        await _secrets.write(backupSecretKey(t.opId), token);
      }
    }
    await signIn();
    return _driveSwitch(t);
  }

  // --- The switch -------------------------------------------------------------

  Future<void> _driveSwitch(AccountTransition t) async {
    _gate.close();
    await _sync.pause();
    _emit(_inTransition(t));
    final userId = _gateway.currentUserId; // R1
    if (userId != null && userId == t.sourceUserId) {
      if (_liveOpId == t.opId) return _advanceSource(t); // #19, #20
      if (t.stage.isBefore(TransitionStage.merged)) {
        await _drop(t); // #31
        return _validate();
      }
      _log.error(
        'auth.switch_source_after_merge',
        category: LogCategory.state,
        context: {'op': t.opId, 'stage': t.stage.name},
      );
      return _emit(Recovering(t, stuck: true));
    }
    if (userId == null) return _switchWithoutSession(t); // #33
    return _advanceTarget(t, userId); // #32
  }

  Future<void> _advanceSource(AccountTransition t) async {
    var s = t;
    if (s.stage == TransitionStage.started) {
      try {
        await _sync.pushPending(); // #19
      } on Failure catch (error) {
        return _emit(Transitioning(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.sourcePushed));
    }
    if (s.merges && s.stage == TransitionStage.sourcePushed) {
      final String token;
      try {
        token = await _api.claimBegin(); // #20
      } on Failure catch (error) {
        return _emit(Transitioning(s, error: error));
      }
      await _secrets.write(claimSecretKey(s.opId), token);
      s = await _save(s.copyWith(stage: TransitionStage.claimed));
    }
    _emit(Transitioning(s, needsTargetSignIn: true));
  }

  /// #33: no session. Before the merge, back to A through its backup; after
  /// it, the gate stays shut until the target signs in again.
  Future<void> _switchWithoutSession(AccountTransition t) async {
    final backup = await _secrets.read(backupSecretKey(t.opId));
    if (t.stage.isBefore(TransitionStage.merged) && backup != null) {
      try {
        await _gateway.restoreSession(backup);
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(t, error: error));
      } on SessionInvalidFailure {
        await _secrets.delete(backupSecretKey(t.opId));
        return _emit(_inTransition(t, needsTargetSignIn: true));
      }
      return _driveSwitch(t); // the SDK is on A again: #31
    }
    _emit(_inTransition(t, needsTargetSignIn: true));
  }

  /// #32 and #23–#30, on the target [userId] the SDK holds.
  Future<void> _advanceTarget(AccountTransition t, String userId) async {
    var s = t;
    if (s.targetUserId != userId ||
        s.stage.isBefore(TransitionStage.targetSignedIn)) {
      s = await _save(
        s.copyWith(
          targetUserId: userId,
          stage: s.stage.atLeast(TransitionStage.targetSignedIn),
        ),
      );
    }
    if (s.merges && s.stage == TransitionStage.targetSignedIn) {
      final token = await _secrets.read(claimSecretKey(s.opId));
      try {
        if (token == null) throw const ClaimInvalidFailure();
        await _api.merge(token, s.opId); // #23, MERGED on a retry
      } on ClaimInvalidFailure {
        return _mergeRefused(s); // #25
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error)); // #26
      }
      await _secrets.delete(backupSecretKey(s.opId)); // #24
      s = await _save(s.copyWith(stage: TransitionStage.merged));
    }
    if (s.stage.isBefore(TransitionStage.localCleared)) {
      await _localReset.run(); // #27
      s = await _save(s.copyWith(stage: TransitionStage.localCleared));
    }
    if (s.stage.isBefore(TransitionStage.targetPulled)) {
      try {
        await _sync.pullAll(); // #28
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.targetPulled));
    }
    if (s.merges && s.stage == TransitionStage.targetPulled) {
      try {
        await _api.mergeAck(s.opId); // #29
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.acknowledged));
    }
    await _store.saveLastKnown(
      AccountUser(
        id: userId,
        email: s.targetHint,
        isAnonymous: false,
        role: AccountRole.user,
      ),
      _now(),
    ); // plan ruling 7; me() replaces it at once
    await _drop(s); // #30
    return _validate();
  }

  /// #25: the claim was refused, so nothing moved. Back to A with its data.
  /// When A cannot come back, a new anonymous user takes the data (ruling
  /// 8).
  Future<void> _mergeRefused(AccountTransition s) async {
    final backup = await _secrets.read(backupSecretKey(s.opId));
    if (backup != null) {
      try {
        await _gateway.restoreSession(backup);
        await _drop(s);
        _notice(const MergeNotDone());
        await _validate();
        return;
      } on OfflineFailure catch (error) {
        return _emit(
          _inTransition(s, error: error),
        ); // the same op on reconnect
      } on SessionInvalidFailure {
        // Ruling 8, below.
      }
    }
    await _gateway.signOutLocal(); // B never sees A's data
    await _drop(s);
    _notice(const MergeNotDone());
    return _begin(
      _newTransition(TransitionKind.anonRecovery, sourceIsAnonymous: true),
    );
  }

  /// Ruling 7: the SDK holds another account than the one whose data the
  /// device has, and no transition says why. The device takes the SDK's
  /// account, as a discard switch that is past the sign-in.
  Future<void> _adopt(AccountUser last, String userId) {
    _log.warning(
      'auth.account_mismatch',
      category: LogCategory.state,
      context: {'last': last.id, 'signed_in': userId},
    );
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: TransitionChoice.discard,
        sourceUserId: last.id,
        sourceIsAnonymous: last.isAnonymous,
      ).copyWith(targetUserId: userId, stage: TransitionStage.targetSignedIn),
    );
  }

  AccountUser _readyUser() => switch (_state) {
    Ready(:final user) => user,
    _ => throw StateError('This needs a confirmed account, not $_state'),
  };

  Future<void> _ensureNoTransition() async {
    if (await _store.transition() != null) {
      throw StateError('An account transition is already running');
    }
  }

  void _notice(AccountNotice notice) {
    if (!_notices.isClosed) _notices.add(notice);
  }

  Future<void> dispose() async {
    await Future.wait([
      for (final subscription in _subscriptions) subscription.cancel(),
    ]);
    await _states.close();
    await _notices.close();
  }

  // --- Start and validation -------------------------------------------------

  Future<void> _settle() async {
    final userId = _gateway.currentUserId; // R1
    if (userId != null) {
      final last = await _store.lastKnown();
      if (last != null && last.id != userId) return _adopt(last, userId);
      return _validate(); // #2, #5
    }
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

  /// #39–#45: send (sign-out), delete on the server (deletion), sign out,
  /// clear the device, start anonymous. Every step is idempotent, so a
  /// launch continues from the saved stage.
  Future<void> _driveSignOut(AccountTransition t) async {
    _gate.close();
    await _sync.pause();
    _emit(_inTransition(t));
    var s = t;
    // Only while the SDK still holds the source: a rerun after the SDK
    // signed out has nothing left to send and no session to send it with
    // (R3).
    if (s.stage == TransitionStage.started &&
        s.kind == TransitionKind.signOut &&
        _gateway.currentUserId == s.sourceUserId) {
      try {
        await _sync.pushPending(); // #39
      } on Failure catch (error) {
        final accepted =
            error is OfflineFailure && s.choice == TransitionChoice.discard;
        if (!accepted) return _emit(_inTransition(s, error: error));
      }
      await _flushLogsQuietly();
    }
    if (s.stage == TransitionStage.started && s.kind == TransitionKind.delete) {
      try {
        await _api.deleteAccount(); // #42
      } on ProfileGoneFailure {
        // #43: an earlier try already deleted it.
      } on LastAdminFailure catch (error) {
        return _refuseDelete(s, error); // #44
      } on OfflineFailure catch (error) {
        return _refuseDelete(s, error); // #44
      }
      s = await _save(s.copyWith(stage: TransitionStage.serverDeleted));
    }
    if (s.stage != TransitionStage.signedOut) {
      if (_gateway.currentUserId != null) await _gateway.signOutLocal(); // #40
      s = await _save(s.copyWith(stage: TransitionStage.signedOut));
    }
    await _localReset.run(); // #41
    await _store.clearLastKnown();
    await _drop(s);
    return _settle();
  }

  Future<void> _refuseDelete(AccountTransition s, Failure failure) async {
    await _drop(s);
    _notice(DeleteRefused(failure));
    return _validate();
  }

  /// The logs go before the session does (spec §4: LogDatabase is kept, and
  /// shipped before sign-out). A failure costs only logs.
  Future<void> _flushLogsQuietly() async {
    try {
      await _flushLogs?.call();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'auth.logs_not_shipped',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
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

/// What a sign-in command does in the current state.
enum _SignIn { link, target, reauth }
