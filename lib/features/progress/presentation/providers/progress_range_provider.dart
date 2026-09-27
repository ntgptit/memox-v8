import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_range_provider.g.dart';

/// The range the Progress tab shows, one choice for every level: a deck
/// opened from Last 30 days opens at Last 30 days, and Back keeps it
/// (FE-A9 D4). Switching reads nothing (BR-PROGRESS-003).
@riverpod
class ProgressRangeChoice extends _$ProgressRangeChoice {
  @override
  ProgressRange build() => ProgressRange.week;

  void choose(ProgressRange range) => state = range;
}
