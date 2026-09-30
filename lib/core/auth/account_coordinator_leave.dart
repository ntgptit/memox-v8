part of 'account_coordinator.dart';

/// Signing in again, signing out, deleting the account and clearing to a new
/// anonymous user (auth spec §3.3 #13, #36–#45, plan ruling 6).
extension AccountLeaving on AccountCoordinator {
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
}
