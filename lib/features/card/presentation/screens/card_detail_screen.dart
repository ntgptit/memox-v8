import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_content_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_scroll_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_schedule_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A card, read-only (UC-CARD-002, spec §6.6, kit 10): content, schedule and
/// history under the deck path `app/` passes in. Editing is the explicit
/// Edit action, never the tap (BR-CARD-020).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.cardId,
    required this.deckContext,
    required this.onEdit,
  });

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// Edit for [cardId]: the router opens the editor.
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(cardDetailProvider(cardId));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.cardDetailTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (detail case AsyncData(value: Ok()))
            MxButton(
              label: l10n.cardEditAction,
              icon: AppIcons.edit,
              size: MxButtonSize.compact,
              tone: MxButtonTone.secondary,
              onPressed: () => onEdit(cardId),
            ),
        ],
      ),
      body: _DetailBody(
        cardId: cardId,
        detail: detail,
        deckContext: deckContext,
      ),
    );
  }
}

/// The page while the card loads, fails, is gone, or shows (ruling P4b-L5).
class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.cardId,
    required this.detail,
    required this.deckContext,
  });

  final String cardId;
  final AsyncValue<Outcome<CardDetail, CardRejection>> detail;
  final Widget Function(String deckId, String currentLabel) deckContext;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (detail) {
      AsyncData(value: Ok(:final value)) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          deckContext(value.card.deckId, l10n.cardDetailTitle),
          Expanded(
            child: CardHistoryScrollWidget(
              cardId: cardId,
              addedAt: value.card.createdAt,
              leading: [
                const SizedBox(height: AppSpacing.control),
                CardDetailContentWidget(detail: value),
                CardScheduleWidget(detail: value),
              ],
            ),
          ),
        ],
      ),
      AsyncData(value: Rejected()) => CardGoneWidget(
        title: l10n.cardGoneTitle,
        body: l10n.cardDetailGoneBody,
        onBack: () => unawaited(Navigator.of(context).maybePop()),
      ),
      AsyncError() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.cardLoadErrorEditTitle,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(cardDetailProvider(cardId)),
          ),
        ],
      ),
      _ => MxScreenScroll(
        children: [
          for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
        ],
      ),
    };
  }
}
