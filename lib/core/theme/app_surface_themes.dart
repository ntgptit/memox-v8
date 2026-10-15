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

/// Material 3's dialog elevation. Its shadow is not drawn (the theme's
/// shadow colour is transparent), as in Material 3.
const double _dialogElevation = 6;

/// Material 3's minimum dialog width.
const double _dialogMinWidth = 280;

/// Material 3's sheet elevation, for the resting and the modal sheet alike.
const double _sheetElevation = 1;

/// Material 3's drag handle: 32 wide and 4 tall.
const Size _dragHandleSize = Size(32, 4);

/// Material 3's plain tooltip height, the least it is.
const double _tooltipMinHeight = 24;

/// The share of the toast's width an action may take beside the message;
/// a wider one goes on its own line (Material 3, the SDK default).
const double _snackBarActionOverflowThreshold = 0.25;

/// Dialog: Material 3 text roles, 24 all round and a 280 minimum width. The
/// elevation is kept, the shadow transparent.
DialogThemeData dialogTheme(ThemeTokens t) => DialogThemeData(
  backgroundColor: t.scheme.surfaceContainerHigh,
  surfaceTintColor: Colors.transparent,
  shadowColor: Colors.transparent,
  elevation: _dialogElevation,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusXl)),
  barrierColor: t.scrim,
  titleTextStyle: t.texts.headlineSmall?.copyWith(color: t.scheme.onSurface),
  contentTextStyle: t.texts.bodyMedium?.copyWith(
    color: t.scheme.onSurfaceVariant,
  ),
  actionsPadding: EdgeInsets.fromLTRB(
    t.dimens.space24,
    0,
    t.dimens.space24,
    t.dimens.space24,
  ),
  constraints: const BoxConstraints(minWidth: _dialogMinWidth),
  insetPadding: EdgeInsets.symmetric(
    horizontal: t.dimens.space24,
    vertical: t.dimens.space24,
  ),
);

/// Sheet: the low container at elevation 1 with no drawn shadow, and
/// Material 3's drag handle.
BottomSheetThemeData bottomSheetTheme(ThemeTokens t) => BottomSheetThemeData(
  backgroundColor: t.scheme.surfaceContainerLow,
  modalBackgroundColor: t.scheme.surfaceContainerLow,
  surfaceTintColor: Colors.transparent,
  shadowColor: Colors.transparent,
  elevation: _sheetElevation,
  modalElevation: _sheetElevation,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(t.dimens.radiusXl),
    ),
  ),
  dragHandleColor: t.scheme.onSurfaceVariant,
  dragHandleSize: _dragHandleSize,
  modalBarrierColor: t.scrim,
);

SnackBarThemeData snackBarTheme(ThemeTokens t) => SnackBarThemeData(
  backgroundColor: t.scheme.inverseSurface,
  actionTextColor: t.scheme.inversePrimary,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: t.radius(t.dimens.radiusXs)),
  insetPadding: EdgeInsets.fromLTRB(
    t.dimens.marginScreen,
    0,
    t.dimens.marginScreen,
    t.dimens.marginScreen,
  ),
  contentTextStyle: t.texts.bodyMedium?.copyWith(
    color: t.scheme.onInverseSurface,
  ),
  actionOverflowThreshold: _snackBarActionOverflowThreshold,
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
  constraints: const BoxConstraints(minHeight: _tooltipMinHeight),
  padding: EdgeInsets.symmetric(
    horizontal: t.dimens.space8,
    vertical: t.dimens.space4,
  ),
);
