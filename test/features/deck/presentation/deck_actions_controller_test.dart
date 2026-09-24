import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> deckCount() async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
          .read<int>('n');

  test('createRootDeck hands back the new deck', () async {
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: 'Korean', schedulerType: SchedulerType.sm2);

    expect(outcome, isA<Ok<Object?, DeckRejection>>());
    expect(await deckCount(), 1);
  });

  test('a blank name is refused and nothing is written', () async {
    final before = await totalChanges(db);
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: '   ', schedulerType: SchedulerType.eightBox);

    expect(
      outcome,
      isA<Rejected<Object?, DeckRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        DeckRejection.blankName,
      ),
    );
    expect(await totalChanges(db), before);
  });
}
