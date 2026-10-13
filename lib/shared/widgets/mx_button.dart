import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// Colour role of a button: the contract's four shipped tones, the soft
/// danger tint of a grade that marks a lapse (screen 16a), the warning
/// fill of a merge (screen 05; FE-B2 spec D15), and the quiet `text` action
/// beside a decision's fill (account UI spec U2).
enum MxButtonTone {
  primary,
  secondary,
  outline,
  text,
  destructive,
  dangerSoft,
  warning,
}

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
    this.mark,
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
       ),
       assert(icon == null || mark == null, 'a glyph or a mark, not both');

  final String label;

  /// Null disables the button under the global 0.38 rule.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// Optional leading glyph, painted at 16.
  final IconData? icon;

  /// A brand's own mark in place of [icon], such as Google's G (account UI
  /// spec U6), painted at [AppIconSize.brandMark] and never read aloud: the
  /// label names the action.
  final ImageProvider? mark;
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
      hasIcon: icon != null || mark != null,
      isBlock: isBlock,
    );
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      autofocus: isAutofocused,
      style: appButtonStyle(
        fill: paint.fill,
        ink: paint.ink,
        edge: paint.edge,
        focusColor: context.accentColor,
        height: geometry.height,
        radius: geometry.radius,
        padding: geometry.padding,
        label: geometry.isSmallType
            ? context.texts.labelLarge
            : context.texts.labelLarge,
      ),
      child: _content(paint.ink, geometry, context.texts.labelMedium),
    );
    final sized = isBlock
        ? SizedBox(width: double.infinity, child: button)
        : button;
    if (onPressed != null) return sized;
    return Opacity(
      opacity: context.dimens.opacityDisabledContent,
      child: sized,
    );
  }

  /// The width this button needs to show its label on one line: the label at
  /// its style and the context's text scale, the icon and its gap, and the
  /// horizontal padding on both sides.
  double naturalWidth(BuildContext context) {
    final geometry = _geometryFor(
      size,
      hasIcon: icon != null || mark != null,
      isBlock: isBlock,
    );
    final style = geometry.isSmallType
        ? context.texts.labelLarge
        : context.texts.labelLarge;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final leadWidth = switch ((icon, mark)) {
      (_?, _) => context.dimens.sizeIconInline + context.dimens.space4,
      (_, _?) => AppIconSize.brandMark + context.dimens.space4,
      _ => 0.0,
    };
    final width = painter.width + leadWidth + geometry.padding * 2;
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
          color: context.colors.outlineVariant,
          width: context.dimens.strokeHairline,
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
        ink: context.accentColor,
        edge: BorderSide(
          color: context.colors.outline,
          width: context.dimens.strokeHairline,
        ),
      ),
      // The quiet action beside a decision's fill (account UI spec U2): the
      // outline's ink without its edge.
      MxButtonTone.text => (
        fill: null,
        ink: context.accentColor,
        edge: BorderSide.none,
      ),
      MxButtonTone.destructive => (
        fill: context.colors.error,
        ink: context.colors.onError,
        edge: BorderSide.none,
      ),
      // The soft danger tint MxInlineBanner and MxCard.isDanger draw
      // (FE-A6 D14); the solid pair above stays the destructive action's.
      MxButtonTone.dangerSoft => (
        fill: context.colors.error.tintOver(context.colors.surface),
        ink: colors.error,
        edge: BorderSide(
          color: context.colors.error,
          width: context.dimens.strokeHairline,
        ),
      ),
      // The warning role and its ink, not the kit's orange and white, which
      // is about 2.8:1 (FE-B2 spec D15).
      MxButtonTone.warning => (
        fill: context.mxColors.warningContainer,
        ink: context.mxColors.onWarningContainer,
        edge: BorderSide.none,
      ),
    };
  }

  static _Geometry _geometryFor(
    MxButtonSize size, {
    required bool hasIcon,
    required bool isBlock,
  }) => switch (size) {
    MxButtonSize.regular => (
      height: context.dimens.sizeButton,
      radius: context.dimens.radiusMd,
      padding: context.dimens.space16,
      isSmallType: false,
      canWrap: true,
    ),
    MxButtonSize.small => (
      height: context.dimens.sizeButtonSmall,
      radius: context.dimens.radiusMd,
      padding: hasIcon ? context.dimens.space16 : context.dimens.space12,
      isSmallType: false,
      canWrap: false,
    ),
    MxButtonSize.compact => (
      height: context.dimens.sizeButtonSmall,
      radius: context.dimens.radiusSm,
      padding: context.dimens.space12,
      isSmallType: true,
      canWrap: false,
    ),
    MxButtonSize.chip => (
      height: context.dimens.sizeChip,
      radius: AppRadius.full,
      padding: context.dimens.space8,
      isSmallType: true,
      canWrap: false,
    ),
    MxButtonSize.study => (
      height: context.dimens.sizeButton,
      radius: AppRadius.full,
      // The contract's 36 sizes a pill that hugs its label; a block
      // action is given its width by its row, and needs the room for
      // the label (FE-A6 P4: "Remembered" in a two-up row).
      padding: isBlock ? context.dimens.space16 : _studyPadding,
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
    final lead = _lead();
    final body = lead == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: context.dimens.space4,
            children: [
              lead,
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

  /// The glyph or the brand mark before the label, if any.
  Widget? _lead() {
    if (icon case final glyph?)
      return Icon(glyph, size: context.dimens.sizeIconInline);
    if (mark case final image?) {
      return Image(
        image: image,
        width: AppIconSize.brandMark,
        height: AppIconSize.brandMark,
        excludeFromSemantics: true,
      );
    }
    return null;
  }
}
