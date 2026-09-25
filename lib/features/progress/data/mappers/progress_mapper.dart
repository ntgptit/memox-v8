import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// The last seven days' split from their rows (Progress spec §6.5).
List<ActiveDay> activeDaysOf(List<ActiveDayRow> rows) => [
  for (final row in rows)
    ActiveDay(day: row.day, learning: row.learning, reviewing: row.reviewing),
];

/// A level from the rows of its statement: the one row with no deck is the
/// total, never added up from the others (Progress spec D5).
ProgressLevel levelOf(List<LevelRow> rows) => ProgressLevel(
  total: _rangeOf(rows.singleWhere((row) => row.deckId == null)),
  decks: [
    for (final row in rows)
      if (row.deckId case final deckId?)
        ProgressDeckRow(
          deckId: deckId,
          // A deck row always has its name (`deck.name` is NOT NULL).
          name: row.name!,
          progress: _rangeOf(row),
        ),
  ],
);

RangeProgress _rangeOf(LevelRow row) =>
    RangeProgress(week: _numbersOf(row.week), month: _numbersOf(row.month));

ProgressNumbers _numbersOf(CountsRow counts) => ProgressNumbers(
  activeCards: counts.cards,
  activeDays: counts.days,
  learningCardDays: counts.learning,
  reviewingCardDays: counts.reviewing,
);
