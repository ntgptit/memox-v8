import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The text role of a line of terms.
enum MxTermLineRole { body, meta, itemTitle, sectionTitle }

/// The ink of a term, a glyph or a whole line.
enum MxTermTone { muted, foreground, primary, warning, accentMark }

/// How a line of terms sits in its width.
enum MxTermLineAlign { start, center }

/// One whole term: its words, an ink over the line's, and an optional
/// leading glyph (decorative).
class MxTerm {
  const MxTerm(this.text, {this.tone, this.glyph, this.glyphTone});

  final String text;
  final MxTermTone? tone;
  final IconData? glyph;
  final MxTermTone? glyphTone;
}

/// What comes before the terms, followed by a gap instead of a dot:
/// [MxTermLead.plain] in the line's style after a word gap ("Card-days:"),
/// [MxTermLead.label] in the primary label weight after a wider gap (a link
/// that leads its facts).
class MxTermLead {
  const MxTermLead.plain(this.text) : isLabel = false;
  const MxTermLead.label(this.text) : isLabel = true;

  final String text;
  final bool isLabel;
}

/// A line of short terms that wraps only between whole terms and draws a dot
/// only between two terms on the same line, so no dot ends or starts a line
/// (DESIGN.md, The Wrap Rule; owner 2026-10-20, spec W1). A term wider than
/// the whole line takes a line of its own and wraps at its own spaces.
///
/// It reads as one node: the whole line, or [semanticsLabel]. ForUI has no
/// such layout, so it is built on Flutter's render layer.
class MxTermLine extends StatelessWidget {
  const MxTermLine({
    super.key,
    required this.terms,
    this.lead,
    this.trail,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.semanticsLabel,
  });

  /// [line] as the ARB messages write it, split at its " · ". A line without
  /// one is a single term: it wraps as a plain text does.
  MxTermLine.text(
    String line, {
    super.key,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.semanticsLabel,
  }) : terms = [for (final term in line.split(separator)) MxTerm(term)],
       lead = null,
       trail = null;

  /// [terms] as they are, each whole: for a line built from the user's own
  /// names, which may hold a " · " of their own.
  MxTermLine.of(
    Iterable<String> terms, {
    super.key,
    this.role = MxTermLineRole.body,
    this.tone = MxTermTone.muted,
    this.align = MxTermLineAlign.start,
    this.semanticsLabel,
  }) : terms = [for (final term in terms) MxTerm(term)],
       lead = null,
       trail = null;

  /// What a localized line of terms is joined with.
  static const String separator = ' · ';

  /// The dot with its spaces; the spaces do not break.
  static const String _dot = ' · ';

  final List<MxTerm> terms;
  final MxTermLead? lead;

  /// A clause after the last term and a word gap, not a dot ("across 4
  /// decks"); it moves to the next line whole when it does not fit.
  final String? trail;
  final MxTermLineRole role;
  final MxTermTone tone;
  final MxTermLineAlign align;
  final String? semanticsLabel;

