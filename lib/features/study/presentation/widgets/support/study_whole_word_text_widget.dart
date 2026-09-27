import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The text of a study face that must stay whole (Guess's term, a Match
/// tile): it wraps between words like any text, but when its widest word
/// is wider than the space, the whole text is drawn just small enough for
/// that word to fit on one line, instead of breaking inside it. It never
/// ellipsizes (FE-A6 D19; Impeccable after P3).
///
/// The fit is a paint-time scale, not a layout callback, so the scroll
/// bodies around it can still ask for its intrinsic height.
class StudyWholeWordTextWidget extends StatelessWidget {
  const StudyWholeWordTextWidget(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  static final RegExp _space = RegExp(r'\s+');

  @override
  Widget build(BuildContext context) => _WholeWordFit(
    widestWord: _widestWord(
      MediaQuery.textScalerOf(context),
      Directionality.of(context),
    ),
    child: Text(text, textAlign: textAlign, style: style),
  );

  double _widestWord(TextScaler scaler, TextDirection direction) {
    var widest = 0.0;
    for (final word in text.split(_space)) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }
}

class _WholeWordFit extends SingleChildRenderObjectWidget {
  const _WholeWordFit({required this.widestWord, required super.child});

  final double widestWord;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholeWordFit(widestWord);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWholeWordFit renderObject,
  ) => renderObject.widestWord = widestWord;
}

/// Lays its child out in `width / scale` and paints it at `scale`, where
/// `scale` shrinks only as far as the widest word needs.
class _RenderWholeWordFit extends RenderProxyBox {
  _RenderWholeWordFit(this._widestWord);

  double _widestWord;
  double get widestWord => _widestWord;
  set widestWord(double value) {
    if (value == _widestWord) return;
    _widestWord = value;
    markNeedsLayout();
  }

  double _scale = 1;

  double _scaleFor(double width) =>
      width.isFinite && _widestWord > width && width > 0
      ? width / _widestWord
      : 1;

  @override
  double computeMinIntrinsicHeight(double width) {
    final scale = _scaleFor(width);
    return (child?.getMinIntrinsicHeight(width / scale) ?? 0) * scale;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final scale = _scaleFor(width);
    return (child?.getMaxIntrinsicHeight(width / scale) ?? 0) * scale;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final scale = _scaleFor(constraints.maxWidth);
    return constraints.constrain(
      child.getDryLayout(_inner(constraints, scale)) * scale,
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    _scale = _scaleFor(constraints.maxWidth);
    child.layout(_inner(constraints, _scale), parentUsesSize: true);
    size = constraints.constrain(child.size * _scale);
  }

  BoxConstraints _inner(BoxConstraints outer, double scale) => BoxConstraints(
    maxWidth: outer.maxWidth / scale,
    maxHeight: outer.maxHeight / scale,
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_scale, _scale, 1),
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.scaleByDouble(_scale, _scale, 1, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: Matrix4.diagonal3Values(_scale, _scale, 1),
        position: position,
        hitTest: (result, position) =>
            child?.hitTest(result, position: position) ?? false,
      );
}
