import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';

import '../../../support/account_harness.dart';

void main() {
  const merge = TransitionChoice.merge;
  const discard = TransitionChoice.discard;

  test('a switch sends, prepares, merges or downloads by its stage', () {
    AccountStep step(TransitionStage stage, TransitionChoice choice) =>
        accountStepOf(
          transitionOf(TransitionKind.switchAccount, stage, choice: choice),
        );

    expect(step(TransitionStage.started, merge), AccountStep.sending);
    expect(step(TransitionStage.sourcePushed, merge), AccountStep.preparing);
    expect(step(TransitionStage.claimed, merge), AccountStep.preparing);
    expect(step(TransitionStage.targetSignedIn, merge), AccountStep.merging);
    expect(
      step(TransitionStage.targetSignedIn, discard),
      AccountStep.downloading,
    );
    expect(step(TransitionStage.localCleared, merge), AccountStep.downloading);
  });

  test('sign-out sends first; deletion deletes first; both then sign out', () {
    AccountStep step(TransitionKind kind, TransitionStage stage) =>
        accountStepOf(transitionOf(kind, stage));

    expect(
      step(TransitionKind.signOut, TransitionStage.started),
      AccountStep.sending,
    );
    expect(
      step(TransitionKind.signOut, TransitionStage.signedOut),
      AccountStep.signingOut,
    );
    expect(
      step(TransitionKind.delete, TransitionStage.started),
      AccountStep.deleting,
    );
    expect(
      step(TransitionKind.delete, TransitionStage.serverDeleted),
      AccountStep.signingOut,
    );
    expect(
      step(TransitionKind.clearToAnon, TransitionStage.started),
      AccountStep.signingOut,
    );
  });

  test('a switch can be cancelled only before the target signs in', () {
    bool can(TransitionStage stage) => canCancelSwitch(
      transitionOf(TransitionKind.switchAccount, stage, choice: merge),
    );

    expect(can(TransitionStage.claimed), isTrue);
    expect(can(TransitionStage.targetSignedIn), isFalse);
    expect(
      canCancelSwitch(
        transitionOf(TransitionKind.signOut, TransitionStage.started),
      ),
      isFalse,
    );
  });

  test('only a transition that blocks writes shows the layer', () {
    final signOut = transitionOf(
      TransitionKind.signOut,
      TransitionStage.started,
    );
    final recovery = transitionOf(
      TransitionKind.anonRecovery,
      TransitionStage.started,
    );
    const offline = OfflineFailure(cause: 'test');

    final view = blockingViewOf(Transitioning(signOut, error: offline));
    expect(view?.transition, signOut);
    expect(view?.error, offline);
    expect(blockingViewOf(Recovering(signOut, isStuck: true))?.isStuck, isTrue);
    expect(blockingViewOf(Transitioning(recovery)), isNull);
    expect(
      blockingViewOf(
        const Ready(
          AccountUser(id: 'u', isAnonymous: true, role: AccountRole.user),
        ),
      ),
      isNull,
    );
    expect(blockingViewOf(null), isNull);
  });
}
