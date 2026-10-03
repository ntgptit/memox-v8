import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/tag_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_attach_model.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Adds one tag, by name, to every card of [cardIds] (UC-CARD-001 A8).
/// Completes true once it landed. Ruling P3-L9: a dialog, since a sheet does
/// not yet pad for the keyboard (UI-base §9 row 64). [onAllGone] runs when
/// every card was already gone (SP2a 2.19).
Future<bool> showCardTagDialog(
  BuildContext context, {
  required Set<String> cardIds,
  VoidCallback? onAllGone,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) =>
          CardTagDialogWidget(cardIds: cardIds, onAllGone: onAllGone),
    ) ??
    false;

class CardTagDialogWidget extends ConsumerStatefulWidget {
  const CardTagDialogWidget({super.key, required this.cardIds, this.onAllGone});

  final Set<String> cardIds;
  final VoidCallback? onAllGone;

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
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .addTag(cardIds: widget.cardIds, tagName: _name.text);
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok(value: TagAttached(outcome: final bulk)):
          showMxSnackbar(
            context,
            message: l10n.bulkToast(
              l10n.cardTaggedToast(bulk.done.length, _name.text.trim()),
              bulk.skipped.length,
            ),
            duration: bulkToastDuration(hasNews: bulk.skipped.isNotEmpty),
          );
          Navigator.of(context).pop(true);
        // IT-ORG-014, BR-TAG-002: nothing was written; the selection stays.
        case Ok(value: TagLimitReached(:final fullCardIds)):
          showMxSnackbar(
            context,
            message: l10n.cardTagLimitReached(fullCardIds.length),
            // Nothing was written: that is the news (SP2a audit m7).
            duration: bulkToastDuration(hasNews: true),
          );
          Navigator.of(context).pop(false);
        // SP2a 2.19: every card was already gone; nothing was written.
        case Rejected(reason: TagRejection.notFound):
          widget.onAllGone?.call();
          showMxSnackbar(
            context,
            message: widget.cardIds.length > 1
                ? l10n.cardBulkAllGone(widget.cardIds.length)
                : l10n.tagRejection(TagRejection.notFound),
            duration: bulkToastDuration(hasNews: widget.cardIds.length > 1),
          );
          Navigator.of(context).pop(false);
        case Rejected(:final reason) when _nameReasons.contains(reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
        case Rejected(:final reason):
          showMxSnackbar(context, message: l10n.tagRejection(reason));
          Navigator.of(context).pop(false);
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
      title: l10n.cardTagTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          MxTextField(
            controller: _name,
            label: l10n.cardTagHint,
            hintText: l10n.cardTagHint,
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
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardTagConfirm,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
