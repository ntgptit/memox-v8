import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';
import 'package:memox/core/theme/theme_rules.dart';

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
/// A deep path fades its start edge while ancestors are scrolled out of
/// view (DEV-306); each stays a reachable button to TalkBack. An ancestor
/// is a `MxRowInk`: its ripple and its focus ring are the shared row's.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({super.key, required this.segments})
    : assert(segments.length > 0, 'a path has at least the current level');

  final List<MxBreadcrumbSegment> segments;

  @override
  Widget build(BuildContext context) {
    final chevronColor = context.colors.outline;
    // Ruling R4: the row is a 48 touch band, not 2 + text + 8.
    return SizedBox(
      height: context.dimens.sizeControl,
      child: LayoutBuilder(
        builder: (context, constraints) => MxScrollFade(
          axis: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.screenMargin),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: context.dimens.space4,
                  children: [
                    for (final (index, segment) in segments.indexed) ...[
                      if (index > 0)
                        Icon(
                          AppIcons.chevronRight,
                          size: context.dimens.sizeIconInline,
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
    if (isCurrent) {
      return Text(segment.label, style: context.texts.titleSmall);
    }
    final target = MxRowInk(
      onTap: segment.onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: context.dimens.sizeControl,
          minHeight: context.dimens.sizeControl,
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            segment.label,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    // A tappable ancestor is already a button (`MxRowInk`); one without a tap
    // stays a button to TalkBack, reachable even while scrolled out of view
    // (DEV-306).
    if (segment.onTap != null) return target;
    return Semantics(button: true, child: target);
  }
}
