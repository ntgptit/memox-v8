import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';

void main() {
  final at = DateTime.utc(2026, 9, 30);

  test('a switch passes its stages in order', () {
    const order = [
      TransitionStage.started,
      TransitionStage.sourcePushed,
      TransitionStage.claimed,
      TransitionStage.targetSignedIn,
      TransitionStage.merged,
      TransitionStage.localCleared,
      TransitionStage.targetPulled,
      TransitionStage.acknowledged,
    ];
    for (var i = 1; i < order.length; i++) {
      expect(order[i - 1].isBefore(order[i]), isTrue, reason: '${order[i]}');
    }
    expect(
      TransitionStage.claimed.atLeast(TransitionStage.targetSignedIn),
      TransitionStage.targetSignedIn,
    );
    expect(
      TransitionStage.merged.atLeast(TransitionStage.targetSignedIn),
      TransitionStage.merged,
    );
  });

  test('sign-out and recovery stages come after the switch ones', () {
    expect(
      TransitionStage.started.isBefore(TransitionStage.serverDeleted),
      isTrue,
    );
    expect(
      TransitionStage.serverDeleted.isBefore(TransitionStage.signedOut),
      isTrue,
    );
    expect(TransitionStage.started.isBefore(TransitionStage.newAnon), isTrue);
  });

  test('copyWith moves the stage and keeps the intent', () {
    final t = AccountTransition(
      opId: 'op',
      kind: TransitionKind.switchAccount,
      choice: TransitionChoice.merge,
      sourceUserId: 'A',
      sourceIsAnonymous: true,
      stage: TransitionStage.claimed,
      createdAt: at,
      updatedAt: at,
    );
    final next = t.copyWith(
      stage: TransitionStage.targetSignedIn,
      targetUserId: 'B',
    );

    expect(next.stage, TransitionStage.targetSignedIn);
    expect(next.targetUserId, 'B');
    expect(next.opId, 'op');
    expect(next.sourceUserId, 'A');
    expect(next.merges, isTrue);
    expect(next.blocksWrites, isTrue);
  });

  test('only anonymous recovery lets business writes through', () {
    for (final kind in TransitionKind.values) {
      final t = AccountTransition(
        opId: 'op',
        kind: kind,
        stage: TransitionStage.started,
        createdAt: at,
        updatedAt: at,
      );
      expect(
        t.blocksWrites,
        kind != TransitionKind.anonRecovery,
        reason: '$kind',
      );
    }
  });

  test('a role other than admin is a user', () {
    expect(AccountRole.parse('admin'), AccountRole.admin);
    expect(AccountRole.parse('user'), AccountRole.user);
    expect(AccountRole.parse(null), AccountRole.user);
    expect(
      const AccountUser(id: 'u', isAnonymous: false, role: AccountRole.admin),
      const AccountUser(id: 'u', isAnonymous: false, role: AccountRole.admin),
    );
  });
}
