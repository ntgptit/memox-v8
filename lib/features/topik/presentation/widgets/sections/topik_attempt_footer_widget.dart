import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Screen 37's footer (critique F1):
/// - Previous is a glyph, so three actions fit 360 dp;
/// - "Questions" (outline) takes the room left and opens the grid;
/// - Next, which is Submit on the last question ([onNext] null), is the one
///   primary (The One Accent Rule).
///
/// While submitting, Submit spins and the rest is off (BR-TOPIK-014).
class TopikAttemptFooterWidget extends StatelessWidget {
  const TopikAttemptFooterWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onQuestions,
    required this.onSubmit,
    required this.isSubmitting,
  });

  /// Null on the first question.
  final VoidCallback? onPrevious;

  /// Null on the last question, where the primary action is Submit.
  final VoidCallback? onNext;
  final VoidCallback onQuestions;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = onNext;
    return MxFooterBar(
      child: Row(
        spacing: context.dimens.space8,
        children: [
          MxIconButton(
            icon: AppIcons.back,
            semanticLabel: l10n.topikPrevious,
            onPressed: isSubmitting ? null : onPrevious,
          ),
          Expanded(
            child: MxButton(
              label: l10n.topikQuestions,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: isSubmitting ? null : onQuestions,
            ),
          ),
          if (next == null)
            MxButton(
              label: l10n.topikSubmit,
              isLoading: isSubmitting,
              onPressed: onSubmit,
            )
          else
            MxButton(
              label: l10n.topikNext,
              onPressed: isSubmitting ? null : next,
            ),
        ],
      ),
    );
  }
}