  /// The line as one string, as TalkBack reads it.
  String get spoken {
    return [
      ?lead?.text,
      [for (final term in terms) term.text].join(separator),
      ?trail,
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final base = _roleStyle(context).copyWith(color: inkOf(context, tone));
    final textAlign = align == MxTermLineAlign.center
        ? TextAlign.center
        : TextAlign.start;
    final lead = this.lead;
    final trail = this.trail;
    return Semantics(
      label: semanticsLabel ?? spoken,
      excludeSemantics: true,
      child: _TermFlow(
        slots: [
          if (lead != null) TermSlot.lead,
          for (final (index, _) in terms.indexed) ...[
            if (index > 0) TermSlot.dot,
            TermSlot.term,
          ],
          if (trail != null) TermSlot.trail,
        ],
        leadGap: lead == null || !lead.isLabel
            ? context.dimens.space4
            : context.dimens.space8,
        wordGap: context.dimens.space4,
        align: align,
        children: [
          if (lead != null)
            Text(
              lead.text,
              style: lead.isLabel
                  ? context.texts.label.copyWith(color: context.colors.primary)
                  : base,
            ),
          for (final (index, term) in terms.indexed) ...[
            if (index > 0) Text(_dot, style: base),
            _term(context, term, base, textAlign),
          ],
          if (trail != null) Text(trail, style: base, textAlign: textAlign),
        ],
      ),
    );
  }

  Widget _term(
    BuildContext context,
    MxTerm term,
    TextStyle base,
    TextAlign textAlign,
  ) {
    final style = term.tone == null
        ? base
        : base.copyWith(color: inkOf(context, term.tone!));
    final text = Text(term.text, style: style, textAlign: textAlign);
    final glyph = term.glyph;
    if (glyph == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.dimens.space4,
      children: [
        Icon(
          glyph,
          size: context.dimens.sizeIconInline,
          color: inkOf(context, term.glyphTone ?? term.tone ?? tone),
        ),
        Flexible(child: text),
      ],
    );
  }

  TextStyle _roleStyle(BuildContext context) => switch (role) {
    MxTermLineRole.body => context.texts.body,
    MxTermLineRole.meta => context.texts.meta,
    MxTermLineRole.itemTitle => context.texts.itemTitle,
    MxTermLineRole.sectionTitle => context.texts.sectionTitle,
  };

  /// The colour of [tone] in the current theme.
  static Color inkOf(BuildContext context, MxTermTone tone) => switch (tone) {
    MxTermTone.muted => context.colors.mutedForeground,
    MxTermTone.foreground => context.colors.foreground,
    MxTermTone.primary => context.colors.primary,
    MxTermTone.warning => context.status.warning,
    MxTermTone.accentMark => context.status.accentMark,
  };
}

/// What a child of the flow is.
enum TermSlot { lead, term, dot, trail }

/// Lays out [children], one per [slots]: `[lead], term, dot, term…, [trail]`.
class _TermFlow extends MultiChildRenderObjectWidget {
  const _TermFlow({
    required this.slots,
    required this.leadGap,
    required this.wordGap,
    required this.align,
    required super.children,
  });

  final List<TermSlot> slots;
  final double leadGap;
  final double wordGap;
  final MxTermLineAlign align;

  @override
  RenderTermFlow createRenderObject(BuildContext context) => RenderTermFlow(
    slots: slots,
    leadGap: leadGap,
    wordGap: wordGap,
    align: align,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderTermFlow renderObject) {
    renderObject
      ..slots = slots
      ..leadGap = leadGap
      ..wordGap = wordGap
      ..align = align
      ..textDirection = Directionality.of(context);
  }
}

/// A child's place in the flow; a dot at a line break is not shown.
class TermFlowParentData extends ContainerBoxParentData<RenderBox> {
  bool isShown = true;
}

/// The render of [MxTermLine]; public for its tests, which read where each
/// dot landed.
class RenderTermFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TermFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TermFlowParentData> {
  RenderTermFlow({
    required this._slots,
    required this._leadGap,
    required this._wordGap,
    required this._align,
    required this._textDirection,
  });

  /// Slack for float error when a term just fits.
  static const double _fitTolerance = 0.01;

  List<TermSlot> _slots;
  set slots(List<TermSlot> value) {
    if (listEquals(value, _slots)) return;
    _slots = value;
    markNeedsLayout();
  }

  double _leadGap;
  set leadGap(double value) {
    if (value == _leadGap) return;
    _leadGap = value;
    markNeedsLayout();
  }

  double _wordGap;
  set wordGap(double value) {
    if (value == _wordGap) return;
    _wordGap = value;
    markNeedsLayout();
  }

  MxTermLineAlign _align;
  set align(MxTermLineAlign value) {
    if (value == _align) return;
    _align = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _isDot(int index) => _slots[index] == TermSlot.dot;

  /// The space before the child at [index] when it shares a line with the
  /// one before: a dot's width is its own child.
  double _gapBefore(int index) => switch (_slots[index]) {
    TermSlot.term when index > 0 && _slots[index - 1] == TermSlot.lead =>
      _leadGap,
    TermSlot.trail => _wordGap,
    _ => 0,
  };

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TermFlowParentData) {
      child.parentData = TermFlowParentData();
    }
  }

