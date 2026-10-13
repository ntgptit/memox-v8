import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// A setting: a bigger label, a roomier lead column, and a trailing slot for
/// a control. The chevron shows only when the row navigates and holds no
/// control, so a row with a toggle never implies a destination. Inside an
/// MxSection, the section draws the dividers.
class MxSettingsRow extends StatelessWidget {
  const MxSettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconTone = MxIconTileTone.tinted,
    this.trailing,
    this.wideControl,
    this.onTap,
    this.isEnabled = true,
    this.isAction = false,
  }) : assert(trailing == null || wideControl == null, 'one control slot');

  final String label;
  final String? subtitle;

  /// Drawn as an MxIconTile at the medium step, centred in the 40 lead column.
  final IconData? icon;

  /// The lead tile's tone: tinted by default; success when the setting's
  /// state is fine, as screen 23's Sync row once sync is settled (critique
  /// 2026-09-30 tone pass, T4).
  final MxIconTileTone iconTone;

  /// A toggle, a time button or a value.
  final Widget? trailing;

  /// A stepper or a segmented tray, on its own line under the label. It
  /// keeps its own width (ruling S17).
  final Widget? wideControl;

  /// Navigates. The row then shows the chevron, unless it holds a control.
  final VoidCallback? onTap;

  /// False dims the tile, the label and the control while the setting is
  /// unavailable; the subtitle, which says why, keeps full ink (critique
  /// 2026-09-30). A control that draws its own disabled state is left to it
  /// (part 3a).
  final bool isEnabled;

  /// Runs an action or opens a dialog: no chevron, since nothing is
  /// navigated to (critique 2026-09-30).
  final bool isAction;

  /// From this text scale on, a trailing control moves under the text, so
  /// the label keeps its width (audit 2026-09-29, screen 24).
  static const double stackTextScale = 1.5;

  static const double _leadColumn = 40;
  static const double _subtitleGap = 4;

  @override
  Widget build(BuildContext context) {
    final isNavigable =
        onTap != null && !isAction && trailing == null && wideControl == null;
    final isStacked =
        trailing != null &&
        MediaQuery.textScalerOf(context).scale(1) >= stackTextScale;
    final below = isStacked ? trailing : wideControl;
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      shouldDimWhenDisabled: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dimens.space16),
          child: Row(
            spacing: context.dimens.space16,
            // Kit 23: beside a wide control the tile stays with the label.
            crossAxisAlignment: below == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (icon case final glyph?)
                Padding(
                  padding: EdgeInsets.only(
                    top: below == null ? 0 : context.dimens.space12,
                  ),
                  child: SizedBox(
                    width: _leadColumn,
                    child: Center(
                      heightFactor: 1,
                      child: _dim(
                        context,
                        MxIconTile(
                          icon: glyph,
                          size: MxIconTileSize.medium,
                          tone: iconTone,
                        ),
                      ),
                    ),
                  ),
                ),
              // As in MxListRow, only the text carries the 12/12 inset, so a
              // 48 toggle target sits inside the row instead of growing it.
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.dimens.space12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dim(
                        context,
                        Text(label, style: context.texts.titleSmall),
                      ),
                      if (subtitle case final text?) ...[
                        const SizedBox(height: _subtitleGap),
                        Text(
                          text,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (below case final control?) ...[
                        SizedBox(height: context.dimens.space12),
                        _dimControl(context, control),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isStacked && trailing != null)
                _dimControl(context, trailing!),
              if (isNavigable)
                _dim(
                  context,
                  Icon(
                    AppIcons.chevronRight,
                    size: context.dimens.sizeIconCompact,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// MxButton, MxToggle and MxStepper draw their own disabled opacity, so
  /// the row leaves them alone, also under a Semantics label, as the
  /// reminder's time button is (critique 2026-09-30 part 3a).
  static bool _drawsOwnDisabledState(Widget control) => switch (control) {
    MxButton() || MxToggle() || MxStepper() => true,
    Semantics(:final child?) => _drawsOwnDisabledState(child),
    _ => false,
  };

  Widget _dimControl(BuildContext context, Widget control) =>
      _drawsOwnDisabledState(control) ? control : _dim(context, control);

  Widget _dim(BuildContext context, Widget child) => isEnabled
      ? child
      : Opacity(opacity: context.dimens.opacityDisabledContent, child: child);
}
