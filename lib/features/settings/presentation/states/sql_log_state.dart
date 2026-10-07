/// The SQL log switch row's own state: the row's value comes from the
/// settings stream; this holds only the save in flight and whether the last
/// one failed (a thrown `Failure`, as every settings write reports it).
final class SqlLogState {
  const SqlLogState({this.isSaving = false, this.hasFailure = false});

  final bool isSaving;
  final bool hasFailure;
}
