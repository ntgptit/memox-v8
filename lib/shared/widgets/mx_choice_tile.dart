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
class MxChoiceTile extends StatefulWidget {
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

  /// The content colour of [tone].
  static Color _foreground(BuildContext context, MxChoiceTone tone) =>
      switch (tone) {
        MxChoiceTone.idle => context.colors.foreground,
        MxChoiceTone.selected => context.colors.primaryForeground,
        MxChoiceTone.right => context.status.success,
        MxChoiceTone.wrong => context.colors.error,
      };

  /// The surface of [tone]: the card ground inside the `border` hairline at
  /// rest, the primary fill when picked, a tint of the answer's colour over
  /// the page with that colour's edge once answered.
  static BoxDecoration _decoration(
    BuildContext context,
    MxChoiceTone tone, {
    required bool isRecessed,
  }) {
    final colors = context.colors;
    final rest = isRecessed ? colors.muted : context.colors.card;
    // At rest the edge is the hairline: in light the card is the page
    // itself, so the edge is what shows a tile to tap (audit 2026-10-19, G1).
    // Every tone has an edge, so a tone eases in from it.
    final (Color fill, Color edge) = switch (tone) {
      MxChoiceTone.idle => (rest, colors.border),
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

  @override
  State<MxChoiceTile> createState() => _MxChoiceTileState();
}

/// A tone and ground.
typedef _Look = ({MxChoiceTone tone, bool isRecessed});

/// What a tile eases from: a look, or the point [t] of the way from [a] to
/// [b] when a tone changed mid-ease, so the ease starts from what is on
/// screen (final review F1). Both looks are read from the theme at each
/// frame.
typedef _From = ({_Look a, _Look b, double t});

class _MxChoiceTileState extends State<MxChoiceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ease = AnimationController(
    vsync: this,
    duration: Durations.short4,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ease,
    curve: Easing.standard,
  );
  late _From _from = _still(_look(widget));

  static _From _still(_Look look) => (a: look, b: look, t: 1);

  static _Look _look(MxChoiceTile tile) =>
      (tone: tile.tone, isRecessed: tile.isRecessed);

  @override
  void didUpdateWidget(MxChoiceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = _look(oldWidget);
    if (old == _look(widget)) return;
    // Only a tone or ground eases. Both ends are read from the theme at each
    // frame, so a theme change follows ForUI's own easing instead of being
    // eased again after it (follow-ups spec T1).
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = _still(old);
      _ease.value = 1;
      return;
    }
    // Mid-ease, what is on screen is the old target part of the way from
    // the earlier start; that start collapses to its nearer look, which is
    // exact after one change and close after more.
    final from = _from;
    final start = from.t < 0.5 ? from.a : from.b;
    _from = _ease.isAnimating
        ? (a: start, b: old, t: _curve.value)
        : _still(old);
    _ease.forward(from: 0);
  }

  @override
  void dispose() {
    _ease.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Durations.short4;
    // The tone eases in, surface and foreground together, so the content never
    // sits on a surface it was not drawn for (Impeccable after P3). Not an
    // AnimatedContainer: it would inset the content by the border.
    final surface = ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
          final from = _from;
          BoxDecoration decorationOf(_Look look) => MxChoiceTile._decoration(
            context,
            look.tone,
            isRecessed: look.isRecessed,
          );
          final decoration = BoxDecoration.lerp(
            BoxDecoration.lerp(
              decorationOf(from.a),
              decorationOf(from.b),
              from.t,
            ),
            decorationOf(_look(widget)),
            t,
          )!;
          final foreground = Color.lerp(
            Color.lerp(
              MxChoiceTile._foreground(context, from.a.tone),
              MxChoiceTile._foreground(context, from.b.tone),
              from.t,
            ),
            MxChoiceTile._foreground(context, widget.tone),
            t,
          )!;
          return DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: widget.padding,
              child: widget.builder(foreground),
            ),
          );
        },
      ),
    );
    return Semantics(
      container: true,
      button: widget.onTap != null,
      selected: widget.isSelected,
      label: widget.semanticsLabel,
      sortKey: widget.sortKey,
      onTap: widget.onTap,
      excludeSemantics: true,
      // Tab reaches the tile, Enter presses it and the theme's outline marks
      // it (DEV-391). Its own semantics node stays hidden under the one
      // above, which also carries the reading order.
      child: FTappable.static(
        onPress: widget.onTap,
        behavior: HitTestBehavior.opaque,
        focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
          borderRadius: context.radii.md,
        ),
        // The fade eases in with the tones, at once under Remove animations.
        child: AnimatedOpacity(
          opacity: widget.isFaded ? context.dimens.opacityMuted : 1,
          duration: motion,
          child: surface,
        ),
      ),
    );
  }
}
