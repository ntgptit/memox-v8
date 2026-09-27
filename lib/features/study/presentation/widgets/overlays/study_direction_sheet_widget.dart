import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// UC-STUDY-003: an sm2 review asks its direction once, here, before it
/// opens (BR-MODE-013, BR-MODE-017). Term first is chosen at first
/// (recommended). Start review answers the choice and closes the sheet;
/// closing it any other way answers null and writes nothing (BR-STUDY-020).
Future<DirectionChoice?> showStudyDirectionSheet(BuildContext context) =>
    showMxBottomSheet<DirectionChoice>(
      context,
      builder: (_) => const StudyDirectionSheetWidget(),
    );

class StudyDirectionSheetWidget extends StatefulWidget {
  const StudyDirectionSheetWidget({super.key});

  @override
  State<StudyDirectionSheetWidget> createState() =>
      _StudyDirectionSheetWidgetState();
}

class _StudyDirectionSheetWidgetState extends State<StudyDirectionSheetWidget> {
  var _choice = DirectionChoice.koreanToMeaning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const choices = DirectionChoice.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.studyDirectionTitle,
          style: context.textStyles.compactTitle,
        ),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.studyDirectionStart,
              icon: AppIcons.play,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(_choice),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, choice) in choices.indexed)
            MxOptionRow(
              title: _title(l10n, choice),
              description: _body(l10n, choice),
              isSelected: choice == _choice,
              onSelected: () => setState(() => _choice = choice),
              hasDivider: index < choices.length - 1,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.grouped,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            child: MxNote(text: l10n.studyDirectionNote),
          ),
        ],
      ),
    );
  }

  static String _title(AppLocalizations l10n, DirectionChoice choice) =>
      switch (choice) {
        DirectionChoice.koreanToMeaning => l10n.studyDirectionTermFirst,
        DirectionChoice.meaningToKorean => l10n.studyDirectionMeaningFirst,
        DirectionChoice.mixed => l10n.studyDirectionMixed,
      };

  static String _body(AppLocalizations l10n, DirectionChoice choice) =>
      switch (choice) {
        DirectionChoice.koreanToMeaning => l10n.studyDirectionTermFirstBody,
        DirectionChoice.meaningToKorean => l10n.studyDirectionMeaningFirstBody,
        DirectionChoice.mixed => l10n.studyDirectionMixedBody,
      };
}
