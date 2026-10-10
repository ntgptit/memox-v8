import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

enum _CardKind { code, prose, error, stackTrace }

/// One block of text under a title: the message, the error, a stack trace, or
/// the context as JSON. The text is selectable, and long lines wrap. Code is
/// set in the monospace [MxTextStyles.code]. It is a `SelectableText` (a
/// stack trace, rows in a `SelectionArea`), not a plain `Text`: a log is the one place the app shows an error's own words, on
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

  /// A stack trace in code, each frame's `#n` in the primary foreground and in a
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
            color: context.semanticColors.primaryText,
          ),
        ),
      ),
    };
  }
}

/// One frame per row, the `#n` in a cell as wide as the trace's largest
/// frame number; a copy gives the trace back as written (critique
/// 2026-09-30 part 3d-2, final review).
class _StackTrace extends StatefulWidget {
  const _StackTrace({
    required this.text,
    required this.style,
    required this.frameStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle frameStyle;

  @override
  State<_StackTrace> createState() => _StackTraceState();
}

class _StackTraceState extends State<_StackTrace> {
  static final RegExp _frame = RegExp(r'^(#\d+)(\s*)');

  /// A copy ends each line with a new line.
  final _lines = _JoiningDelegate('\n');

  /// Per frame, its `#n` and its text joined by the frame's own gap.
  var _frames = <_JoiningDelegate?>[];
  var _rows = <String>[];

  @override
  void initState() {
    super.initState();
    _split();
  }

  @override
  void didUpdateWidget(_StackTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    _disposeFrames();
    _split();
  }

  @override
  void dispose() {
    _disposeFrames();
    _lines.dispose();
    super.dispose();
  }

  void _split() {
    _rows = widget.text.split('\n');
    _frames = [
      for (final row in _rows)
        if (_frame.matchAsPrefix(row) case final match?)
          _JoiningDelegate(match[2]!.isEmpty ? ' ' : match[2]!)
        else
          null,
    ];
  }

  void _disposeFrames() {
    for (final delegate in _frames) {
      delegate?.dispose();
    }
  }

  /// The cell fits the largest frame number and a space, in the code face
  /// at the text scale.
  double _cellWidth(BuildContext context) {
    var digits = 2;
    for (final row in _rows) {
      if (_frame.matchAsPrefix(row) case final match?) {
        digits = math.max(digits, match[1]!.length - 1);
      }
    }
    final painter = TextPainter(
      text: TextSpan(text: '#${'9' * digits} ', style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final cell = _cellWidth(context);
    return SelectionContainer(
      delegate: _lines,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in _rows.indexed)
            if (_frame.matchAsPrefix(row) case final match?)
              // The #n stands on the frame's first line, in the cell the
              // text keeps clear; not a row of marks to centre.
              SelectionContainer(
                delegate: _frames[index]!,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: cell),
                      child: Text(
                        row.substring(match.end),
                        style: widget.style,
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      child: Text(match[1]!, style: widget.frameStyle),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsetsDirectional.only(start: cell),
                child: Text(row, style: widget.style),
              ),
        ],
      ),
    );
  }
}

/// Joins what its children copy with [separator]; Flutter's own delegate
/// joins with nothing.
class _JoiningDelegate extends StaticSelectionContainerDelegate {
  _JoiningDelegate(this.separator);

  final String separator;

  @override
  SelectedContent? getSelectedContent() {
    final parts = [
      for (final selectable in selectables)
        if (selectable.getSelectedContent() case final content?)
          content.plainText,
    ];
    if (parts.isEmpty) return null;
    return SelectedContent(plainText: parts.join(separator));
  }
}
