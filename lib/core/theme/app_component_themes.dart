import 'package:flutter/material.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// What one mode's component themes are built from. Light and dark each get
/// their own instance; no function here branches on the mode.
final class ThemeTokens {
  const ThemeTokens({
    required this.scheme,
    required this.mx,
    required this.texts,
    required this.accent,
    this.dimens = const AppDimens(),
  });

  /// The tokens of the theme in scope, for a widget that builds a component
  /// style the theme has no slot for.
  factory ThemeTokens.of(BuildContext context) => ThemeTokens(
    scheme: context.colors,
    mx: context.mxColors,
    texts: context.texts,
    accent: context.accentColor,
    dimens: context.dimens,
  );

  final ColorScheme scheme;
  final MxColorsExtension mx;
  final TextTheme texts;

  /// Icon and text colour of the accent (see `ThemeRules.accentColor`).
  final Color accent;
  final AppDimens dimens;

  OutlinedBorder get stadium => const StadiumBorder();

  BorderRadius radius(double value) => BorderRadius.circular(value);

  Color get scrim => scheme.scrim.withValues(alpha: dimens.opacityScrim);

  Color onSurfaceAt(double opacity) =>
      scheme.onSurface.withValues(alpha: opacity);
}

/// A Material button at the regular size in [fill] and [foreground]: 40 tall at
/// least (a wrapped label or a larger text scale grows it), full radius (or
/// the [shape] given),
/// [padding] on the sides (24 by default), the `labelLarge` label, an 18 glyph,
/// state layers and the focus ring. A focused one draws the ring in `primary`
/// 2 outside its container ([MxFocusRingBorder]), so it shows on a `primary`
/// fill too. A disabled one follows the Design System's disabled opacities.
/// `MxButton` builds its other tones from this too, so they never restyle a
/// button.
ButtonStyle buttonStyle(
  ThemeTokens t, {
  required Color? fill,
  required Color foreground,
  BorderSide? edge,
  double? padding,
  OutlinedBorder shape = const StadiumBorder(),
}) {
  final dimens = t.dimens;
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, dimens.sizeButton)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: padding ?? dimens.space24),
    ),
    iconSize: WidgetStatePropertyAll(dimens.sizeIconButton),
    shape: WidgetStateProperty.resolveWith(
      (states) => MxFocusRingBorder(
        base: shape,
        ring: states.contains(WidgetState.focused)
            ? BorderSide(color: t.scheme.primary, width: dimens.strokeFocus)
            : BorderSide.none,
        gap: dimens.strokeFocusGap,
      ),
    ),
    elevation: const WidgetStatePropertyAll(0),
    tapTargetSize: MaterialTapTargetSize.padded,
    textStyle: WidgetStatePropertyAll(t.texts.labelLarge),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? (fill == null
                ? null
                : t.onSurfaceAt(dimens.opacityDisabledContainer))
          : fill,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? t.onSurfaceAt(dimens.opacityDisabledContent)
          : foreground,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? t.onSurfaceAt(dimens.opacityDisabledContent)
          : foreground,
    ),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return foreground.withValues(alpha: dimens.opacityPressed);
      }
      if (states.contains(WidgetState.focused)) {
        return foreground.withValues(alpha: dimens.opacityFocus);
      }
      if (states.contains(WidgetState.hovered)) {
        return foreground.withValues(alpha: dimens.opacityHover);
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled) && edge != null) {
        return edge.copyWith(
          color: t.onSurfaceAt(dimens.opacityDisabledContainer),
        );
      }
      return edge;
    }),
  );
}

FilledButtonThemeData filledButtonTheme(ThemeTokens t) => FilledButtonThemeData(
  style: buttonStyle(t, fill: t.scheme.primary, foreground: t.scheme.onPrimary),
);

OutlinedButtonThemeData outlinedButtonTheme(ThemeTokens t) =>
    OutlinedButtonThemeData(
      style: buttonStyle(
        t,
        fill: null,
        foreground: t.accent,
        edge: BorderSide(
          color: t.scheme.outline,
          width: t.dimens.strokeHairline,
        ),
      ),
    );

TextButtonThemeData textButtonTheme(ThemeTokens t) => TextButtonThemeData(
  style: buttonStyle(
    t,
    fill: null,
    foreground: t.accent,
    padding: t.dimens.space12,
  ),
);

IconButtonThemeData iconButtonTheme(ThemeTokens t) {
  final dimens = t.dimens;
  return IconButtonThemeData(
    style: ButtonStyle(
      iconSize: WidgetStatePropertyAll(dimens.sizeIcon),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? t.onSurfaceAt(dimens.opacityDisabledContent)
            : t.scheme.onSurface,
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return t.onSurfaceAt(dimens.opacityPressed);
        }
        if (states.contains(WidgetState.focused)) {
          return t.onSurfaceAt(dimens.opacityFocus);
        }
        if (states.contains(WidgetState.hovered)) {
          return t.onSurfaceAt(dimens.opacityHover);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: t.scheme.primary, width: dimens.strokeFocus)
            : null,
      ),
      shape: const WidgetStatePropertyAll(CircleBorder()),
      fixedSize: WidgetStatePropertyAll(Size.square(dimens.sizeControl)),
      minimumSize: WidgetStatePropertyAll(Size.square(dimens.sizeControl)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    ),
  );
}

