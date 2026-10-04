import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One place on a path: its label and, for a place one can go back to, what
/// going there does.
class MxBreadcrumbItem {
  const MxBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// A path of places (DESIGN.md, MxBreadcrumb), presentation-neutral: it knows
/// no deck, ancestor or route. The last item is where the reader is; the ones
/// before it are ancestors, each a 48 target when it can be tapped. One line:
/// when the path does not fit, the current place keeps its full width and
/// the ancestors share what is left, each cut with an ellipsis but read whole
/// by TalkBack. The separator mirrors in right-to-left text.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({required this.items, super.key});

  /// At least one; the last is the current place.
  final List<MxBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'MxBreadcrumb needs at least one item.');
    final TextStyle? style = context.texts.bodyMedium;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    return Padding(
      // The labels line up with the body's gutter; the ripple reaches past them.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter - AppSpacing.micro,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final List<double> natural = [
            for (final item in items)
              _labelWidth(item.label, style, scaler, direction) +
                  2 * AppSpacing.micro,
          ];
          final double separators =
              (items.length - 1) * (AppIconSize.small + 2 * AppSpacing.micro);
          final List<double> widths = _share(
            natural,
            math.max(0, box.maxWidth - separators),
          );
          final int last = items.length - 1;
          return Row(
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0) const _Separator(),
                SizedBox(
                  width: widths[index],
                  child: _Place(item: item, isCurrent: index == last),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static double _labelWidth(
    String label,
    TextStyle? style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textScaler: scaler,
      textDirection: direction,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  /// The current place (last) takes its natural width while at least a 48
  /// target is left for each ancestor; the ancestors then share the rest,
  /// a short one keeping its natural width and giving the remainder on.
  static List<double> _share(List<double> natural, double room) {
    final int last = natural.length - 1;
    final double floor = last * AppSize.tapTarget;
    final double current = math.min(natural[last], math.max(0, room - floor));
    final List<double> widths = List<double>.filled(natural.length, 0);
    widths[last] = current;
    double left = room - current;
    final List<int> open = [for (var i = 0; i < last; i++) i]
      ..sort((a, b) => natural[a].compareTo(natural[b]));
    for (final (rank, index) in open.indexed) {
      final double fair = left / (open.length - rank);
      final double take = math.min(natural[index], fair);
      widths[index] = take;
      left -= take;
    }
    return widths;
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
      child: ExcludeSemantics(
        child: Icon(
          Icons.chevron_right,
          size: AppIconSize.small,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.item, required this.isCurrent});

  final MxBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final VoidCallback? tap = isCurrent ? null : item.onTap;
    final Widget label = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodyMedium?.apply(
              color: isCurrent ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    final Widget read = Semantics(
      label: item.label,
      selected: isCurrent,
      button: tap != null,
      excludeSemantics: true,
      child: label,
    );
    if (tap == null) {
      return read;
    }
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);
    return MxFocusRing(
      borderRadius: radius,
      child: MxRowInk(onTap: tap, borderRadius: radius, child: read),
    );
  }
}
