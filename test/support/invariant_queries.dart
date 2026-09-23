import 'dart:io';

/// Invariant queries 1-32 of `docs/shared/data/schema.md` ("Bất biến"), read
/// from the document itself: the tests run exactly what the data model states,
/// and there is no copy to keep in step. Each query must return no row.
/// Invariants 33-37 need `delete_batches`, which does not exist yet
/// (foundation plan, Clarification 2).
final Map<int, String> invariantQueries = _readInvariantQueries();

const _lastInvariantInScope = 32;

Map<int, String> _readInvariantQueries() {
  final text = File('docs/shared/data/schema.md').readAsStringSync();
  final section = text.substring(text.indexOf('## Bất biến'));
  final sql = [
    for (final block in RegExp(
      r'```sql\n(.*?)```',
      dotAll: true,
    ).allMatches(section))
      block.group(1)!,
  ].join('\n');
  final headers = RegExp(
    r'^-- (\d+)\. ',
    multiLine: true,
  ).allMatches(sql).toList();
  final queries = <int, String>{};
  for (var i = 0; i < headers.length; i++) {
    final number = int.parse(headers[i].group(1)!);
    if (number > _lastInvariantInScope) continue;
    final end = i + 1 < headers.length ? headers[i + 1].start : sql.length;
    // The header line is the title; `--` lines under it are its notes.
    final lines = sql.substring(headers[i].end, end).split('\n').skip(1);
    final query = lines
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n')
        .trim();
    queries[number] = query.endsWith(';')
        ? query.substring(0, query.length - 1)
        : query;
  }
  return queries;
}

/// What each invariant holds, with the rules it cites.
const invariantSummaries = <int, String>{
  1: "a root deck holds no card (BR-DECK-004)",
  2: "an unset deck holds nothing (BR-DECK-006, BR-DECK-008)",
  3: "a card deck has no sub-deck (BR-DECK-009)",
  4: "a deck of decks has no direct card (BR-DECK-010)",
  5: "a root deck is a deck of decks",
  6: "a descendant points at its parent's root (BR-DECK-019)",
  7: "a root deck is its own root (BR-DECK-002)",
  8: "the deck tree has no cycle (BR-DECK-016)",
  9: "a schedule row runs its root's scheduler and generation (BR-SRS-028, BR-SRS-029)",
  10: "a sub-deck carries no scheduler column (BR-DECK-025)",
  11: "a root deck has a scheduler and a generation (BR-SRS-001)",
  12: "a session's status and end reason form a valid pair (BR-STUDY-010..018)",
  13: "an ended session has ended_at",
  14: "a relearning turn does not change the schedule (BR-SRS-017)",
  15: "no deck is deeper than 10 levels (BR-DECK-001)",
  16: "a completed session has no pending queue item (BR-STUDY-013)",
  17: "queue counters are not negative and self_assess stays within 4 turns (BR-STUDY-073)",
  18: "a session loads no more distinct cards than its card_limit (BR-STUDY-003, BR-STUDY-024)",
  19: "a round follows the round before it (BR-STUDY-059)",
  20: "a later round holds only cards of the round before (BR-STUDY-059)",
  21: "timer state appears only on recall, within 20 seconds (BR-STUDY-031, BR-STUDY-036)",
  22: "a timeout appears only on recall (BR-STUDY-034)",
  23: "fill-only columns appear only on fill (BR-STUDY-027, BR-STUDY-028)",
  24: "a learned card has a due date (BR-STUDY-053, BR-STUDY-058)",
  25: "an unlearned card has no scheduled turn (BR-STUDY-053, BR-STUDY-058)",
  26: "a learning turn belongs to a learning session (BR-STUDY-052)",
  27: "study options live on the root only (BR-STUDY-056)",
  28: "an unlearned card has no due date (BR-STUDY-053)",
  29: "an emptied sub-deck returns to unset (BR-DECK-015)",
  30: "a tree with a learned card has its scheduler locked (BR-SRS-003, BR-STUDY-053)",
  31: "a question direction appears only where it is allowed (BR-MODE-013, BR-MODE-015)",
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
};
