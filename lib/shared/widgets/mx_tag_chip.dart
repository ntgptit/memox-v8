import 'package:flutter/widgets.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A tag as read-only metadata, in two densities: 22 on its own line, 18
/// inside a packed 12px metadata line. The removable chip in the card editor
/// is a different, interactive control.
class MxTagChip extends StatelessWidget {
  const MxTagChip({super.key, required this.label, this.isDense = false});

  final String label;
  final bool isDense;

  /// Minimums: text scaling grows the chip (ruling S11).
  static const double _height = 22;
  static const double _denseHeight = 18;

  /// A long tag must not push the row.
  static const double _maxWidth = 140;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _maxWidth),
    child: MxToneBadge(
      fill: context.colors.secondary,
      ink: context.colors.mutedForeground,
      minHeight: isDense ? _denseHeight : _height,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
