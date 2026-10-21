import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_discard_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_name_field_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/support/held_run.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/core/theme/theme_context.dart';

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

  /// Create was pressed with no scheduler chosen (E3).
  var _isSchedulerMissing = false;

  /// One create at a time: a second tap while the first runs does nothing.
  var _isSubmitting = false;

  /// The confirm is offered while nothing runs and the name fits
  /// BR-DECK-020's length (owner 2026-10-21).
  bool get _canSubmit =>
      !_isSubmitting && !DeckNameFieldWidget.isTooLong(_name.text);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Something typed or chosen would be lost by leaving (A1).
  bool get _isStarted => _name.text.isNotEmpty || _scheduler != null;

  /// Cancel, Back or a tap outside: asks first once the form is started.
  Future<void> _leave() async {
    if (_isStarted && !await showDeckDiscardDialog(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isSubmitting) return;
    final scheduler = _scheduler;
    if (scheduler == null) {
      setState(() => _isSchedulerMissing = true);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _rejection = null;
    });
    final outcome = await runHeld(
      () => ref
          .read(deckActionsControllerProvider.notifier)
          .createRootDeck(name: _name.text, schedulerType: scheduler),
      onFailed: (failure) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        showMxSnackbar(context, message: context.l10n.heldFailure(failure));
      },
    );
    if (outcome == null || !mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Held while the deck is written, as every async confirm is (M3 B2).
    final dialog = MxDialog(
      isHeld: _isSubmitting,
      title: l10n.deckCreateRootTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dimens.space12,
        children: [
          DeckNameFieldWidget(
            controller: _name,
            submitted: _rejection,
            // A new character clears the last refusal; the length rule is
            // read again as it is typed.
            onChanged: (_) => setState(() => _rejection = null),
            onSubmitted: _canSubmit ? (_) => _submit() : null,
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
        onConfirm: _canSubmit ? _submit : null,
        isConfirmLoading: _isSubmitting,
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSubmitting) return;
        unawaited(_leave());
      },
      child: dialog,
    );
  }
}
