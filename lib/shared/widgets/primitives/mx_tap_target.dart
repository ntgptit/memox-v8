import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_size.dart';

/// Guarantees the 48×48 hit area around a control painted smaller (DESIGN.md,
/// "The 48 Floor Rule"): the child paints at its own size, centred, and a
/// touch anywhere in the 48 box reaches it, as Material's padded tap target
/// does.
class MxTapTarget extends SingleChildRenderObjectWidget {
  const MxTapTarget({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTapTarget();
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget() : super(null);

  static const Size _minimum = Size.square(AppSize.tapTarget);

  @override
  void performLayout() {
    final RenderBox box = child!;
    box.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(
        math.max(box.size.width, _minimum.width),
        math.max(box.size.height, _minimum.height),
      ),
    );
    final BoxParentData data = box.parentData! as BoxParentData;
    data.offset = Alignment.center.alongOffset(size - box.size as Offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }
    if (!size.contains(position)) {
      return false;
    }
    // A touch in the padding is a touch on the control's centre.
    final Offset centre = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (result, position) => child!.hitTest(result, position: centre),
    );
  }
}
