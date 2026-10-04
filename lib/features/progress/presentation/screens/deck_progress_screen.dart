import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_skeleton_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/core/error/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_level_list_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 22 inside a deck (UC-PROGRESS-002 at a deck's level): the deck's
/// path, the range, the deck's total and a row per direct child, each
/// opening the next level down. A deck gone to the Trash is a value with
/// the way back, never a retry (E2). Where a row and a segment of the path
/// lead, `app/` decides.
class DeckProgressScreen extends ConsumerWidget {
  const DeckProgressScreen({
    super.key,
    required this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
  });

  final String deckId;
  final ValueChanged<String> onOpenDeck;

  /// A segment of the path: null for Progress itself, else a deck above.
  final ValueChanged<String?> onOpenAncestor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final read = ref.watch(deckProgressProvider(deckId));
    final level = switch (read) {
      AsyncError() => null,
      AsyncValue(value: final DeckProgressLevel level) => level,
      _ => null,
    };
    final Widget body = switch (read) {
      AsyncError(:final error, :final isLoading) => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.progressErrorTitle,
            // The reason by the kind of failure, never its cause
            // (UC-PROGRESS-002 E1, BR-CORE-005).
            body: error is Failure
                ? l10n.failure(error)
                : l10n.progressErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(deckProgressProvider(deckId)),
            isRetrying: isLoading,
          ),
        ],
      ),
      _ when level != null => MxScreenScroll(
        children: [
          const ProgressRangeWidget(),
          const SizedBox(height: AppSpacing.gutter),
          ProgressLevelListWidget(
            level: level.level,
            isDeckLevel: true,
            onOpenDeck: onOpenDeck,
          ),
        ],
      ),
      AsyncValue(value: ProgressDeckMissing()) => _gone(context),
      _ => MxScreenScroll(
        children: [
          const ProgressRangeWidget(),
          const SizedBox(height: AppSpacing.gutter),
          ProgressSkeletonWidget(
            semanticLabel: l10n.progressLoading,
            hasSummary: false,
          ),
        ],
      ),
    };
    final path = level?.path;
    return MxAppShell(
      appBar: MxAppBar(
        title: path == null ? l10n.progressTitle : path.last.name,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null)
            MxBreadcrumb(
              segments: [
                MxBreadcrumbSegment(
                  label: l10n.progressTitle,
                  onTap: () => onOpenAncestor(null),
                ),
                for (final segment in path)
                  MxBreadcrumbSegment(
                    label: segment.name,
                    onTap: () => onOpenAncestor(segment.deckId),
                  ),
              ],
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// The deck of the link went to the Trash or no longer exists
  /// (UC-PROGRESS-002 E2; UI-base row 129).
  Widget _gone(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.deckGoneTitle,
          body: l10n.deckGoneBody,
          actionLabel: l10n.commonBack,
          onAction: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}