  List<RenderBox> get _children {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (final (index, child) in _children.indexed) {
      if (_isDot(index)) continue;
      widest = math.max(widest, child.getMinIntrinsicWidth(height));
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var total = 0.0;
    for (final (index, child) in _children.indexed) {
      total += child.getMaxIntrinsicWidth(height) + _gapBefore(index);
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _flow(BoxConstraints(maxWidth: width), isDry: true).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _flow(constraints, isDry: true).size;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void performLayout() {
    final flow = _flow(constraints, isDry: false);
    size = flow.size;
    for (final (index, child) in _children.indexed) {
      final data = child.parentData! as TermFlowParentData;
      data
        ..offset = flow.offsets[index]
        ..isShown = flow.isShown[index];
    }
  }

  /// Places every child. A term goes on the current line when it fits at its
  /// one-line width (after its dot); otherwise it starts the next line and
  /// its dot is not shown.
  _Flow _flow(BoxConstraints constraints, {required bool isDry}) {
    final children = _children;
    final lineWidth = constraints.maxWidth;
    final sizes = List<Size>.filled(children.length, Size.zero);
    final isShown = List<bool>.filled(children.length, true);
    final lineOf = List<int>.filled(children.length, 0);
    final xs = List<double>.filled(children.length, 0);
    Size measure(int index, double maxWidth) {
      final childConstraints = BoxConstraints(maxWidth: maxWidth);
      final child = children[index];
      if (isDry) return child.getDryLayout(childConstraints);
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    }

    var line = 0;
    var x = 0.0;
    final lineWidths = <double>[0];
    for (var index = 0; index < children.length; index++) {
      if (_isDot(index)) continue;
      final child = children[index];
      final natural = child.getMaxIntrinsicWidth(double.infinity);
      final dotIndex = index - 1;
      final hasDot = dotIndex >= 0 && _isDot(dotIndex);
      final dotSize = hasDot ? measure(dotIndex, double.infinity) : Size.zero;
      final before = hasDot ? dotSize.width : _gapBefore(index);
      final isLineStart = x == 0 && index == 0;
      final fits =
          isLineStart || x + before + natural <= lineWidth + _fitTolerance;
      if (hasDot) {
        sizes[dotIndex] = dotSize;
        isShown[dotIndex] = fits;
        xs[dotIndex] = x;
        lineOf[dotIndex] = line;
      }
      if (!fits) {
        line += 1;
        lineWidths.add(0);
        x = 0;
      }
      final start = fits && !isLineStart ? x + before : x;
      final size = measure(index, math.max(0, lineWidth - start));
      sizes[index] = size;
      xs[index] = start;
      lineOf[index] = line;
      x = start + size.width;
      lineWidths[line] = x;
    }
    // A dot that is not shown sits on the line of the term after it, at its
    // start, and paints nothing.
    for (var index = 0; index < children.length; index++) {
      if (!_isDot(index) || isShown[index]) continue;
      if (!isDry) children[index].layout(BoxConstraints.tight(Size.zero));
      sizes[index] = Size.zero;
      lineOf[index] = lineOf[index + 1];
      xs[index] = 0;
    }
    final lineHeights = List<double>.filled(line + 1, 0);
    for (var index = 0; index < children.length; index++) {
      final height = sizes[index].height;
      lineHeights[lineOf[index]] = math.max(lineHeights[lineOf[index]], height);
    }
    final widest = lineWidths.fold(0.0, math.max);
    final width = constraints.constrainWidth(
      _align == MxTermLineAlign.center && lineWidth.isFinite
          ? lineWidth
          : widest,
    );
    final tops = <double>[0];
    for (var index = 1; index <= line; index++) {
      tops.add(tops[index - 1] + lineHeights[index - 1]);
    }
    final offsets = List<Offset>.filled(children.length, Offset.zero);
    for (var index = 0; index < children.length; index++) {
      final row = lineOf[index];
      final inset = _align == MxTermLineAlign.center
          ? (width - lineWidths[row]) / 2
          : 0.0;
      var left = inset + xs[index];
      if (_textDirection == TextDirection.rtl) {
        left = width - left - sizes[index].width;
      }
      final top = tops[row] + (lineHeights[row] - sizes[index].height) / 2;
      offsets[index] = Offset(left, top);
    }
    final height = tops.last + lineHeights.last;
    return _Flow(
      size: constraints.constrain(Size(width, height)),
      offsets: offsets,
      isShown: isShown,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as TermFlowParentData;
      if (data.isShown) context.paintChild(child, offset + data.offset);
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

class _Flow {
  const _Flow({
    required this.size,
    required this.offsets,
    required this.isShown,
  });

  final Size size;
  final List<Offset> offsets;
  final List<bool> isShown;
}
