import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_preview_digest_provider.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart' show libraryToday;

// Screen 24's live preview (critique 2026-09-30 part 1, spec §5.5).

final class _Workloads implements ReminderWorkloadRepository {
  _Workloads(this.result);

  final Future<List<ReminderDeckWorkload>> Function() result;

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) => result();
}

ProviderContainer _container(_Workloads workloads) {
  final container = ProviderContainer(
    overrides: [
      dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      reminderWorkloadRepositoryProvider.overrideWithValue(workloads),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('the most urgent root, its count and the others', () async {
    final container = _container(
      _Workloads(
        () async => const [
          ReminderDeckWorkload(
            deckId: 'a',
            name: 'Korean',
            overdueCount: 3,
            overdueDays: 2,
            dueTodayCount: 1,
          ),
          ReminderDeckWorkload(
            deckId: 'b',
            name: 'English',
            overdueCount: 0,
            overdueDays: 0,
            dueTodayCount: 2,
          ),
        ],
      ),
    );
    final digest = await container.read(reminderPreviewDigestProvider.future);
    expect(
      (digest!.deckName, digest.dueCount, digest.otherDeckCount),
      ('Korean', 4, 1),
    );
  });

  test('nothing due is null', () async {
    final container = _container(_Workloads(() async => const []));
    expect(await container.read(reminderPreviewDigestProvider.future), isNull);
  });

  test('a failed read is an error', () async {
    final container = _container(
      _Workloads(() async => throw StateError('db')),
    );
    await expectLater(
      container.read(reminderPreviewDigestProvider.future),
      throwsStateError,
    );
  });
}
