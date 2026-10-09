import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/widgets/support/tag_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// How long the name stays still before its plan is read (FE-B2 spec D8).
const Duration tagRenameSettle = Duration(milliseconds: 250);

/// The name to write, and the tag the person confirmed merging into.
typedef TagRenameRequest = ({String name, String? mergeIntoTagId});

/// Renames [tag], starting from [name] when the last try must be planned
/// again (kit 05 `rename`, `renameMerge`, `nameTooLong`). Completes with
/// the request to write, or null when cancelled.
Future<TagRenameRequest?> showTagRenameDialog(
  BuildContext context, {
  required TagCount tag,
  String? name,
}) => showMxDialog<TagRenameRequest>(
  context,
  builder: (_) => TagRenameDialogWidget(tag: tag, name: name ?? tag.name),
);

/// The name, checked as it is typed (BR-TAG-001), and what writing it would
/// do: nothing, a rename, or a merge disclosed before it is confirmed
/// (UC-TAG-001 A1). The last plan stays while the next one settles.
class TagRenameDialogWidget extends ConsumerStatefulWidget {
  const TagRenameDialogWidget({
    super.key,
    required this.tag,
    required this.name,
  });

  final TagCount tag;
  final String name;

  @override
  ConsumerState<TagRenameDialogWidget> createState() =>
      _TagRenameDialogWidgetState();
}

class _TagRenameDialogWidgetState extends ConsumerState<TagRenameDialogWidget> {
  late final _name = TextEditingController(text: widget.name);
  Timer? _settle;
  TagRenamePlan? _plan;

  @override
  void initState() {
    super.initState();
    unawaited(_readPlan());
  }

  @override
  void dispose() {
    _settle?.cancel();
    _name.dispose();
    super.dispose();
  }

  /// The name rule the text breaks, checked at once; null when it passes.
  TagRejection? get _rejection => switch (TagEntity.checkName(_name.text)) {
    Ok() => null,
    Rejected(:final reason) => reason,
  };

  int get _length => _name.text.trim().characters.length;

  void _changed(String _) {
    _settle?.cancel();
    setState(() {});
    if (_rejection != null) return;
    _settle = Timer(tagRenameSettle, () => unawaited(_readPlan()));
  }

  Future<void> _readPlan() async {
    final name = _name.text;
    if (_rejection != null) return;
    try {
      final outcome = await ref
          .read(tagActionsControllerProvider.notifier)
          .planRename(tagId: widget.tag.id, name: name);
      if (!mounted || _name.text != name) return;
      switch (outcome) {
        case Ok(:final value):
          setState(() => _plan = value);
        // The tag was deleted meanwhile: nothing here can succeed. The dialog
        // hands the name to the write, which writes nothing and says the tag
        // is gone (E3).
        case Rejected(reason: TagRejection.notFound):
          _pop(null);
        case Rejected():
          setState(() => _plan = null);
      }
    } on Failure {
      // The last plan stays; the write checks again.
    }
  }

  /// Rename or merge, once the name passes and would change something.
  VoidCallback? get _confirm {
    if (_rejection != null) return null;
    return switch (_plan) {
      TagRenameRename() => () => _pop(null),
      TagRenameMerge(:final target) => () => _pop(target.id),
      TagRenameUnchanged() || null => null,
    };
  }

  void _pop(String? mergeIntoTagId) =>
      Navigator.of(context)
          .pop((name: _name.text, mergeIntoTagId: mergeIntoTagId));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final rejection = _rejection;
    final isTooLong = rejection == TagRejection.nameTooLong;
    final merge = switch (_plan) {
      final TagRenameMerge plan when rejection == null => plan,
      _ => null,
    };
    final confirm = _confirm;
    return MxDialog(
      title: l10n.tagsRename,
      body: l10n.tagsRenameBody(widget.tag.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.tagsNewName, style: styles.fieldLabel)),
              if (isTooLong)
                Text(
                  l10n.tagsLength(_length, TagEntity.maxNameLength),
                  style: styles.captionIn(context.colors.error),
                ),
            ],
          ),
          MxTextField(
            controller: _name,
            label: l10n.tagsNewName,
            errorText: _message(l10n, rejection),
            textInputAction: TextInputAction.done,
            onChanged: _changed,
            onSubmitted: (_) => confirm?.call(),
          ),
          if (rejection == null)
            Text(
              merge == null
                  ? l10n.tagsCaseHint
                  : l10n.tagsLengthUnique(_length, TagEntity.maxNameLength),
              style: styles.footerCaption,
            ),
          if (merge != null) _MergePanel(source: widget.tag, merge: merge),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: merge == null
            ? l10n.tagsRenameConfirm
            : l10n.tagsMergeConfirm,
        isWarning: merge != null,
        onConfirm: confirm,
      ),
    );
  }

  String? _message(AppLocalizations l10n, TagRejection? rejection) =>
      switch (rejection) {
        TagRejection.nameTooLong => l10n.tagsNameTooLong(
          TagEntity.maxNameLength,
        ),
        TagRejection.blankName => l10n.tagRejectionBlankName,
        TagRejection.controlCharacter => l10n.tagRejectionControlCharacter,
        _ => null,
      };
}

/// What the merge does, before it is confirmed (A1): the target keeps its
/// spelling, and carries the union of both tags' cards (BE-B2 D6).
class _MergePanel extends StatelessWidget {
  const _MergePanel({required this.source, required this.merge});

  final TagCount source;
  final TagRenameMerge merge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = context.textStyles.noteText;
    final ink = context.semanticColors.onWarningContainer;
    return MxCard(
      isWarning: true,
      // The panel's glyphs take the warning ink.
      child: IconTheme.merge(
        data: IconThemeData(color: ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.control,
          children: [
            Row(
              spacing: AppSpacing.control,
              children: [
                const Icon(AppIcons.merge),
                Expanded(
                  child: Text(
                    l10n.tagsMergeNotice(merge.target.name, source.name),
                    style: note,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.control,
              runSpacing: AppSpacing.micro,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MxTagChip(label: tagWithCount(source.name, source.cardCount)),
                const Icon(AppIcons.arrowRight),
                MxTagChip(
                  label: tagWithCount(merge.target.name, merge.mergedCardCount),
                ),
              ],
            ),
            Text(l10n.tagsMergeSafe, style: note),
          ],
        ),
      ),
    );
  }
}
