import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// Colour role of a button: ForUI's five variants, the soft danger tint of a
/// grade that marks a lapse (screen 16a), and the warning fill of a merge
/// (screen 05; FE-B2 spec D15).
enum MxButtonTone {
  primary,
  secondary,
  outline,
  text,
  destructive,
  dangerTint,
  warning,
}

/// Painted geometry. [regular] is ForUI's large touch button (48), [small]
/// its small one (40); [chip] is a 32 pill and [study] a regular button that
/// hugs its label. Every size keeps a 48 touch target.
enum MxButtonSize { regular, small, chip, study }

/// The one button contract, on ForUI's [FButton]: geometry comes from [size],
/// colours from [tone]. The caller owns placement and width; [isBlock] fills
/// the parent.
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

  /// Null disables the button.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// Optional leading glyph, at the button's icon size.
  final IconData? icon;

  /// A brand's own mark in place of [icon], such as Google's G (account UI
  /// spec U6), painted at [_brandMarkSize] and never read aloud: the
  /// label names the action.
  final ImageProvider? mark;
  final bool isBlock;

  /// Replaces the label with a spinner, keeps the width and blocks presses.
  /// A loading button keeps its resting paint, even when [onPressed] is null.
  final bool isLoading;

  /// Takes the focus when it first shows: the safe choice of a destructive
  /// dialog (BR-TRASH-011).
  final bool isAutofocused;

  /// A second line under the label, in the button foreground, such as the
  /// interval a grade gives (screen 16a). It grows the button instead of
  /// clipping.
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

  /// The size a brand's guidelines set for its mark beside a label.
  static const double _brandMarkSize = 18;

  /// A study action's side padding when it hugs its label.
  static const double _studyPadding = 36;

  @override
  Widget build(BuildContext context) {
    final style = _style(context);
    final canPress = onPressed != null && !isLoading;
    final button = FButton(
      onPress: canPress ? onPressed : null,
      style: style,
      autofocus: isAutofocused,
      semanticsLabel: semanticLabel,
      mainAxisSize: isBlock ? MainAxisSize.max : MainAxisSize.min,
      prefix: isLoading ? null : _lead(context),
      builder: (context, _, textStyle, _, _, child) =>
          Flexible(child: _label(context, textStyle)),
    );
    return isBlock ? SizedBox(width: double.infinity, child: button) : button;
  }

  /// The width this button needs to show its label on one line: the label as
  /// it is drawn (`drawnTextPainter`: the text scale, the system's bold
  /// text), the lead and its gap, and the horizontal padding on both sides.
  double naturalWidth(BuildContext context) {
    final content = _style(context).contentStyle;
    final painter = drawnTextPainter(
      context,
      label,
      style: content.textStyle.base,
      maxLines: 1,
    )..layout();
    final leadWidth = switch ((icon, mark)) {
      (_?, _) => (content.iconStyle.base.size ?? 0) + content.spacing,
      (_, _?) => _brandMarkSize + content.spacing,
      _ => 0.0,
    };
    final padding = content.padding.resolve(Directionality.of(context));
    final width = painter.width + leadWidth + padding.horizontal;
    painter.dispose();
    return width.ceilToDouble();
  }

  /// The resolved ForUI style of [tone] at [size], kept on a 48 touch target
  /// (mxTargetStyle); a loading button keeps its resting decoration.
  FButtonStyle _style(BuildContext context) {
    final theme = FTheme.of(context);
    final platform = context.platformVariant;
    final sizes = switch (tone) {
      MxButtonTone.primary => theme.buttonStyles.primary,
      MxButtonTone.secondary => theme.buttonStyles.secondary,
      MxButtonTone.outline => theme.buttonStyles.outline,
      MxButtonTone.text => theme.buttonStyles.ghost,
      MxButtonTone.destructive => theme.buttonStyles.destructive,
      MxButtonTone.dangerTint => _dangerTint(context, theme),
      MxButtonTone.warning => _filled(
        theme,
        context.status.warningFill,
        context.status.onWarningFill,
      ),
    };
    final base = sizes.resolve({
      platform,
      switch (size) {
        MxButtonSize.regular || MxButtonSize.study => FButtonSizeVariant.lg,
        MxButtonSize.small => FButtonSizeVariant.sm,
        MxButtonSize.chip => FButtonSizeVariant.xs,
      },
    });
    return mxTargetStyle(
      context,
      base,
      horizontal: size == MxButtonSize.study && !isBlock ? _studyPadding : null,
      isLoading: isLoading,
    );
  }

  /// The soft danger tint MxInlineBanner and MxCard.isDanger draw (FE-A6
  /// D14), with the danger edge: ForUI's destructive tint is the
  /// destructive action itself.
  static FButtonSizeStyles _dangerTint(BuildContext context, FThemeData theme) {
    final colors = theme.colors;
    final fill = colors.error.tintOver(MxTintBase.of(context));
    return FButtonSizeStyles.inherit(
      typography: theme.typography,
      style: theme.style,
      touch: true,
      decoration: (radius) => _decorated(
        colors,
        fill,
        radius,
        BorderSide(color: colors.error, width: theme.style.borderWidth),
      ),
      foregroundColor: colors.error,
      disabledForegroundColor: colors.disable(colors.error),
    );
  }

  /// A solid fill in [fill] with [foreground] on it, in ForUI's button
  /// states: the warning merge (FE-B2 spec D15).
  static FButtonSizeStyles _filled(
    FThemeData theme,
    Color fill,
    Color foreground,
  ) => FButtonSizeStyles.inherit(
    typography: theme.typography,
    style: theme.style,
    touch: true,
    decoration: (radius) =>
        _decorated(theme.colors, fill, radius, BorderSide.none),
    foregroundColor: foreground,
    disabledForegroundColor: theme.colors.disable(foreground),
  );

  static FVariants<
    FTappableVariantConstraint,
    FTappableVariant,
    Decoration,
    DecorationDelta
  >
  _decorated(
    FColors colors,
    Color fill,
    BorderRadiusGeometry radius,
    BorderSide side,
  ) => FVariants.from(
    ShapeDecoration(
      shape: RoundedSuperellipseBorder(borderRadius: radius, side: side),
      color: fill,
    ),
    variants: {
      [FTappableVariant.hovered, FTappableVariant.pressed]:
          DecorationDelta.shapeDelta(color: colors.hover(fill)),
      [FTappableVariant.disabled]: DecorationDelta.shapeDelta(
        color: colors.disable(fill),
      ),
    },
  );

  Widget? _lead(BuildContext context) {
    if (icon case final glyph?) return Icon(glyph);
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

  /// The label, the detail line under it, or, while loading, a spinner over
  /// the hidden label that holds the width the button already had.
  Widget _label(BuildContext context, TextStyle textStyle) {
    final canWrap =
        !isSingleLine &&
        (size == MxButtonSize.regular || size == MxButtonSize.study);
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: canWrap ? _maxWrappedLines : 1,
      softWrap: canWrap,
      overflow: TextOverflow.ellipsis,
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
                style: context.texts.label.copyWith(color: textStyle.color),
              ),
            ],
          );
    if (!isLoading) return text;
    final lead = _lead(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(
          visible: false,
          child: lead == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: context.dimens.space8,
                  children: [
                    lead,
                    Flexible(child: text),
                  ],
                ),
        ),
        // The label's own foreground: the spinner replaces the label, so it
        // is as legible on this fill as the label is (M3F-02).
        MxSpinner(color: textStyle.color),
      ],
    );
  }
}
