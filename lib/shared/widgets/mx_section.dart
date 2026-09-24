import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// The structural unit of Settings and Reminder: an overline, a card that
/// holds a group of rows, and an optional note under it. It keeps its own 16
/// below the block (ruling S9).
class MxSection extends StatelessWidget {
  const MxSection({super.key, this.title, required this.children, this.note});

  final String? title;

  /// The rows. The section draws the ghost dividers between them (ruling
  /// S8), so a row here carries none of its own.
  final List<Widget> children;

  /// A product rule under the card, drawn as an MxNote.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.derivedColors.ghostBorder),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final text?) MxListSectionHeader(label: text),
          MxCard(
            isFullBleed: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, row) in children.indexed) ...[
                  if (index > 0) divider,
                  row,
                ],
              ],
            ),
          ),
          if (note case final text?)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.micro,
                end: AppSpacing.micro,
                top: AppSpacing.control,
              ),
              child: MxNote(text: text),
            ),
        ],
      ),
    );
  }
}
