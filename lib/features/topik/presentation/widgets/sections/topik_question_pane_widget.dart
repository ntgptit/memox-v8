import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The current question (detail file 37, critique F3): "{no}. {stem}", then
/// its options ①–④ as choice tiles, idle or selected only. Nothing says
/// right or wrong before submit (BR-TOPIK-016, D15). [onPick] null holds
/// the options (submitting).
class TopikQuestionPaneWidget extends StatelessWidget {
  const TopikQuestionPaneWidget({
    super.key,
    required this.question,
    required this.selectedIdx,
    required this.onPick,
  });

  final TopikQuestion question;
  final int? selectedIdx;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxScreenScroll(
      children: [
        SizedBox(height: dimens.space16),
        Text(
          l10n.topikQuestionStem(question.no, question.stemKo),
          style: context.texts.bodyLarge,
        ),
        SizedBox(height: dimens.space16),
        for (final option in question.options) ...[
          _option(context, option),
          SizedBox(height: dimens.space8),
        ],
      ],
    );
  }

  Widget _option(BuildContext context, TopikOption option) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final isSelected = option.idx == selectedIdx;
    final pick = onPick;
    return MxChoiceTile(
      tone: isSelected ? MxChoiceTone.selected : MxChoiceTone.idle,
      isSelected: isSelected,
      semanticsLabel: l10n.topikOptionLabel(
        option.idx,
        option.textKo ?? l10n.topikPicture,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
      onTap: pick == null ? null : () => pick(option.idx),
      builder: (foreground) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: dimens.space8,
        children: [
          Text(
            [topikCircled(option.idx), ?option.textKo].join(' '),
            style: context.texts.bodyLarge?.copyWith(color: foreground),
          ),
          if (option.image case final image?)
            Image.asset(image, fit: BoxFit.contain, excludeFromSemantics: true),
        ],
      ),
    );
  }
}
