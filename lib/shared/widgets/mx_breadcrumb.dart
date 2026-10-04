import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One level of a deck path. The id travels in [onTap]'s closure.
@immutable
final class MxBreadcrumbSegment {
  const MxBreadcrumbSegment({required this.label, this.onTap});

  final String label;

  /// Ignored on the last segment, which is the current level.
  final VoidCallback? onTap;
}

/// The deck path inside a nested deck. It never wraps and never truncates a
/// segment. The row scrolls horizontally, opens scrolled to its end so the
/// current level is always in view, and starts at the gutter when it fits.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({super.key, required this.segments})
    : assert(segments.length > 0, 'a path has at least the current level');

  final List<MxBreadcrumbSegment> segments;

  @override
  Widget build(BuildContext context) {
    final chevronColor = context.colors.outline;
    // Ruling R4: the row is a 48 touch band, not 2 + text + 8.
    return SizedBox(
      height: AppSize.touchTarget,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.micro,
                children: [
                  for (final (index, segment) in segments.indexed) ...[
                    if (index > 0)
                      Icon(
                        AppIcons.chevronRight,
                        size: AppIconSize.inline,
                        color: chevronColor,
                      ),
                    _Segment(
                      segment: segment,
                      isCurrent: index == segments.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.segment, required this.isCurrent});

  final MxBreadcrumbSegment segment;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    if (isCurrent) {
      return Text(segment.label, style: styles.breadcrumbCurrent);
    }
    return InkWell(
      onTap: segment.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSize.touchTarget,
          minHeight: AppSize.touchTarget,
        ),
        child: Center(
          widthFactor: 1,
          child: Text(segment.label, style: styles.breadcrumbAncestor),
        ),
      ),
    );
  }
}
