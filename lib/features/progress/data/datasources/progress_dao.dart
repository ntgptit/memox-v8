import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

/// A day of the last seven with activity: its Learning and Reviewing
/// card-days.
typedef ActiveDayRow = ({int day, int learning, int reviewing});

/// One range's four numbers.
typedef CountsRow = ({int cards, int days, int learning, int reviewing});

/// A row of a level: a deck with its numbers for the week and the month; the
/// level's total when [deckId] is null (Progress spec D5).
typedef LevelRow = ({
  String? deckId,
  String? name,
  CountsRow week,
  CountsRow month,
});

/// The answers that count, `r`, with their card `c` and its deck `k`: live
/// cards only, never a `browse` row (BR-PROGRESS-012), on a local day, at the
/// read's offset `?1`, that meets [days] (Progress spec §6.1).
String _answers(String days) =>
    ' FROM review_log r'
    ' JOIN card c ON c.id = r.card_id'
    ' JOIN deck k ON k.id = c.deck_id'
    ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
    " AND r.mode <> 'browse' AND (r.answered_at + ?1) / 86400 $days";

/// The card-days of [_answers]: one row per card and local day, with the
/// `tile_id` a level groups by. A card-day with a `learning` answer is
/// Learning (BR-PROGRESS-005).
String _cardDays({required String tile, required String days}) =>
    'SELECT c.id AS card_id, $tile AS tile_id,'
    ' (r.answered_at + ?1) / 86400 AS day,'
    " MAX(r.kind = 'learning') AS is_learning"
    '${_answers(days)}'
    ' GROUP BY c.id, day';

/// The four numbers of the week (days from `?2`) and of the month, over the
/// card-days in scope (BR-PROGRESS-001, BR-PROGRESS-002).
const _numbers =
    ' COUNT(DISTINCT card_id) FILTER (WHERE day >= ?2) AS week_cards,'
    ' COUNT(DISTINCT day) FILTER (WHERE day >= ?2) AS week_days,'
    ' COUNT(*) FILTER (WHERE day >= ?2 AND is_learning) AS week_learning,'
    ' COUNT(*) FILTER (WHERE day >= ?2 AND NOT is_learning)'
    ' AS week_reviewing,'
    ' COUNT(DISTINCT card_id) AS month_cards,'
    ' COUNT(DISTINCT day) AS month_days,'
    ' COUNT(*) FILTER (WHERE is_learning) AS month_learning,'
    ' COUNT(*) FILTER (WHERE NOT is_learning) AS month_reviewing';

/// The reads of the Progress screen (Progress spec §6). They write nothing
/// (BR-PROGRESS-007, BR-PROGRESS-009).
final class ProgressDao {
  const ProgressDao(this._db);

  final AppDatabase _db;

  /// Every local day with activity up to today, oldest first, folded in
  /// SQLite: the streak's days (UC-PROGRESS-001 step 2, BR-PROGRESS-016).
  Future<List<int>> activeDays(ProgressDays days) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT (r.answered_at + ?1) / 86400 AS day'
          '${_answers('<= ?2')} ORDER BY day',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [for (final row in rows) row.read<int>('day')];
  }

  /// The days of the last seven with activity, with their Learning and
  /// Reviewing card-days: Today and the bars (BR-PROGRESS-014,
  /// BR-PROGRESS-015).
  Future<List<ActiveDayRow>> weekActivity(ProgressDays days) async {
    final rows = await _db
        .customSelect(
          'WITH card_days AS'
          " (${_cardDays(tile: 'NULL', days: 'BETWEEN ?2 AND ?3')})"
          ' SELECT day,'
          ' COUNT(*) FILTER (WHERE is_learning) AS learning,'
          ' COUNT(*) FILTER (WHERE NOT is_learning) AS reviewing'
          ' FROM card_days GROUP BY day ORDER BY day',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.weekStart),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [
      for (final row in rows)
        (
          day: row.read<int>('day'),
          learning: row.read<int>('learning'),
          reviewing: row.read<int>('reviewing'),
        ),
    ];
  }

  /// Every active root deck with the numbers of its whole tree, grouped by
  /// `root_id`, and the library's total from the same statement
  /// (BR-PROGRESS-002, BR-PROGRESS-004).
  Future<List<LevelRow>> rootLevel(ProgressDays days) => _level(
    days,
    cardDays: _cardDays(tile: 'k.root_id', days: 'BETWEEN ?3 AND ?4'),
    decks: 'd.parent_id IS NULL',
  );

  /// Fires once when listened to, then after every write to the history,
  /// the cards or the decks (BR-PROGRESS-008).
  Stream<void> changes() =>
      tableChanges(_db, [_db.reviewLog, _db.card, _db.deck]);

  /// The decks that match [decks], each with the card-days whose `tile_id`
  /// is its id, then one total row over every card-day of [cardDays]
  /// (Progress spec D5).
  Future<List<LevelRow>> _level(
    ProgressDays days, {
    required String cardDays,
    required String decks,
  }) async {
    final rows = await _db
        .customSelect(
          'WITH card_days AS ($cardDays),'
          ' tiles AS (SELECT tile_id,$_numbers FROM card_days GROUP BY tile_id)'
          ' SELECT d.id AS deck_id, d.name AS name, tiles.*'
          ' FROM deck d LEFT JOIN tiles ON tiles.tile_id = d.id'
          ' WHERE $decks AND d.delete_batch_id IS NULL'
          ' UNION ALL'
          ' SELECT NULL, NULL, NULL,$_numbers FROM card_days',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.weekStart),
            Variable<int>(days.monthStart),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [for (final row in rows) _levelRowOf(row)];
  }
}

LevelRow _levelRowOf(QueryRow row) => (
  deckId: row.readNullable<String>('deck_id'),
  name: row.readNullable<String>('name'),
  week: _countsOf(row, 'week'),
  month: _countsOf(row, 'month'),
);

/// A deck with no activity has no `tiles` row: its numbers are zero.
CountsRow _countsOf(QueryRow row, String range) => (
  cards: row.readNullable<int>('${range}_cards') ?? 0,
  days: row.readNullable<int>('${range}_days') ?? 0,
  learning: row.readNullable<int>('${range}_learning') ?? 0,
  reviewing: row.readNullable<int>('${range}_reviewing') ?? 0,
);
