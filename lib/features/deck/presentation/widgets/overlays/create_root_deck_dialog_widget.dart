import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Opens the new-deck dialog (UC-DECK-001). It completes with the created
/// deck, or with null when the person cancels.
Future<DeckEntity?> showCreateRootDeckDialog(BuildContext context) =>
    showMxDialog<DeckEntity>(
      context,
      builder: (_) => const CreateRootDeckDialogWidget(),
    );

/// A root deck's name and the scheduler its cards will follow. The scheduler
/// locks after the first review, so the choice is explained up front.
class CreateRootDeckDialogWidget extends ConsumerStatefulWidget {
  const CreateRootDeckDialogWidget({super.key});

  @override
  ConsumerState<CreateRootDeckDialogWidget> createState() =>
      _CreateRootDeckDialogWidgetState();
}

class _CreateRootDeckDialogWidgetState
    extends ConsumerState<CreateRootDeckDialogWidget> {
  final _name = TextEditingController();
  var _scheduler = SchedulerType.eightBox;
  DeckRejection? _rejection;

  /// One create at a time: a second tap while the first runs does nothing.
  var _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _rejection = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .createRootDeck(name: _name.text, schedulerType: _scheduler);
      if (!mounted) return;
      switch (outcome) {
        case Ok(:final value):
          Navigator.of(context).pop(value);
        // Ruling L3: both reasons this use case returns are about the name.
        case Rejected(:final reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.deckCreateRootTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          MxTextField(
            controller: _name,
            hintText: l10n.deckNameHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.deckRejection(reason),
            },
            textInputAction: TextInputAction.done,
          ),
          MxSegmentedTray<SchedulerType>(
            segments: [
              MxSegment(
                value: SchedulerType.eightBox,
                label: l10n.deckSchedulerEightBox,
              ),
              MxSegment(value: SchedulerType.sm2, label: l10n.deckSchedulerSm2),
            ],
            selected: _scheduler,
            onSelected: (type) => setState(() => _scheduler = type),
          ),
          MxNote(text: l10n.deckSchedulerNote),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckCreateConfirm,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
