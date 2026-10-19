import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_donut.dart';

/// Screen 38's donut (detail file 38, critique S3): the correct answers of
/// the questions, a `success` arc on the `muted` track (as every track),
/// "{correct} / {total}" inside, drawn with `MxDonut`. A topik widget, not
/// MxMasteryDonut, which draws the mastery ramp. A caption under the figure says what it counts,
/// beside the score. Its row says the figures to TalkBack.
class TopikScoreDonutWidget extends StatelessWidget {
  const TopikScoreDonutWidget({
    super.key,
    required this.correct,
    required this.total,
  });

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return SizedBox.square(
      dimension: dimens.sizeControl * 2,
      child: MxDonut(
        fraction: total == 0 ? 0 : correct / total,
        track: context.colors.muted,
        arc: context.status.success,
        strokeWidth: dimens.space8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.topikOfTotal(correct, total),
              style: context.texts.sectionTitle,
            ),
            Text(
              context.l10n.topikCorrect,
              style: context.texts.meta.copyWith(
                color: context.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
