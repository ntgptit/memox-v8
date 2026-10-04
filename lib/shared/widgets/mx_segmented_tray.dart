import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/control_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One segment: the value it stands for and its localized label.
@immutable
class MxSegmentedTrayItem<T> {
  const MxSegmentedTrayItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// One of a few: a muted tray whose chosen segment is raised (DESIGN.md,
/// Inputs). Each segment is 48 tall to the touch and 36 painted.
class MxSegmentedTray<T> extends StatelessWidget {
  const MxSegmentedTray({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.isExpanded = false,
    super.key,
  });

  final List<MxSegmentedTrayItem<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Share the full width equally, as Progress's range tray does.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    const double inset = (AppSize.tapTarget - AppSize.segment) / 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: inset),
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final segment in segments)
              _wrap(
                _Segment<T>(
                  segment: segment,
                  isSelected: segment.value == selected,
                  onTap: () => onChanged(segment.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrap(Widget child) => isExpanded ? Expanded(child: child) : child;
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final MxSegmentedTrayItem<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow? whisper = isDark
        ? AppShadows.whisperDark
        : AppShadows.whisperLight;
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: MxRowInk(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: AppSize.tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.standard,
              height: AppSize.segment,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.grouped,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? mxRaisedInTray(colors) : null,
                borderRadius: radius,
                boxShadow: isSelected ? [?whisper?.on(colors.shadow)] : null,
              ),
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelLarge?.apply(
                  color: isSelected
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
