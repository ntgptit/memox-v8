import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// Colour role of a button: the contract's four shipped tones, and the soft
/// danger tint of a grade that marks a lapse (screen 16a).
enum MxButtonTone { primary, secondary, outline, destructive, dangerSoft }

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
    this.isAutofocused = false,
    this.isSingleLine = false,
    this.detail,
  }) : assert(
         detail == null ||
             size == MxButtonSize.regular ||
             size == MxButtonSize.small ||
             size == MxButtonSize.study,
         'a detail line needs a regular, small or study button',
       );

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

  /// Takes the focus when it first shows: the safe choice of a destructive
  /// dialog (BR-TRASH-011).
  final bool isAutofocused;

  /// A second line under the label, in the button ink, such as the interval
  /// a grade gives (screen 16a). It grows the button instead of clipping.
  final String? detail;

  /// Keeps the label on one line whatever the size: a caller that has
  /// checked [naturalWidth] (MxActionPair) never lets it wrap.
  final bool isSingleLine;

  /// A caller-constrained label wraps to at most this many lines.
  static const int _maxWrappedLines = 2;

  /// Study action horizontal padding (contract: 0 36).
  static const double _studyPadding = 36;

  @override
  Widget build(BuildContext context) {
    final paint = _paintFor(context);
    final geometry = _geometryFor(
      size,
      hasIcon: icon != null,
      isBlock: isBlock,
    );
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      autofocus: isAutofocused,
      style: appButtonStyle(
        fill: paint.fill,
        ink: paint.ink,
        edge: paint.edge,
        focusColor: context.colors.primary,
        height: geometry.height,
        radius: geometry.radius,
        padding: geometry.padding,
        label: geometry.isSmallType
            ? context.textStyles.buttonLabelSmall
            : context.textStyles.buttonLabel,
      ),
      child: _content(paint.ink, geometry, context.textStyles.buttonDetail),
    );
    final sized = isBlock
        ? SizedBox(width: double.infinity, child: button)
        : button;
    if (onPressed != null) return sized;
    return Opacity(opacity: AppOpacity.disabled, child: sized);
  }

  /// The width this button needs to show its label on one line: the label at
  /// its style and the context's text scale, the icon and its gap, and the
  /// horizontal padding on both sides.
  double naturalWidth(BuildContext context) {
    final geometry = _geometryFor(
      size,
      hasIcon: icon != null,
      isBlock: isBlock,
    );
    final style = geometry.isSmallType
        ? context.textStyles.buttonLabelSmall
        : context.textStyles.buttonLabel;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final iconWidth = icon == null ? 0 : AppIconSize.inline + AppSpacing.micro;
    final width = painter.width + iconWidth + geometry.padding * 2;
    painter.dispose();
    return width.ceilToDouble();
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
      // The soft danger tint MxInlineBanner and MxCard.isDanger draw
      // (FE-A6 D14); the solid pair above stays the destructive action's.
      MxButtonTone.dangerSoft => (
        fill: context.derivedColors.dangerSoft,
        ink: colors.error,
        edge: BorderSide(
          color: context.derivedColors.dangerBorder,
          width: AppStroke.hairline,
        ),
      ),
    };
  }

  static _Geometry _geometryFor(
    MxButtonSize size, {
    required bool hasIcon,
    required bool isBlock,
  }) => switch (size) {
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
      // The contract's 36 sizes a pill that hugs its label; a block
      // action is given its width by its row, and needs the room for
      // the label (FE-A6 P4: "Remembered" in a two-up row).
      padding: isBlock ? AppSpacing.gutter : _studyPadding,
      isSmallType: false,
      canWrap: false,
    ),
  };

  Widget _content(Color ink, _Geometry geometry, TextStyle detailStyle) {
    final canWrap = geometry.canWrap && !isSingleLine;
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: canWrap ? _maxWrappedLines : 1,
      softWrap: canWrap,
    );
    final detail = this.detail;
    final text = detail == null
        ? labelText
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelText,
              Text(detail, textAlign: TextAlign.center, style: detailStyle),
            ],
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
        // Ruling O2: onPrimary inside a filled button, primary on the rest.
        MxSpinner(
          isOnFill:
              tone == MxButtonTone.primary || tone == MxButtonTone.destructive,
        ),
      ],
    );
  }
}
