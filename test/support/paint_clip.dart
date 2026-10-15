import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a clip above [finder] would cut [bounds], a rect in screen
/// coordinates that [finder]'s own paint reaches (a focus ring around it).
bool clipsAway(WidgetTester tester, Finder finder, Rect bounds) {
  final object = tester.renderObject<RenderBox>(finder);
  var visible = bounds;
  RenderObject child = object;
  var parent = object.parent;
  while (parent != null) {
    final clip = parent.describeApproximatePaintClip(child);
    if (clip != null) {
      visible = visible.intersect(
        MatrixUtils.transformRect(parent.getTransformTo(null), clip),
      );
    }
    child = parent;
    parent = parent.parent;
  }
  return visible != bounds;
}
