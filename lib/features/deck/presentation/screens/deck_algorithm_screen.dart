import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_switch_algorithm_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_algorithm_options_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_lock_strip_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_start_over_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 02: a root deck's review algorithm, and the reset that opens a
/// new cycle (spec §4.2; UC-DECK-002, UC-SRS-001). A sub-deck has none
/// (BR-DECK-025) and reads as gone, like a deleted deck (ruling D-L3).
class DeckAlgorithmScreen extends ConsumerStatefulWidget {
  const DeckAlgorithmScreen({
    super.key,
    required this.deckId,
    required this.onOpenAncestor,
  });

  final String deckId;

  /// A breadcrumb tap: the root, or null for the Library.
  final ValueChanged<String?> onOpenAncestor;

  @override
  ConsumerState<DeckAlgorithmScreen> createState() =>
      _DeckAlgorithmScreenState();
}

class _DeckAlgorithmScreenState extends ConsumerState<DeckAlgorithmScreen> {
  static const int _skeletonRows = 4;

  /// The algorithm a running switch moves to.
  SchedulerType? _switchingTo;

  /// Set when a switch failed (UC-DECK-002 E2, ruling D-L2): the algorithm
  /// the deck kept, and the one Retry tries again.
  SchedulerType? _switchFailedFrom;
  SchedulerType? _retryTarget;

  Future<void> _onSelected(DeckView view, SchedulerType type) async {
    // UC-DECK-002 A4: the current algorithm changes nothing.
    if (type == view.schedulerType) return;
    final isConfirmed = await showSwitchAlgorithmDialog(
      context,
      algorithm: context.l10n.schedulerType(type),
    );
    if (!isConfirmed || !mounted) return;
    await _switchTo(view, type);
  }

  Future<void> _switchTo(DeckView view, SchedulerType type) async {
    setState(() {
      _switchingTo = type;
      _switchFailedFrom = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .changeScheduler(rootDeckId: view.deck.id, schedulerType: type);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.algorithmSwitchedToast(l10n.schedulerType(type)),
          // Ruling D-L1: a tree that just locked, or a deck gone meanwhile.
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      setState(() => _switchingTo = null);
    } on Failure {
      if (!mounted) return;
      setState(() {
        _switchingTo = null;
        _switchFailedFrom = view.schedulerType;
        _retryTarget = type;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = deckViewProvider(widget.deckId);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.deckReviewAlgorithm,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(provider)) {
        AsyncData(value: Ok(:final value)) when value.deck.isRoot => _content(
          value,
        ),
        AsyncData() => DeckGoneStateWidget(
          onBackToLibrary: () => widget.onOpenAncestor(null),
        ),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.deckLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: context.l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      },
    );
  }

  Widget _content(DeckView view) {
    final l10n = context.l10n;
    final isLocked = view.isSchedulerLocked;
    final failedFrom = _switchFailedFrom;
    final retryTarget = _retryTarget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxBreadcrumb(
          segments: [
            MxBreadcrumbSegment(
              label: l10n.navLibrary,
              onTap: () => widget.onOpenAncestor(null),
            ),
            MxBreadcrumbSegment(
              label: view.deck.name,
              onTap: () => widget.onOpenAncestor(view.deck.id),
            ),
            MxBreadcrumbSegment(label: l10n.deckReviewAlgorithm),
          ],
        ),
        Expanded(
          child: MxScreenScroll(
            children: [
              const SizedBox(height: AppSpacing.micro),
              DeckLockStripWidget(view: view),
              if (failedFrom != null && retryTarget != null) ...[
                const SizedBox(height: AppSpacing.grouped),
                MxInlineBanner(
                  tone: MxBannerTone.danger,
                  title: l10n.algorithmSwitchFailedTitle,
                  message: l10n.algorithmSwitchFailedBody(
                    l10n.schedulerType(failedFrom),
                  ),
                  actions: [
                    MxButton(
                      label: l10n.commonRetry,
                      size: MxButtonSize.compact,
                      onPressed: () => unawaited(_switchTo(view, retryTarget)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.grouped),
              MxListSectionHeader(label: l10n.algorithmHeader),
              DeckAlgorithmOptionsWidget(
                current: view.schedulerType,
                isLocked: isLocked,
                switchingTo: _switchingTo,
                onSelected: (type) => unawaited(_onSelected(view, type)),
              ),
              const SizedBox(height: AppSpacing.grouped),
              MxNote(
                text: isLocked
                    ? l10n.algorithmLockedNote
                    : l10n.algorithmSwitchNote,
                icon: isLocked ? AppIcons.lock : AppIcons.info,
              ),
              const SizedBox(height: AppSpacing.grouped),
              MxListSectionHeader(label: l10n.algorithmStartOverHeader),
              DeckStartOverWidget(
                onReset: () =>
                    unawaited(showResetLearningDialog(context, view: view)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
