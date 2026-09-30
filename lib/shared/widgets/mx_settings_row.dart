import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

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

  /// A toggle, a time button or a value.
  final Widget? trailing;

  /// A stepper or a segmented tray, on its own line under the label. It
  /// keeps its own width (ruling S17).
  final Widget? wideControl;

  /// Navigates. The row then shows the chevron, unless it holds a control.
  final VoidCallback? onTap;

  /// False dims the tile, the label and the control while the setting is
  /// unavailable; the subtitle, which says why, keeps full ink (critique
  /// 2026-09-30).
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
    final styles = context.textStyles;
    final isNavigable =
        onTap != null && !isAction && trailing == null && wideControl == null;
    final isStacked =
        trailing != null &&
        MediaQuery.textScalerOf(context).scale(1) >= stackTextScale;
    final below = isStacked ? trailing : wideControl;
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      dimsWhenDisabled: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            spacing: AppSpacing.gutter,
            // Kit 23: beside a wide control the tile stays with the label.
            crossAxisAlignment: below == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (icon case final glyph?)
                Padding(
                  padding: EdgeInsets.only(
                    top: below == null ? 0 : AppSpacing.grouped,
                  ),
                  child: SizedBox(
                    width: _leadColumn,
                    child: Center(
                      heightFactor: 1,
                      child: _dim(
                        MxIconTile(icon: glyph, size: MxIconTileSize.medium),
                      ),
                    ),
                  ),
                ),
              // As in MxListRow, only the text carries the 12/12 inset, so a
              // 48 toggle target sits inside the row instead of growing it.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.grouped,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dim(Text(label, style: styles.settingsLabel)),
                      if (subtitle case final text?) ...[
                        const SizedBox(height: _subtitleGap),
                        Text(text, style: styles.rowDescription),
                      ],
                      if (below case final control?) ...[
                        const SizedBox(height: AppSpacing.grouped),
                        _dim(control),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isStacked && trailing != null) _dim(trailing!),
              if (isNavigable)
                _dim(
                  Icon(
                    AppIcons.chevronRight,
                    size: AppIconSize.compact,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dim(Widget child) =>
      isEnabled ? child : Opacity(opacity: AppOpacity.disabled, child: child);
}
