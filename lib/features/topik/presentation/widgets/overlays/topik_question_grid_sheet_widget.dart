import 'package:flutter/material.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
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
        child: Wrap(
          spacing: dimens.space8,
          runSpacing: dimens.space8,
          children: [
            for (final no in questionNos)
              _GridCell(
                no: no,
                isAnswered: answered.contains(no),
                isCurrent: no == current,
                onTap: () => Navigator.of(context).pop(TopikGridQuestion(no)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A question's cell: a control square; answered in the accent tinted over
/// the sheet, blank neutral, the current one with a primary edge. One
/// TalkBack node with its state, selected when current.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.no,
    required this.isAnswered,
    required this.isCurrent,
    required this.onTap,
  });

  final int no;
  final bool isAnswered;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final colors = context.colors;
    final radius = BorderRadius.circular(dimens.radiusSm);
    final accent = context.accentColor;
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
          dimension: dimens.sizeControl,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isAnswered
                  ? accent.tintOver(MxTintBase.of(context))
                  : colors.surfaceContainerHighest,
              borderRadius: radius,
              border: isCurrent
                  ? Border.all(
                      color: colors.primary,
                      width: dimens.strokeControl,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$no',
                style: context.texts.labelLarge?.copyWith(
                  color: isAnswered ? accent : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
