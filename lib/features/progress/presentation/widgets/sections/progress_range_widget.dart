import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// The range tray, Last 7 days or Last 30 days (BR-PROGRESS-003): the tab's
/// one choice (FE-A9 D4). Switching reads nothing.
class ProgressRangeWidget extends ConsumerWidget {
  const ProgressRangeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MxSegmentedTray<ProgressRange>(
        segments: [
          MxSegment(value: ProgressRange.week, label: l10n.progressRangeWeek),
          MxSegment(value: ProgressRange.month, label: l10n.progressRangeMonth),
        ],
        selected: ref.watch(progressRangeChoiceProvider),
        onSelected: (range) => _choose(ref, range),
        isWide: true,
      ),
    );
  }

  void _choose(WidgetRef ref, ProgressRange range) =>
      ref.read(progressRangeChoiceProvider.notifier).choose(range);
}