/// The Design System defines no shadow for the FAB; Material's own elevation
/// casts it, the same in light and dark (Material 3: 6, and 8 when hovered).
const double _fabElevation = 6;
const double _fabHoverElevation = 8;

/// The FAB as the Material 3 regular FAB: a 56 square, radius `radiusLg`,
/// elevation 6 resting and 8 hovered, an `onPrimary` 24 glyph on `primary`.
/// `MxFab` swaps the shape for one that also draws the focus ring, which this
/// theme cannot (a theme shape is not state-aware).
FloatingActionButtonThemeData floatingActionButtonTheme(ThemeTokens t) {
  final dimens = t.dimens;
  final onPrimary = t.scheme.onPrimary;
  return FloatingActionButtonThemeData(
    backgroundColor: t.scheme.primary,
    foregroundColor: onPrimary,
    hoverColor: onPrimary.withValues(alpha: dimens.opacityHover),
    focusColor: onPrimary.withValues(alpha: dimens.opacityFocus),
    splashColor: onPrimary.withValues(alpha: dimens.opacityPressed),
    elevation: _fabElevation,
    focusElevation: _fabElevation,
    highlightElevation: _fabElevation,
    hoverElevation: _fabHoverElevation,
    iconSize: dimens.sizeIcon,
    sizeConstraints: BoxConstraints.tightFor(
      width: dimens.sizeFab,
      height: dimens.sizeFab,
    ),
    shape: RoundedRectangleBorder(borderRadius: t.radius(dimens.radiusLg)),
  );
}

/// The Material 3 flat filter chip, read by every Mx chip (`chipButtonStyle`):
/// no fill and a `outlineVariant` hairline at rest, `secondaryContainer` with
/// no edge when selected, an 8 corner, `labelLarge`, an 18 glyph, 8 around the
/// chip and 8 around the label. `secondaryLabelStyle` and `checkmarkColor` are
/// the selected label and check. A disabled chip is the button style's.
ChipThemeData chipTheme(ThemeTokens t) => ChipThemeData(
  color: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? t.scheme.secondaryContainer
        : null,
  ),
  side: WidgetStateBorderSide.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? BorderSide.none
        : BorderSide(
            color: t.scheme.outlineVariant,
            width: t.dimens.strokeHairline,
          ),
  ),
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusSm)),
  showCheckmark: true,
  labelStyle: t.texts.labelLarge?.copyWith(color: t.scheme.onSurfaceVariant),
  secondaryLabelStyle: t.texts.labelLarge?.copyWith(
    color: t.scheme.onSecondaryContainer,
  ),
  checkmarkColor: t.scheme.onSecondaryContainer,
  iconTheme: IconThemeData(
    color: t.scheme.primary,
    size: t.dimens.sizeIconButton,
  ),
  padding: EdgeInsets.all(t.dimens.space8),
  labelPadding: EdgeInsets.symmetric(horizontal: t.dimens.space8),
);

/// The Material 3 switch (`MxToggle` is a `Switch`): a `primary` track with an
/// `onPrimary` handle when on; a `surfaceContainerHighest` track with a
/// `strokeControl` `outline` edge and an `outline` handle when off. A pressed,
/// hovered or focused handle takes `primaryContainer` (on) or
/// `onSurfaceVariant` (off). Disabled, the track is 12% and the off handle
/// 38%, the on handle `surface`; the switch dims itself. Size, handle radii
/// (16, 24, 28), the 40 state layer (primary or onSurface at the hover, pressed
/// and focus opacities) and the motion are Material's own M3 defaults.
SwitchThemeData switchTheme(ThemeTokens t) {
  final scheme = t.scheme;
  final dimens = t.dimens;
  final on = WidgetState.selected;
  final disabled = WidgetState.disabled;
  final engaged =
      WidgetState.pressed | WidgetState.hovered | WidgetState.focused;
  Color faint(Color color) =>
      color.withValues(alpha: dimens.opacityDisabledContainer);
  return SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    trackOutlineWidth: WidgetStatePropertyAll(dimens.strokeControl),
    thumbColor: WidgetStateProperty.fromMap({
      disabled & on: scheme.surface,
      disabled: t.onSurfaceAt(dimens.opacityDisabledContent),
      on & engaged: scheme.primaryContainer,
      on: scheme.onPrimary,
      engaged: scheme.onSurfaceVariant,
      WidgetState.any: scheme.outline,
    }),
    trackColor: WidgetStateProperty.fromMap({
      disabled & on: faint(scheme.onSurface),
      disabled: faint(scheme.surfaceContainerHighest),
      on: scheme.primary,
      WidgetState.any: scheme.surfaceContainerHighest,
    }),
    trackOutlineColor: WidgetStateProperty.fromMap({
      on: Colors.transparent,
      disabled & ~on: faint(scheme.onSurface),
      WidgetState.any: scheme.outline,
    }),
  );
}
