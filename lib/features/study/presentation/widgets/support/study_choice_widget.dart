import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

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
    this.sortKey,
    this.onTap,
  });

  final StudyChoiceTone tone;

  /// The content, drawn in the tone's ink.
  final Widget Function(Color ink) builder;

  /// What TalkBack reads: the content and its state.
  final String semanticsLabel;
  final EdgeInsetsGeometry padding;
  final bool isSelected;

  /// Out of play once the turn is answered (kit Guess).
  final bool isFaded;

  /// Its place in TalkBack's reading order, when it is not the layout's.
  final SemanticsSortKey? sortKey;

  /// Null makes it inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final derived = context.derivedColors;
    final surface = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
      child: DecoratedBox(
        decoration: AppDecorations.studyChoice(colors, derived, tone),
        child: Padding(
          padding: padding,
          child: builder(AppDecorations.studyChoiceInk(colors, derived, tone)),
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
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        // The fade eases in with the tones, at once under Remove animations.
        child: AnimatedOpacity(
          opacity: isFaded ? AppOpacity.disabled : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppDurations.standard,
          child: surface,
        ),
      ),
    );
  }
}
