import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
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
}
