import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A tag as read-only metadata (DESIGN.md, MxTagChip): a pill at least 24
/// tall on its own line, or 20 ([isDense]) inside a row. It hugs its name up
/// to half the width it is given, so a tag never dominates its row; a longer
/// name ends in an ellipsis and stays whole for TalkBack. In a `Row` give it a
/// `Flexible` so it learns the row's width; with no width bound at all it
/// stops at half the window.
class MxTagChip extends StatelessWidget {
  const MxTagChip({required this.label, this.isDense = false, super.key});

  final String label;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxTagColors(context.colors);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: _HalfWidth(
        window: MediaQuery.sizeOf(context).width,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDense ? AppSize.tagChipDense : AppSize.tagChip,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pair.ground,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.control,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: pair.content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays its child out at most half the width it is given. Unlike a
/// `LayoutBuilder` it answers intrinsic sizes, so it works under
/// `IntrinsicHeight`.
class _HalfWidth extends SingleChildRenderObjectWidget {
  const _HalfWidth({required this.window, required super.child});

  /// The cap's base when the width is unbounded.
  final double window;

  @override
  _RenderHalfWidth createRenderObject(BuildContext context) =>
      _RenderHalfWidth(window);

  @override
  void updateRenderObject(BuildContext context, _RenderHalfWidth render) {
    render.window = window;
  }
}

class _RenderHalfWidth extends RenderProxyBox {
  _RenderHalfWidth(this._window);

  double _window;

  set window(double value) {
    if (value == _window) {
      return;
    }
    _window = value;
    markNeedsLayout();
  }

  BoxConstraints _capped(BoxConstraints given) {
    final double base = given.hasBoundedWidth ? given.maxWidth : _window;
    // A tight width wins over the cap; the chip never breaks its parent.
    return given.copyWith(maxWidth: math.max(given.minWidth, base / 2));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(_capped(constraints)));

  @override
  void performLayout() {
    final RenderBox box = child!;
    box.layout(_capped(constraints), parentUsesSize: true);
    size = constraints.constrain(box.size);
  }
}
