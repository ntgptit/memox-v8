import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// One block of text under a title: the message, the error, a stack trace, or
/// the context as JSON. The text is selectable, and long lines wrap. [isCode]
/// sets it in the monospace [MxTextStyles.code]. It is a `SelectableText`, not
/// a `Text`: a log is the one place the app shows an error's own words, on
/// purpose (ADR-018 §1; BR-CORE-005 is about what a user sees).
class MonitoringCodeCardWidget extends StatelessWidget {
  const MonitoringCodeCardWidget({
    super.key,
    required this.title,
    required this.text,
    this.isCode = true,
  });

  final String title;
  final String text;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: title),
        MxCard(
          child: SelectableText(
            text,
            style: isCode ? styles.code : styles.dialogBody,
          ),
        ),
      ],
    );
  }
}
