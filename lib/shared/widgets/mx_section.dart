import 'package:flutter/widgets.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The structural unit of Settings and Reminder: an overline, a card that
/// holds a group of rows, and an optional note under it. It keeps its own 16
/// below the block (ruling S9).
class MxSection extends StatelessWidget {
  const MxSection({super.key, this.title, required this.children, this.note});

  final String? title;

  /// The rows. They sit in an `MxDividedColumn` (ruling S8, DEV-305), so a
  /// row here carries no edge of its own.
  final List<Widget> children;

  /// A product rule under the card, drawn as an MxNote.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final text?) MxListSectionHeader(label: text),
          MxCard(isFullBleed: true, child: MxDividedColumn(children: children)),
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
