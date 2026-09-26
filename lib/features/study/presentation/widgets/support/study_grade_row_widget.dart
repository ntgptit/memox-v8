import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/study/presentation/states/interval_span_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Screen 16a's grades, Again · Hard · Good · Easy (sm2's supportedActions,
/// BR-STUDY-009), each with the interval it would give on a scheduled turn.
/// Again is tinted with the soft danger; the other three share the tonal
/// treatment, and the label always names the grade. At large text the row
/// becomes a 2 × 2 grid (16a). While a write runs it takes no tap
/// (BR-STUDY-004).
class StudyGradeRowWidget extends StatelessWidget {
  const StudyGradeRowWidget({
    super.key,
    required this.intervals,
    required this.isBusy,
    required this.onGrade,
  });

  /// Action → next interval in days; null on a turn without a preview.
  final Map<Object, int>? intervals;
  final bool isBusy;
  final ValueChanged<Sm2Action> onGrade;

  /// From this text scale on, four grades no longer fit one row.
  static const double _gridTextScale = 1.3;
  static const int _perGridRow = 2;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final action in Sm2Action.values)
        Expanded(child: _button(context, action)),
    ];
    final isGrid = MediaQuery.textScalerOf(context).scale(1) >= _gridTextScale;
    final layout = isGrid
        ? Column(
            spacing: AppSpacing.control,
            children: [
              Row(
                spacing: AppSpacing.control,
                children: buttons.sublist(0, _perGridRow),
              ),
              Row(
                spacing: AppSpacing.control,
                children: buttons.sublist(_perGridRow),
              ),
            ],
          )
        : Row(spacing: AppSpacing.control, children: buttons);
    return AbsorbPointer(absorbing: isBusy, child: layout);
  }

  Widget _button(BuildContext context, Sm2Action action) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final grade = l10n.studyGrade(action);
    final days = intervals?[action];
    final span = days == null ? null : intervalSpanOf(days);
    return Semantics(
      label: span == null
          ? grade
          : l10n.studyGradeNextIn(grade, l10n.studyIntervalLong(span, locale)),
      button: true,
      // The merged node keeps the tap the excluded button would offer.
      onTap: () => onGrade(action),
      excludeSemantics: true,
      child: MxButton(
        label: grade,
        detail: span == null ? null : l10n.studyIntervalShort(span, locale),
        tone: action == Sm2Action.again
            ? MxButtonTone.dangerSoft
            : MxButtonTone.secondary,
        isBlock: true,
        onPressed: () => onGrade(action),
      ),
    );
  }
}
