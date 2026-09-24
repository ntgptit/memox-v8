import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// One destination in an MxDeckPickerSheet. It is generic: which decks are
/// eligible, and why, is the caller's (spec §5).
@immutable
final class MxPickerCandidate {
  const MxPickerCandidate({
    required this.label,
    required this.onTap,
    this.reason,
    this.icon = AppIcons.library,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onTap;

  /// Why an ineligible destination cannot take the payload, shown as its
  /// sub-line.
  final String? reason;
  final IconData icon;
  final bool isEnabled;
}

/// Choose the deck this goes to: deck move, card move, Trash restore. It owns
/// the head typography and the scroll region that keeps the footer in view,
/// and nothing about eligibility. An ineligible candidate stays visible,
/// dimmed, with its reason.
class MxDeckPickerSheet extends StatelessWidget {
  const MxDeckPickerSheet({
    super.key,
    required this.title,
    required this.rule,
    required this.candidates,
    required this.dismissLabel,
    required this.onDismiss,
    required this.emptyTitle,
    this.emptyBody,
  });

  final String title;

  /// The one sentence stating what travels and what is not offered.
  final String rule;
  final List<MxPickerCandidate> candidates;

  /// Cancel with targets; OK when there is nowhere to go (ruling O11).
  final String dismissLabel;
  final VoidCallback onDismiss;
  final String emptyTitle;
  final String? emptyBody;

  /// Ruling O11: the title → rule gap is UNSPECIFIED.
  static const double _ruleGap = 4;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final isEmpty = candidates.isEmpty;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _ruleGap,
          children: [
            Text(title, style: styles.compactTitle),
            Text(rule, style: styles.noteText),
          ],
        ),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: dismissLabel,
              onPressed: onDismiss,
              tone: isEmpty ? MxButtonTone.primary : MxButtonTone.outline,
              isBlock: true,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.control,
          end: AppSpacing.control,
          bottom: AppSpacing.control,
        ),
        child: isEmpty
            ? MxEmptyState(
                icon: AppIcons.folder,
                title: emptyTitle,
                body: emptyBody,
                tone: MxEmptyStateTone.neutral,
                isCompact: true,
              )
            : Column(
                children: [
                  for (final (index, candidate) in candidates.indexed)
                    MxListRow(
                      title: candidate.label,
                      subtitle: candidate.reason,
                      leading: MxIconTile(icon: candidate.icon),
                      hasChevron: true,
                      onTap: candidate.onTap,
                      isEnabled: candidate.isEnabled,
                      hasDivider: index < candidates.length - 1,
                    ),
                ],
              ),
      ),
    );
  }
}
