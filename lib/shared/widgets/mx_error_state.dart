import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// An inline load failure with a Retry. It has EmptyState's anatomy at a
/// smaller scale and a danger tone. The body says first that nothing was
/// lost, then offers the retry. A gone item is not a failure: it is an
/// MxEmptyState in the neutral tone (owner 2026-10-08). [actionIcon] swaps
/// Retry's glyph when the action is not a retry, such as Close where
/// nothing can be retried; null draws none.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    super.key,
    required this.title,
    required this.body,
    this.icon = AppIcons.alert,
    this.retryLabel,
    this.onRetry,
    this.isRetrying = false,
    this.actionIcon = AppIcons.retry,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'retryLabel and onRetry come together',
       );

  final String title;
  final String body;

  /// Alert by default; pass `AppIcons.offline` only for a network failure
  /// (critique 2026-09-30).
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  /// The Retry holds a spinner while the reload runs.
  final bool isRetrying;

  /// The action's glyph: Retry by default; Close where nothing can be
  /// retried (study Guess, BR-STUDY-040).
  final IconData? actionIcon;

  static const double _verticalPadding = 40;
  static const double _tileSize = 52;
  static const double _titleGap = 4;

  @override
  Widget build(BuildContext context) {
    return MxCard(
      isFullBleed: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dimens.space24,
          vertical: _verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: _tileSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.error.tintOver(MxTintBase.of(context)),
                  borderRadius: context.radii.lg,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: context.dimens.sizeIcon,
                    color: context.colors.error,
                  ),
                ),
              ),
            ),
            // Ruling O4: the tile → title gap is UNSPECIFIED; EmptyState's.
            SizedBox(height: context.dimens.space16),
            // It swaps in for the skeleton in place: announce it
            // (SW-REV-006), the title with the body that says nothing was
            // lost (audit 2026-10-17).
            MergeSemantics(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.texts.sectionTitle,
                    ),
                    const SizedBox(height: _titleGap),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: context.texts.body.copyWith(
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if ((retryLabel, onRetry) case (
              final label?,
              final onPressed?,
            )) ...[
              SizedBox(height: context.dimens.space16),
              MxButton(
                label: label,
                icon: actionIcon,
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
