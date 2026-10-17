import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';

/// A chip that acts on press and never reads as selected. By default the
/// ghost chip that opens a menu (sort, filters): ForUI's ghost chip
/// (mxChipStyle), no fill and no edge, which sets it apart from
/// MxFilterChip; the menu is the caller's. With [isGhost] false it is the
/// outline chip at rest (the card editor's removable tag).
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
    this.semanticLabel,
    this.isGhost = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The trailing glyph: chevron-down by default.
  final IconData icon;

  /// What TalkBack reads in place of [label]: the trigger's purpose and its
  /// current value ("Playback speed, 1x"), when the painted value alone does
  /// not say what it controls. The chip keeps its tap and its enabled state on
  /// that one node, as MxButton.semanticLabel does.
  final String? semanticLabel;

  /// False draws the outline chip at rest instead of the ghost chip.
  final bool isGhost;

  @override
  Widget build(BuildContext context) => FButton(
    onPress: onPressed,
    style: mxChipStyle(context, isGhost: isGhost),
    semanticsLabel: semanticLabel,
    mainAxisSize: MainAxisSize.min,
    // A label wider than the column ends in an ellipsis, as MxTagChip's does
    // (SW-REV-010).
    builder: (context, _, _, _, _, _) => Flexible(
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    suffix: Icon(icon),
  );
}
