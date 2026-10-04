import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// An inline load failure with Retry, or, without [onRetry], the "not
/// found" form (DESIGN.md, MxErrorState): an r16 `error-container` tile, the
/// empty state's 64, with
/// the alert glyph (cloud-off only for a network failure), a title, an
/// optional message in the local-first voice and the Retry button.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.isNetwork = false,
    super.key,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'Retry has a label and an action, or neither.',
       );

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool isNetwork;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final String? body = message;
    final String? retry = retryLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.section,
        vertical: AppSpacing.major,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSize.emptyTile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  isNetwork ? Icons.cloud_off_outlined : Icons.error_outline,
                  size: AppIconSize.large,
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleLarge,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.control),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.apply(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (retry != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxButton(
              label: retry,
              onPressed: onRetry,
              tone: MxButtonTone.secondary,
              icon: Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }
}
