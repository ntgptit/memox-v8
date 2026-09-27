import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';
import 'package:memox/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart';
import 'package:memox/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart';

const _entry = StarterLibraryEntry(
  templateId: 'fixture.test',
  version: 1,
  title: 'Everyday',
  locale: 'en',
  frontLanguage: 'en',
  backLanguage: 'vi',
  contentSource: 'Development fixture',
  suggestedScheduler: SchedulerType.eightBox,
  cardCount: 3,
  subDeckCount: 2,
  isInLibrary: false,
);

const _added = AddedStarterDeck(
  rootDeckId: 'root',
  title: 'Everyday',
  schedulerType: SchedulerType.sm2,
  cardCount: 3,
);

/// A library that records what it is asked and answers [_entry] and [_added].
final class _Library implements StarterLibraryRepository {
  final adds = <(String, SchedulerType, bool)>[];

  @override
  Stream<List<StarterLibraryEntry>> watchLibrary() => Stream.value([_entry]);

  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async {
    adds.add((templateId, schedulerType, allowSecondCopy));
    return const Ok(_added);
  }
}

void main() {
  test('WatchStarterLibraryUseCase hands on the library as the repository '
      'reads it (UC-STARTER-001 step 5)', () async {
    expect(await WatchStarterLibraryUseCase(_Library()).call().first, [_entry]);
  });

  test('AddStarterDeckUseCase adds with the chosen scheduler and asks for a '
      'second copy only when told to (UC-STARTER-001 A2)', () async {
    final library = _Library();
    final add = AddStarterDeckUseCase(library);

    final first = await add(
      templateId: 'fixture.test',
      schedulerType: SchedulerType.sm2,
    );
    await add(
      templateId: 'fixture.test',
      schedulerType: SchedulerType.eightBox,
      allowSecondCopy: true,
    );

    expect((first as Ok<AddedStarterDeck, StarterRejection>).value, _added);
    expect(library.adds, [
      ('fixture.test', SchedulerType.sm2, false),
      ('fixture.test', SchedulerType.eightBox, true),
    ]);
  });
}
