import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

import 'library_harness.dart';

/// The everyday template of kit 03: English → Vietnamese, 120 cards in four
/// sub-decks, suggesting Eight boxes.
final StarterTemplate everydayTemplate = _template(
  id: 'fixture.everyday-en-vi',
  title: 'English → Vietnamese · Everyday',
  front: 'en',
  back: 'vi',
  scheduler: SchedulerType.eightBox,
  decks: ['Greetings', 'Food', 'Travel', 'Numbers'],
);

/// The Hangul template of kit 03: Korean → Romanisation, 60 cards in two
/// sub-decks, suggesting SM-2.
final StarterTemplate hangulTemplate = _template(
  id: 'fixture.hangul-basics',
  title: 'Korean → Romanisation · Hangul basics',
  front: 'ko',
  back: 'ko-Latn',
  scheduler: SchedulerType.sm2,
  decks: ['Consonants', 'Vowels'],
);

/// Thirty cards per sub-deck.
StarterTemplate _template({
  required String id,
  required String title,
  required String front,
  required String back,
  required SchedulerType scheduler,
  required List<String> decks,
}) => StarterTemplate(
  templateId: id,
  version: 1,
  locale: 'en',
  title: title,
  contentSource: 'Development fixture',
  frontLanguage: front,
  backLanguage: back,
  suggestedScheduler: scheduler,
  decks: [
    for (final name in decks)
      StarterDeck(
        name: name,
        cards: [
          for (var i = 0; i < 30; i++)
            StarterCard(front: '$name $i', back: 'b$i'),
        ],
      ),
  ],
);

/// The Starter library over [LibraryEnv]'s database, with the templates a
/// test chooses and the failures it needs.
final class StarterLibraryFake implements StarterLibraryRepository {
  StarterLibraryFake(
    LibraryEnv env, {
    List<StarterTemplate>? templates,
    bool failsLoad = false,
    Future<void>? loaded,
  }) : _library = StarterLibraryRepositoryImpl(
         env.db,
         env.decks,
         env.cards,
         templates: () async {
           // A read that never ends leaves the screen `loading`.
           await loaded;
           if (failsLoad) {
             throw UnknownDatabaseFailure(cause: StateError('load failed'));
           }
           return templates ?? [everydayTemplate, hangulTemplate];
         },
       );

  final StarterLibraryRepositoryImpl _library;

  /// The next add throws as a full disk does (`addFailed`).
  bool failsAdds = false;

  /// Holds every add until completed (`adding`).
  Completer<void>? hold;

  /// Adds that reached the store.
  int adds = 0;

  Override get asOverride =>
      starterLibraryRepositoryProvider.overrideWithValue(this);

  @override
  Stream<List<StarterLibraryEntry>> watchLibrary() => _library.watchLibrary();

  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async {
    adds++;
    await hold?.future;
    if (failsAdds) {
      throw UnknownDatabaseFailure(cause: StateError('disk full'));
    }
    return _library.addStarterDeck(
      templateId: templateId,
      schedulerType: schedulerType,
      allowSecondCopy: allowSecondCopy,
      now: now,
    );
  }
}
