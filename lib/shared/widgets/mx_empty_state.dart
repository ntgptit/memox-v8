import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

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
    final toneColor = _toneColor(context);
    final padding = isCompact
        ? EdgeInsets.symmetric(
            horizontal: context.dimens.space24,
            vertical: context.dimens.space32,
          )
        : EdgeInsets.fromLTRB(
            context.dimens.space24,
            _topPadding,
            context.dimens.space24,
            context.dimens.space32,
          );
    return SizedBox(
      width: double.infinity,
      child: MxCard(
        isFullBleed: true,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tile(
                icon: icon,
                color: toneColor,
                foreground: switch (tone) {
                  MxEmptyStateTone.primary => context.status.accentMark,
                  MxEmptyStateTone.success => context.status.success,
                  // As the caution tile and the warning banner (critique
                  // 2026-09-30 part 3d-2, E14).
                  MxEmptyStateTone.warning => context.status.warning,
                  _ => toneColor,
                },
                isCompact: isCompact,
              ),
              // Ruling R7: the tile→title and title→body gaps are
              // UNSPECIFIED in the contract.
              SizedBox(height: context.dimens.space16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: isCompact
                    ? context.texts.itemTitle
                    : context.texts.sectionTitle,
              ),
              if (body case final body?) ...[
                SizedBox(height: context.dimens.space8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: context.texts.body.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
              if ((actionLabel, onAction) case (
                final label?,
                final onPressed?,
              )) ...[
                SizedBox(height: context.dimens.space24),
                MxButton(label: label, onPressed: onPressed, isBlock: true),
              ],
              if (secondaryActionLabel case final label?) ...[
                SizedBox(height: context.dimens.space8),
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
                SizedBox(height: context.dimens.space8),
                MxButton(
                  label: label,
                  tone: MxButtonTone.outline,
                  onPressed: onPressed,
                  isBlock: true,
                ),
              ],
              if (footnote case final rule?) ...[
                SizedBox(height: context.dimens.space24),
                MxNote.hint(text: rule),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) => switch (tone) {
    MxEmptyStateTone.primary => context.colors.primary,
    MxEmptyStateTone.neutral => context.colors.mutedForeground,
    MxEmptyStateTone.success => context.status.success,
    MxEmptyStateTone.warning => context.status.warningFill,
    MxEmptyStateTone.danger => context.colors.error,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.isCompact,
  });

  final IconData icon;

  /// The tint's base.
  final Color color;

  /// The glyph: the accent for the primary tone (spec 2026-09-27 D2), the
  /// success text colour for success (critique 2026-09-30 tone pass, T7), the
  /// warning text colour for warning (part 3d-2, E14).
  final Color foreground;
  final bool isCompact;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: isCompact
        ? MxEmptyState._compactTileSize
        : MxEmptyState._tileSize,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.tintOver(MxTintBase.of(context)),
        borderRadius: isCompact ? context.radii.lg : context.radii.xl2,
      ),
      child: Center(
        child: Icon(
          icon,
          size: isCompact
              ? context.dimens.sizeIcon
              : context.dimens.sizeIconTile,
          color: foreground,
        ),
      ),
    ),
  );
}
