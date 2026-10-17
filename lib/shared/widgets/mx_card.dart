import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// The base surface: ForUI's [FCard], its card colour, border and radius.
/// The tones below change only the ground, or the edge for [isSelected].
class MxCard extends StatelessWidget {
  const MxCard({
    super.key,
    required this.child,
    this.isFullBleed = false,
    this.isCompact = false,
    this.isHero = false,
    this.isWarning = false,
    this.isSelected = false,
    this.isSuccess = false,
    this.isDanger = false,
    this.isRecessed = false,
  }) : assert(
         (isHero ? 1 : 0) +
                 (isWarning ? 1 : 0) +
                 (isSuccess ? 1 : 0) +
                 (isDanger ? 1 : 0) +
                 (isRecessed ? 1 : 0) <=
             1,
         'one tone at most',
       );

  final Widget child;

  /// No padding, for rows that run edge to edge. The card clips them to its
  /// radius, so their dividers meet the corners.
  final bool isFullBleed;

  /// The overview's tighter padding, `space16` instead of `space24`, so two
  /// cards fit side by side on a phone.
  final bool isCompact;

  /// The primary tint over the page.
  final bool isHero;

  /// The warning tint over the page (screen 02's locked strip, owner
  /// decision D-O1).
  final bool isWarning;

  /// A primary edge over the card's own ground: a picked row of a selection
  /// (screen 07).
  final bool isSelected;

  /// The success tint over the page: a finished session (FE-A6 D14).
  final bool isSuccess;

  /// The error tint over the page: a session stopped by an error
  /// (FE-A6 D14).
  final bool isDanger;

  /// The muted ground: the answer face of a study card (screen 16a).
  final bool isRecessed;

  /// The selected edge, twice the hairline so it reads as a state.
  static const double _selectedEdgeFactor = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final ground = switch ((
      isHero,
      isWarning,
      isSuccess,
      isDanger,
      isRecessed,
    )) {
      (true, _, _, _, _) => colors.primary.tintOver(MxTintBase.of(context)),
      (_, true, _, _, _) => context.status.warning.tintOver(
        MxTintBase.of(context),
      ),
      (_, _, true, _, _) => context.status.success.tintOver(
        MxTintBase.of(context),
      ),
      (_, _, _, true, _) => colors.error.tintOver(MxTintBase.of(context)),
      (_, _, _, _, true) => colors.muted,
      _ => colors.card,
    };
    final edge = isSelected
        ? BorderSide(
            color: colors.primary,
            width: context.hairline * _selectedEdgeFactor,
          )
        : BorderSide(color: colors.border, width: context.hairline);
    return SizedBox(
      width: double.infinity,
      child: FCard(
        clipBehavior: Clip.antiAlias,
        style: FCardStyleDelta.delta(
          decoration: DecorationDelta.shapeDelta(
            color: ground,
            shape: RoundedSuperellipseBorder(
              borderRadius: context.radii.lg,
              side: edge,
            ),
          ),
        ),
        // What the card holds is tinted over the card's own ground.
        child: MxTintBase(
          color: ground,
          child: Padding(
            padding: isFullBleed
                ? EdgeInsets.zero
                : EdgeInsets.all(isCompact ? dimens.space16 : dimens.space24),
            child: child,
          ),
        ),
      ),
    );
  }
}
