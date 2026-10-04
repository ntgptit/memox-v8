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
import 'package:memox/shared/widgets/mx_skeleton.dart';

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

  @override
  Widget build(BuildContext context) {
    final isEmpty = candidates.isEmpty;
    return MxBottomSheet(
      header: _PickerHead(title: title, rule: rule),
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

/// MxDeckPickerSheet while its candidates load: the same head over a
/// skeleton, so the title does not appear late (ruling M3-A5). The rule is
/// optional because some rules depend on the loaded targets.
class MxDeckPickerLoadingSheet extends StatelessWidget {
  const MxDeckPickerLoadingSheet({
    super.key,
    required this.title,
    this.rule,
    required this.semanticLabel,
    this.rows = _defaultRows,
  });

  final String title;
  final String? rule;

  /// What is loading, in the caller's copy.
  final String semanticLabel;
  final int rows;

  static const int _defaultRows = 3;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    header: _PickerHead(title: title, rule: rule),
    child: MxSkeletonList(semanticLabel: semanticLabel, rows: rows),
  );
}

/// The picker's head: the title and, when known, the rule under it.
class _PickerHead extends StatelessWidget {
  const _PickerHead({required this.title, this.rule});

  final String title;
  final String? rule;

  /// Ruling O11: the title → rule gap is UNSPECIFIED.
  static const double _ruleGap = 4;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Padding(
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
          if (rule case final text?) Text(text, style: styles.noteText),
        ],
      ),
    );
  }
}
