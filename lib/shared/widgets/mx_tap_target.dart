import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// [base], a ForUI button style, kept on a 48 touch target: a painted height
/// under 48 (a 40 small button, a 32 chip) is drawn centred inside the
/// target, and [isLoading] keeps the resting decoration in every state.
/// [horizontal] replaces ForUI's side padding.
FButtonStyle mxTargetStyle(
  BuildContext context,
  FButtonStyle base, {
  double? painted,
  double? horizontal,
  bool isLoading = false,
}) {
  final target = context.dimens.sizeControl;
  final height = painted ?? base.contentStyle.constraints.minHeight;
  final inset = math.max(0.0, (target - height) / 2);
  final padding = base.contentStyle.padding.resolve(Directionality.of(context));
  final decoration = isLoading
      ? FVariants<
          FTappableVariantConstraint,
          FTappableVariant,
          Decoration,
          DecorationDelta
        >.all(_inset(base.decoration.base, inset))
      : FVariants<
          FTappableVariantConstraint,
          FTappableVariant,
          Decoration,
          DecorationDelta
        >.raw(_inset(base.decoration.base, inset), {
          for (final MapEntry(:key, :value) in base.decoration.variants.entries)
            key: _inset(value, inset),
        });
  return base.copyWith(
    decoration: decoration,
    contentStyle: FButtonContentStyleDelta.delta(
      constraints: BoxConstraints(minWidth: target, minHeight: target),
      padding: EdgeInsetsGeometryDelta.value(
        EdgeInsetsDirectional.symmetric(
          horizontal: horizontal ?? padding.left,
          vertical: math.max(padding.top, inset),
        ),
      ),
    ),
  );
}

Decoration _inset(Decoration decoration, double inset) =>
    mxInsetDecoration(decoration, EdgeInsets.symmetric(vertical: inset));

/// [base], a ForUI icon button style, kept on a 48 × 48 touch target: the
/// square it paints (a 32 stepper step) is drawn centred inside it.
FButtonStyle mxIconTargetStyle(BuildContext context, FButtonStyle base) {
  final target = context.dimens.sizeControl;
  final icon = base.iconContentStyle;
  final inset = math.max(0.0, (target - icon.constraints.minHeight) / 2);
  Decoration square(Decoration decoration) =>
      mxInsetDecoration(decoration, EdgeInsets.all(inset));
  return base.copyWith(
    decoration:
        FVariants<
          FTappableVariantConstraint,
          FTappableVariant,
          Decoration,
          DecorationDelta
        >.raw(square(base.decoration.base), {
          for (final MapEntry(:key, :value) in base.decoration.variants.entries)
            key: square(value),
        }),
    iconContentStyle: FButtonIconContentStyleDelta.delta(
      constraints: BoxConstraints.tightFor(width: target, height: target),
      padding: const EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
    ),
  );
}

/// [decoration] painted [inset] in from the box it decorates, so a control
/// keeps its whole 48 touch target and semantics node while it paints
/// smaller (a 40 small button, a 32 chip). ForUI paints a control's
/// decoration across the whole tappable box; this keeps the target and
/// shrinks only the paint.
Decoration mxInsetDecoration(Decoration decoration, EdgeInsets inset) {
  if (inset == EdgeInsets.zero) return decoration;
  return switch (decoration) {
    ShapeDecoration(:final shape) => ShapeDecoration(
      color: decoration.color,
      gradient: decoration.gradient,
      image: decoration.image,
      shadows: decoration.shadows,
      shape: _InsetShapeBorder(shape, inset),
    ),
    BoxDecoration() => mxInsetDecoration(
      ShapeDecoration.fromBoxDecoration(decoration),
      inset,
    ),
    _ => decoration,
  };
}

/// [base] drawn in a rect deflated by [inset].
class _InsetShapeBorder extends ShapeBorder {
  const _InsetShapeBorder(this.base, this.inset);

  final ShapeBorder base;
  final EdgeInsets inset;

  @override
  EdgeInsetsGeometry get dimensions => base.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      base.getInnerPath(inset.deflateRect(rect), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      base.getOuterPath(inset.deflateRect(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      base.paint(canvas, inset.deflateRect(rect), textDirection: textDirection);

  @override
  bool get preferPaintInterior => base.preferPaintInterior;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => base.paintInterior(
    canvas,
    inset.deflateRect(rect),
    paint,
    textDirection: textDirection,
  );

  @override
  ShapeBorder scale(double t) => _InsetShapeBorder(base.scale(t), inset * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _InsetShapeBorder) {
      return _InsetShapeBorder(
        ShapeBorder.lerp(a.base, base, t)!,
        EdgeInsets.lerp(a.inset, inset, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _InsetShapeBorder) {
      return _InsetShapeBorder(
        ShapeBorder.lerp(base, b.base, t)!,
        EdgeInsets.lerp(inset, b.inset, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is _InsetShapeBorder && other.base == base && other.inset == inset;

  @override
  int get hashCode => Object.hash(base, inset);
}
