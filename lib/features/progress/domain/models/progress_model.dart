import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// `/progress` (UC-PROGRESS-001, and UC-PROGRESS-002 at the library level):
/// the overview and a row per root deck, read as one snapshot (Progress
/// spec §5.2).
final class Progress {
  const Progress({
    required this.overview,
    required this.level,
    required this.validUntil,
  });

  final ProgressOverview overview;
  final ProgressLevel level;

  /// The next local midnight: every number changes there with no write
  /// (BR-PROGRESS-003).
  final DateTime validUntil;
}
