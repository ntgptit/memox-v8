import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

enum _Trailing { none, chevron, badge, value, iconButton }

/// What ends a list row: exactly one of a closed set, so a badge and the
/// chevron never meet (DESIGN.md, MxListRow).
class MxListRowTrailing {
  const MxListRowTrailing.none()
    : _kind = _Trailing.none,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = null;

  /// The row opens a place; mirrors in right-to-left text.
  const MxListRowTrailing.chevron()
    : _kind = _Trailing.chevron,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = null;

  const MxListRowTrailing.badge(
    String label, [
    this._tone = MxBadgeTone.neutral,
  ]) : _kind = _Trailing.badge,
       _text = label,
       _button = null;

  /// A plain value, read at full contrast in `on-surface-variant`.
  const MxListRowTrailing.value(String value)
    : _kind = _Trailing.value,
      _text = value,
      _tone = MxBadgeTone.neutral,
      _button = null;

  /// One action of its own (an overflow ⋮): its own TalkBack node and focus
  /// stop, apart from the row's tap.
  const MxListRowTrailing.iconButton(MxIconButton button)
    : _kind = _Trailing.iconButton,
      _text = null,
      _tone = MxBadgeTone.neutral,
      _button = button;

  final _Trailing _kind;
  final String? _text;
  final MxBadgeTone _tone;
  final MxIconButton? _button;
}

/// One row of a list (DESIGN.md, MxListRow): at least 48 tall, 16 across and
/// 12 down; an optional leading icon tile (40) or selection checkbox 12 from
/// the text; a one-line title (cut with an ellipsis, read whole); a subtitle
/// of up to two lines; one trailing mark. Tappable rows carry the shared ripple
/// and the keyboard ring; inert rows stay at full contrast. A disabled row
/// dims its leading mark, title and chevron, never the subtitle that says
/// why. TalkBack reads the row as one node carrying every fact.
class MxListRow extends StatelessWidget {
  const MxListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTone = MxIconTileTone.tinted,
    this.isChecked,
    this.trailing = const MxListRowTrailing.none(),
    this.onTap,
    this.isEnabled = true,
    super.key,
  }) : assert(icon == null || isChecked == null, 'One leading mark.');

  final String title;
  final String? subtitle;

  /// A leading tile in [iconTone].
  final IconData? icon;
  final MxIconTileTone iconTone;

  /// A leading selection checkbox while the list is selecting; `null` hides it.
  final bool? isChecked;

  final MxListRowTrailing trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final double emphasis = isEnabled ? 1 : AppOpacity.disabled;
    final VoidCallback? tap = isEnabled ? onTap : null;
    final String? detail = subtitle;
    final Widget? lead = _leading();
    final Widget? end = _trailing(context);
    final Widget facts = LayoutBuilder(
      builder: (context, line) => Row(
        children: [
          if (lead != null) ...[
            Opacity(opacity: emphasis, child: lead),
            const SizedBox(width: AppSpacing.grouped),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: emphasis,
                  child: Semantics(
                    label: title,
                    excludeSemantics: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mxRowTitleStyle(context.texts, colors),
                    ),
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium?.apply(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (end != null) ...[
            const SizedBox(width: AppSpacing.grouped),
            ..._placed(end, emphasis, line.maxWidth),
          ],
        ],
      ),
    );
    final MxIconButton? action = trailing._button;
    // Beside a trailing action the row stops short; the action's 48 target
    // carries its own inner space.
    final Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.gutter,
          end: action == null ? AppSpacing.gutter : AppSpacing.micro,
          top: AppSpacing.grouped,
          bottom: AppSpacing.grouped,
        ),
        child: facts,
      ),
    );
    final Widget pressable = tap == null
        ? body
        : MxFocusRing(
            borderRadius: BorderRadius.zero,
            child: MxRowInk(onTap: tap, child: body),
          );
    // One TalkBack node carrying every fact, the ripple's tap and focus included.
    final Widget row = MergeSemantics(
      child: Semantics(
        button: tap != null,
        enabled: isEnabled,
        checked: isChecked,
        child: pressable,
      ),
    );
    if (action == null) {
      return row;
    }
    // The trailing action is its own node beside the row, never merged in.
    return Row(
      children: [
        Expanded(child: row),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.micro),
          child: action,
        ),
      ],
    );
  }

  // The chevron dims with the row; a value keeps its width up to half the
  // line, so a long one wraps there and the title keeps the rest.
  List<Widget> _placed(Widget end, double emphasis, double line) {
    if (trailing._kind == _Trailing.chevron) {
      return [Opacity(opacity: emphasis, child: end)];
    }
    if (trailing._kind == _Trailing.value) {
      return [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: line / 2),
          child: end,
        ),
      ];
    }
    return [end];
  }

  Widget? _leading() {
    final bool? checked = isChecked;
    if (checked != null) {
      return ExcludeSemantics(child: MxSelectionCheckbox(isChecked: checked));
    }
    final IconData? glyph = icon;
    if (glyph == null) {
      return null;
    }
    return MxIconTile(icon: glyph, tone: iconTone);
  }

  Widget? _trailing(BuildContext context) {
    final ColorScheme colors = context.colors;
    return switch (trailing._kind) {
      _Trailing.none || _Trailing.iconButton => null,
      _Trailing.chevron => ExcludeSemantics(
        child: Icon(
          Icons.chevron_right,
          size: AppIconSize.large,
          color: colors.onSurfaceVariant,
        ),
      ),
      _Trailing.badge => MxBadge(label: trailing._text!, tone: trailing._tone),
      _Trailing.value => Text(
        trailing._text!,
        textAlign: TextAlign.end,
        style: context.texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
      ),
    };
  }
}
