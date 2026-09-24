import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// An inline load failure with a Retry. It has EmptyState's anatomy at a
/// smaller scale and a danger tone. The body says first that nothing was
/// lost, then offers the retry. Without [onRetry] it is the "not found" form.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    super.key,
    required this.title,
    required this.body,
    this.icon = AppIcons.offline,
    this.retryLabel,
    this.onRetry,
    this.isRetrying = false,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'retryLabel and onRetry come together',
       );

  final String title;
  final String body;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  /// The Retry holds a spinner while the reload runs.
  final bool isRetrying;

  static const double _verticalPadding = 40;
  static const double _tileSize = 52;
  static const double _titleGap = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return MxCard(
      isFullBleed: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.section,
          vertical: _verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: _tileSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.derivedColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AppIconSize.standard,
                    color: colors.error,
                  ),
                ),
              ),
            ),
            // Ruling O4: the tile → title gap is UNSPECIFIED; EmptyState's.
            const SizedBox(height: AppSpacing.gutter),
            Text(
              title,
              textAlign: TextAlign.center,
              style: styles.compactTitle,
            ),
            const SizedBox(height: _titleGap),
            Text(body, textAlign: TextAlign.center, style: styles.emptyBody),
            if ((retryLabel, onRetry) case (
              final label?,
              final onPressed?,
            )) ...[
              const SizedBox(height: AppSpacing.gutter),
              MxButton(
                label: label,
                icon: AppIcons.retry,
                onPressed: onPressed,
                isLoading: isRetrying,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
