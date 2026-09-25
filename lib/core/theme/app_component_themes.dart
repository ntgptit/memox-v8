import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The Material component themes (spec UI base §4.6): the V3 defaults a raw
/// Material widget, or one the framework builds, picks up. A MemoX variant
/// richer than a Material theme can express stays in its `Mx*` widget, which
/// reads these defaults and overrides only what differs.
abstract final class AppComponentThemes {
  /// A field's edge in [color]: hairline, radius 12, and no label gap —
  /// fields never float a label, and Material 3 would otherwise add the gap
  /// to each side of the text.
  static OutlineInputBorder fieldEdge(Color color) => OutlineInputBorder(
    gapPadding: 0,
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color, width: AppStroke.hairline),
  );

  /// Every form field (TextField contract): the muted fill that lightens on
  /// focus, a ghost edge, primary on focus, error in error, the 14 hint.
  static InputDecorationTheme fields(
    ColorScheme scheme,
    MxSemanticColors semantic,
    TextTheme texts,
  ) {
    final ghost = MxDerivedColors.resolve(scheme, semantic).ghostBorder;
    return InputDecorationTheme(
      filled: true,
      isDense: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grouped,
      ),
      hintStyle: MxTextStyles(texts, scheme).inputHint,
      border: fieldEdge(ghost),
      enabledBorder: fieldEdge(ghost),
      disabledBorder: fieldEdge(ghost),
      focusedBorder: fieldEdge(scheme.primary),
      errorBorder: fieldEdge(scheme.error),
      focusedErrorBorder: fieldEdge(scheme.error),
    );
  }

  /// A Material button at the regular V3 size in [fill] and [ink]: 48 tall,
  /// radius 12, gutter padding, the 14/600 label, the pressed overlay and
  /// the focus ring. A disabled one dims under the global 0.38 rule.
  static ButtonStyle _button(
    ColorScheme scheme,
    TextTheme texts, {
    required Color? fill,
    required Color ink,
    required BorderSide edge,
  }) {
    final style = appButtonStyle(
      fill: fill,
      ink: ink,
      edge: edge,
      focusColor: scheme.primary,
      height: AppSize.buttonRegular,
      radius: AppRadius.md,
      padding: AppSpacing.gutter,
      label: MxTextStyles(texts, scheme).buttonLabel,
    );
    Color? dimmed(Color? color) =>
        color?.withValues(alpha: color.a * AppOpacity.disabled);
    final dimmedEdge = edge == BorderSide.none
        ? edge
        : edge.copyWith(color: dimmed(edge.color));
    return style.copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? dimmedEdge
            : style.side?.resolve(states),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? dimmed(fill) : fill,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? dimmed(ink) : ink,
      ),
    );
  }

  /// FilledButton: the primary tone.
  static FilledButtonThemeData filledButtons(
    ColorScheme scheme,
    TextTheme texts,
  ) => FilledButtonThemeData(
    style: _button(
      scheme,
      texts,
      fill: scheme.primary,
      ink: scheme.onPrimary,
      edge: BorderSide.none,
    ),
  );

  /// OutlinedButton: the outline tone.
  static OutlinedButtonThemeData outlinedButtons(
    ColorScheme scheme,
    TextTheme texts,
  ) => OutlinedButtonThemeData(
    style: _button(
      scheme,
      texts,
      fill: null,
      ink: scheme.primary,
      edge: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
    ),
  );

  /// TextButton: primary ink, no fill — the framework's dialog actions.
  static TextButtonThemeData textButtons(ColorScheme scheme, TextTheme texts) =>
      TextButtonThemeData(
        style: _button(
          scheme,
          texts,
          fill: null,
          ink: scheme.primary,
          edge: BorderSide.none,
        ),
      );

  /// IconButton (IconButton contract): a 20 glyph in a 36 round ink box with
  /// a 48 touch area, the pressed overlay, and the focus ring on the
  /// circle's edge (ruling R5).
  static IconButtonThemeData iconButtons(ColorScheme scheme) =>
      IconButtonThemeData(
        style: ButtonStyle(
          iconSize: const WidgetStatePropertyAll(AppIconSize.compact),
          // A disabled one dims under the global 0.38 rule.
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: AppOpacity.disabled)
                : scheme.onSurface,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? scheme.onSurface.withValues(alpha: AppOpacity.pressed)
                : null,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: scheme.primary, width: AppStroke.focus)
                : null,
          ),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          fixedSize: const WidgetStatePropertyAll(
            Size.square(AppSize.iconButtonInk),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSize.iconButtonInk),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      );

  static Color _scrim(ColorScheme scheme) =>
      scheme.scrim.withValues(alpha: AppEffects.scrimOpacity);

  static const _sheetRadius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.xl),
  );

  /// Dialog (Dialog contract): the high container at radius 20, flat, over
  /// the 45% scrim, with the compact title and the dialog body.
  static DialogThemeData dialogs(ColorScheme scheme, TextTheme texts) {
    final styles = MxTextStyles(texts, scheme);
    return DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      barrierColor: _scrim(scheme),
      titleTextStyle: styles.compactTitle,
      contentTextStyle: styles.dialogBody,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.card,
        vertical: AppSpacing.section,
      ),
    );
  }

  /// BottomSheet (BottomSheet contract): the high container, top radius 20,
  /// flat, over the 45% scrim.
  static BottomSheetThemeData sheets(ColorScheme scheme) =>
      BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
        modalBarrierColor: _scrim(scheme),
      );

  /// SnackBar (Snackbar contract): the inverse surface, floating a gutter in,
  /// radius 12, the snackbar message style.
  static SnackBarThemeData snackbars(ColorScheme scheme, TextTheme texts) =>
      SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        // Even sides, so no direction is needed.
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        contentTextStyle: MxTextStyles(texts, scheme).snackbarMessage,
      );
}
