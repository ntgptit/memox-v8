import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A card's review history (UC-CARD-002, kit 10): newest first, grouped by
/// cycle (BR-CARD-017), with older pages on request and a line where it
/// begins (rulings P4b-L3, P4b-L6).
class CardHistorySectionWidget extends ConsumerWidget {
  const CardHistorySectionWidget({
    super.key,
    required this.cardId,
    required this.addedAt,
  });

  final String cardId;

  /// When the card was made: the end-of-history line names it.
  final DateTime addedAt;

  static const int _skeletonRows = 3;

  void _loadMore(WidgetRef ref) => unawaited(
    ref.read(cardHistoryControllerProvider(cardId).notifier).loadMore(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardHistoryControllerProvider(cardId);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _history(context, value, () => _loadMore(ref)),
      ),
      AsyncError() => MxErrorState(
        title: l10n.cardHistoryLoadErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => Column(
        children: [
          for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      ),
    };
  }

  List<Widget> _history(
    BuildContext context,
    CardHistoryView view,
    VoidCallback onLoadMore,
  ) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final entries = view.entries;
    if (entries.isEmpty) {
      return [
        MxListSectionHeader(label: l10n.cardHistory),
        MxEmptyState(
          icon: AppIcons.history,
          title: l10n.cardHistoryEmptyTitle,
          body: l10n.cardHistoryEmptyBody,
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
        ),
      ];
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return [
      MxListSectionHeader(label: l10n.cardHistoryNewestFirst),
      for (final (index, entry) in entries.indexed) ...[
        if (index == 0 || entries[index - 1].generation != entry.generation)
          _CycleHeader(
            label: l10n.cardHistoryCycle(
              entry.generation,
              l10n.cardScheduler(entry.schedulerType),
            ),
          ),
        CardHistoryEventWidget(entry: entry),
      ],
      if (view.hasMoreFailed)
        MxInlineBanner(
          tone: MxBannerTone.danger,
          title: l10n.cardHistoryLoadMoreFailedTitle,
          message: l10n.cardHistoryLoadMoreFailedBody,
          actions: [
            MxButton(
              label: l10n.commonRetry,
              size: MxButtonSize.compact,
              onPressed: onLoadMore,
            ),
          ],
        )
      else if (view.next != null)
        MxButton(
          label: l10n.cardHistoryLoadMore,
          tone: MxButtonTone.secondary,
          isBlock: true,
          isLoading: view.isLoadingMore,
          onPressed: onLoadMore,
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.control),
          child: Text(
            l10n.cardHistoryEnd(
              DateFormat.yMMMd(locale).format(addedAt.toLocal()),
            ),
            textAlign: TextAlign.center,
            style: styles.noteText,
          ),
        ),
    ];
  }
}

/// "Cycle n · scheduler" over one generation's answers (ruling P4b-L4).
class _CycleHeader extends StatelessWidget {
  const _CycleHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.micro,
      AppSpacing.control,
      AppSpacing.micro,
      AppSpacing.control,
    ),
    child: Text(
      label.toUpperCase(),
      semanticsLabel: label,
      style: context.textStyles.overline,
    ),
  );
}
