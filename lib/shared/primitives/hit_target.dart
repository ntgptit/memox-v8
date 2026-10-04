import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// Grows the touch area of a smaller painted control to 48×48 without
/// changing what it paints (DESIGN.md, The 48 Floor Rule). A tap anywhere in
/// the grown area lands on the control, as Material's padded tap target does.
class HitTarget extends SingleChildRenderObjectWidget {
  const HitTarget({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitTarget();
}

class _RenderHitTarget extends RenderShiftedBox {
  _RenderHitTarget() : super(null);

  static const double _floor = AppSize.touchTarget;

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        child.size.width < _floor ? _floor : child.size.width,
        child.size.height < _floor ? _floor : child.size.height,
      ),
    );
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Alignment.center.alongOffset(
      (size - child.size) as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child!.hitTest(result, position: center),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _atLeastFloor(child!.getMinIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _atLeastFloor(child!.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _atLeastFloor(child!.getMaxIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _atLeastFloor(child!.getMaxIntrinsicHeight(width));

  double _atLeastFloor(double value) => value < _floor ? _floor : value;
}
