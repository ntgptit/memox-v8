import 'package:memox/features/progress/domain/models/progress_days_model.dart';

/// Noon on 25 September 2026 in Hanoi (UTC+7): the day the progress tests
/// call today. Apart from progress_fixtures.dart so that the tests that read
/// no database do not depend on it: diff-based test selection follows imports
/// (build_verification_plan.py).
final noonInHanoi = ProgressDays.of(
  DateTime.utc(2026, 9, 25, 5),
  const Duration(hours: 7),
);
