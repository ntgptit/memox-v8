import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

void main() {
  test('each scheduler has the stable code schema.md stores', () {
    expect(SchedulerType.eightBox.code, 'eight_box');
    expect(SchedulerType.sm2.code, 'sm2');
  });

  test('a stored code maps back to its scheduler', () {
    expect(SchedulerType.fromCode('eight_box'), SchedulerType.eightBox);
    expect(SchedulerType.fromCode('sm2'), SchedulerType.sm2);
  });

  test('an unknown code is an error, not a default', () {
    expect(() => SchedulerType.fromCode('leitner'), throwsArgumentError);
  });
}
