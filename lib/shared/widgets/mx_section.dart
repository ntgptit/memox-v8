import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A group of rows under an overline (DESIGN.md, Containers › MxSection): the
/// Section Label, one full-bleed card whose rows are split by hairlines, and
/// an optional footnote.
class MxSection extends StatelessWidget {
  const MxSection({required this.children, this.title, this.note, super.key});

  /// The overline; the widget upper-cases it.
  final String? title;

  /// The rows, at least one.
  final List<Widget> children;

  /// A product rule under the card, drawn as `MxNote.hint`.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final String? overline = title;
    final String? footnote = note;
    final Widget divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.colors.outlineVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.micro,
              bottom: AppSpacing.control,
            ),
            child: Semantics(
              header: true,
              child: Text(
                overline.toUpperCase(),
                style: mxSectionLabelStyle(context.texts, context.colors),
              ),
            ),
          ),
        MxCard(
          isFullBleed: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, row) in children.indexed) ...[
                if (index > 0) divider,
                row,
              ],
            ],
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.micro,
              end: AppSpacing.micro,
              top: AppSpacing.control,
            ),
            child: MxNote.hint(text: footnote),
          ),
      ],
    );
  }
}
