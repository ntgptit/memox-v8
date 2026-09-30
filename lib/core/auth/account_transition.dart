/// What an account transition does (auth spec §3.3).
enum TransitionKind {
  switchAccount,
  signOut,
  delete,
  clearToAnon,
  anonRecovery,
}

/// Whether a switch brings this device's data into the target account.
/// On a sign-out, `discard` means the user accepted losing unsent changes
/// (plan ruling 10).
enum TransitionChoice { merge, discard }

/// How far a transition got, in the order flows pass them. Each kind uses
/// its own subsequence:
/// - Switch: started … acknowledged.
/// - SignOut, Delete and ClearToAnon: started, serverDeleted, signedOut.
/// - AnonRecovery: started, newAnon.
///
/// Every stage is saved before the next step, so a rerun resumes where the
/// last run stopped (spec §6).
enum TransitionStage {
  started,
  sourcePushed,
  claimed,
  targetSignedIn,
  merged,
  localCleared,
  targetPulled,
  acknowledged,
  serverDeleted,
  signedOut,
  newAnon;

  bool isBefore(TransitionStage other) => index < other.index;

  /// The later of this stage and [other].
  TransitionStage atLeast(TransitionStage other) =>
      index >= other.index ? this : other;
}

/// The account transition in progress (auth spec §4): its intent and how far
/// it got. Never who is signed in: the SDK says that (R1).
final class AccountTransition {
  const AccountTransition({
    required this.opId,
    required this.kind,
    required this.stage,
    required this.createdAt,
    required this.updatedAt,
    this.choice,
    this.sourceUserId,
    this.sourceIsAnonymous,
    this.targetUserId,
    this.targetHint,
  });

  /// The merge's `operation_id`; also the key of this flow's secrets.
  final String opId;
  final TransitionKind kind;
  final TransitionChoice? choice;
  final String? sourceUserId;
  final bool? sourceIsAnonymous;
  final String? targetUserId;

  /// The target's email as typed, shown while the target sign-in is asked.
  final String? targetHint;
  final TransitionStage stage;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get merges => choice == TransitionChoice.merge;

  /// Business writes wait during every transition but an anonymous
  /// recovery (R3, spec §3.2).
  bool get blocksWrites => kind != TransitionKind.anonRecovery;

  AccountTransition copyWith({
    TransitionStage? stage,
    String? targetUserId,
    DateTime? updatedAt,
  }) => AccountTransition(
    opId: opId,
    kind: kind,
    choice: choice,
    sourceUserId: sourceUserId,
    sourceIsAnonymous: sourceIsAnonymous,
    targetUserId: targetUserId ?? this.targetUserId,
    targetHint: targetHint,
    stage: stage ?? this.stage,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() =>
      'AccountTransition(${kind.name}, ${stage.name}, op: $opId)';
}
