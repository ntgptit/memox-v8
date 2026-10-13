import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
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
  dangerTint,
  warning,
}

/// Painted geometry. The Design System has two button sizes, [regular] (40) and
/// [small] (32); [chip] and [study] are this app's variants. The touch area is
/// 48 for every size.
enum MxButtonSize { regular, small, chip, study }

typedef _Paint = ({Color? fill, Color foreground, BorderSide edge});
typedef _Geometry = ({double height, double padding, bool canWrap});

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
    this.semanticLabel,
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
  /// spec U6), painted at [_brandMarkSize] and never read aloud: the
  /// label names the action.
  final ImageProvider? mark;
  final bool isBlock;

  /// Replaces the label with a spinner, keeps the width and blocks presses.
  /// A loading button is never dimmed, even when [onPressed] is null.
  final bool isLoading;

  /// Takes the focus when it first shows: the safe choice of a destructive
  /// dialog (BR-TRASH-011).
  final bool isAutofocused;

  /// A second line under the label, in the button foreground, such as the interval
  /// a grade gives (screen 16a). It grows the button instead of clipping.
  final String? detail;

  /// What TalkBack reads in place of [label], when the painted label alone
  /// does not say it (the reminder's bare time). The button keeps its tap
  /// and its enabled state on that one node (SW-REV-005).
  final String? semanticLabel;

  /// Keeps the label on one line whatever the size: a caller that has
  /// checked [naturalWidth] (MxActionPair) never lets it wrap.
  final bool isSingleLine;

  /// A caller-constrained label wraps to at most this many lines.
  static const int _maxWrappedLines = 2;

  /// Study action horizontal padding (contract: 0 36).
  static const double _studyPadding = 36;

  /// The size a brand's guidelines set for its mark beside a label.
  static const double _brandMarkSize = 18;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final paint = _paintFor(context);
    final geometry = _geometryFor(
      tokens.dimens,
      hasIcon: icon != null || mark != null,
    );
    final base = buttonStyle(
      tokens,
      fill: paint.fill,
      foreground: paint.foreground,
      edge: paint.edge.style == BorderStyle.none ? null : paint.edge,
    );
    final style = base.copyWith(
      minimumSize: WidgetStatePropertyAll(Size(0, geometry.height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: geometry.padding),
      ),
      // A loading button keeps its colours; only its presses are blocked.
      backgroundColor: isLoading ? WidgetStatePropertyAll(paint.fill) : null,
      foregroundColor: isLoading
          ? WidgetStatePropertyAll(paint.foreground)
          : null,
    );
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      autofocus: isAutofocused,
      style: style,
      child: _content(context, paint.foreground, geometry),
    );
    final block = isBlock
        ? SizedBox(width: double.infinity, child: button)
        : button;
    final label = semanticLabel;
    if (label == null) return block;
    // Its own node: without one, the label melts into the row's and its
    // siblings' (as the reminder's time did; SW-REV-005).
    final canPress = onPressed != null && !isLoading;
    return Semantics(
      container: true,
      label: label,
      button: true,
      enabled: canPress,
      onTap: canPress ? onPressed : null,
      excludeSemantics: true,
      child: block,
    );
  }

  /// The width this button needs to show its label on one line: the label at
  /// its style and the context's text scale, the icon and its gap, and the
  /// horizontal padding on both sides.
  double naturalWidth(BuildContext context) {
    final geometry = _geometryFor(
      context.dimens,
      hasIcon: icon != null || mark != null,
    );
    final painter = TextPainter(
      text: TextSpan(text: label, style: context.texts.labelLarge),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final leadWidth = switch ((icon, mark)) {
      (_?, _) => context.dimens.sizeIconInline + context.dimens.space4,
      (_, _?) => _brandMarkSize + context.dimens.space4,
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
        foreground: colors.onSurface,
        edge: BorderSide(
          color: context.colors.outlineVariant,
          width: context.dimens.strokeHairline,
        ),
      );
    }
    return switch (tone) {
      MxButtonTone.primary => (
        fill: colors.primary,
        foreground: colors.onPrimary,
        edge: BorderSide.none,
      ),
      MxButtonTone.secondary => (
        fill: colors.surfaceContainer,
        foreground: colors.onSurface,
        edge: BorderSide.none,
      ),
      MxButtonTone.outline => (
        fill: null,
        foreground: context.accentColor,
        edge: BorderSide(
          color: colors.outline,
          width: context.dimens.strokeHairline,
        ),
      ),
      // The quiet action beside a decision's fill (account UI spec U2): the
      // outline's foreground without its edge.
      MxButtonTone.text => (
        fill: null,
        foreground: context.accentColor,
        edge: BorderSide.none,
      ),
      MxButtonTone.destructive => (
        fill: context.colors.error,
        foreground: context.colors.onError,
        edge: BorderSide.none,
      ),
      // The soft danger tint MxInlineBanner and MxCard.isDanger draw
      // (FE-A6 D14); the solid pair above stays the destructive action's.
      MxButtonTone.dangerTint => (
        fill: context.colors.error.tintOver(context.colors.surface),
        foreground: colors.error,
        edge: BorderSide(
          color: context.colors.error,
          width: context.dimens.strokeHairline,
        ),
      ),
      // The warning fill and the text on it (FE-B2 spec D15).
      MxButtonTone.warning => (
        fill: context.mxColors.warningContainer,
        foreground: context.mxColors.onWarningContainer,
        edge: BorderSide.none,
      ),
    };
  }

  _Geometry _geometryFor(AppDimens dimens, {required bool hasIcon}) =>
      switch (size) {
        MxButtonSize.regular => (
          height: dimens.sizeButton,
          padding: dimens.space24,
          canWrap: true,
        ),
        MxButtonSize.small => (
          height: dimens.sizeButtonSmall,
          padding: hasIcon ? dimens.space16 : dimens.space12,
          canWrap: false,
        ),
        MxButtonSize.chip => (
          height: dimens.sizeChip,
          padding: dimens.space8,
          canWrap: false,
        ),
        // The contract's 36 sizes a pill that hugs its label; a block
        // action is given its width by its row, and needs the room for
        // the label (FE-A6 P4: "Remembered" in a two-up row).
        MxButtonSize.study => (
          height: dimens.sizeButton,
          padding: isBlock ? dimens.space16 : _studyPadding,
          canWrap: false,
        ),
      };

  Widget _content(BuildContext context, Color foreground, _Geometry geometry) {
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
              Text(
                detail,
                textAlign: TextAlign.center,
                style: context.texts.labelMedium,
              ),
            ],
          );
    final lead = _lead(context);
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
  Widget? _lead(BuildContext context) {
    if (icon case final glyph?) {
      return Icon(glyph, size: context.dimens.sizeIconInline);
    }
    if (mark case final image?) {
      return Image(
        image: image,
        width: _brandMarkSize,
        height: _brandMarkSize,
        excludeFromSemantics: true,
      );
    }
    return null;
  }
}
