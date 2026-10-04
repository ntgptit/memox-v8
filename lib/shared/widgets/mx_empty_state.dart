import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/feedback_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

export 'package:memox/core/theme/components/feedback_style.dart'
    show MxEmptyStateTone;

/// An empty state's action: a label and what it does.
class MxEmptyStateAction {
  const MxEmptyStateAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Nothing here yet, and what to do (DESIGN.md, MxEmptyState): a toned r20
/// tile (64, or 48 [isCompact]), 8 to the title and its message, 12 to up to
/// two actions (the first filled, 8 apart) and an optional footnote.
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.tone = MxEmptyStateTone.primary,
    this.action,
    this.secondaryAction,
    this.footnote,
    this.isCompact = false,
    super.key,
  }) : assert(
         secondaryAction == null || action != null,
         'A second action follows a first.',
       );

  final IconData icon;
  final String title;
  final String? message;
  final MxEmptyStateTone tone;
  final MxEmptyStateAction? action;
  final MxEmptyStateAction? secondaryAction;

  /// A product rule under the actions, drawn as `MxNote.hint`.
  final String? footnote;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tile = mxEmptyTileColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final String? body = message;
    final MxEmptyStateAction? first = action;
    final MxEmptyStateAction? second = secondaryAction;
    final String? rule = footnote;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.gutter : AppSpacing.section,
        vertical: isCompact ? AppSpacing.section : AppSpacing.major,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: isCompact
                  ? AppSize.emptyTileCompact
                  : AppSize.emptyTile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tile.ground,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(icon, size: AppIconSize.large, color: tile.content),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleLarge,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.control),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.apply(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (first != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxButton(label: first.label, onPressed: first.onPressed),
          ],
          if (second != null) ...[
            const SizedBox(height: AppSpacing.control),
            MxButton(
              label: second.label,
              onPressed: second.onPressed,
              tone: MxButtonTone.text,
            ),
          ],
          if (rule != null) ...[
            const SizedBox(height: AppSpacing.control),
            MxNote.hint(text: rule),
          ],
        ],
      ),
    );
  }
}
