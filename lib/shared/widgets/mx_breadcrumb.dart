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
/// when the path does not fit, the current place keeps its full width, the
/// nearest ancestors stay whole, and the oldest fold into one "…" place that
/// goes to the nearest of them that can be opened and reads them all to
/// TalkBack. The separator
/// mirrors in right-to-left text.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({required this.items, super.key});

  /// At least one; the last is the current place.
  final List<MxBreadcrumbItem> items;

  /// The folded places' mark.
  static const String _fold = '…';

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'MxBreadcrumb needs at least one item.');
    final TextStyle? style = context.texts.bodyMedium;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets system = MediaQuery.paddingOf(context);
    // A place is at least a 48 target wide, however short its label.
    double widthOf(String label) => math.max(
      AppSize.tapTarget,
      _labelWidth(label, style, scaler, direction) + 2 * AppSpacing.micro,
    );
    return Padding(
      // The labels line up with the body's gutter, clear of any cutout; the
      // ripple reaches past them.
      padding: EdgeInsets.only(
        left: AppSpacing.gutter - AppSpacing.micro + system.left,
        right: AppSpacing.gutter - AppSpacing.micro + system.right,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final List<double> natural = [
            for (final item in items) widthOf(item.label),
          ];
          final int hidden = _hiddenCount(
            natural,
            box.maxWidth,
            widthOf(_fold),
          );
          final List<MxBreadcrumbItem> folded = items.sublist(0, hidden);
          final List<MxBreadcrumbItem> shown = items.sublist(hidden);
          final int last = shown.length - 1;
          return Row(
            children: [
              if (folded.isNotEmpty) ...[
                _Place(
                  item: MxBreadcrumbItem(label: _fold, onTap: _nearest(folded)),
                  semanticLabel: [for (final item in folded) item.label]
                      .join(', '),
                  isCurrent: false,
                ),
                const _Separator(),
              ],
              for (final (index, item) in shown.indexed) ...[
                if (index > 0) const _Separator(),
                // Ancestors keep their measured width; the current place
                // takes what is left.
                Flexible(
                  flex: index == last ? 1 : 0,
                  child: _Place(item: item, isCurrent: index == last),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Where the fold goes: the nearest folded place that can be opened.
  static VoidCallback? _nearest(List<MxBreadcrumbItem> folded) {
    for (final item in folded.reversed) {
      final VoidCallback? tap = item.onTap;
      if (tap != null) {
        return tap;
      }
    }
    return null;
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

  /// How many of the oldest ancestors fold into one place: none when the
  /// whole path fits; otherwise the current place and the nearest ancestors
  /// that fit whole beside the fold stay.
  static int _hiddenCount(List<double> natural, double room, double fold) {
    const double separator = AppIconSize.small + 2 * AppSpacing.micro;
    final int last = natural.length - 1;
    double whole = natural[last];
    for (var i = 0; i < last; i++) {
      whole += natural[i] + separator;
    }
    if (whole <= room) {
      return 0;
    }
    double left = room - natural[last] - fold - separator;
    var index = last - 1;
    while (index >= 0 && natural[index] + separator <= left) {
      left -= natural[index] + separator;
      index--;
    }
    return index + 1;
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
  const _Place({
    required this.item,
    required this.isCurrent,
    this.semanticLabel,
  });

  final MxBreadcrumbItem item;
  final bool isCurrent;

  /// What TalkBack reads instead of the label (the folded places).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final VoidCallback? tap = isCurrent ? null : item.onTap;
    final Widget label = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSize.tapTarget,
        minHeight: AppSize.tapTarget,
      ),
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
      label: semanticLabel ?? item.label,
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
