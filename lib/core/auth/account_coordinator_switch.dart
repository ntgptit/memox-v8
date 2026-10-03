part of 'account_coordinator.dart';

/// Linking an identity, and switching the device to another account (auth
/// spec §3.3 #16–#35, plan rulings 4, 7–9).
extension AccountSwitching on AccountCoordinator {
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

  /// A re-auth's replace check without a send, for a code already on its way
  /// to [email] (2.41): changes added since that send are confirmed before
  /// the code is entered, as [requestCode] would (ruling 6).
  Future<void> checkReplace(String email, {bool confirmedLoss = false}) =>
      _serial(() async {
        if (_state is! ReauthRequired) return;
        await _checkReplace(email, confirmedLoss: confirmedLoss);
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

  /// The person declined what the kept Google account would do (its loss
  /// of unsent changes): the next press shows the picker again (P3b final
  /// review I1).
  void forgetPickedGoogle() => _pendingGoogle = null;

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
    // The reset at #27 assumes the source was sent (and, for a merge,
    // claimed) first (final review I6).
    final sourceReady = t.merges
        ? !t.stage.isBefore(TransitionStage.claimed)
        : !t.stage.isBefore(TransitionStage.sourcePushed);
    if (!sourceReady) {
      throw StateError('The source is not sent yet: retry or cancel first');
    }
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
      return _emit(Recovering(t, isStuck: true));
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
    _emit(Transitioning(s, isAwaitingTargetSignIn: true));
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
        return _emit(_inTransition(t, isAwaitingTargetSignIn: true));
      }
      return _driveSwitch(t); // the SDK is on A again: #31
    }
    _emit(_inTransition(t, isAwaitingTargetSignIn: true));
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
}

/// What a sign-in command does in the current state.
enum _SignIn { link, target, reauth }
