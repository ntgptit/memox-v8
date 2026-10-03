/// What a bulk action did with the ids it was given (SP2a 2.19): the ones
/// that still existed were written, the ones already gone were skipped, all
/// inside the same transaction. A rule the cards break is not a skip: that
/// refuses the batch as a `Rejected`.
final class BulkOutcome {
  const BulkOutcome({
    required this.done,
    this.skipped = const {},
    this.batchIds = const [],
  });

  /// The ids written.
  final Set<String> done;

  /// The ids that were gone when the write ran (deleted, in the Trash, or,
  /// for an export, in another deck). The caller prunes them from the
  /// selection and says how many there were.
  final Set<String> skipped;

  /// A delete only: the Trash batch written for each id of [done], in its
  /// order. An Undo names them (BR-TRASH-008).
  final List<String> batchIds;
}
