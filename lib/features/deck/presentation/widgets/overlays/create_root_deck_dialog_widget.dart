import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_discard_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Opens the new-deck dialog (UC-DECK-001). It completes with the created
/// deck, or with null when the person cancels.
Future<DeckEntity?> showCreateRootDeckDialog(BuildContext context) =>
    showMxDialog<DeckEntity>(
      context,
      builder: (_) => const CreateRootDeckDialogWidget(),
    );

/// A root deck's name and the scheduler its cards will follow. The scheduler
/// locks after the first review, so the choice is explained up front and
/// never made for the person (BR-SRS-001, E3). Leaving after typing asks
/// first (A1).
class CreateRootDeckDialogWidget extends ConsumerStatefulWidget {
  const CreateRootDeckDialogWidget({super.key});

  @override
  ConsumerState<CreateRootDeckDialogWidget> createState() =>
      _CreateRootDeckDialogWidgetState();
}

class _CreateRootDeckDialogWidgetState
    extends ConsumerState<CreateRootDeckDialogWidget> {
  final _name = TextEditingController();
  SchedulerType? _scheduler;
  DeckRejection? _rejection;

  /// The last create's failure, shown above the field until the next try
  /// (SP2b 2.27).
  Failure? _failure;

  /// Create was pressed with no scheduler chosen (E3).
  var _isSchedulerMissing = false;

  /// One create at a time: a second tap while the first runs does nothing.
  var _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Something typed or chosen would be lost by leaving (A1).
  bool get _isStarted => _name.text.isNotEmpty || _scheduler != null;

  /// Cancel, Back or a tap outside: asks first once the form is started.
  Future<void> _leave() async {
    // Never over a write: its result must reach the screen (SP2b 2.26).
    if (_isSubmitting) return;
    if (_isStarted && !await showDeckDiscardDialog(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final scheduler = _scheduler;
    if (scheduler == null) {
      setState(() => _isSchedulerMissing = true);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _rejection = null;
      _failure = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .createRootDeck(name: _name.text, schedulerType: scheduler);
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
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck create');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    final dialog = MxDialog(
      isHeld: _isSubmitting,
      title: l10n.deckCreateRootTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          if (failure != null)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              message: l10n.failure(failure),
            ),
          MxTextField(
            controller: _name,
            label: l10n.deckNameHint,
            hintText: l10n.deckNameHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.deckRejection(reason),
            },
            textInputAction: TextInputAction.done,
            onSubmitted: _isSubmitting ? null : (_) => _submit(),
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
            onSelected: (type) => setState(() {
              _scheduler = type;
              _isSchedulerMissing = false;
            }),
          ),
          if (_isSchedulerMissing)
            MxFieldMessage(message: l10n.deckSchedulerRequired),
          MxNote(text: l10n.deckSchedulerNote),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isSubmitting ? null : () => unawaited(_leave()),
        confirmLabel: l10n.deckCreateConfirm,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: dialog,
    );
  }
}
