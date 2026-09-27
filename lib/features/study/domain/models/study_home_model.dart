import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study tab (UC-STUDY-002; Study Home spec §5): the session Resume takes
/// up, and the library's root decks with their workload, read as one
/// snapshot.
final class StudyHome {
  const StudyHome({required this.resumable, required this.content});

  /// The session the Resume card offers (BR-STUDY-075); null when no open
  /// session may be taken up (A1, A2).
  final ResumableSession? resumable;

  final StudyHomeContent content;
}

/// The open session the Resume card offers (BR-STUDY-075).
final class ResumableSession {
  const ResumableSession({
    required this.sessionId,
    required this.deckName,
    required this.kind,
    required this.mode,
    required this.progress,
  });

  final String sessionId;

  /// The deck the session was opened on: a sub-deck or a root.
  final String deckName;

  /// Both read from the session row, never inferred (BR-SRS-015,
  /// BR-MODE-008).
  final SessionKind kind;
  final StudyMode mode;

  /// The round the session serves, counted as the session screen counts it
  /// (spec D3); null while it serves nothing.
  final RoundProgress? progress;
}

/// The three loaded states of the Study tab (BR-STUDY-077).
sealed class StudyHomeContent {
  const StudyHomeContent();
}

/// No root deck: the way forward is the Starter Library.
final class NoRootDecks extends StudyHomeContent {
  const NoRootDecks();
}

/// Root decks, none with a card: the way forward is Library, and no number
/// is shown.
final class NoCards extends StudyHomeContent {
  const NoCards();
}

/// Every root deck with its workload, in the order of BR-STUDY-076, even when
/// no deck has any: the schedule is running (BR-STUDY-008).
final class RootDeckWorkload extends StudyHomeContent {
  const RootDeckWorkload({required this.decks, required this.nextDueAt});

  final List<StudyHomeDeck> decks;

  /// The earliest due date after now of a learned card, the day the caught-up
  /// state names (spec D4); null when no learned card waits.
  final DateTime? nextDueAt;

  int get overdueCount => _sum((deck) => deck.overdueCount);

  int get dueTodayCount => _sum((deck) => deck.dueTodayCount);

  int get newCount => _sum((deck) => deck.newCount);

  /// Overdue and Due today together (BR-STUDY-068).
  int get dueCount => overdueCount + dueTodayCount;

  /// Learned cards resting until they fall due: the total less New and Due,
  /// from the same snapshot (BR-STUDY-068). Never a headline.
  int get scheduledCount => _sum((deck) => deck.scheduledCount);

  /// The decks with any workload: "across K decks".
  int get workloadDeckCount => decks.where((deck) => deck.hasWorkload).length;

  /// No deck has any workload (A3, BR-STUDY-008).
  bool get isCaughtUp => workloadDeckCount == 0;

  int _sum(int Function(StudyHomeDeck deck) count) =>
      decks.fold(0, (total, deck) => total + count(deck));
}

/// A root deck of the Study tab with the workload of its whole tree
/// (BR-STUDY-076).
final class StudyHomeDeck {
  const StudyHomeDeck({
    required this.deckId,
    required this.name,
    required this.schedulerType,
    required this.cardCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.newCount,
  });

  final String deckId;
  final String name;
  final SchedulerType schedulerType;
  final int cardCount;
  final int overdueCount;
  final int dueTodayCount;
  final int newCount;

  bool get hasWorkload => overdueCount + dueTodayCount + newCount > 0;

  /// Its cards resting until they fall due (BR-STUDY-068), never below 0.
  int get scheduledCount {
    final resting = cardCount - newCount - overdueCount - dueTodayCount;
    return resting < 0 ? 0 : resting;
  }

  /// A deck with no card gets no open action (BR-STUDY-076).
  bool get canStudy => cardCount > 0;
}

/// The loaded state [decks] make (BR-STUDY-077), with the decks in the order
/// of BR-STUDY-076.
StudyHomeContent studyHomeContentOf(
  List<StudyHomeDeck> decks, {
  required DateTime? nextDueAt,
}) {
  if (decks.isEmpty) return const NoRootDecks();
  if (!decks.any((deck) => deck.canStudy)) return const NoCards();
  return RootDeckWorkload(
    decks: [...decks]..sort(compareStudyHomeDecks),
    nextDueAt: nextDueAt,
  );
}

/// BR-STUDY-076: Overdue, then Due today, then New, each descending and never
/// their total; then the Unicode-folded name (`foldText`, as tags sort,
/// BR-TAG-001), then the id.
int compareStudyHomeDecks(StudyHomeDeck a, StudyHomeDeck b) {
  final overdue = b.overdueCount.compareTo(a.overdueCount);
  if (overdue != 0) return overdue;
  final dueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
  if (dueToday != 0) return dueToday;
  final fresh = b.newCount.compareTo(a.newCount);
  if (fresh != 0) return fresh;
  final name = foldText(a.name).compareTo(foldText(b.name));
  if (name != 0) return name;
  return a.deckId.compareTo(b.deckId);
}
