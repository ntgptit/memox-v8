import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';

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
    final draft = row.draft;
    final reason = l10n.importRowNote(row);
    final note = reason == null ? null : metaDots(reason);
    final back = draft?.back.trim() ?? '';
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dimens.space16,
          vertical: context.dimens.space12,
        ),
        // The number and the mark centre on the row (kit 11).
        child: Row(
          spacing: context.dimens.space12,
          children: [
            Text(
              '${row.rowNumber}',
              semanticsLabel: l10n.importRowNumber(row.rowNumber),
              style: context.texts.meta.copyWith(
                color: context.colors.mutedForeground,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: context.dimens.space4,
                children: [
                  if (draft != null) ...[
                    Text(
                      draft.front.trim().isEmpty
                          ? l10n.importRowEmptyCell
                          : draft.front.trim(),
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.sectionTitle,
                    ),
                    Text(
                      back.isEmpty ? l10n.importRowEmptyCell : back,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.body.copyWith(
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                  if (note != null)
                    Text(
                      note,
                      style: row.kind == ImportRowKind.invalid
                          ? context.texts.meta.copyWith(
                              color: context.status.warning,
                            )
                          : context.texts.body.copyWith(
                              color: context.colors.mutedForeground,
                            ),
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
      ImportRowKind.ready => (AppIcons.check, context.status.success),
      // The legend badge's glyph; an X would read as a dismiss control.
      ImportRowKind.invalid => (AppIcons.alert, context.status.warning),
      ImportRowKind.duplicateInDeck || ImportRowKind.duplicateInSource => (
        AppIcons.cardDeck,
        colors.mutedForeground,
      ),
      ImportRowKind.blank => (AppIcons.remove, colors.mutedForeground),
    };
    return Semantics(
      label: label,
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: context.dimens.sizeIconCompact),
        child: Icon(icon),
      ),
    );
  }
}
