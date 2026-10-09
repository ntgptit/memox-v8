import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A toned, tappable surface of the round-based modes: a Guess option
/// (screen 18) or a Match tile (screen 17). Study-local, as the kit keeps
/// them: they speak session vocabulary. It is at least 48 tall, carries its
/// state in one semantics node, and fades when it is out of play.
class StudyChoiceWidget extends StatelessWidget {
  const StudyChoiceWidget({
    super.key,
    required this.tone,
    required this.builder,
    required this.semanticsLabel,
    this.padding = EdgeInsets.zero,
    this.isSelected = false,
    this.isFaded = false,
    this.isRecessed = false,
    this.sortKey,
    this.onTap,
  });

  /// What the outside focus ring needs around a choice (the gap and the
  /// stroke): the columns of choices leave it inside their viewport.
  static const double ringRoom = AppStroke.focusOffset + AppStroke.focus;

  final StudyChoiceTone tone;

  /// The content, drawn in the tone's ink.
  final Widget Function(Color ink) builder;

  /// What TalkBack reads: the content and its state.
  final String semanticsLabel;
  final EdgeInsetsGeometry padding;
  final bool isSelected;

  /// Out of play once the turn is answered (kit Guess).
  final bool isFaded;

  /// An idle tile on the recessed ground (Match's meanings).
  final bool isRecessed;

  /// Its place in TalkBack's reading order, when it is not the layout's.
  final SemanticsSortKey? sortKey;

  /// Null makes it inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.standard;
    // The tone eases in, surface and ink together, so the content never
    // sits on a surface it was not drawn for (Impeccable after P3). Not an
    // AnimatedContainer: it would inset the content by the border.
    final ink = AppDecorations.studyChoiceInk(colors, semantic, tone);
    // `Ink` paints the tone on the Material, under the ripple that MxRowInk's
    // InkWell lays on it. No tap, no focus: MxRowInk returns the child bare.
    final surface = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
      child: MxRowInk(
        onTap: onTap,
        placement: MxFocusRingPlacement.outside,
        inkRadius: BorderRadius.circular(AppRadius.md),
        child: TweenAnimationBuilder<Decoration>(
          tween: DecorationTween(
            end: AppDecorations.studyChoice(
              colors,
              semantic,
              tone,
              isRecessed: isRecessed,
            ),
          ),
          duration: motion,
          curve: Easing.standard,
          builder: (context, decoration, child) =>
              Ink(decoration: decoration, child: child),
          child: Padding(
            padding: padding,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: ink),
              duration: motion,
              curve: Easing.standard,
              builder: (context, color, _) => builder(color ?? ink),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      selected: isSelected,
      label: semanticsLabel,
      sortKey: sortKey,
      onTap: onTap,
      // One node for the choice: MxRowInk's own button node folds into it.
      excludeSemantics: true,
      // The fade eases in with the tones, at once under Remove animations.
      child: AnimatedOpacity(
        opacity: isFaded ? AppOpacity.muted : 1,
        duration: motion,
        child: surface,
      ),
    );
  }
}
