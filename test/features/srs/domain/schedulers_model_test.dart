import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

void main() {
  test('schedulerFor returns the matching implementation', () {
    expect(schedulerFor(SchedulerType.eightBox), same(eightBoxScheduler));
    expect(schedulerFor(SchedulerType.sm2), same(sm2Scheduler));
  });
}
