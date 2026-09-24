import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Sends a dialog's name through one controller command.
typedef DeckNameSubmit = Future<Outcome<Object?, DeckRejection>> Function(
  DeckActionsController actions,
  String name,
);

/// A new deck inside [parentId], at the end of its decks (UC-DECK-004).
Future<void> showCreateSubDeckDialog(
  BuildContext context, {
  required String parentId,
}) => showMxDialog<void>(
  context,
  builder: (dialogContext) => DeckNameDialogWidget(
    title: dialogContext.l10n.deckCreateSubTitle,
    confirmLabel: dialogContext.l10n.deckCreateConfirm,
    submit: (actions, name) =>
        actions.createSubDeck(parentId: parentId, name: name),
  ),
);

/// A new name for [deck] (UC-DECK-002).
Future<void> showRenameDeckDialog(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxDialog<void>(
  context,
  builder: (dialogContext) => DeckNameDialogWidget(
    title: dialogContext.l10n.deckRenameTitle,
    confirmLabel: dialogContext.l10n.deckRenameConfirm,
    initialName: deck.name,
    submit: (actions, name) => actions.renameDeck(deckId: deck.id, name: name),
  ),
);

/// One name field and its confirm. A refusal about the name stays under
/// the field; any other refusal closes the dialog with a snackbar (ruling
/// P2-L10).
class DeckNameDialogWidget extends ConsumerStatefulWidget {
  const DeckNameDialogWidget({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.submit,
    this.initialName = '',
  });

  final String title;
  final String confirmLabel;
  final DeckNameSubmit submit;
  final String initialName;

  @override
  ConsumerState<DeckNameDialogWidget> createState() =>
      _DeckNameDialogWidgetState();
}

class _DeckNameDialogWidgetState extends ConsumerState<DeckNameDialogWidget> {
  static const _nameReasons = {
    DeckRejection.blankName,
    DeckRejection.nameTooLong,
  };

  late final _name = TextEditingController(text: widget.initialName);
  DeckRejection? _rejection;

  /// One submit at a time: a second tap while the first runs does nothing.
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
      final outcome = await widget.submit(
        ref.read(deckActionsControllerProvider.notifier),
        _name.text,
      );
      if (!mounted) return;
      switch (outcome) {
        case Ok():
          Navigator.of(context).pop();
        case Rejected(:final reason) when _nameReasons.contains(reason):
          setState(() {
            _rejection = reason;
            _isSubmitting = false;
          });
        case Rejected(:final reason):
          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
          Navigator.of(context).pop();
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
      title: widget.title,
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
            onSubmitted: _isSubmitting ? null : (_) => _submit(),
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: widget.confirmLabel,
        onConfirm: _isSubmitting ? null : _submit,
      ),
    );
  }
}
