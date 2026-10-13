import 'package:flutter/material.dart';
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

/// Card: tonal surface, no border, no shadow.
CardThemeData cardTheme(ThemeTokens t) => CardThemeData(
  color: t.mx.cardSurface,
  surfaceTintColor: Colors.transparent,
  shadowColor: Colors.transparent,
  elevation: 0,
  margin: EdgeInsets.zero,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusMd)),
);

SearchBarThemeData searchBarTheme(ThemeTokens t) {
  final hint = t.texts.labelMedium?.copyWith(color: t.scheme.onSurfaceVariant);
  return SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(t.mx.searchSurface),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(t.stadium),
    constraints: BoxConstraints(minHeight: t.dimens.sizeSearch),
    hintStyle: WidgetStatePropertyAll(hint),
    textStyle: WidgetStatePropertyAll(
      t.texts.labelMedium?.copyWith(color: t.scheme.onSurface),
    ),
  );
}

DividerThemeData dividerTheme(ThemeTokens t) => DividerThemeData(
  color: t.mx.divider,
  thickness: t.dimens.strokeHairline,
  space: t.dimens.strokeHairline,
);

/// A field's edge in [color] at [width]; no label gap, because fields never
/// float a label and Material 3 would otherwise add the gap to each side.
OutlineInputBorder fieldEdge(ThemeTokens t, Color color, {double? width}) =>
    OutlineInputBorder(
      gapPadding: 0,
      borderRadius: t.radius(t.dimens.radiusMd),
      borderSide: BorderSide(
        color: color,
        width: width ?? t.dimens.strokeHairline,
      ),
    );

InputDecorationTheme inputDecorationTheme(ThemeTokens t) {
  final scheme = t.scheme;
  return InputDecorationTheme(
    filled: true,
    isDense: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerLow,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: t.dimens.space12),
    hintStyle: t.texts.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    border: fieldEdge(t, scheme.outline),
    enabledBorder: fieldEdge(t, scheme.outline),
    disabledBorder: fieldEdge(t, scheme.outlineVariant),
    focusedBorder: fieldEdge(t, scheme.primary, width: t.dimens.strokeFocus),
    errorBorder: fieldEdge(t, scheme.error),
    focusedErrorBorder: fieldEdge(t, scheme.error, width: t.dimens.strokeFocus),
  );
}

/// A Material button at the regular size in [fill] and [foreground]: 40 tall at
/// least (a wrapped label or a larger text scale grows it), full radius, 24
/// side padding, the `labelLarge` label, state layers and the focus ring. A
/// disabled one follows the Design System's disabled opacities. `MxButton`
/// builds its other tones from this too, so they never restyle a button.
ButtonStyle buttonStyle(
  ThemeTokens t, {
  required Color? fill,
  required Color foreground,
  BorderSide? edge,
}) {
  final dimens = t.dimens;
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, dimens.sizeButton)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: dimens.space24),
    ),
    shape: WidgetStatePropertyAll(t.stadium),
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
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: t.scheme.primary, width: dimens.strokeFocus);
      }
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
  style: buttonStyle(t, fill: null, foreground: t.accent),
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

NavigationBarThemeData navigationBarTheme(ThemeTokens t) {
  final scheme = t.scheme;
  return NavigationBarThemeData(
    height: t.dimens.sizeNav,
    backgroundColor: scheme.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    indicatorColor: scheme.secondaryContainer,
    indicatorShape: t.stadium,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: t.dimens.sizeIcon,
        color: states.contains(WidgetState.selected)
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => t.texts.labelSmall?.copyWith(
        color: states.contains(WidgetState.selected)
            ? scheme.onSurface
            : scheme.onSurfaceVariant,
      ),
    ),
  );
}

NavigationRailThemeData navigationRailTheme(ThemeTokens t) {
  final scheme = t.scheme;
  return NavigationRailThemeData(
    minWidth: t.dimens.sizeRail,
    backgroundColor: scheme.surface,
    elevation: 0,
    indicatorColor: scheme.secondaryContainer,
    indicatorShape: t.stadium,
    selectedIconTheme: IconThemeData(
      size: t.dimens.sizeIcon,
      color: scheme.onSecondaryContainer,
    ),
    unselectedIconTheme: IconThemeData(
      size: t.dimens.sizeIcon,
      color: scheme.onSurfaceVariant,
    ),
    selectedLabelTextStyle: t.texts.labelSmall?.copyWith(
      color: scheme.onSurface,
    ),
    unselectedLabelTextStyle: t.texts.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
  );
}

ProgressIndicatorThemeData progressIndicatorTheme(ThemeTokens t) =>
    ProgressIndicatorThemeData(
      color: t.mx.successContainer,
      linearTrackColor: t.scheme.surfaceContainerHighest,
      circularTrackColor: t.scheme.surfaceContainerHighest,
      linearMinHeight: t.dimens.sizeTrack,
      borderRadius: t.radius(t.dimens.sizeTrack / 2),
    );

/// Neutral chip: `secondaryContainer` with `onSecondaryContainer`.
ChipThemeData chipTheme(ThemeTokens t) => ChipThemeData(
  backgroundColor: t.scheme.secondaryContainer,
  selectedColor: t.scheme.secondaryContainer,
  side: BorderSide.none,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusSm)),
  labelStyle: t.texts.labelMedium?.copyWith(
    color: t.scheme.onSecondaryContainer,
  ),
  iconTheme: IconThemeData(color: t.scheme.onSecondaryContainer),
);

DialogThemeData dialogTheme(ThemeTokens t) => DialogThemeData(
  backgroundColor: t.scheme.surfaceContainerHigh,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusXl)),
  barrierColor: t.scrim,
  titleTextStyle: t.texts.titleSmall?.copyWith(color: t.scheme.onSurface),
  contentTextStyle: t.texts.bodyMedium?.copyWith(
    color: t.scheme.onSurfaceVariant,
  ),
  insetPadding: EdgeInsets.symmetric(
    horizontal: t.dimens.space24,
    vertical: t.dimens.space24,
  ),
);

BottomSheetThemeData bottomSheetTheme(ThemeTokens t) => BottomSheetThemeData(
  backgroundColor: t.scheme.surfaceContainerHigh,
  modalBackgroundColor: t.scheme.surfaceContainerHigh,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  modalElevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(t.dimens.radiusXl),
    ),
  ),
  modalBarrierColor: t.scrim,
);

SnackBarThemeData snackBarTheme(ThemeTokens t) => SnackBarThemeData(
  backgroundColor: t.scheme.inverseSurface,
  actionTextColor: t.scheme.inversePrimary,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusMd)),
  insetPadding: EdgeInsets.fromLTRB(
    t.dimens.marginScreen,
    0,
    t.dimens.marginScreen,
    t.dimens.marginScreen,
  ),
  contentTextStyle: t.texts.bodyMedium?.copyWith(
    color: t.scheme.onInverseSurface,
  ),
);

TooltipThemeData tooltipTheme(ThemeTokens t) => TooltipThemeData(
  decoration: BoxDecoration(
    color: t.scheme.inverseSurface,
    borderRadius: t.radius(t.dimens.radiusXs),
  ),
  textStyle: t.texts.bodySmall?.copyWith(color: t.scheme.onInverseSurface),
);
