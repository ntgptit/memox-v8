import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before [tag] is deleted, saying no card is (UC-TAG-001 A3; kit 05
/// `del`). Completes true to delete.
Future<bool> showTagDeleteDialog(
  BuildContext context, {
  required TagCount tag,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => TagDeleteDialogWidget(tag: tag),
    ) ??
    false;

class TagDeleteDialogWidget extends StatelessWidget {
  const TagDeleteDialogWidget({super.key, required this.tag});

  final TagCount tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = tag.cardCount;
    return MxDialog(
      title: l10n.tagsDeleteTitle,
      body: l10n.tagsDeleteBody(tag.name, count),
      // A neutral note: the reassurance BR-TAG-008 asks for, without a
      // success ground beside the destructive confirm (critique 2026-09-30
      // part 3d-2, E7).
      content: MxNote(icon: AppIcons.safe, text: l10n.tagsDeleteSafe(count)),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.tagsDeleteConfirm,
        confirmIcon: AppIcons.delete,
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
