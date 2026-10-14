import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The surface directly beneath what it holds, the base a tint is laid over
/// (DESIGN.md Tint Rule): `role.tintOver(MxTintBase.of(context))`.
///
/// MxCard, MxBottomSheet and MxDialog set it to the ground they paint; on the
/// page, with none above, it is `surface`.
class MxTintBase extends InheritedWidget {
  const MxTintBase({super.key, required this.color, required super.child});

  /// The ground [child] sits on.
  final Color color;

  /// The ground under [context]: the nearest [MxTintBase], else `surface`.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MxTintBase>()?.color ??
      context.colors.surface;

  @override
  bool updateShouldNotify(MxTintBase oldWidget) => color != oldWidget.color;
}
