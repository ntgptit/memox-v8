import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

enum _CardKind { code, prose, error, stackTrace }

/// One block of text under a title: the message, the error, a stack trace, or
/// the context as JSON. The text is selectable, and long lines wrap. Code is
/// set in the monospace [MxTextStyles.code]. It is a `SelectableText`, not a
/// `Text`: a log is the one place the app shows an error's own words, on
/// purpose (ADR-018 §1; BR-CORE-005 is about what a user sees).
class MonitoringCodeCardWidget extends StatelessWidget {
  /// JSON or any other code.
  const MonitoringCodeCardWidget({
    super.key,
    required this.title,
    required this.text,
  }) : _kind = _CardKind.code,
       type = '';

  /// Words, such as the message.
  const MonitoringCodeCardWidget.prose({
    super.key,
    required this.title,
    required this.text,
  }) : _kind = _CardKind.prose,
       type = '';

  /// The error: its [type] on a line of its own, set apart from the message
  /// (Impeccable 2026-09-29 F6). Either may be empty.
  const MonitoringCodeCardWidget.error({
    super.key,
    required this.title,
    required this.type,
    required this.text,
  }) : _kind = _CardKind.error;

  /// A stack trace in code, each frame's `#n` in the primary ink, so a new
  /// frame reads apart from a line that wrapped (Impeccable 2026-09-29 F6).
  const MonitoringCodeCardWidget.stackTrace({
    super.key,
    required this.title,
    required this.text,
  }) : _kind = _CardKind.stackTrace,
       type = '';

  final String title;
  final String text;
  final String type;
  final _CardKind _kind;

  static final RegExp _frame = RegExp(r'^#\d+');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: title),
        MxCard(child: _text(context)),
      ],
    );
  }

  Widget _text(BuildContext context) {
    final styles = context.textStyles;
    return switch (_kind) {
      _CardKind.code => SelectableText(text, style: styles.code),
      _CardKind.prose => SelectableText(text, style: styles.dialogBody),
      _CardKind.error => SelectableText.rich(
        TextSpan(
          children: [
            if (type.isNotEmpty) TextSpan(text: type, style: styles.rowTitle),
            if (type.isNotEmpty && text.isNotEmpty) const TextSpan(text: '\n'),
            if (text.isNotEmpty) TextSpan(text: text),
          ],
        ),
        style: styles.dialogBody,
      ),
      _CardKind.stackTrace => SelectableText.rich(
        _trace(styles.code.copyWith(color: context.derivedColors.primaryInk)),
        style: styles.code,
      ),
    };
  }

  TextSpan _trace(TextStyle frameStyle) {
    final lines = text.split('\n');
    return TextSpan(
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) const TextSpan(text: '\n'),
          if (_frame.matchAsPrefix(line) case final match?) ...[
            TextSpan(text: match[0], style: frameStyle),
            TextSpan(text: line.substring(match.end)),
          ] else
            TextSpan(text: line),
        ],
      ],
    );
  }
}
