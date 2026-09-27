import 'library_harness.dart';
import 'progress_fixtures.dart';
import 'deck_fixtures.dart';

/// One day of a deck's history: [daysAgo] before [libraryToday], with
/// [learning] cards answered while being learned and [reviewing] cards
/// answered in review, each card once (a card-day, BR-PROGRESS-011).
typedef StudyDay = ({int daysAgo, int learning, int reviewing});

/// A root deck named [name] with one "Words" sub-deck, whose cards were
/// answered on [days]; returns the root's id.
Future<String> studiedDeck(
  LibraryEnv env,
  String name, {
  List<StudyDay> days = const [],
}) async {
  final root = await env.decks.root(name);
  final words = await env.decks.sub(root.id, 'Words');
  final most = days.fold(
    0,
    (most, day) => day.learning + day.reviewing > most
        ? day.learning + day.reviewing
        : most,
  );
  for (var i = 0; i < most; i++) {
    await learnedCard(env.db, words.id, '${root.id}-$i');
  }
  if (most > 0) await lockScheduler(env.db, root.id);
  for (final day in days) {
    // Early morning of that day, before the harness's 9:00.
    final at = DateTime(
      libraryToday.year,
      libraryToday.month,
      libraryToday.day - day.daysAgo,
      8,
    );
    for (var i = 0; i < day.learning + day.reviewing; i++) {
      await answer(
        env.db,
        '${root.id}-$i',
        at,
        kind: i < day.learning ? 'learning' : 'scheduled',
      );
    }
  }
  return root.id;
}

/// Kit 22's library, with Latin and Vietnamese names (goldens render no
/// Hangul): a week of study ending today, an idle deck, and a deck last
/// studied three weeks ago. [today] false drops today's answers (the held
/// streak); [lastDaysAgo] moves every answer that many days further back
/// (the lost streak).
Future<void> progressLibrary(
  LibraryEnv env, {
  bool today = true,
  int lastDaysAgo = 0,
}) async {
  List<StudyDay> shifted(List<StudyDay> days) => [
    for (final day in days)
      if (today || day.daysAgo > 0 || lastDaysAgo > 0)
        (
          daysAgo: day.daysAgo + lastDaysAgo,
          learning: day.learning,
          reviewing: day.reviewing,
        ),
  ];
  await studiedDeck(
    env,
    'Tiếng Hàn TOPIK I · Từ vựng',
    days: shifted([
      (daysAgo: 6, learning: 3, reviewing: 5),
      (daysAgo: 5, learning: 0, reviewing: 12),
      (daysAgo: 3, learning: 4, reviewing: 9),
      (daysAgo: 2, learning: 1, reviewing: 8),
      (daysAgo: 1, learning: 0, reviewing: 6),
      (daysAgo: 0, learning: 4, reviewing: 8),
    ]),
  );
  await studiedDeck(
    env,
    'IELTS Academic Word List',
    days: shifted([
      (daysAgo: 6, learning: 1, reviewing: 3),
      (daysAgo: 5, learning: 0, reviewing: 6),
      (daysAgo: 3, learning: 2, reviewing: 7),
      (daysAgo: 0, learning: 1, reviewing: 4),
    ]),
  );
  await studiedDeck(
    env,
    'Tiếng Anh giao tiếp hằng ngày',
    days: shifted([(daysAgo: 2, learning: 0, reviewing: 4)]),
  );
  await studiedDeck(env, 'IT');
  await studiedDeck(
    env,
    'Korean Basics',
    days: shifted([(daysAgo: 20, learning: 0, reviewing: 10)]),
  );
}
