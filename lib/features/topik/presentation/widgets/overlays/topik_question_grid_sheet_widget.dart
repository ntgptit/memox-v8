import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// What the question grid closed with.
sealed class TopikGridPick {
  const TopikGridPick();
}

/// Go to question [no].
final class TopikGridQuestion extends TopikGridPick {
  const TopikGridQuestion(this.no);

  final int no;
}

/// Submit the attempt.
final class TopikGridSubmit extends TopikGridPick {
  const TopikGridSubmit();
}

/// Screen 37's question grid (detail file 37, critique F7): one cell per
/// question with its real number, and Submit at the foot. Null when
/// dismissed.
Future<TopikGridPick?> showTopikQuestionGrid(
  BuildContext context, {
  required List<int> questionNos,
  required Set<int> answered,
  required int current,
}) => showMxBottomSheet<TopikGridPick>(
  context,
  builder: (sheetContext) => TopikQuestionGridSheetWidget(
    questionNos: questionNos,
    answered: answered,
    current: current,
  ),
);

class TopikQuestionGridSheetWidget extends StatelessWidget {
  const TopikQuestionGridSheetWidget({
    super.key,
    required this.questionNos,
    required this.answered,
    required this.current,
  });

  final List<int> questionNos;
  final Set<int> answered;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxBottomSheet(
      title: l10n.topikQuestions,
      footer: MxSheetActions.single(
        label: l10n.topikSubmit,
        onPressed: () => Navigator.of(context).pop(const TopikGridSubmit()),
        isInSheet: true,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dimens.space24,
          0,
          dimens.space24,
          dimens.space16,
        ),
        // As many control-wide columns as fit, then the cells share the
        // row, so the grid fills the sheet edge to edge (impeccable after
        // 6b).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = dimens.space8;
            final columns = max(
              1,
              ((constraints.maxWidth + gap) / (dimens.sizeControl + gap))
                  .floor(),
            );
            final side = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final no in questionNos)
                  _GridCell(
                    no: no,
                    side: side,
                    isAnswered: answered.contains(no),
                    isCurrent: no == current,
                    onTap: () =>
                        Navigator.of(context).pop(TopikGridQuestion(no)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A question's cell: a square of [side]; answered in the accent tinted over
/// the sheet, blank with a hairline edge only, the current one with a primary
/// edge. One TalkBack node with its state, selected when current.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.no,
    required this.side,
    required this.isAnswered,
    required this.isCurrent,
    required this.onTap,
  });

  final int no;

  /// The cell's width and height: at least a control.
  final double side;
  final bool isAnswered;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final colors = context.colors;
    final radius = context.radii.sm;
    final accent = context.colors.primary;
    return MxRowInk(
      onTap: onTap,
      isSelected: isCurrent,
      borderRadius: radius,
      child: Semantics(
        label: isAnswered
            ? l10n.topikQuestionAnswered(no)
            : l10n.topikQuestionBlank(no),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Answered is a tinted ground; blank has no ground and a
              // hairline edge, as a chip at rest, so the two differ in both
              // modes (impeccable after 6b: two grounds read alike in dark).
              color: isAnswered
                  ? accent.tintOver(MxTintBase.of(context))
                  : null,
              borderRadius: radius,
              border: switch ((isCurrent, isAnswered)) {
                (true, _) => Border.all(
                  color: context.status.primaryInk,
                  width: dimens.strokeEmphasis,
                ),
                (false, false) => Border.all(
                  color: colors.border,
                  width: context.hairline,
                ),
                (false, true) => null,
              },
            ),
            child: Center(
              child: Text(
                '$no',
                style: context.texts.button.copyWith(
                  color: isAnswered
                      ? context.status.primaryInk
                      : colors.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
