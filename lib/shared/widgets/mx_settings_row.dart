import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// How a settings row reads at its end (DESIGN.md, MxSettingsRow).
enum MxSettingsRowKind {
  /// Opens a page: a chevron, mirrored in right-to-left text.
  navigation,

  /// Runs an action or opens a dialog: no chevron.
  action,

  /// A value that follows another setting: plain text at full contrast.
  value,

  /// On or off: the whole row is one switch.
  toggle,
}

/// One setting (DESIGN.md, MxSettingsRow): a lead `MxIconTile` (40) in
/// [iconTone], the label, an optional subtitle that says why, and its end
/// mark. The label wraps beside the end mark at any text scale. A disabled
/// row dims its tile, label and chevron, never the subtitle; the toggle draws
/// its own disabled state and is not dimmed again. 48 minimum, 16 across and
/// 12 down; one TalkBack node.
class MxSettingsRow extends StatelessWidget {
  const MxSettingsRow.navigation({
    required this.title,
    required this.icon,
    required VoidCallback this.onTap,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.navigation,
       value = null,
       isOn = false,
       onChanged = null;

  const MxSettingsRow.action({
    required this.title,
    required this.icon,
    required VoidCallback this.onTap,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.action,
       value = null,
       isOn = false,
       onChanged = null;

  const MxSettingsRow.value({
    required this.title,
    required this.icon,
    required String this.value,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    super.key,
  }) : kind = MxSettingsRowKind.value,
       onTap = null,
       isOn = false,
       onChanged = null,
       isEnabled = true;

  const MxSettingsRow.toggle({
    required this.title,
    required this.icon,
    required this.isOn,
    required this.onChanged,
    this.subtitle,
    this.iconTone = MxIconTileTone.tinted,
    this.isEnabled = true,
    super.key,
  }) : kind = MxSettingsRowKind.toggle,
       value = null,
       onTap = null;

  final MxSettingsRowKind kind;
  final String title;
  final String? subtitle;
  final IconData icon;
  final MxIconTileTone iconTone;
  final String? value;
  final VoidCallback? onTap;
  final bool isOn;
  final ValueChanged<bool>? onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final double emphasis = isEnabled ? 1 : AppOpacity.disabled;
    final VoidCallback? tap = _tap();
    final String? why = subtitle;
    final bool isToggle = kind == MxSettingsRowKind.toggle;
    Widget laidOut(double line) => Row(
      children: [
        Opacity(
          opacity: emphasis,
          child: MxIconTile(icon: icon, tone: iconTone),
        ),
        const SizedBox(width: AppSpacing.grouped),
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
              if (why != null)
                Text(
                  why,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.apply(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ..._end(context, emphasis, line),
      ],
    );
    // Only a capped trailing needs the line's width.
    final Widget facts = kind == MxSettingsRowKind.value
        ? LayoutBuilder(builder: (context, box) => laidOut(box.maxWidth))
        : laidOut(double.infinity);
    final Widget body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
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
    // One TalkBack node: a button, or the switch itself for a toggle row.
    return MergeSemantics(
      child: Semantics(
        button: tap != null && !isToggle,
        toggled: isToggle ? isOn : null,
        // A toggle that cannot change now reads disabled, as it draws.
        enabled: isToggle ? tap != null : isEnabled,
        child: pressable,
      ),
    );
  }

  VoidCallback? _tap() {
    if (!isEnabled) {
      return null;
    }
    final ValueChanged<bool>? change = onChanged;
    if (kind == MxSettingsRowKind.toggle && change != null) {
      return () => change(!isOn);
    }
    return onTap;
  }

  List<Widget> _end(BuildContext context, double emphasis, double line) {
    final ColorScheme colors = context.colors;
    final String? shown = value;
    return switch (kind) {
      MxSettingsRowKind.action => const <Widget>[],
      MxSettingsRowKind.navigation => [
        const SizedBox(width: AppSpacing.grouped),
        Opacity(
          opacity: emphasis,
          child: ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: AppIconSize.large,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
      MxSettingsRowKind.value => [
        const SizedBox(width: AppSpacing.grouped),
        // A value keeps its width up to half the line, so a long one wraps
        // there and the label keeps the rest.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: line / 2),
          child: Text(
            shown ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: context.texts.bodyMedium?.apply(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
      // The row is the switch: the toggle only draws, so it is one focus
      // stop and one TalkBack node with the row.
      MxSettingsRowKind.toggle => [
        const SizedBox(width: AppSpacing.grouped),
        ExcludeFocus(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: MxToggle(
                isOn: isOn,
                onChanged: isEnabled ? onChanged : null,
              ),
            ),
          ),
        ),
      ],
    };
  }
}
