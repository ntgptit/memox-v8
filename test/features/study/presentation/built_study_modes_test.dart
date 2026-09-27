import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/widgets/support/built_study_modes_widget.dart';

void main() {
  test('P1 offers neither Learn nor Review on either algorithm (spec §3)', () {
    for (final type in SchedulerType.values) {
      expect(isLearningBuilt(type), isFalse, reason: '$type');
      expect(isReviewBuilt(type), isFalse, reason: '$type');
    }
  });
}
