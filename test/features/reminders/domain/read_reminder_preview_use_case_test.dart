import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/reminders/domain/usecases/read_reminder_preview_use_case.dart';

import '../../../support/fake_day_clock.dart';

// Screen 24's live preview: what the notification would say now (critique
// 2026-09-30 part 1; one use case per interaction, ADR-011 D4/D5).

final class _Workloads implements ReminderWorkloadRepository {
  DateTime? now;
  DateTime? startOfToday;
  List<ReminderDeckWorkload> result = const [];

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    this.now = now;
    this.startOfToday = startOfToday;
    return result;
  }
}

void main() {
  test('reads the workload at the clock\'s now, split at local midnight, '
      'and digests it', () async {
    final workloads = _Workloads()
      ..result = const [
        ReminderDeckWorkload(
          deckId: 'a',
          name: 'Korean',
          overdueCount: 1,
          overdueDays: 1,
          dueTodayCount: 2,
        ),
      ];
    final clock = FakeDayClock(DateTime(2026, 9, 30, 9, 15));

    final digest = await ReadReminderPreviewUseCase(workloads, clock)();

    expect(workloads.now, DateTime(2026, 9, 30, 9, 15));
    expect(workloads.startOfToday, DateTime(2026, 9, 30));
    expect((digest!.deckName, digest.dueCount), ('Korean', 3));
  });

  test('nothing due is null', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 30, 9));
    expect(await ReadReminderPreviewUseCase(_Workloads(), clock)(), isNull);
  });
}
