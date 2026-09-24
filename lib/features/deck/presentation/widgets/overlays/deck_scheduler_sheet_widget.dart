import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// A root deck's scheduler (UC-DECK-002, spec §6.2).
Future<void> showDeckSchedulerSheet(
  BuildContext context, {
  required DeckView view,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => DeckSchedulerSheetWidget(view: view),
);

/// While unlocked, a warning says what a change resets (BR-STUDY-016). Once
/// locked, a note explains why and no option can be chosen. Reset learning
/// is out of scope.
class DeckSchedulerSheetWidget extends ConsumerStatefulWidget {
  const DeckSchedulerSheetWidget({super.key, required this.view});

  final DeckView view;

  @override
  ConsumerState<DeckSchedulerSheetWidget> createState() =>
      _DeckSchedulerSheetWidgetState();
}

class _DeckSchedulerSheetWidgetState
    extends ConsumerState<DeckSchedulerSheetWidget> {
  var _isSaving = false;

  Future<void> _choose(SchedulerType type) async {
    if (type == widget.view.schedulerType) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .changeScheduler(
            rootDeckId: widget.view.deck.id,
            schedulerType: type,
          );
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.deckSchedulerChangedToast,
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final isLocked = view.isSchedulerLocked;
    const types = SchedulerType.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.deckSchedulerTitle,
          style: context.textStyles.compactTitle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              0,
              AppSpacing.card,
              AppSpacing.grouped,
            ),
            child: isLocked
                ? MxNote(text: l10n.deckSchedulerLockedNote)
                : MxInlineBanner(
                    tone: MxBannerTone.warning,
                    message: l10n.deckSchedulerChangeWarning,
                  ),
          ),
          for (final (index, type) in types.indexed)
            MxOptionRow(
              title: l10n.schedulerType(type),
              isSelected: type == view.schedulerType,
              onSelected: isLocked || _isSaving
                  ? null
                  : () => unawaited(_choose(type)),
              hasDivider: index < types.length - 1,
            ),
        ],
      ),
    );
  }
}
