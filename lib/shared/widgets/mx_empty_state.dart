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
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tertiaryActionLabel,
    this.onTertiaryAction,
    this.footnote,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction come together',
       ),
       assert(
         onSecondaryAction == null || secondaryActionLabel != null,
         'onSecondaryAction needs secondaryActionLabel',
       ),
       assert(
         (tertiaryActionLabel == null) == (onTertiaryAction == null),
         'tertiaryActionLabel and onTertiaryAction come together',
       );

  final IconData icon;
  final String title;
  final String? body;
  final MxEmptyStateTone tone;

  /// Inside another card or a sheet.
  final bool isCompact;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A second, quieter action; drawn disabled when [onSecondaryAction] is
  /// null.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// A third, quietest action (outline), as the unset deck's "Import cards".
  final String? tertiaryActionLabel;
  final VoidCallback? onTertiaryAction;

  /// A product rule under the action, in the footnote form (`MxNote.hint`,
  /// ruling S19; a boxed note inside the card was two edges in dark, audit
  /// 2026-10-08 F-02, DEV-303).
  final String? footnote;

  static const double _tileSize = 64;
  static const double _compactTileSize = 52;

  /// Full card top padding (contract: 44 24 32).
  static const double _topPadding = 44;

  @override
  Widget build(BuildContext context) {
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
          context.semanticColors,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tile(icon: icon, tone: tone, isCompact: isCompact),
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
              if (secondaryActionLabel case final label?) ...[
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: label,
                  tone: MxButtonTone.secondary,
                  onPressed: onSecondaryAction,
                  isBlock: true,
                ),
              ],
              if ((tertiaryActionLabel, onTertiaryAction) case (
                final label?,
                final onPressed?,
              )) ...[
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: label,
                  tone: MxButtonTone.outline,
                  onPressed: onPressed,
                  isBlock: true,
                ),
              ],
              if (footnote case final rule?) ...[
                const SizedBox(height: AppSpacing.card),
                MxNote.hint(text: rule),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tone,
    required this.isCompact,
  });

  final IconData icon;
  final MxEmptyStateTone tone;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    // The tone's soft ground with its on-soft glyph (spec 2026-10-10 §5.3).
    final (ground, foreground) = switch (tone) {
      MxEmptyStateTone.primary => (
        semantic.primarySoft,
        semantic.onPrimarySoft,
      ),
      MxEmptyStateTone.neutral => (
        semantic.neutralSoft,
        semantic.onNeutralSoft,
      ),
      MxEmptyStateTone.success => (
        semantic.successSoft,
        semantic.onSuccessSoft,
      ),
      MxEmptyStateTone.warning => (
        semantic.warningSoft,
        semantic.onWarningSoft,
      ),
      MxEmptyStateTone.danger => (semantic.dangerSoft, semantic.onDangerSoft),
    };
    return SizedBox.square(
      dimension: isCompact
          ? MxEmptyState._compactTileSize
          : MxEmptyState._tileSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(
            isCompact ? AppRadius.lg : AppRadius.xl,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: isCompact ? AppIconSize.standard : AppIconSize.large,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
