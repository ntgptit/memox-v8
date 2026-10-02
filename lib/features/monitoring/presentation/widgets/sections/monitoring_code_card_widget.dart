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

  /// A stack trace in code, each frame's `#n` in the primary ink and in a
  /// cell its wrapped lines hang under, so a new frame reads apart from a
  /// line that wrapped (Impeccable 2026-09-29 F6; critique 2026-09-30 part
  /// 3d-2, E11).
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
      // One frame per row: the #n in a fixed cell, so a wrapped line hangs
      // under the frame's text (critique 2026-09-30 part 3d-2, E11). Still
      // selectable, across frames.
      _CardKind.stackTrace => SelectionArea(
        child: _StackTrace(
          text: text,
          style: styles.code,
          frameStyle: styles.code.copyWith(
            color: context.derivedColors.primaryInk,
          ),
        ),
      ),
    };
  }
}

class _StackTrace extends StatelessWidget {
  const _StackTrace({
    required this.text,
    required this.style,
    required this.frameStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle frameStyle;

  static final RegExp _frame = RegExp(r'^#\d+');

  /// The cell holds "#99" and a space, in the code face at the text scale.
  static const String _cellSample = '#99 ';

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: _cellSample, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final cell = painter.width;
    painter.dispose();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in text.split('\n'))
          if (_frame.matchAsPrefix(line) case final match?)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: cell,
                  child: Text(match[0]!, style: frameStyle),
                ),
                Expanded(
                  child: Text(
                    line.substring(match.end).trimLeft(),
                    style: style,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: EdgeInsetsDirectional.only(start: cell),
              child: Text(line.trimLeft(), style: style),
            ),
      ],
    );
  }
}
