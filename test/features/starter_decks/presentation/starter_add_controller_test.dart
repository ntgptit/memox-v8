import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/presentation/controllers/starter_add_controller.dart';
import 'package:memox/features/starter_decks/presentation/providers/starter_library_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';
import '../../../support/test_database.dart';

// FE-B4 spec D6: the add behind screen 03's algorithm sheet.

/// The root decks in the library, the Trash included.
Future<int> _roots(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM deck WHERE parent_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

void main() {
  late LibraryEnv env;
  late StarterLibraryFake library;
  late ProviderContainer container;

  setUp(() {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    library = StarterLibraryFake(env);
    container = libraryContainer(env, overrides: [library.asOverride]);
    // The sheet keeps the auto-disposed controller alive.
    container.listen(starterAddControllerProvider, (_, _) {});
  });
  tearDown(() => env.db.close());

  StarterAddController controller() =>
      container.read(starterAddControllerProvider.notifier);

  Future<StarterAddResult?> add({bool allowSecondCopy = false}) =>
      controller().add(
        templateId: hangulTemplate.templateId,
        schedulerType: SchedulerType.sm2,
        allowSecondCopy: allowSecondCopy,
      );

  test('an add copies the template and says what was added; the library '
      'marks it in library', () async {
    container.listen(starterLibraryProvider, (_, _) {});
    final result = await add();

    final added = (result! as StarterAdded).deck;
    expect(
      (added.title, added.schedulerType, added.cardCount),
      (hangulTemplate.title, SchedulerType.sm2, 60),
    );
    await pumpEventQueue();
    final entries = container.read(starterLibraryProvider).value!;
    expect(entries.map((entry) => entry.isInLibrary), [false, true]);
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });

  test('a template already in the library copies nothing '
      '(alreadyPresent)', () async {
    await add();

    expect(await add(), isA<StarterAlreadyPresent>());
    expect(await _roots(env), 1);
  });

  test('a confirmed second copy is a deck of its own (secondCopy)', () async {
    await add();

    expect(await add(allowSecondCopy: true), isA<StarterAdded>());
    expect(await _roots(env), 2);
  });

  test('a failed write keeps the sheet open and says so; the next add '
      'clears it (addFailed)', () async {
    library.failsAdds = true;

    expect(await add(), isNull);
    expect(container.read(starterAddControllerProvider).hasFailed, isTrue);
    expect(await _roots(env), 0);

    library.failsAdds = false;
    expect(await add(), isA<StarterAdded>());
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });

  test('a template gone from the build reads as a failure', () async {
    final result = await controller().add(
      templateId: 'fixture.gone',
      schedulerType: SchedulerType.sm2,
      allowSecondCopy: false,
    );

    expect(result, isNull);
    expect(container.read(starterAddControllerProvider).hasFailed, isTrue);
  });

  test('a second add while one runs is ignored (adding)', () async {
    library.hold = Completer<void>();
    final first = add();
    expect(container.read(starterAddControllerProvider).isAdding, isTrue);

    expect(await add(), isNull);
    library.hold!.complete();

    expect(await first, isA<StarterAdded>());
    expect(library.adds, 1);
    expect(container.read(starterAddControllerProvider).isAdding, isFalse);
  });

  test('a non-Failure from the add ends in hasFailed, not isAdding, and is '
      'reported; the next add works (SP2b 2.29)', () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    library.addError = StateError('bad row');

    expect(await add(), isNull);

    final state = container.read(starterAddControllerProvider);
    expect((state.hasFailed, state.isAdding), (true, false));
    expect(reported.single.exception, isA<StateError>());
    expect(reported.single.library, 'starter add');

    library.addError = null;
    expect(await add(), isA<StarterAdded>());
    expect(container.read(starterAddControllerProvider).hasFailed, isFalse);
  });
}
