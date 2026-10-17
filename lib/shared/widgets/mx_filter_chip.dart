import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';

/// A selectable filter (All · Cards · Decks): ForUI's outline chip
/// (mxChipStyle), in ForUI's selected state with a leading check when
/// selected. Its selection is exposed as state, not only as a look, so
/// screen readers announce it. It never shrinks or wraps: MxChipRow scrolls
/// a row of them.
class MxFilterChip extends StatelessWidget {
  const MxFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool isSelected;

  /// Receives the flipped selection. Null disables the chip.
  final ValueChanged<bool>? onSelected;

  /// Shown after the label, lighter than it.
  final int? count;

  /// Optional leading glyph; a selected chip shows the check instead.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final leading = isSelected ? AppIcons.check : icon;
    final select = onSelected;
    return FButton(
      onPress: select == null ? null : () => select(!isSelected),
      style: mxChipStyle(context),
      selected: isSelected,
      mainAxisSize: MainAxisSize.min,
      prefix: switch (leading) {
        final glyph? => Icon(glyph),
        null => null,
      },
      // A label wider than the column ends in an ellipsis, as MxTagChip's
      // does (SW-REV-010).
      builder: (context, _, textStyle, _, _, _) => Flexible(
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      suffix: switch (count) {
        // The count keeps the label's foreground: a dimmed one falls under
        // 4.5:1, so the meta role alone makes it quieter (M3F-03).
        // The role's own colour would override the chip's ink, so the count
        // takes the ink the button gives its content.
        final value? => Builder(
          builder: (context) => Text(
            value.toString(),
            style: context.texts.meta.copyWith(
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
        ),
        null => null,
      },
    );
  }
}
