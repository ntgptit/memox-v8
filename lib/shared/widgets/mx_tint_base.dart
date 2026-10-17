import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The surface directly beneath what it holds, the base a tint is laid over
/// (DESIGN.md, Tints): `role.tintOver(MxTintBase.of(context))`.
///
/// MxCard, MxBottomSheet and MxDialog set it to the ground they paint; on the
/// page, with none above, it is ForUI's `background`.
class MxTintBase extends InheritedWidget {
  const MxTintBase({super.key, required this.color, required super.child});

  /// The ground [child] sits on.
  final Color color;

  /// The ground under [context]: the nearest [MxTintBase], else `background`.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MxTintBase>()?.color ??
      context.colors.background;

  /// One tonal step off the ground under [context], for a bar drawn on it (a
  /// skeleton, a hidden study bar): `muted` on the page and on a card of the
  /// page's colour; on any other ground, where `muted` may be the ground
  /// itself, the stronger `border`.
  static Color stepOf(BuildContext context) {
    final colors = context.colors;
    final ground = of(context);
    if (ground == colors.background || ground == colors.card) {
      return colors.muted;
    }
    return colors.border;
  }

  @override
  bool updateShouldNotify(MxTintBase oldWidget) => color != oldWidget.color;
}
