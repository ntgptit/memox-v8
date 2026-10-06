import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/controllers/starter_add_controller.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// The scheduler a copy of [entry] studies under (UC-STARTER-001 step 6;
/// kit 03 `choose`). Completes with what the add did, or null when the
/// person cancelled.
Future<StarterAddResult?> showStarterAlgorithmSheet(
  BuildContext context, {
  required StarterLibraryEntry entry,
  required bool isSecondCopy,
}) => showMxBottomSheet<StarterAddResult>(
  context,
  builder: (_) =>
      StarterAlgorithmSheetWidget(entry: entry, isSecondCopy: isSecondCopy),
);

/// The two schedulers, the suggested one first chosen (BR-STARTER-004).
/// While the add runs nothing else can be touched (`adding`); a failure
/// keeps the sheet and the choice, and says so (`addFailed`).
class StarterAlgorithmSheetWidget extends ConsumerStatefulWidget {
  const StarterAlgorithmSheetWidget({
    super.key,
    required this.entry,
    required this.isSecondCopy,
  });

  final StarterLibraryEntry entry;

  /// The person confirmed a second copy (BR-STARTER-008).
  final bool isSecondCopy;

  @override
  ConsumerState<StarterAlgorithmSheetWidget> createState() =>
      _StarterAlgorithmSheetWidgetState();
}

class _StarterAlgorithmSheetWidgetState
    extends ConsumerState<StarterAlgorithmSheetWidget> {
  late var _scheduler = widget.entry.suggestedScheduler;

  Future<void> _add() async {
    final result = await ref
        .read(starterAddControllerProvider.notifier)
        .add(
          templateId: widget.entry.templateId,
          schedulerType: _scheduler,
          allowSecondCopy: widget.isSecondCopy,
        );
    if (result == null || !mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final state = ref.watch(starterAddControllerProvider);
    final isAdding = state.isAdding;
    const schedulers = [SchedulerType.sm2, SchedulerType.eightBox];
    return MxBottomSheet(
      isHeld: isAdding,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.control,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(
              l10n.starterSheetTitle(widget.entry.title),
              style: styles.compactTitle,
            ),
            // The lock, before the choice (BR-SRS-003; critique 2026-09-30
            // part 3d-2, E6). The card above states the counts.
            Text(l10n.deckSchedulerNote, style: styles.footerCaption),
            const SizedBox(height: AppSpacing.control),
            // A field label and its Required caption (critique 2026-09-30
            // part 2, P3).
            Wrap(
              spacing: AppSpacing.micro,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.starterSheetAlgorithmLabel, style: styles.fieldLabel),
                Text(l10n.starterSheetRequired, style: styles.requiredMarker),
              ],
            ),
          ],
        ),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: isAdding ? null : () => Navigator.of(context).pop(),
        confirmLabel: state.hasFailed
            ? l10n.starterTryAgain
            : l10n.starterAddDeck,
        isConfirmLoading: isAdding,
        onConfirm: () => unawaited(_add()),
      ),
      child: Column(
        children: [
          for (final (index, scheduler) in schedulers.indexed)
            MxOptionRow(
              title: starterSchedulerName(l10n, scheduler),
              description: _description(scheduler),
              isSelected: scheduler == _scheduler,
              onSelected: isAdding
                  ? null
                  : () => setState(() => _scheduler = scheduler),
              hasDivider: index < schedulers.length - 1,
            ),
          if (state.hasFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.control,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                title: l10n.starterAddFailedTitle,
                message: l10n.starterAddFailedBody,
              ),
            ),
        ],
      ),
    );
  }

  String _description(SchedulerType scheduler) {
    final l10n = context.l10n;
    final description = starterSchedulerDescription(l10n, scheduler);
    if (scheduler != widget.entry.suggestedScheduler) return description;
    return l10n.starterSuggested(description);
  }
}
