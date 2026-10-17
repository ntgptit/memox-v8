import 'package:flutter/widgets.dart';
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
/// MxSection, the section draws the dividers. Its height is the Material 3
/// list item: 56 with a label alone, 72 with a subtitle.
class MxSettingsRow extends StatelessWidget {
  const MxSettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconTone = MxIconTileTone.tinted,
    this.trailing,
    this.wideControl,
    this.message,
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

  /// A line under the row, such as a field error, from the label's start to
  /// the row's end, so a trailing control does not squeeze it (Study options
  /// compaction, owner 2026-10-07).
  final Widget? message;

  /// Navigates. The row then shows the chevron, unless it holds a control.
  final VoidCallback? onTap;

  /// False dims the tile, the label and the control while the setting is
  /// unavailable; the subtitle, which says why, keeps full strength (critique
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

  /// The painted square of a stepper's step button inside its 48 target.
  static const double _stepPainted = 32;
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
        constraints: BoxConstraints(
          minHeight: subtitle == null
              ? context.dimens.sizeListRow
              : context.dimens.sizeListRowTwoLine,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dimens.space16),
          child: _withMessage(
            context,
            Row(
              // Kit 23: beside a wide control the tile stays with the label.
              crossAxisAlignment: below == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (icon case final glyph?) ...[
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
                  SizedBox(width: context.dimens.space16),
                ],
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
                          Text(label, style: context.texts.itemTitle),
                        ),
                        if (subtitle case final text?) ...[
                          const SizedBox(height: _subtitleGap),
                          Text(
                            text,
                            style: context.texts.body.copyWith(
                              color: context.colors.mutedForeground,
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
                if (!isStacked && trailing != null) ...[
                  SizedBox(width: _trailingGap(context, trailing!)),
                  _dimControl(context, trailing!),
                ],
                if (isNavigable) ...[
                  SizedBox(width: context.dimens.space16),
                  _dim(
                    context,
                    Icon(
                      AppIcons.chevronRight,
                      size: context.dimens.sizeIconCompact,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The row, then [message] under it, indented to the label's start.
  Widget _withMessage(BuildContext context, Widget row) {
    final line = message;
    if (line == null) return row;
    final labelStart = icon == null
        ? 0.0
        : _leadColumn + context.dimens.space16;
    // The message starts on the label's start, so its glyph lines up with
    // the label (audit 2026-10-07).
    final indent = labelStart;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: indent,
            bottom: context.dimens.space12,
          ),
          child: line,
        ),
      ],
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

  /// The clear space before a trailing control. MxStepper's step buttons
  /// paint inside 48 targets that already leave clear space around them, so
  /// the row adds only the rest, and its painted gap matches the other
  /// controls': the label beside it keeps its width ("Per session" stays on
  /// one line at 360dp).
  static double _trailingGap(BuildContext context, Widget control) {
    final dimens = context.dimens;
    if (!_isStepper(control)) return dimens.space16;
    final touchInset = (dimens.sizeControl - _stepPainted) / 2;
    return dimens.space16 - touchInset;
  }

  static bool _isStepper(Widget control) => switch (control) {
    MxStepper() => true,
    Semantics(:final child?) => _isStepper(child),
    _ => false,
  };

  Widget _dimControl(BuildContext context, Widget control) =>
      _drawsOwnDisabledState(control) ? control : _dim(context, control);

  Widget _dim(BuildContext context, Widget child) => isEnabled
      ? child
      : Opacity(opacity: context.colors.disabledOpacity, child: child);
}
