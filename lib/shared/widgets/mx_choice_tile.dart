import 'package:flutter/material.dart' show Durations, Easing;
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// How a choice reads: untouched, picked, answered right or wrong.
enum MxChoiceTone { idle, selected, right, wrong }

/// A toned, tappable answer surface: a Guess option (screen 18), a Match
/// tile (screen 17), a TOPIK option (screen 37, idle and selected only,
/// BR-TOPIK-016). It is at least a control tall, carries its label and state
/// in one semantics node, and fades when it is out of play. Promoted from
/// the study feature when TOPIK became its second user (owner brief
/// 2026-10-15); its look did not change.
class MxChoiceTile extends StatelessWidget {
  const MxChoiceTile({
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

  final MxChoiceTone tone;

  /// The content, drawn in the tone's foreground.
  final Widget Function(Color foreground) builder;

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
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Durations.short4;
    // The tone eases in, surface and foreground together, so the content never
    // sits on a surface it was not drawn for (Impeccable after P3). Not an
    // AnimatedContainer: it would inset the content by the border.
    final foreground = _foreground(context);
    final surface = ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
      child: TweenAnimationBuilder<Decoration>(
        tween: DecorationTween(end: _decoration(context)),
        duration: motion,
        curve: Easing.standard,
        builder: (context, decoration, child) =>
            DecoratedBox(decoration: decoration, child: child),
        child: Padding(
          padding: padding,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: foreground),
            duration: motion,
            curve: Easing.standard,
            builder: (context, color, _) => builder(color ?? foreground),
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
      excludeSemantics: true,
      // Tab reaches the tile, Enter presses it and the theme's outline marks
      // it (DEV-391). Its own semantics node stays hidden under the one
      // above, which also carries the reading order.
      child: FTappable.static(
        onPress: onTap,
        behavior: HitTestBehavior.opaque,
        focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
          borderRadius: context.radii.md,
        ),
        // The fade eases in with the tones, at once under Remove animations.
        child: AnimatedOpacity(
          opacity: isFaded ? context.dimens.opacityMuted : 1,
          duration: motion,
          child: surface,
        ),
      ),
    );
  }

  /// The content colour of [tone].
  Color _foreground(BuildContext context) => switch (tone) {
    MxChoiceTone.idle => context.colors.foreground,
    MxChoiceTone.selected => context.colors.primaryForeground,
    MxChoiceTone.right => context.status.success,
    MxChoiceTone.wrong => context.colors.error,
  };

  /// The surface of [tone]: the card ground at rest, the primary fill when
  /// picked, a tint of the answer's colour over the page with that colour's
  /// edge once answered.
  BoxDecoration _decoration(BuildContext context) {
    final colors = context.colors;
    final rest = isRecessed ? colors.muted : context.colors.card;
    // At rest the edge is the fill itself, so the tone eases in without a
    // border appearing from nothing.
    final (Color fill, Color edge) = switch (tone) {
      MxChoiceTone.idle => (rest, rest),
      MxChoiceTone.selected => (colors.primary, colors.primary),
      MxChoiceTone.right => (
        context.status.success.tintOver(MxTintBase.of(context)),
        context.status.success,
      ),
      MxChoiceTone.wrong => (
        colors.error.tintOver(MxTintBase.of(context)),
        colors.error,
      ),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: context.radii.md,
      border: Border.all(color: edge, width: context.hairline),
    );
  }
}
