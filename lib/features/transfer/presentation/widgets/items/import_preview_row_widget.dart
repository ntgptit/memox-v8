import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// One source row in the preview (kit 11 preview table): its number, the
/// term and the meaning on up to two lines each, why it will not be written,
/// and its status mark. The mark carries its words for TalkBack, so the
/// status is never colour alone (kit deviation K3).
class ImportPreviewRowWidget extends StatelessWidget {
  const ImportPreviewRowWidget({super.key, required this.row});

  final ImportRow row;

  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final draft = row.draft;
    final note = l10n.importRowNote(row);
    final back = draft?.back.trim() ?? '';
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              '${row.rowNumber}',
              semanticsLabel: l10n.importRowNumber(row.rowNumber),
              style: styles.counter,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  if (draft != null) ...[
                    Text(
                      draft.front.trim().isEmpty
                          ? l10n.importRowEmptyCell
                          : draft.front.trim(),
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: styles.contentTitle,
                    ),
                    Text(
                      back.isEmpty ? l10n.importRowEmptyCell : back,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: styles.rowDescription,
                    ),
                  ],
                  if (note != null)
                    Text(
                      note,
                      style: row.kind == ImportRowKind.invalid
                          ? styles.statusLabel(context.derivedColors.warningInk)
                          : styles.rowDescription,
                    ),
                ],
              ),
            ),
            _Mark(kind: row.kind, label: note ?? l10n.importRowReady),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.kind, required this.label});

  final ImportRowKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, color) = switch (kind) {
      ImportRowKind.ready => (AppIcons.check, context.semanticColors.mastery),
      ImportRowKind.invalid => (
        AppIcons.close,
        context.derivedColors.warningInk,
      ),
      ImportRowKind.duplicateInDeck || ImportRowKind.duplicateInSource => (
        AppIcons.cardDeck,
        colors.onSurfaceVariant,
      ),
      ImportRowKind.blank => (AppIcons.remove, colors.onSurfaceVariant),
    };
    return Semantics(
      label: label,
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: AppIconSize.compact),
        child: Icon(icon),
      ),
    );
  }
}
