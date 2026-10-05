import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_rail_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The card detail's scroll, ending in the card's review history
/// (UC-CARD-002, kit 10): newest first, grouped by cycle (BR-CARD-017), with
/// older pages on request and a line where it begins (rulings P4b-L3,
/// P4b-L6). Each history row is its own child of the scroll, so a long
/// history builds only the rows in view.
class CardHistoryScrollWidget extends ConsumerWidget {
  const CardHistoryScrollWidget({
    super.key,
    required this.cardId,
    required this.addedAt,
    required this.leading,
  });

  final String cardId;

  /// When the card was made: the end-of-history line names it.
  final DateTime addedAt;

  /// The rows above the history, such as the content and the schedule.
  final List<Widget> leading;

  static const int _skeletonRows = 3;

  void _loadMore(WidgetRef ref) => unawaited(
    ref.read(cardHistoryControllerProvider(cardId).notifier).loadMore(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardHistoryControllerProvider(cardId);
    final history = switch (ref.watch(provider)) {
      AsyncData(:final value) => _history(
        context,
        value,
        ref.read(dayClockProvider).now(),
        () => _loadMore(ref),
      ),
      AsyncError(:final isLoading) => [
        MxErrorState(
          title: l10n.cardHistoryLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ],
      _ => [
        MxSkeletonList(
          semanticLabel: context.l10n.commonLoading,
          rows: _skeletonRows,
        ),
      ],
    };
    return MxScreenScroll(children: [...leading, ...history]);
  }

  List<Widget> _history(
    BuildContext context,
    CardHistoryView view,
    DateTime now,
    VoidCallback onLoadMore,
  ) {
    final l10n = context.l10n;
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
          _Marker(
            label: l10n.cardHistoryCycle(
              entry.generation,
              l10n.cardScheduler(entry.schedulerType),
            ),
            isFirst: index == 0,
          ),
        CardHistoryEventWidget(entry: entry, now: now),
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
        _Marker(
          label: l10n.cardHistoryEnd(
            DateFormat.yMMMd(locale).format(addedAt.toLocal()),
          ),
          isEnd: true,
        ),
    ];
  }
}

/// A hollow mark on the timeline's rail (DEV-170): "Cycle n · scheduler"
/// over one generation's answers (BR-CARD-017), or, at the end, where the
/// history begins. A cycle mark after an answer keeps a section's space
/// above it.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.label,
    this.isFirst = false,
    this.isEnd = false,
  });

  final String label;
  final bool isFirst;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final style = isEnd ? styles.noteText : styles.fieldLabel;
    final above = isFirst ? 0.0 : AppSpacing.grouped;
    return CardHistoryRailWidget(
      dotTop: above + CardHistoryRailWidget.dotTopOn(context, style),
      isFirst: isFirst,
      isLast: isEnd,
      gap: isEnd ? 0 : AppSpacing.control,
      child: Padding(
        padding: EdgeInsets.only(top: above),
        child: Text(label, style: style),
      ),
    );
  }
}
