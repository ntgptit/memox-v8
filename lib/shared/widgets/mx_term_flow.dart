import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// What a child of the flow is.
enum TermSlot { lead, term, dot, trail }

/// The layout of `MxTermLine`: [children], one per [slots], as `[lead],
/// term, dot, term…, [trail]`. Only `MxTermLine` builds it.
class MxTermFlow extends MultiChildRenderObjectWidget {
  const MxTermFlow({
    super.key,
    required this.slots,
    required this.leadGap,
    required this.wordGap,
    required this.isCentered,
    required this.maxLines,
    required super.children,
  });

  final List<TermSlot> slots;
  final double leadGap;
  final double wordGap;

  /// Each line sits in the middle of the width.
  final bool isCentered;
  final int? maxLines;

  @override
  RenderTermFlow createRenderObject(BuildContext context) => RenderTermFlow(
    slots: slots,
    leadGap: leadGap,
    wordGap: wordGap,
    isCentered: isCentered,
    maxLines: maxLines,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderTermFlow renderObject) {
    renderObject
      ..slots = slots
      ..leadGap = leadGap
      ..wordGap = wordGap
      ..isCentered = isCentered
      ..maxLines = maxLines
      ..textDirection = Directionality.of(context);
  }
}

/// A child's place in the flow; a dot at a line break, and every part past a
/// capped line's cut, is not shown.
@visibleForTesting
class TermFlowParentData extends ContainerBoxParentData<RenderBox> {
  bool isShown = true;
}

/// The render of `MxTermLine`; public for its tests, which read where each
/// dot landed.
@visibleForTesting
class RenderTermFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TermFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TermFlowParentData> {
  RenderTermFlow({
    required this._slots,
    required this._leadGap,
    required this._wordGap,
    required this._isCentered,
    required this._maxLines,
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

  bool _isCentered;
  set isCentered(bool value) {
    if (value == _isCentered) return;
    _isCentered = value;
    markNeedsLayout();
  }

  int? _maxLines;
  set maxLines(int? value) {
    if (value == _maxLines) return;
    _maxLines = value;
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
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final first = firstChild;
    if (first == null) return null;
    final distance = first.getDryBaseline(
      BoxConstraints(maxWidth: constraints.maxWidth),
      baseline,
    );
    if (distance == null) return null;
    return distance + _flow(constraints, isDry: true).offsets.first.dy;
  }

  @override
  void performLayout() {
    assert(_slots.length == childCount, 'one slot per child');
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
  /// its dot is not shown. On a capped line the term that would pass the cap
  /// takes what is left of the last line, and nothing after it is shown.
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

    final maxLines = _maxLines;
    var line = 0;
    var x = 0.0;
    var isCut = false;
    final lineWidths = <double>[0];
    for (var index = 0; index < children.length; index++) {
      if (_isDot(index)) continue;
      final dotIndex = index - 1;
      final hasDot = dotIndex >= 0 && _isDot(dotIndex);
      if (isCut) {
        isShown[index] = false;
        if (hasDot) isShown[dotIndex] = false;
        continue;
      }
      final natural = children[index].getMaxIntrinsicWidth(double.infinity);
      final dotSize = hasDot ? measure(dotIndex, double.infinity) : Size.zero;
      final before = hasDot ? dotSize.width : _gapBefore(index);
      final isFirst = index == 0;
      final fits = isFirst || x + before + natural <= lineWidth + _fitTolerance;
      // A capped line ends here: this term takes what the last line has
      // left, in an ellipsis.
      final isCutHere = !fits && maxLines != null && line >= maxLines - 1;
      final remaining = lineWidth - x - before;
      if (isCutHere) isCut = true;
      if (isCutHere && remaining <= 0) {
        isShown[index] = false;
        if (hasDot) isShown[dotIndex] = false;
        continue;
      }
      final isSameLine = fits || isCutHere;
      if (hasDot) {
        sizes[dotIndex] = dotSize;
        isShown[dotIndex] = isSameLine;
        xs[dotIndex] = x;
        lineOf[dotIndex] = line;
      }
      if (!isSameLine) {
        line += 1;
        lineWidths.add(0);
        x = 0;
      }
      final start = isSameLine && !isFirst ? x + before : x;
      // A term that fits keeps its one-line width even when float error
      // leaves a hair less room (final review I1); a term wider than the
      // line wraps in it.
      final maxWidth = switch ((isFirst, fits, isCutHere)) {
        (true, _, _) => lineWidth,
        (_, _, true) => remaining,
        (_, true, _) => math.max(natural, lineWidth - start),
        _ => lineWidth,
      };
      final size = measure(index, maxWidth);
      sizes[index] = size;
      xs[index] = start;
      lineOf[index] = line;
      x = start + size.width;
      lineWidths[line] = x;
    }
    // A part that is not shown takes no room and paints nothing; one never
    // measured is laid out once at no size, as every render box must be.
    for (var index = 0; index < children.length; index++) {
      if (isShown[index]) continue;
      final child = children[index];
      if (!isDry && !child.hasSize) {
        child.layout(BoxConstraints.tight(Size.zero));
      }
      sizes[index] = Size.zero;
      xs[index] = 0;
      if (index + 1 < children.length) lineOf[index] = lineOf[index + 1];
    }
    final lineHeights = List<double>.filled(line + 1, 0);
    for (var index = 0; index < children.length; index++) {
      final height = sizes[index].height;
      lineHeights[lineOf[index]] = math.max(lineHeights[lineOf[index]], height);
    }
    final widest = lineWidths.fold(0.0, math.max);
    final width = constraints.constrainWidth(
      _isCentered && lineWidth.isFinite ? lineWidth : widest,
    );
    final tops = <double>[0];
    for (var index = 1; index <= line; index++) {
      tops.add(tops[index - 1] + lineHeights[index - 1]);
    }
    final offsets = List<Offset>.filled(children.length, Offset.zero);
    for (var index = 0; index < children.length; index++) {
      final row = lineOf[index];
      final inset = _isCentered ? (width - lineWidths[row]) / 2 : 0.0;
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
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final box = child;
      final data = box.parentData! as TermFlowParentData;
      final isHit =
          data.isShown &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (result, transformed) =>
                box.hitTest(result, position: transformed),
          );
      if (isHit) return true;
      child = data.previousSibling;
    }
    return false;
  }
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
