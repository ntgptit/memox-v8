import 'package:flutter/material.dart';
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
      height: context.dimens.strokeHairline,
      child: ColoredBox(color: context.colors.outlineVariant),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
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
              padding: EdgeInsetsDirectional.only(
                start: context.dimens.space4,
                end: context.dimens.space4,
                top: context.dimens.space8,
              ),
              child: MxNote.hint(text: text),
            ),
        ],
      ),
    );
  }
}
