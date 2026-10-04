import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxStatusBadgeKind;

/// A card's learning status (DESIGN.md, MxStatusBadge): a pill with the
/// status dot and its label on the status container, or, with [isDot], the
/// bare 8 dot for dense rows, still named by [label] for TalkBack. A status
/// is never told by colour alone.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    required this.kind,
    required this.label,
    this.isDot = false,
    super.key,
  });

  final MxStatusBadgeKind kind;

  /// The status's localized name: shown in the pill, read aloud for a dot.
  final String label;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    final paint = mxStatusColors(context.semanticColors, kind);
    if (isDot) {
      return Semantics(
        label: label,
        child: _Dot(color: paint.mark, size: AppSize.statusDot),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.badge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paint.ground,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              _Dot(color: paint.mark, size: AppSize.statusDot),
              Flexible(
                child: Text(
                  label,
                  style: context.texts.labelSmall?.apply(color: paint.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
