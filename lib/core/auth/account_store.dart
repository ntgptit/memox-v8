import 'package:drift/drift.dart';
import 'package:memox/core/auth/account_transition.dart' as auth;
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/database/app_database.dart';

part 'account_store.g.dart';

/// The account's persisted state (auth spec §4): the last account `me()`
/// confirmed and the transition in progress. Device-only; never synced. It
/// writes past the mutation gate (R3 stops business writes, not these).
/// Its statements are `account_state_queries.drift`'s.
@DriftAccessor(
  include: {'package:memox/core/database/queries/account_state_queries.drift'},
)
class AccountStore extends DatabaseAccessor<AppDatabase>
    with _$AccountStoreMixin {
  AccountStore(super.attachedDatabase);

  Future<AccountUser?> lastKnown() async {
    final row = await accountStateRow().getSingleOrNull();
    if (row == null) return null;
    return AccountUser(
      id: row.userId,
      email: row.email,
      isAnonymous: row.isAnonymous == 1,
      role: AccountRole.parse(row.role),
    );
  }

  Future<void> saveLastKnown(AccountUser user, DateTime at) =>
      upsertAccountState(
        AccountStateCompanion.insert(
          id: const Value(accountRowId),
          userId: user.id,
          email: Value(user.email),
          isAnonymous: user.isAnonymous ? 1 : 0,
          role: user.role.name,
          validatedAt: at,
        ),
      );

  Future<void> clearLastKnown() => clearAccountState();

  Future<auth.AccountTransition?> transition() async {
    final row = await accountTransitionRow().getSingleOrNull();
    if (row == null) return null;
    final sourceIsAnonymous = row.sourceIsAnonymous;
    final choice = row.choice;
    return auth.AccountTransition(
      opId: row.opId,
      kind: auth.TransitionKind.values.byName(row.kind),
      choice: choice == null
          ? null
          : auth.TransitionChoice.values.byName(choice),
      sourceUserId: row.sourceUserId,
      sourceIsAnonymous: sourceIsAnonymous == null
          ? null
          : sourceIsAnonymous == 1,
      targetUserId: row.targetUserId,
      targetHint: row.targetHint,
      stage: auth.TransitionStage.values.byName(row.stage),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Saves [t] as the one record and returns it.
  Future<auth.AccountTransition> saveTransition(
    auth.AccountTransition t,
  ) async {
    final sourceIsAnonymous = t.sourceIsAnonymous;
    await upsertAccountTransition(
      AccountTransitionCompanion.insert(
        id: const Value(accountRowId),
        opId: t.opId,
        kind: t.kind.name,
        choice: Value(t.choice?.name),
        sourceUserId: Value(t.sourceUserId),
        sourceIsAnonymous: Value(
          sourceIsAnonymous == null ? null : (sourceIsAnonymous ? 1 : 0),
        ),
        targetUserId: Value(t.targetUserId),
        targetHint: Value(t.targetHint),
        stage: t.stage.name,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      ),
    );
    return t;
  }

  Future<void> clearTransition() => clearAccountTransition();
}
