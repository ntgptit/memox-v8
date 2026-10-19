import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/tag_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/support/held_run.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Adds one tag, by name, to every card of [cardIds] (UC-CARD-001 A8).
/// Completes true once it landed. Ruling P3-L9 chose a dialog when only it
/// could hold a field; both pad for the keyboard now (UI-base §9 row 78).
Future<bool> showCardTagDialog(
  BuildContext context, {
  required Set<String> cardIds,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardTagDialogWidget(cardIds: cardIds),
    ) ??
    false;

class CardTagDialogWidget extends ConsumerStatefulWidget {
  const CardTagDialogWidget({super.key, required this.cardIds});

  final Set<String> cardIds;

  @override
  ConsumerState<CardTagDialogWidget> createState() =>
      _CardTagDialogWidgetState();
}

class _CardTagDialogWidgetState extends ConsumerState<CardTagDialogWidget> {
  /// Refusals about the name itself stay under the field (spec §5).
  static const _nameReasons = {
    TagRejection.blankName,
    TagRejection.nameTooLong,
    TagRejection.controlCharacter,
  };

  final _name = TextEditingController();
  TagRejection? _rejection;
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
    final outcome = await runHeld(
      () => ref
          .read(cardActionsControllerProvider.notifier)
          .addTag(cardIds: widget.cardIds, tagName: _name.text),
      onFailed: (failure) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        showMxSnackbar(context, message: context.l10n.heldFailure(failure));
      },
    );
    if (outcome == null || !mounted) return;
    final l10n = context.l10n;
    switch (outcome) {
      case Ok():
        Navigator.of(context).pop(true);
        showMxSnackbar(
          context,
          message: l10n.cardTaggedToast(
            widget.cardIds.length,
            _name.text.trim(),
          ),
        );
      case Rejected(:final reason) when _nameReasons.contains(reason):
        setState(() {
          _rejection = reason;
          _isSubmitting = false;
        });
      // IT-ORG-014: nothing was written; the selection stays.
      case Rejected(:final reason):
        Navigator.of(context).pop(false);
        showMxSnackbar(context, message: l10n.tagRejection(reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Held while the tag is written, as every async confirm is: the scrim,
    // Back and Cancel wait, and the confirm spins.
    return MxDialog(
      isHeld: _isSubmitting,
      title: l10n.cardTagTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dimens.space12,
        children: [
          MxTextField(
            controller: _name,
            label: l10n.cardTagHint,
            errorText: switch (_rejection) {
              null => null,
              final reason => l10n.tagRejection(reason),
            },
            textInputAction: TextInputAction.done,
            onSubmitted: _isSubmitting ? null : (_) => _submit(),
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardTagConfirm,
        onConfirm: _isSubmitting ? null : _submit,
        isConfirmLoading: _isSubmitting,
      ),
    );
  }
}
