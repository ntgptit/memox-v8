import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';

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
  // Flat: the inverse surface sets it apart; only cards, dialogs, sheets and
  // the FAB are raised (SW-REV-007).
  elevation: 0,
);

TooltipThemeData tooltipTheme(ThemeTokens t) => TooltipThemeData(
  decoration: BoxDecoration(
    color: t.scheme.inverseSurface,
    borderRadius: t.radius(t.dimens.radiusXs),
  ),
  textStyle: t.texts.bodySmall?.copyWith(color: t.scheme.onInverseSurface),
);
