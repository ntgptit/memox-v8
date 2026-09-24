import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// What the surface's emptiness means: action-led, a plain fact, a calm
/// finish, something to act on, or a failed outcome.
enum MxEmptyStateTone { primary, neutral, success, warning, danger }

/// The centred "this is the state of this surface" card: tinted tile, title,
/// one line of copy and optionally the action that fixes it.
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = MxEmptyStateTone.primary,
    this.isCompact = false,
    this.actionLabel,
    this.onAction,
    this.footnote,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction come together',
       );

  final IconData icon;
  final String title;
  final String? body;
  final MxEmptyStateTone tone;

  /// Inside another card or a sheet.
  final bool isCompact;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A product rule under the action, drawn as an MxNote (ruling S19).
  final String? footnote;

  static const double _tileTint = 0.10;
  static const double _tileSize = 64;
  static const double _compactTileSize = 52;

  /// Full card top padding (contract: 44 24 32).
  static const double _topPadding = 44;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(context);
    final styles = context.textStyles;
    final padding = isCompact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.section,
            vertical: AppSpacing.major,
          )
        : const EdgeInsets.fromLTRB(
            AppSpacing.section,
            _topPadding,
            AppSpacing.section,
            AppSpacing.major,
          );
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: AppDecorations.raisedCard(
          context.colors,
          context.derivedColors,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tile(icon: icon, color: toneColor, isCompact: isCompact),
              // Ruling R7: the tile→title and title→body gaps are
              // UNSPECIFIED in the contract.
              const SizedBox(height: AppSpacing.gutter),
              Text(
                title,
                textAlign: TextAlign.center,
                style: isCompact ? styles.emptyTitleCompact : styles.emptyTitle,
              ),
              if (body case final body?) ...[
                const SizedBox(height: AppSpacing.control),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: styles.emptyBody,
                ),
              ],
              if ((actionLabel, onAction) case (
                final label?,
                final onPressed?,
              )) ...[
                const SizedBox(height: AppSpacing.card),
                MxButton(label: label, onPressed: onPressed, isBlock: true),
              ],
              if (footnote case final rule?) ...[
                const SizedBox(height: AppSpacing.card),
                MxNote(text: rule),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) => switch (tone) {
    MxEmptyStateTone.primary => context.colors.primary,
    MxEmptyStateTone.neutral => context.colors.onSurfaceVariant,
    MxEmptyStateTone.success => context.semanticColors.mastery,
    MxEmptyStateTone.warning => context.semanticColors.warning,
    MxEmptyStateTone.danger => context.colors.error,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.isCompact,
  });

  final IconData icon;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: isCompact
        ? MxEmptyState._compactTileSize
        : MxEmptyState._tileSize,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: MxEmptyState._tileTint),
        borderRadius: BorderRadius.circular(
          isCompact ? AppRadius.lg : AppRadius.xl,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: isCompact ? AppIconSize.standard : AppIconSize.large,
          color: color,
        ),
      ),
    ),
  );
}
