import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The one pinned action: ForUI's primary icon button as a square
/// `sizeFab` box with ForUI's shadow, icon only. [semanticLabel] is the
/// accessible name and the long-press tooltip, and is never painted.
/// Placement belongs to MxAppShell.
class MxFab extends StatelessWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final base = theme.buttonStyles.primary.resolve({
      context.platformVariant,
      FButtonSizeVariant.lg,
    });
    final size = context.dimens.sizeFab;
    return FTooltip(
      tipBuilder: (_, _) => Text(semanticLabel),
      child: FButton.icon(
        onPress: onPressed,
        semanticsLabel: semanticLabel,
        style: base.copyWith(
          decoration:
              FVariants<
                FTappableVariantConstraint,
                FTappableVariant,
                Decoration,
                DecorationDelta
              >.raw(_raised(base.decoration.base, theme), {
                for (final MapEntry(:key, :value)
                    in base.decoration.variants.entries)
                  key: _raised(value, theme),
              }),
          iconContentStyle: FButtonIconContentStyleDelta.delta(
            constraints: BoxConstraints.tightFor(width: size, height: size),
          ),
        ),
        child: Icon(icon),
      ),
    );
  }

  /// [decoration] with ForUI's shadow, which lifts it over the scroll.
  static Decoration _raised(Decoration decoration, FThemeData theme) =>
      switch (decoration) {
        ShapeDecoration() => DecorationDelta.shapeDelta(
          shadows: theme.style.shadow,
        )(decoration),
        _ => decoration,
      };
}
