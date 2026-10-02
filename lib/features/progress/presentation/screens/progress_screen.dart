import 'package:flutter/material.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_skeleton_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/core/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_level_list_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 22, the Progress tab (UC-PROGRESS-001, UC-PROGRESS-002 at the
/// library level): Today with the last seven days, the streak, the range,
/// and a row per root deck, read as one snapshot. It writes nothing
/// (BR-PROGRESS-009). Where a row and "Start studying" lead, `app/` decides.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({
    super.key,
    required this.onOpenDeck,
    required this.onStartStudying,
  });

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onStartStudying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Once shown, a new snapshot only replaces the numbers (FE-A9 D8).
    final children = switch (ref.watch(progressProvider)) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          // A local read failed, not the network (critique 2026-09-30).
          icon: AppIcons.alert,
          title: l10n.progressErrorTitle,
          // The reason by the kind of failure, never its cause
          // (UC-PROGRESS-001 E1, BR-CORE-005).
          body: error is Failure ? l10n.failure(error) : l10n.progressErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(progressProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) => _loaded(context, value),
      _ => [ProgressSkeletonWidget(semanticLabel: l10n.progressLoading)],
    };
    return MxAppShell(
      appBar: MxAppBar(title: l10n.progressTitle),
      body: MxScreenScroll(children: children),
    );
  }

  List<Widget> _loaded(BuildContext context, Progress progress) {
    final l10n = context.l10n;
    // No deck, no range to show (UC-PROGRESS-002 A2).
    if (!progress.level.hasDecks) {
      return [
        MxEmptyState(
          icon: AppIcons.progress,
          title: l10n.progressNoDecksTitle,
          body: l10n.progressNoDecksBody,
          tone: MxEmptyStateTone.neutral,
        ),
      ];
    }
    return [
      ProgressTodayWidget(
        overview: progress.overview,
        onStartStudying: onStartStudying,
      ),
      const SizedBox(height: AppSpacing.gutter),
      ProgressStreakWidget(overview: progress.overview),
      // Never studied, every row would read 0: the list waits for the first
      // study day (critique 2026-09-30).
      if (progress.overview.streak.state != StreakState.never) ...[
        const SizedBox(height: AppSpacing.gutter),
        // Above the list it changes; Today and Streak never do (FE-A9 D10).
        const ProgressRangeWidget(),
        const SizedBox(height: AppSpacing.gutter),
        ProgressLevelListWidget(
          level: progress.level,
          isDeckLevel: false,
          onOpenDeck: onOpenDeck,
        ),
      ],
    ];
  }
}
