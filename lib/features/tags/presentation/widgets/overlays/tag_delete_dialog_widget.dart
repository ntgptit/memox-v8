import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// Asks before [tag] is deleted, saying no card is (UC-TAG-001 A3; kit 05
/// `del`). Completes true to delete.
Future<bool> showTagDeleteDialog(
  BuildContext context, {
  required TagCount tag,
}) {
  final l10n = context.l10n;
  final count = tag.cardCount;
  return showMxConfirm(
    context,
    title: l10n.tagsDeleteTitle,
    body: l10n.tagsDeleteBody(tag.name, count),
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.tagsDeleteConfirm,
    // A neutral note: the reassurance BR-TAG-008 asks for, without a
    // success ground beside the destructive confirm (critique 2026-09-30
    // part 3d-2, E7).
    content: MxNote(icon: AppIcons.safe, text: l10n.tagsDeleteSafe(count)),
    isDestructive: true,
  );
}
