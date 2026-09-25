import 'package:memox/core/text/folded_text.dart';

/// The two ranges of Progress by deck: whole local days that end today
/// (BR-PROGRESS-003).
enum ProgressRange {
  week(7),
  month(30);

  const ProgressRange(this.days);

  /// The local days the range holds, today included.
  final int days;
}

/// The four numbers of one scope over one range, and no other
/// (BR-PROGRESS-001).
final class ProgressNumbers {
  const ProgressNumbers({
    required this.activeCards,
    required this.activeDays,
    required this.learningCardDays,
    required this.reviewingCardDays,
  });

  /// Distinct cards with an answer in the range (BR-PROGRESS-002).
  final int activeCards;

  /// Distinct local days with an answer in the range; never a sum over decks
  /// (BR-PROGRESS-002).
  final int activeDays;

  /// Card-days with a `learning` answer, and all the others: one partition
  /// (BR-PROGRESS-005).
  final int learningCardDays;
  final int reviewingCardDays;

  int get cardDays => learningCardDays + reviewingCardDays;

  bool get hasActivity => activeCards > 0;
}

/// A scope's numbers for both ranges, from one read (BR-PROGRESS-003).
final class RangeProgress {
  const RangeProgress({required this.week, required this.month});

  final ProgressNumbers week;
  final ProgressNumbers month;

  ProgressNumbers of(ProgressRange range) => switch (range) {
    ProgressRange.week => week,
    ProgressRange.month => month,
  };
}

/// A deck of a level with the numbers of its whole subtree
/// (BR-PROGRESS-004).
final class ProgressDeckRow {
  const ProgressDeckRow({
    required this.deckId,
    required this.name,
    required this.progress,
  });

  final String deckId;
  final String name;
  final RangeProgress progress;
}

/// One level of Progress by deck (UC-PROGRESS-002): the numbers of the whole
/// scope and a row per deck in it, every deck included, active or not.
final class ProgressLevel {
  ProgressLevel({required this.total, required List<ProgressDeckRow> decks})
    : _weekDecks = _sorted(decks, ProgressRange.week),
      _monthDecks = _sorted(decks, ProgressRange.month);

  /// Read from the statement that reads the rows, never added up from them
  /// (BR-PROGRESS-002).
  final RangeProgress total;

  final List<ProgressDeckRow> _weekDecks;
  final List<ProgressDeckRow> _monthDecks;

  /// The rows in the order of [range] (BR-PROGRESS-006), sorted once when the
  /// level is built, so switching the range costs nothing (BR-PROGRESS-003).
  List<ProgressDeckRow> decksFor(ProgressRange range) => switch (range) {
    ProgressRange.week => _weekDecks,
    ProgressRange.month => _monthDecks,
  };

  bool get hasDecks => _weekDecks.isNotEmpty;

  static List<ProgressDeckRow> _sorted(
    List<ProgressDeckRow> decks,
    ProgressRange range,
  ) {
    final sorted = [...decks]..sort(compareProgressDecks(range));
    return List.unmodifiable(sorted);
  }
}

/// BR-PROGRESS-006: active cards of [range] descending; then the name folded
/// in Dart (`foldText`, never SQL's `lower()`); then the id. A deck with no
/// activity has 0, the least, so it sorts after every active one and stays.
Comparator<ProgressDeckRow> compareProgressDecks(ProgressRange range) =>
    (a, b) {
      final cards = b.progress
          .of(range)
          .activeCards
          .compareTo(a.progress.of(range).activeCards);
      if (cards != 0) return cards;
      final name = foldText(a.name).compareTo(foldText(b.name));
      if (name != 0) return name;
      return a.deckId.compareTo(b.deckId);
    };
