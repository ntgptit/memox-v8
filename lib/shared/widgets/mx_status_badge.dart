import 'package:flutter/widgets.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// The card lifecycle, in order.
enum MxCardStatus { newCard, learning, reviewing, mastered }

/// Names a card's lifecycle state; a Badge counts things. The status fixes
/// the colour. The caller passes the localized name (ruling S6), which the
/// bare dot uses as its semantics label.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.isDot = false,
  });

  final MxCardStatus status;
  final String label;

  /// The bare 8 indicator for dense card rows.
  final bool isDot;

  static const double _pillDot = 6;
  static const double _bareDot = 8;

  /// The dot sits closer to the start edge than the label to the end edge.
  static const double _startPadding = 6;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MxCardStatus.newCard => context.colors.mutedForeground,
      MxCardStatus.learning => context.status.warningFill,
      MxCardStatus.reviewing => context.status.primaryInk,
      MxCardStatus.mastered => context.status.successFill,
    };
    // The label reads in the status ink (AA); dot and fill keep the colour.
    final ink = switch (status) {
      MxCardStatus.newCard => context.colors.mutedForeground,
      MxCardStatus.learning => context.status.warning,
      MxCardStatus.reviewing => context.status.primaryInk,
      MxCardStatus.mastered => context.status.success,
    };
    if (isDot) {
      return Semantics(
        container: true,
        label: label,
        child: _Dot(color: color, size: _bareDot),
      );
    }
    return MxToneBadge(
      fill: color.tintOver(MxTintBase.of(context)),
      ink: ink,
      padding: EdgeInsetsDirectional.only(
        start: _startPadding,
        end: context.dimens.space8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.dimens.space4,
        children: [
          _Dot(color: color, size: _pillDot),
          Text(label, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      key: const ValueKey('mx-status-dot'),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
