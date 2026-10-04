import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

export 'package:memox/core/theme/components/button_style.dart'
    show MxButtonSize, MxButtonTone;

/// A text-labelled action (DESIGN.md, Components › Actions). The caller picks
/// a tone and a size; colours, padding, radius and states belong here.
class MxButton extends StatelessWidget {
  const MxButton({
    required this.label,
    required this.onPressed,
    this.tone = MxButtonTone.primary,
    this.size = MxButtonSize.regular,
    this.icon,
    this.brandMark,
    this.detail,
    this.isLoading = false,
    super.key,
  });

  final String label;

  /// `null` disables the button, drawn at `AppOpacity.disabled`.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// A 16dp glyph before the label.
  final IconData? icon;

  /// An 18dp brand image in the glyph's place (Google's G), never read aloud.
  final ImageProvider? brandMark;

  /// A second, smaller line under a regular button's label.
  final String? detail;

  /// Swaps the label for a spinner at the same width and blocks taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = mxButtonStyle(
      colors: context.colors,
      semantic: context.semanticColors,
      texts: context.texts,
      tone: tone,
      size: size,
    );
    final bool isEnabled = onPressed != null;
    Widget content = _Content(
      label: label,
      size: size,
      icon: icon,
      brandMark: brandMark,
      detail: size == MxButtonSize.regular ? detail : null,
    );
    if (isLoading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            maintainSemantics: true,
            child: content,
          ),
          const MxSpinner(
            size: MxSpinnerSize.small,
            tone: MxSpinnerTone.inherit,
          ),
        ],
      );
    }
    // The ring hugs the painted button; the 48 hit area is the tap target's.
    final Widget button = MxTapTarget(
      child: MxFocusRing(
        borderRadius: BorderRadius.circular(size.radius),
        isOnInverse: tone == MxButtonTone.inverse,
        child: TextButton(
          style: style.copyWith(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      ),
    );
    if (isEnabled) {
      return button;
    }
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.size,
    this.icon,
    this.brandMark,
    this.detail,
  });

  final String label;
  final MxButtonSize size;
  final IconData? icon;
  final ImageProvider? brandMark;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final Widget? lead = _lead();
    Widget text = Text(
      label,
      maxLines: size.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    final String? line = detail;
    if (line != null) {
      text = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // The caption role without a colour, so the line takes the
            // button's content colour like the label does.
            style: AppTextStyles.caption,
          ),
        ],
      );
    }
    if (lead == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lead,
        const SizedBox(width: AppSpacing.control),
        Flexible(child: text),
      ],
    );
  }

  Widget? _lead() {
    final ImageProvider? mark = brandMark;
    if (mark != null) {
      return ExcludeSemantics(
        child: Image(
          image: mark,
          width: AppIconSize.mark,
          height: AppIconSize.mark,
        ),
      );
    }
    final IconData? glyph = icon;
    if (glyph == null) {
      return null;
    }
    return Icon(glyph);
  }
}
