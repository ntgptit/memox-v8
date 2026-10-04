import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

/// The step the transition layer names (account UI spec §5.4).
enum AccountStep {
  sending,
  preparing,
  merging,
  downloading,
  signingOut,
  deleting,
}

/// What the layer shows: a transition that blocks writes, and how it stands.
typedef BlockingView = ({
  AccountTransition transition,
  bool isAwaitingTargetSignIn,
  Failure? error,
  bool isStuck,
});

/// The layer's view of [state], or null when nothing blocks. An anonymous
/// recovery lets writes through, so it shows nothing (auth spec §3.2).
BlockingView? blockingViewOf(AuthState? state) => switch (state) {
  Transitioning(:final transition, :final isAwaitingTargetSignIn, :final error)
      when transition.blocksWrites =>
    (
      transition: transition,
      isAwaitingTargetSignIn: isAwaitingTargetSignIn,
      error: error,
      isStuck: false,
    ),
  Recovering(
    :final transition,
    :final isAwaitingTargetSignIn,
    :final error,
    :final isStuck,
  )
      when transition.blocksWrites =>
    (
      transition: transition,
      isAwaitingTargetSignIn: isAwaitingTargetSignIn,
      error: error,
      isStuck: isStuck,
    ),
  _ => null,
};

/// The step for the stage the record reached. The coordinator saves each
/// stage before the next step, so the stage names the step running.
AccountStep accountStepOf(AccountTransition t) => switch (t.kind) {
  TransitionKind.switchAccount => switch (t.stage) {
    TransitionStage.started => AccountStep.sending,
    TransitionStage.sourcePushed ||
    TransitionStage.claimed => AccountStep.preparing,
    TransitionStage.targetSignedIn when t.merges => AccountStep.merging,
    _ => AccountStep.downloading,
  },
  TransitionKind.signOut =>
    t.stage == TransitionStage.started
        ? AccountStep.sending
        : AccountStep.signingOut,
  TransitionKind.delete =>
    t.stage == TransitionStage.started
        ? AccountStep.deleting
        : AccountStep.signingOut,
  TransitionKind.clearToAnon ||
  TransitionKind.anonRecovery => AccountStep.signingOut,
};

/// Auth spec #22: a switch goes back to where it started only before the
/// target signs in.
bool canCancelSwitch(AccountTransition t) =>
    t.kind == TransitionKind.switchAccount &&
    t.stage.isBefore(TransitionStage.targetSignedIn);

/// Critique 2026-10-02 (F2): a sign-out goes back to where it started only
/// before the SDK signs out, while nothing on this device is gone.
bool canCancelSignOut(AccountTransition t) =>
    t.kind == TransitionKind.signOut && t.stage == TransitionStage.started;
