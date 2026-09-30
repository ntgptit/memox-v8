import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';

import '../../support/test_database.dart';

void main() {
  final at = DateTime.utc(2026, 9, 30, 8);

  test('the last known account round-trips and is cleared', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = AccountStore(db);
    const user = AccountUser(
      id: 'u1',
      email: 'a@example.com',
      isAnonymous: false,
      role: AccountRole.admin,
    );

    expect(await store.lastKnown(), isNull);
    await store.saveLastKnown(user, at);
    await store.saveLastKnown(user, at.add(const Duration(minutes: 1)));
    expect(await store.lastKnown(), user);

    await store.clearLastKnown();
    expect(await store.lastKnown(), isNull);
  });

  test('the transition round-trips every field and is one row', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = AccountStore(db);
    final t = AccountTransition(
      opId: 'op',
      kind: TransitionKind.switchAccount,
      choice: TransitionChoice.merge,
      sourceUserId: 'A',
      sourceIsAnonymous: true,
      targetHint: 'b@example.com',
      stage: TransitionStage.claimed,
      createdAt: at,
      updatedAt: at,
    );

    await store.saveTransition(t);
    await store.saveTransition(
      t.copyWith(stage: TransitionStage.targetSignedIn, targetUserId: 'B'),
    );
    final read = (await store.transition())!;

    expect(read.opId, 'op');
    expect(read.kind, TransitionKind.switchAccount);
    expect(read.choice, TransitionChoice.merge);
    expect(read.sourceUserId, 'A');
    expect(read.sourceIsAnonymous, isTrue);
    expect(read.targetUserId, 'B');
    expect(read.targetHint, 'b@example.com');
    expect(read.stage, TransitionStage.targetSignedIn);
    expect(read.createdAt.isAtSameMomentAs(at), isTrue);

    await store.clearTransition();
    expect(await store.transition(), isNull);
  });
}
