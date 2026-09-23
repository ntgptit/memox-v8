import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Colour role of a button: the contract's four shipped tones.
enum MxButtonTone { primary, secondary, outline, destructive }

/// Painted geometry. [chip] and [study] are the contract's geometry variants;
/// the touch area is 48 for every size.
enum MxButtonSize { regular, small, compact, chip, study }

typedef _Paint = ({Color? fill, Color ink, BorderSide edge});
typedef _Geometry = ({
  double height,
  double radius,
  double padding,
  bool isSmallType,
  bool canWrap,
});

/// The one button contract: height, radius, padding and label type come from
/// [size], colours from [tone]. The caller owns placement and width; [isBlock]
/// fills the parent.
class MxButton extends StatelessWidget {
  const MxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = MxButtonTone.primary,
    this.size = MxButtonSize.regular,
    this.icon,
    this.isBlock = false,
    this.isLoading = false,
  });

  final String label;

  /// Null disables the button under the global 0.38 rule.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// Optional leading glyph, painted at 16.
  final IconData? icon;
  final bool isBlock;

  /// Replaces the label with a spinner, keeps the width and blocks presses.
  final bool isLoading;

  /// A caller-constrained label wraps to at most this many lines.
  static const int _maxWrappedLines = 2;

  /// Study action horizontal padding (contract: 0 36).
  static const double _studyPadding = 36;

  @override
  Widget build(BuildContext context) {
    final paint = _paintFor(context);
    final geometry = _geometryFor(size, hasIcon: icon != null);
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      style: _style(context, paint, geometry),
      child: _content(paint.ink, geometry),
    );
    final sized = isBlock
        ? SizedBox(width: double.infinity, child: button)
        : button;
    if (onPressed != null) return sized;
    return Opacity(opacity: AppOpacity.disabled, child: sized);
  }

  _Paint _paintFor(BuildContext context) {
    final colors = context.colors;
    if (size == MxButtonSize.chip) {
      // Chip geometry paints its own surface whatever the tone (ruling R2).
      return (
        fill: colors.surfaceContainerLowest,
        ink: colors.onSurface,
        edge: BorderSide(
          color: context.derivedColors.ghostBorder,
          width: AppStroke.hairline,
        ),
      );
    }
    return switch (tone) {
      MxButtonTone.primary => (
        fill: colors.primary,
        ink: colors.onPrimary,
        edge: BorderSide.none,
      ),
      MxButtonTone.secondary => (
        fill: colors.surfaceContainer,
        ink: colors.onSurface,
        edge: BorderSide.none,
      ),
      MxButtonTone.outline => (
        fill: null,
        ink: colors.primary,
        edge: BorderSide(
          color: colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      MxButtonTone.destructive => (
        fill: context.semanticColors.errorFill,
        ink: context.semanticColors.onErrorFill,
        edge: BorderSide.none,
      ),
    };
  }

  static _Geometry _geometryFor(MxButtonSize size, {required bool hasIcon}) =>
      switch (size) {
        MxButtonSize.regular => (
          height: AppSize.buttonRegular,
          radius: AppRadius.md,
          padding: AppSpacing.gutter,
          isSmallType: false,
          canWrap: true,
        ),
        MxButtonSize.small => (
          height: AppSize.buttonSmall,
          radius: AppRadius.md,
          padding: hasIcon ? AppSpacing.gutter : AppSpacing.grouped,
          isSmallType: false,
          canWrap: false,
        ),
        MxButtonSize.compact => (
          height: AppSize.buttonCompact,
          radius: AppRadius.sm,
          padding: AppSpacing.grouped,
          isSmallType: true,
          canWrap: false,
        ),
        MxButtonSize.chip => (
          height: AppSize.chip,
          radius: AppRadius.full,
          padding: AppSpacing.control,
          isSmallType: true,
          canWrap: false,
        ),
        MxButtonSize.study => (
          height: AppSize.buttonRegular,
          radius: AppRadius.full,
          padding: _studyPadding,
          isSmallType: false,
          canWrap: false,
        ),
      };

  ButtonStyle _style(BuildContext context, _Paint paint, _Geometry geometry) {
    final focusRing = BorderSide(
      color: context.colors.primary,
      width: AppStroke.focus,
    );
    final textStyles = context.textStyles;
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(paint.fill),
      foregroundColor: WidgetStatePropertyAll(paint.ink),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? paint.ink.withValues(alpha: AppOpacity.pressed)
            : null,
      ),
      // Ruling R5: the focus ring sits on the control's own edge.
      side: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) ? focusRing : paint.edge,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(geometry.radius),
        ),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: geometry.padding),
      ),
      minimumSize: WidgetStatePropertyAll(Size(0, geometry.height)),
      tapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textStyle: WidgetStatePropertyAll(
        geometry.isSmallType
            ? textStyles.buttonLabelSmall
            : textStyles.buttonLabel,
      ),
    );
  }

  Widget _content(Color ink, _Geometry geometry) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: geometry.canWrap ? _maxWrappedLines : 1,
      softWrap: geometry.canWrap,
    );
    final body = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              Icon(icon, size: AppIconSize.inline),
              Flexible(child: text),
            ],
          );
    if (!isLoading) return body;

    // The hidden label holds the width the button already had.
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(visible: false, child: body),
        SizedBox.square(
          dimension: AppIconSize.inline,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.indicator,
            color: ink,
          ),
        ),
      ],
    );
  }
}
