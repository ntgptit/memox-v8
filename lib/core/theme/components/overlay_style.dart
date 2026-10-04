import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// The modal scrim: the scheme's `scrim` at 45% (DESIGN.md, Elevation).
Color mxScrim(ColorScheme colors) =>
    colors.scrim.withValues(alpha: AppOpacity.scrim);

/// A floating surface's ground: the Sheet Ground, `surface-container-high`.
Color mxOverlayGround(ColorScheme colors) => colors.surfaceContainerHigh;

/// The dialog slot, matching `MxDialog`: the sheet ground, r20, no tint and
/// no elevation (its shadow is the overlay shadow `MxDialog` paints).
DialogThemeData mxDialogTheme(ColorScheme colors, TextTheme texts) =>
    DialogThemeData(
      backgroundColor: mxOverlayGround(colors),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
      barrierColor: mxScrim(colors),
      titleTextStyle: texts.titleLarge,
      contentTextStyle: texts.bodyMedium?.apply(color: colors.onSurfaceVariant),
    );

/// The bottom-sheet slot, matching `MxBottomSheet`: the sheet ground, top
/// corners 20, the scrim, no Material drag handle (the sheet draws its own
/// grabber), at most 640 wide (Material 3).
BottomSheetThemeData mxBottomSheetTheme(ColorScheme colors) =>
    BottomSheetThemeData(
      backgroundColor: mxOverlayGround(colors),
      modalBackgroundColor: mxOverlayGround(colors),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: mxScrim(colors),
      showDragHandle: false,
      constraints: const BoxConstraints(maxWidth: AppSize.sheetMaxWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    );

/// The snackbar slot: the inverse surface, floating, r12, inset by the
/// gutter, its action in `inverse-primary`.
SnackBarThemeData mxSnackBarTheme(ColorScheme colors, TextTheme texts) =>
    SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.inverseSurface,
      contentTextStyle: texts.bodyMedium?.apply(color: colors.onInverseSurface),
      actionTextColor: colors.inversePrimary,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    );

/// The card slot, matching `MxCard`'s raised tone (its shadow and dark
/// hairline are painted by `MxCard`).
CardThemeData mxCardTheme(ColorScheme colors) => CardThemeData(
  color: colors.surfaceContainerLowest,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
  ),
);
